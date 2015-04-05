## 
#  The fsm class builds a finite state machine from
#  a text file and runs an input string from a separate 
#  text file.
#
#  ==Example usage:
#  ===Standard (No minimization)
#   $ ruby fsm.rb fsm fsm_input fsm_output
#  
#  The previous command will build the fsm specified 
#  in the fsm text file and run the inputs specified
#  in the fsm_input text file.  The fsm_output argument
#  is optional.  If you specify an output file, the 
#  program will write the results to the specified file.
#  Otherwise, the program will write the results to STD_IN.
#
#  ===Minimization
#  There is an option to minimize the FSM.  The minimization option
#  is specified by appending the --min flag to the end of the argument list.
#   $ ruby fsm.rb fsm fsm_input fsm_output --min
#  Please note that the min option must be at the end of the argument list 
#  and that the fsm_output must be specified (fsm_output can not be left
#  blank as in the standard usage).  
#
#  When the minimize option is selected two additional files will be created:
#  one that contains the minimized fsm formatted in the same style as the
#  standard fsm files and one additional output file that contains the results from the
#  the  minimized fsm.  The minimized fsm file will have the same name as the fsm
#  file provided, but with a .min extension appended to it.  Likewise, the additional
#  output file will have the same name as the output file provided, but with a
#  .min extension appended to it.
#
#  ==fsm file
#  The fsm text file should be formatted as follows:
#     starting state
#     accepting states (comma or space separated)
#     transitions (start, path, dest)
#  
#  If you try to give the program a state or transition that contains
#  special characters or spaces, the program will become confused.
#  See {fsm_1}[rdoc-ref:fsm_1] and {fsm_2}[rdoc-ref:fsm_2] for examples of acceptable file 
#  specifications.
#
#  ==fsm_input file
#  The fsm_input file can be specified in one of two ways*
#   1) string of chars 
#      110...
#      here the first 2 transitions are 1 and the third is 0
#   2) space and/or comma separated words 
#      trans_1, trans_2 trans_3
#  See {fsm_1_input}[rdoc-ref:fsm_1_input] and { fsm_2_input
#  }[rdoc-ref:fsm_2_input] for examples.
#
class FSM

  attr_accessor :state, :accepting_states, :paths, :eta, :curr_states, :next_states

  ## 
  #  Initializes empty fsm  
  #
  def initialize(state=nil)
    @state = state
    @curr_states = []
    @next_states = []
    @accepting_states = []
    @paths = Hash.new{ |h1, k1| h1[k1] = 
                       Hash.new{ |h2, k2| h2[k2] = [] }}
  end

  def clear
    @state = nil
    @eta = nil
    @curr_states = []
    @next_states = []
    @accepting_states = []
    @paths = Hash.new{ |h1, k1| h1[k1] = 
                       Hash.new{ |h2, k2| h2[k2] = [] }}
  end

  def accept(*args)
    @accepting_states = args.to_a.flatten
  end

  ##
  #  {Test Example}[rdoc-ref:TestFSM#test_add_path]
  #
  def add_path(start, path, dest)
      @paths[start][path] << dest
  end

  ##
  #  Pulls words out of input string and into an array
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_parse_input_line_for_words]
  #
  def self.parse_input_line_for_words(line)
    line.split(/\W+/).reject(&:empty?)
  end

  ## 
  #  Builds an fsm from text file
  #  
  #  The method assumes the first line to be the starting state,
  #  the second line to be accepting states, and any lines after 
  #  that to be transitions
  #  
  #  {Test Example}[rdoc-ref:TestFSM#test_build_from_file]
  #
  def build_from_file(filename)
    clear
    open(filename, 'r') do |f|
      while (line = f.gets and line[/\#/]) # skip comments
      end
      @state = FSM.parse_input_line_for_words(line)[0]
      @eta = FSM.parse_input_line_for_words(f.gets)[0]
      accept(FSM.parse_input_line_for_words(f.gets))
      while (line = f.gets) 
        start, path, dest = FSM.parse_input_line_for_words(line)
        add_path(start, path, dest)
      end
    end
  end

  ##
  #  Uses breadth first search to find all states that are reachable
  #  from the start state
  #
  def get_reachable_states(state, trans)
    reachable_states = []
    djikstra_queue = Queue.new
    djikstra_queue.enq state
    while not djikstra_queue.empty?
      visited_state = djikstra_queue.pop
      if @paths[visited_state][trans]
        @paths[visited_state][trans].each do |dest|
          djikstra_queue.enq dest unless reachable_states.include? dest
        end
        reachable_states << visited_state unless visited_state.eql? state
      end
    end
    return reachable_states
  end

  ##
  #  Gets all of the transitions from a line of text.
  #  It can pull transitions either as words (see test/fsm_2) or as chars (see test/fsm_1)
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_get_transition]
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
    has_words = input.include?(",")
    @curr_states = []
    @next_states = []
    @curr_states = get_reachable_states(@state, @eta)
    FSM.get_transition(input, has_words) do |transition|
      return "Reject" if @curr_states.empty?
      @curr_states.each do |state|
        @next_states.concat(get_reachable_states(state, transition))
        @next_states.concat(get_reachable_states(state, @eta))
      end
      @curr_states = @next_states
      @next_states = []
    end
    @curr_states.each do |state|
      return "Accept" if @accepting_states.include?(state)
    end
    return "Reject"
  end

  ##
  #  Reads lines from an input file and either accepts or rejects each 
  #  line
  #  
  #  The method assumes each line of the file is a new test.  Dont put 
  #  line breaks in your tests it will confuse the program
  #
  def run_from_file(input_file, output_file)
    results = []
    open(input_file, 'r') do |f|
      while (line = f.gets)
        line = line.strip unless line.nil?
        next if (line[0..1] == "//")
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

  private :accept, :add_path
end
