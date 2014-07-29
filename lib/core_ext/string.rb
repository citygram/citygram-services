require 'dedent'

class String
  def oneline
    dedent.gsub(/\n/, ' ')
  end
end
