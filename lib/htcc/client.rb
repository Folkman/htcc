# frozen_string_literal: true

require 'net/http'
require 'json'

module HTCC
  class Client
    BASE_URL = 'https://mytotalconnectcomfort.com/portal'.freeze
    HEADERS  = { 'X-Requested-With': 'XMLHttpRequest' }.freeze

    attr_reader :devices

    def initialize(username, password, debug: false, debug_output: nil)
      @debug = debug
      @debug_output = nil
      @devices = []
      login(username, password)
      get_devices if logged_in?
    end

    def debug=(val)
      @debug = val
    end

    def logged_in?
      @logged_in
    end

    def refresh_devices
      @devices = []
      get_devices
    end

    private

    def get_devices
      resp = request(
        '/Location/GetLocationListData',
        method: 'post',
        data: { 'page' => '1', 'filter' => '' }
      )
      locations = ::JSON.parse(resp.body)
      @devices = locations.flat_map { |loc| loc['Devices'] }
      @devices.map! do |device|
        case device['DeviceType']
        when 24
          Thermostat.new(device, self)
        else # Other devices?
          Thermostat.new(device, self)
        end
      end
    end

    def login(username, password)
      resp = request(method: 'post', data: {
        'UserName': username, 'Password': password, 'timeOffset': '240', 'RememberMe': 'false'
      })
      @cookies = get_cookies(resp)
      @logged_in = resp.get_fields('content-length')[0].to_i < 25 # Successful login
    end

    def get_cookies(response)
      response.get_fields('set-cookie')
              .map { |c| cookie = c.split(/;|,/)[0]; cookie.split('=')[1] ? cookie : nil }
              .compact
              .join(';')
    end

    def request(path = '', method: 'get', data: nil, headers: {})
      uri = URI("#{BASE_URL}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.set_debug_output(@debug_output || $stdout) if @debug
      klass = method == 'get' ? Net::HTTP::Get : Net::HTTP::Post
      request = klass.new(uri.request_uri, HEADERS.merge(headers))
      request['Cookie'] = @cookies if @cookies
      request.set_form_data(data) if data
      http.request(request)
    end
  end
end
