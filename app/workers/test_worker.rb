class TestWorker
  include Sidekiq::Worker

  def perform
    # raise StandardError
    sleep(30)
    puts('TEST WORKER')
  end
end
