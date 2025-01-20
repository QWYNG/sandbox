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
        #{xml_to_dynamic_mermaid(result.after_configuration, "after_#{i}")}
        after_#{i - 1} -- "`**#{result.rule.label}**`" --> after_#{i}
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
    else
      element.element_children.each_with_index do |child, i|
        element_to_mermaid(child, mermaid, "#{prefix}_#{element_name}_#{i}")
      end
    end

    mermaid << 'end'

    mermaid
  end
end
