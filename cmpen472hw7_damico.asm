************************************************************************************
*
* Title:       Calculator
*
* Objective:   CSE472 Homework 7 program 
*              
*
*
*Revision:     V3.1
*
*Date:         Feb 25th, 2020
*
*Programmer:   Stephen DAmico
*
*Company:      The Pennsylvania State University
*              Department of Computer Engineering and Computer Science
*
*Algorithm:    save user input, check if it is valid, calculate answer by 
*              saving the input and checking the operator
*
*Register use: A,B: used to calculate numbers and perform operations
*              X: buff to hold numbers, print onto screen 
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from #3100 for program
*
*Input:        user input calculation (serial port)
*
*Output:       answer or invalid input message on Serial port 
*
*Observations: This is a program that calculates an answer using up to three digit numbers.   
*
*Note:         All Homework programs MUST have comments similar
*              to this homework 6 program. So, please use this 
*              comment format for all your subsequent CMPEN 472
*              Homework programs. 
*
*              Adding more explanations and comments help you and 
*              others to understand your program later. 
*
*Comments:     This program is developed and simulated using CodeWarrior
*              development software and targeted for Axion Manufacuturings
*              APS12C128 board (CSM-12C128 board running at 24MHz bus clock.)
*
*************************************************************************************
*Parameter Declaration Section
*
*Export Symbols
              XDEF      Entry          ; export 'Entry' symbol
              ABSENTRY  Entry          ; for assembly entry point

* Symbols and Macros
PORTB         EQU     $0001            ; initializo portb
DDRB          EQU     $0003

;SCISR1        EQU     $00cc            ; Serial port (SCI) Status Register 1
;SCIDRL        EQU     $00cf            ; Serial port (SCI) Data Register

;following is for the TestTerm debugger simulation only
SCISR1        EQU     $0203            ; Serial port (SCI) Status Register 1
SCIDRL        EQU     $0204            ; Serial port (SCI) Data Register

CR            equ     $0d              ; carriage return, ASCII 'Return' key
LF            equ     $0a              ; line feed, ASCII 'next line' character
********************************************************************************************
*Data Section
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)
buff          DS.B     $8              ; initialize buff in memory to 8 bytes
operator      DS.B     $1              ;variable to store the operator 
firstnum      DS.B     $2              ; initialize first and second number variable 
secondnum     DS.B     $2
answer        DS.B     $2              ; answer variable 
countchar     DS.B     $1               ; initialize character counter
count1        DS.B     $1              ; 1st number length
count2        DS.B     $1              ;2nd number length
overflow      DS.B     $2              ;check for overflow
output        DS.B     $8              ; output variable 
address       DS.B     $8
outputc       DS.B     $1
negative      DS.B     $1 
clearb        DS.B     $1
clear1        DS.B     $1
clear2        DS.B     $1
hold          DS.B     $2
extra         DS.B     $1 
negcheck      DS.B     $1         

; Each message ends with $00 (NULL ASCII character) for your program.
;
; There are 256 bytes from $3000 to $3100.  If you need more bytes for
; your messages, you can put more messages 'msg3' and 'msg4' at the end of 
; the program.
******************************************************************************************
* Program Section                                  
StackSP                                   ; Stack space reserved from here to
                                          ; StackST

              ORG  $3100
;code section below
Entry
              LDS   #Entry                ; initialize the stack pointer

