extern Funny_c
global Funny_asm

section .rodata
        ;  00     01   02    03     04   05    06    07   08     09    10    11    12    13    14    15
maskSB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80

maskSR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80

maskSG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80

maskBFunny: dq 0x00000000FFFFFFFF, 0x0000000000000000

maskGFunny: dq 0xFFFFFFFF00000000, 0x0000000000000000

maskRFunny: dq 0x0000000000000000,  0x00000000FFFFFFFF

maskA: dq 0xFF000000FF000000, 0xFF000000FF000000

CuadrupledosCincoCinco: times 4 dd 0xFF

cuatroCien: times 4 dd 0x64

cuatroDiez: times 4 dd 0x0A

cuatroDos: times 4 dd 0x02

cuatroUnos: times 4 dd 0x01

;void Funny_c(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size)
;rdi =  src, rsi= dst, rdx = width, rcx = height, r8 = src_row_size, r9 = dst_row_size
section .text
Funny_asm:
push rbp
mov rbp, rsp
push r13
push r12

mov r10, 0                          ;Contador para las columnas
mov r11, 0                          ;Contador para las filas

pxor xmm5, xmm5                     ;Aca guardamos i para calcular en sigle presition

dec rcx

.ciclo:
    cmp r10, rdx                    ;Comparo con el ancho
    je .chequear_alto

    ;Cargamos el puntero al primer pixel de la tira de 4 a levantar
    lea r12, [rdi + r10*4]                      ;Desplazamiento sobre columna
    mov rax, r11
    push rdx
    mul r8
    pop rdx
    add r12, rax                                ;Desplazamiento sobre columna

    movdqu xmm0, [r12]                             ;Guardamos los pixeles en xmm0

    ;separamos los componentes de los pixeles
    movdqu xmm1, xmm0               
    movdqu xmm2, xmm0
    movdqu xmm3, xmm0
    movdqu xmm4, [maskSB]
    movdqu xmm6, [maskSG]
    movdqu xmm7, [maskSR]
    pshufb xmm1, xmm4               ; filtramos el color azul
    pshufb xmm2, xmm6               ; filtramos el color verde
    pshufb xmm3, xmm7               ; filtramos el color rojo
    
    ;hacemos las cuentas con los índices
    ;insertamos los índices i,j en xmm5 y xmm4 respectivamente para poder trabajarlos en simultaneao
    mov r13, r10

    pinsrd xmm4, r13d, 0

    pinsrd xmm13, r13d, 0

    inc r13d
    pinsrd xmm4, r13d, 1

    pinsrd xmm13, r13d, 1

    inc r13d
    pinsrd xmm4, r13d, 2

    pinsrd xmm13, r13d, 2

    inc r13d
    pinsrd xmm4, r13d, 3

    pinsrd xmm13, r13d, 3
    

    ;funny_b
    movdqu xmm10, [cuatroDos]    
    
    cvtdq2pd xmm8, xmm13
    psrldq xmm13, 8
    cvtdq2pd xmm9, xmm13

    cvtdq2pd xmm6, xmm5
    cvtdq2pd xmm10, xmm10
    

    mulpd xmm8, xmm10
    mulpd xmm9, xmm10    
    mulpd xmm6, xmm10

    movdqu xmm10, [cuatroCien]
    cvtdq2pd xmm10, xmm10

    addpd xmm8, xmm10
    addpd xmm9, xmm10

    addpd xmm6, xmm10

    mulpd xmm8, xmm6
    mulpd xmm9, xmm6
    sqrtpd xmm8, xmm8
    sqrtpd xmm9, xmm9

    movdqu xmm10, [cuatroDiez]
    cvtdq2pd xmm10, xmm10

    mulpd xmm8, xmm10          ;funny_b dos primeros
    mulpd xmm9, xmm10

    ;funny_r
    movdqu xmm6, xmm4               ;j
    psubd xmm6, xmm5                ;j-i
    pabsd xmm6, xmm6

    cvtdq2ps xmm6, xmm6

    sqrtps xmm6, xmm6               ;sqrt(abs(j-i))

    movdqu xmm7, [cuatroCien]
    cvtdq2ps xmm7, xmm7
    mulps xmm6, xmm7                ;xmm6 = funny_r

    ;funny_g
    movdqu xmm7, xmm5               ;i
    movdqu xmm14, [cuatroDiez]

    psubd xmm7, xmm4                ;i-j
    pabsd xmm7, xmm7                ; abs(i-j)
    

    cvtdq2ps xmm7, xmm7
    cvtdq2ps xmm14, xmm14

    mulps xmm7, xmm14               ;abs(i-j)*10

    movdqu xmm14, xmm4
    movdqu xmm13, [cuatroUnos]
    movdqu xmm10, [cuatroCien]

    paddd xmm14, xmm5               ;(j+i)
    paddd xmm14, xmm13               ;(j+i+1)

    cvtdq2ps xmm14, xmm14
    cvtdq2ps xmm10, xmm10

    divps xmm14, xmm10              ;(j+i+1)/100

    divps xmm7, xmm14               ;funny_g

    ;convertimos de nuevo a integer signado truncando los valores
    cvttpd2dq xmm9, xmm9
    pslldq xmm9, 8
    cvttpd2dq xmm8, xmm8

    por xmm8, xmm9

    cvttps2dq xmm7, xmm7
    cvttps2dq xmm6, xmm6

    movdqu xmm15, [CuadrupledosCincoCinco]

    pand xmm8, xmm15
    pand xmm7, xmm15
    pand xmm6, xmm15


    ;dividimos todos los funny por dos

    psrld xmm6, 1            ;funny_r/2
    psrld xmm7, 1            ;funny_g/2
    psrld xmm8, 1            ;funny_b/2

    ;dividimos las componentes de los pixeles por dos
    psrld xmm1, 1                ; b/2
    psrld xmm2, 1                ; g/2
    psrld xmm3, 1                ; r/2
    
    paddusb xmm8, xmm1            ; b_funny
    paddusb xmm7, xmm2            ; g_funny
    paddusb xmm6, xmm3            ; r_funny

    pslldq xmm7, 1
    pslldq xmm6, 2

    paddd xmm8, xmm7
    paddd xmm6, xmm8

    movdqu xmm4, [maskA]
    pand xmm0, xmm4 
    por xmm6, xmm0
    
    ;en este punto, xmm6 tiene toda la data lista para escribir
    lea r13, [rsi + r10*4]
    mov rax, r11
    push rdx
    mul r9 
    pop rdx
    add r13, rax
                
    movdqu [r13], xmm6

    add r10, 4
    jmp .ciclo

.chequear_alto:
cmp r11, rcx
je .fin
mov r10, 0
add r11, 1

movdqu xmm9, [cuatroUnos]

paddd xmm5, xmm9


jmp .ciclo

.fin:
pop r12
pop r13
pop rbp
ret
