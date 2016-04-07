require './examples/sprout_helper'

class Chat
  attr_reader :users

  def initialize
    @users = []
  end

  def setup(server)
    server.on(:accept) do |client|
      register client
    end
  end

  def register(client)
    client.on(:data) do |data|
      send_update data
    end

    client.on(:close) { @users.delete(client) }

    send_update "Hello, there!"
  end

  def send_update data
    users.each { |user| user.push data }
  end
end

reactor = Sprout::Reactor.new
server  = reactor.listen('127.0.0.1', 3000)

chat = Chat.new
chat.setup(server)

reactor.start
