# frozen_string_literal: true

module Services
  module Resources
    class AvailableFiltersBaseService < Services::Base
      include AvailableFiltersHelper

      attribute :current_user, Types::User
      attribute :other_operators, Types::Params::Bool.optional
      attribute :supported_operators, Types::Params::Bool.optional

      private

      def common_filters
        {
          page_types: page_types_filter,
          operators: operators,
          role_based_available_filters: role_based_available_filters,
          user: {
            roles: current_user.roles,
            permissions: current_user.permissions
          }
        }
      end

      def operator_role_available_markets
        return unless current_user.permissions == ['operator']

        operator_markets = OperatorMarket.includes(operator: %i[followings]).references(:operator).select('DISTINCT operator_id')
        market_ids = owning_operator_markets(operator_markets).collect(&:market_id).uniq
        Markets::Market.select('id, name').map { |market| { id: market.id, title: market.name } }.select { |m| market_ids.include?(m[:id]) }
      end

      def operators
        query = operator_query

        if current_user.is_superadmin?
          if other_operators
            query.map { |operator_market| { id: operator_market.operator_id, title: operator_market.name } }
          else
            query.where(supported: true).map { |operator_market| { id: operator_market.operator_id, title: operator_market.name } }
          end
        elsif current_user.teams.joins(:company_type).where(company_types: { permission_types: ['operator'] }).exists?
          operators = OperatorMarket.owned_by_user_or_team(current_user).pluck(:operator_id)

          query.where(supported: true).where(operator: operators).map { |operator_market| { id: operator_market.operator_id, title: operator_market.name } }
        else
          query.where(supported: true).map { |operator_market| { id: operator_market.operator_id, title: operator_market.name } }
        end
      end

      def operator_query
        subquery = OperatorMarket.select('MIN(created_at) as oldest_created_at, operator_id').group(:operator_id)
        OperatorMarket.
          joins(
            <<-SQL
              INNER JOIN (#{subquery.to_sql}) subquery ON
              operator_markets.operator_id = subquery.operator_id AND
              operator_markets.created_at = subquery.oldest_created_at
            SQL
          ).
          where(is_primary: true).
          order('lower(operator_markets.name) ASC')
      end

      def common_sort_options
        [
          { title: 'Operator Name (A-Z)', key: 'first_operator_market_name', value: 'asc' },
          { title: 'Operator Name (Z-A)', key: 'first_operator_market_name', value: 'desc' }
        ]
      end

      def fetch_serialized_ships
        ships = Ship.includes(:page, operator: :operator_markets).references(:pages).order('lower(pages.title) ASC')
        ships = ships.where(operator_id: operator_id) if operator_id.present?
        supported_ships = ships.where(operator_markets: { supported: true })
        filtered_ships = if current_user.superadmin?
          ships_filter_for_admin(ships, supported_ships)
        else
          current_user.travel_agent? ? supported_ships : supported_ships.where(owner_filter(current_user, 'operator_markets'))
        end

        filtered_ships.select('ships.id, pages.title').map { |ship| { id: ship.id, title: ship.title } }
      end

      def ships_filter_for_admin(ships, supported_ships)
        if supported_operators && other_operators
          ships
        elsif supported_operators
          supported_ships
        elsif other_operators
          ships.where.not(id: supported_ships.pluck(:id))
        else
          ships
        end
      end
    end
  end
end
