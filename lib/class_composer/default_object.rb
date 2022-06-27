# frozen_string_literal: true

require "class_composer/version"

# This is to add a falsey like default behavior
# When default value is not passed in let this be an allowed value
# This is intended to eventually be configurable

module ClassComposer
  module DefaultObject
    module_function

    def value
      nil
    end
  end
end
