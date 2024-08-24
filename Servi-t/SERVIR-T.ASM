 
;
;                             Proyecto= Servir-T 
;                             TÉCNICA DIGITALES II
;                             FRSN UTN 
;                             2011
;           
;                    PROGRAMADOR: BERNÁRDEZ ANDRÉS HUGO  





                list p=16F873A
                include "p16f873a.inc"
                __CONFIG 0x3F39; OSCILADOR XT, SIN WDT


CENTISEGUNDO    EQU 0x20; VARIABLES DE TIEMPO
SEGUNDO         EQU 0x21
DECASEGUNDO     EQU 0x22
MINUTO          EQU 0X23
DECAMINUTO      EQU 0X24
HORA            EQU 0X25
DECAHORA        EQU 0X26
DIA             EQU 0X27
MINUTO_A        EQU 0X28   ;VARIABLES DE ALARMA
DECAMINUTO_A    EQU 0X29
HORA_A          EQU 0X2A
DECAHORA_A      EQU 0X2B
ALARMAFLAG      EQU 0X2C ; INDICA CUANDO ESTA ACTIVADA LA ALARMA
BITFLAGS        EQU 0X2D ; BITS DE PROPOSITOS GENERALES, 7:AUXILIAR PAR FREC.DE CONVERSION



MILESIMA        EQU 0X2F; VARIABLES DE MEDICION
CENTESIMA       EQU 0X30;
DESIMA          EQU 0X31
UNIDAD          EQU 0X32
DECENA          EQU 0X33

OPCIONMOS       EQU 0X35; VARIABLES DE MOSTRAR (4 DISPLAYS 7SEG CON BCD Y REFRESCO CON SOFTWARE)
CONTADORMOSTRAR EQU 0X36;  CONTADOR EN FUNCION MOSTRAR
DISPLAYBIT      EQU 0X37;  ESTE BIT ACTIVA UN DISPLAY POR VEZ EN EL PUERTO B
PUNTERO_0       EQU 0X38  ; VALORES QUE APUNTAN LO QUE DEBEN MOSTRAR LOS DISPLAY
PUNTERO_1       EQU 0X39
PUNTERO_2       EQU 0X3A
PUNTERO_3       EQU 0X3B
RETARDOM        EQU 0X3C; RETARDO QUE SE USA CUANDO SE PRENDE UN DISPLAY
PCLATHAUX1      EQU 0X3D; REGISTRO AUXILIAR DE PCLATHAUX USADO EN FUNCION MOSTRAR


RETARDO         EQU 0x40; VARIABLE DE RETARDO SIN TIMER


                         ;VARIABLES DE INTERFAZ
BOTON           EQU 0X41; VARIABLE DE PRESION DE BOTON(GUARDA QUE SE APRETO)
PETICION        EQU 0X42; VARIABLE QUE INTERACTUA CON LA FUNCION ACTUAL CUANDO EL USUARIO APRIETA UN BOTON
SENSO           EQU 0X43; VARIABLE DE DETECCION DE ESTADO DE LOS SENSORES


MENU            EQU 0X44; INDICA QUE FUNCION ESTA SELECCIONADA PARA SER USADA CON ENTER
DECAMENU        EQU 0X45; //      //  //         
FUNCION         EQU 0X46;  INDICA CUAL ES LA FUNCION ACTUAL QUE SE ESTA USANDO

PROCESO         EQU 0X48;  PROCESO ACTUAL QUE SE REALIZA
CRONOPROC       EQU 0X49;  AVISA QUE SE HA COMENZADO A CRONOMETRAR UN PROCESO
CRONO           EQU 0X4A; CRONOMETRA EL TIEMPO DE ALGUN PROCESO (PRECISION DE +0.25 SEGUNDOS) 
                            ;CADA 4 UNIDADES ES UN SEGUNDO. CUENTA MAXIMA 63.75 SEGUNDOS
ERRORNUM        EQU 0X4B;  DESIGNA CON UN NUMERO A UN ERROR QUE HAYA OCURRIDO
                           ;( POR DESBORDAMIENTO DE TIEMPO ESTIMADO PARA UN PROCESO)

WREGAUX         EQU 0X50; VARIABLES AUXILIARES DE INTERRUPCION
STATUSAUX       EQU 0X51
PCLATHAUX       EQU 0X52

                         ; VARIABLES PARA EL ANÁLISIS DE LA CONVERSION
UC              EQU 0X53;
DCV              EQU 0X54;
CC              EQU 0X55;
MC              EQU 0X56;
DMC             EQU 0X57
CMC             EQU 0X58
NUM1            EQU 0X59;       PARA DIVIDIR
NUM2            EQU 0X5A
ARIT_AUX        EQU 0X5B


LETRAMENU       EQU 0X5C  ;VARIABLES QUE SOLO SIRVE PARA MOSTRAR ALGO EN EL DISPLAY
LETRAIZQ        EQU 0X5D
LETRADER        EQU 0X5E
PARPADEOBIT     EQU 0X5F  ; //BIT7:ESTADO DE PARPADEO//2:PARPADEOIZQ//1:PARPADEODER//0:PARPADEO ON

UNIDAD_T        EQU 0X60   ; VARIABLES DE TENSION FINAL
DESIMA_T        EQU 0X61
CENTESIMA_T     EQU 0X62
ALARMA_T        EQU 0X63   ; ALARMA DE TENSION 
UNIDAD_A        EQU 0X64   ; VARIABLES DE TENSIÓN FINAL DE ALARMA
DESIMA_A        EQU 0X65
CENTESIMA_A     EQU 0X66
UNIDAD_C        EQU 0X67  ; CONTROL DEL "ERROR_00"( NO SE DETECTA  VARIACION POR MAS DE UN MINUTO)
DESIMA_C        EQU 0X68
CENTESIMA_C     EQU 0X69
CONTADOR_C      EQU 0X70



ADPROMH         EQU 0X71
ADPROML         EQU 0X72

NUMDH           EQU 0X73  ; VARIABLES PARA FUNCION "DIVDOBLE"
NUMDL           EQU 0X74
DIVDRESTOH       EQU 0X75
DIVDRTAH        EQU 0X76
DIVDRTAL        EQU 0X77








;**********************************************************

                org 0X00
                NOP
                GOTO INICIO;  EMPEZAR EL PROGRAMA
                GOTO INICIO;  REDUNDANCIA
;________________________________________________
;-----------------------------------------------¬|
                ORG 0X04   ;INTERRUPCION     ___<|

                MOVWF WREGAUX   ; GUARDAR REGISTROS IMPORTANTES: PCLATH STATUS Y WREG
                MOVF STATUS,0
                MOVWF STATUSAUX
                MOVF PCLATH,0
                MOVWF PCLATHAUX
                
                
                BTFSS INTCON,2 ; ¿QUE INTERRUPCION? ¿POR TIMER0?
                GOTO TIMER1INT ; NO
                GOTO REFRESCAR ; SI

VOLVERREFRES:   CLRF TMR0;
                BCF INTCON,2; HABILITAR TIMER0
                BTFSS  PIR1,2
                GOTO RETORNARINT
                

TIMER1INT:      BCF PIR1,2;HABILITAR BANDERA COMPARADOR TIMER1


;-------------------------RUTINA DE INCREMENTAR TIEMPO Y LLENAR VARIABLES CON VALOR CORRESPONDIENTE.....
;---------------
                
                INCF CENTISEGUNDO  ; INCREMENTAR UN CENTISEGUNDO Y ACOMODAR HORA...
                
                MOVLW .25
                SUBWF CENTISEGUNDO,0  ; ¿ES CENTISEGUNDO=.25?
                BTFSC STATUS,Z
                INCF CRONO ;  SI: INCREMENTAR CRONO  (CRONO SIRVE PARA CRONOMETRAR CON ERROR MAX DE 0.25 SEGUNDOS,
                                  ; 4 UNIDADES DE CRONO ES UN SEGUNDO)

                MOVLW .50
                SUBWF CENTISEGUNDO,0  ; ¿ES CENTISEGUNDO=.50?
                BTFSC STATUS,Z
                INCF CRONO ; 

                MOVLW .75
                SUBWF CENTISEGUNDO,0  ; ¿ES CENTISEGUNDO=.75?
                BTFSC STATUS,Z
                INCF CRONO ; 


SIGUERELOJ:     MOVLW .100
                SUBWF CENTISEGUNDO,0  ; ¿ES CENISEGUNDO >=.100?
                BTFSS STATUS,C
                GOTO RETORNARINT      ; NO: IR A RETORNARINT
 
                CLRF CENTISEGUNDO     ;SI: CENTISEGUNDO=0

                INCF CRONO             ; INCREMENTAR CRONO
                
                INCF SEGUNDO           ; INCREMENTAR SEGUNDO
                MOVLW 0X0A             ; ¿ES SEGUNDO >=0X0A?
                SUBWF SEGUNDO,0
                BTFSS STATUS,C      
                GOTO RETORNARINT       ; NO: IR A RETORNARINT

                CLRF SEGUNDO           ;SI: SEGUNDO=0, INCREMENTAR DECASEGUNDO
                INCF DECASEGUNDO
                MOVLW 0X06
                SUBWF DECASEGUNDO,0    ;¿ES DECASEGUNDO>= 6?
                BTFSS STATUS,C
                GOTO RETORNARINT        ;NO: IR A RETORNARINT

                CLRF DECASEGUNDO        ;SI: DECASEGUNDO=0, INCREMENTAR MINUTO
                INCF MINUTO
                MOVLW 0X0A              ;¿ES MINUTO>=10?
                SUBWF MINUTO,0
                BTFSS STATUS,C
                GOTO RETORNARINT        ;NO: IR A RETORNARINT

                CLRF MINUTO
                INCF DECAMINUTO         ;SI: MINUTO=0, INCREMENTAR DECAMINUTO
                MOVLW 0X06
                SUBWF DECAMINUTO,0      ; ¿ES DECAMINUTO>= 6?
                BTFSS STATUS,C
                GOTO RETORNARINT        ;NO: IR A RETORNARINT

                CLRF DECAMINUTO         ;SI...

                             ;-------------------LLENAR LAS HORAS TIENE MAS COMPLICACION...
                INCF HORA               ; INCREMENTAR HORA...


                MOVLW 0X02                   ; ¿ DECAHORA>=2 ?
                SUBWF DECAHORA,0              
                BTFSS STATUS,C                
                GOTO HORA1                  ;NO: IR A HORA1
                
                MOVLW 0X04                   ; SI:¿ HORA>=4?
                SUBWF HORA,0
                BTFSS STATUS,C
                GOTO RETORNARINT             ;NO: IR A RETORNARINT

                CLRF HORA                     ;ENTONCE DECAHORA,HORA= 00HS
                CLRF DECAHORA 
                GOTO DIA1                     ;IR A DIA

HORA1:          MOVLW 0X0A                  ; VERIFICAR SI HORA= 0X0A??
                SUBWF HORA,0
                BTFSS STATUS,C
                GOTO RETORNARINT             ;NO: IR A RETORNARINT
                
                CLRF HORA                    ;SI: HORA=00// DECAHORA++
                INCF DECAHORA
                GOTO RETORNARINT

                           ;-----------------------------FIN LLENAR HORAS
DIA1:               
                INCF DIA                   ;¿DIA>=0X0A?
                MOVLW 0X0A                 
                SUBWF DIA,0
                BTFSS STATUS,C
                GOTO RETORNARINT           ;NO: IR A RETORNARINT

                CLRF DIA                   ;SI: DIA=0      
                GOTO RETORNARINT; IR A RETORNARINT
;------------------
;----------------------------------------FIN DE RUTINA DE LLENAR TIEMPO



RETORNARINT:    MOVF STATUSAUX,0; RECUPERAR STATUS
                MOVWF STATUS; 
                MOVF PCLATHAUX,0
                MOVWF PCLATH;  RECUPERAR REGISTRO PCLATH

                MOVF WREGAUX,0; RECUPERAR REGISTRO W
                RETFIE                            

;----------------------FIN INTERRUPCION     || 
;___________________________________________||



;--------------------FUNCION REFRESCAR..........

REFRESCAR:   
                MOVLW 0X08
                MOVWF CONTADORMOSTRAR   ; CONTADORMOSTRAR=8

                MOVLW B'10000000'
                MOVWF DISPLAYBIT ;       ;DISPLAYBIT=B'10000000'
                CLRF PORTB;               PORTB=0
               
                CLRF PCLATH;             ;PCLATH=0
                
                BTFSC PARPADEOBIT,0 ; ¿¿ESTA ACTIVADO EL PARPADEO??
                GOTO PARPADEO;          SI ESTA ACITVADO IR A PARPADEO                
CICLOMOSTRAR:  
                MOVF CONTADORMOSTRAR,0 ; NO
                                    
                ADDWF PCL,1
                NOP                 ; CONTADORMOSTRAR=??
                NOP                         
                MOVF PUNTERO_0,0    ; =2-> WREG=PUNTERO_0
                GOTO CARGARPORTB
                MOVF PUNTERO_1,0    ; =4-> WREG=PUNTERO_1
                GOTO CARGARPORTB
                MOVF PUNTERO_2,0    ; =6-> WREG=PUNTERO_2
                GOTO CARGARPORTB
                MOVF PUNTERO_3,0    ; =8-> WREG=PUNTERO_3                 
                      
                           ;DIRECCIONAMIENTO INDIRECTO!!!
