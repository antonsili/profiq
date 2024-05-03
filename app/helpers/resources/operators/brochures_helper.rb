# frozen_string_literal: true

module Resources
  module Operators
    module BrochuresHelper
      def join_query_mappings
        @join_query_mappings ||= {
          general: {
            first_operator_market_name_query: operator_markets_join_model_attachments('model_attachments'),
            operator_markets_query: operator_markets_join_model_attachments('model_attachments')
          },
          faq: {
            first_operator_market_name_query: "#{faqs_join_operator_markets('faqs')} #{faqs_join_model_attachments('model_attachments')}",
            operator_markets_query: "#{faqs_join_operator_markets('faqs')} #{faqs_join_model_attachments('model_attachments')}"
          }
        }
      end

      def additional_attributes(operator_section, market_id)
        "#{first_operator_market_name_query(operator_section, market_id)},
        #{operator_markets_query(operator_section, market_id)}"
      end

      def first_operator_market_name_query(operator_section, market_id)
        <<-SQL
          (
            SELECT operator_markets.name
            FROM operator_markets
            #{join_query_mappings[operator_section.to_sym][:first_operator_market_name_query]}
            WHERE #{where_query(market_id)}
            ORDER BY operator_markets.created_at ASC
            LIMIT 1
          ) AS first_operator_market_name
        SQL
      end

      def operator_markets_query(operator_section, market_id)
        <<-SQL
          (
            SELECT JSON_AGG(DISTINCT JSONB_BUILD_OBJECT('title', operator_markets.name, 'type_slug', select_options.slug, 'market_slug', markets_markets.slug, 'operator_slug', operators.slug))
            FROM operator_markets
            #{join_query_mappings[operator_section.to_sym][:operator_markets_query]}
            INNER JOIN select_options ON select_options.id = operator_markets.operator_type_id
            INNER JOIN markets_markets ON markets_markets.id = operator_markets.market_id
            INNER JOIN operators on operators.id = operator_markets.operator_id
            WHERE #{where_query(market_id)}
          ) as operator_markets
        SQL
      end

      def where_query(market_id)
        <<-SQL
          model_attachments.attachment_id = attachments.id
          AND operator_markets.market_id = #{market_id}
        SQL
      end

      def operator_markets_join_model_attachments(join_table)
        <<-SQL
          INNER JOIN #{join_table} ON model_attachments.attachable_id = operator_markets.id AND model_attachments.attachable_type = 'OperatorMarket'
        SQL
      end

      def faqs_join_model_attachments(join_table)
        <<-SQL
          INNER JOIN #{join_table} ON model_attachments.attachable_id = faqs.id AND model_attachments.attachable_type = 'Faq'
        SQL
      end

      def faqs_join_operator_markets(join_table)
        <<-SQL
          INNER JOIN #{join_table} ON operator_markets.id = faqs.source_of_faqs_id AND faqs.source_of_faqs_type = 'OperatorMarket'
        SQL
      end
    end
  end
end
