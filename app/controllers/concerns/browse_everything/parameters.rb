# frozen_string_literal: true

require File.expand_path('../../../../lib/browse_everything/resource', __dir__)

module BrowseEverything
  module Parameters
    extend ActiveSupport::Concern

    included do
      # Retrieve the file and directory entries selected using the POST request
      # @return [Array<String>]
      def browse_everything_params
        return unless params[:browse_everything]

        file_values = params[:browse_everything].fetch(:selected_files, [])
        dir_values = params[:browse_everything].fetch(:selected_directories, [])
        # Ensure that these are empty Arrays if ActionController::Parameters are
        # empty
        file_values = [] if file_values.empty?
        dir_values = [] if dir_values.empty?

        file_values + dir_values
      end

      # Retrieve the file entries selected using the legacy POST request parameter
      # @return [Array<String>]
      def selected_params
        params[:selected_files]
      end

      # Retrieve the files selected from browse-everything
      # @return [BrowseEverything::Resource]
      def selected_files
        return [] unless selected_params

        values = selected_params.values.uniq
        values.map { |value| BrowseEverything::Resource.new(value) }
      end

      # Determine whether or not cloud service files are being uploaded
      # @return [Boolean]
      def selected_cloud_files?
        values = selected_files.map(&:cloud_file?)
        values.reduce(:|)
      end
    end
  end
end
