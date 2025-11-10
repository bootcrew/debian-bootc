FROM docker.io/library/debian:unstable

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y && \
  apt install -y \
      btrfs-progs \
      dosfstools \
      e2fsprogs \
      fdisk \
      firmware-linux-free \
      linux-image-generic \
      skopeo \
      systemd \
      systemd-boot* \
      xfsprogs && \
  rm -rf /var/lib/apt/lists/* && \
  apt clean -y

# Regression with newer dracut broke this
RUN mkdir -p /etc/dracut.conf.d && \
    printf "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

ENV CARGO_HOME=/tmp/rust
ENV RUSTUP_HOME=/tmp/rust
ENV DEV_DEPS="libzstd-dev libssl-dev pkg-config curl git build-essential meson libfuse3-dev go-md2man dracut"
RUN --mount=type=tmpfs,dst=/tmp \
    apt update -y && \
    apt install -y $DEV_DEPS libostree-dev ostree && \
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- --profile minimal -y && \
    git clone "https://github.com/bootc-dev/bootc.git" /tmp/bootc && \
    sh -c ". ${RUSTUP_HOME}/env ; make -C /tmp/bootc bin install-all install-initramfs-dracut" && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img" && cp /boot/vmlinuz-$KERNEL_VERSION "/usr/lib/modules/$KERNEL_VERSION/vmlinuz"' && \
    apt purge -y $DEV_DEPS && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean -y

# Necessary for general behavior expected by image-based systems
RUN echo "HOME=/var/home" | tee -a "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var /sysroot /boot /usr/lib/ostree && \
    ln -s var/opt /opt && \
    ln -s var/roothome /root && \
    ln -s var/home /home && \
    ln -s sysroot/ostree /ostree && \
    echo "$(for dir in opt usrlocal home srv mnt ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /var/roothome 0700 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    echo "d /run/media 0755 root root -" | tee -a /usr/lib/tmpfiles.d/bootc-base-dirs.conf && \
    printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | tee "/usr/lib/ostree/prepare-root.conf"

# Setup a temporary root passwd (changeme) for dev purposes
# RUN apt update -y && apt install -y whois
# RUN usermod -p "$(echo "changeme" | mkpasswd -s)" root

RUN bootc container lint
