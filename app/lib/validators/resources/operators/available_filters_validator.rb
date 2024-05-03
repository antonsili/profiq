# frozen_string_literal: true

module Validators
  module Resources
    module Operators
      class AvailableFiltersValidator < ::Validators::Base
        fields :other_operators, :supported_operators
      end
    end
  end
end
