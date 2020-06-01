' Config File-System for Version 5.5:

' === User Settings ============================================================

' Count of file-handles, each file-handle needs 524 Bytes of SRAM
Const Cfilehandles = 2                                      ' [default = 2]

' Handling of FAT-Buffer in SRAM:
' 0 = FAT- and DIR-Buffer is handled in one SRAM buffer with 561 bytes
' 1 = FAT- and DIR-Buffer is handled in separate SRAM buffers with 1078 bytes
' Parameter 1 increased speed of file-handling
Const Csepfathandle = 1                                     ' [default = 1]

' Handling of pending FAT and Directory information of open files
' 0 = FAT and Directory Information is updated every time a data sector of the file is updated
' 1 = FAT and Directory Information is only updated at FLUSH and SAVE command
' Parameter 1 increases writing speed of data significantly
Const Cfatdirsaveatend = 1                                  ' [default = 1]


' Surrounding String with Quotation Marks at the Command WRITE
' 0 = No Surrounding of strings with quotation.marks
' 1 = Surrounding of strings with quotation.marks (f.E. "Text")
Const Ctextquotationmarks = 1                               ' [default = 1]


' Write second FAT. Windows accepts a not updated second FAT
' PC-Command: chkdsk /f corrects the second FAT, it overwrites the
' second FAT with the first FAT
' set this parameter to 0 for high speed continuing saving data
' 0 = Second FAT is not updated
' 1 = Second FAT is updated if exist
Const Cfatsecondupdate = 1                                  ' [default = 1]


' Character to separate ASCII Values in WRITE - statement (and INPUT)
' Normally a comma (,) is used. but it can be changed to other values, f.E.
' to TAB (ASCII-Code 9) if EXCEL Files with Tab separated values should be
' written or read. This parameter works for WRITE and INPUT
' Parameter value is the ASSCII-Code of the separator
' 44 = comma [default]
' 9 = TAB                                   ' [default = 44]
Const Cvariableseparator = 44

' === End of User Setting ======================================================



' === Variables for AVR-DOS ====================================================

' FileSystem Basis Informationen
Dim Gldrivesectors As Long
Dim Gbdoserror As Byte
' Master Boot Record
Dim Gbfilesystem As Byte
' Partition Boot Record
Dim Gbfilesystemstatus As Byte
Dim Glfatfirstsector As Long
Dim Gbnumberoffats As Byte
Dim Glsectorsperfat As Long
Dim Glrootfirstsector As Long
Dim Gwrootentries As Word
Dim Gldatafirstsector As Long
Dim Gbsectorspercluster As Byte
Dim Glmaxclusternumber As Long
Dim Gllastsearchedcluster As Long

' Additional info
Dim Glfs_temp1 As Long

' Block für Directory Handling

Dim Gldirfirstsectornumber As Long
Dim Gwfreedirentry As Word
Dim Glfreedirsectornumber As Long
Dim Gsdir0tempfilename As String * 11
Dim Gwdir0entry As Word                                     ' Keep together with next, otherwise change _DIR
Dim Gldir0sectornumber As Long
Dim Gstempfilename As String * 11
Dim Gwdirentry As Word
Dim Gldirsectornumber As Long
Dim Gbdirbufferstatus As Byte
Dim Gbdirbuffer(512) As Byte
Const C_filesystemsramsize1 = 594
#if Csepfathandle = 1
Dim Glfatsectornumber As Long
Dim Gbfatbufferstatus As Byte
Dim Gbfatbuffer(512) As Byte
Const C_filesystemsramsize2 = 517
#else
Const C_filesystemsramsize2 = 0
#endif

' File Handle Block
Const Co_filenumber = 0
Const Co_filemode = 1
Const Co_filedirentry = 2 : Const Co_filedirentry_2 = 3
Const Co_filedirsectornumber = 4
Const Co_filefirstcluster = 8
Const Co_filesize = 12
Const Co_fileposition = 16
Const Co_filesectornumber = 20
Const Co_filebufferstatus = 24
Const Co_filebuffer = 25
Const C_filehandlesize = Co_filebuffer + 513                ' incl. one Additional Byte for 00 as string terminator
                                                            ' for direct text reading from File-buffer
Const C_filehandlesize_m = 65536 - C_filehandlesize         ' for use with add immediate word with subi, sbci
                                                            ' = minus c_FileHandleSize in Word-Format
Const C_filehandlessize = C_filehandlesize * Cfilehandles


Dim Abfilehandles(c_filehandlessize) As Byte
Const C_filesystemsramsize = C_filesystemsramsize1 + C_filesystemsramsize2 + C_filehandlessize


' End of variables for AVR-DOS ================================================

' Definitions of Constants ====================================================

' Bit definiton for FileSystemStatus

Dfilesystemstatusfat Alias 1 : Const Dfilesystemstatusfat = 1       ' 0 = FAT16, 1 = FAT32
Dfilesystemsubdir Alias 1 : Const Dfilesystemsubdir = 1     ' 0 = Root-Directory, 1 = Sub-Directory
Const Dmfilesystemsubdir =(2 ^ Dfilesystemsubdir)           ' not used yet
Const Dmfilesystemdirincluster =(2 ^ Dfilesystemstatusfat + 2 ^ Dfilesystemsubdir)       ' not used yet
Dfatsecondupdate Alias 7 : Const Dfatsecondupdate = 7       ' Bit-position for parameter of
                                                            ' Update second FAT in gbFileSystemStatus

