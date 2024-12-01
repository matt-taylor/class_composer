# Usage with Array

For more details on basic setup, visit [Basic Composer Page](basic_composer.md)

---

Arrays are treated special with the composed methods. `ClassComposer` will inject a custom method `<<` so that it can be treated as a regular array with the added benefit of validation still occurring.


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
