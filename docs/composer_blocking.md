# Composer Blocking

Composer Blocking enhances nested configuration's that utilize `ClassComposer::Generator`. It is a method that provides additional validations and usability.

Basic Example:
```ruby
require "class_composer"

class LoginStrategy
  include ClassComposer::Generator

  add_composer :password_regex, allowed: Regexp, default: /\A\w{6,20}\z/, desc: "Password must include valid characters between 6 and 20 in length"

  add_composer :username_length, allowed: Integer, default: 10

  add_composer :type, allowed: String, default: "plain_text"
end

class LockableStrategy
  include ClassComposer::Generator

  add_composer :enable, default: false, allowed: [TrueClass, FalseClass], desc: "By default Lockable Strategy is disabled."
  add_composer :password_attempts, default: 10, allowed: Integer, desc: "Max password attempts before the account is locked"
end

class AppConfiguration
  include ClassComposer::Generator

  add_composer_blocking :login, composer_class: LoginStrategy, desc: "Login Strategy for my Application"

  add_composer_blocking :lockable, composer_class: LockableStrategy, enable_attr: :enable, desc: "Lock Strategy for my Application. By default this is disabled"
end

instance = AppConfiguration.new
instance.with_login! do |login|
  login.type = "oauth"
  login.username_length = 20
end
instance.login.type
=> "oauth"
instance.login.type = "plain_text"
=> "plain_text"

instance.lockable?
=> false
# Calling the block automatically enables the config when passed the `enable_attr`
instance.with_lockable! do |lock|
  lock.password_attempts = 5
end
instance.lockable?
=> true
```

## What does it produce?
### Configuration Blocking Method
Provides easy invocation for setting a nested composer configuration. By providing a block, you can easily and cleanly set your options for a specific composer item.

### Check for composer Enable
When the `enable_attr` method is provided, you can easily check if the composer instance is enabled by invoking `item_name?`. This convenience method can be used throughout the application to easily check which code paths to go down

## Allowed Options

### Composer Class
- Required: True
- Description: This is the Class object that includes `ClassComposer::Generator`. If the inclusion is missing, the method will raise an runtime error.
- Type: Class that includes `ClassComposer::Generator`

### Description
- Required: False (Recommend)
- Description: This option provides a human readable description of what the current configuration option does. This value is useful when [Generating an Initializer](generating_initializer.md)
- Type: String

### Block Prepend
- Required: False
- Description: By default, Composer Blocking prepends blocks with `with_`. This options allows you to set a custom prepended name
- Default: `with`
- Type: String or Symbol

### Enable Attr
- Required: False
- Description: When passed the `enable_attr:`, Class composer will enable the composer instance when called with a block and provide a convenience method `item_name?` to check for if the item is enabled.
- Type: String or Symbol


