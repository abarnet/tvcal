require 'rest_client'
require 'digest'
require 'json'
require 'time'

# 21464560
# Orphan Black

# TWC
# 77689

class Search
  def initialize(credentials)
    @key = credentials['key']
    @shared_secret = credentials['shared_secret']
  end


  def seasons_info(series)
    series_id = series['id']

    begin
      seasons = RestClient.get 'http://api.rovicorp.com/data/v1.1/video/seasons', {
        :content_type => :json, :accept => :json,
        params: {
          cosmoid: series_id,
          format: "json",
          apikey: @key,
          sig: sig
        }
      }
    rescue => e
      return "Couldn't find seasons for series #{series_id}: " + e.response
    end
    seasons = JSON.parse seasons
    season_info = {}

    seasons['seasons'].each do |season|
      number = season['number']
      next if number == '0' || season["episodesUri"].nil?
      info = JSON.parse RestClient.get season["episodesUri"] + "&sig=#{sig}".to_str

      episodes_info = info['episodes']
      episodes = []

      episodes_info.each do |e|
        ep_number = e['number']
        episodes[ep_number.to_i - 1] = {
          'id' => /cosmoid=([0-9]+)/.match(e['episodeInfoUri'])[1],
                    'episode' => "#{ep_number}"
                }

          end
          season_info[number] = episodes

      end
#      series['seasons'] = season_info
      return season_info
  end

  def find_title(query)
    res = RestClient.get 'http://api.rovicorp.com/search/v2.1/video/search', {
      :content_type => :json, :accept => :json,
      params: {
        entitytype: "tvseries",
        query: query,
        language: "en",
        country: "US",
        format: "json",
        apikey: @key,
        sig: sig
      }
    }

    json = JSON.parse res.to_str
    first = json["searchResponse"]["results"][0]

    series_id = first['id']

    series = {'id' => "#{series_id}", 'title' => first["video"]["masterTitle"] }
    series['seasons'] = seasons_info series

    return series
    end

    private
    def sig
        timestamp = Time.now.to_i
        md5 = Digest::MD5.new
        md5 << "#{@key}#{@shared_secret}#{timestamp}"
        return md5.hexdigest        
    end
end
