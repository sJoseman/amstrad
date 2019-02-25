 ;------------------------------------------------------------------------
 ;- Explicacion de como funciona un cargador de disco en codigo maquina  -
 ;-         para AMSTRAD CPC (controladora de disco UPD765)              -
 ;- usando como ejemplo el loader principal del juego Cyberbig (Animagic)-
 ;------------------------------------------------------------------------
 ;- Joseman 2019 v1.0                                                    -
 ;------------------------------------------------------------------------
 ;- Agradecimientos                                                      -
 ;- Syx por su paciencia y ayuda ante mis dudas, un genio del asm.       -
 ;- Kevin Thacker por su C.Fuente que me ayudo a entender ciertas cosas  -
 ;------------------------------------------------------------------------

 ;NOTAS
 ;No uso acentos en ningun lado porque Winape los cambia por codigo ASCII de cpc
 
 ;uso indistintamente simbolos & o # para referirme a numero hexadecimal

 ;cuando hablo a nivel bits y el FDC puede suceder que a veces me refiera como
 ;bit 1 a bit 8 o en otros casos como bit 0 a bit 7.
 ;de todas maneras es bastante claro en cada momento, si no fuera asi
 ;avisadme y lo cambio.

 ;NO confundir FDC (Floppy Disc Controler) con FDD (Floppy Disc Drive)
 ;el FDC es el CHIP que comunica al AMSTRAD CPC con la disquetera de 3" (FDD)

 ;La comunicación entre el AMSTRAD CPC y el FDC se produce mediante 3 puertos
 ;Puerto &FA7E - encendido/apagado del motor de las disqueteras.
 ;Puerto &FB7E - MAIN STATUS REGISTER (solo lectura)
 ;Puerto &FB7F - DATA REGISTER 


 ;empecemos pues!

  org #03e8 ;origen en memoria RAM del cargador
  run $

  di ;deshabilita interrupciones ya que va a hacer un ldir a pantalla
  
  ld sp,#bfff ;es una tonteria que ponga el sp en &BFFF y no en &c000
              ;el stack pointer crece hacia abajo, con lo cual malgasta 1 byte

  ld hl,#c000 ;inicio de memoria de pantalla
  ld de,#c001 ;inicio de memoria de pantalla +1
  ld bc,#3fff ;tamano de memoria de pantalla -1
  ld (hl),#00 ;carga todos los pixeles a pen 0 (que posteriormente pondra a color negro)
  ldir ;rellena toda la memoria de pantalla con &00 (la borra)


  ld a,#00 ;elige mode
  call elige_mode_roms_state ;mode 0, ROMS lower & upper disabled.

  ld hl,definicion_colores ;puntero a colores hardware
  call pon_colores ;asigna colores


  ;---------ZONA DE CARGA DE DATOS------------------

  ;OJO, no confundir tracks con sectores
  ;a partir del track 16, RENOMBRARON los sectores y se llaman [#11-#19] [no C1-C9, como seria normal]
  ;y puede inducir a error.

  ld hl,#c000 ;direccion RAM de carga de datos (la primera es la pantalla de presentación)
  ld (direccion_carga),hl ;guarda la direccion

  ld hl,#4000 ;tamano de la carga.
  ld (tamano_carga),hl

  ld a,#10 ;track inicial de los datos (track 16 en decimal)
  ld (track),a
  call lee_bloque_datos

  ld hl,#05dc ;siguiente carga
              ;#05dc + #9e34-1=#a40f

  ld (direccion_carga),hl
  ld hl,#9e34 ;tamano
  ld (tamano_carga),hl
  ld a,#16 ;track 22
  ld (track),a
  call lee_bloque_datos


  ld hl,#a410 ;siguiente carga
  ld (direccion_carga),hl
  ld hl,#12c6 ;#A410+#12C6-1=#B6D5
  ld (tamano_carga),hl
  ld a,#14 ;track 20
  ld (track),a
  call lee_bloque_datos

  jp #070c ;acabada la carga, salta al codigo del propio juego.


lee_bloque_datos

  call enciende_motor_disquetera ;enciende el motor y espera a rotacion estable del disco.

  ;ahora necesitamos recalibrar la disquetera
  ;esto significa ordenar a la disquetera que mueva el cabezal al TRACK0
  ;la disquetera por si sola NO sabe en que track se encuentra el cabezal.
  ;la controladora (FDC) en cambio tiene un variable interna para saber en que TRACK esta.
  ;entonces necesitamos hacer coincidir la cabeza de la disquetera con esta variable del FDC
  ;esto se consigue con la orden RECALIBRATE, ya que manda la cabeza lectora al TRACK0
  ;y resetea esta variable para que, disquetera y FDC coincidan en track actual.

  call recalibrate_fdc ;mandamos cabeza a TRACK0
                       ;NOTA, recalibra la disquetera principal A:
                       ;es decir, el juego no funciona desde disquetera B:

  ld a,(track) ;track &10 de primeras

  ;ahora guarda track actual en 2 variables que situa en la zona de comandos para mandar al FDC
  ld (track_actual),a 
  ld (track_mover_cabeza),a 

  call seek_track_fdc ;vamos a mover cabeza lectora al track especificado en A.

  ld a,#11 ;sector inicial, OJO, NO ESTAN NUMERADOS STANDARD (C1-C9)
           ;SINO #11-#19

  ld (sector_actual_leyendose),a  ;guarda el sector en 2 sitios diferentes para facilitar el pase de parametros
  ld (sector_final_a_leer),a ;al fdc

  ld hl,(direccion_carga) ;recupera punteros
  ld de,(tamano_carga)

  call lee_tracks_sectores ;pantalla de carga (por ej.) empieza en track &10 sector &11
                           ;dentro de esta funcion incrementa track cuando recorre sectores #11-#19
                           ;hasta que tamano_carga llegue a 0

  ;por aqui ha leido todos los datos que se le mandaron leer en cada llamada.

  call apaga_motor_disquetera 

  ret ;vuelve a la zona inicial del loader donde se le manda cargar los tramos de datos del juego.

lee_tracks_sectores

  ;Antes de nada explicar como funciona la comunicacion del Amstrad CPC con el FDC (NEC UPD765)
  ;esta comunicacion consiste en TRES fases 
  ;(excepto en algunos comandos como SEEK y RECALIBRATE  que no tienen EXECUTION-PHASE ni RESULT-PHASE)
  ;FASE 1 o "Command-Phase", donde se le envía el comando al FDC y sus parametros (pueden ser varios bytes)
  ;FASE 2 o "Execution-Phase" donde se leen/escriben los datos (bytes) desde o hacia la disquetera
  ;FASE 3 o "Result-Phase" donde el FDC nos indica el resultado de la operacion usando 4 registros de estado y,
                           ;otros bytes que variaran segun el comando mandado al FDC.

  ;Tanto la longitud de los parametros como de los result bytes devueltos por el FDC VARIAN de un comando a otro.
  ;Es necesario consultar la documentacion tecnica del FDC para saber estas diferentes situaciones.


  call lee_sector ;cada sector son &200 bytes, 512 bytes de datos en decimal.
		  ;cada track tiene 9 sectores
		  ;9x512bytes= 4608 bytes en cada track.
                  ;la pantalla de carga por ejemplo
                  ;ocupa 4 tracks, desde el track #10 al #13 (este ultimo no se lee entero, solo 5 sectores)
                  ;3x4608=13.824bytes
		              ;1x3072= 2.560bytes (5 sectores x 512=2560bytes)
                  ;       ------------
                  ;        16.384bytes, que es exactamente lo que ocupa una pantalla de carga en memoria

  ;por aqui vuelve al leer 1 sector y avanzar al siguiente, si llego al sector final, entonces
  ;viene incrementado el track y puesto de nuevo sector #11.

  ;aqui abajo mira que no hayamos acabado la carga, 
  ;DE se decrementara y llegara 0 dentro de una subfuncion de lee_sector

  ld a,d ;si DE=0, acaba la carga de los datos y vuelve a despues de la llamada a lee_tracks_sectores
  or e
  jr nz,lee_tracks_sectores 
  ret ;vuelve a funcion lee_bloque_datos DESPUES DE LLAMADA call lee_tracks_sectores

lee_sector 

  ;informacion importante
  ;Un track tiene el siguiente formato en un disco de CPC

  ; id field
  ; data field
  ;
  ; id field
  ; data field
  ;
  ; id field
  ; data field
  ; [...]

  ;debemos darle al FDC los valores del ID field que queremos leer.
  ;el ID field consta de 4bytes que seran comparados con los del disco.
  ;una vez que el FDC encuentra ese sector con ese ID entonces leera
  ;los datos. si no encuentra el ID field, el FDC reportara un error.

  ;ID-FIELD (4bytes)
  ;C es cilindro (track) a leer.
  ;H numero logico de cabeza fisica (recuerda en CPC solo una)
  ;R numero de sector que sera leido.
  ;N tamano del sector a leer, un valor &2 significa 512bytes de tamano.


;COMMAND-PHASE de READ DELETED DATA

  push hl ;hl trae direccion de memoria donde se meteran los datos leidos de la disquetera
  push de ;de es el tamano de los datos a leer
  call select_read_deleted_data ;manda al FDC el comando READ DELETED DATA (Command-Phase)
                                
  ;el comando READ DELETED DATA (al igual que READ SECTOR) consta de 8 bytes de parametros.
  ;parametro 1 HU ;disquetera y cara del disco que efectuara la lectura.
                  ;como en CPC solo tenemos un cabezal de lectura, solo tenemos 1 cara.
  ;parametro 2 TR ;track-ID (numero de track fisico del disco que vamos a leer)
  ;parametro 3 HD ;head-ID, CABEZA lectora que leera (recuerda en cpc solo una)
  ;parametro 4 SC ;sector que queremos leer
  ;parametro 5 SZ ;tamano de dicho sector, valor 2 = 512bytes de tamano
  ;parametro 6 LS ;sector final a leer, debe coincidir con SC para leer 1 solo sector.
  ;parametro 7 GP ;tamano GAP, este valor determina el numero en BYTES de separacion entre
                  ;sectores, para que a la controladora le dee tiempo a procesar correctamente
                  ;los datos entre sectores
                  ;este parametro por defecto en cpc es &2a, en cyberbig usan &2c
                  
  ;parametro 8 SL ;SectorLen, (si sector size = 0) se usa este parametro para indicar
                  ;tamano de los datos a leer en el sector (el valor por defecto es &ff)



;EXECUTION-PHASE de READ DELETED DATA  

  ;ok a esta altura la cabeza lectora esta situada en el track y sector especificados para leer datos
  ;y el FDC nos ha informado que la operacion SEEK (mover cabeza) se ha completado correctamente
  ;tambien se ha especificado que vamos a leer una zona con datos borrados (una simple marca ID)
  

  ld bc,#fb7e ;Main Status Register del FDC (lo usa para preguntarle a la FDC si esta lista para mandar 
              ;el siguiente byte)

  call lee_datos_desde_disco ;comprobamos EXECUTION-PHASE del comando READ DELETED DATA
                             ;es decir, leemos los datos del propio juego que el FDC nos va poniendo
                             ;en su data register. (puerto &FB7F)

  ;por aqui vuelve de un RET Z al acabar EXECUTION-PHASE en lee_datos_desde_disco
  ;eso pasara por cada sector leido (512bytes por sector)

