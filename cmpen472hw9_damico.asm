
 ************************************************************************************
*
* Title:       Tcalc 
*
* Objective:   CSE472 Homework 9 program 
*              
*
*
*Revision:     V3.1
*
*Date:         April 8th, 2020
*
*Programmer:   Stephen DAmico
*
*Company:      The Pennsylvania State University
*              Department of Computer Engineering and Computer Science
*
*Algorithm:    save user input, check if it is valid, set the clock accordingly, use 
*              interrupt to increase time, check for calculation and evaluate 
*
*Register use: A,B: used to set the clock and calculate
*              X: buff to hold input, print onto screen 
*             
*             
*Memory use:   RAM Locations from $3000 for data.
*                            from #3100 for program
*
*Input:        user input (serial port)
*
*Output:       clock set or invalid input message on Serial port, calculation if valid expression
*
*Observations: This is a program that sets a clock based on user input or evaluates an expression   
*
*Note:         All Homework programs MUST have comments similar
*              to this homework 9 program. So, please use this 
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
;*******************************************************
; export symbols
            XDEF        Entry        ; export 'Entry' symbol
            ABSENTRY    Entry        ; for assembly entry point
;Symbols and Macros
PORTB         EQU     $0001            ; initializo portb
DDRB          EQU     $0003
; include derivative specific macros
SCIBDH      EQU         $00c8        ; Serial port (SCI) Baud Rate Register H
SCISR1      EQU         $00cc        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00cf        ; Serial port (SCI) Data Register
;following is for the TestTerm debugger simulation only
;SCISR1        EQU     $0203            ; Serial port (SCI) Status Register 1
;SCIDRL        EQU     $0204            ; Serial port (SCI) Data Register


CRGFLG      EQU         $0037        ; Clock and Reset Generator Flags
CRGINT      EQU         $0038        ; Clock and Reset Generator Interrupts
RTICTL      EQU         $003B        ; Real Time Interrupt Control

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character

;*******************************************************
; variable/data section
            ORG     $3000            ; RAMStart defined as $3000
                                     ; in MC9S12C128 chip

ctr2p5m     DS.W    1                ; 16bit interrupt counter for 2.5 mSec. of time
cbufct      DS.B    1                ; user input character buffer fill count
cbuf        DS.B    12                ; user input character buffer, maximum 12 char
cerror      DS.B    1                ; user input error count, 1 - 9 ($31 - $39)

times       DS.B    2                ; time to display on screen
timem       DS.B    2
timeh       DS.B    2

msg2        DC.B    'Hello, please enter time or enter an equation', $00
msg3err     DC.B    'Invalid time format. Correct example => hh:mm:ss', $00
msg4        DC.B    'Tcalc> ', $00
msg10       DC.B    'Baud rate changed to 115k, please restart the terminal and press enter', $00 

; following escape sequence works on Hyper Terminal (but NOT the TestTerminal)
; Please set the Hyper Terminal (property) setting to VT100 Terminal Emulation.
ResetTerm       DC.B    $1B, 'c', $00                 ; reset terminal to default setting
ClearScreen     DC.B    $1B, '[2J', $00               ; clear the Hyper Terminal screen
ClearLine       DC.B    $1B, '[2K', $00               ; clear the line
Scroll4Enable   DC.B    $1B, '[1', $3B, '4r',  $00    ; enable scrolling to top 4 lines
;SavePosition    DC.B    $1B, '[s', $00                ; NOT WORK! save the current cursor position
SavePosition    DC.B    $1B, '7', $00                 ; save the current cursor position
;UnSavePosition  DC.B    $1B, '[u', $00                ; NOT WORK! restore the saved cursor position
UnSavePosition  DC.B    $1B, '8', $00                 ; restore the saved cursor position
CursorToTop     DC.B    $1B, '[2',  $3B, '1f',  $00   ; move cursor to 2,1 position
CursorToPP      DC.B    $1B, '[4',  $3B, '1f',  $00   ; move cursor to 4,1 position, prompt
CursorToCenter  DC.B    $1B, '[08', $3B, '25H', $00   ; move cursor to 8,25 position


;*******************************************************
; interrupt vector section

            ORG     $3FF0            ; Real Time Interrupt (RTI) interrupt vector setup
            DC.W    rtiisr

;*******************************************************
; code section
            ORG     $3100
Entry
            LDS     #Entry           ; initialize the stack pointer
            
            ldx     #msg10           ;tell user the baud rate is changed 
            jsr     printmsg
            jsr     nextline
             
            ldx     #$000D           ; Change the SCI port baud rate to 115.2K
            stx     SCIBDH  
             
