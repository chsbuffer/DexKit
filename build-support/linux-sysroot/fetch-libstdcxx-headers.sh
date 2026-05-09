#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output-path>" >&2
    exit 2
fi

output_path="$1"
package_name="${UBUNTU_LIBSTDCXX_DEV_PACKAGE:-libstdc++-10-dev}"

if [ -e "$output_path" ]; then
    echo "error: output path already exists: $output_path" >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "error: apt-get is required to locate $package_name" >&2
    exit 1
fi

download() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo "error: curl or wget is required" >&2
        exit 1
    fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

package_uri=""
while read -r uri filename _; do
    case "$uri" in
        \'http*|\'file:*)
            uri="${uri#\'}"
            uri="${uri%\'}"
            ;;
        *)
            continue
            ;;
    esac

    case "$filename" in
        "$package_name"_*.deb)
            package_uri="$uri"
            break
            ;;
    esac
done < <(apt-get --print-uris --yes --reinstall install "$package_name")

if [ -z "$package_uri" ]; then
    echo "error: apt-get could not find a downloadable $package_name package" >&2
    exit 1
fi

mkdir -p "$(dirname "$output_path")"
download "$package_uri" "$tmpdir/$package_name.deb"
mkdir -p "$output_path"
dpkg-deb -x "$tmpdir/$package_name.deb" "$output_path"

if [ ! -d "$output_path/usr/include/c++/10" ] || \
   [ ! -d "$output_path/usr/include/x86_64-linux-gnu/c++/10" ]; then
    echo "error: $package_name did not provide the expected GCC 10 headers" >&2
    exit 1
fi
