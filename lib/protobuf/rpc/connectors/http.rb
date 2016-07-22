require "net/http"
require "uri"
require "protobuf/rpc/connectors/base"

module Protobuf
  module Rpc
    module Connectors
      class HTTP < Base
        include Protobuf::Rpc::Connectors::Common

        def send_request
          setup_connection
          send_using_http
          parse_response
        end

      private

        def close_connection
          # no-op
        end

        def continue_timeout
          return @continue_timeout_value if @continue_timeout
          @continue_timeout_value = begin
            case
            when options[:continue_timeout]
              options[:continue_timeout]
            when ENV.key?("PB_HTTP_CLIENT_CONTINUE_TIMEOUT")
              ENV["PB_HTTP_CLIENT_CONTINUE_TIMEOUT"].to_f / 1000
            else
              # Ruby socket will default this to nil.
              nil
            end
          end
          @continue_timeout = true
          @continue_timeout_value
        end

        def open_timeout
          @open_timeout ||= begin
            case
            when options[:open_timeout]
              options[:open_timeout]
            when ENV.key?("PB_HTTP_CLIENT_OPEN_TIMEOUT")
              ENV["PB_HTTP_CLIENT_OPEN_TIMEOUT"].to_f / 1000
            else
              5
            end
          end
        end

        def read_timeout
          @read_timeout ||= begin
            case
            when options[:read_timeout]
              options[:read_timeout]
            when ENV.key?("PB_HTTP_CLIENT_READ_TIMEOUT")
              ENV["PB_HTTP_CLIENT_READ_TIMEOUT"].to_f / 1000
            else
              300
            end
          end
        end

        def send_using_http
          uri = URI.parse("http://#{options[:host]}:#{options[:port]}/")
          http = Net::HTTP.new(uri.host, uri.port)
          http.continue_timeout = continue_timeout
          http.open_timeout = open_timeout
          http.read_timeout = read_timeout
          request = Net::HTTP::Post.new("/")
          request.body = @request_data
          response = http.request(request)
          @response_data = response.body
        end

      end
    end
  end
end
