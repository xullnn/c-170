require 'rack'
# The app
class Talk
  def call(env)
    [200, {'Content-Type' => 'text/plain'}, ["Can I talk to #{env['QUERY_STRING']}!"]]
  end
end

# Middlewares
class Shout
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    [response[0], response[1], response[2].map(&:upcase)]
  end
end

class Zuul
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)
    [response[0], response[1], ["There is no #{env['QUERY_STRING']}. Only Zuul!"]]
  end
end

use Shout
use Zuul

run(Talk.new)
