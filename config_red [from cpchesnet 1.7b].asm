
.menu_red

ld a,1
call pon_borde

ld hl,colores_menu
call pon_colores



call deteccion_m4
;todo bien carry activado
;algo mal carry desactivado

;call desactiva_upper

call MENU_M4 ;displayamos despues de cargar mensajes.

.bucle_menu

 ;lectura de teclado
	ld a,#48 ;linea 40 del matrix de teclado
 	call lee_teclado
 	
        cp #FE ;es 1?
        jp z,elige_servidor
         
        cp #FD ;es 2?
        jp z,elige_cliente

        cp #FB ;es ESC;
        jp z,sal_programa

jp bucle_menu

.elige_servidor
 ld a,1
 ld (servidor),a
 call configuracion_Servidor
 ret


.elige_cliente
xor a
ld (servidor),a
call configuracion_cliente
ret





;---------------------------------CONFIGURACION SERVIDOR-----------------------------------------------
.configuracion_servidor

;OJO, EN ESTA FUNCION SE CREA IX COMO PUNTERO DE SOCKET Y DEBEMOS GUARDARLO PARA FUTURAS CONSULTAS!!
;IY SE CARGA COMO RESPONSE BUFFER!!!

call borra_creditos_txt

call texto_servidor ;solo para que nos limpie la zona

call elige_nick_pantalla

call elige_nick

call elige_puerto_txt
call elige_puerto
call guarda_puerto

call texto_servidor

.espera_espacio

        ld a,#45 ;preguntamos por space
        call lee_teclado
        cp #7F ;?espacio?
        jp z,escucha_cliente

jp espera_espacio

.escucha_cliente

call mensaje_escuchando_txt



;recuperamos puntero a nuestra maravilloso buffer
ld a,(response_buffer)
ld iyL,a
ld a,(response_buffer+1)
ld iyH,a

call activa_upper

.bucle_consigue_socket

; get a socket
 ld	hl,cmdsocket
 call	sendcmd
 ld	a,(iy+3)
 cp	255 ;#ff error, sino numero de socket
 jp z,socket_no_conseguido ;ojo, esto es si no encuentra socket, deberiamos pararlo, de segundas parece petar siempre

 ;a trae el socket conseguido

;primero lo guardamos, asi podremos cerrarlo cuando queramos
ld (socket_usandose),a

;OJO, SOLO PUEDE SER UN VALOR ENTRE 1 Y 4, YA QUE LA M4 SOLO DA ESOS 4 SOCKETS

CP 0
jp z,socket_no_conseguido
cp 5 ;mas de 4 dara no carry, con lo cual mal numero de socket.
jp nc,socket_no_conseguido


 push af; vamos a mostrarlo por pantalla
 call convierte_hex
 ld a,(numero_hex)
 ld (socket_libre),a
 ld a,(numero_hex+1)
 ld (socket_libre+1),a
; ld a,(numero_hex+2)
; ld (socket_libre),a
; ld a,(numero_hex+3)
; ld (socket_libre+3),a
 pop af ;recupero puerto
 
;PORT=numero definido por donde entrara la informacion

;SOCKET=IP+PORT


; store socket in predefined packets
			
			ld	(lsocket),a	; listen socket
			ld	(bsocket),a	; bind socket
			ld	(asocket),a	; accept socket
			ld	(rsocket),a	; receive socket
			ld	(sendsock),a	; send socket
			ld	(sendsock2),a	; send socket (welcome)
			ld	(clsocket),a	; close socket


; multiply by 16 and add to socket status buffer
			
			sla	a
			sla	a
			sla	a
			sla	a
			
			ld	hl,&FF06	; get sock info
			ld	e,(hl)
			inc	hl
			ld	d,(hl)
			ld	l,a
			ld	h,0
			add	hl,de	; sockinfo + (socket*4)
			push	hl

                        pop	ix ; ix puntero al estado del socket ; to current socket status
                        ;a veces coge #fe10 y a veces coge #fe20, sera por numero de socket?
                       ;guardamos socket para futuras consultas

;la guardamos en una variable para usos posteriores.
ld a,h
ld (puntero_estado_socket+1),a ;low endian

ld a,l
ld (puntero_estado_socket),a

;estado actual del socket --> INACTIVO (0)


; bind to IP addr and port
			
                        ;CUALQUIER ERROR CRITICO DETENDRA EL PROGRAMA			

			ld	hl,cmdbind	; fill in ip addr & port if predef not fitting.
			call	sendcmd
			ld	a,(iy+3)
			cp	0
			jp	nz,error_creando_socket
                        
                        IF LENGUAJE=ESPANOL
                         ld a,#53 ;S en ascii
                         ld (socket_creado),a
                         ld a,#49 ;I en ascii
                         ld (socket_creado+1),a
                        ENDIF

                        IF LENGUAJE=INGLES
                         ld a,#59 ;Y en ascii
                         ld (socket_creado),a
                         ld a,#53 ;S en ascii
                         ld (socket_creado+1),a
                        ENDIF

	;estado actual del socket --> INACTIVO (0)

;metemos aqui a ver si conseguimos buclear con cliente de primero mandando
.vuelve_a_escuchar ;PARECE MEJORAR LA ESPERA DE CLIENTE!!!
call recupera_socketyresponse ;puesto posterior a que funcionara PARECE MEJORAR LA ESPERA DE CLIENTE!
			
			ld	hl,cmdlisten	; tell it to listen to above port and ip addr
			call	sendcmd
			ld	a,(iy+3)
			cp	0
			jp	nz,error_escuchando_socket

	;estado actual del socket --> INACTIVO (0)


			IF LENGUAJE=ESPANOL
                         ld a,#53 ;S en ascii
                         ld (socket_aceptado),a
                         ld a,#49 ;I en ascii
                         ld (socket_aceptado+1),a
		        ENDIF

			IF LENGUAJE=INGLES
                         ld a,#59 ;Y en ascii
                         ld (socket_aceptado),a
                         ld a,#53 ;S en ascii
                         ld (socket_aceptado+1),a
		        ENDIF

			ld	hl,cmdaccept	; accept incoming connection..
			call	sendcmd
			ld	a,(iy+3)
			cp	0
			jp	nz,error_aceptando_conexion

;*******estado actual del socket --> ESPERANDO ENTRANTE (4)***********************************

			IF LENGUAJE=ESPANOL
                         ld a,#53 ;S en ascii
                         ld (acepto_conexiones),a
                         ld a,#49 ;I en ascii
                         ld (acepto_conexiones+1),a
                        ENDIF

			IF LENGUAJE=INGLES
                         ld a,#59 ;Y en ascii
                         ld (acepto_conexiones),a
                         ld a,#43 ;S en ascii
                         ld (acepto_conexiones+1),a
                        ENDIF

                        ;si llegamos aqui, ningun error
                        ;reiniciamos variable de error
                        ld a,#20
                        ld (numero_hex),a ;se uso variable numer_hex para display error
		        ld (numero_hex+1),a
  		
                     
                         call actualiza_estado_txt

;ahora esperamos por alguna conexion!

