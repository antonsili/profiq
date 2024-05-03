# frozen_string_literal: true

module Api
  module V1
    module Web
      module Resources
        module Operators
          class BrochuresController < ::Api::V1::Web::ApiController
            before_action :authorize_action

            def index
              additional_attributes, collection = ::Services::Resources::Operators::BrochuresFilterService.
                call(filter_params.merge!(current_user: current_user))
              render json: collection,
                     each_serializer: ::Serializers::Resources::Index::Operators::BrochuresSerializer,
                     adapter: :json_wrapper,
                     additional_attributes: additional_attributes,
                     meta: meta_attributes(additional_attributes, meta_user_attributes)
            end

            def available_filters
              result = ::Services::Resources::Operators::AvailableFilters::BrochuresService.call(available_filters_params.merge!(current_user: current_user))
              result.success? ? success(result.value) : error(result.value, result.status)
            end

            private

            def authorize_action
              authorize :Resource
            end

            def filter_params
              ::Validators::Resources::Operators::BrochuresFilterValidator.new(params).to_hash
            end

            def available_filters_params
              ::Validators::Resources::Operators::AvailableFiltersValidator.new(params).to_hash
            end
          end
        end
      end
    end
  end
end
