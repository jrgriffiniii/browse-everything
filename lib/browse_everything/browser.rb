# frozen_string_literal: true

module BrowseEverything
  class Browser
    attr_reader :providers

    def initialize(opts = {})
      config = BrowseEverything.config

      if opts.key?(:url_options)
        url_options = opts.delete(:url_options)
        config.merge(opts)
      else
        url_options = opts
      end

      @providers = ActiveSupport::HashWithIndifferentAccess.new
      # This iterates through the configuration for each provider
      config.each_pair do |driver_key, config|
        begin
          driver = driver_key.to_s
          driver_klass = BrowseEverything::Driver.const_get((config[:driver] || driver).camelize.to_sym)
          @providers[driver_key] = driver_klass.new(config.merge(url_options: url_options))
        rescue NameError
          Rails.logger.warn "Unknown provider: #{driver}"
        end
      end
    end

    def first_provider
      @providers.to_hash.each_value.to_a.first
    end
  end
end
