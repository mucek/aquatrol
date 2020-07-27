$regfile = "m64def.dat"
$crystal = 11059200
$hwstack = 128
$swstack = 64
$framesize = 64
$version 1 , 0 , 607
$projecttime = 832

Config Com1 = 115200 , Synchrone = 0 , Parity = None , Stopbits = 1 , Databits = 8 , Clockpol = 0       'BLE
Config Serialin = Buffered , Size = 50 , Bytematch = 10

Config Com2 = 57600 , Synchrone = 0 , Parity = None , Stopbits = 1 , Databits = 8 , Clockpol = 0
Config Serialin1 = Buffered , Size = 30 , Bytematch = 10
Open "COM2:" For Binary As #2

Config Timer1 = Pwm , Pwm = 8 , Compare_a_pwm = Clear_up , Compare_b_pwm = Clear_up , Compare_c_pwm = Clear_up , Prescale = 8
Start Timer1
Pwm1a = 0                                                   'pB.5
Pwm1b = 0                                                   'pB.6
Pwm1c = 0                                                   'pB.7

Const Timer0reload = 108                                    '10ms interrupt
Config Timer0 = Timer , Prescale = 1024
Load Timer0 , Timer0reload
On Ovf0 Timer0_10ms
Enable Ovf0
Start Timer0

Config Adc = Single , Prescaler = Auto , Reference = Avcc
'ADC0 - ADC4 (pF.0 - pF.4)

Config Porte.3 = Output : Led_g Alias Porte.3
Config Porte.4 = Output : Led_r Alias Porte.4
Config Porte.5 = Output : Led_b Alias Porte.5

Config Pina.1 = Input : Button2 Alias Pina.1 : Set Porta.1
Config Pina.2 = Input : Button1 Alias Pina.2 : Set Porta.2

Config Pind.4 = Input : Mfp Alias Pind.4
Config Pine.7 = Input : Sd_missing Alias Pine.7 : Porte.7 = 1
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

$lib "I2CV2.LIB"
$lib "I2C_TWI.LBX"

Config Scl = Portd.0
Config Sda = Portd.1
Config Twi = 400000
I2cinit

Config Clock = User
Config Date = Dmy , Separator = Slash

Config Single = Scientific , Digits = 4


'===============================================================================

'Cas
Dim I2c_dta(20) As Byte
Const Rtc_i2c_r = &B11011111
Const Rtc_i2c_w = &B11011110
Dim Time_temps As String * 20 , Date_temps As String * 20
Dim T_hour As Byte , T_min As Byte , T_sec As Byte , T_day As Byte , T_month As Byte , T_year As Byte
Dim Clk_reg3 As Byte , Clk_ok As Bit
Dim Str_time As String * 8
Dim Timer_10ms As Word


'Bluetooth
Dim Bt_initialized As Byte
Dim E_bt_initialized As Eram Byte
Dim Print_bluetooth As Byte


'SD
Dim Btemp1 As Byte
Dim Sdused As Dword
Dim Sdsize As Dword
Dim Sdfree As Dword
Dim File_handle As Byte
Dim File_name As String * 10
Dim Strtemp3 As String * 20
Dim Input_string As String * 40
Dim Dev_id As String * 16
Dim B As Byte
Dim Sd_write As Bit
Dim File_end As Byte
Dim Rnd_id As Word
Dim S_rnd_id As String * 8
Dim String2write As String * 75                             'String za zapis v LOG, po pisanju se izbrise
Dim String2write_dt As String * 100
Dim A As Byte
Dim History_tmr As Word


'Ext ADC - meritev toka
Dim I2c_tmr As Byte
Const 15_bit = 32767
Dim S_voltage As Single
Dim S_voltage1 As Single
Dim Value As Word
Dim Byte1 As Byte
Dim Byte2 As Byte
Dim Byte3 As Byte
Dim I As Byte
Dim C As Byte


'Int ADC 0-4
Dim adc_0 as word
Dim adc_1 as word
Dim adc_2 as word
Dim Adc_3 As Word
Dim adc_4 as word

Dim In1 As Byte
Dim In2 As Byte
Dim Ac_ok As Byte
Dim Ac_fail_cntr As Byte

'1wire
Dim 1w_conv As Bit
Dim Sc_pad(9) As Byte , 1w_tmr As Byte , Temp_sin As Single
Dim Temp As Integer At Sc_pad(1) Overlay
Dim Temperatura As Integer

'Globalne nastavitve
Dim Zakasnitev As Word
Dim Config_bt_skip As Byte
Dim Skip_sd As Byte

'Filtra
Dim Feed_time As Word
   Dim E_feed_time As Eram Word
Dim Disable_pumps As Word

'Termostat
'Editable
Dim Target_temp As Integer : Dim E_target_temp As Eram Integer       'Nastavitev termostata, stopinje*10
'Internal
Dim Temp_hysteresis As Integer
Dim Temp_on As Integer
Dim Temp_off As Integer

'pH/CO2
Dim Ph As Single
Dim Ph_calib_700 As Single
   Dim E_ph_calib_700 As Eram Single
Dim Ph_calib_401 As Single
   Dim E_ph_calib_401 As Eram Single
Dim Ph_calc1 As Single
   Dim E_ph_calc1 As Eram Single
Dim A_ph As Byte
Dim Ph_calibrated As Byte
Dim E_ph_calibrated As Eram Byte
Dim Ph_limit As Single
   Dim E_ph_limit As Eram Single
Dim Ph_on As Single
Dim Ph_off As Single
Dim Ph_hys As Single

Dim Ph_calib As Byte                                        '1, ko pride ukaz na UART

'Skimmer
Dim Skimmer_on1 As String * 8
   Dim E_skimmer_on1 As Eram String * 8
Dim Skimmer_off1 As String * 8
   Dim E_skimmer_off1 As Eram String * 8
Dim Skimmer_on2 As String * 8
   Dim E_skimmer_on2 As Eram String * 8
Dim Skimmer_off2 As String * 8
   Dim E_skimmer_off2 As Eram String * 8


'LEDs
Dim Dimming_step1 As Word                                   'cas koraka v sekundah
   Dim E_dimming_step1 As Eram Word
Dim Dimming_step2 As Word                                   'cas koraka v sekundah
   Dim E_dimming_step2 As Eram Word
Dim Dimming_step3 As Word                                   'cas koraka v sekundah
   Dim E_dimming_step3 As Eram Word

