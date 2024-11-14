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

  def generate_svg(file_name = "stack_diagram.svg")
    svg = Victor::SVG.new(width: 200, height: 50 * @stack.size + 100)
    svg.rect(x: 0, y: 0, width: 200, height: 50 * @stack.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: 100, y: 25, 'text-anchor' => 'middle', 'font-size' => 30)

    @stack.each_with_index do |element, index|
      y_position = (index) * 50 + 100
      svg.rect(x: 10, y: y_position, width: 180, height: 40, fill: 'lightblue', stroke: 'black')
      svg.text(element.to_s, x: 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)
    end

    svg.save(file_name)
  end
end

class MapDiagram
  def initialize(name, map)
    @name = name
    @map = map
  end

  def generate_svg(file_name = "map_diagram.svg")
    svg = Victor::SVG.new(width: 200, height: 50 * @map.size + 100)
    svg.rect(x: 0, y: 0, width: 200, height: 50 * @map.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: 100, y: 25, 'text-anchor' => 'middle', 'font-size' => 30)

    @map.each_with_index do |(key, value), index|
      y_position = (index) * 50 + 100
      svg.rect(x: 10, y: y_position, width: 180, height: 40, fill: 'lightgreen', stroke: 'black')
      svg.text("#{key} => #{value}", x: 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)
    end

    svg.save(file_name)
  end
end

class Diagram
  def initialize(name)
    @name = name
    @svg = Victor::SVG.new(width: 1000, height: 1000)
    @current_x = 0
    @current_y = 0
  end

  def add_map(map_diagram)
    
  end

  def add_stack(element)
  end

  def save(file_name = "combined_diagram.svg")
    @svg.save(file_name)
  end
end


class Configuration
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
    when '.Map'
      element.sort = :map
    when '.List'
      element.sort = :list
    else
      element.sort = :edge  
    end
  end
end

class PrintConfiguration
  def initialize(config)
    @config = config
  end

  def print
    print_element(@config.tree)
  end

  def print_element(element)
    case element.sort
    when :map
      MapDiagram.new(element.name, {}).generate_svg
    when :list
      StackDiagram.new(element.name, []).generate_svg
    when :edge
      puts "Edge: #{element.name}"
    else
      puts "Element: #{element.name}"
    end

    element.each_element do |child|
      print_element(child)
    end
  end
end


xml = <<XML
<T color="yellow">
  <k color="green"> $PGM:Pgm </k>
  <state color="red"> .Map </state>
  <stack color="blue"> .List </stack>
</T>
XML

config = Configuration.new(xml)
PrintConfiguration.new(config).print