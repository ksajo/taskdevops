# -*- mode: ruby -*-
# vi: set ft=ruby :

# ARRAY APP VM
vmsrvs=[
  {
    :hostname => "dbapp",
    :ip => "192.168.1.16",
    :cpu => "2",
    :ram => 1024,
    :file => ""
  },
  {
    :hostname => "webapp",
    :ip => "192.168.1.15",
    :cpu => "2",
    :ram => 1024,
    :file => "cfg_files.tgz"
  }
]

# MAIN CONFIG
Vagrant.configure(2) do |config|
    # DISABLE DEFAULT SHARE FOLDER
    config.vm.synced_folder ".", "/vagrant", disabled: true

    # CONFIGURE EACH VM IN ARRAY
    vmsrvs.each do |machine|
        config.vm.define machine[:hostname] do |node|
            # CREATE VM FROM IMAGE BOX
            node.vm.box = "centos/8"

            # PORTS RANGE FOR VM BY 127.0.0.1
            node.vm.usable_port_range = (2200..2250)

            # SET HOSTNAME OS VM
            node.vm.hostname = machine[:hostname]

            # VM LAN CONFIGURE
            node.vm.network "public_network", ip: machine[:ip]

            # DETAILS SETTINGS VM
            node.vm.provider "virtualbox" do |vb|
                # NAME
                vb.name = machine[:hostname]

                # RAM
                vb.memory = machine[:ram]

                #CPU
                vb.cpus = machine[:cpu]

            end

            node.vm.provision "file", source: "./webapp_settings.conf", destination: "/tmp/webapp_settings.conf"
            node.vm.provision "file", source: machine[:file], destination: "/tmp/"+machine[:file]
            node.vm.provision "shell", path: "init_"+machine[:hostname]+"_service.sh"
         end
     end
end
