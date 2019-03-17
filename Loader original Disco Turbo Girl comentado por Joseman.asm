
	;-------------------------------------
	;loader original TURBO GIRL (Dinamic)
	;comentado por Joseman, Marzo 2019
	;-------------------------------------

	;Este loader es igual al del SATAN, solo que al no haber menu de eleccion de partes
	;actua de forma un poco diferente en algunas zonas.
	
	;los parametros de carga los obtiene de la lectura de 1 sector del disco
	;que guardara &0297 (Satan lo hacia en &0100)
	;esto demuestra que este loader se usa en otros juegos
	;de Dinamic simplemente cambiandole esos parametros.


	org #0100 ;origen del loader
    	      	  ;todos los loaders que cargan con CPM se inician en esta direccion.
  		  ;el loader de T.Girl ocupa desde &0100 a &0296 (407 bytes)
          	  ;la carga de los loaders de CPM implican 512bytes con lo cual desde el byte
          	  ;407 al byte 512 se rellena en el caso del loader del T.Girl con
          	  ;el valor &05  que es la marca "vacio" en los discos de AMSDOS.
	run $


	ld hl,direccion_ejecutar ;parametro para MC BOOT PROGRAM (firmware)
            	                 ;direccion_ejecutar es la direccion donde MC BOOT PROGRAM saltara.
	ld c,#ff;C es otro parametro, es la ROM a donde queremos saltar.
    	         ;#FF no salta a ninguna ROM, sigue en RAM principal. 
	jp #bd16 ;ejecutamos la instruccion de firmware MC BOOT PROGRAM
    	         ;como el parametro pasado direccion_ejecutar es JUSTO aqui debajo, sigue por aqui.
                 ;que hagan esto es un pequeno truco para deshabilitar posibles ROMS no deseadas
         	 ;en el sistema.
 		 ;MC BOOT PROGRAM hace lo siguiente
 		 ;1- Resetea el sonido (SOUND RESET)
       		 ;2- Limpia todas las colas de eventos y listado de timers (KL CHOKE OFF)
                 ;3- Resetea el manager de teclado limpiando el buffer de teclas pulsadas (KM RESET)
      		 ;4- Resetea el CRTC a modo inicial de texto (TXT RESET)
                 ;5- Resetea las tintas y las llamadas a las rutinas SCREEN (SCR RESET)
		 ;a mayores RESETEA EL FIRMWARE (y eso es lo que le interesa al creador del loader).
       		 ;ya que las funciones de disco DEJAN de estar activas y hay que reiniciarlas
       		 ;esto se lleva por delante a cualquier ROM indeseable que pudiera estar activa en el sistema
       		 ;ya sean copiadores, ensambladores, debuggers, etc.

