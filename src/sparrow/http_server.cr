require "http/server"

class HTTP::Request
  def remote_ip
    return @remote_ip
  end
  def remote_ip=(ip)
    @remote_ip = ip
  end
end

class HTTP::Server
  private def handle_client(sock)
    sock.sync = false
    io = sock
    io = ssl_sock = OpenSSL::SSL::Socket.new(io, :server, @ssl.not_nil!) if @ssl

    begin
      until @wants_close
        begin
          request = HTTP::Request.from_io(io)
        rescue
          # HACK: these lines can be removed once #171 is
          # fixed
          ssl_sock.try &.close if @ssl
          sock.close

          return
        end
        break unless request
        request.remote_ip = sock.addr.ip_address
        response = @handler.call(request)
        response.headers["Connection"] = "keep-alive" if
        request.keep_alive?
        response.to_io io
        sock.flush

        if upgrade_handler =
          response.upgrade_handler
          return
          upgrade_handler.call(io)
        end

        break unless
        request.keep_alive?
      end
    ensure
      ssl_sock.try &.close if @ssl
      sock.close
    end
  end
end
