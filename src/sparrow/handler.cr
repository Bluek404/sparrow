module Sparrow::Handler
  extend self

  private def new_id()
    "test"
  end
  private def check_cookie(request, response)
    pp request.headers
    if request.cookie.has_key?("key")
      # ...
    else
      id = new_id()
      response.cookie["id"] = id
    end
    pp response.headers
  end

  def home(request)
    response = HTTP::Response.new(200, View::Home.new.to_s)
    check_cookie(request, response)
    response
  end
end
