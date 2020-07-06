$regfile = "m64def.dat"
$crystal = 11059200
$hwstack = 128
$swstack = 64
$framesize = 64
$version 1 , 0 , 575
$projecttime = 801

Config Com1 = 115200 , Synchrone = 0 , Parity = None , Stopbits = 1 , Databits = 8 , Clockpol = 0       'BLE

Config Com2 = 57600 , Synchrone = 0 , Parity = None , Stopbits = 1 , Databits = 8 , Clockpol = 0
Open "COM2:" For Binary As #2

Config Timer1 = Pwm , Pwm = 8 , Compare_a_pwm = Clear_up , Compare_b_pwm = Clear_up , Compare_c_pwm = Clear_up , Prescale = 8
Start Timer1
Pwm1a = 0                                                   'pB.5
Pwm1b = 0                                                   'pB.6
Pwm1c = 0                                                   'pB.7


Config Adc = Single , Prescaler = Auto , Reference = Avcc
'ADC0 - ADC4 (pF.0 - pF.4)

Config Porte.3 = Output : Led_g Alias Porte.3
Config Porte.4 = Output : Led_r Alias Porte.4
Config Porte.5 = Output : Led_b Alias Porte.5

Config Pina.1 = Input : Button2 Alias Pina.1 : Set Porta.1
Config Pina.2 = Input : Button1 Alias Pina.2 : Set Porta.2

Config Pind.4 = Input : Mfp Alias Pind.4
Config Pine.7 = Input : Sd_detect Alias Pine.7 : Porte.7 = 1
Config Pinc.7 = Input : Main_detect Alias Pinc.7

'Nov
Config Portc.2 = Output : Rele_pump1 Alias Portc.2          'NC! (Re5)
Config Portc.3 = Output : Rele_pump2 Alias Portc.3          'NC! (Re6)
Config Portc.1 = Output : Rele_heater Alias Portc.1         'Re1
Config Portc.0 = Output : Rele_skimmer Alias Portc.0        'Re2
Config Portc.4 = Output : Rele_ph Alias Portc.4             'Re3
Config Portc.5 = Output : Rele_aux Alias Portc.5            'Re4

Config 1wire = Porte.2

Config Debounce = 20

Config Clock = User
Config Date = Dmy , Separator = Slash

Config Single = Scientific , Digits = 4

Enable Interrupts

'===============================================================================

Dim Zakasnitev As Word : Zakasnitev = 1000
Dim A As Word

'===============================================================================================================

Do

   Set Led_r : Waitms Zakasnitev : Reset Led_r : Waitms Zakasnitev
   Set Led_b : Waitms Zakasnitev : Reset Led_b : Waitms Zakasnitev
   Set Led_g : Waitms Zakasnitev : Reset Led_g : Waitms Zakasnitev

   Set Rele_pump1 : Waitms Zakasnitev : Reset Rele_pump1 : Waitms Zakasnitev
   Set Rele_pump2 : Waitms Zakasnitev : Reset Rele_pump2 : Waitms Zakasnitev

   Set Rele_heater : Waitms Zakasnitev : Reset Rele_heater : Waitms Zakasnitev
   Set Rele_skimmer : Waitms Zakasnitev : Reset Rele_skimmer : Waitms Zakasnitev
   Set Rele_ph : Waitms Zakasnitev : Reset Rele_ph : Waitms Zakasnitev
   Set Rele_aux : Waitms Zakasnitev : Reset Rele_aux : Waitms Zakasnitev

   Pwm1a = 255 : Waitms Zakasnitev : Pwm1a = 0 : Waitms Zakasnitev
   Pwm1b = 255 : Waitms Zakasnitev : Pwm1b = 0 : Waitms Zakasnitev
   Pwm1c = 255 : Waitms Zakasnitev : Pwm1c = 0 : Waitms Zakasnitev

   A = 0
   Do
      If Button1 = 0 Then Set Led_g : If Button1 = 1 Then Reset Led_g
      If Button2 = 0 Then Set Led_b : If Button2 = 1 Then Reset Led_b
      Toggle Led_r
      Incr A
      Waitms 100
   Loop Until A > 100
   Reset Led_g
   Reset Led_b
   Reset Led_r

Loop