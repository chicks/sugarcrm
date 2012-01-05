module SugarCRM; module FinderMethods
  module ClassMethods
    private 
      def find_initial(options)
        options.update(:limit => 1)
        result = find_by_sql(options)
        return result.first if result.instance_of? Array # find_by_sql will return an Array if result are found
        result
      end
  
      def find_from_ids(ids, options, &block)
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
            find_some(ids, options, &block)
        end
      end
  
      def find_one(id, options)
      
        if result = connection.get_entry(self._module.name, id, {:fields => self._module.fields.keys})
          result
        else
          raise RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions}"
        end
      end
    
      def find_some(ids, options, &block)
        result = connection.get_entries(self._module.name, ids, {:fields => self._module.fields.keys})

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
          if block_given?
            result.each{|r|
              yield r
            }
          end
          result
        else
          raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids_list})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
        end
      end
    
      def find_every(options, &block)
        find_by_sql(options, &block)
      end
      
      # the number of records we retrieve with each query
      # it is kept small to avoid timeout issues
      SLICE_SIZE = 5
      SLICE_SIZE.freeze
      # results accumulator stores the results we have fetched so far, recursively
      def find_by_sql(options, results_accumulator=nil, &block)
        # SugarCRM REST API has a bug (fixed in release _6.4.0.patch as indicated in SugarCRM bug number 43338)
        # where, when :limit and :offset options are passed simultaneously,
        # :limit is considered to be the smallest of the two, and :offset is the larger
        # In addition to allowing querying of large datasets while avoiding timeouts (by fetching results in small slices),
        # this implementation fixes the :limit - :offset bug so that it behaves correctly
        
        offset = options[:offset].to_i >= 1 ? options[:offset].to_i : nil
        
        # if many results are requested (i.e. multiple result slices), we call this function recursively
        # this array keeps track of which slice we are retrieving (by updating the :offset and :limit options)
        local_options = {}
        # ensure results are ordered so :limit and :offset option behave in a deterministic fashion
        local_options[:order_by] = :id unless options[:order_by]
        
        # we must ensure limit <= offset (due to bug mentioned above)
        if offset
          local_options[:limit] = [offset.to_i, SLICE_SIZE].min
          local_options[:offset] = offset if offset
        else
          local_options[:limit] = options[:limit] ? [options[:limit].to_i, SLICE_SIZE].min : SLICE_SIZE
        end
        local_options[:limit] = [local_options[:limit], options[:limit]].min if options[:limit] # don't retrieve more records than required
        local_options = options.merge(local_options)
        
        query = query_from_options(local_options)
        result_slice = connection.get_entry_list(self._module.name, query, local_options)
        return results_accumulator unless result_slice
        
        result_slice_array = Array.wrap(result_slice)
        if block_given?
          result_slice_array.each{|r| yield r }
        else
          results_accumulator = [] unless results_accumulator
          results_accumulator = results_accumulator.concat(result_slice_array)
        end
        
        # adjust options to take into account records that were already retrieved
        updated_options = {:offset => options[:offset].to_i + result_slice_array.size}
        updated_options[:limit] = (options[:limit] ? options[:limit] - result_slice_array.size : nil)
        updated_options = options.merge(updated_options)
        
        # have we retrieved all the records?
        if (updated_options[:limit] && updated_options[:limit] < 1) || local_options[:limit] > result_slice_array.size
          return results_accumulator
        else
          find_by_sql(updated_options, results_accumulator, &block)
        end
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
    
      # return the opposite of the provided order clause
      # this is used for the :last find option
      # in other words SugarCRM::Account.last(:order_by => "name")
      # is equivalent to SugarCRM::Account.first(:order_by => "name DESC")
      def reverse_order_clause(order)
        raise "reversing multiple order clauses not supported" if order.split(',').size > 1
        raise "order clause format not understood; expected 'column_name (ASC|DESC)?'" unless order =~ /^\s*(\S+)\s*(ASC|DESC)?\s*$/
        column_name = $1
        reversed_order = {'ASC' => 'DESC', 'DESC' => 'ASC'}[$2 || 'ASC']
        return "#{column_name} #{reversed_order}"
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
    
      VALID_FIND_OPTIONS = [ :conditions, :deleted, :fields, :include, :joins, :limit, :link_fields, :offset,
                             :order_by, :select, :readonly, :group, :having, :from, :lock ]

      def validate_find_options(options) #:nodoc:
        options.assert_valid_keys(VALID_FIND_OPTIONS)
      end
    end
  end
end