wait        jsr     getchar          ; wait for enter key
            cmpa    #CR
            bne     wait
                    
            ldx     #ClearScreen     ; clear the Hyper Terminal Screen first
            jsr     printmsg
            ldx     #CursorToTop     ; and move the cursor to top left corner (2,1) to start
            jsr     printmsg
            ldx     #Scroll4Enable   ; enable top 4 lines to scroll if necessary
            jsr     printmsg
            ldx     #CursorToPP      ; move cursor at (4,1) upper left corner for the prompt
            jsr     printmsg           

            ldaa    #$31             ; initialize error counter with '1' ($31)
            staa    cerror

            ldx     #398
            stx     ctr2p5m          ; initialize interrupt counter with 400.
            ldaa    #0               ; set buff count to 0
            staa    cbufct

            ldx     #cbuf            ; set up initial command
            ldaa    #'s'             ; start with 'set' command
            staa    1,x+
            ldaa    #' '             ; initialize time to 00:00:00
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #':'
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #':'
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #'0'
            staa    1,x+
            ldaa    #CR
            staa    1,x+
            ldaa    #11
            staa    cbufct

            bset  RTICTL,%00011001   ; set RTI: dev=10*(2**10)=2.555msec for C128 board
                                     ;      4MHz quartz oscillator clock
            bset  CRGINT,%10000000   ; enable RTI interrupt
            bset  CRGFLG,%10000000   ; clear RTI IF (Interrupt Flag)


looop       jsr   NewCommand         ; check command buffer for a new command entered.

loop2       jsr   UpDisplay          ; update display, each 1 second 

            jsr   getchar            ; user may enter command
            tsta                     ;  save characters if typed
            beq   loop2

            staa  1,x+               ; save the user input character
            inc   cbufct
            jsr   putchar            ; echo print, displayed on the terminal window

            cmpa  #CR
            bne   loop3              ; if Enter/Return key is pressed, scroll up the
            bra   looop              ; and evaluate the new command entered so far.

loop3       ldaa  cbufct             ; if user typed 12 character, it is the maximum, reset command
            cmpa  #12                ;   is in error, ignore the input and continue timer
            blo   loop2
            bra   looop


;subroutine section below

;***********RTI interrupt service routine***************
rtiisr      bset  CRGFLG,%10000000   ; clear RTI Interrupt Flag
            ldx   ctr2p5m
            inx
            stx   ctr2p5m            ; every time the RTI occur, increase interrupt count
rtidone     RTI
;***********end of RTI interrupt service routine********

;***************Update Display**********************
;* Program: Update count down timer display if 1 second is up
;* Input:   ctr2p5m variable
;* Output:  timer display on the Hyper Terminal
;* Registers modified: CCR
;* Algorithm:
;    Check for 1 second passed
;      if not 1 second yet, just pass
;      if 1 second has reached, then update display, toggle LED, and reset ctr2p5m
;**********************************************
UpDisplay
            psha
            pshx
            ldx   ctr2p5m          ; check for 1 sec
            cpx   #399             ; 2.5msec * 400 = 1 sec        0 to 399 count is 400
            lblo   UpDone           ; if interrupt count less than 400, then not 1 sec yet.
                                   ;    no need to update display.

            ldx   #0               ; interrupt counter reached 400 count, 1 sec up now
            stx   ctr2p5m          ; clear the interrupt count to 0, for the next 1 sec.



            ldx   #SavePosition      ; save the current cursor posion (user input in
            jsr   printmsg           ;   progress at the prompt).
            ldx   #CursorToCenter    ; and move the cursor to center(relative) to print time
            jsr   printmsg
            ldx   #timeh
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  #$3A
            jsr   putchar
            ldx   #timem
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  #$3A
            jsr   putchar
            ldx   #times
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar

            ldx   #UnSavePosition    ; back to the prompt area for continued user input
            jsr   printmsg
            
            ldx   times               ; load the seconds to x
            inx                       ; increment seconds
            stx   times               ;store new value to seconds
            ldd   times               ;load d with times
            cmpb  #$3A                ; compare ones digit to $3A
            lbne   UpDone              ;if it is not $3A, we are done
            ldx   #times              ;if it is 3A, set ones digit to 0
            inx
            ldaa  #$30                ;now ones digit is 0
            staa  1,x+
            ldd   times               ;load d with times again
            inca                      ;increment tens digit
            std   times               ;store new value
            cmpa  #$36                ;compare tens digit to $36
            lbne   UpDone             ; if it is not, we are done update
            ldx   #times              ; if it is, clear tens digit to 0
            ldaa  #$30                ; 
            staa  1,x+                ;tens digit now 0
            ldx   timem               ;increment minutes
            inx   
            stx   timem
            ldd   timem               ;load d with minutes
            cmpb  #$3A                ; compare ones digit of minutes to $3A
            lbne   UpDone              ; if it isn't, we are done
            ldaa  #$30                ; if it is, clear ones digit
            ldx   #timem
            inx
            staa  1,x+                ;ones digit now 0
            ldd   timem               ; load d with minutes again
            inca                      ;inc tens digit
            std   timem
            cmpa  #$36                ;compare tens digit to $36
            lbne   UpDone              ; done if not equal
            ldx   #timem
            ldaa  #$30
            staa  1,x+                ;tens digit now 0
            ldx   timeh               ;increment hours
            inx
            stx   timeh
            ldd   timeh               ; load new hours
            cmpa  #$30
            lbeq  hours0
            bra   hours1
            
