module ActionView
  module Helpers
    module FormTagHelper
    private
        def extra_tags_for_form(html_options)
          snowman_tag = tag(:input, :type => "hidden",
                            :name => "utf8", :value => "&#x2713;".html_safe)

          authenticity_token = html_options.delete("authenticity_token")
          method = html_options.delete("method").to_s

          method_tag = case method
            when /^get$/i # must be case-insensitive, but can't use downcase as might be nil
              html_options["method"] = "get"
              ''
            when /^post$/i, "", nil
              html_options["method"] = "post"
              token_tag(authenticity_token)
            else
              html_options["method"] = "post"
              tag(:input, :type => "hidden", :name => "_method", :value => method) + token_tag(authenticity_token)
          end

          tags = snowman_tag << method_tag
          content_tag(:div, tags, :class => 'hide')
        end

        def token_tag(token)
          if token == false || !protect_against_forgery?
            ''
          else
            token = form_authenticity_token if token.nil?
            tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => token)
          end
        end
    end
    module UrlHelper

      def button_to(name, options = {}, html_options = {})
        html_options = html_options.stringify_keys
        convert_boolean_attributes!(html_options, %w( disabled ))

        method_tag = ''
        if (method = html_options.delete('method')) && %w{put delete}.include?(method.to_s)
          method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
        end

        form_method = method.to_s == 'get' ? 'get' : 'post'

        remote = html_options.delete('remote')

        request_token_tag = ''
        if form_method == 'post' && protect_against_forgery?
          request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
        end

        url = options.is_a?(String) ? options : self.url_for(options)
        name ||= url

        html_options = convert_options_to_data_attributes(options, html_options)

        if src = html_options.delete('src')
          input_hash =  { "type" => "image", "src" => path_to_image(src), "alt" => name, "title" => name }
        else
          input_hash = {"type" => "submit", "value" => name}
        end
        html_options.merge!(input_hash)

        ("<form method=\"#{form_method}\" action=\"#{html_escape(url)}\" #{"data-remote=\"true\"" if remote} class=\"button-to\">" +
          method_tag + tag("input", html_options) + request_token_tag + "</form>").html_safe
      end

    end


    module TextHelper

      def truncate_plus(text, length = 30, truncate_string = "...")
        truncate(text, length, truncate_string).gsub(/\s\w*\.\.\./,'...')
      end
    end
  end
end