.espera_cliente	

	call flashea_borde ;inocua con los registros

        call actualiza_estado_txt ;CREO QUE no hace falta salvar registros

        ;creo que aqui podemos esperar por tecla esc para volver atras tambien...
	ld a,#48 ;tecla esc, si la pulsaron nos salimos del programa
	call lee_teclado

	cp #FB
 	jp z,cierra_conex_vuelve_menu ;cerramos conexion y volvemos a menu principal!


	ld	a,(ix)	; get socket status  (0 ==IDLE (OK), 1 == connect in progress, 2 == send in progress, 3 = remote closed conn, 4 == wait incoming)
	cp	4	; incoming connection in progress?
        ;ld (buscando_chars),a ;esta operacion no afecta flags
	jr	z,espera_cliente
	cp	0
	jp	nz,error_esperando_cliente
        ;por aqui hemos recibido conexion!!!
 
ld a,1
call pon_borde ;para quitar lo flasheado mientras esperabamos

;vamos a intentar leer el nick del otro cpc...

.espera_nick_cliente

;esta llamada devuelve carry si mensaje
call recibe_mensaje ;escuchamos al otro cpc, nos mandara el nick en hl (puntero a buffer de texto)
jp nc,espera_nick_cliente
;reescribimos pantalla, sino se nos cuela la frase "estado socket" que esta en recibe_mensaje

call activa_upper ;recibe_mensaje lo desactiva
;push hl
call mensaje_escuchando_txt
;pop hl

  ;nick recibido  
  
  ld hl,mensaje_recibido_txt
  ld de,nick_negras
  ld bc,9
  ldir

;ok, nick recibido, vamos a mandarle el nuestro!

ld hl,nick_blancas ;9bytes contando con el $
 ld de,sendtext
 ld bc,#0009 ;9bytes
 ldir ;metemos el nick!
 
 ld bc,#0009 ;metemos en bc el tamano a guardar
 ;ld (sendsize),bc ;guardamos primero la longitud a mandar
 
;bc tiene que estar cargado con tamano a enviar
;buffer sendtext tiene que estar cargado con los datos.

call envia_mensaje
  
 call mensaje_conexion_srv_txt

.espera_space

        ld a,#45 ;preguntamos por space
        call lee_teclado
        cp #7F ;?espacio?
        jp z,salta_juego_servidor

jp espera_space

.salta_juego_servidor
;call cierra_conexion
call desactiva_upper
ret ;VOLVEMOS A MAIN

.error_creando_socket
 ;a trae el codigo de error...
 call convierte_hex

 ld a,(numero_hex) ;solo nos interesa el primero
 ld (errornum_txt),a
 
 ld a,#4E ;N en ascii
 ld (socket_creado),a
 ld a,#4F ;O en ascii
 ld (socket_creado+1),a
 call actualiza_estado_txt
 call cierra_conexion
 jp bucle_consigue_socket
ret

.error_escuchando_socket

 ;a trae el codigo de error...
 call convierte_hex
 ld a,(numero_hex) ;solo nos interesa el primero
 ld (errornum_txt),a

 ld a,#4E ;N en ascii
 ld (socket_aceptado),a
 ld a,#4F ;O en ascii
 ld (socket_aceptado+1),a
 call actualiza_estado_txt
; call cierra_conexion
 jp vuelve_a_escuchar

; jp bucle_consigue_socket

ret

.error_aceptando_conexion
 ;a trae el codigo de error...
 call convierte_hex
 ld a,(numero_hex) ;solo nos interesa el primero
 ld (errornum_txt),a

 ld a,#4E ;N en ascii
 ld (acepto_conexiones),a
 ld a,#4F ;O en ascii
 ld (acepto_conexiones+1),a
 call actualiza_estado_txt
;call cierra_conexion
 jp vuelve_a_escuchar ; bucle_consigue_socket

ret

.socket_no_conseguido

 ld a,#4E ;N en ascii
 ld (socket_libre),a
 ld a,#4F ;O en ascii
 ld (socket_libre+1),a

ld a,#2d ;codigo ascii guion
ld (errornum_txt),a
call actualiza_estado_txt
 
 ;call cierra_conexion
 jp bucle_consigue_socket

ret

.error_esperando_cliente
;call cierra_conexion 

ld a,#2d ;codigo ascii guion
ld (errornum_txt),a
call actualiza_estado_txt

jp bucle_consigue_socket ;pos salto otra vez... no es seguro que funcione asi
ret


;---------------------------------FIN CONFIGURACION SERVIDOR-----------------------------------------------

;---------------------------------CONFIGURACION CLIENTE-----------------------------------------------
.configuracion_cliente

call borra_creditos_txt


call texto_cliente ;para borrar pantalla

call elige_nick_pantalla

call elige_nick

call texto_cliente

.espera_spc

        ld a,#45 ;preguntamos por space
        call lee_teclado
        cp #7F ;?espacio?
        jp z,peticion_ip

jp espera_spc

.peticion_ip ;por aqui tambien entrara ante cualquier error de conexion en pantalla posterior

call elige_ip_pantalla

call elige_ip

call elige_puerto_txt
call elige_puerto
call guarda_puerto

;OK tenemos ip en ASCII, empezamos con el codigo de duke...
;variable ip_temp_txt

ld hl,ip_servidor_introducida ;cada byte es un numero o un punto
                              ;OJO al borrar en la peticion de ip metemos #20 como espacio.
                              ;aqui debemos meter #0, sino se vuelve loca la funcion conversora!

;primero movemos ip a nuestro txt
ld de,ip_servidor_txt
ld bc,15 ;correcto
ldir

ld hl,ip_servidor_introducida
;este buffer ocupa 14 bytes, 4x3 numeros + 3 puntos =15 ;el ultimo byte el 16 es la $ que ya

;limpiamos #20 espacios y $ final
ld b,15 ;bucle de limpieza ip comprobadas iteraciones

.bucle_fuera_spc

ld a,(hl)
cp #20 ;es espacio
jp z,fuera_spc
 jp sigue_mirando
.fuera_spc
ld a,#00
ld (hl),a
.sigue_mirando
inc hl

djnz bucle_fuera_spc
;quitamos el $, hl esta encima
ld (hl),a
;ya tenemos la ip totalmente limpia

ld hl,ip_servidor_introducida
call ascii2dec 
ld	(ip_addr+3),a

call	ascii2dec
ld	(ip_addr+2),a

call	ascii2dec
ld	(ip_addr+1),a

call	ascii2dec
ld	(ip_addr),a

;OJO, EL PUERTO ESTA CONFIGURADO DEBAJO DE LA VARIABLE IP_ADDR Y ESTA FIJADO A &1234

;hl esta ahora en decimal es decir cada posicion de memoria seria 1 9 2 . 1 6 8 . 0 . 1

;aqui duke mira si esta la rom de la m4 en el sistema, pero nosotros ya lo hacemos al principio de todo del programa
;nunca se llegara aqui si no hay m4

call mensaje_conectando

.cliente_tcp	

call activa_upper

