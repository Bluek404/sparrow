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
        @cookie[kv[0].strip] = kv[1].strip
      end
    end
  end

  def cookie
    @cookie
  end
end

class HTTP::Response
  CookieTime = TimeFormat.new("%a, %d %b %Y %H:%M:%S GMT")
  private def format_cookie_time(time)
    CookieTime.format(time)
  end
  def set_cookie(key, value, expires = nil, domain = nil, path = nil, secure = false, httponly = false)
    # TODO: 转码
    cookie =  "#{ key }=#{ value }"
    cookie += ";expires=#{ format_cookie_time(expires) }" if expires
    cookie += ";domain=#{ domain }"                       if domain
    cookie += ";path=#{ path }"                           if path
    cookie += ";secure"                                   if secure
    cookie += ";httponly"                                 if httponly
    @headers.add("Set-cookie", cookie)
  end
end

