#!/usr/bin/ruby

require 'set'

# setup some data structures to represent the grammar
$terminals = Set.new
$nonterminals = Set.new
$startSymbol = ''
$productions = Hash.new

# hashtables that answer if specific rules or symbols can derive lamda
# populated by DerivesEmptyString
$symbolDerivesEmpty = Hash.new
$ruleDerivesEmpty = Hash.new

# the current left hand side for the production being read
$LHS = ''

# ==SUPPORTING FUNCTIONS==

# an interator that visits each occurance of X in the RHS of all rules
def occurances(x)
  #todo
end

# returns the non-terminal defined by production p
def leftHandSide(p)
  #todo
end

# returns an iterator that visits each production for the non-terminal a
def ProductionsFor(a)
  if $productions[a]
    $productions.each
  end
end

# checks which rules can derive lambda in one or more derivations
def DerviesEmptyString
  #todo
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
        # must be lowercase, do not count the end of input token as a non-terminal
        if isLowerCase x and x != "$"
          # this is a non-terminal
          $terminals << x
        end
      end
    end
  end
end

def parseLine(line)
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

#print out results
puts "Terminals: #{$terminals.to_a.join(", ")}"
puts "Non-terminals: #{$nonterminals.to_a.join(", ")}"
puts "Start symbol: #{$startSymbol}"
ruleNum = 1
puts "\nRules of this grammar:"
$productions.each do |lhs, rhs|
  rhs.each do |rule|
    puts "(#{ruleNum})\t#{lhs} -> #{rule}"
    ruleNum += 1
  end
end
