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

### Basic Add Composer

`add_composer` is the driving method behind the composer gem. It will
- Add a setter Method
- Add a getter Method
- Add instance variable
- Add validation Method

In short, Composer will behave similarly to `attr_accessor`

Check out [Basic Composer](docs/basic_composer.md) for usage details

### Usage with Arrays

Composer allows interactions with arrays in a native way. When the allowed type is `Array`, ClassComposer will add a custom method `<<` to overwrite the native Array method. This ensures that ClassComposer Validations run when adding to the Array.

For more information, check out [Array Usage](docs/array_usage.md)

### Freezing Objects

Sometimes you want freeze an instance of a Configuration. Freezing it will make it immutable from changes Users may try to make.

For more information, check out [Freezing Class Composer Instances](docs/freezing.md)

### Complex usage: Composer Blocking

Composer blocking builds on top of the [Basic Composer](docs/basic_composer.md) to help with nested Configurations that include `ClassCompser::Generator`.
Nested configuration's allow complex configurations for entire projects to work seamlessly together.

For Examples and use cases, check out [Composer Blocking](docs/composer_blocking.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/matt-taylor/class_composer.