direccion_ejecutar ;recuerda, salta por aqui despues de MC BOOT PROGRAM

	ld c,#07 ;ROM 7 (AMSDOS)
	call #bcce ;llamada a firmware (KL INIT BACK)reinicia AMSDOS
           	   ;como se puede ver SOLO activa AMSDOS como ROM necesaria para seguir leyendo de disco.
	ld c,#07 ;ROM 7 (AMSDOS)
	call #b90f ;llamada a firmware KL ROM SELECT
                   ;esto hace que la rom de AMSDOS sea accesible como UPPER ROM desde este loader.
        	   ;es decir es accesible en el rango de memoria principal &C000-&FFFF
	   	   ;lo hacen para poder usar las rutinas de AMSDOS para cargar el juego.

	ld hl,&0297 ;direccion de memoria donde se meteran los datos del sector a leer
                    ;justo despues del loader.
	ld de,#0042 ;registro D, track a leer (00 en este caso).
            	    ;registro E, SECTOR ID (EL track 0 tiene estos SECTOR ID 41,&42,&43,&44,&45,&46,&47,&48,&49)
            	    ;es decir, lee el sector 1 (&42)
	ld b,#01 ;numero de sectores a leer ;en este caso solo lee 1 (512bytes de datos)
	call lee_datos_disco ;lee los parametros del loader que metera en &0297

	ld ix,(#be42);Direccion &BE42 es direccion de memoria a Drive A Extended Disc Parameter Block (XDPB)
	              ;este XDPB son 25 bytes donde esta la configuracion actual usandose de la disquetera
                      ;IX=&A890 (que es donde empieza XDPB)

	ld (ix+#14),#03;escribe en el byte 21 del XDPB (sector size)
                        ;&03=1024bytes de tamano por sector
			;a partir de ahora todos los sectores leidos tendran un tamnano de 1024bytes

	ld (ix+#18),#60 ;Auto select flag (&00=Auto select; &FF= don't alter)

	ld a,#ff
	ld (#be78),a ;desactiva los mensajes de error de lectura de disco  (&00 activa, &ff desactiva)

	ld a,#06 ;a partir del track 1 cambian los sector ID en el disco.
         	 ;nueva nomenclatura para los sector ID (&01,&02,&03,&04,&05)
	         ;este &06 simplemente le vale para saber si ha llegado al ultimo sector
             	 ;y saltar al siguiente track.
	ld (cambia_sectorID+1),a

	ld hl,#0400 ;nuevo tamano por sector (1024 bytes)
	ld (cambia_tamano_sector+1),hl 

	xor a
	ld (desplazamiento_sector),a

	ld hl,&0298 ;lee de los parametros escritos en &0297
	ld a,(hl)
	and a
	jr z,no_cargamos
	 ;En el loader de Satan se entraba por aqui para cargar la pantalla de presentacion
	 ;en T. Girl NO entra por aqui, cargara la pantalla de presentacion mas abajo.
	call carga_pantalla_presentacion ;NO se cumple en T. Girl

no_cargamos

	ld a,(&0297) ;sigue leyendo parametros loader
                     ;parametro numero de partes de la que consta el juego (1 en T.girl)

	cp #01 ;por aqui decide que no hay menu de eleccion de parte (T.Girl solo tiene 1 parte)
               ;en Satan por ejemplo muestra el menu de eleccion.
	jr z,no_menu_eleccion 

	;por aqui pasaria si el juego en cuestion tiene que mostrar menu de eleccion de parte
	;T. Girl no tiene.
	call desactiva_upper_rom ;cada vez que acaba con las lecturas en disco deshabilita la UPPER ROM
                         	 ;para que no entre en conflicto con la memoria de pantalla.

	call pon_tintas ;pone todas las tintas a negro menos la tinta 1 que la pone en blanco.

	ld a,(&0297) ;lee otra vez de zona de parametros
	ld c,a
	ld b,#00
	inc c
	call posiciona_puntero_parametros ;Aqui decidiria el puntero al TEXTO a mostrar en el menu (como en SATAN)
	dec hl ;hl traeria el puntero al texto, decrementan 1 posicion porque con su metodo "oscuro" de posicionar
               ;el puntero se le debio pasar 1 posicion.

	;recuerda, por aqui no pasa T.Girl ya que no tiene MENU.
bucle_texto

	ld a,(hl) ;registro A va cogiendo el valor ASCII del texto a imprimir en pantalla
	cp #ff ;&ff decide fin de texto.
	call nz,#bb5a ;escribe codigo de caracter almacenado en registro A en pantalla.
	inc hl ;incrementa puntero a siguiente codigo ASCII a mostrar en pantalla
	jr nz,bucle_texto

	;por aqui hemos acabado de escribir menu de eleccion de fase en pantalla

	;ahora lee teclado para saber que tecla se ha pulsado

lee_teclado
	call #bb06 ;funcion de FIRMWARE para leer una tecla
    	      	   ;retorna en registro A el codigo ascii de la tecla pulsada.
	cp #31 ;?es tecla 1?
	jr c,lee_teclado ;si es inferior a 1 vuelve a escanear teclado
	cp #3a ;?es tecla 2?
	jr nc,lee_teclado ;si es superior a 2 vuelve a escanear teclado
	sub #30 ;quita el codigo ascii y se queda con 1 o 2 solo.
	ld hl,&0297 
	cp (hl)
	jr z,no_menu_eleccion
	jr nc,lee_teclado


;Turbo Girl salta aqui, NO TIENE MENU DE ELECCION.
no_menu_eleccion 

	ld (fase_loader+1),a ;guarda parametro leido en &0297, numero de partes (&01)
	call pon_tintas_negro 
	call activa_upper_rom ;para poder acceder directamente a las rutinas de AMSDOS

fase_loader
	ld c,#00 ;esto se modifica en tiempo de ejecucion
	ld b,c
	ld hl,&029d ;siguiente zona de variables para efectuar carga de datos
	ld a,(desplazamiento_sector) ;de inicio no hay desplazamiento (&00)


bucle_incremento_fase2
	dec b
	jr z,no_incrementes_desplazamiento ;l0196

	;esto no pasa nunca en T.Girl ya que no hay parte 2

	add (hl) ;aqui prepararia el desplazamiento de sector para cargar parte 2
	inc hl ;aqui moveria puntero a datos de carga parte 2
	jr bucle_incremento_fase2

no_incrementes_desplazamiento

	ld (desplazamiento_sector),a ;lo dicho, no hay desplazamiento (&00)
	call posiciona_puntero_parametros ;posiciona HL en &029E que es donde estan los parametros
                                          ;de carga de T.girl.

	ld (modifica_puntero_parametros+1),hl
	ld a,(hl) ;lee numero de sectores a leer
	and a ;pregunta si no hay sectores para leer (0)
	jr z,no_presentacion ;entiende entonces que no hay pantalla de presentacion
	
	;en T.Girl la hay, asi que pasa por aqui.
	;Recuerda que en SATAN ya habia cargado la pantalla de presentacion mucho antes y NO pasa por aqui.
	call carga_pantalla_presentacion 

;&01A6 direccion de memoria en la que estamos y retornara despues de cargar pantalla de presentacion
pantalla_presentacion_ya_cargada 

no_presentacion ;por aqui salta si no hay pantalla de presentacion (T. Girl tiene)

modifica_puntero_parametros
	ld hl,#0000 ;recuerda, esto fue modificado en tiempo de ejecucion.
	ld bc,#0005 ;posiciona puntero a donde encontrara los datos de carga sea de fase 1 o fase 2
          	    ;literalmente se salta un bloque de parametros que NO se usa en T. Girl (ni SATAN)
	add hl,bc

	ld b,(hl) ;NUMERO DE SECTORES A LEER
	inc hl

	ld e,(hl) 
	inc hl
	ld d,(hl) ;DE tiene ahora la direccion de carga del bloque de datos en cuestion
		  ;DE=&1B6D en T.Girl

	push de

	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl) ;DE tiene ahora la direccion de EJECUCION del bloque de datos cuando decida llamarle.
		  ;DE=&4F2E en T. Girl

	ld (direccion_ejecucion_juego+1),de

	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl) ;DE=&C000, situacion del stack en fase 1
	inc hl
	ld (situacion_stack+1),de

	pop de
	call carga_bloque_datos 

	ld a,(hl) ;HL apunta a zona de parametros loader 
	and a ;si el parametro fuera &00 no cargaria un segundo bloque de datos
              ;en T.girl hay un segundo bloque de datos con lo cual no ejecuta el salto
	      ;registro A toma el valor &10 que es el numero de sectores a leer en la siguiente carga.

	jr z,acabado_ejecuta_juego ;esto no se cumple en T.Girl

	;viene por aqui en T.Girl
	ld b,a ;metemos en registro B el numero de sectores a leer en la siguiente carga
	inc hl
	ld a,(hl) ;leemos otro parametro, este le indica que ponga las tintas a negro
		  ;ya que hay un segundo bloque de datos a leer y sera en memoria de pantalla
	and a ;comprueba el parametro leido, si es 0 NO pone tintas a negro
	push hl
	push bc
	call nz,pon_tintas_negro ;se cumple y pone las tintas a negro.
	pop bc ;recupera numero de sectores a leer
	pop hl ;recupera puntero a datos de loader

	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl) ;DE tiene ahora la direccion de carga del bloque de datos en cuestion
		  ;DE=&C000 para segundo bloque de carga.

	call carga_bloque_datos  ;carga el ultimo bloque de datos en TODA la memoria de pantalla
				 ;&C000-&FFFF

acabado_ejecuta_juego
	xor a
	ld bc,#fa7e
	out (c),a ;apaga la disquetera
	
	call desactiva_upper_rom ;ya no le hace falta acceder a mas comandos de AMSDOS.

situacion_stack
	ld sp,#c000 ;se modifica en tiempo de ejecucion

direccion_ejecucion_juego
	jp #0000 ;se modifica en tiempo de ejecucion
		;en T.girl salta a &4F2E

;este es ultimo punto del loader, con el JP se cede el control al propio juego.


;---------------------------------------------------------------------------------------------
carga_bloque_datos

	ld a,(desplazamiento_sector)
	ex de,hl
	push de
	push bc

	call decide_parametros_y_lee_disco

;POR AQUI RETORNA DESPUES DE CARGAR TODOS LOS DATOS
retorno_carga_datos

	pop bc
	pop hl
	ld a,(desplazamiento_sector)
	add b
	ld (desplazamiento_sector),a ;guarda desplazamiento de disco para siguientes cargas.
	ret


;-------------------------------------------------------------------


decide_parametros_y_lee_disco

	push hl
	ld l,a
	xor a
	ld h,a
	ld de,#fffb
	.l0207
	inc a
	add hl,de
	jr c,l0207
	ld d,a
	ld a,l
	add #06
	ld e,a
	pop hl

	;parametros lee_datos_disco
	;registro B numero de sectores a leer (leido de &101)
	;registro E sector ID
	;registro D track a posicionarnos
	;registro HL buffer de memoria donde se meteran los datos del sector 

	;------parametros primera lectura---------------------------------------------------------
	;en primera lectura tenemos (codigo pantalla carga y colores)
	;HL trae &2710, que es donde empezara a meter datos en memoria
	;B trae 17 sectores a leer (&11 en hexadecimal)
	;E es &01 ya que es el primer sector
	;D track &01
	;es decir va a empezar a leer en track &01 sector &01
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 17 sectores a leer=17408bytes que mete en zona de memoria &2710 a &6B0F
	;--------------------------------------------------------------------------------------------

	;--------parametros segunda lectura (T.Girl primera lectura)---------------------------------
	;HL trae &1B6D, que es donde empezara a meter datos en memoria
	;B trae 33 sectores a leer (&21 en hexadecimal)
	;E es &03 sector 3
	;D track &04
	;es decir va a empezar a leer en track &04 sector &03
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 33 sectores a leer=33792 bytes que mete en zona de memoria &1B6D a &9F6C
	;--------------------------------------------------------------------------------------------

	;--------parametros tercera lectura (T.Girl segunda lectura)---------------------------------
	;HL trae &C000, que es donde empezara a meter datos en memoria
	;B trae 16 sectores a leer (&10 en hexadecimal)
	;E es &01 sector 1
	;D track &0b (track 11)
	;es decir va a empezar a leer en track 11 sector &1
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 16 sectores a leer=16384 bytes que mete en zona de memoria &C000 a &FFFF
	;--------------------------------------------------------------------------------------------

	jp lee_datos_disco

;OJO no retorna por aqui, el RET de lee_datos_disco en este caso le llevara
;de retorno a retorno_carga_datos

;----------------------------------------------------------------------------


carga_pantalla_presentacion

	ld b,(hl) ;B=&11 numero de sectores a leer
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl) ;DE= direccion de carga de la rutina para pantalla de presentacion (&2710)
		  ;DE=&2710

	push de
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl) ;DE= direccion de EJECUCION de la rutina para pantalla de presentacion (&2710)

	ld (modifica_llamada+1),de ;modificamos el call modifica_llamada a call &2710 para que ejecute
                        	   ;rutina de mostrar pantalla de carga.
	pop de

	call carga_bloque_datos 

	;por aqui vuelve con bloque de datos cargado (relativos a la pantalla de presentacion)

	call desactiva_upper_rom

