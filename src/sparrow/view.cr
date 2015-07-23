require "ecr/macros"

module Sparrow::View
  def self.gen_pagination(current_page, last_page)
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
  ViewFileDir = "./src/view/"
  class Farme
    def initialize(@title, @category_id, @body)
      @categories = DB.exec({String, String} ,"SELECT id, name FROM categories").rows
    end
    ecr_file(ViewFileDir + "farme.ecr")
  end
  class Home
    class Body
      def initialize()
      end
      ecr_file(ViewFileDir + "home.ecr")
    end
    def initialize()
      @body = Body.new()
    end
    def to_s()
      Farme.new("匿名版", "", @body).to_s
    end
  end
  class Category
    class Body
      def initialize(@category_id, @category, @data, @page, @last_page, @is_admin)
        @pagination = View.gen_pagination(@page, @last_page)
      end
      ecr_file(ViewFileDir + "category.ecr")
    end
    def initialize(@category_id, category, data, page, last_page, is_admin)
      @category_name = category[0]
      @body = Body.new(@category_id, category, data, page, last_page, is_admin)
    end
    def to_s()
      Farme.new(@category_name, @category_id, @body).to_s
    end
  end
  class Thread
    class Body
      def initialize(@category_name, @thread_id, @thread, @replies, @page, @last_page, @is_admin)
        @pagination = View.gen_pagination(@page, @last_page)
      end
      ecr_file(ViewFileDir + "thread.ecr")
    end
    def initialize(@category_name, @thread_id, thread, replies, page, last_page, is_admin)
      @category_id = thread[2]
      @body = Body.new(@category_name, @thread_id, thread, replies, page, last_page, is_admin)
    end
    def to_s()
      Farme.new("No.#{ @thread_id } —— #{ @category_name }", @category_id, @body).to_s
    end
  end
  class Log
    class Body
      def initialize(@category_id, @category_name, @reports, @logs, @page, @last_page, @is_admin)
        @pagination = View.gen_pagination(@page, @last_page)
      end
      ecr_file(ViewFileDir + "log.ecr")
    end
    def initialize(category_id, @category_name, reports, logs, page, last_page, is_admin)
      @body = Body.new(category_id, @category_name, reports, logs, page, last_page, is_admin)
    end
    def to_s()
      Farme.new("#{ @category_name } 管理记录", @category_id, @body).to_s
    end
  end
end
