# frozen_string_literal: true

RSpec.describe ClassComposer::Generator do
  let(:instance) { klass.new }
  let(:klass) do
    class CacheDefault
      include ClassComposer::Generator

      add_composer :status, allowed: Integer, default: 35, validator: ->(val) { val > 3 }, invalid_message: -> (val) { "#{val} is less than 3" }
      add_composer :array, allowed: Array, default: [], validator: ->(val) { val.length < 5 && val.sum < 40 }, invalid_message: -> (val) { "Array length must be less than 5. And sum must be less than 40" }
    end
    CacheDefault
  end

  describe ".add_composer" do
    context "when default value is invalid" do
    end

    context "with duplicate composer name" do
    end

    context "with array" do
    end
  end
end
