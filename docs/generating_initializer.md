# Generating Initializer

Generating an initializer can help ensure that all users understand all potential configuration options without searching the codebase.

This generation will add both [Basic Composer Options](basic_composer.md) and [Composer Blocking Options](composer_blocking.md) to a configuration file.

The file output will show show assignment to all default values. Additionally all lines are commented out so the User can


```ruby
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

  add_composer :login, allowed: LoginStrategy, default: LoginStrategy.new, desc: "Login Strategy for my Application"

  add_composer_blocking :lockable, composer_class: LockableStrategy, enable_attr: :enable, desc: "Lock Strategy for my Application. By default this is disabled"
end

puts AppConfiguration.composer_generate_config(wrapping: "MyApplication.configure")

----

=begin
This configuration files lists all the configuration options available.
To change the default value, uncomment the line and change the value.
Please take note: Values set as `=` to a config variable are the current default values when none is assigned
=end

MyApplication.configure do |config|
  # ### Block to configure Login ###
  # Login Strategy for my Application
  # config.with_login do |login_config|
    # Password must include valid characters between 6 and 20 in length: [Regexp]
    # login_config.password_regex = (?-mix:\A\w{6,20}\z)

    # login_config.username_length = 10

    # login_config.type = "plain_text"
  # end

  # ### Block to configure Lockable ###
  # Lock Strategy for my Application. By default this is disabled
  # When using the block, the enable flag will automatically get set to true
  # config.with_lockable do |lockable_config|
    # By default Lockable Strategy is disabled.: [TrueClass, FalseClass]
    # lockable_config.enable = false

    # Max password attempts before the account is locked: [Integer]
    # lockable_config.password_attempts = 10
  # end
end
```

## Usage Applications
### Rails Generator
Are you building an Engine or a Gem that requires custom configuration. This code can easily help downstream users understand exactly what options are available to them to configure your Engine/Gem.

