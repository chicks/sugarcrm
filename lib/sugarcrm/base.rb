require 'sugarcrm/attribute_methods'
require 'sugarcrm/association_methods'

module SugarCRM; class Base 

  # Unset all of the instance methods we don't need.
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^define_method$|^class$|^instance_of.$)/ }

  # This holds our connection
  cattr_accessor :connection, :instance_writer => false
    
  # Tracks if we have extended our class with attribute methods yet.
  class_attribute :attribute_methods_generated
  self.attribute_methods_generated = false
  
  class_attribute :association_methods_generated
  self.association_methods_generated = false
  
  class_attribute :_module
  self._module = nil
  
  # Contains a list of attributes
  attr :attributes, true
  attr :id, true
  attr :debug, true

  class << self # Class methods
    def establish_connection(url, user, pass, opts={})
      options = { 
        :debug  => false,
        :register_modules => true,
      }.merge(opts)
      @debug  = options[:debug]
      @@connection = SugarCRM::Connection.new(url, user, pass, options)
    end
  
    def find(*args)
      options = args.extract_options!
      validate_find_options(options)

      case args.first
        when :first then find_initial(options)
        when :all   then find_every(options)
        else             find_from_ids(args, options)
      end
    end

    # A convenience wrapper for <tt>find(:first, *args)</tt>. You can pass in all the
    # same arguments to this method as you can to <tt>find(:first)</tt>.
    def first(*args)
      find(:first, *args)
    end

    # This is an alias for find(:all).  You can pass in all the same arguments to this method as you can
    # to find(:all)
    def all(*args)
      find(:all, *args)
    end

    private 
    
    def find_initial(options)
      options.update(:max_results => 1)
      find_every(options)
    end
  
    def find_from_ids(ids, options)
      expects_array = ids.first.kind_of?(Array)
      return ids.first if expects_array && ids.first.empty?

      ids = ids.flatten.compact.uniq

      case ids.size
        when 0
          raise RecordNotFound, "Couldn't find #{name} without an ID"
        when 1
          result = find_one(ids.first, options)
          expects_array ? [ result ] : result
        else
          find_some(ids, options)
      end
    end
  
    def find_one(id, options)
      if result = SugarCRM.connection.get_entry(self._module.name, id, {:fields => self._module.fields.keys})
        result
      else
        raise RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions}"
      end
    end
    
    def find_some(ids, options)
      result = SugarCRM.connection.get_entries(self._module.name, ids, {:fields => self._module.fields.keys})

      # Determine expected size from limit and offset, not just ids.size.
      expected_size =
        if options[:limit] && ids.size > options[:limit]
          options[:limit]
        else
          ids.size
        end

      # 11 ids with limit 3, offset 9 should give 2 results.
      if options[:offset] && (ids.size - options[:offset] < expected_size)
        expected_size = ids.size - options[:offset]
      end

      if result.size == expected_size
        result
      else
        raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids_list})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
      end
    end
    
    def find_every(options)
      find_by_sql(options)
    end
        
    def find_by_sql(options)
      query = query_from_options(options)
      SugarCRM.connection.get_entry_list(self._module.name, query, options)
    end
    
    def query_from_options(options)
      conditions = []
      options[:conditions].each_pair do |column, value| 
        conditions << "#{self._module.table_name}.#{column} = \'#{value}\'"
      end
      conditions.join(" AND ")
    end
    
    # Enables dynamic finders like <tt>find_by_user_name(user_name)</tt> and <tt>find_by_user_name_and_password(user_name, password)</tt>
    # that are turned into <tt>find(:first, :conditions => ["user_name = ?", user_name])</tt> and
    # <tt>find(:first, :conditions => ["user_name = ? AND password = ?", user_name, password])</tt> respectively. Also works for
    # <tt>find(:all)</tt> by using <tt>find_all_by_amount(50)</tt> that is turned into <tt>find(:all, :conditions => ["amount = ?", 50])</tt>.
    #
    # It's even possible to use all the additional parameters to +find+. For example, the full interface for +find_all_by_amount+
    # is actually <tt>find_all_by_amount(amount, options)</tt>.
    #
    # Also enables dynamic scopes like scoped_by_user_name(user_name) and scoped_by_user_name_and_password(user_name, password) that
    # are turned into scoped(:conditions => ["user_name = ?", user_name]) and scoped(:conditions => ["user_name = ? AND password = ?", user_name, password])
    # respectively.
    #
    # Each dynamic finder, scope or initializer/creator is also defined in the class after it is first invoked, so that future
    # attempts to use it do not run through method_missing.
    def method_missing(method_id, *arguments, &block)
      if match = DynamicFinderMatch.match(method_id)
        attribute_names = match.attribute_names
        super unless all_attributes_exists?(attribute_names)
        if match.finder?
          finder = match.finder
          bang = match.bang?
          # def self.find_by_login_and_activated(*args)
          #   options = args.extract_options!
          #   attributes = construct_attributes_from_arguments(
          #     [:login,:activated],
          #     args
          #   )
          #   finder_options = { :conditions => attributes }
          #   validate_find_options(options)
          #
          #   if options[:conditions]
          #     with_scope(:find => finder_options) do
          #       find(:first, options)
          #     end
          #   else
          #     find(:first, options.merge(finder_options))
          #   end
          # end
          self.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.#{method_id}(*args)
              options = args.extract_options!
              attributes = construct_attributes_from_arguments(
                [:#{attribute_names.join(',:')}],
                args
              )
              finder_options = { :conditions => attributes }
              validate_find_options(options)

              #{'result = ' if bang}if options[:conditions]
                with_scope(:find => finder_options) do
                  find(:#{finder}, options)
                end
              else
                find(:#{finder}, options.merge(finder_options))
              end
              #{'result || raise(RecordNotFound, "Couldn\'t find #{name} with #{attributes.to_a.collect {|pair| "#{pair.first} = #{pair.second}"}.join(\', \')}")' if bang}
            end
          EOS
          send(method_id, *arguments)
        elsif match.instantiator?
          instantiator = match.instantiator
          # def self.find_or_create_by_user_id(*args)
          #   guard_protected_attributes = false
          #
          #   if args[0].is_a?(Hash)
          #     guard_protected_attributes = true
          #     attributes = args[0].with_indifferent_access
          #     find_attributes = attributes.slice(*[:user_id])
          #   else
          #     find_attributes = attributes = construct_attributes_from_arguments([:user_id], args)
          #   end
          #
          #   options = { :conditions => find_attributes }
          #   set_readonly_option!(options)
          #
          #   record = find(:first, options)
          #
          #   if record.nil?
          #     record = self.new { |r| r.send(:attributes=, attributes, guard_protected_attributes) }
          #     yield(record) if block_given?
          #     record.save
          #     record
          #   else
          #     record
          #   end
          # end
          self.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.#{method_id}(*args)
              attributes = [:#{attribute_names.join(',:')}]
              protected_attributes_for_create, unprotected_attributes_for_create = {}, {}
              args.each_with_index do |arg, i|
                if arg.is_a?(Hash)
                  protected_attributes_for_create = args[i].with_indifferent_access
                else
                  unprotected_attributes_for_create[attributes[i]] = args[i]
                end
              end

              find_attributes = (protected_attributes_for_create.merge(unprotected_attributes_for_create)).slice(*attributes)

              options = { :conditions => find_attributes }

              record = find(:first, options)

              if record.nil?
                record = self.new do |r|
                  r.send(:attributes=, protected_attributes_for_create, true) unless protected_attributes_for_create.empty?
                  r.send(:attributes=, unprotected_attributes_for_create, false) unless unprotected_attributes_for_create.empty?
                end
                #{'yield(record) if block_given?'}
                #{'record.save' if instantiator == :create}
                record
              else
                record
              end
            end
          EOS
          send(method_id, *arguments, &block)
        end
      else
        super
      end
    end
    
    def all_attributes_exists?(attribute_names)
      attribute_names.all? { |name| attributes_from_module_fields.include?(name) }
    end
    
    def construct_attributes_from_arguments(attribute_names, arguments)
      attributes = {}
      attribute_names.each_with_index { |name, idx| attributes[name] = arguments[idx] }
      attributes
    end
    
    VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                           :order, :select, :readonly, :group, :having, :from, :lock ]

    def validate_find_options(options) #:nodoc:
      options.assert_valid_keys(VALID_FIND_OPTIONS)
    end
    
  end

  # Creates an instance of a Module Class, i.e. Account, User, Contact, etc.
  # This call depends upon SugarCRM.modules having actual data in it.  If you 
  # are using Base.establish_connection, you should be fine.  But if you are 
  # using the Connection class by itself, you may need to prime the pump with
  # a call to Module.register_all
  def initialize(id=nil, attributes={})
    @id = id
    @attributes = self.class.attributes_from_module_fields.merge(attributes)
    @associations = associations_from_module_link_fields
    define_attribute_methods
    define_association_methods
  end

  def inspect
    self
  end
  
  def to_s
    attrs = []
    @attributes.each_key do |k|
       attrs << "#{k}: #{attribute_for_inspect(k)}"
    end
    "#<#{self.class} #{attrs.join(", ")}>"
  end

  def save
    response = SugarCRM.connection.set_entry(self._module.name, @attributes)
  end
  
  # Wrapper around class attribute
  def attribute_methods_generated?
    self.class.attribute_methods_generated
  end  
  
  def association_methods_generated?
    self.class.association_methods_generated
  end
  
  Base.class_eval do
    include AttributeMethods
    extend  AttributeMethods::ClassMethods
    include AssociationMethods
  end

end; end 