; add PORTB initialization code here

           LDAA       #%11110000          ; set PORTB bit 7,6,5,4 as output, 3,2,1,0 as input
           STAA       DDRB                ; LED 1,2,3,4 on PORTB bit 4,5,6,7
                                          ; DIP switch 1,2,3,4 on PORTB bit 0,1,2,3.
           LDAA       #%11110000          ; Turn off LED 1,2,3,4 at PORTB bit 4,5,6,7
           STAA       PORTB               ; Note: LED numbers and PORTB bit numbers are different  
           BCLR       PORTB,#%10000000    ;Turn on LED4
           BCLR       PORTB, #%01000000   ; Turn on LED 3

           ldaa       #0
           staa       countchar            ; initialize char count to 0 
           
           ldx   #msg5                     ; load the welcome message
           jsr   printmsg                  ;print the welcome message
           jsr   newline                   ; go to a new line
           ldx   #msg3                     ; load and print ecalc prompt
           jsr   printmsg  
           ldaa  #1                        ;save 1 to operator to start
           staa  operator        
           ldaa  #0
           staa  count1
           staa  count2
           staa  outputc                    ;initialize all variables with neccessary values
           staa  negative
           staa  countchar
           staa  operator
           staa  extra
           ldx   #firstnum
           staa  1,x+
           staa  1,x+
           ldx   #secondnum
           staa  1,x+
           staa  1,x+
           ldx   #answer
           staa  1,x+
           staa  1,x+
           ldx   #hold
           staa  1,x+
           staa  1,x+
           ldx   #buff              ; load the buff into x
           
looop      
           jsr   getchar            ; check the key board
           cmpa  #$00               ;  if nothing typed, keep checking
           lbeq   looop              
                                    ;  otherwise - what is typed on key board
           jsr   putchar            ; is displayed on the terminal window
           staa  1,X+               ; store characters to the buff
           inc   countchar          ; increment count char 
           ldab  countchar          ; load b with char count
           cmpb  #9                 ; compare it to 9
           lbeq  invinput           ; input invalid if there is 5 or more char character                           
           cmpa  #CR                ; check for enter
           lbne   looop               ; if Enter/Return key is pressed, move the
           ldaa  #LF                ; cursor to next line
           jsr   putchar            ; go to putchar subroutine
           
           cmpb  #1                 ; check for just one (enter/1num/1op)
           lbeq   invinput          ; if one go to invalid
           cmpb  #2
           lbeq  invinput           ; need at least 4 for valid input
           cmpb  #3                 ; one num, one op, one num then enter
           lbeq  invinput           ;
           ldx   #buff
           lbra   checknum           ; else check for a number
checknum                 
           ldaa  1,x+              ;load a with the number/char  
           cmpa  #$2a              ;compare to operators
           lbeq   saveop            ; branch to save op if equal
           cmpa  #$2b
           lbeq   saveop
           cmpa  #$2D
           lbeq   saveop
           cmpa  #$2f 
           lbeq  saveop
           jsr   putchar            ; print char on screen
           inc   count1            ;increase length of first char 
           ldab  count1            ;invalid if over 3 characters
           cmpb  #4
           lbeq  invinput 
           cmpa  #$39              ; compare a to 9
           lbgt   invinput          ; branch to invalid if it is greater than 9
           cmpa  #$30              ; compare a to 0
           lblt   invinput          ;invalid if it is less than 0
           lbra   checknum           ; if it is not an int from 0-9, invalid input
            
saveop     staa  operator          ;store operator
           jsr   putchar           ;put op on screen
           ldaa  count1
           inca    
           cmpa  countchar          ; add two to size of 1st number (operator+enter)
           lbeq  invinput           ; if this is equal to the input length, invalid input because there is no second number
           ldaa  1,x+               ; load the start of the second number 
           lbra   checksec
           
checksec   cmpa  #CR               ;if enter then convert numbers
           lbeq  convert
           jsr   putchar           ; print char
           cmpa  #$39              ; compare a to 9
           lbgt   invinput          ; branch to invalid if it is greater than 9
           cmpa  #$30              ; compare a to 0
           lblt   invinput          ;invalid if it is less than 0
           ldab  count2
           cmpb  #4                ;invalid if more than 3 digits
           lbeq  invinput
           ldaa  1,x+              ;load next number
           inc   count2            ;increase length of first char 
           lbra  checksec           
            
convert   ldaa  count1              ;load the length of first number
          cmpa  #1
          lbeq  aconvert1d          ; branch to convert number accordingly
          cmpa  #2
          lbeq  aconvert2d
          cmpa  #3
          lbeq  aconvert3d

           
