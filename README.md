# ClassComposer

Basic configuration is relatively simple but tedious to do if done multiple times. throughout a project. The intention of `ClassComposer` is to DRY up as much of that configuration as possible to allow you to just write code.

## Installation

`ClassComposer` is hosted on RubyGems https://rubygems.org/gems/class_composer

Add this line to your application's Gemfile:

```ruby
gem 'class_composer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install class_composer

## Usage

### Basic

`add_composer` is the driving method behind the composer gem. It will
- Add a setter Method
- Add a getter Method
- Add instance variable
- Add validation Method

In short, Composer will behave similarly to `attr_accessor`


```ruby
require 'class_composer'

class MyConfigurableClass
  include ClassComposer::Generator

  ALLOWED_FIBONACCI = [0, 2, 8, 13, 34]

  add_composer :status, allowed: Integer, default: 35
  add_composer :number, allowed: Integer, default: 0, validator: -> (val) {  }
  # when no default is provided, nil will be returned
  add_composer :fibbonacci, allowed: Array, validator: ->(val) { val.all? {|i| i.is_a?(Integer) } && (val - ALLOWED_FIBONACCI) > 0 }, invalid_message: ->(val) { "We only allow #{ALLOWED_FIBONACCI} numbers. Received #{val}" }
  # Allowed can be passed an array of allowed class types
  add_composer :type, allowed: [Proc, Integer], default: 35
```

### KWarg Options

```
allowed
  - Required: True
  - What: Expected value of the name of the composed method
  - Type: Array of Class types or Single Class type

validator
  - Required: False
  - What: Custom way to validate the value of the composed method
  - Type: Proc
  - Default: ->(_) { true }
  - By default validation happens on the `allowed` KWARG first and then the passed in validator function. Proc should expect that the type passed in is one of `allowed`

validation_error_klass
  - Required: false
  - What: Class to raise when a validation error occurs from `allowed` KWarg or from the passed in `validator` proc
  - Type: Class
  - Default: ClassComposer::ValidatorError

validation_error_klass
  - Required: false
  - What: Class to raise when a errors occur outside of validation. This can be for composer method errors or proc errors during validation
  - Type: Class
  - Default: ClassComposer::Error

default
  - Required: false
  - What: This is the default value to set for the composed method
  - Type: Should match the `allowed` KWarg
  - Default: nil
  - Note: When no default value is provided, the return value from the getter will be `nil`. However, this does not mean that NilClass will be an acceptable value during the setter method

invalid_message
  - Required: False
  - What: Message to add to the base invalid setter method
  - Type: Proc or String
    - Proc: ->(val) { } # where val is the failed value of the setter method

```

### Advanced

#### Usage with Array as Allowed
Arrays are treated special with the composed methods. `ClassComposer` will inject a custom method `<<` so that it can be treated as a regular array with the added benefit of validation still occuring.

```ruby
class CustomArrayClass
  include ClassComposer::Generator

  add_composer :array, allowed: Array, default: [], validator: ->(val) { val.sum < 40 }, invalid_message: ->(val) { "Array sum of [#{val.sum}] must be less than 40" }
end

instance = CustomArrayClass.new
instance.array << 1
instance.array << 2
instance.array
=> [1, 2]
instance.array << 50
ClassComposer::ValidatorError: CustomArrayClass.array failed validation. array is expected to be Array. Array sum of [53] must be less than 40

```

#### Usage with complex configuration

```ruby
class ComplexDependencies
  include ClassComposer::Generator

  add_composer :use_scope, allowed: [TrueClass, FalseClass], default: false
  add_scope :scope, allowed: Proc

  def scope
    # skip unless use_scope is explicitly set
    return -> {} unless @use_scope

    # use passed in scope if present
    # Otherwise default to blank default
    @scope || -> {}
  end
end
```
Adding custom methods allows for higher level of complexity. The methods can be used and accessed just as an `attr_accessor` would.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake rspec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment. Run `bundle exec class_composer` to use
the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version:

1. Update the version number in [lib/class_composer/version.rb]
2. Update [CHANGELOG.md]
3. Merge to the main branch. This will trigger an automatic build in CircleCI
   and push the new gem to the repo.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/matt-taylor/class_composer.

