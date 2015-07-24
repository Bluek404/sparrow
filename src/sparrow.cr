require "http/server"
require "./sparrow/*"
require "pg"

module Sparrow
  def self.run(port = 8080)
    static_server = HTTP::StaticFileHandler.new("./static")
    server = HTTP::Server.new(port) do |request|
      time = Time.now
      begin
        path = request.uri.path as String
      rescue
        response = HTTP::Response.not_found
        path = request.path
      end
      response = case path
      when "/"
        Handler.home(request)
      when "/Eloim_Essaim_frugativi_et_appellavi"
        Handler.del_last_thread(request)
      else
        if result = /^(\/[0-9a-zA-Z]{2,16})$/.match(path)
          Handler.category(request, result[1], 1)
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/([0-9]+)$/.match(path)
          page = result[2].to_i
          Handler.category(request, result[1], page)
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/new$/.match(path)
          Handler.new_thread(request, result[1])
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/log$/.match(path)
          Handler.log(request, result[1], 1)
        elsif result = /^(\/[0-9a-zA-Z]{2,16})\/log\/([0-9]+)$/.match(path)
          page = result[2].to_i
          Handler.log(request, result[1], page)
        elsif result = /^\/t\/([0-9a-zA-Z]{1,16})$/.match(path)
          Handler.thread(request, result[1], 1)
        elsif result = /^\/t\/([0-9a-zA-Z]{1,16})\/([0-9]+)$/.match(path)
          page = result[2].to_i
          Handler.thread(request, result[1], page)
        elsif result = /^\/t\/([0-9a-zA-Z]{1,16})\/reply$/.match(path)
          Handler.new_thread(request, result[1])
        elsif result = /^\/s\/([0-9a-zA-Z]{1,16})\/$/.match(path)
          reason = request.uri.query
          Handler.sage_thread(request, result[1], reason)
        elsif result = /^\/d\/([0-9a-zA-Z]{1,16})\/$/.match(path)
          reason = request.uri.query
          Handler.del_thread(request, result[1], reason)
        elsif result = /^\/r\/([0-9a-zA-Z]{1,16})\/$/.match(path)
          reason = request.uri.query
          Handler.report(request, result[1], reason)
        elsif result = /^\/c\/([0-9a-zA-Z]{1,16})$/.match(path)
          Handler.close_report(request, result[1])
        elsif result = /^\/p\/([0-9a-zA-Z]{1,16})$/.match(path)
          Handler.preview(request, result[1])
        else
          static_server.call(request)
        end
      end unless response
      puts "#{ request.remote_ip }\t#{ request.method }\t#{ path }" \
        "\t#{ response.status_code }\t#{ (Time.now-time).milliseconds }ms"
      response
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
