	
;;; Directives
            PRESERVE8
            THUMB   
				
			;IMPORT rand;
			;EXPORT randomGenerate
;;; Equates

INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value
	

;PORT A GPIO - Base Addr: 0x40010800
GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register

GPIOA_BSRR	EQU		0x40010810	; (0x10) Port Bit Set/Reset Register
GPIOA_BRR	EQU		0x40010814	; (0x14) Port Bit Reset Register
GPIOA_LCKR	EQU		0x40010818	; (0x18) Port Configuration Lock Register

;PORT B GPIO - Base Addr: 0x40010C00
GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register
GPIOB_BSRR	EQU		0x40010C10	; (0x10) Port Bit Set/Reset Register
GPIOB_BRR	EQU		0x40010C14	; (0x14) Port Bit Reset Register
GPIOB_LCKR	EQU		0x40010C18	; (0x18) Port Configuration Lock Register

;The onboard LEDS are on port C bits 8 and 9
;PORT C GPIO - Base Addr: 0x40011000
GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register
GPIOC_BSRR	EQU		0x40011010	; (0x10) Port Bit Set/Reset Register
GPIOC_BRR	EQU		0x40011014	; (0x14) Port Bit Reset Register
GPIOC_LCKR	EQU		0x40011018	; (0x18) Port Configuration Lock Register

;Registers for configuring and enabling the clocks
;RCC Registers - Base Addr: 0x40021000
RCC_CR		EQU		0x40021000	; Clock Control Register
RCC_CFGR	EQU		0x40021004	; Clock Configuration Register
RCC_CIR		EQU		0x40021008	; Clock Interrupt Register
RCC_APB2RSTR	EQU	0x4002100C	; APB2 Peripheral Reset Register
RCC_APB1RSTR	EQU	0x40021010	; APB1 Peripheral Reset Register
RCC_AHBENR	EQU		0x40021014	; AHB Peripheral Clock Enable Register

RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register  -- Used

RCC_APB1ENR	EQU		0x4002101C	; APB1 Peripheral Clock Enable Register
RCC_BDCR	EQU		0x40021020	; Backup Domain Control Register
RCC_CSR		EQU		0x40021024	; Control/Status Register
RCC_CFGR2	EQU		0x4002102C	; Clock Configuration Register 2

; Times for delay routines
        
DELAYTIME	EQU		1600000		; (200 ms/24MHz PLL)
LoseDelay EQU 100000
STARTTIME EQU 800000 ;
PRELIMWAIT EQU 400000
WINNERDELAY	EQU 200000
LEDTURNON EQU 800000
DELAY EQU 800000
REACTTIME EQU 800000
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register

; Vector Table Mapped to Address 0 at Reset
            AREA    RESET, Data, READONLY
            EXPORT  __Vectors

__Vectors	DCD		INITIAL_MSP			; stack pointer value when stack is empty
        	DCD		Reset_Handler		; reset vector
			
            AREA    MYCODE, CODE, READONLY
			EXPORT	Reset_Handler 
			ENTRY

Reset_Handler		PROC

		
	BL.W GPIO_ClockInit
		BL.W GPIO_init
		
		LDR R1 ,= GPIOA_ODR ;intially turn off the LEDS 
	
		LDR R0, =0xFFFF;
		STR R0,[R1];
		MOV R10,#0x00;  //seed counter
		MOV R12, #0x00; rep counter
	
mainLoop 
		
        BL waitingForPlayer
		BL	PreLimWaitPattern
		BL UC3
			
		B mainLoop
	
		ENDP
;;;;;;;;Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;----------------------------------------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;; Wait For Player start ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			ALIGN
waitingForPlayer PROC	
		PUSH{R1-R7,LR}
		LDR R1,=GPIOA_ODR
		MOV R5,#0xFDFF ; 1111 1101 1111 1111 mask
		STR R5,[R1]
		LDR R6 ,=STARTTIME
		
delay1	
		SUBS R6, #1; subtract till the flag of Z is 1 --> all zero
		BNE delay1; branch when not eqaul loop through delay1 till done branch to checkinput after
		BL checkInput
		
		LDR R1,=GPIOA_ODR 
		MOV R5,#0xFBFF ; mask
		STR R5,[R1]
		LDR R6 ,=STARTTIME
		BL getSeed
		
