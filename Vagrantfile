# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = "bootpress"
  config.vm.box = "hashicorp/precise32"
  config.vm.provision :shell, :path => "bin/once.sh"
  config.vm.provision :shell, :path => "bin/travis.sh", privileged: false, args: "wp_test root password localhost"
  config.vm.provision :shell, :path => "bin/always.sh", run: "always"
  config.vm.network :private_network, type: :dhcp
  config.vm.synced_folder ".", "/var/www/wp-content/plugins/bootpress-plugin", owner: "www-data", group: "www-data"
end
