module Sprout
  class Stream
    include Events::Emitter

    CHUNK_SIZE = 16 * 1024

    attr_reader :socket, :address, :buffer

    def initialize(socket: nil, address: nil)
      @socket  = socket
      @address = address
      @buffer  = String.new
    end

    def push(data = String.new)
      @buffer << data
    end

    def push!(data)
      push(data)
      handle_write
    end

    def handle_read
      begin
        data = socket.read_nonblock(CHUNK_SIZE)
        emit(:data, data)
      rescue Errno::EAGAIN
      rescue EOFError
        # NOTE
        # For this architecture pattern we delegate
        # explicitly closing the socket connection to
        # the layer on top of the reactor.
        #
        # This could be, for example, an echo server that
        # would close the connection after writing data
        # into the client socket.
        #
        close if socket.closed?
      end
    end

    def handle_write
      return if buffer.empty?

      # NOTE
      # If an exception is raised on a nonblocking
      # write operation that means the Recv-Q
      # on the client is full.
      begin
        bytes   = socket.write_nonblock(buffer)
        @buffer = buffer.slice(bytes, buffer.length)

      rescue Errno::EAGAIN, Errno::EPIPE
      rescue EOFError
        # NOTE
        # Since we process our readables queue before
        # our writables queue it's possible we've already
        # closed off the socket. Writing to it now would
        # raise IOError.
      end
    end

    # Allow our stream to "walk like a duck".
    def to_io
      socket
    end

    def close
      emit(:close)
      socket.close
      @socket = nil
    end

  end
end
