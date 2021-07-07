extern Gamma_c
global Gamma_asm

; Gamma_asm (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);

section .rodata
maskGenerator: times 4 dd 0x000000FF

maskA: dq 0xFF000000FF000000, 0xFF000000FF000000

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

    movdqu xmm15, [maskGenerator]      ;guardamos en xmm15 la mascara que nos permitira generar las mascaras para filtrar componentes
    movdqu xmm13, [doscincuentaycincos]

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

            pand xmm1, xmm15            ;filtramos los azules
            movdqu xmm14, xmm15
            pslldq xmm14, 1             ;movemos los bytes uno hacia la izq generando una mascara que sirve para filtrar los verdes
            pand xmm2, xmm14
            pslldq xmm14, 1             
            pand xmm3, xmm14

            psrldq xmm2, 1
            psrldq xmm3, 2

                ; convertimos a floats
            cvtdq2ps xmm1, xmm1
            cvtdq2ps xmm2, xmm2
            cvtdq2ps xmm3, xmm3

                ;Realizamos el calculo de la ecuaciÃ³n para cada componente
            movdqu xmm4, xmm13
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
            movdqu xmm4, xmm15
            pand xmm1, xmm4
            pand xmm2, xmm4
            pand xmm3, xmm4

            pslldq xmm2, 1
            pslldq xmm3, 2

            por xmm1, xmm2
            por xmm1, xmm3


            pslldq xmm4, 3
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