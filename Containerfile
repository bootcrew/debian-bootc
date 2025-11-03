FROM docker.io/library/debian:unstable

ARG DEBIAN_FRONTEND=noninteractive
# Antipattern but we are doing this since `apt`/`debootstrap` does not allow chroot installation on unprivileged podman builds
ENV DEV_DEPS="libzstd-dev libssl-dev pkg-config libostree-dev curl git build-essential meson libfuse3-dev go-md2man dracut"

RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages && \
    apt update -y && \
    apt install -y $DEV_DEPS ostree

ENV CARGO_HOME=/tmp/rust
ENV RUSTUP_HOME=/tmp/rust
RUN --mount=type=tmpfs,dst=/tmp \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y && \
    git clone https://github.com/bootc-dev/bootc.git /tmp/bootc && \
    sh -c ". ${RUSTUP_HOME}/env ; make -C /tmp/bootc bin install-all install-initramfs-dracut"

ENV DRACUT_NO_XATTR=1
RUN apt install -y \
  btrfs-progs \
  dosfstools \
  e2fsprogs \
  fdisk \
  firmware-linux-free \
  linux-image-generic \
  skopeo \
  systemd \
  systemd-boot* \
  xfsprogs

RUN sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img" && \
    cp /boot/vmlinuz-$KERNEL_VERSION "/usr/lib/modules/$KERNEL_VERSION/vmlinuz"'

# Setup a temporary root passwd (changeme) for dev purposes
# RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN apt remove -y $DEV_DEPS && \
    apt autoremove -y

# Update useradd default to /var/home instead of /home for User Creation
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

RUN rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/srv /srv && \
    ln -s sysroot/ostree ostree && \
    ln -s /var/usrlocal /usr/local && \
    mkdir -p /sysroot /boot

# Necessary for `bootc install`
RUN mkdir -p /usr/lib/ostree && \
    printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | \
    tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
