Init_mapinfo()
{
	local
	global vars, settings
	
	If !FileExist("ini\map info.ini")
	{
		IniWrite, % "", ini\map info.ini, Settings
		IniWrite, % "", ini\map info.ini, UI
	}
	
	settings.features.mapinfo := LLK_IniRead("ini\config.ini", "Features", "enable map-info panel", 0)
	
	settings.mapinfo := {"IDs": {}}

	Loop, Parse, % LLK_FileRead("data\map mods.ini"), `n, `r
	{
		If !InStr(A_LoopField, "id=")
			Continue
		ID := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), settings.mapinfo.IDs[ID] := {"rank": LLK_IniRead("ini\map info.ini", ID, "rank", 1), "show": LLK_IniRead("ini\map info.ini", ID, "show", 1)}
	}

	settings.mapinfo.dColor := ["White", "f77e05", "Red", "Fuchsia", "909090"], settings.mapinfo.eColor_default := ["White", "Yellow", "Green", "Lime"]
	settings.mapinfo.color := [], settings.mapinfo.eColor := []
	Loop 5
		settings.mapinfo.color[A_Index] := LLK_IniRead("ini\map info.ini", "UI", (A_Index = 5) ? "header color" : "difficulty " A_Index " color", settings.mapinfo.dColor[A_Index])
		, settings.mapinfo.eColor[A_Index] := LLK_IniRead("ini\map info.ini", "UI", "logbook " A_Index " color", settings.mapinfo.eColor_default[A_Index])
	settings.mapinfo.fSize := LLK_IniRead("ini\map info.ini", "settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.mapinfo.fSize, font_height, font_width)
	settings.mapinfo.fHeight := font_height, settings.mapinfo.fWidth := font_width
	settings.mapinfo.trigger := LLK_IniRead("ini\map info.ini", "Settings", "enable shift-clicking", 0)
	settings.mapinfo.tabtoggle := LLK_IniRead("ini\map info.ini", "Settings", "show panel while holding tab", 0)
}