.bucle_consigue_socket_cli	 ;por aqui viene si no consigue conectar...
;AQUI CONSEGUIMOS SOCKET EN LA M4 LOCAL, ESTA LIMITADA A 4 SOCKETS

       call activa_upper ;solo por si acaso...

        ld a,1
        call pon_borde ;para asegurarnos de que nadie nos cambio el borde

        ;creo que aqui podemos esperar por tecla esc para volver atras tambien...
	ld a,#48 ;tecla esc, si la pulsaron nos salimos del programa
	call lee_teclado

	cp #FB
 	jp z,vuelvete_pantalla_ip_no_socket	

call recupera_socketyresponse ;aunque ix no se use de primeras, despues ya vendra cargado

; get a socket
;AQUI CONSEGUIMOS SOCKET EN LA M4 LOCAL, ESTA LIMITADA A 4 SOCKETS

ld	hl,cmdsocket
call	sendcmd
ld	a,(iy+3)
cp	255;#ff error, sino numero de socket
jp z,socket_no_conseguido_cli ;SI NO CONSIGUE SOCKET ES PORQUE ALGO PASA CON LA M4 QUE NO DA SOCKETS...

;a trae el socket conseguido
;a trae el socket_conseguido
;primero lo guardamos, asi podremos cerrarlo cuando queramos
ld (socket_usandose),a

 push af; vamos a mostrarlo por pantalla
 call convierte_hex
 ld a,(numero_hex)
 ld (socket_libre),a
 ld a,(numero_hex+1)
 ld (socket_libre+1),a
 pop af ;recupero puerto


ld a,(socket_usandose) ;doble chequeo
;OJO, SOLO PUEDE SER UN VALOR ENTRE 1 Y 4, YA QUE LA M4 SOLO DA ESOS 4 SOCKETS
CP 0
jp z,socket_fuera_rango_cli
cp 5 ;mas de 4 dara no carry, con lo cual mal numero de socket.
jp nc,socket_fuera_rango_cli

			
			; store socket in predefined packets
			
			ld	(csocket),a
			ld	(clsocket),a
			ld	(rsocket),a
			ld	(sendsock),a
			
			
			; multiply by 16 and add to socket status buffer
			
			sla	a
			sla	a
			sla	a
			sla	a
			
			ld	hl,&FF06	; get sock info
			ld	e,(hl)
			inc	hl
			ld	d,(hl)
			ld	l,a
			ld	h,0
			add	hl,de	; sockinfo + (socket*4)
			push	hl
			pop	ix		; ix ptr to current socket status

;guardamos  puntero a estado socket en una variable para usos posteriores.
ld a,h
ld (puntero_estado_socket+1),a ;low endian

ld a,l
ld (puntero_estado_socket),a


			; connect to server
;AQUI SI PONEMOS UNA IP FICTICIA NO SE ENTERARA,
;ESE ERROR_CONECTANDO_SERVER SOLO ES SI EL SOCKET ESTA POR DEBAJO DE 1 O POR ENCIMA DE 4

			
			ld	hl,cmdconnect
			call	sendcmd
			ld	a,(iy+3)
			cp	255 ;#FF error
			jp	z,error_conectando_server_cpchessnet ;volvera a pedir ip

                     IF LENGUAJE=ESPANOL
                        ld a,#53 ;S en ascii
 			ld (conectado_socket_txt),a
 			ld a,#49 ;I en ascii
			ld (conectado_socket_txt+1),a
                     ENDIF

                     IF LENGUAJE=INGLES
                        ld a,#59 ;Y en ascii
 			ld (conectado_socket_txt),a
 			ld a,#53 ;S en ascii
			ld (conectado_socket_txt+1),a
                     ENDIF


 call actualiza_estado_cli


.vuelve_intentar_conexion
call recupera_socketyresponse

wait_connect:

       call flashea_borde ;inocua con los registros

       ld a,#72 ;r en ascii
       ld (conectado_a_serv_txt),a
       ld a,#70 ;p en ascii
       ld (conectado_a_serv_txt+1),a
       call actualiza_estado_cli

        ;creo que aqui podemos esperar por tecla esc para volver atras tambien...
	ld a,#48 ;tecla esc, si la pulsaron nos salimos del programa
	call lee_teclado

	cp #FB
 	jp z,cierra_conex_vuelve_menu ;volvemos a menu principal!




			ld	a,(ix)	; get socket status  (0 ==IDLE (OK), 1 == connect in progress,
                                        ; 2 == send in progress)
			

                        cp	1 ; connect in progress?
			jr	z,wait_connect
			cp	0
			jr	z,connect_ok
                   	
			jp	no_conecto ;volvera a pedir ip

connect_ok:	

IF LENGUAJE=ESPANOL
 ld a,#53 ;s en ascii
 ld (conectado_a_serv_txt),a
 ld a,#49 ;i en ascii
 ld (conectado_a_serv_txt+1),a
ENDIF

IF LENGUAJE=INGLES
 ld a,#59 ;Y en ascii
 ld (conectado_a_serv_txt),a
 ld a,#53 ;S en ascii
 ld (conectado_a_serv_txt+1),a
ENDIF

 call actualiza_estado_cli

ld a,1
call pon_borde ;para quitar lo flasheado mientras esperabamos

;vamos a intentar mandar nuestro nick


.envia_nick
 ld hl,nick_negras ;9bytes contando con el $
 ld de,sendtext
 ld bc,#0009 ;9bytes
 ldir ;metemos el nick!
 
 ld bc,#0009 ;metemos en bc el tamano a enviar
; ld (sendsize),bc ;guardamos primero la longitud a mandar
 
;bc tiene que estar cargado con tamano a enviar
;buffer sendtext tiene que estar cargado con los datos.

call envia_mensaje

;nick enviado a servidor.

;vamos a intentar leer el nick del otro cpc...
.espera_nick_servidor
;esta funcion nos devuelve carry activado si hay mensaje pendiente.
call recibe_mensaje ;escuchamos al otro cpc, nos mandara el nick en hl (puntero a buffer de texto)
jp nc,espera_nick_servidor

  ;nick recibido  
  
call activa_upper ;recibe_mensaje lo desactiva
 
  ld hl,mensaje_recibido_txt
  ld de,nick_blancas
  ld bc,9
  ldir


call mensaje_conectado_cli_txt


.espera_sp

        ld a,#45 ;preguntamos por space
        call lee_teclado
        cp #7F ;?espacio?
        jp z,salta_juego_cliente

jp espera_sp

.salta_juego_cliente
;call cierra_conexion ;DEJAMOS CONEXION ABIERTA DURANTE EL JUEGO
call desactiva_upper

ret ;VOLVEMOS A MAIN



.no_conecto
 ;ld a,24
 ;call pon_borde

 ld a,#4E ;N en ascii
 ld (conectado_a_serv_txt),a
 ld a,#4F ;O en ascii
 ld (conectado_a_serv_txt+1),a
 call actualiza_estado_cli

jp vuelvete_pantalla_ip ;pedimos ip otra vez

.error_conectando_server_cpchessnet
;solo llega aqui si del otro lado hay otro cpchessnet server pero no le acepta la conexion.
;ld a,15
;call pon_borde

 ld a,#4E ;N en ascii
 ld (conectado_socket_txt),a
 ld a,#4F ;O en ascii
 ld (conectado_socket_txt+1),a
 call actualiza_estado_cli
