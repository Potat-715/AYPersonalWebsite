; The code given to you here implements the histogram calculation that 
; we developed in class.  In programming lab, we will add code that
; prints a number in hexadecimal to the monitor.
	.ORIG	x3000		; starting address is x3000

; Count the occurrences of each letter (A to Z) in an ASCII string 
; terminated by a NUL character.  Lower case and upper case should 
; be counted together, and a count also kept of all non-alphabetic 
; characters (not counting the terminal NUL).
;
; The string starts at x4000.
;
; The resulting histogram (which will NOT be initialized in advance) 
; should be stored starting at x3F00, with the non-alphabetic count 
; at x3F00, and the count for each letter in x3F01 (A) through x3F1A (Z).
;
; table of register use in this part of the code
;    R0 holds a pointer to the histogram (x3F00)
;    R1 holds a pointer to the current position in the string
;       and as the loop count during histogram initialization
;    R2 holds the current character being counted
;       and is also used to point to the histogram entry
;    R3 holds the additive inverse of ASCII '@' (xFFC0)
;    R4 holds the difference between ASCII '@' and 'Z' (xFFE6)
;    R5 holds the difference between ASCII '@' and '`' (xFFE0)
;    R6 is used as a temporary register
;

	LD R0,HIST_ADDR      	; point R0 to the start of the histogram
	
	; fill the histogram with zeroes 
	AND R6,R6,#0		; put a zero into R6
	LD R1,NUM_BINS		; initialize loop count to 27
	ADD R2,R0,#0		; copy start of histogram into R2

	; loop to fill histogram starts here
HFLOOP	STR R6,R2,#0		; write a zero into histogram
	ADD R2,R2,#1		; point to next histogram entry
	ADD R1,R1,#-1		; decrement loop count
	BRp HFLOOP		; continue until loop count reaches zero

	; initialize R1, R3, R4, and R5 from memory
	LD R3,NEG_AT		; set R3 to additive inverse of ASCII '@'
	LD R4,AT_MIN_Z		; set R4 to difference between ASCII '@' and 'Z'
	LD R5,AT_MIN_BQ		; set R5 to difference between ASCII '@' and '`'
	LD R1,STR_START		; point R1 to start of string

	; the counting loop starts here
COUNTLOOP
	LDR R2,R1,#0		; read the next character from the string
	BRz PRINT_HIST		; found the end of the string

	ADD R2,R2,R3		; subtract '@' from the character
	BRp AT_LEAST_A		; branch if > '@', i.e., >= 'A'
NON_ALPHA
	LDR R6,R0,#0		; load the non-alpha count
	ADD R6,R6,#1		; add one to it
	STR R6,R0,#0		; store the new non-alpha count
	BRnzp GET_NEXT		; branch to end of conditional structure
AT_LEAST_A
	ADD R6,R2,R4		; compare with 'Z'
	BRp MORE_THAN_Z         ; branch if > 'Z'

; note that we no longer need the current character
; so we can reuse R2 for the pointer to the correct
; histogram entry for incrementing
ALPHA	ADD R2,R2,R0		; point to correct histogram entry
	LDR R6,R2,#0		; load the count
	ADD R6,R6,#1		; add one to it
	STR R6,R2,#0		; store the new count
	BRnzp GET_NEXT		; branch to end of conditional structure

; subtracting as below yields the original character minus '`'
MORE_THAN_Z
	ADD R2,R2,R5		; subtract '`' - '@' from the character
	BRnz NON_ALPHA		; if <= '`', i.e., < 'a', go increment non-alpha
	ADD R6,R2,R4		; compare with 'z'
	BRnz ALPHA		; if <= 'z', go increment alpha count
	BRnzp NON_ALPHA		; otherwise, go increment non-alpha

GET_NEXT
	ADD R1,R1,#1		; point to next character in string
	BRnzp COUNTLOOP		; go to start of counting loop



PRINT_HIST

;Description:
;Every new line we need to find a way to create a new label for the next character
;Printing out label character with a space
;Pull data from pointer
;store data into a register (r1)
;Take the nibble of R1 msb by left shifting and putting it into R2 as its 4 LSB 
;Convert the 4 LSB R2 into a HEX Value
;Check to see if it between 0-9 or A-F
;Print Hex value 
;Repeat for 4 times to get the entire Memory and print a new line 
;Repeat the whole entire process until we have all 26 letters plus one non-character 

; Registers:
;r0 – temp register used mainly for OUT. Occasionally used to for miscellaneous temp variables
;r1 – memory from the pointer where its 4 MSB will be the 4 LSB in R2
;r2 – 4 LSB is from the 4 MSB and is used to convert to HEX values 
;r3 – Counter register for counting how many bits from R1 moved to R2 (4)
;r4 – Counter pointer for HIST_ADDR keeps track of where to pull (4)
;r5 – Counter variable for outer loop (0-26)
;r6 – Counter register for character counter (4) 