CARGARPORTB:    MOVWF FSR  ; DIRECCION DONDE ESTA EL DATO A LEER
                MOVF INDF,0; LEER DATO AL QUE APUNTA FSR                

                
                MOVWF PORTB;  PORTB DEBE SER UN NÚMERO DEL 0X0 AL 0xF 
                MOVF DISPLAYBIT,0; EJEMPLO SI DISPLAYBIT=00010000=>W=00010000
                IORWF PORTB,1 ; EJEMPLO PORTB=(00010000 OR 0000XXXX)=0001XXXX
              
                MOVLW 0XFF;  RETARDO PRENDIDO
                MOVWF RETARDOM

ESPERA1:        NOP
                NOP
                NOP;           SON UN TOTAL DE RETARDO1*4 CICLOS   NOP=1 CICLO GOTO=2CICLO DECFSZ=1 CICLO CUANDO NO SALTA
                DECFSZ RETARDOM ;; 4DISPLAYS QUE ESTARAN 256*4 CICLOS SON UN TOTAL DE 6144 USEG QUE ES MENOR
                                 ; A LOS 10000 DEL TMR1 TODAVIA HAY TIEMPO ANTES DE SER NECESARIO ACTIVAR 
                                 ;LA INTERRUPCION X TMR1
                GOTO ESPERA1
                
                CLRF PORTB ;SE APAGA EL PORTB
                NOP
                NOP        ; SE ESPERA UN POCO PARA QUE SE APAGUE EL DISPLAY 
                NOP       ;APROVECHANDO LAS INSTRUCCIONES DE ESTA FUNCION
                NOP

                RRF DISPLAYBIT,1;  SE ROTA EL BIT A LA DER. DE DISPLAYBIT               
                
                DECF CONTADORMOSTRAR   ; DECREMENTAR CONTADORMOSTRAR
                DECFSZ CONTADORMOSTRAR ; VOLVER A DECREMENTAR  ¿ES CERO?
                GOTO CICLOMOSTRAR      ; AUN NO
                GOTO VOLVERREFRES   ; SI
;-----------------------------------FIN FUNCION RESFRESCAR


PARPADEO:
                BTFSC CENTISEGUNDO,6; ESTE BIT SE PRENDE A LOS 640 MSEG Y SE APAGA CUANDO SE CUMPLE EL SEGUNDO
                GOTO PARPADEAR      ; SI BIT6 DE CENTISEGUNDO ESTA PRENDIDO IR A PARPADEAR

                BTFSS PARPADEOBIT,7  ; ¿¿BIT 7=ON??  BIT 7 DE PARPADEO BIT SE PRENDE CUANDO EMPIEZA EL PARPADEO
                                                     ;Y SE APAGA CUANDO TERMINA    
                GOTO CICLOMOSTRAR        ;NO: VOLVER...

                                     ; FIN DE PARPADEO
                CALL MOSTRAR;      ; LA FUNCIÓN MOSTRAR ACTUALIZA LOS VECTORES SEGÚN OPCIONMOS
                                         ; EXCEPTO FUNCION0 QUE NO PARPADEA ASI QUE NO HAY PROBLEMA
                BCF PARPADEOBIT,7    ; LIMPIAR BIT 7 DE PARPADEOBIT: FIN DE PARPADEO
                GOTO CICLOMOSTRAR    ; VOLVER

PARPADEAR:      BTFSC PARPADEOBIT,7 ;  BIT7=OFF
                GOTO CICLOMOSTRAR   ; SI ESTA PRENDIDO ES PORQUE YA EMPEZO EL PARPADEO ENTONCES SE VUELVE

                BSF PARPADEOBIT,7  ; SI ESTA APAGADO HAY QUE PRENDERLO E INICIAR EL PARPADEO

PARPADEO_DER:   BTFSS PARPADEOBIT,1; SI ESTA PRENDIDO EL BIT 1 PARPADEAR DERECHO: PARPADEO DERECHO SIGNIFICA
                                    ; QUE LOS DOS DISPLAYS DE LA DERECHA INTERCAMBIA CICLICAMENTE SU VALOR POR OTRO
                GOTO  PARPADEO_IZQ
                
                MOVLW LETRADER   ;LETRADER (Y LETRAIZQ)DEBERÍA SER UN NUMERO DEL 0X0 AL 0XF 
                MOVWF PUNTERO_0
                MOVLW LETRADER
                MOVWF PUNTERO_1
 

PARPADEO_IZQ:   BTFSS PARPADEOBIT,2; SI ESTA PRENDIDO EL BIT 2 PARPADEAR IZQUIERDO: SIGNIFICA QUE LOS DOS DISPLAYS
                                   ; DE LA IZQUIERDA INTERCAMBIA CICLICAMENTE SU VALOR POR OTRO
                GOTO  CICLOMOSTRAR

                MOVLW LETRAIZQ
                MOVWF PUNTERO_2  ; NÓTESE QUE SI SE PRENDE EL BIT 1 Y 2 PARPADEAN LOS 4 DISPLAYS AL MISMO TIEMPO
                MOVLW LETRAIZQ
                MOVWF PUNTERO_3

                GOTO CICLOMOSTRAR








;**********************************************************************************************
;**********************************************************************************************
;>>>>>>>>>>>>>>INICIO DEL PROGRAMA AQUI!!!<<<<<<<<<<<<<<<<<<<<<<<<_____________________________
;----------------------------------------------------------------------------------------------

INICIO:         CLRF INTCON; DESACTIVAR INTERRUPCIONES
                
                BCF STATUS, IRP; LOS DATOS SUELEN ESTAR EN BANCO OO Ó O1 POR ESO SE ELIGE IRP=0 PARA DIRECCIONAMIENTO INDIRECTO
                BCF STATUS, RP1;
                BSF STATUS, RP0; BANCO 01  
                                                      ;---------CONFIGURACION PORTA EN BANCO 1
                MOVLW B'00010011'                           ;---CONVERSOR A/D
                MOVWF TRISA;  PORTA,5; PORTA,2 Y PORTA,3 COMO SALIDAS EL RESTO ENTRADAS PORTA,0 SERA ENTRADA ANALÓGICA 
                MOVLW B'00001110';
                MOVWF ADCON1; ADCON1:LEFT JUSTIFIED// RA0 ES ANALOGICO EL RESTO DIGITAL// RELOJ FOSC/16                  
                      
                
                CLRF TRISB; PORTB COMO SALIDA         ;----------CONFIGURACION PORTB Y PORTC EN BANCO 1
                MOVLW 0XFF;
                MOVWF TRISC; PORTC COMO ENTRADA

                
                                                     ;-----------CONFIGURACION TIMERS EN BANCO 1
                BCF OPTION_REG,5;  TIMER0 ACTIVADO CON FUENTE INTERNA SIN PRESCALER
                CLRF PIE1;                            
                BSF PIE1,2; HABILITAR INTERRUPCION POR CCP DE TIMER1  

                


                
                BCF STATUS, RP0; BANCO 00
                                    
                                   ;---------CONFIGURACION PORTA EN BANCO 0
                MOVLW B'01000000'  ; ADCON0: 8TOSC--- CHANNEL 0--- SIN OPERACION--- CONVERSOR MODO: APAGADO!
                MOVWF ADCON0;

                                    ;----------CONFIGURACION DE PORTB EN BANCO 0
                CLRF PORTB; SALIDA PORTB=0
                


                ; CONFIGURACION DEL CCP PARA TIMER1

                MOVLW B'00001011'
                MOVWF CCP1CON;  ; MODO SPECIAL EVENT TRIGGER:CUANDO TMR1 LLEGA A CCPR1 RESETEA E INTERRUMPE
                MOVLW 0X10;     0X2710 CICLOS=10000US=0.01SEG
                MOVWF CCPR1L;    CARGAR CCPR1 PARA QUE INTERRUMPA CADA 0.01 SEGUNDO
                MOVLW 0X27;
                MOVWF CCPR1H; 
                CLRF T1CON;    
                BSF T1CON,0;  SIN PRESCALER-> TME1 1:1, TIMER1 PRENDIDO, CLOCK INTERNO                     
                CLRF PIR1; TODAS LAS BANDERAS INTERRUPCION PIR1 APAGADAS



                CLRF CENTISEGUNDO ; LIMPIAR VARIABLES TIEMPO
                CLRF SEGUNDO
                CLRF DECASEGUNDO
                CLRF MINUTO
                CLRF DECAMINUTO
                CLRF HORA
                CLRF DECAHORA
                CLRF DIA
                CLRF MINUTO_A
                CLRF DECAMINUTO_A
                CLRF HORA_A
                CLRF DECAHORA_A
                CLRF BITFLAGS
                CLRF ALARMAFLAG

                MOVLW 0X07
                MOVWF DESIMA_T; X DEFECTO 700mV PARA EL MAXIMA TEMPERATURA REPRESENTA 70 GRADOS
                CLRF CENTESIMA_T
                CLRF UNIDAD_T
                CLRF ALARMA_T
                CLRF DESIMA_A
                CLRF CENTESIMA_A
                CLRF UNIDAD_A

                MOVLW 0X01        ; PROCESO 1= NOPROCESO
                MOVWF CRONOPROC
                MOVWF PROCESO

                BCF PORTA,2
                BCF PORTA,3       ; CALENTADOR, LINTERNA Y MOTOR APAGADOS
                BCF PORTA,5



                CLRF PETICION ; PREPARANDO VARIABLES DE LA INTERFAZ
                CLRF FUNCION
                CLRF MENU
                BSF MENU,0 ; MENU=1
                CLRF DECAMENU
                CLRF OPCIONMOS; OPCIONMOS=0
                CLRF PARPADEOBIT;
                MOVLW 0X0A
                MOVWF LETRAMENU; CODIGOS PARA MOSTRAR EN EL DISPLAY

                MOVLW 0XFF    ; SENSO Y BOTON SE ASUMEN QUE EMPIEZAN EN ESTADOS NEUTROS
                MOVWF SENSO
                BCF SENSO,5
                MOVWF BOTON    

                
                
                CALL MOSTRAR



                CLRF TMR1H   ; LIMPIAR TIMERS
                CLRF TMR1L
                CLRF TMR0

                MOVLW B'11100000' ;ACTIVACION INTERRUPCIONES (TIMER 1 Y TIMER0)
                MOVWF INTCON
;-----------------------------------------------------------
;-----------------------------------------------------------
     
  ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BUCLE PRINCIPAL<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>

BUCLE:          GOTO PROCESO_ACTUAL; EN DIRECCION FLASH 0X0700



VERCONVERSOR:   BTFSC ADCON0,0; VER SI ESTA ENCENDIDO EL CONVERSOR
                GOTO CONVERSION;

VERALARMA:      BTFSC ALARMAFLAG,0; VER SI ESTA ENCENDIDA LA ALARMA
                GOTO REVISARHORA;



VERBOTON:       MOVF PORTC,0   
                MOVWF SENSO; DEBE ESTAR CONSTANTEMENTE ACTUALIZADO 
                SUBLW B'11011111';CHEQUEAR SI PORTC ES DISTINTO DE 11011111  
                BTFSS STATUS,Z
                GOTO VERIFICAR_ON; SI ES DISTINTO ES PORQUE SE APRETO UN BOTON O SE SENSO ALGO DISTINTO AL ESTADO DE REPOSO              
             
                BTFSC PETICION,6;
                GOTO VERIFICAR_OFF   ; HASTA QUE EL BOTÓN NO SE SUELTE NO HABRÁ PETICIÓN

                
                
VERFUNCION:     GOTO FUNCIONACTUAL; EN FUNCIONACTUAL SE PREGUNTA QUE TAREA SE DEBE REALIZAR EN ESE MOMENTO
              
                           



;---------------------------------------------
;---------------------------------------------




;------------------------------FUNCION DE RETARDO GENERAL
WAIT:           MOVLW 0X7F;  W=0X7F

WAIT_PARAMETRO: MOVWF RETARDO; RETARDO=W  SI SE CARGA PREVIAMENTE A W SE HARAN W CICLOS

ESPERA:         NOP                ;SE HARAN 4*CICLOS DE INSTRUCCIÓN POR CICLO DE RETARDO
                DECFSZ RETARDO
                GOTO ESPERA

                RETURN
;---------------------------FUNCION DE ENTRADAS EN PUERTOC

