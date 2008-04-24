# This monkey-patch/plugin allows a restricted set of attributes to be selected for
# each model in an ActiveRecord find call that eager loads associations.
# Either
#   1. Place this file in Rails lib folder and require it in environment.rb, or
#   2. Place file as vendor/plugins/include-attrs/init.rb
#
# Attributes selected for the base model on which the find is run are selected with
# the :select option to find.  Fields must be prefixed with the base model table name
# if that field name is present in the table of an eager loaded model. Names of selected
# fields (the field name, or the alias if aliased) cannot begin with an underscore.
# Selection of arbitary SQL expressions as base model attributes is permitted.
#
# Attributes on eager-loaded models are specified in the :include option of find 
# by providing a list of attribute names inside a pair of square brackets that follow
# a symbolic association name. No attributes are selected if the list is empty
# (useful for using the join for the association in the find :conditions option).
#
# e.g.
#
# Store.find :all,
#   :select => 'stores.name, owners.name, sum(books.price * books.stock) as total_inventory', 
#   :include => [:manager[:name], :address, {:books[:title, :stock, :price] => :author}],
#   :joins => 'join owners on stores.owner_id = owners.id',
#   :conditions => "addresses.city = 'Sydney'",
#   :group => 'stores.id'


# Class for holding arrays that specify the attributes to be selected for
# an eager-loaded model.  Method response is heavily restricted to prevent
# accidental use of the [] method on a symbol from remaining undetected.
#
class IncludedAssocAttrSelector
  instance_methods.each { |m| undef_method m unless m =~ /^(__|hash$)/ }
  attr_reader :_association, :_attrs
 
  def initialize(association, attrs, cont)
    @_association = association
    @_attrs = attrs.map(&:to_s)
    @cont = cont
  end
  
  def to_s
    ":#{@_association}#{@_attrs.inspect}"
  end
  alias :inspect :to_s
  
  def method_missing(symbol)
    @cont.call
  end
end

Symbol.class_eval do
  alias_method :orig_sq, :[] if method_defined?(:[])
  def [](*attrs)
    callcc { |cont| return IncludedAssocAttrSelector.new(self, attrs, cont) }
    Symbol.method_defined?(:orig_sq) ? orig_sq(*attrs) : method_missing(:[], *attrs)
  end
end

class ActiveRecord::Base

  # Just change the processing of the :select option
  #
  def self.construct_finder_sql_with_included_associations(options, join_dependency)
    scope = scope(:find)
    base_select = options[:select] || scope && scope[:select] || "#{table_name}.*"
    eager_select = eager_select(join_dependency)
    base_select += ', ' unless base_select.empty? || eager_select.empty?
    sql = "SELECT #{base_select + eager_select} FROM #{(scope && scope[:from]) || options[:from] || table_name} "
    sql << join_dependency.joins.map { |join| join.association_join }.join

    add_joins!(sql, options, scope)
    add_conditions!(sql, options[:conditions], scope)
    add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

    sql << "GROUP BY #{options[:group]} " if options[:group]

    add_order!(sql, options[:order], scope)
    add_limit!(sql, options, scope) if using_limitable_reflections?(join_dependency.reflections)
    add_lock!(sql, options, scope)

    return sanitize_sql(sql)
  end

  # The exsiting column_aliases method renamed
  #
  def self.eager_select(join_dependency)
    join_dependency.joins.map do |join|
      join.column_names_with_alias.map do |column_name, aliased_name| 
        "#{join.aliased_table_name}.#{connection.quote_column_name column_name} AS #{aliased_name}"
      end
    end.flatten.join(', ') 
  end  
end

