# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vm.synced_folder ".", "/vagrant"
  config.vm.synced_folder ".", "/usr/local/bootstrap"
  config.vm.hostname = "allthingscloud.eu"
  config.vm.provision "shell", inline: "/usr/local/bootstrap/scripts/install_openldap.sh", run: "always"
  config.vm.network "private_network", ip: "192.168.15.11"
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_version = "20200505.0.0"


end
