require 'active_support/inflector/inflections'
require 'money'
require 'spy_glass/clients'

#########################################
# Seattle Commercial Electrical Permits
#########################################
opts = {
  path: '/seattle-commercial-electrical-permits',
  cache: SpyGlass::Caches::Memory.new(expires_in: 1200),
  source: 'http://data.seattle.gov/resource/raim-ay5x?'+Rack::Utils.build_query({
    '$limit' => 250,
    '$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      status = 'Application Accepted' AND
      category = 'COMMERCIAL' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      application_date IS NOT NULL AND
      address IS NOT NULL AND
      permit_type IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Clients::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      Hi! #{item['applicant_name'].titleize} has applied for a commercial electrical permit at #{item['address']}.
      Find out more at #{item['permit_and_complaint_status_url']['url']}.
    TITLE

    {
      'id' => item['application_permit_number'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end

#########################################
# Seattle Building Permits
#########################################
opts = {
  path: '/seattle-building-permits',
  cache: SpyGlass::Caches::Memory.new(expires_in: 1200),
  source: 'http://data.seattle.gov/resource/mags-97de?'+Rack::Utils.build_query({
    '$limit' => 250,
    '$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      status = 'Application Accepted' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      application_date IS NOT NULL AND
      category IS NOT NULL AND
      address IS NOT NULL AND
      permit_type IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Clients::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      Hi! A building permit for #{item['category'].downcase} #{item['permit_type'].downcase} has been submitted near you at #{item['address']}.
      The proposed value is #{Money.new(item['value'].to_i*100, 'USD').format}.
      Find out more at #{item['permit_and_complaint_status_url']['url']}.
    TITLE

    {
      'id' => item['application_permit_number'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end

#########################################
# Seattle Code Case Violations
#########################################
opts = {
  path: '/seattle-code-violation-cases',
  cache: SpyGlass::Caches::Memory.new(expires_in: 1200),
  source: 'http://data.seattle.gov/resource/dk8m-pdjf?'+Rack::Utils.build_query({
    '$limit' => 250,
    '$order' => 'date_case_created DESC',
    '$where' => <<-WHERE.oneline
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      date_case_created IS NOT NULL AND
      address IS NOT NULL AND
      case_group IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Clients::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      There's been a #{item['case_group'].downcase} code violation near you at #{item['address']}.
      Its status is "#{item['status'].downcase}", and you can find out more at #{item['permit_and_complaint_status_url']['url']}.
    TITLE

    {
      'id' => item['case_number'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end

#########################################
# Seattle 911 Police Incidents
#########################################
opts = {
  path: '/seattle-pd-911-incidents',
  cache: SpyGlass::Caches::Memory.new,
  source: 'http://data.seattle.gov/resource/3k2p-39jp?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'event_clearance_date DESC',
    '$where' => <<-WHERE.oneline
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      event_clearance_date IS NOT NULL AND
      event_clearance_description IS NOT NULL AND
      hundred_block_location IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Clients::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      A 911 incident has occurred near you at #{item['hundred_block_location']}.
      It was described as "#{item['event_clearance_description'].downcase}" and has been cleared.
    TITLE

    {
      'id' => item['cad_cdw_id'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