VERIFICAR_ON:   CALL WAIT      ;ESPERAR
                                  ; NOTA: NO OLVIDAR QUE LOS BOTONES SON TIPO PULL UP
                                  ; CUANDO ESTA APRETADO ES CERO Y CUANDO ESTA SUELTO ES UNO
                              
                MOVF PORTC,0     ; VER PORTC
                MOVWF BOTON       ; GUARDAR EL VALOR EN "BOTON"
                SUBLW B'11011111'
                BTFSC STATUS,Z    ; VERIFICAR QUE ESTE FUERA DEL ESTADO DE REPOSO
                GOTO VERFUNCION


                CALL WAIT       ; ESPERAR

                MOVF PORTC,0
                SUBWF BOTON,0
                BTFSS STATUS,Z     ;VERIFICAR QUE SE MANTIENE EL VALOR DE PORTC CON LO GUARDADO
                GOTO VERFUNCION

       

                MOVLW B'11110000'  ; AQUI SE GUARDAN LOS 4 VALORES DE LOS SENSORES. 1:DESACTIVADO//0:ACTIVADO
                ANDWF BOTON,0  
                MOVWF SENSO

                BTFSC PETICION,6;
                GOTO VERIFICAR_OFF   ; HASTA QUE EL BOTÓN NO SE SUELTE NO HARÁ EFECTO
                

                MOVLW B'00001111'  
                ANDWF BOTON,0
                SUBLW B'00001111'         
                BTFSC STATUS,Z   ; ¿HAY CAMBIO EN LOS PRIMEROS 4 BITS?
                GOTO  VERFUNCION;      ; NO: IR A BUCLE


                BTFSS BOTON,1      ; SEGUN EL BOTON QUE SE APRIETE SE LLENA OPCION
                MOVLW 0X01         ; SI SE APRIETA MAS DE UNO. SOLO UNO ES REGISTRADO
                BTFSS BOTON,2      ; LA PRIORIDAD ES RC0, RC3, RC2, RC1
                MOVLW 0X02
                BTFSS BOTON,3
                MOVLW 0X03
                BTFSS BOTON,0
                MOVLW 0X00
                MOVWF PETICION;
                
                BSF PETICION,6;      ACTIVAR BIT DE VERIFICACION DE APAGADO(OFF) DE BOTON.                
                GOTO VERFUNCION;
                
 ;--------------------------------------------------------------------------      
         
VERIFICAR_OFF:  MOVLW B'00001111'  ;VERIFICAR QUE PORTC ESTE SIN APRETAR
                ANDWF PORTC,0
                SUBLW B'00001111'
                BTFSS STATUS,Z
                GOTO VERFUNCION ; HASTA  QUE NO SE SUELTEN LOS BOTONES LA PETICIÓN NO ES REALIZADA
                
                CALL WAIT         

                MOVLW B'00001111'  ;VERIFICAR QUE PORTC SIGA SIN APRETAR
                ANDWF PORTC,0
                SUBLW B'00001111'
                BTFSS STATUS,Z
                GOTO VERFUNCION ; SINO VOLVER AL BUCLE PRINCIPAL            


                BCF PETICION,6;      DESACTIVAR BIT DE VERIFICAR OFF       
                BSF PETICION,7;      ACTIVAR BIT DE PETICIÓN 
                GOTO VERFUNCION ;    EL BOTON HA SIDO APRETADO CORRECTAMENTE, HAY UNA PETICION PENDIENTE!
;--------------------------------------------


REVISARHORA:    MOVF DECAHORA_A,0
                SUBWF DECAHORA,0      ; ¿DECAHORA=DECAHORA_A?
                BTFSS STATUS,Z
                GOTO VERBOTON         ; NO:


                MOVF HORA_A,0         ;SI
                SUBWF HORA,0
                BTFSS STATUS,Z;         ¿HORA=HORA_A?
                GOTO VERBOTON          ;NO

                MOVF DECAMINUTO_A,0    ;SI
                SUBWF DECAMINUTO,0     ;¿DECAMINUTO=DECAMINUTO_A?
                BTFSS STATUS,Z
                GOTO VERBOTON          ;NO

                MOVF MINUTO_A,0        ;SI
                SUBWF MINUTO,0         ;¿DECAMINUTO=DECAMINUTO_A?
                BTFSS STATUS,Z
                GOTO VERBOTON          ;NO
                
                                       ;SI

                BCF ALARMAFLAG,0; SE APAGA LA ALARMA
                
                
                MOVF UNIDAD_A,0        ; UNIDAD_T=UNIDAD_A// DEIMA_T=DESIMA_A//CENTESIMA_T=CENTESIMA_A
                MOVWF UNIDAD_T
                MOVF DESIMA_A,0
                MOVWF DESIMA_T
                MOVF CENTESIMA_A,0
                MOVWF CENTESIMA_T

                MOVLW .26  ;  FUNCION = ALARMA TENSION
                MOVWF FUNCION
                GOTO VERFUNCION
;--------------------------------------


;----------------DIVIDIR

DIV:           CLRF ARIT_AUX;  WREG= NUM1 /NUM2(DIVISION ENTERA)..Resto en NUM1
               MOVF NUM2,0;    

BUCLEDIV:      INCF ARIT_AUX
               SUBWF NUM1,1
               BTFSC STATUS,C;
               GOTO BUCLEDIV

               ADDWF NUM1,1               
               DECF ARIT_AUX
               MOVF ARIT_AUX,0

               RETURN




;-------------------------------------------------------------------------*************************************************************************************************************************FUNCION MOSTRAR
;-----------MOSTRAR: FUNCION QUE DEBE ADAPTARSE AL DISPOSITIVO A USAR PARA VISUALIZAR LAS SALIDAS----
                            ;ESTE CASO ES PARA 4 DISPLAYS 7 SEGMENTOS

                ORG 0X0150  ;
MOSTRAR:        
                MOVF PCLATH,0
                MOVWF PCLATHAUX1;  SE ALMACENA EL PCLATH ACTUAL

                CLRF PCLATH;           
                BSF PCLATH,0; PCLATH=1                

                MOVF OPCIONMOS,0 ; WREG=OPCIONMOS.. OPCIONMOS ES LA VARIABLE QUE INDICA QUE DEBE APARECER EN PANTALLA

                ADDWF PCL,1   ;  SEGUN LO QUE SEA OPCIONMOS SE ELIGE 
                GOTO MOSTRAR0   
                GOTO MOSTRAR1
                GOTO MOSTRAR2
                GOTO MOSTRAR3
                GOTO MOSTRAR4
                GOTO MOSTRAR5
                GOTO MOSTRAR6
                GOTO MOSTRAR7
                GOTO MOSTRAR8
                GOTO MOSTRAR9

;CARGAR PUNTERO_0, PUNTERO_1, PUNTERO_2, PUNTERO_3 QUE SON LOS QUE UTILIZA EL REFRESCO DEL DISPLAY


;ATENCION!!: ES IMPORTANTE QUE LOS VALORES SEAN DEL 0X00 AL 0X0F YA QUE NO HAY NINGUN FILTRO,
; OTRO VALOR PUEDE HACER QUE SE PRENDA MAS DE UN DISPLAY POR VEZ



MOSTRAR0:       MOVLW MENU          ; OPCIONMOS=0  MOSTRAR MENU      
                MOVWF PUNTERO_0
                MOVLW DECAMENU
                MOVWF PUNTERO_1
                MOVLW LETRAMENU
                MOVWF PUNTERO_2
                MOVLW LETRAMENU
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR

MOSTRAR1:       MOVLW MINUTO        ; OPCIONMOS=1  MOSTRAR HORAS Y MINUTOS      
                MOVWF PUNTERO_0
                MOVLW DECAMINUTO
                MOVWF PUNTERO_1
                MOVLW  HORA
                MOVWF PUNTERO_2
                MOVLW DECAHORA
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR
                
MOSTRAR2:       MOVLW SEGUNDO   ;  OPCIONMOS=2     MOSTRAR MINUTOS Y SEGUNDOS
                MOVWF PUNTERO_0
                MOVLW DECASEGUNDO
                MOVWF PUNTERO_1
                MOVLW MINUTO
                MOVWF PUNTERO_2
                MOVLW DECAMINUTO
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR

MOSTRAR3:       MOVLW MINUTO_A        ; OPCIONMOS=3  MOSTRAR HORA DE ALARMA
                MOVWF PUNTERO_0
                MOVLW DECAMINUTO_A
                MOVWF PUNTERO_1
                MOVLW HORA_A
                MOVWF PUNTERO_2
                MOVLW DECAHORA_A
                MOVWF PUNTERO_3        
                GOTO FINMOSTRAR
;---------------------------------------
MOSTRAR4:       MOVLW ALARMAFLAG
                MOVWF PUNTERO_0
                MOVLW LETRAIZQ
                MOVWF PUNTERO_1     ; ACTIVAR ALARMA SI/NO
                MOVLW LETRAIZQ
                MOVWF PUNTERO_2
                MOVLW LETRAIZQ 
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR

MOSTRAR5:       MOVLW PROCESO
                MOVWF PUNTERO_0
                MOVLW LETRADER  ;   ALARMA SONANDO!!
                MOVWF PUNTERO_1
                MOVLW LETRADER
                MOVWF PUNTERO_2
                MOVLW LETRADER
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR

MOSTRAR6:       MOVLW MILESIMA  ; MOSTRAR TENSION
                MOVWF PUNTERO_0
                MOVLW CENTESIMA
                MOVWF PUNTERO_1
                MOVLW DESIMA
                MOVWF PUNTERO_2
                MOVLW LETRAIZQ
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR;

MOSTRAR7:       MOVLW LETRADER ; MOSTRAR TENSION FINAL
                MOVWF PUNTERO_0
                MOVLW CENTESIMA_T
                MOVWF PUNTERO_1
                MOVLW DESIMA_T
                MOVWF PUNTERO_2
                MOVLW LETRADER
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR;

MOSTRAR8:       MOVLW LETRADER ; MOSTRAR TENSION FINAL PARA ALARMA RELOJ
                MOVWF PUNTERO_0
                MOVLW CENTESIMA_A
                MOVWF PUNTERO_1
                MOVLW DESIMA_A
                MOVWF PUNTERO_2
                MOVLW LETRAIZQ
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR;

MOSTRAR9:       MOVLW LETRADER ; ERRORES DE PROCESO
                MOVWF PUNTERO_0
                MOVLW LETRADER
                MOVWF PUNTERO_1
                MOVLW ERRORNUM
                MOVWF PUNTERO_2
                MOVLW LETRADER
                MOVWF PUNTERO_3
                GOTO FINMOSTRAR;





FINMOSTRAR:     MOVF PCLATHAUX1,0
                MOVWF PCLATH
                RETURN



;-------------------------------








;------------------------------------------------********************************************************************
;**************************************************************************************FUNCIONES PRINCIPALES
               ORG 0X01FE  
FUNCIONACTUAL:                ; LAS FUNCIONES DE USUARIO (FUNCIONES PARA EL USUARIO) QUE ESTEN ENTRE LA MEMORIA 0X0200 HASTA 0X02FF
                          ; NO NECESITAN MODIFICAR EL PCLATH. 
                              ; LAS SUBFUNCIONES DE LAS FUNCIONES SE ENCUENTRAN A PARTIR DE LA MEMORIA 0X0400.
                              ; EL REGISTRO PCLATH COMPLEMENTA AL PCL.
                          
        
                            
                MOVLW 0X02
                MOVWF PCLATH ; PCLATH ES 0X02

                MOVF FUNCION,0;   
                ADDWF PCL,1

                GOTO FUNCION0;   MENU INICIAL
                GOTO FUNCION1;   HORA 
                GOTO FUNCION2;   ALARMA   (CABIAR HORA DE ALARMA)
                GOTO FUNCION3;   TENSION ACTUAL/ 
                GOTO FUNCION4;   SETEAR TENSION FINAL Y LUEGO ACTIVAR ALARMATENSION
                GOTO FUNCION5;   ABRIR/CERRAR  
                NOP;6            
                NOP;7            RESERVADAS PARA FUTURAS FUNCIONES
                NOP;8
                NOP;9
                NOP;10
                NOP;11
                NOP;12
                NOP;13
                NOP;14
                ;-------------------SUBFUNCIONES
                GOTO CAMBIARHORA;15 ; DE FUNCION1  
                GOTO CAMBIARMIN;16
                GOTO CAMBIARMINALARM;17 DE FUNCION2
                GOTO CAMBDESIMA_A;18
                GOTO CAMBCENTESIMA_A;19  
                GOTO ACTIVARALARMA;20
                GOTO CAMBCENTESIMA_T;21 DE FUNCION4             
                NOP;GOTO ACTIVAR_T;22 (OBSOLETA)
                NOP;23
                NOP;24 
                GOTO ALARMA;25  DE FUNCION4 Y ALARMA PRINCIPAL
                GOTO ALARMATENSION;26  DE FUNCION4
                NOP;27
                NOP;28 
                NOP;29
                GOTO ERRORDEPROCESO;30  GENERAL DE PROCESO



                CLRF FUNCION;
                GOTO BUCLE                



;-------------------------------FUNCION=0   MENU INICIAL

FUNCION0:    
                 MOVLW 0X00
                 SUBWF OPCIONMOS,0;    VERIFICAR QUE OPCIONMOS SEA EL CORRESPONDIENTE AL DE LA FUNCION ACTUAL
                 BTFSC STATUS,Z
                 GOTO F0PETICION

                 CLRF PARPADEOBIT
                 CLRF OPCIONMOS       ; OPCIONMOS=0 (MOSTRAR MENU)
                 CALL MOSTRAR

F0PETICION:      BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE;        VOLVER AL BUCLE PRINCIPAL

                 BCF PETICION,7; LIMPIAR BIT DE PETICION
             
                 MOVF PETICION,0

                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 GOTO BUCLE;                 PETICION=0 NO HACE NADA
                 GOTO RESTARMENU            ;PETICION=1  SUBE OPCION DEL MENU
                 GOTO SUMARMENU             ;PETICION=2  BAJA OPCION DEL MENU
                 MOVF MENU,0;                PETICION=3 IR A LA FUNCION MOSTRADA POR EL MENU
                 MOVWF FUNCION              ; FUNCION=MENU
                 GOTO BUCLE





