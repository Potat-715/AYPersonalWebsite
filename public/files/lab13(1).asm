	; ---------- Do not touch this code--it connects your code to the rest of the program. ----------
	.ORIG x3000
	LEA R0,LAB13_START
	TRAP x40
	; ---------- Do not touch this code--it connects your code to the rest of the program. ----------

	;
	; Whenever your Lab 12 program starts executing, the following register values will be set:
	; R1 -- the address of the player visible array
	; R2 -- the address of the game map array
	; *** Remember: do not use R7 in your program. ***
	;
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

BRnzp LAB12DONE

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
	;
	; Whenever your Lab 13 program starts executing, the following register values will be set:
	; R1 -- the address of the player visible array
	; R2 -- the address of the player's array of played columns
	; *** Remember: do not use R7 in your program. ***
	;
LAB13_START
	; ---------- Write your lab 13 code starting here. ----------
    ; --- 0. PRESERVATION ---
    ST R1, SAVE_R1          ; Save base address of Visibility Map
    ST R2, SAVE_R2          ; Save base address of Played Array

; --- 1. INPUT PHASE ---
COLUMN_USER
    LEA R0, COL_PROMPT      
    PUTS                    
    GETC                    
    OUT                     

; --- 2. VALIDATION PHASE ---
CHECK_INPUT
    LD R3, ASCII_NEG_0      
    ADD R4, R0, R3          ; R4 = Integer Column (0-9)
    BRn COLUMN_USER         ; Fail if < 0
    
    ADD R5, R4, #-10        
    BRzp COLUMN_USER        ; Fail if > 9

; --- 3. MEMORY CHECK PHASE ---
CHECK_PLAYED
    LD R2, SAVE_R2          ; Restore R2 to ensure pointer is fresh
    ADD R5, R2, R4          ; R5 = Address of chosen column in Played Array
    LDR R6, R5, #0          
    BRz ACCEPT_COL          ; If 0, it's a valid move

    LEA R0, ALREADY_PLAYED  
    PUTS
    BRnzp COLUMN_USER       ; If 1, column already played, restart

ACCEPT_COL
    AND R6, R6, #0          
    ADD R6, R6, #1          
    STR R6, R5, #0          ; Mark this column as 1 (Played)

; --- 4. CREATE BIT MASK ---
CREATE_MASK
    AND R3, R3, #0          
    ADD R3, R3, #1          ; Start with bit 0 (x0001)
    ADD R5, R4, #0          ; Set shift counter to Column Index
    BRz MASK_READY

SHIFT_LOOP
    ADD R3, R3, R3          ; Shift bit left (multiply by 2)
    ADD R5, R5, #-1
    BRp SHIFT_LOOP

; --- 5. UPDATE VISIBILITY MAP ---
MASK_READY
    AND R0, R0, #0          
    ADD R0, R0, #10         ; Set counter for 10 rows
    LD R1, SAVE_R1          ; Restore R1 for the map update
    ADD R5, R1, #0          ; R5 is our moving row pointer
    
UPDATE_LOOP
    LDR R6, R5, #0          ; Load current row
    
    ; Row = Row OR Mask (using NOT-AND-NOT)
    NOT R6, R6              
    NOT R3, R3              
    AND R6, R6, R3          
    NOT R6, R6              
    NOT R3, R3              ; Restore mask for next iteration
    
    STR R6, R5, #0          ; Save updated row back to memory
    ADD R5, R5, #1          ; Increment row pointer
    ADD R0, R0, #-1         ; Decrement counter
    BRp UPDATE_LOOP

; --- 6. EXIT ---
    BRnzp LAB13DONE         ; Branch to the test exit point

	; ---------- When your lab 13 code is done, execute this trap. ----------
LAB13DONE	; label for your convenience
	TRAP x42

	; ---------- Put any data that you need for lab 13 here. ----------

ASCII_NEG_0     .FILL xFFD0
COL_PROMPT      .STRINGZ "\nChoose a column (0-9): "
ALREADY_PLAYED  .STRINGZ "\nYou played there already."
SAVE_R1 .BLKW #1
SAVE_R2 .BLKW #2


	.END

