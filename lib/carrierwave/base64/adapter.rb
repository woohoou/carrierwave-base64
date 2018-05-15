require 'securerandom'

module Carrierwave
  module Base64
    module Adapter
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def mount_base64_uploader(attribute, uploader_class, options = {})
        mount_uploader attribute, uploader_class, options
        options[:file_name] ||= proc { attribute }

        if options[:file_name].is_a?(String)
          warn(
            '[Deprecation warning] Setting `file_name` option to a string is '\
            'deprecated and will be removed in 3.0.0. If you want to keep the '\
            'existing behaviour, wrap the string in a Proc'
          )
        end

        define_method "#{attribute}=" do |data|
          return if data == send(attribute).to_s

          if respond_to?("#{attribute}_will_change!") && data.present?
            send "#{attribute}_will_change!"
          end

          return super(data) unless data.is_a?(String) &&
                                    data.strip.start_with?('data')

          filename = if options[:file_name].respond_to?(:call)
                       options[:file_name].call(self)
                     else
                       options[:file_name]
                     end.to_s

          super Carrierwave::Base64::Base64StringIO.new(data.strip, filename)
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
      end

      def mount_base64_uploaders(attribute, uploader_class, options = {})
        mount_uploaders attribute, uploader_class, options

        options[:file_name] ||= proc { attribute }

        if options[:file_name].is_a?(String)
          warn(
            '[Deprecation warning] Setting `file_name` option to a string is '\
            'deprecated and will be removed in 3.0.0. If you want to keep the '\
            'existing behaviour, wrap the string in a Proc'
          )
        end

        define_method "#{attribute}=" do |data_array|
          return if data_array == send(attribute) # TODO: Check

          if respond_to?("#{attribute}_will_change!") && data_array.present?
            send "#{attribute}_will_change!"
          end
          filename = if options[:file_name].respond_to?(:call)
            options[:file_name].call(self)
          else
            options[:file_name]
          end.to_s

          files_array = []
          data_array.each_with_index do |data, i|
            files_array << if data.is_a?(String) && data.strip.start_with?('data')
              Carrierwave::Base64::Base64StringIO.new(data.strip, filename+'_'+i.to_s)
            elsif send(attribute).map(&:url).include?(data)
              file = send(attribute).find{|t| t.url == data}
              files_array << file if file.present?
            else
              files_array << data
            end
          end if data_array.is_a?(Array)

          send("remove_#{attribute}!".to_sym) if files == []

          super files_array
        end
      end
    end
  end
end