' Bit Definitions for BufferStatus (FAT, DIR, File)

Deof Alias 1 : Const Deof = 1 : Const Dmeof =(2 ^ Deof)
Deofinsector Alias 2 : Const Deofinsector = 2 : Const Dmeofinsector =(2 ^ Deofinsector)
Dwritepending Alias 3 : Const Dwritepending = 3 : Const Dmwritepending =(2 ^ Dwritepending)
Dfatsector Alias 4 : Const Dfatsector = 4 : Const Dmfatsector =(2 ^ Dfatsector)       ' For Writing Sector back (FATNumber times)
Dfileempty Alias 5 : Const Dfileempty = 5 : Const Dmfileempty =(2 ^ Dfileempty)

' New feature for reduce saving
Dfatdirwritepending Alias 6 : Const Dfatdirwritepending = 6 : Const Dmfatdirwritepending =(2 ^ Dfatdirwritepending)
Dfatdirsaveatend Alias 7 : Const Dfatdirsaveatend = 7 : Const Dmfatdirsaveatend =(2 ^ Dfatdirsaveatend)
Dfatdirsaveanyway Alias 0 : Const Dfatdirsaveanyway = 0 : Const Dmfatdirsaveanyway =(2 ^ Dfatdirsaveanyway)

Const Dmeofall =(2 ^ Deof + 2 ^ Deofinsector)
Const Dmeof_empty =(2 ^ Deof + 2 ^ Deofinsector + 2 ^ Dfileempty)

Const Cp_fatbufferinitstatus =(2 ^ Dfatsector)
Const Cp_dirbufferinitstatus = 0

#if Cfatdirsaveatend = 1
Const Cp_filebufferinitstatus =(2 ^ Dfatdirsaveatend)
#else
Const Cp_filebufferinitstatus = 0
#endif

#if Cfatsecondupdate = 0
   Const Cp_fatsecondupdate =(2 ^ Dfatsecondupdate)
#else
   Const Cp_fatsecondupdate = 0
#endif

' Bit definitions for FileMode (Similar to DOS File Attribut)
Dreadonly Alias 0 : Const Dreadonly = 0
'Const cpFileReadOnly = &H21                ' Archiv and read-only Bit set
Const Cpfilewrite = &H20                                    ' Archiv Bit set

' Error Codes

' Group Number is upper nibble of Error-Code
' Group 0 (0-15): No Error or File End Information
Const Cpnoerror = 0
Const Cpendoffile = 1

' Group 1 (17-31): File System Init
Const Cpnombr = 17
Const Cpnopbr = 18
Const Cpfilesystemnotsupported = 19
Const Cpsectorsizenotsupported = 20
Const Cpsectorsperclusternotsupported = 21
Const Cpcountofclustersnotsupported = 22

' Group 2 (32-47): FAT - Error
Const Cpnonextcluster = 33
Const Cpnofreecluster = 34
Const Cpclustererror = 35
' Group 3 (49-63): Directory Error
Const Cpnofreedirentry = 49
Const Cpfileexists = 50
Const Cpfiledeletenotallowed = 51
Const Cpsubdirectorynotempty = 52
Const Cpsubdirectoryerror = 53
Const Cpnotasubdirectory = 54
' Group 4 (65-79): File Handle
Const Cpnofreefilenumber = 65
Const Cpfilenotfound = 66
Const Cpfilenumbernotfound = 67
Const Cpfileopennohandle = 68
Const Cpfileopenhandleinuse = 69
Const Cpfileopenshareconflict = 70
Const Cpfileinuse = 71
Const Cpfilereadonly = 72
Const Cpfilenowildcardallowed = 73
Const Cpfilenumberinvalid = 74                              ' Zero is not allowed

' Group 7 (97-127): other errors
Const Cpfilepositionerror = 97
Const Cpfileaccesserror = 98
Const Cpinvalidfileposition = 99
Const Cpfilesizetogreat = 100

Const Cpdrivererrorstart = &HC0


' Range 224 to 255 is reserved for Driver

' Other Constants
' File Open Mode /  stored in File-handle return-value of Fileattr(FN#, [1])
Const Cpfileopeninput = 1                                   ' Read
Const Cpfileopenoutput = 2                                  ' Write sequential
'Const cpFileOpenRandom = 4                 ' not in use yet
Const Cpfileopenappend = 8                                  ' Write sequential; first set Pointer to end
Const Cpfileopenbinary = 32                                 ' Read and Write; Pointer can be changed by user


' permission Masks for file access routine regarding to the file open mode
Const Cfilewrite_mode = &B00101010                          ' Binary, Append, Output
Const Cfileread_mode = &B00100001                           ' Binary, Input
Const Cfileseekset_mode = &B00100000                        ' Binary
Const Cfileinputline = &B00100001                           ' Binary, Input
Const Cfileput_mode = &B00100000                            ' Binary
Const Cfileget_mode = &B00100000                            ' Binary

' Directory attributs in FAT16/32
Const Cpfileopenallowed = &B00100001                        ' Read Only and Archiv may be set
Const Cpfiledeleteallowed = &B00100000
Const Cpfilesearchallowed = &B00111101                      ' Do no search hidden Files
' Bit 0 = Read Only
' Bit 1 = Hidden
' Bit 2 = System
' Bit 3 = Volume ID
' Bit 4 = Directory
' Bit 5 = Archiv
' Long File name has Bit 0+1+2+3 set
Dim Lastdosmem As Byte

$lib "AVR-DOS.LBX"