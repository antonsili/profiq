# frozen_string_literal: true

module Resources
  module Ships
    module BrochuresHelper
      SHIP_SECTION_MAPPER = {
        dining: { table_name: 'dining_options', model_name: 'DiningOption' },
        entertainment: { table_name: 'entertainment_types', model_name: 'EntertainmentType' },
        health_fitness: { table_name: 'health_fitness_types', model_name: 'HealthFitnessType' },
        kids_teens: { table_name: 'kid_teen_types', model_name: 'KidTeenType' },
        enrichment: { table_name: 'enrichment_types', model_name: 'EnrichmentType' },
        useful: { table_name: 'useful_types', model_name: 'UsefulType' }
      }.freeze

      def additional_attributes(ship_section)
        if ship_section == 'all_sections'
          'array_agg(DISTINCT model_attachments.id) as model_attachments_ids'
        else
          "#{first_operator_market_name(ship_section)}, #{ships_query(ship_section)}"
        end
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

      def first_operator_market_name(ship_section)
        <<-SQL
          (
            SELECT operator_markets.name
            FROM ships
            #{join_query(ship_section)}
            INNER JOIN operators ON ships.operator_id = operators.id
            INNER JOIN operator_markets ON operator_markets.operator_id = operators.id
            ORDER BY operator_markets.created_at ASC
            LIMIT 1
          ) AS first_operator_market_name
        SQL
      end

      def join_query(ship_section)
        if ship_section == 'general'
          <<-SQL
            INNER JOIN model_attachments ON model_attachments.attachable_id = ships.id AND
              model_attachments.attachable_type = 'Ship' AND
              model_attachments.attachment_id = attachments.id
          SQL
        else
          table_name = SHIP_SECTION_MAPPER[ship_section.to_sym][:table_name]
          model_name = SHIP_SECTION_MAPPER[ship_section.to_sym][:model_name]
          <<-SQL
            INNER JOIN #{table_name} ON #{table_name}.ship_id = ships.id
            INNER JOIN model_attachments ON model_attachments.attachable_id = #{table_name}.id AND
            model_attachments.attachable_type = '#{model_name}' AND
            model_attachments.attachment_id = attachments.id
          SQL
        end
      end
    end
  end
end
