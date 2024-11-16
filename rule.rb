# frozen_string_literal: true

class Rule
  def self.get_rules(file, kompiled_dir)
    parsed_txt = File.join(kompiled_dir, 'parsed.txt')
    semantics_txt = File.read(file).each_line.to_a

    rules = []

    File.read(parsed_txt).each_line do |line|
      next unless line.include?('rule') && line.include?('label')

      source_content = line.match(/Source\(([^)]+)\)/)[1]
      next if source_content.include?('builtin')

      start_line, start_column, end_line, end_column = line.match(/Location\((\d+),(\d+),(\d+),(\d+)\)/).captures.map do |x|
        x.to_i - 1
      end
      label = line.match(/label\(([^)]+)\)/).captures.first

      rewrite_rule = if start_line == end_line
                       semantics_txt[start_line][start_column..end_column]
                     else
                       semantics_txt[(start_line)..(end_line - 1)].join +
                         semantics_txt[end_line][..end_column]
                     end.strip

      rules << Rule.new(label: label, rewrite_rule: rewrite_rule)
    end

    rules
  end

  attr_accessor :label, :rewrite_rule

  def initialize(label:, rewrite_rule:)
    @label = label
    @rewrite_rule = rewrite_rule
  end
end
