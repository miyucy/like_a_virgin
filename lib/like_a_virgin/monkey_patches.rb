require "spec/runner/formatter/base_text_formatter"

class Spec::Runner::Formatter::BaseTextFormatter
  def colour(text, colour_code)
    "#{colour_code}#{text}\e[0m"
  end
end
