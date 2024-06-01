module SchaleDB
  class Data
    HOST = "https://raw.githubusercontent.com/SchaleDB/SchaleDB/main"

    def self.students
      get("data/kr/students.min.json")
    end

    private

    def self.get(path)
      uri = URI("#{HOST}/#{path}")
      JSON.parse(Net::HTTP.get(uri))
    end
  end
end
