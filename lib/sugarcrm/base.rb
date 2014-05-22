module SugarCRM; class Base 

  # Unset all of the instance methods we don't need.
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^define_method$|^class$|^nil.$|^methods$|^instance_of.$|^respond_to)/ }

  # Tracks if we have extended our class with attribute methods yet.
  class_attribute :attribute_methods_generated
  self.attribute_methods_generated = false
  
  class_attribute :association_methods_generated
  self.association_methods_generated = false
  
  class_attribute :_module
  self._module = nil
  
  # the session to which we're linked
  class_attribute :session
  self.session = nil
  
  # Contains a list of attributes
  attr_accessor :attributes,  :modified_attributes, :associations, :debug, :errors

  class << self # Class methods
    def find(*args, &block)
      options = args.extract_options!
      # add default sorting date (necessary for first and last methods to work)
      # most modules (Contacts, Accounts, etc.) use 'date_entered' to store when the record was created
      # other modules (e.g. EmailAddresses) use 'date_created'
      # Here, we account for this discrepancy...
      self.new # make sure the fields are loaded from SugarCRM so method_defined? will work properly
      if self.method_defined? :date_entered
        sort_criteria = 'date_entered'
      elsif self.method_defined? :date_created
        sort_criteria = 'date_created'
      # Added date_modified because TeamSets doesn't have a date_created or date_entered field.  
      # There's no test for this because it's Pro and above only.
      # Hope this doesn't break anything!
      elsif self.method_defined? :date_modified
        sort_criteria = 'date_modified'
      else
        raise InvalidAttribute, "Unable to determine record creation date for sorting criteria: expected date_entered, date_created, or date_modified attribute to be present"
      end
      options = {:order_by => sort_criteria}.merge(options)
      validate_find_options(options)

      case args.first
        when :first
          find_initial(options)
        when :last
          begin
            options[:order_by] = reverse_order_clause(options[:order_by].to_s)
          rescue Exception => e
            raise
          end
          find_initial(options)
        when :all
          Array.wrap(find_every(options, &block)).compact
        else
          find_from_ids(args, options, &block)
      end
    end
  
    # return the connection to the correct SugarCRM server (there can be several)
    def connection
      self.session.connection
    end
    
    # return the number of records satifsying the options
    # note: the REST API has a bug (documented with Sugar as bug 43339) where passing custom attributes in the options will result in the 
    # options being ignored and '0' being returned, regardless of the existence of records satisfying the options
    def count(options={})
      raise InvalidAttribute, 'Conditions on custom attributes are not supported due to REST API bug' if contains_custom_attribute(options[:conditions])
      query = query_from_options(options)
      connection.get_entries_count(self._module.name, query, options)['result_count'].to_i
    end

    # A convenience wrapper for <tt>find(:first, *args)</tt>. You can pass in all the
    # same arguments to this method as you can to <tt>find(:first)</tt>.
    def first(*args, &block)
      find(:first, *args, &block)
    end

    # A convenience wrapper for <tt>find(:last, *args)</tt>. You can pass in all the
    # same arguments to this method as you can to <tt>find(:last)</tt>.
    def last(*args, &block)
      find(:last, *args, &block)
    end

    # This is an alias for find(:all).  You can pass in all the same arguments to this method as you can
    # to find(:all)
    def all(*args, &block)
      find(:all, *args, &block)
    end
    
    # Creates an object (or multiple objects) and saves it to SugarCRM if validations pass.
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
  end

  # Creates an instance of a Module Class, i.e. Account, User, Contact, etc.
  def initialize(attributes={}, &block)
    attributes.delete('id')
    @errors = {}
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
  
  # objects are considered equal if they represent the same SugarCRM record
  # this behavior is required for Rails to be able to properly cast objects to json (lists, in particular)
  def equal?(other)
    return false unless other && other.respond_to?(:id)
     self.id == other.id
  end
  
  # return variables that are defined in SugarCRM, instead of the object's actual variables (such as modified_attributes, errors, etc.)
  def instance_variables
    @_instance_variables ||= @attributes.keys.map{|i| ('@' + i).to_sym }
  end
  
  # override to return the value of the SugarCRM record's attributes
  def instance_variable_get(name)
    name = name.to_s.gsub(/^@/,'')
    @attributes[name]
  end
  
  # Rails requires this to (e.g.) generate json representations of models
  # this code taken directly from the Rails project
  if defined?(Rails)
    def instance_values
      Hash[instance_variables.map { |name| [name.to_s[1..-1], instance_variable_get(name)] }]
    end
  end
  
  def to_json(options={})
    attributes.to_json
  end
  
  def to_xml(options={})
    attributes.to_xml
  end

  # Saves the current object, checks that required fields are present.
  # returns true or false
  def save(opts={})
    options = { :validate => true }.merge(opts)
    return false if !(new_record? || changed?)
    if options[:validate]
      return false if !valid?
    end
    begin
      save!(options)
    rescue
      return false
    end
    true
  end
  
  # Saves the current object, and any modified associations. 
  # Raises an exceptions if save fails for any reason.
  def save!(opts={})
    save_modified_attributes!(opts)
    save_modified_associations!
    true
  end
  
  def delete
    return false if id.blank?
    params          = {}
    params[:id]     = serialize_id
    params[:deleted]= {:name => "deleted", :value => "1"}
    @attributes[:deleted] = (self.class.connection.set_entry(self.class._module.name, params).class == Hash)
  end
  alias :destroy :delete
  
  # Returns if the record is persisted, i.e. it’s not a new record and it was not destroyed
  def persisted?
    !(new_record? || destroyed?)
  end
  
  # Reloads the record from SugarCRM
  def reload!
    self.attributes = self.class.find(self.id).attributes
  end
  
  def blank?
    @attributes.empty?
  end
  alias :empty? :blank?
  
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
  
  def update_attribute!(name, value)
    self.send("#{name}=".to_sym, value)
    self.save!
  end
  
  def update_attribute(name, value)
    begin
      update_attribute!(name, value)
    rescue
      return false
    end
    true
  end
  
  def update_attributes!(attributes)
    attributes.each do |name, value|
      self.send("#{name}=".to_sym, value)
    end
    self.save!
  end
  
  def update_attributes(attributes)
    begin
      update_attributes!(attributes)
    rescue
      return false
    end
    true
  end
  
  # Returns the URL (in string format) where the module instance is available in CRM
  def url
    "#{SugarCRM.session.config[:base_url]}/index.php?module=#{self.class._module.name}&action=DetailView&record=#{self.id}"
  end
    
  # Delegates to id in order to allow two records of the same type and id to work with something like:
  #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
  def hash
    id.hash
  end

  def pretty_print(pp)
    pp.text self.inspect.to_s, 0
  end

  def attribute_methods_generated?
    self.class.attribute_methods_generated
  end  
  
  def association_methods_generated?
    self.class.association_methods_generated
  end
  
  def to_key
    new_record? ? nil : [ id ]
  end
  
  def to_param
    id.to_s
  end
  
  def is_a?(klass)
    superclasses.include? klass
  end
  alias :kind_of? :is_a?
  alias :=== :is_a?
  
  private
  # returns true if the hash contains a custom attribute created in Studio (and whose name therefore ends in '_c')
  def self.contains_custom_attribute(attributes)
    attributes ||= {}
    attributes.each_key{|k|
      return true if k.to_s =~ /_c$/
    }
    false
  end
  
  def superclasses
    return @superclasses if @superclasses
    @superclasses = [self.class]
    current_class = self.class
    while current_class.respond_to? :superclass
      @superclasses << (current_class = current_class.superclass)
    end
    @superclasses
  end
  
  Base.class_eval do
    extend  FinderMethods::ClassMethods
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