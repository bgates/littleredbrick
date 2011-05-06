# This Active Record mod enables eager loading of associations
# (the :include option) for both the find_by_sql method and has_many
# and has_and_belongs_to_many associations that use the :finder_sql option.
#
# The custom sql must include a left outer join for each eager-loaded model,
# and in addition must alias each selected field using the following aliases:
#    Primary key of base model: t0_r0
#    Other fields from base model: t0_rm, where m is the (m-1)th field of the table
#    Primary key of eager loaded models: tn_r0, where n is nth outer-joined table
#    Other fields from eager loaded models: the appropriate tn_rm alias
#
module ActiveRecord
  class Errors

    def delete(key)
      @errors.delete(key.to_s)
    end
  end
=begin
  module Associations
    class HasManyAssociation
      protected
        def find_target
          if @reflection.options[:finder_sql]
            @reflection.klass.find_by_sql(@finder_sql, :include => @reflection.options[:include])
          else
            find(:all)
          end
        end
    end

    class HasAndBelongsToManyAssociation
      protected
        def find_target
          if @reflection.options[:finder_sql]
            records = @reflection.klass.find_by_sql(@finder_sql, :include => @reflection.options[:include])
          else
            records = find(:all)
          end

          @reflection.options[:uniq] ? uniq(records) : records
        end
    end
  end

  class Base
    def self.find_by_sql(sql, options = {})
      options.assert_valid_keys [:include]
      sanitized_sql = sanitize_sql(sql)
      if options[:include].blank?
        connection.select_all(sanitized_sql, "#{name} Load").collect! { |record| instantiate(record) }
      else
        find_with_associations(options.merge(:sql => sanitized_sql))
      end
    end

    private
      def self.select_all_rows(options, join_dependency)
        connection.select_all(
          options[:sql] || construct_finder_sql_with_included_associations(options, join_dependency),
          "#{name} Load Including Associations"
        )
      end
  end
=end
  class BaseWithoutTable < Base
    self.abstract_class = true

    def create_or_update
      errors.empty?
    end

    class << self
      def columns()
        @columns ||= []
      end

      def column(name, sql_type = nil, default = nil, null = true)
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
        reset_column_information
      end

      # Do not reset @columns
      def reset_column_information
        read_methods.each { |name| undef_method(name) }
        @column_names = @columns_hash = @content_columns = @dynamic_methods_hash = @read_methods = nil
      end
    end

  end

  module Validations

    def invalid?
      !valid?
    end
    
    module ClassMethods
      def validates_associated(*associations)
        configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid], :on => :save }
        configuration.update(associations.extract_options!)
        associations.each do |association|
          class_eval do
            validates_each(associations, configuration) do |record, associate_name, value|
              associates = record.send(associate_name)
              associates = [associates] unless associates.respond_to?('each')
              associates.each do |associate|
                if associate && !associate.valid?
                  associate.errors.each do |key, value|
                    record.errors.add(key, value)
                  end
                  #if I add an explicit error message for the association, I must want it; if not, the error must have been explained by the above loop
                  record.errors.delete(associate_name) if record.errors.on(associate_name) == ActiveRecord::Errors.default_error_messages[:invalid]
                  record.errors.add(associate_name, configuration[:message]) unless configuration[:message] == ActiveRecord::Errors.default_error_messages[:invalid]
                end
              end
            end
          end
        end
      end
    end
  end
end