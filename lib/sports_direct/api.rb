require 'httparty'
require 'nokogiri'

module SportsDirect
  class API
    Error = Class.new(StandardError)
    Timeout = Class.new(Error)
    Unauthorized = Class.new(Error)

    include HTTParty

    base_uri 'http://xml.sportsdirectinc.com/sport/v2'
    parser lambda { |body, format| Nokogiri.XML(body) }

    if ENV['SPORTS_DIRECT_PROXY']
      http_proxy *ENV['SPORTS_DIRECT_PROXY'].split(':')
    end

    class << self
      def ncaa_basketball_schedule
        get('/basketball/NCAAB/schedule/schedule_NCAAB.xml')
      end

      def ncaa_basketball_teams(season)
        get("/basketball/NCAAB/teams/#{season}/teams_NCAAB.xml")
      end

      def get(*args)
        response = super

        case response.code
          when 401
            raise Unauthorized.new(response.at('h2').text.split(': ').last)
          when 403
            raise Unauthorized.new(response.at('head/title').text)
          else
            response
        end
      rescue Errno::ECONNRESET
        raise Error.new($!.message)
      rescue Errno::ETIMEDOUT
        raise Timeout.new($!.message)
      end
    end
  end
end
