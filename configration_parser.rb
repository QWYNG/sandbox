require 'rexml/document'

class REXML::Element
  attr_accessor :sort
end

require 'victor'


class StackDiagram
  def initialize(name, stack)
    @name = name
    @stack = stack
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x: x, y: y, width: 400, height: 50 * @stack.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 25, 'text-anchor' => 'middle', 'font-size' => 30)

    @stack.each_with_index do |element, index|
      y_position = y + (index) * 50 + 50
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
    @name = name
    @map = map_string.strip.split("\n").map do |line|
      key, value = line.split('|->').map(&:strip)
      [key.to_sym, value.to_s]
    end.to_h
    
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x: x, y: y, width: 400, height: 50 * @map.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 25, 'text-anchor' => 'middle', 'font-size' => 30)

    @map.each_with_index do |(key, value), index|
      y_position = y + (index) * 50 + 50
      svg.rect(x: x + 10, y: y_position, width: 180, height: 40, fill: 'lightgreen', stroke: 'black')

      if value.empty?
        svg.text("#{key}", x: x + 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)        
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
    svg.text(@name, x: x + 100, y: y + 50, 'text-anchor' => 'middle', 'font-size' => 30)

    svg
  end
end

class StringDiagram
  def initialize(name, value)
    @name = name
    @value = value
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x: x, y: y, width: 400, height: 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 50, 'text-anchor' => 'middle', 'font-size' => 30)
    svg.text(@value, x: x + 100, y: y + 75, 'text-anchor' => 'middle', 'font-size' => 20)

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

  def save(file_name = "combined_diagram.svg")
    @svg.save(file_name)
  end
end


class InitConfiguration
  attr_accessor :tree

  def initialize(xml_str)
    @tree = REXML::Document.new(xml_str).root

    @tree.each_element do |element|
      parse_element(element)
    end
  end

  def parse_element(element)
    element.each_element do |child|
      parse_element(child)
    end
    
    case element.text.strip
    in '.Map'
      element.sort = :map
    in '.List'
      element.sort = :list
    in ''
      element.sort = :namespace
    else
      element.sort = :string
    end
  end
end

class Configuration
  attr_accessor :tree

  def initialize(xml_str, init_configuration)
    @tree = REXML::Document.new(xml_str).root
    @init_configuration = init_configuration

    @tree.each_element do |element|
      parse_element(element)
    end
  end

  def parse_element(element)
    element.each_element do |child|
      parse_element(child)
    end

    init_element = @init_configuration.tree.get_elements(element.xpath).first
    element.sort = init_element.sort
  end
end

class PrintConfiguration
  def initialize(config)
    @config = config
  end

  def print(filename)
    tree = @config.tree
    diagram = Diagram.new(tree.name)
    print_element(@config.tree, diagram, filename)
  end

  def print_element(element, diagram, filename)
    case element.sort
    when :map
      diagram.add_map(MapDiagram.new(element.name, element.text))
    when :list
      diagram.add_stack(StackDiagram.new(element.name, [:a, :b, :c]))
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

    if element.parent.kind_of?(REXML::Document)
      diagram.save("#{filename}.svg")
    end
  end
end
