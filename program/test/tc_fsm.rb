require_relative "../fsm.rb"
require "test/unit"

class TestFSM < Test::Unit::TestCase

  def setup
    @fsm_1 = FSM.new(1)
    @fsm_2 = FSM.new("Bruce_Banner")

    @fsm_1.send(:accept, 1,2,3,4,5)
    @fsm_2.send(:accept, "The_Incredible_Hulk")

    @fsm_1.send(:add_path, 2, 1, 3)
    @fsm_1.send(:add_path, 1, 1, 2)
    @fsm_1.send(:add_path, 3, 1, 1)
    @fsm_2.send(:add_path, "Bruce_Banner", "anger", "The_Incredible_Hulk")
  end

  def test_constructor
    assert_equal(1, @fsm_1.state)
    assert_equal("Bruce_Banner", @fsm_2.state)
  end

  def test_accepting_states
    assert_equal([1,2,3,4,5], @fsm_1.accepting_states)
    assert_equal(["The_Incredible_Hulk"], @fsm_2.accepting_states)
  end

  def test_add_path
    assert_equal(2, @fsm_1.paths[1][1])
    assert_equal(1, @fsm_1.paths[3][1])
    assert_equal(nil, @fsm_1.paths[2][2])
    assert_equal("The_Incredible_Hulk", @fsm_2.paths["Bruce_Banner"]["anger"])
  end

  def test_change_state
    5.times {@fsm_1.send(:change_state, 1)}
    assert_equal(3, @fsm_1.state)
    assert_equal("The_Incredible_Hulk", @fsm_2.send(:change_state, "anger"))
    assert_raise(NoMethodError) { @fsm_2.send(:change_state, "tired") }
  end

  def test_parse_input_line_for_words
    test1 = FSM.parse_input_line_for_words(" Hewl12o, , ,WoRlds, !")
    assert_equal(["Hewl12o", "WoRlds"], test1)
  end

  def test_get_transition
    words = FSM.parse_input_line_for_words(" Hewl12o, , ,WoRlds, !")
    chars = "test"
    i = 0
    FSM.get_transition(" Hewl12o, , ,WoRlds, !", true) do |transition|
      assert_equal(words[i], transition)
      i+=1
    end
    i = 0
    FSM.get_transition(chars, false) do |transition|
      assert_equal(chars[i], transition)
      i+=1
    end
  end

  def test_build_from_file
    file_fsm_1 = FSM.new
    file_fsm_1.build_from_file(File.dirname(__FILE__) + "/fsm_1")
    assert_equal(file_fsm_1.state, @fsm_1.state.to_s)
    5.times do 
      @fsm_1.send(:change_state, 1)
      file_fsm_1.send(:change_state, "1")
    end
    assert_equal("3", file_fsm_1.state)
    assert_equal(file_fsm_1.state, @fsm_1.state.to_s)
  end

  def test_run
    fsm_ends_in_0 = FSM.new
    fsm_ends_in_0.build_from_file(File.dirname(__FILE__) + "/fsm_ends_in_0")
    assert_equal("Accept", fsm_ends_in_0.run("1010101010"))
    assert_equal("Reject: invalid final state", fsm_ends_in_0.run("1010101011"))
    assert_equal("Reject: invalid transition", fsm_ends_in_0.run("1010101021"))
  end

  def test_eliminate_unreachable_states
    ######### CASE 1--NOTHING TO ELIMINATE #########
    rich_min_1 = FSM.new
    rich_min_1.build_from_file(File.dirname(__FILE__) + '/rich_min_1')
    # states before elimination
    assert_equal("q1", rich_min_1.state)
    # states before elimination
    assert_equal(["q1", "q2", "q3"], rich_min_1.states)
    # paths before elimination
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}, 
                  "q3"=>{"a"=>"q1", "b"=>"q1"}}, rich_min_1.paths)
    # accepting states before elimination
    assert_equal(["q1"], rich_min_1.accepting_states)
    rich_min_1.eliminate_unreachable_states
    # states after elimination
    assert_equal("q1", rich_min_1.state)
    # states after elimination
    assert_equal(["q1", "q2", "q3"], rich_min_1.states)
    # paths after elimination
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}, 
                  "q3"=>{"a"=>"q1", "b"=>"q1"}}, rich_min_1.paths)
    # accepting states after elmination
    assert_equal(["q1"], rich_min_1.accepting_states)

    ######### CASE 2--ELIMINATE EVERYTHING EXCEPT START STATE #########
    rich_min_1_2 = FSM.new
    rich_min_1_2.build_from_file(File.dirname(__FILE__) + '/rich_min_1_2')
    # states before elimination
    assert_equal("q4", rich_min_1_2.state)
    # states before elimination
    assert_equal(["q1", "q2", "q3", "q4"], rich_min_1_2.states.sort)
    # paths before elimination
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}, 
                  "q3"=>{"a"=>"q1", "b"=>"q1"}}, rich_min_1_2.paths)
    # accepting states before elimination
    assert_equal(["q1", "q4"], rich_min_1_2.accepting_states)
    rich_min_1_2.eliminate_unreachable_states
    # states after elimination
    assert_equal("q4", rich_min_1_2.state)
    # states after elimination
    assert_equal(["q4"], rich_min_1_2.states)
    # paths after elimination
    assert_equal({}, rich_min_1_2.paths)
    # accepting states after elmination
    assert_equal(["q4"], rich_min_1_2.accepting_states)
  end

  def test_build_tables
    rich_min_1 = FSM.new
    rich_min_1.build_from_file(File.dirname(__FILE__) + '/rich_min_1')
    classes = rich_min_1.states.partition{ |state| rich_min_1.accepting_states.include? state }
    assert_equal(
      {"q1"=>{"my_class"=>["q1"], "a"=>["q2", "q3"], "b"=>["q2", "q3"]}, 
       "q2"=>{"my_class"=>["q2", "q3"], "a"=>["q1"], "b"=>["q1"]}, 
       "q3"=>{"my_class"=>["q2", "q3"], "a"=>["q1"], "b"=>["q1"]}}, 
      rich_min_1.build_tables(classes)
    )
  end

  def test_get_equiv_classes
    rich_min_1 = FSM.new
    rich_min_1.build_from_file(File.dirname(__FILE__) + '/rich_min_1')
    assert_equal([["q1"], ["q2", "q3"]], rich_min_1.get_equiv_classes)
    rich_min_2 = FSM.new
    rich_min_2.build_from_file(File.dirname(__FILE__) + '/rich_min_2')
    assert_equal([["1", "3", "5"], ["2"], ["4"], ["6"]], rich_min_2.get_equiv_classes)
  end

  def test_minimize
    ######### CASE 1--ONLY RESETS PATHS AND STATES #########
    elaine_rich_fsms = FSM.new
    elaine_rich_fsms.build_from_file(File.dirname(__FILE__) + '/rich_min_1')
    # state before minimization
    assert_equal("q1", elaine_rich_fsms.state)
    # states before minimization
    assert_equal(["q1", "q2", "q3"], elaine_rich_fsms.states.sort)
    # paths before minimization
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}, 
                  "q3"=>{"a"=>"q1", "b"=>"q1"}}, elaine_rich_fsms.paths)
    # accepting states before transition
    assert_equal(["q1"], elaine_rich_fsms.accepting_states)
    elaine_rich_fsms.minimize
    # state after minimization
    assert_equal("q1", elaine_rich_fsms.state)
    # states after minimization
    assert_equal(["q1", "q2"], elaine_rich_fsms.states.sort)
    # paths after minimization
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q2"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}}, elaine_rich_fsms.paths)
    # accepting states after transition
    assert_equal(["q1"], elaine_rich_fsms.accepting_states)

    #########  CASE 2--RESETS EVERYTHING #########
    elaine_rich_fsms.build_from_file(File.dirname(__FILE__) + '/rich_min_1_1')
    # state before minimization
    assert_equal("q1", elaine_rich_fsms.state)
    # states before minimization
    assert_equal(["q1", "q2", "q3", "q4"], elaine_rich_fsms.states.sort)
    # paths before minimization
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q4", "b"=>"q4"}, 
                  "q3"=>{"a"=>"q4", "b"=>"q4"},
                  "q4"=>{"a"=>"q2", "b"=>"q3"}}, elaine_rich_fsms.paths)
    # accepting states before transition
    assert_equal(["q1", "q4"], elaine_rich_fsms.accepting_states.sort)
    elaine_rich_fsms.minimize
    # state after minimization
    assert_equal("q1", elaine_rich_fsms.state)
    # states after minimization
    assert_equal(["q1", "q2"], elaine_rich_fsms.states.sort)
    # paths after minimization
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q2"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}}, elaine_rich_fsms.paths)
    # accepting states after transition
    assert_equal(["q1"], elaine_rich_fsms.accepting_states)

    #########  CASE 3--REMOVES UNREACHABLE STATES #########
    elaine_rich_fsms.build_from_file(File.dirname(__FILE__) + '/rich_min_1_2')
    # states before minimization
    assert_equal("q4", elaine_rich_fsms.state)
    # states before minimization
    assert_equal(["q1", "q2", "q3", "q4"], elaine_rich_fsms.states.sort)
    # paths before minimization
    assert_equal({"q1"=>{"a"=>"q2", "b"=>"q3"}, 
                  "q2"=>{"a"=>"q1", "b"=>"q1"}, 
                  "q3"=>{"a"=>"q1", "b"=>"q1"}}, elaine_rich_fsms.paths)
    # accepting states before minimization
    assert_equal(["q1", "q4"], elaine_rich_fsms.accepting_states)
    elaine_rich_fsms.minimize
    # states after minimization
    assert_equal("q4", elaine_rich_fsms.state)
    # states after elimination
    assert_equal(["q4"], elaine_rich_fsms.states.sort)
    # paths after minimization
    assert_equal({}, elaine_rich_fsms.paths)
    # accepting states after minimization
    assert_equal(["q4"], elaine_rich_fsms.accepting_states)
  end
end
