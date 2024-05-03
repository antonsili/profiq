# frozen_string_literal: true

module Validators
  module Resources
    module Operators
      class FaqsFilterValidator < Validators::Resources::Operators::BaseValidator
        fields :faq_type_id

        validates :sort_by, inclusion: { in: %w[updated_at first_operator_market_name name] }, allow_blank: true

        validate -> { inclusion_validator(:faq_type_id, FaqType, false) }
      end
    end
  end
end
