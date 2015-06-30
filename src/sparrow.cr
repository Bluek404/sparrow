require "http/server"
require "./sparrow/*"
require "pg"

module Sparrow
  def self.run(port = 8080)
    static_server = HTTP::StaticFileHandler.new("./static")
    server = HTTP::Server.new(port) do |request|
      path = request.uri.path as String
      case path
      when "/"
        Handler.home(request)
      else
        if result = /^(\/[0-9a-zA-Z]+)$/.match(path)
          Handler.category(request, result[1])
        elsif result = /^(\/[0-9a-zA-Z]+)\/new$/.match(path)
          Handler.new_topic(request, result[1])
        else
          static_server.call(request)
        end
      end
    end

    puts "Listening on http://0.0.0.0:#{ port }"
    server.listen
  end
end

if ARGV.length >= 1
  if ARGV[0] == "init"
    Sparrow.init_db()
  end
end
Sparrow.run()