;RESULT-PHASE de READ DELETED DATA

  ;Ahora toca leer los resultados de la operacion (7 bytes en READ DELETED DATA)
  ;si algo ha salido mal, salta a funcion error_fdc que teoricamente deberia reintentar la carga de ese sector
  ;pero tiene un bug y el CPC re resetea.

  call lee_resultphase_FDC

  ;ahora consulta los resultados
  ;En comando READ DELETED DATA tenemos estos resultados almacenados (la primera vez)
  ;el valor que toma S0 es &40 (%01000000)
  ;el valor que toma S1 es &80 (%10000000)
  ;el valor que toma S2 es &00 (%00000000)
  ;el valor que toma TR es &10 (correcto track 16 la primera vez)
  ;el valor que toma HD es &00 (correcto, cabeza 0)
  ;el valor que toma LS es &11 (correcto, sector &11 es el primero que leemos de inicio)
  ;el valor que toma SZ es &02 (correcto, 512bytes por sector)

  push hl
  ld hl,result_phase_bytes
  ld a,(hl) ;Status register 0 en comando READ DELETED DATA

  cp #40  ;OJO, ESTO QUE VIENE AHORA ES POR LA MANERA ESPECIAL EN QUE AMSTRAD
          ;COLOCO EL FDC EN EL CPC. El UPD765 tiene un pin llamado
          ;TC (terminal count signal), en el amstrad cpc NO ESTA CONECTADO ese pin.
          ;En teoria se debe enviar una senal TC al FDC despues de un comando de lectura/escritura.
          ;como es imposible enviar esa senal al FDC desde el CPC, el controlador de disco
          ;asume que el comando HA FALLADO. por este motivo se activa el bit6 del STATUS REGISTER 0
          ;y el bit 7 en el STATUS REGISTER 1.
          ;es deber de nuestro programa IGNORAR este mensaje de fallo.
          ;ademas de que es imposible para nuestro programa confirmar una 
          ;operacion correcta de lectura/escritura. 

          ;como se puede ver aqui el loader compara con &40 (%01000000) que es el bit6 de SR0
          ;confirma el error y lo IGNORA. si a=&40 NO salta a error_fdc
  jr nz,error_fdc 

  inc hl 
  ld a,(hl) ;STATUS REGISTER 1 en comando READ DELETED DATA
  cp #80 ;%10000000 ;se puede comprobar que aqui comprueba el bit7 de SR1
         ;demostrando el comportamiento raro que adopta el FDC con el CPC al no tener el pin TC conectado.
         ;se puede ver tambien como IGNORA este error que manda el FDC al CPC.
  jr nz,error_fdc

  
  inc hl
  ld a,(hl) ;STATUS REGISTER 2
            ;este registro controla varios errores de lectura/escritura y DEBE estar a &00
  and a ;compara con &00 de manera decorosa.
  jr nz,error_fdc ;si no es &00 es que algo ha fallado al leer desde disco
                  
  ;por aqui no ha habido ningun error

  pop hl ;puntero a direccion de ram donde escribiremos siguiente sector
  pop bc ;recupera tamano de datos, lo debe quitar de la pila por haberse quedado sin uso
  pop bc ;direccion original de inicio de datos en RAM
  ld a,(sector_actual_leyendose)
  cp #19 ;comprueba que no se haya leido el SECTOR final de cada track, #19 (25 en decimal)
  jr z,avanza_track ;si se ha leido ultimo sector, avanza track
  inc a ;si no, simplemente incrementa sector

