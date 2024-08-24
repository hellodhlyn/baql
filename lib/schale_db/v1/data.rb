require "net/http"

module SchaleDB::V1
  class Data
    HOST = "https://schaledb.com"

    def self.students
      get("data/kr/students.min.json")
    end

    def self.events
      get("data/kr/events.min.json")
    end

    def self.items
      get("data/kr/items.min.json")
    end

    private

    def self.get(path)
      address = "#{HOST}/#{path}"
      Rails.logger.info("[SchaleDB::V1::Data] GET #{address}")
      uri = URI(address)
      JSON.parse(Net::HTTP.get(uri))
    end
  end
end
