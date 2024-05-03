# frozen_string_literal: true

module Api
  module V1
    module Web
      class ApiController < ActionController::Base
        include ExceptionsHandler
        include Pundit::Authorization

        before_action :authenticate_user!
        around_action :handle_exceptions

        def meta_attributes(collection, extra_meta = {})
          {
            current_page: collection.current_page.to_i,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
          }.merge(extra_meta)
        end

        def meta_user_attributes
          {
            current_user: {
              id: current_user.id,
              roles: current_user.roles.pluck(:name),
              team_permissions: current_user.permissions
            }
          }
        end

        def success(response = {}, status = 200)
          render json: { response: response, status: status.to_i }, status: status
        end

        def error(message = '', status = 400, details = {})
          render json: { error: { message: message, details: details }, status: status.to_i }, status: status
        end

        private

        def policy_scope(scope)
          super([:api, :v1, :web, scope])
        end

        def authorize(record, query = nil)
          super([:api, :v1, :web, record], query)
        end
      end
    end
  end
end
