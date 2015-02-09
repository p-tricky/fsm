## 
#  The fsm class builds a finite state machine from
#  a text file, and 
#
#  The text files should be formatted as follows:
#     starting state
#     accepting states (comma separated)
#     transitions (start, path, dest)
#
class FSM

  attr_reader :state, :accepting_states, :transitions

  ## Documentation for a function
  #
  #  More details
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

  def self.parse_input_line_for_words(line)
    line.split(/\W+/).reject(&:empty?)
  end

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
