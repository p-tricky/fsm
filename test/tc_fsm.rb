require_relative "../fsm.rb"
require "test/unit"

class TestFSM < Test::Unit::TestCase

  def setup
    @fsm_1 = FSM.new(1)
    @fsm_2 = FSM.new("Bruce_Banner")

    @fsm_1.send(:accept, 1,2,3,4,5)
    @fsm_2.send(:accept, "The_Incredible_Hulk")

    @fsm_1.send(:add_transition, 2, 1, 3)
    @fsm_1.send(:add_transition, 1, 1, 2)
    @fsm_1.send(:add_transition, 3, 1, 1)
    @fsm_2.send(:add_transition, "Bruce_Banner", "anger", "The_Incredible_Hulk")
  end

  def test_constructor
    assert_equal(1, @fsm_1.state)
    assert_equal("Bruce_Banner", @fsm_2.state)
  end

  def test_accepting_states
    assert_equal([1,2,3,4,5], @fsm_1.accepting_states)
    assert_equal(["The_Incredible_Hulk"], @fsm_2.accepting_states)
  end

  def test_add_transition
    assert_equal(2, @fsm_1.transitions[1][1])
    assert_equal(1, @fsm_1.transitions[3][1])
    assert_equal(nil, @fsm_1.transitions[2][2])
    assert_equal("The_Incredible_Hulk", @fsm_2.transitions["Bruce_Banner"]["anger"])
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
    fsm = FSM.new
    fsm.build_from_file(File.dirname(__FILE__) + "/fsm_1")
    assert_equal(fsm.state, @fsm_1.state.to_s)
    5.times do 
      @fsm_1.send(:change_state, 1)
      fsm.send(:change_state, "1")
    end
    assert_equal("3", fsm.state)
    assert_equal(fsm.state, @fsm_1.state.to_s)
  end

  def test_run
    fsm_ends_in_0 = FSM.new
    fsm_ends_in_0.build_from_file(File.dirname(__FILE__) + "/fsm_ends_in_0")
    assert_equal("Accept", fsm_ends_in_0.run("1010101010"))
    assert_equal("Reject: invalid final state", fsm_ends_in_0.run("1010101011"))
    assert_equal("Reject: invalid transition", fsm_ends_in_0.run("1010101021"))
  end

end
