module Sprout
  class Server
    include Events::Emitter

    attr_reader :socket

    def initialize(socket: nil)
      @socket = socket
    end
  end
end
