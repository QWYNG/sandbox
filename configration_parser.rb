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
  def initialize(name, map)
    @name = name
    @map = map
  end

  def generate_svg(x, y)
    svg = Victor::SVG.new
    svg.rect(x: x, y: y, width: 400, height: 50 * @map.size + 100, fill: 'lightgray', stroke: 'black')
    svg.text(@name, x: x + 100, y: y + 25, 'text-anchor' => 'middle', 'font-size' => 30)

    @map.each_with_index do |(key, value), index|
      y_position = y + (index) * 50 + 50
      svg.rect(x: x + 10, y: y_position, width: 180, height: 40, fill: 'lightgreen', stroke: 'black')
      svg.text("#{key} -> #{value}", x: x + 100, y: y_position + 25, 'text-anchor' => 'middle', 'font-size' => 20)
    end

    svg
  end

  def size
    @map.size
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
    tree = @config.tree
    diagram = Diagram.new(tree.name)
    print_element(@config.tree, diagram)
  end

  def print_element(element, diagram)
    case element.sort
    when :map
      diagram.add_map(MapDiagram.new(element.name, {1 => 2, 3 => 4}))
    when :list
      diagram.add_stack(StackDiagram.new(element.name, [:a, :b, :c]))
    when :edge
      puts "Edge: #{element.name}"
    else
      puts "Element: #{element.name}"
    end

    element.each_element do |child|
      print_element(child, diagram)
    end

    if element.parent.kind_of?(REXML::Document)
      diagram.save("#{element.name}.svg")
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