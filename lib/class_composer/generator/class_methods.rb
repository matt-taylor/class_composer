# frozen_string_literal: true

module ClassComposer
  module Generator
    module ClassMethods
      COMPOSER_VALIDATE_METHOD_NAME = ->(name) { :"__composer_#{name}_is_valid__?" }
      COMPOSER_ASSIGNED_ATTR_NAME = ->(name) { :"@__composer_#{name}_value_assigned__" }
      COMPOSER_ASSIGNED_ARRAY_METHODS = ->(name) { :"@__composer_#{name}_array_methods_set__" }
      COMPOSER_ALLOWED_FROZEN_TYPE_ARGS = [:raise, :log]

      def add_composer_blocking(name, composer_class:, desc: nil, block_prepend: "with", enable_attr: nil)
        unless composer_class.include?(ClassComposer::Generator)
          raise ClassComposer::Error, ".add_composer_blocking passed `composer_class:` that does not include ClassComposer::Generator. Passed argument must include ClassComposer::Generator"
        end

        blocking_name = "#{block_prepend}_#{name}"
        blocking_attributes = { block_name: blocking_name, enable_attr: enable_attr }
        add_composer(name, allowed: composer_class, default: composer_class.new, desc: desc, blocking_attributes: blocking_attributes)

        define_method(blocking_name) do |&blk|
          instance = public_send(:"#{name}")
          instance.public_send(:"#{enable_attr}=", true) if enable_attr

          blk.(instance) if blk

          method(:"#{name}=").call(instance)
        end

        if enable_attr
          define_method("#{name}?") do
            public_send(:"#{name}").public_send(enable_attr)
          end
        end
      end

      def add_composer(name, allowed:, desc: nil, validator: ->(_) { true }, validation_error_klass: ::ClassComposer::ValidatorError, error_klass: ::ClassComposer::Error, blocking_attributes: nil, default_shown: nil, **params, &blk)
        default =
          if params.has_key?(:default)
            params[:default]
          else
            ClassComposer::DefaultObject
          end

        if params[:default] && params[:dynamic_default]
          raise Error, "Composer :#{name} had both the `:default` and `:dynamic_default` assigned. Only one allowed"
        end

        if dynamic_default = params[:dynamic_default]
          if ![Proc, Symbol].include?(dynamic_default.class)
            raise Error, "Composer :#{name} defined `:dynamic_default: #{dynamic_default}`. Expected value to be a Symbol mapped to a composer element or a Proc"
          end

          if Symbol === dynamic_default && composer_mapping[dynamic_default].nil?
            raise Error, "Composer :#{name} defined `dynamic_default: #{dynamic_default}`. #{dynamic_default} is not defined. Please ensure that all dynamic_default's are defined before setting them"
          end
        end

        if allowed.is_a?(Array)
          allowed << ClassComposer::DefaultObject
        else
          allowed = [allowed, ClassComposer::DefaultObject]
        end

        if allowed.select { _1.include?(ClassComposer::Generator) }.count > 1
          raise Error, "Allowed arguments has multiple classes that include ClassComposer::Generator. Max 1 is allowed"
        end

        validate_proc = __composer_validator_proc__(validator: validator, allowed: allowed, name: name, error_klass: error_klass)
        __composer_validate_options__!(name: name, validate_proc: validate_proc, default: default, validation_error_klass: validation_error_klass, error_klass: error_klass)

        array_proc = __composer_array_proc__(name: name, validator: validator, allowed: allowed, params: params)
        __composer_assignment__(name: name, allowed: allowed, params: params, validator: validate_proc, array_proc: array_proc, validation_error_klass: validation_error_klass, error_klass: error_klass, &blk)
        __composer_retrieval__(name: name, allowed: allowed, default: default, array_proc: array_proc, params: params, validator: validate_proc, validation_error_klass: validation_error_klass)

        # Add to mapping
        __add_to_composer_mapping__(name: name, default: default, allowed: allowed, desc: desc, blocking_attributes: blocking_attributes, default_shown: default_shown, dynamic_default: params[:dynamic_default])
      end

      def composer_mapping
        @composer_mapping ||= {}
      end

      def composer_generate_config(wrapping:, require_file: nil, space_count: 2)
        @composer_generate_config ||= GenerateConfig.new(instance: self)

        @composer_generate_config.execute(wrapping:, require_file:, space_count:)
      end

      def __add_to_composer_mapping__(name:, default:, allowed:, desc:, blocking_attributes:, default_shown: nil, dynamic_default: nil)
        children = Array(allowed).select { _1.include?(ClassComposer::Generator) }.map do |allowed_class|
          allowed_class.composer_mapping
        end

        composer_mapping[name] = {
          desc: desc,
          children: children.empty? ? nil : children,
          dynamic_default: dynamic_default,
          default_shown: default_shown,
          default: (default.to_s.start_with?("#<") ? default.class : default),
          blocking_attributes: blocking_attributes,
          allowed: allowed,
        }.compact
      end

      def __composer_validate_options__!(name:, validate_proc:, default:, params: {}, validation_error_klass:, error_klass:)
        unless validate_proc.(default)
          raise validation_error_klass, "Default value [#{default}] for #{self.class}.#{name} is not valid"
        end

        if instance_methods.include?(name.to_sym)
          raise error_klass, "[#{name}] is already defined. Ensure composer names are all uniq and do not class with class instance methods"
        end
      end

      def __composer_array_proc__(name:, validator:, allowed:, params:)
        Proc.new do |value, _itself|
          _itself.send(:"#{name}=", value)
        end
      end

      # create assignment method for the incoming name
      def __composer_assignment__(name:, params:, allowed:, validator:, array_proc:, validation_error_klass:, error_klass:, &blk)
        define_method(:"#{name}=") do |value|
          case class_composer_frozen!(name)
          when false
            # false is returned when the instance is frozen AND we do not allow the operation to proceed
            return
          when true
            # true is returned when the instance is frozen AND we allow the operation to proceed
          when nil
            # nil is returned when the instance is not frozen
          end

          is_valid = self.class.__run_validation_item(name: name, validator: validator, allowed: allowed, value: value, params: params)

          if is_valid[:valid]
            instance_variable_set(COMPOSER_ASSIGNED_ATTR_NAME.(name), true)
            instance_variable_set(:"@#{name}", value)
          else
            raise validation_error_klass, is_valid[:message].compact.join(" ")
          end

          if value.is_a?(Array) && !value.instance_variable_get(COMPOSER_ASSIGNED_ARRAY_METHODS.(name))
            _itself = itself
            value.define_singleton_method(:<<) do |val|
              array_proc.(super(val), _itself)
            end
            value.instance_variable_set(COMPOSER_ASSIGNED_ARRAY_METHODS.(name), true)
          end

          if blk
            yield(name, value)
          end

          value
        end
      end

      def __run_validation_item(validator:, name:, value:, allowed:, params:)
        if validator.(value)
          return { valid: true }
        end

        message = ["#{self.class}.#{name} failed validation. #{name} is expected to be #{allowed}. Received [#{value}](#{value.class})"]
        message << (params[:invalid_message].is_a?(Proc) ? params[:invalid_message].(value) : params[:invalid_message].to_s)

        { valid: false, message: message }
      end

      # retrieve the value for the name -- Or return the default value
      def __composer_retrieval__(name:, default:, array_proc:, allowed:, params:, validator:, validation_error_klass:)
        define_method(:"#{name}") do
          value = instance_variable_get(:"@#{name}")
          return value if instance_variable_get(COMPOSER_ASSIGNED_ATTR_NAME.(name))

          if dynamic_default = params[:dynamic_default]
            if Proc === dynamic_default
              value = dynamic_default.(self)
            else
              # We know the method exists because we already checked validity from within
              # `compose_mapping` on add_composer creation
              value = method(:"#{dynamic_default}").()
            end
            is_valid = self.class.__run_validation_item(name: name, validator: validator, allowed: allowed, value: value, params: params)

            if is_valid[:valid]
              instance_variable_set(COMPOSER_ASSIGNED_ATTR_NAME.(name), true)
              instance_variable_set(:"@#{name}", value)
            else
              raise validation_error_klass, is_valid[:message].compact.join(" ")
            end

            return value
          end

          if default.is_a?(Array) && !default.instance_variable_get(COMPOSER_ASSIGNED_ARRAY_METHODS.(name))
            _itself = itself
            default.define_singleton_method(:<<) do |value|
              array_proc.(super(value), _itself)
            end
            default.instance_variable_set(COMPOSER_ASSIGNED_ARRAY_METHODS.(name), true)
          end

          default == ClassComposer::DefaultObject ? ClassComposer::DefaultObject.value : default
        end
      end

      # create validator method for incoming name
      def __composer_validator_proc__(validator:, allowed:, name:, error_klass:)
        if validator && !validator.is_a?(Proc)
          raise error_klass, "Expected validator to be a Proc. Received [#{validator.class}]"
        end

        # Proc will validate the entire attribute -- Full assignment must occur before validate is called
        Proc.new do |value|
          begin
            allow =
              if allowed.is_a?(Array)
                allowed.include?(value.class)
              else
                allowed == value.class
              end
            # order is important -- Do not run validator if it is the default object
            # Default object will likely raise an error if there is a custom validator
            (allowed.include?(ClassComposer::DefaultObject) && value == ClassComposer::DefaultObject) || (allow && validator.(value))
          rescue StandardError => e
            raise error_klass, "#{e} occurred during validation for value [#{value}]. Check custom validator for #{name}"
          end
        end
      end
    end
  end
end
