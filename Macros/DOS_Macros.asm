;MS-DOS SPECIFIC MACROS
FILE_READONLY   equ 0
FILE_WRITEONLY  equ 1
FILE_RW			equ 2

;-------------------------------------------------------------------
;-------------------------------------------------------------------
	DosGetCurrentDate macro
		mov ah,2Ah
		int 21h
	;output: DL = DAY, DH = MONTH, CX = YEAR, AL = DAY OF WEEK (0 = SUNDAY, 1 = MONDAY, ETC
	;note that output is in hex not decimal!
	endm
;-------------------------------------------------------------------
	DosSetCurrentDate macro day,month,year
		;input: DL = DAY, DH = MONTH, CX = YEAR (all in hexadecimal)
		;output: AL = 00h if no error, FFh if error
		mov dl,day
		mov dh,month
		mov cx,year
		mov ah,2Bh
		int 21h
	endm
;-------------------------------------------------------------------
	DosGetCurrentTime macro
	mov ah,2Ch
	int 21h
	endm
;-------------------------------------------------------------------
	DosMKDIR macro
	; Creates a subdirectory of the desired name.
	; input: DS:DX = the pointer to a null-terminated string.
	; usage:
	; mov ax, seg dirname
	; mov ds,ax
	; mov dx, offset dirname
	; DosMKDIR
	; dirname db "New Folder",0
	; return: carry set = error, error code is stored in ax
	; carry clear = success, ax destroyed.
		mov ah,39h
		int 21h
	endm
;-------------------------------------------------------------------
	DosRMDIR macro
	; Deletes the folder with the desired name.
	; Does nothing unless that folder is empty.
	; input: DS:DX = the pointer to a null-terminated string.
	; usage:
	; mov ax, seg dirname
	; mov ds,ax
	; mov dx, offset dirname
	; DosMKDIR
	; dirname db "New Folder",0
	; return: carry set = error, error code is stored in ax
	; carry clear = success, ax destroyed.
		mov ah,39h
		int 21h
	endm
;-------------------------------------------------------------------
	DosGetCurrentDirectory macro dest,driveNumber
	;DS must point to seg dest - must have 64 bytes free,
	;returns a null-terminated path name with no drive or
	;	initial backslash. Returns AX=0100h on success, 0Fh on fail.
	;	carry clear on success, carry set on error
		mov ah,47h
		mov DL,driveNumber
		mov si,offset dest
	endm
;-------------------------------------------------------------------
	DosCreateFile macro ascizFilename,attribs
		;DS:DX = PTR TO NULL-TERMINATED FILENAME
		;CX = ATTRIBUTE FLAGS (ZERO LETS YOU DO WHATEVER)
		mov ah,3Ch
		mov cx,attribs
		mov dx,ascizFilename
		int 21h
		;cf clear if success, returns handle in ax
		
	endm
;-------------------------------------------------------------------
	DosOpenFile macro ascizFilename,accessMode
		mov ah,3Dh
		mov al,accessMode
		mov dx,offset ascizFilename
		int 21h
		;if success, returns Carry Clear and file handle in AX
		;if failed, carry set and AX = ERROR CODE
	endm
;-------------------------------------------------------------------
	DosCloseFile macro
		;input: BX = FILE HANDLE
		mov ah,3Eh
		int 21h
	endm
;-------------------------------------------------------------------
	DosReadFile_NoParams macro
	;input: BX = file handle, CX = bytes to read, 
	;DS:DX points to data buffer
	;output: 
	;Success: AX = number of bytes read, carry clear
	;Error:   AX = error code, carry set
		mov ah,3Fh
		int 21h
	endm
;-------------------------------------------------------------------
	DosWriteFile macro
	;input: BX = file handle, CX = bytes to write, 
	;DS:DX points to data buffer
	;output: 
	;Success: AX = number of bytes written, carry clear
	;Error:   AX = error code, carry set
		mov ah,40h
		int 21h
	endm
;-------------------------------------------------------------------
	ReturnToDos macro
	;exits your program and returns to MS-DOS
		mov ax,4C00h ;return code 0
		int 21h
	endm
;-------------------------------------------------------------------
	DosGetReturnCode macro
	;Return code's internal storage is cleared after reading.
	;output: AH = termination type, AL = return code
		mov ah,4Dh
		int 21h
	endm
;-------------------------------------------------------------------
	WriteTextFile macro filename,text
	;text,filename are labeled memory locations of null-terminated
	;  strings, stored in your data segment.
	push ds
	push ax
		LoadSegment ds,ax,@data
		mov ax, offset filename
		mov word ptr [ds:parameter_storage_w1],ax
		mov ax, offset text
		mov word ptr [ds:parameter_storage_w2],ax
		call doWriteTextFile
	pop ax
	pop ds
	endm
;-------------------------------------------------------------------
	DosReadFile macro handle,bytecount,buffer
	;bx = handle, cx = bytecount, ds:dx = buffer addr.
	push ds
		mov bx,handle		 ;which file to read from
		mov cx,bytecount 	 ;how many bytes to read
		mov dx,seg buffer
		mov ds,dx
		mov dx,offset buffer ;where to store these bytes
		mov ah,3Fh
		int 21h
	pop ds
	endm
;-------------------------------------------------------------------
	DosLSEEK macro mode,handle,bytecountLo,bytecountHi
	;change the value of the file R/W pointer
	;AL = 0,1,2 (offset from beginning, current pos, or end)
	;BX = handle
	;CX:DX = offset in bytes
	;if successful, returns new offset in DX:AX
	
	mov al,mode
	mov ah,42h
	mov bx,handle
	mov cx,bytecountHi  ;not sure if these should be reversed.
	mov dx,bytecountLo
	int 21h
	endm
;-------------------------------------------------------------------
	DosGetInputStatus macro handle
	;handle = handle of file or device to check.
	;returns FF in AL if device is ready for input, 00 if not.
		mov bx,handle
		mov ax,4406h
		int 21h
	endm
;-------------------------------------------------------------------
	DosGetOutputStatus macro handle
	;handle = handle of file or device to check.
	;returns FF in AL if device is ready for output, 00 if not.
	;in DOS v2+, files are always ready for output.
		mov bx,handle
		mov ax,4407h
		int 21h
	endm	
;-------------------------------------------------------------------
	DosDUPHandle macro handle
		mov ah,45h
		mov bx,handle
		int 21h
		;returns new handle in ax
		endm
;-------------------------------------------------------------------
	DosMalloc macro count
		mov bx,count ;1 = one 16-byte "paragraph"
		mov ah,48h
		int 21h
		;returns segment of new memory block into AX if successful.
		;if failed, returns error code in AX and maximum available in BX.
		endm
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
;-------------------------------------------------------------------
