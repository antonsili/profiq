# frozen_string_literal: true

module Services
  module Resources
    module Ships
      module AvailableFilters
        class VideosService < AvailableFiltersBaseService
          attribute :current_user, Types::User
          attribute :operator_id, Types::Coercible::Integer.optional

          def perform
            success(
              available_filters:
                common_filters.merge(
                  resource_types: ships_resource_types_filter,
                  ship_section: SHIP_SECTION,
                  ships: fetch_serialized_ships,
                  sort_options: sort_options.each_with_index.map { |option, index| option.merge(id: index + 1) }
                )
            )
          rescue StandardError => e
            error(e.message, 400)
          end

          private

          def sort_options
            [
              { title: 'Date added (earliest to latest)', key: 'created_at', value: 'asc' },
              { title: 'Date added (latest to earliest)', key: 'created_at', value: 'desc' },
              common_sort_options,
              { title: 'Title (A-Z)', key: 'title', value: 'asc' },
              { title: 'Title (Z-A)', key: 'title', value: 'desc' }
            ].flatten
          end
        end
      end
    end
  end
end
