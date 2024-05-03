# frozen_string_literal: true

module Services
  module Resources
    module Operators
      module AvailableFilters
        class FaqsService < AvailableFiltersBaseService
          def perform
            success(
              available_filters:
                common_filters.merge(
                  available_markets: operator_role_available_markets,
                  resource_types: operators_resource_types_filter,
                  operator_types: OperatorType.select('id, name as title').order('lower(name) ASC'),
                  faq_types: FaqType.select('id, name').order('lower(name) ASC').map { |type| { id: type.id, title: type.name } },
                  sort_options: sort_options.each_with_index.map { |option, index| option.merge(id: index + 1) }
                )
            )
          rescue StandardError => e
            error(e.message, 400)
          end

          private

          def sort_options
            [
              { title: 'Date updated (latest to earliest)', key: 'updated_at', value: 'desc' },
              { title: 'Date updated (earliest to latest)', key: 'updated_at', value: 'asc' },
              common_sort_options,
              { title: 'Title (A-Z)', key: 'name', value: 'asc' },
              { title: 'Title (Z-A)', key: 'name', value: 'desc' }
            ].flatten
          end
        end
      end
    end
  end
end
