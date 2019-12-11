# frozen_string_literal: true

# Manages request parameters for the request to the Google Drive API
module BrowseEverything
  module Auth
    module Google
      class RequestParameters
        # Overrides the constructor for an OpenStruct instance
        # Provides default parameters
        def initialize(params = {})
          @user_query_filters = {}
          @shared_query_filters = {}
          @values = OpenStruct.new(default_params.merge(params))
        end

        def to_h
          @values.to_h
        end

        def add_shared_query_filter(query_term:, operator:, values:)
          if operator == 'in'
            new_constraint = "#{operator} #{query_term}"
            updated_constraints = Array.wrap(@shared_query_filters["'#{values}'"])
            updated_constraints << new_constraint
            @shared_query_filters["'#{values}'"] = updated_constraints
          else
            new_constraint = "#{operator} '#{values}'"
            updated_constraints = Array.wrap(@shared_query_filters[query_term])
            updated_constraints << new_constraint
            @shared_query_filters[query_term] = updated_constraints
          end
          @values.q = build_query
        end

        def add_user_query_filter(query_term:, operator:, values:)
          if operator == 'in'
            new_constraint = "#{operator} #{query_term}"
            updated_constraints = Array.wrap(@user_query_filters["'#{values}'"])
            updated_constraints << new_constraint
            @user_query_filters["'#{values}'"] = updated_constraints
          else
            new_constraint = "#{operator} '#{values}'"
            updated_constraints = Array.wrap(@user_query_filters[query_term])
            updated_constraints << new_constraint
            @user_query_filters[query_term] = updated_constraints
          end
          @values.q = build_query
        end

        private

          # The default query parameters for the Google Drive API
          # @return [Hash]
          # order_by: 'modifiedTime desc,folder,name',
          def default_params
            {
              q: build_query,
              order_by: 'folder,name desc,modifiedTime',
              fields: 'nextPageToken,files(name,id,mimeType,size,modifiedTime,parents,web_content_link)',
              include_team_drive_items: true,
              include_items_from_all_drives: true,
              supports_team_drives: true,
              supports_all_drives: true,
              corpora: 'user,allTeamDrives',
              page_size: 1000
            }
          end

          # @todo Refactor into the Query Class
          def shared_drives_query
            field_queries = ['sharedWithMe']
            query_filters = default_query_filters.merge(@shared_query_filters)
            query_filters.each_pair do |field, constraint|
              field_constraint = constraint.join(" and #{field} ")
              field_queries << "#{field} #{field_constraint}"
            end
            field_queries.join(' and ')
          end

          # @todo Refactor into the Query Class
          def user_drive_query
            field_queries = []
            query_filters = default_query_filters.merge(@user_query_filters)
            query_filters.each_pair do |field, constraint|
              field_constraint = constraint.join(" and #{field} ")
              field_queries << "#{field} #{field_constraint}"
            end
            field_queries.join(' and ')
          end

          # @todo Refactor into the Query Class
          def build_query
            ["(#{shared_drives_query})", "(#{user_drive_query})"].join(' or ')
          end

          def default_query_filters
            {
              'mimeType' => [
                '!= \'application/vnd.google-apps.audio\'',
                '!= \'application/vnd.google-apps.document\'',
                '!= \'application/vnd.google-apps.drawing\'',
                '!= \'application/vnd.google-apps.form\'',
                '!= \'application/vnd.google-apps.fusiontable\'',
                '!= \'application/vnd.google-apps.map\'',
                '!= \'application/vnd.google-apps.photo\'',
                '!= \'application/vnd.google-apps.presentation\'',
                '!= \'application/vnd.google-apps.script\'',
                '!= \'application/vnd.google-apps.site\'',
                '!= \'application/vnd.google-apps.spreadsheet\'',
                '!= \'application/vnd.google-apps.video\''
              ]
            }
          end
      end
    end
  end
end