modifica_llamada
call modifica_llamada ;Esto entraria en bucle infinito, pero se modifica en tiempo de ejecucion para
    	       	      ;apuntar a la rutina adecuada.
		      ;se cambiara a call &2710 (que es donde mete la primera carga)
                      ;la primera carga son las rutinas de colores y mostrado en SCREEN de presentacion
                      ;saltara a rutina que muestra pantalla de presentacion.
                      ;basicamente, cambia a modo 0, setea colores de pantalla
                      ;y hace un ldir a SCREEN con la pantalla de presentacion.
                      ;no hay mas trampa ni carton, simplemente se limita a mover la pantalla de presentacion.
                      ;a memoria de video y, despues espera a que se pulse una tecla y retorna por aqui.

jp activa_upper_rom 

	;no retornara por aqui sino a llamada matriz
	;retorna a pantalla_presentacion_ya_cargada (&01A6)

posiciona_puntero_parametros
	;esta funcion es igual que en SATAN
	;posiciona el puntero de datos de loader un poco de tapadillo
	ld l,c
	ld h,b
	dec l
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld de,&029d
	add hl,de
	add hl,bc
	ret

;---------------------------------------------------------------------------

lee_datos_disco

	ld c,e

bucle_lectura

	push bc ;guarda en pila B numero de sectores a leer, C sector ID
	push de ;guarda en pila D track a posicionarnos

