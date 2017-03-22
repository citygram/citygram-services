require 'spy_glass/registry'

opts = {
  path: '/clt-historic-district-reviews',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://clt-charlotte.opendata.arcgis.com/datasets/694f78a23c194a0bae1847a7ff71618d_0.geojson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    attributes = feature['properties']
    unique_id = attributes['OBJECTID']
    next if feature['geometry'].nil? || feature['geometry']['type'] == 'MultiPolygon' || attributes['ProjAddr'].nil?
    desc_phrase = ''
    if attributes['ProjDesc']
      project_description = attributes['ProjDesc'].strip
      desc_phrase = "for #{project_description} "
    end
    project_address = attributes['ProjAddr'].strip
    unique_title = "New Request #{desc_phrase}at #{project_address}. " + 
      "For more, call (704) 336-2205 or visit http://j.mp/clt-chd-reviews"

    {
      'type' => 'Feature',
      'id' => unique_id,
      'properties' => attributes.merge(
        'title' => unique_title,
        'url' => 'http://charmeck.org/city/charlotte/planning/HistoricDistricts/Pages/ByDistrict.aspx'
      ),
      'geometry' => feature['geometry']
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.reject{ |f| f.nil? } }
end
