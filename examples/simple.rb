require 'socket'

Socket.tcp_server_loop(4481) do |client|
  client.write(client.read)
  client.close
end
