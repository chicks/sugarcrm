module SugarCRM; class Base 

  # Unset all of the instance methods we don't need.
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^define_method$|^class$|^nil.$|^methods$|^instance_of.$|^respond_to)/ }

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
  attr :modified_attributes, true
  attr :associations, true
  attr :debug, true
  attr :errors, true

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
        when :first
          find_initial(options)
        when :all
          Array.wrap(find_every(options)).compact
        else
          find_from_ids(args, options)
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
    
    # Creates an object (or multiple objects) and saves it to SugarCRM, if validations pass.
    # The resulting object is returned whether the object was saved successfully to the database or not.
    #
    # The +attributes+ parameter can be either be a Hash or an Array of Hashes.  These Hashes describe the
    # attributes on the objects that are to be created.
    #
    # ==== Examples
    #   # Create a single new object
    #   User.create(:first_name => 'Jamie')
    #
    #   # Create an Array of new objects
    #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }])
    #
    #   # Create a single object and pass it into a block to set other attributes.
    #   User.create(:first_name => 'Jamie') do |u|
    #     u.is_admin = false
    #   end
    #
    #   # Creating an Array of new objects using a block, where the block is executed for each object:
    #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }]) do |u|
    #     u.is_admin = false
    #   end
    def create(attributes = nil, &block)
      if attributes.is_a?(Array)
        attributes.collect { |attr| create(attr, &block) }
      else
        object = new(attributes)
        yield(object) if block_given?
        object.save
        object
      end
    end

    private 
    
    def find_initial(options)
      options.update(:limit => 1)
      find_every(options)
    end
  
    def find_from_ids(ids, options)
      expects_array = ids.first.kind_of?(Array)
      return ids.first if expects_array && ids.first.empty?

      ids = ids.flatten.compact.uniq

      case ids.size
        when 0
          raise RecordNotFound, "Couldn't find #{self._module.name} without an ID"
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
      SugarCRM.connection.get_entry_list(self._module.name, query, options) || nil # return nil instead of false if no results are found
    end

    def query_from_options(options)
      # If we dont have conditions, just return an empty query
      return "" unless options[:conditions]
      conditions = []
      options[:conditions].each do |condition|
        # Merge the result into the conditions array
        conditions |= flatten_conditions_for(condition)
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
                record = self.new(unprotected_attributes_for_create)
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
      attribute_names.all? { |name| attributes_from_module.include?(name) }
    end
    
    def construct_attributes_from_arguments(attribute_names, arguments)
      attributes = {}
      attribute_names.each_with_index { |name, idx| attributes[name] = arguments[idx] }
      attributes
    end
    
    VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                           :order_by, :select, :readonly, :group, :having, :from, :lock ]

    def validate_find_options(options) #:nodoc:
      options.assert_valid_keys(VALID_FIND_OPTIONS)
    end
    
  end

  # Creates an instance of a Module Class, i.e. Account, User, Contact, etc.
  def initialize(attributes={}, &block)
    @modified_attributes = {}
    merge_attributes(attributes.with_indifferent_access)
    clear_association_cache
    define_attribute_methods
    define_association_methods
    typecast_attributes
    self
  end

  def inspect
    self
  end
  
  def to_s
    attrs = []
    @attributes.keys.sort.each do |k|
      attrs << "#{k}: #{attribute_for_inspect(k)}"
    end
    "#<#{self.class} #{attrs.join(", ")}>"
  end

  # Saves the current object, checks that required fields are present.
  # returns true or false
  def save
    return false if !changed?
    return false if !valid?
    begin
      save!
    rescue
      return false
    end
    true
  end
  
  # Saves the current object, and any modified associations. 
  # Raises an exceptions if save fails for any reason.
  def save!
    save_modified_attributes!
    save_modified_associations!
    true
  end
  
  def delete
    return false if id.blank?
    params          = {}
    params[:id]     = serialize_id
    params[:deleted]= {:name => "deleted", :value => "1"}
    (SugarCRM.connection.set_entry(self.class._module.name, params).class == Hash)       
  end
  
  # Returns true if +comparison_object+ is the same exact object, or +comparison_object+ 
  # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
  #
  # Note that new records are different from any other record by definition, unless the
  # other record is the receiver itself. Besides, if you fetch existing records with
  # +select+ and leave the ID out, you're on your own, this predicate will return false.
  #
  # Note also that destroying a record preserves its ID in the model instance, so deleted
  # models are still comparable.
  def ==(comparison_object)
      comparison_object.instance_of?(self.class) &&
      id.present? &&
      comparison_object.id == id
  end
  alias :eql? :==
  
  def update_attribute(name, value)
    self.send("#{name}=".to_sym, value)
    self.save
  end
  
  def update_attributes(attributes)
    attributes.each do |name, value|
      self.send("#{name}=".to_sym, value)
    end
    self.save
  end
  
  # Delegates to id in order to allow two records of the same type and id to work with something like:
  #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
  def hash
    id.hash
  end
  
  def attribute_methods_generated?
    self.class.attribute_methods_generated
  end  
  
  def association_methods_generated?
    self.class.association_methods_generated
  end
  
  Base.class_eval do
    include AttributeMethods
    extend  AttributeMethods::ClassMethods
    include AttributeValidations
    include AttributeTypeCast
    include AttributeSerializers
    include AssociationMethods
    extend  AssociationMethods::ClassMethods
    include AssociationCache
  end

end; end 