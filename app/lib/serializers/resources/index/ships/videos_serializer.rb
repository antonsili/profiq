# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      module Ships
        class VideosSerializer < VideosBaseSerializer
          include AvailableFiltersHelper

          def tags
            if @instance_options[:ship_section] == 'general'
              [{ id: 'ship', title: 'Ship' }]
            elsif @instance_options[:ship_section] == 'all_sections'
              object.tags.compact.map do |tag|
                (tag == 'Ship') ? { id: 'ship', title: 'Ship' } : SHIP_SECTION.detect { |ss| ss[:id] == tag }
              end
            else
              [SHIP_SECTION.detect { |ss| ss[:id] == @instance_options[:ship_section] }]
            end
          end

          def preview
            {
              kind: 'Ship',
              links: object.preview_ships.map do |ship|
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
