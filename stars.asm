; #########################################################################
;
;   stars.asm - Assembly file for EECS205 Assignment 1
;   
;   NAME: RYAN SWEI
;   NETID: RSS1760
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc

	;; Hardcoded coords for 20 stars
      invoke DrawStar, 200, 240
      invoke DrawStar, 100, 300
      invoke DrawStar, 150, 170
      invoke DrawStar, 175, 250

      invoke DrawStar, 320, 440
      invoke DrawStar, 350, 380
      invoke DrawStar, 370, 350
      invoke DrawStar, 420, 400

      invoke DrawStar, 215, 470
      invoke DrawStar, 123, 390
      invoke DrawStar, 157, 415
      invoke DrawStar, 199, 450

      invoke DrawStar, 500, 210
      invoke DrawStar, 550, 140
      invoke DrawStar, 600, 260
      invoke DrawStar, 630, 170

      invoke DrawStar, 320, 50
      invoke DrawStar, 340, 70
      invoke DrawStar, 300, 35
      invoke DrawStar, 280, 100


	ret  			; Careful! Don't remove this line
DrawStarField endp



END
