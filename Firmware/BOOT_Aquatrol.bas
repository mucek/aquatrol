'-------------------------------------------------------------------------------
'                          Bootloading from MMC/SD or CF
'                    (c) Vögel Franz Josef / MCS Electronic
' Bootloader works with HEX or/and BIN files from a Mass storage device
' supported by AVR-DOS (http://members.aon.at/voegel or www.mcselec.com)
'-------------------------------------------------------------------------------
' following features are implemented:
' - check a Pin for activating bootloading
' - Check for file "BOOT.BIN" in root directory
'   If Exists
'   - Check File-length to fit in Program-area
'   - Program Content of "BOOT.BIN" to Flash
'   - Rename File "BOOT.BIN" to "BOOTDONE.BIN"
'   - Leave Bootloader and start Main Program
' - Check for file "boot.hex" in root directory
'   If Exists:
'   - Check the Hex-File(record-format) with file-length
'   - program flash with content of the Hex-File
'   - Rename File "BOOT.HEX" to "BOOTDONE.HEX"
'   - Leave Bootloader and start Main Program
'-------------------------------------------------------------------------------
' The following features are implemented to prevent an unintentional flashing
' - Check level of a Pin
' - Check for a special File-name
' - Rename a file after flashing
'-------------------------------------------------------------------------------
' In Case that a checked point fails, the main program is started immediately
'
' The program to flash must be stored either in HEX-Format (BOOT.HEX) or in BIN-Format
' (BOOT.BIN) in the root Directory of the card at start time.
' The Bootloader has a size of appr. 7300 Bytes, so Boot-loader size of 8192 Bytes
' have to be set. Set bootloader-start to &HF000 at M128 and &H7000 at M64.
'-------------------------------------------------------------------------------
' Output of bootloader on RS232
' B ... Boot loader started
' C ... Check Card
' D ... Init DOS File System
' N ... No boot file found
' F ... Checking HEX-File
' I ... DOS-Error during file-opening
' S ... Size-Error of Flash-File
' R ... Renaming file
' M ... Start of Main program
' e## . Error occured with errorcode in hex-format(##)
'-------------------------------------------------------------------------------
' !!!! Important
' Change in CONFIG_AVR-DOS.BAS the line
' Const cFileGet_Mode = &B00100000                   ' Old line
' to
' Const cFileGet_Mode = &B00100001                   ' New Line
' This allows AVR-DOS to use GET in a file opened in INPUT mode
'                            (INPUT use less code than BINARY)
'-------------------------------------------------------------------------------

'FARMTECH v.3 mod

$regfile = "m64def.dat"
$hwstack = 64
$swstack = 32
$framesize = 64
$crystal = 11059200
$baud = 57600

Const Loaderchip = 64

$loader = &H7000                                            '4096 words required for AVR-DOS bootloader
Const Maxwordbit = 7                                        'Z7 is maximum bit
Const Loadsize = &H7000 * 2                                 'highest Number of bytes to load

' Define here name of Hex-File
Const Filenamehex = "aquatrol.hex"
Const Filenamebin = "aquatrol.bin"

' Name of Hex or Bin-File after successfully bootloading

'Const Filenamehexdone = "BootDone.hex"
'Const Filenamebindone = "BootDone.Bin"

'---- Start Boot loader if Pine.7 is set to Ground -----------------------------
'Config Pine.7 = Input

'If Pine.7 = 1 Then                                          ' no "jumper" to GND?
'   Goto Startmain                                           ' Leave boot loader
'End If

Config Porte.4 = Output : Led1_gr Alias Porte.4
Config Porte.5 = Output : Led1_bl Alias Porte.5

Config Pinb.4 = Input : Sd_out Alias Pinb.4

Dim A As Word

Led1_gr = 0
Led1_bl = 1

For A = 1 To 6
   Toggle Led1_gr
   Toggle Led1_bl
   Waitms 200
Next

Led1_gr = 0
Led1_bl = 0

If Sd_out = 1 Then                                          ' No SD Card?
   Goto Startmain                                           ' Leave boot loader
End If

'-------------------------------------------------------------------------------
Disable Interrupts

Print
Print "Boot"
' Boot-loader Started
Waitms 500                                                  ' Time for Card to settle
'-------------------------------------------------------------------------------

Dim Btemp1 As Byte

'$include "Config_MMC.bas"
$include "Config_MMCSD_HC.bas"

' Check success of card initializing
If Gbdriveerror <> 0 Then
   Print "Err init " ; Hex(gbdriveerror) ;                  ' Error during card initializing
   Goto Startmain
End If

' Include AVR-DOS Configuration and library

$include "Config_AVR-DOS_boot.BAS"