jp vuelvete_pantalla_ip ;pedimos otra vez la ip


.socket_no_conseguido_cli ;por aqui es si devuelve #ff la lectura del socket
 ld a,#4E ;N en ascii
 ld (socket_libre),a
 ld a,#4F ;O en ascii
 ld (socket_libre+1),a
 call actualiza_estado_cli
 ;call cierra_conexion ;ojo con cerrar conexion aqui que no hemos conseguido socket
 jp bucle_consigue_socket_cli
ret

.socket_fuera_rango_cli
 call actualiza_estado_cli
 jp bucle_consigue_socket_cli

;---------------------------------FIN CONFIGURACION cliente-----------------------------------------------

.vuelvete_pantalla_ip

call resetea_pantalla_ip ;para borrar la ip anterior puesta y que ya habia sido procesada

;mostramos un mensaje en pantalla arriba de los cuadros que solo se mostrara si viene por aqui

ld hl,ip_no_servidor_txt
ld de,#c14b
call imprime_texto

call cierra_conexion


jp peticion_ip ;esta justo despues de peticion de nick en configuracion cliente.

ret ;por aqui no deberia pasar neva

IF LENGUAJE=ESPANOL
.ip_no_servidor_txt dm "ERROR, IP INTRODUCIDA NO TIENE SERVIDOR CPCHESSNET ACTIVO!$"
ENDIF

IF LENGUAJE=INGLES
.ip_no_servidor_txt dm "  ERROR, TYPED IP DOESNT HAVE ACTIVE CPCHESSNET SERVER!   $"
ENDIF

;----------------------------------------------------------

.vuelvete_pantalla_ip_no_socket

call resetea_pantalla_ip ;para borrar la ip anterior puesta y que ya habia sido procesada

;mostramos un mensaje en pantalla arriba de los cuadros que solo se mostrara si viene por aqui

ld hl,ip_no_socket_txt
ld de,#c14b
call imprime_texto

call cierra_conexion


jp peticion_ip ;esta justo despues de peticion de nick en configuracion cliente.

ret ;por aqui no deberia pasar neva

IF LENGUAJE=ESPANOL
.ip_no_socket_txt dm "ERROR, NO HE CONSEGUIDO SOCKET LIBRE, SI PERSISTE ERROR, RESETEA M4!$"
ENDIF

IF LENGUAJE=INGLES
.ip_no_socket_txt dm "  ERROR, I DIDNT GET A FREE SOCKET, IF ERROR CONTINUES, RESET M4!   $"
ENDIF
;-----------------------------CIERRA_CONEXION-----------------------------------------

.cierra_conexion


call activa_upper ;por si acaso!

call recupera_socketyresponse ;recuperamos ix e iy

;metemos numero de socket a cerrar en comando c_netclose
ld a,(socket_usandose)
ld (clsocket),a

ld hl,cmdclose
call sendcmd	

ret

;---------------------
.cierra_conex_vuelve_menu

call cierra_conexion
call desactiva_upper
 .vuelve_menu ;punto de entrada por si no conseguimos socket y pulsamos esc
jp main

;-----------------------




;------------------------------FUNCION PARA RECIBIR MENSAJE DEL OTRO CPC----------------------------------

.recibe_mensaje

;devuelve carry si hay mensaje pendiente.
;si hay mensaje devuelve la variable mensaje_recibido_txt con el mensaje

;ld a,16
;call pon_borde

call resetea_byte_control

;call flashea_borde ;lo dejamos para que nos flashee borde cuando se recibe

;call activa_upper ;no altera flags

call recupera_socketyresponse ;recuperamos iy e ix

;you do not need to wait for anything unless you see something in the buffer.
; Anyting in buffer ? if yes, wait recv
.mira_si_entran_datos

call guarda_estado_red
call actualiza_textos_net


ld	bc,255	;tamano de buffer para recibir mensaje, OJO CON CORROMPER BC ANTES DE RECIBIR EL DATO



			call	recvp

			;cuidado, al volver a viene puede venir cargado... con 1

                        cp	&FF
			jr	z, exit_closep	
			cp	3
			jr	z, exit_closep
			xor	a
			cp	c ;creo que bc es tamano de datos
			jr	nz, got_msgp
			cp	b ;creo que bc es tamano de datos, comprueba que no sea 00
                        JR     NZ,GOT_MSGP
                          ;originalmente Duke espera aqui en bucle, pero porque no hace otra cosa en su prg.
      	         	;  ld a,NO
           		; ld (mensaje_recibido),a
			
			call resetea_byte_control

                        call guarda_estado_red
			call actualiza_textos_net

                     ;   call desactiva_upper ;no altera flags
                        
                         xor a ;mensaje no recibido
                        ret ;nos salimos para que por lo menos nos funcione el teclado

got_msgp:

;ld a,13
;call pon_borde

			push	iy ;iy trae #e800 ;evidentemente apunta a la upper de la m4

			pop	hl ;hl es el puntero del texto!!!!!
			ld	de,&6 ;le suma, supongo que lo primero seran bytes de control
			add	hl,de		; received text pointer

                      push hl
                      push bc
                      ld de,mensaje_recibido_txt
                      ld bc,255 ;lo maximo que se puede recibir
                      ldir
                      pop bc
                      pop hl

;recuerda, el puntero hl apunta a la upper de la m4 #e800
;comprobado este ret nos lleva a despues de call guarda_estado_ret, pero por algun motivo queda flipado alli
			
                      ; ld a,SI
                      ; ld (mensaje_recibido),a

                        call guarda_estado_red
			call actualiza_textos_net

;                        call desactiva_upper ;no altera flags

                        scf ;para indicar que recibimos mensaje
                        ret ;volvemos a funcion que nos llamo con el buffer cargado con el mensaje.
			


exit_closep:
 

            call resetea_byte_control

            ;ld a,NO
            ;ld (mensaje_recibido),a
          ;  call desactiva_upper ;no altera flags

                        call guarda_estado_red
			call actualiza_textos_net

            xor a ;no mensaje
	    ret ;nos devuelve a la funcion que llamo a recibe_mensaje
			
			; recv tcp data
			; in
			; bc = receive size
			; out
			; a = receive status
			; bc = received size 

			
recvp:		; connection still active
			ld	a,(ix)			; 
			cp	3				; socket status  (3 == remote closed connection)
			ret	z
                         
                        ; check if anything in buffer ?
			ld	a,(ix+2)
			cp	0
			jr	nz,recv_contp
			ld	a,(ix+3)
			cp	0
			jr	nz,recv_contp
			ld	bc,0
			ld	a,1 
                       
			ret ;vuelve a call recvp
recv_contp:		

	
			; set receive size
			ld	a,c
			ld	(rsize),a
			ld	a,b
			ld	(rsize+1),a
			
                       	ld	hl,cmdrecv
			call	sendcmd
			
			ld	bc,0
			ld	a,(iy+3)
			cp	0				; all good ?
			jr	z,recv_okp
                   
                        ret ;vuelve al call recv

 		
recv_okp:

;cuidado que a viene cargado con 0, ojo

		
			ld	c,(iy+4)
			ld	b,(iy+5) ;tamano de lo recibido

			ret ;vuelve despues del call recv!!

