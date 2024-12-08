# frozen_string_literal: true

require 'rmagick'

class SvgToPng # rubocop:disable Style/Documentation
  def self.convert(svg_path)
    image = Magick::Image.read(svg_path) { |img| img.format = 'SVG' }.first
    image.write(svg_path.sub('.svg', '.png')) { |img| img.format = 'PNG' }
  end
end
