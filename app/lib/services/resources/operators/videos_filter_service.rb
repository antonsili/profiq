# frozen_string_literal: true

module Services
  module Resources
    module Operators
      class VideosFilterService < BaseService
        include ::Resources::Operators::VideosHelper

        attribute :operator_section, Types::String

        def perform
          videos = load_associations
          videos = apply_filters(videos)
          videos = videos.
            select("video_links.*, #{additional_attributes(operator_section, market_id)}").group('video_links.id')
          videos = videos.order("#{sort_by} #{order_by}") if sort_by.present? && order_by.present?
          prepare_results(videos)
        end

        private

        def prepare_results(videos)
          [
            videos.page(page || 1).per(per || RESOURCES_PER_PAGE),
            OperatorMarket.includes(:profile_image).where(id: videos.map(&:first_operator_market_id)).select(:id)
          ]
        end

        def load_associations
          videos = VideoLink.
            joins('LEFT JOIN model_video_links ON model_video_links.video_link_id = video_links.id')
          videos = if operator_section == 'general'
            videos.joins(
              "LEFT JOIN operator_markets ON model_video_links.videoable_id = operator_markets.id AND model_video_links.videoable_type = 'OperatorMarket'"
            )
          else
            videos.
              joins("LEFT JOIN faqs ON faqs.id = model_video_links.videoable_id AND model_video_links.videoable_type = 'Faq'").
              joins("LEFT JOIN operator_markets ON operator_markets.id = faqs.source_of_faqs_id AND faqs.source_of_faqs_type = 'OperatorMarket'")
          end
          videos.
            joins('LEFT JOIN operators on operators.id = operator_markets.operator_id').
            joins("LEFT JOIN followings on followings.followable_id = operators.id AND followings.followable_type = 'Operator'").
            where(operator_markets: { market_id: market_id })
        end

        def apply_filters(videos)
          videos = videos.search_by_title(query) if query
          videos = role_based_filters(videos, VideoLink)
          common_filters(videos)
        end

        def common_filters(videos)
          query = []
          query.push("operator_markets.operator_type_id = #{operator_type_id}") if operator_type_id.present?
          query.push("operator_markets.operator_id = #{operator_id}") if operator_id.present?
          videos.where(query.join(' AND '))
        end
      end
    end
  end
end
