
;Loader original Stainless Steel version CPM disco

org #0100 ;origen del loader
    	  ;todos los loaders que cargan con CPM se inician en esta direccion.
          ;el loader de Stainless ocupa desde &0100 a &0287 (188 bytes)
          ;la carga de los loaders de CPM implican 512bytes con lo cual desde el byte
          ;&288 al byte &2FF se rellena en el caso del loader del stainless con el valor &1A.

.l0100
ld hl,l0100
ld de,#9800
ld bc,&0188
ldir ;mueve todo el loader a &9800-&9987
jp #980e ;salta a la parte del loader correspondiente en la nueva direccion de memo.
         ;saltaria justo debajo de este codigo anterior, que mueve sin tener por que

;Coloco aqui lo que seria el codigo ya movido para que coincidan las etiquetas.
org #980e

;configura el CRTC para la resolucion usada en el Stainless, 256x168
ld bc,#bc0d
out (c),c ;selecciona registro 13 del CRTC, start addres low
ld bc,#bd00
out (c),c
.l9819 equ $ + 1
ld bc,#bc0c 
out (c),c ;selecciona registro 12 del CRTC, start addres high
ld bc,#bd30
out (c),c
;valores registros 12 y 13 son lo standard en cpc, memoria de video en &c000
ld bc,#bc01 
out (c),c ;registro 1 CRTC, horizontal displayed
ld bc,#bd20 ;valor resolucion  256 pixels en modo 1 (32*8)
out (c),c
ld bc,#bc06 ;registro 6 CRTC, vertical displayed
out (c),c
ld bc,#bd15 ;168 lineas (21*8)
out (c),c
;resolucion seteada 256x168

ld bc,#bc02
out (c),c ;registro 2 CRTC Horizontal Sync Pos
ld bc,#bd2b
out (c),c ;ajusta crtc par centrar a la nueva resolucion

ld hl,colorinchos ;puntero a colores para setear INK's
xor a ;Numero de tinta a cambiarle color en rutina &BE09

.pon_tintas
ld c,(hl)
ld b,c
push hl ;guarda puntero a colores
push af ;guarda valor numero de tinta
call #be9b ;esta direccion de memoria se inicializo al activar CPM con comando |CPM
           ;Se inicializo desde AMSDOS -> start of CP/M 2.1 extended jumpblock
           ;en &be9b se salta a AMDOS direccion &C168 ;; CP/M 2.1 EXTENDED JUMPBLOCK ENTER FIRMWARE
           ;Una vez inicializado el Jumpblock de CPM ejecutara rutina de firmware &BC32 para setear las tintas.
           ;esta llamada a &BC32 se realiza leyendo los 2 bytes posteriores a este call &BE9B
           ;se incrementara el valor de la llamada en el stack pointer para saltarse los valores de rutina a llamar (&BC32)
           ;volvera por &984D
           ;NOTA, todas las llamadas que se realicen a &BE9B actuan de la misma manera, se explica aqui solamente.

.l984B ;bytes &32,&BC ;de=&BC32 en rutina AMSDOS de &C14F
 db &32 ;parametro
.l984C
 db &BC ;parametro &BC32, llamada a firmware SCR SET INK

.l984D ;vuelve por aqui una vez seteada una tinta con el color leido en BC anteriormente
pop af ;recupera numero de tinta
pop hl ;recupera puntero de color a poner
inc hl ;incrementa puntero
inc a ;incrementa tinta a poner
cp #04 ;fin de tintas mode 1?
jr nz,pon_tintas

;por aqui ha puesto las tintas
;hace el mismo sistema para cambiar el borde
ld bc,#0000 ;color de borde
call #be9b ;recuerda que vuelve 2 bytes mas abajo
.l985B
 db &38
.l985C
 db &BC ;&bc38 firmware SCR SET BORDER

.l985D ;vuelve por aqui

ld a,#01 ;MODO a poner, MODE 1
call #be9b ;pone mode 1.
.l9862
 db &0e ;SCR SET MODE
.l9863
 db &bc ;SCR SET MODE

