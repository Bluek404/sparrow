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
  private def get_last_page(parent)
    rows = DB.exec({Int32}, "SELECT COUNT(*) FROM threads WHERE  parent = $1::text",
                   [parent]).rows[0][0]
    last_page = rows/20
    last_page += 1 if last_page%20 != 0
    last_page = 1 if last_page = 0
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
    pagination = gen_pagination(page, last_page)
    threads = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY modified DESC LIMIT #{ page*20 } OFFSET #{ (page-1)*20 }",
                      [category_id]).rows
    replies = Array(Array({String, String, String, Time})).new()
    threads.each do |thread|
      thread_id = thread[0]
      # 获取最后 5 个回复
      # 为了性能所以先倒序获取最后 5 个然后反转过来
      reply = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY time DESC LIMIT 5",
                      [thread_id]).rows.reverse
      replies << reply
    end
    HTTP::Response.ok("text/html",
                      View::Category.new(category_id, category, threads, replies, page, pagination).to_s)
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
    if is_reply?
      rows = DB.exec({Int32}, "SELECT COUNT(*) FROM threads WHERE  parent = $1::text",
                     [parent_id]).rows[0][0] + 1
      last_page = rows/20
      last_page += 1 if last_page%20 != 0
      last_page = 1 if last_page == 0
      header = HTTP::Headers{"Location": "/t/#{ parent_id }/#{ last_page }"}
    else
      header = HTTP::Headers{"Location": "#{ parent_id }"}
    end
    response = HTTP::Response.new(302, nil, header)
    unless cookie && check_cookie(cookie)
      cookie = new_user()

      # 十年后
      time = Time.now + TimeSpan.new(3650, 0, 0, 0)
      response.set_cookie("id", cookie[0], time, nil, "/",nil, true)
      response.set_cookie("key", cookie[1], time, nil, "/",nil, true)
    end
    save_thread(get_thread_id(), cookie[0], request.remote_ip, query["content"][0], parent_id)
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
    pagination = gen_pagination(page, last_page)

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
      where_page = where_row/20
      where_page += 1 if where_row%20 != 0
      where_page = 1 if where_page = 0
      # 转跳到这个回复所在的串和页数
      return HTTP::Response.new(302, nil,
                                HTTP::Headers{"Location": "/t/#{ parent }/#{ where_page }##{ reply_id }"})
    end

    category_name = DB.exec({String}, "SELECT name FROM categories WHERE id = $1::text LIMIT 1",
                       [thread[2]]).rows[0][0]
    replies = DB.exec({String, String, String, Time},
                      "SELECT id, author, content, time FROM threads
                       WHERE parent = $1::text
                       ORDER BY time DESC LIMIT #{ page*20 } OFFSET #{ (page-1)*20 }",
                      [thread_id]).rows
    HTTP::Response.ok("text/html", View::Thread.new(category_name, thread_id, thread, replies, page, pagination).to_s)
  end
end