;.malito
; ld a,NO
; ld (mensaje_recibido),a
; xor a ;no se recibio mensaje
; ret


;------------------------------FIN FUNCION PARA RECIBIR MENSAJE DEL OTRO CPC----------------------------------

;-------------------------------FUNCION PARA ENVIAR MENSAJE AL OTRO CPC---------------------------------------

.envia_mensaje
;bc tiene que traer tamano mensaje
;buffer sendtext tiene que tener cargado el mensaje a enviar.

ld (sendsize),bc ;guardamos primero la longitud a mandar

;call flashea_borde ;asi siempre nos flasheara avisando de envio
                   ;si se queda flasheando enternamente es que el otro no recibe el mensaje!


;call activa_upper ;activamos rom m4 (no altera flags)
;ld a,0
;call pon_borde ;PETA POR AQUI SI LE LLAMAMOS MUCHAS VECES....

call recupera_socketyresponse

 wait_send:	        ld	a,(ix)
			;cp	2			; send in progress?
		;	jr	z,wait_send	; Could do other stuff here!
			cp	0
			call	nz,error_envio	
			
			ld	hl,5
			add	hl,bc
			ex	de,hl
			ld	hl,cmdsend
			ld	(hl),e
			call	sendcmd

						
			; reset size
			ld	hl,0
			ld	(sendsize),hl

;ld a,NO
;ld (mensaje_pendiente),a

;call desactiva_upper

                        call guarda_estado_red
			call actualiza_textos_net

scf ;mensaje bien enviado
ret


.error_envio

;ld a,SI
;ld (mensaje_pendiente),a

;call desactiva_upper

                        call guarda_estado_red
			call actualiza_textos_net 

xor a ;mensaje no enviado
ret





;------------------------------ELIGE NICK-------------------------------------
.elige_nick

;segun sea servidor o cliente apuntamos ix a una variable u otra
ld a,(servidor)
cp 0 ;cliente 0, servidor 1
jp z,n_negras

ld ix,nick_blancas ;puntero a buffer

jp elige_pues

.n_negras
ld ix,nick_negras



.elige_pues

ld b,9 ;8 caracteres, el ultimo no se escribe

push bc
;push hl



call escanea_teclado ;lo hacemos una a mayores, porque a veces nos trae el espacio de la pantalla actual




.bucle_teclado

;borramos el keymap para quitar pulsaciones fantasmas
ld de,keymap
ld hl,borra_keymap
ld bc,10
ldir

;;cp 0 ;todos los caracteres agotados?
call lee_teclado_ascii ;dentro esta escanea_teclado

jp z,bucle_teclado

;a viene con tecla ascii

;primero miramos que nos pasemos de caracteres
pop bc
dec b
push bc
ld c,a ;guardamos un momento a
ld a,b
cp 0 ;todo escrito?
jp z,todo_escrito

ld a,c ;recuperamos nuestro ascii

;comparamos que no sea enter
cp 13
jp z,nos_vamos  ;volvemos directamente, si no escribio nada es su problema

cp #98 ;tecla retroceso
jp nz,escribe
 ;hemos pulsado borrar

 pop bc
 ;necesitamos saber si b=1 para no borrar de mas y desbordar ix
 ld a,b
 cp 8 ;primer caracter (todos los chars sin escribir)
 jp z,desborda_borrando

 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a

 jp hemos_borr_sigue ;sino se empena en volver a escribir un espacio

.escribe
ld (ix),a
inc ix


.hemos_borr_sigue
call elige_nick_pantalla ;reescribimos todo y se va cambiado el nick en pantalla

jp bucle_teclado

.desborda_borrando
inc b ;sino nos lo decrementa en el bucle si haber hecho nada con el
push bc ;metmos bc entes de nada en pila
;pasamos de todo
jp hemos_borr_sigue

.todo_escrito
;solo nos interesa que borre o de a enter
ld a,c ;recuperamos tecla ascii
cp 13
jp z,nos_vamos

cp #98
jp z,borra_char

;solo si no es retroceso o enter
pop bc
inc b ;sino se nos desborda en el proximo dec b
push bc


jp bucle_teclado


.borra_char

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a
 pop bc
 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc
 jp hemos_borr_sigue
 
.nos_vamos
pop bc ;quitamos un push sobrante

ret


;----------------------------------------------------------------------------------


;------------------------------ELIGE IP-------------------------------------
.elige_ip

;seguramente podria compartir un monton de codigo con elige_nick, pero whatever

ld ix,ip_servidor_introducida ;puntero a buffer

ld b,16 ;15 caracteres, el ultimo no se escribe

push bc


call escanea_teclado ;lo hacemos una a mayores, porque a veces nos trae el espacio de la pantalla actual


.bucle_teclado_ip

;OJO, AL METER #20 COMO ESPACIO, SE VUELVE LOCA LA RUTINA CONVERSORA A DEC, CONTROLARLO AL SALIR DE ESTA FUNC.

;borramos el keymap para quitar pulsaciones fantasmas
ld de,keymap
ld hl,borra_keymap
ld bc,10
ldir

;;cp 0 ;todos los caracteres agotados?
call lee_teclado_ascii ;dentro esta escanea_teclado

jp z,bucle_teclado_ip

;a viene con tecla ascii

;primero miramos que nos pasemos de caracteres
pop bc
dec b
push bc
ld c,a ;guardamos un momento a
ld a,b
cp 0 ;todo escrito?
jp z,todo_escrito_ip

ld a,c ;recuperamos nuestro ascii

;comparamos que no sea enter
cp 13
jp z,nos_vamos_ip  ;volvemos directamente, si no escribio nada es su problema

cp #98 ;tecla retroceso
jp nz,escribe_ip
 ;hemos pulsado borrar

 pop bc
 ;necesitamos saber si b=1 para no borrar de mas y desbordar ix
 ld a,b
 cp 15 ;primer caracter (todos los chars sin escribir)
 jp z,desborda_borrando_ip

 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a

 jp hemos_borr_sigue_ip ;sino se empena en volver a escribir un espacio

.escribe_ip
ld (ix),a
inc ix


.hemos_borr_sigue_ip
call elige_ip_pantalla ;reescribimos todo y se va cambiado el nick en pantalla

jp bucle_teclado_ip

.desborda_borrando_ip
inc b ;sino nos lo decrementa en el bucle si haber hecho nada con el
push bc ;metmos bc entes de nada en pila
;pasamos de todo
jp hemos_borr_sigue_ip

.todo_escrito_ip
;solo nos interesa que borre o de a enter
ld a,c ;recuperamos tecla ascii
cp 13
jp z,nos_vamos_ip

cp #98
jp z,borra_char_ip

;solo si no es retroceso o enter
pop bc
inc b ;sino se nos desborda en el proximo dec b
push bc


jp bucle_teclado_ip


.borra_char_ip

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a
 pop bc
 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc
 jp hemos_borr_sigue_ip
 
.nos_vamos_ip
pop bc ;quitamos un push sobrante

ret


;----------------------------------------------------------------------------------

;------------------------------ELIGE PUERTO-------------------------------------
.elige_puerto

ld ix,puerto_a_usar_txt ;aqui es comun a servidor y cliente

