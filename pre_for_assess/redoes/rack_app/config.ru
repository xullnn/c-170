app_obj = Proc.new { |env| [200, {'Content-Type' => 'text/plain'}, ['Hello World.']] }

run app_obj