;------------------------------FUNCION=1      VER HORA
FUNCION1:        MOVLW 0X01
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X01 (MOSTRAR HORA Y MINUTOS)
                 BTFSC STATUS,Z
                 GOTO F1PETICION

                 CLRF PARPADEOBIT
                 MOVLW 0X02
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X02 (MOSTRAR MINUTOS Y SEGUNDOS)
                 BTFSC STATUS,Z
                 GOTO F1PETICION
                 GOTO F1_1
                
F1PETICION:      BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF PETICION,7; LIMPIAR BIT DE PETICION

             
                 MOVF PETICION,0  ; ¿PETICION?
                 ADDWF PCL, 1

                 GOTO F1_0       ;=0: VOLVER A LA FUNCION0(VOLVER AL MENU PRINCIPAL)
                 GOTO F1_1       ;=1: VER HORAS Y MINUTOS
                 GOTO F1_2       ;=2: VER MINUTOS Y SEGUNDOS

                 MOVLW .15       ;=3: IR A FUNCION15 (CAMBIAR HORA)/ FUNCION=.15
                 CLRF OPCIONMOS; BORRAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION TENGA QUE ACTUALIZARLA
                 MOVWF FUNCION
                 GOTO BUCLE



;---------------------------- FUNCION=15        CAMBIAR HORA
CAMBIARHORA: 
                 MOVLW 0X01
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X01
                 BTFSC STATUS,Z
                 GOTO F15PETICION

                 MOVLW 0X0F
                 MOVWF LETRAIZQ
                 MOVLW B'00000101'; ACTIVAR PARPADEO IZQUIERDO
                 MOVWF PARPADEOBIT

                 GOTO F1_1
             
F15PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF INTCON,7; DESHABILITAR INTERRUCIONES
 
                 BCF PETICION,7; LIMPIAR BIT DE PETICION
             
                 MOVF PETICION,0


                 ADDWF PCL, 1
                 GOTO F15VOLVER;VOLVER A FUNCION1   
                 GOTO RESTAHOR; DECREMENTAR HORA
                 GOTO SUMAHOR; INCREMENTAR HORA

                 MOVLW .16     ; IIR A FUNCION CAMBIAR MINUTO (FUNCION=16)
                 MOVWF FUNCION
                 BSF INTCON,7 ;HABILITAR INTERRUPCION
                 CLRF OPCIONMOS; BORRAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION TENGA QUE ACTUALIZARLA
                 GOTO BUCLE
                     





;------------------------- FUNCION=16  CAMBIAR MINUTOS
CAMBIARMIN:      
                 MOVLW 0X01
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X01
                 BTFSC STATUS,Z
                 GOTO F16PETICION


                 MOVLW 0X0F
                 MOVWF LETRADER
                 MOVLW B'00000011'; ACTIVAR PARPADEO DERECHO
                 MOVWF PARPADEOBIT
                 GOTO F1_1
             
F16PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF INTCON,7; DESHABILITAR INTERRUCIONES
 
                 BCF PETICION,7; LIMPIAR BIT DE PETICION


                 MOVF PETICION,0
            

                 ADDWF PCL, 1
             
                 GOTO F15VOLVER;VOLVER A FUNCION1   
                 GOTO RESTAMIN; DECREMENTAR MINUTO
                 GOTO SUMAMIN; INCREMENTAR MINUTO
                 MOVLW .15     ;IR A FUNCION CAMBIAR HORA (FUNCION=15)
                 MOVWF FUNCION
                 CLRF OPCIONMOS;  BORRAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION TENGA QUE ACTUALIZARLA
                 BSF INTCON,7 ;HABILITAR INTERRUPCION
                 GOTO BUCLE                     




;----------------------FUNCION=2 CAMBIAR HORA DE ALARMA

FUNCION2:        MOVLW 0X03
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X03
                 BTFSC STATUS,Z
                 GOTO F2PETICION


                 MOVLW 0X0D
                 MOVWF LETRADER
                 MOVLW 0X0F
                 MOVWF LETRAIZQ

                 MOVLW B'00000111'; ACTIVAR PARPADEO DERECHA 
                 MOVWF PARPADEOBIT
                 GOTO F2_A
             
F2PETICION:      BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE


                 BCF PETICION,7; LIMPIAR BIT DE PETICION
             
                 MOVF PETICION,0


                 ADDWF PCL, 1
                 GOTO F2VOLVER_A;VOLVER A FUNCION0   
                 GOTO RESTAHOR_A; DECREMENTAR HORA
                 GOTO SUMAHOR_A; INCREMENTAR HORA

                 MOVLW .17     ; IR A FUNCION CAMBIAR MINUTO ALARMA (FUNCION=17)
                 MOVWF FUNCION
                 CLRF OPCIONMOS; BORRAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION TENGA QUE ACTUALIZARLA
                 GOTO BUCLE


;----------------------FUNCION=17  CAMBIAR MINUTOS DE ALARMA
CAMBIARMINALARM:  
                 MOVLW 0X03
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X03
                 BTFSC STATUS,Z
                 GOTO F17PETICION

                 MOVLW 0X0D
                 MOVWF LETRAIZQ
                 MOVLW 0X0F 
                 MOVWF LETRADER
                 MOVLW B'00000111'; ACTIVAR PARPADEO IZQUIERDO
                 MOVWF PARPADEOBIT
                 GOTO F2_A
             
F17PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

 
                 BCF PETICION,7; LIMPIAR BIT DE PETICION


                 MOVF PETICION,0
            

                 ADDWF PCL, 1
             
                 GOTO F18VOLVER;VOLVER A FUNCION2(CAMBIAR HORA ALARMA)   
                 GOTO RESTAMIN_A; DECREMENTAR MINUTO
                 GOTO SUMAMIN_A; INCREMENTAR MINUTO
                 MOVLW .18     ;IR A FUNCION CAMBIAR TENSION_A TENSION PARA LA ALARMA (FUNCION= 18)
                 MOVWF FUNCION
                 CLRF OPCIONMOS; BORRAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION TENGA QUE ACTUALIZARLA

                 GOTO BUCLE                     

;--------------------------FUNCION=20  ACTIVAR ALARMA
ACTIVARALARMA:
    
                 MOVLW 0X04
                 SUBWF OPCIONMOS,0;    ¿eS OPCIONMOS=4?
                 BTFSC STATUS,Z
                 GOTO F20PETICION        ;SI: IR A F20PETICION 

                 CLRF PARPADEOBIT
                 MOVLW 0X0D
                 MOVWF LETRAIZQ
                 MOVLW 0X04             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=04 (MOSTRAR ACTIVACION ALARMA)
                 CALL MOSTRAR

F20PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE;        VOLVER AL BUCLE PRINCIPAL

                 BCF PETICION,7; LIMPIAR BIT DE PETICION
             
                 MOVF PETICION,0
                 ADDWF PETICION,0

                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
                             

                 CLRF FUNCION;               ;PETICION=0   VOLVER A MENU
                 GOTO BUCLE;
                 
                 BCF ALARMAFLAG,0             ;PETICION=1  APAGA ALARMAFLAG
                 GOTO BUCLE

                 BSF ALARMAFLAG,0             ;PETICION=2  PRENDE ALARMAFLAG
                 GOTO BUCLE

                 MOVLW 0X02                  ;PETICION=3 IR A LA FUNCION2
                 MOVWF FUNCION               ; FUNCION=MENU
                 GOTO BUCLE

;-------------------------------------------



;--------------------------FUNCION=3:   VERSION ANALOGICA A DIGITAL:

FUNCION3:        
                 MOVLW 0X06
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X06
                 BTFSC STATUS,Z
                 GOTO F3PETICION
                 
                 BSF ADCON0,0; HABILITAR CONVERSIONES
                 CLRF ADPROMH
                 CLRF ADPROML

                 MOVLW 0X0C
                 MOVWF LETRAIZQ
                 CLRF PARPADEOBIT
                 MOVLW 0X06             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=06 (MOSTRAR TENSION ACTUAL)
                 CALL MOSTRAR
             
F3PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE


                 BCF PETICION,7; LIMPIAR BIT DE PETICION
                 MOVF PETICION,0
                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 NOP;    0:VOLVER AL MENU
                 NOP;   1:VOLVER AL MENU
                 GOTO F3VOLVER;  2:VOLVER AL MENU
                 GOTO F3COMPLETO; 3: VER LA PANTALLA COMPLETA

F3VOLVER:        CLRF FUNCION; IR A MENU

                 BCF ADCON0,0; DESHABILITAR CONVERSIONES
                 GOTO BUCLE                     


;---------------------------FUNCION=4  TENSION PARA ALARMATENSION  CAMBIAR UNIDAD Y DESIMA
FUNCION4:        
                 MOVLW 0X07
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X07
                 BTFSC STATUS,Z
                 GOTO F4PETICION    ; SI: IR A F4PETICION
                 
                 MOVLW 0X0F         ;NO: LETRAIZQ=LETRADER=0XF, PARPADEOBIT=00000101, OPCIONMOS=7, 
                 MOVWF LETRAIZQ
                 MOVWF LETRADER 
                 MOVLW B'00000101'
                 MOVWF PARPADEOBIT
                 MOVLW 0X07             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=07 (MOSTRAR TENSION PARA ALARMATENSION)
                 CALL MOSTRAR
             
F4PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE


                 BCF PETICION,7; LIMPIAR BIT DE PETICION

                 MOVF PETICION,0
                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 GOTO F4VOLVER;    0:VOLVER AL MENU
                 GOTO RESTARDEC_T; 1:INCREMENTAR DESIMA_T
                 GOTO SUMARDEC_T;  2:DECREMENTAR DESIMA_T
                
                 MOVLW .21           
                 MOVWF FUNCION    ;3:FUNCIÓN=21
                 CLRF OPCIONMOS   ; LIMPIAR OPCIONMOS PARA QUE LA SIGUIENTE FUNCION DEBA ACTUALIZARLA
                 GOTO BUCLE
;---------------------------

;--------------------------------FUNCION=21 CAMBIAR CENTESIMA PARA ALARMATENSION
CAMBCENTESIMA_T:        
                 MOVLW 0X07
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X07
                 BTFSC STATUS,Z
                 GOTO F21PETICION
                 
                 MOVLW 0X0F        ;NO: LETRAIZQ=LETRADER=0XF, PARPADEOBIT=00000011, OPCIONMOS=7,
                 MOVWF LETRADER 
                 MOVLW B'00000011'
                 MOVWF PARPADEOBIT
                 MOVLW 0X07             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=07 (MOSTRAR TENSION PARA ALARMATENSION)
                 CALL MOSTRAR


F21PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF PETICION,7; LIMPIAR BIT DE PETICION
                
                 MOVLW 0X03
                 MOVWF PCLATH


                 MOVF PETICION,0
                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 GOTO F4VOLVER;    0:VOLVER AL MENU
                 GOTO RESTARCEN_T; 1:DECREMENTAR CENTESIMA_T
                 GOTO SUMARCEN_T;  2:INCREMENTAR CENTESIMA_T
                
                 MOVLW .26           
                 MOVWF FUNCION    ;3: VOLVER A FUNCION=26
                 GOTO BUCLE







;--------------------------FUNCION=26 VER  ALARMA DE TENSION


ALARMATENSION:     
                 MOVLW 0X06
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X06
                 BTFSC STATUS,Z
                 GOTO F26CHECK
                 
                 BSF ADCON0,0; HABILITAR CONVERSIONES
                 BSF ALARMA_T,0; PRENDER BIT DE ALARMA POR TENSION
                 CLRF ADPROMH
                 CLRF ADPROML;  BORRAR ADPROML YA QUE GUARDA EL PROMEDIO DE LA ULTIMA CONVERSION

                 
                 MOVLW 0X03
                 MOVWF PROCESO; CALENTAR
 
                 MOVLW 0X0F
                 MOVWF LETRAIZQ
                 CLRF PARPADEOBIT
                 MOVLW 0X06             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=06 (MOSTRAR TENSION/TEMPERATURA ACTUAL)
                 CALL MOSTRAR
             
F26CHECK:        BTFSS ALARMA_T,7; ESTE BIT SE ACTIVA CUANDO EL VALOR DE TENSION ES SUPERIOR O IGUAL AL DEL SETEADO
                 GOTO F26PETICION 
                 
                
                 BCF ADCON0,0; DESHABILITAR CONVERSIONES
                 BCF PORTA,3; APAGAR CALENTADOR
                 MOVLW 0X01;
                 MOVWF PROCESO; TERMINAR PROCESO                 

                 MOVLW .25
                 MOVWF FUNCION
                 CLRF ALARMA_T; APARGAR BITS DE ALARMA POR TENSION
                                  
                 GOTO BUCLE         




F26PETICION      BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE


                 BCF PETICION,7; LIMPIAR BIT DE PETICION

                 BCF ADCON0,0; DESHABILITAR CONVERSIONES
                 
                 BCF PORTA,3; APAGAR CALENTADOR
                 MOVLW 0X01;
                 MOVWF PROCESO; TERMINAR PROCESO                 


                 MOVLW 0X04                              
                 MOVWF FUNCION               ; FUNCION=4
                 CLRF ALARMA_T
                 GOTO BUCLE        



 ;-------------------------FUNCION=25 ALARMA ACTIVADA!!!!!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