Dim Led1_enabled As Byte
Dim Dimming_timer1 As Word
Dim Led1_on_time As String * 8
   Dim E_led1_on_time As Eram String * 8
Dim Led1_off_time As String * 8
   Dim E_led1_off_time As Eram String * 8
Dim Led1_pwm_on As Byte
   Dim E_led1_pwm_on As Eram Byte
Dim Led1_pwm_off As Byte
   Dim E_led1_pwm_off As Eram Byte

Dim Led2_enabled As Byte
Dim Dimming_timer2 As Word
Dim Led2_on_time As String * 8
   Dim E_led2_on_time As Eram String * 8
Dim Led2_off_time As String * 8
   Dim E_led2_off_time As Eram String * 8
Dim Led2_pwm_on As Byte
   Dim E_led2_pwm_on As Eram Byte
Dim Led2_pwm_off As Byte
   Dim E_led2_pwm_off As Eram Byte

Dim Led3_enabled As Byte
Dim Dimming_timer3 As Word
Dim Led3_on_time As String * 8
   Dim E_led3_on_time As Eram String * 8
Dim Led3_off_time As String * 8
   Dim E_led3_off_time As Eram String * 8
Dim Led3_pwm_on As Byte
   Dim E_led3_pwm_on As Eram Byte
Dim Led3_pwm_off As Byte
   Dim E_led3_pwm_off As Eram Byte

Dim Switch_leds As Byte

Dim Feed_pump_select As Byte                                '0-funkcija onemogocena, 1-funkcija aktivna na R5, 2-funkcija aktivna na R5+R6
   Dim E_feed_pump_select As Eram Byte

Ph_hys = 0.1
Temp_hysteresis = 2                                         '0,2 stopinje C gor/dol od target temp

Zakasnitev = 500                                            'Zamik pri testiranju
Config_bt_skip = 0                                          '1=izklop BT konfiguracije med programiranjem
Skip_sd = 0                                                 '1=izklop SD funkcij
'===============================================================================================================

Enable Interrupts

Gosub 01_init

02_main:
Temperatura = 850                                           'Da ne vklopi gretja, preden prvic prebere senzor
I2c_tmr = 19                                                'Da prvic hitro prebere
1w_tmr = 50

Pwm1a = Led1_pwm_off
Pwm1b = Led2_pwm_off
Pwm1c = Led3_pwm_off



Do
'   Toggle Led_g

   Gosub 41_read_i2c_adc
   Gosub 41_ph_calc
   Gosub 42_read_inputs
   Gosub 43_read_1wire

   Gosub Get_time

   Gosub 51_set_pumps
   Gosub 52_set_lights
   Gosub 53_set_heater
   Gosub 54_set_co2
   Gosub 55_set_skimmer


   If Timer_10ms > 100 Then                                 'sekundni taski, ni natancno!
      Timer_10ms = 0

      Incr Print_bluetooth

      Gosub Print_terminal

      Incr 1w_tmr
      Incr I2c_tmr
      Incr History_tmr

      If Disable_pumps > 0 Then Decr Disable_pumps
      If History_tmr > 60 Then Gosub Sd_write_history
   End If

   If Print_bluetooth > 3 Then
      Print_bluetooth = 0
      Gosub Print_bt
   End If

   'Nastavitve preko UARTa
   If Ph_calib = 1 Then Goto 41_calib_ph
   If Switch_leds = 1 Then Gosub Leds_on_bt

   Reset Led_g                                              'UART
Loop




'===============================================================================================================

51_set_pumps:
   If Disable_pumps = 0 And Rele_pump1 = 1 Then

      String2write = "Pumps enabled!"
      Gosub Sd_write_log

      Reset Rele_pump1
      Reset Rele_pump2
   End If

   If Disable_pumps > 0 And Rele_pump1 = 0 And Rele_pump2 = 0 Then

      If Feed_pump_select = 0 Then
         'Disabled

      Elseif Feed_pump_select = 1 Then
         String2write = "Pump 1 disabled"
         Gosub Sd_write_log

         Set Rele_pump1
      Elseif Feed_pump_select = 2 Then
         String2write = "Pumps 1+2 disabled!"
         Gosub Sd_write_log

         Set Rele_pump1
         Set Rele_pump2
      End If

   End If
Return



52_set_lights:
   If Str_time = Led1_on_time Then Led1_enabled = 1
   If Str_time = Led1_off_time Then Led1_enabled = 0        '

   If Str_time = Led2_on_time Then Led2_enabled = 1
   If Str_time = Led2_off_time Then Led2_enabled = 0

   If Str_time = Led3_on_time Then Led3_enabled = 1
   If Str_time = Led3_off_time Then Led3_enabled = 0


   If Led1_enabled = 1 And Pwm1a < Led1_pwm_on Then         'Sunrise ch 1
      If Dimming_timer1 < Dimming_step1 Then
         Incr Dimming_timer1
      Elseif Dimming_timer1 >= Dimming_step1 Then
         Incr Pwm1a
         Dimming_timer1 = 0
      End If
   End If

   If Led1_enabled = 0 And Pwm1a > Led1_pwm_off Then        'Sunset ch 1
      If Dimming_timer1 < Dimming_step1 Then
         Incr Dimming_timer1
      Elseif Dimming_timer1 >= Dimming_step1 Then
         Decr Pwm1a
         Dimming_timer1 = 0
      End If
   End If


   If Led2_enabled = 1 And Pwm1b < Led2_pwm_on Then
      If Dimming_timer2 < Dimming_step2 Then
         Incr Dimming_timer2
      Elseif Dimming_timer2 >= Dimming_step2 Then
         Incr Pwm1b
         Dimming_timer2 = 0
      End If
   End If

   If Led2_enabled = 0 And Pwm1b > Led2_pwm_off Then
      If Dimming_timer2 < Dimming_step2 Then
         Incr Dimming_timer2
      Elseif Dimming_timer2 >= Dimming_step2 Then
         Decr Pwm1b
         Dimming_timer2 = 0
      End If
   End If


   If Led3_enabled = 1 And Pwm1c < Led3_pwm_on Then
      If Dimming_timer3 < Dimming_step3 Then
         Incr Dimming_timer3
      Elseif Dimming_timer3 >= Dimming_step3 Then
         Incr Pwm1c
         Dimming_timer3 = 0
      End If
   End If

   If Led3_enabled = 0 And Pwm1c > Led3_pwm_off Then
      If Dimming_timer3 < Dimming_step3 Then
         Incr Dimming_timer3
      Elseif Dimming_timer3 >= Dimming_step3 Then
         Decr Pwm1c
         Dimming_timer3 = 0
      End If
   End If

