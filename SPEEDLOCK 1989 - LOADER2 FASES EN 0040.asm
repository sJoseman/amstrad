;LOADER DE FASES T2, UNA VEZ CARGADO JUEGO POR LOADER1
;JOSEMAN 2024
;LOADER2

;ATENCION
;loader0 en &AA00 --> punto de entrada a rutina en &AA1A seria el loader real de carga de datos
;loader1 en &0100 --> punto de entrada a rutina en &3000 (hace ldir a &3000), mismo loader real de carga de datos.
;loader2 en &0040 --> punto de entrada a rutina en &0040 mismo loader que los anteriores.

;LOADER0 (A PARTIR DE &AA00) LOADER 1 Y LOADER 2 SON EXACTENTE IGUALES, SOLO QUE RELOCALIZADOS.
;CUALQUIER DUDA LEER LA DOCUMENTACION EN LOADER0 MEJOR.
;LOADER1 Y LOADER2 TIENEN COMENTARIOS QUE PUEDEN SER ERRONEOS YA QUE LA LIMPIEZA DE DOCUMENTACION Y AFINE LO HICE EN LOADER0

org #0040

.L0040
;parametros de primeras, recien cargado el juego
;bc=&C600, ZONA DE RAM DONDE METERA FICHEROS DE APOYO (NOMBRE DE FASES Y TABLA DE DIRECCION DE CARGA TRACK Y SECTOR)
;de=&3FF0 ;ZONA DE RAM DONDE METERA LOS DATOS
;hl=&24ED ;tiene texto "FRONTSC" de primeras
;NOTA, AL IGUAL QUE EN LOADER1, EL TAMANO DE DATOS A LEER TRACK Y SECTOR LO DECIDE EN UNA RUTINA, &00F3 concretamente
;CONSULTANDO UNA TABLA DE CONVERSION. en call que hay en &00F3 sabremos cuantos datos va a cargar.
;para "FRONTSC" SERAN &4010 BYTES DE TAMANO
;ES EL LOGO DE TERMINATOR 2 Y EL TERMINATOR A MEDIO CUERPO QUE ENSENA AL EJECUTAR MENU!!
;en carga de fase1
;"COMBAT" ESCRIBE EN &2600 (PUNTERO DE TEXTO &24F8), TAMANO &4300
;&2600-&68FF ;CORROBORADO
;"SCENE1" ESCRIBE EN &DB00 (OJO CON ESTO) (PUNTERO DE TEXTO &2501), TAMANO &2400
;&DB00-&FEFF
;en carga de fase 2
;"CHASE" ESCRIBE EN &2600 (PUNTERO DE TEXTO &250B), TAMANO &3400
;&2600-&59FF ;CORROBORADO SOLO ESCRIBE UN FICHERO!
;METER ESTO EN CERDOTE
;en carga fase 3
;"HAND" ESCRIBE EN &2600 (PUNTERO DE TEXTO &2514), TAMANO &1500
;&2600-&3AFF ;CORROBORADO
;"HANDSC" ESCRIBE EN &3FF0 (PUNTERO DE TEXTO &251B), TAMANO &4010
;&3FF0-&7FFF ;NO CORROBORADO, PERO DEBERIA ESTAR BIEN.
;LA FASE DE LA MANO ES UN BONUS, NO TE MATA!!
;FASE4
;"COMBAT" ESCRIBE EN &2600 (PUNTERO DE TEXTO &2525), TAMANO &4300 ;MISMO CODIGO QUE COMBAT DE FASE 1
;&2600-&68FF ;CORROBORADO COMPROBAR CON WINHEX SI SON LOS MISMOS DATOS
;"SCENE2" ESCRIBE EN &DB00 (PUNTERO DE TEXTO &252E), TAMANO &2400
;&DB00-&FEFF ;CORROBORADO
;FASE5
;"EYE" ESCRIBE EN &2600 (PUNTERO DE TEXTO &2538), TAMANO &0B00
;&2600-&30FF ;CORROBORADO
;"EYESC" ESCRIBE EN &3FF0 (PUNTERO DE TEXTO &253E), TAMANO &4010
;&3FF0-&7FFF CORROBORADO.
;LA FASE DEL OJO NO TE MATA, ES UN BONUS
;FASE6
;"HELI" escribe en &2600 (PUNTERO DE TEXTO &2547). TAMANO &2500
;&2600-&4AFF CORROBORADO [SOLO UN FICHERO]
;FASE7
;"COMBAT" ESCRIBE EN &2600 (PUNTERO DE TEXTO &254F), TAMANO &4300
;&2600-&68FF ;CORROBORADO COMPROBAR CON WINHEX SI SON LOS MISMOS DATOS
;"SCENE3" ESCRIBE EN &DB00 (PUNTERO DE TEXTO &2558), TAMANO &2400
;&DB00-&FEFF
;FINAL
;"ENDSC" ESCRIBE EN &3FF0 (PUNTERO DE TEXTO &2562), TAMANO &4010
;&3FF0-&7FFF CORROBORADO.
;VUELVE A MENU DIRECTAMENTE. Y DESPUES VUELVE A CARGAR PANTALLA DEL TERMINATOR PARA MENU.

