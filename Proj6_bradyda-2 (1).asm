TITLE Program Template     (Proj6_bradyda.asm)

; Author: Daniel Brady
; Last Modified: 3/15/2023	
; OSU email address: bradyda@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 3/19/2023
; Description: Program to take 10 signed integers, confirm they are a signed number and within the size of the 32 bi reg.
;Convert the string entered via ASCII table. Show numbers. Then find the sum and average.

INCLUDE Irvine32.inc

mDisplayString	MACRO	string
push	EDX
mov		EDX, string
call	WriteString
pop		EDX

ENDM

mGetString	MACRO	string, input, maxLength
push	EDX
push	EAX
mov		EDX, string
call	WriteString
mov		EDX, input
mov		ECX, MAX_LENGTH
call	ReadString
mov		maxLength, EAX
pop		EAX
pop		EDX

ENDM

ARRAYSIZE = 10
MAX_LENGTH = 15

.data

intro		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ", 13,10
			BYTE	"By: Daniel Brady", 13, 10, 0
instruction	BYTE	"Please provide 10 signed decimal integers.", 13,10
			BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13,10
			BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, ", 13,10
			BYTE	"their sum, and their average value.", 13, 10, 0
prompt1		BYTE	"Please enter an unsigned integer: ", 0
error		BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
errorPrompt	BYTE	"Please try again: ", 0
showNum		BYTE	"You entered the following numbers:" , 0
sumNum		BYTE	"The sum of these numbers is: ", 0
sum			SDWORD	?
avgNum		BYTE	"The average is: ", 0
avg			SDWORD	?
outro		BYTE	"Thanks for stopping by.", 0
userNum		BYTE	15 DUP(?)
numArray	SDWORD	10 DUP(0)
output		BYTE	1 DUP(?)
numLen		DWORD	?
isNegative	DWORD	0
space		BYTE	", ", 0


.code
main PROC

mDisplayString	OFFSET intro
call			CrLf

mDisplayString	OFFSET instruction
call			CrLf

push	OFFSET	 isNegative
push	OFFSET	 numArray
push	OFFSET	 numLen
push	OFFSET	 userNum
push	OFFSET	 prompt1
push	OFFSET	 error
call	ReadVal

push	OFFSET	showNum
call	DisplayArray

push	OFFSET	space
push	OFFSET	ARRAYSIZE
push	OFFSET	output
push	OFFSET	numArray
call	WriteVal
call	CrLf
call	CrLf

push	OFFSET	sum
push	OFFSET	numArray
push	OFFSET	sumNum
call	calculateSum

push	OFFSET	1
push	OFFSET	output
push	OFFSET sum	
call	WriteVal
call	CrLf
call	CrLf

mDisplaySTring	OFFSET avgNum

;calculate the average. kept getting an error if I tried with a procedure
_average:
mov		EAX, sum
mov		EBX, 10
cdq
idiv	EBX
mov		avg, EAX

push	OFFSET	1
push	OFFSET	output
push	OFFSET	avg
call	WriteVal
call	CrLf
call	CrLf

push	OFFSET	outro
call	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP

;Convert a string to an integer and store in the array 
;preconditions: arraysize has been determined
;postconditions: array stored
;receives: variable for user input. empty array. array size for loop
;returns: array of 10 integers. 
ReadVal	Proc
push	EBP
mov		EBP, ESP
mov		EDI, [EBP + 24]	;array
mov		ESI, [EBP + 16]	;userInput
mov		ECX, ARRAYSIZE	;counter for outer loop. to complete for 10 numbers

_outerLoop:
jmp	_getNum

;prompt the user for their input and loop through the string to confirm within range
_getNum:
push	ECX
mGetString	[EBP+12], [EBP+16], [EBP+20]	; prompt, userInput, variable to store string length
mov		ESI, [EBP+16]						;move input into ESI
mov		ECX, [EBP+20]						;move length of string into ECX for inner loop. Allows to iterate for length of string
mov		EDX, 0								;Accumulator
mov		EBX, 0
mov		[EBP+28], EBX						;reset the sign variable for the current number being checked

;check the first value to see if it is positive or negative sign
_checkSign:
cld
lodsb			;move pointer to value
cmp		AL, 45
je		_negativeCheck
cmp		AL, 43
je		_positiveSign
jmp		_validate

;update EBX to 1 to bet checked later once the final value has been found for the user input
_negativeCheck:
mov		EBX, 1
mov		[EBP+28], EBX
dec		ECX			;dec ECX or the loop will check for one extra value
jmp		_nextValue

_positiveSign:
dec		ECX
jmp		_nextValue


;this is for if the sign is negative. We have updated the sign for later and need to look at the next value in the string
_nextValue:
cld					
lodsb					;clear direction flag and point to next value for user input
jmp		_validate

;confirm value is within ASCII table range
_validate:
cmp		AL, 48
jb		_invalidNum
cmp		AL, 57
ja		_invalidNum	
jmp		_addnum			

;give the message that number won't work and prompt for another
_invalidNum:
mDisplayString	[EBP+8]
call	CrLf
pop		ECX		;pop outer loop counter 
mov		EDX, 0	;reset accumulator for the user input
jmp		_getNum

_tooLarge:
mDisplayString	[EBP+8]
call	CrLf
pop		EBX
pop		EAX
pop		ECX		;pop outer loop counter 
mov		EDX, 0	;reset accumulator for the user input
jmp		_getNum

