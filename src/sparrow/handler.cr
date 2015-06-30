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
    DB.exec("UPDATE last_id SET id = $1::text WHERE name = 'user'", [id])
    key = gen_random_key()
    DB.exec("INSERT INTO users VALUES ($1::text, $2::text)", [id, key])
    {id, key}
  end
  private def check_cookie(cookie)
    if cookie.length == 2
      id, key = cookie[0], cookie[1]
      result = DB.exec({String}, "SELECT key FROM users WHERE id = $1::text", [id])
      if result.rows.length != 0
        if result.rows[0][0] == key
          return true
        end
      end
    end
    false
  end
  private def get_cookie(request)
    if request.cookie.has_key?("id") && request.cookie.has_key?("key")
      id = request.cookie["id"] as String
      key = request.cookie["key"] as String
      return {id, key}
    end
  end

  def home(request)
    categories = DB.exec({String, String} ,"SELECT id, name FROM categories").rows
    HTTP::Response.ok("text/html", View::Home.new(categories).to_s)
  end
  def category(request, category)
    category = DB.exec({String, String, String},
                       "SELECT name, admin, rule FROM categories WHERE id = $1::text",
                       [category]).rows
    if category.length == 0
      return HTTP::Response.not_found
    end
    category = category[0]
    HTTP::Response.ok("text/html", View::Category.new(category).to_s)
  end
  def new_topic(request, category)
    cookie = get_cookie(request)
    if cookie && check_cookie(cookie)
      HTTP::Response.ok("text/html", "id = #{ cookie[0] }, key = #{ cookie[1] }")
    else
      cookie = new_user()
      id, key = cookie[0], cookie[1]
      response = HTTP::Response.ok("text/html", "new_id = #{ cookie[0] }, new_key = #{ cookie[1] }")

      # 十年后
      time = Time.now + TimeSpan.new(3650, 0, 0, 0)
      response.set_cookie("id", id, time, nil, "/",nil, true)
      response.set_cookie("key", key, time, nil, "/",nil, true)
      response
    end
  end
end
