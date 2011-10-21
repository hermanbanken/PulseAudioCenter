REM
REM PaWebGUI - A web GUI for PulseAudio
REM

CONST pVer AS STRING = "0.10"
Const pDate As String = "2010"

REM #INCLUDE ONCE readcfg.vb
REM #INCLUDE ONCE "htmlize.bi"

REM Declare some general-purpose variables
DIM AS INTEGER x, y, z, PulseHandler, TestHandler, DebugLevel
DIM AS STRING a, b, c, HomeDir
DIM DisplayTab AS BYTE = 1 ' by default, display the first tab
DIM DisplayOutConf AS INTEGER = -1
PulseHandler = FREEFILE
TYPE PaParams
  DefaultSink AS INTEGER
END TYPE
DIM PaGeneralParams AS PaParams

HomeDir = ReadCFG(EXEPATH + "/pawebgui.cfg", "HomeDir")
DebugLevel = VAL(ReadCFG(EXEPATH + "/pawebgui.cfg", "Debug"))

REM Output the HTTP (partial) header
PRINT "Content-type: text/html; charset=utf-8"
PRINT

SETENVIRON("HOME=" + HomeDir)  ' Otherwise pacmd complains about his home directory :-/

REM Check if we got any command, and if so - execute it
IF LEN(ENVIRON("QUERY_STRING")) >= 9 THEN
  SELECT CASE LEFT(UCASE(ENVIRON("QUERY_STRING")), 3)
    CASE "MUT" ' Eg. MUT001000 to mute the idx 1, and MUT001001 to unmute it
      DisplayTab = 1
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      y = VAL(MID(ENVIRON("QUERY_STRING"), 9, 1))
      IF y = 0 THEN
          OPEN PIPE "pacmd set-sink-input-mute " & x & " 0" FOR INPUT AS #PulseHandler
          WHILE NOT EOF(PulseHandler)
            LINE INPUT #PulseHandler, c
          WEND
          CLOSE #PulseHandler
        ELSE
          OPEN PIPE "pacmd set-sink-input-mute " & x & " 1" FOR INPUT AS #PulseHandler
          WHILE NOT EOF(PulseHandler)
            LINE INPUT #PulseHandler, c
          WEND
          CLOSE #PulseHandler
      END IF
    CASE "VOL" ' Eg. VOL020095 to make volume at 95% for idx 20
      DisplayTab = 1
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      y = VAL(MID(ENVIRON("QUERY_STRING"), 7, 3))
      OPEN PIPE "pacmd set-sink-input-volume " & x & " " & INT(65535 * y / 100) FOR INPUT AS #PulseHandler
      WHILE NOT EOF(PulseHandler)
        LINE INPUT #PulseHandler, c
      WEND
      CLOSE #PulseHandler
    CASE "SMT" ' Mute given sink. Eg. SMT001000 to mute the sink #1, and SMT001001 to unmute it
      DisplayTab = 2
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      y = VAL(MID(ENVIRON("QUERY_STRING"), 9, 1))
      IF y = 0 THEN
          OPEN PIPE "pacmd set-sink-mute " & x & " 0" FOR INPUT AS #PulseHandler
          WHILE NOT EOF(PulseHandler)
            LINE INPUT #PulseHandler, c
          WEND
          CLOSE #PulseHandler
        ELSE
          OPEN PIPE "pacmd set-sink-mute " & x & " 1" FOR INPUT AS #PulseHandler
          WHILE NOT EOF(PulseHandler)
            LINE INPUT #PulseHandler, c
          WEND
          CLOSE #PulseHandler
      END IF
    CASE "SVL" ' Sets sink's volume, Eg. SVL002070 to set sink #2 to 70% volume
      DisplayTab = 2
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      y = VAL(MID(ENVIRON("QUERY_STRING"), 7, 3))
      OPEN PIPE "pacmd set-sink-volume " & x & " " & INT(65535 * y / 100) FOR INPUT AS #PulseHandler
      WHILE NOT EOF(PulseHandler)
        LINE INPUT #PulseHandler, c
      WEND
      CLOSE #PulseHandler
    CASE "MOV" ' Move sink-input to another sink. Eg. MOV028002 moves the 028 app to sink #2
      DisplayTab = 1
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      y = VAL(MID(ENVIRON("QUERY_STRING"), 7, 3))
      OPEN PIPE "pacmd move-sink-input " & x & " " & y FOR INPUT AS #PulseHandler
      WHILE NOT EOF(PulseHandler)
        LINE INPUT #PulseHandler, c
      WEND
      CLOSE #PulseHandler
    CASE "TAB" ' No action, just display the given conf tab
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      IF x >= 1 AND x <= 3 THEN DisplayTab = x
    CASE "SDS" ' Set Default Sink - sets the def. sink (eg. SDS028000 to make the sink #28 default)
      DisplayTab = 2
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 3))
      OPEN PIPE "pacmd set-default-sink " & x FOR INPUT AS #PulseHandler
      WHILE NOT EOF(PulseHandler)
        LINE INPUT #PulseHandler, c
      WEND
      CLOSE #PulseHandler
    CASE "CFG" ' Open the configuration of an output sink for sink idx
      DisplayTab = 1
      x = VAL(MID(ENVIRON("QUERY_STRING"), 4, 6))
      DisplayOutConf = x
  END SELECT
