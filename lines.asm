; #########################################################################
;
;   lines.asm - Assembly file for EECS205 Assignment 2
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here

.CODE


;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved

;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
DrawLine PROC USES eax ebx ecx edx  x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;;	LOCAL foo:DWORD, bar:DWORD
  LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD ,inc_y:DWORD, error:DWORD, curr_x:DWORD, curr_y:DWORD, prev_error:DWORD

	;; Place your code here

    ;; delta x abs
    mov eax, x0
    mov ebx, x1
    sub ebx, eax
    jg end_delta_x
    neg ebx
end_delta_x:
    mov delta_x, ebx

    ;; delta y abs
    mov eax, y0
    mov ebx, y1
    sub ebx, eax
    jg end_delta_y
    neg ebx
end_delta_y:
    mov delta_y, ebx

  ;;First if statement
    mov eax, x0
    mov ebx, x1
    cmp eax, ebx
    jge else_inc_x
    mov inc_x, 1
    jmp end_inc_x
else_inc_x:
    mov inc_x, -1
end_inc_x:

  ;;Second if statement
    mov eax, y0
    mov ebx, y1
    cmp eax, ebx
    jge else_inc_y
    mov inc_y, 1
    jmp end_inc_y
else_inc_y:
    mov inc_y, -1
end_inc_y:

  ;;delta if else
    mov eax, delta_x
    mov ebx, delta_y
    cmp eax, ebx
    jle else_delta
	  xor edx, edx
    mov ecx, 2
    div ecx
    mov error, eax
    jmp end_delta
else_delta:
	  xor edx, edx
    mov ecx, 2
    div ecx
    neg eax
    mov error, eax
end_delta:

;; sets curr variables
  mov eax, x0
  mov ebx, y0
  mov curr_x, eax
  mov curr_y, ebx

  INVOKE DrawPixel, curr_x, curr_y, color

;; Start of while loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  jmp while_cond
start_while:
  INVOKE DrawPixel, curr_x, curr_y, color
  mov eax, error
  mov prev_error, eax

  ;; first if in while that compares prev error and delta x
  mov eax, prev_error
  mov ebx, delta_x
  neg ebx
  cmp eax, ebx
  jle end_error_delta_x

  mov ecx, delta_y
  sub error, ecx
  mov ecx, inc_x
  add curr_x, ecx

end_error_delta_x:

  ;; second if in while that compares prev error and delta y
  mov eax, prev_error
  mov ebx, delta_y
  cmp eax, ebx
  jge end_error_delta_y

  mov ecx, delta_x
  add error, ecx

  mov ecx, inc_y
  add curr_y, ecx

end_error_delta_y:

while_cond:
  mov eax, x1
  cmp curr_x, eax
  jne start_while

  xor eax, eax
  mov eax, y1
  cmp curr_y, eax
  jne start_while

;;End of while loop ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ret        	;;  Don't delete this line...you need it

DrawLine ENDP


END
