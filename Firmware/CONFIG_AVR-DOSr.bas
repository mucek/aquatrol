' Config File-System for Version 5.5:

' === User Settings ============================================================

' Count of file-handles, each file-handle needs 524 Bytes of SRAM
Const cFileHandles = 2                                      ' [default = 2]

' Handling of FAT-Buffer in SRAM:
' 0 = FAT- and DIR-Buffer is handled in one SRAM buffer with 561 bytes
' 1 = FAT- and DIR-Buffer is handled in separate SRAM buffers with 1078 bytes
' Parameter 1 increased speed of file-handling
Const cSepFATHandle = 1                                     ' [default = 1]

' Handling of pending FAT and Directory information of open files
' 0 = FAT and Directory Information is updated every time a data sector of the file is updated
' 1 = FAT and Directory Information is only updated at FLUSH and SAVE command
' Parameter 1 increases writing speed of data significantly
Const cFATDirSaveAtEnd = 1                                  ' [default = 1]


' Surrounding String with Quotation Marks at the Command WRITE
' 0 = No Surrounding of strings with quotation.marks
' 1 = Surrounding of strings with quotation.marks (f.E. "Text")
Const cTextQuotationMarks = 1                               ' [default = 1]


' Write second FAT. Windows accepts a not updated second FAT
' PC-Command: chkdsk /f corrects the second FAT, it overwrites the
' second FAT with the first FAT
' set this parameter to 0 for high speed continuing saving data
' 0 = Second FAT is not updated
' 1 = Second FAT is updated if exist
Const cFATSecondUpdate = 1                                 ' [default = 1]


' Character to separate ASCII Values in WRITE - statement (and INPUT)
' Normally a comma (,) is used. but it can be changed to other values, f.E.
' to TAB (ASCII-Code 9) if EXCEL Files with Tab separated values should be
' written or read. This parameter works for WRITE and INPUT
' Parameter value is the ASSCII-Code of the separator
' 44 = comma [default]
' 9 = TAB                                                  ' [default = 44]
Const cVariableSeparator = 44




' === End of User Setting ======================================================



' === Variables for AVR-DOS ====================================================

' FileSystem Basis Informationen
Dim glDriveSectors as Long
Dim gbDOSError as Byte

' Master Boot Record
Dim gbFileSystem as Byte
' Partition Boot Record
Dim gbFileSystemStatus as Byte
Dim glFATFirstSector as Long
Dim gbNumberOfFATs as Byte
Dim glSectorsPerFat as Long
Dim glRootFirstSector as Long
Dim gwRootEntries as Word
Dim glDataFirstSector as Long
Dim gbSectorsPerCluster as Byte
Dim glMaxClusterNumber as Long
Dim glLastSearchedCluster as Long

' Additional info
Dim glFS_Temp1 as Long

' Block für Directory Handling

Dim glDirFirstSectorNumber as Long

Dim gwFreeDirEntry as Word
Dim glFreeDirSectorNumber as Long

Dim gsDir0TempFileName as String * 11
Dim gwDir0Entry as Word                                     ' Keep together with next, otherwise change _DIR
Dim glDir0SectorNumber as Long

Dim gsTempFileName as String * 11
Dim gwDirEntry as Word
Dim glDirSectorNumber as Long
Dim gbDirBufferStatus as Byte
Dim gbDirBuffer(512) as Byte
Const c_FileSystemSRAMSize1 = 594
#IF cSepFATHandle = 1
Dim glFATSectorNumber as Long
Dim gbFATBufferStatus as Byte
Dim gbFATBuffer(512) as Byte
Const c_FileSystemSRAMSize2 = 517
#ELSE
Const c_FileSystemSRAMSize2 = 0
#ENDIF

' File Handle Block
Const co_FileNumber = 0
Const co_FileMode = 1
Const co_FileDirEntry = 2 : Const co_FileDirEntry_2 = 3
Const co_FileDirSectorNumber = 4
Const co_FileFirstCluster = 8
Const co_FileSize = 12
Const co_FilePosition = 16
Const co_FileSectorNumber = 20
Const co_FileBufferStatus = 24
Const co_FileBuffer = 25
Const c_FileHandleSize = co_FileBuffer + 513                ' incl. one Additional Byte for 00 as string terminator
                                                             ' for direct text reading from File-buffer
Const c_FileHandleSize_m = 65536 - c_FileHandleSize         ' for use with add immediate word with subi, sbci
                                                             ' = minus c_FileHandleSize in Word-Format

Const c_FileHandlesSize = c_FileHandleSize * cFileHandles


Dim abFileHandles(c_FileHandlesSize) as Byte
Const c_FileSystemSRAMSize = c_FileSystemSRAMSize1 + c_FileSystemSRAMSize2 + c_FileHandlesSize


' End of variables for AVR-DOS ================================================

' Definitions of Constants ====================================================

' Bit definiton for FileSystemStatus

dFileSystemStatusFAT Alias 0 : Const dFileSystemStatusFAT = 0       ' 0 = FAT16, 1 = FAT32
dFileSystemSubDir Alias 1 : Const dFileSystemSubDir = 1     ' 0 = Root-Directory, 1 = Sub-Directory
Const dmFileSystemSubDir =(2 ^ dFileSystemSubDir)           ' not used yet
Const dMFileSystemDirInCluster =(2 ^ dFileSystemStatusFAT + 2 ^ dFileSystemSubDir)       ' not used yet
dFATSecondUpdate Alias 7 : Const dFATSecondUpdate = 7       ' Bit-position for parameter of
                                                             ' Update second FAT in gbFileSystemStatus


