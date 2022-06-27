# frozen_string_literal: true

RSpec.describe ClassComposer::Generator do
  describe ".add_composer" do
    context "when validator is not a proc" do
      let(:klass) do
        class InvalidProc
          include ClassComposer::Generator

          add_composer :status, allowed: Integer, default: 35, validator: :not_a_proc, invalid_message: -> (val) { "#{val} is less than 3" }
        end
        InvalidProc
      end

      it "raises" do
        expect { klass }.to raise_error(::ClassComposer::Error, /Expected validator to be a Proc/)
      end
    end

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

    context "with no default value" do
      let(:klass) do
        class ComposerWODefault
          include ClassComposer::Generator

          add_composer :status, allowed: [Integer, String]
        end
        ComposerWODefault
      end

      it "does not raise" do
        expect { klass }.to_not raise_error
      end
    end
  end

  describe "getter methods" do
    let(:klassWithDefault) do
      class KlassWDefault
        include ClassComposer::Generator

        add_composer :status, allowed: Integer, default: 1_000
      end
      KlassWDefault
    end
    let(:klassWithoutDefault) do
      class KlassWODefault
        include ClassComposer::Generator

        add_composer :status, allowed: Integer
      end
      KlassWODefault
    end

    it "gets default value" do
      expect(klassWithDefault.new.status).to eq(1_000)
    end

    it "gets nil value" do
      expect(klassWithoutDefault.new.status).to eq(nil)
    end

    context "when value has been set" do
      before { instance.status = 100_000 }
      let(:instance) { klassss.new }
      let(:klassss) do
        class Klassss
          include ClassComposer::Generator

          add_composer :status, allowed: Integer
        end
        Klassss
      end

      it "returns correct value" do
        expect(instance.status).to eq(100_000)
      end
    end
  end

  describe "setter methods" do
    context "when custom validator raises" do
      let(:klass) do
        class ValidatorRaiseError
          include ClassComposer::Generator

          add_composer :status, allowed: Integer, default: 35, validator: ->(val) { raise NoMethodError }, invalid_message: -> (val) { "#{val} is less than 3" }, validation_error_klass: NoMethodError

        end
        ValidatorRaiseError
      end

      it "raises" do
        expect { klass }.to raise_error(ClassComposer::Error, /NoMethodError occured during validation for value/)
      end
    end

    describe "array setter methods" do
    end

    context "when "
  end
end
