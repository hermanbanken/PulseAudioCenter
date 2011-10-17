REM
REM This file is part of the PulseAudio Web Gui project!
REM

FUNCTION HtmlizeText(QueryString AS STRING) AS STRING
  DIM AS STRING Processing
  DIM AS INTEGER AmpPosition
  Processing = QueryString
  IF INSTR(QueryString, "&") + INSTR(QueryString, CHR(34)) + INSTR(QueryString, "<") + INSTR(QueryString, ">") > 0 THEN
    FOR AmpPosition = LEN(Processing) - 1 TO 0 STEP -1
      SELECT CASE Processing[AmpPosition]
        CASE 38 ' Ampersand "&"
          Processing = MID(Processing, 1, AmpPosition) + "&amp;" + MID(Processing, AmpPosition + 2, LEN(Processing) - AmpPosition)
        CASE 34 ' Quote """
          Processing = MID(Processing, 1, AmpPosition) + "&quot;" + MID(Processing, AmpPosition + 2, LEN(Processing) - AmpPosition)
        CASE 60 ' Less than "<"
          Processing = MID(Processing, 1, AmpPosition) + "&lt;" + MID(Processing, AmpPosition + 2, LEN(Processing) - AmpPosition)
        CASE 62 ' Greater than ">"
          Processing = MID(Processing, 1, AmpPosition) + "&gt;" + MID(Processing, AmpPosition + 2, LEN(Processing) - AmpPosition)
      END SELECT
    NEXT
  END IF
  RETURN Processing
END FUNCTION