bucle_reintento_lectura
	push hl
	ld e,#00 ;disquetera a usar (0 es la principal del amstrad)
	call #c666 ;LLAMA A LA ROM DE AMSDOS DIRECTAMENTE
    	       	   ;situada como UPPER ROM usando rango &C000-&FFFF
        	   ;en este caso llama a la funcion "READ SECTOR"
           	   ;parametros
           	   ;HL buffer de memoria donde se meteran los datos del sector
           	   ;E tiene el numero de disquetera (0 es la principal)
           	   ;D track a leer.
           	   ;C sector number (sector ID)
	pop hl
	jr nc,bucle_reintento_lectura ;si ha habido algun error de lectura lo reintenta.

cambia_tamano_sector
	ld de,&0200 ;este valor lo SOBREESCRIBE para cambiar EL TAMANO de los sectores
		    ;acabara poniendo &0400 (LD DE,&0400) es decir 1024bytes por sector leido
		    ;asi al hacer ADD HL,DE calcula la siguiente zona contigua de RAM
		    ;donde metera el siguiente sector.
	add hl,de ;calcula siguiente zona de memoria donde meter siguiente sector.
	pop de ;recupera D, TRACK a posicionarnos.
	pop bc ;recupera B numero de sectores a leer, C sector ID
	inc c ;incrementa sector ID
	ld a,c 
	and #0f ;se queda con los ultimos 4bits de C
    	    	;asi convierte el sector ID en un numero entre 1 y 9

