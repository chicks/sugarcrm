# encoding: utf-8

module Sugarcrm
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc 'Creates a SugarCRM gem configuration file at config/sugarcrm.yml, and an initializer at config/initializers/sugarcrm.rb'

      def self.source_root
        @_sugarcrm_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_config_file
        template 'sugarcrm.yml', File.join('config', 'sugarcrm.yml')
      end

      def create_initializer_file
        template 'initializer.rb', File.join('config', 'initializers', 'sugarcrm.rb')
      end
    end
  end
end

