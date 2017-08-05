module Fog
  module Compute
    class Hyperv
      class Volumes < Fog::Collection
        autoload :Volume, File.expand_path('../volume', __FILE__)

        attr_accessor :computer_name
        attr_accessor :vm_name

        model Fog::Compute::Hyperv::Volume

        def all(filters = {})
          load service.get_vm_hard_disk_drive({
            computer_name: computer_name,
            vm_name: vm_name,
          }.merge filters)
        end

        def get(filters = {})
          # TODO: Validation?
          #
          # uint ControllerNumber
          # uint ControllerLocation
          # enum [:IDE, :SCSI, :FLOPPY] ControllerType
          new service.get_vm_hard_disk_drive({
            vm_name: id,
            computer_name: computer_name
          }.merge filters)
        end

        def new(options = {})
          super({
            computer_name: computer_name,
            vm_name: vm_name
          }.merge(options))
        end
      end
    end
  end
end
