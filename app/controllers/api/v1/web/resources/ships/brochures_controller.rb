# frozen_string_literal: true

module Api
  module V1
    module Web
      module Resources
        module Ships
          class BrochuresController < ::Api::V1::Web::ApiController
            before_action :authorize_action

            def index
              additional_attributes, collection = ::Services::Resources::Ships::BrochuresFilterService.call(filter_params.merge!(current_user: current_user))
              render json: collection,
                     each_serializer: ::Serializers::Resources::Index::Ships::BrochuresSerializer,
                     adapter: :json_wrapper,
                     additional_attributes: additional_attributes,
                     ship_section: params[:ship_section],
                     meta: meta_attributes(additional_attributes, meta_user_attributes)
            end

            def available_filters
              result = ::Services::Resources::Ships::AvailableFilters::BrochuresService.call(available_filters_params.merge!(current_user: current_user))
              result.success? ? success(result.value) : error(result.value, result.status)
            end

            private

            def authorize_action
              authorize :Resource
            end

            def filter_params
              ::Validators::Resources::Ships::BrochuresFilterValidator.new(params).to_hash
            end

            def available_filters_params
              ::Validators::Resources::Ships::AvailableFiltersValidator.new(params).to_hash
            end
          end
        end
      end
    end
  end
end
