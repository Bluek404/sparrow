require "ecr/macros"

module Sparrow::View
  ViewFileDir = "./src/view/"
  class Home
    def initialize(@categories)
    end
    ecr_file(ViewFileDir + "home.ecr")
  end
  class Category
    def initialize(@category_id, @category, @threads, @replies, @page, @pagination)
    end
    ecr_file(ViewFileDir + "category.ecr")
  end
  class Thread
    def initialize(@category_name, @thread_id, @thread, @replies, @page, @pagination)
    end
    ecr_file(ViewFileDir + "thread.ecr")
  end
end
