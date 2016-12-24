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
	@term_height, @term_width = get_term_size
	if path.blank?
		puts "post doesn't contain image"
		return
	end
        @fit_terminal = !!options[:fit_terminal]
        @double = !!options[:double]

	@full_width = false
	@draw_method = options[:draw_method] #set to :caca or :termpic or :fbi
        @fit_terminal = true

        if @full_width
                @view_width = [@term_height,@term_width].max
                @view_height = [@term_height,@term_width].max
        else
                @view_width = @term_width
                @view_height = @term_height
        end

	case @draw_method
	when :caca
	        @image = Magick::ImageList.new(path)
	when :termpic
	        @image = Magick::ImageList.new(path)
	else
		puts "viewer unset"
	end

      rescue Exception => e
        p e.message
      end

      def draw
        if @draw_method == :caca
                draw_caca
        else
                draw_termpic
        end
      end

      def draw_termpic
        convert_to_fit_terminal_size if @fit_terminal
        rgb_analyze
        ansi_analyze
        puts_ansi
      end

      def draw_caca
        @canvas = Caca::Canvas.new(@view_width, @view_height)
        puts "created canvas"
        @orig_image = @image
        #@image = @image.quantize(4294967295, Magick::RGBColorspace, Magick::NoDitherMethod, 0, false)
        @image = @image.quantize(4294967295, Magick::RGBColorspace, Magick::RiemersmaDitherMethod, 0, false)
        #@image = @image.quantize(4294967295, Magick::GRAYColorspace, Magick::RiemersmaDitherMethod, 0, false)
        @image = @image.resize_to_fit(@view_width, @view_height)
        #@image = @image.resize_to_fill(@view_width, @view_height, Magick::CenterGravity)
        @dither = Caca::Dither.new(24, @image.columns, @image.rows, @image.columns*3, 0x0000ff, 0x00ff00, 0xff0000, 0)
       	@pixels = @image.export_pixels_to_str(0, 0, @image.columns, @image.rows)
        @dither.set_algorithm("fstein")
	#@dither.set_charset("ascii");
	#@dither.set_charset("shades");
	#@dither.set_charset("blocks");
        #@dither.set_algorithm("none")
        #@dither.set_algorithm("ordered2")
        #@dither.set_algorithm("ordered4")
        #@dither.set_algorithm("ordered8")
        @canvas.dither_bitmap(0, 0, @image.columns, @image.rows, @dither, @pixels)
        puts @canvas.export_to_memory("ansi")
      end

      def convert_to_fit_terminal_size
        #term_height, term_width = get_term_size
        #term_width = term_width / 2 if @double
        @orig_image = @image
        @image = @image.resize_to_fit(@view_width, @view_height)
        #@image = @image.resize_to_fill(view_width, view_height)
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