delay2
		SUBS R6,#1; subtract by 1 from delaytime till
		BNE delay2;
		BL checkInput
		
		LDR R1,=GPIOA_ODR 
		MOV R5,#0xF7FF ; 
		STR R5,[R1]
		LDR R6 ,=STARTTIME
		BL getSeed
		
delay3 
		SUBS R6,#1; subtract by 1 from delaytime till
		BNE delay3;
		BL checkInput
		
		LDR R1,=GPIOA_ODR 
		MOV R5,#0xEFFF; 
		STR R5,[R1]
		LDR R6 ,=STARTTIME
		BL getSeed
		
delay4 
		SUBS R6,#1; subtract by 1 from delaytime til
		BNE delay4;	
		BL checkInput
		;POP{R1-R7,PC}
		;waitingForPlayer
		;BX LR 
		B mainLoop
		
exit
		POP{R1-R7,PC}
		
		LTORG
		ENDP
			
	ALIGN
getSeed PROC 
	ADD R10,#1;
	BX LR
	ENDP

	ALIGN
checkInput PROC
	LDR R2 ,=GPIOB_IDR; Black and Red button PIN 8 & 9 
	LDR R3 ,=GPIOC_IDR; Blue button PIN 12
	LDR R4 ,=GPIOA_IDR; Green button PIN 5
	MOV R8, #0x00000000;
	
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x100; clear all bits but the 8 
	CMP R7,#0
	BEQ exit
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x200; mask for desired bit 0010 0000 0000
	CMP R7,#0
	BEQ exit
	
	LDR R7, [R3]
	AND R7, #0x1000 ; 0001 0000 0000 0000 mask
	CMP R7,#0
	BEQ exit
	
	LDR R7,[R4]
	AND R7, #0x20; 0010 0000 mask
	CMP R7,#0
	BEQ exit
	
	BX LR 
	
	LTORG
	ENDP

	ALIGN
PreLimWaitPattern PROC
	
		LDR R1,=GPIOA_ODR
		MOV R5,#0xE1FF ; 1110 0001 1111 1111
		STR R5,[R1]
		
		LDR R6 ,=DELAYTIME
delay21		
		SUBS R6,#1; subtract by 1 from delaytime til
		BNE delay21;

		MOV R6, #1; intit level 1
		B TurnOnLED
		
		LTORG
		ENDP

	ALIGN 
UC3 PROC
	
	
TurnOnLED 	
	ADD R12,#1;
	
	CMP R12, #9;
	BEQ.W LEVEL1COMPLETE

	CMP R12,#17
	BEQ.W LEVEL2COMPLETE
	
	CMP R12,#25
	BEQ.W LEVEL3COMPLETE
	
	CMP R12,#33
	BEQ.W LEVEL4COMPLETE
	
	CMP R12,#41
	BEQ.W LEVEL5COMPLETE
	
	CMP R12,#49
	BEQ.W LEVEL6COMPLETE
	
	CMP R12,#57
	BEQ.W LEVEL7COMPLETE
	
	CMP R12,#65
	BEQ.W LEVEL8COMPLETE
		

	LDR R1 ,= GPIOA_ODR ;turn off LEDS turn off the LEDS 
	LDR R0, =0xFFFF;
	
	
	STR R0,[R1];
	LDR R1,=DELAYTIME
	
delay20
	SUBS  R1 ,#1; subtract by 1 from delaytime til
	BNE delay20;	
	
	AND R10, #3 ;0000 0011
	CMP R10, #0x00; 
	BEQ LED1
	CMP R10, #0x01;
	BEQ LED2
	CMP R10, #0x02;
	BEQ LED3
	CMP R10, #0x03;
	BEQ LED4

LED1
	BL getSeed
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFDFF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	B CHECKWHACK1
	B TurnOnLED

LED2
	BL getSeed
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFBFF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	B CHECKWHACK2
	B TurnOnLED
	
LED3
	BL getSeed
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF7FF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	B CHECKWHACK3
	B TurnOnLED
	
LED4
	BL getSeed
	LDR R1,=GPIOA_ODR
	MOV R5,#0xEFFF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	B CHECKWHACK4
	B TurnOnLED
	
