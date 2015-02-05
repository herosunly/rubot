unless Kernel.respond_to?(:require_relative)
	module Kernel
		def require_relative(path)
			require File.join(File.dirname(caller[0]), path.to_str)
		end
	end
end

require_relative 'helper'

class TestProxyHandler < EventMachine::Connection
	attr_reader :data
	def initialize
		@data = ''
	end
	
	def post_init
		send_data "GET / HTTP/1.0\r\n\r\n"
	end
	
	def receive_data data
		@data << data
	end
end

class TestTCPProxy < Minitest::Test
	def test_form_a_proxy_and_connect_to_google
		EM.run {
			srvr = EventMachine::start_server "0.0.0.0", 0, Rubot::Service::Proxy::TCP, "www.google.com", 80
			port, ip = Socket.unpack_sockaddr_in( EM.get_sockname( srvr ))
			clnt = EventMachine::connect ip, port, TestProxyHandler
			timer = EventMachine::Timer.new(1) do
				refute_equal('',clnt.data)
				assert(clnt.data =~ /html/i)
				EventMachine::stop_event_loop
			end
		}
	end
end
