#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <sysroot-path>" >&2
    exit 2
fi

sysroot_path="$1"
ubuntu_mirror="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu/}"

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
    focal \
    "$sysroot_path" \
    "$ubuntu_mirror"

rm -f "$sysroot_path/etc/apt/sources.list"
rm -rf "$sysroot_path/etc/apt/sources.list.d"
mkdir -p "$sysroot_path/etc/apt/sources.list.d"

cat <<EOF > "$sysroot_path/etc/apt/sources.list.d/focal.list"
deb $ubuntu_mirror focal main universe
deb $ubuntu_mirror focal-updates main universe
deb $ubuntu_mirror focal-security main universe
deb $ubuntu_mirror focal-backports main universe
EOF

chroot "$sysroot_path" apt-get update
chroot "$sysroot_path" apt-get -f -y install
chroot "$sysroot_path" apt-get -y install \
    build-essential \
    gcc \
    gcc-10 \
    g++ \
    g++-10 \
    libstdc++-10-dev \
    zlib1g-dev \
    symlinks

chroot "$sysroot_path" symlinks -cr /usr
chroot "$sysroot_path" apt-get clean
rm -rf "$sysroot_path/var/lib/apt/lists"/* "$sysroot_path/tmp"/* "$sysroot_path/var/tmp"/*
