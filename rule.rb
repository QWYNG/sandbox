class Rule
  def self.get_rules(file)
    rules = []
    text = File.read(file)
    pattern = %r{rule\s\[(?<label>\w+)\]:\s(?<rule>[\s\S]*?)(?=\s*requires|$)}
  
    text.scan(pattern).each do |match|
      match.compact!
      rule = Rule.new(label: match[0], rewrite_rule: match[1])
    
      rules << rule
    end
  
    rules
  end
  
  attr_accessor :label, :rewrite_rule

  def initialize(label:, rewrite_rule:)
    @label = label
    @rewrite_rule = rewrite_rule
  end
end