guarda_sector
  ld (sector_actual_leyendose),a ;siempre coinciden sector actual con sector final.
  ld (sector_final_a_leer),a
  ret ;vuelve a lee_tracks_sectores DESPUES de llamada a esta funcion.
      ;comparara que no se hayan acabado los datos para leer
      ;y volvera a llamar a esta funcion para leer otro sector.

avanza_track
  ld a,(track_actual)
  inc a
  ld (track_actual),a
  ld (track_mover_cabeza),a
  call seek_track_fdc ;mandamos comando SEEK TRACK para posicionar cabeza lectora en nuevo TRACK.

  ld a,#11 ;ponemos primer sector del nuevo track
  jr guarda_sector ;guardamos el sector y retornamos a rutina que nos llamo

error_fdc ;por aqui ha fallado la lectura de 1 sector en el disquet
  ld hl,reintentos_lectura_sector
  dec (hl)
  pop de ;recupera valor metido en stack que ya no necesita (siguiente tramo de memoria a escribir)
  pop de ;mete en DE la longiud de los datos que quedaban por meter antes del error
  pop hl ;recupera la zona de memoria en la que iba a escribir datos antes del error.
  jr nz,lee_sector ;mientras la variable "reintentos" no llegue a 0 intenta volver a leer el sector
   ;por aqui llega cuando "reintentos_lectura_sector" llega a 0
  ld hl,reintentos_lectura_sector
  ld (hl),#03 ;vuelve a inicializar la variable a 3 intentos.
  ld sp,(stack_pointer) ;BUG EN CARGADOR
                        ;se olvidaron de guardar una zona de memoria para el STACK valida,
                        ;aqui colocan el SP en &0000, con lo cual decrecera por
                        ;&FFFF (zona de pantalla) hasta que se corrompa y el CPC se resetee.
  jp lee_bloque_datos 

