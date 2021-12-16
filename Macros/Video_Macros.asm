; VIDEO SETTINGS ARE DEFINED IN "videomodes.asm"


;-------------------------------------------------------------------
	DosVideoMode macro vidMode
	;change to a new video mode.
	;if you change to the same mode you're on, the screen will be wiped
	;and the text cursor reset.
		mov ah,0
		mov al,vidMode
		int 10h
	endm
;-------------------------------------------------------------------
	
;-------------------------------------------------------------------
	SetCursorPos macro row,column,pageNum
	;set the position of the drawing cursor.
		mov DH,row
		mov DL,column
		mov BH,pageNum
		mov AH,02h
		int 10h
		endm
;-------------------------------------------------------------------
	GetCursorPos macro pageNum
		mov BH,pageNum
		mov ah,03h
		int 10h
		endm
;-------------------------------------------------------------------
	ClearScreen macro
	push bx
		GetVideoMode		;returns current video mode in AL
		mov ah,0h
		int 10h				;reloads the current video mode.
	pop bx
	endm
;-------------------------------------------------------------------
	ScrollPageUp macro
	;input: al = number of lines to scroll window
	;bh = attributes to be used on blanked lines
	;ch,cl = row,column of upper left corner of window
	;dh,dl = row,column of upper right corner of window
		mov ah,06h
		int 10h
	endm
;-------------------------------------------------------------------
	ScrollPageDown macro
	;input: al = number of lines to scroll window
	;bh = attributes to be used on blanked lines
	;ch,cl = row,column of upper left corner of window
	;dh,dl = row,column of upper right corner of window
		mov ah,07h
		int 10h
	endm
;-------------------------------------------------------------------
	DrawDot macro column,row,displaypage,color
		mov cx,column
		mov dx,row
		mov bh,displaypage
		mov al,color
		mov ah,0Ch
		int 10h
	endm
;-------------------------------------------------------------------
	ReadDot macro column,row,displaypage
	;returns the color of a given dot on the screen in AL.
		mov cx,column
		mov dx,row
		mov bh,displaypage
		mov ah,0Dh
		int 10h
	endm
;-------------------------------------------------------------------
	GetVideoMode macro
		mov ah,0Fh
		int 10h
	endm
	;return: 
	;AH = COLUMNS ON SCREEN
	;AL = VIDEO MODE
	;BH = ACTIVE DISPLAY PAGE
;-------------------------------------------------------------------
	GetCurrentPalette macro Palette
	;VGA only
	push es
		mov ax,seg Palette
		mov es,ax
		mov dx,offset Palette
		mov cx,100h
		mov bx,0
		mov ax,1017h
		int 10h
	pop es
	endm
;-------------------------------------------------------------------
	VGA_Palette_DAC_Write macro index,red,green,blue
	;this is probably what int 10:1012 does.
	;index: which color in the palette you wish to change.
	mov al,index
	mov dx,VGA_DAC_ADDR_WRITE
	out dx,al
	
	mov dx,VGA_DAC_DATA
	
	mov al,red
	out dx,al
	
	mov al,green
	out dx,al
	
	mov al,blue
	out dx,al
	endm
	
;-------------------------------------------------------------------
	LDIR_DAC_Palettes macro dest,source,count
	;DEST: WHICH INDEX TO START AT (AN UNSIGNED ZERO-INDEXED INDEX)
	
	;SOURCE: LABEL FOR A TABLE OF COLORS, 3 BYTES R,G,B
	
	;COUNT:  HOW MANY COLORS TO CHANGE. 
	;		 1 = YOU WROTE 3 BYTES TO THE DAC. MAX 256
	push ds
		mov bx,seg source
		mov ds,bx
		mov bx,offset source
		mov cx,count	;max 256
		mov al,dest
		call doLDIR_DAC_Palettes
	pop ds
	endm
;-------------------------------------------------------------------

		
	
