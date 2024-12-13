# frozen_string_literal: true

input_file = 'k/kool.md'
output_file = ARGV[0]
rules_to_disable = %w[declare
   declares
   lookup
   return
   tryCatch
   throw
   spawn
   threadTerminate
   join
   acquireLock
   acnquireWait
   release
   releaseFree
   rendezvous
   class
   extends
   new
   createClass
   createObject
   setCrntClass
   addEnvLayer
   storeObj
   this
   thisX
   objectclosure
   super
   method
   application]

   rule_pattern = /^\s*rule\s*\[#{rules_to_disable.join('|')}\]:\s*/
   updated_content = File.read(input_file).gsub(rule_pattern, 'rule')
File.write(output_file, updated_content)
