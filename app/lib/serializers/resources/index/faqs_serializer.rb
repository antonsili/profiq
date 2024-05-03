# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      class FaqsSerializer < ActiveModel::Serializer
        include Rails.application.routes.url_helpers

        attributes %I[id title updated_at description first_operator video preview]

        has_many :faq_types, serializer: CommonSerializer
        has_many :model_attachments, key: :attachments, serializer: Faqs::AttachmentSerializer

        def title
          object.name
        end

        def updated_at
          object.created_at.to_s(:long_date_short_month_without_time)
        end

        def first_operator
          {
            title: operator_market_name
          }
        end

        def video
          video_link = object.video_link
          return nil unless video_link

          {
            title: video_link.title,
            preview_image: video_link.youtube? ? "http://i3.ytimg.com/vi/#{video_link.key}/hqdefault.jpg" : "https://vumbnail.com/#{video_link.key}_large.jpg",
            kind: video_link.kind,
            key: video_link.key,
            url: video_link.href,
            operator: {
              title: operator_market.title,
              profile_image: operator_market.profile_image&.thumbnail_url('200x')
            }
          }
        end

        def preview
          {
            kind: 'Operator',
            links: [
              {
                href: operator_url(operator_market.slug, type: operator_market.operator_type.slug, market: operator_market.market.slug),
                title: operator_market.title
              }
            ]
          }
        end

        private

        def operator_market
          object.source_of_faqs
        end

        def operator_market_name
          return operator_market.title if object.has_only_one_operator_market

          "#{operator_market.title} (#{operator_market.operator_type.name})"
        end
      end
    end
  end
end
