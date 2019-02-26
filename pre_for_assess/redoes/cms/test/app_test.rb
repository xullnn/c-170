ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require "fileutils"
require_relative '../cms'

class TestApp < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content="")
    File.open(File.join(data_path, name), 'w') { |f| f.write(content) }
  end

  def test_index_page
    create_document "changes.txt"

    get "/"
    assert last_response.ok?
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'changes.txt'
  end

  def test_file_page
    create_document "changes.txt", "2003 - Ruby 1.8 released."

    get "/changes.txt"
    assert last_response.ok?
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, '2003 - Ruby 1.8 released.'
  end

  def test_redirection_of_access_nonexistent_file
    get "/nonexistent.txt"
    assert_equal 302, last_response.status
    assert_equal "nonexistent.txt doesn't exist.", last_request_session[:message]

    get last_response["Location"]
    assert_includes last_response.body, "nonexistent.txt doesn't exist."
  end

  def test_markdown_rendering
    create_document "about.md", "# Title One"

    get "/about.md"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h1>Title One</h1>"
  end

  def test_edit_page_for_files
    create_document "changes.txt", "Old content"

    get "/changes.txt/edit"
    action_denied

    get "/", {}, sign_in_as("admin")
    assert_includes last_response.body, "<a href=\"/changes.txt/edit\">Edit</a>"

    get "/changes.txt/edit"
    assert_includes last_response.body, "Edit content of changes.txt"
    assert_includes last_response.body, "Old content"
    assert_includes last_response.body, "Save Changes"
  end

  def test_update_file
    create_document "history.txt", "Old content"

    post "/history.txt/update", { new_content: "some new content" }
    action_denied

    post "/history.txt/update", { new_content: "some new content" }, sign_in_as("admin")
    assert_equal 302, last_response.status
    assert_equal "history.txt has been updated.", last_request_session[:message]
  end

  def test_new_document_page
    get "/"
    assert_includes last_response.body, "<a href=\"/documents/new\">New Document</a>"

    get "/documents/new"
    action_denied

    get "/documents/new", {}, sign_in_as("admin")
    assert_includes last_response.body, "Add a new document"
    assert_includes last_response.body, "<form action=\"/documents\" method=\"post\">"
  end

  def test_create_document
    create_document "history.txt", "Old content"

    post "/documents", { file_name: "  " }
    action_denied

    post "/documents", { file_name: "  " } , sign_in_as("admin")
    assert_includes last_response.body, "file name should be between 1 and 100 characters."

    post "/documents", file_name: "history.txt"
    assert_includes last_response.body, "file name history.txt already existed."

    post "/documents", file_name: "new_file.txt"
    assert_equal 302, last_response.status
    assert_equal "new_file.txt created successfully.", last_request_session[:message]
  end

  def test_delete_document
    create_document "history.txt", "Old content"

    post "/history.txt/destroy"
    action_denied

    get "/", {}, sign_in_as("admin")
    assert_includes last_response.body, "<button type=\"submit\">Delete</button>"

    post "/history.txt/destroy"
    get last_response["Location"]
    assert_includes last_response.body, "history.txt has been deleted"
    refute_includes Dir.children(data_path), "history.txt"
  end

  def test_sign_in_form_page
    get "/"
    assert_includes last_response.body, "<form action=\"\/users/signin\" method=\"get\">"
    assert_includes last_response.body, "<button type=\"submit\">Sign In</button>"

    get "/users/signin"
    assert_includes last_response.body, "<label for=\"username\">Username:</label>"
    assert_includes last_response.body, "<label for=\"password\">Password:</label>"
  end

  def test_hard_coded_signin
    post "/users/signin", { username: "admin", password: "secret" }
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
    assert_includes last_response.body, "<button type=\"submit\">Sign Out</button>"
    assert_equal "admin", last_request_session[:sign_in_as]

    post "/users/signin", { username: "nonadmin", password: "secret" }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid Credentials"
    assert_includes last_response.body, "nonadmin"
  end

  def test_signout_user
    get "/", {}, sign_in_as("admin")
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "You have been signed out."
    refute_includes last_response.body, "<button type=\"submit\">Sign Out</button>"
    refute_includes last_response.body, "Signed in as"
  end

  def last_request_session
    last_request.env['rack.session'] # return a hash like obj
  end

  def sign_in_as(name)
    {'rack.session' => { sign_in_as: name } }
  end

  def action_denied
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", last_request_session[:message]
  end
end
