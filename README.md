# ASCK
ASCK - ASM Start C Kernel is my first attempt at an "Operating System" targeted at x86 systems and runs in 16-bit real mode. I don't know what I'm doing this is just for fun and to learn!

# ASCK v1 
## Phaedra Rinn 2026 

To build:

wcc -0 -s -wx -d0 -ms -zl kernel.c

wasm start.asm

wlink @link.lnk

nasm -f bin boot.asm -o boot.bin

dd if=/dev/zero of=floppy.img bs=512 count=2880
dd if=boot.bin of=floppy.img conv=notrunc
dd if=kernel.bin of=floppy.img bs=512 seek=1 conv=notrunc

Then QEMU:

qemu-system-x86_64 -fda floppy.img
