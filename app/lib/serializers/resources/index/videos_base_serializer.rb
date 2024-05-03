# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      class VideosBaseSerializer < ActiveModel::Serializer
        include Rails.application.routes.url_helpers

        attributes %I[id title kind key created_at url first_operator preview tags preview_image]

        def created_at
          object.created_at.to_s(:long_date_short_month_without_time)
        end

        def url
          object.href
        end

        def preview_image
          object.youtube? ? "http://i3.ytimg.com/vi/#{object.key}/hqdefault.jpg" : "https://vumbnail.com/#{object.key}_large.jpg"
        end

        def first_operator
          {
            title: object.first_operator_market_name,
            profile_image: first_operator_market.profile_image&.thumbnail_url('200x')
          }
        end

        private

        def first_operator_market
          @first_operator_market ||= @instance_options[:first_operator_markets].detect { |om| om.id == object.first_operator_market_id }
        end
      end
    end
  end
end
