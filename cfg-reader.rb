#!/usr/bin/env ruby

require 'set'

# ==Global Variables==
# setup some data structures to represent the grammar
$terminals = Set["$"]
$nonterminals = Set.new
$startSymbol = ''

#key = LHS, value = RHS
$productions = Hash.new

# hashtables that answer if specific rules or symbols can derive lamda
# populated by derivesToLambda
$symbolDerivesToLambda = Hash.new
$checked = Hash.new

# the current left hand side for the production being read
$LHS = ''

# the LL(1) table's name. The actual declaration and intit are done in fillTable()
#$parseTable


# ==SUPPORTING FUNCTIONS==

# an interator that visits each occurance of X in the RHS of all rules
def occurances(x)
  # iterate through all LHSs in the hash,
  # then search through each of the RHSs in the list for occurances of the symbol
  # and yeild them
end

# returns the non-terminal defined by production p (actually the RHS of a production)
def leftHandSide(p)
  # 
end

# returns the set of productions for the non-terminal a
def productionsFor(a)
  if $productions[a]
    return $productions[a]
  else
    # since lambda is not considered a terminal, the first set will look for productions with
    # lambda on the LHS, and this allows any iteration over the results of this function to be
    # agnostic to whether there actually are any productions or not
    return Set.new
  end
end

# checks which rules can derive lambda in one or more derivations
def derivesToLambda(x)
  #puts "Received:\"#{x}\""
  if $terminals.include? x
    return false
  end
  #check for lamb dah or if it already derives
  if(x == "lambda" || $symbolDerivesToLambda[x] == true)
    #puts "went to lamb duh"
    return true
  end
  if (x == "$")
      return false
  end
  #puts "\tParsing:\"#{x}\""#check x's rule for lambdas
  productionsFor(x).each do |i|
    if(i == "lambda")
      $checked[x] = true
      $symbolDerivesToLambda[x] = true#if prod[x] contains a lambda, then yey
      return true;
    end
    $symbolDerivesToLambda[x] = false
  end
  $checked[x] = true
  #since x does not immediately contain a lamb, then check the non terminals within X
  productionsFor(x).each do |i|
    i.split(" ").each do |j|
      if($symbolDerivesToLambda[j] == false)
        return false
      end
      if($checked[j] == true && $symbolDerivesToLambda[j] == true)
        return true
      else
        if(derivesToLambda(j))
          return true
        end
      end
    end
  end
  $symbolDerivesToLambda[x] = false
  return false
end

# calculates the first set (set of terminals) for a given grammar sequence
def firstSet(seq, visited)

  # return the empty set for an empty input string
  if seq.empty?; return {}; end

  # check if the first token is already a terminal
  sep = seq.split
  x = sep[0]

  #puts "Seq: #{seq}, sep: #{sep.inspect}"

  #puts "Seq: #{seq}, empty? #{seq.empty?}, Sep: #{sep.inspect}, x: #{x}, eq lambda? #{x == "lambda"}"
  if $terminals.include? x
    return Set[x]
  end

  # else it's a non-terminal
  f = Set.new
  unless visited.include? x
    visited << x
    productionsFor(x).each do |r|
      g = firstSet(r, visited)
      f = f | g
    end
  end

  #puts "The value of x is #{x}"
  if x == "lambda" or derivesToLambda x
    # run the algorithm on the subsequent symbols
    g = firstSet(sep.drop(1).join(' '), visited)
    f = f | g
  end

  return f
end

def followSet(a, s)
  if s.include?(a)
    return Set.new
  end

  s.add(a)

  f = Set.new

  productions = Set.new
  $productions.each do |lhs, rules|
    rules.each do |rule|
      rule.split.each do |token|
        if a == token
          productions.add([lhs, rule.split])
        end
      end
    end
  end

  productions.each do |lhs, rule|
    rule.map.with_index{|token, index| index if token == a}.compact.each do |index|
      following = rule[(index + 1)..-1]
      g = firstSet(following.join(" "), Set.new)
      f = f.union(g)


      all_lambda = following.all?{|token| derivesToLambda(token)}
      if all_lambda
        g = followSet(lhs, s)
        f = f.union(g)
      end
    end
  end

  return f

end

# returns a set of terminals, the predict set for a given production
def predict(lhs, rhs)
  # create a new set for the terminals to be returned
  terminals = Set.new

  # if the rhs is just lambda then we do follow of lhs
  if rhs == "lambda"
    terminals = followSet(lhs, Set.new) 
  
  # if the rhs has all nonterminals that derive to lambda,
  # we take the union of the follow(lhs) and first(rhs)
  elsif rhs.split.all?{|token| derivesToLambda(token)}
    terminals = followSet(lhs, Set.new) | firstSet(rhs, Set.new)
  
  # if the rhs contains terminals and does not derive to lambda,
  # we just do the first(rhs)
  else
    terminals = firstSet(rhs, Set.new)
  end	


  return terminals
