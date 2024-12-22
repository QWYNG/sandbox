# frozen_string_literal: false

require 'open3'
require 'cgi'
require 'optparse'
require 'strings-ansi'
require_relative 'rule'
require_relative 'mermaid_converter'
require_relative 'result'

def wait_for_prompt(stdout)
  buffer = ''
  buffer << stdout.readpartial(1024) until buffer.include?('(gdb)')
  buffer
end

def run_gdb_command(command, stdin, stdout)
  stdin.puts(command)
  wait_for_prompt(stdout).split('(gdb)').first.strip
end

def extract_configuration(string)
  Strings::ANSI.sanitize(string.match(%r{<T>(.*?)</T>}m).to_s)
end

def exited_normally?(string)
  string.include?('exited normally')
end

def match?(string)
  string.include?('Match succeeds')
end

def run_k(opt, rules:)
  results = []

  Open3.popen3("krun #{opt}") do |stdin, stdout, _stderr, wait_thr|
    wait_thr.pid
    wait_for_prompt(stdout)
    first_out = run_gdb_command('k start', stdin, stdout)

    exited = false
    depth = 0

    results << Result.new(Rule.new(label: 'Initial Configuration', rewrite_rule: ''), depth,
                          extract_configration(first_out))
    rules.each do |rule|
      match_out = run_gdb_command("k match #{rule.label} subject", stdin, stdout)
      results << Result.new(rule, depth, extract_configuration(first_out)) if match?(match_out)
    end

    until exited
      depth += 1
      step_out = run_gdb_command('k step', stdin, stdout)

      results.each do |result|
        result.after_configuration = extract_configuration(step_out) if result.depth == depth - 1
      end

      rules.each do |rule|
        match_out = run_gdb_command("k match #{rule.label} subject", stdin, stdout)
        results << Result.new(rule, depth, extract_configuration(step_out)) if match?(match_out)
      end

      exited = exited_normally?(step_out)
    end

    stdin.puts('quit')
    stdin.close
  end

  results
end

script_file, semantics_file = ARGV

require 'pathname'

kompiled_name = Pathname.new(semantics_file).basename.sub_ext('').to_s
rules = Rule.get_rules(semantics_file, "./#{kompiled_name}-kompiled/")
pp rules.map(&:label)
results = run_k("#{script_file} --debugger", rules:)
mermaids = MermaidConverter.convert(results)
mermaids.each_with_index do |mermaid, i|
  File.write("out/mermaid#{i}.md", mermaid)
end
