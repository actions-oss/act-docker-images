variable "PUSH" {
  default = false
}

variable "RELEASE" {
  default = false
}

variable "OWNER" {
  default = "actions-oss"
}

variable "GIT_REPO" {
  default = "actions-oss/act-docker-images"
}

variable "UBUNTU_LATEST_VERSION" {
  default = "24.04"
}

variable "DEV_BUILD" {
  default = true
}

variable "DOCKER_USER" {}

variable "namespaces" {
  default = flatten([
    "ghcr.io/actions-oss",
    DOCKER_USER != "" ? ["docker.io/actionsoss"] : [],
  ])
}

target "default" {}

function "full_image" {
  params = [version]
  result = "ghcr.io/christopherhx/runner-images:ubuntu${version}-runner-large-latest"
}

function "runner_tag" {
  params = [user]
  result = user == "root" ? "" : "-runner"
}

function "dev_build" {
  params = []
  result = DEV_BUILD ? "dev" : formatdate("YYYYMMDD", timestamp())
}

function "format_tag" {
  params = [tag, version, type, runner]
  result = UBUNTU_LATEST_VERSION == version ? "${tag}:${type}-latest${runner_tag()}-${dev_build()}" : "${tag}:${type}-${tag}${runner_tag()}-${dev_build()}"
}

function "get_platform" {
  params = [platform]
  result = length(split("/", platform)) == 2 ? split("/", platform)[1] : format("%s%s", split("/", platform)[1], split("/", platform)[2])
}

target "ubuntu" {
  dockerfile = "./ubuntu/Dockerfile"
  context    = "."
  ulimits    = ["nofile=4096:4096"]

  args = {
    BUILD_DISTRO      = "ubuntu"
    BUILD_DATE        = formatdate("YYYY-MM-DD hh:mm:ssZ", timestamp())
    BUILD_OWNER       = OWNER
    BUILD_REPO        = GIT_REPO
    BUILD_TAG_VERSION = dev_build()
    BUILD_REF         = ""
  }
}

target "act" {
  inherits = ["ubuntu"]

  name = "act-${sanitize(version)}-${runner}-${sanitize(platform)}"
  matrix = {
    version   = ["24.04", "22.04", "20.04"]
    platform  = ["linux/amd64/v3", "linux/arm/v7", "linux/arm64/v8"]
    runner    = ["root", "runner"]
  }
  platforms = [platform]
  args = {
    MANIFEST_TAG        = "ubuntu-${version}"
    MANIFEST_LATEST_TAG = "ubuntu-latest"
    MANIFEST_BUILD_TAG  = "ubuntu-${version}"

    BUILD_TYPE        = "act"
    BUILD_RUNNER_USER = runner

    FROM_IMAGE_NAME = "buildpack-deps"
    FROM_IMAGE_TAG  = version

  }
  output = ["type=image,push=${PUSH}"]
  tags = flatten([for namespace in namespaces : [
    ["${namespace}:ubuntu-${version}${runner_tag(runner)}-${dev_build()}-${get_platform(platform)}"],
    RELEASE == true ? ["${namespace}:ubuntu-${version}${runner_tag(runner)}-${dev_build()}-${get_platform(platform)}"] : [],
  ]])
}

target "copy_full" {
  dockerfile-inline = "FROM source"

  name        = "copy_full_${sanitize(version.name)}_${sanitize(namespace)}"
  description = "Copy full GHA runner image to own account"
  output      = ["type=image,push=${PUSH}"]
  no-cache    = true

  matrix = {
    namespace = ["ghcr.io/actions-oss", "docker.io/actionsoss"]
    version = [
      { major = 24, full = "24.04", name = "latest" },
      { major = 24, full = "24.04", name = "24.04" },
      { major = 22, full = "22.04", name = "22.04" },
      { major = 20, full = "20.04", name = "20.04" },
    ]
  }
  contexts = {
    source = "docker-image://${full_image(version.major)}"
  }
  tags = ["${namespace}/act-full:ubuntu-${version.name}"]
  args = {
    source = full_image(version.major)
    target = "ubuntu-${version.name}"
  }
}
