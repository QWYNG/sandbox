# frozen_string_literal: true

require_relative('result')
require 'nokogiri'

class MermaidConverter
  def self.convert(results)
    new(results).convert
  end

  def self.convert_join(results)
    new(results, joined: true).convert
  end

  def initialize(results, joined: false)
    @results = results

    @graphs = if joined
                build_joined_graphs(results)
              else
                build_graphs(results)
              end
  end

  def self.initialize_join(results); end

  def convert
    @graphs.map do |graph|
      <<~MERMAID
        graph TD
        #{graph}
      MERMAID
    end
  end

  private

  def build_graphs(results)
    results.map do |result|
      <<~NODE
        #{build_graph(result)}
      NODE
    end
  end

  def build_joined_graphs(results)
    first_result = results.shift

    first_node = <<~NODE
      #{xml_to_dynamic_mermaid(first_result.before_configuration, 'before_0')}
      #{xml_to_dynamic_mermaid(first_result.after_configuration, 'after_0')}
        before_0 -- "`**#{first_result.rule.label}**`" --> after_0
    NODE

    [results.map.with_index(1) do |result, i|
      <<~NODE
        #{xml_to_dynamic_mermaid(result.before_configuration, "before_#{i}")}
        after_#{i - 1} --> before_#{i}
        #{xml_to_dynamic_mermaid(result.after_configuration, "after_#{i}")}
        before_#{i} -- "`**#{result.rule.label}**`" --> after_#{i}
      NODE
    end.unshift(first_node).join("\n")]
  end

  def build_graph(result)
    <<~NODE
      #{xml_to_dynamic_mermaid(result.before_configuration, 'before')}
      #{xml_to_dynamic_mermaid(result.after_configuration, 'after')}
      before -- "`**#{result.rule.label}**`" --> after
    NODE
  end

  def xml_to_dynamic_mermaid(xml_string, prefix)
    mermaid = []
    xml = xml_string.gsub(/<\s/, '&lt; ').gsub(/<\s/, '&gt; ').gsub('"', '&quot')

    doc = Nokogiri::XML(xml)

    mermaid << "subgraph #{prefix}"

    doc.root.element_children.each do |child|
      element_to_mermaid(child, mermaid, prefix)
    end

    mermaid << 'end'
    mermaid.join("\n")
  end

  def element_to_mermaid(element, mermaid, prefix)
    element_name = element.name
    element_content = element.content.strip

    mermaid << "subgraph #{prefix}_#{element_name}[#{element_name}]"

    if element.element_children.empty?
      if element_name == 'k'
        mermaid << "#{element_name}_#{element_name}_#{prefix}[\"#{element_content}\"]"
      else
        element_content.to_s.each_line.with_index do |line, i|
          next if ['.Map', '.List'].include?(line)

          mermaid << "#{element_name}_#{element_name}_#{prefix}_#{i}[\"#{line}\"]"
        end
      end
    elsif (element.children - element.element_children).map(&:text).find { |text| text.include?('ListItem') }
      formated = extract_list_items(element_content)
    formated.each.with_index do |line, i|
        mermaid << "#{element_name}_#{element_name}_#{prefix}_#{i}[\"#{line}\"]"
      end
    else
      element.element_children.each_with_index do |child, i|
        element_to_mermaid(child, mermaid, "#{prefix}_#{element_name}_#{i}")
      end
    end

    mermaid << 'end'

    mermaid
  end

  def extract_list_items(input)
    items = []
    stack = []
    current_item = ''
    current_inside_item = ''
    inside_list_item = false

    input.each_char do |char|
      current_item += char

      if char == '('
        stack.push(char)
        inside_list_item = true if stack.size == 1 && current_item.strip.start_with?('ListItem')
      elsif char == ')'
        stack.pop
      end

      current_inside_item += char if inside_list_item

      # 括弧がすべて閉じられた場合
      next unless stack.empty? && inside_list_item

      items << clean_and_indent(current_item.strip)
      current_inside_item = ''
      current_item = ''
      inside_list_item = false
    end

    items
  end

  def clean_and_indent(input, indent_size = 2)
    # 各行の先頭と末尾の空白を削除し、複数スペースを1つにまとめる
    lines = input.lines.map(&:strip).reject(&:empty?) # 空行を削除
    indent_level = 0
  
    lines.map do |line|
      # 開き括弧が増えたらインデントを上げる
      current_indent = ' ' * (indent_level * indent_size)
      indent_level += line.count('(') - line.count(')')
      indent_level = [indent_level, 0].max # ネガティブな値を防ぐ
  
      "#{current_indent}#{line}"
    end.join("\n")
  end
    
end
