RSpec::Matchers.define :emit_itself do
  match do |actual|
    @parsed = RubyParser.new.parse(actual)
    @emitted = RubyScribe::Emitter.new.emit(@parsed)
    @emitted == actual
  end
  
  failure_message_for_should do |actual|
    "expected that the s-expression:\n\n#{@parsed}\n\nrepresenting:\n\n#{with_boundaries(actual)}\n\nwould emit itself, but emitted:\n\n#{with_boundaries(@emitted)}\n\n"
  end
  
  failure_message_for_should_not do |actual|
    "expected that the s-expression:\n\n#{@parsed}\n\nrepresenting:\n\n#{actual}\n\nwould emit itself, but emitted:\n\n#{@emitted}\n\n"
  end
  
  description do
    "emit itself"
  end
  
  def with_boundaries(string)
    string.split("\n").map {|s| s + "|"}.join("\n")
  end
end