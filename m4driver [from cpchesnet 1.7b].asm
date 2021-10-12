;todas las rutinas para la m4



.deteccion_m4

ei
call busca_rom ;carry flag, encontrada, no carry no encontrada
di

;apartir de aqui esta activada la rom de la m4 en #c000

jp c,texto_encontrada

ld hl,rom_no_encontrada
ld de,temp_buscando
ld bc,31
ldir
call menu_m4 ;updatamos textos
.para_ejecucion jp para_ejecucion


.texto_encontrada

ld hl,rom_encontrada
ld de,temp_buscando
ld bc,31
ldir
CALL menu_m4
;ret

;seguimos con el proceso de deteccion
;recuerda que la m4 esta activada en #c000-#ffff
ld hl,&FF02	; get response buffer address ;esta inicializada la m4rom
ld e,(hl)
inc hl
ld d,(hl)

push	de ;metemos en pila para despues recuperar en iy

;en de tenemos la direccion de contestacion de la m4
;la guardamos en una variable para usos posteriores.
ld a,d
ld (response_buffer+1),a ;low endian

ld a,e
ld (response_buffer),a


pop	iy ;apartir de ahora iy apunta a buffer de contestacion de la m4 a nuestros comandos

call mira_version

call estado_conexion

ret

;-----------------------fin detecta m4---------------

.mira_version

ld hl,cmdver
call sendcmd 

push iy ;metemos en pila puntero al buffer de contestacion
pop hl ;lo sacamos para hl
inc hl : inc hl : inc hl ;lo hace siempre, deben ser 3 parametros no texto.

;metemos en buffer de version los datos del buffer de la m4
ld de,temp_version
ld bc,23 ;por poner algo de momento
ldir ;el $ queda ya definido en el propio temp


ret

;--------------------------------------------------------------

.estado_conexion

ld hl,cmdnetstat
call sendcmd 

push iy ;metemos en pila puntero al buffer de contestacion
pop hl ;lo sacamos para hl
inc hl : inc hl : inc hl ;lo hace siempre, deben ser 3 parametros no texto.

;metemos en buffer de version los datos del buffer de la m4
ld de,temp_estado
ld bc,20 ;por poner algo de momento
ldir ;el $ queda ya definido en el propio temp



ret


sendcmd:
			ld	bc,&FE00
			ld	d,(hl)
			inc	d
sendloop:		inc	b
			outi
			dec	d
			jr	nz,sendloop
			ld	bc,&FC00
			out	(c),c
ret


.busca_rom

   ld a,(m4_rom_num)
   cp &FF
   call	z,find_m4_rom	; find rom (only first run) ;la encuentra y LA INCIALIZA EN &C000, a partir de ahora &c000 lee la "rom" de la m4
			; should add version check too and make sure its v1.0.9
   cp	&FF ;a viene cargada con la rom encontrada de la m4
   jp	nz,encontrada
   ;error, no encontrada		
   xor a ;desactivamos carry
   ret

  .encontrada
   scf
   ret



.find_m4_rom:
			ld	iy,m4_rom_name	; rom identification line
			ld	d,127		; start looking for from (counting downwards)
			
romloop:		push	de
			;ld	bc,&DF00
			;out	(c),d		; select rom
			ld	c,d
			call	&B90F		; system/interrupt friendly
			ld	a,(&C000)
			cp	1 ;marca de agua inicial, si no hay 1 en el primer byte fuera.
			jr	nz, not_this_rom
			
			; get rsxcommand_table
			
			ld	a,(&C004)
			ld	l,a
			ld	a,(&C005)
			ld	h,a ;hl=#c075; le dice donde empieza la tabla de RSX, la primera es 'M4 BOAR',&c4
			push	iy
			pop	de
cmp_loop:
			ld	a,(de) ;buffer de texto 'M4 BOAR',&c4 para comparar
			xor	(hl)			; hl points at rom name
			jr	nz, not_this_rom
			ld	a,(de)
			inc	hl
			inc	de
			and	&80 ;corta al encontrar &c4
			jr	z,cmp_loop
			
			; rom found, store the rom number
			
			pop	de			;  rom number
			ld 	a,d
			ld	(m4_rom_num),a
			ret
			
not_this_rom:
			pop	de
			dec	d
			jr	nz,romloop
			ld	a,255		; not found!
			ret




;variables para m4
;PEGADAS TAL CUAL DUKE
msgserver:	db	"********** TCP SERVER **********",10,13,0
msgsignal:	db	"Signal: &",0
msgtime:		db	"Time: ",0
msgwait:		db	10,13,"TCP server, waiting for client to connect...",10,13,0			
msgconnected:	db	10,13,"Client connected! IP addr: ",0
msgconnclosed:	db	10,13,"Remote closed connection....",10,13,0
msgsenderror:	db	10,13,"ERROR: ",0
cmdwelcome:	db	29
			dw	C_NETSEND
sendsock2:	db	0
			dw	24			
			db	10,13,"Welcome to M4 NET !",10,13,0
cmdnetstat:	db	2
			dw	C_NETSTAT
cmdrssi:		db	2
			dw	C_NETRSSI
cmdtime:		db	2
			dw	C_TIME
cmdver:		db	2
			dw	C_VERSION
cmdsocket:	db	5
			dw	C_NETSOCKET
			db	&0,&0,&6		; domain(not used), type(not used), protocol (TCP/IP)
;cliente
cmdconnect:	db	9	
			dw	C_NETCONNECT
csocket:		db	&0
ip_addr:		db	0,0,0,0	;ip address, la usa para conectarse
cport:			dw	&17F0 ;6128 EN DECIMAL ;&1234	; port, cport lo he puesto yo para poder modificar el puerto aqui
;cliente fin

;servidor
cmdbind:		db	9
			dw	C_NETBIND
bsocket:		db	&0
bipaddr:		db	0,0,0,0	;aparentemente coge la local automaticamente ; IP 0.0.0.0 == IP_ADDR_ANY
bport:	        	dw	&17F0 ;6128 EN DECIMAL ;&1234		; port number

cmdlisten:	db	3
			dw	C_NETLISTEN
lsocket:		db	0

cmdaccept:	db	3
			dw	C_NETACCEPT
asocket:		db	0


cmdsend:		db	0			; we can ignore this byte (part of early design)	
			dw	C_NETSEND
sendsock:		db	0
sendsize:		dw	0			; size
sendtext:		ds	255 ;AQUI HAY QUE LDIR LO QUE QUEREMOS MANDAR!!
			
cmdclose:		db	&03
			dw	C_NETCLOSE
clsocket:		db	&0

cmdrecv:		db	5
			dw	C_NETRECV		; recv
rsocket:		db	&0			; socket
rsize:		dw	2048			; size
			
m4_rom_name:	db "M4 BOAR",&C4		; D | &80
m4_rom_num:	db	&FF
buf:			ds	255	