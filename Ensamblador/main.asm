.386
.model flat, stdcall
.stack 10448576
option casemap:none

; ========== LIBRERIAS =============
include masm32\include\windows.inc 
include masm32\include\kernel32.inc
include masm32\include\user32.inc
includelib masm32\lib\kernel32.lib
includelib masm32\lib\user32.lib
include masm32\include\gdi32.inc
includelib masm32\lib\Gdi32.lib
include masm32\include\msimg32.inc
includelib masm32\lib\msimg32.lib
include masm32\include\winmm.inc
includelib masm32\lib\winmm.lib
 include masm32\include\masm32.inc
includelib masm32\lib\masm32.lib

include masm32\include\msvcrt.inc
includelib masm32\lib\msvcrt.lib
; ================ PROTOTIPOS ======================================
; Delcaramos los prototipos que no están declarados en las librerias
; (Son funciones que nosotros hicimos)
main			proto
credits			proto	:DWORD
playMusic		proto
joystickError	proto
WinMain			proto	:DWORD, :DWORD, :DWORD, :DWORD
vida            proto 
vidamas         proto
MovimientoEnemigo proto 

; =========================================== DECLARACION DE VARIABLES =====================================================
.data
; ==========================================================================================================================
; =============================== VARIABLES QUE NORMALMENTE NO VAN A TENER QUE CAMBIAR =====================================
; ==========================================================================================================================
className				db			"ProyectoEnsamblador",0		; Se usa para declarar el nombre del "estilo" de la ventana.
windowHandler			dword		?							; Un HWND auxiliar
windowClass				WNDCLASSEX	<>							; Aqui es en donde registramos la "clase" de la ventana.
windowMessage			MSG			<>							; Sirve pare el ciclo de mensajes (los del WHILE infinito)
clientRect				RECT		<>							; Un RECT auxilar, representa el área usable de la ventana
windowContext			HDC			?							; El contexto de la ventana
layer					HBITMAP		?							; El lienzo, donde dibujaremos cosas
layerContext			HDC			?							; El contexto del lienzo
auxiliarLayer			HBITMAP		?							; Un lienzo auxiliar
auxiliarLayerContext	HBITMAP		?							; El contexto del lienzo auxiliar
clearColor				HBRUSH		?							; El color de limpiado de pantalla
windowPaintstruct		PAINTSTRUCT	<>							; El paintstruct de la ventana.
joystickInfo			JOYINFO		<>							; Información sobre el joystick
; Mensajes de error:
errorTitle				byte		'Error',0
joystickErrorText		byte		'No se pudo inicializar el joystick',0
; ==========================================================================================================================
; ========================================== VARIABLES QUE PROBABLEMENTE QUIERAN CAMBIAR ===================================
; ==========================================================================================================================
; El título de la ventana
windowTitle				db			"THE LEGEND OF ZNEAKY",0
; El ancho de la venata CON TODO Y LA BARRA DE TITULO Y LOS MARGENES
windowWidth				DWORD		1500
; El alto de la ventana CON TODO Y LA BARRA DE TITULO Y LOS MARGENES
windowHeight			DWORD		900				
; Un string, se usa como título del messagebox NOTESE QUE TRAS ESCRIBIR EL STRING, SE LE CONCATENA UN 0
messageBoxTitle			byte		'Plantilla ensamblador: Créditos',0	
; Se usa como texto de un mensaje, el 10 es para hacer un salto de linea
; (Ya que 10 es el valor ascii de \n)
messageBoxText			byte		'Programación: Edgar Abraham Santos Cervantes',10,'Arte: Estúdio Vaca Roxa',10,'https://bakudas.itch.io/generic-rpg-pack',0
; El nombre de la música a reproducir.
; Asegúrense de que sea .wav
musicFilename			byte		'02.wav',0
; El manejador de la imagen a manuplar, pueden agregar tantos como necesiten.
image					HBITMAP		?

; El nombre de la imagen a cargar
imageFilename			byte		'Personaje4.BMP',0

