module Sparrow::Handler
  extend self

  def home(request)
    HTTP::Response.ok("text/html", View::Home.new.to_s)
  end
end
