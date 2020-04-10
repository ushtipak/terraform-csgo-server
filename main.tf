resource "digitalocean_droplet" "csgo" {
  image    = "ubuntu-16-04-x32"
  name     = "csgo"
  region   = "fra1"
  size     = "4gb"
  ssh_keys = ["${var.ssh_fingerprint}"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key)
    host        = self.ipv4_address
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
    source      = "csgo/autoexec.cfg"
    destination = "/opt/csgo/server/csgo/cfg/autoexec.cfg"
  }

  provisioner "file" {
    source      = "csgo/gamemode_casual.cfg"
    destination = "/opt/csgo/server/csgo/cfg/gamemode_casual.cfg"
  }

  provisioner "file" {
    source      = "csgo/csgo.service"
    destination = "/usr/lib/systemd/system/csgo.service"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable csgo.service",
      "systemctl start csgo.service"
    ]
  }

  provisioner "local-exec" {
    command = "./mapdns"
  }

}

