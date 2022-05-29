# Neutrino Linux
A Buildroot-based Linux base for NeutrinoOS
## Install dependencies and build tools
`./build.sh downloadTools`
## Build
### i386
`./build.sh build`

The build system will output a working, bootable disk image (linfinity.linux.img).
## Run using QEMU
`./build.sh run`