Return



53_set_heater:
   Temp_on = Target_temp - Temp_hysteresis
   Temp_off = Target_temp + Temp_hysteresis

   If Temperatura <= Temp_on And Rele_heater = 0 Then
      Set Rele_heater
      String2write = "Heater enabled!"
      Gosub Sd_write_log
   End If

   If Temperatura >= Temp_off And Rele_heater = 1 Then
      Reset Rele_heater
      String2write = "Heater disabled!"
      Gosub Sd_write_log
   End If
Return



54_set_co2:
   Ph_on = Ph_limit + Ph_hys
   Ph_off = Ph_limit - Ph_hys

   If Ph > Ph_on And Rele_ph = 0 And Ph > 3 And Ph < 11 Then
      Set Rele_ph
      String2write = "CO2 enabled!"
      Gosub Sd_write_log
   End If

   If Ph < Ph_off And Rele_ph = 1 Then
      Reset Rele_ph
      String2write = "CO2 disabled!"
      Gosub Sd_write_log
   End If

   If Ph < 3 Or Ph > 11 And Rele_ph = 1 Then
      Reset Rele_ph
   End If

Return



55_set_skimmer:
   If Str_time = Skimmer_on1 And Rele_skimmer = 0 Then
      Set Rele_skimmer
      String2write = "Skimmer enabled!"
      Gosub Sd_write_log
   End If

   If Str_time = Skimmer_off1 And Rele_skimmer = 1 Then
      Reset Rele_skimmer
      String2write = "Skimmer disabled!"
      Gosub Sd_write_log
   End If

   If Str_time = Skimmer_on2 Then
      Set Rele_skimmer
      String2write = "Skimmer enabled!"
      Gosub Sd_write_log
   End If


   If Str_time = Skimmer_off2 Then
      Reset Rele_skimmer
      String2write = "Skimmer disabled!"
      Gosub Sd_write_log
   End If
Return



01_init:
   'Nextion konfiguracija BPS - samo enkrat!
   'Print #2, "bauds=57600" ; Chr(255) ; Chr(255) ; Chr(255);

   'Set clock
'   Time$ = "14:33:00" : Date$ = "06/05/20"
'   Gosub Set_time
'   Waitms 100
'   Gosub Get_time

   Set Led_r : Waitms Zakasnitev : Reset Led_r
   Set Led_g : Waitms Zakasnitev : Reset Led_g
   Set Led_b : Waitms Zakasnitev : Reset Led_b

   Pwm1a = 0
   Pwm1b = 0
   Pwm1c = 0

   Print #2 , Chr(028) : Waitms 100
   Print #2 , "AquaTrol startup, v." ; Version(2)

   'Bluetooth setup
   Bt_initialized = E_bt_initialized
   If Bt_initialized <> 1 And Config_bt_skip = 0 Then
      'Konfigutacija BLE modula
      Disable Interrupts
      Set Led_b

      Print #2 , "BT config"
      Print Chr(036) ; Chr(036) ; Chr(036);
      Wait 1

      Print #2 , "SS C0"
      Print "SS,C0"                                         '40
      Wait 1

      Print #2 , "S-,AquaTrol"
      Print "S-,AquaTrol"
      Wait 1

      Print #2 , "BT END"
      Print "---" ; Chr(010);
      Wait 1

      Reset Led_b
      Enable Interrupts
      Clear Serialin
      Clear Serialin1
      Bt_initialized = 1
      E_bt_initialized = Bt_initialized
   Elseif Bt_initialized = 1 Then
      'Do nothing, modul je ze sprogramiran!
   End If

   'Get RTC data
   Gosub Get_time

   'Ph kalibracija v EEPROMu
   Ph_calib_401 = E_ph_calib_401
      If Ph_calib_401 < -2.0 Or Ph_calib_401 > 2.0 Or Ph_calib_401 = 0 Then
         Ph_calib_401 = 1.8577
         E_ph_calib_401 = Ph_calib_401
      End If
   Ph_calib_700 = E_ph_calib_700
      If Ph_calib_700 < -2.0 Or Ph_calib_700 > 2.0 Or Ph_calib_700 = 0 Then
         Ph_calib_700 = 1.5317
         E_ph_calib_700 = Ph_calib_700
      End If
   Ph_calc1 = E_ph_calc1
      If Ph_calc1 < -1.0 Or Ph_calc1 > 1.0 Or Ph_calc1 = 0 Then
         Ph_calc1 = 0.1144
         E_ph_calc1 = Ph_calc1
      End If

   Ph_limit = E_ph_limit
      If Ph_limit > 10 Or Ph_limit < -10 Then
         Ph_limit = 6.50
         E_ph_limit = Ph_limit
      End If

   'SD card initialization
   If Skip_sd = 0 And Sd_missing = 0 Then
      Gosub Sd_config
      Gosub Sd_start
   End If

   'Vzamem vrednosti iz EEPROMA, ce ni kartice ali je onemogocena
   If Skip_sd = 1 Or Sd_missing = 1 Then
      'Read EEPROM
      Target_temp = E_target_temp
         If Target_temp > 400 Or Target_temp < 100 Then
            Target_temp = 250
            E_target_temp = Target_temp
         End If

      Skimmer_on1 = E_skimmer_on1
      Skimmer_off1 = E_skimmer_off1
      Skimmer_on2 = E_skimmer_on2
      Skimmer_off2 = E_skimmer_off2

      Feed_time = E_feed_time
         If Feed_time > 900 Then                            'default 5 min
            Feed_time = 300
            E_feed_time = Feed_time
         End If

      Feed_pump_select = E_feed_pump_select
         If Feed_pump_select > 2 Then                       'default disabled
            Feed_pump_select = 0
            E_feed_pump_select = Feed_pump_select
         End If

      Dimming_step1 = E_dimming_step1
         If Dimming_step1 > 2500 Or Dimming_step1 < 100 Then
            Dimming_step1 = 1000
            E_dimming_step1 = Dimming_step1
         End If

      Dimming_step2 = E_dimming_step2
         If Dimming_step2 > 2500 Or Dimming_step2 < 100 Then
            Dimming_step2 = 1000
            E_dimming_step2 = Dimming_step2
         End If

      Dimming_step3 = E_dimming_step3
         If Dimming_step3 > 2500 Or Dimming_step3 < 100 Then
            Dimming_step3 = 1000
            E_dimming_step3 = Dimming_step3
         End If

      Led1_on_time = E_led1_on_time
      Led1_off_time = E_led1_off_time
      Led1_pwm_on = E_led1_pwm_on
      Led1_pwm_off = E_led1_pwm_off
         If Led1_pwm_off > 100 Then
            Led1_pwm_off = 0
            E_led1_pwm_off = Led1_pwm_off
         End If

      Led2_on_time = E_led2_on_time
      Led2_off_time = E_led2_off_time
      Led2_pwm_on = E_led2_pwm_on
      Led2_pwm_off = E_led2_pwm_off
         If Led2_pwm_off > 100 Then
            Led2_pwm_off = 0
            E_led2_pwm_off = Led2_pwm_off
         End If

      Led3_on_time = E_led3_on_time
      Led3_off_time = E_led3_off_time
      Led3_pwm_on = E_led3_pwm_on
      Led3_pwm_off = E_led3_pwm_off
         If Led3_pwm_off > 100 Then
            Led3_pwm_off = 0
            E_led3_pwm_off = Led3_pwm_off
         End If

      Ph_limit = E_ph_limit
         If Ph_limit < 3 Or Ph_limit > 10 Then
            Ph_limit = 6.5
            E_ph_limit = Ph_limit
         End If

   End If
