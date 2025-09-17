# Debian Bootc

Experiment to see if Bootc could work on Debian

<img width="2196" height="1239" alt="image" src="https://github.com/user-attachments/assets/0b031de0-5593-49e8-8e5a-535ebdcf46e3" />

## Building

Build uses podman. The `bootc` tooling is very heavily skewed towards this, docker may work, but I haven't tested it.

In order to get a running debian-bootc system you can run the following steps:

```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

The bootable image file is saved in `/tmp` as `/tmp/debian-bootc.img`. Assuming your `/tmp` is tmpfs, this is significantly faster for the image generation step.

Then you can run the `/tmp/debian-bootc.img` as your boot disk in your preferred hypervisor.

## Running

I'm using `incus` like so:

```shell
$ sudo incus-migrate
The local Incus server is the target [default=yes]:

What would you like to create?
1) Container
2) Virtual Machine
3) Virtual Machine (from .ova)
4) Custom Volume

Please enter the number of your choice: 2
Name of the new instance: debian-bootc
Please provide the path to a disk, partition, or qcow2/raw/vmdk image file: /tmp/debian-bootc.img
Does the VM support UEFI booting? [default=yes]: yes
Does the VM support UEFI Secure Boot? [default=yes]: no

Instance to be created:
  Name: debian-bootc
  Project: default
  Type: virtual-machine
  Source: /tmp/debian-bootc.img
  Source format: raw
  Config:
    security.secureboot: "false"

Additional overrides can be applied at this stage:
1) Begin the migration with the above configuration
2) Override profile list
3) Set additional configuration options
4) Change instance storage pool or volume size
5) Change instance network
6) Add additional disk
7) Change additional disk storage pool

Please pick one of the options above [default=1]: 1
```

The `incus-migrate` command takes several minutes as it tranforms the image into whatever it is that Incus wants.

To start and view:

```shell
incus start debian-bootc && incus console --type=vga debian-bootc
```

# Fixes

- `mount /dev/vda2 /sysroot/boot` - You need this to get `bootc status` and other stuff working
