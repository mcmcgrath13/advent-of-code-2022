class Literal
    def initialize token
      @value = token.to_i
    end
  
    def eval environment
      @value
    end
  end
  
  class Expression
    attr_accessor :left
    attr_accessor :right
    
    def initialize tokens
      @left = tokens[0]
      @op = tokens[1]
      @right = tokens[2]
    end
  
    def eval environment
      left = environment[@left]
      right = environment[@right]
      case @op
        when "+" then left.eval(environment) + right.eval(environment)
        when "-" then left.eval(environment) - right.eval(environment)
        when "*" then left.eval(environment) * right.eval(environment)
        when "/" then left.eval(environment) / right.eval(environment)
      end
    end
  end
  
  class Hole
    def eval environment
      raise "I'm a hole!"
    end
  end
  
  def parse_file(path)
    lines = File.readlines(path)
    environment = Hash.new
    lines.each do |line|
      tokens = line.split(' ')
      var = tokens.shift.chop
      environment[var] = if tokens.size == 1
        Literal.new tokens.first
      else
        Expression.new tokens
      end
    end
  
    environment
  end
  
  def part_1(path)
    environment = parse_file(path)
    environment["root"].eval(environment)
  end
  
  def eval_with_humn(right, environment, val)
    environment["humn"] = Literal.new(val)
    right.eval(environment)
  end
  
  def search_for_var(left_var, right_var, environment)
    left = environment[left_var]
    right = environment[right_var]
    target = left.eval(environment)
    low_guess = -10000000000000
    high_guess = 10000000000000
    low_guess_val = eval_with_humn(right, environment, low_guess)
    high_guess_val = eval_with_humn(right, environment, high_guess)
  
    while low_guess + 1 < high_guess
      guess = (high_guess + low_guess) / 2
      guess_val = eval_with_humn(right, environment, guess)
      if guess_val == target
        puts guess
        puts guess_val
        puts target
        return guess
      end
  
      if (low_guess_val < target && target < guess_val) || (guess_val < target && target < low_guess_val)
        high_guess = guess
        high_guess_val = guess_val
      else
        low_guess = guess
        low_guess_val = guess_val
      end
    end
  
    return 0
  end
  
  def part_2(path)
    environment = parse_file(path)
    environment["humn"] = Hole.new
    begin
      search_for_var(environment["root"].left, environment["root"].right, environment)
    rescue
      search_for_var(environment["root"].right, environment["root"].left, environment)
    end
  end
  
  puts part_1("example.txt")
  puts part_1("input.txt")
  puts part_2("example.txt")
  puts part_2("input.txt")