cambia_sectorID
	cp #0a  ;comprueba que no llegamos al final del track
        	;entonces avanzara el track y pondra el primer sector del track a leer.
        	;#0a es SOLO con track 0, despues SOBREESCRIBIRA este cp &0a por cp &06
        	;que sera la nueva nomenclatura de los sector ID (&01,&02,&03,&04,&05)

	jr c,no_avances_track
	ld a,c ;debemos volver al primer sector del siguiente track
	and #f0 ;lo convertimos en &00
	or #01  ;sumamos 1, &01
	ld c,a  ;es decir, volvemos al primer SECTOR ID (&01)
	inc d  ;incrementamos track
no_avances_track
	djnz bucle_lectura

	;por aqui hemos leido todos los datos que nos han pedido
	ret ;volvemos a la rutina que nos llamo

;-----------------------------------------------------------------------------------------------------

desactiva_upper_rom
	di
	exx ;usamos los registros espejo
	    ;lo hace porque el firmware tiene inicializado registro BC' con los datos
	    ;del gate array, el modo grafico y estado de las upper rom y lower rom 
	set 3,c
	out (c),c ;deshabilita la UPPER ROM (deja de estar accesible AMSDOS en &c000)
	exx
	ei
	ret


;-------------------------------------------------------------------------------------------------------
activa_upper_rom
	di
	exx
	res 3,c ;HABILITA la UPPER ROM para que AMSDOS vuelva a ser accesible en &c000
	out (c),c ;manda el comando al gate array
	exx
	ei
	ret

