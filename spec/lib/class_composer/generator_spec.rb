# frozen_string_literal: true

RSpec.describe ClassComposer::Generator do
  let(:instance) { klass.new }
  let(:klass) do
    class Klass
      include ClassComposer::Generator

      add_composer :status, allowed: Integer, default: 35, validator: ->(val) { val > 3 }, invalid_message: -> (val) { "#{val} is less than 3" }
      add_composer :array, allowed: Array, default: [], validator: ->(val) { val.length < 5 && val.sum < 40 }, invalid_message: -> (val) { "Array length must be less than 5. And sum must be less than 40" }
    end
    Klass
  end

  describe ".add_composer" do
    context "when default value is invalid" do
      let(:klass) do
        class Invalid
          include ClassComposer::Generator

          add_composer :status, allowed: Integer, default: 35, validator: ->(val) { val == 3 }, invalid_message: -> (val) { "#{val} is less than 3" }
        end
        Invalid
      end

      it "raises" do
        expect { klass }.to raise_error(::ClassComposer::ValidatorError, /Default value/)
      end

      context "with error class" do
        let(:klass) do
          class InvalidWithError
            include ClassComposer::Generator

            add_composer :status, allowed: Integer, default: 35, validator: ->(val) { val == 3 }, invalid_message: -> (val) { "#{val} is less than 3" }, validation_error_klass: NoMethodError

          end
          InvalidWithError
        end

        it "raises" do
          expect { klass }.to raise_error(NoMethodError, /Default value/)
        end
      end
    end

    context "with duplicate composer name" do
      let(:klass) do
        class Duplicate
          include ClassComposer::Generator

          add_composer :status, allowed: Integer, default: 35
          add_composer :status, allowed: Integer, default: 35
        end
        Duplicate
      end
      it "raises" do
        expect { klass }.to raise_error(::ClassComposer::Error, /is already defined/)
      end
    end

    context "with multiple allowed types" do
      let(:klass) do
        class Allowed
          include ClassComposer::Generator

          add_composer :message, allowed: [Proc, Integer], default: 35
        end
        Allowed
      end
      let(:klass2) do
        class Allowed2
          include ClassComposer::Generator

          add_composer :message, allowed: [Proc, Integer], default: 35
        end
        Allowed2
      end

      it "does not raise" do
        expect { klass }.to_not raise_error
      end

      it "sets default" do
        expect(klass2.new.message).to eq(35)
      end
    end

    context "when Array passed in" do
      let(:klass) do
        class WithArray
          include ClassComposer::Generator

          add_composer :array, allowed: Array, default: [1,2,3,4,5], validator: ->(val) { val.sum < 40 }
        end
        WithArray
      end

      it "does not raise" do
        expect { klass }.to_not raise_error
      end
    end
  end

  describe "getter methods" do
  end

  describe "setter methods" do
  end

  describe "array setter methods" do
  end
end