' Bit Definitions for BufferStatus (FAT, DIR, File)

dEOF alias 1 : Const dEOF = 1 : Const dmEOF =(2 ^ dEOF)
dEOFinSector alias 2 : Const dEOFinSector = 2 : Const dmEOFinSector =(2 ^ dEOFInSector)
dWritePending alias 3 : Const dWritePending = 3 : Const dmWritePending =(2 ^ dWritePending)
dFATSector alias 4 : Const dFATSector = 4 : Const dmFATSector =(2 ^ dFATSector)       ' For Writing Sector back (FATNumber times)
dFileEmpty alias 5 : Const dFileEmpty = 5 : Const dmFileEmpty =(2 ^ dFileEmpty)

' New feature for reduce saving
dFATDirWritePending Alias 6 : Const dFATDirWritePending = 6 : Const dmFATDirWritePending =(2 ^ dFATDirWritePending)
dFATDirSaveAtEnd Alias 7 : Const dFATDirSaveAtEnd = 7 : Const dmFATDirSaveAtEnd =(2 ^ dFATDirSaveAtEnd)
dFATDirSaveAnyWay Alias 0 : Const dFATDirSaveAnyWay = 0 : Const dmFATDirSaveAnyWay =(2 ^ dFATDirSaveAnyWay)




Const dmEOFAll =(2 ^ dEOF + 2 ^ dEOFinSector)
Const dmEOF_Empty =(2 ^ dEOF + 2 ^ dEOFinSector + 2 ^ dFileEmpty)


Const cp_FATBufferInitStatus =(2 ^ dFatSector)
Const cp_DirBufferInitStatus = 0


#IF cFATDirSaveAtEnd = 1
Const cp_FileBufferInitStatus =(2 ^ dFATDIRSaveAtEnd)
#ELSE
Const cp_FileBufferInitStatus = 0
#ENDIF



#IF cFATSecondUpdate = 0
   Const cp_FATSecondUpdate =(2 ^ dFATSecondUpdate)
#ELSE
   Const cp_FATSecondUpdate = 0
#ENDIF


' Bit definitions for FileMode (Similar to DOS File Attribut)
dReadOnly alias 0 : Const dReadOnly = 0
'Const cpFileReadOnly = &H21             ' Archiv and read-only Bit set
Const cpFileWrite = &H20                                    ' Archiv Bit set


' Error Codes

' Group Number is upper nibble of Error-Code
' Group 0 (0-15): No Error or File End Information
Const cpNoError = 0
Const cpEndOfFile = 1

' Group 1 (17-31): File System Init
Const cpNoMBR = 17
Const cpNoPBR = 18
Const cpFileSystemNotSupported = 19
Const cpSectorSizeNotSupported = 20
Const cpSectorsPerClusterNotSupported = 21
Const cpCountOfClustersNotSupported = 22

' Group 2 (32-47): FAT - Error
Const cpNoNextCluster = 33
Const cpNoFreeCluster = 34
Const cpClusterError = 35
' Group 3 (49-63): Directory Error
Const cpNoFreeDirEntry = 49
Const cpFileExists = 50
Const cpFileDeleteNotAllowed = 51
Const cpSubDirectoryNotEmpty = 52
Const cpSubDirectoryError = 53
Const cpNotASubDirectory = 54
' Group 4 (65-79): File Handle
Const cpNoFreeFileNumber = 65
Const cpFileNotFound = 66
Const cpFileNumberNotFound = 67
Const cpFileOpenNoHandle = 68
Const cpFileOpenHandleInUse = 69
Const cpFileOpenShareConflict = 70
Const cpFileInUse = 71
Const cpFileReadOnly = 72
Const cpFileNoWildCardAllowed = 73
Const cpFileNumberInValid = 74                              ' Zero is not allowed

' Group 7 (97-127): other errors
Const cpFilePositionError = 97
Const cpFileAccessError = 98
Const cpInvalidFilePosition = 99
Const cpFileSizeToGreat = 100

Const cpDriverErrorStart = &HC0


' Range 224 to 255 is reserved for Driver

' Other Constants
' File Open Mode /  stored in File-handle return-value of Fileattr(FN#, [1])
Const cpFileOpenInput = 1                                   ' Read
Const cpFileOpenOutput = 2                                  ' Write sequential
'Const cpFileOpenRandom = 4              ' not in use yet
Const cpFileOpenAppend = 8                                  ' Write sequential; first set Pointer to end
Const cpFileOpenBinary = 32                                 ' Read and Write; Pointer can be changed by user


' permission Masks for file access routine regarding to the file open mode
Const cFileWrite_Mode = &B00101010                          ' Binary, Append, Output
Const cFileRead_Mode = &B00100001                           ' Binary, Input
Const cFileSeekSet_Mode = &B00100000                        ' Binary
Const cFileInputLine = &B00100001                           ' Binary, Input
Const cFilePut_Mode = &B00100000                            ' Binary
Const cFileGet_Mode = &B00100000                            ' Binary

' Directory attributs in FAT16/32
Const cpFileOpenAllowed = &B00100001                        ' Read Only and Archiv may be set
Const cpFileDeleteAllowed = &B00100000
Const cpFileSearchAllowed = &B00111101                      ' Do no search hidden Files
' Bit 0 = Read Only
' Bit 1 = Hidden
' Bit 2 = System
' Bit 3 = Volume ID
' Bit 4 = Directory
' Bit 5 = Archiv
' Long File name has Bit 0+1+2+3 set
Dim LastDosMem as Byte


$LIB "AVR-DOS.Lbx"