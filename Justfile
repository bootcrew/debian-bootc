image_name := env("BUILD_IMAGE_NAME", "debian-bootc")
image_tag := env("BUILD_IMAGE_TAG", "latest")
output_directory := env("BUILD_BASE_DIR", "/tmp")
filesystem := env("BUILD_FILESYSTEM", "ext4")
disk_image := env("BUILD_DISK_IMAGE", "bootable.img")

build-containerfile $image_name=image_name:
    sudo podman build --no-cache -t "${image_name}:latest" .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -e RUST_LOG=debug \
        -v "{{output_directory}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bootc {{ARGS}}

generate-bootable-image $disk_image=disk_image $output_directory=output_directory $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${output_directory}/${disk_image}" ] ; then
        fallocate -l 20G "${output_directory}/${disk_image}"
    fi
    just bootc install to-disk --composefs-backend --via-loopback /data/${disk_image} --filesystem "${filesystem}" --wipe --karg=gnome.initial-setup=1 --bootloader systemd

