;------------------------------------------------------------------------------------------------------
;loader original livingstone supongo 2 DISCO (el que efectua la carga del menu de eleccion de fase)
;Joseman febrero de 2022
;------------------------------------------------------------------------------------------------------

;Notas
;para mas referencias a loader de disco similar mirar mi loader comentado del Cyber Big en Github
;los bits van de 0 a 7 (no de 1 a 8)
;por un (mal) habito que tengo menciono los numeros hexadecimales con # o & indistintamente.
;no uso acentos ya que el winape los transforma en codigos de CPC


;-----------Mini explicacion de comunicacion con FDC--------------------------------------------------

  ;Antes de nada explicar como funciona la comunicacion del Amstrad CPC con el FDC (NEC UPD765)
  ;esta comunicacion consiste en TRES fases 
  ;(excepto en algunos comandos como SEEK y RECALIBRATE  que no tienen EXECUTION-PHASE ni RESULT-PHASE)
  ;FASE 1 o "Command-Phase", donde se le envia el comando al FDC y sus parametros (pueden ser varios bytes)
  ;FASE 2 o "Execution-Phase" donde se leen/escriben los datos (bytes) desde o hacia la disquetera
  ;FASE 3 o "Result-Phase" donde el FDC nos indica el resultado de la operacion usando 4 registros de estado y,
                           ;otros bytes que variaran segun el comando mandado al FDC.

  ;Tanto la longitud de los parametros como de los result bytes devueltos por el FDC VARIAN de un comando a otro.
  ;Es necesario consultar la documentacion tecnica del FDC para saber estas diferentes situaciones.

;en la transmision de datos entre el FDC y la CPU se necesita perder tiempo 
;para que el FDC consiga ejecutar los comandos o servir los datos a la CPU.
;por eso hay un monton de bucles de perdida de tiempo en el loader.

