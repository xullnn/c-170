require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'

  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# view all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists
end

# render new list form
get "/lists/new" do
  erb :new_list
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_name?('list', list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { id: next_list_id, name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list = load_list(params[:id].to_i)
  erb :list
end

get "/lists/:id/edit" do
  @list = load_list(params[:id].to_i)
  erb :edit_list
end

post "/lists/:id/edit" do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  name_error = error_for_name?('list', params[:list_name].strip)
  if name_error
    session[:error] = name_error
    erb :edit_list
  else
    @list[:name] = params[:list_name]
    session[:success] = "The list has been updated."
    redirect "/lists/#{list_id}"
  end
end

post "/lists/:id/delete" do
  @list = load_list(list_id)
  session[:lists].delete_at(list_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "List has been deleted successfully."
    redirect "/lists"
  end
end

post "/lists/:id/todos" do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  todo = params[:todo].strip
  name_error = error_for_name?(list_id, 'todo', todo)
  todo_id = next_todo_id(@list)
  if name_error
    session[:error] = name_error
    erb :list
  else
    @list[:todos] << { id: todo_id, name: todo, completed: false }
    session[:success] = "New todo \"#{todo}\" was added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:todo_id/delete" do
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  todo_id = params[:todo_id].to_i
  todo_id_error = error_for_todo_id(@list, todo_id)
  @list[:todos].delete_at(todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "Todo item was deleted."
    redirect "/lists/#{list_id}"
  end
end

# complete or uncomplete todo item
post "/lists/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  @list = load_list(list_id)
  todo_id = params[:todo_id].to_i
  todo = @list[:todos].find { |todo| todo[:id].to_i == todo_id }
  if todo.nil?
    session[:error] = "Todo item not found."
  else
    if params[:completed] == "true"
      todo[:completed] = true
    elsif params[:completed] == "false"
      todo[:completed] = false
    end
    session[:success] = "The todo item has been updated."
  end
  redirect "/lists/#{@list[:id]}"
end

def load_todo(list, todo_id)

end

post "/lists/:id/complete_all" do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos has been marked as completed."
  redirect "/lists/#{list_id}"
end

get "/seed_data" do
  seed_data
  redirect "/lists"
end

def next_todo_id(list)
  max = list[:todos].map{ |todo| todo[:id] }.max || 0
  max + 1
end

def next_list_id
  max = session[:lists].map { |list| list[:id] }.max || 0
  max + 1
end

def seed_data
  session[:lists] = []
  lists = [
    {id: "1", name: "List 1", todos: [{id: "1", name: "Buy food", completed: false}, {id: "2", name: "Walk dog", completed: false}, {id: "3", name: "See friends", completed: false}] },
    {id: "2", name: "List 2", todos: [{id: "1", name: "Buy food", completed: false}, {id: "2", name: "Walk dog", completed: false}, {id: "3", name: "See friends", completed: false}] },
    {id: "3", name: "List 3", todos: [{id: "1", name: "Buy food", completed: false}, {id: "2", name: "Walk dog", completed: false}, {id: "3", name: "See friends", completed: false}] }
  ]
  lists.each { |list| session[:lists] << list }
end

def load_list(id)
  list = session[:lists].find { |list| list[:id].to_i == id }
  if list.nil?
    session[:error] = "List not found."
    redirect "/lists"
  else
    list
  end
end

def error_for_name?(list_id = nil, type, name)
  return "Name must be between 1 and 100 characters." if !(1..100).cover?(name.size)
  existed_names =
    case type
    when 'list'
      session[:lists].map { |list| list[:name] }
    when 'todo'
      list = session[:lists][list_id]
      list[:todos].map { |todo| todo[:name] }
    end
  return "The name \"#{name}\" has been taken." if existed_names.include?(name)
end

helpers do
  # yield incomplete and complete lists separately while keep their indexes(based on session[:lists])
  def sort_lists(lists)
    incompletes, completes = lists.partition { |list| list_incomplete?(list) }

    incompletes.each { |list| yield(list, lists.index(list)) }
    completes.each { |list| yield(list, lists.index(list)) }
  end

  # similar to sort_lists
  def sort_todos(todos)
    incompletes, completes = todos.partition { |todo| !todo[:completed] }

    incompletes.each { |todo| yield(todo, todos.index(todo)) }
    completes.each { |todo| yield(todo, todos.index(todo)) }
  end

  # return css class to apply style to view
  def todo_css_class(todo)
    todo[:completed] ? "complete" : ""
  end
  # return css class to apply style to view
  def list_todo_class(list)
    list_incomplete?(list) ? "" : "complete"
  end
  # return boolean
  def list_incomplete?(list)
    list[:todos].empty? || list[:todos].any? { |todo| todo[:completed] == false }
  end

  def list_complete_percentage(list)
    completes = list[:todos].count { |todo| todo[:completed] == true }
    "#{completes} / #{list[:todos].size}"
  end
end
