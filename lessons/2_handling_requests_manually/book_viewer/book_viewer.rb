require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'
require 'yaml'
require 'pry'

def search_results
  key_word = params[:query]
  @contents.each.with_index(1).with_object({}) do |(title, chapter_ord), results|
    paragraphs = File.read("data/chp#{chapter_ord}.txt").split("\n\n")
    #matches = paragraphs.select { |p| p.match(Regexp.new(key_word)) }
    matches = paragraphs.each_with_object({}).with_index do |(para, hash), id|
      if para.match(Regexp.new(key_word))
        results[chapter_ord] ||= {}
        results[chapter_ord][:title] = title
        results[chapter_ord][:paragraphes] ||= {}
        results[chapter_ord][:paragraphes][id] = para
      end
    end
  end
end

# results = { chapter_number => { title: '' , paragraphes: {1=>"have done", 220 => "have done"  } }, .... }

before do
  @contents = File.readlines("data/toc.txt")
  @user_info = YAML.load_file("users.yaml")
end

get "/" do
  @wday = Time.new.strftime("%A")

  redirect "/users"
end

get "/users" do
  @users = @user_info.keys
  erb :users
end

get "/users/:name" do
  user_info = YAML.load_file("users.yaml")[params[:name].to_sym]
  @email = user_info[:email]
  @interests = user_info[:interests].join(", ")
  @other_users = @user_info.keys.select { |name| name != params[:name].to_sym }
  erb :user
end

get "/chapters/:number" do
  n = params[:number].to_i
  chapter_name = @contents[n - 1]

  redirect '/' if n > @contents.size

  @title = "Chapter #{n}: #{chapter_name}"
  @chapter = File.read "data/chp#{n}.txt"

  erb :chapter
end

get "/search" do
  @results = search_results

  erb :search
end

not_found do
  redirect "/"
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |p, i|
      "<p id='#{i}'>#{p}</p>"
    end.join
  end

  def highlight_key_word(paragraph)
    key_word = params[:query]
    paragraph.gsub(key_word, "<strong>#{key_word}</strong>")
  end

  def number_of_interests
    count = 0
    @user_info.each do |_, info|
      count += info[:interests].size
    end
    count
  end

  def number_of_users
    @user_info.size
  end
end
