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
      id = request.cookie["id"] as String
      key = request.cookie["key"] as String
      result = DB.exec({String}, "SELECT key FROM users WHERE id = $1::text", [id])
      if result.rows.length != 0
        if result.rows[0][0] == key
          return
        end
      end

      # 身份验证失败，当作新用户
      request.cookie.delete("key")
      check_cookie(request, response)
    else
      id_key = new_user()
      # 十年后
      time = Time.now + TimeSpan.new(3650, 0, 0, 0)
      response.set_cookie("id", id_key[0], time, nil, nil,nil, true)
      response.set_cookie("key", id_key[1], time, nil, nil,nil, true)
    end
  end

  def home(request)
    response = HTTP::Response.new(200, View::Home.new.to_s)
    check_cookie(request, response)
    response
  end
end