;----------------------------------------------------------------------

;llamadas que envian comandos y parametros al FDC

select_read_deleted_data
  ;indica al FDC que va a leer un sector con datos borrados
  ;pese al nombre, no significa que en ese sector haya datos "borrados"
  ;el FLAG de borrado (DAM) es simplemente un ID bit.
  ;Los datos simplemente tienen ese FLAG activado. hay que tenerlo en cuenta
  ;a la hora de leerlos. (es una especie de proteccion anticopia del Cyberbig)
  ld bc,parametros_fdc_readDdata
  jr elegido_parametros 

recalibrate_fdc
  ld bc,parametros_fdc_recalibrate 
  jr elegido_parametros

seek_track_fdc
  ld bc,parametros_fdc_seek

;OJO los comandos RECALIBRATE y SEEK no devuelve bytes de resultado directamente
;es decir NO TIENEN "EXECUTION-PHASE" ni "RESULT-PHASE"
;en estes 2 casos, el programa debe esperar hasta que el Main Status Register
;SENALIZA que el comando ha sido completado
;ENTONCES
;se tiene que mandar un "Sense Interrupt State" para "terminar" el comando en si.


elegido_parametros
  
  push hl
  ld l,c
  ld h,b

  ;leemos primer parametro que es el numero de comandos a mandar al FDC
  ld b,(hl) ;lo metemos en b ya que despues lo usaremos como contador
  ld c,b ;guarda B en C, porque mas abajo lo recupera para comparar con A
         ;y saber que estamos en el comando READ DELETED DATA
         
