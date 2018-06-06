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
  # Create map of all precincts

  elections = body.map do |election|

    # Days out to be search from today.
    # days_out = [0, 1, 3, 7, 14]
    days_out = election['days_out']

    # Stash the today date.
    today = Date.current

    # Target date to compare with current day.
    election_date = election['elections']['date']

    # If difference between today and Election Date is equal to one into the
    # Days Out, get the Geomatries.
    if days_out.include?(today - election_date)

      election['geoms']['geometry']['geometry']

    end

  end

  { 'type' => 'ElectionCollection', 'elections' => elections }

end
