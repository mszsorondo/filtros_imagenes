    ;empaquetamos saturando primero a word y luego a byte así ya los tenemos en el tamaño que queremos
    ; packusdw xmm8, xmm8
    ; packusdw xmm7, xmm7
    ; packusdw xmm6, xmm6

    ; packuswb xmm8, xmm8
    ; packuswb xmm7, xmm7
    ; packuswb xmm6, xmm6

    ;Una vez empaquetado todo construimos con los componentes funny nuevos pixeles
    ; movdqu xmm3, [maskBFunny]  
    ; movdqu xmm4, [maskGFunny]
    ; movdqu xmm5, [maskRFunny]
    ; pand xmm8, xmm3
    ; pand xmm7, xmm4
    ; pand xmm6, xmm5
    ; paddd xmm8, xmm7 
    ; paddd xmm6, xmm8
    ; movdqu xmm2, [pixelConstrucThorMask]
    ; pshufb xmm6, xmm2