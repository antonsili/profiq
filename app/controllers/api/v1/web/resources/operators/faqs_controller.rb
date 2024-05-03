# frozen_string_literal: true

module Api
  module V1
    module Web
      module Resources
        module Operators
          class FaqsController < ::Api::V1::Web::ApiController
            before_action :authorize_action

            def index
              collection = ::Services::Resources::Operators::FaqsFilterService.call(filter_params.merge!(current_user: current_user))
              render json: collection,
                     each_serializer: ::Serializers::Resources::Index::FaqsSerializer,
                     adapter: :json_wrapper,
                     meta: meta_attributes(collection, meta_user_attributes)
            end

            def available_filters
              result = ::Services::Resources::Operators::AvailableFilters::FaqsService.call(available_filters_params.merge!(current_user: current_user))
              result.success? ? success(result.value) : error(result.value, result.status)
            end

            private

            def authorize_action
              authorize :Resource
            end

            def filter_params
              ::Validators::Resources::Operators::FaqsFilterValidator.new(params).to_hash
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
