module Facy
  module GetToken
    def get_tokens
      developer_page  = "https://developers.facebook.com/"
      developer_page2 = "https://developers.facebook.com/tools/accesstoken/"
      
      unless config[:app_id]
        print "1) open: #{developer_page}, create a new app and enter app_id:"
        browse(developer_page) rescue nil
        app_id = STDIN.gets.chomp
        config[:app_id] = app_id
        new_line
      end 

      unless config[:app_secret]
        print "2) enter app_secret:"
        app_secret = STDIN.gets.chomp
        config[:app_secret] = app_secret
        new_line
      end
      
      unless config[:app_token]
        print "3) open: #{developer_page2} and enter app_token:"
        browse(developer_page2) rescue nil
        app_token = STDIN.gets.chomp
        config[:app_token]  = app_token
        new_line
      end

      app_id          = config[:app_id]
      app_token       = config[:app_token]
      permission      = config[:permission]
      redirect_uri    = config[:redirect_uri]
      get_access_url  =
        "https://www.facebook.com/dialog/oauth?client_id=#{app_id}&scope=#{permission}&redirect_uri=#{redirect_uri}"
      get_token_url =
        "http://www.facebook.com/code_gen.php?v=1.0&api_key=#{app_id}"
      rest = Koala::Facebook::RestAPI.new(app_token)

      print "4) open: #{get_access_url} and give authority to facy"
      browse(get_access_url) rescue nil
      STDIN.gets

      print "5) open: #{get_token_url} and enter authen token: "
      browse(get_token_url) rescue nil
      user_token = STDIN.gets.chomp
      new_line

      File.open(File.expand_path('config.yml', '../'), 'w') do |f|
        conf = {
          "app_id" => config[:app_id],
          "app_token" => config[:app_token],
          "app_secret" => config[:app_secret],
          "permission" => config[:permission]
        }
        f.write conf.to_yaml 
      end

      arg_hash = {auth_token: user_token}
      user_session = rest.rest_call("auth.getSession", arg_hash)

      authen_hash = {
        "session_key" => user_session["session_key"],
        "uid" => user_session["uid"]
      }

      config[:session_key] = user_session["session_key"]
      return authen_hash
    end

    def browse(url)
      Launchy.open(url)
    end
  end
  extend GetToken
end