x dword 0
y dword 0
xOrigen sdword 9 ;posicion en x en la imagen de el personaje 
yOrigen sdword 19;posicion en y en la imagen de el personaje 
xEnemigo sdword 481;Posicion en x en la imagen de el enemigo1
yEnemigo sdword 488 ;Posicion en y en la imagen de el enemigo1
xEnemigo2 sdword 574;Posicion en x en la imagen de el enemigo2
yEnemigo2 sdword 486 ;Posicion en y en la imagen de el enemigo2 
xscore dword 948
yscore dword 123
PRIMER dword 0

enemigomuerto dword 0
corazonposx dword 939 ;posicion de los corazones en la imagen
vidarest dword 0 ;contador de cuanta vida me queda 
colisionenemigo dword 0 ;contador de si colisiono con el enemigo
colisionpocion dword 0 ;colisionador de la pocion
Personaje1 RECT {} ;colision de personaje
Enemigo RECT{} ;colision de enemigo
Enemigo2 RECT{};colision de enemigo2
Pocion1 RECT{} ;colision de pocion
Colision RECT {}
ColisionPocion1 RECT {}
RectanguloColision RECT<>
xataque dword 0
yataque dword 0
ataquehecho1 RECT{}
ataquehecho dword 0
ESCENARIO1 dword 0;boleano para las colisiones del primer escenario
ESCENARIO2 dword 0;boleano para las colisiones del segundo escenario
ESCENARIO3 dword 0;boleano para las colisiones del tercer escenario
vidaenemigo1 dword 0
j dword 0
vidaenemigo2 dword 0
pocionaparece dword 0
edit byte 'EDIT',0
miTexto byte 'Play'
miBoton byte 'play',0
button byte 'BUTTON',0
Morir dword 0
pato dword 0
Playpress dword 0 ;boton presionado
BOTONAPARECE DWORD 0
movimiento1 dword 0
movimiento2 dword 0

boton1 dword 600
boton2 dword 500
; =============== MACROS ===================
RGB MACRO red, green, blue
	exitm % blue shl 16 + green shl 8 + red
endm 

.code

main proc
	; El programa comienza aquí.
	; Le pedimos a un hilo que reprodusca la música
	invoke	CreateThread, 0, 0, playMusic, 0, 0, 0
	; Obtenemos nuestro HINSTANCE.
	; NOTA IMPORTANTE: Las funciones de WinAPI normalmente ponen el resultado de sus funciones en el registro EAX
	invoke	GetModuleHandleA, NULL   
	; Mandamos a llamar a WinMain
	; Noten que, como GetModuleHandleA nos regresa nuestro HINSTANCE y los resultados de las funciones de WinAPI
	; suelen estar en EAX, entonces puedo pasar a EAX como el HINSTANCE
	invoke	WinMain, eax, NULL, NULL, SW_SHOWDEFAULT
	; Cierra el programa
	invoke ExitProcess,0
main endp

; Este es el WinMain, donde se crea la ventana y se hace el ciclo de mensajes.
WinMain proc hInstance:dword, hPrevInst:dword, cmdLine:dword, cmdShow:DWORD
	; ============== INICIALIZACION DE LA CLASE ====================
	; Establecemos nuestro callback procedure, que en este caso se llama WindowCallback
	mov		windowClass.lpfnWndProc, OFFSET WindowCallback
	; Tenemos que decir el tamaño de nuestra estructura, si no se lo dicen no se podrá crear la ventana.
	mov		windowClass.cbSize, SIZEOF WNDCLASSEX
	; Le asignamos nuestro HINSTANCE
	mov		eax, hInstance
	mov		windowClass.hInstance, eax
	; Asignamos el nombre de nuestra "clase"
	mov		windowClass.lpszClassName, OFFSET className
	; Registramos la clase
	invoke RegisterClassExA, addr windowClass                      
    
	; ========== CREACIÓN DE LA VENATANA =============
	; Creamos la ventana.
	; Le asignamos los estilos para que se pueda crear pero que NO se pueda alterar su tamaño, maximizar ni minimizar
	xor		ebx, ebx
	mov		ebx, WS_OVERLAPPED
	or		ebx, WS_CAPTION
	or		ebx, WS_SYSMENU
	
	invoke CreateWindowExA, NULL, ADDR className, ADDR windowTitle, ebx, CW_USEDEFAULT, CW_USEDEFAULT, windowWidth, windowHeight, NULL, NULL, hInstance, NULL
    ; Guardamos el resultado en una variable auxilar y mostramos la ventana.
	mov		windowHandler, eax
    invoke ShowWindow, windowHandler,cmdShow               
    invoke UpdateWindow, windowHandler                    

	; ============= EL CICLO DE MENSAJES =======================
    invoke	GetMessageA, ADDR windowMessage, NULL, 0, 0
	.WHILE eax != 0                                  
        invoke	TranslateMessage, ADDR windowMessage
        invoke	DispatchMessageA, ADDR windowMessage
		invoke	GetMessageA, ADDR windowMessage, NULL, 0, 0
   .ENDW
    mov eax, windowMessage.wParam
	ret
