module ActiveRecord
  module Validations
    class AssociatedValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return if (value.is_a?(Array) ? value : [value]).collect{ |r| r.nil? || r.valid? }.all?
        associated_errors = [record.send(attribute)].flatten.map do |associated|
          associated.errors
        end
        associated_errors.each do |error|
          error.each do |associated_attr, associated_error|
            record.errors.add("#{attribute}_#{associated_attr}".to_sym, associated_error)
          end
        end
        record.errors.delete(attribute)
      end
    end
  end
end

class ActiveModel::Errors
  alias old_full_messages full_messages
  def full_messages
    old_full_messages.uniq
  end
end

