;LOADER PRINCIPAL TERMINATOR 2 ----------Speedlock D7 - 1989 ---------------
;JOSEMAN 2024
;LOADER0

;ES EL TERCER LOADER QUE SE LEE DE DISCO, pero voy a llamarle LOADER0
;LOS OTROS 2 LOADERS SON STANDARD Y NO HACEN NADA RARO, NO LOS DOCUMENTO.
;ASI QUE EN LA DOCUMENTACION LLAMARE LOADER0 A ESTE, LOADER1 Y LOADER2 A LOS OTROS

;ESTE LOADER0 HACE 50 DESENCRIPTACIONES DE EL MISMO SEGUN VA AVANZANDO, USANDO DIFERENTE TECNICAS
;REGISTRO R, SITUACION DE STACK, ETC.
;TAMBIEN HACE 13 COMPROBACIONES A LO LARGO DEL LOADER SOBRE SI ESTA CONECTADA UNA MULTIFACE 2
;SE IRA BORRANDO SEGUN AVANZA.

;AL FINAL DE ESTAS TAREAS BORRA TODA LA MEMORIA DEL CPC (INCLUIDA PANTALLA), SALVO LO QUE QUEDA DE LOADER POR EJECUTAR.
;FINALMENTE, SALTA A &A687, QUE CARGA OTRO LOADER ESTE EL REAL DE CARGA DE DATOS DEL JUEGO

;ESTE NUEVO LOADER, EL REAL, SE CARGA EN &AA00, PERO VIENEN TODAS LAS DIRECCIONES DE MEMORIA CODIFICADAS
;LA RUTINA EN &AC4A DECODIFICA TODAS ESAS DIRECCIONES PARA HACERLAS USABLES POR EL LOADER AL EJECUTAR LA LECTURA DE DATOS.
;YA QUE ESTE LOADER EN &AA00 TIENE LA CAPACIDAD DE RELOCALIZARSE EN MEMORIA.

;ESTE LOADER (&AA00) ES EL CLAVE, YA QUE ES REALMENTE EL CODIGO DE CARGA DE DATOS DEL JUEGO.
;AL SER RELOCALIZABLE LO USA EN 3 ZONAS DIFERENTES
;&AA00 --> LOADER QUE CARGARA OTRO LOADER ENCARGADO DE LEER LA PANTALLA DE PRESENTACION Y EL CODIGO PRINCIPAL DEL JUEGO.
;&0100 --> LOADER QUE CARGARA, COMO HE DICHO, PANTALLA DE PRESENTACION Y CODIGO PRINCIPAL DEL JUEGO.
;&0040 --> LOADER DE FASES, VIENE INTEGRADO EN EL CODIGO PRINCIPAL DEL JUEGO Y LO MOVERA A &0040 AL EJECUTAR JUEGO.
;ESTOS 3 LOADERS SON EXACTAMENTE EL MISMO, SOLO QUE RELOCALIZABLE.
;NOTA, aqui usare las direcciones ya relocalizadas, que no coinciden si por ejemplo echas un vistazo al loader ANTES de reloc.
;NOTA2, en los comentarios, el valor que toman los registros, estan comentados con el PRIMER VALOR que toman.

;-----------NOTAS IMPORTANTES PARA ENTENDER EL SPEEDLOCK A GROSSO MODO-------------------------------
;loader en &AA00 --> punto de entrada a rutina en &AA1A seria el loader real de carga de datos
;loader en &0100 --> punto de entrada a rutina en &3000 (hace ldir a &3000), mismo loader real de carga de datos.
;loader en &0040 --> punto de entrada a rutina en &0040 mismo loader que los anteriores.
;Este loader se usara para cargar ficheros de apoyo, ficheros del juego y fases del juego.
;loader0 carga ficheros de apoyo y a loader1 (rutina &AA1A)
;loader1 carga datos principales del juego (rutina &3000)
;loader2 carga fases del juego (rutina &0040)
;los ficheros de apoyo son un fichero de texto con nombres de fase y un fichero de datos para calcular tamdatos/track/sector
;NOTA, es muy importante tener en cuenta que estos loaders no usan nombres de ficheros realmente, solo track/sector.
;los textos se usan para posicionar punteros en track/sector y tamano datos.

;estos 3 loaders actuan de forma exactamente igual
;primero cargan un fichero de texto, comparan el texto que quieren cargar con ese fichero de texto,
;esa comparacion posiciona un puntero de 16bits
;posteriormente carga otro fichero de datos
;usaran ese puntero para calcular tamano de datos a cargar, track y sector desde donde iniciar lectura de datos en disco.

;-----------COMO PROCEDER PARA COPIAR LOS DATOS DEL JUEGO PARA UN POSIBLE CRACK ------------------------------
;con Terminator 2 y Darkman (en mi Github) los pasos son exactamente los mismos (solo que cambian las direcciones)
;en el terminator 2

;para pantalla de carga y ficheros principales juego
;breakpoint en &3000
 ;reg hl=&018C --> direccion donde esta texto "TITLE" (PANTALLA DE CARGA)
 ;reg de=&BFF0 --> zona de RAM donde metera los datos (16bytes datos colores y pantalla)
;breakpoint en &30B6
 ;reg de=&4010, tamano a copiar de datos (en este caso 16 bytes datos colores + &4000 de pantalla de carga)
;breakpoint en &306A
 ;En winape -> select block -> &BFF0 - &FFFF -> save... -> elige nombre fichero.
;repite pasos para "LOWCODE" y MAINCODE

;para fases
;breakpoint en &0040
 ;reg hl=&24ED --> direccion donde esta texto "FRONTSC" (PANTALLA PRINCIPAL MENU EN ESTE CASO, DESPUES SERAN FASES)
 ;reg de=&3FF0 --> zona de RAM donde metera los datos (16bytes datos colores y pantalla)
;breakpoint en &00F6
 ;reg de=&4010, tamano a copiar de datos (en este caso 16 bytes datos colores + &4000 de pantalla de carga)
;breakpoint en &00AA
 ;En winape -> select block -> &3FF0 - &7FFF -> save... -> elige nombre fichero.
;repite pasos para toodas las fases segun se cargan (no son pocas y algunas fases cargan mas de un fichero)

;Despues de todo esto, toca hacer la magia de los loaders fabricacion casera para que se comporten como los loaders originales
;es tedioso, muy tedioso, no lo voy a negar
;--------------------------------------------------------------------------------------------------------------


;------------------DOCUMENTACION DE LOADER ORIGINAL-------------------------------------------------------------------
;LOADER0 se inicia aqui, donde hara una locurota de 50 desencriptaciones y 13 comprobaciones del Multiface conectado.
;pero como he dicho, el meollo empieza en rutina &AC41

;situacion loader &9EBF-&A849
org #9ebf
ld r,a ;a=&69, este resultado lo consiguio en funcion manda_CMDyPARAMETROS_FDC de loaders anteriores no documentados.
       ;&00 sub &97=&69 ;Z=0 C=1
       ;registro r, se usa para refrescar la memoria RAM (si no se pierde la informacion contenida en RAM),
       ;r se incrementa en cada instruccion ejecutada, el Z80 lo coloca en el bus de direcciones para provocar
       ;accesos "vacios" a la memoria, con lo que la mantenia en funcionamiento.
       ;NOTA, En amstrad CPC el refresco de memoria lo efectua el Gate Array NO el registro r del Z80.
       ;El registro R es conocido por usarse en por ejemplo, protecciones anticopia, ya que al incrementarse en cada
       ;instruccion ejecutada, es facil hacer comprobaciones de si se han ejecutado el numero de instrucciones esperadas
       ;en el loader, es decir, no se ha modificado el loader por digamos un cracker.


;--------------DESENCRIPTACION 1 DEL LOADER --------------------------------------------------
ld de,&097c ;para hacer bucle
ld hl,l9ece ;direccion donde empezara a incrementar un byte el numero de instruccion Z80 contenida en ella
            ;es decir lo contenido en esas direcciones no son las instrucciones reales antes de ejecutar el bucle
inc (hl)
dec de
ld a,d
inc hl
or e ;comprueba si reg DE ha llegado a 0 (aunque le cuela el inc hl por el medio para disimular la comparacion)

;aqui abajo cambia las instrucciones del codigo desde &9ECE-&A849; comprobado.
;pongo ya el codigo cambiado con el bucle anterior

;---inicio codigo cambiado con bucle inc (hl)
.l9ece equ $ + 2
jp nz,#9ec7 ;para hacer el bucle de cambio de codigo.

;por aqui ya ha cambiado todo el codigo desde &9ECE-&A849
jp l9ed2 ;efectua salto a una rutina ya cambiada con codigo real.
         ;aunque la rutina esta justo debajo de este jp, sigue justo por aqui debajo.

.l9ed2
ld bc,#7f89 ;Gate Array
out (c),c ;Mode 1, lower enable & upper disabled 
          ;activa la lower rom, porque si hay un Multiface 2 conectado al equipo, 
          ;al activar el multiface (lo hace justo aqui abajo), esa rom esta visible (como lectura)
          ;a partir de &0000 en el cpc.

;---------------COMPROBACION 1 PRESENCIA MULTIFACE 2-------------------------------