Return



Print_nextion:
'   Print "pwms.FF_pwm.val=" ; Out3_set ; Chr(255) ; Chr(255) ; Chr(255);
'   Print "pwms.n0.val=" ; Out3_set ; Chr(255) ; Chr(255) ; Chr(255);
Return



Print_terminal:
   Print #2 , Chr(028) : Waitms 100
   Print #2 , Date$ ; " " ; Time$
   Print #2 , "Fltr1_dis:" ; Rele_pump1 ; "(t=" ; Disable_pumps ; ")"
   Print #2 , "Fltr2_dis:" ; Rele_pump2 ; "(t=" ; Disable_pumps ; ")"
   Print #2 , "Heater:" ; Rele_heater ; "(" ; Temp_on ; "/" ; Temp_off ; ")"
   Print #2 , "Skimmer:" ; Rele_skimmer ; " " ; Skimmer_on1 ; "/" ; Skimmer_off1 ; ", " ; Skimmer_on2 ; "/" ; Skimmer_off2
   Print #2 , "CO2 valve:" ; Rele_ph ; "(" ; Ph_limit ; ")"
   Print #2 , "Aux:" ; Rele_aux
   Print #2 , "Led1:" ; Pwm1a ; "/255, " ; Led1_pwm_on ; "@" ; Led1_on_time ; "/" ; Led1_pwm_off ; "@" ; Led1_off_time
   Print #2 , "Led2:" ; Pwm1b ; "/255, " ; Led2_pwm_on ; "@" ; Led2_on_time ; "/" ; Led2_pwm_off ; "@" ; Led2_off_time
   Print #2 , "Led3:" ; Pwm1c ; "/255, " ; Led3_pwm_on ; "@" ; Led3_on_time ; "/" ; Led3_pwm_off ; "@" ; Led3_off_time
   Print #2 , ""
   Print #2 , "pH :" ; Ph ; "(U=" ; S_voltage ; "V)"
   Print #2 , "Temp :" ; Temperatura ; "oC"
   Print #2 , "AC OK:" ; Ac_ok ; : If Ac_ok = 0 Then Print #2 , "!!!" : If Ac_ok = 1 Then Print ""
   Print #2 , "IN1 feed:" ; In1 ; "(" ; Feed_time ; "s)"
   Print #2 , "IN2 light:" ; In2 ; "(step " ; Dimming_step1 ; ")"
'   Print #2 , "Adc0:" ; Adc_0
'   Print #2 , "Adc1:" ; Adc_1
'   Print #2 , "Adc2:" ; Adc_2
'   Print #2 , "Adc3:" ; Adc_3
'   Print #2 , "Adc4:" ; Adc_4
Return


Print_bt:
   Print ""
   Print Date$ ; " " ; Time$
   Print "Fltr1_dis:" ; Rele_pump1 ; "(t=" ; Disable_pumps ; ")"
   Print "Fltr2_dis:" ; Rele_pump2 ; "(t=" ; Disable_pumps ; ")"
   Print "Heater:" ; Rele_heater ; "(" ; Temp_on ; "/" ; Temp_off ; ")"
   Print "Skimmer:" ; Rele_skimmer ; " " ; Skimmer_on1 ; "/" ; Skimmer_off1 ; ", " ; Skimmer_on2 ; "/" ; Skimmer_off2
   Print "CO2 valve:" ; Rele_ph ; "(" ; Ph_limit ; ")"
   Print "Aux:" ; Rele_aux
   Print "Led1:" ; Pwm1a ; "/255, " ; Led1_pwm_on ; "@" ; Led1_on_time ; "/" ; Led1_pwm_off ; "@" ; Led1_off_time
   Print "Led2:" ; Pwm1b ; "/255, " ; Led2_pwm_on ; "@" ; Led2_on_time ; "/" ; Led2_pwm_off ; "@" ; Led2_off_time
   Print "Led3:" ; Pwm1c ; "/255, " ; Led3_pwm_on ; "@" ; Led3_on_time ; "/" ; Led3_pwm_off ; "@" ; Led3_off_time
   Print ""
   Print "pH :" ; Ph ; "(U=" ; S_voltage ; "V)"
   Print "Temp :" ; Temperatura ; "oC"
   Print "AC OK:" ; Ac_ok ; : If Ac_ok = 0 Then Print "!!!" : If Ac_ok = 1 Then Print ""
   Print "IN1 feed:" ; In1 ; "(" ; Feed_time ; "s)"
   Print "IN2 light:" ; In2 ; "(step " ; Dimming_step1 ; ")"
Return


41_read_i2c_adc:
   If I2c_tmr > 10 Then
      C = 0
      S_voltage = 0

      Do
         I2c_tmr = 0
         Disable Interrupts
         I2cstart
         I2cwbyte &B1001_0000                                  'Popravi adreso glede na ID senzorja! &B1001_0000
         I2cwbyte &B1001_1100
         I2cstop
         For I = 1 To 250
            I2cstart
            I2cwbyte &B1001_0001                            'Popravi adreso glede na ID senzorja!
            I2crbyte Byte1 , Ack
            I2crbyte Byte2 , Ack
            I2crbyte Byte3 , Ack
            I2cstop
            If Byte3.7 = 0 Then
            Exit For
            End If
            Waitms 1
          Next
         I2cstart
         I2cwbyte &B1001_0001                               'Popravi adreso glede na ID senzorja!
         I2crbyte Byte1 , Ack
         I2crbyte Byte2 , Ack
         I2crbyte Byte3 , Ack
         I2cstop
         Enable Interrupts


         Value = Makeint(byte2 , Byte1)
         S_voltage1 = Value / 15_bit
         S_voltage1 = S_voltage1 * 2.048                    'Napetost v V

         S_voltage = S_voltage + S_voltage1
         Incr C
      Loop Until C = 5

      S_voltage = S_voltage / 5

   End If

