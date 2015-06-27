require "http/server"
require "./sparrow/*"
require "pg"

module Sparrow
  def self.run(port = 8080)
    static_server = HTTP::StaticFileHandler.new("./static")
    server = HTTP::Server.new(port) do |request|
      pp request.uri.path
      case request.uri.path
      when "/"
        Handler.home(request)
      else
        static_server.call(request)
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
