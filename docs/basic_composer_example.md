```ruby
require 'class_composer'

class MyConfigurableClass
  include ClassComposer::Generator

  ALLOWED_FIBONACCI = [0, 2, 8, 13, 34]

  add_composer :status, allowed: Integer, default: 35
  add_composer :number, allowed: Integer, default: 0, validator: -> (val) { val < 50 }
  # when no default is provided, nil will be returned
  add_composer :fibbonacci, allowed: Array, validator: ->(val) { val.all? {|i| i.is_a?(Integer) } && val.all? { |i| ALLOWED_FIBONACCI.include?(i) } }, invalid_message: ->(val) { "We only allow #{ALLOWED_FIBONACCI} numbers. Received #{val}" }
  # Allowed can be passed an array of allowed class types
  add_composer :type, allowed: [Proc, Integer], default: 35
end

instance = MyConfigurableClass.new
instance.type
=> 35
instance.number = 75
ClassComposer::ValidatorError: MyConfigurableClass.number failed validation. number is expected to be Integer.
from /gem/lib/class_composer/generator.rb:71:in `block in __composer_assignment__`
instance.number = 15
=> 15
instance.number
=> 15
instance.fibbonacci
=> nil
instance.fibbonacci = [1,2,3]
ClassComposer::ValidatorError: MyConfigurableClass.fibbonacci failed validation. fibbonacci is expected to be [Array]. We only allow [0, 2, 8, 13, 34] numbers. Received [1, 2, 3]
from /gem/lib/class_composer/generator.rb:71:in `block in __composer_assignment__`
instance.fibbonacci = [0,13,34]
=> [0, 13, 34]
instance.fibbonacci
=> [0, 13, 34]
