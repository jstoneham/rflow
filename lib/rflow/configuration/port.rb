require 'active_record'

class RFlow
  class Configuration
    class Port < ActiveRecord::Base
      include ActiveModel::Validations
      
      class PortInvalid < StandardError; end

      belongs_to :component,  :primary_key => 'uuid', :foreign_key => 'component_uuid'

      validate :component_has_defined_port

      # TODO: HACK!  Extract this into Configuration so we can DRY up
      # the stuffs and provide better error checking for getting the
      # class of a component.  Also assumes managed components given
      # as Ruby classes
      def component_has_defined_port
        port_type = self.type.to_s
        case port_type
        when 'RFlow::Configuration::InputPort'
          defined_port = self.component.specification.constantize.defined_input_ports[self.name.to_sym]
        when 'RFlow::Configuration::OutputPort'
          defined_port = self.component.specification.constantize.defined_output_ports[self.name.to_sym]
        else
          error_message = "Invalid port type '#{port_type}' (from '#{self.type.inspect}')"
          RFlow.logger.error error_message
          raise ArgumentError, error_message
        end
        errors.add(:name, "'#{self.name}' not an '#{port_type}' on component #{self.component.name} (#{self.component.uuid})") unless defined_port
      end
    end

    # STI-based classes
    class InputPort < Port;
      has_one :incoming_connection, :class_name => 'RFlow::Configuration::Connection', :primary_key => 'uuid', :foreign_key => 'input_port_uuid'
      has_many :output_ports, :through => :connections
    end

    class OutputPort < Port;
      has_one :outgoing_connection, :class_name => 'RFlow::Configuration::Connection', :primary_key => 'uuid', :foreign_key => 'output_port_uuid'
      has_one :input_port, :through => :connections
    end
  end
end

