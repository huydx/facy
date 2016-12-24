module Facy
  module Core
    def me
      @me
    end

    def config
      @config ||= {}
    end

    def inits
      @inits ||= []
    end

    def init(&block)
      inits << block
    end

    def config_file
      config_file_folder = "/tmp"
      config_file_name = ".facy_config.yml"
      File.expand_path(config_file_name, config_file_folder)
    end

    def _init
      load_config
      login_flow
      inits.each { |block| class_eval(&block) }
      set_me
      log(:info, "core module init success")
    end

    def set_me
      @me = facebook_me
    end

    def load_config
      config.reverse_update(default_config)
      log(:info, "config loaded #{config.to_s}")
    end

    def default_config
      default_conf_file = File.expand_path("../../../config.yml", __FILE__)
      file = File.exist?(config_file) ? config_file : default_conf_file

      config = YAML.load_file(file)
      {
        session_file_folder: "~",
        session_file_name: ".facy_access_token.yml",
        log_folder: "/tmp",
        log_file_name: ".facy_log",
        app_id: config['app_id'],
        app_secret: config['app_secret'],
        permission: config['permission'],
        granted: config['granted'],
        redirect_uri: "http://www.facebook.com/connect/login_success.html",
        prompt: "\e[15;48;5;27m f \e[0m >> ",
        stream_fetch_interval: 60, #2 - original
        notification_fetch_interval: 60, #2 - original
        output_interval: 3, #3 - original
        retry_interval: 2,
        comments_view_num: 10,
        fb_name: "",
        fb_password: "",
        fb_cookiejar: "~/fb-cookies.txt",
        external_image_viewer: "eog",
        external_movie_viewer: "",
        external_www_browser: "firefox",
        pause_output: false,
        utilize_emojis: true, 
        unread_notifications_only: false,
        notification_pages: 1,
        news_feed_pages: 10,
        show_latest_newsfeed: true,
        user_agent: "Mozilla/5.0 (X11; Linux i686 on x86_64; rv:45.0) Gecko/20100101 Firefox/45.0)",
        id_timestamp_last_news_feed: 0,
        id_timestamp_last_notifications: 0,
        facebook_api_version: "2.8",
      }
    end

    def start(options={})
      _init

      EM.run do
        Thread.start do
          while buf = Readline.readline(config[:prompt], true)
            execute(buf.strip)
          end
        end

        Thread.start do
          EM.add_periodic_timer(config[:stream_fetch_interval]) do
            if not config[:pause_output]
              facebook_stream_fetch
            end
          end
        end

        Thread.start do
          EM.add_periodic_timer(config[:output_interval]) do
            if not config[:pause_output]
              periodic_output
            end
          end
        end

        Thread.start do
          EM.add_periodic_timer(config[:notification_fetch_interval]) do
            if not config[:pause_output]
              facebook_notification_fetch
            end
          end
        end

        Signal.trap("INT")  { stop_process }
        Signal.trap("TERM") { stop_process }
      end
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def sync(&block)
      mutex.synchronize do
        block.call
      end
    end

    def async(&block)
      Thread.start { block.call }
    end

    def stop_process
      puts "\nfacy going to stop..."
      Thread.new {
        EventMachine.stop
      }.join
    end
  end

  extend Core
end
