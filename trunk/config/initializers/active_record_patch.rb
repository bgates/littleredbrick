module ActiveRecord
  module Associations
    class HasManyAssociation < AssociationCollection #:nodoc:
      protected
        def construct_sql
          case
            when @reflection.options[:finder_sql]
              @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

            when @reflection.options[:as]
              if @owner.respond_to?(:polymorphic_type) && @owner.polymorphic_type
                quoted_value = @owner.polymorphic_type
              else
                quoted_value = @owner.class.base_class.name.to_s
              end
              resource_type = @owner.class.quote_value(quoted_value)
              @finder_sql =
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = #{owner_quoted_id} AND " +
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = #{resource_type}"
              @finder_sql << " AND (#{conditions})" if conditions
            else
              @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = #{owner_quoted_id}"
              @finder_sql << " AND (#{conditions})" if conditions
          end

          construct_counter_sql
        end

    end

    class AssociationProxy #:nodoc:
      protected
        # Assigns the ID of the owner to the corresponding foreign key in +record+.
        # If the association is polymorphic the type of the owner is also set.
        def set_belongs_to_association_for(record)
          if @reflection.options[:as]
            if @owner.respond_to?(:polymorphic_type) && @owner.polymorphic_type
              resource_type = @owner.polymorphic_type
            else
              resource_type = @owner.class.base_class.name.to_s
            end
            record["#{@reflection.options[:as]}_id"]   = @owner.id if @owner.persisted?
            record["#{@reflection.options[:as]}_type"] = resource_type
          else
            if @owner.persisted?
              primary_key = @reflection.options[:primary_key] || :id
              record[@reflection.primary_key_name] = @owner.send(primary_key)
            end
          end
        end

    end
  end
end

