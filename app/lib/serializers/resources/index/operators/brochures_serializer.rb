# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      module Operators
        class BrochuresSerializer < BrochuresBaseSerializer
          def trade_tag
            object.trade
          end

          def tags
            object.attachment_tags.map { |tag| { id: tag.id, name: tag.name, title: tag.name, slug: tag.slug } }
          end

          def preview
            {
              kind: 'Operator',
              links: JSON.parse(additional_attributes['operator_markets'].to_json).map do |om|
                {
                  href: operator_url(om['operator_slug'], type: om['type_slug'], market: om['market_slug']),
                  title: om['title']
                }
              end
            }
          end
        end
      end
    end
  end
end
