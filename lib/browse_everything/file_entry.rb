# frozen_string_literal: true

module BrowseEverything
  class FileEntry
    attr_reader :id, :location, :name, :size, :mtime, :type, :provider_name, :auth_token

    # rubocop:disable Metrics/ParameterLists
    def initialize(id, location, name, size, mtime, container, type = nil, provider_name = nil, auth_token = nil)
      @id        = id
      @location  = location
      @name      = name
      @size      = size
      @mtime     = mtime
      @container = container
      @type      = type
      @provider_name = provider_name
      @auth_token = auth_token

      @type = default_type if @type.nil?
    end
    # rubocop:enable Metrics/ParameterLists

    def relative_parent_path?
      name =~ /^\.\.?$/ ? true : false
    end

    def container?
      @container
    end

    def provider
      @provider ||= BrowserFactory.for(name: provider_name)
    end

    def mime_type
      extname = File.extname(name)
      provider.class.mime_type(extname)
    end

    def default_type
      return provider.class.container_mime_type if container?

      mime_type
    end

    def url
      return unless provider.respond_to?(:download_url)

      provider.download_url(id)
    end

    def auth_header
      return unless provider.respond_to?(:auth_header)

      provider.auth_header(auth_token)
    end
  end
end
