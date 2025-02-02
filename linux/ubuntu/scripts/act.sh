#!/usr/bin/bash
# shellcheck disable=SC2174

set -Eeuxo pipefail

# Remove '"' so it can be sourced by sh/bash
sed 's|"||g' -i "/etc/environment"

. /etc/os-release

node_arch() {
  case "$(uname -m)" in
    'aarch64') echo 'arm64' ;;
    'x86_64') echo 'x64' ;;
    'armv7l') echo 'armv7l' ;;
    *) exit 1 ;;
  esac
}

ImageOS=ubuntu$(echo "${VERSION_ID}" | cut -d'.' -f 1)
AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ACT_TOOLSDIRECTORY=/opt/acttoolcache
{
  echo "IMAGE_OS=$ImageOS"
  echo "ImageOS=$ImageOS"
  echo "LSB_RELEASE=${VERSION_ID}"
  echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}"
  echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}"
  echo "DEPLOYMENT_BASEPATH=/opt/runner"
  echo "USER=$(whoami)"
  echo "RUNNER_USER=$(whoami)"
  echo "ACT_TOOLSDIRECTORY=${ACT_TOOLSDIRECTORY}"
} | tee -a "/etc/environment"

mkdir -m 0777 -p "${AGENT_TOOLSDIRECTORY}"
chown -R 1001:1000 "${AGENT_TOOLSDIRECTORY}"
mkdir -m 0777 -p "${ACT_TOOLSDIRECTORY}"
chown -R 1001:1000 "${ACT_TOOLSDIRECTORY}"

mkdir -m 0777 -p /github
chown -R 1001:1000 /github

packages=(
  ssh
  gawk
  curl
  jq
  wget
  sudo
  gnupg-agent
  ca-certificates
  software-properties-common
  apt-transport-https
  libyaml-0-2
  zstd
  zip
  unzip
  xz-utils
  python3-pip
  python3-venv
  pipx
)

apt-get -yq update
apt-get -yq install --no-install-recommends --no-install-suggests "${packages[@]}"

ln -s "$(which python3)" "/usr/local/bin/python"

add-apt-repository ppa:git-core/ppa -y
apt-get update
apt-get install -y git

git --version

git config --system --add safe.directory '*'

wget -nv -O- https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get update
apt-get install -y git-lfs

LSB_OS_VERSION="${VERSION_ID//\./}"
echo "LSB_OS_VERSION=${LSB_OS_VERSION}" | tee -a "/etc/environment"

wget -nv -O "/imagegeneration/toolset.json" "https://raw.githubusercontent.com/actions/virtual-environments/main/images/ubuntu/toolsets/toolset-${LSB_OS_VERSION}.json" || echo "File not available"
wget -nv -O "/imagegeneration/LICENSE" "https://raw.githubusercontent.com/actions/virtual-environments/main/LICENSE"

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

if [[ "${VERSION_ID}" == "18.04" ]]; then
  echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/multiarch/prod ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/microsoft-prod.list
else
  echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/microsoft-prod.list
fi
wget -nv https://packages.microsoft.com/keys/microsoft.asc
gpg --dearmor <microsoft.asc >/etc/apt/trusted.gpg.d/microsoft.gpg
apt-key add - <microsoft.asc
rm microsoft.asc
apt-get -yq update
apt-get -yq install --no-install-recommends --no-install-suggests moby-cli moby-buildx moby-compose

docker -v
docker buildx version

IFS=' ' read -r -a NODE <<<"$NODE_VERSION"
for ver in "${NODE[@]}"; do
  VER=$(curl https://nodejs.org/download/release/index.json | jq "[.[] | select(.version|test(\"^v${ver}\"))][0].version" -r)
  NODEPATH="${ACT_TOOLSDIRECTORY}/node/${VER:1}/$(node_arch)"
  mkdir -v -m 0777 -p "$NODEPATH"

  node_tarball="node-$VER-linux-$(node_arch).tar.xz"

  wget -nv -O $node_tarball "https://nodejs.org/download/release/latest-v${ver}.x/${node_tarball}"
  tar -Jxf $node_tarball --strip-components=1 -C "$NODEPATH"
  rm "node-$VER-linux-$(node_arch).tar.xz"
  if [[ "${ver}" == "20" ]]; then # FIXME: Update when changed in GitHub
    sed "s|^PATH=|PATH=$NODEPATH/bin:|mg" -i /etc/environment
  fi
  export PATH="$NODEPATH/bin:$PATH"

  "${NODEPATH}"/bin/node -v
  "${NODEPATH}"/bin/npm -v
done

apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
