require "pry"

require "socket"
require "thread"
require "events"

require_relative "./server"
require_relative "./stream"

module Sprout
  class Reactor
    attr_reader :streams, :blocking

    def initialize(blocking: false)
      @streams  = Array.new
      @blocking = blocking
    end

    def listen(host, port)
      # socket = TCPServer.new(host, port)
      socket = Socket.new(:INET, :STREAM)
      addr   = Socket.pack_sockaddr_in(port, host)

      socket.bind(addr)
      socket.listen(5)

      # Wrap the socket in our server class.
      server = Server.new(socket: socket)

      # Add the server to our collection of evented
      # stream objects.
      register(server)

      server.on(:accept) do |client|
        register(client)
      end

      server
    end

    def start
      unless blocking
        loop { tick }
      else
        Thread.abort_on_exception = true
        Thread.new {
          loop { tick }
        }
      end
    end

    private

      def tick
        to_read,
        to_write = IO.select(streams, streams, nil, nil)

        to_read.each  { |stream| stream.handle_read  }
        to_write.each { |stream| stream.handle_write }
      end

      def register(stream)
        @streams << stream

        stream.on(:close) do
          @streams.delete(stream)
        end
      end

  end
end
