module Formatter
  def clean!(text)
    text.strip.gsub(/\s+/,' ')
  end

  def time_from_string(text)
    DateTime.strptime(text, "%d/%m/%Y %H:%M:%S")
  end
end