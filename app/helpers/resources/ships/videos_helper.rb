# frozen_string_literal: true

module Resources
  module Ships
    module VideosHelper
      def additional_attributes(ship_section)
        if ship_section == 'all_sections'
          "#{all_sections_ships_query},
          #{all_sections_first_operator_market_query('name')},
          #{all_sections_first_operator_market_query('id')},
          #{all_section_tags_query}
          "
        else
          "#{ships_query(ship_section)},
          #{first_operator_market_query('name', ship_section)},
          #{first_operator_market_query('id', ship_section)}
          "
        end
      end

      def all_sections_ships_query
        <<-SQL
          (
            SELECT JSON_AGG(subquery.value)
            FROM(
              SELECT DISTINCT JSONB_BUILD_OBJECT('title', pages.title, 'slug', pages.slug)
              FROM ships
              INNER JOIN model_video_links ON model_video_links.videoable_id = ships.id AND
                model_video_links.videoable_type = 'Ship' AND
                model_video_links.video_link_id = video_links.id
              INNER JOIN pages on ships.id = pages.pageable_id AND pages.pageable_type = 'Ship'
              UNION
              SELECT DISTINCT JSONB_BUILD_OBJECT('title', pages.title, 'slug', pages.slug)
              FROM ships
              INNER JOIN ship_video_links ON ship_video_links.ship_id = ships.id AND
                ship_video_links.video_link_id = video_links.id
              INNER JOIN pages on ships.id = pages.pageable_id AND pages.pageable_type = 'Ship'
            ) as subquery(value)
          ) as preview_ships
        SQL
      end

      def all_sections_first_operator_market_query(field)
        <<-SQL
          ( SELECT subquery.field
              FROM (
                SELECT operator_markets.#{field} as field, operator_markets.created_at as created_at
                FROM ships
                INNER JOIN model_video_links ON model_video_links.videoable_id = ships.id AND
                    model_video_links.videoable_type = 'Ship' AND
                    model_video_links.video_link_id = video_links.id
                INNER JOIN operators ON ships.operator_id = operators.id
                INNER JOIN operator_markets ON operator_markets.operator_id = operators.id
                UNION
                SELECT operator_markets.#{field}, operator_markets.created_at as created_at
                FROM ships
                INNER JOIN ship_video_links ON ship_video_links.ship_id = ships.id AND
                    ship_video_links.video_link_id = video_links.id
                INNER JOIN operators ON ships.operator_id = operators.id
                INNER JOIN operator_markets ON operator_markets.operator_id = operators.id
                ORDER BY created_at ASC
                LIMIT 1
              ) as subquery
          ) AS first_operator_market_#{field}
        SQL
      end

      def all_section_tags_query
        <<-SQL
          ARRAY_AGG(DISTINCT model_video_links.videoable_type) || ARRAY_AGG(DISTINCT ship_video_links.video_link_type) as tags
        SQL
      end

      def ships_query(ship_section)
        <<-SQL
          (
            SELECT JSON_AGG(DISTINCT JSONB_BUILD_OBJECT('title', pages.title, 'slug', pages.slug))
            FROM ships
            #{join_query(ship_section)}
            INNER JOIN pages on ships.id = pages.pageable_id AND pages.pageable_type = 'Ship'
          ) as preview_ships
        SQL
      end

      def first_operator_market_query(field, ship_section)
        <<-SQL
          (
            SELECT operator_markets.#{field}
            FROM ships
            #{join_query(ship_section)}
            INNER JOIN operators ON ships.operator_id = operators.id
            INNER JOIN operator_markets ON operator_markets.operator_id = operators.id
            ORDER BY operator_markets.created_at ASC
            LIMIT 1
          ) AS first_operator_market_#{field}
        SQL
      end

      def join_query(ship_section)
        if ship_section == 'general'
          <<-SQL
            INNER JOIN model_video_links ON model_video_links.videoable_id = ships.id AND
              model_video_links.videoable_type = 'Ship' AND
              model_video_links.video_link_id = video_links.id
          SQL
        else
          <<-SQL
            INNER JOIN ship_video_links ON ship_video_links.ship_id = ships.id AND
              ship_video_links.video_link_type = '#{ship_section}' AND
              ship_video_links.video_link_id = video_links.id
          SQL
        end
      end
    end
  end
end
