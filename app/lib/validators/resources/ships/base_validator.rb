# frozen_string_literal: true

module Validators
  module Resources
    module Ships
      class BaseValidator < Validators::Resources::BaseValidator
        include AvailableFiltersHelper

        fields :ship_id

        validate -> { inclusion_validator(:ship_id, Ship, false) }
      end
    end
  end
end
