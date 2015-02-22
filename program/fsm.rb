## 
#  The fsm class builds a finite state machine from
#  a text file and runs an input string from a separate 
#  text file.
#
#  ==Example usage:
#   $ ruby fsm.rb fsm fsm_input fsm_output
#  
#  The previous command will build the fsm specified 
#  in the fsm text file and run the inputs specified
#  in the fsm_input text file.  The fsm_output argument
#  is optional.  If you specify an output file, the 
#  program will write the results to the specified file.
#  Otherwise, the program will write the results to STD_IN.
#
#  ==fsm file
#  The fsm text file should be formatted as follows:
#     starting state
#     accepting states (comma or space separated)
#     transitions (start, path, dest)
#  
#  If you try to give the program a state or transition that contains
#  special characters or spaces, the program will become confused.
#  See test/fsm_1 and test/fsm_2 for examples of acceptable file 
#  specifications.
#
#  ==fsm_input file
#  The fsm_input file can be specified in one of two ways*
#   1) string of chars 
#      110...
#      here the first 2 transitions are 1 and the third is 0
#   2) space and/or comma separated words 
#      trans_1, trans_2 trans_3
#  See test/fsm_1_input and test/fsm_2_input for examples.
#
class FSM

  attr_reader :state, :accepting_states, :transitions

  ## 
  #  Initializes empty fsm  
  #
  def initialize(state=nil)
    @state = state
    @accepting_states = []
    @transitions = {}
  end

  def accept(*args)
    @accepting_states = args.to_a.flatten
  end

  def add_transition(start, path, dest)
    if @transitions.has_key?(start)
      @transitions[start] = @transitions[start].merge({ path => dest })
    else
      @transitions[start] = { path => dest }
    end
  end

  def change_state(input)
    @state = @transitions[@state][input]
  end

  #
  # Pulls words out of input files and into an array
  #
  def self.parse_input_line_for_words(line)
    line.split(/\W+/).reject(&:empty?)
  end

  # 
  # Builds an fsm from text file
  # 
  # The method assumes the first line to be the starting state,
  # the second line to be accepting states, and any lines after 
  # that to be transitions
  #  
  def build_from_file(filename)
    open(filename, 'r') do |f|
      @state = FSM.parse_input_line_for_words(f.gets)[0]
      accept(FSM.parse_input_line_for_words(f.gets))
      while (line = f.gets) 
        start, path, dest = FSM.parse_input_line_for_words(line)
        add_transition(start, path, dest)
      end
    end
  end
      
  #
  # Gets all of the transitions from a line of text.
  # It can pull transitions are either as words (see test/fsm_2) or as chars (see test/fsm_1
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

  #
  # Processes a string of input and either rejects or accepts.
  #
  def run(input)
    has_words = input.include?(",")
    begin
      FSM.get_transition(input, has_words) do |transition|
        change_state(transition)
      end
      if @accepting_states.include?(@state)
        return "Accept"
      else
        return "Reject: invalid final state"
      end
    rescue NoMethodError
      return "Reject: invalid transition"
    end
  end

  #
  # Reads lines from an input file and either accepts or rejects each 
  # line
  #
  # The method assumes each line of the file is a new test.  Dont put 
  # line breaks in your tests it will confuse the program
  #
  def run_from_file(input_file, output_file)
    results = []
    start_state = @state
    open(input_file, 'r') do |f|
      while (line = f.gets)
        line = line.strip unless line.nil?
        next if (line[0..1] == "//")
        @state = start_state
        result = run(line)
        puts result unless output_file
        results << result
      end
    end
    if not output_file.nil?
      open(output_file, 'w+') do |f|
        results.each do |result|
          f.puts "// #{result}"
        end
      end
    end
  end

  if __FILE__ == $0
    fsm_file = ARGV[0]
    input_file = ARGV[1]
    output_file = ARGV[2]
    fsm = FSM.new
    fsm.build_from_file(fsm_file)
    fsm.run_from_file(input_file, output_file)
  end

  private :accept, :add_transition, :change_state
end
