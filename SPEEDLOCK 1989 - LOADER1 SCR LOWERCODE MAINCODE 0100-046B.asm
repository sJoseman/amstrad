;LOADER1 TERMINATOR 2
;JOSEMAN 2024
;ATENCION
;loader0 en &AA00 --> punto de entrada a rutina en &AA1A seria el loader real de carga de datos
;loader1 en &0100 --> punto de entrada a rutina en &3000 (hace ldir a &3000), mismo loader real de carga de datos.
;loader2 en &0040 --> punto de entrada a rutina en &0040 mismo loader que los anteriores.
;LOADER0 (A PARTIR DE &AA00) LOADER 1 Y LOADER 2 SON EXACTENTE IGUALES, SOLO QUE RELOCALIZADOS.
;CUALQUIER DUDA LEER LA DOCUMENTACION EN LOADER0 MEJOR.
;LOADER1 Y LOADER2 TIENEN COMENTARIOS QUE PUEDEN SER ERRONEOS YA QUE LA LIMPIEZA DE DOCUMENTACION Y AFINE LO HICE EN LOADER0

;CODIGO CARGADO EN &0100 POR RUTINA &AA1A de loader principal

;la rutina &AA1A
;lee un fichero de texto con nombres de fase, lo compara con &AA15, texto "BOOT"
;coincide, con lo cual lee en &AC4A  un fichero de datos que usara para calcular
;datos a leer desde disco y track/sector donde leerlos

;Datos leidos desde disco &0100-&046B
;si los datos se han leido bien, Carry esta activado y efectua un jp &0100, a este codigo.

org #0100
di ;ya vienen desactivadas
ld hl,l01a3
ld de,#3000 ;destino de parte de estos datos cargados
ld bc,&02c9 ;bytes a mover
.l010b equ $ + 1
ldir ;MUEVE &01A3-&046B
     ;A &3000-&32C8 CORROBORADO
ld sp,#0030 ;cambia posicion stack
call pon_tintas_negro ;ya estaban a negro por loader anterior ;l0161

exx
ld bc,#7f8c ;mode 0, lower & upper disabled
out (c),c
exx ;guarda en espejo
    ;hl'=&AC4B (puntero posicionado en datos de tamano a leer desde disco, track y sector
    ;de'=&0202
    ;bc'=&7F8C
      
.l0119
ld hl,l018c ;tiene texto "TITLE"
ld de,#bff0 ;direccion en RAM PARA CARGAR, EL TAMANO SE DECIDE CONSULTANDO TABLA DE TAMANO DATOS TRACK SECTOR
ld bc,#ffff
call #3000 ;LLAMADA A DONDE MOVIO EL CODIGO CON EL LDIR ANTERIOR.

;POR AQUI HA LEIDO DESDE DISCO Y METIDO EN RAM
;&BFF0-&FFFF, &4010 BYTES, RECUERDA, CALCULADOS CON TABLA. TRACK Y SECTOR DE INICIO TAMBIEN CALCULADO.
;corroborado con winape, es la pantalla de carga, sin codificar ni nada, ademas de esos bytes en &BFF0
;LOS BYTES EN &BFF0 SON LOS DATOS DE COLOR PARA LAS TINTAS!! DATO EN FORMATO FIRMWARE

;es decir, en el caso del T2, no hay que copiar todo, solo &C000-&FFFF
;las tintas ya se pondran en el loader pertinente.

jr nc,l0119 ;no carry error de lectura, vuelve a intentar.

ld hl,#bff0 ;DATOS DE COLORES PARA LAS TINTAS DE LA PANTALLA DE CARGA (EN FORMATO FIRMWARE)
call pon_colorines ;l0146
;LOS PONE DESDE TINTA A 0 A TINTA 16

;por aqui puestos los colores de la pantalla de carga, pantalla en zona de VRAM.

.l012d
ld hl,l0192 ;tiene texto "LOWERCODE"
ld de,l0310 ;direccion de carga en RAM
call #3000 ;tamano de datos a leer calculados consultando tabla

;tamano datos a leer &25F0
;escrito en RAM &0310-&28FF ;CORROBORADO
;ojo en &2568 esta el loader de fases
;que movera a &0040
;ES EL MISMO LOADER QUE MOVIO AQUI A &3000
;MUEVE DESDE &2568-&2837 A &0040-&030F ;SIGO EN OTRO TXT COMENTANDO.

