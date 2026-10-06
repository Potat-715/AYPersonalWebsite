; THIS CODE IS A STACK CALCULATOR THAT DOES WHAT A NORMAL CALCULATOR DOES BUT UTILIZES A STACK THROUGH PUSH AND POP SUBROUTINES TO CALCULATE THE VALUE
; THE CODE STARTS BY READING THE INPUTS FROM THE USER AND CHECKS TO SEE IF IT IS A VALID CHARACTER WHETHER IT IS A NUMERIC INPUT OR OPERATOR INPUT OF ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION, OR EXPONENTIATION. 
; IF THE USER PUTS IN AN INVALID INPUT OR INVALID SYNTAX THE CODE WILL OUTPUT AN INVALID EXPRESSION 
; THE CALCULATOR ONLY OUTPUTS THE FINAL VALUE AFTER THE USER INPUTS AN EQUAL SIGN THEN OUTPUTS THE VALUE IN HEX 
.ORIG x3000
    
;your code goes here
MAIN
JSR EVALUATE
HALT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R0 - character input from keyboard
;R6 - current numerical output
;
;
EVALUATE
ST R7, EVALUATE_R7 ; saves r7 from evaluate subroutine to start from the top of the instructions 

READ_LOOP
GETC  ; GETS THE CHARACTER INPUT FROM USER AND STORES INTO R0
OUT ; ECHOS BACK WHAT USER INPUT 


LD R1, ASCII_NEGATIVE_EQUALS ; LOADS R1 WITH THE NEGATIVE ASCII VALUE OF ‘=’
ADD R2, R0, R1 ; SUBTRACTION TO SEE IF THE INPUT IS THE ‘=’ SIGN
BRz END_EVALUATE ; IF USER INPUT ‘=’ THEN WE FINISH THE CALCULATIONS AND MOVE TO OUTPUT

LD R1, ASCII_NEGATIVE_SPACE ; LOADS R1 WITH THE NEGATIVE ASCII VALUE OF ‘ ’
ADD R2, R0, R1 ; SUBTRACTION TO SEE IF THE INPUT IS THE ‘ ’ SIGN
BRz READ_LOOP ; IF USER INPUT ‘ ’ THEN WE IGNORE IT AND CONTINUE READING INPUT

LD R1, ASCII_NEGATIVE_0 ; LOADS R1 WITH THE NEGATIVE ASCII VALUE OF ‘0’
ADD R2, R0, R1          ; SUBTRACTION TO CHECK THE INPUT OF R0
BRn OPERATOR ; IF RESULT IS NEGATIVE THAT MEANS THAT THE INPUT IS NON-NUMERIC AND WE MOVE ON TO SEE IF THE INPUT IS AN OPERATOR CHARACTER
ADD R6, R2, #-9          ; CHECKING TO SEE IF R2 IS GREATER THAN 9 
BRp OPERATOR ; IF RESULT IS POSITIVE THAT MEANS THE INPUT IS NON-NUMERIC AND WE MOVE ON TO SEE IF THE INPUT IS AN OPERATOR CHARACTER


AND R0, R0, #0 ; IF THE INPUT FAILS BOTH BRANCH CHECKS THAT MEANS THE INPUT IS A NUMERIC VALUE
ADD R0, R2, #0 ; STORE R0 WITH R2 INPUT 
JSR PUSH ; PUSH THE VALUE INTO THE STACK
ADD R5, R5, #0 ; CHECK CONDITION IF WE HAVE OVERFLOW 
BRp INVALID_EXPR ; IF OVERFLOW CONDITION HAS BEEN MET WE RETURN INVALID EXPR
BR READ_LOOP ; WE CONTINUE TO READ THE LOOP IF THERE IS NO INVALID EXPR

END_EVALUATE ; SUBROUTINE WHEN THERE IS AN ‘=’ INPUT 
JSR POP ; POP THE LATEST VALUE THAT WAS PUSHED
ADD R5, R5, #0 ; CHECK STACK CONDITION AFTER POP
BRp INVALID_EXPR      ; IF THERE IS STILL STUFF IN THE STACK WE GET INVALID EXPR
 
ADD R6, R0, #0         ; stash the result while we probe the stack
 
JSR POP ; POP ANOTHER TIME TO CHECK STACK 
ADD R5, R5, #0 ; STACK CONDITION CHECKER
BRz INVALID_EXPR      ; a second value popped successfully -> too many operands
 
