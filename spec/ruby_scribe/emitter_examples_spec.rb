require "spec_helper"

describe RubyScribe::Emitter, "Examples" do
  before { @emitter = RubyScribe::Emitter.new }
  
  Dir[File.join(File.dirname(__FILE__), "../examples/*.rb")].each do |example|
    describe "#{File.basename(example)} example" do
      specify("should emit itself") { File.read(example).should emit_itself }
    end
  end
end
