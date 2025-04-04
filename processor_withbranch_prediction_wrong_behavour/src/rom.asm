start:
	nop

	; Initialize registers
	imm     0  %d0  ; Counter
	imm	1  %d1  ; Increment
	imm 	10 %d2  ; Loop limit
	imm 	0  %d3  ; Sum
	imm     0  %d4  ; Temp
	imm	0  %d5  ; Result

	; Main loop - Count from 0 to 9
main_loop:
	add     %d0 %d1 ; Increment counter
	add     %d3 %d0 ; Add to sum

	; Check if counter is even or odd
	imm     1  %d4
	and     %d0 %d4 ; Check LSB
	bra     even    ; Branch if result is 0 (even)

	; Odd path
	add     %d5 %d3 ; Add sum to result
	bra     check_limit ; Skip even path

even:
	sub     %d5 %d3 ; Subtract sum from result

check_limit:
	sub     %d0 %d2 ; Compare counter to limit
	bra     end_loop ; Branch if result is 0 (equal)
	bra     main_loop ; Loop back

end_loop:
	nop
	nop

	; Additional branch-heavy code to test prediction
	imm     16 %d0  ; New counter
	imm     1  %d1  ; Decrement

countdown_loop:
	sub     %d0 %d1 ; Decrement counter
	and     %d0 %d4 ; Check LSB
	bra     even_branch ; Branch if result is 0 (even)
	bra     skip_branch ; Skip next branch
	
even_branch:
	bra     continue ; Continue to next instruction

skip_branch:
	nop

continue:
	lop     %d0 countdown_loop ; Loop until counter is 0
	nop
	nop

stop:
	bra     stop
	nop