Btemp1 = Initfilesystem(1)                                  ' Get File system
                                                    ' use 0 for drive without Master boot record

If Btemp1 <> 0 Then
   Print "Err read " ; Hex(btemp1) ;                        ' Error at reading file system
   Goto Startmain
End If

Dim _sec As Byte , _min As Byte , _hour As Byte , _day As Byte , _month As Byte , _year As Byte
Const _userclock = 0


Const Maxword =(2 ^ Maxwordbit) * 2                         '128
Const Maxwordshift = Maxwordbit + 1
Const Maxpages = Loadsize / Maxword

Const Fn = 10                                               ' file-number

'Dim the used variables
Dim Strline As String * 80                                  ' input line from file
Dim Blinebytes As Byte                                      ' data bytes in hex-line
Dim Blinedataposition As Byte                               ' first/current position of hex-data in line
Dim Blineendposition As Byte
Dim Blinestatus As Byte
Dim Blinelen As Byte
Dim Strtemp As String * 4
Dim Berror As Byte

Dim Strname1 As String * 12
Dim Strname2 As String * 12

Dim J As Byte , Spmcrval As Byte                            ' self program command byte value
Dim Bprog As Byte

Dim Z As Long                                               'this is the Z pointer word
Dim Vl As Byte , Vh As Byte                                 ' these bytes are used for the data values
Dim Wrd As Word , Page As Word                              'these vars contain the page and word address


Dim Bcrc As Byte
Dim Buf(128) As Byte
Dim Bufpointer As Byte
Dim Lfilelen As Long


Disable Interrupts                                          'we do not use ints


Lfilelen = Filelen(filenamebin)

If Lfilelen > 0 Then

   If Lfilelen < Loadsize Then

      Gosub Flashbin                                        ' Size OK
   Else
      Print "Err flash size" ;                              ' Wrong Flash Size
   End If

Else

   Lfilelen = Filelen(filenamehex)
   If Lfilelen > 0 Then
      Gosub Flashhex
   Else
      'Print "N"
   End If

End If

Startmain:
'Print "M"

Close #fn
Kill Filenamebin

Led1_gr = 0
Led1_bl = 0

Goto _reset
End

'--- HEX-File Part -------------------------------------------------------------
Flashhex:
' 1. check Hex-File
Bprog = 0                                                   ' check Intel Hex File

'Print "F" ;
Gosub Bootload


' 2. Flash from Hex-File
Bprog = 1                                                   ' program flash

'Print "P" ;
Led1_gr = 1
Led1_bl = 1

Gosub Bootload


#if Varexist( "FileNameHexDone")
      Strname1 = Filenamehex
      Strname2 = Filenamehexdone
      Kill Strname2
      'Print "R" ;
      Name Strname1 As Strname2
#endif


Goto Startmain:


' Boot loader part (same for File-Checking and Flashing)
Bootload:

Open Filenamehex For Input As #fn
If Gbdoserror > 0 Then
   Print "I" ; Hex(gbdoserror) ;
   Goto Startmain
End If


Page = 0
Wrd = 0

If Bprog = 1 Then
   Spmcrval = 3 : Gosub Do_spm                              ' erase  the first page
   Spmcrval = 17 : Gosub Do_spm                             ' re-enable page
End If


Berror = 0
Bufpointer = 1
Blinebytes = 0
Lfilelen = 0

Do

   If Blinebytes = 0 Then
      Gosub Loadhexfileline
   End If


   Select Case Blinestatus

      Case 0                                                ' read normal data line

         Lfilelen = Lfilelen + Blinebytes
         If Lfilelen > Loadsize Then

            Print "Err flash size" ;                        ' Wrong Flash Size
            Berror = 1
            Exit Do

         End If


         For Blinedataposition = Blinedataposition To Blineendposition Step 2

            Strtemp = Mid(strline , Blinedataposition , 2)
            Btemp1 = Hexval(strtemp)
            Buf(bufpointer) = Btemp1
            Incr Bufpointer
            If Bufpointer > 128 Then
               Gosub Writepage
               Bufpointer = 1
            End If
            Decr Blinebytes
         Next

      Case 1                                                ' address extend record

         Blinebytes = 0                                     ' prepare for reading next line
         ' Address extend line, do nothing

      Case 2
                                                      ' EOF Line read

         If Bufpointer > 1 Then
            Gosub Writepage
         End If
         If Wrd > 0 Then
            Wrd = 0
            Spmcrval = 5 : Gosub Do_spm
            Spmcrval = 17 : Gosub Do_spm
         End If
         Exit Do

      Case Else                                             ' Error

         Print "Le" ; Hex(blinestatus) ; " " ;
         Berror = 1
         Exit Do

   End Select