WinMain endp


; El callback de la ventana.
; La mayoria de la lógica de su proyecto se encontrará aquí.
; (O desde aquí se mandarán a llamar a otras funciones)
WindowCallback proc handler:dword, message:dword, wParam:dword, lParam:dword
	.IF message == WM_CREATE

	 
	xor eax, eax
	mov eax, WS_TABSTOP

	or eax, WS_VISIBLE
	or eax, WS_CHILD
	or eax,BS_DEFPUSHBUTTON
		;invoke CreateWindowExA,0,addr button, addr miBoton,eax,boton1,boton2,200,100,handler,0,0,0
		


	
		; Lo que sucede al crearse la ventana.
		; Normalmente se usa para inicializar variables.
		; Obtiene las dimenciones del área de trabajo de la ventana.
		invoke	GetClientRect, handler, addr clientRect
		; Obtenemos el contexto de la ventana.
		invoke	GetDC, handler
		mov		windowContext, eax
		; Creamos un bitmap del tamaño del área de trabajo de nuestra ventana.
		invoke	CreateCompatibleBitmap, windowContext, clientRect.right, clientRect.bottom
		mov		layer, eax
		; Y le creamos un contexto
		invoke	CreateCompatibleDC, windowContext
		mov		layerContext, eax
		; Liberamos windowContext para poder trabajar con lo demás
		invoke	ReleaseDC, handler, windowContext
		; Le decimos que el contexto layerContext le pertenece a layer
		invoke	SelectObject, layerContext, layer
		invoke	DeleteObject, layer
		; Asignamos un color de limpiado de pantalla
		invoke	CreateSolidBrush, RGB(0,0,0)
		mov		clearColor, eax
		;Cargamos la imagen
		invoke	LoadImage, NULL, addr imageFilename, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
		mov		image, eax
		; Habilitamos el joystick
		invoke	joyGetNumDevs
		.IF eax == 0
			invoke joystickError	
		.ELSE
			invoke	joyGetPos, JOYSTICKID1, addr joystickInfo
			.IF eax != JOYERR_NOERROR
				invoke joystickError
			.ELSE
				invoke	joySetCapture, handler, JOYSTICKID1, NULL, FALSE
				.IF eax != 0
					invoke joystickError
				.ENDIF
			.ENDIF
		.ENDIF
		; Habilita el timer
		invoke	SetTimer, handler, 100, 100, NULL
		
		





		mov Enemigo2.left,574
		mov Enemigo2.top, 540
		mov Enemigo2.right, 574+63
		mov Enemigo2.bottom,540+97

		mov Pocion1.left, 480
		mov Pocion1.top,450
		mov Pocion1.right,480+40
		mov Pocion1.bottom,450+55
		
	   

		

		mov Personaje1.left, 770
		mov Personaje1.top,405
		mov Personaje1.right,770 +52
		mov Personaje1.bottom,405+92
		.ELSEIF message == WM_COMMAND;para recibir los mensajes del boton
		mov eax, wParam
		.IF ax==0
		mov Playpress,1
		mov BOTONAPARECE,1
		mov boton1,2000
		mov boton2,2000
		.ENDIF
	.ELSEIF message == WM_PAINT
		; El proceso de dibujado
		; Iniciamos nuestro windowContext
		invoke	BeginPaint, handler, addr windowPaintstruct
		mov		windowContext, eax
		; Creamos un bitmap auxilar. Esto es, para evitar el efecto de parpadeo
		invoke	CreateCompatibleBitmap, layerContext, clientRect.right, clientRect.bottom
		mov		auxiliarLayer, eax
		; Le creamos su contetxo
		invoke	CreateCompatibleDC, layerContext
		mov		auxiliarLayerContext, eax
		; Lo asociamos
		invoke	SelectObject, auxiliarLayerContext, auxiliarLayer
		invoke	DeleteObject, auxiliarLayer
		; Llenamos nuestro auxiliar con nuestro color de borrado, sirve para limpiar la pantalla
		invoke	FillRect, auxiliarLayerContext, addr clientRect, clearColor
		; Elegimos la imagen
		invoke	SelectObject, layerContext, image
		;invoke SelectObject, layerContext, personajeFilename

		; Aquí pueden poner las cosas que deseen dibujar x,y de la pantalla , ancho, alto, de que parte de la imagen lo coseguira, y el tamaño que tiene
		;invoke TransparentBlt, auxiliarLayerContext, 100, 80, 50, 75, layerContext, 8, 17, 53 ,92, 00000FF00h
		.IF Playpress==0
		invoke TransparentBlt, auxiliarLayerContext, 0, 0, 1500, 1000, layerContext, 1, 1826, 863 ,485, 00000FF00h;pantalla de inicio
		.ENDIF
		.IF Playpress==1
		invoke TransparentBlt, auxiliarLayerContext, 0, 0, 1400, 850, layerContext, 165, 2580, 900,573, 00000FF00h;nota del inicio
		.ENDIF
		.IF Playpress==2
	
			.IF ESCENARIO1==0
		invoke TransparentBlt, auxiliarLayerContext, 0, 0, 1640, 910, layerContext, 1456, 2, 511 ,256, 00000FF00h;escenario
		.IF pocionaparece ==0
	  
		invoke TransparentBlt, auxiliarLayerContext, 1100, 450, 30, 45, layerContext, 926, 605, 101 ,123, 00000FF00h;pocion2
		
		
		
		.ENDIF
		
		.ENDIF ;if de escenario 1
		invoke TransparentBlt, auxiliarLayerContext, 600, 0, 130, 44, layerContext, corazonposx, 442, 187 ,55, 00000FF00h;corazon
		.IF ESCENARIO2==1
		invoke TransparentBlt, auxiliarLayerContext, 400, 0,500, 900, layerContext, 1072, 1025, 251 ,511, 00000FF00h;escenario2
		invoke TransparentBlt, auxiliarLayerContext, 605, 203, 50, 55, layerContext, 1052, 529, 125 ,134, 00000FF00h;cofre
		.IF vidaenemigo1 == 0
		invoke TransparentBlt, auxiliarLayerContext, Enemigo2.left, Enemigo2.top, 50, 55, layerContext, xEnemigo2, yEnemigo2, 63 ,97, 00000FF00h;enemigo2
		.ENDIF
			invoke TransparentBlt, auxiliarLayerContext, 600, 0, 130, 44, layerContext, corazonposx, 442, 187 ,55, 00000FF00h;corazon
		mov eax, Personaje1.left
		add eax, 52
		mov Personaje1.right, eax
		mov eax, Personaje1.top
		add eax,92
		mov Personaje1.bottom, eax
		.IF vidaenemigo1 == 0
			invoke IntersectRect, addr Colision, addr Personaje1, addr Enemigo2;colision enemigo 2

	.IF eax !=0
	mov colisionenemigo,1
	.IF ataquehecho == 0
	.IF yOrigen==126 ;izquierda
	mov eax,Personaje1.left
	add eax,32
	mov Personaje1.left,eax
	invoke vida 
	.ELSEIF yOrigen ==234 ;derecha
    mov eax, Personaje1.left
	sub eax,32
	mov Personaje1.left,eax
	invoke vida
	.ELSEIF yOrigen==342;ARRIBA
	
		mov eax,Personaje1.top
		add eax, 32
		mov Personaje1.top,eax
		invoke vida 
		.ELSEIF yOrigen==19;ABAJO
		mov eax, Personaje1.top
		sub eax,32
		mov Personaje1.top, eax
	 
	
	 .ENDIF
	
	 

	 .ENDIF

	.IF ataquehecho == 0
	mov vidaenemigo1,1
	 .ENDIF


