# frozen_string_literal: true

module Services
  module Resources
    module Ships
      class BaseService < Services::Resources::FilterBaseService
        attribute :ship_section, Types::String
        attribute :ship_id, Types::Coercible::Integer.optional

        private

        def not_supported_markets_filter
          <<-SQL
            EXISTS (
              SELECT 1
              FROM operator_markets
              INNER JOIN operators ON operators.id = operator_markets.operator_id
              WHERE operator_markets.supported = false
                AND operators.id = ships.operator_id
              GROUP BY operators.id
              HAVING COUNT(*) = (
                SELECT COUNT(*)
                FROM operator_markets
                WHERE operator_id = operators.id
              )
            )
          SQL
        end
      end
    end
  end
end
