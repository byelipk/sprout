require 'minitest/autorun'
require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'hiredis/reader'
require 'sprout/reactor'

module Sprout
  class Redis
    attr_reader :redis_connection, :callbacks, :reader

    CRLF = "\r\n".freeze

    def initialize(redis_connection)
      @redis_connection = redis_connection
      @callbacks        = Array.new
      @reader           = Hiredis::Reader.new

      redis_connection.on(:data) do |data|
        # Redis has sent us data! Maybe?
        reader.feed(data)

        until (reply = reader.gets) == false
          receive_reply(reply)
        end
      end
    end

    def receive_reply(reply)
      cb = callbacks.shift
      cb.call(reply) if cb
    end

    def send_command(*args)
      # NOTE
      # Redis uses a template for framing messages
      # that we must conform to:
      # *2\r\n
      # $7\r\n
      # awesome\r\n
      # $5\r\n
      # array\r\n

      args.flatten!

      # Push the start line into the redis_connection buffer.
      redis_connection.push("*" << args.size.to_s << CRLF)

      args.each do |arg|
        # Push content length into redis_connection buffer.
        redis_connection.push("$" << arg.size.to_s << CRLF)

        # Push content into redis_connection buffer.
        redis_connection.push(arg.to_s << CRLF)
      end

      redis_connection.handle_write
    end

    def method_missing(method, *args, &callback)
      send_command(method, *args)
      callbacks.push(callback)
      # yield "Hello world"
    end
  end
end

class RedisReactiveHandler
  attr_reader :client, :reactor

  def initialize(client, reactor)
    # For example, this might be a netcat client
    # that we've used from the command line to
    # connect to the reactor.
    @client  = client
    @reactor = reactor
  end

  def handle
    # We have read data from the client socket...
    client.on(:data) do |data|
      # We can use Sprout to create a new connection
      # with the Redis server.
      socket  = reactor.connect '127.0.0.1', 6379
      redis   = Sprout::Redis.new(socket)
      timeout = 3

      redis.blpop(data.strip, timeout) do |reply|
        # What do we do with our reply from Redis?
        client.push(reply)
        client.handle_write
        client.close
      end
    end
  end
end

reactor = Sprout::Reactor.new
server  = reactor.listen '127.0.0.1', 3000

server.on(:accept) do |client|
  handler = RedisReactiveHandler.new(client, reactor)
  handler.handle
end

reactor.start
