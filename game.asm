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

;; Variables of game object speeds
birdSpeed FXPT 8
pipeSpeed FXPT 10
pipeSpeedInc FXPT 1

;; Positions of sprites
birdPos POSITION <50,200>
backgroundPos POSITION <300,300>
pipePos POSITION <700,300>
pipeSpawn POSITION <700,300>


.CODE

;object.x + bitmap.my_my_my_my_my_my_width / 2
getRight PROC USES edx my_width:DWORD, objXcoord:DWORD
mov edx, my_width
sar edx, 1
mov eax, objXcoord
add eax, edx
ret
getRight ENDP

;object.x - bitmap.width / 2,
getLeft PROC USES edx my_width:DWORD, objXcoord:DWORD
mov edx, my_width
sar edx, 1
mov eax, objXcoord
sub eax, edx
ret
getLeft ENDP

;object.y - bitmap.height / 2
getTop PROC USES edx my_height:DWORD, objYcoord:DWORD
mov edx, my_height
sar edx, 1
mov eax, objYcoord
add eax, edx
ret
getTop ENDP

;object.y + bitmap.height / 2
getBot PROC USES edx my_height:DWORD, objYcoord:DWORD
mov edx, my_height
sar edx, 1
mov eax, objYcoord
sub eax, edx
ret
getBot ENDP


;; Note: You will need to implement CheckIntersect!!!
CheckIntersect PROC USES edi edx ecx esi oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
    LOCAL oneWidth:DWORD, oneHeight:DWORD, twoWidth:DWORD, twoHeight:DWORD

     mov edx, oneBitmap    ;get object one's width and height
     mov edi, (EECS205BITMAP PTR[edx]).dwWidth
     mov oneWidth, edi
     mov edi, (EECS205BITMAP PTR[edx]).dwHeight
     mov oneHeight, edi

     mov edx, twoBitmap    ;get object two's width and height
     mov edi, (EECS205BITMAP PTR[edx]).dwWidth
     mov twoWidth, edi
     mov edi, (EECS205BITMAP PTR[edx]).dwHeight
     mov twoHeight, edi

  ;case 1: right edge of one is less than the left edge of two
    INVOKE getRight, oneWidth, oneX
    mov esi, eax
    INVOKE getLeft, twoWidth, twoX
    cmp esi, eax
    jle NO_INTERSECTION

  ;case 2: left edge of one intersects with right edge of two
    INVOKE getLeft, oneWidth, oneX
    mov esi, eax
    INVOKE getRight, twoWidth, twoX
    cmp esi, eax
    jge NO_INTERSECTION

  ;case 3: bottom edge of one intersects with top edge of two
    INVOKE getBot, oneHeight, oneY
    mov esi, eax
    INVOKE getTop, twoHeight, twoY
    cmp esi, eax
    jge NO_INTERSECTION

  ;case 4: top edge of one intersects with bottom edge of two
    INVOKE getTop, oneHeight, oneY
    mov esi, eax
    INVOKE getBot, twoHeight, twoY
    cmp esi, eax
    jle NO_INTERSECTION

  ;return 1 if we have detected a collision
    mov eax, 1
    jmp RESULT

  NO_INTERSECTION:
    mov eax, 0

  RESULT:

    ret         ;; Do not delete this line!!!
CheckIntersect ENDP

RedrawScreen PROC USES eax edi ecx
  ;clears screen
  mov eax, 0
  mov edi, ScreenBitsPtr
  mov ecx, 307200
  REP STOSB

;; redraws bit maps in their new spots (since last update)
  INVOKE BasicBlit, OFFSET bird, birdPos.x, birdPos.y
  INVOKE BasicBlit, OFFSET pipe, pipePos.x, pipePos.y

  ret
RedrawScreen ENDP

GameInit PROC

	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC USES eax ecx

  mov ecx, birdSpeed

  INVOKE RedrawScreen

;Check if mouse button 1 or space is pressed. If so, move bird higher
;if nothing pressed, make bird fall
  cmp KeyPress, 20h ; Space key
  je MOVE_BIRD_UP

  cmp MouseStatus.buttons, 01h ;Gets mouse one
  je MOVE_BIRD_UP

  add birdPos.y, ecx
  jmp END_MOVE_BIRD

MOVE_BIRD_UP:
  sub birdPos.y, ecx

END_MOVE_BIRD:
  mov ecx, pipeSpeed
  sub pipePos.x, ecx

;; Check to see if bird has hit pipe or not. If didged, respawn pipe and make it faster
  INVOKE CheckIntersect, birdPos.x, birdPos.y, OFFSET bird, pipePos.x, pipePos.y, OFFSET pipe
  cmp eax, 1
  jne NO_COLLISION

COLLISION:
;; Change this to be gameover sometime in next Assignment
  mov ecx, pipeSpawn.x
  mov pipePos.x, ecx

NO_COLLISION:

  cmp pipePos.x, 0
  jg PIPE_STILL_ON_SCREEN
  mov ecx, pipeSpawn.x
  mov pipePos.x, ecx
  mov ecx, pipeSpeedInc
  add pipeSpeed, ecx


PIPE_STILL_ON_SCREEN:

	ret         ;; Do not delete this line!!!
GamePlay ENDP

END
