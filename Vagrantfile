# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "wordpress" do |wordpress|
    wordpress.vm.box = "ubuntu/jammy64"
    wordpress.vm.box_check_update = false
    wordpress.vm.hostname = "wordpress"
    wordpress.vm.network "private_network" , ip: "192.168.105.20", nic_type: "virtio", virtualbox__intnet: "practicasysadmin"
    wordpress.vm.network "forwarded_port", guest: 80, host: 8080
    wordpress.vm.provider "virtualbox" do |vb|
      vb.name = "wordpress"
      vb.memory = "2048"
      vb.cpus = "1"
      vb.default_nic_type = "virtio"
      file_to_disk = "extradisk1.vmdk"
      unless File.exist?(file_to_disk)
        vb.customize [ "createmedium", "disk", "--filename", "extradisk1.vmdk", "--format", "vmdk", "--size", 1024 * 2 ]
      end
      vb.customize [ "storageattach", "wordpress", "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk]
    end
    #Provision:
    wordpress.vm.provision "shell", path: "wp_provision.sh"
  end

  config.vm.define "elk" do |elk|
    elk.vm.box = "ubuntu/jammy64"
    elk.vm.box_check_update = false
    elk.vm.hostname = "elk"
    elk.vm.network "private_network" , ip: "192.168.105.21", nic_type: "virtio", virtualbox__intnet: "practicasysadmin"
    elk.vm.network "forwarded_port", guest: 9200, host: 9200
    elk.vm.network "forwarded_port", guest: 5601, host: 5601
    elk.vm.provider "virtualbox" do |vb|
      vb.name = "elk"
      vb.memory = "8192"
      vb.cpus = 2
      vb.default_nic_type = "virtio"
      file_to_disk = "extradisk2.vmdk"
      unless File.exist?(file_to_disk)
        vb.customize [ "createmedium", "disk", "--filename", "extradisk2.vmdk", "--format", "vmdk", "--size", 1024 * 8 ]
      end
      vb.customize [ "storageattach", "elk", "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", file_to_disk]
    end
    #Provision:
    elk.vm.provision "shell", path: "elk_provision.sh"
  end

end
