Init_Lang(mode := 0)
{
	local
	global vars, settings, Json, db

	lang := LLK_IniRead("ini\config.ini", "settings", "language", "english"), settings.general.lang := !FileExist("data\" lang "\UI.txt") ? "english" : lang
	If (lang != "english") ;load English help-tooltips into secondary object as a fallback (in case a translation is not up-to-date and missing certain tooltip-texts)
		vars.help := Json.Load(LLK_FileRead("data\" (!FileExist("data\" lang "\help tooltips.json") ? "english" : lang) "\help tooltips.json",, "65001")), vars.help2 := Json.Load(LLK_FileRead("data\english\help tooltips.json",, "65001"))
	Loop 2
		vars["lang" (A_Index = 1 ? "" : 2)] := LangLoad((A_Index = 1 ? lang : "english") "\UI.txt")
	vars.help.settings["lang translators"] := vars.lang.translator.Clone(), vars.system.font := LangTrans("system_font")
}

LangClient(log_chunk) ;finds out which language the client is running
{
	local
	global vars, settings, json
	static lang_check

	If !IsObject(lang_check)
	{
		lang_check := {} ;object which holds the "you have entered XYZ" strings for every available language
		Loop, Files, data\*, R
		{
			If (A_LoopFileName != "client.txt")
				Continue
			parse := StrReplace(StrReplace(A_LoopFilePath, "\client.txt"), "data\"), lang_check[parse] := []
			Loop, Parse, % StrReplace(LLK_FileRead(A_LoopFilePath, 1, "65001"), "`t"), `n, `r
			{
				line := A_LoopField
				While (SubStr(line, 1, 1) = " ")
					line := SubStr(line, 2)
				While (SubStr(line, 0) = " ")
					line := SubStr(line, 1, -1)
				If !(InStr(line, "log_enter") && InStr(line, "=") && InStr(line, """")) || (SubStr(line, 1, 1) = ";")
					Continue
				line := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), line := InStr(line, ";##") ? SubStr(line, 1, InStr(line, ";##") -1) : line
				While (SubStr(line, 1, 1) = " ")
					line := SubStr(line, 2)
				While (SubStr(line, 0) = " ")
					line := SubStr(line, 1, -1)
				line := SubStr(line, 1, -1)
				Loop, Parse, % StrReplace(line, "#", "¢"), ¢
					lang_check[parse].Push((parse != "english" && InStr(A_LoopField, "You have entered")) ? "--invalid--" : A_LoopField)
			}
		}
	}

	Loop, Parse, log_chunk, `n, `r
	{
		If InStr(A_LoopField, "Generating level ", 1) ;(potentially) reset parsed language-setting every time "Generating level" is found in the log
			lang_reset := 1

		If InStr(A_LoopField, " : ")
		{
			If lang_reset ;without this reset, this function would merely find the last valid language (instead of the actual current language)
				settings.general.lang_client := lang_client := "unknown"
			For key, val in lang_check
				If LangMatch(A_LoopField, val)
					lang_client := key, lang_reset := 0
		}
			
	}
	settings.general.lang_client := lang_client

	If lang_client && (lang_client != "unknown") ;if the current client-language is supported, load the client-related strings
	{
		lang_parse := LangLoad(lang_client "\client.txt")
		For key, val in lang_parse
			vars.lang[key] := val.Clone()
		vars.system.font := LangTrans("system_font"), vars.help.settings["lang contributors"] := vars.lang.contributor.Clone()
	}
}

LangMatch(text, array, case := 1)
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

LangTrim(text, array, omit := "")
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

LangLoad(file)
{
	local
	global vars

	array := []
	Loop, Parse, % StrReplace(LLK_FileRead("data\" file, 1, "65001"), "`t"), `n, `r
	{
		line := A_LoopField
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

LangTrans(key, index := 1, insert := "")
{
	local
	global vars

	value := !Blank(vars.lang[key][index]) ? vars.lang[key][index] : vars.lang2[key][index], check := 0
	If IsObject(insert)
		For index0, string in (!Blank(vars.lang[key][index]) ? vars.lang[key] : vars.lang2[key])
			value := (index0 = 1) ? "" : value, check += (index0 >= index) ? 1 : 0, value .= (index0 >= index) ? string . insert[check] : ""
	Return Blank(value) ? "0000" : value
}
