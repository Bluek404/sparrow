module Sparrow::Handler
  extend self

  private def new_id()
    "test"
  end
  private def check_cookie(request, response)
    if request.cookie.has_key?("id") && request.cookie.has_key?("key")
      pp request.cookie
    else
      id = new_id()
      response.set_cookie("id", id)
      response.set_cookie("key", "key")
    end
  end

  def home(request)
    response = HTTP::Response.new(200, View::Home.new.to_s)
    check_cookie(request, response)
    response
  end
end
