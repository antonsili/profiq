# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      module Ships
        class BrochuresSerializer < BrochuresBaseSerializer
          include AvailableFiltersHelper

          def trade_tag
            false
          end

          def tags
            []
          end

          def preview
            {
              kind: 'Ship',
              links: additional_attributes['preview_ships'].map do |ship|
                {
                  href: ship_url(ship['slug']),
                  title: ship['title']
                }
              end
            }
          end
        end
      end
    end
  end
end