AND R5, R5, #0         ;initializes R5

PRINT_LOOP             ; Start of Outer loop
LD R0, ASCII_AT        ; Loads @ into R0 (Starting ASCII value for histogram)
ADD R0, R0, R5          ; Updates ASCII in R0 to the corresponding letter using R5
OUT                             ; Prints out the ASCII character currently in R0
LD R0, SPACE             ; Loads ‘ ‘ into R0 
OUT			; Prints Space

STORING                  ; Loop stores current memory from pointer into R1
LD R4, HIST_ADDR  ; Load Address x3F00 into R4
ADD R4, R4, R5 	; R4 gets updated to the updated pointer
LDR R1, R4, #0 	; Stores updated pointer into R1
AND R6, R6, #0	; Initialize R6
ADD R6, R6, #4	; Setup character counter (4 loops)

MSB2LSB		; Loop for storing R1 4 MSB and storing it in R2 LSB
AND R2, R2, #0  	; Initialize R2
AND R3, R3, #0 	; Initialize R3
ADD R3, R3, #4 	; Setup bit counter (4 loops)

EXTRACT_LOOP ; Transferring 4 MSB of R1 into 4 LSB of R2
ADD R2, R2, R2   ; Left shift R2 by 1 digit
ADD R1, R1, #0    ; Checks if R1 is a negative value

BRzp SHIFT 

ADD R2, R2, #1    ;Result if R1 is a negative value we add R2 by 1

SHIFT                  ; Left Shifts R1 and restarts inner loop unless 4 loops have occured
ADD R1, R1, R1  ; Left Shift R1 by 1
ADD R3, R3, #-1  ; Decrement bit counter by 1
BRp EXTRACT_LOOP ; Check if 4 bits have been transferred from R1 to R2

R2HEX ; Converts R2 from binary to hexadecimal
ADD R0, R2, #-9 ; Checks to see whether or not R2 is in either 0-9 or A-F
BRp LETTERS    ; Branch for characters else prints numbers

LD R0, ASCII_0 ; Loads ASCII for 0 into R0
ADD R0, R0, R2 ; updates ASCII to the number from binary value R2 
BR PRINT_CHAR ; prints the hex value in R0

LETTERS	; condition if R2 has a decimal value greater than 10 i.e. R2 has hex value of A-F
ADD R2, R2, #-10 ; Since R2 is greater than 9 we need to get the offset to reach ASCII value
LD R0, ASCII_A ; Loads R0 with ASCII value of ‘A’
ADD R0, R0, R2 ; updates ASCII to the character from binary value R2

PRINT_CHAR 	;prints out the hex value stored in r0 
OUT
ADD R6, R6, #-1	;decrements r6 by 1
BRp MSB2LSB	;checks to see if 4 hex values have been printed 

LD R0, NEWLINE 	; load r0 with new line ‘\n’
OUT		;prints a new line ‘\n’ 

ADD R5,R5,#1	; increment R5 by 1

LD R0, NEGATIVE27		;Loads R0 with value of -27
ADD R0, R0, R5		;Add -27 to R5 to check if we have looped 27 times 

BRn PRINT_LOOP ; Loops back to beginning if the loop hasn’t looped 27 times



; you will need to insert your code to print the histogram here

; do not forget to write a brief description of the approach/algorithm
; for your implementation, list registers used in this part of the code,
; and provide sufficient comments



DONE	HALT			; done


; the data needed by the program
NUM_BINS	.FILL #27	; 27 loop iterations
NEG_AT		.FILL xFFC0	; the additive inverse of ASCII '@'
AT_MIN_Z	.FILL xFFE6	; the difference between ASCII '@' and 'Z'
AT_MIN_BQ	.FILL xFFE0	; the difference between ASCII '@' and '`'
HIST_ADDR	.FILL x3F00     ; histogram starting address
STR_START	.FILL x4000	; string starting address

;additonal constants 

ASCII_AT  .FILL x0040	; ASCII value for ‘@’
SPACE     .FILL x0020	; ASCII value for ‘ ‘ 
ASCII_0   .FILL x0030 	; ASCII value for ‘0’
ASCII_A   .FILL x0041	; ASCII value for ‘A’
NEWLINE   .FILL x000A	; ASCII value for new line ‘\n’
NEGATIVE27 .FILL #-27	;NEGATIVE27 is just -27 


; for testing, you can use the lines below to include the string in this
; program...
; STR_START	.FILL STRING	; string starting address
; STRING		.STRINGZ "This is a test of the counting frequency code.  AbCd...WxYz."



	; the directive below tells the assembler that the program is done
	; (so do not write any code below it!)

	.END
