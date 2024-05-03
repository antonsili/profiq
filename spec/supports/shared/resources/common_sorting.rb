# frozen_string_literal: true

RSpec.shared_examples :common_sorting do
  shared_examples :sorting_by_created_at do |entity_name|
    context 'sorting by created_at asc' do
      let(:params) { default_params.merge!(sort_by: 'created_at', order_by: 'asc') }

      it "returns #{entity_name} sorted by created_at ascending" do
        expect(parsed_json['response'][entity_name].count).to eq(2)
        expect(parsed_json['response'][entity_name].map { |resource| resource['id'] }).to eq([another_resource.id, owning_resource.id])
      end
    end

    context 'sorting by created_at desc' do
      let(:params) { default_params.merge!(sort_by: 'created_at', order_by: 'desc') }

      it "returns #{entity_name} sorted by created_at descending" do
        expect(parsed_json['response'][entity_name].count).to eq(2)
        expect(parsed_json['response'][entity_name].map { |resource| resource['id'] }).to eq([owning_resource.id, another_resource.id])
      end
    end
  end

  shared_examples :sorting_by_first_operator_market_name do |entity_name|
    context 'sorting by first_operator_market_name asc' do
      let(:params) { default_params.merge!(sort_by: 'first_operator_market_name', order_by: 'asc') }

      it "returns #{entity_name} sorted by first_operator_market_name ascending" do
        expect(parsed_json['response'][entity_name].count).to eq(2)
        expect(parsed_json['response'][entity_name].map { |resource| resource['id'] }).to eq([owning_resource.id, another_resource.id])
      end
    end

    context 'sorting by first_operator_market_name desc' do
      let(:params) { default_params.merge!(sort_by: 'first_operator_market_name', order_by: 'desc') }

      it "returns #{entity_name} sorted by first_operator_market_name descending" do
        expect(parsed_json['response'][entity_name].count).to eq(2)
        expect(parsed_json['response'][entity_name].map { |resource| resource['id'] }).to eq([another_resource.id, owning_resource.id])
      end
    end
  end
end
