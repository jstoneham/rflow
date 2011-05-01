require 'active_record'

class RFlow
  class Configuration
    class Component < ActiveRecord::Base
      include ActiveModel::Validations
      
      class ComponentInvalid < StandardError; end
      class ComponentNotFound < StandardError; end

      serialize :options, Hash

      has_many :input_ports,  :primary_key => 'uuid', :foreign_key => 'component_uuid'
      has_many :output_ports, :primary_key => 'uuid', :foreign_key => 'component_uuid'

      # Racy, but with unique index to back it up
      validates_presence_of :uuid
      validates_uniqueness_of :uuid, :name
    end
  end
end
