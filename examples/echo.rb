require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'sprout/reactor'

class FriendlyEchoServer
  attr_reader :client

  def initialize(client)
    @client = client

    log("connected")
  end

  def serve
    client.on(:data) do |raw|
      client.push(raw)
      client.handle_write
      client.close
    end

    client.on(:close) do
      log("disconnected")
    end
  end

  def log(status)
    puts "[#{client.address.ip_address}:#{client.address.ip_port}] Client #{status}"
  end
end

reactor = Sprout::Reactor.new
server  = reactor.listen '127.0.0.1', 3000

server.on(:accept) do |client|
  funky_server = FriendlyEchoServer.new(client)
  funky_server.serve
end

reactor.start
