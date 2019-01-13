require 'find'
require "sinatra"
require "sinatra/reloader"
require 'tilt/erubis'

def read_file_names_under(path)
  Find.find(path).with_object([]) do |name, arr|
    if name.match(/\./)
      arr << name.split("/").last
    end
  end.sort
  # Dir.entries/glob
end

get "/" do
  @files_in_public = read_file_names_under("public/")
  @files_in_public.reverse! if params[:sort] == 'descend'

  erb :list
end
