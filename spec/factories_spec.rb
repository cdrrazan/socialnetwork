require "rails_helper"

# Every factory and trait must build a valid record, so a broken factory
# fails here with a clear message instead of somewhere deep in another spec.
RSpec.describe "Factories" do
  FactoryBot.factories.each do |factory|
    describe factory.name do
      it "creates a valid record" do
        expect(create(factory.name)).to be_persisted
      end

      factory.definition.defined_traits.map(&:name).each do |trait|
        it "creates a valid record with the #{trait} trait" do
          expect(create(factory.name, trait)).to be_persisted
        end
      end
    end
  end
end
