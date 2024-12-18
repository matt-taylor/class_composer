# Add Composer

`ClassComposer` by default is a DRY way to compose configurations for a class. It provides re-usable validations to ensure variables are set correctly. It is lazily loaded by default and has some wicked options available

```ruby
require "class_composer"
class MyCoolClass
  include ClassComposer::Generator

  add_composer :status, allowed: Symbol, default: :in_progress
end
```


## Available Options:

### Allowed
- Required: Yes
- Description: This defines allowed types for this composed item. If `===` fails, it will return a runtime error
- Type: Type of allowed assignments. Or an Array of allowed assignments --

Examples:

```ruby
add_composer :status, allowed: Symbol, default: :in_progress

add_composer :status, allowed: [Symbol, String], default: :in_progress
```

### Default
- Required: False
- Description: This option allows you to set a sane default for configuration while still allowing others to overwrite the value
- Type: It _should_ be one of the `allowed` types to ensure it passes validation

Examples
```ruby
add_composer :status, allowed: Symbol, default: :different_default

add_composer :status, allowed: Symbol, default: "This type does not match Symbol. This default value will raise error"
```

### Dynamic Default
- Required: False
- Description: This option allows you to set a dynamic default composed of other `add_composer` values. The `dynamic_default` is lazy loaded.
- Type: Expected value to be a Symbol mapping to another `add_composer` method or a Proc that takes an instance as an argument.
- Note: When using `dynamic_default`, validations will lazily get run on retrieval. This means that you could have a runtime error if the dynamic value is not of the correct `allowed` type.

Examples
```ruby
add_composer :app_name, allowed: Symbol, default: "My Cool App Name"

add_composer :app_name_comms, allowed: String, dynamic_default: :app_name

add_composer :app_name_website, allowed: String, dynamic_default: ->(instance) { "#{instance.app_name} + #{instance.app_name_comms}" }
```

### Description
- Required: False (Recommend)
- Description: This option provides a human readable description of what the current configuration option does. This value is useful when [Generating an Initializer](generating_initializer.md)
- Type: String

```ruby
add_composer :status, allowed: Symbol, default: :in_progress, desc: "This config value is the current status for the entity."
```


### Default Shown
- Required: False (Recommend)
- Description: This option is helpful when the `default` value is a class or retrieved from an ENV variable. It will overload the `default` value when [Generating an Initializer](generating_initializer.md)
- Type: String

```ruby
add_composer :status, allowed: Symbol, default: :in_progress, desc: "This config value is the current status for the entity.", default_shown: "completed"
```

### Provide a Block
- Required: False
- Description: The optional block will get executed after all validations have completed successful. This is a valuable option when you need to do a secondary action after the value is assigned/changed.
- Type: Proc that accepts (`key`, `value`)

```ruby
BLOCK = Proc.new do |key, value|
  User.send_mail("Your Status has changed to #{key}")
end

add_composer :status, allowed: Symbol, default: :in_progress, desc: "This config value is the current status for the entity.", default_shown: "completed", &BLOCK
```

### Validator
- Required: False
- Description: This option provides additional validation to do on the item during assignment.
- Type: Proc that returns a truthy or falsey value. Truthy response will pass validation. Falsey response will fail validation and raise a runtime error
- Default: `->(_) { true }`

Examples:
```ruby
add_composer :status, allowed: Symbol, default: :in_progress, validator: ->(value) { [:backlog,:in_progress, :complete].include?(value) }
```

### Invalid Message
- Required: False (Recommended with `validator`)
- Description: When provided, you can add a custom validation message to the runtime error. Recommended when `validator` is provided
- Type: Proc that returns a string to add to validation message

Examples:
```ruby
ALLOWED = [:backlog,:in_progress, :complete]
add_composer :status, allowed: Symbol, default: :in_progress, validator: ->(value) { ALLOWED.include?(value) }, invalid_message: ->(value) { "Value must be one of #{ALLOWED}" }
```

### Validation Error Class
- Required False
- Description: The default error to raise when validation fails.
- Default: `ClassComposer::ValidatorError`
- Type: Class that has `StandardError` Ancestor

### Error Class
- Required: False
- Description: The default error class to raise when errors outside of ClassComposer occur. EG during custom validation
- Default: `ClassComposer::Error`
- Type: Class that has `StandardError` ancestor

Examples:
```ruby
ALLOWED = [:backlog,:in_progress, :complete]
add_composer :status, allowed: Symbol, default: :in_progress, validator: ->(value) { UNDEFINED_VARIABLE.include?(value) } validation_error_klass: Exception
# Will raise with `Exception`
```

---

To see some complete Examples, visit [Basic Composer Example](basic_composer_example,md)

