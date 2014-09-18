require 'spy_glass/registry'

class Empty
  def content_type
    'application/json'
  end

  def path
    raw_path
  end

  def raw_path
    '/empty'
  end

  def cooked
    raw
  end

  def raw
    JSON.pretty_generate({ 'type' => 'FeatureCollection', 'features' => [] })
  end

  def to_h
    {}
  end
end

SpyGlass::Registry << Empty.new
