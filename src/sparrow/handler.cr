require "cgi"
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
    DB.exec("UPDATE last_id SET id = $1::text WHERE name = 'user'", [id])
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
  private def get_rows_num(parent)
    DB.exec({Int32}, "SELECT COUNT(*) FROM threads WHERE  parent = $1::text",
            [parent]).rows[0][0]
  end
  private def rows_to_pages(rows)
    page = rows/20
    page += 1 if page%20 != 0
    page = 1 if page == 0
    page
  end
  private def get_last_page(parent)
    rows_to_pages(get_rows_num(parent))
  end
  private def get_thread_id
    last_id = DB.exec({String}, "SELECT id FROM last_id WHERE name = 'threads' LIMIT 1").rows[0][0]
    id = Base62.encode(Base62.decode(last_id) + 1)
    DB.exec("UPDATE last_id SET id = $1::text WHERE name = 'threads'", [id])
    id
  end
  private def save_thread(id, author, author_ip, content, parent)
    DB.exec("INSERT INTO threads
             VALUES ($1::text, $2::text, $3::text, $4::text, $5::text)",
            [id, author, author_ip, content, parent])
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
    last_page = get_last_page(category_id)
    if page > last_page || page < 1
      return HTTP::Response.not_found
    end
    threads = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY modified DESC LIMIT #{ page*20 } OFFSET #{ (page-1)*20 }",
                      [category_id]).rows
    category_data = Array(Tuple({String, String, String, Time}, Array({String, String, String, Time}), Int32)).new()

    threads.each do |thread|
      thread_id = thread[0]
      # 获取最后 5 个回复
      reply_num = get_rows_num(thread_id)
      reply = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY time LIMIT #{ reply_num } OFFSET #{ reply_num-5<0 ? 0 : reply_num-5 }",
                      [thread_id]).rows
      category_data << {thread, reply, reply_num}
    end
    HTTP::Response.ok("text/html",
                      View::Category.new(category_id, category, category_data, page, last_page).to_s)
  end
  def new_thread(request, parent_id)
    if request.method != "POST"
      return HTTP::Response.new(405,
                                HTTP::Response.default_status_message_for(405))
    end

    query = CGI.parse(request.body as String)
    if !query["content"]? || query["content"][0].length < 3 ||
      query["content"][0].length > 1024 || query["content"][0] =~ /^[\s]*$/
      return HTTP::Response.new(400,
                                HTTP::Response.default_status_message_for(400))
    end

    is_reply? = parent_id[0] == '/' ? false : true

    parent_exist? = if is_reply?
      thread = DB.exec({String}, "SELECT parent FROM threads WHERE id = $1::text LIMIT 1",
                       [parent_id]).rows
      if thread.length == 0
        false
      else
        thread_parent = thread[0][0]
        # 检查父级别是否为分类, 用以知道是否为一个单独的串
        thread_parent[0] == '/' ? true : false
      end
    else
      category = DB.exec("SELECT name FROM categories WHERE id = $1::text LIMIT 1",
                       [parent_id]).rows
      category.length == 0 ? false : true
    end
    unless parent_exist?
      return HTTP::Response.not_found
    end

    cookie = get_cookie(request)
    thread_id = get_thread_id()
    if is_reply?
      last_page = rows_to_pages(get_rows_num(parent_id)+1)
      header = HTTP::Headers{"Location": "/t/#{ parent_id }/#{ last_page }##{ thread_id }"}
    else
      header = HTTP::Headers{"Location": "/t/#{ thread_id }"}
    end
    response = HTTP::Response.new(302, nil, header)
    unless cookie && check_cookie(cookie)
      cookie = new_user()

      # 十年后
      time = Time.now + TimeSpan.new(3650, 0, 0, 0)
      response.set_cookie("id", cookie[0], time, nil, "/",nil, true)
      response.set_cookie("key", cookie[1], time, nil, "/",nil, true)
    end
    save_thread(thread_id , cookie[0], request.remote_ip, query["content"][0], parent_id)
    DB.exec("UPDATE users SET last_thread = $1::text WHERE id = $2::text",
            [thread_id, cookie[0]])
    if is_reply?
      DB.exec("UPDATE threads SET modified = now() WHERE id = $1::text", [parent_id])
    end
    response
  end
  def thread(request, thread_id, page)
    thread = DB.exec({String, String, String, Time},
                      "SELECT author, content, parent, time FROM threads
                       WHERE id = $1::text
                       ORDER BY modified DESC LIMIT 1",
                      [thread_id]).rows
    if thread.length == 0
      return HTTP::Response.not_found
    end
    thread = thread[0]
    last_page = get_last_page(thread_id)
    if page > last_page || page < 1
      return HTTP::Response.not_found
    end

    # 根据回复的 ID 找到所在串的功能:
    if thread[2][0] != '/' # 不是 / 开头的，所以不是一个串而是一个串的回复
      # 查找这个回复所属的串
      reply = thread
      reply_id = thread_id
      parent = reply[2]
      # 获取这个回复是串里的第几行
      where_row = DB.exec({Int32}, "SELECT get_reply_where_row($1::text,$2::text)",
                          [parent, reply_id]).rows
      where_row = where_row[0][0]
      # 获得这个回复所处的页数
      where_page = rows_to_pages(where_row)
      # 转跳到这个回复所在的串和页数
      return HTTP::Response.new(302, nil,
                                HTTP::Headers{"Location": "/t/#{ parent }/#{ where_page }##{ reply_id }"})
    end

    category_name = DB.exec({String}, "SELECT name FROM categories WHERE id = $1::text LIMIT 1",
                       [thread[2]]).rows[0][0]
    replies = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY time LIMIT #{ page*20 } OFFSET #{ (page-1)*20 }",
                      [thread_id]).rows
    HTTP::Response.ok("text/html",
                      View::Thread.new(category_name, thread_id, thread, replies, page, last_page).to_s)
  end
  def del_last_thread(request)
    cookie = get_cookie(request)
    if cookie && check_cookie(cookie)
      user_id = cookie[0]
      last_thread = DB.exec({String},
                            "SELECT last_thread FROM users WHERE id = $1::text",
                            [user_id]).rows[0][0]
      if last_thread != ""
        DB.exec("DELETE FROM threads WHERE id = $1::text", [last_thread])
        DB.exec("UPDATE users SET last_thread = '' WHERE id = $1::text", [user_id])
        HTTP::Response.ok("text/html", "OK")
      else
        HTTP::Response.new(403, "没有可以删除的串")
      end
    else
      HTTP::Response.new(403,
                         HTTP::Response.default_status_message_for(403))
    end
  end
end
