class HTTP::Request
  @cookie = Hash(String, String).new
  def initialize(@method : String, @path, @headers = Headers.new : Headers, @body = nil, @version = "HTTP/1.1")
    if body = @body
      @headers["Content-length"] = body.bytesize.to_s
    elsif @method == "POST" || @method == "PUT"
      @headers["Content-length"] = "0"
    end
    parse_cookie()
  end

  private def parse_cookie()
    if @headers.has_key?("Cookie")
      @headers["Cookie"].split(';').each do |value|
        kv = value.split('=')
        next if kv.length != 2
        @cookie[kv[0]] = kv[1]
      end
    end
  end

  def cookie
    @cookie
  end
end

class HTTP::Response
  def set_cookie(key : String, value : String, expires = nil, domain = nil, path = nil, secure = false, httponly = false)
    # TODO: 转码
    cookie = "#{ key }=#{ value }"
    cookie += ";expires=#{ expires }" if expires
    cookie += ";domain=#{ domain }" if domain
    cookie += ";path=#{ path }" if path
    cookie += ";secure" if secure
    cookie += ";httponly" if httponly
    @headers.add("Set-cookie", cookie)
  end
end

