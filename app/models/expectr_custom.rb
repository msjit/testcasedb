# = expectr.rb
#
#  Copyright (c) Chris Wuest <chris@chriswuest.com>
#  Expectr is freely distributable under the terms of an MIT-style license.
#  See COPYING or http://www.opensource.org/licenses/mit-license.php.

begin
	require 'pty'
rescue LoadError
	require 'popen4'
end

require 'timeout'
require 'thread'

# Fixes specifically for Ruby 1.8
if RUBY_VERSION =~ /^1.8/
	# Enforcing encoding is not needed in 1.8 (probably.)  So, we'll define
	# String#encode! to do nothing, for interoperability.
	class String #:nodoc:
		def encode!(encoding)
		end
	end

	# In Ruby 1.8, we want to ignore SIGCHLD.  This is for two reasons:
	# * SIGCHLD will be sent (and cause exceptions) for every Expectr object
	#   created
	# * As John Carter documented in his RExpect library, calls to files which
	#   do not exist can cause odd and unexpected behavior.
	trap 'CHLD', Proc.new { nil }
end

# == Description
# Expectr is an implementation of the Expect library in ruby (see
# http://expect.nist.gov).
#
# Expectr contrasts with Ruby's built-in Expect class by avoiding tying in
# with IO and instead creating a new object entirely to allow for more
# fine-grained control over the execution and display of the program being
# run.
#
# == Examples
# === Simple task automation
#
# Connect via telnet to remote.example.com, run my_command, and return the
# output
#
#   exp = Expectr.new "telnet remote.example.com"
#   exp.expect "username:"
#   exp.send "example\r"
#   exp.expect "password:"
#   exp.send "my_password\r"
#   exp.expect "%"
#   exp.send "my_command\r"
#   exp.expect "%"
#   exp.send "logout"
#
#   output = exp.discard
#
# === Interactive control
# Silently connect via ssh to remote.example.com, log in automatically, then
# relinquish control to the user.  Expect slow networking, so increase
# timeout.
#
#   exp = Expectr.new "ssh remote.example.com", :timeout=>45, :flush_buffer=>false
#
#   match = exp.expect /password|yes\/no/
#   case match.to_s
#     when /password/
#       exp.send "my_password\r"
#     when /yes\/no/
#       exp.send "yes\r"
#       exp.expect /password/
#       exp.send "my_password\r"
#     else
#       puts "Cannot connect to remote.example.com!"
#       die
#   end
#
#   exp.expect "$"
#   exp.interact
#
class ExpectrCustom
	# Amount of time in seconds a call to +expect+ may last (default 30)
	attr_accessor :timeout
	# Size of buffer in bytes to attempt to read in at once (default 8 KiB)
	attr_accessor :buffer_size
	# Whether to flush program output to STDOUT (default true)
	attr_accessor :flush_buffer
	
	attr_accessor :all_output
	# PID of running process
	attr_reader :pid
	# Active buffer to match against
	attr_reader :buffer
	# Buffer passed since last +expect+ match
	attr_reader :discard

	# 
	# === Synopsis
	#
	#   Expectr.new(cmd, args)
	#
	# === Arguments
	# +cmd+::
	#   Command to be executed (String or File)
	# +args+::
	#   Hash of modifiers for Expectr.  Meaningful values are:
	# * :buffer_size::
	#   Amount of data to read at a time.  Default 8 KiB
	# * :flush_buffer::
	#   Flush buffer to STDOUT during execution?  Default true
	# * :timeout::
	#   Timeout in seconds for each +expect+ call.  Default 30
	#
	# === Description
	#
	# Spawn +cmd+ and attach to STDIN and STDOUT for new process.  Fall back
	# to using Open4 if PTY is not present (this is the case on Windows
	# implementations of ruby.
  #
	def initialize(cmd, args={})
	  @logger_buffer = ""
	  
		raise ArgumentError, "String or File expected, was given #{cmd.class}" unless cmd.kind_of? String or cmd.kind_of? File
		cmd = cmd.path if cmd.kind_of? File

		args[0] = {} unless args[0]
		@buffer = String.new
		@discard = String.new
		@timeout = args[:timeout] || 30
		@flush_buffer = args[:flush_buffer].nil? ? true : args[:flush_buffer]
		@buffer_size = args[:buffer_size] || 8192
		@out_mutex = Mutex.new
		@out_update = false
		@all_output = String.new

		[@buffer, @discard].each {|x| x.encode! "UTF-8" }

		if defined? PTY
			@stdout,@stdin,@pid = PTY.spawn cmd
		else
			cmd << " 2>&1" if cmd[/2\s*>/].nil?
			@pid, @stdin, @stdout, stderr = Open4::popen4 cmd
		end

		Thread.new do
			while @pid > 0
				unless select([@stdout], nil, nil, @timeout).nil?
					buf = ''

					begin
						@stdout.sysread(@buffer_size, buf)
					rescue Errno::EIO #Application went away.
						@pid = 0
						break
					end

          @all_output += buf
					buf.encode! "UTF-8"
					print_buffer buf

					@out_mutex.synchronize do
						@buffer << buf
						@out_update = true
					end
				end
			end
		end

		Thread.new do
			Process.wait @pid
			@pid = 0
		end
	end

	# 
	# Clear output buffer
	#
	def clear_buffer
		@out_mutex.synchronize do
			@buffer = ''
			@out_update = false
		end
	end

	# 
	# === Synopsis
	#
	#   Expectr#interact
	# 
	# === Description
	#
	# Relinquish control of the running process to the controlling terminal,
	# acting simply as a pass-through for the life of the process.
	#
	# Interrupts should be caught and sent to the application.
	#
	def interact
		oldtrap = trap 'INT' do
				send "\C-c"
		end

		@flush_buffer = true
		old_tty = `stty -g`
		`stty -icanon min 1 time 0 -echo`

		in_thread = Thread.new do
			input = ''
			while @pid > 0
				if select([STDIN], nil, nil, 1)
					send STDIN.getc.chr
				end
			end
		end

		in_thread.join
		trap 'INT', oldtrap
		`stty #{old_tty}`
		return nil
	end

	#
	# Send +str+ to application
	#
	def send(str)
		begin
			@stdin.syswrite str
		rescue Errno::EIO #Application went away.
			@pid = 0
		end
		raise ArgumentError unless @pid > 0
	end

	# 
	# === Synopsis
	#
	#   Expectr#expect /regexp/, recoverable=false
	#   Expectr#expect "String", recoverable=true
	# 
	# === Arguments
	#
	# +pattern+::
	#   String or regexp to match against
	# +recoverable+::
	#   Determines if execution can continue after a timeout
	#
	# === Description
	#
	# Wait +timeout+ seconds to match +pattern+ in +buffer+.  If timeout is
	# reached, raise an error unless +recoverable+ is true.
	#
	def expect(pattern, recoverable = false)
		match = nil

		case pattern
			when String
				pattern = Regexp.new(Regexp.quote(pattern))
			when Regexp
			else raise TypeError, "Pattern class should be String or Regexp, passed: #{pattern.class}"
		end

		begin
			Timeout::timeout(@timeout) do
				while match.nil?
					if @out_update
						@out_mutex.synchronize do
							match = pattern.match @buffer
							@out_update = false
						end
					end
					sleep 0.1
				end
			end

			@out_mutex.synchronize do
				@discard = @buffer[0..match.begin(0)-1]
				@buffer = @buffer[match.end(0)..-1]
				@out_update = true
			end
		rescue Timeout::Error => details
			raise details unless recoverable
		end

		return match
	end

	#
	# Print buffer to STDOUT only if +flush_buffer+ is true
	#
	def print_buffer(buf)
		# print buf if @flush_buffer
		# STDOUT.flush
		@logger_buffer += buf
		
		if @logger_buffer.match /\n$|\r$/
		  # LOGGER.info @logger_buffer.gsub( /\r\n/m, "\n" ).gsub( /\r\n$/m, "" )
		  LOGGER.info @logger_buffer.gsub( /\r/, "\n" ).gsub( /\n\r$/, "" ).gsub( /\n$/, "" )
		  
		  @logger_buffer =""
		end
	end
	
end