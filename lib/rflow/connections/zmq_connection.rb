require 'em-zeromq'

require 'rflow/connection'
require 'rflow/message'

class RFlow
  module Connections
    class ZMQConnection < RFlow::Connection

      class << self
        attr_accessor :zmq_context

        def create_zmq_context
          RFlow.logger.debug "Creating a new ZeroMQ context"
          if EM.reactor_running?
            raise RuntimeError, "EventMachine reactor is running when attempting to create a ZeroMQ context"
          end
          EM::ZeroMQ::Context.new(1)
        end

        # Returns the current ZeroMQ context object or creates it if
        # it does not exist.
        def zmq_context
          @zmq_context ||= create_zmq_context
        end
      end

      def zmq_context; self.class.zmq_context; end

      attr_accessor :input_socket, :output_socket

      def initialize(config)
        super
        validate_options!
        # Cause the ZMQ context to be created before the reactor is running
        zmq_context
      end


      def validate_options!
        # TODO: Normalize/validate configuration
        missing_options = []

        ['input', 'output'].each do |direction_prefix|
          ['_socket_type', '_address', '_responsibility'].each do |option_suffix|
            option_name = "#{direction_prefix}#{option_suffix}"
            unless options.include? option_name
              missing_options << option_name
            end
          end
        end

        unless missing_options.empty?
          raise ArgumentError, "#{self.class.to_s}: configuration missing options: #{missing_options.join ', '}"
        end

        true
      end


      def connect_input!
        RFlow.logger.debug "Connecting input #{uuid} with #{options.find_all {|k, v| k.to_s =~ /input/}}"
        self.input_socket = zmq_context.socket(ZMQ.const_get(options['input_socket_type'].to_sym))
        input_socket.send(options['input_responsibility'].to_sym,
                          options['input_address'])

        input_socket.on(:message) do |*message_parts|
          message = RFlow::Message.from_avro(message_parts.last.copy_out_string)
          RFlow.logger.debug "#{name}: Received message of type '#{message_parts.first.copy_out_string}'"
          message_parts.each { |part| part.close } # avoid memory leaks
          recv_callback.call(message)
        end

        input_socket
      end


      def connect_output!
        RFlow.logger.debug "Connecting output #{uuid} with #{options.find_all {|k, v| k.to_s =~ /output/}}"
        self.output_socket = zmq_context.socket(ZMQ.const_get(options['output_socket_type'].to_sym))
        output_socket.send(options['output_responsibility'].to_sym,
                           options['output_address'].to_s)
        output_socket
      end


      # TODO: fix this tight loop of retries
      def send_message(message)
        RFlow.logger.debug "#{name}: Sending message of type '#{message.data_type_name.to_s}'"

        begin
          output_socket.send_msg(message.data_type_name.to_s, message.to_avro)
          RFlow.logger.debug "#{name}: Successfully sent message of type '#{message.data_type_name.to_s}'"
        rescue Exception => e
          RFlow.logger.debug "Exception #{e.class}: #{e.message}, retrying send"
          retry
        end
      end

    end
  end
end
