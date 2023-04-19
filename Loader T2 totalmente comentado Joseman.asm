;T2 loader 2, speedlock protection
;El juego contiene 3 loaders en principio.
;El primero es sencillo y carga este loader comentado.
;el loader 2 carga tambien parte del loader1, no se si por dejadez o reusan las funciones en loader 3
;El loader 3 es bastante grande y posiblemente alli este la artilleria pesada de la proteccion.
;Desensamblado y comentado por Joseman 2023

org &0040 ;inicio del loader en memoria RAM
run main ;punto de ejecuion de este loader.

.l0040 ;las direcciones &0040-&00FF, NO son usadas por este loader, partes son del loader 1, no se si loader 3 las usa
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &02
db &00
db &00
db &C0
db &00
db &00
db &40
db &00
db &C0
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &40
db &00
db &00
db &02
db &02
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00 
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
db &00
.L00C0 ;no usado en este loader, usado por loader 1
ld hl,l00c8
ld c,#ff
call #bd16
.l00c8 ;no usado en este loader, usado por loader 1
ld c,#07
ld de,l0040
ld hl,#b0ff
push de
call #bcce
ld hl,l00f8
call #bcd4
xor a
call #001b
ld hl,l00fc
call #bcd4
ld de,l00fd
ex de,hl
ld (hl),e
inc hl
ld (hl),d
inc hl
ld (hl),c
pop hl
ld a,c
ld c,#c9
ld d,h
ld e,d
rst #18
db &FD
db &00
jr c,main

.l00f8 ;usado por loader 1 para detectar comando |DISC
db &44 ;"D" ld b,h
db &49 ;"I" ;ld c,c
db &53 ;"S" ;ld d,e
.l00fd equ $ + 2
.l00fc equ $ + 1
jp #cb84
db &ED
db &11
;--------------------------------------------------------

.main ;punto de entrada del loader actual.
di
.error_repite_CMD
ld bc,#fa7e ;FDC motor control
ld de,CMDreadID_Y_parametros ;informacion para comando FDC READ ID y sus parametros.
out (c),e ;e=&53, %01010011 ;bit 0=1 Motor ON.

call manda_CMDyPARAMETROS_FDC ;manda comando y parametros al FDC, espera mientras esta en EXECUTION PHASE Y VUELVE

;por aqui ejecuto comando y las 3 fases del FDC, COMMAND PHASE, EXECUTION PHASE, RESULT PHASE.
;ahora va a leer los resultados devueltos por el FDC al comando mandado.
;todos los resultados de READ ID fueron &00, 7 resultados en total.

ld a,(hl) ;hl se cargo en manda_CMDyPARAMETROS_FDC con puntero a resultados_comando
          ;el resultado 1 es STATUS REGISTER 1
or a ;compara que ese resultado sea efectivamente &00
jr nz,error_repite_CMD ;si no lo es, vuelve a repetir comando
                       ;cualquier bit a 1 en el STATUS REGISTER indica o que fallo algo o que aun esta procesando el comando.

;por aqui todo bien con el comando READ ID.

ld de,CMDreaddeleteddata_Y_parametros ;nuevo comando y parametros a mandar
ld hl,&015c ;pone la nueva direccion a la que saltara
ld (cambia_dire_salto),hl ;cambia a donde saltara la funcion manda_CMDyPARAMETROS_FDC cuando acabe.
call manda_CMDyPARAMETROS_FDC ;llama de nuevo a la funcion, recuerda, cambio el salto de salida de esta funcion.
                              ;en este caso mando el comando READ DELETED DATA ya que el disco original
                              ;tiene sectores con el flag de deleted data activado.

;de vuelta a leido 3.072bytes de datos del disco sectores &C2-&C7
;y despues de esos datos mete 7 bytes de resultados del comando READ DELETED DATA.
;registros hl y bc vienen cargados antes del RET que nos devuelve a esta parte.
;hl=&0181 (inicio datos leidos)
;bc=&098b ;2443bytes a mover con el ldir, mueve solo los datos reales
          ;ya que tambien metio al final un monton de &E5 que significa sin datos en esa zona del disco.
ld de,#9ebf ;destino de los datos.
push de ;mete en pila la direccion de inicio de esos datos.
ldir ;mueve los datos a &9EBF-&A849
     ;como curiosidad, parece que se pasa 1byte ya que mete tambien un &E5 (aunque igual lo mira en el nuevo codigo)

