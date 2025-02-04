#!/bin/sh
qemu-system-x86_64 -m 1G \
	-net nic,model=rtl8139 \
	-net user,hostfwd=tcp::10022-:22 \
	-cdrom result/iso/nixos-24.11.20250201.f668777-x86_64-linux.iso 
