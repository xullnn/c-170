p system('pwd')
# puts File.expand_path(__FILE__)

# root_path = File.expand_path("../..", __FILE__)
# data_path = File.join(root_path, "data")

#p Dir.glob('*', base: 'data')
p Dir.glob('**/data/**/*.*').map { |file_path| File.basename(file_path) }
# p Dir.glob("#{data_path}/**/*.*").map { |file_path| File.basename(file_path) }

# # expand current file name to a full path of it, then go one level up
# root = File.expand_path("..", __FILE__)
#
# # give a pattern to `Dir::glob`, return an array of file names
# p Dir.glob(root + "/data/**/*.*").map { |full_path| File.basename(full_path) }
