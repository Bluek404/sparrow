require "ecr/macros"

module Sparrow::View
  ViewFileDir = "./src/view/"
  class Home
    def initialize(@categories)
    end
    ecr_file(ViewFileDir + "home.ecr")
  end
  class Category
    def initialize(@category)
    end
    ecr_file(ViewFileDir + "category.ecr")
  end
end