.l9864 ;viene por aqui despues del call anterior
ld e,#00 ;DRIVE a usar para llamada AMSDOS BIOS READ SECTOR
ld a,e ;REG a tiene numero de sector de track a leer, el primero sera el 00 de 9 en total
ld (sector_a_leer),a ;VARIABLE sector
ld c,e ;SECTOR ID a usar para llamada AMSDOS BIOS READ SECTOR
ld d,#09 ;TRACK a usar para llamada AMSDOS BIOS READ SECTOR
ld b,#1f ;numero de sectores a leer (para el djnz)
ld hl,#c000 ;Direccion de memoria donde se escribiran datos leidos de disco
call BIOS_READ_SECTOR ;nota, pantalla de carga en track 9 sector 00

;ha metido la pantalla de carga en memoria de video y datos del juego en memoria oculta de pantalla.
;&C000-&FDFF (&3E00, 15.872bytes), &1f (31) sectores a leer x 512 bytes por sector= 15.872bytes)

ld e,#00
ld a,e
ld (sector_a_leer),a ;reinicia sector a leer
ld c,e ;SECTOR ID a usar para llamada AMSDOS BIOS READ SECTOR
ld d,#01 ;TRACK a usar para llamada AMSDOS BIOS READ SECTOR
ld b,#48 ;numero de sectores a leer (para el djnz)
ld hl,#0100 ;direccion de memoria donde escribir datos a leer
call BIOS_READ_SECTOR ;efectua la lectura requerida
;36.864 bytes leidos
;escribe esos datos en &0100-&90FF

di

;guarda registros ix e iy, presupongo que son necesarios sus valores para CPM
push ix ;ix=&BFFE
push iy ;iy=&AC48
call #8000 ;llama a su propio codigo para reproducir la musica y esperar a que se pulse una tecla.
           ;NOTA, NO LEE NI ESCRIBE NADA EN LAS ZONAS OCULTAS EN PANTALLA.
pop iy ;recupera valores guardados de IX e IY, supongo necesarios para CPM
pop ix

ei ;activa ints, OJO LAS INTS APUNTAN A JP &C163 ya que lo cambia el |CPM segun lee de disco!!
   ;no deberia influir en nuestro futuro cargador para M4, solo tener en cuenta esto.

xor a ;Numero de tinta a cambiarle color en &BE09

