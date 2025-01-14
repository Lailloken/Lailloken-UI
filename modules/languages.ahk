Init_Lang(mode := 0)
{
	local
	global vars, settings, Json, db

	lang := LLK_IniRead("ini" vars.poe_version "\config.ini", "settings", "language", "english"), settings.general.lang := !FileExist("data\" lang "\UI.txt") ? "english" : lang
	If (lang != "english") ;load English help-tooltips into secondary object as a fallback (in case a translation is not up-to-date and missing certain tooltip-texts)
		vars.help := Json.Load(LLK_FileRead("data\" (!FileExist("data\" lang "\help tooltips.json") ? "english" : lang) "\help tooltips.json",, "65001")), vars.help2 := Json.Load(LLK_FileRead("data\english\help tooltips.json",, "65001"))
	Loop 2
		vars["lang" (A_Index = 1 ? "" : 2)] := Lang_Load((A_Index = 1 ? lang : "english") "\UI.txt")
	vars.help.settings["lang translators"] := vars.lang.translator.Clone(), vars.system.font := Lang_Trans("system_font")

	prev_lang := settings.general.lang_client ? settings.general.lang_client : ""
	If !FileExist("data\" settings.general.lang_client0 "\")
		settings.general.lang_client := "unknown", vars.system.font := "Fontin SmallCaps"
	Else
	{
		settings.general.lang_client := settings.general.lang_client0, lang_parse := Lang_Load(settings.general.lang_client0 "\client.txt")
		For key, val in lang_parse
			vars.lang[key] := val.Clone()
		vars.system.font := Lang_Trans("system_font"), vars.help.settings["lang contributors"] := vars.lang.contributor.Clone()
	}

	If prev_lang && (prev_lang != settings.general.lang_client)
	{
		MsgBox, % "Client language has changed between restarts. The tool will now restart."
		LLK_Restart()
	}
}

Lang_Match(text, array, case := 1)
{
	local
	global vars, settings

	check := 1
	If !IsObject(array) || !array.Count()
		Return
	For index, string in array
	{
		check *= InStr(text, string, case) ? 1 : 0
		If !check
			Break
	}
	Return check
}

Lang_Trim(text, array, omit := "")
{
	local
	global vars, settings

	For index, string in array
		text := StrReplace(text, string,,, 1)
	While text && InStr(" " omit, SubStr(text, 1, 1))
		text := SubStr(text, 2)
	While text && InStr(" " omit, SubStr(text, 0))
		text := SubStr(text, 1, -1)
	Return text
}

Lang_Load(file)
{
	local
	global vars

	array := []
	Loop, Parse, % StrReplace(LLK_FileRead("data\" file, 1, "65001"), "`t"), `n, `r
	{
		line := StrReplace(A_LoopField, "&", "&&")
		While (SubStr(line, 1, 1) = " ")
			line := SubStr(line, 2)
		While (SubStr(line, 0) = " ")
			line := SubStr(line, 1, -1)
		If Blank(line) || (SubStr(line, 1, 1) = ";")
			Continue
		If !InStr(line, "=") || Mod(LLK_InStrCount(line, """"), 2)
		{
			MsgBox, % "Potential error in file ""data\" file ", line " A_Index ":`n- key/value pair is missing an equal sign or quotation marks`n- comment-line is missing semi-colon"
			Continue
		}
		key := SubStr(line, 1, InStr(line, "=") - 1), val := SubStr(line, InStr(line, "=") + 1), val := InStr(val, ";##") ? SubStr(val, 1, InStr(val, ";##") - 1) : val
		While (SubStr(key, 1, 1) = " ")
			key := SubStr(key, 2)
		While (SubStr(key, 0) = " ")
			key := SubStr(key, 1, -1)
		While (SubStr(val, 1, 1) = " ")
			val := SubStr(val, 2)
		While (SubStr(val, 0) = " ")
			val := SubStr(val, 1, -1)
		val := StrReplace(SubStr(val, 2, -1), ";", "`n")

		If !val
			Continue
		If !IsObject(array[key])
			array[key] := []
		Loop, Parse, % StrReplace(val, "#", "¢"), ¢
			If !Blank(A_LoopField)
				array[key].Push(A_LoopField)
	}
	Return array
}

Lang_Trans(key, index := 1, insert := "")
{
	local
	global vars

	value := !Blank(vars.lang[key][index]) ? vars.lang[key][index] : vars.lang2[key][index], check := 0
	If IsObject(insert)
		For index0, string in (!Blank(vars.lang[key][index]) ? vars.lang[key] : vars.lang2[key])
			value := (index0 = 1) ? "" : value, check += (index0 >= index) ? 1 : 0, value .= (index0 >= index) ? string . insert[check] : ""
	Return Blank(value) ? "0000" : value
}