end

def fillTable
  # declare the parse table
  $parseTable = Array.new($nonterminals.length) { Array.new($terminals.length) }
  
  # init the table's rows and columns
  $nonterminals.each_with_index do |n, nidx|
    $terminals.each_with_index do |t, tidx|
      $parseTable[nidx][tidx] = -1 # default value indicates error
    end
  end

  # populate the table. Each value is an index into the set of productions for
  # a particular non-terminal in the $productions hashmap. Since they are sets,
  # they do not support random access via their index... We may need to change
  # the data structure to use arrays instead of sets to facilitate this
  $nonterminals.each_with_index do |n, nidx|
    productionsFor(n).each_with_index do |p, pidx|
      predict(n, p).each do |predictTerm|
        # hoping that set -> array preserves the same order as doing Set.each
        $parseTable[nidx][$terminals.to_a.index(predictTerm)] = pidx
      end
    end
  end
end


# ==APPLICATION LOGIC==

def isUpperCase(str)
  str == str.upcase
end

def isLowerCase(str)
  str == str.downcase
end

# looks at the LHS of rules to find all non-terminals of the grammar
def findNonTerminals(sides)
  # determine if this line is a production for a new nonterminal
  # does the line contain a "->"?
  if sides.length > 1

    # enforce that the LHS should be a nonterminal (upper case)
    if isUpperCase sides[0]
      
      # record the non-terminal
      $nonterminals << sides[0]

      # set this terminal as the LHS of production for future alternations
      $LHS = sides[0]
      
      # and determine if this is the start symbol
      if sides[1].include? "$"
        $startSymbol = sides[0]
      end
    end
  end
end


def findTerminals(line)
  # split the line by the alternation operator, and cleanup whitespace
  tokens = line.split("|").map(&:strip)
  tokens.each do |t|
    # skip empty elements in the array
    if !t.empty?

      # add this to the production rules structure
      # insert a new key if this is the first production for this LHS
      if !$productions[$LHS]
        $productions[$LHS] = Set.new
      end
      # add the production
      $productions[$LHS] << t

      # split this token into terminals and non-terminals
      terms = t.split(" ").map(&:strip)
      terms.each do |x|
        # must be lowercase, do not count the end of input token as
        # a non-terminal, nor the lambda symbol
        if isLowerCase x and x != "$" and x != "lambda"
          # this is a non-terminal
          $terminals << x
        end
      end
    end
  end
end

def parseLine(line)
  #puts "Read line: #{line}"
  if line.empty?
    return
  end

  sides = line.split("->").map(&:strip)
  findNonTerminals sides

  # omit the lhs from the non-terminal-finding subroutine
  if sides.length > 1
    rhs = sides[1]
  else
    rhs = sides[0]
  end

  findTerminals rhs
end


# ==MAIN PROGRAM==
#
# check that there is a file specified
unless ARGV.length == 1
  puts "Usage: ruby #{$0} myGrammar.cfg\n"
  exit
end

# read the CFG line by line
file = File.new(ARGV[0], "r")
while (line = file.gets)
  parseLine(line.chomp)
end
file.close

# print out results
puts "Terminals: #{$terminals.to_a.join(", ")}"
puts "Non-terminals: #{$nonterminals.to_a.join(", ")}"
puts "Start symbol: #{$startSymbol}"
ruleNum = 1
puts "\nRules of this grammar:"


$productions.each do |lhs, rules|
  rules.each do |rhs|
    puts "(#{ruleNum})\t\t#{lhs} -> #{rhs}"
    print "First set:\t"
    puts "{#{firstSet(rhs, Set.new).to_a.join(", ")}}\n\n"

    ruleNum += 1
  end
end

$nonterminals.each do |a|
    follow_set = followSet(a, Set.new)

    puts "Follow Set for #{a}: {#{follow_set.to_a.join(", ")}}"
end

# populate the parse table
fillTable

# print the table
puts "\nThe parse table for this grammar: (index per non-terminal, or -1 for syntax error)"
# find the longest non-terminal to pad the other non-terms with space to have even columns
len = 0
$nonterminals.each do |n|
  nlen = n.length
  if nlen > len
    len = nlen
  end
end
print " " * (len + 4)
puts " #{$terminals.to_a.join('   ')}"
$nonterminals.each_with_index do |n, nidx|
  # label
  print "%#{len}s | " % n
  # row data
  $terminals.each_with_index do |t, tidx|
    print "%#{t.length + 2}d " % $parseTable[nidx][tidx]
  end
  puts "\n"
end
