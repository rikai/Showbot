BASE_BOX = "centos/7"
MACHINE_IP = "192.168.65.2"
VM_MEMORY = 2048
VM_CPU = 2

Vagrant.configure("2") do |config|
  config.vm.box = BASE_BOX
  config.vm.hostname = "jbotprime"
  config.vm.network :private_network, ip: MACHINE_IP

  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = VM_MEMORY
    libvirt.cpus = VM_CPU
  end

  config.vm.synced_folder ".", "/home/vagrant/jbot", :type => "sshfs"
  config.vm.provision :shell, :path => "vagrant-scripts/provision.sh",
    :env => {MACHINE_IP: MACHINE_IP}
end
