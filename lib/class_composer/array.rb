# frozen_string_literal: true

module ClassComposer
  class Array
    def initialize(validator)
      @validator = validator
      super
    end

    def <<
      value = super



      value
    end
  end
end