ld b,6 ;5 caracteres, el ultimo no se escribe

push bc

call escanea_teclado ;lo hacemos una a mayores, porque a veces nos trae el espacio de la pantalla actual

.bucle_teclado_puerto

;borramos el keymap para quitar pulsaciones fantasmas
ld de,keymap
ld hl,borra_keymap
ld bc,10
ldir

call lee_teclado_ascii ;dentro esta escanea_teclado

jp z,bucle_teclado_puerto

;a viene con tecla ascii

;primero miramos que nos pasemos de caracteres
pop bc
dec b
push bc
ld c,a ;guardamos un momento a
ld a,b
cp 0 ;todo escrito?
jp z,todo_escrito_puerto

ld a,c ;recuperamos nuestro ascii

;comparamos que no sea enter
cp 13
jp z,nos_vamos_puerto  ;volvemos directamente, si no escribio nada es su problema

cp "." ;no permitimos puntos aqui
jp z,pasa_del_punto

cp #98 ;tecla retroceso
jp nz,escribe_puerto
 ;hemos pulsado borrar

 pop bc
 ;necesitamos saber si b=1 para no borrar de mas y desbordar ix
 ld a,b
 cp 5 ;primer caracter (todos los chars sin escribir)
 jp z,desborda_borrando_puerto

 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a

 jp hemos_borr_sigue_puerto ;sino se empena en volver a escribir un espacio

.escribe_puerto
ld (ix),a
inc ix


.hemos_borr_sigue_puerto
call elige_puerto_txt ;reescribimos todo y se va cambiado el nick en pantalla

jp bucle_teclado_puerto

.desborda_borrando_puerto
inc b ;sino nos lo decrementa en el bucle si haber hecho nada con el
push bc ;metmos bc entes de nada en pila
;pasamos de todo
jp hemos_borr_sigue_puerto

.todo_escrito_puerto
;solo nos interesa que borre o de a enter
ld a,c ;recuperamos tecla ascii
cp 13
jp z,nos_vamos_puerto

cp #98
jp z,borra_char_puerto

;solo si no es retroceso o enter
pop bc
inc b ;sino se nos desborda en el proximo dec b
push bc


jp bucle_teclado_puerto


.borra_char_puerto

 dec ix
 ld a,#20 ;codigo espacio
 ld (ix),a
 pop bc
 inc b ;por la borrada
 inc b ;por haber quitado de antemano ya
 push bc
 jp hemos_borr_sigue_puerto
 
.nos_vamos_puerto
pop bc ;quitamos un push sobrante

ret

.pasa_del_punto
 pop bc
 inc b ;se decremento antes de mirar si es punto
 push bc
 jp bucle_teclado_puerto


;----------------------------------------------------------------------------------

;---------------------GUARDA_PUERTO---------------------------------------------
.guarda_puerto
;metemos en su sitio el puerto en DECIMAL
;por ejemplo, 6128 tiene que convertirse en #17f0

;tan pronto encontremos un espacio #20 no seguimos mirando...

;vaciamos los espacios posibles
ld hl,puerto_a_usar_txt
ld de,puerto_temp


.bucle_limpieza_puerto
ld a,(hl)
cp #20 
jp z,limpia_blanco

cp #24 ;final de linea $
jp z,acabada_limpieza

;por aqui es un digito

ld (de),a
inc de

.limpia_blanco
inc hl

jp bucle_limpieza_puerto

.acabada_limpieza

;YA NO HAY ESPACIOS EN NUMERO


ld hl,puerto_temp
call ascii2decpuerto ;hl se codifica el mismo, es decir, la zona de memoria que apuntaba hl
;corroborado, funciona bien funcion anterior. los #FF estan conservados.


xor a
ld b,a ;contador de digitos introducidos

ld hl,puerto_temp

.bucle_cuenta_digitos

  ld a,(hl)
  cp #FF ;fin digito
  jp z,fin_cuenta_digitos
 inc b
 inc hl
 jp bucle_cuenta_digitos

.fin_cuenta_digitos
;correcto, b lleva tantos digitos como tiene el numero
;maximo 5 digitos

ld hl,puerto_temp

ld a,b
cp #5
jp z,son_5_digitos

cp #4
jp z,son_4_digitos

cp #3
jp z,son_3_digitos

cp #2
jp z,son_2_digitos

cp #1
jp z,son_1_digitos

;por aqui no deberia pasar JAMAS

jp main ;lo mandamos a main antes de petar todo

;ahora caeremos en cascada

.son_5_digitos
;multiplicamos el primero por 10.000
 ;hl ya esta cargado
 xor a
 ld b,a ;siempre 0
 ld a,(hl)
 ld c,a ;primer digito

 ld de,10000 

 push hl ;salvaguardamos puntero
 call multiplica16bit
 ;DE -> MITAD ALTA [NUNCA TENDRA NADA]
 ;HL -> MITAD BAJA [SOLO NOS INTERESA HL]
 ld a,h
 ld (variable_bucle+1),a
 ld a,l
 ld (variable_bucle),a
 
 pop hl ;recuperamos puntero de puerto
 inc hl

.son_4_digitos
 ;multiplicamos por 1000
 xor a
 ld b,a ;siempre 0
 ld a,(hl)
 ld c,a ;primer digito

 ld de,1000 

 push hl ;salvaguardamos puntero
 call multiplica16bit

 ;DE -> MITAD ALTA [NUNCA TENDRA NADA]
 ;HL -> MITAD BAJA [SOLO NOS INTERESA HL]
 
 ld bc,variable_bucle
 ld a,(bc)
 ld e,a
 inc bc
 ld a,(bc)
 ld d,a
 add hl,de
 ld a,h
 ld (variable_bucle+1),a
 ld a,l
 ld (variable_bucle),a
 pop hl ;recuperamos puntero a puerto
 inc hl


.son_3_digitos
 ;multiplicamos por 100
 xor a
 ld b,a ;siempre 0
 ld a,(hl)
 ld c,a ;primer digito

 ld de,100 

 push hl ;salvaguardamos puntero
 call multiplica16bit

 ;DE -> MITAD ALTA [NUNCA TENDRA NADA]
 ;HL -> MITAD BAJA [SOLO NOS INTERESA HL]
 
 ld bc,variable_bucle
 ld a,(bc)
 ld e,a
 inc bc
 ld a,(bc)
 ld d,a
 add hl,de
 ld a,h
 ld (variable_bucle+1),a
 ld a,l
 ld (variable_bucle),a
 pop hl ;recuperamos puntero a puerto
 inc hl



.son_2_digitos
 ;multiplicamos por 10

xor a
 ld b,a ;siempre 0
 ld a,(hl)
 ld c,a ;primer digito

 ld de,10 

 push hl ;salvaguardamos puntero
 call multiplica16bit

 ;DE -> MITAD ALTA [NUNCA TENDRA NADA]
 ;HL -> MITAD BAJA [SOLO NOS INTERESA HL]
 
 ld bc,variable_bucle
 ld a,(bc)
 ld e,a
 inc bc
 ld a,(bc)
 ld d,a
 add hl,de
 ld a,h
 ld (variable_bucle+1),a
 ld a,l
 ld (variable_bucle),a
 pop hl ;recuperamos puntero a puerto
 inc hl


