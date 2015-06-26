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

class HTTP::Cookie < Hash(String, String)
  def initialize(@response)
    super()
  end

  def []=(key : String, value : String)
    # TODO: 转码
    cookie = "#{ key }=#{ value };"
    @response.headers.add("Set-cookie", cookie)
    super
  end
end

class HTTP::Response
  # 因为下面的init方法是覆盖的，所以无法在所有初始化方法里初始@cookie，只能预先初始占位
  @cookie = Hash(String, String).new

  def initialize(@status_code, @body = nil, @headers = Headers.new : Headers, status_message = nil, @version = "HTTP/1.1")
    @status_message = status_message || self.class.default_status_message_for(@status_code)

    if (body = @body)
      @headers["Content-length"] = body.bytesize.to_s
    end

    init_cookie() # 真正初始化@cookie
  end

  private def init_cookie()
    @cookie = Cookie.new(self)
  end
  def cookie
    @cookie
  end
end

