module Sprout
  class Server
    include Events::Emitter

    attr_reader :socket

    def initialize(socket: nil)
      @socket = socket
    end

    # NOTE
    # This is where we pull client connections off
    # of the listen queue. When our server becomes
    # readable that means its underlying socket
    # has data to read from its Recv-Q.
    def handle_read
      begin
        client, addr = socket.accept_nonblock
        emit(:accept, Stream.new(socket: client, address: addr))
      rescue IOError
      end
    end

    # NOTE
    # In our evented system the server class needs to
    # behave like it's an IO object. So we'll delegate
    # to the actual socket - an actual IO object.
    def to_io
      socket
    end

    def welcome
      puts "Running Sprout::Reactor"
      puts "Listening on #{socket.local_address.ip_address}:#{socket.local_address.ip_port}..."
    end

    def close
      emit(:close)
      socket.close
      @socket = nil
    end
  end
end
