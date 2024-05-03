# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Ships::VideosController, type: :request do
  subject(:get_resources) do
    get(api_web_resources_ships_videos_path, params)
  end

  include_context :role_based_filters
  include_context :common_filters
  include_context :common_sorting

  describe 'GET /api/web/resources/ships/videos' do
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
    let(:following_ship)   { create(:ship, operator: following_operator) }
    let(:owning_ship)      { create(:ship, operator: owning_operator) }

    let(:owning_resource) { create(:video_link, title: 'owning') }

    let!(:unsupported_model_video_link) { create(:model_video_link, videoable: unsupported_ship, video_link: create(:video_link)) }
    let!(:following_model_video_link)   { create(:model_video_link, videoable: following_ship, video_link: create(:video_link)) }
    let!(:owning_model_video_link) do
      create(:model_video_link, videoable: owning_ship, video_link: owning_resource)
    end

    let(:default_params) { { ship_section: 'general' } }

    let(:operator_company_type)   { create(:company_type, permission_types: %w[operator]) }
    let(:team)                    { create(:teams_team, company_type: operator_company_type, markets: [market]) }
    let(:user)                    { create(:user, teams: [team]) }

    include_examples :user_with_admin_role, 'video_links'
    include_examples :user_with_operator_role, 'video_links'
    include_examples :user_with_agent_role, 'video_links'
    include_examples :user_with_operator_agent_role, 'video_links'

    context 'when user has admin role' do
      context 'when some of operator markets are not supported' do
        let(:user) { create(:superadmin) }

        before do
          sign_in(user)
          following_operator.add_follow!(user)
          create(:operator_market, operator_type: river_cruise_line, operator: following_operator, supported: false)
          create(:operator_market, operator_type: river_cruise_line, operator: owning_operator, supported: false)
          create(:operator_market, operator_type: river_cruise_line, operator: unsupported_operator_market.operator, supported: true)
          get_resources
        end

        context 'when supported_operators is true' do
          let(:params) { default_params.merge!(supported_operators: true) }

          it 'return only video_links for ship with operator with several not supported operator markets' do
            expect(parsed_json['response']['video_links'].count).to eq(3)
            expect(parsed_json['response']['video_links'].map { |resource| resource['first_operator']['title'] }).to include(unsupported_operator_market.name)
          end
        end

        context 'when other_operators is true' do
          let(:params) { default_params.merge!(other_operators: true) }

          it 'return no result' do
            expect(parsed_json['response']['video_links'].count).to eq(0)
          end
        end
      end
    end

    context 'when common filters are applied' do
      include_examples :with_provided_operator_id, 'video_links'
      include_examples :with_provided_ship_id, 'video_links'

      context 'with search by title' do
        let(:searchable_title) { 'another' }
        let(:params) { default_params.merge!(query: 'another') }

        before do
          sign_in(user)
          create(:model_video_link, videoable: owning_ship, video_link: create(:video_link, title: searchable_title))
          get_resources
        end

        it 'returns video_links filtered by title' do
          expect(parsed_json['response']['video_links'].count).to eq(1)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['title'] }).to include(searchable_title)
        end
      end

      context 'when ship section is not general' do
        let(:params)                  { default_params.merge!(ship_section: 'accomodation') }
        let(:accomodation_video_link) { create(:video_link, title: 'accomodation video link') }

        before do
          sign_in(user)
          create(:ship_video_link, ship: owning_ship, video_link: accomodation_video_link, video_link_type: :accomodation)
          create(:ship_video_link, ship: owning_ship, video_link: accomodation_video_link, video_link_type: :dining)
          get_resources
        end

        it 'return video_links for not general ship section' do
          expect(parsed_json['response']['video_links'].count).to eq(1)
          expect(parsed_json['response']['video_links'].map { |video_link| video_link['title'] }).to include(accomodation_video_link.title)
        end
      end
    end

    context 'when sorting is applied' do
      let(:another_owning_operator) { create(:operator) }
      let(:another_resource)        { create(:video_link, created_at: 5.years.ago, title: 'another') }
      let(:another_owning_ship)     { create(:ship, operator: another_owning_operator) }
      let!(:another_owning_operator_market) do
        create(:operator_market, supported: true, operator: another_owning_operator, name: 'second_operator_market', owner_id: user.id, owner_type: 'User')
      end

      before do
        sign_in(user)
        create(:model_video_link, videoable: another_owning_ship, video_link: another_resource)
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

    context 'when video_links are on several ships' do
      let(:another_ship) { create(:ship, operator: owning_operator) }
      let(:params) { default_params }

      before do
        sign_in(user)
        create(:model_video_link, videoable: another_ship, video_link: owning_resource)
        get_resources
      end

      it 'returns correct preview links for all ships' do
        expect(parsed_json['response']['video_links'][0]['preview']['links'].map { |s| s['title'] }).to eq([owning_ship.title, another_ship.title])
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
        expect(parsed_json['response']['video_links'][0]['first_operator']['title']).to eq(another_owning_operator_market.name)
      end
    end

    context 'when ship_section is all_sections' do
      let(:user) { create(:superadmin) }
      let(:params) { default_params.merge!(ship_section: 'all_sections', i_follow: true, other_operators: true, supported_operators: true) }

      let(:dining_option_ship) { create(:ship, operator: create(:operator, :with_primary_operator_market)) }
      let(:another_ship) { create(:ship, operator: following_operator) }

      let!(:dining_option_ship_video_link) do
        create(:ship_video_link, ship_id: dining_option_ship.id, video_link_type: 'dining', video_link: create(:video_link))
      end
      let!(:owning_resource_on_another_ship) { create(:model_video_link, videoable: another_ship, video_link: owning_resource) }

      before do
        sign_in(user)
        get_resources
      end

      it 'returns all both ship and dining options videos' do
        expect(parsed_json['response']['video_links'].count).to eq 4
        expect(
          parsed_json['response']['video_links'].detect do |attachment|
            attachment['id'] == dining_option_ship_video_link.video_link_id
          end['preview']['links'][0]['title']
        ).to eq dining_option_ship.title
        expect(
          parsed_json['response']['video_links'].detect { |video_link| video_link['id'] == owning_resource.id }['preview']['links'].map { |s| s['title'] }
        ).to eq [owning_ship.title, another_ship.title]
      end

      it 'returns videos with the necessary tags' do
        expect(
          parsed_json['response']['video_links'].detect { |video_link| video_link['id'] == owning_resource.id }['tags'].map { |t| t['title'] }
        ).to eq [owning_ship.model_video_link.videoable_type]

        dining_option_ship_tags = parsed_json['response']['video_links'].
          detect { |video_link| video_link['id'] == dining_option_ship_video_link.video_link_id }.
          fetch('tags', []).
          map { |t| t['id'] }
        expect(dining_option_ship_tags).to eq [dining_option_ship.ship_video_links.first.video_link_type]
      end
    end
  end
end
