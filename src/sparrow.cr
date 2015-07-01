require "http/server"
require "./sparrow/*"
require "pg"

module Sparrow
  def self.run(port = 8080)
    static_server = HTTP::StaticFileHandler.new("./static")
    server = HTTP::Server.new(port) do |request|
      path = request.uri.path as String
      pp path
      case path
      when "/"
        Handler.home(request)
      else
        if result = /^(\/[0-9a-zA-Z]{2,16})$/.match(path)
          Handler.category(request, result[1], 1)
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/([0-9]+)$/.match(path)
          page = result[2].to_i
          Handler.category(request, result[1], page)
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/new$/.match(path)
          Handler.new_thread(request, result[1])
        elsif result = /^\/t\/([0-9a-zA-Z]{1,16})$/.match(path)
          Handler.thread(request, result[1], 1)
        elsif result = /^\/t\/([0-9a-zA-Z]{1,16})\/([0-9]+)$/.match(path)
          page = result[2].to_i
          Handler.thread(request, result[1], page)
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
