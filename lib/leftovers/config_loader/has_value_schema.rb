# frozen_string_literal: true

module Leftovers
  class ConfigLoader
    class HasValueSchema < ValueOrObjectSchema
      inherit_attributes_from StringPatternSchema, except: :unless

      attribute :at, ValueOrArraySchema[ArgumentPositionSchema], require_group: :matcher
      attribute :has_value, ValueOrArraySchema[HasValueSchema], require_group: :matcher

      attribute :has_receiver, ValueOrArraySchema[HasValueSchema], require_group: :matcher
      attribute :type, ValueOrArraySchema[ValueTypeSchema], require_group: :matcher
      attribute :unless, ValueOrArraySchema[HasValueSchema], require_group: :matcher

      self.or_value_schema = ScalarValueSchema
    end
  end
end
