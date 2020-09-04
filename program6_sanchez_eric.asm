TITLE Program 6 - reading and writing integers     (program6_sanchez_eric.asm)

; Author: Eric Sanchez
; Last Modified: 3/15/2020
; OSU email address: sanceric@oregonstate.edu
; Course number/section: CS271-400
; Project Number: 6               Due Date: 3/15/2020
; Description: This program implements procedures for reading and writing
;				strings of numbers, validating the data, and storing them
;				as signed integers. These two procedures use macros for
;				getting keyboard input from the user. The program outputs
;				the list of numbers the user entered and calculates the
;				sum and average of the numbers.
;
;				Although this program calculates the sum and averages correctly
;				for positive and negative integers, the output of the values
;				the user entered is still in reverse order.

INCLUDE Irvine32.inc

ARRAYSIZE = 10
; (insert constant definitions here)

.data
introMsg		BYTE "Programming Assignment 6: Designing low level I/O procedures", 0dh,0ah
				BYTE "Written by Eric Sanchez",0dh,0ah,0ah
				BYTE "Please Provide 10 decimal integers.",0dh,0ah
				BYTE "Each number needs to be small enough to fit inside a 32 bit register.",0dh,0ah
				BYTE "After you have finished inputting the raw numbers I will display a list",0dh,0ah
				BYTE "of the integers, their sum, and their average value.",0

promptVal		BYTE	"Please enter a signed number: ",0
invalidVal		BYTE	"ERROR: You did not enter a signed number or your number was too big.",0dh,0ah
				BYTE	"Please try again: ",0

valuesMsg		BYTE "You entered the following numbers: ",0
sumMsg			BYTE "The sum of these numbers is: ",0
avgMsg			BYTE "The rounded average is: ",0

comma			BYTE ", ",0
number			BYTE 13 dup(?),0
order			DWORD 10

sum				DWORD 0
average			SDWORD 0

array DWORD ARRAYSIZE dup(?)

;procedure prototypes
ReadVal			PROTO, buffer:PTR BYTE, arrCurr:DWORD
writeVal		PROTO, buffer:DWORD

;******************************************************************************
;mGetString gets string input from the user,
;uses the edx and ecx registers, values
;are preserved by pushing/popping from system stack
;******************************************************************************
mGetString MACRO var1
	push	edx
	push	ecx
	mov		edx, [var1]
	mov		ecx, 14
	call	readString
	pop		ecx
	pop		edx
ENDM

;******************************************************************************
;mDisplayString prints an integer to the console after
;being passed by the calling procedure. uses the edx
;register, preserved py pushing/popping from system stack
;******************************************************************************
mDisplayString MACRO var2
	push	edx
	mov		edx, OFFSET var2
	call	writeString
	mov		edx, OFFSET comma
	call	writeString
	pop		edx
ENDM


.code

;******************************************************************************
;main procedure, stripped down and calls other procedures
;******************************************************************************

main PROC

	call	intro
	call	fillArray
	call	calcSum
	call	calcAvg
	call	closing

	exit	; exit to operating system
main ENDP


;******************************************************************************
;intro procedure prints the starting messages
;returns/receives nothing
;modifies edx, push/pop to preserve register
;******************************************************************************
intro PROC USES edx
	mov		edx, OFFSET introMsg
	call	writeString
	call	Crlf
	call	Crlf
	ret
intro ENDP

;******************************************************************************
;fillArray procedure gets 10 integers from the user using the readVal procedure
;returns/receives receives nothing
;precondition: array must exist
;modifies registers: eax, ebx, ecx, edx
;******************************************************************************
fillArray PROC
	LOCAL	arrayPos:DWORD
	mov		arrayPos, 0
	mov		ecx, LENGTHOF array
L1:
	mov		edx, OFFSET promptVal
	call	writeString
	
	INVOKE	ReadVal, OFFSET number, arrayPos

	inc		arrayPos
	loop	L1
	ret
fillArray ENDP

;******************************************************************************
;ReadVal procedure uses the getString macro to get a string a number from
;the user and converts it to an integer for storage in an array by the calling
;procedure.
;returns nothing
;receives the offset of a string to store the value from user and the
;current position in the array being filled
;array must exist for readVal to store values from user
;modifies registers: all of 'em!!!
;******************************************************************************
ReadVal PROC USES ecx, buffer:PTR BYTE, arrCurr:DWORD
	LOCAL temp:DWORD
	mov		edi, OFFSET array

	mov		eax, 0
usrInput:
	mov		temp, 0
	mGetString buffer
	mov		edx, buffer
	mov		esi, buffer
	mov		ecx, eax					;eax set to number of characters entered by readString in mGetString
	dec		ecx							;decrement by 1 up front because final int will be handled differently in loop
	cmp		ecx, 0
	je		lastInt
	cld

makeInt:
	mov		eax, 0
	lodsb
	cmp		eax, 45
	je		negative					;makes a negative integer if negative is encountered
	call	IsDigit						;checks for valid digit if negative sign not found
	jnz		invalid						;error message if not a digit
	sub		eax, 48						;convert ASCII code to int
	add		eax, temp
	mul		order
	mov		temp, eax
	dec		ecx
	cmp		ecx, 0
	je		lastInt
	jmp		positive					;go to positive if there's more numbers in string

