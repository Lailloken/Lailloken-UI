Init_mapinfo()
{
	local
	global vars, settings, db, Json
	
	If !FileExist("ini\map info.ini")
	{
		IniWrite, % "", ini\map info.ini, Settings
		IniWrite, % "", ini\map info.ini, UI
	}
	
	settings.features.mapinfo := (settings.general.lang_client = "unknown") ? 0 : LLK_IniRead("ini\config.ini", "Features", "enable map-info panel", 0)
	settings.mapinfo := {"IDs": {}}

	Loop, Parse, % StrReplace(LLK_FileRead("data\english\map-info.txt"), "`t"), `n, `r
	{
		If !InStr(A_LoopField, "id=")
			Continue
		ID := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), settings.mapinfo.IDs[ID] := {"rank": LLK_IniRead("ini\map info.ini", ID, "rank", 1), "show": LLK_IniRead("ini\map info.ini", ID, "show", 1)}
	}

	settings.mapinfo.dColor := ["FFFFFF", "f77e05", "Red", "Fuchsia", "909090"], settings.mapinfo.eColor_default := ["FFFFFF", "Yellow", "Green", "Lime"]
	settings.mapinfo.color := [], settings.mapinfo.eColor := []
	Loop 5
		settings.mapinfo.color[A_Index] := LLK_IniRead("ini\map info.ini", "UI", (A_Index = 5) ? "header color" : "difficulty " A_Index " color", settings.mapinfo.dColor[A_Index]), settings.mapinfo.eColor[A_Index] := LLK_IniRead("ini\map info.ini", "UI", "logbook " A_Index " color", settings.mapinfo.eColor_default[A_Index])
	settings.mapinfo.fSize := LLK_IniRead("ini\map info.ini", "settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.mapinfo.fSize, font_height, font_width)
	settings.mapinfo.fHeight := font_height, settings.mapinfo.fWidth := font_width
	settings.mapinfo.trigger := LLK_IniRead("ini\map info.ini", "Settings", "enable shift-clicking", 0)
	settings.mapinfo.tabtoggle := LLK_IniRead("ini\map info.ini", "Settings", "show panel while holding tab", 0)

	lang := settings.general.lang_client, db.mapinfo := {"localization": {}, "maps": {}, "mods": {}, "mod types": [], "expedition areas": [], "expedition groups": {}}
	Loop, Parse, % StrReplace(LLK_FileRead("data\" (FileExist("data\" lang "\map-info.txt") ? lang : "english") "\map-info.txt", 1), "`t"), `n, `r
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
			db.mapinfo.mods[section][key] := val
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

MapinfoGUI(mode := 1)
{
	local
	global vars, settings
	static toggle := 0

	map := vars.mapinfo.active_map ;short-cut variable
	If map.cancel
	{
		map.cancel := 0
		Return
	}
	toggle := !toggle, GUI_name := "mapinfo" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmapinfo" (mode = 2 ? " +E0x20" : "")
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.mapinfo.fWidth/2, % settings.mapinfo.fWidth/2
	Gui, %GUI_name%: Font, % "s"settings.mapinfo.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.mapinfo.main, vars.hwnd.mapinfo := {"main": mapinfo}, mod_count := 0
	summary := map.mods . LangTrans("maps_stats", 1) " | " map.quantity . LangTrans("maps_stats", 2) " |" (!Blank(map.packsize) ? " " map.packsize . LangTrans("maps_stats", 3) : " " map.rarity . LangTrans("maps_stats", 4))
	If (map.mods + map.quantity > 0)
		dimensions := [summary]
	Else dimensions := []
	
	For index0, category in vars.mapinfo.categories
	{
		If Blank(category)
			Continue
		category_copy := (mode = 2) && InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category
		dimensions.Push((mode = 2 && InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category) ":")
		Loop 4
		{
			For index, val in map[category][A_Index]
				dimensions.Push((mode = 2) && InStr(val.1, ":") ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1), mod_count += (SubStr(val.2, 1, 1) != 3) ? 1 : 0
			For index, val in map[category].0[A_Index]
			{
				If (mode != 2)
					dimensions.Push(val.1)
				mod_count += (SubStr(val.2, 1, 1) != 3) ? 1 : 0
			}
		}
	}
	LLK_PanelDimensions(dimensions, settings.mapinfo.fSize, width, height,,, 0)
		
	For index0, category in vars.mapinfo.categories
	{
		check := 0
		Loop, % (mode = 2) ? 4 : 5
			check += map[category][5 - A_Index].Count() ? 1 : 0
		If !check
			Continue
		
		Gui, %GUI_name%: Add, Text, % (added ? "xs " : "") "Section c"settings.mapinfo.color.5 " w"width (mode = 2 ? " Right" : ""), % (mode = 2 && InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category) ":"
		added += 1
		Loop 4
		{
			For index, val in map[category][5 - A_Index]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				Gui, %GUI_name%: Add, Text, % "xs y+-"settings.mapinfo.fHeight/6 " Section HWNDhwnd w"width " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : ""), % text
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd
			}
		}
		Gui, %GUI_name%: Font, strike
		Loop 4
		{
			If (mode = 2)
				Break
			For index, val in map[category].0[5 - A_Index]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				Gui, %GUI_name%: Add, Text, % "xs y+-"settings.mapinfo.fHeight/6 " Section HWNDhwnd w"width " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : ""), % text
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd
			}
		}
		Gui, %GUI_name%: Font, norm
	}

	If (map.mods + map.quantity > 0)
	{
		Gui, %GUI_name%: Add, Text, % "xs y+"settings.mapinfo.fWidth " Section Center HWNDhwnd w"width, % summary
		LLK_PanelDimensions([summary], settings.mapinfo.fSize, w, h,,, 0), added := 0, spectrum := [0, 0, 0, 0], spectrum[0] := [0, 0, 0, 0]

		For index0, category in vars.mapinfo.categories
		{
			If LLK_HasVal(vars.mapinfo.expedition_areas, InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category)
				Continue
			Loop 4
			{
				spectrum[A_Index] += map[category][A_Index].Count() ? map[category][A_Index].Count() : 0
				spectrum.0[A_Index] += map[category].0[A_Index].Count() ? map[category].0[A_Index].Count() : 0
			}
		}
		
		Loop 4
		{
			index0 := A_Index
			Loop, % spectrum[5 - A_Index]
			{
				Gui, %GUI_name%: Add, Progress, % (!added ? "xs Section y+0 xp+"(width - w)/2 : "ys x+"settings.mapinfo.fWidth//10) " BackgroundBlack c"settings.mapinfo.color[5 - index0] " w"
				. w/mod_count - settings.mapinfo.fWidth//10 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
		Loop 4
		{
			index0 := A_Index
			Loop, % spectrum.0[5 - A_Index]
			{
				Gui, %GUI_name%: Add, Progress, % (!added ? "xs Section y+0 xp+"(width - w)/2 : "ys x+"settings.mapinfo.fWidth//10) " BackgroundBlack Border c"settings.mapinfo.color[5 - index0] " w"
				. w/mod_count - settings.mapinfo.fWidth//10 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
	}
	Else w := width

	If (InStr(vars.log.areaID, "hideout") || InStr(vars.log.areaID, "heisthub")) && (mode = 2) && !InStr(vars.mapinfo.active_map.name, "logbook")
		Gui, %GUI_name%: Add, Text, % "xs y+0 Center w"w, % LLK_StringCase(StrReplace(StrReplace(vars.mapinfo.active_map.name, "maven's invitation: "), " map"))

	If !mode
		WinGetPos, x, y,,, % "ahk_id "hwnd_old
	Else
	{
		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.mapinfo.main
		MouseGetPos, xPos, yPos
		y := (mode = 2) ? vars.client.yc - h/2 : (yPos - (h + vars.client.h/25) < vars.client.y) ? yPos + vars.client.h/25 : yPos - (h + vars.client.h/25), oob := (y + h > vars.client.y + vars.client.h) ? 1 : 0
		If oob
			x := (xPos - vars.client.h/25 - w < vars.client.x) ? xPos + vars.client.h/25 : xPos - vars.client.h/25 - w, y := (yPos + h/2 > vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - h : (yPos - h/2 < vars.client.y) ? vars.client.y : yPos - h/2
		Else x := (mode = 2) ? vars.client.x + vars.client.w - w : (xPos - w/2 < vars.client.x) ? vars.client.x : (xPos + w/2 > vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - w : xPos - w/2
	}
	Gui, %GUI_name%: Show, % (mode ? "NA " : "") "x"x " y"y
	LLK_Overlay(mapinfo, "show", mode, GUI_name)
	
	WinGetPos,,, w, h, % "ahk_id " vars.hwnd.mapinfo.main
	If (w < 10)
		LLK_ToolTip(LangTrans("ms_map-info") ": " LangTrans("global_nothing"), 1.5,,,, "red"), LLK_Overlay(mapinfo, "destroy"), vars.mapinfo.active_map := ""
	LLK_Overlay(hwnd_old, "destroy")
}

MapinfoLineparse(line, ByRef text, ByRef value)
{
	local
	global vars

	If LangMatch(line, vars.lang.mods_contract_alert, 0) ;remove the %-value from "per x% alert level" contract-mods
		remove := SubStr(line, InStr(line, vars.lang.mods_contract_alert.1)), remove := SubStr(remove, 1, InStr(remove, vars.lang.mods_contract_alert.2) + StrLen(vars.lang.mods_contract_alert.2) - 1), remove2 := LangTrim(remove, vars.lang.mods_contract_alert), line := LLK_StringRemove(line, remove2 " , " remove2 "," remove2)

	Loop, Parse, line
	{
		If (A_Index = 1)
			text := "", value := ""
		If LLK_IsType(A_LoopField, "alpha") || InStr(",'", A_LoopField) || (A_LoopField = "-" && LLK_IsType(SubStr(line, A_Index + 1, 1), "alpha"))
			text .= A_LoopField
		Else If IsNumber(A_LoopField) || InStr(".", A_LoopField)
			value .= A_LoopField
	}
	text := StrReplace(text, "  ", " ")
	While (SubStr(text, 1, 1) = " ")
		text := SubStr(text, 2)
	While (SubStr(text, 0) = " ")
		text := SubStr(text, 1, -1)
}

MapinfoParse(mode := 1)
{
	local
	global vars, settings, db
	static clip
	
	item := vars.omnikey.item
	If mode
		clip := StrReplace(StrReplace(StrReplace(Clipboard, "`r`n", ";"), " — " LangTrans("items_unscalable")), " (augmented)")

	If LLK_PatternMatch(item.rarity, "", [LangTrans("items_normal"), LangTrans("items_unique")]) && !(InStr(item.name, "expedition logbook") || InStr(item.base, "expedition logbook"))
		error := [LangTrans("m_general_language", 3) ":`n" LLK_StringCase(LangTrans("items_normal") " && " LangTrans("items_unique")), 1.5, "Red"]
	Else If item.unid
		error := [LangTrans("m_general_language", 3) ":`n" LLK_StringCase(LangTrans("items_unidentified")), 1.5, "Red"]
	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3), LLK_Overlay(vars.hwnd.mapinfo.main, "destroy"), vars.mapinfo.active_map.cancel := 1
		Return 0
	}

	expedition_groups := db.mapinfo["expedition groups"].Clone(), vars.mapinfo.expedition_areas := db.mapinfo["expedition areas"].Clone(), vars.mapinfo.categories := db.mapinfo["mod types"].Clone(), vars.mapinfo.active_map := {}
	For index, category in vars.mapinfo.categories
		vars.mapinfo.active_map[category] := []
	mod_count := 0, map_mods := {}, mod_multi := 1, map := vars.mapinfo.active_map, mods := db.mapinfo.mods ;short-cut variables
	For key in map
		Loop 5
			map[key][(A_Index = 5) ? 0 : A_Index] := []

	Loop, Parse, clip, `;
	{
		If LLK_PatternMatch(A_LoopField, "{ ", [LangTrans("items_prefix"), LangTrans("items_suffix")])
		{
			mod_count += 1, texts := [], values := []
			Loop, Parse, A_LoopField, `n
			{
				If (A_Index = 1) || (SubStr(A_LoopField, 1, 1) = "(")
					Continue
				MapinfoLineparse(IteminfoModRemoveRange(A_LoopField), text, value)
				texts.Push(text), values.Push(Format("{:0." (InStr(value, ".") ? 1 : 0) "f}", (mod_multi != 1) ? Floor(value * mod_multi) : value)), check := "", value := ""
			}
			For index, text in texts
			{
				If mods.HasKey(text)
					map_mods[text] := map_mods.HasKey(text) ? map_mods[text] + values[index] : values[index]
				Else check .= !check ? text : "|" text, value .= !value ? values[index] : "/" values[index]
			}
			If check && mods.HasKey(check)
				map_mods[check] := value
		}
		Else If InStr(A_LoopField, " (enchant)")
		{
			If (SubStr(A_LoopField, 1, 1) = "(")
				Continue
			MapinfoLineparse(StrReplace(IteminfoModRemoveRange(A_LoopField), " (enchant)"), enchant_text, enchant_value)
			If InStr(A_LoopField, LangTrans("mods_memory_magnitude"))
				MapinfoLineparse(A_LoopField, magnitude_text, magnitude_value), mod_multi := Format("{:0.2f}", mod_multi + magnitude_value / 100)
			Else If mods.HasKey(enchant_text)
				map_mods[enchant_text] := map_mods.HasKey(enchant_text) ? map_mods[enchant_text] + enchant_value : enchant_value
		}
		Else If expedition_groups.HasKey(A_LoopField)
		{
			index_check := 1
			While LLK_HasVal(vars.mapinfo.expedition_areas, InStr(vars.mapinfo.categories[index_check], "(") ? SubStr(vars.mapinfo.categories[index_check], 1, InStr(vars.mapinfo.categories[index_check], "(") - 2) : vars.mapinfo.categories[index_check])
				index_check += 1
			expedition_npc := vars.mapinfo.expedition_npc := expedition_groups[A_LoopField], key := expedition_area " (" expedition_npc ")", vars.mapinfo.categories.InsertAt(index_check, key), map[key] := []
			Loop 5
				map[key][5 - A_Index] := []
		}
		Else If LLK_HasVal(vars.mapinfo.expedition_areas, A_LoopField)
			expedition_area := LLK_StringCase(A_LoopField)
		Else If InStr(A_LoopField, " (implicit)")
		{
			If (SubStr(A_LoopField, 1, 1) = "(")
				Continue
			MapinfoLineparse(StrReplace(IteminfoModRemoveRange(A_LoopField), " (implicit)"), implicit_text, implicit_value)
			If (mods[implicit_text].type = "expedition")
			{
				pushtext := InStr(mods[implicit_text].text, ": +") ? StrReplace(mods[implicit_text].text, ": +", ": +" implicit_value,, 1) : InStr(mods[implicit_text].text, "%") ? StrReplace(mods[implicit_text].text, "%", implicit_value "%",, 1) : mods[implicit_text].text
				If !settings.mapinfo.IDs[mods[implicit_text].id].show
				{
					If !IsObject(map[key].0[settings.mapinfo.IDs[mods[implicit_text].id].rank])
						map[key].0[settings.mapinfo.IDs[mods[implicit_text].id].rank] := []
					map[key].0[settings.mapinfo.IDs[mods[implicit_text].id].rank].Push([pushtext, mods[implicit_text].id])
				}
				Else map[key][settings.mapinfo.IDs[mods[implicit_text].id].rank].Push([pushtext, mods[implicit_text].id])
			}
		}
		Else
			For index, val in ["quantity", "rarity", "packsize"]
				If StrMatch(A_LoopField, LangTrans("items_map" val))
					%val% := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), %val% := StrReplace(StrReplace(%val%, "%"), "+")
	}
	/*
	If !item.itembase
	{
		For key, val in db.mapinfo.localization
			If InStr(item.name, key (LLK_PatternMatch(key, "", ["Invitation", "Logbook", "Contract", "Blueprint"]) ? "" : " Map"), 1)
				name := val, name_copy := key
	}
	Else name := db.mapinfo.localization[LLK_StringRemove(item.itembase, " Map,Maven's ")], name_copy := LLK_StringRemove(item.itembase, " Map,Maven's ")
	*/
	
	If !item.itembase_copy
	{
		name := item.name_copy, passes := 0
		Loop
		{
			If (passes = 2)
				Break
			Loop
			{
				If (A_Index > StrLen(name))
				{
					affix := ""
					Break
				}
				affix := SubStr(name, 1, A_Index)
				If InStr(vars.omnikey.clipboard, LangTrans("items_affix", 1) . affix . LangTrans("items_affix", 2))
				{
					name := LLK_StringRemove(name, affix " , " affix "," affix), affix := "", passes += 1
					Continue 2
				}
			}
			Loop
			{
				If (A_Index > StrLen(name))
				{
					passes += 1, affix := ""
					Break
				}
				affix := SubStr(name, 1 - A_Index)
				If InStr(vars.omnikey.clipboard, LangTrans("items_affix", 1) . affix . LangTrans("items_affix", 2))
				{
					name := LLK_StringRemove(name, affix " , " affix "," affix), affix := "", passes += 1
					Continue 2
				}
			}
		}
	}
	Else name := item.itembase_copy
	name := LangTrim(name, vars.lang.items_mapname)

	For key, val in db.mapinfo.localization
		If InStr(name, key)
			name := StrReplace(name, key, val)

	For map_mod, value in map_mods
	{
		pushtext := InStr(mods[map_mod].text, ": +") ? StrReplace(mods[map_mod].text, ": +", ": +" value,, 1) : InStr(mods[map_mod].text, "%") ? StrReplace(mods[map_mod].text, "%", value "%",, 1) : mods[map_mod].text
		If !settings.mapinfo.IDs[mods[map_mod].id].show
		{
			If !IsObject(map[mods[map_mod].type].0[settings.mapinfo.IDs[mods[map_mod].id].rank])
				map[mods[map_mod].type].0[settings.mapinfo.IDs[mods[map_mod].id].rank] := []
			map[mods[map_mod].type].0[settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
		}
		Else map[mods[map_mod].type][settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
	}

	For key, val in {"maven's invitation": "mavenhub", "expedition logbook": "expedition", "contract:": "heist", "blueprint:": "heist", "writing invitation": "primordialboss1", "polaric invitation": "primordialboss2", "incandescent invitation": "primordialboss3", "screaming invitation": "primordialboss4", "blighted ": "blight", "blight-ravaged ": "blight"}
		If InStr(item.name "`n" item.itembase, key)
		{
			map.tag := val
			Break
		}
	map.quantity := quantity, map.rarity := rarity, map.packsize := packsize, map.name := name, map.name_copy := name_copy, map.mods := mod_count, map.english := item.name "`n" item.itembase
	Return 1
}

MapinfoRank(hotkey)
{
	local
	global vars, settings
	
	check := LLK_HasVal(vars.hwnd.mapinfo, vars.general.cMouse), control := SubStr(check, InStr(check, "_") + 1)
	Loop, Parse, hotkey
		If IsNumber(A_LoopField)
		{
			hotkey := A_LoopField
			Break
		}
	
	If !check
		Return
	If IsNumber(hotkey)
	{
		settings.mapinfo.IDs[control].rank := hotkey
		IniWrite, % hotkey, ini\map info.ini, % control, rank
	}
	Else
	{
		settings.mapinfo.IDs[control].show := !settings.mapinfo.IDs[control].show
		IniWrite, % settings.mapinfo.IDs[control].show, ini\map info.ini, % control, show
	}
	MapinfoParse(0), MapinfoGUI(0)
	KeyWait, % hotkey
}
