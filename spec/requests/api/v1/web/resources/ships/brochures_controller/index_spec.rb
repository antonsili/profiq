# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Ships::BrochuresController, type: :request do
  subject(:get_resources) do
    get(api_web_resources_ships_brochures_path, params)
  end

  include_context :role_based_filters
  include_context :common_filters
  include_context :common_sorting

  describe 'GET /api/web/resources/ships/brochures' do
    let(:market)            { Markets::Market.default_market }
    let(:river_cruise_line) { OperatorType.find_by(slug: 'river-cruise-line') }

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

    let(:unsupported_ship) { create(:ship, operator: unsupported_operator_market.operator) }
    let!(:following_ship) { create(:ship, operator: following_operator) }
    let!(:owning_ship) { create(:ship, operator: owning_operator) }

    let(:owning_resource) { create(:attachment, expires_on: Date.today) }

    let!(:unsupported_model_attachment) { create(:model_attachment, attachable: unsupported_ship, attachment: create(:attachment)) }
    let!(:following_model_attachment) { create(:model_attachment, attachable: following_ship, attachment: create(:attachment)) }
    let!(:owning_model_attachment) do
      create(:model_attachment, attachable: owning_ship, attachment: owning_resource)
    end

    let(:default_params) { { ship_section: 'general' } }

    let(:operator_company_type)   { create(:company_type, permission_types: %w[operator]) }
    let(:team)                    { create(:teams_team, company_type: operator_company_type, markets: [market]) }
    let(:user)                    { create(:user, teams: [team]) }

    include_examples :user_with_admin_role, 'attachments'
    include_examples :user_with_operator_role, 'attachments'
    include_examples :user_with_agent_role, 'attachments'
    include_examples :user_with_operator_agent_role, 'attachments'

    context 'when common filters are applied' do
      include_examples :with_provided_ship_id, 'attachments'
      include_examples :with_provided_operator_id, 'attachments'

      context 'with search by name' do
        let(:searchable_file_name)  { 'another.pdf' }
        let(:params) { default_params.merge!(query: 'another') }

        before do
          sign_in(user)
          create(:model_attachment, attachable: owning_ship, attachment: create(:attachment, file_name: searchable_file_name))
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
          create(:model_attachment, attachable: owning_ship, attachment: create(:attachment, file_type: factsheet_type))
          get_resources
        end

        it 'returns attachments filtered by file_type_ids' do
          expect(parsed_json['response']['attachments'].count).to eq(1)
          expect(parsed_json['response']['attachments'].map { |attachment| attachment['file_type']['title'] }).to include(factsheet_type.name)
        end
      end
    end

    context 'when sorting is applied' do
      let(:another_owning_operator) { create(:operator, slug: 'another_owning') }
      let(:another_resource) { create(:attachment, file_name: 'another.pdf', created_at: 5.years.ago, expires_on: 5.years.from_now) }
      let!(:another_owning_operator_market) do
        create(:operator_market, supported: true, operator: another_owning_operator, name: 'second_operator_market', owner_id: user.id, owner_type: 'User')
      end
      let(:another_owning_ship) { create(:ship, operator: another_owning_operator) }

      before do
        sign_in(user)
        create(:model_attachment, attachable: another_owning_ship, attachment: another_resource)
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

    context 'when attachments are on several ships' do
      let(:another_ship) { create(:ship, operator: owning_operator) }
      let(:params) { default_params }

      before do
        sign_in(user)
        create(:model_attachment, attachable: another_ship, attachment: owning_resource)
        get_resources
      end

      it 'returns correct preview links for all ships' do
        expect(parsed_json['response']['attachments'][0]['preview']['links'].map { |s| s['title'] }).to eq([owning_ship.title, another_ship.title])
      end
    end

    context 'when operator has several operator markets' do
      let!(:another_owning_operator_market) do
        create(:operator_market, operator_type: river_cruise_line, operator: owning_operator, name: 'second_operator_market', created_at: 5.years.ago)
      end
      let(:params) { default_params }

      before do
        sign_in(user)
        get_resources
      end

      it 'returns oldest operator market name' do
        expect(parsed_json['response']['attachments'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
      end
    end

    context 'when ship_section is all_sections' do
      let(:user) { create(:superadmin) }
      let(:params) { default_params.merge!(ship_section: 'all_sections', i_follow: true, other_operators: true, supported_operators: true) }

      let(:dining_option_ship) { create(:ship, operator: create(:operator, :with_primary_operator_market)) }
      let(:dining_option) { create(:dining_option, ship: dining_option_ship) }
      let(:another_ship) { create(:ship, operator: following_operator) }

      let!(:dining_option_model_attachment) { create(:model_attachment, attachable: dining_option, attachment: create(:attachment)) }
      let!(:owning_resource_on_another_ship) { create(:model_attachment, attachable: another_ship, attachment: owning_resource) }

      before do
        sign_in(user)
        get_resources
      end

      it 'returns all both ship and dining options attachments' do
        expect(parsed_json['response']['attachments'].count).to eq 4
        expect(
          parsed_json['response']['attachments'].detect do |attachment|
            attachment['id'] == dining_option_model_attachment.attachment_id
          end['preview']['links'][0]['title']
        ).to eq dining_option_ship.title
        expect(
          parsed_json['response']['attachments'].detect { |attachment| attachment['id'] == owning_resource.id }['preview']['links'].map { |s| s['title'] }
        ).to eq [owning_ship.title, another_ship.title]
      end
    end
  end
end
