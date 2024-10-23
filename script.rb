require 'open3'
require 'strings-ansi'
require 'cgi'

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

Result = Struct.new(:rule, :depth, :before_configration, :after_configration)

def run_k(opt, modul:, rules:)
  results = []

  Open3.popen3("krun #{opt}") do |stdin, stdout, _stderr, wait_thr|
    pid = wait_thr.pid
    puts "pid: #{pid}"
    wait_for_prompt(stdout)
    run_gdb_command('k start', stdin, stdout)

    exited = false
    depth = 0

    until exited
      depth += 1
      step_out = run_gdb_command('k step', stdin, stdout)

      results.each do |result|
        result.after_configration = extract_configration(step_out) if result.depth == depth - 1
      end

      rules.each do |rule|
        match_out = run_gdb_command("k match #{modul}.#{rule.label} subject", stdin, stdout)
        results << Result.new(rule, depth, extract_configration(step_out)) if match?(match_out)
      end

      exited = exited_normally?(step_out)
    end

    stdin.puts('quit')
    stdin.close
  end

  results
end

Rule = Struct.new(:label, :rewrite_rule)
def get_rules(file)
  rules = []
  text = File.read(file)
  pattern = %r{rule\s\[(\w+)\]:\s*((?:<\w+>[\s\S]*?</\w+>\s*)+)(?:\s*requires[\s\S]*?)?}

  text.scan(pattern).each do |match|
    match.compact!
    rule = Rule.new
    rule.label = match[0]
    rule.rewrite_rule = match[1]
    rules << rule
  end

  rules
end

def generate_html(results)
  html = <<~HTML
    <!DOCTYPE html>
    <html lang="ja">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Configuration Slideshow</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100%;
                margin: 0;
            }
            .slideshow-container {
                width: 60%;
                background-color: #f8f8f8;
                padding: 20px;
                border: 1px solid #ddd;
                box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
                position: relative;
            }
            .slide {
                display: none;
            }
            .active {
                display: block;
            }
            .navigation {
                position: absolute;
                top: 100%;
                width: 100%;
                display: flex;
                justify-content: space-between;
                transform: translateY(-50%);
            }
            .prev, .next {
                background-color: #333;
                color: white;
                padding: 10px;
                cursor: pointer;
                user-select: none;
            }
            pre {
                background-color: #f8f8f8;
                padding: 10px;
                border: 1px solid #ddd;
                overflow-x: auto;
            }
        </style>
    </head>
    <body>

    <div class="slideshow-container">

      <div class="navigation">
        <span class="prev" onclick="changeSlide(-1)">&#10094; Prev</span>
        <span class="next" onclick="changeSlide(1)">Next &#10095;</span>
      </div>

  HTML

  results.each_with_index do |result, index|
    html += <<~HTML
          <div class="slide #{'active' if index.zero?}">
              <h2>Depth #{result.depth}</h2>
              <h3>Before Configuration</h3>
              <pre>
      #{CGI.escapeHTML(Strings::ANSI.sanitize(result.before_configration.to_s))}
              </pre>

              <h3>Rewrite Rule</h3>
              <h4>#{result.rule.label}</h4>
              <pre>
      #{CGI.escapeHTML(result.rule.rewrite_rule.to_s)}
              </pre>
              <h3>After Configuration</h3>
              <pre>
      #{CGI.escapeHTML(Strings::ANSI.sanitize(result.after_configration.to_s))}
              </pre>
          </div>
    HTML
  end

  html += <<~HTML
    <script>
        let currentSlide = 0;
        const slides = document.querySelectorAll('.slide');

        function showSlide(index) {
            slides.forEach((slide, i) => {
                slide.classList.remove('active');
                if (i === index) {
                    slide.classList.add('active');
                }
            });
        }

        function changeSlide(direction) {
            currentSlide = (currentSlide + direction + slides.length) % slides.length;
            showSlide(currentSlide);
        }

        // 初回スライド表示
        showSlide(currentSlide);
    </script>

    </body>
    </html>
  HTML

  html
end

script_file, semantics_file, modul = ARGV
results = run_k("#{script_file} --debugger", modul: modul, rules: get_rules(semantics_file))
File.write('slideshow.html', generate_html(results))