ALARMA:          MOVLW 0X05
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X05
                 BTFSC STATUS,Z
                 GOTO F25PETICION
                 

                 MOVLW 0X0C
                 MOVWF LETRADER                 
                 CLRF PARPADEOBIT
                 MOVLW 0X05
                 MOVWF OPCIONMOS
                 CALL MOSTRAR
                 MOVLW 0X04
                 MOVWF PROCESO; PROCESO=4                PRENDER LINTERNA PARA LUEGO ABRIR VALVULA


             
F25PETICION:     MOVLW 0X00
                 SUBWF PROCESO,0
                 BTFSC STATUS,Z;      ¿(PROCESO=0)? 
                 CLRF FUNCION         ;SI => FUNCION=00 (SALIR DE ALARMA)
                 
                                      ;NO:....   
                 BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF PETICION,7; LIMPIAR PETICION

                 CLRF PROCESO; PROCESO=0
                 
                 CLRF FUNCION

                 GOTO BUCLE
               
;---------------------------------FUNCION=18  CAMBIAR DESIMA Y UNIDAD PARA ALARMA TENSION CON ALARMA RELOJ
CAMBDESIMA_A:        
                 MOVLW 0X08
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X08
                 BTFSC STATUS,Z
                 GOTO F18PETICION    ; SI: IR A F18PETICION
                 
                 MOVLW 0X0D
                 MOVWF LETRADER
                 MOVLW 0X0F
                 MOVWF LETRAIZQ
                 MOVLW B'00000101'
                 MOVWF PARPADEOBIT
                 MOVLW 0X08             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=08 (MOSTRAR TENSION PARA ALARMATENSION)
                 CALL MOSTRAR
             
F18PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE


                 BCF PETICION,7; LIMPIAR BIT DE PETICION

                 MOVLW 0X03
                 MOVWF PCLATH

                 MOVF PETICION,0
                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 GOTO F18VOLVER;   VOLVER A FUNCION2
                 GOTO RESTARDEC_A;
                 GOTO SUMARDEC_A; 
                
                 MOVLW .19           ;IR A CAMBCENTESIMA_A
                 MOVWF FUNCION
                 CLRF OPCIONMOS
                 GOTO BUCLE
;---------------------------

;--------------------------------FUNCION=19 CAMBIAR CENTESIMA PARA ALARMATENSION CON ALARMA RELOJ!!
CAMBCENTESIMA_A:        
                 MOVLW 0X08
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X08
                 BTFSC STATUS,Z
                 GOTO F19PETICION
                 
                 MOVLW 0X0F
                 MOVWF LETRADER
                 MOVLW 0X0D
                 MOVWF LETRAIZQ
 
                 MOVLW B'00000011'
                 MOVWF PARPADEOBIT
                 MOVLW 0X08             
                 MOVWF OPCIONMOS       ;NO: OPCIONMOS=08 (MOSTRAR TENSION PARA ALARMATENSION)
                 CALL MOSTRAR

F19PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF PETICION,7; LIMPIAR BIT DE PETICION

                 MOVLW 0X03
                 MOVWF PCLATH

                 MOVF PETICION,0
                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 GOTO F18VOLVER;   VOLVER A FUNCION2
                 GOTO RESTARCEN_A;
                 GOTO SUMARCEN_A; 
                
                 MOVLW .20;  IR A ACTIVAR ALARMA RELOJ         
                 MOVWF FUNCION
                 GOTO BUCLE





;-----------------------------------FUNCION=5            ABRIR/CERRAR VALVULA



FUNCION5:        MOVLW 0X05
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X05
                 BTFSC STATUS,Z
                 GOTO F5PETICION
                 

                 MOVLW 0X0B
                 MOVWF LETRADER                 
                 CLRF PARPADEOBIT
                 MOVLW 0X05
                 MOVWF OPCIONMOS
                 CALL MOSTRAR

             
F5PETICION:      BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE

                 BCF PETICION,7; LIMPIAR BIT DE PETICION

                 MOVLW 0X03   ;  MEMORIA A LA ALTURA DEL 0X0300
                 MOVWF PCLATH

                 MOVF PETICION,0
                 ADDWF PETICION,0  ; SALTAR DE ADOS

                 ADDWF PCL,1 ;                ¿¿¿QUE HACER???>>>>>>
             
                 CLRF FUNCION
                 GOTO BUCLE;  PETICON=0: VOLVER A MENU
                 
 
                 CLRF PROCESO;  PETICON=1: PROCESO=0 (CERRAR VALVULA)
                 GOTO BUCLE;

                 CLRF PROCESO;  PETICON=2: PROCESO=0 (CERRAR VALVULA)
                 GOTO BUCLE;

                 MOVLW 0X04;      PETICION=3: PROCESO=4 (PREPARAR LINTERNA PARA ABRIR Y LUEGO HACERLO )
                 MOVWF PROCESO                


                 GOTO BUCLE

;-------------------------------FUNCION=30  ERROR DE PROCESO
ERRORDEPROCESO:  MOVLW 0X09
                 SUBWF OPCIONMOS,0;   CHEQUEAR SI OPCIONMOS ES 0X01
                 BTFSC STATUS,Z
                 GOTO F30PETICION

                 BCF ADCON0,0; DESHABILITAR CONVERSIONES
                 
                 MOVLW 0XE
                 MOVWF LETRADER
                 CLRF PARPADEOBIT
                 MOVLW 0X09
                 MOVWF OPCIONMOS
                 CALL MOSTRAR

             
F30PETICION:     BTFSS PETICION,7; VER SI HAY PETICION
                 GOTO BUCLE
                 BCF PETICION,7; LIMPIAR PETICION
                 
                 CLRF FUNCION
                 GOTO BUCLE










;.............***************************************...................................................**



;----...........**************************************************...................................
;*************************************************************************************FUNCIONES AUXILIARES







;-----------------------------------------------------.
;---------------------- CODIGOS AUXILIARES DE LAS FUNCIONES
                  ORG 0X400


;---------------------FUNCION=0 FUNCION0 AUXILIAR             (MENU)
SUMARMENU:       INCF MENU             ;SUMAR 1 AL MENU
                 MOVLW 0X06                    
                 SUBWF MENU,0          ; COMPARAR CON 0X06
                 BTFSS STATUS,Z
                 GOTO DECAMENU1        ; SI LLEGO A 0X06 VOLVER A 0X01
                 CLRF MENU
                 BSF MENU,0
                 GOTO DECAMENU1
              
             
RESTARMENU:      DECF MENU             ;RESTAR 1 AL MENU
                 MOVLW 0X00
                 SUBWF MENU,0          ; COMPARAR CON 0
                 BTFSS STATUS,Z
                 GOTO  DECAMENU1       ; SI ES CERO LLEVARLO A 0X05
             
                 MOVLW 0X05
                 MOVWF MENU
             
DECAMENU1:       CLRF DECAMENU;         ; DECAMENU ES CERO YA QUE SOLO HAY 3 OPCIONES
                 GOTO BUCLE;



;------------------------FUNCION=1 AUXILIARES FUNCION1         (VER HORA)
F1_0:            CLRF FUNCION;     FUNCION=0
                 GOTO BUCLE

F1_1:            CLRF OPCIONMOS  
                 BSF OPCIONMOS,0; OPCIONMOS=1  MOSTRAR HORAS Y MINUTOS
                 CALL MOSTRAR
                 GOTO BUCLE

F1_2:            CLRF OPCIONMOS
                 BSF OPCIONMOS,1  ; OPCIONMOS=2  MOSTRAR MINUTOS Y SEGUNDOS
                 CALL MOSTRAR
                 GOTO BUCLE



;-----------------------FUNCION=15 CAMBIARHOR AUXILIAR   (CAMBIAR HORA)

F15VOLVER        CLRF OPCIONMOS;
                 MOVLW 0X01  
                 MOVWF FUNCION   ; FUNCION=1
                 BSF INTCON,7    ; SE HABILITAN LAS INTERRUPCIONES
                 GOTO BUCLE      ;VOLVER AL BUCLE PRINCIPAL


SUMAHOR:         INCF HORA;       ; INCREMENTAR HORA
                 MOVLW 0X02        
                 SUBWF DECAHORA,0  ; SI DECAHORA ES 2 ENTONCES VERIFICAR QUE NO SE HAYA LLEGADO A LA HORA 24
                 BTFSC STATUS,Z
                 GOTO  SUMAHOR1     ; SI ES 2 IR A SUMAHOR1      

                 MOVLW 0X0A         ; SI DECAHORA NO ES 2 ENTONCES VEMOS SI HORA LLEGO A 0X0A
                 SUBWF HORA,0
                 BTFSS STATUS,Z
                 GOTO FINHOR        ; SI NO ES DIEZ NO HAY PROBLEMA
                           
                 CLRF HORA          ; SI ES DIEZ SE INCREMENTA DECAHORA Y SE LIMPIA HORA(=0)
                 INCF DECAHORA
                 BSF INTCON,7
                 GOTO BUCLE

SUMAHOR1:        MOVLW 0X04       ; VERIFICAR QUE HORA NO SEA 4
                 SUBWF HORA,0
                 BTFSS STATUS,Z
                 GOTO FINHOR
                           
                 CLRF HORA         ; SI ES 4 ENTONCES SON LAS 24 O SEA LAS 00HS
                 CLRF DECAHORA     ; LIMPIAR DECAHORA Y LIMPIAR HORA
                 BSF INTCON,7      ; HABILITAR INTERRUPCIONES Y VOLVER A BUCLE
                 GOTO BUCLE



RESTAHOR:        DECF HORA          ; SE DECREMENTA HORA
                 MOVLW 0XFF         ; SI HORA ES= 0XFF ES PORQUE YA DIO LA VUELTA HAY QUE MOSTRAR 9
                 SUBWF HORA,0
                 BTFSS STATUS,Z
                 GOTO FINHOR        ; SI NO ES 0XFF NO HAY PROBLEMA

                 DECF DECAHORA      ; SI ES 0XFF HAY QUE PONER 9 EN HORA Y DECREMENTAR DECAHORA
                 MOVLW 0X09
                 MOVWF HORA

                 MOVLW 0XFF         ; ¿DECAHORA PASO A SER 0XFF?
                 SUBWF DECAHORA,0             
                 BTFSS STATUS,Z
                 GOTO FINHOR          ;NO ENTONCES VOLVER 

                 MOVLW 0X03           ;SI ENTONCES MOSTRAR 23HS=> DECAHORA=2 HORA=3
                 MOVWF HORA
                 MOVWF DECAHORA
                 DECF DECAHORA
                               
             
FINHOR:          BSF INTCON,7; HABILITAR INTERRUPCIONES
                 GOTO BUCLE

;--------------------FUNCION=16   CAMBIARMIN AUXILIAR          (CAMBIAR MINUTOS)
SUMAMIN:         INCF MINUTO           ;INCREMENTAR HORA
                 MOVLW 0X0A            ; ¿ HORA ES 0XA?
                 SUBWF MINUTO,0
                 BTFSS STATUS,Z        
                 GOTO FINMIN            ;NO: NO HAY PROBLEMA VOLVER A BUCLE

                 CLRF MINUTO             ;SI: MINUTO=0 INCREMENTAR DECAMINUTO
                 INCF DECAMINUTO
                 
                 MOVLW 0X06             ; ¿DECAMINUTO ES 6?
                 SUBWF DECAMINUTO,0
                 BTFSS STATUS,Z
                 GOTO FINMIN             ;NO: VOLVER
                 CLRF DECAMINUTO         ;SI: LIMPIAR DECAMINUTO
                 GOTO FINMIN

RESTAMIN:        DECF MINUTO             ;DECREMENTAR MINUTO
                 MOVLW 0XFF
                 SUBWF MINUTO,0          ;ES MINUTO 0XFF? (DIO VUELTA??)
                 BTFSS STATUS,Z
                 GOTO FINMIN             ;NO: VOLVER
             
                 MOVLW 0X09              ;SI: MINUTO=9 DECREMENTAR DECAMINUTO
                 MOVWF MINUTO
                 DECF DECAMINUTO

                 MOVLW 0XFF 
                 SUBWF DECAMINUTO,0      ;¿ES DECAMINUTO 0XFF?
                 BTFSS STATUS,Z 
                 GOTO FINMIN             ; NO: VOLVER
                 MOVLW 0X05              ; SI: DECAMINUTO=5
                 MOVWF DECAMINUTO                                            
             
FINMIN:          BSF INTCON,7
                 GOTO BUCLE
;---------------------------------------------


;----------------------FUNCION2:                        (CAMBIAR HORA ALARMA)
                  ;-----           NOTA: ESTE TRAMO ES IGUAL AL DE CAMBIARHOR CON MODIFICACIONES EN LAS VARIBLES Y LOS LABELS
F2_A:

                 MOVLW 0X03  
                 MOVWF OPCIONMOS; OPCIONMOS=3  MOSTRAR HORAS Y MINUTOS ALARMA
                 CALL MOSTRAR
                 GOTO BUCLE

 
F2VOLVER_A       
                 CLRF FUNCION   ; FUNCION=0
                 GOTO BUCLE      ;VOLVER AL BUCLE PRINCIPAL


