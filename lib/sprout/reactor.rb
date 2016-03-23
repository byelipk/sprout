require "pry"

require "socket"
require "thread"
require "events"

require_relative "./server"
require_relative "./stream"

module Sprout
  class Reactor
    attr_reader :streams, :blocking

    def initialize(blocking: true)
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

      # Print info to console
      server.welcome

      # Add the server to our collection of evented
      # stream objects.
      register(server)

      server.on(:accept) do |client|
        # NOTE
        # The effect of setting this option is that
        # we will only be able to write 1 byte into
        # the socket per event loop tick.
        client.socket.setsockopt(:SOCKET, :SNDBUF, 1)
        # client.socket.setsockopt(:SOCKET, :RCVBUF, 1)

        register(client)
      end

      server
    end

    def start
      handle_signals!

      if blocking
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
          log
        end

        log
      end

      def log
        puts "[Reactor] #{streams.length - 1} connected clients"
      end

      def handle_signals!
        Signal.trap(:INT) do
          streams.each { |stream| stream.emit(:close) }
          puts
          puts "Shutting down Reactor..."
          exit(1)
        end
      end

  end
end