;convert the string to a number and check that it can fit in 32 bit register
;accumulate for each loop of the string
_addNum:

mov		EBX, EDX		;move accumulated value into EBX
push	EAX				
push	EBX
mov		EAX, EBX		;move the accumulated value into EAX to multiply
mov		EBX, 10
imul	EBX				
jo		_tooLarge		;if the value is too large, the overflow flag will set and jump to error message
mov		EDX, EAX		;move the value into EDX
pop		EBX				;pop the already accumulated value
pop		EAX

sub		AL, 48			;convert the string to a integer
movsx	EAX, AL			;move value to eax
add		EDX, EAX		;add the value to the accumulator

dec		ECX
jnz		_nextValue		;decrement and move to next value of the string if not the end of the string

push	EAX
mov		[EDI], EDX   ;move accumulator into array
jmp		_negative	


;if value is negative, use neg instruction to multiply value by -1 
_negative:
mov		EBX, [EBP+28]
cmp		EBX, 1
jne		_NextInput
mov		EAX, [EDI]
neg		EAX
mov		[EDI], EAX		;if string was negative, negate the integer and add back to the array

;move on to get next value
_nextInput:
pop		EAX
add		EDI, 4			;move to next position in array
pop		ECX				;decrement for the length of the array
dec		ECX
jnz		_outerLoop

_done:

call	CrLf
pop		EBP
ret 28

ReadVal ENDP

;Display message for the array
;preconditions: readval completed
;postconditions: none
;receives: message to print
;returns: None
DisplayArray Proc
push	EBP
mov		EBP, ESP
mov		EAX, [EBP+8]
mDisplayString	EAX
call	CrLf

pop		EBP
ret 4

DisplayArray ENDP

;Receives an integer value or an array of integers and converts to a string 
;preconditions: array of integers or a single integer value saved in a variable. loop amount given
;postconditions: none
;receives: integer/array. loop size, outstring for printing out individual bytes
;returns: either a single string value or an array of strings with spaces between each number
WriteVal Proc

push	EBP
mov		EBP, ESP
mov		ESI, [EBP+8]			;array
mov		ECX, [EBP+16]			;amount numbers to loop through

;loop to convert number to a string
_loop:
mov		EDI, [EBP+12]			;move the outstring byte into EDI
push	ECX						;push and save the amount of times needed to loop
mov		ECX, 1					;push 1 into ECX for when the string is printed
mov		EAX, [ESI]				;move the array value into EAX
jmp		_negativeCheck


;checks if the number is negative, if so goes to print the negative character
_negativeCheck:
cmp		EAX, 0
jl		_negative
jmp		_conversion

;print the negative string character then move on to the number
_negative:
push	EAX
mov		AL, 45
stosb					;move the negative string character into AL and load into EDI and print
mDisplayString	[EBP+12]
dec		EDI
pop		EAX
neg		EAX				;already have the negative string charcter. Negate and consider the numbers

;take the integer and divide by 10 and store the remainder as that is the last value for the string. loop until done
_conversion:
mov		EBX, 10	
cdq
idiv	EBX			;divide integer by 10
cmp		EAX, 0
je		_lastInt	;if EAX is 0, we know we are at the last value
add		EDX, 48		;convert the remainder to a string
push	EDX			;push the string onto the stack starting at the back
inc		ECX			;increment to keep track of how many times we must pop from the stack
jmp		_conversion

;end the of integer found. convert to string
_lastInt:
add		EDX, 48		;conver final remainder to string
push	EDX

;print out the converted integer as a string
_print:
pop		EAX				;pop the stack, this will allow the remainder to be loaded
stosb					;point to value in AL and load into EDI
mDisplayString [EBP+12]	;print the string in EDI, 1 byte at a time
dec		EDI				;reset EDI or it will save any values that are not overwritten
loop	_print			;loop based on inner loop ECX

jmp		_checkSpace		

;this is to see if a space is needed. if the length of the array was 1, no space needed
;this is specifically for when the average and sum are converated
_checkSpace:
pop		ECX
cmp		ECX, 1
je		_nextNum

;add the space between strings in the array
_addSpace:
mDisplayString	[EBP+20]
jmp		_nextNum

;move to next number in array. if just 1 value, will return
_nextNum:
add		ESI, 4
dec		EDI		;reset EDI for the next loop
dec		ECX
jnz		_loop


pop	EBP
ret	16 

WriteVal ENDP

;Calculate the sum of the array of integers by adding and returning the result
;preconditions: array of integers set. 
;postconditions: sum variable udpated with result
;receives: integer array, sum address, message to print
;returns: sum of array
calculateSum Proc
push	EBP
mov		EBP, ESP
mov		EAX, [EBP+8]	;string to print message
mov		ESI, [EBP+16]	;sum address
mDisplayString EAX
mov		EDI, [EBP+12]	;array
mov		ECX, 10
mov		EAX,0
_sum:
add		EAX, [EDI]		;add the values into EAX
add		EDI, 4
loop	_sum

_returnSum:
mov		[ESI], EAX		;move the sum into ESI to be returned to is variable

pop		EBP
ret		12	
calculateSum ENDP

;Outro 
;preconditions: all procedures have run
;postconditions: none
;receives: message to print
;returns: None
farewell Proc
push	EBP
mov		EBP, ESP
mov		EAX, [EBP+8]
mDisplayString EAX
call	CrLf

pop		EBP
ret 4
farewell ENDP
END main
