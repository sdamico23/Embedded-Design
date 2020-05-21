************************************************************************************
*
* Title:       LED Light Dimming by User Input
*
* Objective:   CSE472 Homework 6 program 
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
*Algorithm:    save user input, check if it is valid, set light level using PWM through the use of loops if valid
*
*Register use: A: Light on/off state and Switch SW1 on/off state 
*              X,Y: Delay Loop Counters
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from #3100 for program
*
*Input:        user light level from keyboard
*
*Output:       LED 1,2,3,4 at PORTB bit 4,5,6,7 or error message on screen
*
*Observations: This is a program that dims LEDs based on what the user inputs 
*              and the dimming value can change by changing the ratio of off to on. 
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

SCISR1        EQU     $00cc            ; Serial port (SCI) Status Register 1
SCIDRL        EQU     $00cf            ; Serial port (SCI) Data Register

;following is for the TestTerm debugger simulation only
;SCISR1        EQU     $0203            ; Serial port (SCI) Status Register 1
;SCIDRL        EQU     $0204            ; Serial port (SCI) Data Register

CR            equ     $0d              ; carriage return, ASCII 'Return' key
LF            equ     $0a              ; line feed, ASCII 'next line' character
********************************************************************************************
*Data Section
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)
buff          DS.B     $4              ; initialize buff in memory to 4 bytes

ONN           DS.B     $1                ;initial  up counter
OFF           DS.B     $1               ;initial down counter 
countchar     DS.B     $1               ; initialize character counter

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
           ldaa       #1                 ; initialize off and on values so the light is off
           staa       ONN
           ldaa       #101
           staa       OFF 
           ldaa       #0
           staa       countchar            ; initialize char count to 0 
           
           ldx   #msg5                     ; load the welcome message
           jsr   printmsg                  ;print the welcome message
           jsr   newline                   ; go to a new line
           ldx   #buff                     ; load the buff into x

           
looop      jsr   mainLoop           ; jump to dim 
loop       jsr   getchar            ; check the key board
           cmpa  #$00               ;  if nothing typed, keep checking
           beq   looop
                                    ;  otherwise - what is typed on key board
           jsr   putchar            ; is displayed on the terminal window
           staa  1,X+               ; store characters to the buff
           inc   countchar          ; increment count char 
           ldab  countchar          ; load b with char count
           cmpb  #5                 ; compare it to 5
           lbeq   invinput          ; input invalid if there is 5 or more char character                           
           cmpa  #CR                ; check for enter
           bne   loop              ; if Enter/Return key is pressed, move the
           ldaa  #LF                ; cursor to next line
           jsr   putchar            ; go to putchar subroutine
           
           cmpb  #1                 ; check for just one (enter?)
           lbeq   invinput          ; if one go to invalid
           cmpb  #4
           lbeq  start3
           ldx   #buff               ;load buff back to x
           bra   checknum           ; else check for a number 
            
checknum                 
           ldaa  1,x+               ;load a with the number/char
           cmpa  #CR               ;compare to enter
           beq   numdig            ; branch to get number of digits if enter
           cmpa  #$39              ; compare a to 9
           bgt   invinput               ; branch to invalid if it is greater than 9
           cmpa  #$30              ; compare a to 0
           blt   invinput          ;invalid if it is less than 0
           bra   checknum           ; if it is not an int from 0-9, invalid input
start3     ldx   #buff             ; load buff to x
           bra   check3
           
check3     ldaa  1,x+              ; load the three digits and check to see if they are 100 followed by enter
           cmpa  #$31
           bne   invinput
           ldaa  1, x+
           cmpa  #$30
           bne   invinput
           ldaa  1, x+
           cmpa  #$30
           bne   invinput
           ldaa  1, x+
           cmpa  #CR
           bne   invinput
           bra   convert3
           
numdig     ldaa  countchar         ;load character count to a
           suba  #1                ; subtract one to get the number of digits 
           cmpa  #1                ; compare a to one
           beq   convert1             ; get value for one digit 
           cmpa  #2                ; compare a to 2
           beq    convert2             ; get value for 2 digits
           cmpa   #3                ;compare a to 3
           beq    convert3           ;get value for 100
           

           
     

           
