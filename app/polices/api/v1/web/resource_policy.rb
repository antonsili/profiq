# frozen_string_literal: true

module Api
  module V1
    module Web
      class ResourcePolicy < ::Api::V1::Web::ApplicationPolicy
        def index?
          superadmin? || travel_agent_or_operator?
        end

        def available_filters?
          index?
        end
      end
    end
  end
end
