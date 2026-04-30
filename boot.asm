; ------------------------------------------------------------
; 16-bit Real Mode Bootloader
; Loads kernel from the disk (starting at sector 2)
; into memory at 0x1000:0x0000 (physical 0x10000) and jumps to it
; ------------------------------------------------------------

[BITS 16]                 ; 16-bit real mode
[ORG 0x7C00]              ; BIOS loads boot sector at 0x0000:0x7C00

; ------------------------------------------------------------
; Constants
; ------------------------------------------------------------
KERNEL_LOAD_SEG     equ 0x1000   
KERNEL_LOAD_OFFSET  equ 0x0000   ; physical = 0x10000
KERNEL_START_SECTOR equ 1         ; LBA of first kernel sector (1 = sector 2)
KERNEL_SECTORS      equ 8         ; Number of sectors to load

; ------------------------------------------------------------
; Entry point
; ------------------------------------------------------------
start:
    ; ---- Setup segment registers and stack ----
    xor ax, ax                  ; AX = 0
    mov ds, ax                  ; Data segment = 0
    mov es, ax                  ; Extra segment = 0
    mov ss, ax                  ; Stack segment = 0
    mov sp, 0x7C00              ; Stack grows down from just below the boot sector

    ; ---- Save boot drive number (BIOS passes it in DL) ----
    mov [boot_drive], dl

    ; ---- Display message ----
    mov si, msg_loading
    call print_string

    ; ---- Reset disk system (recommended before reading) ----
    mov ah, 0x00                ; BIOS function: reset disk system
    mov dl, [boot_drive]        ; Drive number
    int 0x13
    jc disk_error               ; Carry flag set on error

    ; ---- Load kernel from disk ----
    mov ax, KERNEL_START_SECTOR   ; LBA = 1 (sector 2)
    call lba_to_chs

    ; ---- Set up ES:BX for read ----
    mov ax, KERNEL_LOAD_SEG
    mov es, ax
    mov bx, KERNEL_LOAD_OFFSET    ; ES:BX = 0x1000:0x0000

    ; ---- Read kernel sectors ----
    mov ah, 0x02                ; BIOS function: read sectors
    mov al, KERNEL_SECTORS      ; Number of sectors to read
    mov dl, [boot_drive]        ; Drive number
    int 0x13
    jc disk_error               ; If carry set, read failed

    ; ---- Verify read enough sectors ----
    cmp al, KERNEL_SECTORS
    jne disk_error              ; If not all sectors read, error

    ; ---- Print success message ----
    mov si, msg_ok
    call print_string

    ; ---- Jump to loaded kernel ----
    ; far jump to the kernel entry point
    jmp KERNEL_LOAD_SEG:KERNEL_LOAD_OFFSET

; ------------------------------------------------------------
; Error handler: print message and halt
; ------------------------------------------------------------
disk_error:
    mov si, msg_error
    call print_string
    cli                         ; Disable interrupts
    hlt                         ; Halt CPU
    jmp $                       ; Infinite loop if hlt is interrupted

; ------------------------------------------------------------
; Print a null-terminated string (DS:SI)
; ------------------------------------------------------------
print_string:
    pusha                       ; Save registers
    mov ah, 0x0E                ; BIOS teletype output function
.next_char:
    lodsb                       ; Load byte from [SI] into AL, increment SI
    test al, al                 ; Check for null terminator
    jz .done
    int 0x10                    ; Print character in AL
    jmp .next_char
.done:
    popa                        ; Restore registers
    ret

; ------------------------------------------------------------
; Convert LBA (in AX) to CHS for int 13h (ah=02h)
; Input:  AX = LBA (1-based sector number)
; Output: CH = cylinder (low 8 bits)
;         CL = sector (bits 0-5) + cylinder high bits (bits 6-7)
;         DH = head
;         DL = drive (unchanged, must be set by caller)
; ------------------------------------------------------------
lba_to_chs:
    push bx
    push ax

    ; ---- Get sectors per track and number of heads ----
    ;   Floppy sectors fallback:
    ;   Sectors per track = 18
    ;   Heads = 2
    mov bx, 18                  ; Sectors per track
    mov cx, 2                   ; Number of heads

    ; ---- Calculate sector (1-based) ----
    xor dx, dx
    div bx                      ; AX = LBA / SPT, DX = LBA % SPT
    inc dx                      ; Sector = (LBA % SPT) + 1
    mov cl, dl                  ; CL = sector number (bits 0-5)

    ; ---- Calculate head and cylinder ----
    xor dx, dx
    div cx                      ; AX = (LBA / SPT) / Heads, DX = head
    mov ch, al                  ; CH = cylinder (low 8 bits)
    ; Cylinder high bits (if any) go into CL bits 6-7
    shl ah, 6                   ; Move high bits of cylinder to top of CL
    or cl, ah                   ; Combine with sector bits

    mov dh, dl                  ; DH = head

    pop ax
    pop bx
    ret

; ------------------------------------------------------------
; Data
; ------------------------------------------------------------
msg_loading db 'Loading kernel...', 0x0D, 0x0A, 0
msg_ok      db 'OK, jumping to kernel.', 0x0D, 0x0A, 0
msg_error   db 'Disk read error! System halted.', 0x0D, 0x0A, 0

boot_drive  db 0                ; Store boot drive number here

; ------------------------------------------------------------
; Boot sector signature (must be at offset 510)
; ------------------------------------------------------------
times 510 - ($ - $$) db 0       ; Pad with zeros up to byte 510
dw 0xAA55                       ; Boot signature