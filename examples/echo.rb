require 'minitest/autorun'
require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'sprout/reactor'

class FriendlyEchoServer
  attr_reader :client

  def initialize(client)
    @client = client
  end

  def serve
    client.on(:data) do |raw|
      client.push(raw)
      client.handle_write
    end
  end
end

reactor = Sprout::Reactor.new
server  = reactor.listen '127.0.0.1', 3000

server.on(:accept) do |client|
  funky_server = FriendlyEchoServer.new(client)
  funky_server.serve
end

reactor.start
