# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Web::Resources::Ships::VideosController, type: :request do
  subject(:get_filters) do
    get(available_filters_api_web_resources_ships_videos_path)
  end

  describe 'GET /api/web/resources/operators/videos/available_filters' do
    let!(:market)                      { Markets::Market.default_market }
    let(:following_operator)           { create(:operator) }
    let(:owning_operator)              { create(:operator) }
    let!(:unsupported_operator_market) { create(:primary_operator_market, supported: false) }
    let!(:following_operator_market)   { create(:primary_operator_market, operator: following_operator, supported: true) }
    let!(:owning_operator_market)      { create(:primary_operator_market, operator: owning_operator, supported: true, owner_id: user.id, owner_type: 'User') }

    include_examples :user_with_admin_role
    include_examples :user_with_agent_role
    include_examples :user_with_operator_agent_role

    context 'when user has operator role' do
      let(:operator_company_type) { create(:company_type, permission_types: %w[operator]) }
      let(:team)                  { create(:teams_team, company_type: operator_company_type, markets: [market]) }
      let(:user)                  { create(:user, teams: [team]) }

      before do
        sign_in(user)
        get_filters
      end

      it 'returns correct operator filters' do
        expect(parsed_json['response']['available_filters']['role_based_available_filters']).to eq([])
      end
    end
  end
end
