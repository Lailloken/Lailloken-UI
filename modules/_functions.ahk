Blank(var)
{
	If (var = "")
		Return 1
}

CheckClient()
{
	local
	global vars

	WinGet, clients, List, % WinExist("ahk_exe GeForceNOW.exe") ? "ahk_exe GeForceNOW.exe" : "ahk_class POEWindowClass"
	If (clients > 1)
		LLK_Error("Multiple game-clients detected. Tool will exit.")

	If WinExist("ahk_exe GeForceNOW.exe")
		WinGetTitle, title, ahk_exe GeForceNOW.exe
	Else WinGet, title, ProcessPath, ahk_class POEWindowClass

	If WinExist("ahk_exe GeForceNOW.exe") && LLK_PatternMatch(title, "", [" 2", " ii"],,, 0) || RegExMatch(title, "i)2\\.*\.exe$")
		Return " 2"
}

DB_Load(database)
{
	local
	global vars, settings, db, json

	If (database = "leveltracker")
	{
		lang := settings.general.lang, lang2 := settings.general.lang_client
		If !vars.poe_version
			db.leveltracker := {"areas": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] areas.json") ? lang : "english") "\[leveltracker] areas.json"))
			, "gems": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] gems.json") ? lang : "english") "\[leveltracker] gems.json"))
			, "quests": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] quests.json") ? lang : "english") "\[leveltracker] quests.json"))
			, "regex": Json.Load(LLK_FileRead("data\global\[leveltracker] gem regex.json"))
			, "trees": {"supported": ["3_25", "3_25_alternate"]}}
		Else
			db.leveltracker := {"areaIDs": {}, "areas": json.load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] areas 2.json") ? lang : "english") "\[leveltracker] areas 2.json"))
			, "trees": {"supported": ["0_1"]}, "regex": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang2 "\[leveltracker] gem regex 2.json") ? lang2 : "english") "\[leveltracker] gem regex 2.json"))}

		For iAct, aAct in db.leveltracker.areas
			For iArea, oArea in aAct
				If oArea.crafting_recipe
					db.leveltracker.areaIDs[oArea.id] := oArea.map_name ? {"name": oArea.name, "mapname": oArea.map_name, "craft": oArea.crafting_recipe} : {"name": oArea.name, "craft": oArea.crafting_recipe}
				Else db.leveltracker.areaIDs[oArea.id] := oArea.map_name ? {"name": oArea.name, "mapname": oArea.map_name} : {"name": oArea.name}
	}
	Else If (database = "item_mods")
		db.item_mods := Json.Load(LLK_FileRead("data\global\item mods" vars.poe_version ".json"))
	Else If (database = "item_bases")
		db.item_bases := Json.Load(LLK_FileRead("data\global\item bases" vars.poe_version ".json", 1))
	Else If (database = "item_drops")
		db.item_drops := Json.Load(LLK_FileRead("data\global\item drop-tiers" vars.poe_version ".json"))
	Else If (database = "anoints")
		db.anoints := Json.Load(LLK_FileRead("data\" (FileExist("data\" settings.general.lang_client "\anoints.json") ? settings.general.lang_client : "english") "\anoints.json",, "65001"))
	Else If (database = "essences")
		db.essences := Json.Load(LLK_FileRead("data\" (FileExist("data\" settings.general.lang_client "\essences.json") ? settings.general.lang_client : "english") "\essences.json",, "65001"))
	Else If (database = "mapinfo")
	{
		db.mapinfo := {"localization": {}, "maps": {}, "mods": {}, "mod types": [], "expedition areas": [], "expedition groups": {}}
		Loop, Parse, % StrReplace(LLK_FileRead("data\" (FileExist("data\" settings.general.lang_client "\map-info" vars.poe_version ".txt") ? settings.general.lang_client : "english") "\map-info" vars.poe_version ".txt", 1), "`t"), `n, `r
		{
			section := (SubStr(A_LoopField, 1, 1) = "[") ? LLK_StringRemove(SubStr(A_LoopField, 2, InStr(A_LoopField, "]") - 2), "# , #") : section
			If !A_LoopField || (SubStr(A_LoopField, 1, 1) = ";") || (SubStr(A_LoopField, 1, 1) = "[")
			{
				line := ""
				Continue
			}
			line := InStr(A_LoopField, ";##") ? SubStr(A_LoopField, 1, InStr(A_LoopField, ";##") - 1) : A_LoopField
			key := InStr(line, "=") ? SubStr(line, 1, InStr(line, "=") - 1) : "", val := InStr(line, "=") ? SubStr(line, InStr(line, "=") + 1) : ""

			If (section = "Map Names") && InStr(line, "=")
				db.mapinfo.localization[key] := val
			Else If LLK_PatternMatch(section, "", ["mod types", "expedition areas"])
				db.mapinfo[section].Push(line)
			Else If (section = "expedition groups")
				db.mapinfo[section][key] := val
			Else If LLK_PatternMatch(key, "", ["type", "text", "ID"])
			{
				If !IsObject(db.mapinfo.mods[section])
					db.mapinfo.mods[section] := {}
				If settings.general.dev && (key = "ID") && db.mapinfo.mods[section].ID
					MsgBox, % "duplicate: " section
				db.mapinfo.mods[section][key] := StrReplace(val, "&", "&&")
				If settings.general.dev && (key = "type") && (val != "expedition") && !LLK_HasVal(db.mapinfo["mod types"], val)
					MsgBox, % "invalid mod-type for:`n" section
			}
		}

		Loop, Parse, % StrReplace(LLK_FileRead("data\global\Atlas.txt", 1), "`t"), `n, `r
		{
			val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
			maps .= StrReplace(val, ",", " (" A_Index "),") ;create a list of all maps
			Sort, val, D`,
			db.mapinfo.maps[A_Index] := StrReplace(SubStr(val, 1, -1), ",", "`n") ;store tier X maps here
		}
		Sort, maps, D`,
		Loop, Parse, % LLK_StringCase(maps), `,
			If A_LoopField
				db.mapinfo.maps[SubStr(A_LoopField, 1, 1)] .= !db.mapinfo.maps[SubStr(A_LoopField, 1, 1)] ? A_LoopField : "`n" A_LoopField ;store maps starting with a-z here
	}
	Else If (database = "OCR")
	{
		tldr := Json.Load(LLK_FileRead("data\english\TLDR-tooltips.json"))
		db.altars := tldr["eldritch altars"].Clone()
		db.altar_dictionary := []
		For outer in ["", ""]
			For index1, key in ["boss", "minions", "player"]
			{
				If (outer = 1)
				{
					If !IsObject(db.altars[key "_check"])
						db.altars[key "_check"] := []
					For index, array in db.altars[key]
						Loop, Parse, % array.1, `n, `r
							If !LLK_HasVal(db.altars[key "_check"], A_LoopField)
								db.altars[key "_check"].Push(A_LoopField)
				}
				Else
				{
					For iDB, kDB in db.altars[key "_check"]
						Loop, Parse, % StrReplace(kDB, "`n", " "), % A_Space
							If !LLK_HasVal(db.altar_dictionary, A_LoopField)
								db.altar_dictionary.Push(A_LoopField)
				}
			}

		db.vaalareas := tldr["vaal side areas"].Clone()
		db.vaalareas_dictionary := []
		For key in db.vaalareas
			Loop, Parse, key, % A_Space
				If !LLK_HasVal(db.vaalareas_dictionary, A_LoopField)
					db.vaalareas_dictionary.Push(A_LoopField)
	}
	Else If (database = "legion")
		db.legion := Json.Load(LLK_FileRead("data\" (FileExist("data\" settings.general.lang_client "\timeless jewels.json") ? settings.general.lang_client : "english") "\timeless jewels.json"))
}

FormatSeconds(seconds, leading_zeroes := 1)  ; Convert the specified number of seconds to hh:mm:ss format.
{
	local

	days := 0, time := 19990101  ; *Midnight* of an arbitrary date.
	While (seconds >= 86400)
		days += 1, seconds -= 86400
	time += seconds, seconds
	FormatTime, time, %time%, HH:mm:ss
	If days
		time := (days < 10 ? "0" : "") days ":" time
	While !leading_zeroes && InStr("0:", SubStr(time, 1, 1)) && (StrLen(time) > 4) ;remove leading 0s and colons
		time := SubStr(time, 2)
	return time
}

HTTPtoVar(URL, mode := "URL", currency := "") ; taken from the AHK-wiki, adapted to also fetch data from bulk-exchange
{
	local
	global vars, settings, json

	If (mode = "exchange")
		item := URL, URL := "https://www.pathofexile.com/api/trade/exchange/" StrReplace(settings.stash.league, " ", "%20"), array := []
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open((mode = "exchange") ? "POST" : "GET", URL, true)
	If (mode = "exchange")
		whr.SetRequestHeader("Content-Type", "application/json")
	whr.Send((mode = "exchange") ? "{""query"":{""status"":{""option"":""onlineleague""},""have"":[""" currency """],""want"":[""" item """]},""sort"":{""have"":""asc""},""engine"":""new""}" : "")
	; Using 'true' above and the call below allows the script to remain responsive.
	whr.WaitForResponse()

	If (mode = "exchange")
	{
		limits_max := StrSplit(whr.GetResponseHeader("X-Rate-Limit-Ip"), ",", A_Space), limits_current := StrSplit(whr.GetResponseHeader("X-Rate-Limit-Ip-State"), ",", A_Space)
		status := whr.Status(), limits := {}
		Loop, % limits_max.Count()
		{
			pCurrent := StrSplit(limits_current[A_Index], ":", A_Space), pMax := StrSplit(limits_max[A_Index], ":", A_Space)
			limits[pCurrent.2] := [pCurrent.1, pMax.1, pMax.3]
		}
		array.1 := (SubStr(whr.ResponseText, 1, 1) . SubStr(whr.ResponseText, 0) != "{}") || InStr(whr.ResponseText, """error""") ? "" : json.Load(whr.ResponseText)
		array.2 := limits, array.3 := status, array.4 := (status = 429) ? whr.GetResponseHeader("Retry-After") : ""
	}
	Return (mode = "URL" ? whr.ResponseText : array)
}

IniBatchRead(file, section := "", encoding := "1200")
{
	local

	ini := {}, file := Blank(section) ? LLK_FileRead(file, 1, encoding) : LLK_IniRead(file, section)
	If !Blank(section)
		ini[section] := {}
	If Blank(section) && !InStr(file, "[") && !InStr(file, "]") || !Blank(section) && (file = " " || file = "")
		Return ini

	Loop, Parse, file, `n, `r
	{
		If Blank(A_LoopField)
			Continue
		If (SubStr(A_LoopField, 1, 1) = "[")
		{
			section := SubStr(A_LoopField, 2, -1), ini[section] := {}
			Continue
		}
		If InStr(A_LoopField, "=")
			key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		Else key := A_LoopField, val := ""

		val := (SubStr(val, 1, 1) = """" && SubStr(val, 0, 1) = """") ? SubStr(val, 2, -1) : val
		ini[section][key] := val
	}
	Return ini
}

LLK_ArraySort(array)
{
	local

	parse := {}, parse2 := []
	For index, val in array
		parse[val] := 1

	For key in parse
		parse2.Push(key)

	Return parse2
}

LLK_CloneObject(object)
{
	local

	For key, val in object
		If !IsNumber(key)
			is_array := 1

	If is_array
		new_object := []
	Else new_object := {}

	For key, val in object
		If !IsObject(val)
			new_object[key] := val
		Else new_object[key] := LLK_CloneObject(val)
	Return new_object
}

LLK_Error(ErrorMessage, restart := 0)
{
	MsgBox, % ErrorMessage
	If restart
		Reload
	ExitApp
}

LLK_FilePermissionError(issue, folder)
{
	local

	MsgBox, % Lang_Trans("m_permission_error1", (issue = "create") ? 1 : 2) " " folder "`n`n" Lang_Trans("m_permission_error1", 3) "`n" Lang_Trans("m_permission_error1", 4) "`n`n" Lang_Trans("m_permission_error1", 5) "`n`n" Lang_Trans("m_permission_error1", 6)
}

LLK_FileRead(file, keep_case := 0, encoding := "65001")
{
	local

	FileRead, read, % (!Blank(encoding) ? "*P" encoding " " : "") file
	If !keep_case
		StringLower, read, read
	Return read
}

LLK_HasKey(object, value, InStr := 0, case_sensitive := 0, all_results := 0, recurse := 0)
{
	local

	If !IsObject(object) || Blank(value)
		Return
	parse := []
	For key, val in object
	{
		If (key = value) || InStr && InStr(key, value, case_sensitive) || recurse && IsObject(val) && LLK_HasKey(val, value, InStr, case_sensitive, all_results, recurse)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}
	}

	If all_results
		Return (parse.Count() ? parse : "")
	Return
}

LLK_HasVal(object, value, InStr := 0, case_sensitive := 0, all_results := 0, recurse := 0, check_decimals := 0) ; check_decimals is a band-aid fix for very specific use-cases where X and X.000[...] need to be distinguished
{
	local

	If !IsObject(object) || Blank(value)
		Return
	parse := []
	For key, val in object
		If (val = value) && !check_decimals || (val = value) && InStr(val, ".") && InStr(value, ".") && check_decimals || InStr && InStr(val, value, case_sensitive) || recurse && IsObject(val) && LLK_HasVal(val, value, InStr, case_sensitive, all_results, recurse, check_decimals)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}

	If all_results && parse.Count()
		Return parse
	Return
}

LLK_HasRegex(object, regex, all_results := 0, check_key := 0)
{
	local

	If !IsObject(object)
		Return
	parse := []
	For key, val in object
		If RegExMatch(!check_key ? val : key, regex)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}

	If all_results && parse.Count()
		Return parse
}

LLK_IniRead(file, section := "", key := "", default := "")
{
	IniRead, iniread, % file, % section, % key, % Blank(default) ? A_Space : default
	iniread := (iniread = " ") ? "" : iniread 	;work-around for situations where A_Space is taken literally instead of "blank" (blank return is hard-coded as %A_Space%, so % "" doesn't work)
	If !Blank(default) && Blank(iniread)		;IniRead's 'default' is only used if the key cannot be found in the ini-file
		Return default 					;if the key in the ini-file is blank, the target-variable will also be blank (instead of storing 'default')
	Else Return iniread
}

LLK_InRange(x, y, range)
{
	If (y >= x - range) && (y <= x + range)
		Return 1
	Else Return 0
}

LLK_InStrCount(string, character, delimiter := "")
{
	count := 0
	Loop, Parse, string, % delimiter
		If (A_Loopfield = character)
			count += 1
	Return count
}

LLK_IsBetween(var, x, y)
{
	If Blank(x) || Blank(y)
		Return
	x += 0, y += 0
	If (x > y)
		z := x, x := y, y := z
	If (x <= var) && (var <= y)
		Return 1
	Else Return 0
}

LLK_IsType(character, type)
{
	If (character = "")
		Return 0
	If (character = " ") && (type = "alpha" || type = "alnum")
		Return 1
	Else If character is %type%
		Return 1
}

LLK_Log(message)
{
	local
	global vars

	If !vars.logging
		Return

	FormatTime, logstamp, A_Now, yyyy-MM-dd`, HH:mm:ss
	FileAppend, % (InStr(message, "---") ? "`r`n" : "") "[" logstamp "] " message "`r`n", data\log.txt
}

LLK_PatternMatch(text, string, object, swap := 0, value := 1, case := 1) ;swap param switches the order around, val param determines if values or keys of the object are used
{
	local

	For index, val in object
	{
		val := value ? val : index
		check := swap ? val . string : string . val
		If InStr(text, check, case)
		{
			While (SubStr(val, 1, 1) = " ")
				val := SubStr(val, 2)
			Return InStr(val, " ") ? SubStr(val, 1, InStr(val, " ") - 1) : val
		}
	}
}

LLK_Restart()
{
	Reload
	ExitApp
}

LLK_StringCase(string, mode := 0, title := 0)
{
	local

	If mode
		StringUpper, string, % string, % title ? "T" : ""
	Else StringLower, string, % string, % title ? "T" : ""
	Return string
}

LLK_StringCompare(string, needles)
{
	local

	For index, needle in needles
		If !Blank(needle) && (SubStr(string, 1, StrLen(needle)) = needle)
			Return 1
}

LLK_StringRemove(string, characters)
{
	local

	Loop, Parse, characters, `,
	{
		If (A_LoopField = "")
			Continue
		string := StrReplace(string, A_LoopField)
	}
	Return string
}

LLK_TrimDecimals(string)
{
	local

	If !InStr(string, ".")
		Return string
	While InStr("0.", (check := SubStr(string, 0))) && !Blank(check)
	{
		string := SubStr(string, 1, -1)
		If (check = ".")
			Break
	}
	Return string
}

SnipGuiClose()
{
	local
	global vars, settings

	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.snip.main
	vars.snip := {"x": x, "y": y, "w": w, "h": h}
	Gui, snip: Destroy
	vars.hwnd.Delete("snip")
}

StrMatch(string, check, match_length := 0)
{
	local

	If (SubStr(string, 1, StrLen(check)) = check) && (match_length && StrLen(string) = StrLen(check) || !match_length)
		Return 1
}

StringSend(ByRef string, ByRef WindowTitle := "") ;based on example #4 on https://www.autohotkey.com/docs/v1/lib/OnMessage.htm
{
	local
	global vars

	VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
	SizeInBytes := (StrLen(string) + 1) * (A_IsUnicode ? 2 : 1)
	NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
	NumPut(&string, CopyDataStruct, 2*A_PtrSize)
	SendMessage, 0x004A, 0, &CopyDataStruct,, % Blank(WindowTitle) ? vars.general.bThread : WindowTitle
	Return (ErrorLevel = "FAIL" ? 0 : ErrorLevel)
}

UpdateCheck(timer := 0) ;checks for updates: timer param refers to whether this function was called via the timer or during script-start
{
	local
	global vars, settings, Json

	vars.update := [0], update := vars.update

	If !FileExist("update\")
		FileCreateDir, update\
	update.1 := !FileExist("update\") ? -2 : update.1
	FileDelete, update\update.* ;delete any leftover files
	update.1 := FileExist("update\update.*") ? -1 : update.1 ;error code -1 = delete-permission
	Loop, Files, update\lailloken-ui-*, D
		FileRemoveDir, % A_LoopFileLongPath, 1 ;delete any leftover folders
	Loop, Files, update\exile-ui-*, D
		FileRemoveDir, % A_LoopFileLongPath, 1 ;delete any leftover folders
	update.1 := FileExist("update\lailloken-ui-*") ? -1 : update.1 ;error code -1 = delete-permission
	update.1 := FileExist("update\exile-ui-*") ? -1 : update.1 ;error code -1 = delete-permission
	FileAppend, 1, update\update.test
	update.1 := !FileExist("update\update.test") ? -2 : update.1 ;error code -2 = write-permission
	FileDelete, update\update.test
	update.1 := FileExist("update\update.test") ? -1 : !FileExist("data\versions.json") ? -3 : update.1 ;error code -3 = bricked install (version-file not found)
	If (update.1 < 0)
	{
		If InStr("2", timer)
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
		Return
	}
	versions_local := Json.Load(LLK_FileRead("data\versions.json")) ;load local versions
	If versions_local.HasKey("hotfix")
		versions_local._release.1 .= "." . (versions_local.hotfix < 10 ? "0" : "") . versions_local.hotfix
	Loop, Files, % "update\update_*.zip"
	{
		version := SubStr(A_LoopFileName, InStr(A_LoopFileName, "_") + 1), version := StrReplace(version, ".zip")
		If Blank(version) || (version <= versions_local["_release"].1)
			FileDelete, % A_LoopFileLongPath
	}

	FileDelete, data\version_check.json
	Try version_check := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/versions.json")
	update.1 := !InStr(version_check, """_release""") ? -4 : update.1 ;error-code -4 = version-list download failed
	If (update.1 = -4)
	{
		If InStr("2", timer)
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
		Return
	}
	versions_live := Json.Load(version_check) ;load version-list into object
	If versions_live.HasKey("hotfix")
		versions_live._release.1 .= "." . (versions_live.hotfix < 10 ? "0" : "") . versions_live.hotfix
	vars.updater := {"version": [versions_local._release.1, UpdateParseVersion(versions_local._release.1)], "latest": [versions_live._release.1, UpdateParseVersion(versions_live._release.1)]}
	vars.updater.skip := LLK_IniRead("ini" vars.poe_version "\config.ini", "versions", "skip", 0)

	Try changelog_check := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/changelog.json")
	If (SubStr(changelog_check, 1, 1) . SubStr(changelog_check, 0) = "[]")
	{
		vars.updater.changelog := Json.Load(changelog_check)
		FileDelete, data\changelog.json
		If !FileExist("data\changelog.json")
			FileAppend, % changelog_check, data\changelog.json
	}
	Else
	{
		vars.updater.changelog := Json.Load(LLK_FileRead("data\changelog.json"))
		If !LLK_HasVal(vars.updater.changelog, vars.updater.version.1,,,, 1)
			vars.updater.changelog.InsertAt(1, [[vars.updater.version.2, vars.updater.version.1], "changelog download failed"])
	}

	If (timer != 2) && (vars.updater.skip = vars.updater.latest.1)
		Return

	If InStr("01", timer) && (versions_live._release.1 > versions_local._release.1)
	{
		vars.update := [1]
		Return
	}
	Else If (timer = 2)
	{
		Gui, update_download: New, -Caption -DPIScale +LastFound +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDdownload
		Gui, update_download: Color, Black
		Gui, update_download: Add, Progress, range0-10 HWNDhwnd BackgroundBlack cGreen, 0
		Gui, update_download: Show
		UpdateDownload(hwnd)
		branch := InStr(versions_live._release.2, "/main.zip") ? "main" : "beta"
		vars.updater.target_version := [LLK_IniRead("ini\config.ini", "versions", "apply update")]
		Loop, Parse, % vars.updater.target_version.1, % "."
			vars.updater.target_version.2 .= (A_Index = 3) ? (A_LoopField < 10 ? "0" : "") A_LoopField : A_LoopField

		LLK_Log("starting update to " vars.updater.target_version.1)

		If !FileExist("update\update_" vars.updater.target_version.2 ".zip")
			UrlDownloadToFile, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/tags/v" vars.updater.target_version.1 ".zip", % "update\update_" vars.updater.target_version.2 ".zip"
		If ErrorLevel || !FileExist("update\update_" vars.updater.target_version.2 ".zip")
			vars.update := [-5, vars.updater.target_version.1] ;error-code -5 = download of zip-file failed
		If (vars.update.1 >= 0)
		{
			FileCopyDir, % "update\update_" vars.updater.target_version.2 ".zip", update, 1
			If ErrorLevel || !(FileExist("update\lailloken-ui-*") || FileExist("update\exile-ui-*"))
				vars.update := [-6, vars.updater.target_version.1] ;error-code -6 = zip-file couldn't be extracted
		}
		If (vars.update.1 >= 0)
		{
			SplitPath, A_ScriptFullPath,, path
			Loop, Files, % FileExist("update\exile-ui-*") ? "update\exile-ui-*" : "update\Lailloken-ui-*", D
				Loop, Files, % A_LoopFilePath "\*", FD
				{
					If InStr(FileExist(A_LoopFileLongPath), "D")
						FileMoveDir, % A_LoopFileLongPath, % path "\" A_LoopFileName, 2
					Else FileMove, % A_LoopFileLongPath, % path "\" A_LoopFileName, 1
					If ErrorLevel
						vars.update := [-6, vars.updater.target_version.1]
				}
		}

		If (vars.update.1 >= 0)
		{
			FileDelete, data\version_check.json
			IniDelete, % "ini\config.ini", versions, apply update
			LLK_Log("finished update to " vars.updater.target_version.1)
			If (vars.updater.target_version.2 <= 15703) && !InStr(A_ScriptName, "lailloken")
			{
				FileDelete, Exile UI.ahk
				Run, Lailloken UI.ahk
				ExitApp
			}
			Else If (vars.updater.target_version.2 >= 15704) && InStr(A_ScriptName, "lailloken")
			{
				FileDelete, Lailloken UI.ahk
				Run, Exile UI.ahk
				ExitApp
			}
			Reload
			ExitApp
		}
		If (vars.update.1 < 0)
		{
			SetTimer, UpdateDownload, Delete
			Gui, update_download: Destroy
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
			LLK_Log("failed update to " vars.updater.target_version.1)
			Return
		}
	}
}

UpdateDownload(mode := "")
{
	local
	static dl_bar := 0, HWND_bar

	If (mode = "reset")
	{
		dl_bar := 0
		GuiControl,, % HWND_bar, % dl_bar
		GuiControl, movedraw, % HWND_bar
		Return
	}
	If (mode)
	{
		HWND_bar := mode
		SetTimer, UpdateDownload, 500
	}

	dl_bar += (dl_bar = 10) ? -10 : 1
	GuiControl,, % HWND_bar, % dl_bar
}

UpdateParseVersion(string)
{
	local

	Loop, Parse, string
	{
		If (A_Index = 1)
			string := ""
		string .= (A_Index = 1) ? "1." : (A_Index = 3) ? A_LoopField "." : (InStr("47", A_Index) && A_LoopField = "0") ? "" : (A_LoopField = ".") ? " (hotfix " : A_LoopField
	}
	string .= InStr(string, "(hotfix") ? ")" : ""
	Return string
}