ADD R5, R6, #0          ; final answer goes in R5, per spec
ADD R0, R5, #0          ; RESULT2HEX actually reads its input from R0
JSR RESULT2HEX ; GO TO HEX CONVERTER SUBROUTINE 
 
LD R7, EVALUATE_R7 ; LOAD INITIAL R7 POINTER 
RET ; RETURNS BACK TO THE STORED R7 VALUE 

INVALID_EXPR ; INVALID EXPRESSION SUBROUTINE
LEA R0, INVALID_MSG ; MESSAGE OF IN VALID EXPRESSION IS STORED IN R0
PUTS ; OUTPUT R0 WITH THE MESSAGE
LD R7, EVALUATE_R7 ; WE GO TO THE EVALUATE R7 STORE WHICH ENDS THE PROGRAM
RET
 
EVALUATE_R7            .BLKW #1
ASCII_NEGATIVE_EQUALS  .FILL #-61   ;  NEGATIVE ASCII VALUE OF ‘=’
ASCII_NEGATIVE_SPACE   .FILL #-32   ;NEGATIVE ASCII VALUE OF ‘ ’
ASCII_NEGATIVE_0       .FILL #-48   ; NEGATIVE ASCII VALUE OF ‘0’
ASCII_NEGATIVE_PLUS    .FILL #-43   ; NEGATIVE ASCII VALUE OF ‘+’
ASCII_NEGATIVE_MINUS   .FILL #-45   ; NEGATIVE ASCII VALUE OF ‘-’
ASCII_NEGATIVE_MULT    .FILL #-42   ; NEGATIVE ASCII VALUE OF ‘*’
ASCII_NEGATIVE_SLASH   .FILL #-47   ; NEGATIVE ASCII VALUE OF ‘/’
ASCII_NEGATIVE_CARET   .FILL #-94   ; NEGATIVE ASCII VALUE OF ‘^’
INVALID_MSG            .STRINGZ "Invalid Expression" ; SELF EXPLANATORY

OPERATOR ; CHECKS WHAT OPERATOR CHARACTER THE USER INPUT WHEN THE CODE ABOVE DETERMINED WAS NON-NUMERIC 

ADD R2, R0, #0      ; R2 = operator char (safe across PUSH/POP calls)
 
JSR POP     ; POP AND STORED INTO R4
ADD R5, R5, #0 ; CHECK FOR UNDERFLOW 
BRp INVALID_EXPR ; IF UNDERFLOW USER MADE A MISTAKE SOMEWHERE

ADD R4, R0, #0     ; STORES POP INTO R4
 
JSR POP     ; POP AND STORED INTO R3
ADD R5, R5, #0 ; CHECK FOR UNDERFLOW 
BRp INVALID_EXPR ; IF UNDERFLOW USER MADE A MISTAKE SOMEWHERE

ADD R3, R0, #0     ; STORES POP INTO R3
 
LD  R1, ASCII_NEGATIVE_PLUS ; CHECK IF THE OPERATOR INPUT IS A ‘+’ SIGN
ADD R0, R2, R1 ; SUBTRACTION TO CHECK
BRz JSRADD ; IF SO WE GO TO THE ADD SUBROUTINE 


LD  R1, ASCII_NEGATIVE_MINUS ; CHECK IF THE OPERATOR INPUT IS A ‘-’ SIGN
ADD R0, R2, R1 ; SUBTRACTION TO CHECK
BRz JSRSUB ;IF SO WE GO TO THE SUBTRACTION SUBROUTINE 


LD  R1, ASCII_NEGATIVE_MULT ; CHECK IF THE OPERATOR INPUT IS A ‘*’ SIGN
ADD R0, R2, R1 ; SUBTRACTION TO CHECK
BRz JSRMULT ; IF SO WE GO TO THE MULT SUBROUTINE 


LD  R1, ASCII_NEGATIVE_SLASH ; CHECK IF THE OPERATOR INPUT IS A ‘/’ SIGN
ADD R0, R2, R1 ; SUBTRACTION TO CHECK
BRz JSRDIV ; IF SO WE GO TO THE DIVISION SUBROUTINE

LD  R1, ASCII_NEGATIVE_CARET ; CHECK IF THE OPERATOR INPUT IS A ‘^’ SIGN
ADD R0, R2, R1 ; SUBTRACTION TO CHECK
BRz JSREXP ; IF SO WE GO TO EXP SUBROUNTINE 

