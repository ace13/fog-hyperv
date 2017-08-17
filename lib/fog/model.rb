module Fog
  module Hyperv
    module ModelExtends
      def lazy_attributes(*attrs)
        @lazy_attributes ||= []
        @lazy_attributes += attrs.map(&:to_s).map(&:to_sym)
      end
    end

    module ModelIncludes
      def lazy_attributes
        if self.class.respond_to? :lazy_attributes
          self.class.lazy_attributes
        else
          []
        end
      end

      def dirty?
        attributes.reject { |k, v| !self.class.attributes.include?(k) || lazy_attributes.include?(k) || old.attributes[k] == v }.any?
      end

      def parent
        return nil unless collection
        return collection.vm if collection.attributes.include? :vm
        return collection.computer if collection.attributes.include? :computer
        @parent ||= begin
          r = service.servers.get vm_name if attributes.include? :vm_name
          r = service.hosts.get computer_name if attributes.include? :computer_name
          r
        end
      end

      private

      def clear_lazy
        lazy_attributes.each do |attr|
          attributes[attr] = nil
        end
      end

      def changed?(attr)
        attributes.reject { |k, v| !self.class.attributes.include?(k) || lazy_attributes.include?(k) || old.attributes[k] == v }.key?(attr)
      end

      def old
        @old ||= dup.reload
      end
    end

    class Model < Fog::Model
      extend Fog::Hyperv::ModelExtends
      include Fog::Hyperv::ModelIncludes
    end
  end
end