ExtraWideMode equ 1
EXE_FILE	  equ 1
;for hexdumping gfx data
;BUG: PRINTS GARBAGE TO THE SCREEN DURING COMPRESSION 
;		IF ANOTHER PROGRAM HAS THE SAME FILE OPEN
;		I DON'T KNOW HOW TO FIX THIS SINCE IT HAS MORE TO DO WITH WINDOWS THAN MS-DOS

	ifdef COM_FILE
		.model tiny
		.stack 1024
	else
		.model small
		.stack 800h
	endif
	
	.data
	


;;;;;; MACROS
		include \SrcAll\8086_Macros.asm
		include \SrcDOS\lib\macros\DOS_Macros.asm
		include \SrcDOS\lib\macros\debug_macros.asm
		include \SrcDOS\lib\macros\video_macros.asm
		include \SrcDOS\lib\macros\mouse_macros.asm
		include \SrcDOS\lib\macros\keyboard_macros.asm	
		include \SrcDOS\lib\80186_Compatibility.asm
		include \SrcDOS\lib\macros\ascii_defs.asm
		include \SrcDOS\lib\gfx\videomodes.asm
	
UserRam byte 256 DUP (0)
CursorX				equ UserRam		;byte, for debugging
CursorY				equ UserRam+1	;byte, for debugging

MonitorBak_AX 		equ UserRam+2		;word, for debugging
MonitorBak_F		equ UserRam+4		;word, for debugging
MonitorBak_IP   	equ UserRam+6		;word, for debugging
MonitorBak_ES   	equ UserRam+8		;word, for debugging
MonitorBak_DS   	equ UserRam+10		;word, for debugging
MonitorBak_BP		equ UserRam+12		;word, for debugging
MonitorBak_CS		equ UserRam+14		;word, for debugging
MonitorBak_SP		equ UserRam+16		;word, for debugging
MonitorBak_SS		equ UserRam+18		;word, for debugging
MonitorBak_SI		equ UserRam+20		;word, for debugging
MonitorBak_TempRet	equ UserRam+22		;word, for debugging
MonitorBak_TempVidMode equ UserRam+24	;byte
softVideoMode equ MonitorBak_TempVidMode
softCarriageReturn	equ UserRam+25		;byte

SEG_PSP				equ UserRam+26		;word, read from ES at startup
SEG_ENV				equ UserRam+28		;word, read from PSP offset 2Ch
VAR_ARGS			equ UserRam+30		;byte, how many command line arguments there are
CMD_LEN				equ UserRam+31		;byte, total length of command line args
TEMP_FILESIZE		equ UserRam+32		;word, total byte count of file
parameter_storage_w1 equ UserRam+34		;word, for writing files (temp file name)
parameter_storage_w2 equ UserRam+36		;word, for writing files (temp file contents)
parameter_storage_w3 equ UserRam+38		;word, for writing files (temp file handle)
TextColor			equ UserRam+255

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; end of user ram.


;;;; STRING RAM

const_max_len equ 20		;how many characters you wish to allow. 

StringParams label byte					;used with 0Ah int 21h
max_len db const_max_len				;use "StringRam" to refer to this.
actual_len db 0							;placeholder, MS-DOS will overwrite this later.
StringRam byte const_max_len DUP (0)	;STRING BUFFER


const_max_filename_len equ 11
Filename 		byte const_max_filename_len dup ('$')		;??????.bin, $-terminated
Filename_ASCIZ  byte const_max_filename_len dup (0)			;??????.bin, NULL-terminated
Filename_OUT 			byte "out.bin",0
Filename_OUT_Dollar 	byte "out.bin$"
Handle		word 0										;placeholder, we will fill this in later
Handle_Out  word 0

INPUT_BUFFER	byte 1000h dup (0)						;work area and output

extraspace		byte 0									;one extra byte for FE terminator

OUTPUT_BUFFER	byte 1000h dup (0)

extraspace2		byte 0		

;;;; end of data segment	
	
	
	.code
	
start:
	mov ax,@data		;Get address of data segment
	mov ds,ax			;load it into DS
	
	mov al,0Fh			;white text in video modes
	mov byte ptr [ds:TextColor],al	
	
	
	mov bx,es					;back up (seg PSP) into BX
	mov CL,byte ptr [ds:0080h]	;get command line arg length
	mov byte ptr [ds:CMD_LEN],CL
	
	mov ax,word ptr [ds:002Ch]	;get enviroment segment into AX
	
	mov word ptr [ds:SEG_PSP],bx			;store the Program Segment Prefix segment into RAM
	mov word ptr [ds:SEG_ENV],ax			;store the environment segment into RAM

	cld					;String functions are set to auto-increment
	

	mov di,offset Filename
	call ParseFilenameFromCommandLine		
	;RETRIEVES FILENAME FROM PSP - STORES IN $-TERMINATED RAM AREA
	
	mov di,offset Filename_ASCIZ
	call ParseFilenameFromCommandLine		
	;RETRIEVES FILENAME FROM PSP - STORES IN NULL-TERMINATED RAM AREA
	
		
	call Primm
	byte "Now compressing '",0
	DosPrintString Filename
	call Primm
	byte "'...",13,10,0
	
	
	
	DosOpenFile Filename_ASCIZ,FILE_READONLY
	jc FileOpenError
		mov word ptr [ds:Handle],AX
		
		mov bx,ax		;mov handle to bx
		mov cx,1000h	;max bytes to read
		mov ax,@data
		mov ds,ax
		mov dx,offset INPUT_BUFFER
		DosReadFile_NoParams	;mov ah,3Fh int 21h
		;copies 1000h bytes from file into INPUT_BUFFER
		;returns file size in ax
		
		mov cx,ax
		mov word ptr [ds:TEMP_FILESIZE],ax
		
		mov ax,@data
		mov ds,ax
		mov es,ax
		
		
		mov di,offset INPUT_BUFFER
		add di,cx
		mov al,0FEh
		stosb			;store an FE-terminator at the end of the input buffer
		
		
	; the input file is no longer needed, so close it.
		mov bx,word ptr [ds:Handle]
		DosCloseFile					;closes the input file
		
