
	;------------------------------
	;loader original SATAN (Dinamic)
	;comentado por Joseman, Marzo 2019
	;-------------------------------

	;Este loader es bastante sencillo, usa el FIRMWARE para cargar los datos.
	;quiza lo mas complicado que hace es la forma que tiene de calcular
	;el desplazamiento TRACK-SECTOR, ya que lo hace de una manera un poco
	;"oscura", supongo que para ocultar un poco a ojos ajenos las zonas de carga
	;los parametros de carga los obtiene de la lectura de 1 sector del disco
	;que guardara &0100
	;esto demuestra que este loader posiblemente se usa en otros juegos
	;de Dinamic simplemente cambiandole esos parametros.

	org &0100 ;origen del loader
    	      	  ;todos los loaders que cargan con CPM se inician en esta direccion.
  		  ;el loader de SATAN ocupa desde &0100 a &02BF (448 bytes)
          	  ;la carga de los loaders de CPM implican 512bytes con lo cual desde el byte
          	  ;449 al byte 512 se rellena en el caso del loader del satan con
          	  ;el valor &05  que es la marca "vacio" en los discos de AMSDOS.
	run $


	;--------------------------------------------------------------
	;DESHABILITAMOS ESTA ZONA DEL CODIGO ORIGINAL
	;LO QUE HACE ES RELOCALIZAR EL CODIGO DEL LOADER 
	;EN #A9BE, NOSOTROS YA LO HACEMOS DIRECTAMENTE EN EL EMULADOR
	;PARA FACILITAR EL TRACEO DEL LOADER.

	;ld hl,&0100 ;direccion de inicio de este loader
	;ld de,&a9b0 ;direccion donde lo va a relocalizar
	;ld bc,&01c0 ;tamano del loader (448bytes)
	;ldir ;lo mueve a la direccion de memoria &a9b0

	;--------------------------------------------------------------

	jp &a9be ;salta a la nueva zona donde ha relocalizado.

	;esta zona ahora esta en #A9BE
	org &A9BE ;obligamos al emulador a que compile ya en esa zona
          	  ;para facilitar el traceado del programa.

	ld hl,#a9c6 ;parametro para MC BOOT PROGRAM (firmware)
            	    ;#A9C6 es la direccion donde MC BOOT PROGRAM saltara.
	ld c,#ff ;C es otro parametro, es la ROM a donde queremos saltar.
    	         ;#FF no salta a ninguna ROM, sigue en RAM principal. 

	jp #bd16 ;ejecutamos la instruccion de firmware MC BOOT PROGRAM
    	         ;como el parametro pasado #A9C6 es JUSTO aqui debajo, sigue por aqui.
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

	;estamos en #AC96 (recuerda, MC BOOT PROGRAM salta aqui)	
	ld c,#07 ;ROM 7 (AMSDOS)
	call #bcce ;llamada a firmware (KL INIT BACK)reinicia AMSDOS
           	   ;como se puede ver SOLO activa AMSDOS como ROM necesaria para seguir leyendo de disco.

	ld c,#07 ;ROM 7 (AMSDOS)
	call #b90f ;llamada a firmware KL ROM SELECT
                   ;esto hace que la rom de AMSDOS sea accesible como UPPER ROM desde este loader.
        	   ;es decir es accesible en el rango de memoria principal &C000-&FFFF
	   	   ;lo hacen para poder usar las rutinas de AMSDOS para cargar el juego.

	ld hl,&0100 ;direccion de memoria donde se meteran los datos del sector a leer
	ld de,&0042 ;registro D, track a leer (00 en este caso).
            	    ;registro E, SECTOR ID (EL track 0 tiene estos SECTOR ID 41,&42,&43,&44,&45,&46,&47,&48,&49)
            	    ;es decir, lee el sector 1 (&42)
	ld b,&01 ;numero de sectores a leer ;en este caso solo lee 1 (512bytes de datos)

	call lee_datos_disco  ;carga 512bytes de datos (1sector)
           		      ;track 0 sector 1 (ID &42)
		      	      ;Aunque carga 512bytes solo usa 69 bytes que usara como parametros para el loader.
                              ;del byte 70 hasta el ultimo se rellena con &E5 que es la marca "vacio" en los discos
 			      ;de AMSDOS.