;proteccion frente a un Multiface 2 conectado al equipo
ld bc,#fee8 ;Multiface 2 ROM/RAM
out (c),c ;Activa Multiface 2 (visible en la lower ROM en el amstrad)
ld a,(#0000) ;lee de la LOWER ROM, si hay un multiface 2 conectado al CPC 
             ;en la posicion &0000 de la lower rom se leera el byte &F3
cp #f3 ;hay un &F3 en &0000 LOWER ROM?
jp z,#0000 ;si lo hay entonces es que se ha activado un multiface2 conectado al equipo. 
           ;salta a la direccion &0000 que en este caso es la ROM del multiface 2, pero el equipo se queda en un 
           ;bucle completo infinito sin hacer nada.
           ;entiendo que si se intenta usar el multiface 2, la copia que genere en este punto no sera usable
           ;por la zona en la que se encuentra el program counter (NO ESTOY SEGURO, aclaracion necesitada)

;por aqui no hay Multiface 2 conectado al equipo.

ld hl,l9ee9 ;(hl)=&00
.l9ee9 equ $ + 2
.l9ee8 equ $ + 1
ld bc,#0032 ;50bytes que movera de &9ee9
ld de,l9ee8 ;destino lddr
lddr ;pone a &00 (l9ee9)=&00 las direcciones &9EE8-&9EB7
     ;borra el principio de este loader e incluso mas hacia atras


;--------------DESENCRIPTACION 2 DEL LOADER --------------------------------------------------
ld hl,l9f04
ld bc,#0946 ;para bucle que va a hacer aqui abajo
ld d,#2c ;valor para efectuar operaciones con registro r
ld a,r ;LEE DEL REGISTRO r, cargado con &69 al principio de este loader.
       ;registro r se fue incrementando con cada instruccion ejecutada.
       ;al cargarlo con un valor predefinido al principio, y siendo conocedor de lo que hace este loader
       ;se puede saber el valor que deberia tener el registro r si nadie ha tocado nada.
       ;basado en ese valor va a decodificar el loader (&9F04-&A849)
       ;si "alguien" ha tocado el codigo del loader, digamos un cracker por poner un ejemplo.
       ;la decodificacion fallara y el loader dejara de funcionar.

xor d ;&49 xor &2c de primeras
      ;%01001001 xor %00101100
add (hl) ;le suma a registro A lo que hay en (hl)
sub #07 ;resta &07 al resultado del add anterior
ld (hl),a ;guarda ese resultado en (hl), es decir vuelve a cambiar el codigo de este loader
          ;pero esta vez dependiendo del valor del registro r
          ;cualquier modificacion en el inicio de este loader alterara el valor del registro r
          ;con lo cual lo que haria aqui es estropear el codigo que aqui esta poniendo con los
          ;ld (hl),a en bucle.
inc hl ;siguiente instruccion a "poner bien"
dec bc ;decrementa bucle de "decodificacion".
ld a,b
or c ;comprueba que bc ha llegado a &00 (fin de bucle)

;el codigo a partir de aqui abajo es cambiado con este bucle (incluido el jp nz del propio bucle)
;aqui abajo pongo ya el codigo cambiado
.l9f04 equ $ + 2
jp nz,#9ef7 ;si bc no ha llegado a 0 sigue bucleando, sigue "decodificando" instrucciones/codigo.
            ;decodifica codigo &9F04-&A849 (incluido el propio jp nz de este bucle)
            ;si algo falla, este propio jp fallara y el loader fallara.

jp l9f08 ;salta justo aqui abajo

;--------------DESENCRIPTACION 3 DEL LOADER --------------------------------------------------

.l9f08 ;vuelve a decodificar usando registro r como llave
;decodifica codigo &9F20-&A849 (incluido el propio jp que hace el bucle)
ld hl,&9f20 ;inicio a descodificar
ld bc,#092a ;tamano a descodificar.
ld d,#5f ;parametro definido con respecto al valor que deberia tener el registro r sin variacion de loader.
ld a,r
xor (hl)
xor d
ld (hl),a
ld d,a
inc hl ;siguiente direccion a decodificar.
dec bc ;decrementa bucle de decodificacion
inc d
ld a,c
or b
jp z,l9f23 ;cuando llegue a cero el bucle salta, el codigo de esa zona ya habra sido modificado.
;por aqui abajo se ha vuelto a modificar todo el codigo de loader.
;pongo el codigo ya modificado.

jp #9f10 ;salto para hacer bucle 
.l9f22 equ $ + 1
jp (ix) ;de inicio no ejecuta esta instruccion, al salir del bucle salta a &9F23, la sobreescribira de todas maneras.

.l9f23
ld hl,l9f23 ;inicio de este punto del programa
ld bc,#0064 ;tamano para el lddr, 100 bytes
ld de,l9f22 ;destino (justo detras)
lddr ;escribe el valor &21 desde &9F22-&9EBF, sigue borrando rastro del loader segun avanza.

;--------------DESENCRIPTACION 4 DEL LOADER --------------------------------------------------
;vuelve a decodificar el codigo del loader, una vez mas. &9F23-&A849
ld hl,l9f3e
ld bc,#090c
ld a,r
add (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c
;pongo el codigo ya decodificado por rutina anterior
.l9f3e equ $ + 2
jp nz,#9f34 ;mientras no llegue a 0 reg bc sigue decodificando

jp l9f42 ;salta justo aqui abajo

;---------------COMPROBACION 2 PRESENCIA MULTIFACE 2-------------------------------

.l9f42 ;vuelve a mirar si hay una multiface 2 conectada al equipo.
ld bc,#7f89 ;Gate Array
out (c),c  ;Mode 1, lower enable & upper disabled 
          ;activa la lower rom, porque si hay un Multiface 2 conectado al equipo, 
          ;al activar el multiface (lo hace justo aqui abajo), esa rom esta visible (como lectura)
          ;a partir de &0000 en el cpc.

ld bc,#fee8 ;Multiface 2 ROM/RAM
out (c),c ;Activa Multiface 2 (visible en la lower ROM en el amstrad)
ld a,(#0000);lee de la LOWER ROM, si hay un multiface 2 conectado al CPC 
             ;en la posicion &0000 de la lower rom se leera el byte &F3
cp #f3 ;hay un &F3 en &0000 LOWER ROM?
jp z,#0000 ;si lo hay entonces es que se ha activado un multiface2 conectado al equipo. 
           ;salta a la direccion &0000 que en este caso es la ROM del multiface 2, pero el equipo se queda en un 
           ;bucle completo infinito sin hacer nada.
           ;entiendo que si se intenta usar el multiface 2, la copia que genere en este punto no sera usable
           ;por la zona en la que se encuentra el program counter (NO ESTOY SEGURO, aclaracion necesitada)

;por aqui no hay Multiface 2 conectado al equipo.

;vuelve a borrar/machacar el loader hacia atras &9f59-&9f27
ld hl,l9f59 ;inicio de borrado
.l9f59 equ $ + 2
.l9f58 equ $ + 1
ld bc,#0032 ;tamano de borrado
ld de,l9f58 ;destino (va decrementando)
lddr ;borra

;--------------DESENCRIPTACION 5 DEL LOADER --------------------------------------------------

;vuelve a decodificar loader &9F74-&A849
ld hl,l9f74
ld bc,#08d6
ld d,#3f
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c
.l9f74 equ $ + 2
;pongo el codigo ya decodificado.
jp nz,&9F78

jp l9f78 ;salta justo aqui abajo

;---------------COMPROBACION 3 PRESENCIA MULTIFACE 2-------------------------------
;y otra vez que detecta si hay una multiface 2 conectada al equipo.
;ya no comento el codigo de la deteccion.
.l9f78
ld bc,#7f89
.l9f7b
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;por aqui no hay multiface 2 conectada
;vuelve a borrar rastro del loader &9f8f-&9F5D
ld hl,l9f8f
.l9f8f equ $ + 2
.l9f8e equ $ + 1
ld bc,#0032
ld de,l9f8e
lddr ;borra


;--------------DESENCRIPTACION 6 DEL LOADER --------------------------------------------------
;vuelve a decodificar codigo del loader
;decodifica &9FAA-&A849
ld hl,l9faa
ld bc,#08a0
ld d,#6d
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c
.l9faa equ $ + 2
;pongo el codigo decodificado
jp nz,#9f9d

jp l9fae ;salta justo aqui abajo

;vuelve a borrar su rastro hacia atras &9fb1-&9f4D
.l9fae
ld hl,l9fb1
.l9fb1
ld bc,#0064
ld de,&9fb0
lddr ;borra

;--------------DESENCRIPTACION 7 DEL LOADER --------------------------------------------------
;vuelve a descodificar el codigo del loader #cansino
;decodifica &9fcc-&a849
ld hl,l9fcc
ld bc,#087e
ld d,#63
ld a,r
add (hl)
sub d
ld (hl),a
inc hl
dec bc
ld a,b
or c
;pongo codigo ya decodificado
.l9fcc equ $ + 2
jp nz,#9fc1

jp l9fd0 ;salta justo aqui abajo.

.l9fd0 ;vuelve a borrar sus pasos
;&9FD0-&9F6C
ld hl,l9fd0
ld de,&9fcf
ld bc,#0064
lddr ;borra

;--------------DESENCRIPTACION 8 DEL LOADER --------------------------------------------------
;decodifica loader desde &A000-
ld bc,#084a
ld hl,&A000 ;posicion de datos loader (los cuales han sido decodificados tropecientas veces a estas alturas)
call l9fe4 ;hace call justo aqui abajo para meter en pila &9FE4
.l9fe4
pop ix ;recupera ese valor de pila ix=&9FE4 
ld de,#001c ;desplazamiento ix
add ix,de ;suma desplazamiento, ix=&A000 (lo usa como datos para decodificar, si se ha movido un byte el loader falla)
.l9feb
ld a,r
xor hx
sub (hl)
xor lx
ld (hl),a
dec bc
ld a,c
inc hl
or b
jp nz,l9ffd ;mini salto para marear la perdiz
jp la000 ;salto una vez decodificado loader
.l9ffd
jp l9feb ;hace bucle de decodificacion

;pongo datos ya decodificados
.la000
ld sp,la00f ;cambia de sitio el Stack Pointer (zona con datos del propio loader)

;vuelve a borrar sus pasos OTRA vez &A00c-&9fec (valor &ED de borrado)
ld hl,la00c
ld de,la00b
.la00b equ $ + 2
ld bc,#0020
.la00c
lddr ;borra

.la00f equ $ + 1
.la00e
jp pe,la024 ;Salta si el indicador de paridad/desbordamiento (P/O) esta a uno (pero salta a codigo sin decodificar)
            ;esta zona se DECODIFICA aqui abajo (incluido salto), &a00e


;--------------DESENCRIPTACION 9 DEL LOADER --------------------------------------------------
;VUELVE A DECODIFICAR EL CODIGO (ASI EN MAYUSCULAS)
ld hl,la023
.la014
ld de,la00e
ld bc,#0827
ld a,r
xor (hl)
ld (hl),a
ldi ;va metiendo en &a00e ultimo byte decodificado, tambien los va metiendo en la posicion correcta de memoria.
dec de ;decrementa de, el ldi lo incremento. Para mantener direccion &A00E en reg de.
ret po ;aqui hay una cosa importante, el stack se cambio a codigo del loader
       ;en ese codigo, el stack esta posicionado con valor &A024, que justamente es a donde tiene que saltar el loader
       ;cuando acabe de decodificar.
       ;PO se activara cuando registro BC=&0000, loader decodificado.

;pongo codigo ya decodificado.
.la023 equ $ + 1
jr &A01A ;bucle decodificacion.

.la024 ;salta aqui cuando el RET PO se cumple.
;borra los pasos del loader hasta este punto
ld hl,la024
ld bc,#0064
ld de,#a023
lddr ;borra &A023-&9FC0 (incluso borra partes ya borradas anteriormente, fiesta del borrado)

;--------------DESENCRIPTACION 10 DEL LOADER --------------------------------------------------
;VUELVE a decodificar loader. &A03F-&A849
ld hl,la03f
ld bc,#080b
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c
.la03f equ $ + 2
;pongo codigo ya decodificado
jp nz,#a035 ;bucle decodificacion

jp la043 ;salta justo aqui abajo

.la043 ;vuelve a borrar sus pasos... matame camion
ld hl,la043
ld bc,#0064
ld de,&a042
lddr ;borra &A042-&9FDF (con &21)

;--------------DESENCRIPTACION 11 DEL LOADER --------------------------------------------------
;vuelve a decodificar su propio codigo, &A05E-&A849
ld hl,la05e
ld bc,#07ec
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c
.la05e equ $ + 2
;pongo el codigo ya decodificado
jp nz,#a054

jp la062 ;salta justo aqui debajo

;---------------COMPROBACION 4 PRESENCIA MULTIFACE 2-------------------------------
.la062 ;vuelve a efectuar deteccion de posible multiface 2
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;vuelve a borrar sus pasos hasta aqui
ld hl,la079
.la079 equ $ + 2
.la078 equ $ + 1
ld bc,#0032
ld de,la078
lddr ;borra desde &A078-&A047 (con valor &00)

;--------------DESENCRIPTACION 12 DEL LOADER --------------------------------------------------
;vuelve a decodificar su propio codigo (sorpresa)
;decodifica &A094-&A849
ld hl,la094
ld bc,#07b6
ld d,#5e
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c
.la094 equ $ + 2
;pongo codigo ya decodificado
jp nz,#a087 ;bucle decodificacion

jp la098 ;salta justo aqui abajo

.la098 ;vuelve a borrar sus pasos
ld hl,la098
ld bc,#0064
ld de,&a097
lddr ;borra &A097-&A034 (con &21)

;--------------DESENCRIPTACION 13 DEL LOADER --------------------------------------------------
;vuelve a decodificarse (me aburro)

ld hl,la0b3
ld bc,#0797
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo ya decodificado
.la0b3 equ $ + 2
jp nz,#a0a9 ;bucle decodificacion

jp la0b7 ;salta justo aqui debajo.

;---------------COMPROBACION 5 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar multiface 2
.la0b7
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;borra sus pasos
ld hl,la0ce
.la0ce equ $ + 2
.la0cd equ $ + 1
ld bc,#0032
ld de,la0cd
lddr ;borra &a0cd-&a09d (&00)


;--------------DESENCRIPTACION 14 DEL LOADER --------------------------------------------------
;si, vuelve a decodificar.
ld hl,la0e9
ld bc,#0761
ld d,#2b
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c
;codigo ya decodificado
.la0e9 equ $ + 2
jp nz,#a0dc ;bucle deco

jp la0ed ;salta aqui abajo

;si, lo estas adivinando, vuelve a borrar su rastro.
.la0ed
ld hl,la0ed
ld bc,#0064
ld de,&a0ec
lddr ;borra &a0ec-&a089

;--------------DESENCRIPTACION 15 DEL LOADER --------------------------------------------------
;apuesto a que va a decodificar, si, estaba en lo cierto...
ld hl,la108
ld bc,#0742
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la108 equ $ + 2
jp nz,#a0fe ;bucle deco


jp la10c ;salta justo aqui debajo

;vuelve a borrar sus pasos
.la10c
ld hl,la10c
ld bc,#0064
ld de,&a10b
lddr ;borra  &A10B-&A0A8

;--------------DESENCRIPTACION 16 DEL LOADER --------------------------------------------------
;vuelve a decodificar &A127-&A849
ld hl,la127
ld bc,#0723
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la127 equ $ + 2
jp nz,#a11d ;bucle deco

jp la12b ;salta justo aqui abajo

;---------------COMPROBACION 6 PRESENCIA MULTIFACE 2-------------------------------
;VUELVE a detectar multiface 2
.la12b
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;y otra vez a borrar sus pasos.
ld hl,la142
.la142 equ $ + 2
.la141 equ $ + 1
ld bc,#0032
ld de,la141
lddr ;borra &A141-&A110 (&00), no borra todo, deja &a10d-&a10f

;--------------DESENCRIPTACION 17 DEL LOADER --------------------------------------------------
;vuelve a decodificar &A15D-&A849
.la148
ld hl,la15d
ld bc,#06ed
ld d,#2a
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
.la157
inc hl
dec bc
ld a,b
or c

;pongo codigo deco
.la15d equ $ + 2
jp nz,#a150 ;bucle deco

jp la161 ;salta aqui debajo

;--------------DESENCRIPTACION 18 DEL LOADER --------------------------------------------------
;VUELVE A DECODIFICAR &A179-&A849
.la161
ld hl,la179
ld bc,#06d1
ld d,#6d
ld a,r
xor (hl)
xor d
ld (hl),a
ld d,a
inc hl
dec bc
inc d
ld a,c
or b
jp z,la17c ;acabada decodificacion

;codigo ya decodificado
.la179 equ $ + 2
jp #a169 ;bucle deco

jp (ix) ;esta instruccion no se ejecuta nunca.

;salta aqui despues de la deco
.la17c
ld sp,&a18b ;cambia el stack de sitio (zona con datos loader)

;borra sus pasos
ld hl,&a188
ld de,&a187
ld bc,#0020
lddr ;borra &A187-&A168, deja sin borrar &A143-&A167, aunque lo borrara en su siguiente borrado de rastro.

.la18a
jp pe,la1a0 ;no se efectua este salto

;--------------DESENCRIPTACION 19 DEL LOADER --------------------------------------------------
;vuelve a decodificar.
ld hl,la19f
ld de,la18a
ld bc,#06ab
ld a,r
xor (hl)
ld (hl),a
ldi
dec de
ret po ;cuando bc llegue a &0000 se cumple este ret, "retorna" a &A1A0, ya que cuando cambio el stack
       ;tiene esa direccion ya cargada en el.

;pongo codigo ya decodificado
.la19f equ $ + 1
jr #a196 ;bucle deco

;salta aqui por direccion guardada en stack pointer al cambiarlo de sitio.

;borra sus pasos.
.la1a0
ld hl,la1a0
ld bc,#0064
ld de,la19f
lddr ;borra &A19F-&A13C


;--------------DESENCRIPTACION 20 DEL LOADER --------------------------------------------------
;vuelve a decodificarse &A1BB-&A849

ld hl,la1bb
ld bc,#068f
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la1bb equ $ + 2
jp nz,#a1b1 ;bucle deco

jp la1bf ;salta justo aqui debajo

;---------------COMPROBACION 7 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar multiface 2
.la1bf
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000


;borra su rastro.
ld hl,&a1d6
ld bc,#0032
ld de,&a1d5
lddr ;borra &A1D5-&A1A4

;--------------DESENCRIPTACION 21 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la1f1
ld bc,#0659
ld d,#3f
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo ya decodificado
.la1f1 equ $ + 2
jp nz,#a1e4 ;bucle decodificacion

jp la1f5 ;salta justo aqui abajo

;---------------COMPROBACION 8 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar multiface2
.la1f5
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000


;borra sus pasos
ld hl,la20c
.la20c equ $ + 2
.la20b equ $ + 1
ld bc,#0032
ld de,la20b
lddr ;borra &A20B-&A1DA (&00)

;--------------DESENCRIPTACION 22 DEL LOADER --------------------------------------------------
;vuelve a decodificar loader.
ld hl,la227
ld bc,#0623
ld d,#6d
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la227 equ $ + 2
jp nz,#a21a

jp la22b ;salta justo aqui abajo

;borr sus pasos
.la22b
ld hl,la22b
ld de,&a22a
ld bc,#0064
lddr ;borra &A22A-A1C7 (&21)


ld bc,#05ef
ld hl,la25b
call la23f ;llama justo aqui debajo con call para meter direccion siguiente a la actual del loader en el Stack Pointer

;--------------DESENCRIPTACION 23 DEL LOADER --------------------------------------------------
;decodifica loader
.la23f
pop ix ;recupera direccion actual en memoria del loader
ld de,#001c
add ix,de ;usara esta suma + direccion del loader en RAM para decodificar codigo.
.la246
ld a,r
xor hx
sub (hl)
xor lx
ld (hl),a
dec bc
ld a,c
inc hl
or b
jp nz,la258
jp la25b ;acabada decodificacion
.la258
jp la246 ;bucle decodificacion
;pongo codigo ya decodificado

;---------------COMPROBACION 9 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar Multiface 2 conectada
.la25b
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;vuelve a borrar sus pasos.
ld hl,&a272
ld bc,#0032
ld de,&a271
lddr ;borra &A271-&A240

;--------------DESENCRIPTACION 24 DEL LOADER --------------------------------------------------
;vuelve a decodificar loader
ld hl,la28d
ld bc,#05bd
ld d,#2f
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la28d equ $ + 2
jp nz,#a280 ;bucle decodificacion

jp la291 ;salta justo aqui debajo

;--------------DESENCRIPTACION 25 DEL LOADER --------------------------------------------------
.la291
ld de,#05ac
ld hl,la29e
dec (hl)
dec de
ld a,d
inc hl
or e

;pongo codigo decodificado
.la29e equ $ + 2
jp nz,#a297 ;bucle decodificacion

jp la2a2 ;salta aqui debajo

.la2a2
ld sp,la2b1 ;cambia de sitio stack pointer
;borra sus pasos
ld hl,la2ae
ld de,&a2ad
ld bc,#0020
.la2ae
lddr ;borra &A2AD-&A28E
.la2b1 equ $ + 1
.la2b0
jp pe,&a2c6 ;no se cumple

;--------------DESENCRIPTACION 26 DEL LOADER --------------------------------------------------
;vuelve a decodificar 
ld hl,la2c5
ld de,la2b0
ld bc,#0585
ld a,r
xor (hl)
ld (hl),a
ldi
dec de
ret po ;se cumple ret cuando bc=&0000, la pila ya tiene la direccion correcta por el cambio de stack pointer anterior
       ;(sp)=&A2C6
.la2c5 equ $ + 1
jr #a2bc ;bucle decodificacion

;borra sus pasos
.la2c8 equ $ + 2
ld de,la2c8
.la2c9
ld hl,la2c9
ld bc,#0064
lddr ;borra &A2C8-&A265

;--------------DESENCRIPTACION 27 DEL LOADER --------------------------------------------------

;vuelve a decodificar.
ld bc,#0566
ld sp,&a848 ;cambia sp, (sp)=&535D, &A848 es el final del loader, es decir usa esos datos decodificados cienes de veces
            ;para decodificarse otra vez, Y PARA DECODIFICAR LOADER AL REVES
            ;desde &A849-&A2E4

.la2d7
pop de ;de=&535D
ld a,r
xor d
ld d,a
push de
dec bc
ld a,c
dec sp
or b
jp nz,la2d7 ;bucle decodificacion

;pongo codigo decodificado

jp la2e7 ;salta justo aqui debajo.

;vuelve a borrar sus pasos.
.la2e7
ld hl,la2eb
.la2eb equ $ + 1
.la2ea
ld bc,#0032
ld de,la2ea
lddr ;borra &A2EA-&A2B9 (&32)

;--------------DESENCRIPTACION 28 DEL LOADER --------------------------------------------------

;vuelve a decodificarse
ld hl,la306
ld bc,#0544
ld d,#5f
ld a,r
xor d
add (hl)
cpl
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la306 equ $ + 2
jp nz,#a2fa ;bucle decodificacion

jp la30a ;salta aqui debajo

;vuelve a borrar sus pasos.
.la30a
ld hl,la30d
.la30d
ld bc,#0064
ld de,&a30c
lddr ;borra &A30C-&A2A9 (&01)

;--------------DESENCRIPTACION 29 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la328
ld bc,#0522
ld d,#35
ld a,r
add (hl)
sub d
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la328 equ $ + 2
jp nz,#a31d ;bucle decodificacion

jp la32c ;salta aqui abajo

;borra su paso, cambia stack
.la32c
ld sp,la33b ;cambia direccion del Stack Pointer
ld hl,la338
ld de,la337
.la337 equ $ + 2
ld bc,#0020
.la338
lddr ;borra &A337-&318 (&ED)

.la33b equ $ + 1
.la33a
jp pe,&a350 ;no se cumple

;--------------DESENCRIPTACION 30 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la34f
ld de,la33a
ld bc,#04fb
ld a,r
xor (hl)
ld (hl),a
ldi
dec de
ret po ;"retorna" a la direccion que estaba en el SP al cambiarlo aqui arriba, salta a la350

;pongo codigo ya decodificado
.la34f equ $ + 1
jr #a346 ;bucle decodificacion

;--------------DESENCRIPTACION 31 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld de,#04ed
ld hl,la35d
inc (hl)
dec de
ld a,d
inc hl
or e
;pongo codigo ya decodificado
.la35d equ $ + 2
jp nz,#a356 ;bucle decodificacion


jp la361 ;salta aqui debajo

.la361
ld hl,la361
ld bc,#0064
ld de,&a360
lddr ;borra &A360-&2FD (&21)

;--------------DESENCRIPTACION 32 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la37c
ld bc,#04ce
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo ya decodificado
.la37c equ $ + 2
jp nz,#a372 ;bucle decodificacion

jp la380 ;salta justo aqui debajo

;borra sus pasos
.la380
ld hl,la380
ld de,&a37f
ld bc,#0064
lddr ;borra &A37F-&A31C (&21)

;--------------DESENCRIPTACION 33 DEL LOADER --------------------------------------------------
;vuelve a decodificarse.
ld bc,#049a
ld hl,la3b0
call la394 ;mete en SP la direccion de memoria seguida a esta
.la394
pop ix ;recupera esa direccion en IX
ld de,#001c
add ix,de ;calcula valor para usarlo como clave para decodificar
.la39b
ld a,r
xor hx
sub (hl)
xor lx
ld (hl),a
dec bc
ld a,c
inc hl
or b
jp nz,la3ad ;salta mientras decodifica

jp la3b0 ;salto despues de decodificacion
.la3ad
jp #a39b ;bucle decodificacion

;---------------COMPROBACION 10 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar Multiface 2
.la3b0
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000


;borra sus pasos
ld hl,la3c7
.la3c7 equ $ + 2
.la3c6 equ $ + 1
ld bc,#0032
ld de,la3c6
lddr ;borra &A3C6-&A395 (&00)

;--------------DESENCRIPTACION 34 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la3e2
ld bc,#0468
ld d,#2f
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la3e2 equ $ + 2
jp nz,#a3d5 ;bucle decodificacion

.la3e5 equ $ + 2
jp la3e6 ;salta justo aqui debajo

;borra sus pasos
.la3e6
ld hl,la3e6
ld bc,#0064
ld de,la3e5
lddr ;borra &A3E5-&A382 (&21)

;--------------DESENCRIPTACION 35 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la401
ld bc,#0449
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c
.la401 equ $ + 2
jp nz,#a3f7 ;bucle decodificacion

jp la405 ;salta aqui debajo

;borra sus pasos
.la407 equ $ + 2
.la405
ld de,la407
.la408
ld hl,la408
ld bc,#0064
lddr ;borra &A407-&A3A4 (&21)


;--------------DESENCRIPTACION 36 DEL LOADER --------------------------------------------------
;vuelve a decodificarse

ld bc,#0427
ld sp,&a848 ;apunta al final del loader (sp)=&7E98
.la416
pop de ;recupera lo que hay en SP (datos del propio loader) lo usa para decodificar
ld a,r
xor d
ld d,a
push de ;lo vuelve a meter en pila (va hacia atras decodificando, usando SP para sacar y meter datos
dec bc
ld a,c
dec sp
or b
jp nz,la416 ;bucle decodificacion (usando pila)

;pongo datos decodificados
jp la426 ;salta justo aqui debajo

;borra sus pasos
.la428 equ $ + 2
.la426
ld hl,la429
.la429
ld bc,#0064
ld de,la428
lddr ;borra &A428-&A3C5 (&01)

;--------------DESENCRIPTACION 37 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la444
ld bc,#0406
ld d,#26
ld a,r
add (hl)
sub d
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo ya decodificado
.la444 equ $ + 2
jp nz,#a439

jp la448 ;salta justo aqui debajo

;--------------DESENCRIPTACION 38 DEL LOADER --------------------------------------------------
.la448
ld de,#03f5
ld hl,la455
inc (hl)
dec de
ld a,d
inc hl
or e

;pongo codigo decodificado
.la455 equ $ + 2
jp nz,#a44e ;bucle deco

.la458 equ $ + 2
jp la459 ;salta justo aqui debajo

;borra sus pasos
.la459
ld hl,la459
ld bc,#0064
ld de,la458
lddr ;borra &A458-&A3F5 (&21)

;--------------DESENCRIPTACION 39 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la474
ld bc,#03d6
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la474 equ $ + 2
jp nz,#a46a ;bucle deco

.la476 equ $ + 1
jp la478 ;salta justo aqui debajo

;---------------COMPROBACION 11 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar posible multiface 2
.la478
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;vuelve a borrar sus pasos.
ld hl,la48f
.la48f equ $ + 2
.la48e equ $ + 1
ld bc,#0032
ld de,la48e
lddr ;borra &A48E-&A45D

;--------------DESENCRIPTACION 40 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la4aa
ld bc,#03a0
ld d,#2d
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo decodificado
.la4aa equ $ + 2
jp nz,#a49d ;bucle decodificacion

.la4ad equ $ + 2
jp la4ae ;salta aqui debajo

;borra sus pasos
.la4ae
ld hl,la4ae
ld bc,#0064
ld de,la4ad
lddr ;borra &A4AD-&A44A (&21)

;--------------DESENCRIPTACION 41 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la4c9
ld bc,#0381
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c
.la4c9 equ $ + 2
jp nz,#a4bf ;bucle deco

jp la4cd ;salta justo aqui debajo

;---------------COMPROBACION 12 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar posible multiface 2
.la4cd
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;borra sus pasos
ld hl,la4e4
.la4e4 equ $ + 2
.la4e3 equ $ + 1
ld bc,#0032
ld de,la4e3
lddr ;borra &A4E3-&A4B2 (&00)

;--------------DESENCRIPTACION 42 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la4ff
ld bc,#034b
ld d,#2d
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo deco
.la4ff equ $ + 2
jp nz,#a4f2

jp la503 ;salta justo aqui debajo

;--------------DESENCRIPTACION 43 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
.la503
ld de,#033a
ld hl,la510
dec (hl)
dec de
ld a,d
inc hl
or e

;pongo codigo deco
.la510 equ $ + 2
jp nz,&a509 ;bucle deco

jp la514 ;salta justo aqui debajo


;borra sus pasos
.la514
ld sp,la523
ld hl,la520
ld de,la51f
.la51f equ $ + 2
ld bc,#0020
.la520
lddr ;borra &A51f-&A500

.la523 equ $ + 1
.la522
jp pe,&a538 ;no se cumple

;--------------DESENCRIPTACION 44 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la537
ld de,la522
ld bc,#0313
ld a,r
xor (hl)
ld (hl),a
ldi
dec de
ret po ;"vuelve" a &A538, valor deliverado en SP

;pongo codigo deco
.la537 equ $ + 1
jr #a52e ;bucle deco

;--------------DESENCRIPTACION 45 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la550
ld bc,#02fa
ld d,#6e
ld a,r
xor (hl)
xor d
ld (hl),a
ld d,a
inc hl
dec bc
inc d
ld a,c
or b
jp z,la553 ;salto cuando acaba de decodificar.

;pongo codigo deco
.la550 equ $ + 2
jp #a540 ;bucle deco
jp (ix) ;no se usa

;vuelve borrar sus pasos
.la553
ld sp,la562 ;cambio de stack para RETornar a sitio predifinido en el
ld hl,la55f
ld de,la55e
.la55e equ $ + 2
ld bc,#0020
.la55f
lddr ;Borra &A55E-&A43F (&ED)



.la562 equ $ + 1
.la561
jp pe,&a577 ;no se cumple

;--------------DESENCRIPTACION 46 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
.la566 equ $ + 2
ld hl,la576
ld de,la561
ld bc,#02d4
ld a,r
xor (hl)
ld (hl),a
ldi
dec de
ret po ;"vuelve" al acabar deco

;pongo codigo decodificado
.la576 equ $ + 1
jr &a56d ;bucle deco

;vuelve a borrar sus pasos
ld hl,la57b
.la57b equ $ + 1
.la57a
ld bc,#0032
ld de,la57a
lddr ;borra &A57A-&A549 (&32)

;--------------DESENCRIPTACION 47 DEL LOADER --------------------------------------------------
;vuele a descodificarse
ld hl,la596
ld bc,#02b4
ld d,#20
ld a,r
xor d
add (hl)
cpl
ld (hl),a
inc hl
dec bc
ld a,b
or c
;pongo codigo ya decodificado
.la596 equ $ + 2
jp nz,#a58a ;bucle deco

jp la59a ;salta justo aqui debajo

;--------------DESENCRIPTACION 48 DEL LOADER --------------------------------------------------

;vuelve a decodificarse
.la59a
ld de,#02a3
ld hl,la5a7
inc (hl)
dec de
ld a,d
inc hl
or e

;pongo codigo decodificado
.la5a7 equ $ + 2
jp nz,#a5a0 ;bucle deco

jp la5ab ;salta justo aqui abajo

;borra sus pasos
.la5ab
ld hl,la5ab
ld bc,#0064
ld de,#a5aa
lddr ;borra &A5AA-&A547 (&21)

;--------------DESENCRIPTACION 49 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la5c6
ld bc,#0284
ld a,r
xor (hl)
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo deco
.la5c6 equ $ + 2
jp nz,#a5bc ;bucle deco

jp la5ca ;salta justo aqui debajo

;---------------COMPROBACION 13 PRESENCIA MULTIFACE 2-------------------------------
;vuelve a detectar multiface 2
.la5ca
ld bc,#7f89
out (c),c
ld bc,#fee8
out (c),c
ld a,(#0000)
cp #f3
jp z,#0000

;borra sus pasos
ld hl,la5e1
.la5e1 equ $ + 2
.la5e0 equ $ + 1
ld bc,#0032
ld de,la5e0
lddr ;borra &A5E0-&A5AF (&00)

;--------------DESENCRIPTACION 50 DEL LOADER --------------------------------------------------
;vuelve a decodificarse
ld hl,la5fc
ld bc,#024e
ld d,#72
ld a,r
xor d
add (hl)
sub #07
ld (hl),a
inc hl
dec bc
ld a,b
or c

;pongo codigo descodificado
.la5fc equ $ + 2
jp nz,#a5ef ;bucle deco

jp la600 ;salta justo aqui debajo

;-------------DESENCRIPTACIONES Y COMPROBACIONES DE MF2 ACABADAS--------------------------------

.la601 equ $ + 1
.la600
ld sp,#bff8 ;cambia stack pointer a zona fuera del loader
exx ;cambia a registros secundarios
ld bc,#7f8d ;Gate Array
out (c),c ;Mode 1, lower & upper disabled
exx ;cambia a registros primarios

xor a ;a=&00
ld h,a ;h=&00
ex af,af' ;cambia af secundario
ld a,h ;a'=&00
ld l,h ;l=00, hl=&00
ld e,l 
ld d,e ;de=&00
inc de ;de=&0001
ld bc,la616
ld (hl),a ;hl=&0000, mete &00 en primera posicion de RAM del CPC
.la616
ldir ;hl=&0000, de=&0001, bc=&A616
     ;BORRA TODA LA MEMORIA DEL CPC HASTA ESTE PUNTO DEL LOADER
     ;&0000-&a616 (queda la posicion &A617 sin borrar)

;------SE HA EFECTUADO BORRADO DESDE INICIO DE RAM DEL CPC HASTA ESTE PUNTO &0000-&A617-------

.LA618
ld hl,#a84a ;parametro ldir (fin de loader+1)
ld e,l
ld d,h
inc de ;hl+1 posicion (fin de loader+2)
ld bc,#86ef
ld (hl),a ;(&A84A)=&00
ldir ;borra &A84B-&FFFF (incluye pantalla)
     ;borra &0000-&2F39

;------SE HA EFECTUADO BORRADO DESDE &A84B-&FFFF----------------------------------------------
;------SE HA VUELTO A EFECTUAR BORRADO INICIO DE RAM DEL CPC &0000-&2F39----------------------

exx ;registros secundarios
ld c,#89 ;bc=&7F89
out (c),c ;Mode 1, lower enable & upper disabled
exx ;recupera registros primarios

;----OJO LOWER ROM ACTIVADA--------------------------
ld hl,#0600 ;zona de LOWER ROM, NO RAM, CPC OS
ld a,#44
.la62f
cp (hl) ;compara &44 con &00
jr z,la635 ;en la posicion &0653 de la lower rom hay un &44, se cumple Z.
           ;OJO, solo hay un &44 en la rom del 6128, en la del 464 y 664 hay un &E1 (pos &0653)
           ;en 464 y 664 el &44 esta en posicion &0638 (464) &0633 (664)

inc hl ;hl=&0601, etc.
jr la62f ;bucle de comparacion de &44 con &00


.la635 ;por aqui salta cuando posicion en lower rom coincide con (&44), diferentes posiciones segun
       ;modelo de cpc
       ;hl esta posicionado diferente segun modelo de cpc
       ;me baso en el 6128
 
inc hl ;hl=&0654
inc hl ;hl=&0655
inc hl ;hl=&0656

ld e,(hl) 
inc hl
ld d,(hl) ;de=&08BD

ex de,hl ;hl=&08BD, de=&0657

ld (la643),hl ;sobreescribe el call de aqui abajo con llamada correcta segun modelo de cpc
call #0044 ;Copy first &40 bytes of this ROM to RAM at &0000 and initialise the low kernel jumpblock
.la643 equ $ + 1
call #bb5a ;SE SOBREESCRIBE CON LLAMADA ACORDE AL MODELO DE CPC
           ;CALL &08BD para cpc 6128, RESTAURA EL HIGH JUMP BLOCK
           ;BASICAMENTE ESTA reINICIALIZANDO EL FIRMWARE DEL CPC


;low y high jump block inicializado en este punto

ld hl,la687 ;direccion a donde saltara MC START PROGRAM
exx
ld bc,#7f8d ;Gate Array
out (c),c ;Mode 1, lower & upper disabled
exx

ld c,#ff ;rom selection number, ram principal.
jp #bd16 ;MC START PROGRAM, hl=direccion del programa a ejecutar
;SEGUIRA POR &A687
;-----------ATENCION SE SALTA A &A687, ALLI CARGARA DESDE DISQUETERA OTRO LOADER, EL QUE REALMENTE LEE LOS DATOS DEL JUEGO---

;ESTE CODIGO DE CAMBIO DE COLORES NO SE LLAMA EN NINGUN MOMENTO, POSIBLEMENTE EN OTROS JUEGOS SI.
;----CODIGO NO USADO-----------
xor a
.la655
push af
ld b,(hl)
ld c,b
inc hl
push hl
call #bc32
pop hl
pop af
inc a
cp #10
jr nz,la655
ld b,#00
ld c,b
call #bc38
ld e,#06
jr la676
;----FIN CODIGO NO USADO-----------

;.la66e
.motorON_waitROTATION
di
ld e,#65 ;bit 0=1, enciende motor disquetera
ld bc,#fa7e ;fdc motor control
out (c),e ;enciende motor disquetera

;bucle de espera para que la disquetera alcance la rotacion optima al encender el motor
.la676
ld b,#f5
.la678
in a,(c)
rra
jr c,la678
.la67d
in a,(c)
rra
jr nc,la67d
dec e
jr nz,la676
di
ret

;-----------PUNTO DE EJECUCION PARA LECTURA DE OTRO LOADER, LO QUE SERIA EL LOADER REALMENTE DE CARGA DE DATOS JUEGO-------
.la687 ;SALTO DESDE MC START PROGRAM

ld a,#01
call #bc0e ;PONE MODE 1 CON RUTINA DE FIRMWARE

call tintas_negro ;pone a negro tintas

call motorON_waitROTATION ;enciende motor disquetera y espera rotacion optima

ld a,#02 ;tamano datos para comando read deleted data (&02-->512bytes por sector)
ld (datasize_READDELETEDDATA),a
add #4a ;mete comando &4C READ DELETED DATA, sumandole el dato de tamano datos
        ;una forma un poco curiosa de ocultar que van a usar este comando del FDC.
ld (writeCMD_RDData),a

ld sp,&A600 ;coloca stack justo debajo del loader
ld hl,#aa00 ;donde leera los datos en RAM del comando READ DELETED DATA
ld d,#01 ;track a posicionar cabezal disquetera.
ld e,#c1 ;sector inicial a leer
ld c,#ca ;sector final a leer
call conf_FDCyREADDELETEDDATA ;la756

;por aqui vuelve de configurar parametros en el FDC, con respecto al formato del disco
;y efectuar una lectura de datos con comando READ DELETED DATA
;escribe datos de disco en &AA00-&BDFF. &1400 bytes leidos (5.120bytes)
;10 sectores leidos (&C1-&CA), 512bytes*10 sectores= 5.120 bytes leidos en total.
;no todo son datos reales, ya que el final se rellena con &E5 (marca de no dato en sector disco)
;DATOS REALES &AA00-&ACE2 (739bytes)
;DATOS BASURA (MARCADOS CON &E5, NO DATA EN DISCO) &ACE3-&BDFF (4381bytes)

ld hl,#aa00 ;inicio RAM datos leidos
ld a,#e5 ;parametro para desencriptar datos leidos
ld de,#1500 ;bucle total a realizar desencriptando datos

.la6b3 ;DESENCRIPTADO DE NUEVO LOADER CARGADO.
xor (hl) ;desencripta dato en registro A
ld (hl),a ;guarda ese dato
inc hl ;siguiente dato a desencriptar
dec de
ld a,d
or e
ld a,#e5 ;vuelve a meter parametro para desencriptar datos
jr nz,la6b3 ;buclea desencriptando todos los datos &AA00-&BEFF

;desencripta mas alla de los datos leidos de disco
;curiosamente donde habia &E5 los convierte en &00, donde habia &00 los convierte en &E5


ld hl,#aa00 ;inicio de datos ya desencriptados, lo usara para saltar al codigo recien cargado y desencriptado
exx ;opera con registros secundarios
ld bc,#fa7e ;Motor Control
out (c),c ;apaga motor disquetera.

;procede a borrar loader actual, tanto hacia atras como hacia delante

;borra loader por delante de este codigo
xor a 
ld hl,la6e8
ld de,la6e9
ld bc,#0162
ld (hl),a ;coloca valor &00 en primera posicion de memoria para efectuar el borrado a &00
ldir ;borra &A6E8-&A84A (CORROBORADO) (incluso codigo de loader jamas usado, quiza usado como senuelo)

;borra loader detras de este codigo
ld hl,la600
ld de,la601
ld bc,#00dd
ld (hl),a
ldir ;borra &A600-&A6DD (CORROBORADO), incluso este mismo comando ldir parcialmente


ld bc,#7f8d ;Gate Array 
out (c),c ;Mode 1, lower & upper disabled

xor a
ex af,af' ;usa af'
exx ;trae de vuelta registros primarios, entre ellos reg hl donde cargo inicio de datos recien cargados y desencriptados
jp (hl) ;ejecuta salta a codigo nuevo &AA00.
;AQUI SALTA A NUEVO CODIGO RECIEN CARGADO EN &AA00.
;fin de ejecucion loader actual, ha sido duro, un infierno Coronel Trautman
;AQUI ABAJO HAY ALGO CODIGO FAKE SIN USAR Y LAS SUBRUTINAS DE LECTURA DE DISCO PARA LEER NUEVO LOADER.
;EL NUEVO LOADER LO COMENTO MAS ABAJO EN SU POSICION DE CARGA &AA00

;-----codigo no usado loader------
.la6e9 equ $ + 1
.la6e8
ld a,#28
jr la6ed
xor a
.la6ed
ld bc,#bc01
out (c),c
inc b
out (c),a
ret
;---fin codigo no usado loader-----

;.la6f6
.tintas_negro
ld a,#10 ;numero de tintas
ld bc,#7f54 ;color negro
.la6fb
out (c),a
out (c),c ;pone a negro las tintas
dec a
jp p,la6fb
ret
;---------------------------

;----codigo no usado loader-----------------
ld c,#c8
ld hl,#a853
ld d,#00
jp la755
ld c,a
ld d,#01
ld e,#01
ld b,#16
.la715
ld a,#19
sub e
cp b
jr c,la722
ld a,e
add b
dec a
ld c,a
jp la73b
.la722
ld c,#18
push bc
push af
push hl
push de
call la73b
pop de
pop hl
pop af
pop bc
ld e,a
ld a,b
sub e
ld b,a
ld a,h
add e
ld h,a
ld e,#01
inc d
jr la715
.la73b
ld a,#4c
ld (writeCMD_RDData),a
ld a,#06
ld (datasize_READDELETEDDATA),a ;tamano datos para comando read deleted data (&06-->8.192 bytes por sector)
             ;OJO, el dsk no tiene este tamano de datos realmente (todos son de 512bytes)
             ;ver que hace en este caso.
ld a,c
dec e
sub e
ld (la7dd),a
ld a,e
ld (la7c8),a
ld e,#c1
ld c,e
jp conf_FDCyREADDELETEDDATA ;la756

.la755
ld e,c

;----fin codigo no usado loader-----------------


;.la756
.conf_FDCyREADDELETEDDATA
ld a,d ;d=&01
ld (track_posicionar),a
ld (track_READDELETEDDATA),a
ld (RAM_DATOS),hl ;hl=&AA00 ;sobreescribe valor de hl, es donde metera los datos en RAM del comando READ DELETED DATA
ld a,e ;e=&C1 sector inicial a leer
ld (sector_READDELETEDDATA),a
ld a,c ;c=&CA sector final del track
ld (sectorfinal_READDELETEDDATA),a

.la768
ld de,CMDyPARAM_READID ;la82c
call parametros_CMD_READID_mandalo ;manda_CMD_guarda_resultados ;la798

ld a,(#a84a) ;resultado 1 recibido
             ;primer comando mandado READ ID
             
or a ;si algo fue mal, se activo a 1 algun bit del resultado recibido
jr nz,la768 ;si es asi vuelve a mandar el comando

ld de,CMDyPARAM_SEEK ;direccion para comando &0f y parametros
            ;comando SEEK (para mover la cabeza al track especificado)
call la782 ;manda comando SEEK, y comprueba con SENSE INTERRUPT STATUS que el movimiento de cabezal se ha completado.

;por aqui se ha posicionado en el track especificado en parametros.
;posicionado en TRACK 0

;el track 0 y el track 1 contienen sectores con flag de datos borrados activo
;no todos los sectores del track 0 tienen ese flag activo
;sectores &C1, &C8, &C9, &CA NO tienen ese flag activo.
;siempre hablando del disco que nos concierne, el del Terminator 2, no se si eso cambia en otros juegos con speedlock.

ld de,CMDyPARAM_READ_DELETED_DATA ;algunos parametros de READ DELETED DATA se cambian en tiempo de ejecucion
                                  ;como track y sector para ir leyendo los datos.
.RAM_DATOS equ $ + 1
ld hl,la839 ;sobreescribe valor de hl, lo sobreescribe con &AA00
jr la7a0

.la782 ;llamada desde rutina que carga los parametros para ejecutar el comando seek
call la793
;vuelve al ejecutar comando seek al track especificado en parametros
;OJO los comandos RECALIBRATE y SEEK no devuelve bytes de resultado directamente
;es decir NO TIENEN "EXECUTION-PHASE" ni "RESULT-PHASE"
;en estes 2 casos, el programa debe esperar hasta que el Main Status Register
;SENALIZA que el comando ha sido completado
;ENTONCES
;se tiene que mandar un "Sense Interrupt State" para "terminar" el comando en si.

.la785
ld de,CMD_SENSEINTSTATUS

call parametros_CMD_READID_mandalo ; manda_CMD_guarda_resultados ;la798
ld hl,#a84a
bit 5,(hl) ;lee el Bit 5 del STATUS REGISTER 0, que es el SEEK END
           
jr z,la785 ;mientras bit5=0 NO se ha acabado el posicionamiento de cabezal. Buclea.

;por aqui SEEK completado correctamente.
ret ;vuelve a &A77A, justo despues a donde se llamo la ejecution del comando seek al track especificado.

.la793
ld bc,la820 ;lo usa para poner la direccion &a820 en el JP de la rutina &A7A3
jr manda_CMD_guarda_resultados ;la7a3
;vuelve despues del call en &A782

;.la798
;.manda_CMD_guarda_resultados
.parametros_CMD_READID_mandalo
ld bc,la808 ;lo usa para sobreescribir un jp despues de mandar el comando + parametros
            ;y saltar a la direccion correcta.
ld hl,#a84a ;direccion donde guardara los resultados del comando ejecutado por el FDC
            ;esta direccion esta justo despues de este loader.
jr manda_CMD_guarda_resultados ;la7a3
;no volvera por aqui

.la7a0 ;salto para ejecutar un READ DELETED DATA, el salto es en &A780
;parametros
;de=comando READ ID DATA y PARAMETROS
;hl=&AA00 (donde guardara los bytes leidos con comando READ DELETED DATA, un nuevo loader cargara)
ld bc,la7d1 ;para sobreescribir salto a la salida de esta rutina

;.la7a3
.manda_CMD_guarda_resultados
;parametros bc=&a808, hl=&a84a
ld (la7ca),bc ;sobreescribe un jp despues de mandar el comando y parametros al FDC
              ;para que salte a la zona adecuada.

ld a,(de) ;de=&A82C
ld b,a ;b=&02

.bucle_handshaking_cmd_parametros ;la7a9
push bc ;guarda bc (&0208) ;b=&02, numero de comando+parametros a mandar al FDC
inc de
ld a,(de) ;de=&a82d a=&4A
ld bc,#fb7e ;FDC Main Status register 
push af ;guarda comando

.bucle_handshaking ;la7b0
in a,(c)
add a
jr nc,bucle_handshaking ;la7b0
jp m,bucle_handshaking ;la7b0

pop af ;recupera comando
inc c ;FDC data register

out (c),a ;manda comando &4a al fdc READ ID
ld b,#08

.la7be ;bucle de espera despues de enviar comando o parametro
djnz la7be

pop bc ;reg b trae numero de cmd+paremetros a enviar comando
djnz bucle_handshaking_cmd_parametros ;la7a9 ;envia el comando y todos sus parametros

ld bc,#fb7e ;FDC MAIN STATUS REGISTER
.la7c8 equ $ + 2
ld de,#0000
.la7ca equ $ + 1
jp la7d1 ;sobreescribe este jp a la direccion correcta de salto
         ;la primera vez jp &a808, segunda &a820, etc.
;no volvera por aqui, si no a la funcion que llamo a esta subfuncion

;-----CODIGO NO USADO POR LOADER, LO BORRA SIN USAR-------
.la7cc
inc c
in a,(c)
dec c
dec de
.la7d1
in a,(c)
jp p,la7d1
ld a,d
or e
jp nz,la7cc
.la7dd equ $ + 2
ld de,#0000
.la7de
inc c
in a,(c)
ld (hl),a
dec c
inc hl
dec de
ld a,d
or e
jp z,la7fb
.la7ea
in a,(c)
jp p,la7ea
and #20
jp nz,la7de
jp la805
.la7f7
inc c
in a,(c)
dec c
.la7fb
in a,(c)
jp p,la7fb
and #20
jp nz,la7f7
.la805
ld hl,#a84a
;-----FIN CODIGO NO USADO POR LOADER, LO BORRA SIN USAR-------


.la808 ;viene por aqui despues de mandar comando y parametros

;bc=&FB7E FDC MAIN STATUS REGISTER
;mira si se acabo de completar la ejecucion del comando por parte del FDC
in a,(c)
cp #c0
jr c,la808 ;no completado? pues espero haciendo bucle

inc c ;FDC DATA REGISTER
in a,(c) ;GUARDA DATOS DEVUELTOS POR EL COMANDO MANDADO
ld (hl),a ;HL=&a84a, justo despues de este loader, guarda ahi los datos devueltos por el fdc
dec c ;FDC MAIN STATUS REGISTER
inc hl ;incrementa puntero datos 

ld a,#05
.la816 ;pequeno bucle de espera
dec a
jr nz,la816

in a,(c) ;todos los datos recibidos?
and #10
jr nz,la808 ;no? pues sigo recibiendo datos
ret ;vuelve al call original que hizo la llamada a estas subfunciones
    ;vuelve a &A76E la primera vez

.la820 ;mini rutina para el comando seek, el comando seek no tiene result phase, hay que usar otras tecnicas
       ;para saber cuando se ha completado, con lo cual entiendo que lo que hace aqui es inutil.
       ;de hecho no hace el bucle y RETorna a la funcion original que ejecuto el comando Seek
in a,(c)
jp p,la820
ret

;.la826
.CMDyPARAM_SEEK
db &03 ;numero de comando + parametros a enviar al FDC
db &0f ;comando seek 
db &00 ;parametro 1 , head y disquetera a usar 
;.la829
.track_posicionar
db &00 ;parametro 2 track al que hacer el seek 

;.la82c equ $ + 2
;.la82a
.CMD_SENSEINTSTATUS
db &01
db &08

.CMDyPARAM_READID
db &02 ;numero de comandos a mandar fdc ;ld bc,#0208
db &4a ;comando READ ID ;ld c,d
db &00 ;parametro para READ ID ;nop

;.la82f
.CMDyPARAM_READ_DELETED_DATA
db &09 ;numero de cmd+parametros a mandar
;.la830
.writeCMD_RDData
db &00 ;sobreescribe esta posicion con comando &4C
db &00 ;parametro 1 --> Disquetera 0 cabezal 0
.track_READDELETEDDATA
db &00 ;parametro 2--> TRACK para el READ DELETED DATA, lo sobreescribira segun quiera leer el track requerido.
db &00 ;parametro 3--> Cabezal a usar, cabezal 0.
.sector_READDELETEDDATA
db &00 ;parametro 4--> Numero de sector a ser leido. Lo sobreescribira segun quiera leer un sector u otro.
.datasize_READDELETEDDATA
db &00 ;parametro 5--> tamano de los datos en bytes que tiene ese sector. lo sobreescribira con tamano de datos en sector
       ;el disco del T2 solo tiene tamano &02 (512bytes/sector), pero tambien usa tamano 6, investigar en este caso.
.sectorfinal_READDELETEDDATA
db &00 ;parametro 6--> EOT, especifica cual es el sector final del Track que estamos leyendo.
;.la839 equ $ + 2
db &2A ;parametro 7--> tamano GAP, este tamano se decide en el formateo. &2A -> IBM Diskette type 2
db &FF ;parametro 8--> solo se usa si parametro 5 =&00, no es el caso en este loader.
.la839
db &00
db &1A ;ld a,(de)
db &06 ;ld b,#10
db &10
inc b
add hl,bc
ld (bc),a
jr #a851
inc bc
dec bc
ld bc,#1509
dec bc
dec c
ld d,h


;----fin loader------

.la84a_ST0 ;utilizan el final de loader para recibir los resultados de los comandos realizados
           ;&A84A son los resultados del Status Register 0



;------------CODIGO RECIEN CARGADO POR ESTE PROPIO LOADER, LO PONGO AQUI PARA NO HACER VARIOS TXT-----------
.lAA00
;NOTA MUY IMPORTANTE, AUNQUE ME REFIERO A "FICHEROS A CARGAR DESDE DISCO" A LO LARGO DEL LOADER 
;NO EXISTEN ESOS NOMBRES DE FICHERO EN DISCO, EL DISCO SOLO SE LEE MEDIANTE TRACK Y SECTOR
;ESTE LOADER USA UNOS NOMBRES COMO REFERENCIA PARA CALCULAR TRACK Y SECTOR DONDE LEERIA ESE "FICHERO"

di ;desactiva interrupciones, ya vienen desactivadas.
ld sp,#c000 ;coloca stack en zona standard de CPC

.laa04
ld hl,laa15 ;"nombre" de fichero a cargar. Este valor se usara para comparar con fichero de texto con "nombres" de ficheros
            ;y posicionar un puntero con el cual decidira tamano de datos track/sector inicio lectura disco de esos datos.

ld de,#0100 ;direccion donde cargara el fichero, lo carga aqui pero lo metera en pila para preservarlo varias veces
            ;supongo quieren enmascarar este dato a traves de varias rutinas.
            ;lo recuperara de stack a tomar por culo despues de chorrocientas rutinas, en &AA6F

ld bc,#ffff

call relocaliza_LDfichero_especREGHL ;hace varias cosas cosas ;laa1a 
           ;relocaliza todo este loader adaptandoloa a rango &AA00
           ;lee un fichero de texto con nombres de fase, lo compara con &AA15, texto "BOOT", DEVUELVE UN PUNTERO.
           ;carga otro "fichero" y usa ese puntero para calcular tamano de datos y track/sector donde iniciar la carga
           
;por aqui ha leido datos en &0100-&046B
;carry viene activado senalizando que todo bien

jr nc,laa04 ;si lectura incorrecta, vuelve a intentarla.

jp #0100 ;salta a loader 1, donde se leeran los datos principales del juego , ejecutara el juego y movera a &0040
         ;el loader de fases. Estos loaders son iguales, y actuan igual en loader0, loader1 y loader2, solo que son
         ;relocalizados en otras zonas de memoria.

;--------------------------------------------------------

.laa15 ;se usa en rutina que carga fichero de texto con nombres de fase, para posicionar puntero y calcular tamano datos
       ;y track/sector donde iniciar la lectura de datos.
db &42 ;B
db &4F ;O
db &4F ;O
db &54 ;T
db &00

.relocaliza_LDfichero_especREGHL
.LAA1A ;AQUI SE EFECTUA LA  RELOCALIZACION DEL LOADER ADAPTANDOLO AL RANGO &AA00 (RUTINA EN &AC4A)
       ;ESA MISMA RUTINA MODIFICARA EL INICIO DE ESTA RUTINA POR UN JP &AA35
       ;Y USARA .LAA1D AQUI ABAJO PARA GUARDAR RESULTADOS DE LOS COMANDOS AL FDC EN RESULT PHASE.
;parametros
;hl -> direccion con texto "BOOT"; usa un sistema de identificacion de datos a leer de disco desde texto con su nombre.
;de -> &0100, no se usara hasta varias rutinas saltadas despues, es la direccion donde escribira en RAM datos desde disco
;bc -> &ffff ;lo usara para obligar a unos saltos en &AC4A

;guarda parametros recibidos por esta rutina
push bc ;lo recuperara en rutina &AC4A
push de
push hl ;ESTAS 3 INSTRUCCIONES LAS CAMBIARA POR UN JP &AA35 en la rutina &AC4A
        ;CUANDO SE LLAMA A ESTA FUNCION DESDE &AC4A PUSH BC, PUSH DE, PUSH HL SE HAN CAMBIADO POR JP &AA35

.LAA1D ;Esta direccion la usara mas adelante como zona para guardar los resultados recibidos por el comando mandado al FDC
ld a,#c9 ;comando RET para el Z80
ld (#0000),a ;lo mete en &0000
call #0000 ;salta a &0000 pero RETornara porque le ha puesto ese comando en esa direccion
;es posible que esto anterior lo haga por si acaso algun hardware ha activado la lower rom?
;en el stack queda esta direccion de salto &AA25, con lo cual retorna por aqui a ese call &0000

dec sp 
dec sp ;decrementa sp para llegar a ese &AA25 que guardo al saltar al llamar a &0000 y RETornar
pop hl ;recupera esa direcion en registro hl, hl=&AA25
ld bc,#000b
and a ;pone flag de Carry a 0 para que no influya en esta resta con sbc de abajo.
sbc hl,bc ;resta a hl reg bc, carry esta a cero, no influye en la resta.
          ;&AA25 - &000b = &AA1A
;hl=&AA1A
;mete este valor en de
ld d,h
ld e,l
;de=&AA1A
ld bc,#0230
add hl,bc ;&AA1A + &0230 = &AC4A
;hl=&AC4A
jp (hl) ;efectua salto a &AC4A, calculado justo aqui detras
;nota, stack esta  con valor &AA15, lo recuperara en &AA35 despues de regresar por aqui abajo
;salta a &AC4A

;-------
.LAA35 ;por aqui se salta una vez que en rutina de &AC4A, relocaliza al loader adaptandolo a rango de &AA00
       ;... cambia la entrada de la rutina de &AA1A por un JP &AA35, salta a &AA1A que le traera por aqui.
       ;ESTA RUTINA (&AA35) LEE LOS 2 FICHEROS DE APOYO
       ;EL PRIMERO ES UN TEXTO CON LOS NOMBRES DE "ARCHIVOS", DONDE POSICIONARA UN PUNTERO AL "NOMBRE" ADECUADO
       ;ESE PUNTERO LO USARA CON EL SEGUNDO ARCHIVO QUE CARGA, PARA SABER TRACK/SECTOR Y TAMANO A CARGAR.
       ;EL SEGUNDO SON DATOS DE TAMANO DE DATOS Y TRACK/SECTOR INICIAL DONDE LEER ESOS DATOS.

ld a,i ;a=&00
ex af,af' ;af=&0044, af'=&0040
di ;desactivan interrupciones (ya vienen desactivadas)
exx ;cambian todos los registros primarios por los secundarios (menos regs af af')
push bc ;bc=&7F8D, lo guarda en pila. son los datos para GA Mode 1, lower & upper disabled
exx ;vuelve a recuperar registros primarios
push de ;de=&0100 lo mete en pila, ha estado preservando este valor varias veces, la carga de reg de con este valor
        ;se hizo bastante atras en el loader.
push hl ;hl=&AA15
ld bc,#fa7f ;bit 0 = 1, FDC MOTOR ON
out (c),c ;enciende disquetera
ld bc,#f540 ;PPI puerto B, lo va a usar para esperar VSYNC del CRTC, lo usa para perder tiempo y esperar 
            ;rotacion optima de disquetera
            ;el valor &40 del reg c lo usa para el bucle de perdida de tiempo.
.laa46
in a,(c)
rra
jr c,laa46 ;espera VSYNC
.laa4b
in a,(c)
rra
jr nc,laa4b ;espera Vsync
dec c
jr nz,laa46 ;bucle perdida de tiempo para esperar rotacion optima de motor disquetera.

;por aqui motor de disquetera encendido y rotacion optima alcanzada.

LD HL,(&AC48) ;recupera en hl el valor &AC4A, zona de RAM donde escribir los datos que se van a leer desde disco.
ld de,#0008 ;reg d TRACK, reg e SECTOR a leer (le suma &C0 para convertirlo a ID correcta, en otros casos le suma &80)
CALL LEE_DATOS_DISCO ;&AB6A
           ;se ejecutara un READ ID y tambien
           ;se ejecuta un SEEK, un sense interrupt status y un READ DATA.
;se han leido 512bytes del track 0 sector C8
;LO GUARDO EN &AC4A-&AE49 CORROBORADO, AUNQUE LOS DATOS REALES LEIDOS SON
;&AC4A-&ACC9, LO DEMAS ESTA RELLENADO CON BYTE NO DATA &E5
;LA LECTURA NUEVA DEL CODIGO CARGADO ES TEXTO
;BOOT, TITLE, LOWCODE, MAINCODEFRONTSC, COMBAT, SCENE1, CHASE, HAND, HANDSC, SCENE2, EYE, EYESC, HELI, SCENE3, ENDSC 

;CARRY VENDRA ACTIVADO SI LA LECTURA SE HIZO BIEN.
pop hl ;HL=&AA15, texto "BOOT" de loader cargado en &AA00
jr nc,error_lectura_datos ;NC SIGNIFICA ERROR DE LECTURA DE DATOS REQUERIDOS. ;laa8c

;por aqui todo bien

call busca_texto_tabla ;#AA8F ;parametro enviado reg hl con texto "BOOT" de primeras en loader de &AA00
           ;lo compara con texto reciencargado en &AC4A
           ;de primeras coincide "BOOT" con "BOOT"
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


jr nc,texto_NO_encontrado ;NO CARRY es que no se ha encontrado el texto deseado ;laa87

;de primeras al buscar "BOOT" se activa carry y viene por aqui
;"BOOT" significa para el loader que debe cargar un "fichero" para calcular tamano de datos a leer de disco, track y sector
push bc ;&0000 a stack, RECUERDA BC LO DEVUELVE CARGADO LA RUTINA busca_texto_tabla
ld hl,(&AC48) ;recupera puntero a textos cargados en zona &AC4A, zona de RAM donde meter los nuevos datos requeridos
ld de,#000a ;TRACK Y SECTOR A LEER DE DISCO, al sector le llama correctamente en la propia rutina
call LEE_DATOS_DISCO ;&AB6A
;LO GUARDO EN &AC4A-&AE49 CORROBORADO
;SON DATOS PARA CALCULAR BYTES A LEER DESDE DISCO Y TRACK SECTOR DONDE EMPEZAR A LEERLO
;CALCULARA ESTOS VALORES EN LLAMADA DE AQUI ABAJO A &AACD
pop bc ;bc=&0000, RECUERDA BC LO DEVUELVE CARGADO LA RUTINA busca_texto_tabla
pop hl ;&0100, por dios POR FIN usa el valor cargado al principio de todo del loader
jr nc,laa75 ;recuerda no carry es error en lectura de datos requeridos

;por aqui datos leidos correctamente
call &AACD ;ESTA RUTINA CALCULA BYTES A LEER DE DISCO, TRACK SECTOR DONDE LEERLOS
           ;Y EFECTUAR ESA LECTURA DE DISCO
           ;POR EJEMPLO DE VUELVE POR AQUI HA LEIDO DATOS Y ESCRITO EN 
           ;&0100-&046B
           ;trae hl cargado con siguiente posicion de RAM donde meter datos
           ;hl=&0500

.laa75 ;error de lectura de datos requeridos o datos leidos correctamente, senalizado con carry
push af ;entiendo que guarda el estado de Carry para saber si datos bien leidos o no
ld bc,#fa7e
out (c),c ;APAGA MOTOR DISQUETERA.
pop bc ;recupera en bc registro af
exx ;lo mete en registros espejo
pop bc ;bc=&7F8D, ya perdi el norte de donde saca este valor
       ;parecen valores GA Mode 1, lower & upper disabled
exx ;recupera segundo par de registros
    ;recuerda, metio en bc el valor de af proviniento de la salida de la rutina &AACD
and a ;quita Carry y activa flag Z si a=&00, de primeras a=&00
ex af,af' ;af=&0040 af'=&0054, Z activado, Carry desactivado
ld a,c ;recupera valor de flags a la salida del &AACD, carry activado si lectura correcta
rra ;bit 0 (carry flag) entra en Carry, es decir recupera resultado de lectura correcta de datos
ld a,b ;recupera valor de reg a a la salida de rutina &AACD
ret po ; P/V is reset
       ;overflow or parity. Is equal to 1 if the result of an operation has given an invalid result.
       ;In the case of a logic operation, is equal to 1 when the result parity is odd.
       ;la primera vez que pasa por aqui V = &00, ES DECIR, V ESTA RESETEADO, HACE EL RET
       ;VUELVE POR &AA10, que es el principio de todo del loader cargado en &AA00
       ;llamara a codigo recien cargado en &0100!!

;NO SE LLEGA AQUI NUNCA, EL LOADER DE FASES SI LO USA, AL SER UN LOADER "GENERICO" USA UNA U OTRA FUNCION SEGUN
;LO QUE QUIERA HACER.
ei
ret

.texto_NO_encontrado ;si no encuentra el texto buscado en fichero con nombres de archivo, llegara por aqui. ;laa87
pop hl ;hl=&0100 (direccion donde escribir nuevo fichero que estaba intentando leer desde disco)
       ;aunque solo lo POPea para sacarlo de pila y no dejarlo sin usar al dar error en texto de busqueda
ld a,#01
jr laa75 ;por aqui salta a apagar disquetera, al no estar Carry activado, la rutina de lectura devolvera error
         ;y reintentara todo el proceso otra vez.

.error_lectura_datos ;POR AQUI SALTA SI HUBO UN ERROR AL LEER DATOS CON READ DATA ;laa8c 
pop bc ;simplemente quita bc de pila ya que no se usara al producirse un error de lectura de datos.
jr laa75 ;por aqui salta a apagar disquetera, al no estar Carry activado, la rutina de lectura devolvera error
         ;y reintentara todo el proceso otra vez.

.LAA8F ;Se llama a esta rutina con un call, una vez comprobada que la carga del ultimo archivo fue correcta
.busca_texto_tabla
;parametro enviado reg hl con texto "BOOT" de primeras en loader de &AA00

ld bc,#0000 ;reg c se usara para INCrementar si no encuentra el texto buscado
            ;reg c puede llegar a alcanzar &40 si no se encuentra el texto en la tabla de nombres.
            ;&3F=63, esta rutina tiene la capacidad de consultar una tabla con 63 nombres de fichero!!
            ;lo que devuelve rutina esta rutina en reg BC es CRUCIAL para que la rutina calcula_tamano_cargado
            ;devuelva el tamano de datos correctos a cargar desde disco

ld de,(&AC48) ;ZONA INICIAL DE RAM DONDE METIO EL FICHERO DE TEXTO CON NOMBRES DE ARCHIVO, de=&AC4A.
.laa96
push bc ;&0000 a stack
push hl ;&AA15 a stack
push de ;&AC4A a stack

ld b,#08 ;tamano texto a comparar
call compara_textos ;compara zona con texto reciencargado en &AC4A y zona de loader &AA15
;si la comparacion es correcta Carry viene activado.

;de primeras compara "BOOT" CON "BOOT", asi que es correcta la busqueda, Carry activado.

pop hl ;hl=&AC4A
rla ;a=&00, mete carry en bit 0 de reg a, bit 7 de reg a se mete en carry
    ;con lo cual a=&01 y Carry desactivado en esta rotacion    
ld bc,#0008 ;numero de caracteres a saltar?
add hl,bc ;avanza puntero de zona de texto, hl=&AC52, apunta a "TITLE"
ex de,hl ;devuelve a reg de la nueva zona de texto
pop hl ;hl=&AA15, apunta a loader en &AA00 zona de texto "BOOT"
pop bc ;bc=&0000
rra ;vuelve a meter bit 0 a carry y carry a bit 7 de reg a, es decir lo deja como estaba antes del rla
ret c ;este carry se refiere a la correcta comparacion de los textos "BOOT" de primeras

;POR AQUI SI NO ENCUENTRA TEXTO BUSCADO
inc c ;si no encuentra el texto buscado, reg bc va incrementandose en valor
ld a,c
cp #40 ;cuando alcanza &40 deja de buscar texto, no lo ha encontrado en la tabla de texto
       ;resaltar que aunque el terminator 2 usa unos pocos ficheros, esta rutina tiene la capacidad de leer
       ;un monton de ficheros mas, ya que recorre toda la tabla hasta &AE42 buscando el nombre requerido.
jr nz,laa96
ret ;vuelve a la rutina que llamo a la comparacion de textos, pero sin Carry senalizado, es decir, dando error.

.laab0
.compara_textos
;parametros
;reg b=&08 ;para el bucle
;hl=&AA15 ;esto se cargo en el loader que se carga en &AA00, letras "BOOT"
;de=&AC4A (INICIO DE FICHERO TEXTO CON NOMBRES DE FASE), letras "BOOT"
ld a,(de) ;compara si el texto de reg hl es igual al de reg de
          ;aqui pasa un caso curioso, la primera vez compara el mismo texto "BOOT"
          ;PERO compara 8 caracteres, mientras lee BOOT, bien, pero despues recibe un 20 en zona de textos
          ;y un &00 en zona &AA19, destacar que en zona &AA1A hay CODIGO que usa el loader cargado en &AA00
          ;asi que JAMAS cuadrara la primera vez que busca BOOT, presupongo que ahora esa zona, la usara para nombres
         ;de ficheros.
cp (hl)
jr nz,laaba ;si no coincide, entonces el texto en hl no es el mismo que en de y salta.
            ;RECUERDA, AUN BUSCANDO EL MISMO TEXTO "BOOT" SALTARA DESPUES DE LA T YA QUE LEE 8 CARACTERES
            ;Y NO COINCIDE POR LO DICHO ANTERIORMENTE.
.laab4
inc hl
inc de
djnz compara_textos ;buclea 8 veces.

;por aqui texto en reg hl es igual al de reg de
.laab8
scf ;da como correcta la busqueda
ret ;retorna a 

.laaba ;por aqui si no coincide el texto de reg hl con el de reg de, presupongo que sera para carga de otros datos?
       ;OJO, TAMBIEN SALTA BUSCANDO LA PRIMERA VEZ EL TEXTO "BOOT" YA QUE NO COINCIDE AL FINAL
cp #41 ;&41 es letra "A" en ASCII
       ;a=&20, espacio en zona de textos, despues de BOOT$
jr c,laac3 ;Carry si reg a es MENOR que &41, es decir NO ES UNA VOCAL O CONSONANTE lo que trae reg a

;por aqui le suman &20 a codigo ascii para buscar en MINUSCULA el caracter
or #20
cp (hl) ;compara ahora en minuscula
jr z,laab4

.laac3 ;por aqui reg a no es vocal o consonante
cp #20 ;lo compara con ESPACIO
jr nz,laacb ;no es un espacio? salta Y DA COMO ERRONEA LA BUSQUEDA DEL TEXTO
;por aqui es espacio (leido de zona de texto con nombres de fase)
ld a,(hl) ;hl apunta a zona en &AA1A, de primeras tiene un &00 (al final de "BOOT")
or a ;comprueba si lo leido en reg a es &00
jr z,laab8 ;es cero? salta entonces y DA COMO CORRECTA LA BUSQUEDA.

.laacb ;DA COMO ERRONEA LA BUSQUEDA DE TEXTO
and a 
ret

.LAACD ;salta aqui despues de cargar 512bytes de disco en rutina &AA72
;SE HA CARGADO UNA TABLA DE CONVERSION, PARA HACER CALCULOS, CALCULAR TAMANO DATOS A LEER EN DISCO E INICIO TRACK/SECTOR
;la clave de esos calculos es el registro BC obtenido en la comparacion de textos.
;Reg C TRAE ALGO ASI COMO EL NUMERO DE ARCHIVO QUE TOCA LEER DE DISCO, CON LO CUAL SE DESPLAZA EN ESTOS DATOS PARA SABER EL
;TAMANO A LEER, posteriormente hara lo mismo para calcular track y sector iniciales
;POR EJEMPLO, SI PRIMERAS BC=&0000, OBTENIDO DE COMPARAR TEXTO "BOOT", REG DE DEVUELVE &036C, QUE ES TAMANO DE LOADER EN &0100
;SI REG BC=&0001, OBTENIDO DE COMPARAR TEXTO "TITLE", EL TAMANO DEVUELTO ES &4010, QUE SERIA LA PANTALLA DE CARGA Y COLORES.
;ESTE LOADER SOLO COMPARA EL TEXTO BOOT, PARA CARGAR EL LOADER NUEVO EN &0100
;PERO EL LOADER EN &0100 Y EL LOADER EN &0040, COMPARARAN VARIOS TEXTOS, para hacer lo mismo que en esta rutina.



call &AB25 ;hace calculos con los datos recien cargados
           ;DEVUELVE EN REGISTRO DE EL NUMERO DE DATOS A LEER DESDE DISCO.

exx ;OJO, METE EN ESPEJO LOS SIGUIENTES VALORES
    ;HL=&0100 ;IGUAL QUE ANTES DE LLAMAR A &AB25
    ;DE=&036C ;VALOR PROVINIENTE DE CALCULOS en &AB25
              ;SON LOS BYTES A LEER DESDE DISCO &200 DE PRIMERAS &016C DE SEGUNDAS!!!
    ;BC=&0000 ;RECUERDA BC LO DEVUELVE CARGADO LA RUTINA COMPARA_TEXTOS y es crucial para los calculos.

ld de,#0201 ;de es INICIO DE CALCULOS DE TRACK / SECTOR QUE SERA PARAMETRO PARA LA LECTURA DE DATOS DE DISCO 
            ;reg d TRACK, reg e SECTOR a leer (le suma &C0 para convertirlo a ID correcta)
            ;EN LOADER0 NO SE VARIA ESTE DATO, PERO EN LOADER1 Y LOADER2, LA RUTINA DE CALCULO DE TRACK Y SECTOR
            ;ACTUALIZARA REG DE CON LOS DATOS CORRECTOS PARA EFECTUAR LA LECTURA DE FICHERO A LEER DESDE DISCO.
       

ld bc,#0190
ld hl,(&AC48) ;recupera puntero a datos recien cargados

;ahora calculara track/sector inicial donde empezar a leer esos datos.

.laada ;por aqui tambien vuelve despues de leer 512bytes de datos desde disco
       ;incrementar sector o track/sector para siguiente lectura de disco
       ;tambien viene reg bc cargado con &0190 aqui arriba, decrementado (datos que faltan por cargar)
       ;hl viene incrementado tambien a siguiente dato en tabla de calculos.

;ahora va a usar ese valor en BC, que devolvio rutina busca_texto_tabla
;la tabla de datos cargada tiene valores al principio de &01, &01, &01...&02,&02..&42, &03,&03...
;&04,&04..&05,&05..&45..&06,&06... etc,etc,etc
;CUANDO VALOR CALCULADO EN RUTINA busca_texto_tabla, REC C, COINCIDE CON ESOS &01,&02,&03,&04
;la rutina entonces se ha posiciando en zona donde sabe que debe calcular sector a leer e incrementara acorde
;este valor &0201 cargado en reg de anteriormente.

ld a,(hl) ;vuelve a leer primer byte de datos recien cargados (tambien lo hace en rutina &AB25
          ;a=&00
bit 7,a ;el bit 7 de reg a solo sera apartir de valor &80 leido de esa tabla
        ;en terminator 2 NO existe valor igual a &80 o mayor, nunca saltara
        ;se llegara a &AAE6 un poco mas abajo si no se cumple el Z de comparacion reg C devuelto por rutina busca_texto_tabla
jr nz,laae6 ;repito, NUNCA saltara en terminator 2

;hace exactamente lo mismo que en rutina &AB25
and #3f ;%00111111, se queda con b0-b5 de reg a
        ;a=00 de primeras
exx
cp c ;AQUI COMPARA EL VALOR DEVUELTO POR busca_texto_tabla en reg c, lo compara con leido en tabla de datos reg a
     ;SI COINCIDE, ENTONCES SABE QUE ESTA EN LA ZONA ADECUADA PARA FICHERO A CARGAR ACTUALMENTE.
exx
jr z,laaf7 ;SALTA SI SE ENCUENTRA EN ZONA DE DATOS CORRESPONDIENTE A FICHERO A CARGAR ACTUALMENTE.
;por aqui reg a diferente a reg c
;tambien viene por aqui una vez leidos 512bytes desde disco (mas abajo)
;si reg de no ha llegado a cero (numero de lecturas?) salta aqui
;antes de saltar aqui hizo un exx, trae los secundarios activos
;hl=&AC4A (puntero a datos misteriosos cargados)
;de=&0201 TRACK y SECTOR leidos desde disco
;bc=&0190, cargado un poco mas arriba en esta rutina
.laae6
inc hl ;incrementa puntero a datos, hl=&AC4B
dec bc ;bc=&018F
inc e ;siguiente sector a leer
ld a,e ;INCrementa sector que acabara leyendo
cp #0b ;nos hemos pasado de sector ID? (van desde &01 a &0A, &81-&8A)
jr nz,laaf1 ;no nos hemos pasado con el sector ID
;por aqui nos hemos pasado, incrementa track, resetea sector ID.
inc d ;incrementa track
ld e,#01 ;resetea sector ID al primero
.laaf1 ;por aqui no nos hemos pasado de sector ID
;sector a leer ya incrementado
ld a,b
or c ;ha llegado reg bc a cero?
jr nz,laada ;reg bc no ha llegado a cero, salta. En terminator 2 NUNCA SE LLEGA A CERO AQUI
;REPITO, POR AQUI NUNCA LLEGA EN TERMINATOR 2.
;por aqui reg bc a cero
exx
ret

.laaf7 ;por aqui viene para cada lectura de disco requerida, 
       ;SALTA A ESTA RUTINA CUANDO ENCUENTRA EN FICHERO DE DATOS LA ZONA QUE COINCIDE CON VALOR DEVUELTO POR RUTINA
       ;busca_texto_tabla EN REG C
       ;REG DE SE HA CALCULADO CON RESPECTO A ESA TABLA EN RUTINA DE AQUI ARRIBA
       ;TRAE TRACK Y SECTOR DONDE EMPEZAR LECTURA DE DATOS EN DISCO DE FICHERO QUE SE LEERA DESDSE DISCO.

exx ;hl=&0100, bc=&0000, de=&036C, OJO CON EL VALOR DE REG DE, SE CALCULO EN RUTINA &AB25
    ;de segundas que viene por aqui
    ;hl=&0300 (siguiente posicion de memoria a escribir)
    ;bc=&0000
    ;de=&016C, DECREMENTADO EN &200 (datos pendientes de leer desde disco)
    
push bc ;preserva &0000, valor crucial para realizar los calculos
ex de,hl ;de=&0100, hl=&036C
ld bc,#0200 ;TAMANO DATOS 512BYTES
and a ;quita carry para usar instruccion sbc aqui abajo
sbc hl,bc ;&036C-&0200, hl=&016C al ser mayor hl que bc, no activa carry en la resta
          ;DE SEGUNDAS &016C-&0200, desborda hl=&FF6C, CARRY activado
          ;RECUERDA &036C SON LOS BYTES EXACTOS A LEER DESDE DISCO, CALCULADO EN RUTINA &AB25
jr nc,lab09 ;de primeras NC, de segundas desborda no salta.
;por aqui hemos desbordado la resta al ser bc mas grande que hl
add hl,bc ;deshace la resta que se desbordo, hl=&016C
ld (#ABE6),hl ;varia el valor que toma reg de en rutina que llamara a READ DATA
              ;SON LOS BYTES QUE QUEDAN POR LEER DE DISCO &016C
ld hl,#0000 ;resetea hl

.lab09 ;por aqui si hl es mayor que bc en el SBC de aqui arriba
exx
push de ;guarda en pila track/sector
        ;de es track sector a leer, se ira incrementando aqui segun va leyendo de disco
        ;EN LOADER1 Y LOADER2 ESTE VALOR SE HA ACTUALIZADO SEGUN CALCULOS DE TRACK Y SECTOR ANTERIORES
        ;PARA LEER  ZONA DE DISCO CORRESPONDIENTE A "FICHERO" A LEER DESDE DISCO.

;SIGUE DOCUMENTANDO AQUI JOSE, ACLARADO EL CALCULO DE TRACK SECTOR
exx
ex (sp),hl ;recupera ese valor de de guardado en pila en hl, y mete valor de hl en pila
           ;hl=&0201 ;TRACK y SECTOR A LEER DESDE DISCO
           ;(stack)=&016C (datos pendientes de leer desde disco)
ex de,hl ;de=&0201, hl=&0100
push hl ;&0100 a pila

call &AB75 ;ACCEDE DENTRO DE LA RUTINA .LAB6A .LEE_DATOS_DISCO
            ;RECUERDA ESTA RUTINA HACE TODO EL TRABAJO, READ ID, SEEK, Y READ DATA
            ;SOLO LEE UN SECTOR POR CADA LLAMADA
            ;parametros enviados de primeras
            ;hl=&0100, DONDE METERA LOS DATOS EN RAM A LEER DESDE DISCO
            ;de=&0201 ;reg d TRACK, reg e SECTOR a leer (le suma &80 para convertirlo a ID correcta)
;LEE 512BYTES EN TRACK 02 SECTOR &81 (de primeras)
;DESTINO &0100-&02FF CORROBORADO
;en ultima lectura solo leera los datos restantes por el sbc que hace mas arriba

;TRAE CARRY ACTIVADO SI SE LEYO BIEN DATOS REQUERIDOS DE DISCO

pop hl ;RECUPERA PUNTERO A MEMORIA RAM DONDE METER DATOS
       ;DE SEGUNDAS (DONDE HIZO LECTURA PARCIAL DE &016C BYTES DE DATOS) HL=&0300 (ESCRIBIO &0300-&046B)
pop de ;RECUPERA EL VALOR RESULTANTE DE RESTARLE &200 AL RESULTADO RECIBIDO POR RUTINA &AB25 
       ;de=&016C (SON LOS BYTES QUE QUEDAN POR LEER DE DISCO)
       ;DE SEGUNDA REG DE=&0000

jr nc,lab23 ;NC ES ERROR DE LECTURA DE DATOS DESDE DISCO.

ld bc,#0200 ;512BYTES
add hl,bc ;AVANZA PUNTERO DE MEMORIA RAM 512BYTES PARA LEER MAS DATOS DESDE DISCO
          ;DE SEGUNDAS HL=&0500, AUNQUE SOLO ESCRIBIO EN &0300-&046B
pop bc ;resetea bc, bc=&0000

ld a,d
or e ;ha llegado reg de a cero?
     ;RECUERDA reg de aqui son los bytes a leer de disco
     ;en segunda lectura por aqui llega a cero, hizo 2 lecturas, una de &200, otra de &016C
     ;de es restado con &0200 la primera vez, tomando de segundas valor &016C, y reseteandose a cero.
exx
jr nz,laae6 ;si reg de no ha llegado a cero, si ha llegado a cero, se han leido los bytes especificados
            ;para leer desde disco.

;POR AQUI SE HAN LEIDO LOS DATOS REQUERIDOS DE DISCO, LA PRIMERA VEZ &200 + &016C DATOS LEIDOS
;DESDE &0100-&046B
exx ;recupera puntero de escritura de datos en ram, hl=&0500 la primera vez que pasa por aqui
scf ;activa Carry, para senalizar que lectura de datos desde disco bien.
ret ;vuelve por &AA75

.lab23 ;ERROR DE LECTURA DE DATOS DE DISCO POR AQUI.
pop bc
ret ;vuelve sin Carry activado, la rutina de vuelta entendera que hubo un error de lectura de datos y lo volvera a reint.



.LAB25 ;despues de leer fichero de texto, buscar nombre de archivo en ese texto, cargara un fichero de datos
       ;ese fichero de datos se procesa aqui para calcular tamano de datos a cargar
;parametros
;reg bc=&0000 ;RECUERDA BC LO DEVUELVE CARGADO LA RUTINA COMPARA_TEXTOS
;hl= &0100
ld de,#0000
exx ;usa registros espejo como primarios, de=&0000 se conserva en la zona de registros espejo, 
    ;reg bc, con resultado de rutina compara_textos tb se guarda ahi
ld bc,#0190
ld hl,(&AC48) ;mete en hl puntero a datos recien leidos, hl=&AC4A

.lab2f
ld a,(hl) ;lee primer dato de zona recien leida.
          ;a=&00 de primeras
bit 7,a ;bit 7=0 de primeras
jr nz,lab45 ;salta si bit7=1, se limitara a incrementar puntero de zona recien cargada, y si bc (&190), llego a cero.
;por aqui bit 7=0
and #3f ;%00111111, se queda con b0-b5 de reg a
        ;a=00 de primeras
exx ;recupera registros primarios, es decir recupera de=&0000, bc=&0000, hl=&0100
cp c ;cp &0 con &0 de primeras, RECUERDA BC LO DEVUELVE CARGADO LA RUTINA COMPARA_TEXTOS
jr nz,lab44 ;de primeras no se cumple
;aqui reg a (que se quedo con los bits 0 a 5) es igual a reg c
inc d ;de=&01
exx ;vuelve a usar registros secundarios, es decir recupera puntero a zona recien cargada en HL
bit 6,(hl) ;hl=&AC4A
exx ;recupera registros primarios
jr z,lab44 ;si bit 6=0 de (hl) salta, como (hl)=&00 SALTA de primeras

;por aqui hl =&0100, de=&0200, bc=&0000 de primeras
inc e ;de=&0201
jr lab4c

.lab44 ;por aqui puede llegar en 2 casos aqui arriba
exx ;recupera registros secundarios, es decir recupera puntero a zona recien cargada en HL
.lab45
inc hl ;siguiente zona de memoria recien cargada, hl=&AC4B
dec bc ;bc se cargo con &0190 al principio de rutina, OJO BC NUNCA LLEGARA A &0000, SE SALDRA ANTES DE ESTA RUTINA.
ld a,b ;comprueba si ha llegado a &0000
or c
jr nz,lab2f ;OJO NO PARECE LLEGAR A CERO, SE SALE ANTES DE LA RUTINA!! POR LO MENOS LA PRIMERA VEZ QUE ENTRA AQUI
            ;OJO A PUNTERO DE HL SE LE HACE UN ADD BC (CALCULADO VALOR), CON LO CUAL NO ES LINEAL EL INCREMENTO DEL PUNTERO
            ;POR EJEMPLO AQUI ABAJO DE PRIMERAS HACE UN &AC4A+&1C0=&AE0A, QUE ES ZONA DE DATOS DESPUES DE &E5 NO DATOS!!

exx ;por aqui NO llega nunca.

.lab4c
sla d ;rota bits a la izquierda, bit 7 entra por carry, entra valor 0 por bit 0
      ;d=&02 sla -> d=&04, seria como multiplicar x2 registro d
ld a,d ;a=&04
add e ;e=&01, a=&04, &04+&01, reg a =&5
ld d,a ;d=&5
ld a,c ;a=&00

exx
ld hl,(#AC48) ;vuelve a recuperar puntero a zona recien cargada. hl=&AC4A
ld b,#01
add #c0 ;a=&00, + &C0, a=&C0
ld c,a ;c=&C0
add hl,bc ;&AC4A + &01C0; hl=&AE0A, ZONA ENMEDIO DE &E5's AL FINAL DE FICHERO CARGADO.
ld a,(hl) ;A=&6C
exx ;de=&0501
ld e,a ;de=&056C
bit 0,d ;de=&05 --> %0101
jr nz,lab65 ;bit es 1, con lo cual Z no se activa, salta
or a
ret z

.lab65 
ld a,d ;a=&05
sub #02 ;a=&03
ld d,a ;d=&03; de=&036C
ret ;RETORNA TAMANO DATOS A LEER DESDE DISCO.


.LAB6A
.LEE_DATOS_DISCO
;ESTA RUTINA HACE TODO EL TRABAJO, READ ID, SEEK, Y READ DATA
;SOLO LEE UN SECTOR POR CADA LLAMADA
;parametros
;hl=&AC4A, DONDE METERA LOS DATOS EN RAM A LEER DESDE DISCO
;de=&0008 ;reg d TRACK, reg e SECTOR a leer (le suma &C0 para convertirlo a ID correcta)

xor a
LD (&ABE6),A
LD (&ABE7),A
ld c,#c0  ;sector ID inicial, lo usa para calcular el sector a leer usando el reg e mandado como parametro
jr lab77
.LAB75 ;PUNTO DE ENTRADA DESDE RUTINA lab09
ld c,#80 ;se usa en rutina posterior a cargar unos datos raros en &AC4A, usar esos datos para calcular ALGO
         ;sector ID inicial, lo usa para calcular el sector a leer usando el reg e mandado como parametro
         ;APARTIR DE TRACK 2 EL ID YA NO ES &C0-&CA, SI NO &81-&8A
         

.lab77
ld a,d ;a=&00
;AQUI ABAJO PARECE ESCRIBIR EN ZONA DE MEMORIA DONDE ESTAN LAS INSTRUCCIONES A MANDAR AL FDC.
LD (&AC38),A ;TRACK DONDE POSICIONAR CABEZA CON COMANDO SEEK
LD (&AC41),A ;TRACK A LEER CON COMANDO READ DATA
LD (&AB9F),HL ;instruccion original ld (#0185),hl ;modifica la toma de valor de reg hl aqui abajo
ld a,e ;e=&08
or c  ;c=&C0 ;a=&C8 sector inicial y final de track especificado, (lee en bloques de 512bytes)
LD (&AC43),A ;SECTOR number empezar a leer para comando READ DATA
LD (&AC45),A ;END OF TRACK sector final donde acabara la lectura READ DATA
.lab89
.bucle_reintento_comando
LD DE,&AC3B ;direccion de memoria donde esta numero de comandos, comando y parametros al FDC
            ;En este caso se mandara comando READ ID al FDC
CALL SEND_CMD_RECIBE_DATOS ;&ABB9 ;;;instruccion original call #019f

;vuelve una vez mandado comando, execution phase acabada y guardado resultados del resul phase, ST1 comprobado tb.
;Carry flag set, todo correcto. STATUS REGISTER 1 comprobado.
;el caso es que parece no usar esto para controlar algun error recibido en STATUS REGISTER 1

LD A,(&AA1D) ;LEE STATUS REGISTER 0
             ;A=&00
or a ;solo dara &00 si a viene con &00. Esto significara que todo correcto con ejecucion del comando mandado.
jr nz,bucle_reintento_comando ;si NZ, reintenta el comando mandado al FDC ;lab89

;por aqui todo correcto en mandar comando y recibir datos / resultados del FDC.
LD DE,&AC35 ;zona de datos con comando y parametros nuevos a mandar al FDC, comando SEEK
CALL &ABA3
;POR AQUI MANDO COMANDO SEEK A TRACK 0 Y EJECUTO UN SENSE INTERRUPT STATUS PARA COMPLETAR EL POSICIONAMIENTO AL TRACK 0

LD DE,&AC3E ;DATOS PARA COMANDO READ DATA
.LAB9E
LD HL,&AC4A ;ld hl,#0000 ;EL VALOR QUE TOMA HL SE MODIFICA AQUI ARRIBA, 
            ;hl=&AC4A, donde escribira los datos requeridos con READ DATA

JR &ABC1 ;VOLVERA POR &AA5C despues de este salto


.LABA3 ;LLAMA AQUI DESPUES DE COMANDO READ ID Y RECEPCION DE RESULTADOS
CALL &ABB4 ;MANDA COMANDO SEEK A FDC y espera a que el MAIN STATUS REGISTER este preparado para enviar recibir datos
           ;en el caso de SEEK, para saber si ha acabado el posicionamiento al track especificado
           ;se debe mandar el comando SENSE INTERRUPT STATUS, lo hace aqui abajo.

.laba6
LD DE,&AC39 ;direccion para comando SENSE INTERRUPT STATUS
CALL SEND_CMD_RECIBE_DATOS ;al mandar este comando se produce el desplazamiento al track especificado.

LD HL,&AA1D ;zona donde se guardo resultado de sense interrupt status (relativo al comando seek mandado anteriormente)
bit 5,(hl) ;consulta ST0 bit 5, SEEK END, cuando se pone a 1 se acabo el posicionamiento al track especificado.
jr z,laba6 ;mientras devuelva bit 5=0, sigue bucleando esperando a que acabe posicionamiento de cabezal.

;por aqui se posiciono en track 0 del disco, como se le indico en comando SEEK
ret ;retorna a rutina principal que llamo a esta, &AB9B

.LABB4 ;Viene desde LABA3 que a su vez fue llamado despues de ejecutar y recepcionar comando READ ID.
LD BC,&AC30 ;valor para modicar salto de la rutina despues de mandar el nuevo comando al FDC ;ld bc,#0216
jr labc4
;NO volvera por aqui, volvera por &ABA6 que es desde donde se llamo a LABB4


.LABB9 ;LLAMADO CON CALL DESDE RUTINA LAB6A, DESPUES DE CAMBIAR LO QUE PARECEN PARAMETROS DE FDC EN ZONAS DE MEMORIA
.SEND_CMD_RECIBE_DATOS
;PARAMETRO REG DE DIRECCION DE MEMORIA DONDE SE ENCUENTRA EL COMANDO Y PARAMETROS A MANDAR AL FDC

LD BC,&AC11 ;sera el salto desde esta rutina segun el comando mandado al fdc para pasar a
            ;execution phase y result phase del FDC ;instruccion original ld bc,#01f7, 
LD HL,&AA1D ;Direccion donde guardara los datos recibidos en result phase del FDC ;instruccion original ld hl,#0003,
jr labc4

.labc1 ;hace un jp para ejecutar un comando READ DATA desde funcion &ab9e
;parametro HL=&AC4A, donde guardara los datos requeridos al FDC en RAM
LD BC,&ABF6 ;para variar salto en salida de rutina

.labc4
LD (&ABE9),BC ;VARIA UN JP DE AQUI ABAJO, SEGUN COMANDO A MANDAR AL FDC
              ;bc=&AC11 para comando READ ID
              ;bc=&AC30 para comando SEEK
              ;bc=&ABF6 para comando READ DATA

ld a,(de) ;de=&AC3B a=&02, NUMERO DE COMANDOS A MANDAR AL FDC, EN ESTE CASO SERA COMANDO READ ID
          ;de=&AC35 PARA COMANDO SEEK
          ;de=&AC3E PARA COMANDO READ DATA
ld b,a ;lo guarda para el djnz del bucle de comando y CONFIG a mandar, el valor varia segun comando a mandar.

.labca
.BUCLE_CMDYCONFIG ;comentarios para comando READ ID, pero los demas comandos sera similar.
;POR AQUI MANDA COMANDO Y CONFIGURACION(ES) DEL COMANDO AL FDC
push bc ;guarda en pila el valor del bucle de numero de comandos.
inc de ;Incrementa puntero de zona de datos comandos fdc, de=&AC3C
ld bc,#fb7e ;Main status register FDC.

.labcf
.bucle__handshaking
in a,(c)
add a
jr nc,bucle__handshaking ;labcf
jp m,bucle__handshaking ;#01b5

inc c ;c=&7F, se posiciona en Data Register Port del FDC para mandar el comando
ld a,(de) ;a=&4A --> comando READ ID, bit 6 MF=1 (MFM selected) IBM System 34 Double Density format
          ;A=&00 --> CONFIGURACION PARA COMANDO READ ID, CABEZA 0, DRIVE 0.
out (c),a ;MANDA COMANDO AL FDC
ld b,#08
.bucle_espera ;labdd
djnz bucle_espera ;labdd

pop bc ;recupera numero de comandos a mandar
djnz BUCLE_CMDYCONFIG ;labca

;POR AQUI HA MANDADO COMANDO Y CONFIG DEL COMANDO AL FDC

ld bc,#fb7e ;Main status register FDC.
.LABE5
ld de,#0000  ;a la entrada de esta rutina se resetearon a &00 &00 los valores que toma reg DE
             ;siempre tendra valor &0000, hasta que en rutina llamada por read data en &ab03 lo cambia por datos
             ;restantes a leer en ULTIMA lectura a disco.
             ;El caso es que no parece usar este valor cuando toma bytes restantes ya que se destruye reg de con otros datos.
             ;nos da un poco igual de todas maneras.


.LABE8
;jp #01dc ;EL VALOR DEL SALTO SE VARIA DESDE RUTINA LABC4 LLAMADA A SU VEZ POR LA LAB6A
JP &AC11 ;con comando READ ID
;JP &AC30 para comando SEEK
;JP &ABF6 para comando READ DATA

.labeb
.escribe_datos_ram
inc c ;se posiciona en FDC DATA REGISTER, que es por donde recibe los datos que va leyendo de disco
in a,(c) ;lee dato
ld (hl),a ;lo guarda en memoria ram &AC4A-&AE49 CORROBORADO
dec c
inc hl
dec de
ld a,d
or e
jr z,lac05 ;cuando acaba de leer todos los datos salta a &AC05

.LABF6 ;salta aqui despues de mandar comando y parametros al fdc de READ DATA
;bc=&FB7E FDC MAIN STATUS REGISTER
in a,(c)
jp p,&ABF6 ;comprueba si el fdc esta listo o no para recibir/enviar datos, si no buclea
;por aqui FDC listo.
;a=&F0 %11110000
and #20 ;%00100000 ;se interesa por bit 5 que indica si el FDC aun esta en execution mode del comando
                   ;en READ DATA en execution mode, esta leyendo los datos requeridos desde el disco.
jr nz,escribe_datos_ram ;mientras NZ se estan recibiendo datos a cargar desde el FDC!!

;por aqui acabo de leer los datos requeridos.
;LEYO 512 BYTES EN TRACK 0 SECTOR C8
;LO GUARDO EN &AC4A-&AE49 CORROBORADO, AUNQUE LOS DATOS REALES LEIDOS SON
;&AC4A-&ACC9, LO DEMAS ESTA RELLENADO CON BYTE NO DATA &E5
;LA LECTURA NUEVA DEL CODIGO CARGADO ES TEXTO
;BOOT, TITLE, LOWCODE, MAINCODEFRONTSC, COMBAT, SCENE1, CHASE, HAND, HANDSC, SCENE2, EYE, EYESC, HELI, SCENE3, ENDSC 
jr lee_resultphase_READDATA ;lac0e
;volvera por &AA5C, la funcion main que ejecuto seek, sense interrupt y read data.

.lac01
inc c
in a,(c)
dec c
.lac05
in a,(c)
jp p,#AC05
and #20
jr nz,lac01

.lac0e ;SALTA AQUI DESPUES DE LEER DATOS DE TEXTO DESDE DISCO EN &AC4A-&ACC9
.lee_resultphase_READDATA
ld hl,&AA1D ;donde guardara los bytes de resultado de READ DATA. 7 bytes.

.lac11 ;SALTO DESDE COMANDO READ ID
;mira si se acabo de completar la ejecucion del comando por parte del FDC
in a,(c)
cp #c0
jr c,lac11 ;no completado? pues espero haciendo bucle

inc c ;FDC DATA REGISTER
in a,(c) ;GUARDA DATOS DEVUELTOS POR EL COMANDO MANDADO
ld (hl),a ;hl=&AA1D, guarda en esa direccion los resultado al comando mandado al FDC (READ ID)
          ;El comando READ ID devuelve 7 resultados, 7 bytes
          ;ST0=&00 ;STATUS REGISTER 0
          ;ST1=&00 ;STATUS REGISTER 1
          ;ST2=&00 ;STATUS REGISTER 2
          ;C=&01   ;TRACK ACTUAL SELECCIONADO ;entiendo que es track 1 porque es donde quedo el cabezal al cargar este loader
          ;H=&00   ;CABEZAL 0
          ;R=&C5   ;NUMERO DE SECTOR QUE SERA LEIDO O ESCRITO ;entiendo que es &C5 porque es lo ultimo que leyo al car. loader
          ;N=&02   ;NUMERO DE BYTES POR SECTOR, &02= 512bytes por sector
dec c ;FDC MAIN STATUS REGISTER
inc hl ;incrementa puntero datos

ld a,#05
.lac1f ;pequeno bucle de espera
dec a
jr nz,lac1f

in a,(c)
and #10 ;todos los datos recibidos?
jr nz,lac11 ;no? pues sigo recibiendo datos

;Por aqui todos los bytes de RESULT PHASE recibidos
LD A,(&AA1E) ;LEE STATUS REGISTER 1, recibido despues de ejecutar READ ID ;ld a,(#0004)
             ;a=%00000000
and #24 ;%00100100 ;mira si se ha activado bit 5 (CRC ERROR) o bit 2 (el fdc no consiguio leer el campo ID del sector)
ret nz ;NZ es que ha habido algun error al ejecutar comando READ ID
scf ;activa carry para senalizar que el comando se ejecuto bien.
ret ;vuelve a la rutina principal que llamo a ejecutar el comando.
    ;en el caso de READ ID vuelve a &AB8F
    ;en el caso de READ DATA vuelve a &AA5C

.lac30 ;salta aqui desde rutina donde mandara comando SEEK
.wait_MSR_ready
;bc esta situado en MAIN STATUS REGISTER del FDC.
in a,(c)
ret m ;S flag is set, bit 7 activado. CUANDO ESTE PREPARADO EL FDC PARA RECIBIR O MANDAR DATOS RETORNA.
      ;EN ESTE CASO DE COMANDO SEEK, necesita mandar el comando SENSE INTERRUPT STATUS para saber si acabo
      ;el posicionamiento al track especificado, por eso espera aqui a que este preparado para recibir otro comando el FDC.
jr wait_MSR_ready ;espera a que el FDC este preparado para mandar o recibir datos.

;---DATOS PARA COMANDO SEEK----
.LAC35
db &03 ;NUMERO DE COMANDO Y PARAMETROS A MANDAR AL FDC, comando SEEK 1, comando 2 parametros
db &0F ;comando SEEK (para mover la cabeza al track especificado)
db &00 ;parametro 1 comando SEEK (seleccion de cabezal y disquetera)
.LAC38 ;variable modificada en rutina LAB6A
db &00 ;parametro 2 comando SEEK (TRACK AL QUE QUEREMOS IR), USADO POR RUTINA MAIN &ABA3 y subrutinas

;---DATOS PARA COMANDO SENSE INTERRUPT STATUS---
.LAC39
db &01 ;NUMERO DE COMANDO Y PARAMETROS A MANDAR AL FDC, 
db &08 ;Comando SENSE INTERRUPT STATUS (NO TIENE PARAMETROS), SENSE INTERRUPT STATUS SE USA PARA SABER SI EL CMD SEEK ACABO 

;----DATOS PARA COMANDO READ ID---------------------
.LAC3B ;NUMERO DE COMANDOS A MANDAR AL FDC, 2 PARA READ ID. VARIABLE LEIDA DESDE RUTINA LABC4 LLAMADA A SU VEZ POR LA LAB6A 
db &02 ;ld bc,#0208
.LAC3C ;COMANDO A MANDAR AL FDC, &4A --> comando READ ID, bit 6 MF=1 (MFM selected) IBM System 34 Double Density format 
db &4A ;comando READ ID
db &00 ;parametro de read ID

;----DATOS PARA COMANDO READ DATA----------------
.LAC3E ;NUMERO DE COMANDOS A MANDAR AL FDC, 9 PARA READ DATA.
db &09 ;NUMERO DE COMANDO Y PARAMETROS A MANDAR AL FDC
db &46 ;comando READ DATA, SK=0, MF=1, MT=0, SK-> no SKIP DELETED DATA ADDRES MARK, MF-> MFM mode selec. MT-> solo 1 cara.
db &00 ;parametro 1 disquetera 0 cabezal 0
.LAC41 ;variable modificada en rutina LAB6A, para cambiar track a leer con comando READ DATA
db &00 ;parametro 2 track a leer
db &00 ;parametro 3 head 0 de disquetera
.LAC43 ;variable modificada en rutina LAB6A, para cambiar el sector a leer con comando READ DATA
db &00 ;parametro 4 SECTOR number a leer, SE MODIFICO CON &C8 PARA EFECTUAR LECTURA 
db &02 ;parametro 5 tamano de sector en bytes, &02 -> 512bytes por sector
.LAC45 ;variable modificada en rutina LAB6A, para cambiar cuantos sectores se leeran con el comando READ DATA
db &00 ;parametro 6 END OF TRACK, sector final a leer en comando READ DATA SE MODIFICO CON &C8 PARA EFECTUAR LECTURA
.LAC46
db &2A ;parametro 7 GPL, GAP LENGTH, esta longitud de GAP se decidio al formatear el disco!
.LAC47
db &FF ;parametro 8 solo se usa si parametro 5=&00, no es el caso aqui.

;---OTRAS VARIABLES USADAS POR LOADER----
;VARIABLES &AC48 y &AC49 una vez desenmascaradas reflejan la direccion &AC4A
;se usara este valor para 2 cosas, primero para saltar a una rutina que se colocara en esa zona de memoria
;despues de leer el fichero de texto con los nombres de fase, se usara como BUFFER para ficheros de apoyo a cargar
.LAC48 ;DE PRIMERAS LA RUTINA DE DESENMASCARAMIENTO EN la6b3 LO CAMBIA POR &30
db &30 ;LEIDO EN RUTINA &AA35, ESTE VALOR &30 LO CAMBIA RUTINA DE DESENMASCARAMIENTO POR &4A
.LAC49 ;DE PRIMERAS LA RUTINA DE DESENMASCARAMIENTO EN la6b3 LO CAMBIA POR &02
db &02 ;LEIDO EN RUTINA &AA35, ESTE VALOR &02 LO CAMBIA RUTINA DE DESENMASCARAMIENTO POR &AC

;--------------------
.LAC4A ;SALTA A ESTA DIRECCION (CALCULADA) AL PRINCIPIO DEL CODIGO NUEVO CARGADO EN ESTAS DIRECCIONES
       ;RELOCALIZA TODAS LAS DIRECCIONES DE ESTE NUEVO LOADER CARGADO, PARA ACOMODARLO AL RANGO DE &AA00
       ;AL EFECTUAR EL SALTO A &AA1A A LA SALIDA DE ESTA RUTINA, ESTA DIRECCION SE USARA COMO BUFFER POSTERIORMENTE
       ;EL BUFFER SE USA PARA CARGAR 2 "ARCHIVOS" DE TEXTO/DATOS
       ;EL PRIMERO SON DATOS DE TEXTO CON LOS NOMBRES DE FASE DEL JUEGO 
         ;BOOT, TITLE, LOWCODE, MAINCODEFRONTSC, COMBAT, SCENE1, CHASE, HAND, HANDSC, SCENE2, EYE, EYESC, HELI, SCENE3, ENDSC 
         ;ESTE TEXTO SE GUARDA EN &AC4A-&ACC9, LO DEMAS SE SOBREESCRIBE CON &E5 (NO DATA BYTE DEL DISCO)
       ;EL SEGUNDO SON DATOS PARA CALCULAR TAMANO DE DATOS A CARGAR Y TRACK/SECTOR INICIAL DONDE ESTAN ESOS DATOS.
       ;ESTOS "FICHEROS" DE DATOS ESTAN EN TRACK 0 SECTOR DISTINTO, 512 BYTES. 
       ;LA FORMA DE ACTUAR ES LA SIGUIENTE, CARGA FICHERO DE TEXTO, POSICIONA UN PUNTERO BUSCANDO EL TEXTO QUE LE INDICA
       ;en la direccion laa15, despues carga fichero de datos de tamano, track/sector inicial y usa ese puntero posicionado
       ;para calcular el tamano de datos de ese "fichero" a cargar y track/sector inicial donde empezar a leer.
       

;NOTA lo descrito anteriormente es igual o similar a codigo en &3000 de loader1, o codigo en &0040 de loader2
;esto seria el loader real de carga de datos, lo usara para cargar ficheros de apoyo, ficheros del juego y fases del juego.
;loader0 carga ficheros de apoyo y a loader1
;loader1 carga ficheros de apoyo y datos principales del juego
;loader2 carga ficheros de apoyo y carga fases del juego.
;la caracteristica de este loader es que es RELOCALIZABLE, por eso lo pueden usar en &AC4A, &3000 o &0040

;parametros
;hl viene cargado con la direccion de salto calculada &AC4A
;de viene cargado con valor resultado de un sbc, de=&AA1A, lo metera en reg ix para ejecutar salto en el jp (ix) del final.
    ;tambien usara este valor para cambiar 3 instrucciones al inicio de la rutina &AA1A

;ESTA RUTINA RELOCALIZA EL LOADER ACTUALIZANDO DIRECCIONES DE CARGA EN EL CODIGO Y
;AL FINAL SALTARA A &AA1A QUE FUE MODIFICADA AL INICIO CON
;JP &AA35, QUE ES JUSTO DESPUES A RUTINA QUE EFECTUO ESTE SALTO CON JP &AC4A

ld bc,#0041 ;valor de relocalizacion para direcciones del loader
add hl,bc ;&AC4A+&0041= &AC8B, zona de datos donde leera el desplazamiento a hacer en zona de loader para cambiar instrucciones
ld a,#2c ;valor para el bucle de cambio de instrucciones de carga, 44 bytes x 2 cambios de cada, 88bytes a leer, CORROBORADO.
         ;en zona &AC8B-&ACE2 (final del loader)
.lac50
.bucle_relocalizacion
ld c,(hl) ;c=&39
inc hl ;&AC8C
ld b,(hl) ;b=&00
inc hl ;&AC8D
push hl ;guarda en stack
push bc ;guarda en stack bc=&0039
pop ix ;recupera en ix, ix=&0039
add ix,de ;&0039+AA1A= &AA53
ld l,(ix+#01) ;l=&2E
ld h,(ix+#02) ;h=&02 ;hl=&022E
add hl,de ;&022E + &AA1A ;HL=&AC48, es decir en &AA53 consigue un valor que sumado con &AA1A (recibido como parametro
          ;a esta funcion), consigue el valor &AC48 que usara para convertir 
          ;un "ld hl,(&022e)" que tiene ese valor de suma a "ld hl,(&AC48)"
          ;asi que recien cargado tiene el valor que aplicara al sumatorio con &AA1A y lo reescribe alli
          ;tiene cargado el DESPLAZAMIENTO y despues pone el valor real en la instruccion.
ld (ix+#01),l
ld (ix+#02),h ;cambia un ld hl,(&0248) a --> ld hl,(&AC48)
pop hl ;hl=&AC8D
dec a
jr nz,bucle_relocalizacion ;lac50
;por aqui ha RELOCALIZADO a esta zona de memoria, cambiado un monton de instrucciones de carga en el propio loader
ld a,#c3
ld (de),a ;de=&AA1A, cambia inicio de rutina &AA1A con instruccion JP
push de
pop ix ;recupera en ix valor de de, ix=&AA1A, es el primer salto que hara en el jp (ix) de &AC89
ld hl,#001b
add hl,de ;hl=&AA35
ex de,hl ;de=&AA35, hl=&AA1A
inc hl ;hl=&AA1B
ld (hl),e
inc hl
ld (hl),d ;CAMBIA DIRECCION DE MEMORIA A DONDE SALTARA EL JP QUE ACABA DE MODIFICAR A LA ENTRADA DE &AA1A
          ;AHORA INICIO DE RUTINA &AA1A SERA UN JP &AA35
pop hl ;hl &AA15
pop de ;de=&0100, lo volvera a meter en pila rutina &AA35 que acabara siendo llamada al finalizar esta rutina y empezar sig.
pop bc ;bc=&FFFF ;este valor se mando como parametro a rutina &AA1A y se guardo en pila

ld a,b ;a=&FF
inc a ;a=&00, Z flag activado
jr nz,lac85 ;el Z flag se ha obligado a activarse, NO hace el JR
;viene por aqui de primeras
ld a,c ;a=&FF
inc a ;a=&00, Z flag activado
jr z,lac89 ;ejecuta el salto de primeras al forcar el Z flago
.lac85
ld (&AC48),bc
.lac89
jp (ix) ;ix=&AA1A, salta a esa direccion, en pila esta (&AA10), en &AA1A se cambiaron 3 instrucciones al inicio de ella
                    ;en esta misma rutina.


.LAC8B ;zona de datos que usa rutina &AC4A para calcular desplazamiento de puntero ix y cambiar instrucciones de carga
;repito esto son los SUMATORIOS para calcular el puntero donde CAMBIARA INSTRUCCIONES DE CARGA.
db &39 ;SUMATORIO &0039
db &00  
db &3F ;SUMATORIO &003F, ETC, ETC,ETC.
db &00  
db &45 
db &00 
db &4B 
db &00 
db &51 
db &00 
db &58 
db &00 
db &79 
db &00 
db &81 
db &00 
db &B3 
db &00 
db &BD 
db &00 
db &E9 
db &00 
db &F5 
db &00 
db &12 
db &01
db &39
db &01 
db &51 
db &01
db &54
db &01 
db &5E 
db &01
db &61
db &01 
db &64 
db &01
db &69
db &01 
db &6C 
db &01
db &6F
db &01 
db &72 
db &01
db &75
db &01 
db &7B 
db &01
db &7E
db &01 
db &81 
db &01
db &89
db &01 
db &8c 
db &01
db &8F
db &01 
db &92 
db &01
db &9A
db &01 
db &9F 
db &01
db &A2
db &01 
db &A7 
db &01
db &AB
db &01 
db &BA 
db &01
db &CE
db &01 
db &DE
db &01 
db &ED
db &01 ;???, WINAPE cagandola como siempre en el desensamblado de datos
db &F4
db &01
db &0E 
db &02 
db &2D 
db &02 
db &6C 
db &02 

;----fin codigo cargado por loader 3------------------------