SUMAHOR_A:       INCF HORA_A;       ; INCREMENTAR HORA
                 MOVLW 0X02        
                 SUBWF DECAHORA_A,0  ; SI DECAHORA_A ES 2 ENTONCES VERIFICAR QUE NO SE HAYA LLEGADO A LA HORA 24
                 BTFSC STATUS,Z
                 GOTO  SUMAHOR1_A     ; SI ES 2 IR A SUMAHOR1      

                 MOVLW 0X0A         ; SI DECAHORA_A NO ES 2 ENTONCES VEMOS SI HORA LLEGO A 0X0A
                 SUBWF HORA_A,0
                 BTFSS STATUS,Z
                 GOTO FINHOR_A        ; SI NO ES DIEZ NO HAY PROBLEMA
                           
                 CLRF HORA_A          ; SI ES DIEZ SE INCREMENTA DECAHORA Y SE LIMPIA HORA_A(=0)
                 INCF DECAHORA_A
                 GOTO BUCLE

SUMAHOR1_A:        MOVLW 0X04       ; VERIFICAR QUE HORA_A NO SEA 4
                 SUBWF HORA_A,0
                 BTFSS STATUS,Z
                 GOTO FINHOR_A
                           
                 CLRF HORA_A         ; SI ES 4 ENTONCES SON LAS 24 O SEA LAS 00HS
                 CLRF DECAHORA_A     ; LIMPIAR DECAHORA_A Y LIMPIAR HORA_A
                 GOTO BUCLE



RESTAHOR_A:      DECF HORA_A          ; SE DECREMENTA HORA_A
                 MOVLW 0XFF         ; SI HORA ES= 0XFF ES PORQUE YA DIO LA VUELTA HAY QUE MOSTRAR 9
                 SUBWF HORA_A,0
                 BTFSS STATUS,Z
                 GOTO FINHOR_A        ; SI NO ES 0XFF NO HAY PROBLEMA

                 DECF DECAHORA_A      ; SI ES 0XFF HAY QUE PONER 9 EN HORA Y DECREMENTAR DECAHORA_A
                 MOVLW 0X09
                 MOVWF HORA_A

                 MOVLW 0XFF         ; ¿DECAHORA_A PASO A SER 0XFF?
                 SUBWF DECAHORA_A,0             
                 BTFSS STATUS,Z
                 GOTO FINHOR_A          ;NO ENTONCES VOLVER 

                 MOVLW 0X03           ;SI ENTONCES MOSTRAR 23HS=> DECAHORA_A=2 HORA_A=3
                 MOVWF HORA_A
                 MOVWF DECAHORA_A
                 DECF DECAHORA_A
                               
             
FINHOR_A:        GOTO BUCLE
;--------------------FUNCION=17      (CAMBIARMIN_A PARA ALARMA) AUXILIAR         (CAMBIAR MINUTO ALARMA)
SUMAMIN_A:       INCF MINUTO_A           ;INCREMENTAR MINUTO
                 MOVLW 0X0A            ; ¿ MINUTO ES 0XA?
                 SUBWF MINUTO_A,0
                 BTFSS STATUS,Z        
                 GOTO FINMIN_A            ;NO: NO HAY PROBLEMA VOLVER A BUCLE

                 CLRF MINUTO_A             ;SI: MINUTO_A=0 INCREMENTAR DECAMINUTO
                 INCF DECAMINUTO_A
                 
                 MOVLW 0X06             ; ¿DECAMINUTO_A ES 6?
                 SUBWF DECAMINUTO_A,0
                 BTFSS STATUS,Z
                 GOTO FINMIN_A             ;NO: VOLVER
                 CLRF DECAMINUTO_A         ;SI: LIMPIAR DECAMINUTO_A
                 GOTO FINMIN_A

RESTAMIN_A:        DECF MINUTO_A             ;DECREMENTAR MINUTO_A
                 MOVLW 0XFF
                 SUBWF MINUTO_A,0          ;ES MINUTO_A 0XFF? (DIO VUELTA??)
                 BTFSS STATUS,Z
                 GOTO FINMIN_A             ;NO: VOLVER
             
                 MOVLW 0X09              ;SI: MINUTO_A=9 DECREMENTAR DECAMINUTO_A
                 MOVWF MINUTO_A
                 DECF DECAMINUTO_A

                 MOVLW 0XFF 
                 SUBWF DECAMINUTO_A,0      ;¿ES DECAMINUTO_A 0XFF?
                 BTFSS STATUS,Z 
                 GOTO FINMIN_A             ; NO: VOLVER
                 MOVLW 0X05              ; SI: DECAMINUTO_A=5
                 MOVWF DECAMINUTO_A                                            
             
FINMIN_A:        GOTO BUCLE
;---------------------------------------------

;----------------------------AUXILIAR FUNCION3  (MOSTRAR TENSION)

F3COMPLETO:     MOVLW UNIDAD
                MOVWF PUNTERO_3
                GOTO BUCLE;






;----------------------------AUXILIAR FUNCION4 (CAMBIAR DESIMA_T Y UNIDAD_T)


F4VOLVER:          CLRF FUNCION
                   GOTO BUCLE


RESTARDEC_T:       DECF DESIMA_T   ; DECREMENTAR DESIMA_T

                   MOVLW 0XFF
                   SUBWF DESIMA_T,0 ; CUANDO DESIMA_T LLEGUE A 0XFF 
                   BTFSS STATUS,Z  ; HAY QUE PONER 9 EN DESIMA_T Y DECREMENTAR UNIDAD_T
                   GOTO BUCLE
                   MOVLW 0X09
                   MOVWF DESIMA_T

                   ;DECF UNIDAD_T
                   ;MOVLW 0XFF
                   ;SUBWF UNIDAD_T,0
                   ;BTFSS STATUS,Z
                   ;GOTO BUCLE      ; CUANDO UNIDAD_T LLEGUE A 0XFF HAY QUE PONER 4 EN UNIDAD_T
                   ;MOVLW 0X04
                   ;MOVWF UNIDAD_T
                   GOTO BUCLE


SUMARDEC_T:        INCF DESIMA_T   ; DECREMENTAR DESIMA_T

                   MOVLW 0X0A
                   SUBWF DESIMA_T,0  ; CUANDO DESIMA_T LLEGUE A 0X0A 
                   BTFSS STATUS,Z  ; HAY QUE PONER 0 EN DESIMA_T E INCREMENTAR UNIDAD_T
                   GOTO BUCLE
                   CLRF DESIMA_T


                                   ;DESHABILITADO YA QUE SE PUSO MÁXIMO DE 0,99 mV EQUIVALENTE A 99ºC
                   ;INCF UNIDAD_T
                   ;MOVLW 0X05
                   ;SUBWF UNIDAD_T,0
                   ;BTFSS STATUS,Z
                   ;GOTO BUCLE      ; CUANDO UNIDAD_T LLEGUE A 0X05 HAY QUE PONER 0 EN UNIDAD_T
                   ;CLRF UNIDAD_T

                 ; UNIDAD_T NO INCREMENTA YA QUE SE MEDIRÁ DE 0 A 99 ADEMÁS LA TEMPERATURA MAXIMA DEBERÍA MANTENERSE A 100ºC
                   GOTO BUCLE
;-----------------------------------AUXILIAR FUNCION 21   (CAMBIAR CENTESIMA_T)
RESTARCEN_T:      DECF CENTESIMA_T   ; DECREMENTAR DESIMA_T

                   MOVLW 0XFF
                   SUBWF CENTESIMA_T,0  ; CUANDO DESIMA_T LLEGUE A 0XFF 
                   BTFSS STATUS,Z  ; HAY QUE PONER 9 EN DESIMA_T Y DECREMENTAR UNIDAD_T
                   GOTO BUCLE
                   MOVLW 0X09
                   MOVWF CENTESIMA_T
                   GOTO BUCLE


SUMARCEN_T:        INCF CENTESIMA_T   ; DECREMENTAR DESIMA_T

                   MOVLW 0X0A
                   SUBWF CENTESIMA_T,0  ; CUANDO DESIMA_T LLEGUE A 0X0A 
                   BTFSS STATUS,Z  ; HAY QUE PONER 0 EN DESIMA_T E INCREMENTAR UNIDAD_T
                   GOTO BUCLE
                   CLRF CENTESIMA_T
                   GOTO BUCLE




;----------------------------AUXILIAR FUNCION18 (CAMBIAR DESIMA_A Y UNIDAD_A)   PARA ALARMA RELOJ


F18VOLVER:
                   MOVLW .2
                   MOVWF FUNCION
                   CLRF OPCIONMOS
                   GOTO BUCLE


RESTARDEC_A:       DECF DESIMA_A   ; DECREMENTAR DESIMA_T

                   MOVLW 0XFF
                   SUBWF DESIMA_A,0 ; CUANDO DESIMA_T LLEGUE A 0XFF 
                   BTFSS STATUS,Z  ; HAY QUE PONER 9 EN DESIMA_T Y DECREMENTAR UNIDAD_T
                   GOTO BUCLE
                   MOVLW 0X09
                   MOVWF DESIMA_A


                                   ;DESHABILITADO YA QUE SE PUSO MÁXIMO DE 0,99 mV EQUIVALENTE A 99ºC
                   ;DECF UNIDAD_A   
                   ;MOVLW 0XFF
                   ;SUBWF UNIDAD_A,0
                   ;BTFSS STATUS,Z
                   ;GOTO BUCLE      ; CUANDO UNIDAD_T LLEGUE A 0XFF HAY QUE PONER 4 EN UNIDAD_T
                   ;MOVLW 0X04
                   ;MOVWF UNIDAD_A
                          ; UNIDAD_T NO INCREMENTA YA QUE SE MEDIRÁ DE 0 A 99 ADEMÁS LA TEMPERATURA MAXIMA DEBERÍA MANTENERSE A 100ºC
                   GOTO BUCLE


SUMARDEC_A:        INCF DESIMA_A   ; DECREMENTAR DESIMA_T

                   MOVLW 0X0A
                   SUBWF DESIMA_A,0  ; CUANDO DESIMA_T LLEGUE A 0X0A 
                   BTFSS STATUS,Z  ; HAY QUE PONER 0 EN DESIMA_T E INCREMENTAR UNIDAD_T
                   GOTO BUCLE
                   CLRF DESIMA_A

                   ;INCF UNIDAD_A
                   ;MOVLW 0X05
                   ;SUBWF UNIDAD_A,0
                   ;BTFSS STATUS,Z
                   ;GOTO BUCLE      ; CUANDO UNIDAD_T LLEGUE A 0X05 HAY QUE PONER 0 EN UNIDAD_T
                   ;CLRF UNIDAD_A
                   GOTO BUCLE
;-----------------------------------AUXILIAR FUNCION 19   (CAMBIAR CENTESIMA_A)   PARA ALARMA RELOJ
RESTARCEN_A:      DECF CENTESIMA_A   ; DECREMENTAR DESIMA_T

                   MOVLW 0XFF
                   SUBWF CENTESIMA_A,0  ; CUANDO DESIMA_T LLEGUE A 0XFF 
                   BTFSS STATUS,Z  ; HAY QUE PONER 9 EN DESIMA_T Y DECREMENTAR UNIDAD_T
                   GOTO BUCLE
                   MOVLW 0X09
                   MOVWF CENTESIMA_A
                   GOTO BUCLE


SUMARCEN_A:        INCF CENTESIMA_A   ; DECREMENTAR DESIMA_T

                   MOVLW 0X0A
                   SUBWF CENTESIMA_A,0  ; CUANDO DESIMA_T LLEGUE A 0X0A 
                   BTFSS STATUS,Z  ; HAY QUE PONER 0 EN DESIMA_T E INCREMENTAR UNIDAD_T
                   GOTO BUCLE
                   CLRF CENTESIMA_A
                   GOTO BUCLE

;---------------------------------------------------------------------------





                  GOTO BUCLE;







;------------------FUNCION DIVD_16
          ; ESTA FUNCIÓN DIVIDE UN NÚMERO DE 2 BYTES POR .16 QUE EN HEXADECIAMAL SE ESCRIBE 0X10. 
          ; AL IGUAL QUE EN EL SISTEMA DECIMAL, DIVIDIR POR LA BASE OCACIONA EL CORRIMIENTO DE LOS DÍGITOS A LA DERECHA.



DIVD_16:       CLRF DIVDRTAH
               CLRF DIVDRTAL
               MOVF NUMDL,0
               SWAPF NUMDH,0
               MOVWF DIVDRTAH  ;  DIVDRTAH=SWAPF (NUMDH)
               ANDLW B'11110000'
               MOVWF DIVDRTAL  ;   DIVDRTAL=(DIVDRTAH) AND(B'11110000') 
               MOVLW B'00001111'
               ANDWF DIVDRTAH,1; DIVDRTAH=(DIVDRTAH) AND(B'00001111')
               SWAPF NUMDL,0
               ANDLW B'00001111'
               ADDWF DIVDRTAL   ; DIVDRTAL=DIVDRTAL+[SWAPF(NUMDL)] AND(B'00001111')
               RETURN







;****************************UNA ACCION IMPORTANTE!!!! CONVERSION ANALÓGICA A DIGITAL*******************************
CONVERSION:    
                BTFSC CENTISEGUNDO,2; ESTE BIT SE PRENDE Y SE APAGA UNA VEZ CADA 8 MSEG ESTO SERÍA UNA FRECUENCIA DE 12.5 HZ
                                           ;( EN REALIDAD SOLO HAY 12 CONVERSIONES POR SEGUNDO)
                GOTO CONVERTIR     ; SI BIT 2 DE CENTISEGUNDO ESTA PRENDIDO IR A CONVERTIR


                BTFSC BITFLAGS,7  ; ¿¿BIT 7=OFF??    
                BCF BITFLAGS,7       ; NO:  APAGAR BITFLAGS,7 
                GOTO VERALARMA       ; SI:VOLVER


