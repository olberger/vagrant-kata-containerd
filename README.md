# Vagrant running k8s with KataContainers on Ubuntu 16.04 with containerd

Install KataContainers in a k8s cluster, with containerd and CRI.

Attention, we don't deploy kata runtime from Ubuntu packages to
simplify integration with containerd, and use the instructions from
the KataContainers packaging project.

For setting it up, you will need,

- VirtualBox (Currently only tested with virtualbox)
- Vagrant with following plugins
  - vagrant-vbguest
  - vagrant-hostmanager
  - vagrant-share
  - vagrant-reload (handles reboot during provisionning)

To Install the plugins, use following command,

vagrant plugin install &lt;plugin-name&gt;

The setup instructions are simple, once you have installed the prereqs, clone the repo

```
git clone https://github.com/olberger/vagrant-kata-dev
```

Edit the Vagrantfile to update details

1. Update the bridge interface so the box will have IP address from your local network using DHCP. If you do not update, it will ask for the interface name you start machine.

Create the vagrant box with following command

``` vagrant up ```

Once the box is started, login to the box using following command

``` vagrant ssh ```

Switch to root user and move to vagrant shared directory and install the setup script

```

```
# docker info | grep Runtime
WARNING: No swap limit support
Runtimes: kata-runtime runc
Default Runtime: runc
```