Return



41_calib_ph:
   Set Led_r : Set Led_b : Reset Led_g

   Print "Insert probe to buffer pH=7,00 in 10s and wait"
      A_ph = 60
      Do
         Print "Calibrating to pH 7,00, time remaining " ; A_ph ; "s ..."
         Decr A_ph
         Wait 1
      Loop Until A_ph = 0

      Ph_calib_700 = 0
      A_ph = 0
      I2c_tmr = 20
      Do
         Gosub 41_read_i2c_adc
         Waitms 10
         Ph_calib_700 = Ph_calib_700 + S_voltage
         Incr A_ph
      Loop Until A_ph = 10

      Ph_calib_700 = Ph_calib_700 / 10
      E_ph_calib_700 = Ph_calib_700
      Print "pH 7,00 voltage: " ; Ph_calib_700 ; "V"
      Wait 5


   Print "Put probe into destiled water"
      A_ph = 20
      Do
         Print Chr(028) : Waitms 100
         Print "Clear probe, time remaining " ; A_ph ; "s ..."
         Decr A_ph
         Wait 1
      Loop Until A_ph = 0

   Print "Insert probe to buffer pH=4,01 in 10s and wait"
      A_ph = 60
      Do
         Print Chr(028) : Waitms 100
         Print "Calibrating to pH 4,01, time remaining " ; A_ph ; "s ..."
         Decr A_ph
         Wait 1
      Loop Until A_ph = 0

      Ph_calib_401 = 0
      A_ph = 0
      I2c_tmr = 20
      Do
         Gosub 41_read_i2c_adc
         Waitms 10
         Ph_calib_401 = Ph_calib_401 + S_voltage
         Incr A_ph
      Loop Until A_ph = 10

      Ph_calib_401 = Ph_calib_401 / 10
      E_ph_calib_401 = Ph_calib_401

      Ph_calc1 = Ph_calib_401 - Ph_calib_700
      Ph_calc1 = Ph_calc1 / 3                               '1 pH

      Print "pH 4,01 voltage: " ; Ph_calib_401 ; "V"
      Print "1 pH step voltage: " ; Ph_calc1 ; "V"

      Ph_calibrated = 1
      E_ph_calibrated = Ph_calibrated

      Wait 5

      Print Chr(028) : Waitms 100
      Print "Clear probe before putting into aquarium!"

      Wait 5

      Ph_calib = 0
   Reset Led_r : Reset Led_b : Reset Led_g
Goto 02_main


41_ph_calc:
   Ph = S_voltage - Ph_calib_700
   Ph = Ph / Ph_calc1
   Ph = -ph
   Ph = Ph + 7.00
Return



42_read_inputs:
   Adc_0 = Getadc(0)
   Adc_1 = Getadc(1)
   Adc_2 = Getadc(2)
   Adc_3 = Getadc(3)
   Adc_4 = Getadc(4)

   If Button1 = 0 Then In1 = 1 : If Button1 = 1 Then In1 = 0       'Feed
      If In1 = 1 Then
         Disable_pumps = Feed_time
         Set Led_r : Set Led_b
         Wait 2
         Reset Led_r : Reset Led_b
      End If
   If Button2 = 0 Then In2 = 1 : If Button2 = 1 Then In2 = 0       'Light
      If In2 = 1 Then
         If Led1_enabled = 0 Then
            Do
               Led1_enabled = 1 : If Pwm1a < Led1_pwm_on Then Incr Pwm1a
               Led2_enabled = 1 : If Pwm1b < Led2_pwm_on Then Incr Pwm1b
               Led3_enabled = 1 : If Pwm1c < Led3_pwm_on Then Incr Pwm1c
               Waitms 50
               Toggle Led_g
            Loop Until Pwm1a = Led1_pwm_on
               Pwm1a = Led1_pwm_on
               Pwm1b = Led2_pwm_on
               Pwm1c = Led3_pwm_on
               Reset Led_g

         Elseif Led1_enabled = 1 Then                       'Izklop
            Do
               Led1_enabled = 0 : If Pwm1a > Led1_pwm_off Then Decr Pwm1a
               Led2_enabled = 0 : If Pwm1b > Led2_pwm_off Then Decr Pwm1b
               Led3_enabled = 0 : If Pwm1c > Led3_pwm_off Then Decr Pwm1c
               Toggle Led_g : Toggle Led_r
               Waitms 50
            Loop Until Pwm1a = Led1_pwm_off
               Reset Led_g : Reset Led_r
               Pwm1a = Led1_pwm_off
               Pwm1b = Led2_pwm_off
               Pwm1c = Led3_pwm_off
         End If
         Waitms 250
      End If

   If Main_detect = 1 Then
      If Ac_fail_cntr < 250 Then Incr Ac_fail_cntr
   Elseif Main_detect = 0 Then
      Ac_fail_cntr = 0
   End If

   If Ac_fail_cntr > 10 Then
      Ac_ok = 0
   Else
      Ac_ok = 1
   End If
Return


Leds_on_bt:
   If Led1_enabled = 0 Then
      Do
         Led1_enabled = 1 : If Pwm1a < Led1_pwm_on Then Incr Pwm1a
         Led2_enabled = 1 : If Pwm1b < Led2_pwm_on Then Incr Pwm1b
         Led3_enabled = 1 : If Pwm1c < Led3_pwm_on Then Incr Pwm1c
         Waitms 50
         Toggle Led_g
      Loop Until Pwm1a = Led1_pwm_on
         Pwm1a = Led1_pwm_on
         Pwm1b = Led2_pwm_on
         Pwm1c = Led3_pwm_on
         Reset Led_g

   Elseif Led1_enabled = 1 Then                       'Izklop
      Do
         Led1_enabled = 0 : If Pwm1a > Led1_pwm_off Then Decr Pwm1a
         Led2_enabled = 0 : If Pwm1b > Led2_pwm_off Then Decr Pwm1b
         Led3_enabled = 0 : If Pwm1c > Led3_pwm_off Then Decr Pwm1c
         Toggle Led_g : Toggle Led_r
         Waitms 50
      Loop Until Pwm1a = Led1_pwm_off
         Reset Led_g : Reset Led_r
         Pwm1a = Led1_pwm_off
         Pwm1b = Led2_pwm_off
         Pwm1c = Led3_pwm_off
   End If

   Switch_leds = 0
