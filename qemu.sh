#!/bin/sh
qemu-system-x86_64 -m 4G \
	-smp 1 \
	-net nic,model=rtl8139 \
	-net user,hostfwd=tcp::10022-:22 \
	-audiodev alsa,id=snd0,out.dev=default -machine pcspk-audiodev=snd0 \
	-hda disk.img \
	-cdrom result/iso/nixos-24.11.20250201.f668777-x86_64-linux.iso 
