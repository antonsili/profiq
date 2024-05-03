# frozen_string_literal: true

module Validators
  module Resources
    module Ships
      class VideosFilterValidator < Validators::Resources::Ships::BaseValidator
        fields :ship_section

        validates :sort_by, inclusion: { in: %w[created_at first_operator_market_name title] }, allow_blank: true
        validates :ship_section, inclusion: { in: SHIP_SECTION.map { |ss| ss[:id] } }
      end
    end
  end
end
