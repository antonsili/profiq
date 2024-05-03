# frozen_string_literal: true

module Api
  module V1
    module Web
      module Resources
        module Ships
          class VideosController < ::Api::V1::Web::ApiController
            before_action :authorize_action

            def index
              collection, first_operator_markets = ::Services::Resources::Ships::VideosFilterService.call(filter_params.merge!(current_user: current_user))
              render json: collection,
                     each_serializer: ::Serializers::Resources::Index::Ships::VideosSerializer,
                     adapter: :json_wrapper,
                     first_operator_markets: first_operator_markets,
                     ship_section: params[:ship_section],
                     meta: meta_attributes(collection, meta_user_attributes)
            end

            def available_filters
              result = ::Services::Resources::Ships::AvailableFilters::VideosService.call(available_filters_params.merge!(current_user: current_user))
              result.success? ? success(result.value) : error(result.value, result.status)
            end

            private

            def authorize_action
              authorize :Resource
            end

            def filter_params
              ::Validators::Resources::Ships::VideosFilterValidator.new(params).to_hash
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
