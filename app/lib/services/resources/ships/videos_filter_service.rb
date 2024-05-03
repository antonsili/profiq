# frozen_string_literal: true

module Services
  module Resources
    module Ships
      class VideosFilterService < BaseService
        include ::Resources::Ships::VideosHelper

        def perform
          videos = load_associations
          videos = apply_filters(videos)
          videos = videos.
            select("video_links.*, #{additional_attributes(ship_section)}").group('video_links.id')
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
          videos = VideoLink
          videos = if ship_section == 'general'
            videos.
              joins("INNER JOIN model_video_links ON model_video_links.video_link_id = video_links.id AND model_video_links.videoable_type = 'Ship'").
              joins('INNER JOIN ships on ships.id = model_video_links.videoable_id')
          elsif ship_section == 'all_sections'
            videos.
              joins("LEFT JOIN model_video_links ON model_video_links.video_link_id = video_links.id AND model_video_links.videoable_type = 'Ship'").
              joins('LEFT JOIN ship_video_links ON ship_video_links.video_link_id = video_links.id').
              joins("INNER JOIN ships on
                (ships.id = ship_video_links.ship_id) OR
                (ships.id = model_video_links.videoable_id AND model_video_links.videoable_type = 'Ship')"
                   )
          else
            videos.
              joins("INNER JOIN ship_video_links ON ship_video_links.video_link_id = video_links.id AND ship_video_links.video_link_type = '#{ship_section}'").
              joins('INNER JOIN ships on ships.id = ship_video_links.ship_id')
          end
          videos.
            joins('INNER JOIN operators ON ships.operator_id = operators.id').
            joins('INNER JOIN operator_markets ON operator_markets.operator_id = operators.id').
            joins("LEFT JOIN followings on followings.followable_id = operators.id AND followings.followable_type = 'Operator'")
        end

        def apply_filters(videos)
          videos = videos.search_by_title(query) if query
          videos = role_based_filters(videos, VideoLink)
          common_filters(videos)
        end

        def common_filters(videos)
          query = []
          query.push("ships.operator_id = #{operator_id}") if operator_id.present?
          query.push("ships.id = #{ship_id}") if ship_id.present?
          videos.where(query.join(' AND '))
        end
      end
    end
  end
end
