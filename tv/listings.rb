require 'rest_client'
require 'json'
require 'time'

# 21464560
# Orphan Black

# TWC
# 77689


class Listings
  def initialize(key)
    @key = key
  end

  FIELDS = [
    "ProgramId", "Title", "EpisodeTitle", "Copy",
    "AiringType", "AiringTime", "Duration",
    "Channel", "CallLetters", "SourceDisplayName", "SourceLongName"
  ]

  def airings(series)

    series_id = series['id']
    service = "77689"


    all_airings = []

    [Time.now, Time.now + 14 * 24 * 60 * 60].each do |start_date|


      begin
        res = RestClient.get "http://api.rovicorp.com/TVlistings/v9/listings/programdetails/#{service}/#{series_id}/info", {
          :content_type => :json, :accept => :json,
          params: {
            startdate: start_date.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
            locale: "en-US",
            copytextformat: "PlainText",
            include: "Program",
            page: 0,
            duration: "20160",
            imagecount: "5",
            inprogress: "true",
            format: "json",
            apikey: @key
          }
        }
      rescue => e
        puts "error fetching airings"
        puts e
        return []
      end

      json = JSON.parse res.to_str

      details = json["ProgramDetailsResult"]
      if details["Schedule"].nil?
        raise "Series id not found"
      end

      airings = details["Schedule"]["Airings"]
      newAirings = airings.select {|a| a["AiringType"] == "New"}
      all_airings += newAirings.map do |a|
        data = {}

        FIELDS.each {|f| data[f] = a[f]}

        data['AiringTime'] = Time.strptime(data['AiringTime'], '%Y-%m-%dT%H:%M:%S%z')
        data['id'] = data["ProgramId"]
        data['last_fetch'] = Time.now
        data['series_id'] = series_id
        latest_season = series['seasons'].keys.map {|s| s.to_i}.max
        series['seasons'].each do |s_num, s|
          s.each do |e|
            if e['id'] == data['id']
              data['season'] = s_num
              data['episode'] = e['episode']
              unless s_num.to_i == latest_season.to_i
                data['AiringType'] = 'OldSeason'
                data['debug'] = "s_num: '#{s_num}', latest_season: '#{latest_season}', season_keys: '#{series['seasons'].keys}'"
              end
            end
          end
        end

        data
      end
    end

    return all_airings
  end
end