Return


43_read_1wire:
   If 1w_tmr > 10 Then
      1w_tmr = 0

      If 1w_conv = 0 Then
         Set Led_b
         Disable Interrupts
         1wreset : 1wwrite &HCC : 1wwrite &H44
         Enable Interrupts
         Reset Led_b
      Else
         Set Led_b
         Disable Interrupts
         Temp_sin = 0
         1wreset : 1wwrite &HCC : 1wwrite &HBE
         Sc_pad(1) = 1wread(9)
         1wreset
         Enable Interrupts

         If Sc_pad(9) = Crc8(sc_pad(1) , 8) Then
            Temp_sin = Temp / 16                            '16     2
            Temp_sin = Temp_sin * 10
            Temperatura = Int(temp_sin)
         End If
         Reset Led_b
      End If

      Toggle 1w_conv
   End If
Return





'********************  Set Time  ********************
'-------------------------------------------------------------------------------
Set_time:

   T_sec = Makebcd(_sec)
   T_min = Makebcd(_min)
   T_hour = Makebcd(_hour)
   T_day = Makebcd(_day)
   T_month = Makebcd(_month)
   T_year = Makebcd(_year)
   T_sec.7 = 1
   I2cstart : I2cwbyte Rtc_i2c_w : I2cwbyte 0 : I2cwbyte T_sec : I2cwbyte T_min : I2cwbyte T_hour : I2cstop
   I2cstart : I2cwbyte Rtc_i2c_w : I2cwbyte 3 : I2cwbyte &B00001001 : I2cwbyte T_day : I2cwbyte T_month : I2cwbyte T_year : I2cstop
   I2cstart : I2cwbyte Rtc_i2c_w : I2cwbyte 7 : I2cwbyte &B01000000 : I2cstop

   Print #2 , "RTC set: " ; Time$ ; " " ; Date$
   Wait 1

Return

'********************  Get Time  ********************
'-------------------------------------------------------------------------------
Get_time:
   I2cstart : I2cwbyte Rtc_i2c_w : I2cwbyte 0 : I2cstop
   I2cstart : I2cwbyte Rtc_i2c_r : I2crbyte T_sec , Ack : I2crbyte T_min , Ack : I2crbyte T_hour , Nack : I2cstop
   I2cstart : I2cwbyte Rtc_i2c_w : I2cwbyte 3 : I2cstop
   I2cstart : I2cwbyte Rtc_i2c_r : I2crbyte Clk_reg3 , Ack : I2crbyte T_day , Ack : I2crbyte T_month , Ack : I2crbyte T_year , Nack : I2cstop
   Clk_ok = 0
   If Clk_reg3.5 = 1 Then
      Clk_ok = 1
      T_sec.7 = 0 : T_month.5 = 0
      _sec = Makedec(t_sec) : _min = Makedec(t_min) : _hour = Makedec(t_hour)
      _day = Makedec(t_day) : _month = Makedec(t_month) : _year = Makedec(t_year)

   End If
   Str_time = Time$
Return

Getdatetime:
'called when date or time is read
Return

Setdate:
'called when date$ is set
Return

Settime:
'scanned when time$  is set
Return












'Rutine za branje in pisanje s SD kartice
Sd_config:
   Set Led_r
   If Sd_missing = 0 And Skip_sd = 0 Then                    'Le ob vstavljeni kartici
      Disable Interrupts
      $include "Config_MMCSD_HC.bas"
      $include "CONFIG_AVR-DOS.bas"
      Btemp1 = Initfilesystem(1)
      Enable Interrupts
      Print #2 , "SD init"
      Waitms 500
   End If
   Reset Led_r
Return



Sd_write_log:
   If Sd_missing = 0 And Skip_sd = 0 Then
      Set Led_r
      Chdir "LOG"
        File_handle = Freefile()
        File_name = "DATA.TXT"
        Open File_name For Append As #file_handle           'Append

        String2write_dt = ""                                'Na zacetek vrstice vedno vpisem DD/MM/YY HH:MM:SS
        String2write_dt = Date$
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Time$
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + String2write

        Print #file_handle , String2write_dt

        String2write = ""
        String2write_dt = ""
        Chdir "\"
        Flush #file_handle
        Close #file_handle
      Reset Led_r
   End If
Return


Sd_write_history:
   History_tmr = 0
   If Sd_missing = 0 And Skip_sd = 0 Then
      Set Led_r
      Chdir "LOG"
        File_handle = Freefile()
        File_name = "LOG.TXT"
        Open File_name For Append As #file_handle           'Append

        String2write_dt = ""                                'Na zacetek vrstice vedno vpisem DD/MM/YY HH:MM:SS
        String2write_dt = Date$
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Time$
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_pump1)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_pump2)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_heater)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_skimmer)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_ph)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(rele_aux)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(pwm1a)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(pwm1b)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(pwm1b)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(ph)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(temperatura)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(ac_ok)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(in1)
        String2write_dt = String2write_dt + ","
        String2write_dt = String2write_dt + Str(in2)

        Print #file_handle , String2write_dt

        String2write = ""
        String2write_dt = ""
        Chdir "\"
        Flush #file_handle
        Close #file_handle
      Reset Led_r
   End If
Return