;IMPORTANTE, LOS FICHEROS DE COMBAT EN FASE 1, FASE 4 Y FASE 7, SON LOS MISMOS DATOS, COMPROBADO CON WINHEX

;OJO el inicio de este loader &0040 se cambiara por un JP &005B mas abajo en el codigo
;despues lo usara para saltar a direccion correcta llamando a &0040 --> JP &005B

push bc
.l0041
push de
push hl
ld a,#c9 
ld (#0000),a ;mete ret
call #0000 ;llama a ese ret
;vuelve por aqui, PERO en stack -2 bytes quedo esta llamada y en pilla metio &004B
dec sp
dec sp
pop hl ;hl=&004B, manera sutil, muy sutil de cargar hl con ese valor.
ld bc,#000b
and a ;desactiva carry
sbc hl,bc ;&004B-&000B= HL=&0040
ld d,h
ld e,l ;DE=&0040
ld bc,l0230 
add hl,bc ;&0040+&0230. HL=&0270
jp (hl) ;salta a esa direccion

.L005B ;ESTE ES EL LOADER REAL DE CARGA DE FASES, MISMA RUTINA QUE LOADER0 .LAA35
       ;vendra por aqui despues de efectuar salto anterior, poner direcciones de memoria correctas para el loader
       ;esta claro que este loader es relocalizable a gusto, seguro en otros juegos esta en otro lado.
       ;el salto lo consigue escribiendo un JP &005B en &0040, y llamando a &0040
;parametros de primeras, recien cargado el juego
;bc=&C600, ZONA DE RAM DONDE METERA FICHEROS DE APOYO (NOMBRE DE FASES Y TABLA DE DIRECCION DE CARGA TRACK Y SECTOR)
;de=&3FF0 ;ZONA DE RAM DONDE METERA LOS DATOS
;hl=&24ED ;tiene texto "FRONTSC" de primeras
;NOTA, AL IGUAL QUE EN LOADER1, EL TAMANO DE DATOS A LEER TRACK Y SECTOR LO DECIDE EN UNA RUTINA
;CONSULTANDO UNA TABLA DE CONVERSION. en call que hay en &00F3 sabremos cuantos datos va a cargar.
;para "FRONTSC" SERAN &4010 BYTES DE TAMANO LOS LEERA EN &3FF0-&7FFF

ld a,i
ex af,af'
di
exx
push bc
exx
push de
push hl
ld bc,#fa7f
out (c),c ;enciende motor de disquetera
ld bc,#f540
.l006c ;bucle de perdida de tiempo
in a,(c)
rra
jr c,l006c
.l0071
in a,(c)
rra
.l0075 equ $ + 1
jr nc,l0071
dec c
jr nz,l006c

;por aqui motor encendido, rotacion optima alcanzada.
ld hl,(&026E) ;HL=&C600, BUFFER DONDE METERA FICHEROS DE APOYO.
ld de,#0008 ;TRACK Y SECTOR A LEER
call LEE_DATOS_DISCO ;RUTINA SIMILAR A LA DE LOADER PRINCIPAL EN &AB6A ;l0190

;POR AQUI METIO "NOMBRES" DE FASES EN &C600, SIGUE EL MISMO PROCESO QUE EN LOADER0
pop hl ;RECUPERO A PUNTERO DE TEXTO "FRONTSC" de primeras
jr nc,l00b2 ;si algo fue mal, repite comando y lectura.

call l00B5 ;ahora buscara texto "FRONTSC" EN TABLA DE NOMBRES. IGUAL QUE RUTINA busca_texto_tabla LOADER0
;esta rutina devuelve Carry si se encontro texto buscado
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
jr nc,l00ad ;NO CARRY es que no se ha encontrado el texto deseado

push bc
ld hl,(l026e) ;RECUPERA DIRECCION DE RAM QUE USA PARA BUFFER &C600
ld de,#000a ;TRACK Y SECTOR A LEER DE DISCO, al sector le llama correctamente en la propia rutina
call LEE_DATOS_DISCO ;l0150

;SON DATOS PARA CALCULAR BYTES A LEER DESDE DISCO Y TRACK SECTOR DONDE EMPEZAR A LEERLO
;CALCULARA ESTOS VALORES EN LLAMADA DE AQUI ABAJO A &AACD

pop bc
pop hl
.l0096
jr nc,l009b ;recuerda no carry es error en lectura de datos requeridos

;por aqui datos leidos correctamente
call l00F3 ;ESTA RUTINA CALCULA BYTES A LEER DE DISCO, TRACK SECTOR DONDE LEERLOS
           ;Y EFECTUAR ESA LECTURA DE DISCO

;POR AQUI HA ESCRITO EN RAM EN EL CASO DE "FRONTSC"
;SERAN &4010 BYTES DE TAMANO LOS LEERA EN &3FF0-&7FFF CORROBORADO
;ES LA PANTALLA DE FASE1, SOLO QUE TIENE DE INICIO LOS DATOS PARA LAS TINTAS
;LAS COLOCARA EL PROPIO JUEGO AL VOLVER.

.l009b ;error de lectura de datos requeridos o datos leidos correctamente, senalizado con carry

;AHORA APAGA DISQUETERA Y VOLVERA POR EL EI RET DE AQUI ABAJO AL CODIGO DEL JUEGO
;EN EL CASO DE FRONTSC VUELVE A &8129 Y EJECUTA MENU DEL JUEGO.
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
ret po ;NO VUELVE POR AQUI

;VUELVE POR AQUI AL CODIGO DEL JUEGO QUE LLAMO A ESTA CARGA OJO 
ei ;REACTIVA INTS OJO
ret

.l00ad
pop hl
ld a,#01
jr l009b
.l00b2
pop bc
.l00b3
jr l009b

.L00B5
ld bc,#0000
ld de,(l022e)
.l00bc
push bc
push hl
push de
ld b,#08
call l0096
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
jr nz,l00bc
ret
.l00d6
ld a,(de)
cp (hl)
jr nz,l00e0
.l00da
inc hl
inc de
djnz l00d6
.l00de
scf
ret
.l00e0
cp #41
jr c,l00e9
or #20
cp (hl)
jr z,l00da
.l00e9
cp #20
jr nz,l00f1
ld a,(hl)
or a
jr z,l00de
.l00f1
and a
ret

.L00F3
;SE HA CARGADO UNA TABLA DE CONVERSION, PARA HACER CALCULOS Y CALCULAR TAMANO DATOS A LEER EN DISCO
call L014B ;hace calculos con los datos recien cargados
           ;valor devuelto
           ;DE=&4010 ;VALOR PROVINIENTE DE CALCULOS en esta rutina llamada (&014B) (igual que rutina &AB25 de loader0)
           ;SON LOS BYTES A LEER DESDE DISCO &200 DE PRIMERAS &016C DE SEGUNDAS!!!

;Ademas de ese dato calculado en &014B
;HL=&3FF0, zona en RAM donde escribir los datos a leer en disco.


;NO DOCUMENTO MAS POR AQUI, LEER EN LOADER0

exx ;mete esos valores
ld de,&0201
ld bc,&0190
ld hl,(&026e)
.l0100
ld a,(hl)
bit 7,a
jr nz,l010c
and #3f
exx
cp c
exx
.l010b equ $ + 1
jr z,l011d
.l010c
inc hl
dec bc
inc e
ld a,e
cp #0b
jr nz,l0117
inc d
ld e,#01
.l0117
ld a,b
or c
jr nz,l0100
exx
ret
.l011d
exx
push bc
ex de,hl
ld bc,l0200
and a
sbc hl,bc
jr nc,l012f
add hl,bc
ld (l01cc),hl
ld hl,#0000
.l012f
exx
push de
exx
ex (sp),hl
ex de,hl
push hl
call l015b
pop hl
.l0139
pop de
jr nc,l0149
ld bc,l0200
add hl,bc
pop bc
ld a,d
or e
exx
jr nz,l010c
exx
scf
ret
.l0149
pop bc
ret
ld de,#0000
exx
.l0150 equ $ + 1
ld bc,l0190
.l0154 equ $ + 2
ld hl,(l022e)
.l0155
ld a,(hl)
bit 7,a
jr nz,l016b
.l015b equ $ + 1
and #3f
exx
cp c
jr nz,l016a
inc d
.l0161
exx
bit 6,(hl)
exx
jr z,l016a
inc e
.l0169 equ $ + 1
jr l0172
.l016a
exx
.l016b
inc hl
dec bc
ld a,b
or c
.l016f
jr nz,l0155
exx
.l0172
sla d
ld a,d
.l0175
add e
ld d,a
ld a,c
exx
ld hl,(l022e)
ld b,#01
.l017e
add #c0
ld c,a
add hl,bc
ld a,(hl)
exx
ld e,a
.l0185
bit 0,d
jr nz,l018b
.l0189
or a
ret z
.l018b
ld a,d
sub #02
ld d,a
.l018f
ret

.l0190
.LEE_DATOS_DISCO ;LEER RUTINA EN LOADER0 ESTA MEJOR DOCUMENTADA.
;ESTA RUTINA HACE TODO EL TRABAJO, READ ID, SEEK, Y READ DATA
;SOLO LEE UN SECTOR POR CADA LLAMADA
;parametros
;hl, DONDE METERA LOS DATOS EN RAM A LEER DESDE DISCO
;reg d TRACK, reg e SECTOR a leer (le suma &C0 para convertirlo a ID correcta)

xor a
ld (l01cc),a
ld (l01cd),a
ld c,#c0
.l019a equ $ + 1
jr l019d
ld c,#80
.l019d
ld a,d
.l019f equ $ + 1
ld (l021e),a
.l01a2 equ $ + 1
ld (l0227),a
ld (l0185),hl
ld a,e
or c
.l01ab equ $ + 2
ld (l0229),a
ld (l022b),a

.l01af
.bucle_reintento_comando
ld de,l0221 ;direccion de memoria donde esta numero de comandos, comando y parametros al FDC
call SEND_CMD_RECIBE_DATOS ;&01DF

;vuelve una vez mandado comando, execution phase acabada y guardado resultados del resul phase, ST1 comprobado tb.
;Carry flag set, todo correcto. STATUS REGISTER 1 comprobado.
;el caso es que parece no usar esto para controlar algun error recibido en STATUS REGISTER 1

.l01b5
ld a,(#0043) ;LEE STATUS REGISTER 0
or a
jr nz,l01af ;si NZ, reintenta el comando mandado al FDC 

;por aqui todo correcto en mandar comando y recibir datos / resultados del FDC.

ld de,l025B ;zona de datos con comando y parametros nuevos a mandar al FDC, comando SEEK
call l01C9

;POR AQUI MANDO COMANDO SEEK A TRACK 0 Y EJECUTO UN SENSE INTERRUPT STATUS PARA COMPLETAR EL POSICIONAMIENTO AL TRACK 0

ld de,l0264 ;DATOS PARA COMANDO READ DATA
ld hl,#0000 ;CAMBIADO A &C600, QUE SERA DONDE LEE DATOS DE APOYO EN RAM
jr l01e7 ;VOLVERA POR &0082 despues de este salto
;------------------

call l019a
.l01ce equ $ + 2
.l01cd equ $ + 1
.l01cc
ld de,l021f
.l01cf
call l019f
ld hl,#0003
bit 5,(hl)
jr z,l01cc
ret
.l01dc equ $ + 2
ld bc,l0216
jr l01ea

.L01DF
.SEND_CMD_RECIBE_DATOS
ld bc,l01f7
ld hl,#0003
jr l01ea

.L01E7 ;hace un jp aqui para ejecutar un comando READ DATA
;parametro HL, donde guardara los datos requeridos al FDC en RAM
ld bc,l021C ;para variar salto en salida de rutina
.l01eb equ $ + 1
.l01ea
ld (l01cf),bc
ld a,(de)
ld b,a

.l01f0
.BUCLE_CMDYCONFIG
push bc
inc de
ld bc,#fb7e
.l01f5
in a,(c)
.l01f7
add a
jr nc,l01f5
jp m,l01b5
inc c
ld a,(de)
.l0200 equ $ + 1
out (c),a
.l0201
ld b,#08
.l0203
djnz l0203
pop bc
djnz BUCLE_CMDYCONFIG ;l01f0

;POR AQUI HA MANDADO COMANDO Y CONFIG DEL COMANDO AL FDC
.l0208
ld bc,#fb7e ;Main status register FDC.
ld de,#0000 ;EL VALOR QUE TOMA REG DE varia segun comando a mandar, documentado en loader0
jp l021C ;EL VALOR DEL SALTO SE VARIA segun comando a mandar, documentado en loader0
          ;EN ESTE CASO EFECTUA UN READ DATA

.l0211
.escribe_datos_ram
inc c
in a,(c)
ld (hl),a
dec c
.l0216
inc hl
dec de
ld a,d
or e
.l021b equ $ + 1
jr z,l022b
in a,(c)
.l021f equ $ + 1
.l021e
jp p,l01dc
.l0221
and #20
.l0224 equ $ + 1
jr nz,escribe_datos_ram ;l0211
;por aqui acabo de leer los datos requeridos.

jr lee_resultphase_READDATA ;l0234

.l0227
inc c
.l0229 equ $ + 1
in a,(c)
dec c
.l022b
in a,(c)
.l022e equ $ + 1
jp p,l01eb
.l0230
and #20
jr nz,l0227

.l0234
.lee_resultphase_READDATA
ld hl,#0043 ;donde guardara los bytes de resultado de READ DATA. 7 bytes.
.l0237
in a,(c)
cp #c0
jr c,l0237
inc c
in a,(c)
ld (hl),a ;GUARDA DATOS DEVUELTOS POR EL COMANDO MANDADO
dec c
inc hl
ld a,#05
.l0245
dec a
jr nz,l0245
in a,(c)
and #10
jr nz,l0237

;Por aqui todos los bytes de RESULT PHASE recibidos
ld a,(#0044) ;LEE STATUS REGISTER 1
and #24
ret nz ;NZ es que ha habido algun error al ejecutar comando
scf ;activa carry para senalizar que el comando se ejecuto bien.
ret ;VOLVERA A FUNCION MAIN QUE LLAMO A ESTAS RUTINAS, DOCUMENTADO EN LOADER0


.l0256
in a,(c)
ret m
jr l0256
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

.L0270 ;salta desde el inicio de codigo en &0040 con salto calculado

;sigue aqui jose
ld bc,&0041 ;valor de relocalizacion para direcciones del loader
add hl,bc
ld a,#2c ;valor bucle para poner las direcciones reales de memoria

.l0276
.bucle_relocalizacion
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
jr nz,bucle_relocalizacion ;l0276

;por aqui cambiadas todas las direcciones del loader, relocalizado
ld a,#c3 ;mete instruccion JP
ld (de),a ;cambia inicio de loader &0040 con un JP, AHORA CALCULARA LA DIRECCION DE SALTO
push de
pop ix
ld hl,#001b
add hl,de
ex de,hl ;DE=&005B, ES LA DIRECCION DE SALTO DEL JP PUESTO EN &0040
inc hl
ld (hl),e
inc hl
ld (hl),d ;cambia la direccion de salto del JP en &0040

pop hl
pop de
pop bc ;bc&=C600, ojo aqui hay variacion con respecto a loader1 donde bc=&FFFF
ld a,b
inc a
jr nz,l02ab ;aqui se produce NZ de primeras, mientras que en loader1 se produce Z de primeras.
ld a,c
inc a
jr z,l02af

.l02ab ;por aqui a<>&00
ld (&026E),bc ;si este codigo es igual al de loader1
              ;aqui esta definiendo la direccion para el BUFFER de carga de datos de apoyo que sera &C600
.l02af
jp (ix) ;salta a &0040, inicio de este loader, ahora modificado con un JP &005B

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
nop
nop
nop
nop
nop
nop
nop
