# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Operators::VideosController, type: :request do
  subject(:get_resources) do
    get(api_web_resources_operators_videos_path, params)
  end

  include_context :role_based_filters
  include_context :common_filters
  include_context :common_sorting

  describe 'GET /api/web/resources/operators/videos' do
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

    let(:owning_resource) { create(:video_link, title: 'owning') }

    let!(:unsupported_model_video_link) { create(:model_video_link, videoable: unsupported_operator_market, video_link: create(:video_link)) }
    let!(:following_model_video_link)   { create(:model_video_link, videoable: following_operator_market, video_link: create(:video_link)) }
    let!(:owning_model_video_link) do
      create(:model_video_link, videoable: owning_operator_market, video_link: owning_resource)
    end

    let(:default_params) { { market_id: Markets::Market.default_market.id, operator_section: 'general' } }

    let(:operator_company_type)   { create(:company_type, permission_types: %w[operator]) }
    let(:team)                    { create(:teams_team, company_type: operator_company_type, markets: [market]) }
    let(:user)                    { create(:user, teams: [team]) }

    include_examples :user_with_admin_role, 'video_links'
    include_examples :user_with_operator_role, 'video_links'
    include_examples :user_with_agent_role, 'video_links'
    include_examples :user_with_operator_agent_role, 'video_links'

    context 'when common filters are applied' do
      include_examples :with_provided_market_id, 'video_links'
      include_examples :with_provided_operator_type_id, 'video_links'
      include_examples :with_provided_operator_id, 'video_links'

      context 'with search by name' do
        let(:searchable_title) { 'another' }
        let(:params) { default_params.merge!(query: 'another') }

        before do
          sign_in(user)
          create(:model_video_link, videoable: owning_operator_market, video_link: create(:video_link, title: searchable_title))
          get_resources
        end

        it 'returns videos filtered by title' do
          expect(parsed_json['response']['video_links'].count).to eq(1)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['title'] }).to include(searchable_title)
        end
      end

      context 'when operator section is faq' do
        let(:faq_video_link) { create(:video_link) }
        let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
        let(:params)         { default_params.merge!(operator_section: 'faq') }

        before do
          sign_in(user)
          create(:model_video_link, videoable: faq, video_link: faq_video_link)
          get_resources
        end

        it 'returns video_links filtered by operator_section' do
          expect(parsed_json['response']['video_links'].count).to eq(1)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['id'] }).to include(faq_video_link.id)
        end
      end

      context 'when operator section is general' do
        let(:faq_video_link) { create(:video_link) }
        let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
        let(:params)         { default_params }

        before do
          sign_in(user)
          create(:model_video_link, videoable: faq, video_link: faq_video_link)
          get_resources
        end

        it 'returns video_links filtered by operator_section' do
          expect(parsed_json['response']['video_links'].count).to eq(1)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['id'] }).not_to include(faq_video_link.id)
        end
      end
    end

    context 'when sorting is applied' do
      let(:another_owning_operator) { create(:operator) }
      let(:another_resource)        { create(:video_link, created_at: 5.years.ago, title: 'another') }
      let(:another_owning_operator_market) do
        create(:operator_market, supported: true, operator: another_owning_operator, name: 'second_operator_market', owner_id: user.id, owner_type: 'User')
      end

      before do
        sign_in(user)
        create(:model_video_link, videoable: another_owning_operator_market, video_link: another_resource)
        get_resources
      end

      include_examples :sorting_by_created_at, 'video_links'
      include_examples :sorting_by_first_operator_market_name, 'video_links'

      context 'sorting by title asc' do
        let(:params) { default_params.merge!(sort_by: 'title', order_by: 'asc') }

        it 'returns video_links sorted by video_link title ascending' do
          expect(parsed_json['response']['video_links'].count).to eq(2)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['id'] }).to eq([another_resource.id, owning_resource.id])
        end
      end

      context 'sorting by title desc' do
        let(:params) { default_params.merge!(sort_by: 'title', order_by: 'desc') }

        it 'returns video_links sorted by video_link title descending' do
          expect(parsed_json['response']['video_links'].count).to eq(2)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['id'] }).to eq([owning_resource.id, another_resource.id])
        end
      end
    end

    context 'when video_links are on several model video_links' do
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

      let(:faq_video_link) { create(:video_link) }
      let(:faq)            { create(:faq, source_of_faqs: owning_operator_market) }
      let(:another_faq)    { create(:faq, source_of_faqs: another_owning_operator_market) }

      context 'operator markets' do
        let(:params) { default_params }

        before do
          sign_in(user)
          create(:model_video_link, videoable: another_owning_operator_market, video_link: owning_resource)
          get_resources
        end

        it 'returns correct additional attributes' do
          expect(parsed_json['response']['video_links'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
        end
      end

      context 'faqs' do
        let(:params) { default_params.merge!(operator_section: 'faq') }

        before do
          sign_in(user)
          create(:model_video_link, videoable: faq, video_link: faq_video_link)
          create(:model_video_link, videoable: another_faq, video_link: faq_video_link)
          get_resources
        end

        it 'returns correct additional attributes' do
          expect(parsed_json['response']['video_links'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
        end
      end
    end
  end
end
