require "net/http"

module SchaleDB
  class Data
    HOST = "https://raw.githubusercontent.com/SchaleDB/SchaleDB/main"

    def self.students
      get("data/kr/students.min.json")
    end

    def self.stages
      get("data/kr/stages.min.json")
    end

    def self.items
      get("data/kr/items.min.json")
    end

    private

    def self.get(path)
      address = "#{HOST}/#{path}"
      Rails.logger.info("[SchaleDB::Data] GET #{address}")
      uri = URI(address)
      JSON.parse(Net::HTTP.get(uri))
    end
  end
end
