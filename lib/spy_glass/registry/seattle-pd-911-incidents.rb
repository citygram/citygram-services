require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
title_template = ERB.new(<<-ERB.oneline)
A 911 incident occurred near you at <%= block_location %>. It was described as "<%= description %>" and has been cleared. <% if duration %>The incident remained open for <%= duration %>. <% end %>The general offense (GO) # is <%= general_offense_number %>.
ERB

opts = {
  path: '/seattle-pd-911-incidents',
  cache: SpyGlass::Cache::Memory.new,
  source: 'https://data.seattle.gov/resource/3k2p-39jp?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'event_clearance_date DESC',
    '$where' => <<-WHERE.oneline
      event_clearance_group != 'TRAFFIC RELATED CALLS' AND
      event_clearance_group != 'FALSE ALARMS' AND
      initial_type_description != 'DISTURBANCE, MISCELLANEOUS/OTHER' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      event_clearance_date IS NOT NULL AND
      event_clearance_description IS NOT NULL AND
      hundred_block_location IS NOT NULL
    WHERE
  })
}

class EventDuration
  include ActionView::Helpers::TextHelper

  def initialize(start, finish)
    @start = DateTime.parse(start)
    @finish = DateTime.parse(finish)
  end

  def to_s
    if hours > 0
      "#{pluralize(hours, 'hour')} #{pluralize(minutes, 'minute')}"
    else
      pluralize(minutes, 'minute')
    end
  end

  def minutes
    (duration_minutes % 60).round(0)
  end

  def hours
    duration_hours.round(0)
  end

  def duration_minutes
    duration_hours * 60
  end

  def duration_hours
    duration_days * 24
  end

  def duration_days
    (@finish - @start).to_f
  end
end

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    clearance_time = DateTime.parse(item['event_clearance_date']).
                              in_time_zone(time_zone).
                              strftime('%I:%M%p')

    general_offense_number = item['general_offense_number']
    block_location = item['hundred_block_location']
    description = item['event_clearance_description'].downcase
    duration = nil

    if at_scene_time = item['at_scene_time']
      duration = EventDuration.new(at_scene_time, item['event_clearance_date']).to_s
    end

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
      'properties' => item.merge('title' => title_template.result(binding).strip)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
