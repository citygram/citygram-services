require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone['Eastern Time (US & Canada)']

opts = {
  path: '/orlando-voting-centers',
  cache: SpyGlass::Cache::Memory.new(expires_in: 3600),
  source: 'https://raw.githubusercontent.com/cforlando/CityGram-Intermediary/master/voting_centers/data/voting.json'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  # For each election
  # Generate most recent notification if within one day

  # Days out to be search from today

  days_out = body['days_out']

  # Stash the today date
  today = Date.current

  # Create map of all precincts

  elections = body['elections'].map do |election|

    # Target date to compare with current day.
    election_date = Date.parse election['date']

    # If difference between today and Election Date is equal to one into the
    # Days Out, get the Geomatries.
    diff = Integer(election_date - today)
    if days_out.include?diff

      # Create the election/date alert for each precinct
      features = body['geoms'].reject{|x| x['properties']['voting_center'].nil?}.map do |geom|

        # IDs must be unique per message
        id = "#{today}|#{election['name']}|#{diff}|#{geom['properties']['precinct']}"

        # Title is the text message content
        title = "The #{election['name']} is "
        if diff == 0
          title << 'today'
        elsif diff == 1
          title << 'tomorrow'
        else
          title << "in #{diff} days"
        end
        center = geom['properties']['voting_center'].split.map(&:capitalize).join(' ')
        title << " on #{election_date}. Your polling place is the #{center}"

        {
          'id' => id,
          'type' => 'Feature',
          'properties' => {'title' => title},
          'geometry' => geom['geometry']
        }
      end
    end
  end
  { 'type' => 'FeatureCollection', 'features' => elections.flatten! }
end