;ahora hace una cosa muy curiosa, reusa el codigo de los PARAMETROS de READ DELETED DATA
;hasta que llega al parametro 1 &E0 que para el Z80 es un RET PO
;ese RET provoca que se "vuelva" al parametro metido en pila que fue &9EBF
;es decir, se EJECUTA el codigo recien leido por este loader.
;pero eso ya se mirara en otro codigo fuente comentado (o no) ;)
;---------------------FIN LOADER ACTUAL---------------------------------------------------------

.CMDreaddeleteddata_Y_parametros
db &09 ;numero de parametros y cmd a mandar al FDC
db &4C ;comando read deleted data ;SK=0 MF=1 MT=0
db &E0 ;parametro 1 %11100000 US0=0 US1=0 HD=0 (disquetera 0, cabezal 0)
db &00 ;parametro 2 ;C track 0
db &00 ;parametro 3 ;H cabezal 0
db &C2 ;parametro 4 ;R sector &C2
db &02 ;parametro 5 ;N bytes escritos en ese sector (&02=512bytes)
db &C7 ;parametro 6 ;EOT ultimo sector del track 
db &2A ;parametro 7 ;GPL tamano de GAP (se decidio cuando se formateo el disco con el programa original)
db &FF ;paremetro 8 ;DTL tamano de datos (no se usa en este caso, ya que se definio en parametro N)


.manda_CMDyPARAMETROS_FDC
ld hl,resultados_comando
ld a,(de) ;pasado como parametro a esta funcion
          ;a= toma el numero de comando + parametros a mandar.
          ;con READ ID toma valor &02, comando + 1 parametro.
          ;con READ DELETED DATA toma valor &09, comando + 8 parametros.

push hl ;guarda en pila puntero resultados_comando

.bucle_parametros
ex af,af'
inc de ;de=&0154
ld bc,#fb7e ;Main status register FDC. Read Only. 

.espera_RQM ;l0136
in a,(c)
add a ;comprueba si Bit 7=1, si es asi sumar reg a con el mismo activara Carry.
      ;bit 7= RQM Request For Master (1=ready for next byte)
jr nc,espera_RQM ;l0136 ;no esta preparado? buclea hasta que lo este.
jp m,espera_RQM ;Salta si el indicador de signo S esta a uno (resultado negativo).
                ;el indicador de signo se activa si bit7=1 y bit 6=1
                ;b6 -> DIO Data Input/Output (0=CPU->FDC, 1=FDC->CPU)
                ;es decir la direccion es FDC->CPU, luego no se pueden mandar comando aun al FDC.

;por aqui RQM ->ready y DIO CPU->FDC

;-------COMMAND PHASE---------------------------------------

ld a,(de) ;a=&4A
inc c ;bc=&7B7F FDC DATA REGISTER
out (c),a ;comando &4A al FDC, la primera vez que se llama a esta funcion, en la segunda llamada sera el comando READ DELETED DATA.
          ;comando READ ID, Siendo el bit 6 MF=1 (MFM selected)

ld b,#08 ;pequeno bucle despues de enviar comando.
ex af,af' ;recupera parametro 1 leido de &0153 (numero de comando+parametros a mandar al FDC)
.wait_comando
djnz wait_comando
dec a ;decrementa numero de parametros a mandar al FDC
jr nz,bucle_parametros ;manda ese numero de parametros al FDC

;por aqui se ha acabado de mandar comando READ ID y sus parametros al FDC. recuerda, en la siguiente llamada comando READ DELETED DATA.

ld bc,#fb7e ;FDC MAIN STATUS REGISTER
ld de,#2010 ;usa reg e para comparar si FDC BUSY.
.cambia_dire_salto equ $ + 1
jp execution_result_phase ;el ret de execution_result_phase le devolvera al punto del programa
                          ;donde se llamo a manda_CMDyPARAMETROS_FDC, NO VOLVERA POR AQUI.
                          ;lo que si hara despues es cambiar la direcion de salto de este JP
                          ;con lo cual ya no hara un jp execution_result_phase
                          ;si no un jp execution_result_READDELETEDDATA
                          ;esta variacion la hace para el comando READ DELETED DATA ya que tiene que leer los datos que le pide al FDC.


.CMDreadID_Y_parametros
db &02 ;numero de envios al fdc, comando + parametro.
db &4A ;READ ID COMMAND
db &00 ;parametro disquetera=0 cabezal fisico=0


;-------------funcion usada por read deleted data para leer los datos pedidos al FDC-------------------------
.lee_sectores ;procede a leer los datos que estan en sectores &C2 hasta &C7 (6 sectores * 512bytes=3.072bytes a leer)
inc c ;bc=FB7F DATA REGISTER PORT.
in a,(c)
ld (hl),a ;&0181=&ED
          ;&0182=&4F
          ;&0183=&11
          ;&0184=&7C
          ;&0185=&09
          ;&0186=&21
          ;&0187=&CE
          ;&0188=&9E
          ;&0189=&34
          ;[...]
          ;&0D80=&E5
          ;3.072 bytes leidos

dec c ;bc=&FB7E, MAIN STATUS REGISTER
inc hl ;siguiente posicion de memoria de RAM donde escribira los datos.

.execution_result_READDELETEDDATA
;----execution phase
in a,(c)
jp p,execution_result_READDELETEDDATA ;Salta si el indicador de signo S esta a cero (resultado positivo). ;l015c
   ;valores devueltos reg a
   ;a=&50 bit7 0 (data register no ready), efectua jp
   ;a=&F0 bit7 1 (data register ready), no efectua jp, sigue por aqui abajo.
      
and d ;&F0 and &10 (mira bit 4 FDC BUSY)
jr nz,lee_sectores ;l0156 ;si FDC BUSY bit 4=1 buclea, va leyendo los sectores que se le ha dicho
                   ;mete esos datos en &0181-&0D80, 3.072 bytes a leer)

;por aqui ha acabado de leer los sectores especificados en READ DELETED DATA.
;reg hl esta situado un byte despues de los datos leidos
;metera ahi los resultados que ha devuelto el comando.
;para eso usa la misma funcion que READ ID -> execution_result_phase


.execution_result_phase

;-------EXECUTION PHASE---------------------------------------

.bucle_handshaking

in a,(c) ;leemos de MAIN STATUS REGISTER
cp #c0 ;se interesa por el bit 8 y el bit 7 (#c0=%11000000)
	 ;si reg A >= &c0 significa que POR LO MENOS b7 y b8 estan activados. (y es lo unico que le importa)
         ;esta preguntando si el Data Register del fdc esta listo para mandar datos a la CPU

jr c,bucle_handshaking ;mientras bit 6=1 el sentido de comunicacion es desde el FDC (data regiter) a la CPU.
                       ;mientras bit 7=0 el data register no esta listo para recepcion o envio de datos.
           ;por ejemplo las primeras veces ese in a,(c) devuelve &50
           ;&50= %01010000 (bit 7 a 0, bit 6 a 1). 
           ;bit 7 a 0 significa que el Data register no esta preparado para comunicarse con la CPU
           ;el Carry se cumple y seguira bucleando.

           ;el primer valor diferente a &50 devuelto es &D0=%11010000
           ;con ese valor bit 7=1, lo que significa que el data register ya esta listo para
           ;comunicarse con la CPU. 
           ;bit 6=1, la transmision es FDC->CPU
           ;El Carry no se cumple y deja de hacer bucle.

;por aqui &D0, sentido de la comunicacion es FDC->CPU y data register listo.
;va proceder a leer los resultados del comando realizado (Restult phase)

;---------------RESULT PHASE---------------------------------------------

inc c ;bc=&7B7F FDC DATA REGISTER.

;ahora va a leer los resultados del comando mandado (READ ID)
;por aqui pasa tantas veces como resultados devuelva el comando en cuestion.
in a,(c) ;leemos del data register
         ;a=&0->%00000000
ld (hl),a ;lo guarda en tabla resultados_comando
          ;segun se haga el bucle principal bucle_handshaking ira incrementando hl y guardando
          ;RESULTADOS READ ID
          ;&0181=&00 ;ST0
          ;&0182=&00 ;ST1
          ;&0183=&00 ;ST2
          ;&0184=&00 ;C
          ;&0185=&00 ;H
          ;&0186=&00 ;R
          ;&0187=&00 ;N
          ;RESULTADOS READ DELETED DATA
          ;&0D81=&40 ;ST0
          ;&0D82=&80 ;ST1
          ;&0D83=&00 ;ST2
          ;&0D84=&00 ;C
          ;&0D85=&00 ;H
          ;&0D86=&C7 ;R
          ;&0D87=&02 ;N

dec c ;bc=&7B7E FDC MAIN STATUS REGISTER
inc hl ;hl=&0182

ld a,#05
.pequenobucle ;l0172
dec a
jr nz,pequenobucle ;l0172

in a,(c) ;leemos del main status register
and e ;a=&D0 -> %11010000
      ;e=&10 -> %00010000 ;nos quedamos solo con el bit 4
      ;bit 4 FDC BUSY
      ;bit4 a 1= un comando de lectura o escritura esta en proceso (en este caso READ ID)
jr nz,bucle_handshaking ;si bit 4=1 el flag de Z no se activa, con lo cual vuelve a buclear desde el principio
                        ;seguira bucleando hasta que el FDC devuelva FDC NO BUSY.
                        ;Esta recibiendo los resultados del comando realizado, cuando FDC NO BUSY, se habran
                        ;leido todos los resultados.


;por aqui FDC NO BUSY

sub #97 ;REG a siempre sera 0 aqui debido al AND anterior.
        ;&00 sub &97=&69 ;Z=0 C=1
pop hl ;recupera inicio puntero resultados_comando, con READ DELETED DATA parametro para un ldir.
ld bc,#098b ;lo usa como parametro para un ldir despues de READ DELETED DATA.
ret ;vuelve por donde se llamo a manda_CMDyPARAMETROS_FDC

.resultados_comando
.mensaje_informacionSLDP
;MENSAJE DE INFORMACION SOBRE SPEEDLOCK DISC PROTECTION SYSTEMS Y NUMERO DE TELEFONO
;estos datos seran sobreescritos con resultado de los comandos y los datos que leera READ DELETED DATA.

db #53 ;S
db #50 ;P
db #45 ;E
db #45 ;E
db #44 ;D
db #4c ;L
db #4f ;O
db #43 ;C
db #4b ;K
db #20 ;spc
db #44 ;D
db #49 ;I
db #53 ;S
db #43 ;C
db #20 ;spc
db #50 ;P
db #52 ;R
db #4f ;O
db #54 ;T
db #45 ;E
db #43 ;C
db #54 ;T
db #49 ;I
db #4f ;O
db #4e ;N
db #20 ;spc
db #53 ;S
db #59 ;Y
db #53 ;S
db #54 ;T
db #45 ;E
db #4d ;M
db #53 ;S
db #20 ;spc
db #28 ;(
db #43 ;C
db #29 ;)
db #20 ;spc
db #31 ;1
db #39 ;9
db #38 ;8
db #39 ;9
db #20 ;spc
db #53 ;S
db #50 ;P
db #45 ;E
db #45 ;E
db #44 ;D
db #4c ;L
db #4f ;O
db #43 ;C
db #4b ;K
db #20 ;spc
db #41 ;A
db #53 ;S
db #53 ;S
db #4f ;O
db #43 ;C
db #49 ;I
db #41 ;A
db #54 ;T
db #45 ;E
db #53 ;S
db #20 ;spc
db #46 ;F
db #4f ;O
db #52 ;R
db #20 ;spc
db #4d ;M
db #4f ;O
db #52 ;R
db #45 ;E
db #20 ;spc
db #44 ;D
db #45 ;E
.l01cc
db #54 ;T
db #41 ;A
db #49 ;I
db #4c ;L
.l01d0
db #53 ;S
db #2c ;,
db #20 ;spc
db #50 ;P
db #48 ;H
db #4f ;O
db #4e ;N
db #45 ;E
db #20 ;spc
.l01d9
db #28 ;(
db #30 ;0
db #37 ;7
db #33 ;3
db #34 ;4
db #29 ;)
db #20 ;spc
db #34 ;4
.l01e1
db #37 ;7
db #30 ;0
db #33 ;3
.l01e4
db #30 ;0
db #33 ;3
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
.l01ef
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
.l01f8
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
.l0200
db #00
db #00
.l0202
db #00
db #00
db #00
db #00
db #00
db #00
.l0208
db #00
db #00
db #00
db #00
db #00
db #00
db #00
.l020f
db #00
db #00
db #00
db #00
.l0213
db #00
db #00
.l0215
db #00
db #00
.l0217
db #00
db #00
.l0219
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
.l0224
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
db #00
;-----------------FIN LOADER-----------------------------------