CONVERTIR:      BTFSC BITFLAGS,7 ;  ¿BIT7=OFF?
                GOTO VERALARMA   ; NO: ESTA PRENDIDO SI YA SE REALIZO LA CONVERSION ENTONCES SE VUELVE

                BSF BITFLAGS,7  ; SI: HAY QUE PRENDERLO Y REALIZAR LA CONVERSION


               BSF ADCON0,2;  PEDIR CONVERSION!!!!!!<<<<<<<<<<<<<<<<<<<<





PROMEDIARAD:  
                                       ;AL PROMEDIO TOTAL SE LE SACA UN 10% Y SE LE AGREGA LA NUEVA LECTURA DIVIDIDA 10
                                       ; O SEA:
                                       ; ADPROM[K]=ADPROM[K-1]-ADPROM[K-1]/10 +ADRES[K]/10 

                                          ;PASO1:   RESTARLE 1/16 AL PROMEDIO

              MOVLW 0X0A   ; NUM2=.10 QUE ES USADO COMO DIVISOR DE 1 BYTE
              MOVWF NUM2              
              MOVF ADPROMH,0
              MOVWF NUMDH
              MOVF ADPROML,0
              MOVWF NUMDL


              CALL DIVD_16
                                     ; (RESTA DE DOBLE-BYTE)
              MOVF DIVDRTAL,0;
              SUBWF ADPROML,1; ADPROML=ADPROML-DIVDRTAL
              BTFSS STATUS,C; SI CARRIER ES 0 ES PORQUE ADPROML<DIVDRTAL HAY QUE SACARLE 1 A ADPROMH
              DECF ADPROMH;
              MOVF DIVDRTAH,0;
              SUBWF ADPROMH,1; ADPROMH= ADPROMH-DIVDRTAH 
                                         ; POR SER DIVRTA(H:L) EL 10% DE ADPROM(H:L)  LA RESTA DA UN NUMERO POSITIVO

ESPERAR_AD:    BTFSC ADCON0,2; LA CONVERSION FUE PEDIDA CON ANTERIORIDAD YA DEBERÍA HABERSE LOGRADO.
               GOTO ESPERAR_AD               


                                         ;PASO2:  LEER REGISTROS DE CONVERSION Y DIVIDIRLOS EN 16

               BSF STATUS, RP0 ; (IR AL BANCO 1) 
               MOVF ADRESL,0;
               BCF STATUS, RP0 ; (VOLVER AL BANCO 0) 
               
               ANDLW B'11000000'; SE FILTRA POR LAS DUDAS, SOLO SON UTILES LOS BITS 7 Y 6
               MOVWF NUMDL
               
               MOVF ADRESH,0
               MOVWF NUMDH

               CALL DIVD_16       
               
                                         ;PASO3: SUMARSELO AL PROMEDIO
                                           ;(SUMA DOBLE-BYTE)
               MOVF DIVDRTAL,0;
               ADDWF ADPROML,1; ADPROML= ADPROML+DIVDRTAL
               BTFSC STATUS,C; SI HAY CARRIER HAY QUE SUMARLE 1 A 
               INCF ADPROMH;
               MOVF DIVDRTAH,0;
               ADDWF ADPROMH,1; ADPROMH= ADPROMH+DIVDRTAH




LEER_AD:

               CLRF UC; LIMPIAR UNIDAD DE CONVERSOR
               CLRF DCV; LIMPIAR DECIMA DE CONVERSOR
               CLRF CC; LIMPIAR CENTESIMA DE CONVERSOR
               CLRF MC; LIMPIAR MILESIMA DE CONVERSOR
               CLRF DMC; LIMPIAR DECIMA DE MILESIMA DE CONVERSOR
               CLRF CMC; LIMPIAR CENTESIMA DE MILESIMA DE CONVERSOR           





BIT9:          BTFSS ADPROMH,7
               GOTO BIT8

               MOVLW .2
               ADDWF UC,1

               MOVLW .5
               ADDWF DCV,1


BIT8:          BTFSS ADPROMH,6
               GOTO BIT7            

               MOVLW .1
               ADDWF UC,1

               MOVLW .2
               ADDWF DCV,1

               MOVLW .5
               ADDWF CC




BIT7:                        
               BTFSS ADPROMH,5
               GOTO BIT6  

               MOVLW .6
               ADDWF DCV,1

               MOVLW .2
               ADDWF CC

               MOVLW .5
               ADDWF MC,1
               
 
           
BIT6:                   
               BTFSS ADPROMH,4
               GOTO BIT5  

          
               MOVLW .3
               ADDWF DCV,1

               MOVLW .1
               ADDWF CC

               MOVLW .2
               ADDWF MC,1
               
               MOVLW .5
               ADDWF DMC,1

 



BIT5:          BTFSS ADPROMH,3
               GOTO BIT4  

               
               MOVLW .1
               ADDWF DCV,1

               MOVLW .5
               ADDWF CC

               MOVLW .6
               ADDWF MC,1
               
               MOVLW .2
               ADDWF DMC,1

               MOVLW .5
               ADDWF CMC,1



BIT4:          BTFSS ADPROMH,2
               GOTO BIT3  

                 

               MOVLW .7
               ADDWF CC

               MOVLW .8
               ADDWF MC,1
               
               MOVLW .1
               ADDWF DMC,1

               MOVLW .2
               ADDWF CMC,1




BIT3:          BTFSS ADPROMH,1
               GOTO BIT2            



               MOVLW .3
               ADDWF CC

               MOVLW .9
               ADDWF MC,1
               
               MOVLW .0
               ADDWF DMC,1

               MOVLW .6
               ADDWF CMC,1


BIT2:          BTFSS ADPROMH,0
               GOTO BIT1            


   
               MOVLW .1
               ADDWF CC

               MOVLW .9
               ADDWF MC,1
               
               MOVLW .5
               ADDWF DMC,1

               MOVLW .3
               ADDWF CMC,1




BIT1:          BTFSS ADPROML,7
               GOTO BIT0  


   
               MOVLW .9
               ADDWF MC,1
               
               MOVLW .7
               ADDWF DMC,1

               MOVLW .7; (SE HA REDONDEADO PARA ARRIBA)
               ADDWF CMC,1


        


BIT0:          BTFSS ADPROML,6
               GOTO  DIGITALIZAR 

               
               MOVLW .4
               ADDWF MC,1
               
               MOVLW .8
               ADDWF DMC,1

               MOVLW .8
               ADDWF CMC,1



DIGITALIZAR:                   ; EL DIVISOR ES NUM2 QUE FUE PREVIAMENTE CARGADO CON .10
               MOVF CMC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=CMC/10  NUM1=RESTO
               ADDWF DMC,1  ; DMC= DMC+CMC/10
               MOVF NUM1,0
               MOVWF CMC    ; CMC=RESTO

               MOVF DMC,0
               MOVWF NUM1; NUM1=DMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=DMC/10  NUM1=RESTO
               ADDWF MC,1  ; MC= MC+DMC/10
               MOVF NUM1,0
               MOVWF DMC    ; DMC=RESTO

               MOVF MC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=MC/10  NUM1=RESTO
               ADDWF CC,1  ; CC= CC+MC/10
               MOVF NUM1,0
               MOVWF MC    ; MC=RESTO

               MOVF CC,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=CC/10  NUM1=RESTO
               ADDWF DCV,1  ; DCV= DCV+CC/10
               MOVF NUM1,0
               MOVWF CC    ; CC=RESTO

               MOVF DCV,0
               MOVWF NUM1; NUM1=CMC
               CALL DIV    ; NUM1/NUM2=W O SEA W=DCV/10  NUM1=RESTO
               ADDWF UC,1  ; UC= UC+DCV/10
               MOVF NUM1,0
               MOVWF DCV    ; DCV=RESTO


TRANSFERIR:               
               MOVF UC,0;        UNIDAD=UC //DESIMA=DCV // CENTESIMA=CC // MILESIMA=MC
               MOVWF UNIDAD;
               MOVF DCV,0;
               MOVWF DESIMA;
               MOVF CC,0;
               MOVWF CENTESIMA;
               MOVF MC,0;
               MOVWF MILESIMA;


TEST_T:          BTFSS ALARMA_T,0     ;¿ALARMA_T = 1?
                 GOTO VERALARMA       ; NO
                
                 MOVF UNIDAD_T,0      ;SI
                 SUBWF UNIDAD,0 
                 BTFSS STATUS,C;  ¿UNIDAD>=UNIDAD_T?
                 GOTO VERALARMA ;  NO
                 BTFSS STATUS,Z;   ¿UNIDAD=UNIDAD_T?
                 GOTO ACT_ALARMA_T  ;NO: ENTONCES UNIDAD>UNIDAD_T ACTIVAR ALARMA
                    
                 MOVF DESIMA_T,0 ;SI: UNIDAD=UNIDAD_T
                 SUBWF DESIMA,0 
                 BTFSS STATUS,C;  ¿DESIMA>=CENTESIMA_T?
                 GOTO VERALARMA
                 BTFSS STATUS,Z;  ¿DESIMA =DESIMA_T?
                 GOTO ACT_ALARMA_T ;NO

                 MOVF CENTESIMA_T,0 ;SI
                 SUBWF CENTESIMA,0 
                 BTFSS STATUS,C;  ¿CENTESIMA>=CENTESIMA_T?
                 GOTO VERALARMA; NO
ACT_ALARMA_T:    
                 BSF ALARMA_T,7 ;SI





               GOTO VERALARMA              

;************************************
;************************************ACCIONES DE COMANDO DE DISPOSITIVOS EXTERNOS******************
                    ; **FUNCIONES RELACIONADAS:
                    ; "BUCLE"//"ALARMA_TENSION"(FUNCION=26)//"ALARMA"(FUNCION=25)//ERRORESPROC

                    ; **VARIABLES USADAS:
                    ;ENTRADAS:
                    ; SENSO/ BIT7= LUZ NIVEL //BIT6= SENSOR BOYA//BIT5=SENSOR CERRADO //BIT4=SENSOR ABIERTO
                    ;SALIDAS:
                    ; PORTA:  BIT5=MOTOR VALVULA// BIT3=CALENTADOR//BIT2=LINTERNA//  ADCON0,0
                    ;ENTRADAS/SALIDAS:
                    ; PROCESO//CRONO//CRONOPROC//ERRORNUM//FUNCION//UNIDAD_C//DESIMA_C//CENTESIMA_C
                    ;CONTADOR_C//AUXILIAR_C

                    ;**POSIBILIDAD A SALTOS EXTERNOS:
                    ;   "VERCONVERSOR"(EN BUCLE PRINCIPAL)
                    
                    ;COMENTARIO: ES UNA FUNCION IMPORTANTE POR ESO ES LLAMADA EN CADA BUCLE DEL BUCLE PRINCIPAL

                 ORG 0X700
PROCESO_ACTUAL: 

                MOVLW 0X07
                MOVWF PCLATH
                
                MOVF PROCESO,0
                
                ADDWF PCL,1
                GOTO CERRARVALVULA; PROCESO=0 
                GOTO NOPROCESO; PROCESO=1  (SI NO HAY QUE REALIZAR PROCESO DEBE ESTAR EN "1")
                GOTO ABRIRVALVULA; PROCESO=2
                GOTO CALENTAR;    PROCESO=3
                GOTO PRENDERLAMP; PROCESO=4
                ;GOTO APAGARCALOR   EL APAGADO SE HACE DIRECTAMENTE AL SELECCIONAR OTRO PROCESO O EN UNA FUNCION
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
 
                GOTO CERRARVALVULA; DEFAULT
               
;-----------------------------------PROCESO=0  CERRAR VALVULA

CERRARVALVULA:  
                BCF ADCON0,0; APAGAR CONVERSIONES
                BCF PORTA,2; APAGAR LINTERNA
                BCF PORTA,3; FORZAR EL CIERRE DEL CALENTADOR (SI TODO ESTA BIEN EL CALENTADOR YA DEBERÍA HABERSE APAGADO ANTES)

                MOVLW 0X00
                SUBWF CRONOPROC,0 ;  ¿CRONOPROCESO=0X00?
                BTFSC STATUS,Z 
                GOTO CONTAR0; SI
                
                CLRF CRONO;   ;N0: RESETEAR CRONOMETRO PARA PROCESO ACTUAL
                CLRF CRONOPROC; CRONOPROCESO= NUMERO DE PROCESO ACTUAL



CONTAR0:        MOVLW .40; 40/4= 10 SEGUNDOS
                SUBWF CRONO,0
                BTFSC STATUS,C; ¿CRONO>=.40?
                GOTO ERROR_01  ; SI

                                ;NO...


                
                BTFSC SENSO,5;  ¿SENSO[BIT5]?
                GOTO CERRARYA;   BIT 5=1 => NO SE DETECTA QUE LA VALVULA ESTE CERRADA. SE ASUME QUE ESTA ABIERTA
                               ;  BIT5=0 LA VALVULA ESTA CERRADA...
                BCF PORTA,5; APAGAR MOTOR DE VALVULAS O FORZAR APAGADO.  NO SE DEBE ABRIR LA VALVULA SI EL VASO ESTA LLENO!!
                MOVLW 0X01;
                MOVWF PROCESO; TERMINAR PROCESO
                
                MOVLW 0XFF    ; PONIENDO UN NUMERO NO USADO EN OPCIONMOS HACE QUE CUALQUIER FUNCIÓN INICIALICE X PRIMERA VEZ
                MOVWF OPCIONMOS; ACTUALIZAR FUNCION ACTUAL PARA QUE VUELVA A ACTIVAR ADCON0,0 POR EJEMPLO
                GOTO VERCONVERSOR; VOLVER



