# frozen_string_literal: true

require_relative('result')
require 'nokogiri'

class MermaidConverter
  def self.convert(results)
    new(results).convert
  end

  def initialize(results)
    @results = results
    @graphs = build_graphs(results)
  end

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

  def build_graph(result)
    <<~NODE
      #{xml_to_dynamic_mermaid(result.before_configuration, 'before')}
      #{xml_to_dynamic_mermaid(result.after_configuration, 'after')}
      before -- "`**#{result.rule.label}**`" --> after
    NODE
  end

  def xml_to_dynamic_mermaid(xml, prefix)
    mermaid = []

    prefix = prefix
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
      mermaid << "#{element_name}_#{element_name}_#{prefix}[\"#{element_content}\"]"
    else
      element.element_children.each do |child|
        mermaid << element_to_mermaid(child, mermaid, prefix)
      end
    end

    mermaid << 'end'

    mermaid
  end
end
