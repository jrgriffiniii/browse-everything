# frozen_string_literal: true

module BrowseEverything
  module Driver
    class FileSystem < Base
      def icon
        'file'
      end

      def validate_config
        raise BrowseEverything::InitializationError, 'FileSystem driver requires a :home argument' if config[:home].blank?
      end

      def contents(path = '', _page_index = 0, _auth_token = nil)
        real_path = if path == '/' || !File.exist?(path)
                      File.join(home_path, path)
                    else
                      path
                    end

        values = if File.directory?(real_path)
                   make_directory_entry real_path
                 else
                   [details(real_path)]
                 end

        @entries = values.compact

        @sorter.call(@entries)
      end

      # Generate the attributes Hash for a FileEntry object
      # This should be moved to FileEntry#attributes
      # @param [BrowseEverything::FileEntry] file_entry
      # @param [String] access_token
      # @return [Hash]
      def attributes_for(file_entry, _access_token = nil)
        full_path = File.expand_path(file_entry.id)
        uri = "file://#{full_path}"

        {
          id: file_entry.id,
          url: uri,
          file_name: file_entry.name,
          file_size: file_entry.size,
          container: file_entry.container?,
          provider: file_entry.provider_name
        }
      end

      # Links need to be restructured as first-order objects
      class Link < OpenStruct
        def container?
          directory.present?
        end
      end

      # Retrieve an array of link attributes for a resource path
      # @param path [String]
      # @return [Array]
      def link_for(path, _file_name = '', _file_size = 0, _container = false, _access_token = nil)
        full_path = File.expand_path(path)
        return [] if hidden?(full_path)

        uri = "file://#{full_path}"
        # Ignore the argument
        file_name = File.basename(full_path)
        # Ignore the argument
        file_size = calculate_file_size(full_path)
        container = File.directory?(full_path)

        link_attributes = {
          id: full_path,
          file_name: file_name,
          file_size: file_size,
          container: container,
          directory: container,
          type: container ? self.class.container_mime_type : self.class.file_mime_type,
          provider: 'file_system'
        }

        [[uri, link_attributes]]
      end

      def authorized?
        true
      end

      # Construct a FileEntry objects for a file-system resource
      # @param path [String] path to the file
      # @param display [String] display label for the resource
      # @return [BrowseEverything::FileEntry]
      def details(path, display = File.basename(path))
        return unless File.exist?(path)

        info = File::Stat.new(path)
        BrowseEverything::FileEntry.new(
          path,
          [key, path].join(':'),
          display,
          info.size,
          info.mtime,
          info.directory?,
          nil,
          'file_system'
        )
      end

      private

        # Construct an array of FileEntry objects for the contents of a
        # directory
        # @param real_path [String] path to the file system directory
        # @return [Array<BrowseEverything::FileEntry>]
        def make_directory_entry(real_path)
          pattern = File.join(real_path, '*')
          Dir.glob(pattern).collect { |f| details(f) }
        end

        def home_path
          Pathname.new(config[:home])
        end

        def make_pathname(path)
          expanded = File.expand_path(path)
          file_entry_path = Pathname.new(expanded)
          file_entry_path.relative_path_from(home_path)
        end

        def calculate_file_size(path)
          File.size(path).to_i
        rescue StandardError => error
          Rails.logger.error "Failed to find the file size for #{path}: #{error}"
          0
        end

        # Determines whether or not a file entry is hidden
        # @param [String] path
        # @return [Boolean]
        def hidden?(path)
          path =~ /^\..+/
        end
    end
  end
end