aconvert1d  ldx    #buff            ; load buff address to x
            ldaa   1, x+            ; load number to a
            suba   #$30             ; subtract $30 to get decimal
            staa    hold
            ldd     hold
            lsrd                    ;logical shift right so that value can go into 
            lsrd                    ; variable correctly
            lsrd
            lsrd
            lsrd
            lsrd
            lsrd
            lsrd
            std   firstnum         ; store this value to firstnumber
            lbra    convert2        ; branch to convert the second number 
          

aconvert2d ldx     #buff         ; load buff address to x
           ldaa    1,x+          ; load a with first number
           suba    #$30          ; subtract hex 30 from a to get decimal
           ldab    #10           ; load b with 10
           mul                   ; multiply the first number and ten to get right value (a*b)
           ldaa    1,x+          ; load second number into a
           suba    #$30
           aba                   ; add b and a
           staa    hold
           ldd     hold
           lsrd
           lsrd                   ;logical shift right to get right value in variable
           lsrd
           lsrd
           lsrd
           lsrd
           lsrd
           lsrd
           std     firstnum      ; store this value to firstnum
           lbra     convert2


aconvert3d ldx     #buff         ; load buff address to x
           ldaa    1,x+          ; load a with first number
           suba    #$30          ; subtract hex 30 from a to get decimal
           ldab    #100           ; load b with 100
           mul                   ; multiply the first number and ten to get right value (a*b)
           std     firstnum      ;store to first number
           ldaa    1,x+          ; load second number into b
           suba    #$30          ; sub $30 to get decimal
           ldab    #10
           mul   
           ldaa    1, X+         ; load third num
           suba    #$30          ; sub to get decimal value
           aba                   ; add tens digit to this
           lsrd                   
           lsrd
           lsrd                   ;logical shift right to get right value in variable
           lsrd
           lsrd
           lsrd
           lsrd
           lsrd
           addd   firstnum           
           std    firstnum     ; store first number to value  
           lbra   convert2
                



convert2  ldaa  count2              ;load the length of first number
          cmpa  #1
          lbeq  bconvert1d           ; branch to convert number accordingly
          cmpa  #2
          lbeq  bconvert2d
          cmpa  #3
          lbeq  bconvert3d

           
           
bconvert1d  ldx    #buff            ; load buff address to x
            inc    count1           ; add length of first num +1(op) to get address of second number
            ldab   count1
            abx
            ldaa   1, x+            ; load number to a
            suba   #$30             ; subtract $30 to get decimal
            staa    hold
            ldd     hold
            lsrd
            lsrd
            lsrd                    ;logical shift right to get right value in variable
            lsrd
            lsrd
            lsrd
            lsrd
            lsrd
            std     secondnum      ; store this value to firstnum
            lbra    getop        ; branch to get the operator  
          

bconvert2d ldx     #buff         ; load buff address to x
           inc     count1        ;add length of first num +1(op) to get addr of second number
           ldab    count1
           abx
           ldaa    1,x+          ; load a with first number
           suba    #$30          ; subtract hex 30 from a to get decimal
           ldab    #10           ; load b with 10
           mul                   ; multiply the first number and ten to get right value (a*b)
           ldaa    1,x+          ; load second number into a
           suba    #$30
           aba                   ; add b and a
           staa    hold
           ldd     hold
           lsrd
           lsrd
           lsrd
           lsrd                   ;logical shift right to get right value in variable
           lsrd
           lsrd
           lsrd
           lsrd
           std     secondnum      ; store this value to firstnum
           lbra     getop        ; branch to get operator