Sd_start:

   Disable Interrupts
   If Sd_missing = 0 And Skip_sd = 0 Then
      Set Led_r
      Print #2 , "SD start"
      Waitms 500

      Mkdir "LOG"                                           'Log datoteke za debug
      Mkdir "CONFIG"                                        'Konfiguracijska mapa

     'Find TIME.TXT
      Strtemp3 = Dir( "TIME.TXT")
      If Strtemp3 <> "" Then
         Print #2 , "Time found!"
         File_handle = Freefile()
         Open "TIME.TXT" For Input As #file_handle
            Lineinput #file_handle , Time_temps
            Lineinput #file_handle , Date_temps
         Close #file_handle

         If Len(time_temps) = 8 And Len(date_temps) = 8 Then
            Time$ = Time_temps : Date$ = Date_temps
            Gosub Set_time
            Waitms 100
            Gosub Get_time
            If Clk_ok = 1 Then Kill "TIME.TXT"
         End If

      End If

     Chdir "\"
     File_handle = Freefile()                                                   ' dobiš prosti socket
     File_name = "About.txt"
     Open File_name For Output As #file_handle              ' odpreš datoteko za pisanje. Èe datoteka s tem imenom že obstaja, bo prepisana!

     Print #file_handle , "AquaTrol v.1.0"
     Close #file_handle

     Chdir "LOG"
     File_handle = Freefile()                                                   ' dobiš prosti socket
     File_name = "DATA.TXT"
     Open File_name For Append As #file_handle              ' odpreš datoteko za pisanje. Èe datoteka s tem imenom že obstaja, bo prepisana!

     String2write = ""
     String2write = Version(2)
     String2write = String2write + ", "
     String2write = String2write + Date$
     String2write = String2write + ", "
     String2write = String2write + Time$

     Print #file_handle , ""
     Print #file_handle , "AquaTrol startup, v." ; String2write
     String2write = ""
     Close #file_handle
     Chdir "\"

    Recheck:
    Chdir "CONFIG"
     Strtemp3 = Dir( "config.txt")
     A = Len(strtemp3)
     If A = 0 Then                                          'datoteka ne obstaja - ustvari jo!
        File_handle = Freefile()
        File_name = "CONFIG.TXT"
        Open File_name For Output As #file_handle
        Print #file_handle , "AquaTROL BASIC SETTINGS"
        Print #file_handle , "/Edit only values, keep formatting!!!/"
'        Rnd_id = Rnd(999999)                                                    'Random generacija sestmestnega IDja
'        S_rnd_id = Str(rnd_id)
'        S_rnd_id = Format(s_rnd_id , "000000")
        Print #file_handle , ""
        Print #file_handle , "_________LED 1:__________"
        Print #file_handle , "255 - power on (000-255)"
        Print #file_handle , "000 - power off (000-255)"
        Print #file_handle , "11:00:00 - on time"
        Print #file_handle , "19:00:00 - off time"
        Print #file_handle , "1000 - Dimming Step 1(0100-9999)"
        Print #file_handle , "_________LED 2:__________"
        Print #file_handle , "255 - power on (000-255)"
        Print #file_handle , "000 - power off (000-255)"
        Print #file_handle , "11:15:00 - on time"
        Print #file_handle , "18:50:00 - off time"
        Print #file_handle , "1100 - Dimming Step 1(0100-9999)"
        Print #file_handle , "_________LED 3:__________"
        Print #file_handle , "255 - power on (000-255)"
        Print #file_handle , "000 - power off (000-255)"
        Print #file_handle , "09:00:00 - on time"
        Print #file_handle , "20:00:00 - off time"
        Print #file_handle , "1200 - Dimming Step 1(0100-9999)"
        Print #file_handle , ""
        Print #file_handle , "_______TEMPERATURE_______"
        Print #file_handle , "250 - target temperature (xxx=xx.x)"
        Print #file_handle , ""
        Print #file_handle , "_________SKIMMER_________"
        Print #file_handle , "10:00:00 - on time 1"
        Print #file_handle , "10:15:00 - off time 1"
        Print #file_handle , "16:00:00 - on time 2"
        Print #file_handle , "16:15:00 - off time 2"
        Print #file_handle , ""
        Print #file_handle , "_________CO2 VALVE_______"
        Print #file_handle , "6.50 - target pH (x.xx)"
        Print #file_handle , ""
        Print #file_handle , "________FEED TIME________"
        Print #file_handle , "300 - feed time in s (xxx)"
        Print #file_handle , "1 - pumps affected (0,1,2)"
        Print #file_handle , ""
        Print #file_handle , "_____CO2 calibration______"
        Print #file_handle , "1.8577 - ph_calib_401"
        Print #file_handle , "1.5317 - ph_calib_700"
        Print #file_handle , "0.1144 - ph_calc1"

        Chdir "\"
        Flush #file_handle
        Close #file_handle
     Elseif A <> 0 Then                                                         'datoteka ye obstaja, preberi parametre
        File_handle = Freefile()
        File_name = "CONFIG.TXT"
        Open File_name For Input As #file_handle
             Line Input #file_handle , Input_string
             Line Input #file_handle , Input_string
             Line Input #file_handle , Input_string
             Line Input #file_handle , Input_string : Input_string = ""       'Prve 4 vrstice me ne zanimajo!

             'LED1
             Line Input #file_handle , Input_string         'LED1 power day
               Input_string = Left(input_string , 3)
               Led1_pwm_on = Val(input_string)
               E_led1_pwm_on = Led1_pwm_on
             Line Input #file_handle , Input_string         'power night
               Input_string = Left(input_string , 3)
               Led1_pwm_off = Val(input_string)
               E_led1_pwm_off = Led1_pwm_off
            Line Input #file_handle , Input_string          'time to turn on
               Input_string = Left(input_string , 8)
               Led1_on_time = Input_string
               E_led1_on_time = Led1_on_time
            Line Input #file_handle , Input_string          'time to turn off
               Input_string = Left(input_string , 8)
               Led1_off_time = Input_string
               E_led1_off_time = Led1_off_time
            Line Input #file_handle , Input_string          'tspeed of sunset/sunrise
               Input_string = Left(input_string , 4)
               Dimming_step1 = Val(input_string)
               E_dimming_step1 = Dimming_step1

            'LED2
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string          'LED2 power day
               Input_string = Left(input_string , 3)
               Led2_pwm_on = Val(input_string)
               E_led2_pwm_on = Led2_pwm_on
            Line Input #file_handle , Input_string          'power night
               Input_string = Left(input_string , 3)
               Led2_pwm_off = Val(input_string)
               E_led2_pwm_off = Led2_pwm_off
            Line Input #file_handle , Input_string          'time to turn on
               Input_string = Left(input_string , 8)
               Led2_on_time = Input_string
               E_led2_on_time = Led2_on_time
            Line Input #file_handle , Input_string          'time to turn off
               Input_string = Left(input_string , 8)
               Led2_off_time = Input_string
               E_led2_off_time = Led2_off_time
            Line Input #file_handle , Input_string          'tspeed of sunset/sunrise
               Input_string = Left(input_string , 4)
               Dimming_step2 = Val(input_string)
               E_dimming_step2 = Dimming_step2

            'LED3
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string          'LED3 power day
               Input_string = Left(input_string , 3)
               Led3_pwm_on = Val(input_string)
               E_led3_pwm_on = Led3_pwm_on
            Line Input #file_handle , Input_string          'power night
               Input_string = Left(input_string , 3)
               Led3_pwm_off = Val(input_string)
               E_led3_pwm_off = Led3_pwm_off
            Line Input #file_handle , Input_string          'time to turn on
               Input_string = Left(input_string , 8)
               Led3_on_time = Input_string
               E_led3_on_time = Led3_on_time
            Line Input #file_handle , Input_string          'time to turn off
               Input_string = Left(input_string , 8)
               Led3_off_time = Input_string
               E_led3_off_time = Led3_off_time
            Line Input #file_handle , Input_string          'tspeed of sunset/sunrise
               Input_string = Left(input_string , 4)
               Dimming_step3 = Val(input_string)
               E_dimming_step3 = Dimming_step3

            'TEMPERATURE
            Line Input #file_handle , Input_string
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 3)
               Target_temp = Val(input_string)
               E_target_temp = Target_temp

            'SKIMMER
            Line Input #file_handle , Input_string
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 8)
               Skimmer_on1 = Input_string
               E_skimmer_on1 = Skimmer_on1
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 8)
               Skimmer_off1 = Input_string
               E_skimmer_off1 = Skimmer_off1
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 8)
               Skimmer_on2 = Input_string
               E_skimmer_on2 = Skimmer_on2
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 8)
               Skimmer_off2 = Input_string
               E_skimmer_off2 = Skimmer_off2

            'CO2 VALVE
            Line Input #file_handle , Input_string
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 4)
               Ph_limit = Val(input_string)
               E_ph_limit = Ph_limit

            'FEED DELAY
            Line Input #file_handle , Input_string
            Line Input #file_handle , Input_string : Input_string = ""
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 3)
               Feed_time = Val(input_string)
               E_feed_time = Feed_time
            Line Input #file_handle , Input_string
               Input_string = Left(input_string , 1)
               Feed_pump_select = Val(input_string)
               E_feed_pump_select = Feed_pump_select

        Flush #file_handle
        Close #file_handle
        Chdir "\"
     End If
     Sdsize = Disksize() : Sdfree = Diskfree() : Sdused = Sdsize - Sdfree
     Print #2 , "SD: " ; Sdused ; "kB"
     Waitms 500

     Reset Led_r
   Elseif Sd_missing = 1 Then
      Print #2 , "SD error!"
   End If

   Print #2 , "Data from SD:"
   Print #2 , "L1 day:" ; Led1_pwm_on
   Print #2 , "L1 night:" ; Led1_pwm_off
   Print #2 , "L1 on:" ; Led1_on_time
   Print #2 , "L1 off:" ; Led1_off_time
   Print #2 , "Dimming step1:" ; Dimming_step1
   Print #2 , ""
   Print #2 , "L2 day:" ; Led2_pwm_on
   Print #2 , "L2 night:" ; Led2_pwm_off
   Print #2 , "L2 on:" ; Led2_on_time
   Print #2 , "L2 off:" ; Led2_off_time
   Print #2 , "Dimming step2:" ; Dimming_step2
   Print #2 , ""
   Print #2 , "L3 day:" ; Led3_pwm_on
   Print #2 , "L3 night:" ; Led3_pwm_off
   Print #2 , "L3 on:" ; Led3_on_time
   Print #2 , "L3 off:" ; Led3_off_time
   Print #2 , "Dimming step3:" ; Dimming_step3
   Print #2 , ""
   Print #2 , "Temp_set:" ; Target_temp
   Print #2 , ""
   Print #2 , "Skimmer1:" ; Skimmer_on1 ; "/" ; Skimmer_off1
   Print #2 , "Skimmer2:" ; Skimmer_on2 ; "/" ; Skimmer_off2
   Print #2 , ""
   Print #2 , "CO2:" ; Ph_limit
   Print #2 , ""
   Print #2 , "Feed:" ; Feed_time ; "," ; Feed_pump_select
   Print #2 ,
   Print #2 , "pH calib 4.01:" ; Ph_calib_401
   Print #2 , "pH calib 7.00:" ; Ph_calib_700
   Print #2 , "pH calib:" ; Ph_calc1

   Gosub Print_bt

   Wait 5

   Enable Interrupts
