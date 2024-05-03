# frozen_string_literal: true

module Validators
  module Resources
    module Operators
      class BrochuresFilterValidator < Validators::Resources::Operators::BaseValidator
        fields :file_type_ids, :trade, :attachment_tag_ids, :operator_section

        validates :trade, inclusion: { in: %w[true false] }

        validate -> { array_validator(:file_type_ids, FileType) }
        validate -> { array_validator(:attachment_tag_ids, AttachmentTag) }

        validates :sort_by, inclusion: { in: %w[created_at expires_on first_operator_market_name file_name] }, allow_blank: true
        validates :operator_section, inclusion: { in: %w[general faq] }
      end
    end
  end
end
