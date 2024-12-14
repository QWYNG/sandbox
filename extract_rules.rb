# frozen_string_literal: true

input_file = 'k/kool.md'
output_file = ARGV[0]
rules_to_disable = [
  'declare',
  'declares',
  'lookup',
  'return',
  'tryCatch',
  'throw',
  'spawn',
  'threadTerminate',
  'join',
  'acquireLock',
  'acquireWait',
  'release',
  'releaseFree',
  'rendezvous',
  'class',
  'extends',
  'new',
  'createClass',
  'createObject',
  'setCrntClass',
  'addEnvLayer',
  'storeObj',
  'this',
  'thisX',
  'objectclosure',
  'super',
  'method',
  'application',
  'sum'
]

rule_pattern = /rule\s\[(#{rules_to_disable.join('|')})\]:/
updated_content = File.read(input_file).gsub(rule_pattern, 'rule')
File.write(output_file, updated_content)