MapinfoGUI(mode := 1)
{
	local
	global vars, settings, Json

	map := vars.mapinfo.active_map ;short-cut variable
	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmapinfo" (mode = 2 ? " +E0x20" : "")
	Gui, %mapinfo%: Color, Black
	Gui, %mapinfo%: Margin, % settings.mapinfo.fWidth/2, % settings.mapinfo.fWidth/2
	Gui, %mapinfo%: Font, % "s"settings.mapinfo.fSize " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.mapinfo.main, vars.hwnd.mapinfo := {"main": mapinfo}, summary := map.mods "m | " map.quantity "q |" (!Blank(map.packsize) ? " " map.packsize "p" : " " map.rarity "r"), mod_count := 0
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
		
		;Gui, %mapinfo%: Font, underline
		Gui, %mapinfo%: Add, Text, % (added ? "xs " : "") "Section c"settings.mapinfo.color.5 " w"width (mode = 2 ? " Right" : ""), % (mode = 2 && InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category) ":" ;(LLK_HasVal(vars.mapinfo.expedition_areas, InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category) ? "Aqua"
		;Gui, %mapinfo%: Font, norm
		added += 1
		Loop 4
		{
			For index, val in map[category][5 - A_Index]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				Gui, %mapinfo%: Add, Text, % "xs y+-"settings.mapinfo.fHeight/6 " Section HWNDhwnd w"width " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : ""), % text
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd
			}
		}
		Gui, %mapinfo%: Font, strike
		Loop 4
		{
			If (mode = 2)
				Break
			For index, val in map[category].0[5 - A_Index]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				Gui, %mapinfo%: Add, Text, % "xs y+-"settings.mapinfo.fHeight/6 " Section HWNDhwnd w"width " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : ""), % text
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd
			}
		}
		Gui, %mapinfo%: Font, norm
	}

	If (map.mods + map.quantity > 0)
	{
		Gui, %mapinfo%: Add, Text, % "xs y+"settings.mapinfo.fWidth " Section Center HWNDhwnd w"width, % summary
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
				Gui, %mapinfo%: Add, Progress, % (!added ? "xs Section y+0 xp+"(width - w)/2 : "ys x+"settings.mapinfo.fWidth//10) " BackgroundBlack c"settings.mapinfo.color[5 - index0] " w"
				. w/mod_count - settings.mapinfo.fWidth//10 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
		Loop 4
		{
			index0 := A_Index
			Loop, % spectrum.0[5 - A_Index]
			{
				Gui, %mapinfo%: Add, Progress, % (!added ? "xs Section y+0 xp+"(width - w)/2 : "ys x+"settings.mapinfo.fWidth//10) " BackgroundBlack Border c"settings.mapinfo.color[5 - index0] " w"
				. w/mod_count - settings.mapinfo.fWidth//10 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
	}
	Else w := width

	If (InStr(vars.log.areaID, "hideout") || InStr(vars.log.areaID, "heisthub")) && (mode = 2) && !InStr(vars.mapinfo.active_map.name, "logbook")
		Gui, %mapinfo%: Add, Text, % "xs y+0 Center w"w, % LLK_StringCase(StrReplace(StrReplace(vars.mapinfo.active_map.name, "maven's invitation: "), " map"))

	If !mode
		WinGetPos, x, y,,, % "ahk_id "hwnd_old
	Else
	{
		Gui, %mapinfo%: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.mapinfo.main
		MouseGetPos, xPos, yPos
		x := (mode = 2) ? vars.monitor.x + vars.monitor.w - w : (xPos - w/2 < vars.monitor.x) ? vars.monitor.x : (xPos + w/2 > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos - w/2
		y := (mode = 2) ? "Center" : (yPos - (h + settings.mapinfo.fHeight * 2) < vars.monitor.y) ? yPos + h*0.1 : yPos - (h + settings.mapinfo.fHeight * 2)
	}
	Gui, %mapinfo%: Show, % (mode ? "NA " : "") "x"x " y"y
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.mapinfo.main
	If (w < 10)
	{
		LLK_ToolTip("map-info: nothing`nto display", 1.5,,,, "red")
		LLK_Overlay(mapinfo, "destroy")
	}
	Else LLK_Overlay(mapinfo, "show", mode)
	LLK_Overlay(hwnd_old, "destroy")
}

MapinfoLineparse(line, ByRef text, ByRef value)
{
	local

	Loop, Parse, line
	{
		If (A_Index = 1)
			text := "", value := ""
		If LLK_IsType(A_LoopField, "alpha") || InStr(",'", A_LoopField)
			text .= A_LoopField
		Else If IsNumber(A_LoopField)
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
	
	If mode
		clip := StrReplace(StrReplace(Clipboard, "`r`n", ";"), " — Unscalable Value")

	If (InStr(clip, "rarity: normal") || InStr(clip, "rarity: unique")) && !InStr(clip, "item class: expedition")
		error := ["not supported:`n" (InStr(clip, "rarity: normal") ? "white" : "unique") " maps", 1.5, "Red"]
	Else If InStr(clip, ";unidentified;")
		error := ["not supported:`nun-id maps", 1.5, "Red"]
	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3)
		Return 0
	}

	expedition_groups := {"Black Scythe Mercenaries": "tujen", "Order of the Chalice": "rog", "Druids of the Broken Circle": "gwennen", "Knights of the Sun": "dannig"}
	vars.mapinfo.expedition_areas := ["Battleground Graves", "Bluffs", "Cemetery", "Desert Ruins", "Dried Riverbed", "Forest Ruins", "Karui Wargraves", "Mountainside", "Rotting Temple", "Sarn Slums", "Scrublands", "Shipwreck Reef" ;cont
	, "Utzaal Outskirts", "Vaal Temple", "Volcanic Island"]
	vars.mapinfo.categories := ["player", "monsters", "bosses", "area", "heist"]
	vars.mapinfo.active_map := {"player": [], "bosses": [], "monsters": [], "area": [], "heist": []}, mod_count := 0, map_mods := {}, mod_multi := 1
	map := vars.mapinfo.active_map, mods := db.mapinfo.mods ;short-cut variables
	For key in map
		Loop 5
			map[key][(A_Index = 5) ? 0 : A_Index] := []
	
	Loop, Parse, clip, `;
	{
		If StrMatch(A_LoopField, "rarity: ")
			map_rarity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)
		Else If StrMatch(A_LoopField, "item quantity: ")
			quantity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), quantity := SubStr(quantity, 1, InStr(quantity, " ") - 1), quantity := StrReplace(StrReplace(quantity, "%"), "+")
		Else If StrMatch(A_LoopField, "item rarity: ")
			rarity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), rarity := SubStr(rarity, 1, InStr(rarity, " ") - 1), rarity := StrReplace(StrReplace(rarity, "%"), "+")
		Else If StrMatch(A_LoopField, "monster pack size: ")
			packsize := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), packsize := SubStr(packsize, 1, InStr(packsize, " ") - 1), packsize := StrReplace(StrReplace(packsize, "%"), "+")
		Else If StrMatch(A_LoopField, "{ prefix modifier """) || StrMatch(A_LoopField, "{ suffix modifier """)
		{
			mod_count += 1, texts := [], values := [], affix := InStr(A_LoopField, "{ prefix") ? "prefix" : "suffix", %affix% := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), %affix% := SubStr(%affix%, 1, InStr(%affix%, """") - 1)
			name := StrReplace(name, (affix = "prefix") ? %affix% " " : " " %affix%)
			Loop, Parse, A_LoopField, `n
			{
				If (A_Index = 1) || (SubStr(A_LoopField, 1, 1) = "(")
					Continue
				MapinfoLineparse(IteminfoModRemoveRange(StrReplace(A_LoopField, "per 25% alert level", "per alert level")), text, value)
				texts.Push(text), values.Push(Format("{:0.0f}", Floor(value * mod_multi))), check := "", value := ""
			}
			/*
			Loop, Parse, A_LoopField, `n
			{
				If (A_Index = 1) || (SubStr(A_LoopField, 1, 1) = "(")
					Continue
				parse := IteminfoModRemoveRange(StrReplace(A_LoopField, " per 25% alert level"))
				Loop, Parse, parse
				{
					If (A_Index = 1)
						text := "", value := ""
					If LLK_IsType(A_LoopField, "alpha") || InStr(",'", A_LoopField)
						text .= A_LoopField
					Else If IsNumber(A_LoopField)
						value .= A_LoopField
				}
				text := StrReplace(text, "  ", " ")
				While (SubStr(text, 1, 1) = " ")
					text := SubStr(text, 2)
				While (SubStr(text, 0) = " ")
					text := SubStr(text, 1, -1)
				texts.Push(text), values.Push(value), check := "", value := ""
			}
			*/
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
			If InStr(A_LoopField, "increased Explicit Modifier magnitudes")
				mod_multi := Format("{:0.2f}", mod_multi + SubStr(A_LoopField, 1, InStr(A_LoopField, "%") - 1) / 100)
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
		Else If (A_Index = 3)
			name := A_LoopField
		Else If (A_Index = 4) && !InStr(A_LoopField, "---")
			name := A_LoopField
	}

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

	map.quantity := quantity, map.rarity := rarity, map.packsize := packsize, map.name := name, map.mods := mod_count
	Return 1
}
/*
MapinfoParse(mode := 1)
{
	local
	global vars, settings, db
	static clip

	If mode
		clip := StrReplace(StrReplace(Clipboard, "`r`n", ";"), " — Unscalable Value")
	vars.mapinfo.active_map := {"player": {}, "bosses": {}, "monsters": {}, "area": {}, "heist": {}}, mod_count := 0
	map := vars.mapinfo.active_map, mods := db.mapinfo.mods ;short-cut variables
	For key in map
		Loop 5
			map[key][(A_Index = 5) ? 0 : A_Index] := []
	
	Loop, Parse, clip, `;
	{
		If StrMatch(A_LoopField, "rarity: ")
			map_rarity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)
		Else If StrMatch(A_LoopField, "item quantity: ")
			quantity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), quantity := SubStr(quantity, 1, InStr(quantity, " ") - 1), quantity := StrReplace(StrReplace(quantity, "%"), "+")
		Else If StrMatch(A_LoopField, "item rarity: ")
			rarity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), rarity := SubStr(rarity, 1, InStr(rarity, " ") - 1), rarity := StrReplace(StrReplace(rarity, "%"), "+")
		Else If StrMatch(A_LoopField, "monster pack size: ")
			packsize := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), packsize := SubStr(packsize, 1, InStr(packsize, " ") - 1), packsize := StrReplace(StrReplace(packsize, "%"), "+")
		Else If StrMatch(A_LoopField, "{ prefix modifier """) || StrMatch(A_LoopField, "{ suffix modifier """)
		{
			mod_count += 1, texts := [], values := [], affix := InStr(A_LoopField, "{ prefix") ? "prefix" : "suffix", %affix% := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), %affix% := SubStr(%affix%, 1, InStr(%affix%, """") - 1)
			name := StrReplace(name, (affix = "prefix") ? %affix% " " : " " %affix%)
			Loop, Parse, A_LoopField, `n
			{
				If (A_Index = 1) || (SubStr(A_LoopField, 1, 1) = "(")
					Continue
				parse := IteminfoModRemoveRange(StrReplace(A_LoopField, " per 25% alert level"))
				Loop, Parse, parse
				{
					If (A_Index = 1)
						text := "", value := ""
					If LLK_IsType(A_LoopField, "alpha") || InStr(",'", A_LoopField)
						text .= A_LoopField
					Else If IsNumber(A_LoopField)
						value .= A_LoopField
				}
				text := StrReplace(text, "  ", " ")
				While (SubStr(text, 1, 1) = " ")
					text := SubStr(text, 2)
				While (SubStr(text, 0) = " ")
					text := SubStr(text, 1, -1)
				texts.Push(text), values.Push(value), check := "", value := ""
			}
			For index, text in texts
			{
				If mods.HasKey(text)
				{
					pushtext := InStr(mods[text].text, ": +") ? StrReplace(mods[text].text, ": +", ": +" values[index],, 1) : InStr(mods[text].text, "%") ? StrReplace(mods[text].text, "%", values[index] "%",, 1) : mods[text].text
					If !settings.mapinfo.IDs[mods[text].id].show
					{
						If !IsObject(map[mods[text].type].0[settings.mapinfo.IDs[mods[text].id].rank])
							map[mods[text].type].0[settings.mapinfo.IDs[mods[text].id].rank] := []
						map[mods[text].type].0[settings.mapinfo.IDs[mods[text].id].rank].Push([pushtext, mods[text].id])
					}
					Else map[mods[text].type][settings.mapinfo.IDs[mods[text].id].rank].Push([pushtext, mods[text].id])
				}
				Else check .= !check ? text : "|" text, value .= !value ? values[index] : "/" values[index]
			}
			If check && mods.HasKey(check)
			{
				pushtext := InStr(mods[check].text, ": +") ? StrReplace(mods[check].text, ": +", ": +" value,, 1) : InStr(mods[check].text, "%") ? StrReplace(mods[check].text, "%", value "%",, 1) : mods[check].text
				If !settings.mapinfo.IDs[mods[check].id].show
				{
					If !IsObject(map[mods[check].type].0[settings.mapinfo.IDs[mods[check].id].rank])
						map[mods[check].type].0[settings.mapinfo.IDs[mods[check].id].rank] := []
					map[mods[check].type].0[settings.mapinfo.IDs[mods[check].id].rank].Push([pushtext, mods[check].id])
				}
				Else map[mods[check].type][settings.mapinfo.IDs[mods[check].id].rank].Push([pushtext, mods[check].id])
			}
		}
		Else If (A_Index = 3)
			name := A_LoopField
		Else If (A_Index = 4) && !InStr(A_LoopField, "---")
			name := A_LoopField
	}
	If InStr("normal,unique", map_rarity)
		error := ["not supported:`n" (map_rarity = "normal" ? "white" : LLK_StringCase(map_rarity)) " maps", 1.5, "Red"]
	Else If InStr(Clipboard, "`r`nunidentified`r`n")
		error := ["not supported:`nun-ID maps", 1.5, "Red"]
	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3)
		Return 0
	}
	map.quantity := quantity, map.rarity := rarity, map.packsize := packsize, map.name := name, map.mods := mod_count
	Return 1
}
*/
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
	;LLK_ToolTip(check ", " hotkey ", " settings.mapinfo.IDs[control].show)
	KeyWait, % hotkey
}
