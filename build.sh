echo "Building..."
mkdir -p build
wcc -0 -s -wx -d0 -ms -zl kernel.c
wasm start.asm
wlink @link.lnk
nasm -f bin boot.asm -o boot.bin
dd if=/dev/zero of=floppy.img bs=512 count=2880
dd if=boot.bin of=floppy.img conv=notrunc
dd if=kernel.bin of=floppy.img bs=512 seek=1 conv=notrunc
echo "Build Complete!"
