class TestWorker
  include Sidekiq::Worker

  OPEN_LIBRARY_URL = 'https://openlibrary.org/api/books?bibkeys=ISBN:0385472579&format=json&jscmd=data'

  def perform
    execute
  end

  def execute
    response = HTTParty.get(OPEN_LIBRARY_URL)
    parsed_body = response.body.present? ? JSON.parse(response.body) : nil
    [response.code, parsed_body]
  end
end