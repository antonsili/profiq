# frozen_string_literal: true

module Resources
  module Operators
    module FaqsHelper
      def operator_type_hidden(market_id)
        <<-SQL
          CASE
          WHEN (
            SELECT COUNT(*)
            FROM operator_markets
            WHERE operator_markets.operator_id = (
              SELECT operator_id
              FROM operator_markets
              WHERE operator_markets.id = faqs.source_of_faqs_id AND faqs.source_of_faqs_type = 'OperatorMarket'
            ) AND operator_markets.market_id = #{market_id}
            HAVING COUNT(*) = 1
          ) IS NOT NULL THEN TRUE
          ELSE FALSE
          END AS has_only_one_operator_market
        SQL
      end

      def first_operator_market_name_query
        <<-SQL
          (
            SELECT operator_markets.name
            FROM operator_markets
            WHERE operator_markets.id = faqs.source_of_faqs_id AND
              faqs.source_of_faqs_type = 'OperatorMarket'
          ) AS first_operator_market_name
        SQL
      end
    end
  end
end