END IF


REM Get PulseAudio data
TYPE PaApp
  Index AS INTEGER
  Name AS STRING
  sysName AS STRING
  Volume AS INTEGER
  Muted AS INTEGER
  Username AS STRING
  Userhost AS STRING
  Icon AS STRING
  OutSink AS INTEGER
END TYPE
DIM PaAppList(1 TO 100) AS PaApp
DIM PaAppListSize AS INTEGER = 0
TYPE PaSink
  Index AS INTEGER
  AlsaName AS STRING
  AlsaLongName AS STRING
  Volume AS INTEGER
  Muted AS INTEGER
END TYPE
DIM PaSinkList(1 TO 100) AS PaSink
DIM PaSinkListSize AS INTEGER = 0


REM Get informations about PulseAudio sinks
OPEN PIPE "pacmd list-sinks" FOR INPUT AS #PulseHandler

WHILE NOT EOF(PulseHandler)
  LINE INPUT #PulseHandler, a
  a = TRIM(a, Any " " + CHR(9))
  IF DebugLevel > 0 THEN
    PRINT "<!-- " + a + " -->"     ' For debug purposes
  END IF
  IF LEFT(a, 8) = "* index:" THEN
    IF PaSinkListSize < UBOUND(PaSinkList) THEN PaSinkListSize += 1
    PaSinkList(PaSinkListSize).Index = VAL(MID(a, 9))
    PaGeneralParams.DefaultSink = PaSinkList(PaSinkListSize).Index
  END IF
  IF LEFT(a, 6) = "index:" THEN
    IF PaSinkListSize < UBOUND(PaSinkList) THEN PaSinkListSize += 1
    PaSinkList(PaSinkListSize).Index = VAL(MID(a, 7))
  END IF
  IF LEFT(a, 7) = "volume:" THEN
    PaSinkList(PaSinkListSize).Volume = VAL(MID(a, INSTR(a, "%") - 3, 3))
  END IF
  IF LEFT(a, 6) = "muted:" THEN
    IF LCASE(TRIM(MID(a, 7))) = "no" THEN
        PaSinkList(PaSinkListSize).Muted = 0
      ELSE
        PaSinkList(PaSinkListSize).Muted = 1
    END IF
  END IF
  IF LEFT(a, 14) = "alsa.card_name" THEN
    z = 0
    b = ""
    FOR y = 16 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaSinkList(PaSinkListSize).AlsaName = b
  END IF
  IF LEFT(a, 19) = "alsa.long_card_name" THEN
    z = 0
    b = ""
    FOR y = 16 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaSinkList(PaSinkListSize).AlsaLongName = b
  END IF
WEND
CLOSE #PulseHandler


