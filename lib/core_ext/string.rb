require 'dedent'

class String
  def oneline
    dedent.gsub(/\s{2,}|\n/, ' ')
  end
end
