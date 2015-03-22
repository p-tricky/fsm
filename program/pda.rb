## 
#  The PDA class builds a pda from
#  a text file and runs an input string from a separate 
#  text file.
#
#  ==Example usage:
#  ===Standard (No minimization)
#   $ ruby pda.rb pda pda_input pda_output
#  
#  The previous command will build the pda specified 
#  in the pda text file and run the inputs specified
#  in the pda_input text file.  The pda_output argument
#  is optional.  If you specify an output file, the 
#  program will write the results to the specified file.
#  Otherwise, the program will write the results to STD_IN.
#
#
#  ==pda file
#  The pda text file should be formatted as follows:
#     starting state
#     accepting states (comma or space separated)
#     transitions (start, path, dest)
#  
#  If you try to give the program a state or transition that contains
#  special characters or spaces, the program will become confused.
#  See {equals}[rdoc-ref:equals] and {palindrome}[rdoc-ref:palindrome] for examples of acceptable file 
#  specifications.
#
#  ==pda_input file
#  The pda_input file can be specified in one of two ways*
#   1) string of chars 
#      110...
#      here the first 2 transitions are 1 and the third is 0
#   2) space and/or comma separated words 
#      trans_1, trans_2 trans_3
#  See {equals_input}[rdoc-ref:equals_input] and {palindrome_input
#  }[rdoc-ref:palindrome_input] for examples.
#
class PDA

  attr_reader :state, :states, :accepting_states, :paths

  ## 
  #  Initializes empty pda  
  #
  def initialize(state=nil)
    @start_state = state
    @state = state
    @states = []
    @states << state if state
    @accepting_states = []
    @transitions = []
    @stack = []
    @trans_push_pop_lookup_table = {}
    @paths = {}
  end

  def clear
    @start_state = nil
    @state = nil
    @states = []
    @accepting_states = []
    @transitions = []
    @stack = []
    @trans_push_pop_lookup_table = {}
    @paths = {}
  end

  def reset
    @state = @start_state
    @stack = []
  end

  def accept(*args)
    @accepting_states = args.to_a.flatten
  end

  def add_path(start, path, dest)
    if @paths.has_key?(start)
      @paths[start] = @paths[start].merge({ path => dest })
    else
      @paths[start] = { path => dest }
    end
    if not @states.include? start
      @states << start
    end
    if not @states.include? dest
      @states << dest
    end
    if not @transitions.include? path
      @transitions << path
    end
  end

  def change_state(input)
    src = @state
    @state = @paths[@state][input]
    index = [src, input, @state]
    pop, push = @trans_push_pop_lookup_table[index]
    if not pop.empty?
      popped = @stack.pop 
      raise NoMethodError unless pop == popped 
    end
    @stack.push push unless push.empty?
  end

  ##
  #  Pulls words out of input string and into an array
  #
  def self.parse_input_line_for_words(line)
    line.split(/\W+/).reject(&:empty?)
  end

  ## 
  #  Builds an pda from text file
  #  
  #  The method assumes the first line to be the starting state,
  #  the second line to be accepting states, and any lines after 
  #  that to be transitions
  #  
  def build_from_file(filename)
    clear
    open(filename, 'r') do |f|
      while (line = f.gets and line[/\#/]) # skip commented headers
      end
      @start_state = PDA.parse_input_line_for_words(line)[0]
      @state = @start_state
      @states << @state
      accept(PDA.parse_input_line_for_words(f.gets))
      while (line = f.gets) 
        start, consume, pop, push, dest = line.split(',').map{|el| el.strip}
        add_path(start, consume, dest)
        path = [start, consume, dest]
        @trans_push_pop_lookup_table[path] = [pop, push]
      end
    end
  end
      
  ##
  #  Writes the pda to a file using a formatting style
  #  that is compatible with the build from file method
  #  
  def write_to_file(filename) 
    open(filename, 'w+') do |f|
      f.puts "#{@state}"
      @accepting_states.each_with_index do |state, pos|
        if pos <  @accepting_states.length-1
          f.print "#{state}, "
        else
          f.print "#{state}\n"
        end
      end
      @paths.each do |src, paths_from_src|
        paths_from_src.each do |trans, dest|
          pop, push = @trans_push_pop_lookup_table[index]
          f.puts "#{src}, #{trans}, #{pop}, #{push}, #{trans}"
        end
      end
    end
  end

  ##
  #  Gets all of the transitions from a line of text.
  #  It can pull transitions either as words or as chars
  #
  def self.get_transition(line, has_words)
    if has_words
      transitions = self.parse_input_line_for_words(line)
      transitions.size.times do |n|
        yield transitions[n]
      end
    else
      line.length.times do |n|
        yield line[n]
      end
    end
  end

  ##
  #  Processes a string of input and either rejects or accepts.
  # 
  def run(input)
    reset
    has_words = input.include? ","
    begin
      PDA.get_transition(input, has_words) do |transition|
        change_state(transition)
      end
      if @accepting_states.include?(@state) and @stack.empty?
        return "Accept"
      else
        return "Reject"
      end
    rescue NoMethodError
      return "Reject"
    end
  end

  ##
  #  Reads lines from an input file and either accepts or rejects each 
  #  line
  #  
  #  The method assumes each line of the file is a new test.  Dont put 
  #  line breaks in your tests it will confuse the program
  #
  def run_from_file(input_file, output_file=nil)
    results = []
    open(input_file, 'r') do |f|
      while (line = f.gets)
        line = line.strip unless line.nil?
        next if (line[0] == "\#")
        result = run(line)
        puts result unless output_file
        results << result
      end
    end
    if not output_file.nil?
      open(output_file, 'w+') do |f|
        results.each do |result|
          f.puts "#{result}"
        end
      end
    end
  end

  if __FILE__ == $0
    pda_file = ARGV[0]
    input_file = ARGV[1]
    output_file = ARGV[2]
    pda = PDA.new
    pda.build_from_file(pda_file)
    pda.run_from_file(input_file, output_file)
  end

  private :accept, :add_path, :change_state
end