BR INVALID_EXPR   ; IF THE INPUT FAILS ALL CHECKS THEN IT MEANS IT IS NOT A VALID OPERATOR 





JSRADD ; GO TO ADD SUBROUTINE
JSR ADD_STACK

JSRSUB ; GO TO SUB SUBROUTINE
JSR SUBTRACT_STACK

JSRMULT ; GO TO MULT SUBROUTINE
JSR MULT_STACK

JSRDIV ; GO TO DIVISION SUBROUTINE
JSR DIV_STACK

JSREXP ; GO TO EXPONENTIAL SUBROUTINE 
JSR EXP_STACK 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
ADD_STACK
AND R0, R0, #0; Clear Result Register
ADD R0, R3, R4 ; R3+R4=R6
JSR PUSH ; pushing R6 to stack
ADD R5, R5, #0 ; Underflow or Overflow Check
BRp INVALID_EXPR ; BR if Underflow or Overflow
BRnzp READ_LOOP ; Goes back to reading values

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
SUBTRACT_STACK
AND R0, R0, #0     ; clears R0
NOT R4, R4           ; negates second value
ADD R4, R4, #1     ; negates second value
ADD R0, R3, R4     ; R0= R3-R4
JSR PUSH ; pushing R0 to stack
ADD R5, R5, #0 ; Underflow or Overflow Check
BRp INVALID_EXPR ; BR if Underflow or Overflow
BRnzp READ_LOOP ; Goes back to reading values

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
MULT_STACK
AND R0, R0, #0 ; result register cleared = 0

ADD R4, R4, #0 ; mult by 0 checker
BRzp MULT_LOOP ; already >= 0, no sign fix needed

NOT R3, R3       ; Negates R3
ADD R3, R3, #1 ; R3 = |R3| negating both preserves R3*R4 since (-a)(-b)=ab
NOT R4, R4       ; Negates R4
ADD R4, R4, #1 ; R4 = |R4| negating both preserves R3*R4 since (-a)(-b)=ab

MULT_LOOP ; Loop works for posxpos, negxpos, negation when negxneg, posxneg
ADD R4, R4, #0 ; checks multiplication loops
BRz MULT_END  ; R4=0 -> straight to done
ADD R0, R0, R3 ; adds R3 to result
ADD R4, R4, #-1 ; decrements loop counter
BR MULT_LOOP ; goes back to loop

MULT_END
JSR PUSH ; pushing R0 to stack
ADD R5, R5, #0 ; Underflow or Overflow Check
BRp INVALID_EXPR ; BR if Underflow or Overflow
BRnzp READ_LOOP ; Goes back to reading values

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
DIV_STACK
AND R0, R0, #0; Clear Result Register

ZERO_CHECK
ADD R4, R4, #0 ; Checks for invalid operation)
BRz END_DIV ; ends if invalid

; Division checker is to check for division combinations pos;pos, neg;neg, neg;pos, pos;neg
; this will funnel it down to the varying operations that handle the aforementioned four 
; combinations
R3_DIV_CHECK
ADD R3, R3, #0
BRn R3_NEG_R4_DIV_CHECK
BRp R4_DIV_CHECK

R3_NEG_R4_DIV_CHECK
ADD R4,R4,#0
BRn NEGNEG_OP
BRp NEGPOS_OP

R4_DIV_CHECK
ADD R4,R4,#0
BRn POSNEG_OP
BRp POSPOS_OP

; result is positive
; negates R3 to make it positive
; R4 is already negative and ready for subtraction
; prepares for the positive division loop where divisor is positive and dividend is repetitively  
; subtracted and quotient is incremented once for every successful subtraction
NEGNEG_OP
AND R2, R2, #0 ; initialize R2
NOT R3, R3 ; Negate R3
ADD R3, R3, #1; Negate R3
ADD R2, R2, R3 ; add negated dividend
BR POS_DIV_LOOP 

; result is positive
; negates R4 to prepare it for subtraction
; R3 is already positive
; prepares for the positive division loop where divisor is positive and dividend is repetitively  
; subtracted and quotient is incremented once for every successful subtraction
POSPOS_OP
AND R2, R2, #0 ; initialize R2
ADD R2, R2, R3 ; Add the dividend
NOT R4, R4 ; Negate R4
ADD R4, R4, #1; Negate R4
BR POS_DIV_LOOP 

