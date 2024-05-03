# frozen_string_literal: true

module Services
  module Resources
    module Operators
      class BrochuresFilterService < BaseService
        include ::Resources::Operators::BrochuresHelper

        attribute :trade, Types::Params::Bool.optional
        attribute :file_type_ids, Types::Params::Array.optional
        attribute :attachment_tag_ids, Types::Params::Array.optional
        attribute :operator_section, Types::String

        def perform
          attachments = load_associations
          attachments = apply_filters(attachments)
          attachments = attachments.
            select("attachments.id, attachments.created_at, #{additional_attributes(operator_section, market_id)}").group('attachments.id')
          attachments = attachments.order("#{sort_by} #{order_by}") if sort_by.present? && order_by.present?
          return [Attachment.none.page(page || 1).per(per || RESOURCES_PER_PAGE), Attachment.none] if attachments.blank?

          prepare_results(attachments)
        end

        private

        def prepare_results(attachments)
          attachments = attachments.page(page || 1).per(per || RESOURCES_PER_PAGE)
          attachment_ids = attachments.map { |r| r['id'] }
          [
            attachments,
            Attachment.includes(:file_type).where(id: attachment_ids).order("position(id::text in '#{attachment_ids.join(',')}')")
          ]
        end

        def load_associations
          attachments = Attachment.
            joins('LEFT JOIN model_attachments ON model_attachments.attachment_id = attachments.id').
            joins('LEFT JOIN attachments_attachment_tags ON attachments_attachment_tags.attachment_id = attachments.id')

          attachments = if operator_section == 'general'
            attachments.joins(
              "LEFT JOIN operator_markets ON model_attachments.attachable_id = operator_markets.id AND model_attachments.attachable_type = 'OperatorMarket'"
            )
          else
            attachments.
              joins("LEFT JOIN faqs ON faqs.id = model_attachments.attachable_id AND model_attachments.attachable_type = 'Faq'").
              joins("LEFT JOIN operator_markets ON operator_markets.id = faqs.source_of_faqs_id AND faqs.source_of_faqs_type = 'OperatorMarket'")
          end
          attachments.
            joins('LEFT JOIN operators on operators.id = operator_markets.operator_id').
            joins("LEFT JOIN followings on followings.followable_id = operators.id AND followings.followable_type = 'Operator'").
            where(operator_markets: { market_id: market_id })
        end

        def apply_filters(attachments)
          attachments = attachments.search_by_name(query) if query
          attachments = role_based_filters(attachments, Attachment)
          common_filters(attachments)
        end

        def common_filters(attachments)
          query = []
          query.push("attachments.file_type_id IN (#{file_type_ids.join(',')})") if file_type_ids.present?
          query.push("operator_markets.operator_type_id = #{operator_type_id}") if operator_type_id.present?
          query.push("operator_markets.operator_id = #{operator_id}") if operator_id.present?
          query.push("attachments_attachment_tags.attachment_tag_id IN (#{attachment_tag_ids.join(',')})") if attachment_tag_ids.present?
          query.push("attachments.trade = #{trade}")
          attachments.where(query.join(' AND '))
        end
      end
    end
  end
end