;------------------------------------------------------------------------------------------------------

pon_tintas
	call pon_tintas_negro
	ld a,#01 ;elige tinta 1
	ld bc,#1a1a ;elige el color blanco brillante que es el color de letra del MENU.
		    ;T.girl NO tiene menu.
	call #bc32  ;pone el color para la tinta definida en registro A (SCR SET INK)
           	    ;aqui cambia tinta 1 a blanco brillante 
		    ;(que es como se muestran las letras del menu de eleccion de fase)

	jr establece_tintas ;se llamara a MC SET INKS.

pon_tintas_negro 

	ld bc,#0000
	call #bc38 ;pone borde a negro
		   ;DE trae la direccion de memoria donde el firmware guarda los colores actuales usandose.
           	   ;los guarda de una manera muy curiosa
	           ;son 17 bytes (border+16 colores) (primer parametro INK)
 	           ;y otros 17 bytes (border +16 colores) (segundo parametro INK)
   	           ;si el primer parametro no coincide con el segundo, el CPC 
       		   ;flashea estas 2 tintas en el mismo pen.
	ex de,hl ;metemos la direccion de esos datos en DE
	ld (datos_ink+1),hl ;para cambiar el codigo de aqui abajo...
	ld b,#22 ;bucle 34 veces (border + 16 colores) + (border + 16 colores)
bucle_negro
	ld (hl),#14 ;&14 es el color HARDWARE negro 
	inc hl
	djnz bucle_negro;bucleamos 34 veces
	;hemos puesto todos los colores a negro.

establece_tintas

datos_ink
	ld de,#0000;los datos de las tintas (el vector de ink) tiene el siguiente formato
    	     	    ;byte 0 color del borde
        	    ;byte 1 Color del PEN 0... byte 16 - color del PEN 15.
            	    ;los colores son valores HARDWARE

	jp #bd25 ;MC SET INKS pone los 16 colores, los datos estan definidos a donde apunta registro DE

	;no volvera por aqui, como en pila esta colocado la direccion de memoria POSTERIOR al ultimo CALL,
	;al llamar a una rutina de firmware (como es MC SET INKS), el ret de la rutina nos devolvera al 
	;ultimo call realizado, en este caso a despues de llamar a la rutina tintas.

	;----------------------------------------------------------------------------------------------------



desplazamiento_sector
;posicion &0296
	push hl ;no se inicializa al cargar loader, por eso toma valor &05 (vacio en AMSDOS)


;-------------------------------------------------------------------------------------------
;estos push hl son basura que mete el loader al cargar un sector entero del que no usa el final
;push hl = &E5 que es la marca en los discos que indica sin dato
;hay 105bytes con la marca de "vacio" ya que el loader no ocupa

	;push hl
	;push hl
	;[...] 105 bytes de &05.

;---------------------------------------------------


;-------------SECTOR QUE LEE EN &0297-----------------
;la explicacion de parametros de carga loader
;estan totalmente definidos en el loader de SATAN.
;consultarlo para saber que significa cada byte
parametros_loader_0297

	db #01,#00,#00,#00,#00,#00,#42
;&029E ;empiezan parametros carga pantalla presentacion
	db #11
	db #10,#27,#10,#27,#21,#6d,#1b,#2e
	db #4f,#00,#c0,#10,#01,#00,#c0,#1f
	db #13,#0c,#31,#2d,#20,#2e,#ff,#e5