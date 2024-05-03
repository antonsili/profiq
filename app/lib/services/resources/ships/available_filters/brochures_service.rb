# frozen_string_literal: true

module Services
  module Resources
    module Ships
      module AvailableFilters
        class BrochuresService < AvailableFiltersBaseService
          attribute :current_user, Types::User
          attribute :operator_id, Types::Coercible::Integer.optional

          def perform
            success(
              available_filters:
                common_filters.merge(
                  resource_types: ships_resource_types_filter,
                  file_types: FileType.all.order('lower(name) ASC').map { |type| { id: type.id, title: type.title } },
                  ship_section: SHIP_SECTION - [{ title: 'Accommodation', id: 'accomodation' }],
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
