# frozen_string_literal: true

module Services
  module Resources
    module Ships
      class BrochuresFilterService < BaseService
        include ::Resources::Ships::BrochuresHelper

        attribute :file_type_ids, Types::Params::Array.optional

        def perform
          attachments = load_associations
          attachments = apply_filters(attachments)
          attachments = attachments.
            select("attachments.id, attachments.created_at, #{additional_attributes(ship_section)}").group('attachments.id')
          attachments = attachments.order("#{sort_by} #{order_by}") if sort_before_additional_loading?
          return [Attachment.none.page(page || 1).per(per || RESOURCES_PER_PAGE), Attachment.none] if attachments.blank?

          prepare_results(attachments)
        end

        private

        def prepare_results(attachments)
          attachments = prepare_additional_attributes(attachments) if ship_section == 'all_sections'
          unless sort_before_additional_loading?
            attachments = attachments.sort_by { |attachment| attachment['first_operator_market_name'] }
            attachments.reverse! if order_by == 'desc'
          end
          paginate_result = Kaminari.paginate_array(attachments).page(page || 1).per(per || RESOURCES_PER_PAGE)
          attachment_ids = paginate_result.map { |r| r['id'] }
          [
            paginate_result,
            Attachment.includes(:file_type).where(id: attachment_ids).order("position(id::text in '#{attachment_ids.join(',')}')")
          ]
        end

        def load_associations
          attachments = Attachment.
            joins('INNER JOIN model_attachments ON model_attachments.attachment_id = attachments.id')
          if ship_section == 'general'
            attachments = attachments.joins("LEFT JOIN ships ON model_attachments.attachable_id = ships.id AND model_attachments.attachable_type = 'Ship'")
          elsif ship_section == 'all_sections'
            attachments = load_all_sections(attachments)
          else
            table_name = SHIP_SECTION_MAPPER[ship_section.to_sym][:table_name]
            model_name = SHIP_SECTION_MAPPER[ship_section.to_sym][:model_name]
            attachments = attachments.joins(
              <<-SQL
                LEFT JOIN #{table_name} ON model_attachments.attachable_id = #{table_name}.id AND model_attachments.attachable_type = '#{model_name}'
                LEFT JOIN ships ON #{table_name}.ship_id = ships.id
              SQL
            )
          end
          attachments.
            joins('INNER JOIN operators on operators.id = ships.operator_id').
            joins('INNER JOIN operator_markets ON operator_markets.operator_id = operators.id').
            joins("LEFT JOIN followings on followings.followable_id = operators.id AND followings.followable_type = 'Operator'")
        end

        def apply_filters(attachments)
          attachments = attachments.search_by_name(query) if query
          attachments = role_based_filters(attachments, Attachment)
          common_filters(attachments)
        end

        def common_filters(attachments)
          query = []
          query.push("attachments.file_type_id IN (#{file_type_ids.join(',')})") if file_type_ids.present?
          query.push("ships.operator_id = #{operator_id}") if operator_id.present?
          query.push("ships.id = #{ship_id}") if ship_id.present?
          attachments.where(query.join(' AND '))
        end

        def load_all_sections(attachments)
          section_type_ship_joins = ''
          SHIP_SECTION_MAPPER.each do |_key, value|
            attachments = attachments.
              joins("LEFT JOIN #{value[:table_name]} ON model_attachments.attachable_id = #{value[:table_name]}.id AND
                                                        model_attachments.attachable_type = '#{value[:model_name]}'"
                   )
            section_type_ship_joins += " OR #{value[:table_name]}.ship_id = ships.id"
          end
          attachments = attachments.
            joins("LEFT JOIN ships ON (model_attachments.attachable_id = ships.id AND model_attachments.attachable_type = 'Ship') #{section_type_ship_joins}")
        end

        def prepare_additional_attributes(attachments)
          attachments.map do |attachment|
            attachment = attachment.as_json
            ship_ids = []
            attachment['preview_ships'] = ModelAttachment.where(id: attachment['model_attachments_ids']).map do |model_attachment|
              page = (model_attachment.attachable_type == 'Ship') ? model_attachment.attachable.page : model_attachment.attachable.ship.page
              ship_ids.push(page.pageable_id) unless ship_ids.include?(page.pageable_id)
              { 'title': page.title, 'slug': page.slug }.stringify_keys
            end.uniq
            attachment['first_operator_market_name'] = ActiveRecord::Base.connection.execute(
              <<-SQL
                SELECT operator_markets.name
                FROM ships
                INNER JOIN operators ON ships.operator_id = operators.id
                INNER JOIN operator_markets ON operator_markets.operator_id = operators.id
                WHERE ships.id IN (#{ship_ids.join(',')})
                ORDER BY operator_markets.created_at ASC
                LIMIT 1
              SQL
            ).to_a[0]['name']
            attachment
          end
        end

        def sort_before_additional_loading?
          sort_by.present? && order_by.present? && !(sort_by == 'first_operator_market_name' && ship_section == 'all_sections')
        end
      end
    end
  end
end
