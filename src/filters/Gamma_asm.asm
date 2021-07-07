extern Gamma_c
global Gamma_asm

; Gamma_asm (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);

section .rodata
maskSB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80

maskSR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80

maskSG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80

maskA: dq 0xFF000000FF000000, 0xFF000000FF000000


maskBGamma: dq 0x00000000FFFFFFFF, 0x0000000000000000

maskGGamma: dq 0xFFFFFFFF00000000, 0x0000000000000000

maskRGamma: dq 0x0000000000000000,  0x00000000FFFFFFFF


maskShuffleGamma: db 0x00, 0x04, 0x08, 0x80, 0x01, 0x05, 0x09, 0x80, 0x02, 0x06, 0x0A, 0x80, 0x03, 0x07, 0x0B, 0x80

doscincuentaycincos: times 4 dd 0x000000FF

;*src en rdi - *dst en rsi - width en rdx - height en rcx - src_row_size en r8 - dst_row_size en r9
section .text
Gamma_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r15
    push r14
    push r13

    ; iterador a lo largo de filas (para la fila i, recorremos todas las columnas)...
    ; ... tomo de a 4 pixeles de 4 bytes cada uno luego (iterare src_row_size >> 4) -dividido 4- veces
    mov rbx, 0; contador columnas, #bytes de manera tal que para direccionar la componente
        ; de la fila solo se sume rbx y no tener que acordarse de multiplicar y hacer errores boludos
    .aLoLargoDeFila:
        cmp rbx, r8
        je .fin

        lea r14, [rdi + rbx]
        mov r15, 0 ; nuestro iterador de filas, para direccionar se DEBE multiplicar por src_row_size (r8)
                    ; direccionamiento debe ser [rdi + rbx + r15 * r8 ]
        .aLoLargoDeColumna:
            cmp r15, rcx
            je .finColumna
            ; aca tenemos la direccion de los 4 pixeles que queremos en r14            
            ;tomarPixeles
            movdqu xmm0, [r14]
            ; guardamos los pixeles en xmm1/2/3 para filtralos
            movdqu xmm1, xmm0               
            movdqu xmm2, xmm0
            movdqu xmm3, xmm0
            movdqu xmm4, [maskSB]
            movdqu xmm5, [maskSG]
            movdqu xmm6, [maskSR]
            pshufb xmm1, xmm4               ; filtramos el color azul
            pshufb xmm2, xmm5               ; filtramos el color verde
            pshufb xmm3, xmm6               ; filtramos el color rojo

                ; convertimos a floats
            cvtdq2ps xmm1, xmm1
            cvtdq2ps xmm2, xmm2
            cvtdq2ps xmm3, xmm3

                ;Realizamos el calculo de la ecuación para cada componente
            movdqu xmm4, [doscincuentaycincos] 
            cvtdq2ps xmm4, xmm4

            divps xmm1, xmm4
            divps xmm2, xmm4
            divps xmm3, xmm4

            sqrtps xmm1, xmm1
            sqrtps xmm2, xmm2
            sqrtps xmm3, xmm3

            mulps xmm1, xmm4
            mulps xmm2, xmm4
            mulps xmm3, xmm4
            
            ; convertimos a int normales de nuevo
            cvttps2dq xmm1, xmm1
            cvttps2dq xmm2, xmm2
            cvttps2dq xmm3, xmm3
; hasta aca da todo MUY bien, hicimos cuentas aleatorias con xmm1
            packusdw xmm1, xmm1
            packusdw xmm2, xmm2
            packusdw xmm3, xmm3

            packuswb xmm1, xmm1
            packuswb xmm2, xmm2
            packuswb xmm3, xmm3

            movdqu xmm4, [maskBGamma]  
            movdqu xmm5, [maskGGamma]
            movdqu xmm6, [maskRGamma]
            pand xmm1, xmm4
            pand xmm2, xmm5
            pand xmm3, xmm6

            paddd xmm1, xmm2 
            paddd xmm1, xmm3

            movdqu xmm2, [maskShuffleGamma]
            pshufb xmm1, xmm2

            movdqu xmm4, [maskA]
            pand xmm0, xmm4 
            paddb xmm1, xmm0

            lea r13, [rsi + rbx]
            mov rax, r15
            push rdx
            mul r8  
            pop rdx
            lea r13, [r13 + rax]
                
            movdqu [r13], xmm1

            inc r15
            lea r14, [r14 + r8]
            jmp .aLoLargoDeColumna        
    .finColumna:      
        add rbx, 16
        jmp .aLoLargoDeFila 

.fin:
pop r13
pop r14
pop r15
pop rbx
pop rbp
ret
