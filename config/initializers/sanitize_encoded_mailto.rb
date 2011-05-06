module HTML
  class WhiteListSanitizer < Sanitizer

  protected
    #the last line of this allows the use of mail_to('text', nil, :encode => 'hex') inside text that has sanitize applied to it
    def contains_bad_protocols?(attr_name, value)
      uri_attributes.include?(attr_name) &&
      (value =~ /(^[^\/:]*):|(&#0*58)|(&#x70)|(%|&#37;)3A/ && !(allowed_protocols.include?(value.split(protocol_separator).first) ||
                                                                allowed_protocols.include?(CGI::unescapeHTML(value.split(protocol_separator).first))))
    end
  end
end