jr nc,l012d

.l0139 equ $ + 1
.l0138
ld hl,l019a ;tiene texto "MAINCODE"
ld de,#8000 ;direccion de carga en RAM
call #3000 ;tamano de datos a leer calculados consultando tabla
jr nc,l0138

;tamano datos a leer &4000
;escrito en RAM &8000-&BFFF ;CORROBORADO

;destacar que ha sobreescrito main loader situado en &AA00


jp #8003 ;SALTA A MAINCODE
         ;PERO AUN LEE DESDE DISCO MAS VECES
         ;ojo en &2568 esta el loader de fases (parte del codigo de LOWERCODE)
         ;que movera a &0040 y llamara para cargar fases.
         ;ES EL MISMO LOADER QUE MOVIO AQUI A &3000
         ;LA PRIMERA VEZ SE LLAMA EN &8126 CON TEXTO "FRONTSC"

;ya no volvera por aqui.


.l0146 ;por aqui salta despues de cargar TITLE (PANTALLA DE CARGA)
.pon_colorines
;parametro
;hl=#bff0, title no se carga en &C000, si no que empieza en &BFF0
;esos bytes a mayores son
;#00,#00,#01,#02,#05,#0a,#0b,#0e,#14,#17,#03,#1a,#0f,#18,#19,#06
;LOS BYTES EN &BFF0 SON LOS DATOS DE COLOR PARA LAS TINTAS!!
;ESTAN EN FORMATO FIRMWARE, POR ESO USA AQUI ABAJO UNA TABLA PARA CONVERTIRLOS A GA COLOR
ld bc,#7f00
.l0149
out (c),c
ld a,(hl)
ld de,tabla_conv_colores ;carga puntero de conversion de colores
add e ;mueve puntero de conversion
.l0150
ld e,a
jr nc,l0154 ;si se activa carry con el add e, debe incrementer puntero byte alto
inc d

.l0154
ld a,(de) ;a=&14 de primeras
or #40 ;a=&54 (color negro)
out (c),a ;pone color negro
inc hl
inc c
.l015b
ld a,c
cp #11 ;todos los colores puestos?
jr nz,l0149
;por aqui todos los colores puestos.
ret

.l0161
.pon_tintas_negro
ld bc,#7f00
.l0164
out (c),c
ld a,#54
.l0169 equ $ + 1
out (c),a
inc c
ld a,c
cp #11
.l016f equ $ + 1
jr nz,l0164
ret


.l0171
.tabla_conv_colores
;tabla de conversion de colores a datos de GA (de los 27 colores)
db &14
db &04
db &15
db &1C
.l0175
db &18
db &1D
db &0C
db &05
db &02
db &16
db &06
db &17
.l017e equ $ + 1
db &1E
db &01
db &1F
db &0E
db &07
db &0F
db &12
db &02
.l0185
db &13
db &1A
db &19
db &1B
.l0189
db &0A
db &03
db &0B

;---"NOMBRES" DE ARCHIVO A CARGAR, REALMENTE NO USA NOMBRES, PERO LOS USA PARA CALCULAR DONDE METER LOS DATOS.
.l018c
db &54 ;T
db &49 ;I
db &54 ;T
.l018f
db &4C ;L
.l0190
db &45 ;E
db &00 
.l0192
db &4C ;L
db &4F ;O
.l0194
db &57 ;W
db &43 ;C
db &4F ;O
db &44 ;D
db &45 ;E
db &00 
.l019a
db &4D ;M
db &41 ;A
db &49 ;I
db &4E ;N
db &43 ;C
.l019f
db &4F ;O
db &44 ;D
db &45 ;E
.l01a2
db &00

