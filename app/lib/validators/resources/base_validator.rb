# frozen_string_literal: true

module Validators
  module Resources
    class BaseValidator < ::Validators::Base
      include Validators::ArrayValidator
      include Validators::InclusionValidator

      fields :query, :page, :per, :our_operators, :other_operators, :supported_operators,
        :i_follow, :sort_by, :order_by, :operator_id

      validates :page, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_blank: true
      validates :per, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 },
                      allow_blank: true

      validates :our_operators, inclusion: { in: %w[true false] }, allow_blank: true
      validates :other_operators, inclusion: { in: %w[true false] }, allow_blank: true
      validates :supported_operators, inclusion: { in: %w[true false] }, allow_blank: true
      validates :i_follow, inclusion: { in: %w[true false] }, allow_blank: true

      validates :order_by, inclusion: { in: %w[asc desc] }, allow_blank: true

      validate -> { inclusion_validator(:operator_id, Operator, false) }
    end
  end
end
