
;#########################################################################
;
;   trig.asm - Assembly file for EECS205 Assignment 3
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

include trig.inc
include blit.inc
include lines.inc
include stars.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI
TWO_PI	= 411774                ;;  2 * PI
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)

.CODE

FixedMul PROC USES edx ebx a:FXPT, b:FXPT
  mov eax, a
  mov ebx, b
  imul ebx
  shl edx, 16                 ; get integer portion
  shr eax, 16                 ; get fraction portion
  add eax, edx                ; combine portions to make fixed point
  ret
FixedMul ENDP


FixedSin PROC USES esi edi ecx angle:FXPT

	mov esi, angle

	;first, check to see which quadrant the input angle is in
	;if input is out of range (not in [0,2pi)), jump into another section to correct input


CHECK:
	cmp esi, 0
	jl PosAngle				;if angle is less than zero, keep adding 2pi until its positive
	cmp esi, PI_HALF		;if at this point, angle is greater than or equal to zero
	jl CONT1				;jump if angle is less than pi/2 (in quadrant 1)
  je MANUAL_SET
	cmp esi, PI				;if at this point, angle is greater than or equal to pi/2
	jl QUAD_TWO				;jump if angle is greater than pi/2 but less than pi
	cmp esi, PI + PI_HALF   ;if at this point, angle is greater than or equal to pi
	jl QUAD_THREE			;jump if angle is greater than pi but less than 3pi/2
	cmp esi, TWO_PI			;if at this point, angle is greater than or equal to 3pi/2
	jl QUAD_FOUR			;jump if angle is greater than 3pi/2 but less than 2pi
	jmp ReduceAngle			;if at this point, angle is greater than or equal to 2pi

QUAD_TWO:

	mov edi, PI
	sub edi, esi				;sin (x) = sin (Pi � x) (for Pi/2 < x < Pi), so compute Pi-angle
	mov esi, edi
	jmp CONT1

QUAD_THREE:

    sub esi, PI
	jmp CONT2

QUAD_FOUR:

	sub esi, PI
	neg esi
	add esi, PI
	jmp CONT2

PosAngle:					;make negative angles positive by adding 2pi

	cmp esi, 0
	jge CHECK
	add esi, TWO_PI
	jmp PosAngle

ReduceAngle:				;correct angles to be below 2pi

	cmp esi, TWO_PI
	jl CHECK
	sub esi, TWO_PI
	jmp ReduceAngle

CONT1:										                ; don't negate table lookup

  	Invoke FixedMul, esi, PI_INC_RECIP		;get fixed-point index
  	shr eax, 16								            ;get index as integer
    mov cx, [SINTAB + 2*eax]		          ;lookup SINTAB[index]
    movzx eax, cx							            ;move sine table value into eax to return
	jmp PROC_END

CONT2:						                      	; negate table lookup

 	Invoke FixedMul, esi, PI_INC_RECIP		    ;get fixed-point index
  	shr eax, 16								              ;get index as integer
    mov cx, [SINTAB + 2*eax]		            ;lookup SINTAB[index]
    movzx eax, cx							              ;move sine table value into eax to return
	  neg eax
	  jmp PROC_END

MANUAL_SET:                                  ;since SINTAB doesn't have value for pi/2, manually set it here
  mov eax, 00010000h
  ret

PROC_END:

	ret			; Don't delete this line!!!
FixedSin ENDP

FixedCos PROC USES esi angle:FXPT


	mov esi, angle
	add esi, PI_HALF
	Invoke FixedSin, esi
	ret			; Don't delete this line!!!

FixedCos ENDP

END
