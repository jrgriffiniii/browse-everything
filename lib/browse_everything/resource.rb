# frozen_string_literal: true

# Class modeling resources selected for upload using browse-everything
module BrowseEverything
  class Resource < ActiveSupport::HashWithIndifferentAccess
    # Retrieve the path for the resource
    # @return [String]
    def path
      return if url.nil?

      _provider_key, uri = url.split(/:\/\//)
      uri
    end

    # Determine whether or not this file is a cloud resource
    # @return [Boolean]
    def cloud_file?
      return false if url.nil?

      m = /^https?\:/.match(url)
      !m.nil?
    end

    private

      # Retrieve the URL for the resource
      # @return [String]
      def url
        fetch("url", nil)
      end
  end
end
