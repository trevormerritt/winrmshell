#!/usr/bin/env ruby
require 'winrm'
require 'winrm-fs'
require 'optparse'
require 'ostruct'
require 'byebug'
$stderr.sync = true
require 'optparse'

QUIT_CODE = '!!QUIT!!'

# default options
user    = ''
pass    = ''
host    = ''
shell   = 'CMD'

def fail_on_connect
  exit 'Unable to connect.'
end

def open_shell(host, user, pass, shell)
  connection = WinRM::Connection.new(
    endpoint: "http://#{host}:5985/wsman",
    user: user,
    password: pass
  )

  fail_on_connect if connection.nil?

  puts "Connected!"
  command = ''
  while command != QUIT_CODE
    # send the command to the server and get the results.
    connection.shell(:cmd) do |shell|
      print ":>"
      command = gets.chomp
      unless command.length.zero? || command === QUIT_CODE
        shell.run(command) do |stdout, stderr|
          out = stdout.nil? ? '' : stdout.strip
          err = stderr.nil? ? '' : stderr.strip
          puts out unless out.length.zero?
          puts err unless err.length.zero?
        end
      end
    end
  end

  print "Disconnecting.."
  connection.close
  puts ".done."
end

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on('-u', '--user=val', String)   { |val| user = val }
  opts.on('-p', '--pass=val', String)   { |val| pass = val }
  opts.on('-h', '--host=val', String)   { |val| host = val }
  opts.on('--cmd')                      { shell = 'CMD'}
  opts.on('--ps')                       { shell = 'POWERSHELL'}
  opts.on_tail('-h', '--help')          { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!

  # check for options
  errors = []
  errors.push('Username required') if user.length.zero?
  errors.push('Password required') if pass.length.zero?
  errors.push('Host required') if host.length.zero?

  unless errors.size.zero?
    print 'Invalid Options: '
    bad_options = ''
    errors.each do |error|
      bad_options += "#{error}, "
    end
    puts bad_options[0..(bad_options.length - 3)]
    puts opts
    exit
  end

  # we have no errors in our options.
  # time to go
  # do your thing
  open_shell(host, user, pass, shell)
end
