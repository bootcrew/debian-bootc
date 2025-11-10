# Debian Bootc

Reference [debian](http://debian.org/) container image configured for [bootc](https://github.com/bootc-dev/bootc) usage.

<img width="2196" height="1239" alt="image" src="https://github.com/user-attachments/assets/0b031de0-5593-49e8-8e5a-535ebdcf46e3" />

## Building

In order to get a running debian-bootc system you can run the following steps:
```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

Then you can run the `bootable.img` as your boot disk in your preferred hypervisor.

## Notes

For Debian Stable, please take a look at <https://github.com/linuxsnow/debian-bootc-core> or pull request workflows in order to make it work in this repo. Thank you!
