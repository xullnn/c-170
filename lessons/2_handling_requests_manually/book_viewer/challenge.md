Requirements

When a user visits the root path, /, they should be presented with a listing of all of the files in the public directory. The listing for a file should only display the file's name and not the names of any directories.

- only filenames, no directories
- get fileanmes as an array of strings and assign to an instance variable
  - use `Find.find` to recursively get all the dir and file names under `public/`
    - iterate through the names, only keep wanted ones
- put the instance variable inside `get '/'` block
- find corresponding html container in home.erb
  - insert strings by iteration

When a user clicks one of the filenames in the list, they should be taken directly to that file. Take advantage of Sinatra's built-in serving of the public directory.

- change every file name on homepage to a link
- set the href attribute of every link to its relative path to `public`

Create at least 5 files in the public directory to test the listing page.
- touch files directly under `public`

Add a parameter that controls the sort order of the files on the page. They should be sorted in an ascending (A-Z) order by default, or descending (Z-A) if the parameter has a certain value.
- sorting operation should be done inside `read_file_names_under(path)` method

Display a link to reverse the order. The text of the link should reflect the order that will be displayed if it is clicked: "Sort ascending" or "Sort descending".
- create an anchor tag at home page set the href attribute to `reverse_list`
- add new route inside `book_viewer.rb`
  - inside the method reverse! the instance variable `@files_in_public`
