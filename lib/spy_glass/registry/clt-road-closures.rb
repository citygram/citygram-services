require 'spy_glass/registry'

opts = {
  path: '/clt-road-closures',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://clt-charlotte.opendata.arcgis.com/datasets/32526cecacdc4802bbacbdd76f246896_0.geojson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  include ActionView::Helpers::TextHelper
  features = body["features"].map do |record|
    attrs = record["properties"]
    # next if attrs["Type"].nil?
    #     oid = attrs["Petition"]
    #     petition = attrs["Petition"]
    #     petitioner = attrs["Petitioner"]
    #     from_zone = attrs["ExistZone"]
    #     to_zone = attrs["ReqZone"]
    #     r_type = attrs["Type"].downcase if attrs["Type"]
    #     title = <<-TITLE.oneline.gsub(/\.\.\.\./, '...')
    #       #{SpyGlass::Salutations.next} #{petitioner} filed a #{r_type} rezoning request from #{from_zone} to #{to_zone}.
    #       Learn more: #{attrs['Hyperlink']}
    #     TITLE

    # {
    #   'id' => record['properties']["OBJECTID"],
    #   'type' => 'Feature',
    #   'properties' => attrs.merge('title' => title),
    #   'geometry' => record["geometry"]
    # }
    # closure_descr = attrs["BLOCKNM"]
    # closure_comment = attrs["COMMENT_"]
    # create_date = attrs["CreationDate"]
    # start_date = attrs["STARTDATE"]
    # end_date = attrs["ENDDATE"]
    # title = "not sure"
    # if Date.today > end_date
    #   title = "inert"
    # elsif Date.today == (start_date - 1)
    #   title = "starting"
    # elsif
    # end
    oid = attrs["OBJECTID"]
    start_date_attr = attrs["STARTDATE"]
    end_date_attr = attrs["ENDDATE"]
    next if start_date_attr.nil? || end_date_attr.nil?
    blockage = attrs["BLOCKTYPE"]
    loc = attrs["BLOCKNM"]
    loc_desc = attrs["LOCDESC"]
    start_date = Date.parse(start_date_attr)
    end_date = Date.parse(end_date_attr)
    duration = (end_date - start_date).to_i+1
    title = if blockage.nil?
      "#{loc} will close roads in your area on #{start_date} for #{pluralize(duration, 'day')}"
    else
      "#{blockage} will close #{loc} #{loc_desc} on #{start_date} for #{pluralize(duration, 'day')}"
    end

    if Date.today > end_date
      status = "reopened"
      title = "#{loc} #{loc_desc} was scheduled to reopen on #{end_date} after a closure of #{pluralize(duration, 'day')}"
    elsif Date.today >= (start_date - 1)
      status = "closed"
      title = "[CLOSED] #{title}"
    elsif Date.today < start_date
      status = 'announced'
    end
    oid = "#{oid}-#{status}"
    {
      'id' => oid,
      'type' => 'Feature',
      'properties' => attrs.merge('title' => title, 'status' => status),
      'geometry' => record["geometry"]
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.reject{ |f| f.nil? } }
end