CERRARYA:       BSF PORTA,5; ENCENDER MOTOR DE VALVULA(ES UN MOTOR SINCRONICO QUE GIRA EN ALGUNA SENTIDO HASTA CHOCAR 
                                         ;CON ALGUN TOPE A LO QUE INVIERTE SU SENTIDO)
                GOTO VERCONVERSOR



;----------------------------------PROCESO=1   NO HAY PROCESO ACTIVO

NOPROCESO:      CLRF CRONOPROC;
                INCF CRONOPROC;
                BCF PORTA,3; FORZAR EL CIERRE DEL CALENTADOR
   


                BTFSS SENSO,5;  ¿SENSO[BIT5]?
                GOTO VERCONVERSOR;   BIT5=0 LA VALVULA ESTA CERRADA...

                CLRF PROCESO; PROCESO=0 CERRAR VALVULA
                GOTO VERCONVERSOR;


;-----------------------------------PROCESO=2  ABRIR VALVULA


ABRIRVALVULA:  
                BTFSC SENSO,7;  SI EL RECIPIENTE ESTA LLENO HAY QUE CERRAR LA VALVULA. 
                GOTO VERCRONO02 ; AÚN ESTA VACÍO
                CLRF PROCESO;  ESTA LLENO HAY QUE CERRAR VALVULA
                GOTO VERCONVERSOR            


                


VERCRONO02:     MOVLW 0X02
                SUBWF CRONOPROC,0 ;  ¿CRONOPROCESO=0X02?
                BTFSC STATUS,Z 
                GOTO CONTAR2; SI

                CLRF CRONO;   ;N0: RESETEAR CRONOMETRO PARA PROCESO ACTUAL
                MOVLW 0X02                
                MOVWF CRONOPROC; CRONOPROCESO= NUMERO DE PROCESO ACTUAL


CONTAR2:        MOVLW .180; 180/4= 45 SEGUNDOS
                SUBWF CRONO,0
                BTFSC STATUS,C; ¿CRONO>=.100?
                GOTO ERROR_02  ; SI


                                ;NO...


                
                BTFSC SENSO,4;  ¿SENSO[BIT4]?
                GOTO ABRIRYA;   BIT 4=1 => NO SE DETECTA QUE LA VALVULA ESTE ABIERTA. SE ASUME QUE ESTA CERRADA
                               ;  BIT4=0 LA VALVULA ESTA ABIERTA...
                BCF PORTA,5; APAGAR MOTOR DE VALVULAS O FORZAR APAGADO.  NO SE DEBE ABRIR LA VALVULA SI EL VASO ESTA LLENO!!
                

                GOTO VERCONVERSOR; VOLVER



ABRIRYA:        
                BTFSC SENSO,5;    ¿SENSO[BIT5]? 
                GOTO ABRIRYA1      ;BIT=1//NO

                                    ;SI:BIT=0
                MOVLW .16; 16/4= 4 SEGUNDOS
                SUBWF CRONO,0
                BTFSC STATUS,C; ¿CRONO>=.12?
                GOTO ERROR_03  ; SI
                               ;NO
ABRIRYA1:       BSF PORTA,5; ENCENDER MOTOR DE VALVULA(ES UN MOTOR SINCRONICO QUE GIRA EN ALGUNA SENTIDO 
                            ;HASTA CHOCAR CON ALGUN TOPE A LO QUE INVIERTE SU SENTIDO)
                GOTO VERCONVERSOR



;-----------------------------PROCESO=3 CALENTAR





CALENTAR:       BTFSC SENSO,5   ; SI LA VALVULA *NO ESTA CERRADA*(ABIERTA) NO TIENE QUE CALENTAR
                GOTO ERROR_04
                BTFSS SENSO,6   ; SI EL CONTENEDOR PRINCIPAL ESTA VACÍO, SE ACTIVA EL SENSOR Y NO SE DEBE CALENTAR
                GOTO ERROR_06


                MOVLW 0X03
                SUBWF CRONOPROC,0 ;  ¿CRONOPROCESO=0X00?
                BTFSC STATUS,Z 
                GOTO CONTAR3; SI
                
                MOVLW .60; N0: RESETEAR VARIABLES PARA PROCESO ACTUAL  (se da 180-60=120 => 120/4=30segundos de precalentamiento
                              ; por experimento se ve que al principio cuesta mas variar la temperatura)
                MOVWF CRONO;   SE PREPARA CRONO 30 SEGUNDOS ANTES DE QUE HAGA  PASAR A CONTADOR_C A CERO Y HAGA 
                                       ;REFRESCAR LAS VARIABLES POR PRIMERA VEZ

                CLRF CONTADOR_C; RESETEAR CONTADOR_C
                DECF CONTADOR_C;

                                
                CLRF UNIDAD_C
                CLRF DESIMA_C
                CLRF CENTESIMA_C
                MOVLW 0X03                
                MOVWF  CRONOPROC; CRONOPROCESO= NUMERO DE PROCESO ACTUAL


CONTAR3:        MOVLW .180; (.180; 180/4= 45 SEGUNDO)
                SUBWF CRONO,0
                BTFSS STATUS,C; ¿CRONO>=CUMPLIO .45 SEG
                GOTO CALENTAR_YA;NO
                INCF CONTADOR_C;SI
                CLRF CRONO;

                                   ;HA PASADO 45 SEGUNDOS SI TODO MARCHA BIEN ENTONCES EL VALOR FORMADO  CON UNIDAD,
                                    ; DESIMA Y CENTESIMA TENDRÍA QUE HABER INCREMENTADO
                MOVF UNIDAD_C,0
                SUBWF UNIDAD,0;       ¿UNIDAD>=UNIDAD_C ?    
                BTFSS STATUS,C;   
                GOTO  ERROR_00  ; NO: ERROR
                BTFSS STATUS,Z;       ¿UNIDAD=UNIDAD_C?
                GOTO REFRESCAR_C; : entonces si no es menor ni es igual: es mayor
                                   
                MOVF DESIMA_C,0       ; SI
                SUBWF DESIMA,0;      ¿DESIMA>=DESIMA_C  ?
                BTFSS STATUS,C;   
                GOTO ERROR_00;   NO
                BTFSS STATUS,Z;      ¿DESIMA=DESIMA_C?
                GOTO  REFRESCAR_C  ;  NO: entonces es mayor

                MOVF CENTESIMA,0
                SUBWF CENTESIMA_C,0;    ¿CENTESIMA=<CENTESIMA_C?
                BTFSC STATUS,C;   
                GOTO ERROR_00  ;   SI
                
                
REFRESCAR_C:    MOVF UNIDAD,0
                MOVWF UNIDAD_C;       UNIDAD_C=UNIDAD    
                MOVF DESIMA,0
                MOVWF DESIMA_C;      DESIMA_C=  DESIMA
                MOVF CENTESIMA,0
                MOVWF CENTESIMA_C;   CENTESIMA_C= CENTESIMA

                INCF CENTESIMA_C;  SE SUMA 1 A CENTESIMA_C PARA QUE EL PROXIMO VALOR TENGA QUE SER SI O SI MAYOR AL ACTUAL
                MOVLW 0X0A
                SUBWF CENTESIMA_C,0;  CENTESIMA_C>=0X0A??
                BTFSS STATUS, C   
                GOTO CALENTAR_YA;  NO
                
                CLRF CENTESIMA_C  ;SI...
                INCF DESIMA_C; 
                MOVLW 0X0A
                SUBWF DESIMA_C,0;  DESIMA_C>=0X0A??
                BTFSS STATUS, C  
                GOTO CALENTAR_YA;  NO
                
                MOVLW 0X09  ; SI: SI LLEGA A 99 SE DEBE MANTENERSE, YA QUE ES EL MÁXIMO VALOR
                MOVWF DESIMA_C
                MOVWF CENTESIMA_C                


CALENTAR_YA:    MOVLW 0XFF;
                SUBWF CONTADOR_C,0;
                BTFSC STATUS,Z;¿CONTADOR_C=0XFF?(CONDICION INICIAL)
                GOTO FIN_C ; SI                       
                                  ;NO
                MOVLW .12; 
                SUBWF CONTADOR_C,0;  CUANDO EL CONTADOR LLEGA A .12 HABRÁN PASADO 9 MINUTOS
                BTFSC STATUS,C; ¿CONTADOR_C>=.12?
                GOTO ERROR_05
                

FIN_C:          BSF PORTA,3; ENCENDER CALENTADOR
                GOTO VERCONVERSOR


               ; NOTA: PARA CALENTAR SE UTILIZA LA FUNCION ALARMATENSION(FUNCION=26)

;-----------------------------------PROCESO=4  PRENDER LAMPARA PARA DETECTAR NIVEL DE LÍQUIDO EN RECIPIENTE MEDIANTE FOTODIODO

PRENDERLAMP:  
                BCF PORTA,3; FORZAR EL CIERRE DEL CALENTADOR (SI TODO ESTA BIEN EL CALENTADOR YA DEBERÍA HABERSE APAGADO ANTES)
                BSF PORTA,2; PRENDER LINTERNA!!
                
                MOVLW 0X04
                SUBWF CRONOPROC,0 ;  ¿CRONOPROCESO=0X04?
                BTFSC STATUS,Z 
                GOTO CONTAR4; SI
                
                CLRF CRONO;   ;N0: RESETEAR CRONOMETRO PARA PROCESO ACTUAL
                
                MOVLW 0X04
                MOVWF CRONOPROC; CRONOPROC= PROCESO ACTUAL



CONTAR4:        MOVLW .1; 1/4= 1/4 SEGUNDO  (SE DA UN TIEMPO ANTES DE ABRIR PARA QUE EL FOTODIODO DETECTE LA LUZ CORRECTAMENTE)
                SUBWF CRONO,0
                BTFSS STATUS,C; ¿CRONO>=.2?
                GOTO VERCONVERSOR;  NO: ESPERAR

                MOVLW 0X02; SI: PROCESO=2 (LISTO PARA ABRIR VALVULA ENTONCES IR A ABRIR VALVULA)
                MOVWF PROCESO;
                GOTO VERCONVERSOR;              





;***************************************ERRORES
ERROR_00:    ; ERROR FATAL!! SE ESTA CALENTANDO Y NO HAY VARIACION DE TEMPERATURA POR MAS DE 45 SEGUNDOS;
            
            BCF PORTA,3; PARAR DE CALENTAR
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA  
                        ; ANTE CUALQUIER ERROR SE BUSCA QUE LA VALVULA ESTE CERRADA Y EL CALENTADOR APAGADO 
            MOVLW 0X00
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR


ERROR_01:   MOVLW 0X01; ERROR FATAL!! LA VALVULA ESTA SIN CERRAR POR MAS DE 10 SEGUNDOS Y EL NIVEL LLEGO A SU LIMITE
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            CLRF CRONO
            GOTO VERCONVERSOR; VOLVER AL BUCLE PRINCIPAL
            


ERROR_02:        ; ERROR!!! EL PROCESO DE ABRIR VALVULA  SIGUIÓ ACTIVADO POR MAS DE 45 SEGUNDOS; ES POSIBLE QUE NO HAYA RECIPIENTE
            BCF PORTA,5; PARAR MOTOR
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA
            MOVLW 0X02
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR
           

ERROR_03:       ; ERROR !!! SE HA ENERGIZADO EL MOTOR PERO LA VALVULA ESTA SIN ABRIR POR MAS DE 4 SEGUNDOS
            BCF PORTA,5; PARAR MOTOR
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA
            MOVLW 0X03
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR


ERROR_04      ;PELIGRO!!! SE HA INTENTADO CALENTAR CON LA VALVULA ABIERTA
            BCF PORTA,3; FORZAR LA PARADA DEL CALENTADOR  
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA
            MOVLW 0X04
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR

ERROR_05    ; ERROR GRAVE!! HA PASADO MAS DE 9 MINUTOS Y EL PROCESO DE CALENTAR NO HA TERMINADO
            BCF PORTA,3; PARAR DE CALENTAR
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA  ; 
            MOVLW 0X05
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR


ERROR_06           ; PELIGRO!!! SE HA INTENTADO CALENTAR SIN LÍQUIDO
            BCF PORTA,3; FORZAR LA PARADA DEL CALENTADOR  
            CLRF PROCESO; PROCESO=0X00 CERRARVALVULA
            MOVLW 0X06
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO VERCONVERSOR







             ORG 0X00F00; 
                             ; ERROR DEL PROGRAMA, POR ALGUNA EXTRAÑA RAZON PCL HA LLEGADO A UNA DIRECCIÓN PROHIBIDA

            BCF STATUS,IRP; BANCO 0 PARA DIRECCIONAMIENTO INDIRECTO
            BCF STATUS,RP1; IR AL BANCO 0
            BCF STATUS,RP0;
            CLRF PCLATH;
  
            MOVLW 0X09
            MOVWF ERRORNUM
            MOVLW .30
            MOVWF FUNCION
            GOTO BUCLE;
            END