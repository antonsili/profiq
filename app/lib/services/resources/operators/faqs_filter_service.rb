# frozen_string_literal: true

module Services
  module Resources
    module Operators
      class FaqsFilterService < BaseService
        include ::Resources::Operators::FaqsHelper

        attribute :faq_type_id, Types::Coercible::Integer.optional

        def perform
          faqs = load_associations
          faqs = apply_filters(faqs)
          faqs = faqs.select("faqs.*, #{operator_type_hidden(market_id)}, #{first_operator_market_name_query}").group('faqs.id')
          faqs = faqs.order("#{sort_by} #{order_by}") if sort_by.present? && order_by.present?
          faqs.page(page || 1).per(per || RESOURCES_PER_PAGE)
        end

        private

        def load_associations
          Faq.
            includes(:faqs_faq_types, :faq_types, :video_link,
              source_of_faqs: %i[operator operator_type profile_image market], model_attachments: [:attachment]
            ).
            joins("INNER JOIN operator_markets ON operator_markets.id = faqs.source_of_faqs_id AND faqs.source_of_faqs_type = 'OperatorMarket'").
            joins('LEFT JOIN operators on operators.id = operator_markets.operator_id').
            joins("LEFT JOIN followings on followings.followable_id = operators.id AND followings.followable_type = 'Operator'").
            joins('LEFT JOIN faqs_faq_types ON faqs_faq_types.faq_id = faqs.id').
            where(operator_markets: { market_id: market_id })
        end

        def apply_filters(faqs)
          faqs = faqs.search_by_name_and_description(query) if query
          faqs = role_based_filters(faqs, Faq)
          common_filters(faqs)
        end

        def common_filters(faqs)
          query = []
          query.push("operator_markets.operator_type_id = #{operator_type_id}") if operator_type_id.present?
          query.push("operator_markets.operator_id = #{operator_id}") if operator_id.present?
          query.push("faqs_faq_types.faq_type_id = #{faq_type_id}") if faq_type_id.present?
          faqs.where(query.join(' AND '))
        end
      end
    end
  end
end
