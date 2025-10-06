#!/usr/bin/env bash
set -euo pipefail


# find the first file in ./mkosi.output named snowDesktop_*x86-64.raw
image_file=/tmp/bootable.img

if [ -z "$image_file" ]; then
    echo "No image file found"
    exit 1
fi


abs_image_file=$(realpath "$image_file")

# make the instance_name "snow" plus the variant
instance_name="dbc-desktop"
echo "Creating instance $instance_name from image file $abs_image_file"
incus init "$instance_name" --empty --vm
incus config device override "$instance_name" root size=50GiB
incus config set "$instance_name" limits.cpu=4 limits.memory=8GiB
incus config set "$instance_name" security.secureboot=false
incus config device add "$instance_name" vtpm tpm
incus config device add "$instance_name" install disk source="$abs_image_file" boot.priority=90
incus start "$instance_name"


echo "dbc-desktop is Starting..."

incus console --type=vga "$instance_name"

