# frozen_string_literal: true

module Validators
  module Resources
    module Operators
      class VideosFilterValidator < Validators::Resources::Operators::BaseValidator
        fields :operator_section

        validates :sort_by, inclusion: { in: %w[created_at first_operator_market_name title] }, allow_blank: true
        validates :operator_section, inclusion: { in: %w[general faq] }
      end
    end
  end
end