mov colisionenemigo,0
		.ENDIF
	.ENDIF
		.ENDIF;if de escenario 2
		.IF ESCENARIO3==1
		invoke TransparentBlt, auxiliarLayerContext, 400, 0,500, 900, layerContext, 1526, 1048, 284 ,513, 00000FF00h;escenario3
		invoke MovimientoEnemigo
		
     	invoke TransparentBlt, auxiliarLayerContext, Enemigo.left, Enemigo.top, 50, 55, layerContext, xEnemigo, yEnemigo, 63 ,97, 00000FF00h;enemigo1
	
	
		.ENDIF ;if escenario 3
		
		invoke TransparentBlt, auxiliarLayerContext,Personaje1.left, Personaje1.top,40,65, layerContext, xOrigen, yOrigen,60,100, 00000FF00h;personaje
		.if ataquehecho==1
		invoke TransparentBlt, auxiliarLayerContext, ataquehecho1.left, ataquehecho1.top, 50, 55, layerContext, xataque, yataque, 77 ,84, 00000FF00h;ataque
		.ENDIF
	    
		.IF pato==1; imagen del final
		invoke TransparentBlt, auxiliarLayerContext, 0, 0, 1640, 910, layerContext, 1957, 1017, 1047 ,633, 00000FF00h;escenario
		invoke KillTimer, handler, 100
		.ENDIF ;imagen del final
		invoke TransparentBlt, auxiliarLayerContext, 100, 2, 180, 50, layerContext, 951, 301, 182 ,55, 00000FF00h;score
		invoke TransparentBlt, auxiliarLayerContext, 300, 2, 50, 50, layerContext, 948, 123, 51 ,59, 00000FF00h;numero0
		
		invoke TransparentBlt, auxiliarLayerContext, 400, 2, 50, 50, layerContext, 948, 123, 50 ,59, 00000FF00h;numero0
		invoke TransparentBlt, auxiliarLayerContext, 350, 2,50, 50, layerContext, xscore, yscore, 50 ,59, 00000FF00h;numero0
		
	.ENDIF
		
		
		
	
      


	
		
		; Ya que terminamos de dibujarlas, las mostramos en pantalla
		invoke	BitBlt, windowContext, 0, 0, clientRect.right, clientRect.bottom, auxiliarLayerContext, 0, 0, SRCCOPY
		invoke  EndPaint, handler, addr windowPaintstruct
		; Es MUY importante liberar los recursos al terminar de usuarlos, si no se liberan la aplicación se quedará trabada con el tiempo
		invoke	DeleteDC, windowContext
		invoke	DeleteDC, auxiliarLayerContext

	.ELSEIF message == WM_KEYDOWN
	
		; Lo que hace cuando una tecla se presiona
		; Deben especificar las teclas de acuerdo a su código ASCII
		; Pueden consultarlo aquí: https://elcodigoascii.com.ar/
		; Movemos wParam a EAX para que AL contenga el valor ASCII de la tecla presionada.
		mov	eax, wParam
		; Esto es un ejemplo: Si presionamos la tecla P mostrará los créditos
		;xOrigen sdword 9
	;yOrigen sdword 19
	mov xOrigen,9
	mov yOrigen,19
	.IF Playpress==0 && Playpress==1
		.ELSEIF al==49;boton 1
	  inc Playpress
	
		.ENDIF
	
		.IF al == 80
	
			invoke	credits, handler
		.ELSEIF al== 65;a
		
		mov ataquehecho,1
			add xOrigen,78
			.IF xOrigen == 9+468
			mov xOrigen, 9
			.ENDIF
			mov yOrigen, 126
			
			sub Personaje1.left,10
			
       .ELSEIF al==68;d
	   mov ataquehecho,1
	  add xOrigen,78
			.IF xOrigen == 9+468
			mov xOrigen, 9
			.ENDIF
	   mov yOrigen, 234
	   add Personaje1.left,10
	   
       .ELSEIF al==87;w
	   mov ataquehecho,1
	add xOrigen,78
			.IF xOrigen == 9+468
			mov xOrigen, 9
			.ENDIF
	   mov yOrigen, 342
	   sub Personaje1.top,10
	   
       .ELSEIF al==83;s
	   mov ataquehecho,1
	  add xOrigen,78
			.IF xOrigen == 9+468
			mov xOrigen, 9
			.ENDIF
		
	   mov yOrigen,19
	   add Personaje1.top, 10
	   
		.ELSEIF al==81 && yOrigen ==19;ataque hacia abajo
		mov ataquehecho,0
			mov xOrigen,1290
			mov yOrigen,44
		.ELSEIF al==81 && yOrigen ==342;ataque hacia arriba
		mov ataquehecho,0 
			mov xOrigen,1284
			mov yOrigen,368
	   .ELSEIF al==81 && yOrigen ==126;ataque izquierda
	   mov ataquehecho,0 
			mov xOrigen,1259
			mov yOrigen,152
			.ELSEIF al==81 && yOrigen ==234;ataque hacia derecha 
			mov ataquehecho,0
			mov xOrigen,1261
			mov yOrigen,261
	   	
		.ENDIF
	
	.ELSEIF message == MM_JOY1MOVE
		; Lo que pasa cuando mueves la palanca del joystick
		xor	ebx, ebx
		xor edx, edx
		mov	edx, lParam
		mov bx, dx
		and	dx, 0
		ror edx, 16
		; En este punto, BX contiene la coordenada de la palanca en x
		; Y DX la coordenada y
		; Las coordenadas se dan relativas al la esquina superior izquierda de la palanca.
		; En escala del 0 a 0FFFFh
		; Lo que significa que si la palanca está en medio, la coordenada en X será 07FFFh
		; Y la coordenada Y también.
		; Lo máximo hacia arriba es 0 en Y
		; Lo máximo hacia abajo en FFFF en Y
		; Lo máximo hacia la derecha es FFFF en X
		; Lo máximo hacia la izquierda es 0 en X
		; Si la palanca no está en ningún extremo, será un valor intermedio
		; Este es un ejemplo: Si la palanca está al máximo a la derecha, mostrará los créditos
		.IF bx == 0FFFFh
			invoke credits, handler
		.ENDIF 
	.ELSEIF message == MM_JOY1BUTTONDOWN
		; Lo que hace cuando presionas un botón del joystick
		; Pueden comparar que botón se presionó haciendo un AND
		xor	ebx, ebx
		mov	ebx, wParam
		and	ebx, JOY_BUTTON1
		; Esto es un ejemplo, si presionamos el botón 1 del joystick, mostrará los créditos
		.IF	ebx != 0
			invoke credits, handler
		.ENDIF
	.ELSEIF message == WM_TIMER
		; Lo que hace cada tick (cada vez que se ejecute el timer)
		;invoke Enemigos 
		
	
		
	
		.IF ESCENARIO3==1
	mov eax,Personaje1.left
		mov ebx,Personaje1.top
		.IF Enemigo.left<eax;derecha
		add Enemigo.left,5
		mov yEnemigo,804
		.ENDIF
	  .IF Enemigo.left>eax;izquierda
	  sub Enemigo.left,5
	  mov yEnemigo,699

	  .ENDIF
		.IF Enemigo.top>ebx;arriba
		 sub Enemigo.top,5
		 mov yEnemigo,593
		.ENDIF
		.IF Enemigo.top<ebx;abajo
		add Enemigo.top,5
		
		mov eax, Personaje1.left
		add eax, 52
		mov Personaje1.right, eax
		mov eax, Personaje1.top
		add eax,92
		mov Personaje1.bottom, eax
			invoke IntersectRect, addr Colision, addr Personaje1, addr Enemigo;colision enemigo 2
	.IF eax !=0
	.IF yOrigen==126 ;izquierda
	mov eax,Personaje1.left
	add eax,32
	mov Personaje1.left,eax
	.ELSEIF yOrigen ==234 ;derecha
    mov eax, Personaje1.left
	sub eax,32
	mov Personaje1.left,eax
	.ELSEIF yOrigen==342;ARRIBA
	
		mov eax,Personaje1.top
		add eax, 32
		mov Personaje1.top,eax
		.ELSEIF yOrigen==19;ABAJO
		mov eax, Personaje1.top
		sub eax,32
		mov Personaje1.top, eax
		.ENDIF
	.ENDIF
		
		.ENDIF

		.ENDIF;if de arriba

		.IF ESCENARIO2==1
		.IF vidaenemigo1==0
		mov eax,Personaje1.left
		mov ebx,Personaje1.top
		.IF Enemigo2.left<eax;derecha
		add Enemigo2.left,5
		mov yEnemigo2,803
		.ENDIF
	  .IF Enemigo2.left>eax;izquierda
	  sub Enemigo2.left,5
	  mov yEnemigo2,699

	  .ENDIF
		.IF Enemigo2.top>ebx;arriba
		 sub Enemigo2.top,5
		 mov yEnemigo2,593
		.ENDIF
		.IF Enemigo2.top<ebx;abajo
		add Enemigo2.top,5
		
		.ENDIF
		.ENDIF
		.ENDIF

		
		.IF ESCENARIO1==0;colisiones del primer esscenario
		.IF Personaje1.left<655 &&Personaje1.left>600&&Personaje1.top<195 &&Personaje1.top>155;colision con la puerta superior
		mov Personaje1.left,625
		mov Personaje1.top,705
		mov ESCENARIO1,1
		mov ESCENARIO2,1
		.ENDIF

     	.IF Personaje1.left<830 &&Personaje1.left>780&&Personaje1.top<710 &&Personaje1.top>655;colision con la puerta inferior
		mov ESCENARIO1,1
		mov ESCENARIO3,1
		mov Personaje1.left,545
		mov Personaje1.top,46
		.ENDIF
		.IF Personaje1.left<1150&&Personaje1.left>1080&&Personaje1.top<450&&Personaje1.top>420;colision con la pocion1
		 .IF Personaje1.left < 1150 ;izquierda
      add Personaje1.left,32
	 mov colisionpocion,1
	 invoke vidamas
	 mov colisionenemigo,0
        .ENDIF

        .IF Personaje1.left > 1070;derecha
        sub Personaje1.left,32
        .ENDIF

        .IF Personaje1.top > 420;abajo
      sub Personaje1.top,32
        .ENDIF

        .IF Personaje1.top < 450;arriba
        add Personaje1.top,32
        .ENDIF

		.ENDIF;colision con la pocion1

		 .IF Personaje1.left < 450 ;izquierda
      add Personaje1.left,32
        .ENDIF

        .IF Personaje1.left > 1150;derecha
        sub Personaje1.left,32
        .ENDIF

        .IF Personaje1.top > 690;abajo
      sub Personaje1.top,32
        .ENDIF

        .IF Personaje1.top < 180;arriba
        add Personaje1.top,32
        .ENDIF
		.IF Morir==1
		invoke KillTimer, handler, 100
		.ENDIF
		.ENDIF;colisiones del primer escenario

		 .IF ESCENARIO2==1;colisiones del segundo escenario
	    .IF Personaje1.left<670 &&Personaje1.left>634&&Personaje1.top<790 &&Personaje1.top>770;colision de la puerta 
		mov ESCENARIO1,0
		mov ESCENARIO2,0
		mov Personaje1.left,650
		mov Personaje1.top,204
		.ENDIF
		.IF Personaje1.left <631&&Personaje1.left>591 &&Personaje1.top<215 &&Personaje1.top>145;colision con el cofre 
	     mov pato,1
		 .ELSEIF vidaenemigo1==1
		 mov xscore,1065
		 mov yscore,190
	
		.ENDIF

		 .IF Personaje1.left < 450 
      add Personaje1.left,32
	  
        .ENDIF

        .IF Personaje1.left > 780
        sub Personaje1.left,32
        .ENDIF

        .IF Personaje1.top > 800
      sub Personaje1.top,32
        .ENDIF

        .IF Personaje1.top < 80
        add Personaje1.top,32
        .ENDIF
		.IF Morir==1
		invoke KillTimer, handler, 100
		.ENDIF
        .ENDIF;colisiones del segundo escenario

		 .IF ESCENARIO3==1;colisiones del Tercer escenario
	.IF Personaje1.left<560 &&Personaje1.left>510&&Personaje1.top<55 &&Personaje1.top>10 ;colision con la puerta de arriba
		mov ESCENARIO1,0
		mov ESCENARIO3,0
		mov Personaje1.left,800
		mov Personaje1.top,684
		.ENDIF

		 .IF Personaje1.left < 450 
      add Personaje1.left,32
        .ENDIF

        .IF Personaje1.left > 860
        sub Personaje1.left,32
        .ENDIF

        .IF Personaje1.top > 350
      sub Personaje1.top,32
        .ENDIF

        .IF Personaje1.top < 40
        add Personaje1.top,32
        .ENDIF
		.IF Morir==1
		invoke KillTimer, handler, 100
		.ENDIF
        .ENDIF;colisiones del Tercer escenario
		
		
		
		
		invoke	InvalidateRect, handler, NULL, FALSE
		
	.ELSEIF message == WM_DESTROY
		; Lo que debe suceder al intentar cerrar la ventana.   
        invoke PostQuitMessage, NULL
    .ENDIF
	; Este es un fallback.
	; NOTA IMPORTANTE: Normalmente WinAPI espera que se le regrese ciertos valores dependiendo del mensaje que se esté procesando.
	; Como varia mucho entre mensaje y mensaje, entonces DefWindowProcA se encarga de regresar el mensaje predeterminado como si las cosas
	; fueran con normalidad. Pero en realidad pueden devolver otras cosas y el comportamiento de WinAPI cambiará.
	; (Por ejemplo, si regresan -1 en EAX al procesar WM_CREATE, la ventana no se creará)
    invoke DefWindowProcA, handler, message, wParam, lParam     
    ret
