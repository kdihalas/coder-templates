terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.0"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Your project ID."
  default = "18c11c98-524d-42af-a83a-0edc32e5d517"
}

variable "size" {
  type = string
  description = "Size of the Dev instance"
  default = "DEV1-S"

  validation {
    condition     = contains(["DEV1-S","DEV1-M","DEV1-L","DEV1-XL"], var.size)
    error_message = "Value must be DEV1-S, DEV1-M, DEV1-L or DEV1-XL"
  }
}

provider "scaleway" {
  zone = "nl-ams-2"
  region = "nl-ams"
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = "/home/${data.coder_workspace.me.owner}"

  startup_script = <<EOF
    #!/bin/sh
    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh
    code-server --auth none --port 13337
    EOF

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/${data.coder_workspace.me.owner}"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "scaleway_instance_ip" "public_ip" {
  project_id = var.project_id
}

resource "scaleway_instance_server" "dev" {
  project_id = var.project_id
  type       = var.size
  image      = "ubuntu_jammy"

  tags = ["dev", "coder"]

  ip_id = scaleway_instance_ip.public_ip.id

  user_data = {
    cloud-init = templatefile("cloud-config.yaml.tftpl", {
      username          = data.coder_workspace.me.owner
      init_script       = base64encode(coder_agent.main.init_script)
      coder_agent_token = coder_agent.main.token
    })
  }
}

resource "coder_metadata" "instance" {
  resource_id = scaleway_instance_server.dev.id

  item {
    key = "Public IP"
    value = scaleway_instance_server.dev.public_ip
  }

  item {
    key = "Public IPV6"
    value = scaleway_instance_server.dev.ipv6_address
  }

  item {
    key = "Size"
    value = var.size
  }

  item {
    key = "dir"
    value = "/home/${data.coder_workspace.me.owner}"
  }
}