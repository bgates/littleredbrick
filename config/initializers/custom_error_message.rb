module ActiveModel
  class Errors

    # Redefine the ActiveRecord::Errors::full_messages method:
    #  Returns all the full error messages in an array. 'Base' messages are handled as usual.
    #  Non-base messages are prefixed with the attribute name as usual UNLESS they begin with '^'
    #  in which case the attribute name is omitted.
    #  E.g. validates_acceptance_of :accepted_terms, :message => '^Please accept the terms of service'
    def full_messages
      full_messages = []

      each do |attribute, messages|
        messages = Array.wrap(messages)
        next if messages.empty?

        if attribute == :base
          messages.each {|m| full_messages << m }
        else
          attr_name = attribute.to_s.gsub('.', '_').humanize
          attr_name = @base.class.human_attribute_name(attribute, :default => attr_name)

          messages.each do |m|
            options = m =~ /^\^/ ? { :default => "%{message}", :message => m[1..-1], :attribute => '' } :
                                   { :default => "%{attribute} %{message}", :message => m, :attribute => attr_name }
            full_messages << I18n.t(:"errors.format", options)
          end
        end
      end

      full_messages
    end
  end
end