hours0      cmpb #$3A
            lblt UpDone
            ldaa #$30
            ldx  #timeh
            inx
            staa 1,x+
            ldd  timeh
            inca
            bra  UpDone

hours1     cmpb  #$33
           blt   UpDone
           ldaa  #$30
           ldx   #timeh
           staa  1,x+
           staa  1,x+
           bra   UpDone       
            
            



UpDone      pulx
            pula
            rts
setDisplay
            psha
            pshx

            ldx   #SavePosition      ; save the current cursor posion (user input in
            jsr   printmsg           ;   progress at the prompt).
            ldx   #CursorToCenter    ; and move the cursor to center(relative) to print time
            jsr   printmsg

            ldx   #cbuf
            inx
            inx
            ldaa  1,x+             ;print the hours, mins, seconds on the screen
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            ldaa  1,x+
            jsr   putchar
            

            ldx   #cbuf
            inx
            inx
            ldaa   1,x+
            ldab   1,x+
            std   timeh         ;store the hours, minutes, seconds to their respective variable 
            inx
            ldaa   1,x+
            ldab   1,x+
            std   timem
            inx
            ldaa   1,x+
            ldab   1,x+
            std   times

            ldx     #UnSavePosition    ; back to the prompt area for continued user input
            jsr     printmsg
            jsr     nextline
            jsr     clearbuff          ;clear the buff 
            ldx     #msg4            ; print tcalc
            jsr     printmsg
            cli                ;turn interrupt on
            ldx     #cbuf
            lbra     loop2            ;go back to the main loop 
            
checknum   ldaa  cbufct
           cmpa  #8
           lbgt   invinput               
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

           
aconvert1d  ldx    #cbuf            ; load buff address to x
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
          

aconvert2d ldx     #cbuf         ; load buff address to x
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


aconvert3d ldx     #cbuf         ; load buff address to x
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

           
           
bconvert1d  ldx    #cbuf            ; load buff address to x
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
          

bconvert2d ldx     #cbuf         ; load buff address to x
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


bconvert3d ldx     #cbuf         ; load buff address to x
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
           
           
done       jsr   nextline             ;print newline
           ldx   #msg4               ;load and print tcalc prompt
           jsr   printmsg     
           jsr   startclear          ;clear all inputs
           ldx   #cbuf
           lbra  loop2               ; branch back to main loop
         

oferr      jsr   nextline             ;print newline
           ldx   #msg8               ; load x with invalid input message
           jsr   printmsg            ; print message
           jsr   nextline             ;print newline
           ldx   #msg4               ;load and print ecalc prompt
           jsr   printmsg     
           jsr   startclear          ;clear all inputs
           ldx   #cbuf 
           lbra  loop2              ; branch back to main loop  
           
invinput      
           jsr   nextline             ;print newline
           ldx   #msg9               ; load x with invalid input message
           jsr   printmsg            ; print message
           jsr   nextline             ;print newline
           ldx   #msg4               ;load and print ecalc prompt
           jsr   printmsg     
           jsr   startclear           ;clear all inputs
           ldx   #cbuf
           lbra  loop2               ; branch back to main loop



;***************end of Update Display***************

;***************New Command Process*******************************
;* Program: Check for 'run' command or 'stop' command.
;* Input:   Command buffer filled with characters, and the command buffer character count
;*             cbuf, cbufct
;* Output:  Display on Hyper Terminal, count down characters 9876543210 displayed each 1 second
;*             continue repeat unless 'stop' command.
;*          When a command is issued, the count display reset and always starts with 9.
;*          Interrupt start with CLI for 'run' command, interrupt stops with SEI for 'stop' command.
;*          When a new command is entered, cound time always reset to 9, command buffer cleared, 
;*             print error message if error.  And X register pointing at the begining of 
;*             the command buffer.
;* Registers modified: X, CCR
;* Algorithm:
;*     check 'run' or 'stop' command, and start or stop the interrupt
;*     print error message if error
;*     clear command buffer
;*     Please see the flow chart.
;* 
;**********************************************
clearbuff     ldx   #cbuf                  ; clear char buffer
              ldaa  #0
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              staa  1,x+
              ldx   #cbufct
              staa  1,x+
              rts
