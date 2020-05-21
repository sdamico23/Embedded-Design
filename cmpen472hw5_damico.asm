************************************************************************************
*
* Title:       Hyper Terminal Menu Program
*
* Objective:   CSE472 Homework 5 program 
*              
*
*
*Revision:     V3.1
*
*Date:         Feb. 21, 2020
*
*Programmer:   Stephen DAmico
*
*Company:      The Pennsylvania State University
*              Department of Computer Engineering and Computer Science
*
*Algorithm:    Use the subroutines getchar, putchar to retrieve user input from the keyboard 
*              and display it on the terminal. Save the input to match to approriate action on the board using comparisons. 
*
*Register use: A: store characters 
*              B: store char  
*              X: store to the buff
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from $3100 for program
*
*Input:       characters typed by the user
* 
*
*Output:      SCISR1 serial port (terminal)
*
*Observations: This is a program that will display a menu and perform specific functions on the board based on what the user inputs. 
*
*Note:         All Homework programs MUST have comments similar
*              to this homework 5 program. So, please use this 
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

*Data Section
              ORG     $3000            ; RAMStart defined as $3000
                                       ; in MC9S12C128 chip ($3000 - $3FFF)
buff          DC.B     $5              ; initialize buff in memory

ON            DS.B     $1                ;initial  up counter to 0
OFF           DS.B     $1               ;initial down counter to 101
Count         DS.B     $1               ; counter for 100 loops
; Each message ends with $00 (NULL ASCII character) for your program.
;
; There are 256 bytes from $3000 to $3100.  If you need more bytes for
; your messages, you can put more messages 'msg3' and 'msg4' at the end of 
; the program.
                                  
StackSP                                ; Stack space reserved from here to
                                       ; StackST

              ORG  $3100
;code section below
Entry
              LDS   #Entry             ; initialize the stack pointer

; add PORTB initialization code here

              LDAA       #%11110000    ; set PORTB bit 7,6,5,4 as output, 3,2,1,0 as input
              STAA       DDRB          ; LED 1,2,3,4 on PORTB bit 4,5,6,7
                                       ; DIP switch 1,2,3,4 on PORTB bit 0,1,2,3.
              LDAA       #%11110000    ; Turn off LED 1,2,3,4 at PORTB bit 4,5,6,7
              STAA       PORTB         ; Note: LED numbers and PORTB bit numbers are different
              
printmenu     ldx   #msg5              ; print the series of menu messages
              jsr   printmsg           ;putting a new line after each one
              jsr   newline
              ldx   #msg6             
              jsr   printmsg
              jsr   newline
              ldx   #msg7              
              jsr   printmsg
              jsr   newline
              ldx   #msg8             
              jsr   printmsg
              jsr   newline
              ldx   #msg9              
              jsr   printmsg
              jsr   newline
              ldx   #msg10              
              jsr   printmsg
              jsr   newline
              ldx   #msg11              
              jsr   printmsg
              jsr   newline
              ldx   #msg12              
              jsr   printmsg
              jsr   newline
              ldx   #msg13              
              jsr   printmsg
              jsr   newline
              ldx   #msg3
              jsr   printmsg
              jsr   newline
              
              
              ldx   #buff              ; load x with the address of Buff
            
looop         jsr   getchar            ; check the key board
              cmpa  #$00               ;  if nothing typed, keep checking
              beq   looop
                                       ;  otherwise - what is typed on key board
              jsr   putchar            ; is displayed on the terminal window
              staa  1,X+               ; store characters to the buff
                                      
              cmpa  #CR                ;check for enter
              bne   looop              ; if Enter/Return key is pressed, move the
              ldaa  #LF                ; cursor to next line
              jsr   putchar            ; go to putchar subroutine 
              
              
              
                 
              ldx  #buff               ;after we get the command, load the address of buff
              ldaa 1,X+              ; load first char, increment x address to next post
              
              cmpa  #$4C               ; compare to L
              lbeq  lbyte2             ; jump to check the second byte if L
              cmpa  #$46                ;compare to F
              lbeq  fbyte2            ;jump to check second byte if F
              cmpa  #$51                ;if not L or F, check for QUIT. If not quit, it is invalid
              lbne   invinput
              ldaa  1,X+         
              cmpa   #$55
              lbne   invinput
              ldaa  1,X+ 
              cmpa   #$49
              lbne   invinput
              ldaa  1,X+ 
              cmpa   #$54
              lbne   invinput
              ldaa  1,X+   
              cmpa   #CR
              lbeq   typewriter          ; go to typewriter if quit
              
              
