# frozen_string_literal: true

module Services
  module Resources
    module Operators
      module AvailableFilters
        class BrochuresService < AvailableFiltersBaseService
          def perform
            success(
              available_filters:
                common_filters.merge(
                  available_markets: operator_role_available_markets,
                  resource_types: operators_resource_types_filter,
                  operator_section: brochures_operator_section_filter,
                  file_types: FileType.id_title_pairs,
                  operator_types: OperatorType.select('id, name as title').order('lower(name) ASC'),
                  attachment_tags: AttachmentTag.select('id, name as title').order('lower(name) ASC'),
                  trade_resources: true,
                  sort_options: sort_options.each_with_index.map { |option, index| option.merge(id: index + 1) }
                )
            )
          rescue StandardError => e
            error(e.message, 400)
          end

          private

          def sort_options
            [
              { title: 'Date added (latest to earliest)', key: 'created_at', value: 'desc' },
              { title: 'Date added (earliest to latest)', key: 'created_at', value: 'asc' },
              { title: 'Drop-off date (earliest to latest)', key: 'expires_on', value: 'asc' },
              { title: 'Drop-off date (latest to earliest)', key: 'expires_on', value: 'desc' },
              common_sort_options,
              { title: 'Title (A-Z)', key: 'file_name', value: 'asc' },
              { title: 'Title (Z-A)', key: 'file_name', value: 'desc' }
            ].flatten
          end
        end
      end
    end
  end
end
