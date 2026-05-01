;Werewolves of london
;disco original uk 
;Anticopy v5 + Weak Sectors

;No hay acentos ya que el winape pone otros simbolos.

;Comentarios sobre el loader

;No funciona en la gama plus, ya que ejecuta ;KL U ROM ENABLE ;ACTIVA LA ROM DE BASIC EN &C000
;pero en la gama plus NO se activa el basic, con lo cual los datos recabados son erroneos.

;Efectua una lectura al track 40 sector &6D que almacenara en &A9B0-&ABAF =&200 (512 bytes leidos)
;despues saltara a esa direccion con un call &A9B0, alli hay una rutina para decodificar la zona de RAM &0170-&028B
;En ese rango hay un codigo de BASIC normal codificado. decodifica estas instrucciones de basic y despues llamara al programa
;de basic para efectuar la carga del juego con loads normales y corrientes.

;Una vez acaba de cargar el juego mediante basic, salta a codigo añadido al propio juego para efectuar comprobación de que el disco insertado
;es el original con Weak Sectors. Este codigo NO existe en la version cinta.
;Efectuara 3 lecturas mas al track 40 sector &C6 (WEAK SECTOR) para decodificar el programa principal en &5172 (o resetear el CPC si no es el original)
;documento esta ultima proteccion anticopia al final de este archivo.

;----------NOTAS DE roudoudou EN CPCWIKI SOBRE LOS WEAKSECTORS---------------
;there is different weak sectors, but the thing is there is at least one weak bit
;there is a transition at detection limit so sometimes the FDC see a 1, sometimes a 0 and everything can change after that
;regarding the control routine, only one difference is ok
;but there is games (passager du temps AFAIK) which require 3 differents reads on 10
;just remember DSK are not masters, only a dedicated format to run on emulators
;-------------------------------------------------------------------------------



;rango de carga del loader &0040-&028B
;NOTA
;el fichero "as.bin" del disco original es "binario protegido"
;tal como esta grabado en el disco el codigo de este archivo esta encriptado
;El interprete de basic ejecuta el run"as.bin" que acabara llamando a CAS IN DIRECT
;ira leyendo de 128 bytes en 128bytes desde disco
;cada 128 bytes leido, decodificara estos datos usando un valor en el rango de zona de ram &D281 (UPPER ROM AMSDOS)
;se decodificadara en su totalidad XOReando esa zona de memoria en la UPPER ROM con la zona del propio juego.
;El tipo "binario protegido" no se puede crear con un save de BASIC (que yo sepa), tuvo que ser creado con alguna herramienta?

run entrada

org #0040

.l0040 ;address_of_start_of_ROM_lower_reserved_area
;buffer que usa la ROM de BASIC para tokenizar el comando de basic tecleado.
;basicamente el run"as" tecleado en disco original o cualquier cosa que se escriba y se pulse enter en interprete de BASIC
db #ca,#01,#00,#00,#00,#00

.entrada ;&46
ld de,&0040 ;primer byte usable
ld hl,#abff ;ultimo byte usable
call #bccb ;KL ROM WALK ;inicializa todas las roms del sistema

;hl trae el ultimo byte usable despues de KL ROM WALK
;de trae el primer byte usable despues de KL ROM WALK
push hl ;hl=&A6FB
push de ;de=&0040

ld hl,CMDtablaRSX ;direccion de memoria con comando a buscar en roms
;&84 ;comando READ SECTOR en la tabla de RSX (&04+&80)
call #bcd4 ;KL FIND COMMAND
;comando encontrado carry=true
;reg c trae numero de ROM que tiene el comando; c=&07 (rom de amsdos)
;reg hl trae direccion del comando; hl=&C03C ;BIOS & CP/M 2.1 EXTENDED JUMPBLOCK READ SECTOR

