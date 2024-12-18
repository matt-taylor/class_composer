# frozen_string_literal: true

require "class_composer/default_object"
require "class_composer/generate_config"
require "class_composer/generator/instance_methods"
require "class_composer/generator/class_methods"

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
  end
end
