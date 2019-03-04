; #########################################################################
;
;   game.asm - Assembly file for EECS205 Assignment 4/5
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include \masm32\include\masm32.inc
includelib \masm32\lib\masm32.lib

;; Has keycodes
include keys.inc


.DATA

;; Positions of sprites
birdPos POSN <50,200>
backgroundPos POSN <300,300>
pipePos POSN <600,300>

birdSpeed DWORD 8


.CODE

;object.x + bitmap.width / 2
getRightEdge PROC USES esi wdth:DWORD, objX:DWORD
mov esi, wdth
sar esi, 1
mov eax, objX
add eax, esi
ret
getRightEdge ENDP

;object.x - bitmap.width / 2,
getLeftEdge PROC USES esi wdth:DWORD, objX:DWORD
mov esi, wdth
sar esi, 1
mov eax, objX
sub eax, esi
ret
getLeftEdge ENDP

;object.y - bitmap.height / 2
getTopEdge PROC USES esi hght:DWORD, objY:DWORD
mov esi, hght
sar esi, 1
mov eax, objY
add eax, esi
ret
getTopEdge ENDP

;object.y + bitmap.height / 2
getBottomEdge PROC USES esi hght:DWORD, objY:DWORD
mov esi, hght
sar esi, 1
mov eax, objY
sub eax, esi
ret
getBottomEdge ENDP


;; Note: You will need to implement CheckIntersect!!!
CheckIntersect PROC oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
  LOCAL oneWidth:DWORD, oneHeight:DWORD, twoWidth:DWORD, twoHeight:DWORD

   mov edx, oneBitmap    ;get object one's width and height
   mov edi, (EECS205BITMAP PTR[edx]).dwWidth
   mov oneWidth, edi
   mov edi, (EECS205BITMAP PTR[edx]).dwHeight
   mov oneHeight, edi

   mov ecx, twoBitmap    ;get object two's width and height
   mov esi, (EECS205BITMAP PTR[ecx]).dwWidth
   mov twoWidth, esi
   mov esi, (EECS205BITMAP PTR[ecx]).dwHeight
   mov twoHeight, esi


;case 1: right edge of one is less than the left edge of two
  ;get right edge of box one
  INVOKE getRightEdge, oneWidth, oneX
  mov esi, eax
  ;get left edge of box two
  INVOKE getLeftEdge, twoWidth, twoX
  ;check for intersection
  cmp esi, eax
  jle NoIntersection ;if right edge of one is less than left edge of two, no intersection


;case 2: left edge of one intersects with right edge of two
  ;get left edge of box 1
  INVOKE getLeftEdge, oneWidth, oneX
  mov esi, eax
  ;get right edge of box2
  INVOKE getRightEdge, twoWidth, twoX
  ;check for intersection
  cmp esi, eax
  jge NoIntersection ;if left edge of one is greater than right edge of two, no intersection


;case 3: bottom edge of one intersects with top edge of two
  ;get bottom edge of box 1
  INVOKE getBottomEdge, oneHeight, oneY
  mov esi, eax
  ;get top edge of box 2
  INVOKE getTopEdge, twoHeight, twoY
  ;check for intersection
  cmp esi, eax
  jge NoIntersection ;if bottom edge of one is greater than top edge of two, no intersection


;case 4: top edge of one intersects with bottom edge of two
  ;get top edge of box 1
  INVOKE getTopEdge, oneHeight, oneY
  mov esi, eax
  ;get bottom edge of box 2
  INVOKE getBottomEdge, twoHeight, twoY
  ;check for intersection
  cmp esi, eax
  jle NoIntersection ;if top edge of one is less than bottom edge of two, no intersection

  mov eax, 1  ;return non-zero value if there is intersection
  jmp result

NoIntersection:
  mov eax, 0

result:
   ret 			; Don't delete this line!!!


  ret         ;; Do not delete this line!!!
CheckIntersect ENDP

RedrawScreen PROC USES eax edi ecx
  ;clears screen
  mov eax, 0
  mov edi, ScreenBitsPtr
  mov ecx, 307200
  REP STOSB

  ;arrow outlines at top
  INVOKE BasicBlit, OFFSET bird, birdPos.x, birdPos.y
  INVOKE BasicBlit, OFFSET pipe, pipePos.x, pipePos.y

  ret
RedrawScreen ENDP

GameInit PROC

INVOKE BasicBlit, OFFSET bird, birdPos.x, birdPos.y
INVOKE BasicBlit, OFFSET pipe, pipePos.x, pipePos.y
;;INVOKE BasicBlit, OFFSET background, backgroundPos.x, backgroundPos.y

	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC USES edx

  ;;mov edx, birdSpeed

  INVOKE RedrawScreen

  cmp KeyPress, 20h ; Space key
  je SPACE_PRESSED
  add birdPos.y, 8
  jmp END_MOVE_BIRD

SPACE_PRESSED:
  sub birdPos.y, 8

END_MOVE_BIRD:

sub pipePos.x, 10

INVOKE CheckIntersect, birdPos.x, birdPos.y, OFFSET bird, pipePos.x, pipePos.y, OFFSET pipe
cmp eax, 1
jne NO_COLLISION

COLLISION:
  add pipePos.x, 600

NO_COLLISION:

	ret         ;; Do not delete this line!!!
GamePlay ENDP

END
