require 'socket'

server = TCPServer.new('localhost', 3003)

def parse_query_str(param_str)
  method, path_and_params, protocol = param_str.split
  if param_str =~ /\?/
    params = (path_and_params || '').split('?').last.split(/[\&=]/).each_slice(2).to_a.to_h
  else
    params = {}
  end
  [method, params, protocol]
end

loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon.ico/
  puts request_line

# GET /?rolls=2&sides=6 HTTP/1.1

  params = parse_query_str(request_line)[1]

  client.puts "HTTP/1.1 200 OK"
  client.puts
  # client.puts "Content-Type: text/html\n\n"
  client.puts "<html>"
  client.puts "<body>"

  client.puts "<h3>#{request_line}</h3>"

  client.puts "<h1>Dice Rolls</h1>"
  client.puts "<pre>"

  number = params["number"].to_i
  client.puts "The current number is #{number}."
  client.puts "<a href='?number=#{number + 1}'>Add one.</a>"
  client.puts "<a href='?number=#{number - 1}'>Sub one.</a>"
  client.puts "</pre>"
  client.puts "</body>"
  client.puts "</html>"

  client.close
end
