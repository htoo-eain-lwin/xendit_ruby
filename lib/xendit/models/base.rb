module Xendit
  module Models
    class Base
      def initialize(attributes = {})
        @attributes = attributes.transform_keys(&:to_s)
        initialize_attributes
      end

      def to_h
        @attributes.dup
      end

      def to_json(*args)
        MultiJson.dump(to_h, *args)
      end

      def ==(other)
        other.is_a?(self.class) && to_h == other.to_h
      end

      def [](key)
        @attributes[key.to_s]
      end

      def []=(key, value)
        @attributes[key.to_s] = value
      end

      private

      def initialize_attributes
        # Override in subclasses to define attribute accessors
      end

      def define_attribute(name)
        define_singleton_method(name) { @attributes[name.to_s] }
        define_singleton_method("#{name}=") { |value| @attributes[name.to_s] = value }
      end
    end
  end
end