Loop


Close #fn

If Berror > 0 Then
   Goto Startmain                                           ' restart in case of error
End If

Return

Loadhexfileline:

   If Eof(#fn) <> 0 Then
      Blinestatus = 8                                       ' no regular end of File
      Return
   End If

   Line Input #fn , Strline

   If Gbdoserror <> 0 Then
      Blinestatus = 7
      Return
   End If

   Strtemp = Mid(strline , 1 , 1)                           ' check for starting ":"
   If Strtemp <> ":" Then
      Blinestatus = 6
      Return
   End If

   ' Check Checksum
   Blinelen = Len(strline)
   Bcrc = 0
   For Btemp1 = 2 To Blinelen Step 2
      Strtemp = Mid(strline , Btemp1 , 2)
      Bcrc = Bcrc + Hexval(strtemp)
   Next

   If Bcrc <> 0 Then
      Blinestatus = 9
      Return
   End If


   ' Number of bytes

   Strtemp = Mid(strline , 2 , 2)
   Blinebytes = Hexval(strtemp)
   If Blinebytes > 0 Then
      Blinedataposition = 10
      Btemp1 = Blinebytes * 2
      Blineendposition = Btemp1 + 8
   End If

   ' Type of Record

   Strtemp = Mid(strline , 8 , 2)

   Select Case Strtemp

      Case "00"                                             ' normal data record

         Blinestatus = 0

      Case "01"                                             ' address extend record (> 64KB)
         Blinestatus = 2

      Case "02"                                             ' EOF record
         Blinestatus = 1

      Case Else                                             ' unknown record type (Error?)
         Blinestatus = 5

   End Select

Return

'write one or more pages

Writepage:

   For J = 1 To 128 Step 2                                  ' we write 2 bytes into a page
      Vl = Buf(j) : Vh = Buf(j + 1)                         ' get Low and High bytes
      Spmcrval = 1 : Gosub Do_spm                           ' write value into page at word address
      Wrd = Wrd + 2                                         ' word address increases with 2 because LS bit of Z is not used
      If Wrd = Maxword Then
          Wrd = 0                                           ' Z pointer needs wrd to be 0
          Spmcrval = 5 : Gosub Do_spm                       ' write page
          Spmcrval = 17 : Gosub Do_spm                      ' re-enable page

          Page = Page + 1                                   ' next page

          If Page <= Maxpages Then                          ' avoid to erase first page of bootlaoder

             Spmcrval = 3 : Gosub Do_spm                    ' erase  next page
             Spmcrval = 17 : Gosub Do_spm                   ' re-enable page

          End If

      End If
   Next
Return

Do_spm:

   Z = Page                                                 'make equal to page
   Shift Z , Left , Maxwordshift                            'shift to proper place
   Z = Z + Wrd

   If Bprog <> 1 Then
      Return
   End If

   Bitwait Spmcsr.0 , Reset                                 ' check for previous SPM complete
   Bitwait Eecr.1 , Reset
                                      'wait for eeprom                                                 'add word
   !lds r30,{Z}
   !lds r31,{Z+1}

   #if Loaderchip = 128
      lds r24,{Z+2}
      sts rampz,r24                                         ' we need to set rampz also for the M128
   #endif

   #if _romsize > 65536
      lds r24,{Z+2}
      sts rampz,r24                                         'set rampz for chips with >64KB Flash
   #endif

   !lds r0, {vl}                                            'store them into r0 and r1 registers
   !lds r1, {vh}
   Spmcsr = Spmcrval                                        'assign register
   !spm                                                     'this is an asm instruction
   !nop
   !nop

   Incr A
   If A >= 1000 Then
      A = 0
      Toggle Led1_gr
      Toggle Led1_bl
   End If

Return

'--- BIN-File Part -------------------------------------------------------------
Flashbin:

'Print "P" ;

Led1_gr = 1
Led1_bl = 1

Dim W1 As Word , B1 As Byte

Bprog = 1
Open Filenamebin For Input As #fn

If Gbdoserror > 0 Then
   Print "I" ; Hex(gbdoserror)
   Goto Startmain
End If


Page = 0
Wrd = 0

If Bprog = 1 Then
   Spmcrval = 3 : Gosub Do_spm                              ' erase  the first page
   Spmcrval = 17 : Gosub Do_spm                             ' re-enable page
End If


Do

   Get #fn , Buf(1) , , 128
   Gosub Writepage
   If Eof(fn) > 0 Then
      If Wrd > 0 Then
         Wrd = 0
         Spmcrval = 5 : Gosub Do_spm
         Spmcrval = 17 : Gosub Do_spm
      End If

      Exit Do

   End If

Loop

Return