.son_1_digitos
 ;multiplicamos por 1

xor a
 ld b,a ;siempre 0
 ld a,(hl)
 ld c,a ;primer digito

 ld de,1

 push hl ;salvaguardamos puntero
 call multiplica16bit

 ;DE -> MITAD ALTA [NUNCA TENDRA NADA]
 ;HL -> MITAD BAJA [SOLO NOS INTERESA HL]
 
 ld bc,variable_bucle
 ld a,(bc)
 ld e,a
 inc bc
 ld a,(bc)
 ld d,a
 add hl,de
 ld a,h
 ld (variable_bucle+1),a
 ld a,l
 ld (variable_bucle),a
 pop hl ;recuperamos puntero a puerto
 inc hl

;POR AQUI ACABAMOS DE MULTIPLICAR, tenemos en variable_bucle el numero de interaciones

ld de,#0000

 ld a,(variable_bucle+1)
 ld h,a
 ld a,(variable_bucle)
 ld l,a

.bucle_iteraciones
 
 ld a,l
 cp #00
 jp nz,iterame

 ;por aqui l es 0
 ld a,h
 cp #00
 jp nz,iterame

 ;por aqui nos salimos
 ;de esta convertido a decimal de manera cutrona!
 jp acabada_conversion

.iterame
  inc de
  dec hl
  
  jp bucle_iteraciones

.acabada_conversion

;hay que guardar el puerto!!!
;puerto bien!!!! corroborado!!!!

;metemos tanto en servidor como en cliente, al fin y al cabo son los mismos puertos
;y en cada lado, cada uno vera lo que mete!!

;hay que meter en bport y cport

ld hl,bport
ld a,e
ld (hl),a
inc hl
ld a,d
ld (hl),a

ld hl,cport
ld a,e
ld (hl),a
inc hl
ld a,d
ld (hl),a

;reponemos puerto_a_usar_txt a 6128, para la siguiente vez

ld hl,puerto_a_usar_orig
ld de,puerto_a_usar_txt
ld bc,6
ldir ;CORRECTO

ret ;TODO CORRECTO

.puerto_temp ;los #FF son marcas de agua de fin de numero introducido.
db #FF ;1
db #FF ;2
db #FF ;3
db #FF ;4
db #FF ;5
db #FF ;por si mete los 5, el 6 es fuera.

.variable_bucle ;sumaremos todo aqui y sera lo que tengamos que iterar!
db #00
db #00

.puerto_a_usar_orig
dm '6128'
db #20 ;lo maximo son 5 digitos 65535
dm '$' ;fin de linea

;-----------------------------------------------

;----------------------------------------------------------------------------------------------------
.recibe_confirmacion_tablero

ld hl,mensaje_recibido_txt ;la primera vez el byte esta a #00
ld a,(hl)
cp #CA ;en algun momento es chat?
;jr z,guarda_variable_chat
jr nz,no_guardes_mas
;guardamos variable
 ld (mensaje_anterior_confirmacion),a

.no_guardes_mas 
;mientras no nos llegue #FE, repetiremos infinitamente, a la larga habra que hacer timeouts


  ;ld hl,enviando_tablero1
   ld a,(puntero_alta) ;cargamos hl
   ld h,a
   ld a,(puntero_baja)
   ld l,a

   ld de,enviando_tablero_fin

   ld a,l
   cp e
   jp nz,imprime_mensaje
    ld a,h
    cp d
   jp nz,imprime_mensaje

     ;volvemos a meter puntero 1
     ld hl,enviando_tablero1
     ld a,h
     ld (puntero_alta),a
     ld a,l
     ld (puntero_baja),a

   .imprime_mensaje
   push hl ;guardamos puntero mensaje
  ;imprimimos mensaje...
   ld de,#c533
   call imprime_texto
   pop hl
   ;sumamos desplazamiento 
    ld de,0024 ;tamano de mensaje
    add hl,de
    ld a,h
    ld (puntero_alta),a
    ld a,l
    ld (puntero_baja),a

  
;llamado para mensaje de chat
;llamado despues de recibe mensaje esta a 00
;LLAMADO ANTES tb esta a 00, alguien me ha sobreescrito el byte de recepcion!!
 

 call recibe_mensaje

  jp nc,sal_repite_envio_tablero
  ;hemos recibido un mensaje, si no es la confirmacion, podria ser un mensaje de chat!
  ;EL PRIMER MENSAJE PODRIA SER DE CHAT!
  ld hl,mensaje_recibido_txt
  ld a,(hl)
  cp #FD ;es confirmacion tablero?
  jp z,confirmada_recepcion
    ;si no es tablero, es chat, el fin de partida lo decide quien lo recibe, pero DESPUES de confirmar recepcion.
    ;NO IMPRIMIMOS CHAT, SE VUELVE LOCO SI METEMOS 200 MENSAJES SIN ENVIAR EN BUFFER
    
    
 .sal_repite_envio_tablero    
  xor a
  ret ;damos la mala noticia....

;jp bucle_confirmacion  

.confirmada_recepcion

 ld hl,enviado_tablero
 ld de,#c533
 call imprime_texto

 scf ;confirmamos recepcion
 ret
   
;--------------------------------------------------------------  


.recupera_socketyresponse

;FUNCION CORROBORADA tanto en IX como IY con que_hay_pila

push af
;recuperamos puntero a nuestra maravilloso buffer
ld a,(response_buffer)
ld iyL,a
ld a,(response_buffer+1)
ld iyH,a

;la guardamos en una variable para usos posteriores.

ld a,(puntero_estado_socket)
ld ixL,a
ld a,(puntero_estado_socket+1) ;low endian
ld ixH,a

pop af

ret

.muestra_estado_socket

push af
push bc
push hl
push de

ld a,(socket_status)

ld b,#30 ;codigo ascii del 0

add b

ld (socket_error_txt),a
ld hl,socket_error_txt
ld de,#c000
call imprime_texto

;incrementamos hasta el 0, que es lo minimo (0)

pop de
pop hl
pop bc
pop af

ret

.resetea_byte_control
push af
push hl

ld hl,mensaje_recibido_txt
xor a
ld (hl),a

pop hl
pop af
ret




.resetea_variables_net

ld a,NO
ld (esperando_confirmacion_mensaje),a
ld (mensaje_pendiente_envio),a
;ld (mensaje_recibido),a

ret

;------------------------RESETEA NET INICIO-----------------------------
.resetea_net_inicio ;para ip's y cosas de los menus NO del juego

ld hl,res_ip
ld de,ip_servidor_txt
ld bc,16 ;CORROBORADO
ldir

;para el menu de introduccion de ip
ld hl,res_menu_ip
ld de,ip_servidor_introducida
ld bc,16
ldir

ret

.res_ip dm '               $' ;16
.res_menu_ip db #20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,'$'



;-----------------------RESETEA PANTALLA IP------------------------------
.resetea_pantalla_ip

ld hl,res_ipp
ld de,ip_servidor_txt
ld bc,16 ;CORROBORADO
ldir

;para el menu de introduccion de ip
ld hl,res_menu_ipp
ld de,ip_servidor_introducida
ld bc,16
ldir