Return



Sd_data_send:                                               'Posiljanje preko UARTa
   If Sd_missing = 0 And Skip_sd = 0 Then
      Set Led_r
        Chdir "LOG"
        File_handle = Freefile()
        File_name = "data.txt"
        Open File_name For Input As #file_handle
        Do
          Line Input #file_handle , Input_string
          Print Input_string
          Input_string = ""
          File_end = Eof(#file_handle)
        Loop Until File_end <> 0

        Print "SENT!"

        Flush #file_handle
        Close #file_handle
        Chdir "\"
      Reset Led_r
   Elseif Sd_missing = 1 Then
         Print #2 , "SD error!"
   End If
Return


Sd_data_del:                                                'Brisanje preko UARTa
   If Sd_missing = 0 And Skip_sd = 0 Then
      Set Led_r
      Chdir "LOG"
      File_handle = Freefile()
      Kill "data.txt"
      Flush #file_handle
      Close #file_handle
      Chdir "\"
      Print "DEL OK"
      Reset Led_r
   Elseif Sd_missing = 1 Then
      Print #2 , "SD error!"
   End If
Return







Serial0charmatch:
   Pushall

   If _rs232inbuf0(_rs_bufcountr0 -1) = 13 Then
      Set Led_g

      If _rs232inbuf0(_rs_bufcountr0 -2) = 99 Then Ph_calib = 1       'c - Calibrate
      If _rs232inbuf0(_rs_bufcountr0 -2) = 108 Then Switch_leds = 1       'l - Leds

   End If

   Popall
   Clear Serialin
Return


Serial1charmatch:
   Disable Interrupts
   Pushall

   If _rs232inbuf1(_rs_bufcountr1 -1) = 13 Then
      Set Led_g

      If _rs232inbuf1(_rs_bufcountr1 -2) = 99 Then Ph_calib = 1       'c - Calibrate
      If _rs232inbuf1(_rs_bufcountr1 -2) = 108 Then Switch_leds = 1       'l - Leds

   End If

   Clear Serialin1
   Popall
   Enable Interrupts
Return


Timer0_10ms:
   Load Timer0 , Timer0reload
   Incr Timer_10ms
Return