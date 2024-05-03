# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Operators::FaqsController, type: :request do
  subject(:get_resources) do
    get(api_web_resources_operators_faqs_path, params)
  end

  include_context :role_based_filters
  include_context :common_filters
  include_context :common_sorting

  describe 'GET /api/web/resources/operators/faqs' do
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

    let!(:owning_resource) { create(:faq, name: 'yName', source_of_faqs: owning_operator_market) }
    let!(:unsupported_faq) { create(:faq, source_of_faqs: unsupported_operator_market) }
    let!(:following_faq)   { create(:faq, source_of_faqs: following_operator_market) }

    let(:default_params) { { market_id: Markets::Market.default_market.id } }

    let(:operator_company_type)   { create(:company_type, permission_types: %w[operator]) }
    let(:team)                    { create(:teams_team, company_type: operator_company_type, markets: [market]) }
    let(:user)                    { create(:user, teams: [team]) }

    include_examples :user_with_admin_role, 'faqs'
    include_examples :user_with_operator_role, 'faqs'
    include_examples :user_with_agent_role, 'faqs'
    include_examples :user_with_operator_agent_role, 'faqs'

    context 'when common filters are applied' do
      include_examples :with_provided_market_id, 'faqs'
      include_examples :with_provided_operator_id, 'faqs'

      context 'when operator_type_id is provided' do
        let(:tour_operator_type) { OperatorType.find_by(slug: 'tour-operator') }
        let!(:tour_operator_market) do
          create(
            :operator_market,
            operator: owning_operator,
            operator_type: tour_operator_type,
            supported: true,
            name: 'tour_operator_market',
            owner_id: user.id,
            owner_type: 'User'
          )
        end

        let(:params) { default_params.merge!(operator_type_id: tour_operator_type.id) }

        before do
          sign_in(user)
          create(:faq, source_of_faqs: tour_operator_market)
          get_resources
        end

        it 'returns faqs filtered by operator_type_id' do
          expect(parsed_json['response']['faqs'].count).to eq(1)
          expect(parsed_json['response']['faqs'].map { |resource| resource['first_operator']['title'] }).to(
            include("#{tour_operator_market.name} (#{tour_operator_type.name})")
          )
        end
      end

      context 'when faq_type_id is provided' do
        let(:faq_type) { create(:faq_type) }
        let(:params)   { default_params.merge!(faq_type_id: faq_type.id) }

        let!(:faq_with_type) { create(:faq, source_of_faqs: owning_operator_market, faq_types: [faq_type]) }

        before do
          sign_in(user)
          get_resources
        end

        it 'returns faqs filtered by faq_type_id' do
          expect(parsed_json['response']['faqs'].count).to eq(1)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([faq_with_type.id])
        end
      end

      context 'with search by name' do
        let(:searchable_faq_name) { 'queryString' }
        let(:params) { default_params.merge!(query: 'queryString') }

        let!(:faq_with_searchable_name)        { create(:faq, source_of_faqs: owning_operator_market, name: "abc #{searchable_faq_name} cba") }
        let!(:faq_with_searchable_description) { create(:faq, source_of_faqs: owning_operator_market, description: "abc #{searchable_faq_name} cba") }

        before do
          sign_in(user)
          get_resources
        end

        it 'returns faqs filtered by name and description' do
          expect(parsed_json['response']['faqs'].count).to eq(2)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([faq_with_searchable_name.id, faq_with_searchable_description.id])
        end
      end
    end

    context 'when sorting is applied' do
      let(:another_owning_operator) { create(:operator) }
      let(:another_owning_operator_market) do
        create(:operator_market, supported: true, operator: another_owning_operator, name: 'second_operator_market', owner_id: user.id, owner_type: 'User')
      end
      let!(:another_resource) { create(:faq, name: 'aName', source_of_faqs: another_owning_operator_market, updated_at: 5.years.ago) }

      before do
        sign_in(user)
        get_resources
      end

      include_examples :sorting_by_first_operator_market_name, 'faqs'

      context 'sorting by name asc' do
        let(:params) { default_params.merge!(sort_by: 'name', order_by: 'asc') }

        it 'returns faqs sorted by faq name ascending' do
          expect(parsed_json['response']['faqs'].count).to eq(2)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([another_resource.id, owning_resource.id])
        end
      end

      context 'sorting by name desc' do
        let(:params) { default_params.merge!(sort_by: 'name', order_by: 'desc') }

        it 'returns faqs sorted by faq name descending' do
          expect(parsed_json['response']['faqs'].count).to eq(2)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([owning_resource.id, another_resource.id])
        end
      end

      context 'sorting by updated_at asc' do
        let(:params) { default_params.merge!(sort_by: 'updated_at', order_by: 'asc') }

        it 'returns faqs sorted by faq updated_at ascending' do
          expect(parsed_json['response']['faqs'].count).to eq(2)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([another_resource.id, owning_resource.id])
        end
      end

      context 'sorting by updated_at desc' do
        let(:params) { default_params.merge!(sort_by: 'updated_at', order_by: 'desc') }

        it 'returns faqs sorted by faq updated_at descending' do
          expect(parsed_json['response']['faqs'].count).to eq(2)
          expect(parsed_json['response']['faqs'].map { |faq| faq['id'] }).to eq([owning_resource.id, another_resource.id])
        end
      end
    end
  end
end
