# frozen_string_literal: true

module ClassComposer
  class GenerateConfig
    attr_reader :instance
    NOTICE = <<~HEREDOC
    =begin
    This configuration files lists all the configuration options available.
    To change the default value, uncomment the line and change the value.
    Please take note: Values set as `=` to a config variable are the current default values when none is assigned
    =end
    HEREDOC

    def initialize(instance:)
      raise ArgumentError, ":instance class (#{instance}) must include ClassComposer::Generator. It does not" unless instance.include?(ClassComposer::Generator)

      @instance = instance
    end

    def execute(wrapping:, require_file:, space_count: 1, config_name: "config")
      mapping = instance.composer_mapping
      generated_config = generate(mapping:, space_count:, demeters_deep:[config_name])

      stringified = ""
      stringified += "require \"#{require_file}\"\n\n" if require_file
      stringified += NOTICE
      stringified += "\n"
      stringified += "#{wrapping} do |#{config_name}|\n"
      flattened_config = generated_config.flatten(1).map { _1.join(" ") }
      flattened_config.pop if flattened_config[-1] == ""

      stringified += flattened_config.join("\n")
      stringified += "\nend"
      stringified
    end

    private

    def generate(mapping:, space_count:, demeters_deep:)
      mapping.map do |key, metadata|
        if blocking_attributes = metadata[:blocking_attributes]
          if children = metadata[:children]
            do_block = "#{key}_config"
            blocking(key:, do_block:, metadata:, space_count:, demeters_deep:, blocking_attributes:) do
              generate(mapping: children.first, space_count: space_count + 2, demeters_deep: [do_block])
            end
          else
            []
          end
        elsif children = metadata[:children]
          config_prepend = demeters_deep + [key]
          children_config = []
          if desc = metadata[:desc]
            children_config << spec_child_description(space_count:, desc:, key:)
          end

          children.each do |child|
            children_config += generate(mapping: child, space_count:, demeters_deep: config_prepend)
          end

          children_config.flatten(1)
        else
          spec(key:, metadata:, space_count:, demeters_deep:)
        end
      end
    end

    def spec_child_description(space_count:, desc:, key:)
      base = "#########"
      length = base.length * 2 + 4 + key.capitalize.length

      [
        [prepending(space_count),"#" * length],
        [prepending(space_count),"##{" " * (length - 2)}#" ],
        [prepending(space_count), "#{base}  #{key.capitalize}  #{base}"],
        [prepending(space_count),"##{" " * (length - 2)}#" ],
        [prepending(space_count),"#" * length],
        [prepending(space_count), "## #{desc}"],
        [],
      ]
    end

    def blocking(key:, do_block:, metadata:, space_count:, demeters_deep:, blocking_attributes:)
      config = concat_demeter_with_key(blocking_attributes[:block_name], demeters_deep)
      values = [
        [prepending(space_count), "### Block to configure #{key.to_s.split("_").map {_1.capitalize}.join(" ")} ###"],
        [prepending(space_count), metadata[:desc]],
      ]
      values << [prepending(space_count), "When using the block, the #{blocking_attributes[:enable_attr]} flag will automatically get set to true"] if blocking_attributes[:enable_attr]
      values << [prepending(space_count), config, "do", "|#{do_block}|"]

      values += yield.flatten(1)
      values.pop if values[-1] == [""]
      values << [prepending(space_count), "end"]

      values << [""]
    end

    def spec(key:, metadata:, space_count:, demeters_deep:)
      config = concat_demeter_with_key(key, demeters_deep)

      if metadata[:default_shown]
         default = metadata[:default_shown]
      elsif metadata[:dynamic_default]
        if Symbol === metadata[:dynamic_default]
          default = concat_demeter_with_key(metadata[:dynamic_default], demeters_deep)
        else
          default = " # Proc provided for :dynamic_default parameter. :default_shown parameter not provided"
        end
      elsif metadata[:allowed].include?(String)
        default = "\"#{metadata[:default]}\""
      else
        default = custom_case(metadata[:default])
      end
      arr = []

      arr << [prepending(space_count), "#{metadata[:desc]}: #{(metadata[:allowed] - [ClassComposer::DefaultObject])}"] if metadata[:desc]
      arr <<[prepending(space_count), config, "=", default]
      arr << [""]

      arr
    end

    def custom_case(default)
      case default
      when Symbol
        default.inspect
      when (ActiveSupport::Duration rescue NilClass)
        default.inspect.gsub(" ", ".")
      else
        default
      end
    end

    def prepending(space_count)
      "#{" " * space_count}#"
    end

    def concat_demeter_with_key(key, demeters_deep)
      (demeters_deep + ["#{key}"]).join(".")
    end
  end
end
