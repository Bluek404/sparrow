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
  class Home
    def initialize(@categories)
    end
    ecr_file(ViewFileDir + "home.ecr")
  end
  class Category
    def initialize(@category_id, @category, @data, @page, @last_page, @is_admin)
      @pagination = View.gen_pagination(@page, @last_page)
    end
    ecr_file(ViewFileDir + "category.ecr")
  end
  class Thread
    def initialize(@category_name, @thread_id, @thread, @replies, @page, @last_page, @is_admin)
      @pagination = View.gen_pagination(@page, @last_page)
    end
    ecr_file(ViewFileDir + "thread.ecr")
  end
  class Log
    def initialize(@category_id, @category_name, @reports, @logs, @page, @last_page, @is_admin)
      @pagination = View.gen_pagination(@page, @last_page)
    end
    ecr_file(ViewFileDir + "log.ecr")
  end
end