ret

.res_ipp dm '               $' ;16
.res_menu_ipp db #20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,'$'




;---------------------------GUARDA ESTADO RET---------------------------------

.guarda_estado_red

push af
;push bc
;push de
;push hl

ld	a,(ix)	;vamos a guardar el estado del socket para mostrarlo en pantalla
ld (socket_status),a


;pop hl
;pop de
;pop bc
pop af

ret

;------------------------------------------------------------------------

convierte_hex:	;a trae el numero a mostrar

push af ;MENUDO FALLAZO, esta trabajando con b!!!
pop bc 

                 	ld	a,b
			srl	a
			srl	a
			srl	a
			srl	a
			add	a,&90
			daa
			adc	a,&40
			daa
			ld (numero_hex),a ;call	&bb5a
			ld	a,b
			and	&0f
			add	a,&90
			daa
			adc	a,&40
			daa
			ld (numero_hex+1),a ;call	&bb5a
			;ld	a,10 ;enter?
			;ld (numero_hex+2),a ;call	&bb5a
			;ld	a,13 ;enter?
			;ld (numero_hex+3),a ; call	&bb5a
			ret

;----------------------------------------------------------------------------

.que_hay_pila
;nos dice lo que hay en la pila


;quiero ver a donde me devuelve esta funcion...
pop de ;quito el dato de este propio call
ld b,d
ld c,e ;lo metemos en bc, para poder volver

pop de ;quito el dato de la pila que es el que me va a devolver el ret

ld a,d

push bc
call convierte_hex
pop bc

ld a,(numero_hex)
 ld (socket_libre),a
 ld a,(numero_hex+1)
 ld (socket_libre+1),a

push bc ;guardamos vuelta
push de ;guardamos dato
ld hl,socket_libre
ld de,#c08a
call imprime_texto
pop de ;recuperamos dato
pop bc

ld a,e

push bc ;guardamos vuelta
call convierte_hex
pop bc

ld a,(numero_hex)
 ld (socket_libre),a
 ld a,(numero_hex+1)
 ld (socket_libre+1),a

push bc
ld hl,socket_libre
ld de,#c090 ;c052
call imprime_texto



;pop bc

;nos ahoramos el ultimo pop bc, que ya nos lleva a la que nos llamo


ret


;------------------------------------------

;OJO LA RUTINA ASCII2DEC, BUSCA UN PUNTO (.) PARA ACABAR LA RUTINA, YA QUE ESTA HECHA PARA DIRECCIONES IP.
;POR ESO LA LLAMA TANTAS VECES COMO NUMEROS IP HAYA. (4) 192.168.0.1
;TENEMOS LA PERRA SUERTE DE QUE PONIAMOS COMO ULTIMO DIGITO EN LAS IP UN 0, PORQUE SINO DE DESMADRARIA ESTA FUNCION
;FIJATE QUE COMPARA CON 0 TAN PRONTO EMPIEZA!!!!!

ascii2dec:	ld	d,0
loop2e:		ld	a,(hl)
			cp	0 ;OJO OJO, QUE ESTO ES PARA LA ULTIMA SALIDA!!! SINO SE DESMADRA EN EL ULTIMO DIGITO!!!
			jr	z,found2e
			cp	&2e ;ES UN PUNTO? ESTO PROVOCA QUE SE SALGA DE LA RUTINA
			jr	z,found2e
			; convert to decimal
			cp	&41	;A ? A MAYUSCULA, DETRAS DE ELLA ESTAN LOS NUMEROS
			jr	nc,less_than_a ;CREO QUE DEBERIA LLAMARSE MAYOR QUE A
			sub	&30	; - '0' 
			jr	next_dec
less_than_a:	sub	&37	; - ('A'-10)
next_dec:		ld	(hl),a
			inc	hl
			inc	d
			dec	bc ;OJO CON ESTE BC, LO CONVIERTE EN #FFFF, COMPROBAR EN RUTINA ORIGINAL!
			xor	a   ;NO PASA NADA, SON LOS PUNTOS LOS QUE HACEN SALIR DE ESTA RUTINA.
			cp	c
			ret	z
			jr	loop2e
found2e:
			push	hl
			call	dec2bin
			pop	hl
			inc	hl
			ret ;AQUI VUELVE SI NOS ENCONTRAMOS CON UN PUNTO!!!
dec2bin:		dec	hl ;VUELVE AL NUMERO ANTERIOR
			ld	a,(hl)
			dec	hl ;VUELVE AL NUMERO ANTERIOR
			dec	d ;NUMERO DE DECIMALES ANDADOS
			ret	z
			ld	b,(hl)
			inc	b
			dec	b
			jr	z,skipmul10
mul10:		add	10       ;MULTIPLICA POR *10 CUANTAS DECENAS HAYA
			djnz	mul10
skipmul10:	dec	d
			ret	z
			dec	hl
			ld	b,(hl)
			inc	b
			dec	b
			ret	z
mul100:		add	100      ;MULTIPLICA *100 CUANTAS  DECENAS HAYA
			djnz	mul100
			ret



;modificada por jose

ascii2decPUERTO:	ld	d,0
loop2ee:		ld	a,(hl)
			cp	#ff ;marca de fin de puerto
			jr	z,fuera_calamar
			cp	&2e ;ES UN PUNTO? ESTO PROVOCA QUE SE SALGA DE LA RUTINA
			jr	z,found2ee
			; convert to decimal
			cp	&41	;A ? A MAYUSCULA, DETRAS DE ELLA ESTAN LOS NUMEROS
			jr	nc,less_than_aa ;CREO QUE DEBERIA LLAMARSE MAYOR QUE A
			sub	&30	; - '0' 
			jr	next_decc
less_than_aa:	sub	&37	; - ('A'-10)
next_decc:		ld	(hl),a
			inc	hl
			inc	d
			dec	bc ;OJO CON ESTE BC, LO CONVIERTE EN #FFFF, COMPROBAR EN RUTINA ORIGINAL!
			xor	a   ;NO PASA NADA, SON LOS PUNTOS LOS QUE HACEN SALIR DE ESTA RUTINA.
			cp	c
			ret	z
			jr	loop2ee
found2ee:
			push	hl
			call	dec2binn
			pop	hl
			inc	hl
			ret ;AQUI VUELVE SI NOS ENCONTRAMOS CON UN PUNTO!!!
dec2binn:		dec	hl ;VUELVE AL NUMERO ANTERIOR
			ld	a,(hl)
			dec	hl ;VUELVE AL NUMERO ANTERIOR
			dec	d ;NUMERO DE DECIMALES ANDADOS
			ret	z
			ld	b,(hl)
			inc	b
			dec	b
			jr	z,skipmul10p
mul10p:		add	10       ;MULTIPLICA POR *10 CUANTAS DECENAS HAYA
			djnz	mul10p
skipmul10p:	dec	d
			ret	z
			dec	hl
			ld	b,(hl)
			inc	b
			dec	b
			ret	z
mul100p:		add	100      ;MULTIPLICA *100 CUANTAS  DECENAS HAYA
			djnz	mul100p
			ret

.fuera_calamar
ret