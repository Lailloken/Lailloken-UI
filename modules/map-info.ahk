Init_mapinfo()
{
	local
	global vars, settings, db, Json

	If !FileExist("ini" vars.poe_version "\map info.ini")
	{
		IniWrite, % "", % "ini" vars.poe_version "\map info.ini", Settings
		IniWrite, % "", % "ini" vars.poe_version "\map info.ini", UI
	}

	ini := IniBatchRead("ini" vars.poe_version "\map info.ini")
	If !ini.HasKey("pinned")
		If !vars.poe_version
		{
			IniWrite, % "001=1`n002=1`n003=1`n004=1`n007=1", % "ini" vars.poe_version "\map info.ini", pinned
			ini.pinned := {"001": 1, "002": 1, "003": 1, "004": 1, "007": 1}
		}
		Else
		{
			IniWrite, % "053=1`n054=1`n056=1", % "ini" vars.poe_version "\map info.ini", pinned
			ini.pinned := {"053": 1, "054": 1, "056": 1}
		}
	settings.features.mapinfo := (settings.general.lang_client = "unknown") ? 0 : LLK_IniRead("ini" vars.poe_version "\config.ini", "Features", "enable map-info panel", 0)
	settings.mapinfo := {"IDs": {}, "pinned": {}}

	For key, val in ini.pinned
		settings.mapinfo.pinned[key] := val

	Loop, Parse, % StrReplace(LLK_FileRead("data\english\map-info" vars.poe_version ".txt"), "`t"), `n, `r
	{
		If !InStr(A_LoopField, "id=")
			Continue
		ID := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), settings.mapinfo.IDs[ID] := {"rank": !Blank(check := ini[ID].rank) ? check : 0, "show": !Blank(check1 := ini[ID].show) ? check1 : 1}
	}

	settings.mapinfo.dColor := ["00FF00", "FF8000", "FF0000", "FF00FF"], settings.mapinfo.eColor_default := ["FF8000", "FFFF00", "009900", "00FF00"]
	settings.mapinfo.dColor.0 := "FFFFFF", settings.mapinfo.eColor_default.0 := "FFFFFF"
	settings.mapinfo.color := [], settings.mapinfo.eColor := []
	Loop 5
		settings.mapinfo.color[5 - A_Index] := !Blank(check := ini.UI["difficulty " 5 - A_Index " color"]) ? check : settings.mapinfo.dColor[5 - A_Index]
	,	settings.mapinfo.eColor[5 - A_Index] := !Blank(check := ini.UI["logbook " 5 - A_Index " color"]) ? check : settings.mapinfo.eColor_default[5 - A_Index]
	settings.mapinfo.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.mapinfo.fSize, font_height, font_width), settings.mapinfo.fHeight := font_height, settings.mapinfo.fWidth := font_width
	settings.mapinfo.trigger := !Blank(check := ini.settings["enable shift-clicking"]) ? check : 0
	settings.mapinfo.tabtoggle := !Blank(check := ini.settings["show panel while holding tab"]) ? check : 0
	settings.mapinfo.roll_highlight := !Blank(check := ini.settings["highlight map rolls"]) ? check : 0, settings.mapinfo.roll_requirements := {}
	settings.mapinfo.roll_colors := [!Blank(check := ini.UI["map rolls text color"]) ? check : "00FF00", !Blank(check1 := ini.UI["map rolls back color"]) ? check1 : "000000"]
	Loop 6
		settings.mapinfo.roll_requirements[Lang_Trans("maps_stats_full", A_Index + 1)] := !Blank(check := ini.UI[Lang_Trans("maps_stats_full", A_Index + 1) " requirement"]) ? check : ""

	lang := settings.general.lang_client, db.mapinfo := {"localization": {}, "maps": {}, "mods": {}, "mod types": [], "expedition areas": [], "expedition groups": {}}
	Loop, Parse, % StrReplace(LLK_FileRead("data\" (FileExist("data\" lang "\map-info" vars.poe_version ".txt") ? lang : "english") "\map-info" vars.poe_version ".txt", 1), "`t"), `n, `r
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

Mapinfo_GUI(mode := 1)
{
	local
	global vars, settings
	static toggle := 0

	map := vars.mapinfo.active_map ;short-cut variable
	If !map
		Return
	toggle := !toggle, GUI_name := "mapinfo" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDmapinfo" (mode = 2 ? " +E0x20" : "")
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, 0, 0 ;% settings.mapinfo.fWidth/2, % settings.mapinfo.fWidth/2
	Gui, %GUI_name%: Font, % "s"settings.mapinfo.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.mapinfo.main, vars.hwnd.mapinfo := {"main": mapinfo}, mod_count := 0
	If !vars.poe_version
		summary := summary0 := map.mods . Lang_Trans("maps_stats", 1) " | " map.quantity . Lang_Trans("maps_stats", 2) " | " map.rarity . Lang_Trans("maps_stats", 3)
		. (!Blank(map.packsize) ? " | " map.packsize . Lang_Trans("maps_stats", 4) : "")
	Else summary := summary0 := "waystones: " (Blank(map.waystones) ? "+0%" : map.waystones) ;(map.tier >= 11 ? "-20% ele res (t11+)" : map.tier >= 6 ? "-10% ele res (t6+)" : "no res penalty")

	If StrLen(map.maps . map.scarabs . map.currency)
	{
		Loop, Parse, % "maps,scarabs,currency", `,
			If !Blank(map[A_LoopField])
				add := " | " map[A_LoopField] . Lang_Trans("maps_stats", 4 + A_Index), summary .= add, summary1 .= StrReplace(add, !summary1 ? " | " : "")
	}

	dimensions := [], summary_array := StrSplit(summary, "|", A_Space), summary_array0 := StrSplit(summary0, "|", A_Space), summary_array1 := StrSplit(summary1, "|", A_Space)
	LLK_PanelDimensions(summary_array, settings.mapinfo.fSize, wSummary, hSummary)

	For index0, category in vars.mapinfo.categories
	{
		If Blank(category)
			Continue
		If InStr(category, "(")
			dimensions.Push(SubStr(category, 1, InStr(category, "(") - 2))
		Loop 5
		{
			For index, val in map[category][5 - A_Index]
				dimensions.Push((mode = 2) && InStr(val.1, ":") ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1), mod_count += (SubStr(val.2, 1, 1) != 3) ? 1 : 0
			For index, val in map[category][-1][5 - A_Index]
			{
				If (mode != 2)
					dimensions.Push(val.1)
				mod_count += (SubStr(val.2, 1, 1) != 3) ? 1 : 0
			}
		}
	}
	LLK_PanelDimensions(dimensions, settings.mapinfo.fSize, wPanels, hPanels), added := 0, yControl := hControl := 0, count := {}, wPic := settings.mapinfo.fHeight*2 - 1
	divisor := (wPanels + wPic - 1 > wSummary * summary_array0.Count()) ? 4 : summary_array0.Count()
	wPanels := wGUI := Max(wPanels + wPic - 1, wSummary * summary_array0.Count()), wSpectrum := wSummary * summary_array0.Count() - 2, wSpectrum1 := wSpectrum // mod_count
	While Mod(wGui, divisor)
		wGui += 1, wPanels += 1
	wPanels := wPanels - wPic + 1

	For index0, category in vars.mapinfo.categories
	{
		check := 0
		Loop, 5
			check += map[category][5 - A_Index].Count() ? map[category][5 - A_Index].Count() : 0
		If (mode < 2)
			For index, array in map[category][-1]
				check += array.Count() ? array.Count() : 0
		If !check
			Continue
		count[category] := 0

		If (mode < 2)
		{
			pic := (InStr(category, "(") ? SubStr(category, InStr(category, "(") + 1, InStr(category, ")") - InStr(category, "(") - 1) : category), check += InStr(category, "(") ? 1 : 0
			hPic := Max(check*settings.mapinfo.fHeight - check + 1, settings.mapinfo.fHeight*2 - 1)
			GUI, %GUI_name%: Add, Text, % "xs x0 " (!added ? " y0" : " y" yControl + hControl - 1) " Section HWNDhwnd Border BackgroundTrans w" wPic " h" hPic, % " "
			ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
			pBitmap0 := Gdip_CreateBitmapFromFile("img\GUI\map-info\" pic ".png")
			If InStr("area,heist", category)
				factor := hPic/wPic, hResize := Round(64 * factor), pBitmap := Gdip_CloneBitmapArea(pBitmap0,, 200 - hResize/2, 64, hResize,, 1)
			Else pBitmap := Gdip_CloneBitmapArea(pBitmap0,,, 64, Round(64 * (hPic/wPic)),, 1)
			hbmBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
			GUI, %GUI_name%: Add, Pic, % "xp yp h" hPic " w-1", HBitmap:*%hbmBitmap%
			Gdip_DisposeImage(pBitmap0), Gdip_DisposeImage(pBitmap), DeleteObject(hbmBitmap)
		}

		If InStr(category, "(")
		{
			Gui, %GUI_name%: Font, underline
			style := (mode < 2) ? "ys Section x+-1 y" yControl : "xs Section" . (added ? " y" yControl + hControl - 1 : "")
			Gui, %GUI_name%: Add, Text, % style . (mode = 2 ? " Right" : " Center") " HWNDhwnd Border w" wPanels . (mode = 2 ? " Right" : ""), % " " SubStr(category, 1, Instr(category, "(") - 2) " "
			Gui, %GUI_name%: Font, norm
			ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
			added += 1, count[category] += 1, yControl1 := yControl
		}

		Loop 5
		{
			outer := A_Index
			For index, val in map[category][5 - outer]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				If (mode < 2)
					style := !count[category] ? "ys x+-1 y" yControl : "xs y+-1"
				Else style := added ? "xs y" yControl + hControl - 1 : "xs"
				Gui, %GUI_name%: Add, Text, % style . (!count[category] ? " Section" : "") " Border HWNDhwnd w" wPanels " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : "") . (check < 2 ? " 0x200 h" settings.mapinfo.fHeight*2 - 1 : ""), % " " text " "
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd, count[category] += 1, added += 1
				ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
				If (count[category] = 1)
					yControl1 := yControl
			}
		}
		Gui, %GUI_name%: Font, strike
		Loop 5
		{
			If (mode = 2)
				Break
			For index, val in map[category][-1][5 - A_Index]
			{
				text := InStr(val.1, ":") && (mode = 2) ? SubStr(val.1, 1, InStr(val.1, ":") - 1) : val.1, prefix := ""
				If (mode < 2)
					style := !count[category] ? "ys x+-1 y" yControl : "xs y+-1"
				Else style := added ? "xs y" yControl + hControl - 1 : "xs"
				Gui, %GUI_name%: Add, Text, % style . (!count[category] ? " Section" : "") " Border HWNDhwnd w" wPanels " c"settings.mapinfo[(SubStr(val.2, 1, 1) = 3) ? "eColor" : "color"][settings.mapinfo.IDs[val.2].rank] (mode = 2 ? " Right" : "") . (check < 2 ? " 0x200 h" settings.mapinfo.fHeight*2 - 1 : ""), % " " text " "
				While vars.hwnd.mapinfo.HasKey(prefix "mod_" val.2)
					prefix := A_Index
				vars.hwnd.mapinfo[prefix "mod_" val.2] := hwnd, count[category] += 1, added += 1
				ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
				If (count[category] = 1)
					yControl1 := yControl
			}
		}
		Gui, %GUI_name%: Font, norm
		If (mode = 2)
		{
			pic := (InStr(category, "(") ? SubStr(category, InStr(category, "(") + 1, InStr(category, ")") - InStr(category, "(") - 1) : category), check += InStr(category, "(") ? 1 : 0
			wPic := settings.mapinfo.fHeight*2 - 1, hPic := Max(check*settings.mapinfo.fHeight - check + 1, settings.mapinfo.fHeight*2 - 1)
			GUI, %GUI_name%: Add, Text, % "ys x+-1 Border BackgroundTrans y" yControl1 " h" yControl + hControl - yControl1 " w" wPic, % " "
			pBitmap0 := Gdip_CreateBitmapFromFile("img\GUI\map-info\" pic ".png")
			If InStr("area,heist", category)
				factor := hPic/wPic, hResize := Round(64 * factor), pBitmap := Gdip_CloneBitmapArea(pBitmap0,, 200 - hResize/2, 64, hResize,, 1)
			Else pBitmap := Gdip_CloneBitmapArea(pBitmap0,,, 64, Round(64 * (hPic/wPic)),, 1)
			hbmBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
			GUI, %GUI_name%: Add, Pic, % "xp yp h" hPic " w-1", HBitmap:*%hbmBitmap%
			Gdip_DisposeImage(pBitmap0), Gdip_DisposeImage(pBitmap), DeleteObject(hbmBitmap)
		}
	}

	rolls := ["mods", "quantity", "rarity", "pack size", "maps", "scarabs", "currency"]
	If (map.mods + (!vars.poe_version ? map.quantity : 0) > 0)
	{
		;Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans x1 y" yControl + hControl " Section HWNDhwnd Center w" width + settings.mapinfo.fHeight*2 - 3, % summary
		For index, vSum in summary_array0
		{
			style := (index = 1 ? "xs Section y+" (yControl + hControl ? -1 : 0) " x" wGUI//2 - (wSummary * summary_array0.Count())//2 : "ys x+0"), roll := settings.mapinfo.roll_requirements[rolls[index]]
			color := settings.mapinfo.roll_highlight && !Blank(roll) && (SubStr(vSum, 1, -1) >= roll) ? " c" settings.mapinfo.roll_colors.1 : ""
			Gui, %GUI_name%: Add, Text, % style " HWNDhwnd BackgroundTrans Border Center w" wSummary . color, % vSum
			If color
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack c" settings.mapinfo.roll_colors.2, 100
		}
		For index, vSum in summary_array1
		{
			style := (index = 1 ? "xs Section y+" (yControl + hControl ? -1 : 0) " x" wGUI//2 - (wSummary * summary_array1.Count())//2 : "ys x+0"), roll := settings.mapinfo.roll_requirements[rolls[index + 4]]
			color := settings.mapinfo.roll_highlight && !Blank(roll) && (SubStr(vSum, 1, -1) >= roll) ? " c" settings.mapinfo.roll_colors.1 : ""
			Gui, %GUI_name%: Add, Text, % style " HWNDhwnd BackgroundTrans Border Center w" wSummary . color, % vSum
			If color
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack c" settings.mapinfo.roll_colors.2, 100
		}
		added := 0, spectrum := [0, 0, 0, 0], spectrum[-1] := [0, 0, 0, 0], spectrum.0 := 0, spectrum[-1].0 := 0

		For index0, category in vars.mapinfo.categories
		{
			If !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, InStr(category, "(") ? SubStr(category, 1, InStr(category, "(") - 2) : category))
				Continue
			Loop 5
			{
				spectrum[5 - A_Index] += map[category][5 - A_Index].Count() ? map[category][5 - A_Index].Count() : 0
				spectrum[-1][5 - A_Index] += map[category][-1][5 - A_Index].Count() ? map[category][-1][5 - A_Index].Count() : 0
			}
		}

		Loop 5
		{
			index0 := A_Index
			Loop, % spectrum[5 - A_Index]
			{
				style := !added ? "xs Section HWNDhwnd y+" settings.mapinfo.fHeight//5 " x" wGui/2 - (wSpectrum1 * mod_count)/2 : "ys x+0" ;(Mod(wSpectrum, mod_count) && LLK_IsBetween(added, Floor(mod_count/2), Ceil(mod_count/2)) ? (mod_count > 3 ? 2 : 1) : 0)
				Gui, %GUI_name%: Add, Progress, % style " BackgroundBlack c"settings.mapinfo.color[5 - index0] " w" wSpectrum1 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
		Loop 5
		{
			index0 := A_Index
			Loop, % spectrum[-1][5 - A_Index]
			{
				style := !added ? "xs Section HWNDhwnd y+" settings.mapinfo.fHeight//5 " x" wGui/2 - (wSpectrum1 * mod_count)/2 : "ys x+0" ;(Mod(wSpectrum, mod_count) && LLK_IsBetween(added, Floor(mod_count/2), Ceil(mod_count/2)) ? (mod_count > 3 ? 2 : 1) : 0)
				Gui, %GUI_name%: Add, Progress, % style " BackgroundBlack Border c"settings.mapinfo.color[5 - index0] " w" wSpectrum1 " h"settings.mapinfo.fHeight/3, 100
				added += 1
			}
		}
		ControlGetPos, xPos, yPos, w_, h_,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Text, % "Border BackgroundTrans x0 y" yControl + hControl - 1 " w" wGUI " h" yPos + h_ - (yControl + hControl) + settings.mapinfo.fHeight//4, % " "
	}

	If !mode
		WinGetPos, x, y,,, % "ahk_id "hwnd_old
	Else
	{
		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.mapinfo.main
		MouseGetPos, xPos, yPos
		y := (mode = 2) ? vars.monitor.y + vars.client.yc - h/2 : (yPos - (h + vars.client.h/25) < vars.client.y) ? yPos + vars.client.h/25 : yPos - (h + vars.client.h/25), oob := (y + h > vars.client.y + vars.client.h) ? 1 : 0
		If oob
			x := (xPos - vars.client.h/25 - w < vars.client.x) ? xPos + vars.client.h/25 : xPos - vars.client.h/25 - w, y := (yPos + h/2 > vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - h : (yPos - h/2 < vars.client.y) ? vars.client.y : yPos - h/2
		Else x := (mode = 2) ? vars.client.x + vars.client.w - w : (xPos - w/2 < vars.client.x) ? vars.client.x : (xPos + w/2 > vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - w : xPos - w/2
	}
	Gui, %GUI_name%: Show, % (mode ? "NA " : "") "x"x " y"y
	LLK_Overlay(mapinfo, "show", mode, GUI_name)

	WinGetPos,,, w, h, % "ahk_id " vars.hwnd.mapinfo.main
	If (w < 10)
		LLK_ToolTip(Lang_Trans("ms_map-info") ": " Lang_Trans("global_nothing"), 1.5,,,, "red"), LLK_Overlay(mapinfo, "destroy"), vars.mapinfo.active_map := ""
	LLK_Overlay(hwnd_old, "destroy"), vars.mapinfo.active_map.summary := summary
}

Mapinfo_Lineparse(line, ByRef text, ByRef value)
{
	local
	global vars

	If !vars.poe_version && Lang_Match(line, vars.lang.mods_contract_alert, 0) ;remove the %-value from "per x% alert level" contract-mods
		remove := SubStr(line, InStr(line, vars.lang.mods_contract_alert.1)), remove := SubStr(remove, 1, InStr(remove, vars.lang.mods_contract_alert.2) + StrLen(vars.lang.mods_contract_alert.2) - 1)
		, remove2 := Lang_Trim(remove, vars.lang.mods_contract_alert), line := LLK_StringRemove(line, remove2 " , " remove2 "," remove2)

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

Mapinfo_Parse(mode := 1, poe_version := "")
{
	local
	global vars, settings, db
	static clip

	If poe_version
		Return Mapinfo_Parse2(mode)

	item := vars.omnikey.item
	If mode
		clip := StrReplace(StrReplace(StrReplace(Clipboard, "`r`n", ";"), " — " Lang_Trans("items_unscalable")), " (augmented)")

	If LLK_PatternMatch(item.rarity, "", [Lang_Trans("items_normal"), Lang_Trans("items_unique")]) && !(InStr(item.name, "expedition logbook") || InStr(item.base, "expedition logbook"))
		error := [Lang_Trans("m_general_language", 3) ":`n" LLK_StringCase(Lang_Trans("items_normal") " && " Lang_Trans("items_unique")), 1.5, "Red"]
	Else If item.unid
		error := [Lang_Trans("m_general_language", 3) ":`n" LLK_StringCase(Lang_Trans("items_unidentified")), 1.5, "Red"]
	Else If InStr(clip, Lang_Trans("items_mapreward"))
		error := [Lang_Trans("m_general_language", 3) ":`nvaldo maps", 1.5, "Red"]

	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3), LLK_Overlay(vars.hwnd.mapinfo.main, "destroy"), vars.mapinfo.active_map := ""
		Return 0
	}

	expedition_groups := db.mapinfo["expedition groups"].Clone(), vars.mapinfo.expedition_areas := db.mapinfo["expedition areas"].Clone(), vars.mapinfo.categories := db.mapinfo["mod types"].Clone(), vars.mapinfo.active_map := {}
	For index, category in vars.mapinfo.categories
		vars.mapinfo.active_map[category] := []
	mod_count := 0, map_mods := {}, content := [], mod_multi := 1, map := vars.mapinfo.active_map, mods := db.mapinfo.mods ;short-cut variables
	For key in map
		Loop 6
			map[key][5 - A_Index] := []

	Loop, Parse, clip, `;
	{
		If LLK_PatternMatch(A_LoopField, "{ ", [Lang_Trans("items_prefix"), Lang_Trans("items_suffix")])
		{
			mod_count += 1, texts := [], values := []
			Loop, Parse, A_LoopField, `n
			{
				If (A_Index = 1) || (SubStr(A_LoopField, 1, 1) = "(")
					Continue
				Mapinfo_Lineparse(Iteminfo_ModRemoveRange(A_LoopField), text, value)
				texts.Push(text)
				If IsNumber(value)
					values.Push(Format("{:0." (InStr(value, ".") ? 1 : 0) "f}", (mod_multi != 1) ? Floor(value * mod_multi) : value))
				Else values.Push("")
				check := "", value := ""
			}
			For index, text in texts
			{
				If mods.HasKey(text) && !LLK_HasKey(mods, text "|" texts[index + 1], 1) && !LLK_HasKey(mods, texts[index -1] "|" text, 1)
					map_mods[text] := map_mods.HasKey(text) ? map_mods[text] + values[index] : values[index]
				Else check .= !check ? text : "|" text, value .= !value ? values[index] : (InStr(check, " fewer trap") || SubStr(value, 0 - StrLen(values[index])) = values[index] || InStr(check, "inflict withered") ? "" : IsNumber(values[index]) ? "/" values[index] : "")
			}

			If check && mods.HasKey(check)
				map_mods[check] := value
			Else If check && settings.general.dev && !InStr(check, "also apply to rarity")
			{
				Clipboard := check
				MsgBox, % check
			}
		}
		Else If LLK_PatternMatch(A_LoopField, "", [Lang_Trans("items_elderguardian")]) || Lang_Match(A_LoopField, vars.lang.items_conqueror)
		{
			For outer in ["", ""]
				For mechanic in (outer = 1) ? {"enslaver": 1, "eradicator": 1, "constrictor": 1, "purifier": 1} : {"baran": 1, "drox": 1, "al-hezmin": 1, "veritania": 1}
					If InStr(A_LoopField, Lang_Trans("items_" mechanic), 1)
						content.Push(mechanic)
		}
		Else If InStr(A_LoopField, " (enchant)")
		{
			If (SubStr(A_LoopField, 1, 1) = "(")
				Continue
			Mapinfo_Lineparse(StrReplace(Iteminfo_ModRemoveRange(A_LoopField), " (enchant)"), enchant_text, enchant_value)
			If InStr(A_LoopField, Lang_Trans("mods_memory_magnitude"))
				Mapinfo_Lineparse(A_LoopField, magnitude_text, magnitude_value), mod_multi := Format("{:0.2f}", mod_multi + magnitude_value / 100)
			Else If mods.HasKey(enchant_text)
				map_mods[enchant_text] := map_mods.HasKey(enchant_text) ? map_mods[enchant_text] + enchant_value : enchant_value
		}
		Else If expedition_groups.HasKey(A_LoopField)
		{
			index_check := 1
			While LLK_HasVal(vars.mapinfo.expedition_areas, InStr(vars.mapinfo.categories[index_check], "(") ? SubStr(vars.mapinfo.categories[index_check], 1, InStr(vars.mapinfo.categories[index_check], "(") - 2) : vars.mapinfo.categories[index_check])
				index_check += 1
			expedition_npc := vars.mapinfo.expedition_npc := expedition_groups[A_LoopField], key := expedition_area " (" expedition_npc ")", vars.mapinfo.categories.InsertAt(index_check, key), map[key] := []
			Loop 6
				map[key][5 - A_Index] := []
		}
		Else If !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, A_LoopField))
			expedition_area := LLK_StringCase(A_LoopField)
		Else If InStr(A_LoopField, " (implicit)")
		{
			If (SubStr(A_LoopField, 1, 1) = "(")
				Continue
			Mapinfo_Lineparse(StrReplace(Iteminfo_ModRemoveRange(A_LoopField), " (implicit)"), implicit_text, implicit_value)
			If (mods[implicit_text].type = "expedition")
			{
				pushtext := InStr(mods[implicit_text].text, ": +") ? StrReplace(mods[implicit_text].text, ": +", ": +" implicit_value,, 1) : InStr(mods[implicit_text].text, "%") ? StrReplace(mods[implicit_text].text, "%", implicit_value "%",, 1) : mods[implicit_text].text
				If !settings.mapinfo.IDs[mods[implicit_text].id].show
				{
					If !IsObject(map[key][-1][settings.mapinfo.IDs[mods[implicit_text].id].rank])
						map[key][-1][settings.mapinfo.IDs[mods[implicit_text].id].rank] := []
					map[key][-1][settings.mapinfo.IDs[mods[implicit_text].id].rank].Push([pushtext, mods[implicit_text].id])
				}
				Else map[key][settings.mapinfo.IDs[mods[implicit_text].id].rank].Push([pushtext, mods[implicit_text].id])
			}
		}
		Else If InStr(A_LoopField, Lang_Trans("items_maptier"))
			tier := SubStr(A_LoopField, -1), tier += 0
		Else
			For index, val in ["quantity", "rarity", "packsize", "maps", "scarabs", "currency"]
			{
				If StrMatch(A_LoopField, Lang_Trans("items_map" val))
					%val% := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), %val% := StrReplace(StrReplace(%val%, "%"), "+")
				Else If (tier = 17) && (index > 3) && Blank(%val%)
					%val% := 0
			}
	}

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
				If InStr(vars.omnikey.clipboard, Lang_Trans("items_affix", 1) . affix . Lang_Trans("items_affix", 2))
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
				If InStr(vars.omnikey.clipboard, Lang_Trans("items_affix", 1) . affix . Lang_Trans("items_affix", 2))
				{
					name := LLK_StringRemove(name, affix " , " affix "," affix), affix := "", passes += 1
					Continue 2
				}
			}
		}
	}
	Else name := item.itembase_copy
	name := Lang_Trim(name, vars.lang.items_mapname)

	For key, val in db.mapinfo.localization
		If InStr(name, key)
			name := StrReplace(name, key, val)

	For map_mod, value in map_mods
	{
		pushtext := InStr(mods[map_mod].text, ": +") || InStr(mods[map_mod].text, ": -") ? StrReplace(StrReplace(mods[map_mod].text, ": -", ": -" value), ": +", ": +" value,, 1) : InStr(mods[map_mod].text, "%") ? StrReplace(mods[map_mod].text, "%", value "%",, 1) : mods[map_mod].text
		pushtext := StrReplace(pushtext, "(n)", "`n")
		If !settings.mapinfo.IDs[mods[map_mod].id].show
		{
			If !IsObject(map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank])
				map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank] := []
			map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
		}
		Else map[mods[map_mod].type][settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
	}

	For key, val in {"maven's invitation": "mavenhub", "expedition logbook": "expedition", "contract:": "heist", "blueprint:": "heist", "writing invitation": "primordialboss1", "polaric invitation": "primordialboss2", "incandescent invitation": "primordialboss3", "screaming invitation": "primordialboss4", "blighted ": "blight", "blight-ravaged ": "blight"}
		If InStr(item.name "`n" item.itembase, key)
		{
			map.tag := val
			Break
		}
	map.quantity := quantity, map.rarity := rarity, map.packsize := packsize, map.maps := maps, map.scarabs := scarabs, map.currency := currency, map.name := name, map.name_copy := name_copy, map.mods := mod_count, map.english := item.name "`n" item.itembase
	If content.Count()
		map.content := content.Clone()
	Return 1
}

