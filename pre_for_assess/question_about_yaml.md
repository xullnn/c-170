Hi everyone, I have a question about updating yaml file in Ruby. I know Ruby can load yaml file then return a hash, and it can also write data into a yaml file. But what if I want to update one specific value of a key? For example:

example.yaml

```yaml
Bob:
  id: 1
  score: 2

Amy:
  id: 2
  score: 0

Sam:
  id: 3
  score: 3
```

Now I want to update the score of Amy to `5`. One way is to load the whole file as a hash, and do things like `hash["Amy"]["score"] = 5`, then write back into the file

```ruby
File.open("./example.yaml", "w") do |f|
  f.write(Psych.dump(hash))
end
```

But this is a bit expensive, since we have to read the whole file, change some data, then write all data into the file again. When we have millions of users there, we have to read-and-write so much data every time, though we just want to change one user's data.

My attempts:

In this case, what we know while performing the updating?

- user name or user id
- the key/value we want to change

What would be the basic steps to update portion of the file?

- locate data item of the given user in the file
- load user information from file
- update data
- write back data into file

My purpose is to change any user's certain attribute(s) without rewriting other users' data.

Algorithm:

- read file
- locate where the data we want to change starts(char index? offset)
- user =~ (name) to return index(char position)
- read n lines from that position(n should be the attribute number of user)
- sub/update key/value pairs we want to update
- write back from pervious matched position

Solution 1

```ruby
def find_position(target, file_obj)
  file_obj.pos = file_obj.read =~ Regexp.new(target)
end

def update_user(name, params)
  file = File.new("./example.yaml")
  char_pos = find_position(name, file)
  new_str = 3.times.with_object("") do |_, str|
    str << file.readline
  end
  params.each do |k, v|
    attr_line = Regexp.new(k.to_s + ".+$")
    new_str.sub!(attr_line, "#{k}: #{v}")
  end
  File.write("./example.yaml", new_str, char_pos)
end
```

This solution is based on the algorithm described above. It bypasses Psych library, handle the data only as string throughout the process.

Solution 2

```ruby
require 'yaml'

def modify_user(name, params)
  users_info = YAML.load_file("./example.yaml")
  user = users_info[name]
  params.each do |k, v|
    user[k.to_s] = v
  end
  File.open("./example.yaml", "w") do |f|
    f.write(YAML.dump(users_info))
  end
end
```

Solution 3

```ruby
# omit find_position method
def change_user(name, params)
  users_info = YAML.load_file("./example.yaml")
  user_info = users_info[name]
  params.each do |k, v|
    user_info[k.to_s] = v
  end
  pos = find_position(name, File.open("./example.yaml"))
  user_hash = { name => user_info }
  File.write("./example.yaml", YAML.dump(user_hash).sub("---\n", ""), pos)
end
```

Solution 2 and 3 are similar, the difference is solution 2 dumps all the data back into the file after updating, solution 3 only dumps the data relates to specified user. Solution 3 borrows the logic of inserting data from a certain position(from solution 1).

And I tested the time cost of the 3 solutions:

```ruby
# write 100000 users into example.yaml
f = File.open("./example.yaml", "w")
100000.times do |n|
  str = "user_#{n}:\n  id: #{n}\n  score: 0\n"
  File.write("./example.yaml", str, mode: "a")
end

# try updating user_50000 by different solutions and record how much time each solution would take

# solution 1
start = Time.new
update_user("user_50000", score: 9)
over = Time.new
duration = over - start
p duration

require 'yaml'

# solution 2
start = Time.new
modify_user("user_50000", score: 8)
over = Time.new
duration = over - start
p duration

# solution 3
start = Time.new
change_user("user_50000", score: 7)
over = Time.new
duration = over - start
p duration
```

And an output on my machine is:

```
0.003138
7.586313
4.425295
```

The complete code is in this github gist.

Solution 1 is about 2000 times faster than solution 2. Then I changed the number of users to 1000000. The output was similar.

Defect of solution 1 and 3

Previously I only change the score from one digit to another, however, if I pass ("user_50000", score: "100"), the two more chars 00 (from x to x00) will "eat" the two chars after it. Means it will break the data behind it. Since the solution is write data based on given offset, there's no extra space for us. If we add two more chars position(assume we could), we are actually rewrite all the file from where we began to write.But solution 2 doesn't have this problem.

My question are:

Is there any way to fix the defect of 'offset based inserting' solution?

Is this problem one of the reasons we need to use database?

Thanks.
