; #########################################################################
;
;   blit.asm - Assembly file for EECS205 Assignment 3
;
;
; #########################################################################

; *************************************************************************
;	Name: Ryan Swei
; *************************************************************************


      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc


.DATA

	;; If you need to, you can place global variables here

.CODE

;repeat of fixed multiplcation function for blit file
FixedMul2 PROC USES edx ebx a:FXPT, b:FXPT
  mov eax, a
  mov ebx, b
  imul ebx
  shl edx, 16                 ; get integer portion
  shr eax, 16                 ; get fraction portion
  add eax, edx                ; combine portions to make fixed point
  ret
FixedMul2 ENDP

DrawPixel PROC USES ebx esi ecx x:DWORD, y:DWORD, color:DWORD

; given coordiantes (x,y), the index of the backbuffer is given by:
; index = (# elem per row)*y + x
; in our case, the number of elements per row is 640 (screen width)

;check input to make sure coordinates are in bounds of backbuffer
	cmp x,640
	jge OutOfBounds
	cmp x, 0
	jl OutOfBounds
	cmp y,480
	jge OutOfBounds
	cmp y,0
	jl OutOfBounds

	mov eax, 640							;eax <- screen width
	mov esi, y								;esi <- y
	imul esi									;eax <- 640*y
	add eax, x								;eax holds correct index... eax <-640*y+x
	mov ecx, color							;move color into register so we can later grab LSByte
	add eax, ScreenBitsPtr
	mov BYTE PTR [eax], cl					;place LSByte of color in backbuffer
	ret 									; Don't delete this line!!!

OutOfBounds:
	ret

DrawPixel ENDP

BasicBlit PROC USES edx ebx ecx esi edi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD

    LOCAL xc:DWORD, yc:DWORD, dwWidth: DWORD, dwHeight: DWORD, tempX:DWORD, tempY:DWORD, transp:BYTE, colorStart:DWORD

    mov esi, ptrBitmap								;esi holds ptrBitmap

	mov al, (EECS205BITMAP PTR [esi]).bTransparent	;store transparency color in local
	mov transp, al

	mov edx, (EECS205BITMAP PTR [esi]).lpBytes
	mov colorStart, edx								;store start of bitmap color array in local

	;get starting x coordinate
    mov ecx, (EECS205BITMAP PTR[esi]).dwWidth
    mov dwWidth, ecx								;store width of bitmap in local
    sar eax, 1										;divide width by 2
    mov edx, xcenter
    sub edx, ecx									;edx <- xcenter - dwWidth/2
    mov xc, edx										;xc holds starting x coordinate

	;get starting y coordinate
    mov ecx, (EECS205BITMAP PTR[esi]).dwHeight
    mov dwHeight, ecx								;store height of bitmap in local
    sar ecx, 1										;divide height by 2
    mov edx, ycenter
    sub edx, ecx									;edx <- ycenter - dwHeight/2
    mov yc, edx

    xor edi, edi									;initialize y to 0

	OuterLoopCheck:
		cmp edi, dwHeight									;go to outer loop if y < dwHeight
		jge bb_end											;didn't meet outer loop condition
															;fall through to outer loop

	OuterLoop:
		xor ecx, ecx										;initialize x to 0
															;fall through to inner loop check

	InnerLoopCheck:
        cmp ecx, dwWidth  ; if x < dwWidth, do inner loop again
        jl InnerLoop
		add edi, 1											;increment outer loop
		jmp OuterLoopCheck

	InnerLoop:
        ;First, find index for pixel color
		;index = y*dwWidth + x
        mov eax, dwWidth
        imul edi                                      ;eax <- y*dwWidth
        add eax, ecx                                  ;eax <- y*dwWidth + x, so eax holds index

        ;Then, get the color of the pixel with index we just found
        add eax, colorStart							  ;get color of pixel
        mov dl, BYTE PTR [eax]						  ;dl holds 8 bit quanity of color of the pixel.


		;calculate current coordinates
		mov ebx, ecx
		add ebx, xc
		mov tempX, ebx								;tempX <- x + xc
		mov ebx, edi
		add ebx, yc
		mov tempY, ebx								;tempY <- y + yc

		;make sure current coordinates are within screen bounds
        cmp tempX, 0
        jl cont
        cmp tempX, 639
        jg cont
        cmp tempY, 0
        jl cont
        cmp tempY, 479
        jg cont

        cmp transp, dl                                      ;Don't draw pixels if current coordinates should be transparent
        je cont

        invoke DrawPixel, tempX, tempY, dl					;draw next pixel if previous checks pass

    cont:
        add ecx, 1											;increment inner loop
		jmp InnerLoopCheck

	bb_end:

    ret

BasicBlit ENDP

RotateBlit PROC USES ebx ecx edx esi edi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT

  LOCAL cosa:FXPT,sina:FXPT
  LOCAL shiftX:DWORD,shiftY:DWORD, dstX:DWORD, dstY:DWORD, dstWidth:DWORD, dstHeight:DWORD, srcX:DWORD, srcY:DWORD
  LOCAL xc:DWORD, yc:DWORD
  LOCAL dwWidth:DWORD, dwHeight:DWORD, transp:BYTE

  INVOKE FixedCos, angle
  mov cosa, eax
  INVOKE FixedSin, angle
  mov sina, eax

  ;esi <- bitmap pointer
  mov esi, lpBmp

  ;store bitmap data in locals
  mov eax, (EECS205BITMAP PTR[esi]).dwWidth
  mov dwWidth, eax
  mov eax, (EECS205BITMAP PTR[esi]).dwHeight
  mov dwHeight, eax
  mov al, (EECS205BITMAP PTR [esi]).bTransparent
  mov transp, al

  ;(EECS205BITMAP PTR [esi]).dwWidth * cosa / 2
  mov ecx, dwWidth
  sal ecx, 16                     ;make dwWidth fixed point
  INVOKE FixedMul2, ecx, cosa     ;(EECS205BITMAP PTR [esi]).dwWidth * cosa
  mov ecx, eax                    ;copy out contents of eax reg because it is needed to hold function call returns
  mov edi, 00008000h              ;1/2 in fixed point
  INVOKE FixedMul2, ecx, edi      ;(EECS205BITMAP PTR [esi]).dwWidth * cosa / 2
  mov shiftX, eax

  ;(EECS205BITMAP PTR[esi]).dwHeight * sina / 2
  mov ecx, dwHeight
  sal ecx, 16                     ;make dwHeight fixed point
  INVOKE FixedMul2, ecx, sina     ;(EECS205BITMAP PTR [esi]).dwHeight * sina
  mov ecx, eax                    ;copy out contents of eax reg because it is needed to hold function call returns
  mov edi, 00008000h              ;1/2 in fixed point
  INVOKE FixedMul2, ecx, edi      ;(EECS205BITMAP PTR [esi]).dwHeight * sina / 2
  sub shiftX, eax                 ;shiftX = (EECS205BITMAP PTR [esi]).dwWidth * cosa / 2 - (EECS205BITMAP PTR[esi]).dwHeight * sina / 2
  sar shiftX, 16                  ;convert fixed to int

  ;(EECS205BITMAP PTR [esi]).dwHeight * cosa / 2
  mov ecx, dwHeight
  sal ecx, 16                     ;make dwHeight fixed point
  INVOKE FixedMul2, ecx, cosa     ;(EECS205BITMAP PTR [esi]).dwHeight * cosa
  mov ecx, eax                    ;copy out contents of eax reg because it is needed to hold function call returns
  mov edi, 00008000h              ;1/2 in fixed point
  INVOKE FixedMul2, ecx, edi      ;(EECS205BITMAP PTR [esi]).dwHeight * cosa / 2

  mov shiftY, eax


  ;(EECS205BITMAP PTR[esi]).dwWidth * sina / 2
  mov ecx, dwWidth
  sal ecx, 16                     ;make dwWidth fixed point
  INVOKE FixedMul2, ecx, sina     ;(EECS205BITMAP PTR [esi]).dwWidth * sina
  mov ecx, eax                    ;copy out contents of eax reg because it is needed to hold function call returns
  mov edi, 00008000h              ;1/2 in fixed point
  INVOKE FixedMul2, ecx, edi      ;(EECS205BITMAP PTR [esi]).dwWidth * sina / 2

  add shiftY, eax                 ;shiftY = (EECS205BITMAP PTR [esi]).dwHeight * cosa / 2 + (EECS205BITMAP PTR[esi]).dwWidth * sina / 2
  sar shiftY, 16                  ;convert fixed to int

  mov ecx, dwWidth
  add ecx, dwHeight
  mov dstWidth, ecx
  mov dstHeight, ecx

  ;initialize outer loop variable
  mov ecx, dstWidth
  neg ecx
  mov dstX, ecx                             ; dstX = -dstWidth
                                            ;fall through to outer loop check

OuterLoopCheck:
  mov ecx, dstWidth
  cmp dstX, ecx
  jge rb_end
                                            ;fall through to outer loop
OuterLoop:
  mov ecx, dstHeight
  neg ecx
  mov dstY, ecx                             ; dstY = -dstHeight

InnerLoopCheck:
  mov ecx, dstHeight
  cmp dstY, ecx                            ;if dstY < dstHeight
  jl InnerLoop
  add dstX, 1                              ;increment dstX (outer loop variable)
  jmp OuterLoopCheck

InnerLoop:

;calculate srcX
  mov ebx, dstX
  sal ebx, 16                               ;convert dstX to fixed point
  INVOKE FixedMul2, ebx, cosa
  sar eax, 16
  mov edi, eax                              ; edi <- dstX*cosa
  mov ebx, dstY
  sal ebx, 16
  INVOKE FixedMul2, ebx, sina
  sar eax, 16                               ;eax <- dstY*sina
  add edi, eax
  mov srcX, edi                               ; srcX = dstX*cosa + dstY*sina

;calculate srcY
  mov ebx, dstY
  sal ebx, 16                                ;convert dstY to fixed point
  INVOKE FixedMul2, ebx, cosa
  sar eax, 16
  mov edi, eax                                ;edi<- dstY*cosa
  mov ebx, dstX
  sal ebx, 16                                 ;convert dstX to fixed point
  INVOKE FixedMul2, ebx, sina
  sar eax, 16                                 ;eax <- dstX*sina
  sub edi, eax
  mov srcY, edi                                 ;srcY = dstY*cosa – dstX*sina

  ;Checks to make sure pixel is within bounds

  ;srcX >= 0 && srcX < (EECS205BITMAP PTR [esi]).dwWidth
  cmp srcX, 0
  jl cont
  mov ebx, dwWidth
  cmp srcX, ebx
  jg cont

  ;srcY >= 0 && srcY < (EECS205BITMAP PTR [esi]).dwHeight
  cmp srcY, 0
  jl cont
  mov ebx, dwHeight
  cmp srcY, ebx
  jge cont

  ;calculate (xcenter+dstX-​shiftX)
  mov ebx, xcenter
  add ebx, dstX
  sub ebx, shiftX

  ;(xcenter+dstX- shiftX) >= 0 && (xcenter+dstX -shiftX) < 639
  cmp ebx, 0
  jl cont
  cmp ebx, 639
  jge cont

  ;calculate (ycenter+dstY​-shiftY)
  mov ecx, ycenter
  add ecx, dstY
  sub ecx, shiftY

  ;(ycenter+dstY -shiftY) >= 0 && (ycenter+dstY -shiftY) < 479
  cmp ecx, 0
  jl cont
  cmp ecx, 479
  jge cont

  ;transparency color checks
  mov eax, dwWidth                                    ;get index of color in lpBytes
  imul srcY
  add eax, srcX                                       ;index = srcY*dwWidth + srcX
  add eax, (EECS205BITMAP PTR [esi]).lpBytes          ;get memory location of color
  mov dl, BYTE PTR [eax]                              ;get 8-bit color from array
  cmp transp, dl                                      ;if current color matches transparency color, don't draw
  je cont
  invoke DrawPixel, ebx, ecx, dl                     ;DrawPixel(xcenter+dstX- shiftX, ycenter+dstY -shiftY,bitmap pixel)

cont:
  add dstY, 1                                  ;increment inner loop variable
  jmp InnerLoopCheck

rb_end:

  ret			; Don't delete this line!!!
RotateBlit ENDP


END