positive:
	mov		eax, 0
	lodsb
	call	IsDigit
	jnz		invalid
	sub		eax, 48
	add		eax, temp
	mul		order
	mov		temp, eax
	loop	positive					;loop until all numbers have been added to value
	jmp		lastInt

negative:
	dec		ecx							;decrement loop counter to handle negative sign already being read
	cmp		ecx, 0
	je		lastNegInt
negLoop:
	mov		eax, 0
	lodsb
	call	IsDigit						;check if value is a digit, print error if not
	jnz		invalid
	cmp		eax, 45						;check for additional negative sign, print error
	je		invalid
	sub		eax, 48
	mov		ebx, eax
	mov		eax, temp
	sub		eax, ebx
	mul		order
	mov		temp, eax
	loop	negLoop

;lastInt and lastNegInt are separate because the loops above
;multiply by a factor of ten to handle additional numbers in the string
;The last integer doesn't need this.
lastNegInt:
	mov		eax, 0
	lodsb
	call	IsDigit
	jnz		invalid
	sub		eax, 48
	mov		ebx, eax
	mov		eax, temp
	sub		eax, ebx
	mov		temp, eax
	mov		ebx, arrCurr
	mov		[edi + ebx*8], eax
	ret

lastInt:
	mov		eax, 0
	lodsb
	call	IsDigit
	jnz		invalid
	sub		eax, 48
	add		temp, eax
	mov		eax, temp
	mov		ebx, arrCurr
	mov		[edi + ebx*8], eax
	ret

invalid:
	mov		edx, OFFSET invalidVal
	call	writeString
	jmp		usrInput
ReadVal	ENDP

;******************************************************************************
;printArray prints the contents of the array storing the user's values
;receives/returns nothing
;eax, ebx, ecx, esi registers used
;******************************************************************************
printArray PROC USES eax ebx ecx esi
	LOCAL arrayPos:DWORD
	mov		esi, OFFSET array
	mov		arrayPos,0
	mov		ecx, LENGTHOF array
printLoop:
	mov		ebx, arrayPos
	mov		eax, [esi+ebx*8]
	INVOKE	writeVal, eax
	inc		arrayPos
	loop	printLoop
	ret
printArray ENDP

;******************************************************************************
;writeVal converts an integer saved in an array to a string to be printed
;receives an integer as an argument and converts to string to be printed
;eax, ebx, edx, edi registers used
;******************************************************************************
writeVal PROC USES eax ebx edx edi, buffer:DWORD
	cld	
	mov		edi, OFFSET number
	mov		eax, buffer
	cmp		eax, 0
	jl		negativeConvert

convertLoop:
	mov		edx, 0
	cmp		eax, 0
	je		stringComplete					;if eax is 0, there value is 0. It will have reached
											;this point once all places of integer have been converted to string
	div		order
	push	eax
	mov		eax, edx
	add		eax, 48
	stosb
	pop		eax
	jmp		convertLoop

;negativeConvert puts a negative sign in the string, takes the twos complement
;of the number in the int, and converts using the same loop as positive values
negativeConvert:
	not		eax
	inc		eax
	push	eax
	mov		eax, 45
	stosb
	pop		eax
	jmp		convertLoop

;when the string conversion is complete, the string is passed to the display
;string macro to be printed.
stringComplete:
	stosb
	mDisplayString number
	ret
writeVal ENDP

;******************************************************************************
;calcSum calculates the sum of the numbers entered
;requires that the array has been filled
;eax, ebx, ecx, edx, esi registers used
;******************************************************************************

calcSum PROC
	LOCAL sumPos:DWORD
	mov		sumPos, 0
	mov		esi, OFFSET array
	mov		ebx, sumPos
	mov		sum, 0
	mov		eax, sum
	mov		ecx, LENGTHOF array
sumLoop:
	mov		edx, [esi + ebx*8]
	add		eax, edx
	inc		ebx
	loop	sumLoop
	mov		sum, eax
ret
calcSum ENDP

;******************************************************************************
;calcAvg procedure calculates the average of the number by dividing by 10 and
;rounding up if the value remainder is greater than 10
;set up includes moving the sum to the eax register and sign extending before
;calling idiv.
;eax, edx registers used
;******************************************************************************
calcAvg PROC USES eax edx
	mov		edx, 0
	mov		sum, eax
	cdq
	idiv	order
	cmp		edx, 5
	jl		roundDown
	inc		eax
roundDown:
	mov		average, eax
	ret
calcAvg ENDP


;******************************************************************************
;closing procedure prints the ending messages
;returns/receives nothing
;modifies edx, value preserved with USES
;******************************************************************************
closing PROC USES edx	
;print user's values
	mov		edx, OFFSET valuesMsg
	call	writeString
	call	Crlf
	call	printArray
	call	Crlf

;print sum
	mov		edx, OFFSET sumMsg
	call	writeString
	mov		eax, sum
	call	writeInt
	call	Crlf

;print average
	mov		edx, OFFSET avgMsg
	call	writeString
	mov		eax, average
	call	writeInt
	call	Crlf
	ret

closing ENDP



END main
