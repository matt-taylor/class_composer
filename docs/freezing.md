# Freezing ClassComposer

`ClassComposer` provides a simple way to freeze instances of its classes. Freezing can help ensure that configurations do not change during the life of the script or application.

Different behaviors are available when a user attempts to change a composed item after the instance has been frozen

## Allowed Options:
### Behavior:
- Required: When `&block` is nil, behavior is required
- Description: The behavior ClassComposer should enact when a composed item tries to get changed
- Type: Symbol [:raise, :log_and_allow, :log_and_skip]

### Children:
- Required: false
- Description: Any ClassComposed item that includes `ClassComposer::Generator` is considered a nested Child. When option set to true, We will iterate the tree and set all child instances to the same behavior as the parent. One stop shop to freeze all nested configuration
- Type: Boolean

### Block
- Required: When `behavior` is nil, block is required
- Description: Custom behavior tailored to your use case. For example, In test, maybe you raise, but production maybe you allow
- Type: Passed in block, Return `true` to allow the variable to get set. Return `false` to not allow the variable to get set


```ruby
MyCoolEngine.config.class_composer_freeze_objects!(children: true) do |instance, key|
  if Rails.staging?
    # allow the variable to get set in staging
    Rails.logger("Yikes! you are changing a config variable after boot. We will honor this")
    true
  elsif Rails.prod?
    # disallow the variable to get set in prod
    Rails.logger("Yikes! you are changing a config variable after boot. We will NOT honor this")
    false
  else
    raise Error, "Cant change value on #{instance.class} for key. Please change"
  end
end
```

## Usage

### Rails Engine
When building out a complex nested configuration structure for a Rails Engine, you may want to ensure changes to the configuration do not occur after the Rails App runs its initializers. As example code, this can get added to your `*engine.rb` file

```ruby
# MyCoolEngine.config is the location of the config instance
# Assign Defaults must get run first otherwise Lazily loaded objects will run into failure

# Run after Rails loads the initializes and environment files
# Ensures User has already set their desired config before we lock this down
initializer "my_cool_engine.config.instantiate", after: :load_config_initializers do |_app|
  # ensure defaults are instantiated and all variables are assigned
  MyCoolEngine.config.class_composer_assign_defaults!(children: true)

  # Now that we can confirm all variables are defined, freeze all objects an their children
  MyCoolEngine.config.class_composer_freeze_objects!(behavior: :raise, children: true)
end
```
