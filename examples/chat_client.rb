require "./examples/sprout_helper"

class ChatClient
  CHUNK_SIZE = 8 * 1024
end

require 'thread'
Thread.abort_on_exception = true
Thread.new do

end

loop do
  puts "Write your message:\n"

  raw = gets
  raw.strip!

  if raw.match /q|quit/i
    break
  end

  message = String.new
  message << "[NEW]"
  message << raw

  # client.write(message)
end
