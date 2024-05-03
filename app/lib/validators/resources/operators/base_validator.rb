# frozen_string_literal: true

module Validators
  module Resources
    module Operators
      class BaseValidator < Validators::Resources::BaseValidator
        fields :market_id, :operator_type_id, :operator_id

        validate -> { inclusion_validator(:market_id, ::Markets::Market, true) }
        validate -> { inclusion_validator(:operator_type_id, OperatorType, false) }
        validate -> { inclusion_validator(:operator_id, Operator, false) }
      end
    end
  end
end
