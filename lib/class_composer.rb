# frozen_string_literal: true

require "class_composer/version"
require "class_composer/generator"

module ClassComposer
  class Error < StandardError; end
  class ValidatorError < Error; end
end
