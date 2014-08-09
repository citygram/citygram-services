require 'spy_glass/registry'

opts = {
  path: '/sf-311-cases',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.sfgov.org/resource/vw6y-z8j6?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'opened DESC',
    '$where' => <<-WHERE.oneline
      opened >= '#{7.days.ago.iso8601}' AND
      status = 'open' AND
      case_id IS NOT NULL AND
      category IS NOT NULL AND
      address IS NOT NULL AND
      neighborhood IS NOT NULL
    WHERE
  })
}

downcase_words = %w(intersection of and).freeze
downcase_regexp = Regexp.union(downcase_words.map{|w| /#{w}/i })

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      A new 311 case has been opened at #{item['address'].titleize} in the #{item['neighborhood']} neighborhood.
      The category is "#{item['category'].downcase}".
      Find out more: http://crmproxy.sfgov.org/selfservice/trackcase.jsp?ref=#{item['case_id']}.
    TITLE

    title.gsub!(downcase_regexp, &:downcase)
    title.gsub!(/(\,*) san francisco\,\ ca\,\ (\d*)/i, '')
    title.gsub!(/\s{2,}/, ' ')

    {
      'id' => item['case_id'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['point']['longitude'].to_f,
          item['point']['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
