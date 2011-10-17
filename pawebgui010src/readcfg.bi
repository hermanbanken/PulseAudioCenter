REM
REM This file is part of the PulseAudio Web Gui project!
REM


FUNCTION CheckTrimBOM(WorkString AS STRING) AS STRING  ' Remove any BOM UTF8 header from the line
  DIM Result AS STRING = WorkString
  DIM WorkStringLen AS INTEGER = LEN(WorkString)
  IF WorkStringLen >= 3 THEN
    IF MID(WorkString, 1, 3) = CHR(239) + CHR(187) + CHR(191) THEN
      IF WorkStringLen > 3 THEN
          Result = MID(WorkString, 4)
        ELSE
          Result = ""
      END IF
    END IF
  END IF
  RETURN Result
END FUNCTION


FUNCTION ReadCFG(CFGfile AS STRING, CFGField AS STRING) AS STRING
 STATIC CfgTable(1 TO 2, 0 TO 255) AS STRING
 DIM AS STRING CfgReturnString, CfgTmpBuffer
 DIM AS INTEGER Counter

 IF CfgTable(1, 0) <> "init ok" THEN
   DIM AS INTEGER CfgFileHandler, CfgColonPos, Counter
   CfgFileHandler = FREEFILE
   CfgReturnString = ""
   Counter = 0
   CfgTable(1, 0) = "init ok"
   IF DIR(CFGfile) <> "" THEN
      OPEN CFGfile FOR INPUT AS #CfgFileHandler
      DO
         Counter += 1
         LINE INPUT #CfgFileHandler, CfgTmpBuffer
         CfgTmpBuffer = CheckTrimBOM(CfgTmpBuffer)
         IF MID(TRIM(CfgTmpBuffer), 1, 1) <> "#" THEN
           CfgColonPos = INSTR(CfgTmpBuffer, "=")
           CfgTable(1, Counter) = TRIM(MID(CfgTmpBuffer, 1, CfgColonPos - 1))
           CfgTable(2, Counter) = TRIM(MID(CfgTmpBuffer, CfgColonPos + 1))
         END IF
      LOOP UNTIL EOF(CfgFileHandler) OR Counter = 255
      CLOSE #CfgFileHandler
   END IF
   CfgTable(2, 0) = STR(Counter)
 END IF

 Counter = 0
 DO
   Counter += 1
   IF UCASE(CfgTable(1, Counter)) = UCASE(CFGField) THEN CfgReturnString = CfgTable(2, Counter)
 LOOP UNTIL CfgReturnString <> "" OR Counter >= VAL(CfgTable(2, 0))

 RETURN CfgReturnString
END FUNCTION
