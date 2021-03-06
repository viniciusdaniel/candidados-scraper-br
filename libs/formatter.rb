module Eleicoes
  module Formatter
    def clean!(text)
      text.strip.gsub(/\s+/,' ')
    end

    def time_from_string(text)
      DateTime.strptime(text, "%d/%m/%Y %H:%M:%S")
    end

    def date_from_string(text)
      DateTime.strptime(text, "%d/%m/%Y")
    end

    def filename_format(text)
      parts = text.split('.')
      ext = parts.pop
      text = parts.join('-').parameterize
      "#{text}.#{ext}"
    end

    def fileext(url)
      File.extname(url).gsub(/\?.*/, '')
    end
  end
end
