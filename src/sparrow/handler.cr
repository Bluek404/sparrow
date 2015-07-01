require "secure_random"

module Sparrow::Handler
  extend self

  private def self.gen_random_key
    SecureRandom.hex(64)
  end
  private def new_user()
    result = DB.exec({String}, "SELECT id FROM last_id WHERE name = 'user' LIMIT 1")
    last_id = result.rows[0][0]
    id = Base62.encode(Base62.decode(last_id) + 1)
    DB.exec("UPDATE last_id SET id = $1::text WHERE name = 'user' LIMIT 1", [id])
    key = gen_random_key()
    DB.exec("INSERT INTO users VALUES ($1::text, $2::text)", [id, key])
    {id, key}
  end
  private def check_cookie(cookie)
    if cookie.length == 2
      id, key = cookie[0], cookie[1]
      result = DB.exec({String}, "SELECT key FROM users WHERE id = $1::text LIMIT 1", [id])
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
  private def get_last_page(parent)
    rows = DB.exec({Int32}, "SELECT COUNT(*) FROM threads WHERE  parent = $1::text",
                   [parent]).rows[0][0]
    last_page = rows/20
    last_page += 1 if last_page%20 != 0
    last_page
  end
  private def gen_pagination(current_page, last_page)
    begin_page = current_page - 4
    end_page = current_page + 4
    if begin_page < 1
      end_page = end_page - (begin_page - 1)
      begin_page = 1
      end_page = last_page if end_page > last_page
    elsif end_page > last_page
      begin_page = begin_page - (end_page - last_page)
      end_page = last_page
      begin_page = 1 if begin_page < 1
    end
    begin_page..end_page
  end
  def home(request)
    categories = DB.exec({String, String} ,"SELECT id, name FROM categories").rows
    HTTP::Response.ok("text/html", View::Home.new(categories).to_s)
  end
  def category(request, category_id, page)
    category = DB.exec({String, String, String},
                       "SELECT name, admin, rule FROM categories WHERE id = $1::text LIMIT 1",
                       [category_id]).rows
    if category.length == 0
      return HTTP::Response.not_found
    end
    category = category[0]
    threads = DB.exec({String, String, String, Int32},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text AND sage = FALSE
                       ORDER BY modified DESC LIMIT #{ page*20 } OFFSET #{ (page-1)*20 }",
                      [category_id]).rows
    replies = Array(Array({String, String, String, Int32})).new()
    threads.each do |thread|
      thread_id = thread[0]
      # 获取最后 5 个回复
      # 为了性能所以先倒序获取最后 5 个然后反转过来
      reply = DB.exec({String, String, String, Int32},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text AND sage = FALSE
                       ORDER BY time DESC LIMIT 5",
                      [thread_id]).rows.reverse
      replies << reply
    end
    pagination = gen_pagination(page, get_last_page(category_id))
    HTTP::Response.ok("text/html", View::Category.new(category_id, category, threads, replies, page, pagination).to_s)
  end
  def new_thread(request, category)
    category = DB.exec("SELECT name FROM categories WHERE id = $1::text LIMIT 1",
                       [category]).rows
    if category.length == 0
      return HTTP::Response.not_found
    end
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
