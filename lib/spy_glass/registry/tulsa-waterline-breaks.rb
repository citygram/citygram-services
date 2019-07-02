require 'spy_glass/registry'

opts = {
  path: '/tulsa-street-projects',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://www.cityoftulsa.org/umbraco/surface/BreakBoard/GetBreakBoardData/'
}


SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['records'].map do |item|
    title = <<-TITLE.oneline
      There is waterline break nearby at
      #{'addr'}
      .  Go to http://http://www.improveourtulsa.com for more information
    TITLE
    {
      'id' => "WO_NUMBER",
      'type' => 'Problem',
      'title' => title,
      'properties' => {'creation_date'=> 'Created',
                       'wateroff_date'=> 'WaterOff_Date',
                       'wateroff_time'=> Time.at('WaterOff_Time'.to_f / 1000),
                       'digdate'=> 'DigDate',
                       'digtime'=> Time.at('DigTime'.to_f / 1000),
                      }
    }

  end

  {'type' => 'FeatureCollection', 'features' => features}
end