REM Get informations about PulseAudio applications
OPEN PIPE "pacmd list-sink-inputs" FOR INPUT AS #PulseHandler

WHILE NOT EOF(PulseHandler)
  LINE INPUT #PulseHandler, a
  a = TRIM(a, Any CHR(9) + " *")
  ' PRINT "<!-- " + a + " -->"     ' For debug purposes
  IF LEFT(a, 6) = "index:" THEN
    IF PaAppListSize < UBOUND(PaAppList) THEN PaAppListSize += 1
    PaAppList(PaAppListSize).Index = VAL(MID(a, 7))
  END IF
  IF LEFT(a, 5) = "sink:" THEN
    PaAppList(PaAppListSize).OutSink = VAL(MID(a, 6))
  END IF
  IF LEFT(a, 7) = "volume:" THEN
    PaAppList(PaAppListSize).Volume = VAL(MID(a, INSTR(a, "%") - 3, 3))
  END IF
  IF LEFT(a, 6) = "muted:" THEN
    IF LCASE(TRIM(MID(a, 7))) = "no" THEN
        PaAppList(PaAppListSize).Muted = 0
      ELSE
        PaAppList(PaAppListSize).Muted = 1
    END IF
  END IF
  IF LEFT(a, 16) = "application.name" THEN
    z = 0
    b = ""
    FOR y = 16 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaAppList(PaAppListSize).Name = b
  END IF
  IF LEFT(a, 24) = "application.process.user" THEN
    z = 0
    b = ""
    FOR y = 25 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaAppList(PaAppListSize).Username = b
  END IF
  IF LEFT(a, 24) = "application.process.host" THEN
    z = 0
    b = ""
    FOR y = 25 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaAppList(PaAppListSize).Userhost = b
  END IF
  IF LEFT(a, 26) = "application.process.binary" THEN
    z = 0
    b = ""
    FOR y = 25 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaAppList(PaAppListSize).sysName = b
  END IF
  IF LEFT(a, 21) = "application.icon_name" THEN
    z = 0
    b = ""
    FOR y = 25 TO LEN(a)
      IF MID(a, y, 1) = CHR(34) THEN
          z += 1
        ELSE
          IF z = 1 THEN b += MID(a, y, 1)
      END IF
    NEXT y
    PaAppList(PaAppListSize).Icon = LCASE(b)
  END IF
WEND
CLOSE #PulseHandler
FOR x = 1 TO PaAppListSize ' Check for missing informations, and replace if needed
  IF LEN(PaAppList(x).Name) = 0 THEN PaAppList(x).Name = PaAppList(x).sysName
  IF LEN(PaAppList(x).Icon) = 0 THEN PaAppList(x).Icon = LCASE(PaAppList(x).sysName)
NEXT x


REM Output the html mess
PRINT "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.01 Transitional//EN"" ""http://www.w3.org/TR/html4/loose.dtd"">"
PRINT "<html>"
PRINT "  <head>"
PRINT "    <title>PulseAudio web GUI</title>"
PRINT "    <meta http-equiv=""content-type"" content=""text/html; charset=utf-8"">"
PRINT "    <link rel=""Stylesheet"" type=""text/css"" href=""style.css"">"
PRINT "    <link rel=""shortcut icon"" href=""favicon.png"">"

