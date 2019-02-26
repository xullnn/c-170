require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'
require 'yaml'
require 'pry'

before do
  @contents = File.readlines("data/toc.txt")
  @count_users = load_users.size
  @count_interests = load_users.inject(0) { |acc, (name, info)| acc + info[:interests].size }
end

get "/" do
  @title = "Home Page"
  erb :home
  # @title = "Public Files"
  # @filenames = Dir.glob("**/*.*", { base: "public" }).sort
  # @filenames.reverse! if params[:sort_order] && params[:sort_order] == 'descending'
  # erb :challenge
end

get "/chapters/:number" do
  number = params[:number].to_i
  redirect "/" unless (1..@contents.size).cover?(number)

  chapter_title = @contents[number - 1]
  @title = "Chapter #{number}: #{chapter_title}"
  @paragraphes_with_ids = in_paragraphes(read_chapter(number))

  erb :chapter
end

get "/search" do
  query = params[:query]
  if !query.nil?
    @results = search_contents(query)
    #[{'title' => 'some title', 'number' => '1', 'id_and_paragraphes' => { 0 => 'xxx', 4 => 'xxx' }}]
  end
  erb :search
end

get "/users" do
  @users = load_users
  erb :users
end

get "/users/:name" do
  users = load_users
  this_user = params[:name].to_sym
  current_user = users[this_user]
  @email = current_user[:email]
  @interests = current_user[:interests].join(", ")
  @other_names = users.select { |name, _| name != this_user }.keys.map(&:to_s)
  erb :user
end

def load_users
  YAML.load_file("./users.yaml")
end

def search_contents(query)
  @contents.each.with_index(1).with_object([]) do |(title, number), arr|
    h = {}
    if !search_paragraphes(read_chapter(number), query).empty?
      h['title'] = title
      h['number'] = number
      h['id_and_paragraphes'] = search_paragraphes(read_chapter(number), query)
      arr << h
    end
  end
end

def search_paragraphes(text, query)
  text.split(/\n{2,}/).each.with_index.with_object({}) do |(paragraph, id), results|
    results[id] = paragraph if paragraph.include?(query)
  end
end

def read_chapter(number)
  File.read("data/chp#{number}.txt")
end

not_found do
  redirect "/"
end

helpers do
  def in_paragraphes(text)
    text.split(/\n{2,}/).map.with_index.with_object({}) do |(content, id), hash|
      hash[id] = content
    end
  end

  def emphasize_query(paragraph, query_str)
    paragraph.gsub(query_str, "<strong>#{query_str}</strong>")
  end
end
