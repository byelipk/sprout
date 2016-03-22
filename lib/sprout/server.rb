module Sprout
  class Server
    include Events::Emitter

    attr_reader :socket

    def initialize(socket: nil)
      @socket = socket
    end

    # NOTE
    # This is where we pull client connections off
    # of the listen queue. At this point the server
    # socket will have data to read from its Recv-Q.
    def handle_read
      begin
        client = socket.accept_nonblock
        emit(:accept, client)
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
  end
end
