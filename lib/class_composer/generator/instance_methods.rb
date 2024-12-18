# frozen_string_literal: true

module ClassComposer
  module Generator
    module InstanceMethods
      def class_composer_frozen!(key)
        # when nil, we allow changes to the instance methods
        return if @class_composer_frozen.nil?

        # When frozen is a proc, we let the user decide how to handle
        # The return value decides if the value can be changed or not
        if Proc === @class_composer_frozen
          return @class_composer_frozen.(self, key)
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
  end
end