WindowCallback endp

; Reproduce la música
playMusic proc
	xor		ebx, ebx
	mov		ebx, SND_FILENAME
	or		ebx, SND_LOOP
	or		ebx, SND_ASYNC
	invoke	PlaySound, addr musicFilename, NULL, ebx
	ret
playMusic endp

; Muestra el error del joystick
joystickError proc
	xor		ebx, ebx
	mov		ebx, MB_OK
	or		ebx, MB_ICONERROR
	invoke	MessageBoxA, NULL, addr joystickErrorText, addr errorTitle, ebx
	ret
joystickError endp

; Muestra los créditos
credits	proc handler:DWORD
	; Estoy matando al timer para que no haya problemas al mostrar el Messagebox.
	; Veanlo como un sistema de pausa
	invoke KillTimer, handler, 100
	xor ebx, ebx
	mov ebx, MB_OK
	or	ebx, MB_ICONINFORMATION
	invoke	MessageBoxA, handler, addr messageBoxText, addr messageBoxTitle, ebx
	; Volvemos a habilitar el timer
	invoke SetTimer, handler, 100, 10, NULL
	ret
credits endp

vida proc ;funcion para restar la vida y que se termine el juego si llega a 0
 .IF colisionenemigo==1
 .IF ataquehecho ==1
 add corazonposx,64; VARIABLE PARA MOSTRAR LOS CORAZONES 
