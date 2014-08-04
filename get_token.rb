require "pry"

module Facy
  module GetToken
    def get_tokens
      app_id    = config[:app_id]
      app_token = config[:app_token]
      get_access_url =
        "https://www.facebook.com/dialog/oauth?client_id=#{app_id}&scope=read_stream&redirect_uri=http://www.facebook.com/connect/login_success.html"
      get_token_url =
        "http://www.facebook.com/code_gen.php?v=1.0&api_key=#{app_id}"
      rest = Koala::Facebook::RestAPI.new(app_token)
      
      puts "1) open: #{get_access_url} and give authority to facy"
      browse(get_access_url) rescue nil
      STDIN.gets

      puts "2) open: #{get_token_url}"
      browse(get_token_url) rescue nil
      STDIN.gets

      print "3) enter authen token: "
      user_token = STDIN.gets.strip

      arg_hash = {auth_token: user_token}
      user_session = rest.rest_call("auth.getSession", arg_hash)

      authen_hash = {
        "session_key" => user_session["session_key"],
        "uid" => user_session["uid"]
      }
      return authen_hash
    end

    def browse(url)
      Launchy.open(url)
    end
  end
  extend GetToken
end
