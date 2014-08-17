module Facy
  module GetToken
    def session_file
      File.expand_path(config[:session_file_name], config[:session_file_folder])
    end

    def setup_app_id
      developer_page = "https://developers.facebook.com"      
      puts "★　go to #{developer_page} and enter our app_id: "
      browse(developer_page)
      config[:app_id] = STDIN.gets.chomp
    end

    def save_config_file
      File.open(File.expand_path('../../../config.yml', __FILE__), 'w') do |f|
        conf = {
          "app_id" => config[:app_id],
          "permission" => config[:permission],
          "granted" => true
        }
        f.write conf.to_yaml 
      end
    end

    def load_session_file
      session = YAML.load_file(session_file)
      config[:access_token] = session["access_token"]
      return (ret = config[:access_token].nil? ? false : true)
    rescue Errno::ENOENT #file not found
      return false
    end

    def save_session_file
      hash = {"access_token" => config[:access_token]}
      p session_file
      File.open(session_file, "w") { |f| f.write hash.to_yaml } 
    end

    def grant_access
      app_id = config[:app_id]
      redirect_uri = config[:redirect_uri]
      permission = config[:permission]

      get_access_url  =
        "https://www.facebook.com/dialog/oauth?client_id=#{app_id}&scope=#{permission}&redirect_uri=#{redirect_uri}"
      puts "★　goto #{get_access_url} to grant access to our app"
      browse(get_access_url)
      puts "→ after access granted press enter"
      STDIN.gets
    end

    def setup_token 
      developer_page = "https://developers.facebook.com/tools/accesstoken/"
      puts "★  goto #{developer_page} and enter User access token: "
      browse(developer_page)
      token = STDIN.gets.chomp
      config[:access_token] = token
    end

    def login_flow
      unless config[:app_id]
        setup_app_id
      end
      unless config[:granted]
        grant_access
      end
      save_config_file

      unless load_session_file 
        setup_token
        save_session_file
      end
    end

    def browse(url)
      Launchy.open(url)
    end
  end
  extend GetToken
end
