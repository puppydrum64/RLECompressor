; KEYBOARD MACROS
; PUT THIS IN YOUR DATA SEGMENT



;-------------------------------------------------------------------
	ResetTextCursor	macro
		SetCursorPos 0,0,0
	endm
;-------------------------------------------------------------------
	GetShiftFlags macro
	
;returns the following bit pattern in AL:
; Bit(s)  Description     (Table 00582)
; 7      Insert active
; 6      CapsLock active
; 5      NumLock active
; 4      ScrollLock active
; 3      Alt key pressed (either Alt on 101/102-key keyboards)
; 2      Ctrl key pressed (either Ctrl on 101/102-key keyboards)
; 1      left shift key pressed
; 0      right shift key pressed

;AH is likely to be clobbered


	
		mov ah,02h
		int 16h
	endm
;-------------------------------------------------------------------
	ChangeTextColor macro color
	mov al,color ;must be a value between 80h and 8Fh
	call PrintChar_Color
	endm
;-------------------------------------------------------------------
	repVideoPrintChar_Color	macro char,pageNum,color,count
	mov al,char
	mov bh,pageNum
	mov bl,color
	mov cx,count
	mov ah,09h
	int 10h
	endm
;-------------------------------------------------------------------
	repVideoPrintChar macro char,pageNum,count
	;no color
	mov al,char
	mov bh,pageNum
	mov cx,count
	mov ah,0Ah
	int 10h
	endm
;-------------------------------------------------------------------
	VideoPrintChar macro
		;al: the character to write
		;bh: display page
		;bl: text color
		mov ah,0Eh
		int 10h
	endm
;-------------------------------------------------------------------
	VideoNewLine macro
		mov al,13
		mov ah,0Eh
		int 10h
		mov al,10
		int 10h
	endm
;-------------------------------------------------------------------
	DosPrintChar macro
		; dl: the character to write
		mov ah,02h
		int 21h
	endm
;-------------------------------------------------------------------
	DosNewLine macro
		mov dl,13
		DosPrintChar
		mov dl,10
		DosPrintChar
	endm
;-------------------------------------------------------------------
	DosRingBell macro
	;uses  (ascii code 7) to "ring the bell"
	;bug: no sound is heard.
		mov al,07h
		mov bh,0
		mov bl,1
		VideoPrintChar
	endm
;-------------------------------------------------------------------
	DosReadKey macro
	;read in a key press from the keyboard buffer.
	;The key's ascii code will be stored in AL.
	;Unless it's an arrow key, those are stored in AH.
		mov ah,00h
		int 16h
	endm
;-------------------------------------------------------------------
	DosGetString macro len
	;len must be 1 more than the actual allowable length
	;to make room for the terminator.
		push ax
			mov al,len
			mov byte ptr [ds:max_len],al
		pop ax
		call doDosGetString
		endm
;-------------------------------------------------------------------
	DosPrintString macro myString
	;print a $-terminated string to the screen.
	;the $ does not get printed.
	;the segment where myString is stored needs to be in DS.
	push ax
	push dx
		lea dx,myString
		mov ah,09h
		int 21h
	pop dx
	pop ax
	endm
;-------------------------------------------------------------------
	FlushKeyBuffer macro action
	;action: this can flow into another interrupt for convenience.
	;if you don't care just input 0.
	
	;if you don't do this before asking for input, any key you just pressed
	;will get "typed in" so you need to do this
		ifdef BuildTandy
			mov ah,04h
			int 16h
		else
			mov ah,0Ch
			mov al,action
			int 21h
		endif
	endm
;-------------------------------------------------------------------
		ifdef softCarriageReturn
		SetCustomCR macro newCR
			mov al,newCR
			mov byte ptr [ds:softCarriageReturn],al
			endm
		endif
;-------------------------------------------------------------------
	PrintTextBox macro boxStartingRow
		pushRegs
		SetCursorPos boxStartingRow,0,0
		mov cx,(22-boxStartingRow)
		call doPrintTextBox
		popRegs
		endm
;-------------------------------------------------------------------
	TextBoxMessage macro message,row,indent
		PrintTextBox 17
		SetCursorPos row,indent,0
		mov si,offset message
		; call PrintString_Color_Delay	;this is broken right now, prints black text on black screen
		call PrintString_Delay
		call delay
		FlushKeyBuffer 0
		endm
;-------------------------------------------------------------------
	CopyInputToRAM macro dest
	;source is always stringRam
	;dest is a label to a ram area.
		push es
			Load_ESDI ax,dest
			call doCopyInputToRAM
		pop es
		endm
;-------------------------------------------------------------------
	YesNoInput macro choiceYes,choiceNo

local Here
Here:
			call waitKey
			DosReadKey
			and al,11011111b
			cmp al,"Y"
			je choiceYes
			cmp al,"N"
			jne Here
			jmp choiceNo
		endm

;-------------------------------------------------------------------
;-------------------------------------------------------------------