.tintas_a_negro ;bucle tintas a negro
ld bc,#0000 ;aqui no usa puntero, ya que pondra todo a color negro
push af
call #be9b
.l989B ;ld (#f1bc),a ;bytes &32,&BC,&F1 ;de=&BC32 en rutina AMSDOS de &C14F
 db &32 ;parametro
.l989C
 db &BC ;parametro &BC32 SCR SET INK

.l989D ;vuelve por aqui una vez seteada una tinta con el color leido en BC anteriormente
pop af ;recupera color de tinta
inc a ;siguiente tinta
cp #04
jr nz,tintas_a_negro

;por aqui puestas tintas a 0, negro.
;OJO el firmware no ha hecho caso a este cambio de tintas ya que, las ints no apuntan al firmware
;si no a la BIOS de CPM!!

;ahora setea AY para que no siga sonando ni haga ruido mientras se cargan las ultimas partes del juego.

ld a,#07 ;registro AY a escribir, reg 7= Mixer Control Register
ld c,#b1 ;dato a escribir ;%1011 0001
         ;Channel A tone OFF
         ;Channel B tone ON
         ;Channel C tone ON
         ;Channel A noise ON
         ;Channel B noise OFF
         ;Channel C noise OFF
         ;BIT 6 debe ser siempre 0 en CPC
         ;BIT 7 NO SE USA EN CPC, supongo es indiferente que se mande en este bit.

call Escribe_regAY_dato

ld bc,#0300
.bucle_AY
inc a
call Escribe_regAY_dato
djnz bucle_AY
;Registro 8 AY =00 Channel A Volume
;Registro 9 AY =00 Channel B Volume
;registro 10 AY=00 Channel C Volume

;ahora realizara varias lecturas desde disco a memoria de pantalla
;ya he explicado como funciona, no comento esta parte.
ld e,#00
ld a,e
ld (sector_a_leer),a
ld c,e
ld d,#0d
ld hl,#c000
ld b,#02
call BIOS_READ_SECTOR

ld hl,#c800
ld b,#02
call BIOS_READ_SECTOR

ld hl,#d000
ld b,#02
call BIOS_READ_SECTOR

ld hl,#d800
ld b,#02
call BIOS_READ_SECTOR

ld hl,#e000
ld b,#02
call BIOS_READ_SECTOR

ld hl,#e800
ld b,#02
call BIOS_READ_SECTOR

di
ld sp,#0100 ;coloca Stack debajo del codigo del juego.

xor a
ld bc,#fa7e ;apaga motor de disquetera. Me pregunto si realmente hace falta, el propio CPM deberia hacerlo?
out (c),a

ld bc,#7f8d ;Mode 1, lower & upper disabled
out (c),c

;ahora movera esto ultimo leido de disco a las zonas de RAM adecuadas.
ld hl,#c000
ld de,#9540
ld bc,#02c0
ldir

ld hl,#c800
ld de,#9d40
ld bc,#02c0
ldir

ld hl,#d000
ld de,#a540
ld bc,#02c0
ldir

ld hl,#d800
ld de,#ad40
ld bc,#02c0
ldir

ld hl,#e000
ld de,#b540
ld bc,#02c0
ldir

ld hl,#e800
ld de,#bd40
ld bc,#02c0
ldir

jp #0100 ;salta y ejecuta el juego.
;--------FIN MAIN-------------------

.BIOS_READ_SECTOR

push hl ;guarda direccion donde se meteran los datos

;lee 1 sector de cada vez que se llama aqui abajo
;cada sector son 512bytes
call #be89 ;zona inicializada al usar comando |CPM
           ;alli realiza un jp &C666 , comando AMSDOS  BIOS READ SECTOR
           ;; HL = buffer
           ;; E = drive
           ;; D = track
           ;; C = sector id

pop hl ;recupera direccion donde se metieron los datos

jr nc,BIOS_READ_SECTOR ;Carry se activa si se ha leido bien el sector
                       ;si no es asi este JR vuelve a intentar la lectura.

;por aqui se ha leido bien el sector requerido
inc h
inc h ;incrementa puntero de escritura en RAM para lectura de siguiente sector
ld a,c
add #c9 ;siguiente sector ID de track 9 a leer
ld c,a
ld a,(sector_a_leer)
inc a
cp #09 ;mira si se han leido todos los sectores del track actual
jr nz,no_saltes_track
;por aqui salta a siguiente track a leer, ya que se leyo el anterior entero.
inc d ;incrementa track
xor a ;vuelve a poner a 0 numero de sector a leer
ld c,a ;mete parametro sector en parametro BIOS READ SECTOR

.no_saltes_track
ld (sector_a_leer),a ;guarda sector actual a leer
djnz BIOS_READ_SECTOR ;efectua tantas lecturas como se le ha indicado en parametro reg b que llamo a esta funcion.

;por aqui leyo toda la informacion que pidio en la llamada a esta rutina
ret ;vuelve a rutina que pidio las lecturas a disco.
;---------FIN RUTINA BIOS_READ_SECTOR-------------------------

;--DATOS NO USADOS, NI EN LOADER NI EN JUEGO----
ccf ;datos no usados?
ret nz ;datos no usados?
rlca ;datos no usados?
;--FIN DATOS NO USADOS, NI EN LOADER NI EN JUEGO----


.sector_a_leer
nop
;.l9962
.colorinchos
db &00
db &06
db &14
db &19

;.l9966
.Escribe_regAY_dato
;parametros
;reg a, registro de AY a leer/escribir
;reg c, parametro a mandarle a registro ay seleccionado
push bc
push af
ld b,#f4 ;PPI Port A [selecciona un registro del AY para leerlo o escribirlo]
out (c),a ;mete en PPI el registro 7 del AY, mixer control register
          ;PERO NO LO SELECCIONA AUN.
ld b,#f6 ;LEE ESTADO DEL PPI PUERTO C
in a,(c)
or #c0 ;ACTIVA BIT 7 Y BIT 6 PSG function selection --> Select PSG register
out (c),a ;AHORA si SELECCIONA registro AY mediante puerto C del PPI.
and #3f ;pone a 0 bit 7 y bit 6
out (c),a ;pone al AY en inactive mode

ld b,#f4  ; setup register data on PPI port A
out (c),c ;coloca dato a mandar a AY en PPI port A

ld b,#f6
ld c,a
or #80 ;%1000 0000 Write to selected PSG register
out (c),a

out (c),c ;pone al AY en inactive mode

pop af ;saca de la pila registros guardados anteriormente
pop bc
ret

;---------------FIN LOADER----------------------------------------------------------