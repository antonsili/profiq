# frozen_string_literal: true

module Services
  module Resources
    class FilterBaseService < Services::Base
      include FiltersHelper

      attribute :page, Types::Nominal::Integer
      attribute :per, Types::Coercible::Integer.optional
      attribute :current_user, Types::User

      attribute :our_operators, Types::Params::Bool.optional
      attribute :other_operators, Types::Params::Bool.optional
      attribute :supported_operators, Types::Params::Bool.optional
      attribute :i_follow, Types::Params::Bool.optional

      attribute :sort_by, Types::String.optional
      attribute :order_by, Types::String.optional
      attribute :query, Types::String.optional

      attribute :operator_id, Types::Coercible::Integer.optional

      RESOURCES_PER_PAGE = 21

      private

      def role_based_filters(resources, entity)
        query = if current_user.is_superadmin?
          admin_role_filter_query(supported_operators, other_operators, i_follow)
        else
          resources = resources.where(supported_markets_filter)
          operator_markets = OperatorMarket.includes(operator: :followings)
          non_admin_role_query(operator_markets)
        end

        return resources.where(query.compact.join(' OR ')) if current_user.permissions == ['operator'] && !current_user.is_superadmin?

        return entity.none if query.empty?

        resources.where(query.compact.join(' OR '))
      end
    end
  end
end