bucle_comandos_fdc

  ;--------------------
  ;FASE "Command-Phase"
  ;--------------------

  ;IMPORTANTE
  ;el comando y numero de parametro a enviar al FDC VARIA según el propio comando.

  inc hl ;mueve puntero a siguiente dato
  ld a,(hl) ;lee comando o parametro a mandar al FDC
	push bc
  call manda_comandoOparametro_FDC ;manda comando o parametro al FDC

  pop bc ;recupera numero de comandos a mandar
  djnz bucle_comandos_fdc ;decrementa b (numero de comandos a mandar al FDC)
                          ;y vuelve arriba para hacer bucle

  ;por aqui hemos acabado de mandar el comando y todos los parametros al FDC
  ;recuerda, el numero de parametros varia segun el comando que mandemos

  pop hl

  ld a,c ;carga valor original de B que guardamos en C, solo le interesa saber que estamos en la
         ;parte de cargar datos (READ DELETED DATA)
  cp #09 ;si es asi (&9), se vuelve, no hace los seek de aqui abajo (ya se hicieron en su momento).
  
  ret z ;siempre se retorna de esta rutina excepto en la parte de lectura de datos.

  ;ok, por aqui solo pasamos con comandos RECALIBRATE y SEEK
  ;al haber ejecutado un comando que implica un seek (movimiento de cabeza lectora)
  ;necesitamos saber si el seek ha sido correcto y completado
  ;como estos comandos no tienen RESULT-PHASE que podamos consultar, debemos
  ;enviar el comando SENSE INTERRUP STATUS al FDC, que le ordena "terminar" el comando SEEK.
  ;este comando nos devolvera 1 solo byte con el resultado (Status Register 3), lo consultaremos
  ;y si no es correcto, volveremos a intentarlo hasta que lo sea.
  ;esta funcion lo hace "espera_seek_correcto"


espera_seek_correcto 

;FASE "COMMAND-PHASE" de SENSE INTERRUP STATUS

  ld a,#08 ;a= %00001000 ;comando SENSE INTERRUP STATUS
	         ;al acabar una instruccion que implique una SEEK operation, hay que comprobar este parametro
  call manda_comandoOparametro_FDC ;manda el parametro


;FASE "RESULT-PHASE" de comando SENSE INTERRUP STATUS, seek y recalibrate NO tienen.

  call lee_resultphase_FDC ;leemos el resultado del comando que nos devuelve el FDC

  
  ;despues de leer el resultado que nos ha mandado el FDC
  ;(que se ha almacenado en nuestra zona definida para result_phase_bytes (7bytes))
  ;en el caso de SENSE INTERRUP STATUS nos devuelve 1 byte (el Status Register 3)
  
  ;procedemos a consultarlo
  ld a,(result_phase_bytes) ;leemos lo que nos devolvio el FDC (Status Register 3 en este caso)
  bit 5,a ;nos interesamos por el bit 5, que nos indica que la FDD esta en modo READY
    jr z,espera_seek_correcto ;si no es así, realizamos la consulta otra vez hasta
                              ;asegurarnos de que el comando se completo bien y la FDD esta lista.
  
  ret ;por aqui la FDD nos ha respondido que esta preparada y todo correcto. Nos volvemos.


;-----------------------------  

manda_comandoOparametro_FDC

;por aqui seguimos en COMMAND-PHASE


  ld bc,#fb7e ;Main Status Register del FDC
  push af ;guarda el comando o parametro en stack


  ;alguna documentacion del FDC dice que tiene que haber un espacio de tiempo
  ;entre comandos, en la practica parece que no se necesita en el CPC.
  ;pero se suele poner por compatibilidad.

  ;;aqui abajo se ve la perdida de tiempo implementada en este loader
  ld a,#05
perdemos_tiempo
  dec a
  nop
  jr nz,perdemos_tiempo

  ;ahora esperamos a que el FDC nos diga que esta listo para recibir o
  ;enviar datos
