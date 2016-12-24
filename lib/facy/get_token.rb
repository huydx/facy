# coding: utf-8

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
      log(:info, "app_id setup success #{config[:app_id]}")
    end

    def setup_app_secret
      developer_page = "https://developers.facebook.com"      
      puts "★　go to #{developer_page} and enter our app_secret: "
      config[:app_secret] = STDIN.gets.chomp
      log(:info, "app_secret setup success #{config[:app_id]}")
    end

    def save_config_file
      File.open(config_file, 'w') do |f|
        conf = {
          "app_id" => config[:app_id],
          "app_secret" => config[:app_secret],
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
      log(:info, "session file load success #{config[:access_token]}")
    rescue Errno::ENOENT #file not found
      return false
    end

    def save_session_file
      hash = {"access_token" => config[:access_token]}
      File.open(session_file, "w") { |f| f.write hash.to_yaml } 
      log(:info, "session file save success at #{session_file}")
    end

    def exchange_long_term_token
      oauth = Koala::Facebook::OAuth.new(config[:app_id], config[:app_secret]) 
      new_token = oauth.exchange_access_token_info(config[:access_token])
      if new_token["access_token"]
        config[:access_token] = new_token["access_token"]
        log(:info, "long term access token exchanged success")
      else
        log(:error, "long term access token exchanged failed")
        raise Exception.new("can not accquire new access token") unless new_token["access_token"]
      end
    end

    def grant_access
      app_id = config[:app_id]
      redirect_uri = config[:redirect_uri]
      permission = config[:permission]
      puts "showing dialog"
      get_access_url  =
        "https://www.facebook.com/v#{config[:facebook_api_version]}/dialog/oauth?client_id=#{app_id}&scope=#{permission}&redirect_uri=#{redirect_uri}"
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
      log(:info, "setup access token success: #{token}")
    end

    def setup_feed_login_email
       puts "★ Facebook email login to access news feed:"
       fb_email = STDIN.gets.chomp
       config[:fb_email] = fb_email
    end

    def setup_feed_login_password
       puts "★ Facebook password login to access news feed:"
       fb_password = STDIN.noecho(&:gets).chomp
       config[:fb_password] = fb_password
    end

    def setup_feed_login
      scwd=File.dirname(__FILE__)
      bypass_second_check=false
      if File.exists?("#{config[:fb_cookiejar]}")
        out = `casperjs --ssl-protocol=tlsv1 --user-agent="#{config[:user_agent]}" --cookies-file=#{config[:fb_cookiejar]} #{scwd}/facebook-check-login.js`
        if out.include? "false"
            FileUtils.rm("#{config[:fb_cookiejar]}")
            setup_feed_login_email
            setup_feed_login_password
        else
            log(:info, "facebook cookies are still good")
            bypass_second_check=true
        end
      else
        setup_feed_login_email
       	setup_feed_login_password
      end
      if not bypass_second_check
        out = `casperjs --ssl-protocol=tlsv1 --user-agent="#{config[:user_agent]}" --cookies-file="#{config[:fb_cookiejar]}" --email="#{config[:fb_email]}" --password="#{config[:fb_password]}" #{scwd}/facebook-login.js`
        if out.include? "false"
            log(:info, "setup facebook feed login failed")
            if File.exists?("#{config[:fb_cookiejar]}")
              FileUtils.rm("#{config[:fb_cookiejar]}")
            end
            raise Exception.new("login attempt failed");
        else
            log(:info, "setup facebook feed login success")
        end
      end
	  config[:fb_email]=""
	  config[:fb_password]=""
      
    end

    def login_flow
      unless config[:app_id]
        setup_app_id
      end
      unless config[:app_secret]
        setup_app_secret
      end
      unless config[:granted]
        grant_access
      end
      setup_feed_login
      save_config_file

      unless load_session_file 
        setup_token
        exchange_long_term_token
        save_session_file
      end
      log(:info, "login flow success")
    end

    def browse(url)
      Launchy.open(url)
    rescue
      puts "warning: can't open url"
    end
  end
  extend GetToken
end