fbyte2        ldaa  1,X+                ;load next byte into A
              cmpa   #$31               ; continue to check for F1 to F4, branch as neccessary
              lbeq   F1CR               ; if it is none, the input is invalid
              cmpa   #$32               ;if it matches a command, proceed to check for enter key
              lbeq   F2CR
              cmpa   #$33
              lbeq   F3CR
              cmpa   #$34
              lbeq   F4CR
              lbRA   invinput
              
lbyte2        ldaa  1,X+               ; load next byte into B
              cmpa   #$31              ;continue to check for L1 to L4
              lbeq   L1CR              ; if it is none, input is invalid
              cmpa   #$32              ;if it matches a command, proceed to check for enter key
              lbeq   L2CR
              cmpa   #$33
              lbeq   L3CR
              cmpa   #$34
              lbeq   L4CR    
              lBRA   invinput 
              
L1CR          ldab  1,X+                 ;The following will check to see that the user pressed 
              cmpb  #CR                  ; the enter key after the command, if they did it will send it to proper command
              lbeq   L1
              lbra   invinput
L2CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   mainLoop
              lbra   invinput
L3CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   L3
              lbra   invinput
L4CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   L4
              lbra   invinput
F1CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   F1
              lbra   invinput
F2CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   dimdown
              lbra   invinput
F3CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   F3
              lbra   invinput
F4CR          ldab  1,X+                 
              cmpb  #CR
              lbeq   F4
              lbra   invinput
                
invinput      
              ldx   #msg14               ; load x with invalid input message
              jsr   printmsg            ; print message
              jsr   newline             ;print newline
              ldx   #buff               ; load x with the buff
              lbra   looop               ; branch back to main loop
              
L1            bclr  PORTB, %00010000   ; turn on LED1
              ldx   #buff               ; load the buff back to x
              lBra   looop              ; go back to the looop
              

F1            bset  PORTB, %00010000    ; turn off the Led1
              ldx   #buff               ; load the buff back to x
              lbra   looop              ; return to looop


mainLoop   ldx        #buff              ; load the buff back intox
           LDAA        #1                ; load a with 1
           LDAB        #101              ;load b with 101
           STAA        ON                ; store a to ON
           STAB        OFF               ;store b to OFF
           LDy         #11               ; load y with 11
           STy         Count             ; store y to count
   
countL     LDy         Count             ; load count to xy
           Bra         upValues
upValues   LDAA        ON                 ; load a with on
           LDAB        OFF               ;load b with off 

           
UpLoop     BCLR        PORTB, %00100000   ; turn on led2
           JSR         delay5us          ;delay 50 us
           decA                           ; dec a by 1
           BNE         UpLoop             ; keep looping until a is 0

           
DownLoop   BSET        PORTB, %00100000   ; turn off LED2
           JSR         delay5us          ; delay 50 us
           decb                           ; decrease b by 1
           BNE         DownLoop           ; keep branching until b is 0 
           DEy                            ;decrease the count value
           BNE        upValues            ; countinue the same level for 10 times to make it look smooth
                                          
           INC        ON                  ;increase ON 
           DEC        OFF                 ; decrease OFF
           
           ldab       OFF                 ; Load b with off 
           cmpb       #0                  ; compare b to 0

           lbeq        looop             ; go to the dim down if Off value is 0
           lBra        countL              ; if not, go back to the start and run again (dimup again)
           
           