; result is negative
; R3 is negative
; R4 is positive
; prepares for the positive division loop where divisor is negative and dividend is repetitively  
; added and quotient is decremented once for every successful subtraction
NEGPOS_OP
AND R2, R2, #0 ; initialize R2
ADD R2, R2, R3 ; add dividend
BR NEG_DIV_LOOP 

; result is negative
; R3 is negated
; R4 is negated
; prepares for the positive division loop where divisor is negative and dividend is repetitively  
; added and quotient is decremented once for every successful subtraction
POSNEG_OP
AND R2, R2, #0 ; initialize R2
NOT R3, R3 ; Negate R3
ADD R3, R3, #1; Negate R3
ADD R2, R2, R3 ; add negated dividend’
NOT R4, R4 ; Negate R4
ADD R4, R4, #1; Negate R4
BR NEG_DIV_LOOP

; prepares for the positive division loop where divisor is positive and dividend is repetitively  
; subtracted and quotient is incremented once for every successful subtraction
POS_DIV_LOOP
ADD R2, R2, R4   ; subtract divisor
BRn END_DIV
ADD R0, R0, #1
BR POS_DIV_LOOP

; prepares for the positive division loop where divisor is negative and dividend is repetitively  
; added and quotient is decremented once for every successful subtraction
NEG_DIV_LOOP
ADD R2, R2, R4   ; add divisor
BRp END_DIV
ADD R0, R0, #-1
BR NEG_DIV_LOOP

END_DIV
JSR PUSH ; pushing R0 to stack
ADD R5, R5, #0 ; Underflow or Overflow Check
BRp INVALID_EXPR ; BR if Underflow or Overflow
BRnzp READ_LOOP ; Goes back to reading values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
EXP_STACK
AND     R0, R0, #0      ; Clear R0 (result register)

  
;Edge Case: Exponent R4 == 0
ADD     R4, R4, #0      ; Test R4
BRz     EXP_ZERO        ; If R4 == 0, result is 1
        
;Initialize Outer Loop
ADD     R0, R3, #0      ; R0 = R3 (Accumulator starts at base^1)
ADD     R4, R4, #-1     ; R4 = R4 - 1 (Number of multiplications needed)
BRz     EXP_DONE        ; If exponent was 1, R0 is already set

EXP_OUTER_LOOP
ADD     R1, R0, #0      ; Copy current product to R1 (multiplicand)
AND     R0, R0, #0      ; Clear R0 to accumulate new product
ADD     R2, R3, #0      ; R2 = R3 (Inner loop counter set to base)

EXP_INNER_LOOP
ADD     R0, R0, R1      ; R0 = R0 + R1
ADD     R2, R2, #-1     ; R2--
BRnp    EXP_INNER_LOOP  ; Repeat until R2 == 0

;Outer Loop Control 
ADD     R4, R4, #-1     ; R4--
BRnp    EXP_OUTER_LOOP  ; Repeat until R4 == 0
BR EXP_DONE

EXP_ZERO
ADD     R0, R0, #1      ; Any non-zero base to power 0 equals 1

EXP_DONE
JSR PUSH ; pushing R0 to stack
ADD R5, R5, #0 ; Underflow or Overflow Check
BRp INVALID_EXPR ; BR if Underflow or Overflow
BRnzp READ_LOOP ; Goes back to reading values


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R3- value to print in hexadecimal

RESULT2HEX ; MP1 / LAB1 CODE BUT TAILORED TO MP2

ST R7, SAVE_R7 ; STORES ALL REGISTERS THAT WILL BE USED FOR HEX CONVERTER
ST R1, SAVE_R1
ST R2, SAVE_R2
ST R3, SAVE_R3
ST R5, SAVE_R5

ADD R1, R0, #0 ; STORES R0 INTO R1
AND R4, R4, #0 ; INITIALIZES R4
ADD R4, R4, #4 ; SETUP NIBBLE COUNTER REGISTER 

HEX_LOOP
AND R2, R2, #0 ; INITIALIZE R2 
AND R3, R3, #0 ; INITIALIZE R3
ADD R3, R3, #4 ; SETUP BIT COUNTER REGISTER

EXTRACT_LOOP ; EXTRACTS THE 4 MSB IN R1 AND TRANSFERS TO R2 MP1 CODE 
ADD R2, R2, R2
ADD R1, R1, #0
BRzp SHIFT
ADD R2, R2, #1

SHIFT ; SHIFTS R1 AND DECREMENTS BIT COUNTER MP1 CODE
ADD R1, R1, R1
ADD R3, R3, #-1
BRp EXTRACT_LOOP

ADD R0, R2, #0 ; STORES R2 INTO R0 MP1 CODE
ADD R6, R0, #-10 ; SEE IF R0 IS ‘0-9’ OR ‘A-F’ MP1 CODE
BRzp HEX

LD R6, ASCII_0  ; LOADS R6 WITH ‘0’
ADD R0, R2, R6 ; WHEN R0 IS ‘0-9’ WE CONVERT TO HEX MP1 CODE
BR PRINT_CHAR ; GO TO PRINT CHARACTER

HEX ; CONDITION WHEN R0 IS ‘A-F’ 
ADD R0, R0, #-10 ; OFFSET TO FIND THE EXACT HEX VALUE MP1 CODE
LD R6, ASCII_A ; LOAD R6 WITH ‘A’
ADD R0, R0, R6 ; FINDS THE ASCII VALUE OF R0 TO CONVERT TO HEX MP1 CODE

PRINT_CHAR ; PRINTS CHARACTER  MP1 CODE
OUT

ADD R4, R4, #-1 ; DECREMENT NIBBLE COUNTER
BRp HEX_LOOP ; GO BACK IF WE STILL HAVE MORE NIBBLES TO CONVERT

LD R7, SAVE_R7 ; LOAD BACK SAVED REGISTERS 
LD R1, SAVE_R1
LD R2, SAVE_R2
LD R3, SAVE_R3
LD R5, SAVE_R5
RET ; RETURNS

SAVE_R7 .BLKW #1 ; MEMORY OF SAVED REGISTERS
SAVE_R1 .BLKW #1 
SAVE_R2 .BLKW #1
SAVE_R3 .BLKW #1
SAVE_R5 .BLKW #1

ASCII_0 .FILL #48 ; ASCII VALUE OF ‘0’
ASCII_A .FILL #65 ; ASCII VALUE OF ‘A’ 


;IN:R0, OUT:R5 (0-success, 1-fail/overflow)
;R3: STACK_END R4: STACK_TOP
;
PUSH    
    ST R3, PUSH_SaveR3    ;save R3
    ST R4, PUSH_SaveR4    ;save R4
    AND R5, R5, #0        ;
    LD R3, STACK_END    ;
    LD R4, STACk_TOP    ;
    ADD R3, R3, #-1        ;
    NOT R3, R3        ;
    ADD R3, R3, #1        ;
    ADD R3, R3, R4        ;
    BRz OVERFLOW        ;stack is full
    STR R0, R4, #0        ;no overflow, store value in the stack
    ADD R4, R4, #-1        ;move top of the stack
    ST R4, STACK_TOP    ;store top of stack pointer
    BRnzp DONE_PUSH        ;
OVERFLOW
    ADD R5, R5, #1        ;
DONE_PUSH
    LD R3, PUSH_SaveR3    ;
    LD R4, PUSH_SaveR4    ;
    RET


PUSH_SaveR3    .BLKW #1    ;
PUSH_SaveR4    .BLKW #1    ;


;OUT: R0, OUT R5 (0-success, 1-fail/underflow)
;R3 STACK_START R4 STACK_TOP
;
POP    
    ST R3, POP_SaveR3    ;save R3
    ST R4, POP_SaveR4    ;save R3
    AND R5, R5, #0        ;clear R5
    LD R3, STACK_START    ;
    LD R4, STACK_TOP    ;
    NOT R3, R3        ;
    ADD R3, R3, #1        ;
    ADD R3, R3, R4        ;
    BRz UNDERFLOW        ;
    ADD R4, R4, #1        ;
    LDR R0, R4, #0        ;
    ST R4, STACK_TOP    ;
    BRnzp DONE_POP        ;
UNDERFLOW
    ADD R5, R5, #1        ;
DONE_POP
    LD R3, POP_SaveR3    ;
    LD R4, POP_SaveR4    ;
    RET


POP_SaveR3    .BLKW #1    ;
POP_SaveR4    .BLKW #1    ;
STACK_END    .FILL x3FF0    ;
STACK_START    .FILL x4000    ;
STACK_TOP    .FILL x4000    ;


.END