IF DisplayOutConf >= 0 THEN
    PRINT "    <meta http-equiv=""refresh"" content=""10; URL=" + ENVIRON("SCRIPT_NAME") + "?CFG" + RIGHT("000000" & DisplayOutConf, 6) + """>"
  ELSE
    PRINT "    <meta http-equiv=""refresh"" content=""10; URL=" + ENVIRON("SCRIPT_NAME") + "?TAB" + RIGHT("000" & DisplayTab, 3) + "000"">"
END IF

PRINT "  </head>"
PRINT
PRINT "  <body>"
PRINT "    <p class=""maintitle"">PulseAudio web GUI v" + pVer + "</p>"
PRINT
PRINT "    <table class=""tabtable"">"
PRINT "      <tr>"
IF DisplayTab = 1 THEN PRINT "        <td class=""activetab"">"; ELSE PRINT "        <td>";
PRINT "<a href=""" + ENVIRON("SCRIPT_NAME") + "?TAB001000" + """>Input sinks</a></td>"
IF DisplayTab = 2 THEN PRINT "        <td class=""activetab"">"; ELSE PRINT "        <td>";
PRINT "<a href=""" + ENVIRON("SCRIPT_NAME") + "?TAB002000" + """>Output sinks</a></td>"
IF DisplayTab = 3 THEN PRINT "        <td class=""activetab"">"; ELSE PRINT "        <td>";
PRINT "<a href=""" + ENVIRON("SCRIPT_NAME") + "?TAB003000" + """>Informations</a></td>"
PRINT "      </tr>"
PRINT "    </table>"
PRINT

SELECT CASE DisplayTab
  CASE 1 ' Input sinks
    PRINT "    <table class=""contenttable"">"
    IF PaAppListSize = 0 THEN
        PRINT "      <tr><td>No clients connected to the PulseAudio daemon.</td></tr>"
      ELSE
        FOR x = 1 TO PaAppListSize
          PRINT "      <tr>"
          TestHandler = FREEFILE
          IF OPEN(EXEPATH + "/" + PaAppList(x).Icon + ".png", FOR INPUT, AS #TestHandler) = 0 THEN
              CLOSE #TestHandler
              c = PaAppList(x).Icon + ".png"
            ELSE
              c = "noicon.png"
          END IF
          PRINT "        <td class=""tdApp""><img src=""" + c + """ class=""AppIcon"" title=""" + PaAppList(x).Icon + """>" + PaAppList(x).Name + "<span class=""ownerspan""><br>Owner: " + PaAppList(x).Username + "@" + PaAppList(x).Userhost + "</span></td>"
          IF PaAppList(x).Muted = 0 THEN
              PRINT "        <td class=""tdMute""><a href=""" + ENVIRON("SCRIPT_NAME") + "?MUT" + RIGHT("000" & PaAppList(x).Index, 3) + "001"" title=""mute""><img src=""unmuted.png"" class=""unmuted""></a></td>"
            ELSE
              PRINT "        <td class=""tdMute""><a href=""" + ENVIRON("SCRIPT_NAME") + "?MUT" + RIGHT("000" & PaAppList(x).Index, 3) + "000"" title=""unmute""><img src=""muted.png"" class=""muted""></a></td>"
          END IF
          PRINT "        <td class=""tdVol"">";
          FOR y = 1 TO 100
            PRINT "<a href=""" + ENVIRON("SCRIPT_NAME") + "?VOL" + RIGHT("000" & PaAppList(x).Index, 3) + RIGHT("000" & (y), 3) + """ title=""" & (y) & "%""><img src=""vol.png"" class=""";
            IF PaAppList(x).Volume >= (y) THEN
                PRINT "vol1";
              ELSE
                PRINT "vol2";
            END IF
            PRINT """></a>";
          NEXT y
          PRINT " (Vol: " & PaAppList(x).Volume & "%)";
          PRINT "</td>"
          PRINT "        <td class=""tdOut"">"

          FOR y = 1 TO PaSinkListSize
            IF PaSinkList(y).Index = PaAppList(x).OutSink THEN
                IF PaAppList(x).Index = DisplayOutConf THEN
                    PRINT "          <a href=""" + ENVIRON("SCRIPT_NAME") + "?TAB001000"" class=""OutSinkActiveItem"">" + PaSinkList(y).AlsaName + "</a>";
                  ELSE
                    PRINT "          <a href=""" + ENVIRON("SCRIPT_NAME") + "?CFG" + RIGHT("000000" & PaAppList(x).Index, 6) + """ class=""OutSinkActiveItem"">" + PaSinkList(y).AlsaName + "</a>";
                END IF
                IF y < PaSinkListSize THEN PRINT "<br>" ELSE PRINT
              ELSE
                IF DisplayOutConf = PaAppList(x).Index THEN
                  PRINT "          <a href=""" + ENVIRON("SCRIPT_NAME") + "?MOV" + RIGHT("000" & PaAppList(x).Index, 3) + RIGHT("000" & PaSinkList(y).Index, 3) + """ class=""OutSinkItem"">" + PaSinkList(y).AlsaName + "</a>";
                  IF y < PaSinkListSize THEN PRINT "<br>" ELSE PRINT
                END IF
            END IF
          NEXT y
          PRINT "        </td>"
          PRINT "      </tr>"
        NEXT x
    END IF
    PRINT "    </table>"
  CASE 2  ' Output sinks
    PRINT "    <table class=""contenttable"">"
    IF PaSinkListSize = 0 THEN
        PRINT "      <tr><td>No PulseAudio sink detected.</td></tr>"
      ELSE
        FOR x = 1 TO PaSinkListSize
          PRINT "      <tr>"
          TestHandler = FREEFILE

          IF PaGeneralParams.DefaultSink = PaSinkList(x).Index THEN
              PRINT "        <td class=""tdDefSink""><img src=""sndcard.png"" class=""CardIcon"" title=""[" & PaSinkList(x).Index & "] " + PaSinkList(x).AlsaLongName + """>" + PaSinkList(x).AlsaName + " (default)</td>"
            ELSE
              PRINT "        <td class=""tdSink""><img src=""sndcard.png"" class=""CardIcon"" title=""[" & PaSinkList(x).Index & "] " + PaSinkList(x).AlsaLongName + """><a href=""" + ENVIRON("SCRIPT_NAME") + "?SDS" + RIGHT("000" & PaSinkList(x).Index, 3) + "000"" title=""Set this sink as the default output"">" + PaSinkList(x).AlsaName + "</a></td>"
          END IF
          IF PaSinkList(x).Muted = 0 THEN
              PRINT "        <td class=""tdMute""><a href=""" + ENVIRON("SCRIPT_NAME") + "?SMT" + RIGHT("000" & PaSinkList(x).Index, 3) + "001"" title=""mute""><img src=""unmuted.png"" class=""unmuted""></a></td>"
            ELSE
              PRINT "        <td class=""tdMute""><a href=""" + ENVIRON("SCRIPT_NAME") + "?SMT" + RIGHT("000" & PaSinkList(x).Index, 3) + "000"" title=""unmute""><img src=""muted.png"" class=""muted""></a></td>"
          END IF
          PRINT "        <td class=""tdVol"">";
          FOR y = 1 TO 100
            PRINT "<a href=""" + ENVIRON("SCRIPT_NAME") + "?SVL" + RIGHT("000" & PaSinkList(x).Index, 3) + RIGHT("000" & (y), 3) + """ title=""" & (y) & "%""><img src=""vol.png"" class=""";
            IF PaSinkList(x).Volume >= (y) THEN
                PRINT "vol1";
              ELSE
                PRINT "vol2";
            END IF
            PRINT """></a>";
          NEXT y
          PRINT " (Vol: " & PaSinkList(x).Volume & "%)";
          PRINT "</td>"
          PRINT "      </tr>"
        NEXT x
    END IF
    PRINT "    </table>"
  CASE 3
    PRINT "    <p class=""sysinfoHeader"">System statistics:</p>"
    PRINT "    <p class=""sysinfo"">"
    PulseHandler = FREEFILE
    OPEN PIPE "pacmd stat" FOR INPUT AS #PulseHandler
    WHILE NOT EOF(PulseHandler)
      LINE INPUT #PulseHandler, a
      PRINT "      " + HtmlizeText(a) + "<br>"
    WEND
    CLOSE #PulseHandler
    PRINT "    </p>"
END SELECT

PRINT
PRINT "    <hr class=""footerdelimiter"">"
PRINT "    <p class=""footertext"">Copyright &copy; Mateusz Viste " + pDate + "</p>"
PRINT "  </body>"
PRINT "</html>"

END
