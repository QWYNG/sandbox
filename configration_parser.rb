require 'rexml/document'
require 'strings-ansi'
require 'victor'
require 'nokogiri'

module REXML
  class Element
    attr_accessor :sort
  end
end

class StackDiagram
  def initialize(name, stack_string)
    @name = name
    @stack = stack_string.strip.split("\n").map(&:strip)
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x:, y:, width: 400 + @stack.max { |x, y|
      x.size <=> y.size
    } * 50, height: 50 * @stack.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 25, 'text-anchor' => 'middle')

    @stack.each_with_index do |element, index|
      y_position = y + index * 50 + 50
      svg.rect(x: x + 10, y: y_position, width: 180, height: 40, fill: 'lightblue', stroke: 'black')
      svg.text(element.to_s, x: x + 100, y: y_position + 20, 'text-anchor' => 'middle', 'font-size' => 20)
    end

    svg
  end

  def size
    @stack.size
  end
end

class MapDiagram
  def initialize(name, map_string)
    @name = CGI.unescapeHTML(name)
    @map = CGI.unescapeHTML(map_string).strip.split("\n").map do |line|
      key, value = line.split('|->').map(&:strip)
      [key.to_sym, value.to_s]
    end.to_h
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x:, y:, width: 200 + @map.max { |x, y|
      x.to_s.size <=> y.to_s.size
    }.join.size * 50, height: 50 * @map.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 25, 'text-anchor' => 'middle')

    @map.each_with_index do |(key, value), index|
      y_position = y + index * 50 + 50
      svg.rect(x: x + 10, y: y_position, width: 180, height: 40, fill: 'lightgreen', stroke: 'black')

      if value.empty?
        svg.text(key.to_s, x: x + 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)
      else
        svg.text("#{key} -> #{value}", x: x + 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)
      end
    end

    svg
  end

  def size
    @map.size
  end
end

class NamespaceDiagram
  def initialize(name, children_count = 0)
    @name = name
    @children_count = children_count
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x:, y:, width: 500, height: 400 * @children_count + 50, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 50, 'text-anchor' => 'middle')

    svg
  end
end

class StringDiagram
  def initialize(name, value)
    @name = CGI.unescapeHTML(name)
    @value = CGI.unescapeHTML(value)
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x:, y:, width: 200 + @value.size * 10, height: 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 50, 'text-anchor' => 'middle')
    svg.text(@value, x: x + 20, y: y + 75, 'font-size' => 20)

    svg
  end
end

class Diagram
  def initialize(name)
    @name = name
    @svg = Victor::SVG.new(width: '100000px', height: '100000px')
    @current_x = 1
    @current_y = 1
  end

  def add_map(map_diagram)
    map_svg = map_diagram.generate_svg(@current_x, @current_y)
    @svg.append(map_svg)
    @current_x += 0
    @current_y += 50 * map_diagram.size + 100
  end

  def add_stack(stack_diagram)
    stack_svg = stack_diagram.generate_svg(@current_x, @current_y)
    @svg.append(stack_svg)
    @current_x += 0
    @current_y += 50 * stack_diagram.size + 100
  end

  def add_namespace(namespace_diagram)
    namespace_svg = namespace_diagram.generate_svg(@current_x, @current_y)
    @svg.append(namespace_svg)
    @current_x += 0
    @current_y += 60
  end

  def add_string(string_diagram)
    string_svg = string_diagram.generate_svg(@current_x, @current_y)
    @svg.append(string_svg)
    @current_x += 0
    @current_y += 100
  end

  def add_related_rule(rule)
    @svg.rect(x: @current_x, y: @current_y, width: 400 + rule.rewrite_rule.size * 4,
              height: 50 * rule.rewrite_rule.lines.size + 50, fill: 'lightgray', stroke: 'black')
    @svg.text("Rewrite rule: #{rule.label}", x: @current_x + 20, y: @current_y + 20)
    @svg.foreignObject(x: @current_x + 10, y: @current_y + 40, width: 400 + rule.rewrite_rule.size * 8, height: 200) do
      @svg.html(xmlns: 'http://www.w3.org/1999/xhtml') do
        rule.rewrite_rule.each_line do |line|
          @svg.h3(line)
        end
      end
    end

    @current_y += 50 * rule.rewrite_rule.lines.size + 50
  end

  def save(file_name = 'combined_diagram.svg')
    @svg.save(file_name)
  end
end

class InitConfiguration
  attr_accessor :tree

  def initialize(xml_str)
    escaped_xml_string = xml_str.gsub(%r{<k>(.*?)</k>}m) do |_match|
      inner_text = ::Regexp.last_match(1).strip # <k>と</k>の間のテキスト
      escaped_text = CGI.escapeHTML(inner_text) # エスケープ処理
      "<k>#{escaped_text}</k>"
    end

    doc = Nokogiri::XML(escaped_xml_string)

    # タグ以外の内容をエスケープ
    doc.traverse do |node|
      node.content = CGI.escapeHTML(node.content.strip) if node.text?
    end

    xml_str = doc.to_s

    @tree = REXML::Document.new(xml_str).root

    @tree.each_element do |element|
      parse_element(element)
    end
  end

  def parse_element(element)
    element.each_element do |child|
      parse_element(child)
    end

    element.sort = case element.text&.strip
                   in '.Map'
                     :map
                   in '.List'
                     :list
                   in ''
                     :namespace
                   else
                     :string
                   end
  end
end

class Configuration
  attr_accessor :tree

  def initialize(xml_str, init_configuration)
    escaped_xml_string = xml_str.gsub(%r{<k>(.*?)</k>}m) do |_match|
      inner_text = ::Regexp.last_match(1).strip # <k>と</k>の間のテキスト
      escaped_text = CGI.escapeHTML(inner_text) # エスケープ処理
      "<k>#{escaped_text}</k>"
    end

    doc = Nokogiri::XML(escaped_xml_string)

    doc.traverse do |node|
      node.content = CGI.escapeHTML(node.content.strip) if node.text?
    end

    xml_str = doc.to_s
    @init_configuration = init_configuration
    @tree = REXML::Document.new(xml_str).root
    @tree.each_element do |element|
      parse_element(element)
    end
  end

  def parse_element(element)
    element.each_element do |child|
      parse_element(child)
    end

    init_element = @init_configuration.tree.get_elements(element.xpath).first
    element.sort = init_element.sort if init_element
  end
end

class PrintConfiguration
  def initialize(result, init_configuration)
    @result = result
    @before_configration = Configuration.new(Strings::ANSI.sanitize(result.before_configration.to_s),
                                             init_configuration)
    @after_configration = Configuration.new(Strings::ANSI.sanitize(result.after_configration.to_s), init_configuration)
  end

  def print(filename)
    diagram = Diagram.new(@before_configration.tree.name)
    print_element(@before_configration.tree, diagram, filename)
    diagram.add_related_rule(@result.rule)
    print_element(@after_configration.tree, diagram, filename)
    diagram.save("#{filename}.svg")
  end

  def print_element(element, diagram, filename)
    case element.sort
    when :map
      diagram.add_map(MapDiagram.new(element.name, element.text))
    when :list
      diagram.add_stack(StackDiagram.new(element.name, element.text))
    when :namespace
      diagram.add_namespace(NamespaceDiagram.new(element.name, element.elements.size))
    when :string
      diagram.add_string(StringDiagram.new(element.name, element.text))
    else
      puts "Element: #{element.name}"
    end

    element.each_element do |child|
      print_element(child, diagram, filename)
    end
  end
end
