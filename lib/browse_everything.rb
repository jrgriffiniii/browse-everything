# frozen_string_literal: true

require 'rails'
require 'browse_everything/version'
require 'browse_everything/engine'
require 'browse_everything/retriever'

module BrowseEverything
  autoload :Browser,   'browse_everything/browser'
  autoload :FileEntry, 'browse_everything/file_entry'
  autoload :Resource, 'browse_everything/resource'

  module Driver
    module Paginator
      autoload :Base,         'browse_everything/driver/paginator/base'
      autoload :GoogleDrive,  'browse_everything/driver/paginator/google_drive'
    end

    autoload :Base,        'browse_everything/driver/base'
    autoload :FileSystem,  'browse_everything/driver/file_system'
    autoload :Dropbox,     'browse_everything/driver/dropbox'
    autoload :Box,         'browse_everything/driver/box'
    autoload :GoogleDrive, 'browse_everything/driver/google_drive'
    autoload :S3,          'browse_everything/driver/s3'

    # Access the sorter set for the base driver class
    # @return [Proc]
    def sorter
      BrowseEverything::Driver::Base.sorter
    end

    # Provide a custom sorter for all driver classes
    # @param [Proc] the sorting lambda (or proc)
    def sorter=(sorting_proc)
      BrowseEverything::Driver::Base.sorter = sorting_proc
    end

    module_function :sorter, :sorter=
  end

  module Auth
    module Google
      autoload :Credentials,        'browse_everything/auth/google/credentials'
      autoload :RequestParameters,  'browse_everything/auth/google/request_parameters'
    end
  end

  class InitializationError < RuntimeError; end
  class ConfigurationError < StandardError; end
  class NotImplementedError < StandardError; end
  class NotAuthorizedError < StandardError; end

  class << self
    attr_writer :config
    attr_accessor :current_browser

    def current_provider
      current_browser.session
    end

    def load_config_file(path)
      config_file_content = File.read(path)
      config_file_template = ERB.new(config_file_content)
      YAML.safe_load(config_file_template.result, [Symbol])
    end

    def config_path
      Rails.root.join('config', 'browse_everything_providers.yml')
    end

    def default_options
      load_config_file(config_path)
    end

    def configure(value)
      return if value.nil?
      # binding.pry

      options = {}
      if value.is_a?(Hash)
        options = ActiveSupport::HashWithIndifferentAccess.new(value)
      elsif value.is_a?(String)
        begin
          loaded_values = load_config_file(value)
          options = ActiveSupport::HashWithIndifferentAccess.new(loaded_values)
        rescue Errno::ENOENT
          raise ConfigurationError, 'Missing browse_everything_providers.yml configuration file'
        end
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end
      # @config = ActiveSupport::HashWithIndifferentAccess.new(options.merge(default_options))
      # binding.pry
      @config = ActiveSupport::HashWithIndifferentAccess.new(default_options.merge(options))

      if @config.include? 'drop_box'
        warn '[DEPRECATION] `drop_box` is deprecated.  Please use `dropbox` instead.'
        @config['dropbox'] = @config.delete('drop_box')
      end

      @config
    end

    def config
      return @config unless @config.nil?

      config_path = Rails.root.join('config', 'browse_everything_providers.yml')
      configure(config_path.to_s)
      @config
    end
  end
end
