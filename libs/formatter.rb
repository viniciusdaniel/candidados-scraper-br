module Eleicoes
  module Formatter
    def clean!(text)
      text.strip.gsub(/\s+/,' ')
    end

    def time_from_string(text)
      DateTime.strptime(text, "%d/%m/%Y %H:%M:%S")
    end

    def filename_format(text)
      text.parameterize
    end

    def fileext(url)
      File.extname(url).gsub(/\?.*/, '')
    end
  end
end
