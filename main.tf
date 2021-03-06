resource "digitalocean_droplet" "csgo" {
  image    = "ubuntu-16-04-x32"
  name     = "csgo"
  region   = "fra1"
  size     = "UPDATESLUG"
  tags     = ["csgo"]
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key)
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD4KpEVb7jk0QxeMdXZrm68e8zKo1D17nd/JNoXTNAcBZsC/186N6kQlvPwwWpKYwAoFzVDuIHalok+61S1rAFEFJ0K0pTbQWnFBjZh2BfTdeCW5NL5cMkOevd6lyAvvM/85W3w4JCsrBak8pRet5WQjsjMlshsX0b88hHbYuipYik8+VjTOhtglc2ccRjjMm6i7hsb5uq/wc0UBlefbYiCpfW9SQdWQQLeNWCueJEhM7e6AFmymqvQWpcTqZrYqZLmul5YppjwBIav8E49Fy5fwZyi64tMaLCfuoB2Ap30FhRZz5rCsBy+K3CGU1cvdWOIrUy/8bduJlA398gXnSCF bozovic@rs1lxl-109541' >> /root/.ssh/authorized_keys"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update -y",
      "apt-get install -y gcc-multilib libstdc++6 libgcc1 zlib1g libncurses5 libc6 wget screen",
      "mkdir /opt/csgo",
      "cd /opt/csgo",
      "wget http://media.steampowered.com/client/steamcmd_linux.tar.gz",
      "tar xfv steamcmd_linux.tar.gz",
      "./steamcmd.sh +login anonymous +force_install_dir ./server/ +app_update 740 validate +quit",
      "useradd -m csgo",
      "chown csgo /opt/csgo/ -R"
    ]
  }

  provisioner "file" {
    source      = "csgo/server.cfg"
    destination = "/opt/csgo/server/csgo/cfg/server.cfg"
  }

  provisioner "file" {
    source      = "csgo/gamemode_casual.cfg"
    destination = "/opt/csgo/server/csgo/cfg/gamemode_casual.cfg"
  }

  provisioner "file" {
    source      = "csgo/gamemode_armsrace.cfg"
    destination = "/opt/csgo/server/csgo/cfg/gamemode_armsrace.cfg"
  }

  provisioner "file" {
    source      = "csgo/gamemodes_server.txt"
    destination = "/opt/csgo/server/csgo/cfg/gamemodes_server.txt"
  }

  provisioner "file" {
    source      = "csgo/csgo.service"
    destination = "/lib/systemd/system/csgo.service"
  }

  provisioner "file" {
    source      = "update_csgo_unit_file_with_ip.sh"
    destination = "/opt/csgo/update_csgo_unit_file_with_ip.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/csgo/update_csgo_unit_file_with_ip.sh",
      "/opt/csgo/update_csgo_unit_file_with_ip.sh",
      "systemctl daemon-reload",
      "systemctl enable csgo.service",
      "systemctl start csgo.service"
    ]
  }

  provisioner "local-exec" {
    command = "./mapdns"
  }

}

