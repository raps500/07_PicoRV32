// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "custom_ops.S"

.balign 16
	.section .text
	.global main
    /* set stack pointer at the end of the 128k block */
    lui sp,(128*1024)>>12
	j main
    
return_to_bootl:
    j 0x0

