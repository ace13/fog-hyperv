# frozen_string_literal: true

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
        self.class.respond_to?(:lazy_attributes) ? self.class.lazy_attributes : []
      end

      def dirty?
        attributes.reject do |k, v|
          !self.class.attributes.include?(k) || lazy_attributes.include?(k) || (old ? old.attributes[k] == v : false)
        end.any?
      end

      def parent
        return @interface if @interface
        return @vm if @vm
        return @computer if @computer
        return @cluster if @cluster
        return nil unless collection
        return collection.vm if collection.attributes.include? :vm
        return collection.computer if collection.attributes.include? :computer

        @parent ||= begin
          r = service.servers.get vm_name if attributes.include? :vm_name
          r = service.hosts.get computer_name if attributes.include? :computer_name
          r
        end
      end

      def interface
        return unless @interface || respond_to?(:vm_network_adapter_name) && vm_network_adapter_name

        @interface ||= service.network_adapters.get vm_network_adapter_name, vm_name: vm_name
      end
      alias network_adapter interface

      def vm
        return unless respond_to?(:vm_name) && vm_name

        @vm ||= service.servers.get vm_name
      end

      def computer
        return unless @computer || (respond_to?(:computer_name) && computer_name)

        @computer ||= service.hosts.get computer_name
      end

      def cluster
        return unless @cluster || (respond_to?(:cluster_name) && cluster_name)

        @cluster ||= service.clusters.get cluster_name
      end

      private

      def logger
        service.logger
      end

      def clear_lazy
        lazy_attributes.each do |attr|
          attributes[attr] = nil
        end
      end

      def changed?(attr)
        attributes.reject do |k, v|
          !self.class.attributes.include?(k) || lazy_attributes.include?(k) || (old ? old.attributes[k] == v : true)
        end.key?(attr)
      end

      def changed!(attr)
        changed?(attr) ? attributes[attr] : nil
      end

      def old
        @old ||= (persisted? ? dup.reload : nil)
      end
    end

    class Model < Fog::Model
      extend Fog::Hyperv::ModelExtends
      include Fog::Hyperv::ModelIncludes

      def initialize(attributes = {})
        super

        @old = dup if persisted?
      end
    end
  end
end
