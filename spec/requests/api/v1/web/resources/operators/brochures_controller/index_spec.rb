# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Operators::BrochuresController, type: :request do
  subject(:get_resources) do
    get(api_web_resources_operators_brochures_path, params)
  end

  include_context :role_based_filters
  include_context :common_filters
  include_context :common_sorting

  describe 'GET /api/web/resources/operators/brochures' do
    let(:market)                       { Markets::Market.default_market }
    let(:following_operator)           { create(:operator) }
    let(:owning_operator)              { create(:operator) }
    let!(:unsupported_operator_market) { create(:operator_market, supported: false) }
    let!(:following_operator_market)   { create(:operator_market, operator: following_operator, supported: true) }
    let!(:owning_operator_market) do
      create(
        :operator_market,
        operator: owning_operator,
        supported: true,
        name: 'first operator market',
        owner_id: user.id,
        owner_type: 'User'
      )
    end

    let(:attachment_tag_1) { create(:attachment_tag) }
    let(:attachment_tag_2) { create(:attachment_tag) }
    let(:attachment_tag_3) { create(:attachment_tag) }

    let(:owning_resource) { create(:attachment, expires_on: Date.today, attachment_tags: [attachment_tag_1, attachment_tag_2]) }

    let!(:unsupported_model_attachment) { create(:model_attachment, attachable: unsupported_operator_market, attachment: create(:attachment)) }
    let!(:following_model_attachment)   { create(:model_attachment, attachable: following_operator_market, attachment: create(:attachment)) }
    let!(:owning_model_attachment) { create(:model_attachment, attachable: owning_operator_market, attachment: owning_resource) }

    let(:default_params) { { market_id: Markets::Market.default_market.id, trade: false, operator_section: 'general' } }

    let(:operator_company_type)   { create(:company_type, permission_types: %w[operator]) }
    let(:team)                    { create(:teams_team, company_type: operator_company_type, markets: [market]) }
    let(:user)                    { create(:user, teams: [team]) }

    include_examples :user_with_admin_role, 'attachments'
    include_examples :user_with_operator_role, 'attachments'
    include_examples :user_with_agent_role, 'attachments'
    include_examples :user_with_operator_agent_role, 'attachments'

    context 'when common filters are applied' do
      include_examples :with_provided_market_id, 'attachments'
      include_examples :with_provided_operator_type_id, 'attachments'
      include_examples :with_provided_operator_id, 'attachments'

      context 'with search by name' do
        let(:searchable_file_name)  { 'another.pdf' }
        let(:params) { default_params.merge!(query: 'another') }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_operator_market, attachment: create(:attachment, file_name: searchable_file_name))
          get_resources
        end

        it 'returns attachments filtered by name' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['file_name'] }).to include(searchable_file_name)
        end
      end

      context 'when file_type_ids are provided' do
        let(:factsheet_type) { create(:file_type, name: 'Factsheet') }
        let(:params) { default_params.merge!(file_type_ids: [factsheet_type.id]) }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_operator_market, attachment: create(:attachment, file_type: factsheet_type))
          get_resources
        end

        it 'returns attachments filtered by file_type_ids' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['file_type']['title'] }).to include(factsheet_type.name)
        end
      end

      context 'when attachment_tag_ids are provided' do
        let(:attachment_tag) { create(:attachment_tag) }
        let(:params) { default_params.merge!(attachment_tag_ids: [attachment_tag.id]) }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_operator_market, attachment: create(:attachment, attachment_tags: [attachment_tag]))
          get_resources
        end

        it 'returns attachments filtered by attachment_tag_ids' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['tags'][0]['id'] }).to include(attachment_tag.id)
        end
      end

      context 'when trade is true' do
        let(:trade_attachment) { create(:attachment, trade: true) }
        let(:params)           { default_params.merge!(trade: true) }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_operator_market, attachment: trade_attachment)
          get_resources
        end

        it 'returns attachments filtered by trade value' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to include(trade_attachment.id)
        end
      end

      context 'when trade is false' do
        let(:trade_attachment) { create(:attachment, trade: true) }
        let(:params)           { default_params }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_operator_market, attachment: trade_attachment)
          get_resources
        end

        it 'returns attachments filtered by trade value' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).not_to include(trade_attachment.id)
        end
      end

      context 'when operator section is faq' do
        let(:faq_attachment) { create(:attachment) }
        let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
        let(:params)         { default_params.merge!(operator_section: 'faq') }

        before do
          sign_in(user)
          create(:model_attachment, attachable: faq, attachment: faq_attachment)
          get_resources
        end

        it 'returns attachments filtered by operator_section' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to include(faq_attachment.id)
        end
      end

      context 'when operator section is general' do
        let(:faq_attachment) { create(:attachment) }
        let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
        let(:params)         { default_params }

        before do
          sign_in(user)
          create(:model_attachment, attachable: faq, attachment: faq_attachment)
          get_resources
        end

        it 'returns attachments filtered by operator_section' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).not_to include(faq_attachment.id)
        end
      end
    end

    context 'when sorting is applied' do
      let(:another_owning_operator) { create(:operator) }
      let(:another_resource)        { create(:attachment, file_name: 'another.pdf', created_at: 5.years.ago, expires_on: 5.years.from_now) }
      let(:another_owning_operator_market) do
        create(:operator_market, supported: true, operator: another_owning_operator, name: 'second_operator_market', owner_id: user.id, owner_type: 'User')
      end

      before do
        sign_in(user)
        create(:model_attachment, attachable: another_owning_operator_market, attachment: another_resource)
        get_resources
      end

      include_examples :sorting_by_created_at, 'attachments'
      include_examples :sorting_by_first_operator_market_name, 'attachments'

      context 'sorting by expires_on asc' do
        let(:params) { default_params.merge!(sort_by: 'expires_on', order_by: 'asc') }

        it 'returns attachments sorted by attachment expires_on ascending' do
          expect(parsed_json['response']['attachments'].count).to eq(2)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to eq([owning_resource.id, another_resource.id])
        end
      end

      context 'sorting by expires_on desc' do
        let(:params) { default_params.merge!(sort_by: 'expires_on', order_by: 'desc') }

        it 'returns attachments sorted by attachment expires_on descending' do
          expect(parsed_json['response']['attachments'].count).to eq(2)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to eq([another_resource.id, owning_resource.id])
        end
      end

      context 'sorting by file_name asc' do
        let(:params) { default_params.merge!(sort_by: 'file_name', order_by: 'asc') }

        it 'returns attachments sorted by attachment file_name ascending' do
          expect(parsed_json['response']['attachments'].count).to eq(2)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to eq([another_resource.id, owning_resource.id])
        end
      end

      context 'sorting by file_name desc' do
        let(:params) { default_params.merge!(sort_by: 'file_name', order_by: 'desc') }

        it 'returns attachments sorted by attachment file_name descending' do
          expect(parsed_json['response']['attachments'].count).to eq(2)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['id'] }).to eq([owning_resource.id, another_resource.id])
        end
      end
    end

    context 'when attachments are on several model attachments' do
      let(:another_owning_operator) { create(:operator) }
      let!(:another_owning_operator_market) do
        create(
          :operator_market,
          operator: another_owning_operator,
          supported: true,
          name: 'second_operator_market',
          created_at: 5.years.ago,
          owner_id: user.id,
          owner_type: 'User'
        )
      end

      let(:faq_attachment) { create(:attachment, trade: true, attachment_tags: [attachment_tag_1, attachment_tag_2, attachment_tag_3]) }
      let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
      let(:another_faq)    { create(:faq, source_of_faqs: another_owning_operator_market) }

      context 'operator markets' do
        let(:params) { default_params.merge!(trade: true) }

        before do
          sign_in(user)
          create(:model_attachment,
            attachable: another_owning_operator_market, attachment: create(:attachment, trade: true, attachment_tags: [attachment_tag_2, attachment_tag_3])
          )
          get_resources
        end

        it 'returns correct additional attributes' do
          expect(parsed_json['response']['attachments'][0]['trade_tag']).to eq(true)
          expect(parsed_json['response']['attachments'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
          expect(parsed_json['response']['attachments'][0]['tags'].map { |tag| tag['id'] }).to(
            eq([attachment_tag_2.id, attachment_tag_3.id])
          )
        end
      end

      context 'faqs' do
        let(:params) { default_params.merge!(operator_section: 'faq', trade: true) }

        before do
          sign_in(user)
          create(:model_attachment, attachable: faq, attachment: faq_attachment)
          create(:model_attachment, attachable: another_faq, attachment: faq_attachment)
          get_resources
        end

        it 'returns correct additional attributes' do
          expect(parsed_json['response']['attachments'][0]['trade_tag']).to eq(true)
          expect(parsed_json['response']['attachments'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
          expect(parsed_json['response']['attachments'][0]['tags'].map { |tag| tag['id'] }).to(
            eq([attachment_tag_1.id, attachment_tag_2.id, attachment_tag_3.id])
          )
        end
      end
    end
  end
end