;el motivo por el que lee los parametros del loader de un sector del disco y los mete en &0100
;es (supongo) usar el mismo loader para diferentes juegos.
;asi que es posible que algun juego mas de Dinamic use el mismo loader con diferentes parametros.
            

	ld ix,(#be42) ;Direccion &BE42 es direccion de memoria a Drive A Extended Disc Parameter Block (XDPB)
	              ;este XDPB son 25 bytes donde esta la configuracion actual usandose de la disquetera
                      ;IX=&A890 (que es donde empieza XDPB)
	
	ld (ix+#14),#03 ;escribe en el byte 21 del XDPB (sector size)
                        ;&03=1024bytes de tamano por sector
			;a partir de ahora todos los sectores leidos tendran un tamnano de 1024bytes

	ld (ix+#18),#60 ;Auto select flag (&00=Auto select; &FF= don't alter)

	ld a,#ff
	ld (#be78),a ;desactiva los mensajes de error de lectura de disco  (&00 activa, &ff desactiva)

	ld a,#06 ;a partir del track 1 cambian los sector ID en el disco.
         	 ;nueva nomenclatura para los sector ID (&01,&02,&03,&04,&05)
	         ;este &06 simplemente le vale para saber si ha llegado al ultimo sector
             	 ;y saltar al siguiente track.

	ld (cambia_sectorID+1),a ;cambia el valor donde hace la comparacion de fin de sector por este &06


	ld hl,#0400 ;nuevo tamano por sector (1024 bytes)
	ld (cambia_tamano_sector+1),hl ;modifica el codigo del loader para que ahora haga LD DE,#0400

	xor a
	ld (desplazamiento_sector),a ;inicializa a 0 esta variable

	ld a,(parametros_loader_0100) ;leemos ya datos del sector que hemos escrito en &0100-&02ff
	ld (fase_loader+1),a ;A=&02 lo modifica en tiempo de ejecucion para que la comparacion
    	                     ;de mas abajo sea diferente segun en que fase se encuentre el loader.

	cp #01 ;si A=&02 ponemos tintas y MENU de eleccion de fase.
    	       ;por eso lee ese parametro en &0100 para indicarle que esta en la fase de mostrar
       	       ;menu
       	       ;si A=&01 entonces es que ya hemos puesto el menu

	jr z,no_menu_eleccion_parte

	;por aqui muestra menu de eleccion de parte.

	call desactiva_upper_rom ;cada vez que acaba con las lecturas en disco deshabilita la UPPER ROM
                         	 ;para que no entre en conflicto con la memoria de pantalla.

	call pon_tintas ;pone todas las tintas a negro menos la tinta 1 que la pone en blanco.

	ld a,(parametros_loader_0100) ;vuelve a hacer la misma lectura A=&02
				      ;esta vez para usarlo como desplazamiento en funcion
				      ;posiciona_puntero_parametros
	ld c,a ;C=&02
	ld b,#00
	inc c ;bc=&0003
	call posiciona_puntero_parametros ;HL trae la direccion a leer parametros 
          	                          ;en este caso texto en pantalla (HL=&0128).

	;HL viene con la direccion de texto del menu para mostrar en pantalla

	;ahora en bucle_texto ira poniendo caracter a caracter el menu de eleccion de fase
        ;1- SATAN  I
        ;2- SATAN II


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

	ld hl,parametros_loader_0100 ;vuelve a leer en &100
	cp (hl) ;compara lo que hemos elegido (1 o 2), con parametro al que apunta (hl)->&02
	jr z,fase_elegida ;si hemos pulsado 2 salta a fase_elegida
	jr nc,lee_teclado ;1 daria Carry ya que A<(hl) con lo cual sigue igual a fase_elegida

	;por aqui hemos elegido si fase 1 o fase 2
fase_elegida 
	ld (fase_loader+1),a ;modifica en tiempo de ejecucion con el parametro que hemos elegido de fase
	call activa_upper_rom ;vuelva a hacer accesible AMDOS en UPPER ROM (&C000) ;#ab42

no_menu_eleccion_parte
	call pon_tintas_negro ;una vez elegida parte a cargar, ponemos a negro pantalla
	ld hl,&0101 ;se posiciona en parametros para loader +1.
	ld a,(hl) ;A=&11 usa el parametro de numero de sectores para decidir cargar pantalla de presentacion
	and a ;?es A=&0? entonces no carga pantalla de presentacion o entiende que ya esta cargada
	jr z,pantalla_presentacion_ya_cargada

	call carga_pantalla_presentacion

	;por aqui vuelve despues de meter primera carga en &2709 a &6b08
	;que basicamente lo que hace es setear colores y mover pantalla de carga a memoria de pantalla.

pantalla_presentacion_ya_cargada

fase_loader
	ld c,#00 ;se modifica el parametro de C segun eligamos fase 1 o fase 2
	ld b,c
	ld hl,&0106 ;siguiente zona de variables para efectuar carga de datos
	ld a,(desplazamiento_sector)

bucle_incremento_fase2
	dec b ;b trae &01 si hemos elegido fase 1, o 2 si hemos elegido fase 2 en MENU.
	      ;al hacer dec b, si salta el flag de Zero es porque habiamos elegido fase 1
 
	jr z,no_incrementes_desplazamiento

	;por aqui entra solo en carga parte 2, para calcular el desplazamiento al bloque de datos
	;de dicha parte
	;hl apunta a 106
	add (hl) ;A= &11 + 2A = &3B
	inc hl ;hl=&0107 ;este valor no llega a usarse nunca, por lo menos en SATAN
	jr bucle_incremento_fase2 


no_incrementes_desplazamiento
	ld (desplazamiento_sector),a

	call posiciona_puntero_parametros ;HL viene cargado con direccion donde leeremos parametros
                                   	  ;para siguiente carga

	ld (modifica_puntero_parametros+1),hl
	ld a,(hl) ;fase 1 y fase 2, a coge valor &0
	and a ;pregunta si es 0 ;en fase 1 y fase 2 SIEMPRE es 0
	jr z,todo_correcto
	call carga_pantalla_presentacion ;ESTO NO SE CUMPLE NUNCA
    	   ;solo se cumpliria si se hubiese movido mal el puntero de parametros
           ;o que no hubiera lo que espera en su zona de memoria 
           ;quiza es una sencilla proteccion anticopia.

todo_correcto
modifica_puntero_parametros
	ld hl,#0000 ;recuerda, esto fue modificado en tiempo de ejecucion.
	ld bc,#0005
	add hl,bc ;posiciona puntero a donde encontrara los datos de carga sea de fase 1 o fase 2
          	  ;literalmente se salta un bloque de parametros que NO se usa en SATAN

	ld b,(hl) ;NUMERO DE SECTORES A LEER
	inc hl
	ld e,(hl) 

	inc hl
	ld d,(hl) ;DE tiene ahora la direccion de carga del bloque de datos en cuestion
	ld (DIRECCION_CARGA+1),de
	inc hl
	ld e,(hl) 
	inc hl
	ld d,(hl) ;DE tiene ahora la direccion de EJECUCION del bloque de datos cuando decida llamarle.
	ld (direccion_ejecucion_juego+1),de
	inc hl
	ld e,(hl) ;E=&00
	inc hl
	ld d,(hl) ;D=&C0 
              ;DE=&C000, situacion del stack en fase 1
	inc hl
	ld (situacion_stack+1),de
	ld a,(hl) ;a=&0A en fase 1
	and a ;pone Carry flag a 0
      
	ld (sector_a_leer_carga2+1),a ;guarda &0A en fase 1 ;;#aaac),a ;
	inc hl
	ld a,(hl) ;toma valor &01 para decidir mas abajo poner tintas a negro
	ld (decide_tintas_negro+1),a
	inc hl
	ld e,(hl) 
	inc hl
	ld d,(hl) ;DE=&C00C, decide direccion de carga del segundo bloque de datos
	ld (direccion_carga2+1),de

DIRECCION_CARGA
	ld de,#0000 ;modifica esto en tiempo de ejecucion.
              	    ;&033C en fase1 y tambien en fase 2

	call carga_bloque_datos ;cargamos los datos una vez que tenemos todos los parametros

	;por aqui datos ya cargados

	;ahora comprueba si hay un SEGUNDO bloque de datos a leer.
	ld a,(sector_a_leer_carga2+1)
	and a
	jr z,acabado_ejecuta_juego ;si no lo hay, no carga nada mas, y salta a apagar disquetera
    	                           ;deshabilitar UPPER ROM y ejecutar juego.

	;por aqui se pasa para cargar el SEGUNDO bloque de datos de cada parte.

decide_tintas_negro
	ld a,#00 ;modificada en tiempo de ejecucion
      	     	 ;para decidir si poner tintas a negro o no.
	and a
	call nz,pon_tintas_negro ;si no da cero, salta a PONER TINTAS EN NEGRO


sector_a_leer_carga2
	ld b,#00 ;se modifica en tiempo de ejecucion
    	    	 ;se usa para decidir el sector de la carga 2

direccion_carga2
	ld de,#0000 ;se modifica en tiempo de ejecucion
    	            ;fase 1 de=&c00c
        	    ;carga datos en &C00C

	call carga_bloque_datos ;cargamos segundo bloque de datos

	;por aqui tenemos TODOS los datos cargados del juego!

acabado_ejecuta_juego
	xor a
	ld bc,#fa7e ;apaga motor disquetera
	out (c),a

	call desactiva_upper_rom ;volvemos a modo normal en &c000 ;#ab39

situacion_stack
	ld sp,#c000 ;se modifica en tiempo de ejecucion
            	    ;con fase 1 se situa en &C000
		    ;con fase 2 se situa en &c000 tambien

direccion_ejecucion_juego
	jp #0000 ;se modifica en tiempo de ejecucion
    	    	 ;con fase 1 se salta a &033C
        	 ;CON fase 2 se salta a &033C tambien.
		 ;este es ultimo punto del loader, con el JP se cede el control al propio juego.

;------------------------------------------------------------------------------

carga_bloque_datos 

	ld a,(desplazamiento_sector) ;de inicio esta a 0 porque se XOR la zona.
   	                             ;en pantalla de presentacion coge valor &00
				     ;en fase 1 carga1, coge &11
                	             ;en fase 1 carga2, coge &31
                        	     ;en fase 2 carga1, coge &3B
				     ;en fase 2 carga2, coge &5D

	ex de,hl
	push de ;guarda puntero a zona &0105, zona &117 en fase 1
	push bc ;guarda B, es NUMERO DE SECTORES A LEER

	call decide_parametros_y_lee_disco

;POR AQUI RETORNA DESPUES DE CARGAR TODOS LOS DATOS
retorno_carga_datos

	pop bc ;recupera B numero de sectores a leer
	pop hl ;recupera puntero a zona de datos de carga (&0105)
	ld a,(desplazamiento_sector)
	add b ;b trae ultimo sector leido...
      	      ;se va guardando el desplazamiento total, para mas tarde calcular
	      ;track y sector segun que queramos cargar.
      
	ld (desplazamiento_sector),a
	ret

;-------------------------------------------------------------------------------

decide_parametros_y_lee_disco

	push hl ;guarda HL buffer de memoria donde se meteran los datos del sector

	ld l,a ;l toma el valor de desplazamiento sector
	
	xor a ;a=0
	ld h,a ;pone a 0 registro H
		;hl en pantalla de carga = &0000
       		;hl en fase 1 carga 1 =&0011
	        ;hl en fase 1 carga 2 =&0031
	        ;hl en fase 2 carga 1 =&003B
 	        ;hl en fase 2 carga 2 =&005D

	ld de,#fffb

bucle_decide_track
	inc a ;en este bucle decide TRACK a posicionarnos.
	add hl,de ;cuanto mas grande sea el desplazamiento que trae HL
          	  ;mas veces hara este bucle para calcular track
	  	  ;es decir dependiendo de pantalla de carga, fase 1, fase 2...
          	  ;el desplazamiento sera cada vez mas alto, el TRACK a posicionarnos sera cada vez mas alto

	jr c,bucle_decide_track ;si desbordamos HL hace este bucle
	

	ld d,a ;AHORA REGISTRO D, TIENE EL TRACK A POSICIONARNOS
	ld a,l ;ahora coge el "resto" del calculo de posicionamiento de track
	add #06 ;y lo mete dentro de los limites &00 - &05 que seria el SECTOR ID en el 
        	;que comenzar a leer

	ld e,a ;REGISTRO E SECTOR A LEER
    	   ;AQUI HA DECIDIDO TRACK Y SECTOR A LEER (DE)
       	   ;simplemente lo calcula teniendo en cuenta el desplazamiento TOTAL en sectores.

	pop hl ;recuperamos buffer de memoria donde se meteran los datos del sector

	;parametros lee_datos_disco
	;registro B numero de sectores a leer (leido de &101)
	;registro E sector ID
	;registro D track a posicionarnos
	;registro HL buffer de memoria donde se meteran los datos del sector 

	;------parametros primera lectura---------------------------------------------------------
	;en primera lectura tenemos (codigo pantalla carga y colores)
	;HL trae &2709, que es donde empezara a meter datos en memoria
	;B trae 17 sectores a leer (&11 en hexadecimal)
	;E es &01 ya que es el primer sector
	;D track &01
	;es decir va a empezar a leer en track &01 sector &01
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 17 sectores a leer=17408bytes que mete en zona de memoria &2709 a &6b08
	;--------------------------------------------------------------------------------------------

	;--------parametros segunda lectura (fase 1 primera lectura)---------------------------------
	;HL trae &033C, que es donde empezara a meter datos en memoria
	;B trae 32 sectores a leer (&20 en hexadecimal)
	;E es &03 sector 3
	;D track &04
	;es decir va a empezar a leer en track &04 sector &03
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 32 sectores a leer=32768 bytes que mete en zona de memoria &033C a &833B
	;--------------------------------------------------------------------------------------------

	;--------parametros tercera lectura (fase 1 segunda lectura)---------------------------------
	;HL trae &C00C, que es donde empezara a meter datos en memoria
	;B trae 10 sectores a leer (&0A en hexadecimal)
	;E es &05 sector 5
	;D track &0a (track 10)
	;es decir va a empezar a leer en track 10 sector &0a
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 10 sectores a leer=10240 bytes que mete en zona de memoria &C00C a &E80B
	;--------------------------------------------------------------------------------------------


	;---------parametros segunda lectura (fase 2 primera lectura)-------------------------------
	;HL trae &033C, que es donde empezara a meter datos en memoria
	;B trae 34 sectores a leer (&22 en hexadecimal)
	;E es &05 sector 5
	;D track &0C (12)
	;es decir va a empezar a leer en track &10 sector &05
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 34 sectores a leer=34816 bytes que mete en zona de memoria &033C a &8B3B
	;--------------------------------------------------------------------------------------------

	;--------parametros tercera lectura (fase 2 segunda lectura)---------------------------------
	;HL trae &C00C, que es donde empezara a meter datos en memoria
	;B trae 11 sectores a leer (&0B en hexadecimal)
	;E es &04 sector 4
	;D track &13 (track 19)
	;es decir va a empezar a leer en track 19 sector 4
	;de cada sector lee 1024bytes (tamano de sector que cambio despues de cargar zona &100-&2ff)
	;1024bytes x 11 sectores a leer=11264 bytes que mete en zona de memoria &C00C a &EC0B
	;--------------------------------------------------------------------------------------------

	jp lee_datos_disco 
	;OJO no retorna por aqui, el RET de lee_datos_disco en este caso le llevara
	;de retorno a retorno_carga_datos (&AACB)

;------------------------------------------------------------------------------------------------

carga_pantalla_presentacion
	ld b,(hl) ;B=&11 numero de sectores a leer
	inc hl ;HL=&0102
	ld e,(hl) ;E=&09
	inc hl ;&0103
	ld d,(hl) ;D=&27 
		  ;DE= direccion de carga de la rutina para pantalla de presentacion (&2709)
	push de
	inc hl ;HL=&104
	ld e,(hl) ;e=&09
	inc hl ;hl=&105
	ld d,(hl) ;D=&27 
		  ;de= direccion de EJECUCION de la rutina para pantalla de presentacion (&2709)
	ld (modifica_llamada+1),de ;modificamos el call &AAFE a call &2709 para que ejecute
                        	   ;rutina de mostrar pantalla de carga.

	pop de ;recuperamos &2709 que es la direccion de CARGA

	call carga_bloque_datos 
	;por aqui vuelve con bloque de datos cargado

	call desactiva_upper_rom ;volvemos a desactivar acceso a amdos desde &c000

modifica_llamada
	call #aafe ;Esto entraria en bucle infinito, pero se modifica en tiempo de ejecucion para
    	       	   ;apuntar a la rutina adecuada.
        	   ;se cambiara a call &2709 (que es donde mete la primera carga)
          	   ;la primera carga son las rutinas de colores y mostrado en SCREEN de presentacion
           	   ;saltara a rutina que muestra pantalla de presentacion.
           	   ;basicamente, cambia a modo 0, setea colores de pantalla
           	   ;y hace un ldir a SCREEN con la pantalla de presentacion.
                    ;no hay mas trampa ni carton, simplemente se limita a mover la pantalla de presentacion.
           	   ;a memoria de video y, despues espera a que se pulse una tecla y retorna por aqui.

	jp activa_upper_rom
	;de nuevo, no retornara por aqui sino a llamada matriz
	;retorna a pantalla_presentacion_ya_cargada (&AA46)

;------------------------------------------------------------------------------------------------------

posiciona_puntero_parametros
	;en esta funcion marea la perdiz arbitrariamente para decidir apuntar a los datos correctos de carga
	;el ld de,&0106 demuestra que es una posicion muy definida y arbitraria.

	ld l,c ;l=&03
	ld a,(parametros_loader_0100) ;vuelve a leer por tercera vez la misma zona A=&02
	ld c,a ;c=&02
	ld h,b ;b viene a 0 como parametro a esta funcion H=&00
	dec l ;l=&02, HL=&0002
	add hl,hl ;*2 hl=0004
	add hl,hl ;*2 hl=0008
	add hl,hl ;*2 hl=0010
	add hl,hl ;*2 hl=0020
	ld de,&0106 
	add hl,de ;&0020 + &0106= hl=&0126
	add hl,bc ;&0126 + &0002= hl=&0128 parece posicionar mareando la perdiz en zona de memoria
	ret
;----------------------------------------------------------------------------------------------


lee_datos_disco
	ld c,e ;&42

bucle_lectura
	push bc ;guarda en pila B numero de sectores a leer, C sector ID
	push de ;guarda en pila D track a posicionarnos

bucle_reintento_lectura
	push hl
	ld e,&00 ;disquetera a usar (0 es la principal del amstrad)
	call &c666 ;LLAMA A LA ROM DE AMSDOS DIRECTAMENTE
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
	ld de,&aab0 ;este valor lo SOBREESCRIBE para cambiar EL TAMANO de los sectores
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
	and #f0;lo convertimos en &40
	or #01 ;sumamos 1, &41
	ld c,a ;es decir, volvemos al primer SECTOR ID (&41)
	inc d ;incrementamos track

no_avances_track
	djnz bucle_lectura 

	;por aqui hemos leido todos los datos que nos han pedido
	ret ;volvemos a la rutina que nos llamo

;--------------------------------------------------------------------------------------
desactiva_upper_rom
	di ;deshabilitamos interrupciones
	exx ;usamos los registros espejo
	    ;lo hace porque el firmware tiene inicializado registro BC' con los datos
	    ;del gate array, el modo grafico y estado de las upper rom y lower rom 

	set 3,c ;deshabilita la UPPER ROM (deja de estar accesible AMSDOS en &c000)
	out (c),c
	exx
	ei
	ret

;---------------------------------------------------------------------------------------

activa_upper_rom
	di
	exx ;usamos de nuevo registros espejos para tocar el GATE ARRAY
	res 3,c ;HABILITA la UPPER ROM para que AMSDOS vuelva a ser accesible en &c000
	out (c),c ;manda el comando al gate array
	exx
	ei
	ret

;--------------------------------------------------------------------------------------

pon_tintas
	call pon_tintas_negro

	ld a,#01 ;elige tinta 1
	ld bc,#1a1a ;elige el color blanco brillante que es el color de letra del MENU.
	call #bc32 ;pone el color para la tinta definida en registro A (SCR SET INK)
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
	djnz bucle_negro ;bucleamos 34 veces
	;hemos puesto todos los colores a negro.

establece_tintas
datos_ink
	ld de,#0000 ;los datos de las tintas (el vector de ink) tiene el siguiente formato
    	     	    ;byte 0 color del borde
        	    ;byte 1 Color del PEN 0... byte 16 - color del PEN 15.
            	    ;los colores son valores HARDWARE
	jp #bd25 ;MC SET INKS pone los 16 colores, los datos estan definidos a donde apunta registro DE

	;no volvera por aqui, como en pila esta colocado la direccion de memoria POSTERIOR al ultimo CALL,
	;al llamar a una rutina de firmware (como es MC SET INKS), el ret de la rutina nos devolvera al 
	;ultimo call realizado, en este caso a despues de llamar a la rutina tintas.

	;----------------------------------------------------------------------------------------------------
	
	;variable para calcular el desplazamiento en el disco
desplazamiento_sector
	nop

	;-------------------------------------------------------------------------------------------
	;estos push hl son basura que mete el loader al cargar un sector entero del que no usa el final
	;push hl = &E5 que es la marca en los discos que indica sin dato
	;hay 64bytes con la marca de "vacio" ya que el loader no ocupa

	;push hl
	;push hl
	;[...] 64 bytes de &05.

	;---------------------------------------------------

	;-------------SECTOR QUE LEE EN &100-----------------

	;explicacion de parametros de carga loader
parametros_loader_0100
;&0100
	db #02 ;lo usa para decidir poner el menu de eleccion de parte
    	   ;tambien lo usa para hacer desplazamiento en funcion
       	   ;posiciona_puntero_parametros
;&0101
	db #11 ;Numero de sectores a leer
;&0102-&0103
	db #09,#27 ;direccion de carga para rutina de pantalla de presentacion en LOW ENDIAN
;&0104-&0105
	db #09,#27 ;direccion de EJECUCION para rutina de pantalla de presentacion en LOW ENDIAN
;&0106
	db #2a ;desplazamiento en disco a datos parte 2
;&0107
	db #2d ;no parece usarse en el loader SATAN
;&0108 comienzo bloque de parametros para carga parte 1
	db #00 ;lo usa para una comparacion que en SATAN siempre es la misma.
;&0109-&010c NO SE USA EN SATAN
	db #00,#00,#00,#00
;&10D
	db #20 ;Numero de sectores a leer primera parte carga 1
;&010E -&010F
	db #3c,#03 ;direccion de carga primera parte (carga1) en LOW ENDIAN
;&0110 -&0111
	db #3c,#03 ;direccion de EJECUCION primera parte (carga1) en LOW ENDIAN
;&0112-&0113
	db #00,#c0 ;situacion del STACK POINTER de la primera parte en LOW ENDIAN
;&0114
	db #0a ;Numero de sectores a leer primera parte carga 2
;&0115
	db #01 ;decide poner las tintas a negro para ultima parte de la carga.
;&0116-&0117
	db #0c,#c0 ;direccion de carga primera parte (carga2) en LOW ENDIAN
;&0118 comienzo bloque de parametros para carga parte 2
	db #00;lo usa para una comparacion que en SATAN siempre es la misma.
;&0019 - &011C NO SE USA EN SATAN
	db #00,#00,#00,#00
;&011D
	db #22 ;Numero de sectores a leer segunda parte (carga1)
;&011e - &011f
	db #3c,#03 ;direccion de carga segunda parte (carga1) en LOW ENDIAN 
;&0120-&0121
	db #3c,#03 ;direccion de EJECUCION segunda parte (carga1) en LOW ENDIAN 
;&0122-&0123
	db #00,#c0 ;situacion del STACK POINTER de la segunda parte en LOW ENDIAN
;&0124
	db #0b ;Numero de sectores a leer segunda parte (carga2)
;&0125
	db #01 ;decide poner las tintas a negro para ultima parte de la carga.
;&0126-&0127
	db #0c,#c0 ;direccion de carga primera parte (carga2) en LOW ENDIAN

;&0128 datos de texto para el menu de eleccion de parte
	db #1f ;codigo de control ASCII "US" para posicionar el cursor de texto en pantalla
	db #0f ;parametro posicion vertical en pantalla para US.
	db #0b ;parametro posicion horizontal en pantalla para US.
	db #31 ;"1"
	db #2d ;"-"
	db #20 ;" " espacio
	db #53 ;"S"
	db #41 ;"A"
	db #54 ;"T"
	db #41 ;"A"
	db #4e ;"N"
	db #20 ;" " espacio
	db #20 ;" " espacio
	db #49 ;"I"
	db #1f ;codigo de control ASCII "US" para posicionar el cursor de texto en pantalla
	db #0f ;parametro posicion vertical en pantalla para US.
	db #0d ;parametro posicion horizontal en pantalla para US.
	db #32 ;"2"
	db #2d ;"-"
	db #20 ;" " espacio
	db #53 ;"S" 
	db #41 ;"A"
	db #54 ;"T"
	db #41 ;"A"
	db #4e ;"N"
	db #20 ;" " espacio
	db #49 ;"I"
	db #49 ;"I"
	db #ff ;codigo que usa para determinar fin de texto.
	;[...]
	;;el resto de bytes hasta el 512 se rellema en &05
	;que es la marca "vacio" en los discos de AMSDOS.

	;-----------------------------------------------------------