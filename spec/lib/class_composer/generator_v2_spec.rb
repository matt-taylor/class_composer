RSpec.describe ClassComposer::Generator do
  let(:name) {  Faker::Lorem.word }
  let(:allowed) { String }
  let(:klass) { composer_new_klass }

  describe ".add_composer_blocking (Class level)" do
    let(:composed_class) { composer_new_klass }
    let(:with_attr_reader) { false }
    let(:attr_reader_name) { :enable }
    let(:enable_attr) { with_attr_reader ? attr_reader_name : nil }
    let(:blocking_name) { :with }
    let(:blocking_attributes) { { block_name: "#{blocking_name}_#{name}", enable_attr:} }

    before do
      if with_attr_reader
        composed_class.add_composer(attr_reader_name, allowed: [TrueClass, FalseClass])
      end
    end

    context "with duplicate name" do
      it do
        klass.add_composer_blocking(name, composer_class: composed_class)

        expect do
          klass.add_composer_blocking(name, composer_class: composed_class)
        end.to raise_error(ClassComposer::Error, /is already defined/)
      end
    end

    context "with invalid composer_class" do
      it do
        expect do
          klass.add_composer_blocking(name, composer_class: String)
        end.to raise_error(ClassComposer::Error, /.add_composer_blocking passed/)
      end
    end

    context "with custom blocking" do
      let(:blocking_name) { Faker::Lorem.word }

      it "defines instance methods" do
        klass.add_composer_blocking(name, composer_class: composed_class, block_prepend: blocking_name)

        expect(klass.instance_methods).to include(:"#{name}=", :"#{name}", :"#{blocking_attributes[:block_name]}")
      end

      it "sets blocking mapping" do
        klass.add_composer_blocking(name, composer_class: composed_class, block_prepend: blocking_name)

        expect(klass.composer_mapping.dig(name, :blocking_attributes)).to eq(blocking_attributes)
      end

      context "with enable_attr" do
        let(:enable_attr) { true}

        it "defines instance methods" do
          klass.add_composer_blocking(name, composer_class: composed_class, block_prepend: blocking_name, enable_attr:)

          expect(klass.instance_methods).to include(:"#{name}=", :"#{name}", :"#{name}?", :"#{blocking_attributes[:block_name]}")
        end

        it "sets blocking mapping" do
          klass.add_composer_blocking(name, composer_class: composed_class, block_prepend: blocking_name, enable_attr:)

          expect(klass.composer_mapping.dig(name, :blocking_attributes)).to eq(blocking_attributes)
        end
      end
    end

    it "defines instance methods" do
      klass.add_composer_blocking(name, composer_class: composed_class)

      expect(klass.instance_methods).to include(:"#{name}=", :"#{name}")
    end

    it "sets blocking mapping" do
    end
  end

  describe ".add_composer (Class level)" do
    context "with duplicate name" do
      it do
        klass.add_composer(name, allowed:)
        expect { klass.add_composer(name, allowed:) }.to raise_error(ClassComposer::Error, /\[#{name}\] is already defined/)
      end
    end

    context "when validator is not a proc" do
      it do
        expect do
          klass.add_composer(name, allowed:, validator: :not_a_proc)
        end.to raise_error(ClassComposer::Error, /Expected validator to be a Proc/)
      end
    end

    context "when default value is not valid" do
      it do
        expect do
          klass.add_composer(name, default: 1234, allowed:)
        end.to raise_error(ClassComposer::Error, /Default value/)
      end

      context "with custom error class" do
        it do
          expect do
            klass.add_composer(name, default: 1234, allowed:, validation_error_klass: NoMethodError)
          end.to raise_error(NoMethodError, /Default value/)
        end
      end
    end

    context "with multiple allowed types" do
      let(:allowed) { [String, Symbol] }

      it "does not raise" do
        expect { klass.add_composer(name, allowed:) }.to_not raise_error
      end

      context "when single included type includes ClassComposer::Generator" do
        let(:composer_class1) { composer_new_klass }
        let(:allowed) { [String, composer_class1] }

        it "does not raise" do
          expect { klass.add_composer(name, allowed:) }.to_not raise_error
        end
      end

      context "when multiple types include ClassComposer::Generator" do
        let(:composer_class1) { composer_new_klass }
        let(:composer_class2) { composer_new_klass }
        let(:allowed) { [String, composer_class1, composer_class2] }

        it "raises" do
          expect { klass.add_composer(name, allowed:) }.to raise_error(ClassComposer::Error, /Allowed arguments has multiple classes that include ClassComposer::Generator/)
        end
      end
    end

    context "when Array passed in" do
      it "does not raise" do
        expect do
          klass.add_composer(name, allowed: Array, default: [1,2,3,4,5], validator: ->(val) { val.sum < 40 })
        end.to_not raise_error
      end
    end



    it "defines instance methods" do
      klass.add_composer(name, allowed:)

      expect(klass.instance_methods).to include(:"#{name}=", :"#{name}")
    end
  end

  describe "#class_composer_frozen! (Instance Level)" do
    subject(:class_composer_frozen) { instance.class_composer_frozen!(name) }

    let(:instance) { klass.new}
    context "when frozen!" do
      before { allow(Kernel).to receive(:warn) }

      context "with proc" do
        before { instance.class_composer_freeze_objects!(&frozen_with) }

        context "when allowed to get set" do
          let(:frozen_with) { -> (key) { Kernel.warn("received"); true } }

          it do
            is_expected.to eq(true)
          end

          it do
            expect(Kernel).to receive(:warn).with("received")

            subject
          end
        end

        context "when not allowed to get set" do
          let(:frozen_with) { -> (key) { Kernel.warn("received"); false } }

          it do
            is_expected.to eq(false)
          end

          it do
            expect(Kernel).to receive(:warn).with("received")

            subject
          end
        end
      end

      context "with raise" do
        before { instance.class_composer_freeze_objects!(behavior: frozen_with) }
        let(:frozen_with) { ClassComposer::FROZEN_RAISE }

        it "raises" do
          expect { class_composer_frozen }.to raise_error(ClassComposer::Error, /#{klass} instance methods are frozen/)
        end
      end

      context "with log and allow" do
        before { instance.class_composer_freeze_objects!(behavior: frozen_with) }
        let(:frozen_with) { ClassComposer::FROZEN_LOG_AND_ALLOW }

        it "logs and returns true" do
          expect(Kernel).to receive(:warn).with(/#{klass} instance methods are frozen/)

          expect(class_composer_frozen).to eq(true)
        end
      end

      context "with log and skip" do
        before { instance.class_composer_freeze_objects!(behavior: frozen_with) }
        let(:frozen_with) { ClassComposer::FROZEN_LOG_AND_SKIP }

        it "logs and returns false" do
          expect(Kernel).to receive(:warn).with(/#{klass} instance methods are frozen/)

          expect(class_composer_frozen).to eq(false)
        end
      end
    end

    context "when not frozen" do
      it do
        is_expected.to be_nil
      end
    end
  end

  describe "#class_composer_assign_defaults! (Instance Level)" do
    subject(:class_composer_assign_defaults) { instance.class_composer_assign_defaults!(children:) }

    let(:instance) { klass.new }
    let(:children) { false }
    before { klass.add_composer(name, allowed:, default: name) }

    it do
      expect(instance).to receive(name).and_call_original
      class_composer_assign_defaults
    end

    context "with children" do
      let(:composer_class) { composer_new_klass }
      let(:composer_name) { Faker::Lorem.word }
      let(:composer_class_instance) { composer_class.new }
      before do
        composer_class.add_composer(name, allowed:, default: name)
        allow(composer_class).to receive(:new).and_return(composer_class_instance)
        klass.add_composer_blocking(composer_name, composer_class:)
      end

      it "does not call children" do
        expect(composer_class_instance).not_to receive(name).and_call_original
        class_composer_assign_defaults
      end

      context "allow children" do
        let(:children) { true }

        it "calls children" do
          expect(composer_class_instance).to receive(name).and_call_original
          class_composer_assign_defaults
        end
      end
    end
  end

  describe "#class_composer_freeze_objects! (Instance Level)" do
    subject(:class_composer_freeze_objects) { instance.class_composer_freeze_objects!(behavior:, children:, &block) }

    let(:instance) { klass.new }
    let(:block) { nil }
    let(:behavior) { nil }
    let(:children) { false }

    context "when block and behavior missing" do
      let(:block) { nil }
      let(:behavior) { nil }

      it do
        expect { class_composer_freeze_objects }.to raise_error(ArgumentError, /`behavior` or `block` must be present/)
      end
    end

    context "when block and behavior are present" do
      let(:block) { ClassComposer::FROZEN_TYPES.sample }
      let(:behavior) { ->() {} }

      it do
        expect { class_composer_freeze_objects }.to raise_error(ArgumentError, /`behavior` and `block` can not both be present. Choose one/)
      end
    end

    context "with invalid behavior" do
      let(:behavior) { "InvalidBehavior" }

      it do
        expect { class_composer_freeze_objects }.to raise_error(ClassComposer::Error, /Unknown behavior/)
      end
    end

    context "with valid behavior" do
      let(:behavior) { ClassComposer::FROZEN_TYPES.sample }

      it do
        expect { class_composer_freeze_objects }.not_to raise_error
      end

      it do
        expect(class_composer_freeze_objects).to be_nil
      end
    end

    context "with valid proc" do
      let(:block) { ->() { "proc is tested in class_composer_frozen" } }

      it do
        expect { class_composer_freeze_objects }.not_to raise_error
      end

      it do
        expect(class_composer_freeze_objects).to be_nil
      end

      context "with children" do
      end
    end

    context "with children" do
      let(:children) { true }
      let(:composer_class) { composer_new_klass }
      let(:composer_name) { Faker::Lorem.word }
      let(:composer_class_instance) { composer_class.new }
      before do
        composer_class.add_composer(name, allowed:, default: name)
        allow(composer_class).to receive(:new).and_return(composer_class_instance)
        klass.add_composer_blocking(composer_name, composer_class:)
      end

      context "with proc" do
        let(:block) { -> () {} }

        it "child proc is the same" do
          class_composer_freeze_objects

          expect(composer_class_instance.instance_variable_get(:@class_composer_frozen)).to eq(block)
          expect(instance.instance_variable_get(:@class_composer_frozen)).to eq(block)
        end
      end

      context "with behavior" do
        let(:behavior) { ClassComposer::FROZEN_TYPES.sample }

        it "child behavior is the same" do
          class_composer_freeze_objects

          expect(composer_class_instance.instance_variable_get(:@class_composer_frozen)).to eq(behavior)
          expect(instance.instance_variable_get(:@class_composer_frozen)).to eq(behavior)
        end
      end
    end
  end

  describe "* Getter Methods * (Instance Level)" do
    context "with custom validator" do
      let(:validator) { ->(val) { val < 50 } }


      context "with custom message" do
        let(:invalid_message) { ->(val) { "#{val} must be less than 50" } }
      end
    end
  end

  describe "* Setter Methods * (Instance Level)" do
    let(:instance) { klass.new }
    before do
      klass.add_composer(name, allowed:, default: "", **params, &blk)
      allow(Kernel).to receive(:warn)
    end

    let(:params) { {} }
    let(:blk) { nil }

    context "when frozen" do
      before do
        allow(Kernel).to receive(:warn)
        instance.class_composer_freeze_objects!(behavior:)
      end

      context "when allowed to set" do
        let(:behavior) { ClassComposer::FROZEN_LOG_AND_ALLOW }

        it "sets variable" do
          expect(instance.send(name)).to eq("")

          expect(Kernel).to receive(:warn).with(/This operation will proceed/)

          instance.send("#{name}=", "New String")

          expect(instance.send(name)).to eq("New String")
        end
      end

      context "when not allowed to set" do
        let(:behavior) { ClassComposer::FROZEN_LOG_AND_SKIP }

        it "skips setting variable" do
          expect(instance.send(name)).to eq("")

          expect(Kernel).to receive(:warn).with(/This operation will NOT proceed/)

          instance.send("#{name}=", "New String")

          expect(instance.send(name)).to eq("")
        end
      end
    end

    context "when invalid" do
      context "with incorrect type" do
        it "raises" do
          expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /failed validation/)
        end

        context "with array" do
          before { klass.add_composer("array", allowed: Array, default: [], **params) }

          it "raises" do
            expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /failed validation/)
          end
        end
      end

      context "when custom validation fails" do
        let(:params) { super().merge(validator: ->(value) { value == "" || value.include?("l") } ) }

        it "raises" do
          expect { instance.send("#{name}=", "boo") }.to raise_error(ClassComposer::ValidatorError, /failed validation/)
        end
      end

      context "with invalid custom validation message" do
        context "when a proc" do
          let(:params) { super().merge(invalid_message: ->(value) { "#{value} is invalid with custom proc" } ) }

          it "raises" do
            expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /invalid with custom proc/)
          end

          context "with array" do
            before { klass.add_composer("array", allowed: Array, default: [], **params) }

            it "raises" do
              expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /invalid with custom proc/)
            end
          end
        end

        context "when a string" do
          let(:params) { super().merge(invalid_message: "custom invalid value") }

          it "raises" do
            expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /custom invalid value/)
          end

          context "with array" do
            before { klass.add_composer("array", allowed: Array, default: [], **params) }

            it "raises" do
              expect { instance.send("#{name}=", 5) }.to raise_error(ClassComposer::ValidatorError, /custom invalid value/)
            end
          end
        end
      end
    end

    context "when composer passed with a block" do
      let(:blk) { ->(name, value) { Kernel.warn("Setting #{name} => #{value}") } }
      let(:new_value) { "This is a New Value" }

      it "calls block after assignment" do
        expect(Kernel).to receive(:warn).with("Setting #{name} => #{new_value}")

        instance.send("#{name}=", new_value)

        expect(instance.send("#{name}")).to eq(new_value)
      end
    end

    context "with blocking" do
      let(:composer_class) { composer_new_klass }
      let(:composer_class_instance) { composer_class.new }
      let(:enable_attr) { :enable }
      let(:block_prepend) { :with }
      let(:block_name) { "#{block_prepend}_#{blocking_composer_name}"}
      let(:blocking_attributes) { { block_name:, enable_attr:} }
      let(:blocking_composer_name) { Faker::Lorem.word }

      before do
        allow(composer_class).to receive(:new).and_return(composer_class_instance)
        composer_class.add_composer(enable_attr, allowed: [TrueClass, FalseClass], default: false)
        klass.add_composer_blocking(blocking_composer_name, composer_class:, block_prepend:, enable_attr:)
      end

      it "enables from block" do
        expect(composer_class_instance.send(enable_attr)).to eq(false)

        instance.send(block_name) do |_|
        end

        expect(instance.send("#{blocking_composer_name}?")).to be(true)
      end

      it "enables without block given" do
        expect(composer_class_instance.send(enable_attr)).to eq(false)

        instance.send(block_name)

        expect(instance.send("#{blocking_composer_name}?")).to be(true)
      end

      it "enabled via variable name" do
        expect(composer_class_instance.send(enable_attr)).to eq(false)

        instance.send(blocking_composer_name).send("#{enable_attr}=", true)

        expect(instance.send("#{blocking_composer_name}?")).to be(true)
      end
    end

    context "with Array" do
      # Bug Alert: @matt-taylor
      # Array addition has issues with in place adding. <<, push, unshift, etc will bypass validation and frozen types
      before do
        klass.add_composer("array", allowed: Array, default: [])
      end

      context "with <<" do
        context "when first call is set" do
          before { instance.array = [] }

          it "succeeds" do
            expect(instance.array).to eq([])
            expect { instance.array << 5 }.to_not raise_error
            expect(instance.array).to eq([5])
          end
        end

        context "when first call is get" do
          it "succeeds" do
            expect(instance.array).to eq([])
            expect { instance.array << 5 }.to_not raise_error
            expect(instance.array).to eq([5])
          end
        end
      end
    end
  end
end
