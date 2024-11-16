# ruby script.rb <script_file> <semantics_file> <modul>
# e.g. ruby script.rb k/sum.imp k/imp.md IMP

require 'open3'
require 'strings-ansi'
require 'cgi'
require 'optparse'
require 'curses'
require_relative 'rule'
require_relative 'configration_parser'

def wait_for_prompt(stdout)
  buffer = ''
  buffer << stdout.readpartial(1024) until buffer.include?('(gdb)')
  buffer
end

def run_gdb_command(command, stdin, stdout)
  stdin.puts(command)
  wait_for_prompt(stdout).split('(gdb)').first.strip
end

def extract_configration(string)
  string.match(%r{<T>(.*?)</T>}m)
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
      results << Result.new(rule, depth, extract_configration(first_out)) if match?(match_out)
    end

    until exited
      depth += 1
      step_out = run_gdb_command('k step', stdin, stdout)

      results.each do |result|
        result.after_configration = extract_configration(step_out) if result.depth == depth - 1
      end

      rules.each do |rule|
        match_out = run_gdb_command("k match #{rule.label} subject", stdin, stdout)
        results << Result.new(rule, depth, extract_configration(step_out)) if match?(match_out)
      end

      exited = exited_normally?(step_out)
    end

    stdin.puts('quit')
    stdin.close
  end

  results
end

Result = Struct.new(:rule, :depth, :before_configration, :after_configration)

def display_slide(win, result)
  win.clear
  row = 0
  win.setpos(row, 0)
  win.addstr("Depth - #{result.depth}")
  win.setpos(row += 1, 0)
  win.addstr('Before Configuration:')
  Strings::ANSI.sanitize(result.before_configration.to_s).each_line do |line|
    win.setpos(row += 1, 2)
    win.addstr(line)
  end
  win.setpos(row += 2, 0)
  win.addstr("Rewrite Rule: #{result.rule&.label}")
  result.rule&.rewrite_rule&.each_line do |line|
    win.setpos(row += 1, 2)
    win.addstr(line)
  end
  win.setpos(row += 2, 0)
  win.addstr('After Configuration:')
  Strings::ANSI.sanitize(result.after_configration.to_s).each_line do |line|
    win.setpos(row += 1, 2)
    win.addstr(line)
  end
  win.setpos(row += 2, 0)
  win.addstr("<-- Use a/d keys to navigate, 'q' to quit -->")
  win.refresh
end

def generate_svg(results)
  init_result = results.shift

  init_configuration = InitConfiguration.new(Strings::ANSI.sanitize(init_result.before_configration.to_s))

  results.each do |result|
    before_config = Configuration.new(Strings::ANSI.sanitize(result.before_configration.to_s), init_configuration)
    PrintConfiguration.new(before_config).print("output#{result.depth}_before")
    after_config = Configuration.new(Strings::ANSI.sanitize(result.after_configration.to_s), init_configuration)
    PrintConfiguration.new(after_config).print("output#{result.depth}_after")
  end
end

script_file, semantics_file = ARGV
opts = OptionParser.new
Option = { out: 'tui' }
opts.on('-o FORMAT') do |v|
  Option[:out] = v
end
opts.parse!(ARGV)

results = run_k("#{script_file} --debugger", rules: Rule.get_rules(semantics_file, './imp-kompiled/'))

puts "\rGeneration complete!"

if Option[:out] == 'svg'
  filename = 'output'
  generate_svg(results)
  puts "#{filename} generated"
else
  Curses.init_screen
  begin
    Curses.curs_set(0)
    win = Curses.stdscr
    result_index = 0

    display_slide(win, results[result_index])

    loop do
      case win.getch
      when 'd'
        result_index += 1 if result_index < results.size - 1
      when 'a'
        result_index -= 1 if result_index.positive?
      when 'q'
        break
      end
      display_slide(win, results[result_index])
    end
  ensure
    Curses.close_screen
  end
end
