require "events"
require_relative "./server"

module Sprout
  class Reactor
    def listen(host, port)
      Server.new
    end

    def start
    end
  end
end