esperando_RQM
  in a,(c) ;lee del main status register del fdc
  add a ;aqui mira si el bit 8 de A esta a 1.
        ;es decir, si el bit 8 del Main Status Register (RQM) esta activado
        ;si es asi, el FDC nos esta diciendo que esta listo para enviar o
        ;recibir datos
        ;para detectar esta situacion suma registro A consigo mismo
        ;si bit 8=1 entonces la suma desborda y carry se activa.
  jr nc,esperando_RQM

  add a
  jr nc,listo_para_mandar ;entiendo que nunca sera C
  ;no pasa nunca por aqui
  pop af 
  ret

  ;ok, esta listo, le mandamos entonces comando o parametro
listo_para_mandar
  pop af
  inc c ;bc=&FB7F Data Register del FDC
  out (c),a ;mandamos comando o parametro (el primero siempre es un comando)
  dec c ;volvemos valor de BC para que apunte a Main Status Register del FDC
  ret
;------------------------------------------------------------------------------------


escribe_dato_en_ram ;a esta rutina se llega desde lee_datos_desde_disco

  ;recuerda, estamos en EXECUTION-PHASE
  ;nos movemos al puerto &fb7f (DATA REGISTER)
  inc c ;nos movemos al Data Register que tiene el dato preparado para leer
        ;y que escribiremos en RAM
  in a,(c)
  ld (hl),a ;escribimos el dato en RAM
  dec c ;nos volvemos al Main Status Register
  inc hl ;incrementamos puntero en RAM
  dec de ;decrementamos contador de tamano de datos.
  
  ;continuamos otra vez por leer_datos_desde_disco
  ;byte a byte hasta acabar la carga.

lee_datos_desde_disco

;por aqui se va a pasar por cada BYTE que se lea del sector actual.
;primero le pregunta a la FDC si esta lista para enviar el siguiente byte
;estamos posicionados en puerto &fb7e que es el Main Status Register del FDC

;el flag Parity se usa para comprobar que los bits puestos a 1 de A son pares en una operacion
;de I/O con un periferico
;si A=&50 (%01010000) buclea
;si A=#70 (%01110000) buclea
;si A=#F0 (%11110000) NO buclea
;si A=#D0 (%11010000),NO buclea (execution-phase acabada)

;ACLARAR ESTO CON MAURI, NO LO ENTIENDO, A VECES SALTA A VECES NO AUN SIENDO PARITY EN LOS 2

bucle_espera_FDD
  ;aqui estamos leyendo del puerto &fb7e que es el Main Status Register del FDC
  in a,(c)
  jp p,bucle_espera_FDD ;esperamos a que el data register nos mande la informacion
                                       ;(bit 8 a 1), por eso usa el flag P para dilucidar

  ;por aqui la informacion del MAIN STATUS REGISTER del fdc esta en A
  and #20 ;a=%00100000 ;mira si AUN estamos en EXECUTION-PHASE
          ;si es asi, significa que el FDC nos tiene listo 1byte leido del disco
          ;en su puerto &fb7f DATA REGISTER

  
  ret z ;si da Z es porque se cabo la EXECUTION-PHASE, es decir, ya no hay mas datos que leer
        ;en el sector que le mandamos posicionarse, volvera a esta rutina leyendo el siguiente sector.


  ;entonces llegamos aqui con el FDC informandonos que tiene listo 1 byte para su lectura en el puerto
  ;&fb7f DATA REGISTER

  ;aqui abajo mira que DE no haya llegado a 0, lo mira en tramos de byte
  ;es decir por aqui se cumple el Z en el ultimo sector de carga 
  ;de bloque de datos actual (que seguramente no se lea entero)

  ;como curiosidad decir que en la pantalla de carga jamas se cumple la condicion de=&0000
  ;cuando de=&0001 (en pantalla de carga) la funcion retornara por el "and &20" de aqui arriba.

  ;curiosamente con la carga del segundo y tercer bloque de datos pasa diferente, 
  ;se cumple varias veces de=&00000, y buclea varias veces (mas de 100) sacando datos
  ;del data register (que no usa) hasta que se cumple el "and &20" de aqui arriba.

  ;basicamente SOLO se sale de esta rutina si el FDC nos indica que la EXECUTION-PHASE esta acabada.

  ld a,d ;de tiene el tamano que ocuparan los datos en memoria
  or e 
  jp nz,escribe_dato_en_ram ;aun no hemos acabado...pues escribimos en RAM

  ;por aqui se ha leido todos los datos que se especificaron en tamano (DE)
  ;es decir un bloque de datos del juego (sea pantalla de carga o como ellos hayan dispuesto)
  ;como he dicho NO siempre se cumple de=&0000 (pantalla de carga)

  inc c ;nos posicionamos en DATA REGISTER del FDC
  in a,(c)
  dec c ;nos posicionamos en MAIN STATUS REGISTER
  jp lee_datos_desde_disco ;salta a lee_datos, pero no para leer 
                           ;sino para consultar MAIN STATUS REGISTER y que le informe del final
                           ;de EXECUTION-PHASE