CHECKWHACK1 
	LDR R2 ,=GPIOB_IDR; Black and Red button PIN 8 & 9 
	LDR R3 ,=GPIOC_IDR; Blue button PIN 12
	LDR R4 ,=GPIOA_IDR; Green button PIN 5
	MOV R8, #0x00000000;
	
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x100; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W TurnOnLED
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x200; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W lost
	
	LDR R7, [R3]
	AND R7, #0x1000
	CMP R7,#0
	BEQ.W lost
	
	LDR R7,[R4]
	AND R7, #0x20
	CMP R7,#0
	BEQ.W lost

	B reacttime1
	
CHECKWHACK2
	LDR R2 ,=GPIOB_IDR; Black and Red button PIN 8 & 9 
	LDR R3 ,=GPIOC_IDR; Blue button PIN 12
	LDR R4 ,=GPIOA_IDR; Green button PIN 5
	MOV R8, #0x00000000;
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x100; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x200; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ TurnOnLED
	
	LDR R7, [R3]
	AND R7, #0x1000
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7,[R4]
	AND R7, #0x20
	CMP R7,#0
	BEQ.W  lost
	B reacttime2
	
CHECKWHACK3
	LDR R2 ,=GPIOB_IDR; Black and Red button PIN 8 & 9 
	LDR R3 ,=GPIOC_IDR; Blue button PIN 12
	LDR R4 ,=GPIOA_IDR; Green button PIN 5
	MOV R8, #0x00000000;
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x100; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x200; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7, [R3]
	AND R7, #0x1000
	CMP R7,#0
	BEQ  TurnOnLED
	
	LDR R7,[R4]
	AND R7, #0x20
	CMP R7,#0
	BEQ.W  lost
	B reacttime3
	
CHECKWHACK4
	LDR R2 ,=GPIOB_IDR; Black and Red button PIN 8 & 9 
	LDR R3 ,=GPIOC_IDR; Blue button PIN 12
	LDR R4 ,=GPIOA_IDR; Green button PIN 5
	MOV R8, #0x00000000;
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x100; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7, [R2]; Black and red switch
	AND R7, #0x200; clear all bits but the 8 and 9th bits  
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7, [R3]
	AND R7, #0x1000
	CMP R7,#0
	BEQ.W  lost
	
	LDR R7,[R4]
	AND R7, #0x20
	CMP R7,#0
	BEQ TurnOnLED
	
	
	B reacttime4

reacttime1
		BL getSeed
		;SDIV R11 ,R6
		SUBS R11,#1; subtract by 1 from delaytime til
		BNE CHECKWHACK1;
		
		B lost
reacttime2	
		BL getSeed
		
		SUBS R11,#1; subtract by 1 from delaytime til
		BNE CHECKWHACK2;
		
		B lost
reacttime3	 
		BL getSeed
		;SDIV R11,R6
		SUBS R11,#1; subtract by 1 from delaytime til
		BNE CHECKWHACK3;
		
		B lost
reacttime4	 
		BL getSeed
		;SDIV R11,R6
		SUBS R11,#1; subtract by 1 from delaytime til
		BNE CHECKWHACK4;
		
		B lost 
		
	LTORG
	ENDP


	ALIGN
LEVEL1COMPLETE PROC
	ADD R6,#1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xEFFF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete1
	SUBS R8, #1;
	BNE delayComplete1
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 111 1111 1111 turn off all LEDs
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete1A
	SUBS R8, #1;
	BNE delayComplete1A

	SDIV R11,R6
	B TurnOnLED
	
	ENDP 

	ALIGN
LEVEL2COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF7FF ; 1111 0111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete2
	SUBS R8, #1;
	BNE delayComplete2
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete2V
	SUBS R8, #1;
	BNE delayComplete2V
	
	SDIV R11,R6
	B TurnOnLED
	ENDP 
		
		
	ALIGN
LEVEL3COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xE7FF ; 1110 0111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete3
	SUBS R8, #1;
	BNE delayComplete3
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1110 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete3V
	SUBS R8, #1;
	BNE delayComplete3V
	
	SDIV R11,R6
	B TurnOnLED
	ENDP
		

	ALIGN
LEVEL4COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFBFF ; 1110 1011 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete4
	SUBS R8, #1;
	BNE delayComplete4
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete4V
	SUBS R8, #1;
	BNE delayComplete4V

	SDIV R11,R6
	B TurnOnLED
	ENDP 
		
	ALIGN
