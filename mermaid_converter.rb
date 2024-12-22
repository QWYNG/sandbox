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
      #{xml_to_dynamic_mermaid(result.before_configration, "T#{result.depth}")}
    NODE
  end

  def xml_to_dynamic_mermaid(xml, prefix = 'T')
    mermaid = []

    prefix = prefix
    doc = Nokogiri::XML(xml)

    mermaid << "subgraph #{prefix}[\"<T>\"]"

    # ルート直下の要素
    doc.root.element_children.each do |child|
      child_name = child.name
      child_content = child.content.strip

      if child.element_children.empty?
        # 子要素を持たないノード
        mermaid << "    #{prefix}_#{child_name}[\"<#{child_name}> #{child_content} </#{child_name}>\"]"
      else
        # 子要素を持つノード（サブグラフとして描画）
        mermaid << "    subgraph #{prefix}_#{child_name}[\"<#{child_name}>\"]"
        child.element_children.each do |sub_child|
          sub_child_name = sub_child.name
          sub_child_content = sub_child.content.strip
          mermaid << "        #{prefix}_#{sub_child_name}[\"#{sub_child_name}: #{sub_child_content}\"]"
        end
        mermaid << '    end'
      end
    end

    mermaid << 'end'
    mermaid.join("\n")
  end
end
