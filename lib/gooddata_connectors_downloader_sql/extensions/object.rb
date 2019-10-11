# encoding: utf-8

class Object
  class << self
    def class_from_string(class_name)
      raise ArgumentError if class_name.nil? || class_name.empty?
      raise ArgumentError unless class_name.is_a?(String)

      class_name.split('::').inject(Object) { |a, e| a.const_get e }
    end
  end
end
