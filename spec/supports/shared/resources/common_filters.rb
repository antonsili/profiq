# frozen_string_literal: true

RSpec.shared_examples :common_filters do
  shared_examples :with_provided_market_id do |entity_name|
    context 'when market_id is provided' do
      let(:fr_market) { Markets::Market.find_by(slug: :fr) }
      let!(:fr_owning_operator_market) do
        create(
          :operator_market,
          operator: owning_operator,
          supported: true,
          market: fr_market,
          name: 'fr_name',
          owner_id: user.id,
          owner_type: 'User'
        )
      end

      let(:params) { default_params.merge!(market_id: fr_market.id) }

      before do
        sign_in(user)
        create(:model_attachment, attachable: fr_owning_operator_market, attachment: create(:attachment))
        create(:model_video_link, videoable: fr_owning_operator_market, video_link: create(:video_link))
        create(:faq, source_of_faqs: fr_owning_operator_market)
        get_resources
      end

      it "returns #{entity_name} filtered by market_id" do
        expect(parsed_json['response'][entity_name].count).to eq(1)
        expect(parsed_json['response'][entity_name].map { |resource| resource['first_operator']['title'] }).to include(fr_owning_operator_market.name)
      end
    end
  end

  shared_examples :with_provided_operator_type_id do |entity_name|
    context 'when operator_type_id is provided' do
      let(:tour_operator_type) { OperatorType.find_by(slug: 'tour-operator') }
      let!(:tour_operator_market) do
        create(
          :operator_market,
          operator: owning_operator,
          supported: true,
          operator_type: tour_operator_type,
          name: 'tour_operator_market',
          owner_id: user.id,
          owner_type: 'User'
        )
      end

      let(:params) { default_params.merge!(operator_type_id: tour_operator_type.id) }

      before do
        sign_in(user)
        create(:model_attachment, attachable: tour_operator_market, attachment: create(:attachment))
        create(:model_video_link, videoable: tour_operator_market, video_link: create(:video_link))
        get_resources
      end

      it "returns #{entity_name} filtered by operator_type_id" do
        expect(parsed_json['response'][entity_name].count).to eq(1)
        expect(parsed_json['response'][entity_name].map { |resource| resource['first_operator']['title'] }).to include(tour_operator_market.name)
      end
    end
  end

  shared_examples :with_provided_operator_id do |entity_name|
    context 'when operator_id is provided' do
      let(:another_owning_operator) { create(:operator) }
      let!(:another_owning_operator_market) do
        create(
          :operator_market,
          operator: another_owning_operator,
          supported: true,
          name: 'another_owning_operator_market',
          owner_id: user.id,
          owner_type: 'User'
        )
      end

      let(:another_owning_ship) { create(:ship, operator: another_owning_operator) }
      let(:params) { default_params.merge!(operator_id: another_owning_operator.id.to_s) }

      before do
        sign_in(user)
        create(:model_attachment, attachable: another_owning_ship, attachment: create(:attachment))
        create(:model_attachment, attachable: another_owning_operator_market, attachment: create(:attachment))
        create(:model_video_link, videoable: another_owning_operator_market, video_link: create(:video_link))
        create(:model_video_link, videoable: another_owning_ship, video_link: create(:video_link))
        create(:faq, source_of_faqs: another_owning_operator_market)
        get_resources
      end

      it "returns #{entity_name} filtered by operator_id" do
        expect(parsed_json['response'][entity_name].count).to eq(1)
        expect(parsed_json['response'][entity_name].map { |resource| resource['first_operator']['title'] }).to include(another_owning_operator_market.name)
      end
    end
  end

  shared_examples :with_provided_ship_id do |entity_name|
    context 'when ship_id is provided' do
      let(:another_owning_operator) { create(:operator) }
      let!(:another_owning_operator_market) do
        create(
          :operator_market,
          operator: another_owning_operator,
          supported: true,
          name: 'another_owning_operator_market',
          owner_id: user.id,
          owner_type: 'User'
        )
      end

      let(:another_owning_ship) { create(:ship, operator: another_owning_operator) }
      let(:params) { default_params.merge!(ship_id: another_owning_ship.id.to_s) }

      before do
        sign_in(user)
        create(:model_video_link, videoable: another_owning_ship, video_link: create(:video_link))
        create(:model_attachment, attachable: another_owning_ship, attachment: create(:attachment))
        get_resources
      end

      it "returns #{entity_name} filtered by ship_id" do
        expect(parsed_json['response'][entity_name].count).to eq(1)
        expect(parsed_json['response'][entity_name].map { |resource| resource['first_operator']['title'] }).to include(another_owning_operator_market.name)
      end
    end
  end
end
