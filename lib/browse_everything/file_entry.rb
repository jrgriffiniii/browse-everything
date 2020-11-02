# frozen_string_literal: true

module BrowseEverything
  class FileEntry
    def self.relative_parent_pattern
      /^\.\.?$/
    end

    attr_reader :id, :location, :name, :size, :mtime, :type

    def initialize(id, location, name, size, mtime, container, type = nil)
      @id        = id
      @location  = location
      @name      = name
      @size      = size
      @mtime     = mtime
      @container = container
      @type      = type || (@container ? 'application/x-directory' : Rack::Mime.mime_type(File.extname(name)))
    end

    def relative_parent_path?
      self.class.relative_parent_pattern.match?(name)
    end

    def container?
      @container
    end
  end
end
