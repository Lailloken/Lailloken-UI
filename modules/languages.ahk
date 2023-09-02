Init_Lang()
{
	local
	global vars, settings, Json

	lang := LLK_IniRead("ini\config.ini", "settings", "language", "english"), lang := !FileExist("data\lang_"lang ".txt") ? "english" : lang, settings.general.lang := lang
	Loop, Parse, % StrReplace(LLK_FileRead("data\lang_"settings.general.lang ".txt", 1), "`t"), `n, `r
	{
		If Blank(A_LoopField) || (SubStr(A_LoopField, 1, 1) = ";")
			Continue
		If !InStr(A_LoopField, "=")
		{
			MsgBox, % "Error in file ""data\lang_"settings.general.lang """, line"A_Index ":`nkey/value pair is missing an equal sign, or comment is missing a semicolon"
			Continue
		}
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), val := SubStr(val, 2), val := SubStr(val, 1, -1)
		If !val
			Continue
		If !IsObject(vars.lang[key])
			vars.lang[key] := []
		vars.lang[key].Push(val)
	}
	vars.help.settings["lang translators"] := vars.lang.translator.Clone()
}

LangLineParse(line, array)
{
	local
	global vars, settings

	If !array.Count()
		Return

	check := 1
	For index, segment in array
	{
		check *= InStr(line, segment, 1) ? 1 : 0
		If !check
			Break
	}
	Return check
}

LangLineTrim(line, array, location := 0)
{
	local
	global vars, settings

	location := location ? vars.lang.location_identifier.1 : ""
	For index, segment in array
		line := StrReplace(line, segment,,, 1)
	While InStr(" "location, SubStr(line, 1, 1))
		line := SubStr(line, 2)
	While InStr(" "location, SubStr(line, 0))
		line := SubStr(line, 1, -1)
	Return line
}
