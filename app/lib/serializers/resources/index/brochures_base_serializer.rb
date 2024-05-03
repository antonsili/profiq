# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      class BrochuresBaseSerializer < ActiveModel::Serializer
        include Rails.application.routes.url_helpers

        attributes %I[id trade_tag src file_name created_at expires_on first_operator tags preview preview_image]

        belongs_to :file_type, serializer: CommonSerializer

        def expires_on
          object.expires_on&.to_s(:long_date_short_month_without_time)
        end

        def created_at
          object.created_at.to_s(:long_date_short_month_without_time)
        end

        def preview_image
          # N+1 while requesting thumbnail
          object.thumbnail_url('300x')
        end

        def src
          object.file.url
        end

        def first_operator
          {
            title: additional_attributes['first_operator_market_name']
          }
        end

        private

        def additional_attributes
          @additional_attributes ||= @instance_options[:additional_attributes].detect { |a| a['id'].to_i == object.id }
        end
      end
    end
  end
end
