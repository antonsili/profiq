# frozen_string_literal: true

module Validators
  module Resources
    module Ships
      class BrochuresFilterValidator < Validators::Resources::Ships::BaseValidator
        fields :file_type_ids, :ship_section

        validate -> { array_validator(:file_type_ids, FileType) }
        validates :ship_section, inclusion: { in: (SHIP_SECTION - [{ title: 'Accommodation', id: 'accomodation' }]).map { |ss| ss[:id] } }

        validates :sort_by, inclusion: { in: %w[created_at expires_on first_operator_market_name file_name] }, allow_blank: true
      end
    end
  end
end
