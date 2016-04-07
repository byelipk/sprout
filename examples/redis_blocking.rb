require './examples/sprout_helper'
require 'redis'

class RedisBlockingHandler
  attr_reader :client

  def initialize(client)
    @client = client
  end

  def handle
    # When we read the data the client connection
    # has sent us...
    client.on(:data) do |data|
      timeout = 3
      redis   = Redis.new

      begin
        # NOTE
        # If there is data in the redis list then
        # blpop will return straight away, otherwise
        # it will block for 3 seconds.
        #
        # rpush hello the world is good
        response = redis.blpop(data.strip, timeout)
        write(response)

      rescue Redis::CommandError => e
        write(e.message)
      end
    end
  end

  def write(data)
    client.push(data.to_s)
    client.handle_write
    client.close
  end
end

reactor = Sprout::Reactor.new
server  = reactor.listen '127.0.0.1', 3000

server.on(:accept) do |client|
  handler = RedisBlockingHandler.new(client)
  handler.handle
end

reactor.start
