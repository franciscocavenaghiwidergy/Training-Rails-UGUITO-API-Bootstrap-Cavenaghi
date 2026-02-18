class TestWorker
  include Sidekiq::Worker
  def execute
    sleep(30)
    [200, { result: 'TEST WORKER' }]
  end
end