ld (guarda_dirCMD),hl ;guarda la direccion del comando
ld a,(#a702) ;direccion de memoria reservada para AMSDOS, no esta documentada o no esta bien documentada. 
             ;aparenta guardar que disquetera se esta usando (0 o 1), pero la guia de firmware dice que esa
             ;variable se encuentra en &A700
             ;reg a=&00 disquetera A

ld e,a ;guarda disquetera usada.
ld d,#28 ;TRACK PARA READ SECTOR (TRACK 40)
ld c,#6d ;SECTOR ID PARA READ SECTOR
ld hl,#a89f ;number of first sector (&01=IBM; &41=System; &C1=Data)
ld (hl),#64 ;&64 supongo definido en master del disco ya que no es ningun formato standard
inc hl ;&a8a0 number of sectors per track (Data=9; System=9; IBM=8)
ld (hl),#0a ;10 sectores por track
ld hl,#a9b0 ;buffer PARA READ SECTOR
rst #18 ;FAR CALL &18 RST3
db &05
db &01 ;&0105, direccion de memoria donde estan los parametros para FAR CALL &18
       ;3 bytes, los 2 primeros direccion del comando de amsdos buscados, el tercero numero rom de AMSDOS
       ;guarda_dirCMD, direccion donde guardo a donde apunta READ SECTOR en rom de AMSDOS
       ;NromAMSDOS=&07

;efectua salto a READ SECTOR de AMSDOS
;;==================================================================
;; BIOS: READ SECTOR
;;
;; HL = buffer
;; E = drive
;; D = track
;; C = sector id
;;
;; NOTES:
;; - H parameter is forced to 0
;; - N parameter comes from XDPB
;; - R parameter defined by user
;; - only 1 sector read at a time
;; - C parameter defined by user (must be valid track number)
;; - double density only
;; - "read data" only + skip

;PARAMETROS ENVIADOS
;REG HL=&A9B0 BUFFER
;REG E=&00 DRIVE A
;REG D TRACK= &28 (TRACK 40)
;REG C SECTOR ID = &6D

;lee del track 40 (datos de proteccion anticopia, lee una rutina que desencriptara el codigo basic en &0170)
;escribe esos datos en &A9B0-&ABAF =&200 (512 bytes leidos)
;datos reales &A9B0-&AB2F (los restantes estan marcados como &E5, sin datos en el disco)

;vuelve por aqui despues de ejecutar la lectura del track 40
.L0070
ld hl,&0104
call &BCD4 ;KL FIND COMMAND
;comando encontrado carry=true
;reg c trae numero de ROM que tiene el comando; c=&07 (rom de amsdos)
;reg hl trae direccion del comando; hl=&C045 ;; BIOS & CP/M 2.1 EXTENDED JUMPBLOCK MOVE TRACK

ld (guarda_dirCMD),hl ;guarda la direccion del comando

ld hl,#a89f ;number of first sector (&01=IBM; &41=System; &C1=Data)
ld (hl),#41 ;number of first sector (&01=IBM; &41=System; &C1=Data)
inc hl
ld (hl),#09 ;&a8a0 number of sectors per track (Data=9; System=9; IBM=8)
ld a,(#a702) ;disquetera a usar a=&00
ld e,a ;parametro disquetera a usar para MOVE TRACK
ld d,#02 ;parametro de track al que desplazar cabezal de MOVE TRACK
rst #18 ;FAR CALL RST3
db &05 
db &01 ;&0105, direccion de memoria donde estan los parametros para FAR CALL &18
       ;3 bytes, los 2 primeros direccion del comando de amsdos buscados, el tercero numero rom de AMSDOS
       ;guarda_dirCMD, direccion donde guardo a donde apunta MOVE TRACK en rom de AMSDOS
       ;NromAMSDOS=&07

;efectua salto a MOVE TRACK
;;=======================================================================
;; BIOS: MOVE TRACK
;;
;; entry:
;; E = drive
;; D = track

;e=&00
;d=&02

;vuelve por aqui despues de mover track.
;NOTA, este movimiento de track es mas bien una perdida de tiempo.
      ;para que el comando de READ SECTOR finalice correctamente con esta perdida de tiempo?

call codigo_proteccion ;&A9B0 ;salta a codigo leido del track 40 sector &6D (proteccion anticopia) (DOCUMENTADO MAS ABAJO)
;decodifica &0170-&028B usando un byte fijo para decodificar y saca el tamano a decodificar del tamano del fichero as.bin

.L008D
pop de ;recupera de pila el primer byte usable despues de KL ROM WALK
pop hl ;recupera de pila el ultimo byte usable despues de KL ROM WALK

call #b900 ;KL U ROM ENABLE ;ACTIVA LA ROM DE BASIC EN &C000
           ;OJO, ESTO LO HACE INCOMPATIBLE CON LA GAMA CPC+
           ;KL U ROM ENABLE activa la zona &9f Cartridge bank 31, en vez de &00 cartridge bank 1

;UPPER ROM BASIC ACTIVADO EN &C000-&FFFF
;hara 2 llamadas a rutinas de BASIC en UPPER ROM SEGUN EL MODELO DE CPC USANDOSE.
ld a,(#c002) ;lee la version de Basic en uso, 00=464, 01=664, 02=6128, 04=464+ 6128+ 
             ;(NO FUNCIONA EN GAMA PLUS, NO SE MUESTRA LA ZONA CORRECTA DE BASIC)
or a
jr z,cpc464 ;l00c4 ;si es cpc464 se cumple Z, nz cpc664 y 6128
cp #01 ;es cpc664?
jr z,cpc664 ;l00b0

;por aqui es cpc6128

;RUTINA EN &F53F DE UPPER ROM, BASIC.
;;initialise memory model
;Values passed from MC_START_PROGRAM
;DE = first byte of available memory
;HL=last byte of memory not used by BASIC
;BC=last byte of memory not used by firmware

;Returns Carry true if failed - I.e. not enough memory

call #f53f ;llama a rutina de Basic en UPPER ROM ;;initialise memory model

;RUTINA EN &CB37 DE UPPER ROM, BASIC.
;;<< EXCEPTION HANDLING
;;< Includes ERROR, STOP, END, ON ERROR GOTO 0 (not ON ERROR GOTO n!), RESUME and error messages
;;========================================================================
;; clear errors and set resume addr to current
call #cb37 ;EXCEPTION HANDLING
           ;resume addr, hl=&000


ld a,#ff
ld (#ae2c),a ;program protection flag (<>0 hides program as if protected)
ld ix,#ae64 ;address of end of ROM lower reserved area (byte before Program area)
ld hl,#de60 ;direccion de rutina de basic en UPPER ROM ;;execute statement at HL
            ;lo usa para que en el RET de la rutina en &00D6 se vuelva a &DE60, rutina de BASIC EN UPPER ROM. 
jr ejecutaBASICprg ;l00d6
;NO vuelve por aqui, vuelve a &DE60 ;direccion de basic ;;=execute statement at HL
;basicamente ejecuta el programa de basic cargado en &0170 (cargado en este propio loader)

.l00b0
.cpc664 ;igual que en cpc6128 con diferentes direcciones de la rom de basic ya que varian entre modelos
call #f544
call #cb3a
ld a,#ff
ld (#ae2c),a
ld ix,#ae64
ld hl,#de65
jr ejecutaBASICprg ;l00d6

.l00c4
.cpc464 ;igual que en cpc6128 con diferentes direcciones de la rom de basic ya que varian entre modelos
call #f4c4
call #ca84
ld a,#ff
ld (#ae45),a
ld ix,#ae81
ld hl,#dd74

.ejecutaBASICprg ;l00d6 ;punto de entrada despues de inicializar el modelo en particular de CPC
       ;hara un run del programa basic situado en &0170 (cargado en este mismo loader)
       ;SE EJECUTARA UN PROGRAMA DE BASIC NORMAL Y CORRIENTE EN &0170 QUE EFECTUARA LA LECTURA DE ARCHIVOS DEL JUEGO
       ;CON LOADS NORMALES.
       ;Al final del programa basic, se hara un CALL 38403 (CALL &9603), RUTINA PARA PROTECCION ANTICOPIA WEAKSECTORS
       ;DOCUMENTADA MAS ABAJO EN ESTE ARCHIVO.

push hl ;mete en stack ;direccion de rutina basic en UPPER ROM ;;=execute statement at HL
        
ld hl,(#a76d) ;length of file in bytes (&0000 for ASCII files)
              ;hl=&024C lee lo que ocupa fichero de carga as.bin, se escribio en esta direccion al hacer run"as.bin"
ld bc,l0040 ;inicio de este loader
add hl,bc   ;&024C+&0040=&028C
ld de,l016f ;ultimo byte de este loader antes del codigo decodificado en &0170
ld (ix+#00),e
ld (ix+#01),d ;&AE64 address of end of ROM lower reserved area (byte before Program area)
              ;de=&016F; es decir establece el Program Area en la direccion decodificada de este loader (&0170)

ld (ix+#02),l
ld (ix+#03),h ;&AE66 address of start of Variables and DEF FNs area

ld (ix+#04),l
ld (ix+#05),h ;&AE68 address of start of Variables and DEF FNs area

ld (ix+#06),l 
ld (ix+#07),h ;&AE6A address of start of Arrays area (where next Variable or DEF FN entry is placed)

ld (ix+#08),l
ld (ix+#09),h ;&AE6C address of start of free space (where next Array entry is placed)

ld hl,#003f ;parametro para ;direccion de basic ;;=execute statement at HL
            ;elige comando de basic con este parametro en HL
;; command RUN
;RUN <filename>
;Loads and runs a file

;RUN [<line number>]
;Runs the current program from the specified line number

ret ;VUELVE A &DE60 ;direccion de basic ;;=execute statement at HL
    ;SE EJECUTARA UN PROGRAMA DE BASIC NORMAL Y CORRIENTE EN &0170 QUE EFECTUARA LA LECTURA DE ARCHIVOS DEL JUEGO
    ;CON LOADS NORMALES.
    ;Al final del programa basic, se hara un CALL 38403 (CALL &9603), RUTINA PARA PROTECCION ANTICOPIA WEAKSECTORS

.l0103
.CMDtablaRSX
db &84 ;comando READ SECTOR en la tabla de RSX (&04+&80)
db &87 ;comando MOVE TRACK en la tabla de RSX (&07+&80)
.l0105
.guarda_dirCMD
db &00
db &00
.NromAMSDOS
db &07

ds 103,&00 ;define espacio vacio para alinear a &0170 el codigo de basic a alinear.

.l016f
nop

;---------- CODIGO DECODIFICADO---------
.L0170 ;zona codificada, ejecuta codigo leido del track 40 para decodificar esta zona
;zona decodificada &0170-&028B, es codigo BASIC tal cual, lo acabara llamando desde el loader principal
;PONGO EL CODIGO BASIC

;NOTA solapan las lineas de basic, con lo cual en el listado de basic sale
;10 MEMORY &13FF
;80 DATA 0,24,6,2

;CODIGO REAL BASIC
;10 MEMORY &13FF 
;6 CALL &BB48 ;DESHABILITA QUE SE PUEDA PULSAR ESCAPE
;10 MODE 1 ; BORDER 0 ;FOR x=0 TO 3 ; READ a ; INK x,a ; NEXT x
    ; LOAD "res",20000 ; LOAD"wolf.scr",&6000 ; CALL 10000 OPENOUT"d" ;MEMORY 999 ; LOAD "fld.bin",&3E8
    ;LOAD "were.bin",&5172 ; FOR x=0 TO 15 ; INK x,0 ; NEXT x ; MODE 0 ; LOAD "spr.bin",&C000 
;80 DATA 0,24,6,2 
;80 OUT &BC00,1 ; OUT &BD00,32 ; OUT &BC00,2 ; OUT &BD00,42 ; OUT &BC00,6 ; OUT &BD00,24 ; CALL 38403 

;CODIGO DECODIFICADO, REALMENTE ES EL PROGRAMA EN BASIC TOKENIZADO.
;A BASIC program is stored in a tokenised format. 
;Here the keywords are represented by 1 or 2 byte unique sequences.
;Each line of the BASIC program has the form
;Offset	Size 	Description
;  0 	 2 	Length of line data in bytes (note 1)
;  2 	 2 	16-bit decimal integer line number (note 2)
;  4 	 n 	BASIC line encoded into tokens (note 3)
; n+1 	 1 	"0" the end of line marker (note 4) 

;Notes

;1-This 16-bit value has two functions, if "0" it signals the end of the BASIC program. In this case,
;  there is no furthur BASIC program lines or data, otherwise, this value defines the length of the 
;  tokenised BASIC program line in bytes, and includes the 2 bytes defining this value, the 2 bytes defining 
;  the program line number, and the end of line marker. This number is stored in little endian notation
;  with low byte followed by high byte.

;2-This 16-bit value defines the line number and exists if the length of line data in bytes is not "0". 
;  A line number is a integer number in the range 1-65535. This number is stored in little endian notation
;  with low byte followed by high byte.

;3-This data defines the tokenised BASIC program line and exists if the length of line data in bytes is not "0".
;  The length is dependant on the BASIC program line contents.

;4-This value defines the end of the tokenised BASIC line data and exists if the length of line data
;  in bytes is not "0". The BASIC interpreter looks for this token during the processing of this line,
; and if found, will stop execution and continue to the next line.

.linea10
db #c9,#00,#0a,#00,#aa,#20,#1c,#ff,#13,#20,#00 ;linea 10
.linea6
db #0a,#00,#06,#00,#83,#20,#1c,#48,#bb,#00 ;linea 6
.linea10_2
db #b4,#00,#0a,#00,#ad,#20,#0f,#01,#82,#20,#0e
db #01,#9e,#20,#0d,#00,#00,#f8,#ef
db #0e,#20,#ec,#20,#11,#01,#c3,#20
db #0d,#00,#00,#e1,#01,#a2,#20,#0d
db #00,#00,#f8,#2c,#0d,#00,#00,#e1
db #01,#b0,#20,#0d,#00,#00,#f8,#01
db #a8,#20,#22,#72,#65,#73,#22,#2c
db #1a,#20,#4e,#01,#a8,#22,#77,#6f
db #6c,#66,#2e,#73,#63,#72,#22,#2c
db #1c,#00,#60,#01,#83,#20,#1a,#10
db #27,#01,#b7,#22,#64,#22,#01,#aa
db #20,#1a,#e7,#03,#01,#a8,#20,#22
db #66,#6c,#64,#2e,#62,#69,#6e,#22
db #2c,#1c,#e8,#03,#01,#a8,#20,#22
db #77,#65,#72,#65,#2e,#62,#69,#6e
db #22,#2c,#1c,#72,#51,#01,#9e,#20
db #0d,#00,#00,#f8,#ef,#0e,#20,#ec
db #20,#19,#0f,#01,#a2,#20,#0d,#00
db #00,#f8,#2c,#0e,#01,#b0,#20,#0d
db #00,#00,#f8,#01,#ad,#20,#0e,#01
db #a8,#20,#22,#73,#70,#72,#2e,#62
db #69,#6e,#22,#2c,#1c,#00,#c0,#20
db #00
.linea80
db #51,#00,#50,#00,#8c,#20,#30
db #2c,#32,#34,#2c,#36,#2c,#32,#20
db #00
.linea80_2
db #41,#00,#50,#00,#b9,#20,#1c
db #00,#bc,#2c,#0f,#01,#b9,#20,#1c
db #00,#bd,#2c,#19,#20,#01,#b9,#20
db #1c,#00,#bc,#2c,#10,#01,#b9,#20
db #1c,#00,#bd,#2c,#19,#2a,#01,#b9
db #20,#1c,#00,#bc,#2c,#14,#01,#b9
db #20,#1c,#00,#bd,#2c,#19,#18,#01
db #83,#20,#1f,#00,#00,#03,#16,#90
db #20,#00
;sobrantes?
db #00,#00

;----------FIN CODIGO DECODIFICADO---------

;--------------FIN LOADER PRINCIPAL-------------------------------

;----CODIGO LEIDO DESDE EL TRACK 40 SECTOR &6D PROTECCION ANTICOPIA----------
;se usa para desencriptar el loader principal
org #a9b0
.codigo_proteccion
ld hl,(#a76d) ;length of file in bytes (&0000 for ASCII files)
              ;hl=&024C lee lo que ocupa fichero de carga as.bin, se escribio en esta direccion al hacer run"as.bin"
ld bc,#0130 ;tamano a decodificar en loader principal
            ;rango &0170-&028B
xor a ;quita flag de carry para que no influya en sbc
sbc hl,bc ;&024C-&0130=&011C
ld c,l
ld b,h ;bc=&011C
ld hl,#0170 ;direccion del loader principal
ld d,#ac ;clave para el xor que hace mas abajo
.la9c0
.bucle_decod
ld a,d ;para realizar el xor aqui abajo
xor (hl) ;&AC XOR &3D =&91
ld (hl),a ;guarda el resultado del xor en la misma direccion de memoria
rrc (hl) ;desplaza los bits de (hl) a la derecha, el bit 0 pasa a carry y a bit 7
         ;&3D-->&C8, carry = 1
inc (hl) ;(hl)=&C9
inc hl ;hl=&0171
dec bc
ld a,c
or b ;comprueba que bc no llegue a 0
jr nz,bucle_decod ;si no llega sigue decodificando.
;decodifica &0170-&028B
ret ;vuelve a loader principal que llamo a decodificar

.LA9CD
;datos/instrucciones usadas? basura?
;no aparentan usarse
db #3a,#00,#00,#00,#00,#00,#00,#00
db #00,#00,#00,#00,#00,#00,#00,#00
db #00,#00,#00,#00,#00,#00,#00,#00
db #00,#00,#00,#00,#00,#00,#00,#00
db #00,#00,#00,#e5,#00,#00,#6b,#04
db #20,#19,#82,#2c,#22,#43,#41,#54
db #22,#f4,#ff,#03,#28,#19,#0d,#29
db #01,#c5,#20,#46,#32,#00,#1c,#00
db #3c,#00,#a4,#20,#19,#84,#2c,#22
db #7c,#43,#50,#4d,#22,#f4,#ff,#03
db #28,#19,#0d,#29,#01,#c5,#20,#46
db #34,#00,#25,#00,#46,#00,#a4,#20
db #19,#87,#2c,#1b,#00,#0a,#00,#a4
db #20,#19,#80,#2c,#22,#43,#4c,#53
db #22,#f4,#ff,#03,#28,#19,#0d,#29
db #01,#c5,#20,#46,#30,#00,#1d,#00
db #14,#00,#a4,#20,#19,#81,#2c,#22
db #7c,#54,#41,#50,#45,#22,#f4,#ff
db #03,#28,#19,#0d,#29,#01,#c5,#20
db #46,#31,#00,#1d,#00,#1e,#00,#a4
db #20,#19,#83,#2c,#22,#7c,#44,#49
db #53,#43,#22,#f4,#ff,#03,#28,#19
db #0d,#29,#01,#c5,#20,#46,#33,#00
db #26,#00,#28,#00,#a4,#20,#19,#8a
db #2c,#22,#43,#4c,#53,#3a,#4c,#49
db #53,#54,#22,#f4,#ff,#03,#28,#19
db #0d,#29,#01,#c5,#20,#46,#2e,#20
db #20,#20,#20,#20,#20,#00,#1b,#00
db #32,#00,#a4,#20,#19,#82,#2c,#22
db #43,#41,#54,#22,#f4,#ff,#03,#28
db #19,#0d,#29,#01,#c5,#20,#46,#32
db #00,#1c,#00,#3c,#00,#a4,#20,#19
db #84,#2c,#22,#7c,#43,#50,#4d,#22
db #f4,#ff,#03,#28,#19,#0d,#29,#01
db #c5,#20,#46,#34,#00,#25,#00,#46
db #00,#a4,#20,#19,#87,#2c,#22,#73
db #70,#65,#65,#64,#20,#77,#72,#69
db #74,#65,#20,#31,#22,#f4,#ff,#03
db #28,#19,#0d,#29,#01,#c5,#20,#66
db #37,#00,#06,#00,#50,#00,#b1,#00
db #06,#00,#5a,#00,#98,#00,#00,#00
db #1a,#03,#28,#19,#0d,#29,#01,#c5
db #20,#46,#2e,#00,#06,#00,#32,#00
db #98,#00,#00,#00,#1a,#27,#00,#00
db #00,#1a,#a4

;----FIN CODIGO LEIDO DESDE EL TRACK 40 SECTOR &6D-----------------------------


;------------DOCUMENTACION DE LA PROTECCION ANTICOPIA WEAKSECTORS UNA VEZ CARGADO EL JUEGO------------------------
;SE LLAMA DESDE EL PROGRAMA DE BASIC EJECUTADO AL FINAL LA CARGA DE TODOS LOS FICHEROS DEL JUEGO
;EN VERSION CINTA SE CARGA EL PROGRAMA PRINCIPAL HASTA &9602, SE PUEDE SUPONER QUE TODO EL CODIGO DE AQUI EN ADELANTE
;ESTA RELACIONADO CON LA PROTECCION ANTICOPIA DE LA VERSION DISCO.
;comparando la version cinta rango &03E8-&9602 con la de disco, son exactamente iguales.
;Con lo cual, esta parte &9603-&9AE4 (que pertenece al fichero "were.bin" del disco original)
;se agrego para la parte anticopia de la version disco
;solo se usa la zona &9603-&96A8, lo demas parece basurilla no utilizada.
org #9603

call bucle_lee_weaksector ;efectuara 3 lecturas al track 40 sector &C6 (weak sector)
           ;las 2 primeras lecturas devuelven los mismos datos, la tercera NO.
           ;mismo track, mismo sector, NO devolviendo los mismos datos, apasionante el FDC del CPC.


;----------NOTAS DE roudoudou EN CPCWIKI SOBRE LOS WEAKSECTORS---------------
;there is different weak sectors, but the thing is there is at least one weak bit
;there is a transition at detection limit so sometimes the FDC see a 1, sometimes a 0 and everything can change after that
;regarding the control routine, only one difference is ok
;but there is games (passager du temps AFAIK) which require 3 differents reads on 10
;just remember DSK are not masters, only a dedicated format to run on emulators
;-------------------------------------------------------------------------------

;por aqui ha validado la proteccion anticopia, si no efectuara un call &0000 dentro de la anterior funcion.
;procede a desencriptar el fichero were.bin rango &5172-&9603
;lo que significa que el rango &9604-&9AE4 pertenece exclusivamente a la proteccion anticopia.
;se comprueba comparando el juego con la version cinta, donde no existen los dados de &9603-&9AE4

ld hl,#5171
ld bc,#4492 ;tamano de datos a desencriptar 17.554 bytes

.bucle_desencriptado ;bucle de desencriptado de los datos fichero "were.bin" en &5172-&9AE4
.l960c 
inc hl ;direccion inicial del fichero "were.bin" &5172-&9AE4
ld a,(hl)
xor #32 ;clave desencriptado
ld (hl),a ;desencripta
.l9611
ld a,#00
dec bc
cp b
jr nz,bucle_desencriptado ;l960c
cp c
jr nz,bucle_desencriptado ;l960c

;desencriptado terminado, ejecuta el juego.
.l961c equ $ + 2
jp #5172 ;Ejecuta el juego, direccion igual que la version cinta.



.bucle_lee_weaksector
.l961d ;esta zona sera borrada al validar proteccion anticopia

ld hl,#be78
ld (hl),#ff ;desactiva que muestre errores de lectura de disco en caso de que existieran
ld hl,#be66
ld (hl),#02 ;establece el numero de intentos de lectura en caso de que hubiera errores

.l9627
.bucle_readtrack40
;primera lectura a track 40 sector &C6 (weak sector)
;segunda lectura a track 40 sector &C6 (weak sector) MISMA LECTURA que primera
;tercera lectura a track 40 sector &C6 (weak sector) NO DEVUELVE LOS MISMOS DATOS EN TERCERA LECTURA.

ld hl,CMDREADSECTOR ;l9644 ;direccion de memoria con comando a buscar en roms
            ;&84 ;comando READ SECTOR en la tabla de RSX (&04+&80)
call #bcd4 ;KL FIND COMMAND
;comando encontrado carry=true
;reg c trae numero de ROM que tiene el comando; c=&07 (rom de amsdos)
;reg hl trae direccion del comando; hl=&C03C ;BIOS & CP/M 2.1 EXTENDED JUMPBLOCK READ SECTOR

ld (guardaDIRCMD),hl
ld a,c
ld (ROM_CMD),a ;guarda en que ROM se encontro comando (7-AMSDOS)
ld hl,READSECTOR_PARAMETROS ;l9648
ld e,(hl) ;disquetera a usar
inc hl
ld d,(hl) ;track
inc hl
ld c,(hl) ;sector ID
ld hl,#a9b0 ;buffer donde leera los datos
rst #18
db &45 
db &96 ;&9645, direccion de memoria donde estan los parametros para FAR CALL &18
       ;3 bytes, los 2 primeros direccion del comando de amsdos buscados, el tercero numero rom de AMSDOS
       ;guarda_dirCMD, direccion donde guardo a donde apunta READ SECTOR en rom de AMSDOS
       ;NromAMSDOS=&07

;efectua salto a READ SECTOR de AMSDOS
;;==================================================================
;; BIOS: READ SECTOR
;;
;; HL = buffer
;; E = drive
;; D = track
;; C = sector id
;;
;; NOTES:
;; - H parameter is forced to 0
;; - N parameter comes from XDPB
;; - R parameter defined by user
;; - only 1 sector read at a time
;; - C parameter defined by user (must be valid track number)
;; - double density only
;; - "read data" only + skip

;PARAMETROS ENVIADOS
;REG HL=&A9B0 BUFFER
;REG E=&00 DRIVE A
;REG D TRACK= &28 (TRACK 40)
;REG C SECTOR ID = &C6

;lee del track 40 sector &C6 (weak sector)
;escribe esos datos en &A9B0-&ABAF =&200 (512 bytes leidos)
;el rango &A9B0-&AA13 se llena con &E5 (marca de no datos en esa zona)
;el rango &AA14-&ABAF se llena con datos leidos de disco

;vuelve por aqui despues de ejecutar la lectura del track 40 sector &C6

jr l9655

.l9644
.CMDREADSECTOR
db &84 ;comando READ SECTOR en la tabla de RSX (&04+&80)
.l9645
.guardaDIRCMD
db &00
db &00
.l9647
.ROM_CMD
db &07
.l9648
.READSECTOR_PARAMETROS
db &00 ;disquetera
db &28 ;track
db &C6 ;sector ID
db &4D
db &96

.l964d ;mueve 2 bytes de zona leida de track 40 sector &C6 primera lectura
db &00
.l964e
db &00

.L964F ;mueve 2 bytes de zona leida de track 40 sector &C6 segunda lectura
db &00
db &00
.L9651 ;mueve 2 bytes de zona leida de track 40 sector &C6 tercera lectura [NO LEE LOS MISMOS DATOS]
db &00
db &00
.l9653
.punterozonatrack40
db &4D
db &96

.l9655
ld de,(l9653) ;de=&964D primer bucle
              ;de=&964F segundo bucle
ld hl,#aa19
ld bc,#0002
ldir ;mueve 2 bytes de &AA19 y AA1A (zona leida de track 40)
     ;primer bucle
     ;&964D=&2E
     ;&964E=&63
     ;segundo bucle
     ;&964F=&2E
     ;&9650=&63
     ;tercer bucle
     ;&9651=&84
     ;&9652=&86

ld hl,l9653
ld a,l ;a=&53
cp e ;&53 comparado con &4F (reg de incrementado con el ldir)
     ;dara Z cuando puntero de, reg e=&53, pasara al acabar la tercera lectura del track 40
jr z,lecturas_finalizadastTRK40 ;l966e ;primera comparacion no da Z
           ;si se obliga el salto con la primera comparacion a &966e, se ejecuta el juego normalmente.
           ;es de suponer que se inducen 3 lecturas al track 40 por sobreasegurar que es el disco original.
;por aqui en primera comparacion
ld (l9653),de ;de=&964F
              ;de=&9651 segundas

jr bucle_readtrack40 ;l9627

.lecturas_finalizadastTRK40 ;l966e ;lectura de los 3 sectores de track 40 correcta
       ;REPITO, las 2 primeras lecturas al MISMO track y sector NO son las mismas que en la tercera lectura
       ;siendo igual el mismo track y sector.
ld b,#00 ;bucle para mover puntero de los datos extraidos de las lecturas
ld hl,l964d ;primera lectura del track 40 sector &C6

.bucle_cmp_readstrk40 ;l9673 ;bucle de lectura datos extraidos de track 40 sector &C6
ld a,(hl) ;a=&2E
          ;a=&2E de segundas
inc hl 
inc hl ;hl=&964F (segunda lectura del track 40 sector &C6)
       ;hl=&9651 (tercera lectura del track 40 sector &C6) DIFIERE EN DATOS
cp (hl) ;(hl)=&2E
        ;(hl)=&84, no coincide debido a esos datos diferentes leidos
jr nz,datos_diferentesTRK40 ;l9691

;por aqui solo pasara si los datos leidos en track40 son iguales en diferentes lecturas
;es decir, no esta validando el weaksector
inc b
ld a,#02
cp b
jr nz,bucle_cmp_readstrk40 ;l9673 ;compara las 3 lecturas al track40

;por aqui no pasa jamas con el werewolves ya que se cumple el NZ de datos_diferentesTRK40
;SE PASARIA POR AQUI SI NO HUBIERA UN WEAK SECTOR EN TRACK 40 SECTOR &C6
;es decir NO es el disco original.

ld a,(l961c) 
cp #00 ;COMPARA INSTRUCCION JP &5172 (EL &51) CON &00, COSA QUE NO DEBERIA PASAR NUNCA
       ;tecnicamente esa direccion solo estaria a &00 si fuerzo aqui abajo la entrada con un Z y no un NZ
jr nz,RESETEA_CPC ;l96a6 resetea el cpc ya que no se ha encontrado WEAK SECTOR

;por aqui no pasara nunca, al comparar con &00 una direccion que contendra siempre &51, se reseteara el cpc.
;si fuerzo al programa a pasar por aqui (solo por testear)
ld hl,l961c ;carga direccion del JP &5172
ld (hl),b ;mete un &02 en esa direccion, quedando la instruccion LD (BC),A
          ;es decir, se carga directamente el salto a la ejecucion del juego.
          ;aunque a estas alturas nunca llegara a ese punto del programa para ejecutar el juego.
ld b,#00
ld hl,l964e
jr bucle_cmp_readstrk40 ;l9673

.datos_diferentesTRK40 ;salta al no coincidir datos de primera/segunda lectura con la tercera lectura al track 40 sector &C6
.l9691 ;ES DECIR SE HA VALIDADO QUE EL TRACK 40 SECTOR &C6 ES UN WEAKSECTOR.
ld hl,#be78
ld (hl),#00 ;disc error messages ON
ld hl,#be66
ld (hl),#0a ;numero de reintentos de lecturas si falla.

ld b,#8a
ld hl,l961c ;direccion de memoria que guarda el jp &5172 (direccion de ejecucion real del juego) ultimo byte
.l96a0
inc hl ;se situa en &961D, borrara los datos de este loader &961D-&96A0 seran borrados
ld (hl),#00
djnz l96a0
ret ;vuelve a rutina que llamo a esta funcion de varias lecturas a track40 sector &C6

.RESETEA_CPC
.l96a6
call #0000
;por aqui no pasara ya, se ha reseteado el cpc.
;esta zona posterior &96A9-&9AE4, que parecen datos random, no se usa y no existe en la version cinta.
;la borro porque no es necesario ni para el loader ni para la ejecucion del juego.