dimdown    LDx        #buff               ; load the buff back to x
           LDAA       #101                ; load 101 to a
           STAA       ON                  ; store 101 to on value
           LDAB       #01                 ; load 1 into b
           STAB       OFF                 ; load 1 to off value
           LDy        #11                 ; load y w 11
           STy        Count

countL2    LDy       Count                 ; load 11 back into y
           Bra       DownVal
DownVal    LDAA        ON                 ;load a with on value
           LDAB        OFF                ;load b with off value

           
UpLoop2    BCLR        PORTB, %00100000   ;turn on led 2
           JSR         delay5us          ;delay 50 us
           decA                           ;dec a by 1
           BNE         UpLoop2            ;keep looping until a is 0
 
           
DownLoop2  BSET        PORTB, %00100000   ;turn off LED2
           JSR         delay5us          ;delay 50 us
           decb                           ;decrease b by 1
           BNE        DownLoop2             ;keep branching until b is 0 
           DEy                            ;decrease count
           BNE        DownVal             ;branch back to dim for 10 times to make it smooth
           
           DEC        ON                  ; decrease on value
           INC        OFF                 ; increment off value
           
           ldab       ON                  ;load on value into b
           cmpb       #0                  ; compare b to zero
           lbeq        looop            ;branch back to the start if the off value is zero 
           lBra        countL2            ; branch until dimmed back to off
           
L3            bclr  PORTB, %01000000   ; turn on LED3
              ldx   #buff               ; load the buff back to x
              lbra   looop              ; return to looop

F3            bset  PORTB, %01000000    ; turn off the Led3
              ldx   #buff               ; load the buff back to x
              lbra   looop              ; branch back to looop

L4            bclr  PORTB, %10000000   ; turn on LED4
              ldx   #buff               ; load the buff back to x
              lbra  looop               ; return to looop

F4            bset  PORTB, %10000000    ; turn off the Led4
              ldx   #buff               ; load the buff back to x
              lbra  looop               ; return to looop
              
              

              
typewriter    ldx   #msg1              ; print the first message, 'Hello'
              jsr   printmsg
            
              ldaa  #CR                ; move the cursor to beginning of the line
              jsr   putchar            ;   Cariage Return/Enter key
              ldaa  #LF                ; move the cursor to next line, Line Feed
              jsr   putchar
            
              ldx   #msg2              ; print the second message
              jsr   printmsg
              ldaa  #CR                ; move the cursor to beginning of the line
              jsr   putchar            ;   Cariage Return/Enter key
              ldaa  #LF                ; move the cursor to next line, Line Feed
              jsr   putchar
            
trlooop       jsr   getchar            ; type writer - check the key board
              cmpa  #$00               ;  if nothing typed, keep checking
              beq   trlooop
                                       ;  otherwise - what is typed on key board
              jsr   putchar            ; is displayed on the terminal window
              cmpa  #CR
              bne   trlooop              ; if Enter/Return key is pressed, move the
              ldaa  #LF                ; cursor to next line
              jsr   putchar
              bra   trlooop
              jsr   printmsg     
;subroutine section below

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
               
delay5us 
            PSHX
          
            LDX          #202                  ; load x 
dly5usLoop  NOP                               ; NOP= delay 1 clock cycle
            DEX         
            BNE          dly5usLoop          ;loop to get 5 uS

            PULX
            RTS
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
msg5           DC.B    'L1:Turn on LED1', $00
msg6           DC.B    'F1: Turn off LED1', $00
msg7           DC.B    'L2: LED 2 goes from 0% light level to 100% light level in 5 seconds', $00
msg8           DC.B    'F2: LED 2 goes from 100% light level to 0% light level in 5 seconds', $00
msg9           DC.B    'L3: Turn on LED3', $00
msg10          DC.B    'F3: Turn off LED3', $00
msg11          DC.B    'L4: Turn on LED4', $00
msg12          DC.B    'F4: Turn off LED4', $00
msg13          DC.B    'QUIT: Quit menu program, run Type writer program', $00
msg14          DC.B    'Error: invalid command. Please enter a new command', $00
               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled
