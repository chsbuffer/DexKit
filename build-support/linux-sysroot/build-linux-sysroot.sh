#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <sysroot-path>" >&2
    exit 2
fi

sysroot_path="$1"
ubuntu_mirror="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu/}"
ubuntu_codename="${UBUNTU_CODENAME:-focal}"
ubuntu_components="${UBUNTU_COMPONENTS:-main universe}"
if [ "${UBUNTU_EXTRA_PACKAGES+x}" ]; then
    extra_packages="$UBUNTU_EXTRA_PACKAGES"
elif [ "$ubuntu_codename" = "focal" ]; then
    extra_packages="gcc-10 g++-10 libstdc++-10-dev"
else
    extra_packages=""
fi

if [ -e "$sysroot_path" ]; then
    echo "error: sysroot path already exists: $sysroot_path" >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "error: this script must be run as root" >&2
    exit 1
fi

apt-get update
apt-get install -y debootstrap ubuntu-keyring ca-certificates gnupg xz-utils

mkdir -p "$(dirname "$sysroot_path")"

debootstrap \
    --variant=minbase \
    --force-check-gpg \
    --arch amd64 \
    "$ubuntu_codename" \
    "$sysroot_path" \
    "$ubuntu_mirror"

rm -f "$sysroot_path/etc/apt/sources.list"
rm -rf "$sysroot_path/etc/apt/sources.list.d"
mkdir -p "$sysroot_path/etc/apt/sources.list.d"

cat <<EOF > "$sysroot_path/etc/apt/sources.list.d/$ubuntu_codename.list"
deb $ubuntu_mirror $ubuntu_codename $ubuntu_components
deb $ubuntu_mirror $ubuntu_codename-updates $ubuntu_components
deb $ubuntu_mirror $ubuntu_codename-security $ubuntu_components
deb $ubuntu_mirror $ubuntu_codename-backports $ubuntu_components
EOF

chroot "$sysroot_path" apt-get update
chroot "$sysroot_path" apt-get -f -y install
chroot "$sysroot_path" apt-get -y install \
    build-essential \
    gcc \
    g++ \
    zlib1g-dev \
    symlinks \
    $extra_packages

chroot "$sysroot_path" symlinks -cr /usr
chroot "$sysroot_path" apt-get clean
rm -rf "$sysroot_path/var/lib/apt/lists"/* "$sysroot_path/tmp"/* "$sysroot_path/var/tmp"/*
