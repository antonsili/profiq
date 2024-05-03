# frozen_string_literal: true

module Services
  module Resources
    module Operators
      class BaseService < Services::Resources::FilterBaseService
        attribute :market_id, Types::Nominal::Integer
        attribute :operator_type_id, Types::Coercible::Integer.optional
      end
    end
  end
end
