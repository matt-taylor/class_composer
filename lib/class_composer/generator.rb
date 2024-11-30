# frozen_string_literal: true

require "class_composer/default_object"
require "class_composer/generate_config"

module ClassComposer
  FROZEN_TYPES = [
    DEFAULT_FROZEN_TYPE = FROZEN_RAISE = :raise,
    FROZEN_LOG_AND_ALLOW = :log_and_allow,
    FROZEN_LOG_AND_SKIP = :log_and_skip,
  ]
  module Generator
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def class_composer_frozen!(key)
        # when nil, we allow changes to the instance methods
        return if @class_composer_frozen.nil?

        # When frozen is a proc, we let the user decide how to handle
        # The return value decides if the value can be changed or not
        if Proc === @class_composer_frozen
          return @class_composer_frozen.(key)
        end

        msg = "#{self.class} instance methods are frozen. Attempted to change variable [#{key}]."
        case @class_composer_frozen
        when FROZEN_LOG_AND_ALLOW
          msg += " This operation will proceed."
          Kernel.warn(msg)
          return true
        when FROZEN_LOG_AND_SKIP
          msg += " This operation will NOT proceed."
          Kernel.warn(msg)
          return false
        when FROZEN_RAISE
          raise Error, msg
        end
      end

      def class_composer_assign_defaults!(children: false)
        self.class.composer_mapping.each do |key, metadata|
          assigned_value = method(:"#{key}").call
          method(:"#{key}=").call(assigned_value)

          if children && metadata[:children]
            method(:"#{key}").call().class_composer_assign_defaults!(children: children)
          end
        end

        nil
      end

      def class_composer_freeze_objects!(behavior: nil, children: false, &block)
        if behavior && block
          raise ArgumentError, "`behavior` and `block` can not both be present. Choose one"
        end

        if behavior.nil? && block.nil?
          raise ArgumentError, "`behavior` or `block` must be present."
        end

        if block
          @class_composer_frozen = block
        else
          if !FROZEN_TYPES.include?(behavior)
            raise Error, "Unknown behavior [#{behavior}]. Expected one of #{FROZEN_TYPES}."
          end
          @class_composer_frozen = behavior
        end

        # If children is set, iterate the children, otherwise exit early
        return if children == false

        self.class.composer_mapping.each do |key, metadata|
          next unless metadata[:children]

          method(:"#{key}").call().class_composer_freeze_objects!(behavior:, children:, &block)
        end
      end
    end

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
        __composer_retrieval__(name: name, default: default, array_proc: array_proc)

        # Add to mapping
        __add_to_composer_mapping__(name: name, default: default, allowed: allowed, desc: desc, blocking_attributes: blocking_attributes, default_shown: default_shown)
      end

      def composer_mapping
        @composer_mapping ||= {}
      end

      def composer_generate_config(wrapping:, require_file: nil, space_count: 2)
        @composer_generate_config ||= GenerateConfig.new(instance: self)

        @composer_generate_config.execute(wrapping:, require_file:, space_count:)
      end

      def __add_to_composer_mapping__(name:, default:, allowed:, desc:, blocking_attributes:, default_shown: nil)
        children = Array(allowed).select { _1.include?(ClassComposer::Generator) }.map do |allowed_class|
          allowed_class.composer_mapping
        end

        composer_mapping[name] = {
          desc: desc,
          children: children.empty? ? nil : children,
          default: default_shown || (default.to_s.start_with?("#<") ? default.class : default),
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

          is_valid = validator.(value)

          if is_valid
            instance_variable_set(COMPOSER_ASSIGNED_ATTR_NAME.(name), true)
            instance_variable_set(:"@#{name}", value)
          else
            message = ["#{self.class}.#{name} failed validation. #{name} is expected to be #{allowed}. Received [#{value}](#{value.class})"]

            message << (params[:invalid_message].is_a?(Proc) ? params[:invalid_message].(value) : params[:invalid_message].to_s)
            raise validation_error_klass, message.compact.join(" ")
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

      # retrieve the value for the name -- Or return the default value
      def __composer_retrieval__(name:, default:, array_proc:)
        define_method(:"#{name}") do
          value = instance_variable_get(:"@#{name}")
          return value if instance_variable_get(COMPOSER_ASSIGNED_ATTR_NAME.(name))

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
