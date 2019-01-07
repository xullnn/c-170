require 'socket'

server = TCPServer.new('localhost', 3003)

loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon.ico/
  puts request_line

# GET /?rolls=2&sides=6 HTTP/1.1

  params = request_line.split[1][2..-1].split(/[\&=]/).each_slice(2).to_a.to_h

  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/html\n\n"
  client.puts "<html>"
  client.puts "<body>"

  # client.puts request_line

  client.puts "<h1>Dice Rolls</h1>"
  client.puts "<pre>"
  params['rolls'].to_i.times do
    client.puts rand(params['sides'].to_i) + 1
  end
  client.puts "</pre>"
  client.puts "</body>"
  client.puts "</html>"

  client.close
end
