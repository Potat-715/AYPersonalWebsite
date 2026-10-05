	; ---------- Do not touch this code--it connects your code to the rest of the program. ----------
	.ORIG x3000
	LEA R0,2
	TRAP x40
	BRnzp 1
	TRAP x42
	; ---------- Do not touch this code--it connects your code to the rest of the program. ----------

	;
	; Whenever your Lab 12 program starts executing, the following register values will be set:
	; R1 -- the address of the player visible array
	; R2 -- the address of the game map array
	; *** Remember: do not use R7 in your program. ***
	;
LAB12_START
	; ---------- Write your lab 12 code starting here. ----------

LEA R0, HEADER
PUTS
	;We are printing out 0123456789 for counting the columns

        AND R4, R4, #0 

ROW_LOOP
	LD R5, ASCII_OFFSET
	ADD R0, R4, R5
	OUT	
	AND R3,R3,#0
	AND R6,R6,#0
	ADD R6,R6,#1
COL_LOOP
	LDR R0, R1, #0
	AND R0, R0, R6
	BRz PRINT_DOT

	LDR R0, R2, #0
	AND R0, R0, R6
	BRz PRINT_DASH
	BRnp PRINT_STAR

PRINT_DOT
	LD R0, DOT_CHAR
	OUT
	BRnzp NEXT_COL
PRINT_DASH
	LD R0, DASH_CHAR
	OUT
	BRnzp NEXT_COL
PRINT_STAR
	LD R0, STAR_CHAR
	OUT
	BRnzp NEXT_COL

NEXT_COL
	ADD R6,R6,R6
	ADD R3,R3,#1
	ADD R0, R3,#-10
	BRn COL_LOOP
	
	LD R0, NEWLINE 
	OUT
	ADD R1, R1, #1
	ADD R2, R2, #1
	ADD R4, R4, #1 
	ADD R0, R4, #-10
	BRn ROW_LOOP 


	; ---------- When your lab 12 code is done, execute this trap. ----------
LAB12DONE	; label for your convenience
	TRAP x41

	; ---------- Put any data that you need for lab 12 here. ----------

HEADER .STRINGZ " 0123456789\n"
DOT_CHAR .FILL x2E
DASH_CHAR .FILL x2D
STAR_CHAR .FILL x2A
ASCII_OFFSET .FILL x30
NEWLINE .FILL x0A
        .END


