#!/usr/bin/bash
# shellcheck disable=SC2174

set -Eeuxo pipefail

# Remove '"' so it can be sourced by sh/bash
sed 's|"||g' -i "/etc/environment"

. /etc/os-release

WGET_FLAGS="--no-verbose"

node_arch() {
  case "$(uname -m)" in
    'aarch64') echo 'arm64' ;;
    'x86_64')  echo 'x64' ;;
    'armv7l')  echo 'armv7l' ;;
    *) exit 1 ;;
  esac
}

LSB_OS_VERSION="${VERSION_ID//\./}"
echo "LSB_OS_VERSION=${LSB_OS_VERSION}" | tee -a "/etc/environment"

ImageOS=ubuntu$(echo "${VERSION_ID}" | cut -d'.' -f 1)
AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ACT_TOOLSDIRECTORY=/opt/acttoolcache

tee <<-EOF >>/etc/environment
	IMAGE_OS=$ImageOS
	ImageOS=$ImageOS
	LSB_RELEASE=${VERSION_ID}
	AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}
	RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}
	DEPLOYMENT_BASEPATH=/opt/runner
	USER=$(whoami)
	RUNNER_USER=$(whoami)
	ACT_TOOLSDIRECTORY=${ACT_TOOLSDIRECTORY}
EOF

mkdir -m 0777 -p "${AGENT_TOOLSDIRECTORY}" "${ACT_TOOLSDIRECTORY}" /github
chown -R 1001:1000 "${AGENT_TOOLSDIRECTORY}" "${ACT_TOOLSDIRECTORY}" /github

packages=(
  openssh-client
  gawk
  curl
  jq
  wget
  sudo
  ca-certificates
  apt-transport-https
  zip
  unzip
  xz-utils
)

apt-get update
apt-get install "${packages[@]}"

ln -s "$(which python3)" "/usr/local/bin/python"

tee <<-EOF >/etc/apt/sources.list.d/00-git-core.list
	deb https://ppa.launchpadcontent.net/git-core/ppa/ubuntu ${VERSION_CODENAME} main
	deb-src https://ppa.launchpadcontent.net/git-core/ppa/ubuntu ${VERSION_CODENAME} main
EOF

apt-get update
apt-get install git

git --version

git config --system --add safe.directory '*'

wget "${WGET_FLAGS}" -qO- https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get update
apt-get install git-lfs

wget "${WGET_FLAGS}" -O "/imagegeneration/toolset.json" "https://raw.githubusercontent.com/actions/virtual-environments/main/images/ubuntu/toolsets/toolset-${LSB_OS_VERSION}.json" || echo "File not available"
wget "${WGET_FLAGS}" -O "/imagegeneration/LICENSE" "https://raw.githubusercontent.com/actions/virtual-environments/main/LICENSE"

mkdir -m 0700 -p ~/.ssh
{
  ssh_hosts=(
    github.com
    gitlab.com
    codeberg.org
    ssh.dev.azure.com
    sr.ht
  )
  for host in "${ssh_hosts[@]}"; do
    ssh-keyscan $host
  done
} >>/etc/ssh/ssh_known_hosts

{
  case "${VERSION_ID}" in
    '18.04') echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/multiarch/prod ${VERSION_CODENAME} main" ;;
    *)       echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" ;;
  esac
} | tee /etc/apt/sources.list.d/microsoft-prod.list

apt-get update
apt-get install --no-install-recommends --no-install-suggests moby-cli moby-buildx moby-compose

docker -v
docker buildx version

nodejs_major_ver="20"
nodejs_package_version=$(wget "${WGET_FLAGS}" -qO- https://nodejs.org/download/release/index.json | jq "[.[] | select(.version|test(\"^v${nodejs_major_ver}\"))][0].version" -r)
NODEPATH="${ACT_TOOLSDIRECTORY}/node/${nodejs_package_version:1}/$(node_arch)"
mkdir -v -m 0777 -p "$NODEPATH"

node_tarball="node-${nodejs_package_version}-linux-$(node_arch).tar.xz"

wget "${WGET_FLAGS}" -O $node_tarball "https://nodejs.org/download/release/latest-v${nodejs_major_ver}.x/${node_tarball}"
tar -Jxf $node_tarball --strip-components=1 -C "$NODEPATH"
rm $node_tarball
sed "s|^PATH=|PATH=$NODEPATH/bin:|mg" -i /etc/environment
export PATH="$NODEPATH/bin:$PATH"

# not using full path, this must not fail
node -v
npm -v

apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