convert1  ldx    #buff           ; load buff address to x
          ldaa   1, x+            ; load number to a
          suba   #$30             ; subtract $30 to get decimal
          staa   ONN              ; store this value to on
          ldaa   #101             ; load a with 101
          ldab   ONN              ; load b with on value
          sba                     ; subtract b from a
          staa   OFF              ; store value to off
          bra    mainLoop1         ; branch to mainLoop to start dim 
          

convert2   ldx     #buff         ; load buff address to x
           ldaa    1,x+          ; load a with first number
           suba    #$30          ; subtract hex 30 from a to get decimal
           ldab    #10           ; load b with 10
           mul                   ; multiply the first number and ten to get right value (a*b)
           ldaa    1,x+          ; load second number into b
           suba    #$30
           aba                   ; add b and a
           staa    ONN           ; store this value to on
           ldaa    #101          ; load 101 to a 
           ldab    ONN           ; load on value to b 
           sba                   ; subtract b from a
           staa    OFF           ; store this to off value
           Bra     mainLoop1      ; branch to mainLoop to dim 
          


convert3  ldaa     #101              ; load onn w 100, off with 1 and check for enter 
          staa     ONN
          ldaa     #1
          staa     OFF
          bra      mainLoop1          ; branch to mainLoop after values loaded         
    

           
invinput      
           ldx   #msg6               ; load x with invalid input message
           jsr   printmsg            ; print message
           jsr   newline             ;print newline
              
           ldx   #buff               ; load x with the buff
           ldaa  #0
           staa  countchar               ; reset count to 0
           lbra   looop               ; branch back to main loop   
********************************************************************************
* Subroutine Section

;***********************************************************************
; delay1us subroutine 
;
; This subroutine cause a few usec. delay
;
; Input:  a 16bit count number in 'Counter1'
; Output: time delay, cpu cycle wasted
; Registers in use: X register, as counter
; Memory locations in use: a 16bit input number in 'Counter1'
;
; Comments: one can ass more NOP instructions to lengthen 
;           the delay time. 
         
delay10us 
            PSHA
          
            LDAA          #202              ; load a 
dly10usLoop                                 ; NOP= delay 1 clock cycle
            SUBA          #01                 ; Decrease a by 1
            BNE          dly10usLoop           ;loop to get 1 uS

            PULA
            RTS

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
mainLoop1  psha           
           LDAA         ONN              ;load a with on value
           BCLR         PORTB,%00010000  ; turn LED1 on
           BRA          onLoop1           ; branch to onLoop
           
onLoop1    jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          onLoop1           ; loop if a is not equal to 0
           BSET         PORTB,%00010000   ; turn off led 1 
           LDAA         OFF
           bra          offLoop1          ; load off value and go to off loop 
offLoop1   jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          offLoop1          ; loop if a not equal to 1
           ldaa          #0
           staa          countchar        ; reset countchar value to 0
           pula
           clr           buff             ; clr the buff and load address to x
           ldx           #buff
           lbra          looop             ; retrun when dim done
           
mainLoop   psha           
           LDAA         ONN              ;load a with on value
           BCLR         PORTB,%00010000  ; turn LED1 on
           BRA          onLoop           ; branch to onLoop
           
onLoop     jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          onLoop           ; loop if a is not equal to 0
           BSET         PORTB,%00010000   ; turn off led 1 
           LDAA         OFF
           bra          offLoop          ; load off value and go to off loop 
offLoop    jsr          delay10us        ; wait 10 us
           DECA                          ; decrease a by 1
           BNE          offLoop          ; loop if a not equal to 1
           pula
           rts                           ; retrun when dim done 

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
msg1           DC.B    'Hello', $00
msg2           DC.B    'You may type below', $00
msg3           DC.B    'Enter your command below:', $00
msg4           DC.B    'Error: Invalid command', $00 
msg5           DC.B    'Welcome!  Enter the LED 1 light level, 0 to 100 in range, and hit Enter', $00 
msg6           DC.B    'Error: invalid light level. Please enter a number from 0 to 100 range, and hit Enter', $00
               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled       