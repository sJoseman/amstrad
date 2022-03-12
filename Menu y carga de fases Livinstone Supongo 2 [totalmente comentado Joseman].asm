;Menu de seleccion de fase a cargar Livingstone Supongo II
;Joseman Febrero-Marzo 2022
;No uso acentos ya que winape los convierte en codigo ascii de CPC
 


org &0300
run $

.l0300
call configura_CRTC

xor a
ld (variable_1_o_2_seleccionado),a ;selecciona fase 1 por defecto en el menu.

call configura_CRTC_Colores_Crea_interrupcion

call pinta_sprites_menu 
;por aqui acabo de pintar el menu en pantalla


.bucle_espera_eleccion_fase
call espera_valor_0a_contador_parpadeo ;velocidad de parpadeo del numero seleccionado

call borra_sprite_numero_fase_seleccionado

;ahora comprobara si se pulso teclado (teclas requeridas) y joystick.
call comprueba_pulsacion_teclado_y_joystick

;el resultado de dichas comprobaciones se guardo
;con  la rotacion de los 8 bits registro c y poniendo a 1 si alguna tecla (o joy) se pulso
;y or a posible pulsacion de linea de joystick
;en la variable dato_pulsacion_teclado_y_joystick

;carga a con ese dato de pulsaciones
ld a,(dato_pulsacion_teclado_y_joystick)
;datos de registro a
;&00 no se ha pulsado tecla o joystick
;&01 se ha pulsado tecla '1' o joystick arriba
;&02 se ha pulsado tecla '2' o joystick abajo
;&10 se ha pulsado tecla 'space' o joystick fuego
;curiosamente tambien se guarda el dato de las siguientes pulsaciones
;tecla 'o', tecla 'p', tecla 'return', tecla 'control', joystick izquierda, joystick derecha
;pero no hacen nada con ella (podria ser codigo de otros juegos reutilizado aqui)

bit 4,a
jr nz,se_ha_pulsado_space_o_fuego
bit 0,a
jr z,no_se_ha_pulsado_num_1
;por aqui se ha pulsado tecla 1 o joystick arriba
call selecciona_parpadeo_num_1
jr bucle_espera_eleccion_fase
.no_se_ha_pulsado_num_1
bit 1,a
jr z,bucle_espera_eleccion_fase
;por aqui se ha pulsado tecla 2 o joystick abajo
call selecciona_parpadeo_num_2

;seguira el bucle  hasta que se pulse space o fuego, lo que hara que se salte
;a la rutina de carga de fase seleccionada

jr bucle_espera_eleccion_fase

;----------------------------------------------------------------------------

;-------------------------------------------
.espera_valor_0a_contador_parpadeo
;aunque aqui buclea aparentemente sin final ya que no se hace ningun update de contador_activa_parpadeo
;recordad que el update se hace en la interrupcion que creo el programador
;asi que cuando salte a la interrupcion adecuada ese contador se ira incrementando
;y ese cp &0a sera cierto en algun momento

ld a,(contador_activa_parpadeo) ;lo incrementa en lo unico que hace en la interrupcion
cp &0a ;a=&0a nos hace salir de esta rutina permitiendo el efecto parpadeo
       ;es decir, si en cp &0a
       ;cambiamos el valor por uno mas bajo, el parpadeo se torna mas rapido
       ;en cambio si ponemos un valor mas alto el parpadeo se enlentecera

jr c,espera_valor_0a_contador_parpadeo

;una vez alcanzado el valor &0a, reinicia la variable a &0
xor a
ld (contador_activa_parpadeo),a
ret



;---------------------------------------------
.selecciona_parpadeo_num_1

call pinta_sprites_menu ;vuelve a pintar el menu entero ya que alguno de los numeros
                        ;podria encontrarse borrado (para simular el efecto parpadeo)

xor a
ld (variable_1_o_2_seleccionado),a ;&00 parpadea sprite numero 1
;esta variable indicara a la rutina borra_sprite_numero_fase_seleccionado
;que sprite debe borrar para simular el efecto parpadeo

ret

;---------------------------------------------------------------

.selecciona_parpadeo_num_2

call pinta_sprites_menu ;vuelve a pintar el menu entero ya que alguno de los numeros
                        ;podria encontrarse borrado (para simular el efecto parpadeo)

ld a,&01
ld (variable_1_o_2_seleccionado),a ;&01 parpadea sprite numero 2
;esta variable indicara a la rutina borra_sprite_numero_fase_seleccionado
;que sprite debe borrar para simular el efecto parpadeo

ret

;------------------------------------------------------------------------------------
.borra_sprite_numero_fase_seleccionado

ld ix,sprite_numero_1
ld a,(variable_1_o_2_seleccionado) ;a=&00, borra numero 1
                                   ;a=&01, borra numero 2

xor &80 ;a valga &00 o &01, su bit 7 SERA siempre 0 la primera vez que entra en esta funcion
        ;PERO, al escribir aqui abajo en la variable
        ;variable_1_o_2_seleccionado este xor
        ;entonces el bit 7 alternara entre 0 y 1 de cada vez que se llame a esta funcion

ld (variable_1_o_2_seleccionado),a ;guarda dicho XOR

bit 7,a ;el bit 7 alterna entre 0 y 1
;esto lo que hace es lo siguiente
;si el bit 7 esta 1, BORRARA el numero seleccionado
;pero si el bit 7 esta a 0, pintara el numero seleccionado
;creando ese parpadeo que se ve al seleccionar el numero de fase

jp z,pinta_sprites_menu

;por aqui BORRA el numero de fase seleccionado
and &7f ;%01111111
         ;se deshace de ese bit 7 mencionado, es decir bit 7 aqui toma valor 0 siempre.

or a ;comprueba que numero debe borrar
     ;si a=0, ya trae seleccionado en ix los datos del sprite numero 1, con lo cual
     ;efectua el salto a borrarlo
jr z,borra_numero_seleccionado
;por aqui debe borrar el numero 2
;con lo cual carga registro ix con los datos del sprite numero 2
ld ix,sprite_numero_2

.borra_numero_seleccionado
ld e,(ix+&0000)
ld d,(ix+&0001) ;direccion de memoria a pintar sprite
ld l,(ix+&0002)
ld h,(ix+&0003) ;direccion del sprite a pintar
ld b,(hl)
inc hl
ld c,(hl)
ex de,hl
jp borra_sprite_seleccionado

;el ret de borra_sprite_seleccionado le llevara a la funcion que llamo a esta
;---------------------------------------------------------------------------------


;--------------------------------------------------
.se_ha_pulsado_space_o_fuego
;por aqui inicia la carga de la fase requerida
call pinta_sprites_menu

call comprueba_proteccion_anticopia

;por aqui vuelve despues de comprobar proteccion anticopia en track 40 del disco.
;flag Z=&1 proteccion anticopia pasada
;flag Z=&0 proteccion anticopia NO pasada

jp nz,&0300 ;si no pasa la proteccion anticopia, vuelve a ensenar el menu de eleccion de fase
            
;por aqui se ha pasado la proteccion anticopia
;procedera a leer del disco la fase seleccionada

ld a,(variable_1_o_2_seleccionado)
     ;a=&80 fase 1
     ;a=&01 fase 2
and &7f ;comprueba bit 7
jr z,carga_fase_1

;por aqui cargara fase 2
ld a,&1b ;track inicial a leer
ld hl,&0300 ;direccion de salto al juego
push hl ;lo guarda en el stack ya que aqui abajo hace un jp &0116
        ;y el ret de &0116 lo llevara a &0300

ld hl,&bfff ;direccion inicial memoria RAM a escribir
ld bc,&bd00 ;datos a leer en total del disco (48.384 bytes)
            ;el juego ocupa desde #0300-#BFFF
ld ix,formato_disco_lectura_fases
jp &0116

;como he dicho no se volvera por aqui en el ret de &0116
;si no que a &0300 ya que lo mete en la pila antes de llamar a esta funcion

.carga_fase_1
ld a,&0e
ld hl,&0300 ;direccion de salto al juego
push hl ;lo guarda en el stack ya que aqui abajo hace un jp &0116
        ;y el ret de &0116 lo llevara a &0300

ld hl,&bfff ;direccion inicial memoria RAM a escribir
ld bc,&bd00 ;datos a leer en total del disco (48.384 bytes)
            ;el juego ocupa desde #0300-#BFFF

ld ix,formato_disco_lectura_fases 
jp &0116

;como he dicho no se volvera por aqui en el ret de &0116
;si no que a &0300 ya que lo mete en la pila antes de llamar a esta funcion

;-------------------------------------------------
.borra_pantalla
ld hl,&c000
ld de,&c001
ld bc,&3fff
ld (hl),&00 ;borra toda la memoria de video poniendo valor &00 en ella
ldir
ret


;-----------------------------------------
.datos_posicion_sprite

;primer sprite (numero "1")
.sprite_numero_1
db &b6 
db &c2 ;direccion de pantalla para pintar primer sprite
db &3d
db &06 ;zona de datos primer sprite (el numero 1)

;segundo sprite (numero "2")
.sprite_numero_2
db &35 
db &c5 ;direccion de pantalla para pintar segundo sprite
db &cf 
db &06 ;zona de datos segundo sprite (el numero 1)

;tercer sprite (nombre del juego pintado arriba de todo "Livingstone II"
db &12 
db &c0 ;direccion de pantalla para pintar segundo sprite
db &7d 
db &0b ;zona de datos segundo sprite

;cuarto sprite  ("Phase" del "1")
db &44 
db &c2
db &91
db &07 

;quinto sprite ("Phase" del "2")
db &c4
db &c4
db &91 
db &07 

;sexto sprite (logotipo "OPERA soft" de abajo)
db &48 
db &c7 
db &13 
db &0a 

;---------------------------------------------------------------------------------------------

.pinta_sprites_menu
ld ix,datos_posicion_sprite
ld b,&06 ;numero de sprites totales a pintar

.pinta_todos_sprites
push bc ;guardamos numero total de sprites en total a pintar
ld e,(ix+&0000) ;e=&b6
ld d,(ix+&0001) ;d=&c2 ;zona de pantalla

ld l,(ix+&0002) ;l=&3d
ld h,(ix+&0003) ;h=&06
                ;hl=&063d ;zona de datos graficos para dibujar el menu
                ;el primer dato es el numero "1", con 2 bytes iniciales que le dicen a la rutina de pintado
                ;el ancho y el alto del sprite a pintar.
call pinta_sprite

ld de,&0004

add ix,de ;apuntamos a los datos de pintado del siguiente sprite (direccion de pantalla, zona de datos sprite)
pop bc ;recupera numero de sprites a pintar en total
djnz pinta_todos_sprites ;mientras no se pinten todos los sprites bucleamos

;se han pintado todos los sprites
ret

;--------------------------------------------
.borra_sprite_seleccionado
push bc
ld e,&00 ;carga dato con valor a negro en pantalla

.bucle_borrado_sprite
push bc
push hl
.borra_ancho_sprite
ld (hl),e ;borra lo que habia pintado en esa parte de la pantalla
inc hl
djnz borra_ancho_sprite
;siguiente linea sprite
pop hl ;recupera direccion inicial de pintado de pantalla
ld bc,&0800
add hl,bc ;salta a siguiente linea del sprite a borrar
.l0402
jr nc,no_desborda_direccion
;por aqui corrige el desborde direccion de pintado en pantalla
;se debe entender como maneja el CPC la pantalla de video para saber por que se hace esto
ld bc,&c050
add hl,bc
.no_desborda_direccion
pop bc
dec c ;decrementa linea a borrar
jr nz,bucle_borrado_sprite ;va borrando sprite
pop bc
ret

;---------------------------------------------------

.pinta_sprite
ld b,(hl)
inc hl
ld c,(hl) ;bc= contador ancho y alto
          ;b ancho sprite (6bytes*2pixeles por byte = 12 pixeles de ancho)
          ;c alto sprite (24 lineas, 24 pixeles de alto)
         
inc hl

.pinta_linea
push bc
push hl ;guarda direccion inicial de pintado de sprite
push de ;direccion pantalla
.pinta_ancho_sprite
ld a,(hl) ;dato sprite
ld (de),a ;lo escribe en pantalla

inc hl ;incrementa el puntero de dato de sprite
inc de ;incremena el puntero de direccion de pantalla a pintar
djnz pinta_ancho_sprite

;por aqui ha pintado una linea del sprite

pop hl ;recupera direccion inicial de pantalla del pintado del sprite
ld de,&0800 ;siguiente linea de pintado del sprite
add hl,de ;salta a la siguiente posicion de memoria de pantalla para pintar otra linea del sprite
jr nc,no_desborda
;por aqui hay que reajustar el pintado del sprite a la posicion correcta de memoria de pantalla
;para entender esto hay que consultar como se distribuye la memoria grafica del Amstrad CPC.
ld de,&c050
add hl,de

.no_desborda
ex de,hl ;mete en registro de la nueva direccion de pintado de pantalla (la siguiente linea)
pop hl ;recupera puntero de datos del sprite a pintar
pop bc ;recupera ancho y alto del sprite
ld a,b ;carga a con ancho de sprite
add l ;mueve el puntero (low byte) de los datos del sprite
ld l,a ;lo carga en l, hl tiene ahora la direccion de la siguiente linea del sprite a pintar
jr nc,no_desborda_low_byte
;por aqui se necesita incrementar el high byte de la direccion del sprite ya que la low ha desbordado
inc h ;incrementa high byte de la direccion del sprite
.no_desborda_low_byte
dec c ;decrementa contador de alto del sprite
jr nz,pinta_linea ;mientras no se acabe de pintar el alto y ancho del sprite sigue con ello

;por aqui hemos acabado de pintar el sprite
;la primera vez que pasa por aqui ha acabado de pintar el numero "1" entero del menu de eleccion de fase
ret

;-------------------------------------------------

.configura_CRTC_Colores_Crea_interrupcion
ld bc,&0000
call pon_color_borde

ld a,&00
call cambia_inicio_video_borra_pantalla
jp activa_interrupcion_menu

;---------------------------------------------------------------------

.pon_color_borde
push bc ;guarda parametro pasado a la funcion
ld bc,&7f10 ;selecciona Border como pen elegido
out (c),c ;Selecciona Border
pop bc ;recupera parametro pasado a la funcion

ld hl,datos_colores
add hl,bc ;bc de primeras = &0000
ld a,(hl) ;lee color para el pen elegido
or &40 ;lo "desencripta" a=&54
ld b,&7f
ld c,a
out (c),c ;Border a color negro
ret

.cambia_inicio_video_borra_pantalla
or &9c ;a=&9C
ld bc,&7f00 ;puerto Gate Array
out (c),a ;Mode 0, lower disabled, upper disabled
          ;bit 4 interrupt generation control a 1 (The GA scan line counter will be cleared)

ld bc,&bc0c ;selecciona registro 12 del CRTC
out (c),c
ld a,&30
inc b
out (c),a ;valor &30 a registro 12 del crtc
          ;Start Address (High), situa la pantalla en zona &C000
dec b
ld c,&0d
out (c),c ;selecciona registro 13 del CRTC
inc b
xor a
out (c),a ;valor &00 a registro 13 del crtc
          ;Start Address (High)
          ;la pantalla empieza en &C000


call borra_pantalla
ret

;---------------------------------------------------------------------------------------------------

.activa_interrupcion_menu
di ;ya las tenia desactivadas
xor a
ld (contador_interrupcion),a
ld hl,codigo_interrupcion ;selecciona codigo que suplantara a las interrupciones genericas del CPC
ld (&0039),hl ;pone la direccion que apunta al codigo propio de interrupcion
              ;en la zona de saltos del cpc
call pon_colorines
ei ;al activar interrupciones, ahora la interrupcion puesta por el menu toma el control.
ret

;------------------------------------------------------
.codigo_interrupcion
;nota,en amstrad hay 6 interrupciones por ciclo

;la interrupcion que crea este menu es muy sencillita
;simplemente incrementa un contador de parpadeo (en la interrupcion 6 de cada ciclo)
;hasta que llega a un valor determinado (&a0)
;mientras no se llega a ese valor, no se saldra de la interrupcion 6
;con lo cual no se repinta nada en pantalla mientras tanto (ni escanea el teclado)
;ralentizando el parpadeo del numero seleccionado

di ;deshabilita interrupciones, ya que estamos dentro de ella y no queremos que se generen mas aqui dentro.
push af
ld a,(contador_interrupcion)
inc a ;incrementa contador de interrupcion (va desde 1 a 6, el valor 0 solo se usa para inicializar)
ld (contador_interrupcion),a
cp &06 ;mira que estemos en interrupcion 6
jr nz,sal_interrupcion

;por aqui estamos en interrupcion 6

;primero salva todos los registros principales
;ya que, al activarse la interrupcion, esos registros estaban trabajando con la funcion que se estaba ejecutando
push bc
push de
push hl
push ix
push iy

;inicializa el contador de interrupcion a &00
xor a
ld (contador_interrupcion),a ;inicializa contador de interrupcion
call incrementa_contador_parpadeo

;recupera los registros principales, para que al volver de la interrupcion
;la rutina que los estuviera usando no reciba valores cambiados por la propia rutina de interrupcion
pop iy
pop ix
pop hl
pop de
pop bc

.sal_interrupcion
pop af
ei
ret
;---------------------------------------------------------------

.incrementa_contador_parpadeo
ld a,(contador_activa_parpadeo)
inc a
ld (contador_activa_parpadeo),a
ret

;------------------------------------------
.comprueba_pulsacion_teclado_y_joystick ;por aqui viene despues de borrar el sprite del numero de fase seleccionada
call escanea_teclado_guarda_buffer
;un buffer con posibles teclas pulsadas se ha guardado
 
ld hl,datos_para_calculo_desplazamiento_buffer_y_bit
      ;estos datos los usa para calcular la linea de teclado escrita en el buffer de teclado
      ;que quieren consultar
      ;y el bit que quieren saber si se pulso.

call carga_regA_bits_pulsaciones

;por aqui los bits del reg a vienen cargados a 1 si se ha pulsado alguna tecla
;depende del bit activado se ha pulsado una u otra tecla

push af ;guarda en stack esas pulsaciones
call comprueba_buffer_joystick
;registro h viene cargado con la zona de joystick que devolvio el AY (linea &49)
pop af
or h ;aqui hace un or entre las pulsaciones de teclado registradas
     ;y el dato del joystick
     ;si no se ha pulsado joystick el registro tiene cargado &00, a se mantiene igual
     ;pero si se ha pulsado algo del joystick
     ;los bits pulsados en joystick pasan a formar parte del registro a
     ;que sera una mezcla entre las pulsaciones del teclado y el joystick

ld (dato_pulsacion_teclado_y_joystick),a
ret

;-------------------------------------------------------------------------
.carga_regA_bits_pulsaciones
ld c,&00
ld b,(hl) ;b=&08 de primeras, lo usa para rotar los 8bits del registro c
          ;en cada iteracion del bucle se rotan hacia la izquierda
          ;1 posicion los bits del registro c
          ;al final del bucle, se habra rotado totalmente el registro c
          ;pero si alguna tecla requerida se ha pulsado, su bit correspondiente estara a 1
         
.bucle_comprobacion_tecla_pulsada
inc hl ;incrementa puntero... Leera memoria desde &05a5-&05ac
ld a,(hl) ;Leera datos &4F,&17,&12,&2f,&1b,&22,&41,&40
          ;los usara para calcular que posicion del buffer de teclado consultar
          ;y el bit que quieren consultar.


rlc c ;Rotate Left Circular
      ;rota todos los bits de c 1 posicion a la izquierda
      ;bit 7 es ahora bit 0
      ;el bit rotado a bit 0, tomara valor 1 si se ha pulsado la tecla requerida.
       
push hl ;guarda puntero
push bc ;guarda b, contador de bucle
        ;guarda c, que lo va rotando como ya hemos dicho

call comprueba_pulsacion_tecla_requerida
;la rutina anterior devuelve
;Z=0 si se pulso tecla consultada en la linea de teclado de buffer
;Z=1 si no se pulso


pop bc ;recupera b, contador de bucle
       ;recupera c, que va guardando en sus bits alguna posible pulscion
pop hl ;recupera puntero a datos de posicion del buffer y bit a consultar
jr z,sigue_comprobando_buffer_teclado ;si no se pulso tecla, se cumple z y salta

;por aqui se pulso alguna tecla
set 0,c ;pone a 1, la posicion 0 del registro c segun lo va rotando

.sigue_comprobando_buffer_teclado
djnz bucle_comprobacion_tecla_pulsada

;aqui llega cuando se ha rotado TODO el registro c
;si se ha pulsado alguna de las teclas requeridas, su bit estara a 1

ld a,c ;carga registro a con esos datos de bit
ret

;-------------------------------------------------------------------------------
.escanea_teclado_guarda_buffer
;antes de nada
;recordemos que el chip de sonido AY, tambien maneja las posibles pulsaciones de teclado
;mediante su Registro numero 15

di
ld de,buffer_tecla_pulsada ;va metiendo en el buffer el valor devuelto por registro 15 del AY
ld bc,&f40e ;b= PPI port A
            ;c= valor &0e (15 decimal) es el que se le mandara al AY mediante el puerto C del PPI
            ;para que seleccione el registro 15 del AY.
            
            
out (c),c ;escribe el valor &0e (15 decimal) en el puerto A del ppi
          ;este valor se usara para seleccionar el registro 15 del AY mas abajo

ld b,&f6 ;PPI port C
in a,(c) ;lee del puerto C del PPI
and &30 ;&00110000 (ENTIENDO QUE ESTA COMPARACION SIEMPRE DEVOLVERA 0?
ld c,a ;a=0 de primeras
or &c0 ;%00000000 or &11000000 ;setea el PSG function selection con los bits 7 y 6 a 1
       ;el PSG function selection entonces actua seleccionando el registro del ay que elegimos antes.
out (c),a ;&f6c0 de primeras (bit 7 y bit 6 a 1, Select PSG register)
          ;es decir se selecciona el registro 15 del AY (External Dataregister Port A)
          ;el registro 15 del AY se usa en el Amstrad CPC para recibir datos del teclado

out (c),c ;&f600  pone el PPI en inactive (se debe hacer siempre que se le manda un comando al PPI)

;

inc b ;apunta a puerto "control" del PPI
ld a,&92 ;%10010010 ;If Bit 7 is "1" then the other bits will initialize Port A-B as Input or Output
         ;bit 4=1  PPI PORT A INPUT mode
out (c),a ;pone el puerto A como INPUT
push bc ;guarda puerto de control del PPI
set 6,c ;registro c es &00 aqui, al activar su bit 6, lo convierte en &40
        ;&40 es la primera linea del teclado a escanear (va de &40 a &49)
        ;aqui les valdria con poner ld c,&40, pero supongo que quieren marear un poco la perdiz.

.escanea_lineas_teclado
ld b,&f6 ;puerto C PPI 
out (c),c ;Introduce la linea del teclado que queremos escanear (ira desde &40 a &49)
ld b,&f4 ;puerto A PPI (que recordemos esta como INPUT)
in a,(c) ;Lee atraves del puerto A del PPI, lo que nos manda el Registro 15 del AY (teclado)
         ;Es decir, el resultado que devuelve el escaneo de la linea del teclado que le hemos mandado
         ;cada bit del registro a es 1 tecla (8 teclas en total por linea)
         ;si no se ha pulsado ninguna tecla de la linea de teclado escaneada a tomara valor &FF
         ;y si se ha pulsado alguna tecla, el bit correspondiente vendra a 0

cpl ;invierte resultado devuelto por el AY, es decir, si no se ha pulsado nada a=&00
    ;y si se ha pulsado alguna tecla, su bit ahora sera 1

ld (de),a ;guarda en el buffer de teclado la linea escaneada
inc de ;incrementa buffer
inc c ;incrementa linea de teclado a escanear
ld a,c
and &0f ;%00001111
cp &0a ;&0a=10 decimal, numero de lineas totales que escanea del teclado
jr nz,escanea_lineas_teclado ;si no hemos escaneado todas las lineas sigue escaneando

;por aqui hemos escaneado todas las lineas de teclado y guardado en el buffer las posibles pulsaciones
pop bc ;recupera puerto de control del PPI
ld a,&0082 ;%10000010 ;If Bit 7 is "1" then the other bits will initialize Port A-B as Input or Output
           ;bit 4=0  PPI PORT A OUTPUT mode
out (c),a ;configura PPI
dec b ;apuntamos a pueto &f7 ;PPI port C
out (c),c ;pone el PPI en inactive (se debe hacer siempre que se le manda un comando al PPI)
ei ;activa interrupciones
ret

;-----------------------------------------------------------------------------
.pon_colorines
ld hl,desplazamiento_puntero_dato_color
ld b,&10 ;16 colores a setear

.bucle_colores
ld e,(hl)
ld d,&00
push hl
ld hl,datos_colores
add hl,de ;usa una especie de desplazamiento para leer el color
          ;supongo que para marear la perdiz a los mirones de codigo fuente
ld a,(hl)
call pon_color
pop hl
inc hl
djnz bucle_colores
ret

;------------------------------------

;----CODIGO NO USADO APARENTEMENTE--------
;este codigo pone supuestamente 16 colores en el gate array
;pero nunca es llamado, ya que se hace en la rutina "pon_colorines"
di
ld b,&10
.l052d
push hl
ld a,(hl)
call pon_color
pop hl
inc hl
djnz l052d
ei
ret
;----FIN CODIGO NO USADO APARENTEMENTE--------

.pon_color
push bc
ld c,b
dec c
ld b,&7f
out (c),c
or &40
ld c,a
out (c),c
pop bc
ret

;----------------------------------------------------------

.comprueba_pulsacion_tecla_requerida
;esta rutina devuelve
;Z=0 si se pulso tecla consultada en la linea de teclado de buffer
;Z=1 si no se pulso

;por aqui entra en cada iteracion del bucle situado en &04b0
push af ;a lo leyo de un buffer en l05a4
ld a,(valor_FF_siempre);registro a siempre tomara valor &FF
and &a0 ;&11111111 and %10100000 = %10100000
        ;registro a SIEMPRE tomara valor &A0

ld c,a ;c=&A0
pop af ;recupera dato leido en 05a4
ld hl,buffer_tecla_pulsada
call elige_posicion_buffer_teclado_y_bit_a_consultar
;a viene cargado con un valor que oscilara entre
;&1,&2,&4,&8,&10,&20,&40,&80 (leido de una zona de memoria usando un puntero y desplazandolo)
;lo usa para decidir que bit consultar en la linea de teclado requerida
;Esto es cosa de Opera Soft, no tiene nada que ver con manejar el teclado de forma normal.


and (hl) ;aqui consulta si se pulso el bit requerido
         ;en la zona de memoria del buffer del teclado
         ;si se pulso tecla Z=0
         ;si no se pulso tecla Z=1
ret

;--------------------------------------------------

.elige_posicion_buffer_teclado_y_bit_a_consultar
push de ;guarda puntero misterioso
push af ;guarda valor leido en &05a4 en su momento
and &f8 ;a=&4f de primeras, &17 de segundas, &12, &2f,&1b,&22,&41,&40
        ;%01001111 and %11111000 = %01001000 (&48) de primeras 
        ;resultados
        ;&48,&10,&10,&28,&18,&20,&40,&40

rrca ;divide entre 2
rrca ;divide entre 2
rrca ;divide entre 2
     ;resultados
     ;&09,&02,&02,&05,&03,&04,&08,&08

 
ld e,a ;guarda resultado de division
ld d,&00 ;carga en registro de el desplazamiento para leer en nuestro buffer de teclado
         ;la linea &48
add hl,de ;se desplaza en nuestro buffer de teclado 
          ;&05a1 ;linea &49 teclado ;linea de pulsaciones de joystick y tecla 'del'
          ;&059a ;linea &42 teclado ;linea control, f4, return, etc
          ;&059a ;linea &42 teclado ;linea control, f4, return, etc
          ;&059d ;linea &45 teclado ;linea space, etc.
          ;&059b ;linea &43 teclado ;linea 'p', etc.
          ;&059c ;linea &44 teclado ;linea 'o',etc
          ;&05a0 ;linea &48 teclado ;linea 'a','q',TAB
          ;&05a0 ;linea &48 teclado ;linea 'a','q',TAB

pop af ;recupera valor leido en &05a4
push hl ;guarda posicion del buffer de teclado con el desplazamiento
ld hl,bit_a_consultar_linea_teclado ;zona con datos &1,&2,&4,&8,&10,&20,&40,&80
and &07 ;&4f de primeras
        ;%01001111 and %00000111=%00000111
ld e,a
add hl,de ;desplaza puntero en la zona donde se elegira bit a consultar de la linea requerida
ld a,(hl) ;a=&80
pop hl ;recupera posicion del buffer de teclado con el desplazamiento
pop de ;recupera puntero misterioso
ret


.comprueba_buffer_joystick
ld a,(linea_teclado_joystick)
and &3f ;comprueba si se ha pulsado alguno de los 5bits del teclado
ld h,a ;lo guarda en registro h
ret

;----------------------------------------------------------

.configura_CRTC
;setea CRTC
;R1=&28
;R2=&2E
;R6=&19
;R7=&1E

ld hl,datos_configuracion_CRTC
.bucle_seteo_CRTC
ld b,&bc ;selecciona puerto del CRTC para elegir registro
ld c,(hl);lee numero de registro a seleccionar
inc hl
out (c),c
inc b ;selecciona puerto del CRTC para escribir dato en el registro seleccionado
ld c,(hl)
out (c),c
inc hl ;incrementa puntero de registro y datos
bit 7,(hl) ;comprueba que no sea valor &FF (fin de configuracion CRTC)
jr z,bucle_seteo_CRTC
ret

;-------------------------------------------------
.datos_configuracion_CRTC
db &01
db &28
db &02
db &2e
db &06
db &19
db &07
db &1e
db &ff ;marca final de configuracion CRTC

.dato_pulsacion_teclado_y_joystick
db &FF

.contador_activa_parpadeo
db &FF
.variable_1_o_2_seleccionado
db &00
.contador_interrupcion
db &FF

db &FF
db &FF
db &FF

.buffer_tecla_pulsada
db &FF ;linea &40 keyboard
db &FF ;linea &41 keyboard
db &FF ;linea &42 keyboard
db &FF ;linea &43 keyboard
db &FF ;linea &44 keyboard
db &FF ;linea &45 keyboard
db &FF ;linea &46 keyboard
db &FF ;linea &47 keyboard
db &FF ;linea &48 keyboard
.linea_teclado_joystick
db &FF ;linea &49 keyboard


.valor_FF_siempre
db &FF

db &FF ;este valor no se usa en este programa para nada...

.datos_para_calculo_desplazamiento_buffer_y_bit ;(situado en &05a4)
db &08 ;valor contador de bucle en bucle situado en &04c6
db &4f 
db &17 
db &12 
db &2f 
db &1b 
db &22
db &41
db &40 

.datos_colores ;esta tabla de colores usa un desplazamiento de indice, no estan contiguos
db &14
db &10
db &15
db &1c
db &18
db &1d
db &0c
db &05
db &0d
db &16
db &06
db &17
db &1e
db &00
db &1f
db &0e
db &07
db &0f
db &1a
db &19
db &13
db &12
db &02
db &09
.l05c5 ;mas datos colores
db &0a
db &03
db &0b
db &13
db &15
db &0e
db &0b
db &1e
db &00
db &1c

;-------------------ESTOS DATOS DE AQUI ABAJO NO PARECEN USARSE NUNCA--------------
.l05d0 equ $ + 1
.l05cf
ld c,&0015
ld d,&0017
inc c
ld a,(de)
inc c
ld a,(bc)
inc d
nop
inc de
dec b
ld b,&001f
dec d
ld (bc),a
inc e
inc bc
dec c
rlca
ld c,&04
inc c
dec bc
inc d
;-----------FIN DATOS QUE NO PARECEN USARSE NUNCA--------------------------

.bit_a_consultar_linea_teclado
db &01 ;linea &48 tecla '1'
db &02 ;linea &48 tecla '2'

db &04 ;linea &42 tecla 'f4'
       ;linea &44 tecla 'o'

db &08 ;linea &43 tecla 'p'
db &10
db &20 
db &40 
db &80 ;bit a consultar en
       ;linea &49 tecla 'del'
       ;linea &42 tecla 'control'
       ;linea &45 tecla 'space'

.desplazamiento_puntero_dato_color
db &00
db &02
db &01 
db &14
db &0b
db &13
db &09
db &0c
db &19
db &1a
db &0d
db &04
db &0f
db &06
db &03
db &00

;----------------------------------------------------------------
.comprueba_proteccion_anticopia

;una vez seleccionado en menu fase 1 o fase 2, vendra por aqui a comprobar anticopia

ld ix,datos_formato_disco_anticopia
                          ;direccion donde estan los datos de formato del disco que mandara al FDC para configurarlo.
                          ;los datos que leera son relativos al track 40, con parametros especiales
                          ;sector ID inicial &08
                          ;sector ID final &08
                          ;longitud de sector &08
                          ;la longitud de sector se calcula con la formula (2^&08)*128=32.768bytes por sector
                          ;el FDC del amstrad CPC no es capaz de leer esa cantidad de datos por sector
                          ;se debe estar configurando para comprobar si el disco es original.
                          ;aunque el valor &08 no es un valor valido para el FDC del amstrad CPC
                          ;si se ha formateado con ese valor, al leerlo hay que especificar ese &08 igual.
                          

ld a,&28 ;track inicial a leer (track 40 del disco, el ultimo fisico)
         ;Este track tiene un formato especial, incluso con GAPs. 
         ;Lo usara para comprobar que es el disco original el que esta insertado.

ld hl,&bfff ;direccion inicial memoria RAM a escribir
ld bc,&0612 ;datos a leer en total del disco (1.554 bytes)
.l060e equ $ + 2
call &0116 ;reusa el loader original que cargo este mismo menu
           
;por aqui volvera desde loader original (el que carga el menu de eleccion de fases)
;ha leido del track 40 sector &08 la cantidad de 1.554 bytes
;las ha escrito en las posiciones de memoria &B9EE-&BFFF

;ahora cargara mas datos desde disco...
.l0612 equ $ + 3
ld ix,datos_formato_disco_anticopia2
ld a,&28 ;track 40 otra vez
ld hl,&bfff ;direccion inicial memoria RAM a escribir
ld bc,&00ff ;datos a leer en total del disco (255 bytes)
call &0116 ;vuelve a saltar al loader original

;por aqui volvera desde loader original (el que carga el menu de eleccion de fases)
;ha leido del track 40 sector &7 la cantidad de 255 bytes
;las ha escrito en las posiciones de memoria &BF01-&BFFF

ld b,&ff ;numero de datos a comparar entre las 2 lecturas anticopia
ld hl,&bfff ;aqui estan los datos de la segunda lectura de la proteccion anticopia
ld de,&baed ;zona que se escribio con datos de la primera lectura anticopia

.bucle_comparacion_datos
ld a,(de) ;a=&4E de primeras...
cp (hl) ;en (hl) hay &4E tambien de primeras...
jr nz,piraton ;si no coincide la comparacion, entonces el disco insertado no es el original.

;por aqui sigue comparando datos de las dos lecturas anticopia
;si algun byte no es igual, no pasara la proteccion anticopia.
dec hl
dec de
djnz bucle_comparacion_datos

;por aqui ha pasado la proteccion anticopia
xor a ;pone a 1 el flag Z, lo usara despues del ret para comprobar que se paso la anticopia
ret

.piraton
;por aqui NO se ha pasado la proteccion anticopia
ld a,&01
or a ;pone a 0 el flag Z, para indicarle a la rutina que llamo a esta que la proteccion anticopia
     ;NO se ha pasado correctamente
ret

;---------------------------------------------------------------------------------------------
.datos_formato_disco_anticopia
;Estos datos de formato del disco son un poco especiales, ya que el track final del disco original
;tiene un formato DIFERENTE a los anteriores. Es posible que sea por proteccion anticopia.
;los sectores ID en el track 40 van de &00 a &08
;como se puede ver, configurara el comando READ DATA como sector INICIAL y FINAL como sector ID &08

db &8 ;parametro 5 para comando READ DATA
             ;&08 (32.768 bytes por sector)
             ;como ya he dicho el FDC del Amstrad CPC no puede leer esa cantidad de datos por sector.
             ;pero si es necesario para leer correctamente los datos si se formateo con ese parametro el disco.

db &8 ;parametro 4 para comando READ DATA
             ;&08 sector INICIAL

db &8 ;parametro 6 para comando READ DATA
              ;&08 SECTOR END OF TRACK

.formato_disco_lectura_fases
db &03 ;parametro 5 para comando READ DATA
       ;&03 (1.024 por sector)

db &01 ;parametro 4 para comando READ DATA
       ;&01 sector INICIAL

db &05 ;parametro 6 para comando READ DATA
       ;&5 SECTOR END OF TRACK

.datos_formato_disco_anticopia2
db &01 ;parametro 5 para comando READ DATA
       ;&01 256 bytes por sector
       
db &07 ;parametro 4 para comando READ DATA
             ;&07 sector INICIAL

db &07 ;parametro 6 para comando READ DATA
              ;&08 SECTOR END OF TRACK

;los datos a partir de aqui abajo son los sprites que pinta en pantalla.

;--------------FIN MENU DE SELECCION DE FASE-----------------------------------------------------------
