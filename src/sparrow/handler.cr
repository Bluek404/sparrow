require "secure_random"

module Sparrow::Handler
  extend self

  private def self.gen_random_key
    SecureRandom.hex(64)
  end
  private def new_user()
    result = DB.exec({String}, "SELECT id FROM last_id WHERE name = 'user'")
    last_id = result.rows[0][0]
    id = Base62.encode(Base62.decode(last_id) + 1)
    DB.exec("UPDATE last_id SET id = '#{ id }' WHERE name = 'user'")
    key = gen_random_key()
    DB.exec %{INSERT INTO users VALUES ('#{ id }', '#{ key }')}
    {id, key}
  end
  private def check_cookie(request, response)
    if request.cookie.has_key?("id") && request.cookie.has_key?("key")
      pp request.cookie
    else
      id_key = new_user()
      pp request.cookie.has_key?("id")
      pp request.cookie.has_key?("key")
      response.set_cookie("id", id_key[0], nil, nil, nil,nil, true)
      response.set_cookie("key", id_key[1], nil, nil, nil,nil, true)
    end
  end

  def home(request)
    response = HTTP::Response.new(200, View::Home.new.to_s)
    check_cookie(request, response)
    response
  end
end
