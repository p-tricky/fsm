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
#  See {fsm_1}[rdoc-ref:fsm_1] and test/fsm_2 for examples of acceptable file 
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

  attr_reader :state, :states, :accepting_states, :paths

  ## 
  #  Initializes empty fsm  
  #
  def initialize(state=nil)
    @state = state
    @states = []
    @states << state if state
    @accepting_states = []
    @transitions = []
    @paths = {}
  end

  ##
  #  {Test Example}[rdoc-ref:TestFSM#test_clear]
  #
  def clear
    @state = nil
    @states = []
    @accepting_states = []
    @transitions = []
    @paths = {}
  end

  def accept(*args)
    @accepting_states = args.to_a.flatten
  end

  ##
  #  {Test Example}[rdoc-ref:TestFSM#test_add_path]
  #
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

  ##
  #  {Test Example}[rdoc-ref:TestFSM#test_change_state]
  #
  def change_state(input)
    @state = @paths[@state][input]
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
      @states << @state
      accept(FSM.parse_input_line_for_words(f.gets))
      while (line = f.gets) 
        start, path, dest = FSM.parse_input_line_for_words(line)
        add_path(start, path, dest)
      end
    end
  end
      
  ##
  #  Writes the fsm to a file using a formatting style
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
          f.puts "#{src}, #{trans}, #{dest}"
        end
      end
    end
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
    begin
      FSM.get_transition(input, has_words) do |transition|
        change_state(transition)
      end
      if @accepting_states.include?(@state)
        return "Accept"
      else
        return "Reject: invalid transition" if @state.nil?
        return "Reject: invalid final state"
      end
    rescue NoMethodError
      return "Reject: invalid transition"
    end
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

  ##
  #  Uses breadth first search to find all states that are reachable 
  #  from the start state
  #
  def get_reachable_states()
    reachable_states = [@state]
    djikstra_queue = Queue.new
    djikstra_queue.enq @state
    while not djikstra_queue.empty?
      visited_state = djikstra_queue.pop
      if @paths[visited_state]
        @paths[visited_state].each do |trans, dest|
          djikstra_queue.enq dest unless reachable_states.include? dest
        end
        reachable_states << visited_state
      end
    end
    return reachable_states
  end

  ##
  #  Gets reachable states and then eliminates all others
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_eliminate_unreachable_states]
  #
  def eliminate_unreachable_states()
    reachable_states = get_reachable_states
    @states.delete_if{ |state| not reachable_states.include? state }
    @accepting_states.delete_if{ |state| not reachable_states.include? state }
    @paths.delete_if{ |state| not reachable_states.include? state }
  end

  ##
  #  Returns a hash of hashes.
  #
  #  In the return hash, each key corresponds to
  #  a state.  For each possible transition there
  #  is a secondary hash where the key is the 
  #  transition and the value is the state that
  #  results from said transition.
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_build_tables]
  #
  def build_tables(classes)
    tbls = Hash.new
    @states.each do |state|
      tbl = build_table state, classes
      tbls[state] = tbl
    end
    return tbls
  end

  ##
  #  Returns a 2 dimensional hash.
  #
  #  Each state in the fsm is a key in the hash.
  #  The keys hash to another hash that contains
  #  metadata.  The metadata includes the key's class
  #  as well as all of the possible transitions from
  #  the key and the classes that the transitions lead to
  #
  def build_table(state, classes)
    tbl = Hash.new
    classes.each do |cur_class|
      my_class = cur_class if cur_class.find { |targ| targ.eql? state }
      tbl["my_class"] = my_class and break if my_class
    end
    @transitions.each do |transition| 
      dest = @paths[state][transition] rescue nil
      tbl[transition] = dest unless dest
      if dest
        classes.each do |cur_class|
          dest_class = cur_class if cur_class.find { |targ| targ.eql? dest }
          tbl[transition] = dest_class and break if dest_class
        end
      end
    end
    return tbl
  end

  ##
  #  Group the tables by metadata.  This returns a hash where the keys are the
  #  unique metadata entries, and the values are an array containing all of the
  #  tbls that share the same metadata.
  #
  #  Add all states with identical metadata to the same equiv_class.
  #  Return an array containing each equiv_class
  #
  def split_classes(tbls)
    equiv_classes = []
    tbls.group_by{ |state, metadata| metadata }.values.each do |tbls_with_equiv_metadata|
      # group_by returns a hash where
      equiv_class = []
      tbls_with_equiv_metadata.each do |state, metadata|
        equiv_class << state
      end
      equiv_classes << equiv_class
    end
    return equiv_classes
  end

  ##
  #  Returns a 2 dimensional array.  Each subarray contains all states
  #  that are part of the same equivalence class
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_get_equiv_classes]
  #
  def get_equiv_classes(equiv_classes=nil)
    old_equiv_classes = equiv_classes
    if not old_equiv_classes
      old_equiv_classes = @states.partition{ |state| @accepting_states.include? state }.reject(&:empty?)
    end
    tbls = build_tables old_equiv_classes
    new_equiv_classes = split_classes(tbls)
    new_equiv_classes = get_equiv_classes(new_equiv_classes) unless new_equiv_classes.eql?(old_equiv_classes) 
    return new_equiv_classes
  end

  ##
  #  Modifies the fsm so that it contains only the first state from each equiv class.
  #  It also removes any classes that are unreachable
  #
  #  {Test Example}[rdoc-ref:TestFSM#test_minimize]
  #
  def minimize()
    eliminate_unreachable_states
    equiv_classes = get_equiv_classes
    keeper_states = []
    equiv_classes.each do |equiv_class| 
      keeper_states << equiv_class.first
    end
    #reset state
    @state = equiv_classes.find{ |equiv_class| equiv_class.include? @state}.first
    # remove redundant states
    @states = keeper_states
    # remove redundant accepting states
    @accepting_states.delete_if{ |state| not @states.include? state }
    # reset paths 
    @paths.each do |src, paths_from_src|
      src_class = equiv_classes.find{ |equiv_class| equiv_class.include?(src) }
      src_keeper_state = src_class.first
      paths_from_src.each do |trans, dest|
        dest_class = equiv_classes.find{ |equiv_class| equiv_class.include?(dest) }
        dest_keeper_state = dest_class.first
        # replace src and dest with keeper state from respective classes
        if @paths.has_key?(src_keeper_state)
          @paths[src_keeper_state] = @paths[src_keeper_state].merge({ trans => dest_keeper_state })
        else
          @paths[src_keeper_state] = { trans => dest_keeper_state }
        end
      end
    end
    # remove redundant paths
    @paths.delete_if{ |state| not @states.include? state }
  end

  ##
  #  Builds an fsm from the input file
  #  Minimizes the fsm.
  #  Writes the minimized fsm to a file of the same
  #  name as the input file but with the addition .min
  #  extention
  #
  def build_from_file_and_minimize(filename)
    build_from_file(filename)
    minimize()
    write_to_file(filename+".min")
  end

  if __FILE__ == $0
    fsm_file = ARGV[0]
    input_file = ARGV[1]
    output_file = ARGV[2]
    min = ARGV[3]
    if (min and not min.eql? "--min") or (ARGV[0..2].include? "--min")
      puts "Sorry, error when processing command line input."
      puts "Please see docs for proper usage."
      exit 1
    end
    fsm = FSM.new
    fsm_min = FSM.new if min
    fsm.build_from_file(fsm_file)
    fsm_min.build_from_file_and_minimize(fsm_file) if min
    fsm_min.write_to_file fsm_file + ".min" if min
    fsm.run_from_file(input_file, output_file)
    fsm_min.run_from_file(input_file, output_file+".min") if min
  end

  private :accept, :add_path, :change_state
end
