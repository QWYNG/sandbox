require "RMagick"

class SvgToPng # rubocop:disable Style/Documentation
  def self.convert(svg_path)
    Magick::Image.from_file(svg_path) do
      self.format = 'SVG'
      self.background_color = 'transparent'
    end
    img.write(svg_path.gsub(/svg$/, 'png'))
  end
end