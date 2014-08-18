module Facy
  module ImageViewer
    def view_img(path, options={})
      Image.new(path, options).draw
    end

    module AnsiRGB
      def self.wrap_with_code(string, rgb)
        red, green, blue = rgb[0], rgb[1], rgb[2]
        "\e[#{code(red, green, blue)}m" + string + "\e[0m"
      end

      def self.code(red, green, blue)
        index = 16 +
          to_ansi_domain(red) * 36 +
          to_ansi_domain(green) * 6 +
          to_ansi_domain(blue)
        "48;5;#{index}"
      end

      def self.to_ansi_domain(value)
        (6 * (value / 256.0)).to_i
      end
    end
  
    class Image
      def initialize(path, options={})
        @image = Magick::ImageList.new(path)
        @fit_terminal = !!options[:fit_terminal]
      rescue Exception => e
        p e.message
      end

      def draw
        convert_to_fit_terminal_size if @fit_terminal
        rgb_analyze
        ansi_analyze
        puts_ansi
      end

      def rgb_analyze
        @rgb = []
        cols = @image.columns
        rows = @image.rows
        rows.times do |y|
          cols.times do |x|
            @rgb[y] ||= []
            pixcel = @image.pixel_color(x, y)
            r = pixcel.red / 256
            g = pixcel.green / 256
            b = pixcel.blue / 256
            @rgb[y] << [r, g, b]
          end
        end
      end

      def ansi_analyze
        raise "use rgb_analyze before ansi_analyze" unless @rgb
        ret = []
        @rgb.map! do |row|
          ret << row.map{|pixcel|
            AnsiRGB.wrap_with_code(@double ? "  " : " ", pixcel)
          }.join
        end
        @ansi = ret.join("\n")
      rescue Exception => e
        error e.message
      end
      
      def puts_ansi
        raise "use ansi_analyze before to_ansi" unless @ansi
        puts @ansi
      end
      
      def get_term_size
        `stty size`.split(" ").map(&:to_i)
      end
    end
  end

  extend ImageViewer
end
