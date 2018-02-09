;8 pixels = 1 column
;String is started at 20h and string length is 7 then it occupies 56d pixels(38h).
;String ends at 57h(87d).
;8 pixels = 1 row (It's string height)	;=============================
data segment
	buff db 200 dup(0)
	f1 db '1.0',0
	f2 db '2.0',0
	f3 db '3.0',0
	f4 db '4.0',0
	f5 db '5.0',0
	f6 db '6.0',0
	f7 db '7.0',0
	f8 db '8.0',0
	f9 db '9.0',0
	
	filename db '00001.vcf',0
	md1 db 'BEGIN:VCARD',13,10,'VERSION:2.1',13,10,'N:;'
	len1 dw 1dh
	md2 db ';;;',13,10,'FN:'
	len2 dw 08h
	md3 db 13,10,'TEL;CELL;PREF:'
	len3 dw 10h
	md4 db 13,10,'END:VCARD',13,10,13,10
	len4 dw 0fh

	msg1 db '----------------------------------------'
	     db '                PHONEBOOK' ,10,13   
	     db '----------------------------------------'
	     db '$'
	msg2 db 10, 13, 10, 13, ' Enter Name: $'
	msg3 db 10, 13, 10, 13, ' Enter Contact Name : $'
	msg5 db 10, 13, 10, 13, ' Search Name : $'
	msg6 db 10, 13, 10, 13, '  Number : $' 
	msg14 db 10, 13, 10, 13, 'No Contacts!$',10,13,10,13
	msg15 db 10, 13, 10, 13, ' Access denied!$'
	msg16 db 10, 13, 10, 13, 'Contact created.$'
	msg17 db 10, 13, 10, 13, ' Contact Deleted.$'
	msg21 db 10, 13, 10, 13, ' Sorry Contact Not Match    !!$'
	msg23 db 10, 13, 10, 13,'SORRY!!',10,13,'You Have Not Sufficient Balance',10,13,'To Make An Outgoing Call$'
	msg24 db '*.', 0
	msg25 db '*'
	msg26 db 10, 13, '$'
	msg28 db 10, 13, 10, 13, ' Enter Number(Esc to stop):$'
	msg31 db '$'
	msg32 db ' $'
	t1 db '1$'
	t2 db '2$'
	t3 db '3$'
	t4 db '4$'
	t5 db '5$'
	t6 db '6$'
	t7 db '7$'
	t8 db '8$'
	t9 db '9$'
	row1 dw ?
row2 dw ?
col1 dw ?
col2 dw ?
color db ?	

	handle dw 0
	cflag db 0
	flag db 0
	flag2 db 0
	nooffile dw 0
	fileno dw 0
	buffer1 db 80, 0, 80 dup(0)
	buffer2 db 80, 0, 80 dup(0)
	buffer3 db 80, 0, 80 dup(0)

	but1 db 'CREATE'
	but2 db 'SPEED DIAL'
	but3 db 'EXIT'
	but4 db 'DELETE'
	but5 db 'EDIT'
	but6 db 'BACK'
	but44 db 'BACKUP'
	St1 DB "PASSWORD $"
St2 DB 50,18 DUP(0)
St3 DB "PASSWORD MATCHED.....WELCOME$"
St4 DB 10,13,"PASSWORD NOT MATCHED....ACCESS DENIED $"
St5 DB "AMP$"

data ends
code segment
   	assume cs:code,es:data,ds:data

start:	mov ax,data
	    mov ds,ax
		MOV es,ax
		;call grapmode
        MOV DX,OFFSET St1
		MOV AH,9H
		INT 21H
		MOV DX,OFFSET St2
		MOV AH,0AH
		INT 21H
		MOV CX,03
		LEA SI,St5
		LEA DI,St2
		ADD DI,02
		cld
		REP CMPSB
		JNz  UNM
		Jmp MAT

UNM: MOV DX,OFFSET St4
     MOV AH,09
     INT 21H
	 mov bl,4
	 call delay
	 jmp exit

mat: MOV DX,OFFSET St3
     MOV AH,09;
     INT 21H
	 mov bl,2
	 call delay
	
begin:
	call grapmode                  ; changing graphics mode	
	mov si,0
	mov di,0
	mov dx,0
	jmp disp2

;create file..................................
cr_file:
	call grapmode
	lea dx, msg2              ; module for creating a file
	call disp1
	call read1                ; read name of file to be
	lea dx, buffer1[2]        ; created
	mov cx, 0
	mov ah, 3ch               ; create the file
	int 21h
	mov handle,ax                  ; push file handle onto stack.	
writex:	lea dx, msg28             ; ask if data is to
	call disp1
	mov bx,handle                ; retrieve file handle from stack.
	mov buffer1[1], 0
write :	
	call readch               ; read data character by character.
	cmp al,40h
	jnc writex
	mov buffer1[0], al
	cmp buffer1[0], 27        ; check if character is 'Esc'(stop).
	jz no
	cmp buffer1[0], 0dh
	jne neol
	lea dx, msg31
	call disp1
	mov si, dx
	mov byte ptr ds:[si + 2], 0
	mov cx, 3
	jmp com
neol :	
	mov cx, 1
	lea dx, buffer1[0]
com :	
	mov ah, 40h               ; write to the file
	int 21h
	mov byte ptr ds:[si + 2], '$'
	jmp write
no :	
	mov bx,handle
	mov AH,3Eh
	int 21h
	lea dx, msg16             ; creation successful
	call disp1
	mov bl,02
	call delay
	jmp begin

;end of create file.................

;view file...................

vw_file:
	lea dx, msg5	; module to view the
	call disp1		; contents of a file
	lea dx, buffer1[2]
	call disp1
	lea dx, msg6	;Number: string
	call disp1	
	lea dx, buffer1[2]	
	mov al, 02h	;read/write mode
	mov ah, 3dh	; open the existing file
	int 21h
	mov buffer2[0], 0
	cmp ax, 2		; error if file not found
	jnz v_err
	lea dx, msg14
	call disp1
	jmp endv

v_err:	cmp ax, 3		; error if path not found
	jnz cont2
	lea dx, msg21
	call disp1
	mov flag,1
	jmp endv
	
cont2:	mov handle, ax
	mov bx, handle	;file handle
	mov cx, 1		;no of byte to read
	lea dx, buffer1
	mov ah, 3fh               ; read the file
	int 21h
	cmp ax, 0                 ; stop if end-of-file
	jz endv
	cmp buffer1[0], 0dh
	jnz show
	inc buffer2[0]
	cmp buffer2[0], 23        ; check if end of page
	jnz show
	lea dx, msg26
	call disp1
show : 	mov buffer1[1], '$'
	lea dx, buffer1
	call disp1
	mov ax, handle
	jmp cont2
endv :

jj:	cmp flag,0
	jne jj2
	jmp calling
jj2:	jmp optn2

;end of view file.............

;delete file...................

dl_file:
	call grapmode
	lea dx, buffer1[2]
	mov ah, 41h               ; delete the file
	int 21h
	cmp ax, 2                 ; error if file not found
	jnz err2
	lea dx, msg14
	call disp1
	jmp endd
err2 :  cmp ax, 5                 ; error if access denied
	jnz done
	lea dx, msg15
	call disp1
	jmp endd
done :  lea dx, msg17             ; delete successful
	call disp1
endd :	
	mov bl,02
	call delay
	jmp begin

;end of delete file.............
;edit file.........

ed_file:
	call grapmode
	lea dx, buffer1[2]        ; created
	mov cx, 0
	mov ah, 3ch               ; create the file
	int 21h
	mov handle, ax                   ; push file handle onto stack.	
writex2:lea dx, msg28             ; ask if data is to
	call disp1
	mov bx, handle			; retrieve file handle from stack.
	mov buffer1[1], 0
write2 :	
	call readch               ; read data character by character.
	cmp al,40h
	jnc writex2
	mov buffer1[0], al
	cmp buffer1[0], 27        ; check if character is 'Esc'(stop).
	jz no2
	cmp buffer1[0], 0dh
	jne neol2
	lea dx, msg31
	call disp1
	mov si, dx
	mov byte ptr ds:[si + 2], 0
	mov cx, 3
	jmp com2
neol2 :	
	mov cx, 1
	lea dx, buffer1[0]
com2 :	
	mov ah, 40h               ; write to the file
	int 21h
	mov byte ptr ds:[si + 2], '$'
	jmp write2
no2 :	
	mov bx,handle
	mov AH,3Eh
	int 21h
	lea dx, msg16             ; creation successful
	call disp1
	mov bl,02
	call delay
	jmp begin

;end of edit file.............

;speed dial
speed:call grapmode 
	draw macro r1,r2,c1,c2,color		; macro for rectangular box
	mov row1,r1
	mov row2,r2
	mov col1,c1
	mov col2,c2
	mov al,color
	call box
    endm
	draw 20H,40H,50H,70H,1fh
	draw 20H,40H,7AH,9CH,1fh
	draw 20H,40H,0A5H,0C8H,1fh
	draw 50H,70H,50H,70H,1fh
	draw 50H,70H,7AH,9CH,1fh
	draw 50H,70H,0A5H,0C8H,1fh
	draw 80H,0a0H,50H,70H,1fh
	draw 80H,0a0H,7AH,9CH,1fh
	draw 80H,0a0H,0A5H,0C8H,1fh
	mov ax,data
	mov es,ax
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,0bh		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,5h
	mov bp,offset t1	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl,0fh	;colour
	mov cx,01h	;string length
	mov dl,11h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,5h
	mov bp,offset t2	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,16h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,5h
	mov bp,offset t3	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,0bh		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,0bh
	mov bp,offset t4	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,11h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,0bh
	mov bp,offset t5	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,16h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,0bh
	mov bp,offset t6	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,0bh		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,12h
	mov bp,offset t7	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,11h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,12h
	mov bp,offset t8	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,01h	;string length
	mov dl,16h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,12h
	mov bp,offset t9	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h
	
	;Mouse initialization........................

	again1:
	mov ax,0000h
	int 33h
	cmp ax,0000h
	je again1

	;End Mouse initialization..................
	;show initialized mouse pointer

	mov ax, 0001h
	int 33h

	;endsssssssss show initialized mouse pointer
	;check for button click..............

;button1.........
checkr:	
	mov ax,0003h
	int 33h
	cmp bx,1h
	je rn
	cmp bx,2h		;any button pressed
	jne checkr
	mov cflag,1
rn:	shr cx,01h		;in graphical mode cx will be douled auto.

chr1:cmp cx,50h	;greater than or equal 1B we want!!!!
	jc chr2
	cmp cx,70h	;less than 5E!!!!
	jnc chr2
	cmp dx,20h	;greater than or equal 1B we want!!!!
	jc chr2
	cmp dx,40h	;less than 2E!!!!
	jnc chr2
	lea dx,f1
	cmp cflag,1
	je edit1
	
	
    mov flag,0
	jmp vw_ 	
edit1:jmp skp_
	
chr2:cmp cx,7ah	;greater than or equal 1B we want!!!!
	jc chr3
	cmp cx,9ch	;less than 5E!!!!
	jnc chr3
	cmp dx,20h	;greater than or equal 1B we want!!!!
	jc chr3
	cmp dx,40h	;less than 2E!!!!
	jnc chr3
	lea dx,f2
	cmp cflag,1
	je edit2
	mov flag,0
	jmp vw_ 		;jump to create
	
edit2:jmp skp_
	
chr3:cmp cx,0a5h	;greater than or equal 1B we want!!!!
	jc chr4
	cmp cx,0c8h	;less than 5E!!!!
	jnc chr4
	cmp dx,20h	;greater than or equal 1B we want!!!!
	jc chr4
	cmp dx,40h	;less than 2E!!!!
	jnc chr4
	lea dx,f3
	cmp cflag,1
	je edit3
	mov flag,0
	jmp vw_ 
	
edit3:jmp skp_
	
chr4:cmp cx,50h	;greater than or equal 1B we want!!!!
	jc chr5
	cmp cx,70h	;less than 5E!!!!
	jnc chr5
	cmp dx,50h	;greater than or equal 1B we want!!!!
	jc chr5
	cmp dx,70h	;less than 2E!!!!
	jnc chr5
	lea dx,f4
	cmp cflag,1
	je edit4
	mov flag,0
	jmp vw_ 

edit4:jmp skp_
	
chr5:cmp cx,7ah	;greater than or equal 1B we want!!!!
	jc chr6
	cmp cx,9ch	;less than 5E!!!!
	jnc chr6
	cmp dx,50h	;greater than or equal 1B we want!!!!
	jc chr6
	cmp dx,70h	;less than 2E!!!!
	jnc chr6
	lea dx,f5
	cmp cflag,1
	je edit5
	mov flag,0
	jmp vw_ 

edit5:jmp skp_
	
chr6:cmp cx,0a5h	;greater than or equal 1B we want!!!!
	jc chr7
	cmp cx,0c8h	;less than 5E!!!!
	jnc chr7
	cmp dx,50h	;greater than or equal 1B we want!!!!
	jc chr7
	cmp dx,70h	;less than 2E!!!!
	jnc chr7
	lea dx,f6
	cmp cflag,1
	je edit6
	mov flag,0
	jmp vw_ 

edit6:jmp skp_
	
chr7:cmp cx,50h	;greater than or equal 1B we want!!!!
	jc chr8
	cmp cx,70h	;less than 5E!!!!
	jnc chr8
	cmp dx,80h	;greater than or equal 1B we want!!!!
	jc chr8
	cmp dx,0a0h	;less than 2E!!!!
	jnc chr8
	lea dx,f7
	cmp cflag,1
	je edit7
	mov flag,0
	jmp vw_ 

edit7:jmp skp_
	
chr8:cmp cx,7ah	;greater than or equal 1B we want!!!!
	jc chr9
	cmp cx,9ch	;less than 5E!!!!
	jnc chr9
	cmp dx,80h	;greater than or equal 1B we want!!!!
	jc chr9
	cmp dx,0a0h	;less than 2E!!!!
	jnc chr9
	lea dx,f8
	cmp cflag,1
	je edit8
	mov flag,0
	jmp vw_ 

edit8:jmp skp_
	
chr9:cmp cx,0a5h	;greater than or equal 1B we want!!!!
	jc checkrx
	cmp cx,0c8h	;less than 5E!!!!
	jnc checkrx
	cmp dx,80h	;greater than or equal 1B we want!!!!
	jc checkrx
	cmp dx,0a0h	;less than 2E!!!!
	jnc checkrx
	lea dx,f9
	cmp cflag,1
	je edit9
	mov flag,0
	jmp vw_

edit9:jmp skp_
checkrx:jmp checkr
;-----------view speed

vw_:
	call grapmode	
	mov al, 02h	;read/write mode
	mov ah, 3dh	; open the existing file
	int 21h	
	lea dx,msg5
	call disp1
	mov buffer2[0], 0
	cmp ax, 2		; error if file not found
	jnz v_err8
	lea dx, msg14
	call disp1
	jmp endv8

v_err8:	cmp ax, 3		; error if path not found
	jnz cont28
	lea dx, msg21
	call disp1
	mov flag,1
	jmp endv8
	
cont28:	mov handle, ax
	mov bx, handle	;file handle
	mov cx, 1		;no of byte to read
	lea dx, buffer1
	mov ah, 3fh               ; read the file
	int 21h
	cmp ax, 0                 ; stop if end-of-file
	jz endv8
	cmp buffer1[0],'*'
	je endv8
	cmp buffer1[0], 0dh
	jnz show8
	inc buffer2[0]
	cmp buffer2[0], 23        ; check if end of page
	jnz show8
	lea dx, msg26
	call disp1

show8 : 	mov buffer1[1], '$'
	lea dx, buffer1
	call disp1
	mov ax, handle
	jmp cont28
endv8:
jj8:	cmp flag,0
	jne jj28
	jmp calling
jj28:	jmp optn2

;-----view speed---------	
jmp begin
	
skp_:mov cx,0
	mov ah,3ch
	int 21h
	mov handle ,ax
	call grapmode
	lea dx, msg2              ; module for creating a file
	call disp1
	call read1                ; read name of file to be
	lea dx, buffer1[2]        ; created
	mov bx,handle
	mov ch,0
	mov cl,buffer1[1]
	mov ah,40h
	int 21h
	mov cx,1
	lea dx,msg25
	mov ah,40h
	int 21h

writex9:	lea dx, msg28             ; ask if data is to
	call disp1
	mov bx,handle                ; retrieve file handle from stack.
	mov buffer1[1], 0
write9 :	
	call readch               ; read data character by character.
	cmp al,40h
	jnc writex9
	mov buffer1[0], al
	cmp buffer1[0], 27        ; check if character is 'Esc'(stop).
	jz no9
	cmp buffer1[0], 0dh
	jne neol9
	lea dx, msg31
	call disp1
	mov si, dx
	mov byte ptr ds:[si + 2], 0
	mov cx, 3
	jmp com9
neol9 :	
	mov cx, 1
	lea dx, buffer1[0]
com9 :	
	mov ah, 40h               ; write to the file
	int 21h
	mov byte ptr ds:[si + 2], '$'
	jmp write9
no9 :	
	mov bx,handle
	mov AH,3Eh
	int 21h
	lea dx, msg16             ; creation successful
	call disp1
	mov bl,02
	call delay
	mov cflag,0
	jmp speed
	
;backup file.................

bkp_file:push nooffile
	mov dh,3h
strt:	push dx
	cmp nooffile,0
	je edv2
	jmp xyz
edv2: jmp endv2
xyz: 	
dhruv1:
	mov buffer1[0],80
	mov di,2h
	mov dl, 1
dhr1:mov bh, 0
	mov ah, 2
	int 10h
	mov ah, 08h
	int 10h
	mov buffer1[di],al
	inc di
	inc dl
	cmp al, 0	;end of string.....
	jne dhr1
	mov buffer1[di],'$'
	sub di,3h
	mov si,0
	lea dx, buffer1[2]	
	mov al, 02h	;read/write mode
	mov ah, 3dh	; open the existing file
	int 21h
	mov buffer2[0], 0
	cmp ax, 2		; error if file not found
	jnz v_err1
	lea dx, msg14
	call disp1
	jmp endv1

v_err1:	cmp ax, 3		; error if path not found
	jnz cont21
	lea dx, msg21
	call disp1
	mov flag,1
	jmp endv1
	
cont21:	mov handle, ax
	mov bx, handle	;file handle
	mov cx, 1		;no of byte to read
	lea dx, buffer3[si]
	mov ah, 3fh               ; read the file
	int 21h
	cmp ax, 0                 ; stop if end-of-file
	jz endv1
	cmp buffer3[si], 0dh
	jnz show1
	inc buffer2[0]
	cmp buffer2[0], 23        ; check if end of page
	jnz show1
	lea dx, msg26
	call disp1
show1 : inc si
	
	mov ax, handle
	jmp cont21
endv1 :	mov buffer3[si], '$'

;=========
	cmp flag2,1
	je opn

cre:	lea dx, filename        ; created
	mov cx, 0
	mov ah, 3ch               ; create the file
	int 21h
	mov handle,ax
	jmp skp_opn

opn:	mov al,2
	lea dx, filename        ; created
	mov cx, 0
	mov ah, 3dh               ; create the file
	int 21h
	mov handle,ax
	mov bx,handle
	mov al,2
	mov cx, 0
	mov dx, 0
	mov ah,42h
	int 21h
	
skp_opn:mov bx,handle	;file handle transfer
	lea dx, md1	; module to view the
	mov cx,len1
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, buffer1[2]	; module to view the
	mov cx,di
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, md2	; module to view the
	mov cx,len2
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, buffer1[2]	; module to view the
	mov cx,di
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, md3	; module to view the
	mov cx,len3
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, buffer3	; module to view the
	mov cx,si
	mov ah,40h
	int 21h

	mov bx,handle	;file handle transfer
	lea dx, md4	; module to view the
	mov cx,len4
	mov ah,40h
	int 21h

close:	mov bx,handle
	mov ah,3eh
	int 21h
	
	mov flag2,1
	dec nooffile 
	pop dx
	inc dh
	jmp strt
endv2:	pop nooffile
	mov flag2,0
	jmp exit

;end of backup file......... 
	
;call....................
calling:mov dx,4560
	call tone
	
	mov dx,4063
	call tone
	
	mov dx,3619
	call tone
	
	mov dx,3416
	call tone
	
	mov dx,3043
	call tone
	
	mov dx,2711
	call tone
	
	mov dx,2415
	call tone
	
	mov dx,4560
	call tone
	
	lea dx,msg23
	call disp1

	mov bl,03
	call delay
	jmp begin


tone proc
	mov     al, 182         ; Prepare the speaker for the
        out     43h, al         ;  note.
        mov     ax,dx        ; Frequency number (in decimal)
                                ;  for middle C.
        out     42h, al         ; Output low byte.
        mov     al, ah          ; Output high byte.
        out     42h, al 
        in      al, 61h         ; Turn on note (get value from
                                ;  port 61h).
        or      al, 00000011b   ; Set bits 1 and 0.
        out     61h, al         ; Send new value.

	mov bl,01
	call delay

        in      al, 61h         ; Turn off note (get value from
                                ;  port 61h).
        and     al, 11111100b   ; Reset bits 1 and 0.
        out     61h, al         ; Send new value.
	ret
endp

;end of call.......................

;disp2 proc.........................
disp2:
     
	mov dh, 0	;set cursor
	mov dl, 0	;position
	mov bh, 0	;to o,o
	mov ah, 2
	int 10h
	mov nooffile,0
	lea dx, msg1	; display menu
	call disp1		;write stndrd string to STDOUT
	lea dx, msg24 	; module for displaying
			; contents of directory
	mov cx, 0
	mov ah, 4eh	; Get first file
	int 21h		; in directory
	cmp ax, 18		; Check if no files
	jnz list5		; in directory
	lea dx, msg14	; Display message
	call disp1		; 'File not found'
	jmp optn		;go to buttons
list5 :	lea dx,msg32
	call disp1
	mov ah, 2fh	; Get dta address
	int 21h
	mov byte ptr es:[bx + 42], 0
	add bx, 1eh
	mov buffer1[0], 0
char5 :	
	mov dl, byte ptr es:[bx]  ; Get character of
	inc bx		; filename from DTA
	inc buffer1[0]
	cmp dl, '.'		; Check if extension
	jnz cont8		; is starting
cont7 :	
	lea dx, msg31
	call disp1
	inc buffer1[0]
	cmp buffer1[0], 0bh       ; Check for end of filename
	jne cont7                 ; buffer - 13 characters
	jmp char5
cont8 :	
	mov ah, 02h               ; Display character
	int 21h                   ; of filename
	cmp dl, 0                 ; Check for end
	jne char5                  ; of file name
	lea dx, msg26
	call disp1
	inc cx
	inc nooffile	;...............................................
	cmp cx, 23                ; Check for end of page
	jne cont9
	jmp optn
	mov cx, 0
	lea dx, msg26
	call disp1
cont9 :	
	mov ah, 4fh               ; Get next file
	int 21h
	jnc list5
	jmp optn

disp1 proc			
	push ax
	  mov ah, 09h	; module for display of
	  int 21h		; a string on screen
	pop ax
	  ret
disp1 endp	

delay proc
	mov ah,2ch
	int 21h
	mov bh,dh
	add bh,bl
	cmp bh,3ch
	jc sc2
	sub bh,3ch
sc2:	mov ah,2ch
sc:	int 21h
	cmp bh,dh
	jne sc

	ret
endp

readch proc               
	  mov ah, 01h	; module for reading a
	  int 21h		; character from keyboard
	  ret
readch endp

read1 proc			; module for reading
	  mov buffer1[0], 80	; first string===========================
	  mov buffer1[1],0	
	  lea dx, buffer1
	  mov ah, 0ah	; read string from keyboard
	  int 21h
	  mov bl, buffer1[1]
	  mov bh, 0
	  add bx, 2
	  mov buffer1[bx], 0	; ASCIIZ string, so
	  ret		; terminate with 0
read1 endp	

;Graphics MOdule -1- starts.................
optn:	
	
	mov bx,018h
	push nooffile
sna2:	cmp nooffile,0
	je sna222
	mov cx,0120h	;column 
	mov dx,bx	;row
	mov al,02h	;button color(green)
	mov ah,0ch	;change colour for single pixel
        add bx,07h	;bx=bx+7
sna22:	int 10h
	inc cx
	cmp cx,0128h
	jne sna22
	inc dx
	mov cx,0120h
	cmp dx,bx
	jne sna22
	inc bx		;bx=(bx)+1 ~bx+8
	dec nooffile
	jmp sna2
sna222:	pop nooffile

	mov bx,018h
	push nooffile
sna23:	cmp nooffile,0
	je sna2223
	mov cx,0130h	;column 
	mov dx,bx	;row
	mov al,0fh	;button color(white)
	mov ah,0ch	;change colour for single pixel
        add bx,07h	;bx=bx+7
sna223:	int 10h
	inc cx
	cmp cx,0138h
	jne sna223
	inc dx
	mov cx,0130h
	cmp dx,bx
	jne sna223
	inc bx		;bx=(bx)+1 ~bx+8
	dec nooffile
	jmp sna23
	
sna2223:pop nooffile


	;Drawing button..............................
;button1

	mov cx,0bh	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color(white)
	mov ah,0ch	;change colour for single pixel
sna:    int 10h
	inc cx
	cmp cx,4ah
	jne sna
	inc dx
	mov cx,0Bh
	cmp dx,0c2h
	jne sna
;button2
	mov cx,4eh	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color
	mov ah,0ch	;change colour for single pixel
sna1:	int 10h
	inc cx
	cmp cx,07ah
	jne sna1
	inc dx
	mov cx,4eh
	cmp dx,0c2h
	jne sna1

;button3
	mov cx,080h	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color
	mov ah,0ch	;change colour for single pixel
sn1:	int 10h
	inc cx
	cmp cx,0e5h
	jne sn1
	inc dx
	mov cx,080h
	cmp dx,0C2h
	jne sn1

;button4
	mov cx,0ebh	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color
	mov ah,0ch	;change colour for single pixel
sn11:	int 10h
	inc cx
	cmp cx,123h
	jne sn11
	inc dx
	mov cx,0ebh
	cmp dx,0C2h
	jne sn11
	
	;Drawing button  END..............
	
	;Drawing string on button.........................

;button1

	mov ax,data
	mov es,ax
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	    ;colour
	mov cx,06h	    ;string length
	mov dl,2h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,17h
	mov bp,offset but1	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h

;button2
	mov al,01h
	mov bh,0h
	mov bl, 0fh
	mov cx,04h
	mov dl,0bh
	mov dh,17h
	mov bp,offset but3
	mov ah,13h
	int 10h

;button3
	mov al,01h
	mov bh,0h
	mov bl, 0fh
	mov cx,0ah
	mov dl,11h
	mov dh,17h
	mov bp,offset but2
	mov ah,13h
	int 10h

;button4
	mov al,01h
	mov bh,0h
	mov bl, 0fh
	mov cx,06h
	mov dl,1eh
	mov dh,17h
	mov bp,offset but44
	mov ah,13h
	int 10h
	;end Drawing button.............


	mov ax,data
	mov ds,ax
	
	;Mouse initialization........................
	again:
	mov ax,0000h
	int 33h
	cmp ax,0000h
	je again

	;End Mouse initialization..................
	;show initialized mouse pointer

	mov ax, 0001h
	int 33h

	;endsssssssss show initialized mouse pointer
	;check for button click..............

;button1.........
check:	mov fileno,0h
	mov ax,0003h
	int 33h
	cmp bx,1h		;any button pressed
	jne check
	
	shr cx,01h		
	cmp cx,0Bh	;greater than or equal 0B we want!!!!
	jc che1
	cmp cx,4ah	;less than 4A!!!!
	jnc che1
	cmp dx,0b0h	;greater than or equal 0B0 we want!!!!
	jc che1
	cmp dx,0c3h	;less than C3!!!!
	jnc che1
	jmp cr_file		;jump to create

;button2........
che1:	cmp cx,4eh	;greater than or equal 60 we want!!!!
	jc che5
	cmp cx,7Ah	;less than A2!!!!
	jnc che5
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc che5
	cmp dx,0c3h	;less than 2E!!!!
	jnc che5
	jmp exit		;jump to exit(operating system)

;button3........
che5:	cmp cx,80h	;greater than or equal 60 we want!!!!
	jc che55
	cmp cx,0e5H	;less than A2!!!!
	jnc che55
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc che55
	cmp dx,0C3h	;less than 2E!!!!
	jnc che2
	jmp speed		;jump to exit(operating system)

;button4........
che55:	cmp cx,0eBh	;greater than or equal 60 we want!!!!
	jc che2
	cmp cx,123H	;less than A2!!!!
	jnc che2
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc che2
	cmp dx,0C3h	;less than 2E!!!!
	jnc che2
	jmp bkp_file		;jump to exit(operating system)
	
CHECKIO: JMP CHECK
	
che2:	cmp cx,0120h
	jc checkIO
	cmp cx,0128h
	jnc che222
	mov bx,18h
	cmp dx,bx
	jc che222
	mov ax,nooffile
che22:	cmp ax,0h
	je checkIO
	inc fileno
	add bx,08h
	dec ax
	cmp dx,bx
	jnc che22
		
	mov flag,0
	jmp dhruv	;--------------------------
	

che222:	cmp cx,0130h
	jc checkx
	cmp cx,0138h
	jnc checkx
	mov bx,18h
	cmp dx,bx
	jc checkx
	mov ax,nooffile
che2222:cmp ax,0h
	je checkx
	inc fileno
	add bx,08h
	dec ax
	cmp dx,bx
	jnc che2222
		
	mov flag,1
	jmp dhruv	;--------------------------
	
checkx:	jmp check

;Endsssssssssss check for button click............
		
dhruv:
	
	mov buffer1[0],80
	mov di,2h
	mov dl, 1
dhr:	push fileno
	mov dh, 2
dhru:	inc dh
	dec fileno
	cmp fileno, 0h
	jne dhru
	pop fileno
	mov bh, 0
	mov ah, 2
	int 10h
	mov ah, 08h
	int 10h
	mov buffer1[di],al
	inc di
	inc dl
	cmp al, 0	;end of string.....
	jne dhr
	mov buffer1[di],'$'
	call grapmode
	jmp vw_file
	

;End of Graphics MOdule -1- ..................

;Graphics MOdule -2- starts.................
optn2:	mov ax,data
	mov es,ax

;Drawing button..............................
;delete button
	mov cx,1Bh	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color(white)
	mov ah,0ch	;change colour for single pixel
sna3:  	int 10h
	inc cx
	cmp cx,5Dh
	jne sna3
	inc dx
	mov cx,1Bh
	cmp dx,0c2h
	jne sna3
;edit button
	mov cx,60h	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color
	mov ah,0ch	;change colour for single pixel
sna4:	int 10h
	inc cx
	cmp cx,0A2h
	jne sna4
	inc dx
	mov cx,60h
	cmp dx,0c2h
	jne sna4
;back button
	mov cx,0a6h	;column
	mov dx,0b0h	;row
	mov al,0fh		;button color
	mov ah,0ch	;change colour for single pixel
sna5:	int 10h
	inc cx
	cmp cx,0f8h
	jne sna5
	inc dx
	mov cx,0a6h
	cmp dx,0c2h
	jne sna5

	;Drawing button  END..............
	
	;Drawing string on button.........................

;delete button
	mov al,01h		;string write mode with attr.
	mov bh,0h		;page no
	mov bl, 0fh	;colour
	mov cx,06h	;string length
	mov dl,4h		; 1Bh+4h=20h=32d 32d/8d=4pixel
	mov dh,17h
	mov bp,offset but4	;??
	mov ah,13h	;display string with attr. in graphical mode
	int 10h

;edit button
	mov al,01h
	mov bh,0h
	mov bl, 0fh
	mov cx,04h
	mov dl,0eh
	mov dh,17h
	mov bp,offset but5
	mov ah,13h
	int 10h

;back button
	mov al,01h
	mov bh,0h
	mov bl, 0fh
	mov cx,04h
	mov dl,16h
	mov dh,17h
	mov bp,offset but6
	mov ah,13h
	int 10h

	;end Drawing button.............
	;Mouse initialization........................

	again2:
	mov ax,0000h
	int 33h
	cmp ax,0000h
	je again2

	;End Mouse initialization..................
	;show initialized mouse pointer

	mov ax, 0001h
	int 33h

;endsssssssss show initialized mouse pointer
;check for button click..............
;delete button.........

check1:	mov ax,0003h
	int 33h
	cmp bx,1h		;any button pressed
	jne check1
	
	shr cx,01h		;in graphical mode cx will be douled auto.

	cmp cx,1Bh	;greater than or equal 1B we want!!!!
	jc che3
	cmp cx,5Eh	;less than 5E!!!!
	jnc che3
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc che3
	cmp dx,0c3h	;less than 2E!!!!
	jnc che3
	jmp dl_file		;jump to create

;edit button........
che3:	cmp cx,60h	;greater than or equal 60 we want!!!!
	jc che4
	cmp cx,0A2h	;less than A2!!!!
	jnc che4
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc che4
	cmp dx,0c3h	;less than 2E!!!!
	jnc che4
	jmp ed_file		;jump to delete

;back button........
che4:	cmp cx,0A4h	;greater than or equal A4 we want!!!!
	jc check1
	cmp cx,0E6h	;less than E6!!!!
	jnc check1
	cmp dx,0b0h	;greater than or equal 1B we want!!!!
	jc check1
	cmp dx,0c3h	;less than 2E!!!!
	jnc check1
	jmp begin		;jump to delete

	;Endsssssssssss check for button click............
	
	call textmode	;back to text mode
	
;End of Graphics MOdule -2- ..................

grapmode proc		 ;for graphic mode
	mov al,13h
	mov ah,00  
	int 10h
	ret
endp

textmode proc		 ;for text mode
	mov al,03h
	mov ah,00h
	int 10h
	ret
endp
box proc near			;DRAW BOX/RECTANGLE
	push cx
	push dx
	mov cx,col1
	mov dx,row1
	mov ah,0ch
back_a1 :	
	int 10h
	inc cx
	cmp cx,col2
	jne back_a1
	mov cx,col1
	inc dx
	cmp dx,row2
	jne back_a1
	pop dx
	pop cx
	ret
box endp
exit:	call textmode
	mov ah,4ch	;back to operating system
	int 21h

code ends
END start
