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

    def push(data)
      if data
        @buffer << data
      end
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
        # When the client closes its end of the TCP
        # connection that triggers a readable event on
        # the socket. When we try to read from the socket
        # an end-of-file error is raised.
        #
        # So we need to close off our end and remove
        # the stream from our collection of streams.
        #
        # Note that closing the socket does not remove the
        # stream from the collection of writable streams.
        # So this socket will raise an exception within the
        # |handle_write| method if we try to write to it.
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

    def to_io
      socket
    end

    def close
      emit(:close)
      socket.close
      socket = nil
    end

  end
end