;----------------------------------------------------------------------------------------------  

lee_resultphase_FDC

;-------------------
;FASE "RESULT-PHASE"
;-------------------

  push hl
  ld hl,result_phase_bytes ;zona donde guardaremos los bytes de resultado que nos envia
                           ;el MAIN DATA REGISTER del FDC despues de acabar la EXECUTION-PHASE

;por aqui abajo pasara por cada RESULT BYTE que recibamos del FDC
espera_DR_ready

  ;consultamos MAIN STATUS REGISTER para que nos diga si el DATA REGISTER 
  ;tiene los resultados del comando actual.

  in a,(c) ;bc=#FB7E, estamos leyendo del Main Status Register
  
  cp #c0 ;se interesa por el bit 8 y el bit 7 (#c0=%11000000)
	 ;si A >= &c0 significa que POR LO MENOS b7 y b8 estan activados. (y es lo unico que le importa)
         ;esta preguntando si el Data Register del fdc esta listo para mandar datos a la CPU
  jr c,espera_DR_ready  ;si no lo esta, espera a que lo este.

  inc c ;bc=#FB7F, una vez preparado el data register para comunicarse con nosotros, vamos a ello.
  in a,(c) ;leemos el resultado del comando mandado

  ;los valores que coje registro A en el RESULT-PHASE varian en numero y significado
  ;segun comando al fdc ejecutado.
  ;por ejemplo el comando READ DELETED DATA recibe 7bytes
  ;S0 (status register 0)
  ;S1 (status register 1)
  ;S2 (status register 2)
  ;TR (TRACK ID)
  ;HD (HEAD ID)
  ;LS (LAST SECTOR ID)
  ;SZ (SECTOR SIZE)
 
  ;generalmente los datos interesantes estan en los STATUS REGISTER

  ;En READ DELETED DATA
  ;el valor que toma S0 es &40 (%01000000)
  ;el valor que toma S1 es &80 (%10000000)
  ;el valor que toma S2 es &00 (%00000000)
  ;el valor que toma TR es &10 (correcto track 16 la primera vez)
  ;el valor que toma HD es &00 (correcto, cabeza 0)
  ;el valor que toma LS es &11 (correcto, sector &11 es el primero que leemos de inicio)
  ;el valor que toma SZ es &02 (correcto, 512bytes por sector)

  ;OJO, en esta funcion solo coge los valores
  ;que hacer con ellos lo decide al RETornar de esta funcion.


  ld (hl),a ;lo guardamos result_phase_bytes
            ;para consultarlo mas tarde (al finalizar esta funcion)

  dec c ;volvemos a Main Status Register
  inc hl ;incrementamos puntero result_phase_bytes para seguir guardando bytes de resultado.


  ;alguna documentacion del FDC dice que tiene que haber un espacio de tiempo
  ;entre comandos, en la practica parece que no se necesita en el CPC.
  ;pero se suele poner por compatibilidad.

  ;;aqui abajo se ve la perdida de tiempo implementada en este loader
  ld a,#05

esperate
  dec a
  nop
  jr nz,esperate

  in a,(c) ;leemos MAIN STATUS REGISTER
  and #10 ;(%00010000) consulta bit 4, para ver si el FDC nos sigue enviando datos de resultado
          ;o ya a acabado.

  jr nz,espera_DR_ready ;si nos sigue enviando datos, entonces repetimos bucle y 
                        ;seguimos almacenando los bytes de resultado en variable
                        ;result_phase_bytes incrementando el puntero de cada vez

  ;por aqui pasamos cuando el FDC nos dice que ya ha acabado de mandarnos los datos de resultado.
  ;tenemos dichos datos que nos ha enviado el FDC mediante el DATA REGISTER
  ;en result_phase_bytes

  pop hl
  ret ;consultara los result_phase_bytes fuera de aqui ya.

;--------------------------------------------------------------------------------------------------------  

enciende_motor_disquetera
  ld a,#01 ;como anecdota comentar que se encienden TODOS los motores de las disqueteras conectadas al CPC.
  jr motor_fdc_start_stop
apaga_motor_disquetera
  xor a

