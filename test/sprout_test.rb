require 'minitest/autorun'
require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'sprout/reactor'

describe "echo service" do
  it "works" do
    reactor = Sprout::Reactor.new blocking: true
    server  = reactor.listen('127.0.0.1', 3000)

    server.on(:accept) do |client|
      client.on(:data) do |data|
        client.push(data)
        client.handle_write
      end
    end

    reactor.start

    # NOTE
    # At this point, if our reactor does not accept
    # client connections, the socket opened up by netcat
    # will remain in the listen queue.
    `echo foo | nc localhost 3000`.strip.must_equal "foo"
  end
end
