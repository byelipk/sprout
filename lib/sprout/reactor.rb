require "socket"
require "events"
require_relative "./server"

module Sprout
  class Reactor
    def listen(host, port)
      # socket = TCPServer.new(host, port)
      socket = Socket.new(:INET, :STREAM)
      addr   = Socket.pack_sockaddr_in(port, host)

      socket.bind(addr)
      socket.listen(1)

      server = Server.new(socket: socket)

      server
    end

    def start
    end
  end
end