bconvert3d ldx     #buff         ; load buff address to x
           inc     count1        ; add length of first num +1(op) to get address of second number
           ldab    count1
           abx    
           ldaa    1,x+          ; load a with first number
           suba    #$30          ; subtract hex 30 from a to get decimal
           ldab    #100           ; load b with 100
           mul                   ; multiply the first number and ten to get right value (a*b)
           std     secondnum      ;store to first number
           ldaa    1,x+          ; load second number into b
           suba    #$30          ; sub $30 to get decimal
           ldab    #10
           mul   
           ldaa    1, X+         ; load third num
           suba    #$30          ; sub to get decimal value
           aba   
           lsrd
           lsrd                  ;logical shift right to get right value in variable
           lsrd
           lsrd
           lsrd
           lsrd
           lsrd
           lsrd
           addd   secondnum           
           std    secondnum     ; store first number to value 
           lbra   getop   

getop      ldaa   operator       ; load the operator
           cmpa   #$2a            ;(*)compare to operators
           lbeq   multiply         ; and branch accordingly 
           cmpa   #$2b            ; (+)
           lbeq   add
           cmpa   #$2D            ; (-)
           lbeq   checksub
           cmpa   #$2f            ;(/)
           lbeq   divide
add        ldd   firstnum         ; load first number to d
           addd  secondnum        ;add second number to d 
           std   answer           ;store to answer 
           lbra    convertans      ; go to convert answer
           
           
checksub   ldd   firstnum            ;this is to see which of the numbers is larger
           stab  negcheck
           ldd   secondnum
           cmpb  negcheck           ; if second is larger>> answer will be negative
           lbgt   bminus1           ;
           lbra   aminus2           ;
           
aminus2    ldd   firstnum           ;load first number to d
           subd   secondnum         ;subtract second number from the first
           std    answer            ;store d to answer
           lbra    convertans        ; go to convert 
           
bminus1    ldaa   #$1              ;answer will be negative
           staa   negative
           ldd    secondnum         ; load second num to d 
           subd   firstnum          ;subtract second number from the first
           std    answer            ; store d to answer
           lbra    convertans        ; go to convert answer 
             

multiply   ldd  firstnum            ; multiple the first and second numbers 
           ldy  secondnum           ; 
           emul
           std   answer
           sty   overflow           ;check for overflow
           ldx  #overflow          ; load a with the lower 4 digits of overflow 
           ldaa 1,x+
           ldaa 1,x+                   
           cmpa  #$0                 ; if not equal to zero, there is overflow
           lbne  oferr
           lbra   convertans          ;branch to convert the answer
           
divide     ldd   secondnum          ; check for divide by zero
           cmpb  #0
           lbeq  invinput            ;divide by zero is invalid 
           ldd   firstnum            ; divide first number by second
           ldx   secondnum           ; d/x->y, r=d 
           idiv
           stx    answer              ; answer goes in y, store to answer 
           lbra   convertans
           
convertans ldx   #output             ;load and store output address
           
outputans 
           ldd   answer              ; load the answer to d
           pshx
           ldx   #10                 ; load x with 10 
           idiv  
           addd  #$30                ;add $30 to get hex
           stx   answer
           pulx
           stab   1,x+              ; store remainder to the output 
           inc   outputc             ;inc output counter 
           pshx                     ; store new answer value
           ldx   #answer
           ldaa  1,x+                ; load answer to a 
           ldaa  1,x+                ; get second byte
           cmpa  #0                  ; compare to 0
           lbeq  printeq              ;if answer is 0, we are done
           pulx 
           lbra  outputans
            
printeq    ldaa  #$3D                ; print the equal sign and 
           jsr  putchar
           ldaa negative              ;negative sign if neccessary
           cmpa #0
           lbeq  aoutput
           ldaa  #$2D
           jsr  putchar
           lbra aoutput
                     
           
aoutput    ldaa  #0                ; get address of last number in output 
           ldx   #hold
           staa  1,x+              ; becuase we will print in reverse order
           staa  1,x+
           ldd   #output
           dec   outputc
           addb  outputc
           std   hold
           ldx   hold
           inc   outputc
boutput                           ; print output then post decrement
           ldaa  1,x-
           jsr   putchar
           dec   outputc
           lbeq  done
           lbra  boutput          ;loop until done
           
           
