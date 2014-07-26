require 'rack/utils'

module SpyGlass
  Registry = []
end

require 'dedent'
class String
  # Monkey patch used for building query strings
  def oneline
    dedent.gsub(/\n/, ' ')
  end
end

require 'spy_glass/registry'
