; startup.asm - Custom 16-bit Real Mode Startup for Open Watcom
; This code is assembled with WASM (Watcom Assembler)
; It replaces the standard cstart and avoids any DOS dependencies.

.386p
; Define segments compatible with Watcom's default segment ordering
_TEXT   segment word public 'CODE'
_TEXT   ends
_DATA   segment word public 'DATA'
_DATA   ends

_TEXT   segment
        assume  cs:_TEXT, ds:_DATA, ss:_DATA

        ; This symbol replaces the standard Watcom startup
        public  _cstart_
_cstart_ proc far
        ; At this point, CS points to our code segment.
        ; Make sure DS, ES, and SS point to our data segment.
        mov     ax, seg _DATA
        mov     ds, ax
        mov     es, ax

        ; Set up a stack
        mov     ax, 0x7000      ; Put the stack at a safe high address
        mov     ss, ax
        mov     sp, 0xFFFE      ; Stack grows down from the top of the segment

        ; Call the C kernel entry point
        ; Using 'far ptr' ensures the correct segment:offset
        call    far ptr _KernelMain

        ; If KernelMain returns, halt the system
        cli
        hlt
_cstart_ endp

_TEXT   ends
        end