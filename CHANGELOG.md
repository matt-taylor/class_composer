# Changelog

### Versioning

**Major:** x - Major Releases with new features that constitute a breaking change

**Minor:** x.x - Minor changes or features added which are backwards compatible

**Patch:** x.x.x - Patch Updates

# Release Notes

## v2.0.0 (Nov 2024)
- Minimum Ruby Version bumped to v3.1
- Initializer File Generator
  - Add(`desc:`) key to your configs and ClassComposer can create a Initializer for you with all options
  - Automatically will track new options added
- Options added:
  - `desc:` -- Describe what the configuration is doing. Recommended but optional
  - `default_shown:` With Config Initializer file Generation, you can add a custom value to display as the default (For example: Use this options with ENV variables or sensitive arguments)
  - `&block`: Provide a block to the composer class method. This block gets executed on assignment after validation.
- Methods Added:
  - `add_composer_blocking`(Class): Recommended composer method to use when default is another ClassComposer included class (See Readme for more details)
  - `class_composer_assign_defaults!` (Instance): Class Composer values are lazily loaded. This option allows you to load configured options by calling a method (See Readme for more details)
  - `class_composer_freeze_objects!`(Instance): Call this instance method if you want to make the instance immutable to changes. Helpful to ensure all changes are made before the application code runs (See Readme for more details)
  - `composer_generate_config`(Instance): Create the Configuration text for an initializer file. (See Readme for more details)

## v1.0.0 June 2022
- Initial Launch!