class ActiveRecord::Associations::ClassMethods::JoinDependency

  # Just add the table_joins, base, and base_id instance variables,
  # and move the JoinBase from the joins to the build call.
  #
  
  attr_reader :table_joins
  
  def initialize(base, associations, joins)
    @base                  = base
    @base_id               = base.primary_key
    @joins                 = []
    @join_base = JoinBase.new(base)
    @table_joins           = joins
    @associations          = associations
    @reflections           = []
    @base_records_hash     = {}
    @base_records_in_order = []
    @table_aliases         = Hash.new { |aliases, table| aliases[table] = 0 }
    @table_aliases[base.table_name] = 1
    build(associations, @join_base)
  end
 
  # Base attrs are those not having an underscore as their first character.
  #
  def instantiate(rows)
    j = joins.map { |j| j.reflection.name }.join(', ')
    rows.each do |row|
      primary_id = row[@base_id]
      unless @base_records_hash[primary_id]
        base_attrs = row.reject { |attr, value| attr[0] == ?_ }
        @base_records_in_order << (@base_records_hash[primary_id] = @base.send(:instantiate, base_attrs))
      end
      @join_index = -1
      construct(@base_records_hash[primary_id], @associations, joins, row)
    end
    remove_duplicate_results!(@base, @base_records_in_order, @associations)
    return @base_records_in_order
  end
  
  def join_associations() @joins end
  def join_base() @join_base end
  
  protected

    # Handle the :assoc[:attr1, :attr2, ...] syntax for attribute selection on eager-loaded models
    #
    def build(associations, parent)
      case associations
        when Symbol, String, IncludedAssocAttrSelector
          attrs = nil
          if IncludedAssocAttrSelector === associations
            attrs = associations._attrs
            associations = associations._association
          end
          unless reflection = parent.reflections[associations.to_s.intern]
            raise ActiveRecord::ConfigurationError, "Association named '#{ associations }' was not found; perhaps you misspelled it?"
          end
          @reflections << reflection
          @joins << (join_assoc = build_join_association(reflection, parent, attrs))
          join_assoc
        when Array
          associations.each do |association|
            build(association, parent)
          end
        when Hash
          associations.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |name|
            build(associations[name], build(name, parent))
          end
        else
          raise ActiveRecord::ConfigurationError, associations.inspect
      end
    end
    
    def build_join_association(reflection, parent, attrs)
      JoinAssociation.new(reflection, self, parent, attrs)
    end
    
    # Handle IncludedAssocAttrSelector include specs
    # and avoid having to dup the joins array by keeping an index rather than shifting.
    #
    def construct(parent, associations, joins, row)
      
      case associations
        when Symbol, String, IncludedAssocAttrSelector
          associations = associations._association if IncludedAssocAttrSelector === associations
          while (join = joins[@join_index += 1]).reflection.name.to_s != associations.to_s
            raise ActiveRecord::ConfigurationError, "Not Enough Associations" if join.nil?
          end
          construct_association(parent, join, row) if parent
        when Array
          associations.each do |association|
            construct(parent, association, joins, row)
          end
        when Hash
          associations.keys.sort{|a,b|a.to_s<=>b.to_s}.each do |name|
            association = construct_association(parent, joins[@join_index+=1], row) if parent
            construct(association, associations[name], joins, row)
          end
        else
          raise ActiveRecord::ConfigurationError, associations.inspect
      end
    end
    
    # Handle IncludedAssocAttrSelector include specs
    #
    def remove_duplicate_results!(base, records, associations)
      case associations
        when Symbol, String, IncludedAssocAttrSelector
          associations = associations._association if IncludedAssocAttrSelector === associations
          reflection = base.reflections[associations]
          if reflection && [:has_many, :has_and_belongs_to_many].include?(reflection.macro)
            records.each { |record| record.send(reflection.name).target.uniq! }
          end
        when Array
          associations.each do |association|
            remove_duplicate_results!(base, records, association)
          end
        when Hash
          associations.keys.each do |name|
            name = name._association if IncludedAssocAttrSelector === name
            reflection = base.reflections[name]
            is_collection = [:has_many, :has_and_belongs_to_many].include?(reflection.macro)

            parent_records = records.map do |record|
              next unless record.send(reflection.name)
              is_collection ? record.send(reflection.name).target.uniq! : record.send(reflection.name)
            end.flatten.compact

            remove_duplicate_results!(reflection.class_name.constantize, parent_records, associations[name]) unless parent_records.empty?
          end
      end
    end

    # Just add a return(nil) if no attributes have been selected
    #
    def construct_association(record, join, row)
      return nil if join.selected_attrs.empty?
      case join.reflection.macro
        when :has_many, :has_and_belongs_to_many
          collection = record.send(join.reflection.name)
          collection.loaded
          return nil if record.id.to_s != join.parent.record_id(row).to_s or row[join.aliased_primary_key].nil?
          association = join.instantiate(row)
          collection.target.push(association) unless collection.target.include?(association)
        when :has_one
          return if record.id.to_s != join.parent.record_id(row).to_s
          association = join.instantiate(row) unless row[join.aliased_primary_key].nil?
          record.send("set_#{join.reflection.name}_target", association)
        when :belongs_to
          return if record.id.to_s != join.parent.record_id(row).to_s or row[join.aliased_primary_key].nil?
          association = join.instantiate(row)
          record.send("set_#{join.reflection.name}_target", association)
        else
          raise ActiveRecord::ConfigurationError, "unknown macro: #{join.reflection.macro}"
      end
      return association
    end
    
  # Base table attrs are no longer aliased to t0_rn.
  #
  class JoinBase
    def aliased_prefix
      aliased_table_name
    end

    def aliased_primary_key
      active_record.primary_key
    end
  end

  class JoinAssociation
    
    # Just add the selected_attrs parameter, instance_variable, and reader method
    # and move the table_joins (manual joins) from parent.table_joins to the join_dependency,
    #
    attr_reader :selected_attrs
    
    def initialize(reflection, join_dependency, parent, selected_attrs = nil)
      reflection.check_validity!
      if reflection.options[:polymorphic]
        raise EagerLoadPolymorphicError.new(reflection)
      end

      super(reflection.klass)
      @selected_attrs     = selected_attrs || column_names
      @parent             = parent
      @reflection         = reflection
      @aliased_prefix     = "t#{ join_dependency.joins.size }"
      @aliased_table_name = table_name #.tr('.', '_') # start with the table name, sub out any .'s
      @parent_table_name  = parent.active_record.table_name

      if !join_dependency.table_joins.blank? && join_dependency.table_joins.to_s.downcase =~ %r{join(\s+\w+)?\s+#{aliased_table_name.downcase}\son}
        join_dependency.table_aliases[aliased_table_name] += 1
      end

      unless join_dependency.table_aliases[aliased_table_name].zero?
        # if the table name has been used, then use an alias
        @aliased_table_name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}"
        table_index = join_dependency.table_aliases[aliased_table_name]
        join_dependency.table_aliases[aliased_table_name] += 1
        @aliased_table_name = @aliased_table_name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
      else
        join_dependency.table_aliases[aliased_table_name] += 1
      end

      if reflection.macro == :has_and_belongs_to_many || (reflection.macro == :has_many && reflection.options[:through])
        @aliased_join_table_name = reflection.macro == :has_and_belongs_to_many ? reflection.options[:join_table] : reflection.through_reflection.klass.table_name
        unless join_dependency.table_aliases[aliased_join_table_name].zero?
          @aliased_join_table_name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}_join"
          table_index = join_dependency.table_aliases[aliased_join_table_name]
          join_dependency.table_aliases[aliased_join_table_name] += 1
          @aliased_join_table_name = @aliased_join_table_name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
        else
          join_dependency.table_aliases[aliased_join_table_name] += 1
        end
      end
    end

    # Moved from JoinBase. Now only applicable to JoinAssociations
    #            
    def aliased_primary_key
      "_#{ aliased_prefix }_r0"
    end
    
    # Restrict the fields selected for this join's table_alias if specified in the find :select option
    # 
    def column_names_with_alias
      unless @column_names_with_alias
        @column_names_with_alias = []
        ([primary_key] + (@selected_attrs - [primary_key])).each_with_index do |column_name, i|
           @column_names_with_alias << [column_name, "_#{ aliased_prefix }_r#{ i }"] unless @selected_attrs.empty?
        end
      end
      return @column_names_with_alias
    end  
  end
end


class ActiveRecord::Associations::ClassMethods::InnerJoinDependency
  protected
    def build_join_association(reflection, parent, attrs)
      InnerJoinAssociation.new(reflection, self, parent)
    end
end