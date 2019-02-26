def run_the_stack(middlewares, app, env)
  prev_app = app

  middlewares.reverse.each do |middleware|
    prev_app = middleware.new(prev_app)
  end

  prev_app.call(env)
end

# the App
class Talk
  def call(env)
    "Can I talk to #{env[:name]}?"
  end
end

# p run_the_stack([], Talk.new, { name: "Dana"} )

# Add middleware

class Shout
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).upcase
  end
end

# p run_the_stack([Shout], Talk.new, { name: "Dana"} )

#hijacking response
class Zuul
  def initialize(app)
    @app = app
  end

  def call(env)
    "There is no #{env[:name]}. Only Zuul!"
  end
end

p run_the_stack([Shout, Zuul], Talk.new, { name: "Dana"} )