Mapinfo_Parse2(mode)
{
	local
	global vars, settings, db
	static clip

	item := vars.omnikey.item
	If mode
		clip := StrReplace(Clipboard, " (augmented)")

	If LLK_PatternMatch(item.rarity, "", [Lang_Trans("items_normal"), Lang_Trans("items_unique")])
		error := [Lang_Trans("m_general_language", 3) ":`n" LLK_StringCase(Lang_Trans("items_normal") " && " Lang_Trans("items_unique")), 1.5, "Red"]
	Else If item.unid
		error := [Lang_Trans("m_general_language", 3) ":`n" LLK_StringCase(Lang_Trans("items_unidentified")), 1.5, "Red"]

	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3), LLK_Overlay(vars.hwnd.mapinfo.main, "destroy"), vars.mapinfo.active_map := ""
		Return 0
	}

	vars.mapinfo.categories := db.mapinfo["mod types"].Clone(), vars.mapinfo.active_map := {}
	For index, category in vars.mapinfo.categories
		vars.mapinfo.active_map[category] := []
	mod_count := 0, map_mods := {}, map := vars.mapinfo.active_map, mods := db.mapinfo.mods, parsed_lines := {}, map.mods := 0

	;If !IsObject(clip)
	;	clip := StrSplit(clip, "`n", "`r ")

	For key in map
		Loop 6
			map[key][5 - A_Index] := []

	Loop, Parse, clip, `n, `r
	{
		If !map.name
			If !InStr(A_LoopField, "(")
				Continue
			Else map.name := A_LoopField

		If !item_level
			If !InStr(A_LoopField, Lang_Trans("items_ilevel")) && !InStr(A_LoopField, "waystone drop chance:")
				Continue
			Else If InStr(A_LoopField, "waystone drop chance:")
				map.waystones := SubStr(A_LoopField, InStr(A_LoopField, "+")), map.waystones := (check := InStr(map.waystones, " (")) ? SubStr(map.waystones, 1, check - 1) : map.waystones
			Else
			{
				item_level := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)
				raw_text := SubStr(clip, InStr(clip, Lang_Trans("items_ilevel"))), raw_text := SubStr(raw_text, InStr(raw_text, "-`r`n") + 3), raw_text := SubStr(raw_text, 1, InStr(raw_text, "---") - 3)
				Break
			}
	}

	Loop, Parse, raw_text, `n, `r
	{
		If (A_Index = 1)
			raw_text := ""
		Mapinfo_Lineparse(Iteminfo_ModRemoveRange(A_LoopField), text, value)
		raw_text .= (!raw_text ? "" : "`n") text, parsed_lines[text] := !parsed_lines[text] ? value : parsed_lines[text] + value
	}

	For key, val in db.mapinfo.mods
		If RegExMatch(raw_text, "i)" StrReplace(key, "|", ".*"))
		{
			map.mods += 1
			Loop, Parse, key, % "|"
				map_mods[key] .= (!map_mods[key] ? "" : "/") . parsed_lines[A_LoopField], raw_text := StrReplace(raw_text, A_LoopField, "",, 1)
			If InStr(key, "freeze buildup")
				map_mods[key] := SubStr(map_mods[key], 1, InStr(map_mods[key], "/") - 1) ;freeze/ignite/shock hybrid mod is always X/X/X %, so simply display as X%
		}

	Loop, Parse, raw_text, `n, `r
		If settings.general.dev && !Blank(A_LoopField)
			MsgBox, % "unknown mod: " A_LoopField

	For map_mod, value in map_mods
	{
		pushtext := InStr(mods[map_mod].text, ": +") || InStr(mods[map_mod].text, ": -") ? StrReplace(StrReplace(mods[map_mod].text, ": -", ": -" value), ": +", ": +" value,, 1) : InStr(mods[map_mod].text, "%") ? StrReplace(mods[map_mod].text, "%", value "%",, 1) : mods[map_mod].text
		pushtext := StrReplace(pushtext, "(n)", "`n")
		If !settings.mapinfo.IDs[mods[map_mod].id].show
		{
			If !IsObject(map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank])
				map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank] := []
			map[mods[map_mod].type][-1][settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
		}
		Else map[mods[map_mod].type][settings.mapinfo.IDs[mods[map_mod].id].rank].Push([pushtext, mods[map_mod].id])
	}
	Return 1
}

Mapinfo_Rank(hotkey)
{
	local
	global vars, settings

	search := (vars.general.wMouse = vars.hwnd.settings.main) ? 1 : 0
	check := LLK_HasVal(!search ? vars.hwnd.mapinfo : vars.hwnd.settings, vars.general.cMouse), control := SubStr(check, InStr(check, "_") + 1)

	If !check
		Return

	If !InStr(hotkey, "RButton")
		hotkey0 := Hotkeys_RemoveModifiers(hotkey), hotkey := GetKeyName(hotkey0)
	Else hotkey := 0

	If IsNumber(hotkey)
		IniWrite, % (settings.mapinfo.IDs[control].rank := hotkey), % "ini" vars.poe_version "\map info.ini", % control, rank
	Else IniWrite, % (settings.mapinfo.IDs[control].show := !settings.mapinfo.IDs[control].show), % "ini" vars.poe_version "\map info.ini", % control, show
	If !search
		Mapinfo_Parse(0, vars.poe_version), Mapinfo_GUI(0)
	Else Settings_menu("map-info",, 0)
	KeyWait, % hotkey0
}
