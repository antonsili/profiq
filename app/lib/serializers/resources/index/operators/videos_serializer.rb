# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      module Operators
        class VideosSerializer < VideosBaseSerializer
          def tags
            []
          end

          def preview
            {
              kind: 'Operator',
              links: object.oms.map do |om|
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
