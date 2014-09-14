# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'fileutils'
Vagrant.require_version ">= 1.6.0"
CONFIG = File.join(File.dirname(__FILE__), "config.rb")
if File.exist?(CONFIG)
  require CONFIG
else
  raise 'Missing config file! Run: cp config.rb.sample config.rb'
end
Vagrant.configure("2") do |config|
  config.vbguest.auto_update = false
  config.vm.box = "robin/wheezy64"
  if $php_version == "5.3"
    config.vm.box = "robin/ubuntu-squeeze64"
  end
  config.vm.hostname = "magego.vagrantup.com"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 1080, host: 1080
  config.vm.network "private_network", ip: "192.168.98.2"
  config.vm.provision "shell" do |s|
    if $use_local_provisioner == true
      s.path = "bin/vagrant-bootstrap.sh"
    else
      s.path = "https://raw.githubusercontent.com/robinwl/magego/master/bin/vagrant-bootstrap.sh"
    end
    if $sample_data == true
      s.args = "true"
    else
      s.args = "false"
    end
  end
  config.vm.provider "virtualbox" do |vb|
    #vb.name = "magego"
    #vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2", "--ioapic", "on"]
  end
end
