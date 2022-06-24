# frozen_string_literal: true

require "class_composer/version"

module ClassComposer
  module Generator
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      COMPOSER_VALIDATE_METHOD_NAME = ->(name) { :"__composer_#{name}_is_valid__?" }
      COMPOSER_ASSIGNED_ATTR_NAME = ->(name) { :"@__composer_#{name}_value_assigned__" }
      COMPOSER_ASSIGNED_ARRAY_METHODS = ->(name) { :"@__composer_#{name}_array_methods_set__" }

      def add_composer(name, allowed:, default: nil, accessor: true, validator: ->(_) { true }, validation_error_klass: ::ClassComposer::ValidatorError, error_klass: ::ClassComposer::Error,**params)
        validate_proc = __composer_validator_proc__(validator: validator, allowed: allowed, name: name, error_klass: error_klass)
        __composer_validate_options__!(name: name, validate_proc: validate_proc, default: default, validation_error_klass: validation_error_klass, error_klass: error_klass)

        array_proc = __composer_array_proc__(name: name, validator: validator, allowed: allowed, params: params)
        __composer_assignment__(name: name, allowed: allowed, params: params, validator: validate_proc, array_proc: array_proc, validation_error_klass: validation_error_klass, error_klass: error_klass)
        __composer_retrieval__(name: name, default: default, array_proc: array_proc)
      end

      def __composer_validate_options__!(name:, validate_proc:, default:, params: {}, validation_error_klass:, error_klass:)
        unless validate_proc.(default)
          raise validation_error_klass, "Default value [#{default}] for #{self.class}.#{name} is not valid"
        end

        if self.class.instance_methods.include?(name.to_sym)
          raise error_klass, "#{name} is already defined. Ensure composer names are all uniq and do not class with class instance methods"
        end
      end

      def __composer_array_proc__(name:, validator:, allowed:, params:)
        Proc.new do |value, _itself|
          _itself.send(:"#{name}=", value)
        end
      end

      # create assignment method for the incoming name
      def __composer_assignment__(name:, params:, allowed:, validator:, array_proc:, validation_error_klass:, error_klass:)
        define_method(:"#{name}=") do |value|
          is_valid = validator.(value)

          if is_valid
            instance_variable_set(COMPOSER_ASSIGNED_ATTR_NAME.(name), true)
            instance_variable_set(:"@#{name}", value)
          else
            value.pop if value.is_a?(Array) # we assigned the array value...pop it from the array
            message = ["#{self.class}.#{name} failed validation. #{name} is expected to be #{allowed}."]

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
          default
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
            allow && validator.(value)
          rescue StandardError => e
            raise error_klass, "#{e} occured during validation for value [#{value}]. Check custom validator for #{name}"
          end
        end
      end
    end
  end
end
