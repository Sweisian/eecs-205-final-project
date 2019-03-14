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

include \masm32\include\windows.inc
include \masm32\include\winmm.inc
includelib \masm32\lib\winmm.lib

include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib
include \masm32\include\masm32.inc
includelib \masm32\lib\masm32.lib


;; Has keycodes
include keys.inc


.DATA

;; Variables of game object speeds and physics values
birdVelocityUp DWORD 8
backSpeed FXPT 4
pipeSpeed FXPT 10
pipeSpeedInc FXPT 1
birdVertVelocity DWORD 0
birdGravity DWORD -1

;; Positions of sprites
birdPos POSITION <50,200>
pipePos POSITION <700,100>
backOnePos POSITION <288,250>
backTwoPos POSITION <576,250>
backThreePos POSITION <864,250>
backFourPos POSITION <1152,250>
gameOverPos POSITION <640,230>

;; Positions of spawnpoints
backSpawn POSITION <1152,250>
pipeSpawn POSITION <720,300>

;; pause state Variables
isPaused DWORD -1
isGameOver DWORD -1

; Path to sound file
SndPath BYTE "Flappy_Bird_Theme_Song_Loop.wav", 0


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

; clears and redraws sprites on the screen. Called once per update. Does not handle game over image
RedrawScreen PROC USES eax edi ecx
  ;clears screen
  mov eax, 0
  mov edi, ScreenBitsPtr
  mov ecx, 307200
  REP STOSB

;; redraws bit maps in their new spots (since last update)

  INVOKE BasicBlit, OFFSET background, backOnePos.x, backOnePos.y
  INVOKE BasicBlit, OFFSET background, backTwoPos.x, backTwoPos.y
  INVOKE BasicBlit, OFFSET background, backThreePos.x, backThreePos.y
  INVOKE BasicBlit, OFFSET background, backFourPos.x, backFourPos.y
  INVOKE BasicBlit, OFFSET pipe, pipePos.x, pipePos.y
  INVOKE BasicBlit, OFFSET bird, birdPos.x, birdPos.y


  ret
RedrawScreen ENDP

; Returns the displacement from the current bird y value
CalcBirdDisplacement PROC USES ecx

  mov ecx, birdVertVelocity
  add ecx, birdGravity
  mov birdVertVelocity, ecx
  mov eax, birdVertVelocity

  ret
CalcBirdDisplacement ENDP

; Moves the background images. If any of them go off the screen, it moves them them to the spawn point off the right side of the screen
MoveBackground PROC USES ecx

mov ecx, backSpeed

sub backOnePos.x, ecx
sub backTwoPos.x, ecx
sub backThreePos.x, ecx
sub backFourPos.x, ecx

mov ecx, backSpawn.x

cmp backOnePos.x, 0
jg BACK_ONE_STILL_ON_SCREEN
mov backOnePos.x, ecx

BACK_ONE_STILL_ON_SCREEN:

cmp backTwoPos.x, 0
jg BACK_TWO_STILL_ON_SCREEN
mov backTwoPos.x, ecx

BACK_TWO_STILL_ON_SCREEN:

cmp backThreePos.x, 0
jg BACK_THREE_STILL_ON_SCREEN
mov backThreePos.x, ecx

BACK_THREE_STILL_ON_SCREEN:

cmp backFourPos.x, 0
jg BACK_FOUR_STILL_ON_SCREEN
mov backFourPos.x, ecx

BACK_FOUR_STILL_ON_SCREEN:


  ret
MoveBackground ENDP


; Kicks off the sound loop and starts the random number generation
GameInit PROC

  INVOKE PlaySound, offset SndPath, 0, SND_FILENAME OR SND_ASYNC OR SND_LOOP
  rdtsc
  INVOKE nseed, eax

	ret         ;; Do not delete this line!!! GameInit ENDP

GameInit ENDP


GamePlay PROC USES eax ecx


;; Check for pause!
  cmp KeyDown, 50h ; "p" key
  jne PAUSE_NOT_PRESSED
  mov KeyDown, 0
  neg isPaused

PAUSE_NOT_PRESSED:
  cmp isPaused, 1
  je END_GAME_LOOP


  INVOKE MoveBackground


;Check if space is pressed. If so, add vertical veloctiy to bird
  mov ecx, birdVelocityUp
  cmp KeyDown, 20h ; Space key
  jne MOVE_BIRD
  mov KeyDown, 0
  mov birdVertVelocity, ecx

MOVE_BIRD:
  INVOKE CalcBirdDisplacement
  sub birdPos.y, eax

END_MOVE_BIRD:
  mov ecx, pipeSpeed
  sub pipePos.x, ecx

;; Check to see if bird has hit pipe or not. If didged, respawn pipe and make it faster
  INVOKE CheckIntersect, birdPos.x, birdPos.y, OFFSET bird, pipePos.x, pipePos.y, OFFSET pipe
  cmp eax, 1
  jne NO_COLLISION

COLLISION:
;; Change this to be gameover sometime in next Assignment
  mov isGameOver, 1

NO_COLLISION:
  cmp pipePos.x, 0
  jg PIPE_STILL_ON_SCREEN
  mov ecx, pipeSpawn.x
  mov pipePos.x, ecx
  mov ecx, pipeSpeedInc
  add pipeSpeed, ecx


; Randomly decide which side of screen to spawn pipe and how far to stick it out
  INVOKE nrandom, 2
  cmp eax, 0
  jne SPAWN_DOWN_PIPE
SPAWN_UP_PIPE:
  INVOKE nrandom, 200
  add eax, 300
  mov pipePos.y, eax
  jmp END_PIPE_SPAWN

SPAWN_DOWN_PIPE:
  INVOKE nrandom, 130
  mov pipePos.y, eax

END_PIPE_SPAWN:

PIPE_STILL_ON_SCREEN:

; check if the bird is out of bounds. If so, end game
cmp birdPos.y, 0
jl BIRD_OUT_OF_BOUNDS

cmp birdPos.y, 480
jg BIRD_OUT_OF_BOUNDS

jmp BIRD_IN_BOUNDS

BIRD_OUT_OF_BOUNDS:
mov isGameOver, 1


BIRD_IN_BOUNDS:

INVOKE RedrawScreen

;Check for gameover state. If so, draw the game over image
cmp isGameOver, 1
jne END_GAME_LOOP
INVOKE BasicBlit, OFFSET game_over, gameOverPos.x, gameOverPos.y
mov isPaused, 1

END_GAME_LOOP:

	ret         ;; Do not delete this line!!!
GamePlay ENDP

END