LEVEL5COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xEBFF ; 1110 1011 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete5
	SUBS R8, #1;
	BNE delayComplete5
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete5V
	SUBS R8, #1;
	BNE delayComplete5V
	
	SDIV R11,R6
	B TurnOnLED
	ENDP 
		
	ALIGN
LEVEL6COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF3FF ; 1111 0011 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete6
	SUBS R8, #1;
	BNE delayComplete6
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME

delayComplete6V
	SUBS R8, #1;
	BNE delayComplete6V

	SDIV R11,R6
	B TurnOnLED
	ENDP 
		
		
	ALIGN
LEVEL7COMPLETE PROC
	ADD R6, #1;
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF3FF ; 111e 0011 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete7
	SUBS R8, #1;
	BNE delayComplete7
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=DELAYTIME
	
delayComplete7V
	SUBS R8, #1;
	BNE delayComplete7V
	
	SDIV R11,R6
	B TurnOnLED
	ENDP 
			
	ALIGN
LEVEL8COMPLETE PROC ;;win the game 
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFDFF ; 1111 1101 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	
delayComplete8
	SUBS R11, #1;
	BNE delayComplete8
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R11,=REACTTIME
	
	B LEVEL8COMPLETE 
		
	ENDP 
	
	ALIGN  
lost PROC

	CMP R6 ,#1;
	BEQ LOSTIN1

	CMP R6, #2
	BEQ LOSTIN2

	CMP R6, #3
	BEQ LOSTIN3
	
	CMP R6 ,#4
	BEQ LOSTIN4
	
	CMP R6 ,#5
	BEQ LOSTIN5
	
	CMP R6 ,#6
	BEQ LOSTIN6
	
	CMP R6 ,#7
	BEQ.W LOSTIN7

	ENDP

LOSTIN1

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN1A
	SUBS R8, #1;
	BNE delayLOSTIN1A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xEFFF ; 1110 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN1B
	SUBS R8, #1;
	BNE delayLOSTIN1B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	
	B LOSTIN1
	

LOSTIN2

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN2A
	SUBS R8, #1;
	BNE delayLOSTIN2A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF7FF ; 1111 0111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN2B
	SUBS R8, #1;
	BNE delayLOSTIN2B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	
	B LOSTIN2;
	
LOSTIN3

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN3A
	SUBS R8, #1;
	BNE delayLOSTIN3A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xE7FF ; 1110 0111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN3B
	SUBS R8, #1;
	BNE delayLOSTIN3B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	
	B LOSTIN3;
	
LOSTIN4

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN4A
	SUBS R8, #1;
	BNE delayLOSTIN4A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFBFF ; 1111 1011 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN4B
	SUBS R8, #1;
	BNE delayLOSTIN4B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	B LOSTIN4;
	
LOSTIN5

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN5A
	SUBS R8, #1;
	BNE delayLOSTIN5A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xEBFF ; 1110 0111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN5B
	SUBS R8, #1;
	BNE delayLOSTIN5B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	B LOSTIN5;
	
LOSTIN6

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN6A
	SUBS R8, #1;
	BNE delayLOSTIN6A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF3FF ; 1110 0111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN6B
	SUBS R8, #1;
	BNE delayLOSTIN6B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]

	B LOSTIN6;

LOSTIN7

	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN7A
	SUBS R8, #1;
	BNE delayLOSTIN7A
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xF1FF ; 0001 0111 1111 1111
	STR R5,[R1]
	LDR R8,=LoseDelay
	
delayLOSTIN7B
	SUBS R8, #1;
	BNE delayLOSTIN7B
	
	LDR R1,=GPIOA_ODR
	MOV R5,#0xFFFF ; 1111 1111 1111 1111
	STR R5,[R1]
	
	
	B LOSTIN7;
	



	
;----------------------------------------------------------------------------------------------------;
;This routine will enable the clock for the Ports that you need	
	ALIGN
GPIO_ClockInit PROC

	; Students to write.  Registers   .. RCC_APB2ENR
	; ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12 *****NEW for 2015**** SW5(Green): PA5
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12
	
	LDR R6,=RCC_APB2ENR ; ENABLES the ports A, B, C
	LDR R0 ,[R6];
	ORR R0,#0x1C;
	STR R0,[R6];
	
	BX LR 
	ENDP
		
	
	
