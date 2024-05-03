# frozen_string_literal: true

module Serializers
  module Resources
    module Index
      module Faqs
        class AttachmentSerializer < ActiveModel::Serializer
          attributes %I[id file_name src]

          def id
            attachment.id
          end

          def file_name
            attachment.file_name
          end

          def src
            attachment.file.url
          end

          private

          def attachment
            object.attachment
          end
        end
      end
    end
  end
end