done       jsr   newline             ;print newline
           ldx   #msg3               ;load and print ecalc prompt
           jsr   printmsg     
           jsr   startclear          ;clear all inputs
           ldx   #buff
           lbra  looop               ; branch back to main loop
         

oferr      jsr   newline             ;print newline
           ldx   #msg6               ; load x with invalid input message
           jsr   printmsg            ; print message
           jsr   newline             ;print newline
           ldx   #msg3               ;load and print ecalc prompt
           jsr   printmsg     
           jsr   startclear          ;clear all inputs
           ldx   #buff 
           lbra  looop              ; branch back to main loop  
           
invinput      
           jsr   newline             ;print newline
           ldx   #msg4               ; load x with invalid input message
           jsr   printmsg            ; print message
           jsr   newline             ;print newline
           ldx   #msg3               ;load and print ecalc prompt
           jsr   printmsg     
           jsr   startclear           ;clear all inputs
           ldx   #buff
           lbra  looop               ; branch back to main loop   
********************************************************************************
* Subroutine Section

;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
startclear    ldaa  #8               ;the folloiwing subroutine will clear all variables 
              staa  clearb           ;then return to stack
              ldaa  #1
              staa  clear1
              ldaa  #2
              staa  clear2
              lbra  clearbuff
clearbuff     ldx   #buff
              ldaa  #0
              staa  1,x+
              dec  clearb
              ldaa  clearb
              cmpa  #0
              lbeq  set8
              lbra  clearbuff
              
set8          ldaa  #8
              staa  clearb
              lbra  clearo
clearo        
              ldx   #output
              ldaa  #0
              staa  1,x+
              dec  clearb
              ldaa  clearb
              cmpa  #0
              lbeq  set8a
              lbra   clearo
set8a         ldaa  #8
              staa  clearb
              lbra   cleara
              
cleara       
              ldx   #output
              ldaa  #0
              staa  1,x+
              dec  clearb
              ldaa clearb
              cmpa  #0
              lbeq  clear1a
              lbra   cleara

clear1a       ldaa   #0
              staa   operator
              staa   countchar
              staa   count1
              staa   count2
              staa   outputc
              staa   negative
              staa   negcheck
              staa   extra
              lbra   clear2a
              
clear2a       ldx   #firstnum
              ldaa  #0
              staa  1,x+
              staa  1,x+
              ldx   #secondnum
              ldaa  #0
              staa  1,x+
              staa  1,x+
              ldx   #answer
              ldaa  #0
              staa  1,x+
              staa  1,x+
              ldx   #hold
              staa  1, x+
              staa  1,x+  
              ldx   #overflow
              staa  1, x+
              staa  1, x+
              rts                      ;return once all variables are cleared

              
              
              
newline       ldaa  #CR                ; move the cursor to beginning of the line
              jsr   putchar            ;   Cariage Return/Enter key
              ldaa  #LF                ; move the cursor to next line, Line Feed
              jsr   putchar              
              rts
NULL           equ     $00
printmsg       psha                   ;Save registers
               pshx
printmsgloop   ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
               cmpa    #NULL
               beq     printmsgdone   ;end of strint yet?
               jsr     putchar        ;if not, print character and do next
               bra     printmsgloop

printmsgdone   pulx 
               pula
               rts
               
;***********end of printmsg********************


;***************putchar************************
;* Program: Send one character to SCI port, (terminal/keyboard)
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, (terminal/keyboard)
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar        brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               staa  SCIDRL                      ; send a character
               rts
;***************end of putchar*****************


;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************
getchar        brclr SCISR1,#%00100000,getchar7  
               ldaa  SCIDRL
               rts
getchar7       clra
               rts
;****************end of getchar**************** 


;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip
msg3           DC.B    'Ecalc>', $00
msg4           DC.B    'Invalid Input Format', $00 
msg5           DC.B    'Welcome! Ready for a three digit calculation.', $00 
msg6           DC.B    'Overflow error', $00
               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled       