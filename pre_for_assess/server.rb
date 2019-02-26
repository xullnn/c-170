require 'socket'

def parse_url(url)
  params = Hash.new('')
  method, path_and_params, http_version = url.split(' ')
  params['status_and_http_v'] = http_version
  params['path'] = path_and_params.split('?').first
  params['method'] = method
  params = path_and_params.delete('/?').split('&').map { |pair| pair.split('=') }.to_h
  params.merge!(params)
end

server = TCPServer.new('localhost', 3003)
loop do
  client = server.accept

  request_line = client.gets
  next if request_line =~ /favicon/ || !request_line
  # headers
  client.puts "HTTP/1.1 200 OK\n"
  client.puts "Content-Type: text/html\n\n"
  # body
  params = parse_url(request_line)
  client.puts '<html>'
    client.puts '<body>'

      # raw data sent from browser
      client.puts request_line

      client.puts '<pre>'
      client.puts params
      client.puts '</pre>'

   # params['rolls'].to_i.times { client.puts '<p>', rand(params['sides'].to_i) + 1, '</p>' }

    client.puts '<h1>Counter</h1>'
    number = params['number'].to_i
    client.puts "<p>The current number is #{number}.</p>"

    client.puts "<a href='/?number=#{number + 1}'>Add One</a>"
    client.puts "<a href='/?number=#{number - 1}'>Minus One</a>"

    client.puts '</body>'
  client.puts '</html>'
  client.close
end
