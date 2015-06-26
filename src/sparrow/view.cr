require "ecr/macros"

module Sparrow::View
  ViewFileDir = "./src/view/"
  class Home
    def initialize()
    end
    ecr_file(ViewFileDir + "home.ecr")
  end
end
