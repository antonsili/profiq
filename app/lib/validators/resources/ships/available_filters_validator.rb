# frozen_string_literal: true

module Validators
  module Resources
    module Ships
      class AvailableFiltersValidator < ::Validators::Base
        include Validators::InclusionValidator

        fields :operator_id, :other_operators, :supported_operators

        validate -> { inclusion_validator(:operator_id, Operator, false) }
      end
    end
  end
end
