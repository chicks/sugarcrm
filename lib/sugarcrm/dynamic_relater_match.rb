module SugarCRM
  class DynamicRelaterMatch
    def self.match(method)
      dr_match = self.new(method)
      dr_match.module_instance ? dr_match : nil
    end

    def initialize(method)
      case method.to_s
      when /^add_([_a-zA-Z]\w*)$/
        @module_instance = $1
      else
        @module_instance = nil
      end
    end

    attr_reader :module_instance
  end
end
