FROM docker.io/library/debian:unstable

COPY files/ostree/prepare-root.conf /usr/lib/ostree/prepare-root.conf

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y ca-certificates

COPY noahm.sources /etc/apt/sources.list.d
COPY noahm.gpg /etc/apt
RUN apt-get update -y && apt-get install -y bootc coreos-bootupd ostree composefs


RUN apt install -y \
  dracut \
  podman \
  linux-image-generic \
  firmware-linux-free \
  systemd \
  btrfs-progs \
  e2fsprogs \
  xfsprogs \
  udev \
  cpio \
  zstd \
  binutils \
  dosfstools \
  conmon \
  crun \
  netavark \
  skopeo \
  dbus \
  fdisk \
  systemd-boot*


RUN echo "$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" > kernel_version.txt && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$(cat kernel_version.txt)"  "/usr/lib/modules/$(cat kernel_version.txt)/initramfs.img" && \
    cp /boot/vmlinuz-$(cat kernel_version.txt) "/usr/lib/modules/$(cat kernel_version.txt)/vmlinuz" && \
    rm kernel_version.txt

# If you want a desktop :)
RUN apt install -y gnome

# Alter root file structure a bit for ostree
RUN mkdir -p /boot /sysroot /var/home /var/roothome /var/usrlocal /var/srv && \
    rm -rf /var/log /home /root /usr/local /srv && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/usrlocal /usr/local && \
    ln -s /var/srv /srv

# Setup a temporary root passwd (changeme) for dev purposes
# TODO: Replace this for a more robust option when in prod
RUN usermod -p '$6$AJv9RHlhEXO6Gpul$5fvVTZXeM0vC03xckTIjY8rdCofnkKSzvF5vEzXDKAby5p3qaOGTHDypVVxKsCE3CbZz7C3NXnbpITrEUvN/Y/' root

# Necessary labels
LABEL containers.bootc 1
