# frozen_string_literal: true

module BrowseEverything
  class Bytestream
    attr_accessor :id, :container_id, :location, :name, :size, :mtime, :uri, :media_type

    def file_uri?
      /^file\:\/\// =~ uri
    end

    # Constructor
    # @param id
    # @param container_id
    # @param location
    # @param name
    # @param size
    # @param mtime
    # @param media_type
    def initialize(id:, container_id: nil, location:, name:, size:, mtime:,
                   uri:, media_type: 'application/octet-stream')
      @id = id
      @container_id = container_id
      @location = location
      @name = name
      @size = size
      @mtime = mtime
      @uri = uri
      @media_type = media_type
    end
  end
end