;This routine enables the GPIO for the LED's.  By default the I/O lines are input so we only need to configure for ouptut.
	ALIGN
GPIO_init  PROC
	LDR R6 , =GPIOA_CRH;  ENABLE the 4 LEDS to active low --> turns them all on
	LDR R0, =0x44433334;
	STR R0,[R6];
	
	LDR R6, =GPIOB_CRH;  intialize the input
	LDR R0, =0x44444444;
	STR R0 ,[R6];
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12

    BX LR
	ENDP
		
	ALIGN
	END
}

;Requires
    ;waitingForPlayer
    ;Registers R1 - R7 , LR
    ;R1 holds the GPIOA_ODR 
    ;R5 Holds Masking bits , and the results;
    ;R6 holds the delay time
    ;R10 holds the seed counter
    
;Check input
;R2,R3,R4 hold the GPIOx_IDR x = A,B,C respectively when needed
    ;R7 holds the the switch input. Masked with 

;Promise: 
;UC1 has many functions implemented. The first function is the LED pattern that runs right to left ;repeatedly, within this function a subroutine of adding one to a  Seed counter similar to time() in ;c++ to produce a srand().Further more the delay function is implemented to produce this LED ;pattern, within this function there is function to check user input to move from UC2 to UC3.

;Notes
;These functions help prepare the game as well as the entry point of the game.Prelim wait time 
;The intent of this subroutine is to wait for the user to input, press a button to proceed to the ;game(UC3). This pattern emitted from the LED is by loading in the GPIOA_ODR into a register, ;these LEDS being active low every bit is one except the LED desired to turn on. The pattern ;implemented for this game is LEDs turning on one after another with some delay between each ;LED turn on. The delay is a global variable declared near the top with all the global variables ;are.After turning on one LED by Loading the GPIOA_ODR (output for the LEDs), masking the bit ;for the desired LED to turn on, thus going from left to right masking it with 0 on the 9th bit. ;Storing this masked bit with the value from GPIOA_ODR thus turning on the first LED. The ;delay is then triggered as the next process, this is a subroutine in which the program subtracts ;one from the delay value and continuously loops through this process until the value of the ;register equates to 0. During this delay period there is a branch to a routine to check for user ;input. This process checks the user input by loading the GPIOA_IDR  , GPIOC_IDR , GPIO_IDR ;into registers. Creating masks for each button to check, these buttons are also active low when ;pressed down, thus the GPIOx_IDRs are masked with desired input mask bits and compared to ;the value 0 to know if a button is pressed. This process of repeating the LED pattern, delays , ;and checking for user input is repeated indefinitely until user input is valid then the game ;proceeds to use case 3 (UC3). 
;During the time of prelim wait time there is a subroutine that has a register that keeps adding ;one to act as a seed to make the game random, this randomness is implemented in UC3.
;Before UC3 there is a short delay before the game starts in which all LEDs flash for a short ;period before starting.

;UC3
;Registers
;R12: button press counter
;R6:Level counter 
;R1: Loading in GPIOx_ODR 
;R10: seed counter 
;R1: GPIOx_ODR 
;R5: LED OUTPUT
;R11:delay time load
;Promise
;In UC3 before the game starts in calls a subroutine to flashs LEDs to indicate the game is about ;to start. The main function of the game starts in which a random LED turns on and the user can ;proceed to match each button to the corresponding LED. By doing this repeatedly for 64 button ;presses equating to 8 rounds the user is met with with a winning sequence, missing the ;corresponding button with LED or timer running out returns a losing sequence.

;Note
;This is a long function that has many subroutines. The randomness of LEDs are from masking ;the register that kept track of the Seed with 3, this will either return the first,second, third , or ;fourth led to turn on. To check the input with the corresponding LED this is very similar to the ;checking input used in UC2. 


;UC4
;Each correct input will result in R12 to increase by 1. Each level 8 button have to be correctly ;pressed to move on. This is up to 8 Rounds thus 64 button presses required to win. By ;completing each level the life for each LED expires quicker, the delay is Divided by R6 value.

;UC5
 ;Pressing the non-corresponding LED will result in losing or when the timer that is set for each ;LED’s life cycle expires will also result in a lost. Similar to UC2 LED pattern making, the same ;concepts are applied to make the losing sequence for each round and also is applied to the ;winning sequence.