motor_fdc_start_stop
  ld bc,#fa7e
  out (c),a

  ;ahora se necesita ESPERAR a que el motor haga girar el disco a una velocidad estable
  
  ;bucle para perder tiempo y esperar rotacion optima de disco.
  ld hl,#03c9
bucle_espera
  djnz bucle_espera
  dec hl
  ld a,h
  or l
  jr nz,bucle_espera
  ret

;---------------------------------------------------------------------------------------------------


elige_mode_roms_state
  exx ;aqui usa el registro espejo BC, dando por sentado que esta correctamente inicializado
      ;es decir, asume que no ha sido modificado por algun motivo ajeno al firmware
      ;BC tiene ahora el valor &7F8D (cargado por el propio firmware)

  res 1,c ;pone a 0 bit 1 de BC
  res 0,c ;pone a 0 bit 0 de BC
          ;es decir transforma de manera enrevesada BC en #7F8C (apunta al GATE ARRAY)

  or c ;agrega registro C en A (que tenia el valor del MODE a poner)
  ld c,a ;esto es una tonteria, no le hace falta cargar C con A, si aqui abajo hiciera un out (c),a
  out (c),c ;pone mode 0, lower rom & upper rom disabled
  exx ;vuelve a los registros normales
  ret

;--------------------------------------------------------------------------------------------------------  

pon_colores
  ld bc,#7f00 ;Gate Array funcion select pen
bucle_colores
  out (c),c ;elegimos pen a cambiar color
  ld a,(hl) ;cogemos color hardware
  inc hl ;incrementamos puntero de colores
  out (c),a ;ponemos color en el pen elegido
  inc c ;incrementa pen, va de 00 a 15 (16 colores)
        ;cuando C toma valor 16 es porque 16 seria el color de borde (7f10)
  ld a,c
  cp #11 ;si a = 17 entonces fuera del bucle.
  jr nz,bucle_colores
  ret

;zona de variables

definicion_colores
  db &54 ;NEGRO
  db &44 ;AZUL
  db &55 ;AZUL BRILLANTE
  db &57 ;AZUL CIELO
  db &53 ;CYAN BRILLANTE
  db &4b ;BLANCO BRILLANTE
  db &41 ;GRIS
  db &5c ;ROJO
  db &4c ;ROJO BRILLANTE
  db &4e ;NARANJA
  db &4a ;AMARILLO BRILLANTE
  db &56 ;VERDE
  db &5a ;VERDE LIMA
  db &58 ;MAGENTA
  db &4d ;MAGENTA BRILLANTE
  db &4f ;MAGENTA PASTEL
  db &54 ;NEGRO (para borde)

reintentos_lectura_sector
  db &03
parametros_fdc_readDdata
  db &09 ;9 parametros
  db &4c ;MFM mode selected y READ DELETED DATA (parametro 1)
  db &0  ;disquetera (paremetro 2)
track_actual
  db &01 ;track a leer (parametro 3)

  db &00 ;cabeza lectora que efectuara la lectura (en CPC solo tenemos una) (parametro 4)

sector_actual_leyendose
  db &11 ;;; numero de sector a leer (parametro 5)

  db &02 ;;; tamano del sector que queremos leer (parametro 6)
         ;; ESTE PARAMETRO DETERMINA EL TAMANO DE LOS DATOS EN EL SECTOR A LEER.
         ;; 2 = 512 byte sector(parametro 6)
sector_final_a_leer
  db &11 ;Sector final a leer (debe ser el mismo a inicial para lectura de 1 sector) (parametro 7)

  db &2c ;GAP (parametro 8)
  db &ff ;SectorLen, (si sector size = 0) por defecto &ff (parametro 9)

parametros_fdc_recalibrate
  db &02 ;2 parametros
  db &07 ;comando FDC RECALIBRATE
  db &00 ;recalibra disquetera A (&00)
parametros_fdc_seek
  db &03 ;tiene 3 parametros aqui, porque en el tercero llega a la variable track_guardado_sitio_2
  db &0f ;comando SEEK (para mover la cabeza al track especificado)
  db &00 ;parametro de SEEK que especifica disquetera (00 es disquetera A)
track_mover_cabeza
  db &01 ;parametro de SEEK para especificar track al que mover cabeza lectora

result_phase_bytes ;status_registers_fdc
  ;aqui define y almacena los 7 posibles bytes que retorne algun comando del FDC
  ;en concreto read track

  db &44
  db &45
  db &20
  db &4c
  db &4f  
  db &53 
  db &20 

stack_pointer
db &00
db &00

direccion_carga
  db &00
  db &00

tamano_carga
  db &00
  db &00

track
  db &00
