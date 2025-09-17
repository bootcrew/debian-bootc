image_name := env("BUILD_IMAGE_NAME", "debian-bootc")
image_tag := env("BUILD_IMAGE_TAG", "latest")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")

build-containerfile:
    sudo podman build \
        --no-cache -t {{image_name}}:latest .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -e RUST_LOG=debug \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "/tmp:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:latest" bootc {{ARGS}}


generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "/tmp/debian-bootc.img" ] ; then
        fallocate -l 20G "/tmp/debian-bootc.img"
    fi
    just bootc install to-disk --composefs-native --via-loopback /data/debian-bootc.img --filesystem "${filesystem}" --wipe --bootloader systemd
