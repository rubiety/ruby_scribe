RSpec::Matchers.define :emit_as do |expected|
  match do |actual|
    @emitted = RubyScribe::Emitter.new.emit(actual)
    @emitted == expected
  end
  
  failure_message_for_should do |actual|
    "expected that:\n\n#{actual}\n\n would emit as:\n\n#{with_boundaries(expected)}\n\nbut instead was:\n\n#{with_boundaries(@emitted)}"
  end

  failure_message_for_should_not do |actual|
    "expected that:\n\n#{actual}\n\n would not emit as:\n\n#{with_boundaries(expected)}\n\nbut instead was:\n\n#{with_boundaries(@emitted)}"
  end
  
  description do
    segment = expected.split("\n")[0] + "..."
    "emit as #{segment}"
  end
  
  def with_boundaries(string)
    string.split("\n").map {|s| s + "|"}.join("\n")
  end
end