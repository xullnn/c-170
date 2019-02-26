require 'bundler/setup'
require 'sinatra'
require "sinatra/reloader" if development?
require 'pry' if development?
require "tilt/erubis"
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'

  #set :erb, :escape_html => true
end

ROOT_PATH = File.expand_path("..", __FILE__)

get "/" do
  pattern = File.join(data_path, "*.*")
  headers["Content-Type"] = "text/html;charset=utf-8"
  @file_names = Dir.glob(pattern).map { |f| File.basename(f) }
  erb :index
end

get "/:file_name" do
  file_name = params[:file_name]
  file_path = File.join(data_path, "#{file_name}")
  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{file_name} doesn't exist."
    redirect "/"
  end
end

get "/:file_name/edit" do
  validate_user_sign_in
  file_name = params[:file_name]
  file_path = File.join(data_path, "#{file_name}")
  if File.file?(file_path)
    @current_content = File.read(file_path)
  else
    session[:message] = "#{file_name} doesn't exist."
    redirect "/"
  end
  erb :edit
end

post "/:file_name/update" do
  validate_user_sign_in
  file_name = params[:file_name]
  file_path = File.join(data_path, "#{file_name}")
  if File.file?(file_path)
    File.write(file_path, params[:new_content])
    session[:message] = "#{file_name} has been updated."
  else
    session[:message] = "#{file_name} doesn't exist."
  end
  redirect "/"
end

get "/documents/new" do
  validate_user_sign_in
  erb :new
end

post "/documents" do
  validate_user_sign_in
  name = params[:file_name].to_s
  file_path = File.join(data_path, name)
  if name.strip == ""
    status 422
    session[:message] = "file name should be between 1 and 100 characters."
    erb :new
  elsif File.file?(file_path)
    status 422
    session[:message] = "file name #{name} already existed."
    erb :new
  else
    File.write(File.join(data_path, name), '')
    session[:message] = "#{name} created successfully."
    redirect "/"
  end
end

post "/:file_name/destroy" do
  validate_user_sign_in
  file_name = params[:file_name]
  file_path = File.join(data_path, "#{file_name}")
  if File.file?(file_path)
    FileUtils.rm_rf(file_path)
    session[:message] = "#{file_name} has been deleted."
  else
    session[:message] = "#{file_name} doesn't exist."
  end
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  if valid_credential?
    session[:message] = "Welcome!"
    session[:sign_in_as] = params[:username]
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:sign_in_as)
  session[:message] = "You have been signed out."
  redirect "/"
end

def valid_credential?
  name = params[:username]
  valid_users = load_user_credentials
  valid_users[name] && BCrypt::Password.new(valid_users[name]) == params[:password]
end

def hash_password(plain)
  BCrypt::Password.create(plain)
end

def load_user_credentials
  credentials_path =
    if ENV['RACK_ENV'] == 'test'
      File.expand_path('../test/users.yaml', __FILE__)
    else
      File.expand_path('../users.yaml', __FILE__)
    end

  YAML.load_file(credentials_path)
end

def validate_user_sign_in
  unless session[:sign_in_as]
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

def render_markdown(text)
  Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text)
end

def load_file_content(file_path)
  content = File.read(file_path)
  file_type = File.extname(file_path)
  if file_type == '.txt'
    headers["Content-Type"] = "text/plain"
    content
  elsif file_type == '.md'
    headers["Content-Type"] = "text/html"
    render_markdown(content)
  end
end

def data_path
  if ENV["RACK_ENV"] == 'test'
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end
