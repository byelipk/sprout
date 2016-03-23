require 'minitest/autorun'
require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'sprout/reactor'

describe "echo service" do
  it "works" do
    reactor = Sprout::Reactor.new blocking: false
    server  = reactor.listen('127.0.0.1', 3000)

    server.on(:accept) do |client|
      # We have a new client socket connection!

      # NOTE
      # We have pulled data out of the client socket
      # and exposed it through the callback API.
      # This is where we build our echo server.
      # Notice that we are not performing any kind
      # of processing on the data. We are just writing
      # what we get back into the client socket.
      client.on(:data) do |data|
        client.push(data)   # Push data into the buffer
        client.handle_write # Execute write operation
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