inc vidarest;VARIABLE PARA CONTAR LA VIDA RESTANTE 
.ENDIF
  .ENDIF

  .IF vidarest>3
  mov Morir, 1
invoke TransparentBlt, auxiliarLayerContext, 0, 0, 1250, 1025, layerContext, 2, 1025, 979,769 , 00000FF00h

  .ENDIF
  ret
vida endp

vidamas proc ;funcion para aumentar la vida 
   .IF colisionpocion==1 
   mov corazonposx,939
   
   inc vidarest
  mov pocionaparece,1
   .ENDIF
   ret
vidamas endp

MovimientoEnemigo proc;para la aletoriedad del primer enemigo
.IF PRIMER==0
		invoke crt_time, 0
		invoke crt_srand, eax

            invoke crt_rand
			
            and eax, 000000325h
			.IF eax<000001C2h
			add eax, 00000032h
			.ENDIF
			.IF eax>000001C2h
			mov Enemigo.left, eax
			.ENDIF

				invoke crt_time, 0
		    invoke crt_srand, eax
            invoke crt_rand
			   and eax, 00000015Ah
			   .IF eax<00000032h
			   add eax,00000032h
			   .ENDIF
			   .IF eax>00000032h
			mov Enemigo.top,eax
			.ENDIF
				mov PRIMER,1

			.ENDIF
ret

MovimientoEnemigo endp


end main