CompressFile proc
	;now, we'll read from the file buffer and get to work!
		mov si,offset INPUT_BUFFER
		mov di,offset OUTPUT_BUFFER
		
compress:
		lodsb
		cmp al,0FEh
		je Terminated
		push cx
		push di
		push si
		
			mov cx,0FFFFh	;max loop
			xchg di,si		;scasb only works with es:di
			repz scasb		;scan until we get a different value
			xchg di,si		;put them back
			
			
		pop dx		;we need to retrieve the run length, so pop the old SI into DX instead.
		pop di	
		pop cx

		
		push si
			sub si,dx	;the difference is the run length. Should be less than 256 bytes.
			mov bx,si
		pop si
		
		cmp bx,3
		ja continue
			;a run of 2 or less shouldn't be RLE-encoded as it actually wastes space.
			;three bytes is the same space but takes less time to unpack
			;so if 3 or fewer bytes in a row, just store the data as-is.
			;at this moment, SI = two bytes after the last byte of the previous run.
			push si
			push cx
				sub si,2-1		;some sort of off-by-one error going on here
				sub si,bx
				mov cx,bx
				rep movsb		;this data will be stored as-is
			pop cx
			pop si
			jmp predicate		;no run length to encode, so just skip to the predicate
			
continue:
		cmp bx,100h		;return an error if dx is greater than or equal to 256 at this stage
		jae RunTooBig	;goto errorhandler
		
		push ax
			mov al,0F8h	;store the RLE control byte of F8 before the run length
			stosb
		
			mov al,bl
			stosb		;store the run length in the output buffer
		pop ax
		stosb			;store the data in the output buffer
		
predicate:
		dec si			;fix off-by-one error
		jmp compress
		
Terminated:
		mov al,0FEh
		stosb
CompressFile endp

;almost done! 
;now we just need to write the contents of OUTPUT_BUFFER
;	to a new file.


		;di might be one too high
		mov dx,offset OUTPUT_BUFFER
		sub di,dx	;get file size
		mov cx,di	;parameter for syscall
		push cx		;push file size 
			DosCreateFile offset Filename_OUT,0
			mov word ptr [ds:Handle_OUT],ax
			mov bx,ax		;move handle to bx
		pop cx				;put total file size in CX
		mov dx,offset OUTPUT_BUFFER
		mov ah,40h
		int 21h			;create file OUT.BIN from the output of our compression

		mov bx,word ptr [ds:Handle_OUT]
		DosCloseFile	;now close the file, we're done with it.
		
		
	call primm
	byte 13,10
	byte "Compression successful!",13,10
	byte "File ",22h,0
	DosPrintString Filename
	call primm
	byte 22h
	byte " was RLE compressed into ",22h,0
	DosPrintString Filename_OUT_Dollar
	call primm
	byte 22h,". ",13,10
	byte "The program has closed. Have a nice day!",0

ExitDOS:				;this label is needed by "WaitKey.asm"

	FlushKeyBuffer 0	;needed to prevent "phantom typing" to stdin
	mov ax,4C00h		;return to dos
	int 21h
;;;; END OF MAIN




;;;; ERROR MESSAGES
FileOpenError:
	call primm
	byte "Error: Could not find file: ",0
	DosPrintString Filename
	call primm
	byte 13,10
	byte "Please make sure the file is in the same directory",13,10
	byte "as this program, and try again!",13,10,0
	jmp ExitDOS

RunTooBig:
	call primm
	byte "Error: Could not compress file: ",0
	DosPrintString Filename
	call primm
	byte 13,10
	byte "There was a run length of 256 or greater in the file.",13,10,0
	jmp ExitDOS

CreateFileFailed:
	call primm
	byte "Error: Could not create file: ",0
	DosPrintString Filename_OUT_Dollar
	call NewLine
	jmp ExitDOS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;; SUBROUTINES



;;;; TESTING
	include R:\SrcDOS\lib\stdio\commandLine.asm
;;;; LIBRARY
	include R:\SrcDOS\lib\interrupts\diy_ints.asm
	include R:\SrcDOS\lib\stdio\Keyboard.asm
	include R:\SrcALL\V1_Monitor.asm
	include R:\SrcDOS\lib\stdio\strings\printing_textmode.asm
	include R:\SrcDOS\lib\Timing.asm
	include R:\SrcALL\compare.asm
	
end start