NewCommand
            psha

            ldx   #cbuf            ; read command buffer, see if set time or calculation
            ldaa  1,x+             ; each command is followed by an enter key
            cmpa  #'s'             ; if s, go to check for valid format
            lbeq   ckset
            cmpa  #$39              ; compare a to 9
            lbgt   invinput          ; branch to invalid if it is greater than 9
            cmpa  #$30              ; compare a to 0
            lblt   invinput
            ldx    #cbuf            ;load the buff to x if valid
            lbra   checknum

ckset       ldaa   1,x+             ;     check if 'set' command
            cmpa   #$20             ;    check for space
            lbne   CNerror
            ldaa   1,x+
            cmpa   #$31              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror          ;invalid if it is less than 0
            ldaa   1,x+
            cmpa   #$32              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror          ;invalid if it is less than 0
            ldaa    1,x+
            cmpa    #$3A            ; check for :
            lbne    CNerror
            ldaa   1,x+
            cmpa   #$35              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror          ;invalid if it is less than 0
            ldaa   1,x+
            cmpa   #$39              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror          ;invalid if it is less than 0
            ldaa    1,x+
            cmpa    #$3A            ; check for :
            bne    CNerror
            ldaa   1,x+
            cmpa   #$35              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror          ;invalid if it is less than 0
            ldaa   1,x+
            cmpa   #$39              ; compare a to 9
            lbgt   CNerror          ; branch to invalid if it is greater than 9
            cmpa   #$30              ; compare a to 0
            lblt   CNerror 
            ldaa  1,x+
            cmpa  #CR
            lbne   CNerror
            lbra   setDisplay
            
CNoff       sei                    ; it is 'quit' command, turn off interrupt
      ; 

            
CNonn       cli                    ; it is 'run' command, turn on interrupt
;            bra   CNdone

CNdone      ldx   #398             ; with new command, restart 10 second timer
            stx   ctr2p5m          ; initialize interrupt counter with 400.
            ldaa  #9
            staa  times            ; initialize 10 second timer with #9
            bra   CNexit


CNerror
            jsr   nextline         ; scroll up the screen, top 4 lines
            ldx   #msg3err         ; print the 'Command Error' message
            jsr   printmsg
            jsr   nextline
            ldx   #msg4            ; print the instruciton message
            jsr   printmsg
            jsr   clearbuff        ;clear buff and load buff to x
            ldx   #cbuf
            lbra   loop2            ;go back to the main loop 


CNerrdone   staa  cerror            


CNexit
            jsr   nextline         ; scroll up the screen, top 4 lines
            ldx   #msg4            ; print the prompt CMD> , at (4,1) upper left corner
            jsr   printmsg


            clr   cbufct           ; reset command buffer
            ldx   #cbuf

            pula
            rts
;***************end of New Command Process***************


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
NULL            equ     $00
printmsg        psha                   ;Save registers
                pshx
printmsgloop    ldaa    1,X+           ;pick up an ASCII character from string
                                       ;   pointed by X register
                                       ;then update the X register to point to
                                       ;   the next byte
                cmpa    #NULL
                beq     printmsgdone   ;end of strint yet?
                jsr     putchar        ;if not, print character and do next
                lbra     printmsgloop
printmsgdone    pulx 
                pula
                rts
startclear    ldaa  #8               ;the folloiwing subroutine will clear all variables 
              staa  clearb           ;then return to stack
              ldaa  #1
              staa  clear1
              ldaa  #2
              staa  clear2
              lbra  clearbuff1
clearbuff1    ldx   #cbuf
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
              dec   clearb
              ldaa  clearb
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

;***********end of printmsg********************

;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar     brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
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

getchar     brclr SCISR1,#%00100000,getchar7
            ldaa  SCIDRL
            rts
getchar7    clra
            rts
;****************end of getchar**************** 

;****************nextline**********************
nextline    ldaa  #CR              ; move the cursor to beginning of the line
            jsr   putchar          ;   Cariage Return/Enter key
            ldaa  #LF              ; move the cursor to next line, Line Feed
            jsr   putchar
            rts
;****************end of nextline***************
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

msg8           DC.B    'Overflow error', $00 
msg9           DC.B    'Invalid input format', $00   

            END                    ; this is end of assembly source file
                                   ; lines below are ignored - not assembled