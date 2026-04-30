/* kernel.c - 16-bit Real Mode C Kernel for Open Watcom */
void print_string(const char *str)
{
    /* Video memory starts at 0xB800:0x0000 */
    unsigned char *video_ptr = (unsigned char *)0xB8000000L;
    static int pos = 0; /* Simple static counter for screen position */

    while (*str)
    {
        if (*str == '\n')
        {
            /* Basic newline support: advance to the next 80-column line */
            pos = (pos / 80 + 1) * 80;
            str++;
            continue;
        }
        /* Character byte */
        video_ptr[pos * 2] = *str;
        /* Attribute byte (Light Grey on Black) */
        video_ptr[pos * 2 + 1] = 0x07;
        pos++;
        str++;
    }
}

/* Entry point, called from our custom startup code */
void KernelMain(void)
{
    char *msg = "hello from c!";
    print_string(msg);

    /* Print 'P' in an infinite loop */
    while (1)
    {
        /* BIOS teletype interrupt to print a character */
        __asm {
            mov ah, 0x0E
            mov al, 'P'
            int 0x10
        }
    }
}