.l01a3 ;MOVIDO A RANGO &3000-&32C8, TODO HASTA EL FINAL DE ESTE CODIGO.
;CONSERVO LA ETIQUETA
;PERO PONGO AQUI EL CODIGO MOVIDO A &3000
org #3000
.L3000 ;llamado despues de poner tintas a cero
;OJO, EL CODIGO EN ESTA RUTINA CAMBIARA ESTE INICIO POR UN JP &301B QUE SE ACABARA LLAMANDO.
;NOTA, ESTE CODIGO TAMBIEN SE METERA EN &0040 POR RUTINA EN &8000 DEL JUEGO, LO USARA PARA CARGAR FASES.
;parametros
;bc=&FFFF
;de=&BFF0 ;ZONA DE RAM DONDE METERA LOS DATOS
;hl=&018c ;tiene texto "TITLE" de primeras
push bc
push de
push hl
ld a,#c9
ld (#0000),a ;mete ret
call #0000 ;llama a ese ret
;vuelve por aqui, PERO en stack -2 bytes quedo esta llamada y en pilla metio &300B
dec sp
dec sp
pop hl ;hl=&300B, manera sutil, muy sutil de cargar hl con ese valor.
ld bc,#000b
and a  ;desactiva carry
sbc hl,bc ;&300B-&000B ;hl=&3000 (principio de codigo metido en &3000 con ldir)
ld d,h
ld e,l ;de=&3000
ld bc,#0230
add hl,bc ;&3000+&0230=&3230
jp (hl) ;efectua salta a &3230

.L301B ;vendra por aqui despues de efectuar salto anterior, poner direcciones de memoria correctas para el loader
       ;esta claro que este loader es relocalizable a gusto, seguro en otros juegos esta en otro lado.
       ;ESTE ES EL LOADER REAL DE CARGA DE FICHEROS

;parametros
;bc=&FFFF
;de=&BFF0 ;ZONA DE RAM DONDE METERA LOS DATOS
;hl=&018c ;tiene texto "TITLE" de primeras

ld a,i ;a=&00
ex af,af' ;af=&0054 af'=&0040
di ;ya trae las ints desactivadas

exx ;espejo a primarios
push bc ;guarda en pila &7F8C, que parece ser importante para ellos, pero a mi me parecen datos del GA
exx ;recupera primarios

push de ;&BFF0 a pila (parametro para funcion &3000)
push hl ;&018c a pila (parametro para funcion &3000) ;tiene texto "TITLE" de primeras

ld bc,#fa7f
out (c),c ;enciende motor de disquetera

ld bc,#f540 ;reg c valor de bucle perdida de tiempo para rotacion optima
.l302c ;bucle de perdida de tiempo
in a,(c)
rra
jr c,l302c
.l3031
in a,(c)
rra
jr nc,l3031
dec c
jr nz,l302c

;por aqui motor encendido, rotacion optima alcanzada.

ld hl,(&322e) ;hl=&3230, DIRECCION DONDE METER TRACK A LEER
ld de,#0008 ;TRACK Y SECTOR A LEER
call LEE_DATOS_DISCO ;RUTINA SIMILAR A LA DE LOADER PRINCIPAL EN &AB6A ;&3150 

;por aqui acaba de leer en &3230-&342F, 512bytes de datos
;es la misma lista de nombres de fase que ya cargo en loader de &A000
;BOOT, TITLE, LOWCODE, MAINCODEFRONTSC, COMBAT, SCENE1, CHASE, HAND, HANDSC, SCENE2, EYE, EYESC, HELI, SCENE3, ENDSC 

;Carry activado si lectura correcta

pop hl ;hl=&018C ;tiene texto "TITLE" de primeras
jr nc,l3072 ;lectura incorrecta? repite intento de lectura

;por aqui todo bien
call &3075 ;RUTINA IGUAL QUE LA DE &A88F 
;COMPARA EL TEXTO "TITLE" CON LISTADO DE TEXTO CON NOMBRES DE FASE, SI LO ENCUENTRA, TRAERA CARRY ACTIVADO
;tambien devuelve registro BC
;este valor de reg BC ES CLAVE PARA LA RUTINA QUE CALCULA LOS BYTES A LEER DESDE DISCO!!
;Seria como una variable tipo "numero de archivo a cargar"
;bc=&0000 --> fichero "BOOT" a cargar (loader0) ;BOOT es loader1
;bc=&0001 --> fichero "TITLE" a cargar (loader1) ;TITLE es pantalla de presentacion del juego
;bc=&0002 --> fichero "LOWCODE" a cargar (loader1) ;datos juego (contienen loader2)
;bc=&0003 --> fichero "MAINCODE" a cargar (loader1) ;datos juego
;bc=&0004 --> fichero "FRONTSC" a cargar (loader2) MENU pantalla principal con foto del terminator y logo.
;bc=&0005 --> fichero "COMBAT" a cargar (loader2) FASE1 fichero1
;bc=&0006 --> fichero "SCENE1" a cargar (loader2) FASE1 fichero2
;[ETC, ETC, ETC]
jr nc,l306d ;NC significa que no encontro el texto buscado
;por aqui texto encontrado, encuentra "TITLE" ya que esta en el listado cargado.

push bc ;&0001 a stack
ld hl,(&322E) ;hl=&3230 DIRECCION DONDE METER TRACK A LEER
ld de,#000a ;TRACK Y SECTOR A LEER DE DISCO, al sector le llama correctamente en la propia rutina
call LEE_DATOS_DISCO ;&3150
;hace lo mismo que en loader principal, ahora carga un fichero para calcular tamano de datos a leer de disco, track y sector
;este fichero es el mismo que carga en loader principal.
;CALCULARA ESTOS VALORES EN LLAMADA DE AQUI ABAJO A &30B3
pop bc ;bc=&001
pop hl ;hl=&BFF0 direccion de ram donde metera los datos!!
jr nc,l305b ;recuerda no carry es error en lectura de datos requeridos

call &30B3 ;igual que en loader principal
           ;ESTA RUTINA CALCULA BYTES A LEER DE DISCO
           ;Y EFECTUAR ESA LECTURA DE DISCO
           ;POR EJEMPLO DE VUELVE POR AQUI HA LEIDO DATOS Y ESCRITO EN 
           ;&BFF0-&FFFF CORROBORADO. EL TAMANO DE LECTURA LO DECIDE EN UNA RUTINA QUE LEE DATOS DE TAMANO TRACK Y SECTOR
           ;trae hl cargado con siguiente posicion de RAM donde meter datos
           
.l305b
push af
ld bc,#fa7e
out (c),c
pop bc
exx
pop bc
exx
and a
ex af,af'
ld a,c
rra
ld a,b
ret po
ei
ret

.l306d ;TEXTO NO ENCONTRADO
pop hl
ld a,#01
jr l305b
.l3072
pop bc
jr l305b
ld bc,#0000
ld de,(#022e)
.l307c
push bc
push hl
push de
ld b,#08
call #0096
pop hl
rla
ld bc,#0008
add hl,bc
ex de,hl
pop hl
pop bc
rra
ret c
inc c
ld a,c
cp #40
jr nz,l307c
ret
.l3096
ld a,(de)
cp (hl)
jr nz,l30a0
.l309a
inc hl
inc de
djnz l3096
.l309e
scf
ret
.l30a0
cp #41
jr c,l30a9
or #20
cp (hl)
jr z,l309a
.l30a9
cp #20
jr nz,l30b1
ld a,(hl)
or a
jr z,l309e
.l30b1
and a
ret

.L30B3 ;igual que en rutina de mainloader
call &310B ;CALCULA TAMANO DE DATOS EN REGISTRO DE
exx
ld de,#0201
ld bc,#0190
ld hl,(#022e)
.l30c0
ld a,(hl)
bit 7,a
jr nz,l30cc
and #3f
exx
cp c
exx
jr z,l30dd
.l30cc
inc hl
dec bc
inc e
ld a,e
cp #0b
jr nz,l30d7
inc d
ld e,#01
.l30d7
ld a,b
or c
jr nz,l30c0
exx
ret
.l30dd
exx
push bc
ex de,hl
ld bc,#0200
and a
sbc hl,bc
jr nc,l30ef
add hl,bc
ld (#01cc),hl
ld hl,#0000
.l30ef
exx
push de
exx
ex (sp),hl
ex de,hl
push hl
call #015b
pop hl
pop de
jr nc,l3109
ld bc,#0200
.l30ff
add hl,bc
pop bc
ld a,d
or e
exx
jr nz,l30cc
exx
scf
ret
.l3109
pop bc
ret

.L310B ;IGUAL QUE RUTINA EN MAIN LOADER
ld de,#0000
exx
ld bc,#0190
ld hl,(#322e)
.l3115
ld a,(hl)
bit 7,a
jr nz,l312b
and #3f
exx
cp c
jr nz,l312a
inc d
exx
bit 6,(hl)
exx
jr z,l312a
inc e
jr l3132
.l312a
exx
.l312b
inc hl
dec bc
ld a,b
or c
jr nz,l3115
exx
.l3132
sla d
ld a,d
add e
ld d,a
ld a,c
exx
ld hl,(#022e)
ld b,#01
add #c0
ld c,a
add hl,bc
ld a,(hl)
exx
ld e,a
bit 0,d
jr nz,l314b
or a
ret z
.l314b
ld a,d
sub #02
ld d,a
ret

.L3150
.LEE_DATOS_DISCO ;LEER EN LOADER0
xor a
ld (#01cc),a
ld (#01cd),a
ld c,#c0
jr l315d
ld c,#80
.l315d
ld a,d
ld (#021e),a
ld (#0227),a
ld (#0185),hl
ld a,e
or c
ld (#0229),a
ld (#022b),a
.l316f
ld de,#0221
call #019f
ld a,(#0003)
or a
jr nz,l316f
ld de,#021b
call #0189
ld de,#0224
ld hl,#0000
jr l31a7
call #019a
.l318c
ld de,#021f
call #019f
ld hl,#0003
bit 5,(hl)
jr z,l318c
ret
ld bc,#0216
jr l31aa
ld bc,#01f7
ld hl,#0003
jr l31aa
.l31a7
ld bc,#01dc
.l31aa
ld (#01cf),bc
ld a,(de)
ld b,a
.l31b0
push bc
inc de
ld bc,#fb7e
.l31b5
in a,(c)
add a
jr nc,l31b5
jp m,#01b5
inc c
ld a,(de)
out (c),a
ld b,#08
.l31c3
djnz l31c3
pop bc
djnz l31b0
ld bc,#fb7e
ld de,#0000
jp #01dc
.l31d1
inc c
in a,(c)
ld (hl),a
dec c
inc hl
dec de
ld a,d
or e
jr z,l31eb
in a,(c)
jp p,#01dc
and #20
jr nz,l31d1
jr l31f4
.l31e7
inc c
in a,(c)
dec c
.l31eb
in a,(c)
jp p,#01eb
and #20
jr nz,l31e7
.l31f4
ld hl,#0003
.l31f7
in a,(c)
cp #c0
jr c,l31f7
inc c
in a,(c)
ld (hl),a
dec c
inc hl
ld a,#05
.l3205
dec a
jr nz,l3205
in a,(c)
and #10
jr nz,l31f7
ld a,(#0004)
and #24
ret nz
scf
ret
.l3216
in a,(c)
ret m
jr l3216
inc bc
rrca
nop
nop
ld bc,#0208
ld c,d
nop
add hl,bc
ld b,(hl)
nop
nop
nop
nop
ld (bc),a
nop
ld hl,(l30ff)
ld (bc),a

.L3230 ;salta desde el inicio de codigo en &3000 con salto calculado

ld bc,#0041 ;valor de relocalizacion para direcciones del loader
add hl,bc ;hl=&3230 +&0041 =&3271
ld a,#2c ;valor bucle para poner las direcciones reales de memoria
.l3236
.cambia_direcciones_correctas
ld c,(hl)
inc hl
ld b,(hl) ;bc=&0039

inc hl ;hl=&3273
push hl ;lo guarda en stack
push bc ;&0039 a pila
pop ix ;lo recupera en ix
add ix,de ;&0039+&3000= &3039
ld l,(ix+#01) ;cambia una direccion de carga codificada
ld h,(ix+#02) ;hl=&022e
add hl,de ;hl=&322e
ld (ix+#01),l
ld (ix+#02),h ;mete en posicion leida, el dato correcto de direccion de memoria
pop hl
dec a
jr nz,cambia_direcciones_correctas ;l3236

;por aqui cambiadas todas las direcciones del loader en &3000 a las correctas.
ld a,#c3
ld (de),a ;de=&3000 ;mete instruccion JP al principio de &3000
push de ;&3000 a pila
pop ix ;lo recupera en ix, ix=&3000
ld hl,#001b 
add hl,de ;&3000+&001b. hl=&301b
ex de,hl ;hl=&3000, de=&301b
inc hl
ld (hl),e
inc hl
ld (hl),d ;mete la direccion correcta del salto en &3000 --> JP &301B
pop hl ;hl=018C, direccion de texto "TITLE"
pop de ;de=&BFF0
pop bc ;bc=&FFFF
ld a,b ;a=&FF
inc a ;a=&00, Z activado
jr nz,l326b ;de primeras no efectua salto
;por aqui a=&00
ld a,c ;a=&FF
inc a ;a=&00, Z activado
jr z,l326f ;de primeras efectua salto
;por aqui a<>&00
.l326b
ld (&322E),bc

.l326f ;por aqui reg a=&00
jp (ix) ;salta a &3000, que modifico con un JP &301B, asi que ira por rutina &301B

add hl,sp
nop
ccf
nop
ld b,l
nop
ld c,e
nop
ld d,c
nop
ld e,b
nop
ld a,c
nop
add c
nop
or e
nop
cp l
nop
jp (hl)
nop
push af
nop
ld (de),a
ld bc,#0139
ld d,c
ld bc,#0154
ld e,(hl)
ld bc,#0161
ld h,h
ld bc,#0169
ld l,h
ld bc,#016f
ld (hl),d
ld bc,#0175
ld a,e
ld bc,#017e
add c
ld bc,#0189
adc h
ld bc,#018f
sub d
ld bc,#019a
sbc a
ld bc,#01a2
and a
ld bc,#01ab
cp d
ld bc,#01ce
sbc #01
???
call p,#0e01
ld (bc),a
dec l
ld (bc),a
ld l,h
ld (bc),a



;--------------------CODIGO ANTES DE METER EN &3000
push bc
push de
push hl
ld a,#c9
ld (#0000),a
.l01ab
call #0000
dec sp
dec sp
pop hl
ld bc,#000b
and a
.l01b5
sbc hl,bc
ld d,h
ld e,l
ld bc,l0230
add hl,bc
jp (hl)
ld a,i
ex af,af'
di
exx
push bc
exx
push de
push hl
ld bc,#fa7f
out (c),c
.l01ce equ $ + 2
.l01cd equ $ + 1
.l01cc
ld bc,#f540
.l01cf
in a,(c)
rra
jr c,l01cf
.l01d4
in a,(c)
rra
jr nc,l01d4
dec c
jr nz,l01cf
.l01dc
ld hl,(l022e)
ld de,#0008
call l0150
pop hl
jr nc,l0215
call #0075
.l01eb
jr nc,l0210
push bc
ld hl,(l022e)
ld de,#000a
call l0150
.l01f7
pop bc
pop hl
jr nc,l01fe
call #00b3
.l01fe
push af
.l0201 equ $ + 2
.l0200 equ $ + 1
ld bc,#fa7e
out (c),c
pop bc
exx
pop bc
exx
.l0208
and a
ex af,af'
ld a,c
rra
ld a,b
ret po
ei
ret
.l0210
pop hl
ld a,#01
jr l01fe
.l0215
pop bc
.l0216
jr l01fe
ld bc,#0000
.l021e equ $ + 3
.l021b
ld de,(l022e)
.l021f
push bc
push hl
.l0221
push de
ld b,#08
.l0224
call #0096
.l0227
pop hl
rla
.l022b equ $ + 2
.l0229
ld bc,#0008
add hl,bc
ex de,hl
.l022e
pop hl
pop bc
.l0230
rra
ret c
inc c
ld a,c
cp #40
jr nz,l021f
ret
.l0239
ld a,(de)
cp (hl)
jr nz,l0243
.l023d
inc hl
inc de
djnz l0239
.l0241
scf
ret
.l0243
cp #41
jr c,l024c
or #20
cp (hl)
jr z,l023d
.l024c
cp #20
jr nz,l0254
ld a,(hl)
or a
jr z,l0241
.l0254
and a
ret
call l010b
exx
ld de,l0201
ld bc,l0190
ld hl,(l022e)
.l0263
ld a,(hl)
bit 7,a
jr nz,l026f
and #3f
exx
cp c
exx
jr z,l0280
.l026f
inc hl
dec bc
inc e
ld a,e
cp #0b
jr nz,l027a
inc d
ld e,#01
.l027a
ld a,b
or c
jr nz,l0263
exx
ret
.l0280
exx
push bc
ex de,hl
ld bc,l0200
and a
sbc hl,bc
jr nc,l0292
add hl,bc
ld (l01cc),hl
ld hl,#0000
.l0292
exx
push de
exx
ex (sp),hl
ex de,hl
push hl
call l015b
pop hl
pop de
jr nc,l02ac
ld bc,l0200
add hl,bc
pop bc
ld a,d
or e
exx
jr nz,l026f
exx
scf
ret
.l02ac
pop bc
ret
ld de,#0000
exx
ld bc,l0190
ld hl,(l022e)
.l02b8
ld a,(hl)
bit 7,a
jr nz,l02ce
and #3f
exx
cp c
jr nz,l02cd
inc d
exx
bit 6,(hl)
exx
.l02c9 equ $ + 1
jr z,l02cd
inc e
jr l02d5
.l02cd
exx
.l02ce
inc hl
dec bc
ld a,b
or c
jr nz,l02b8
exx
.l02d5
sla d
ld a,d
add e
ld d,a
ld a,c
exx
ld hl,(l022e)
ld b,#01
add #c0
ld c,a
add hl,bc
ld a,(hl)
exx
ld e,a
bit 0,d
jr nz,l02ee
or a
ret z
.l02ee
ld a,d
sub #02
ld d,a
ret
xor a
ld (l01cc),a
ld (l01cd),a
ld c,#c0
jr l0300
ld c,#80
.l0300
ld a,d
ld (l021e),a
ld (l0227),a
ld (l0185),hl
ld a,e
or c
ld (l0229),a
.l0310 equ $ + 1
ld (l022b),a
.l0312
ld de,l0221
call l019f
ld a,(#0003)
or a
jr nz,l0312
ld de,l021b
call l0189
ld de,l0224
ld hl,#0000
jr l034a
call l019a
.l032f
ld de,l021f
call l019f
ld hl,#0003
bit 5,(hl)
jr z,l032f
ret
ld bc,l0216
jr l034d
ld bc,l01f7
ld hl,#0003
jr l034d
.l034a
ld bc,l01dc
.l034d
ld (l01cf),bc
ld a,(de)
ld b,a
.l0353
push bc
inc de
ld bc,#fb7e
.l0358
in a,(c)
add a
jr nc,l0358
jp m,l01b5
inc c
ld a,(de)
out (c),a
ld b,#08
.l0366
djnz l0366
pop bc
djnz l0353
ld bc,#fb7e
ld de,#0000
jp l01dc
.l0374
inc c
in a,(c)
ld (hl),a
dec c
inc hl
dec de
ld a,d
or e
jr z,l038e
in a,(c)
jp p,l01dc
and #20
jr nz,l0374
jr l0397
.l038a
inc c
in a,(c)
dec c
.l038e
in a,(c)
jp p,l01eb
and #20
jr nz,l038a
.l0397
ld hl,#0003
.l039a
in a,(c)
cp #c0
jr c,l039a
inc c
in a,(c)
ld (hl),a
dec c
inc hl
ld a,#05
.l03a8
dec a
jr nz,l03a8
in a,(c)
and #10
jr nz,l039a
ld a,(#0004)
and #24
ret nz
scf
ret
.l03b9
in a,(c)
ret m
jr l03b9
inc bc
rrca
nop
nop
ld bc,l0208
ld c,d
nop
add hl,bc
ld b,(hl)
nop
nop
nop
nop
ld (bc),a
nop
ld hl,(#30ff)
ld (bc),a
ld bc,#0041
add hl,bc
ld a,#2c
.l03d9
ld c,(hl)
inc hl
ld b,(hl)
inc hl
push hl
push bc
pop ix
add ix,de
ld l,(ix+#01)
ld h,(ix+#02)
add hl,de
ld (ix+#01),l
ld (ix+#02),h
pop hl
dec a
jr nz,l03d9
ld a,#c3
ld (de),a
push de
pop ix
ld hl,#001b
add hl,de
ex de,hl
inc hl
ld (hl),e
inc hl
ld (hl),d
pop hl
pop de
pop bc
ld a,b
inc a
jr nz,l040e
ld a,c
inc a
jr z,l0412
.l040e
ld (l022e),bc
.l0412
jp (ix)
add hl,sp
nop
ccf
nop
ld b,l
nop
ld c,e
nop
ld d,c
nop
ld e,b
nop
ld a,c
nop
add c
nop
or e
nop
cp l
nop
jp (hl)
nop
push af
nop
ld (de),a
ld bc,l0139
ld d,c
ld bc,l0154
ld e,(hl)
ld bc,l0161
ld h,h
ld bc,l0169
ld l,h
ld bc,l016f
ld (hl),d
ld bc,l0175
ld a,e
ld bc,l017e
add c
ld bc,l0189
adc h
ld bc,l018f
sub d
ld bc,l019a
sbc a
ld bc,l01a2
and a
ld bc,l01ab
cp d
ld bc,l01ce
sbc #01
???
call p,#0e01
ld (bc),a
dec l
ld (bc),a
ld l,h
ld (bc),a
