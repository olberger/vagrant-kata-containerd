# -*- mode: ruby -*-
# vi: set ft=ruby :

#BOX_IMAGE = "ubuntu/xenial64"
BOX_IMAGE = "ubuntu/bionic64"
HOSTNAME = "kata-containerd-cri"

# Change this to adjust to your host's devices
#BRIDGE_IF = "enp6s0"
#BRIDGE_IF = "wlp5s0"
BRIDGE_IF = "wlp2s0"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = BOX_IMAGE
  config.vm.box_check_update = false
  config.vbguest.auto_update = false
  config.vm.hostname = HOSTNAME 
  config.hostmanager.enabled = true
  config.hostmanager.manage_guest = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  config.hostmanager.ip_resolver = proc do |machine|
    result = ""
    machine.communicate.execute("hostname -I | cut -d ' ' -f 2") do |type, data|
      result << data if type == :stdout
    end
    ip = result.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network "public_network", type: "dhcp", :bridge => BRIDGE_IF
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
    #   # Customize the amount of memory on the VM:
    # You may choose different values but qemu for kata-containers will need some RAM
    vb.memory = "4096"
    vb.cpus = "2"
    # Activate nested virtualization support if you have an intel processor, which will be helpfull for qemu/kvm inside the VM
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    # I had to disable IPv6, but this may be useless for others
    echo  "Disabling IPv6"
    echo "net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    net.ipv6.conf.lo.disable_ipv6 = 1
    net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p

    # Install base tools that will be needed later
    apt-get -y install apt-transport-https ca-certificates wget software-properties-common

    # Update to latest Ubuntu packages
    apt-get update && apt-get -y full-upgrade 
  SHELL

  # Then reboot the VM
  config.vm.provision :reload

  # Now the provisionning of the cluster

  # First install Docker
  config.vm.provision "shell", path: "docker.sh", privileged: false

  # Then make sure containerd is installed properly
  config.vm.provision "shell", path: "containerd.sh", privileged: false

  # Install Kubernetes
  config.vm.provision "shell", path: "kubernetes.sh", privileged: false

  # Install a CNI network component (others may fit ?)
  config.vm.provision "shell", path: "calico.sh", privileged: false

  # Finally install KataContainers
  config.vm.provision "shell", path: "kata.sh", privileged: false 
end
