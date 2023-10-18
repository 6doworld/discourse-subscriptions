# frozen_string_literal: true

require "rails_helper"

describe ::DiscourseSubscriptions::Products::CreateOrUpdateService do
  describe "#call" do
    subject(:call) { described_class.new(object).call! }

    context 'when creating a new product' do
      # I am not sure how adding such validations to the model
      #  can affect existing code
      context 'with blank external id' do
        let(:object) { { id: ''} }

        it 'raises proper error' do
          expect { call }.to(
            raise_error(ArgumentError, 'stripe product id cannot be blank') &
            not_change(::DiscourseSubscriptions::Product, :count)
          )
        end
      end

      context 'with present external id' do
        let(:object) { { id: 'prod_12345'} }

        it 'saves new record' do
          expect { call }.to change(::DiscourseSubscriptions::Product, :count).by(1)
          expect(::DiscourseSubscriptions::Product.last.external_id).to eq('prod_12345')
        end
      end
    end

    context 'with existing record' do
      before do
        ::DiscourseSubscriptions::Product.create!(external_id: 'prod_12345')
      end

      # I am not sure how adding such validations to the model
      #  can affect existing code
      context 'with blank external id' do
        let(:object) { { id: ''} }

        it 'raises proper error' do
          expect { call }.to(
            raise_error(ArgumentError, 'stripe product id cannot be blank') &
            not_change(::DiscourseSubscriptions::Product, :count)
          )
        end
      end

      context 'with different external id' do
        let(:object) { { id: 'prod_00000'} }

        it 'saves new record' do
          expect { call }.to change(::DiscourseSubscriptions::Product, :count).by(1)
          expect(::DiscourseSubscriptions::Product.last.external_id).to eq('prod_00000')
        end
      end

      context 'with same external id' do
        let(:object) { { id: 'prod_12345'} }

        it 'does not change database records' do
          expect { call }.not_to(
            change(::DiscourseSubscriptions::Product, :count)
          )
        end

        it 'returns true' do
          expect(call).to eq(true)
        end
      end
    end
  end
end