;FDC es el Floppy Disc Controller (NEC UPD765)
;FDD es el Floppy Disc Drive (disquetera de 3" simple cara, solo 1 cabezal)
;------------------------------------------------------------------------------------------------------------

;empecemos

org #0100 ;todos los programas que se arrancan con |cpm empiezan en esta direccion de memoria
run $

di ;deshabilita interrupciones,
   ;cualquier operacion de cambio de stack, movimiento de datos con ldir
   ;usar registros secundarios o los registros index ix e iy
   ;implica tener que deshabilitarlas.
   ;ademas que necesitamos que el propio firmware del CPC quede deshabilitado (no se usa para nada aqui).

ld sp,&0100 ;coloca stack detras del loader
ld hl,#ffff ;direccion inicial de carga de datos (va escribiendo hacia abajo en memoria de CPC)
            ;casi todos los juegos de Opera Soft lo hacen asi
            ;por eso las pantallas de carga se van visualizando al reves.


ld a,#01 ;track inicial de los datos en disco
ld bc,#fd00 ;numero de bytes a leer en total
ld ix,datos_formato_disco ;direccion donde estan los datos de formato del disco que mandara al FDC para configurarlo.
call configura_carga_datos ;aqui hara todas las operaciones y volvera solo para ejecutar el menu con jp &0300

;saltara ya al programa cargado.
jp #0300 ;salta a menu de eleccion de fase una vez cargado


;-----------subrutinas----------------

.configura_carga_datos
di ;vuelve a deshabilitar innecesariamente los interrupciones (lo hizo al principio)
   ;nunca las vuelven a activar, entiendo que este di es totalmente innecesario

ld (direccion_memo_escribir_low_byte),hl ;direccion inicial memoria RAM a escribir
ld (track_a_mover_cabezal),a ;track inicial a leer
ld (cantidad_bytes_quedan_por_intentar_leer),bc ;bytes totales a leer desde disco

;ahora va a meter la configuracion del formato del disco en el comando READ DATA
;longitud de sector 1024 bytes
;sector inicial de cada track = &01
;sector final de cada track = &05
ld a,(ix+#00)
ld (l02db),a ;parametro 5 para comando READ DATA
             ;a=&03 (1024 bytes por sector)
ld a,(ix+#01)
ld (l02da),a ;parametro 4 para comando READ DATA
             ;a=&01 sector INICIAL
             
ld a,(ix+#02) ;parametro 6 para comando READ DATA
              ;a=&05 SECTOR END OF TRACK = &05
ld (l02dc),a

call configura_crtc_borra_pantalla

call pon_colorines

call enciende_motor_FDC_espera_revoluciones

.lee_datos_disco
;va leyendo 1024bytes de cada sector (hay 5 sectores por track)
;5*1024=5.120bytes por track
call lee_sectores ;dentro de esta funcion lee 1024 bytes de cada sector en el track actual
           ;si hay algun error de lectura de disco reintentara releer el sector fallido
           ;cuando vuelva se habra leido un track entero (5120bytes)
           ;si el comando READ DATA se ejecuta correctamente
           ;el numero de sector se incrementa AUTOMATICAMENTE
           ;y se iran leyendo todos los sectores secuencialmente en las siguientes
           ;llamadas al comando READ DATA.

ld hl,track_a_mover_cabezal ;variable donde se almacena track (va desde #01 a #0D)
inc (hl) ;incrementa track a leer
         
ld a,(direccion_memo_escribir_high_byte)
sub #14 ;quita 5.120bytes a la direccion de memoria a escribir en RAM
        ;es decir se ha leido un track entero y necesita posicionar en la siguiente zona acorde de RAM
      
ld (direccion_memo_escribir_high_byte),a
ld de,(cantidad_bytes_quedan_por_intentar_leer) ;carga el numero de bytes que le quedan por leer del disco
ld a,e
or d ;comprueba que hemos acabado de leer todos los datos
jr nz,lee_datos_disco ;si no es asi sigue leyendo del disco

;por aqui hemos acabado de leer todos los datos del disco solicitados
jp apaga_motor_FDC ;el ret de la subrutina apaga_motor_FDC lo llevara de vuelta a 
                   ;&0113, en el que efectuara ya el salto al menu de eleccion de fase.


;------------------------
.manda_orden_al_FDC
;esta rutina es para mandar comando, parametros hacia el FDC o recibir datos desde el FDC

ld bc,#fb7e ;Main Status Register del FDC
in a,(c)
and #10 ;comprueba bit 4 (de 0 a 7)
ret nz ;si el bit 4 esta a 1 significa que el FDC aun esta en medio de de un read o write command.
       ;con lo cual no enviara nada al FDC.

;por aqui mandara 2 tipos de comando al FDC
;SEEK para mover la cabeza lectora al track a leer
;READ DATA para leer los datos de ese track
ld b,(hl) ;b se carga con el numero resultante de la suma de comando + parametros a mandar.
          ;es decir 1 por el propio comando +x parametros a mandar
          ;por ejemplo con SEEK se carga con &3 ya que es 1 por el comando + 2 por los parametros a mandarle.

inc hl ;mueve puntero al comando a mandar al FDC

.manda_comando_parametros_FDC 

push bc
ld bc,#fb7e ;Main Status Register del FDC

;ahora esperamos a que el FDC nos diga que esta listo para recibir o enviar datos

esperando_RQM ;si el Data Register del FDC no esta preparado para enviar recibir datos, buclea
              ;hasta que lo este.
in a,(c)
add a ;si el bit 7 esta a 1 se activa carry (como si carry cogiera el valor del bit 7)
      ;ademas con este add el bit 6 pasa ahora al bit 7
jr nc,esperando_RQM ;espera a bit 7 =1, es decir a que el Data Register este preparado.

add a ;ahora comprueba lo mismo con lo que era el bit 6 (ahora es el bit 7)
      ;el bit 6 (ahora movido a bit 7) es DIO (DATA INPUT/OUTPUT)
      ;Si 0 entonces transferencia es desde la CPU al DATA REGISTER
      ;Si 1 entonces la transferencia es desde el DATA REGISTER a la CPU
jr c,FDC_to_CPU ;si bit 7=1 el FDC esta en transferencia direccion FDC -> CPU  
                ;es decir el FDC esta mandando datos o resultados del comando en direccion CPU.
                ;en direccion FDC->CPU, NO podemos mandarle comandos al data register.

;por aqui transferencia en direccion CPU->FDC
;estamos preparados para mandar comandos o parametros al FDC

ld a,(hl) ;lee comando a mandar al FDC
          ;el primer comando que manda es #0F
          ;comando SEEK (para mover la cabeza al track especificado)
ld bc,#fb7f ;FDC DATA REGISTER
out (c),a ;manda comando o parametros al FDC
inc hl ;incrementa el puntero de comando y parametros
pop bc ;recupera numero de parametros a mandarle al FDC


ld a,#05 ;para perdida de tiempo
;pierde un poco de tiempo despues de mandarle el comando o el parametro al FDC
.wasting_time
dec a
nop
jr nz,wasting_time

djnz manda_comando_parametros_FDC ;decrementa b que son el numero de parametros a mandarle al FDC
                                  ;y repite la operacion de envio de datos al FDC con esos parametros

;hemos acabado de mandarle el comando y los parametros al FDC
ret

.FDC_to_CPU
pop bc ;recupera contador de comando + parametros
       ;en realidad en este loader nunca salta a esta zona


;-----------------------------------------------------------------
.guarda_status_registers
;aqui almacena los resultados que devuelve el FDC despues de ejecutar los comandos
;estos resultados se usan de diferentes formas dependiendo del comando
;pero generalmente su uso es para comprobar que el comando se ejecuto correctamente por el FDC

ld hl,#0040 ;direccion de memoria RAM donde escribira los status registers
ld bc,#fb7e ;Main status register FDC. Read Only. 

.Sigue_leyendo_Status_Registers ;por aqui salta para escribir cada status register en memoria
.espera_FDC_ready
in a,(c) ;lee el MAIN STATUS REGISTER devuelto por el FDC.
bit 7,a ;bit 7 en el MAIN STATUS REGISTER.
jr z,espera_FDC_ready ;sigue comprobando que el FDC esta listo para recibir o mandar datos

;aqui decide si la transmision es CPU->FDC, para seguir mandandole datos
;o si es FDC->CPU para guardar los datos que devuelve el FDC con los resultados del comando mandado
bit 6,a ;DIO Data Input/Output (0=CPU->FDC, 1=FDC->CPU) 
jr nz,lee_STATUS_REGISTERS_y_guardalos

;por aqui 0=CPU->FDC
bit 4,a ;FDC Busy (still in command-, execution- or result-phase)
jr nz,espera_FDC_ready ;si el FDC aun no ha acabado la operacion, bucleamos para esperarle.

;por aqui acabo de recibir los datos desde el data register
;los datos que nos ha enviado el data register se han escrito en la
;zona de memoria #0040 y siguientes.
ld hl,#0040 ;direccion de memoria RAM donde escribio los status registers
            ;OJO usa una direccion fuera de este loader
ld a,(hl) ;lee el primer byte recibido desde el data register
ret


.lee_STATUS_REGISTERS_y_guardalos
;por aqui 1=FDC->CPU
inc c ;nos movemos a Data Register 
in a,(c) ;The other four Status Registers cannot be read directly
         ;instead they are returned through the data register (#FB7F)
         ;as result bytes in response to specific commands.

ld (hl),a ;va metiendo los estatus registers en #0040,#0041, etc.
inc hl ;movemos puntero donde guarda los status regisers
dec c ;nos movemos de nuevo a Main status register FDC. Read Only. 

;perdemos tiempo...
ld a,#05
.wasted_time
dec a
jr nz,wasted_time

jr sigue_leyendo_Status_Registers

;-------------------------------------------------------------------

.enciende_motor_FDC_espera_revoluciones
ld a,#01 ;parametro FDC para encender motor disquetera
jr control_motor_FDD

.apaga_motor_FDC ;por aqui saltara al acabar de leer todos los datos del disco y apagara la disquetera
xor a ;parametro FDC para apagar motor disquetera

.control_motor_FDD
ld bc,#fa7e ;puerto de control del motor de la disquetera
out (c),a ;enciende o apaga motor disquetera
ld a,#40
jr espera_FDC_O_motor_RPM ;bucle de perdida de tiempo para que el motor alcance las revoluciones necesarias.
   ;aqui hace un jr para que el ret de espera_FDC_O_motor_rpm le lleve al call original

.termina_comando_SEEK
;los comandos RECALIBRATE y SEEK no devuelve bytes de resultado directamente
;es decir NO TIENEN "EXECUTION-PHASE" ni "RESULT-PHASE"
;en estes 2 casos, el programa debe esperar hasta que el Main Status Register
;SENALIZA que el comando ha sido completado
;ENTONCES
;se tiene que mandar un "Sense Interrupt State" para "terminar" el comando en si.

ld a,(tiempo_espera_posicion_cabezal) ;siempre toma valor 1
call espera_FDC_O_motor_RPM
;la cabeza lectora esta posicionada en el track especificado
ld a,#0f ;para perder un tiempo determinado
call bucle_pierde_tiempo
ld bc,#fb7e ;Main status register FDC. Read Only. 
.espera_FDC_listo
in a,(c)
bit 7,a ;bit 7 en el STATUS REGISTER 1.
jr z,espera_FDC_listo ;comprueba que el FDC esta listo para recibir o mandar datos

;por aqui el FDC esta listo para mandar o recibir datos
ld hl,l02e3
inc hl
ld a,(hl) ;a siempre toma valor &8
          ;entiendo que es comando SENSE INTERRUPT STATUS

inc bc ;nos movemos a Data Register del FDC
out (c),a ;mandamos el comando SENSE INTERRUPT STATUS

ld a,#05
.perdemos_tiempo
dec a
nop
jr nz,perdemos_tiempo

jr guarda_status_registers ;el ret de la subrutina a la que saltamos
                           ;nos devolvera a la que llamo a esta.

;-------------------------------------------------------------------
.mueve_cabezal_track_destino
ld hl,track_fisico_fdd
sub (hl) ;a= track al que ir, (hl) track anterior leido
         ;esta resta SIEMPRE da como resultado &1
         ;decide el tiempo de espera de movimiento del cabezal al siguiente track, que en Livingstone 2
         ;siempre es contiguo

ret z ;NUNCA se cumple z
jr nc,l01df ;para salto de track? NUNCA se cumple carry
;por aqui nunca pasa.
neg

.l01df
ld (tiempo_espera_posicion_cabezal),a

.mueve_cabezal
ld a,(track_a_mover_cabezal) ;track a donde mover cabezal del FDD
ld hl,comando_parametros_fdc_seek ;comando SEEK y parametros a mandarle al FDC
push hl
pop ix
ld (ix+#03),a ;parametro track del comando SEEK
call manda_orden_al_FDC ;manda el comando al FDC (mueve cabeza lectora a track 1)

call termina_comando_SEEK ;el comando SEEK (y RECALIBRATE) necesita ser "terminado"
                          ;tambien comprobara que se "termino" correctamente

inc hl ;incrementa puntero a #0041 (zona de ram donde se guardaron los STATUS REGISTERS)
ld a,(hl) ;entiendo que esta leyendo el resultado del comando SENSE INTERRUPT STATUS
          ;TP  Physical Track Number
ld hl,track_a_mover_cabezal
cp (hl) ;compara con el track al que le mando ir, si coincide, todo correcto.
        ;movimiento de cabezal correcto
jr nz,mueve_cabezal ;si no es asi repite el comando seek al track que necesitamos ir

;por aqui se ha posicionado bien la cabeza lectora en el track mandado en seek
ld (track_fisico_fdd),a ;track donde esta la cabeza del FDD fisicamente.
;todo correcto por aqui, la cabeza de la FDD esta en el track mandado en seek
ret

;---------------------------------------------------------

.espera_FDC_O_motor_RPM
push af
ld a,#0c ;para perder tiempo mientras el motor alcanza las revoluciones necesarias
call bucle_pierde_tiempo
pop af
dec a
jr nz,espera_FDC_O_motor_RPM
ret

.bucle_pierde_tiempo ;l020b
push af
ld a,#f6 ;para perder aun mas tiempo mientras el motor alcanza las revoluciones necesarias
.l020e
dec a
jr nz,l020e
pop af
dec a
jr nz,bucle_pierde_tiempo
ret

;----------------------------------------------------------------

.lee_sectores
ld a,(track_a_mover_cabezal) ;track al que movera la cabeza lectora (de inicio #01) 
             
call mueve_cabezal_track_destino ;mueve la cabeza lectora al track especificado 
                                 ;y comprobara que se ha movido correctamente

.manda_comando_READ_DATA
ld hl,comando_parametros_READ_DATA ;siguiente comando a mandar al FDC, comando READ DATA
            ;con los siguientes parametros
            ;MT=0 (usamos FDD con solo una cabeza lectora)
            ;MF=1 (usamos MFM format)
            ;SK=0 (Skip Deleted Data Address Mark)

call manda_orden_al_FDC

jr nz,manda_comando_READ_DATA ;si el FDC no esta preparado para recibir el comando, vuelve a intentarlo

;por aqui comando READ DATA mandado

ld hl,(direccion_memo_escribir_low_byte) ;recupera memoria RAM a escribir datos
.l0228 equ $ + 1
ld bc,#fb7e ;Main status register FDC. Read Only. 
ld de,(cantidad_bytes_quedan_por_intentar_leer) ;recupera numero de bytes que quedan por escribir en RAM
              ;recupera -5120bytes de cada vez que es lo que ocupa cada track
              

.lee_datos_disco_espera_rqm
in a,(c)
jp p,lee_datos_disco_espera_rqm ;esperamos a que el data register tenga preparada la informacion a leer.
                                ;para dilucidarlo usamos el bit 7 del MAIN STATUS REGISTER).
                                ;por eso usa el flag de signo para dilucidar,
	                        ;es decir, si el bit 7 del Main Status Register (RQM) esta activado
   	                        ;el FDC nos esta diciendo que esta listo para enviar o
                                ;recibir datos mediante el DATA REGISTER

bit 5,a ;mira si AUN estamos en EXECUTION-PHASE
jr z,lee_status_registers ;si z, se acabo la EXECUTION-PHASE

;por aqui AUN estamos en EXECUTION-PHASE (estamos leyendo datos del disco)
ld a,e
or d ;comprobamos si hemos leido todos los bytes que mandamos cargar al principio del loader
jr z,espera_status_registers_y_leelos ;de=#0000? es decir hemos leido el numero de datos especificado
                                       ;si es si saltamos a lectura de status registers

;por aqui aun quedan datos para leer y cargar en RAM
inc bc ;Data Register (Port #FB7F) 
ind ;Reads the (C) port and writes the result to (HL), then decrements HL and decrements B
    ;escribe el dato leido por el comando READ DATA
    ;en la memoria de cpc especificada (el primer dato va a #FFFF), es decir, esta escribiendo
    ;desde el final de la memoria del CPC (memoria de video)
    ;hasta #0300 que es donde empieza el programa que pone el menu de eleccion de fase
    ;la pantalla de presentacion se visualiza al reves dese #FFFF a #C000 (como siempre hace Opera Soft)
    ;ind decrementa HL y registro b automaticamente

dec c ;se posiciona en Main status register FDC. Read Only. 
inc b ;incrementa b porque ind lo decrementa automaticamente y Opera Soft no usa esa "feature" aqui
      ;vuelve a posicionarse en Main status register FDC. Read Only. 

dec de ;decrementa numero de lecturas que hacemos en READ DATA
       ;se va escribiendo byte a byte hacia atras en memoria desde #FFFF a #0300
       ;en tramos de 5120bytes que es lo que ocupa un sector.
       ;la pantalla de presentacion en #c000-#ffff
       ;el programa de eleccion de fase en #0300
       ;por el medio hay datos vacios
       ;menos en #4000
       ;y #A67C - #BFFF con datos sueltos que supongo usa el programa de eleccion de fase
        

jr lee_datos_disco_espera_rqm ;sigue leyendo datos del disco

espera_status_registers_y_leelos
;por aqui llega cuando de=#0000, es decir, hemos leido todos los datos especificados en DE al principio del loader.
;como ya he dicho se ha escrito toda la memoria del CPC desde #0300 a #FFFF (hacia atras)

inc bc ;Data Register (Port #FB7F) 
in a,(c) 
dec bc ;Main status register FDC. Read Only. 
jr lee_datos_disco_espera_rqm ;en este salto al estar DE=#0000 (todos los datos leidos)
                              ;solo espera a que acabe la EXECUTION-PHASE

;cuando acabe la EXECUTION-PHASE, seguira por aqui.
;estamos en RESULT-PHASE (el FDC nos dice que resultado ha dado el comando READ DATA)

.lee_status_registers ;lee los resultados devueltos por el FDC en los Status Registers
ld (cantidad_bytes_restantes_leer),de ;va guardando el contador de bytes cuando las lecturas son correctas
call guarda_status_registers ;leera los los status registers de READ DATA y los escribira en 
                             ;#0040-#0046
                             ;el valor que devuelve S0 es &40 (%01000000)
                             ;el valor que devuelve S1 es &80 (%10000000)
                             ;el valor que devuelve S2 es &00 (%00000000)
                             ;el valor que devuelve TR es &0D (track 13)
                             ;el valor que toma HD es &00 (correcto, cabeza 0)
                             ;el valor que toma LS es &05 (correcto, sector &05, ultimo sector de cada track)
                             ;el valor que toma SZ es &03 (correcto, 1024 bytes por sector)

ld b,a ;preserva S0 en b
and #c0 ;comprueba bit 7 y bit 6 de S0
        ;solo con bit7 y bit6 =0 saltara a todo_correcto
jr z,todo_correcto ;EN EL CPC NUNCA PASA QUE TODO CORRECTO CON STATUS REGISTER 0 EN READ DATA COMMAND
                   ;la explicacion es que en el CPC no se conecto el pin TC del FDC al bus de datos
                   ;con lo cual el FDC SIEMPRE asumira que hubo un error con el comando
                   ;es el loader (el programador) el que DEBE ignorar este error!

;como he dicho, por como esta conectado el FDC al CPC, siempre pasara por aqui
;es decir podria ser un error o podria no serlo. El programa debe dilucidarlo.
ld b,a ;recupera S0
bit 3,a ;comprueba flag Not Ready del fdc, si no estaba preparado el fdc bit=1
jr z,FDC_ready ;salta si el flag Not Ready NO esta activo (bit 3 =0)

;por aqui el bit 3 esta a 1, es decir, el FDC devolvio Not Ready del comando READ DATA
;es la unica manera que se tiene para comprobar si es realmente un error o un falso error.
;volvera a intentar leer los datos de ese sector
ld a,#28
call espera_FDC_O_motor_RPM
jr manda_comando_READ_DATA

.FDC_ready
;por aqui todo correcto con ST0
inc hl
ld a,(hl) ;lee ST1
bit 7,a ;End of Cylinder
jr nz,todo_correcto ;si todo correcto b7=1, es decir nz, salta a #026b 
            ;al final de la lectura DE=#0000, con lo cual terminara la lectura de datos desde disco.

;por aqui solo pasa si hubo algun error en la transmision de datos desde la FDD
bit 5,a ;comprueba si  hubo algun error de datos en la transferencia FDC->CPU
jr z,lee_sectores ;si hubo error no actualiza puntero de cantidad de bytes a escribir 
                  ;y vuelve a intentarlo.

.todo_correcto
ld de,(cantidad_bytes_restantes_leer) ;si DE=#0000, en el ret de aqui abajo,
                                          ;al volver a la rutina que llamo a esta subrutina
                                          ;la comprobacion de que se acabo la lectura se activara.
                                          ;apagara el motor de la disquetera y saltara al programa cargado.

ld (cantidad_bytes_quedan_por_intentar_leer),de ;actualiza contador de bytes a escribir y,
                                                    ;volvera a la rutina que llamo a esta subrutina
                                                    ;incrementara track del disco a leer
                                                    ;y volvera a esta rutina para leer el nuevo track.
                                                      
ret

;----------------------------------------------------------------

.configura_crtc_borra_pantalla
ld hl,datos_CRTC ;carga puntero a datos que mandara al CRTC

;aqui abajo de primeras configura el crtc con los siguientes datos
;R1=&28 (Horizontal Displayed) ancho pantalla (160 pixeles en mode 0)
;R2=&2e (Horizontal Sync Position)
;R6=&19 (Vertical Displayed) alto pantalla (200 lineas)
;R7=&1e (Vertical Sync position)

.envia_datos_crtc ;bucle de envio datos al CRTC
ld b,#bc ;puerto CRTC para seleccionar registro a escribir
ld c,(hl) ;lee numero de registro del CRTC en el que queremos meter el dato
inc hl ;mueve puntero de datos
out (c),c ;&bc01 CRTC registro 1 (horizontal displayed)
inc b ;&BD puerto CRTC para escribir dato del registro seleccionado anteriormente
ld c,(hl) ;&28 de primeras
out (c),c
inc hl ;incrementa puntero de datos a mandar a CRTC
bit 7,(hl) ;comprueba si ultimo bit es 1 ya que el valor #ff le indica que pare de escribir
           ;datos al CRTC (lo elige el programador, podria ser cualquier valor que el tenga en cuenta aqui)
jr z,envia_datos_crtc ;si hl<>&FF sigue mandando datos al crtc

;por aqui sigue cuando acaba de configurar CRTC
ld bc,#7f10 ;selecciona BORDE en GA
out (c),c
ld c,#54 ;pone color negro en borde
out (c),c
ld a,#9c
ld bc,#7f00 
out (c),a  ;pone Mode 0, lower ROM disabled, upper ROM disabled
ld bc,#bc0c ;Selecciona registro 12 del CRTC (Start Address High Register)
out (c),c
ld a,#30 ;fija la direccion de memoria de video del cpc
inc b
out (c),a ;pone valor #30 en registro 12 del CRTC
dec b
ld c,#0d ;selecciona registro 13 del CRTC (Start Address Low Register)
out (c),c
inc b
xor a
out (c),a ;pone #valor 00 en el registro 13 del CRTC

ld hl,#c000 ;direccion de pantalla
ld de,#c001
ld (hl),#00
ld bc,#3fff
ldir ;pone toda la pantalla a color negro
ret

.datos_CRTC
db #01 ;registro 1 del CRTC
db #28 ;dato a meter en el registro 1 del CRTC
db #02 ;registro 2 del CRTC
db #2E ;dato a meter en el registro 2 del CRTC
db #06 ;registro 6 del CRTC
db #19 ;dato a meter en el registro 6 del CRTC
db #07 ;registro 7 del CRTC
db #1E ;dato a meter en el registro 7 del CRTC
db #FF ;comprobacion de fin de envio de datos al CRTC


.pon_colorines
;elige el color del pen al reves, desde el 15 al 0
ld b,#10 ;numero colores (16)
ld hl,datos_colores ;direccion de ram donde estan los colores a poner

.bucle_colores
ld a,(hl) ;lee color
push bc ;guarda contador de colores
ld c,b ;carga el contador en c que tambien es el numero de pen a seleccionar
dec c ;decrementa contador para empezar en pen 15 (pen va de 15 a 0)
ld b,#7f ;puerto de acceso al GATE ARRAY
out (c),c ;selecciona pen segun el contador guardado en registro c
ld c,a ;carga en registro c el color a poner
out (c),c ;pone el color
pop bc ;recupera contador de colores
inc hl ;incrementa puntero a siguiente color
djnz bucle_colores ;pone todos los colores
ret


.comando_parametros_READ_DATA
db #09 ;numero de comandos a mandar al FDC
db #46 ;comando read data con parametros elegidos
db #00 ;parametro 1 HEAD NUMBER 0; DRIVE 0
.l02da equ $ + 2
.track_a_mover_cabezal
db #01 ;parametro 2 TRACK NUMBER
db #00 ;parametro 3 HEAD 0
db #01 ;parametro 4 SECTOR NUMBER (1 A 5)
.l02db
db #03 ;parametro 5  DATOS POR SECTOR (&03=1024 bytes por sector)
.l02dc
db #05 ;parametro 6 END OF TRACK (sector 5)
db #35 ;parametro 7 longitud del GAP3
db #ff ;parametro 8 (no encuentro informacion de que significa cuando parametro 5 <> #00

.comando_parametros_fdc_seek
db #03 ;tiene 3 parametros aqui, porque en el tercero llega a la variable track_guardado_sitio_2
db #0F ;comando SEEK (para mover la cabeza al track especificado)
db #00 ;parametro de SEEK que especifica disquetera (00 es disquetera A)
db #00 ;parametro de SEEK para especificar track al que mover cabeza lectora

.datos_formato_disco equ $ + 2
.l02e3
db #01 ;aparenta no usarse nunca
db #08 ;comando SENSE INTERRUPT STATUS
db #03 ;cargara el parametro 6 de READ DATA desde esta posicion a la posicion adecuada del propio comando
.l02e8 equ $ + 2
.tiempo_espera_posicion_cabezal
db #01 ;aqui almacena resultado de restar track al que ir con el que esta situado
       ;cuanto mas grande sea la resta, mas espera a que el FDC consiga situar la cabeza en el track situado
       ;en Livinsgtone 2 siempre da resultado 1 ya que solo lee tracks continuos
db #05
db #08


.track_fisico_fdd
db #00

.direccion_memo_escribir_low_byte
db #00
.direccion_memo_escribir_high_byte
db #00 ;quitara #14 de la high byte de la direccion de ram a escribir
       ;es decir quita 5.120bytes a la direccion de memoria que es lo que ocupa un track entero

.cantidad_bytes_quedan_por_intentar_leer
db #00
db #00

.cantidad_bytes_restantes_leer
db #00
db #00
.datos_colores ;datos de colores (16 colores mode 0)
db &54,&55,&44,&53,&57,&42,&56,&5e
db &43,&4b,&40,&58,&4e,&4c,&5c,&54
