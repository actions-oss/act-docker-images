packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "image" {
  type    = string
  default = "ubuntu:24.04"
}

variable "commit" {
  type    = bool
  default = false
}

source "docker" "container" {
  commit      = var.commit
  discard     = !var.commit
  pull        = true
  run_command = ["-d", "-i", "-t", "--name", "${source.name}", "{{ .Image }}"]
}

build {
  name = "act-minimal"

  source "docker.container" {
    name  = "ubuntu20"
    image = "ubuntu:20.04"
  }
  source "docker.container" {
    name  = "ubuntu22"
    image = "ubuntu:22.04"
  }
  source "docker.container" {
    name  = "ubuntu24"
    image = "ubuntu:24.04"
  }
  source "docker.container" {
    name  = "fedora42"
    image = "fedora:42"
  }
  source "docker.container" {
    name  = "alpine3"
    image = "alpine:3"
  }

  sources = ["source.docker.container", ]

  provisioner "shell" {
    only = [
      "docker.ubuntu20",
      "docker.ubuntu22",
      "docker.ubuntu24",
    ]
    env = {
      DEBIAN_FRONTEND = "noninteractive",
      TERM            = "dumb",
    }
    inline = [
      "printf '%s\n' 'tzdata tzdata/Areas select Etc' 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections",
      "apt-get -yq update",
      "apt-get -yq --no-install-recommends install ansible",
    ]
  }

  provisioner "shell" {
    only = [
      "docker.fedora42",
    ]
    env = {
      TERM = "dumb",
    }
    inline = [
      "dnf -y update",
      "dnf -y install ansible",
    ]
  }

  provisioner "shell" {
    only = [
      "docker.alpine3",
    ]
    env = {
      TERM = "dumb",
    }
    inline = [
      "apk add -Uul ansible",
    ]
  }

  provisioner "ansible" {
    playbook_file = "./playbook.yaml"
    user          = "root"
    extra_arguments = [
      "-vvv",
      "--extra-vars",
      "ansible_host=${source.name} ansible_connection=docker"
    ]
  }
}
