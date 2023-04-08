Init_maps:
If !FileExist("ini\map info.ini")
{
	IniWrite, % "", ini\map info.ini, Settings
	IniWrite, % "", ini\map info.ini, UI
}
Loop 16
{
	IniRead, maps_tier%A_Index%, data\Atlas.ini, Maps, tier%A_Index%
	StringLower, maps_tier%A_Index%, maps_tier%A_Index%
	maps_list := (maps_list = "") ? StrReplace(maps_tier%A_Index%, ",", " (" A_Index "),") : maps_list StrReplace(maps_tier%A_Index%, ",", " (" A_Index "),")
	Sort, maps_tier%A_Index%, D`,
	maps_tier%A_Index% := SubStr(maps_tier%A_Index%, 1, -1)
	maps_tier%A_Index% := StrReplace(maps_tier%A_Index%, ",", "`n")
}
Sort, maps_list, D`,
Loop, Parse, maps_list, `,, `,
{
	If (A_Loopfield = "")
		break
	letter := SubStr(A_Loopfield, 1, 1)
	maps_%letter% := (maps_%letter% = "") ? A_Loopfield : maps_%letter% "`n" A_Loopfield
}

mapinfo_colors_default := ["White", "f77e05", "Red", "Fuchsia"]
mapinfo_colors_default[0] := "909090"
mapinfo_colors := []
Loop 5
{
	loop := A_Index - 1
	If (A_Index = 1)
		IniRead, cID, ini\map info.ini, UI, header color, % A_Space
	Else IniRead, cID, ini\map info.ini, UI, difficulty %loop% color, % A_Space
	If !cID
		mapinfo_colors[loop] := mapinfo_colors_default[loop]
	Else mapinfo_colors[loop] := cID
}

IniRead, enable_map_info_shiftclick, ini\map info.ini, Settings, enable shift-clicking, 0
IniRead, fSize_offset_map_info, ini\map info.ini, Settings, font-offset, 0
If fSize_offset_map_info is not number
	fSize_offset_map_info := 0
LLK_FontSize(fSize0 + fSize_offset_map_info, font_height_mapinfo, font_width_mapinfo)
IniRead, mapinfo_mods_database, data\Map mods.ini,,, % A_Space
Return

Map_info:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "enable_map_info")
{
	If (enable_map_info = 0)
	{
		Gui, mapinfo_panel: Destroy
		hwnd_mapinfo_panel := ""
		mapinfo_switched := 0
	}
	IniWrite, % enable_map_info, ini\config.ini, Features, enable map-info panel
	GoSub, Settings_menu
	Return
}

If InStr(A_GuiControl, "mapinfo_settings_color")
{
	cID := StrReplace(A_GuiControl, "mapinfo_settings_color")
	If (click = 1)
	{
		If (StrLen(Clipboard) = 6) || (SubStr(Clipboard, 1, 1) = "#" && StrLen(Clipboard) = 7)
		{
			hex := StrReplace(Clipboard, "#")
			GuiControl, settings_menu: +c%hex%, % A_GuiControl
			IniWrite, % hex, ini\map info.ini, UI, % !cID ? "header color" : "difficulty "cID " color"
			mapinfo_colors[cID] := hex
		}
		Else
		{
			LLK_ToolTip("invalid RGB-code in clipboard", 1.5)
			Return
		}
	}
	Else
	{
		If (mapinfo_colors[cID] = mapinfo_colors_default[cID])
			Return
		GuiControl, % "settings_menu: +c"mapinfo_colors_default[cID], % A_GuiControl
		IniWrite, % "", ini\map info.ini, UI, % !cID ? "header color" : "difficulty "cID " color"
		mapinfo_colors[cID] := mapinfo_colors_default[cID]
	}
	GuiControl, settings_menu: movedraw, % A_GuiControl
	
	If WinExist("ahk_id " hwnd_mapinfo_panel)
		LLK_MapInfo("refresh")
	Else
	{
		LLK_MapInfo("switch")
		mapinfo_switched := 1
	}
	Return
}

If (A_GuiControl = "enable_map_info_shiftclick")
{
	IniWrite, % enable_map_info_shiftclick, ini\map info.ini, Settings, enable shift-clicking
	Return
}

If (A_GuiControl = "fSize_map_info_minus")
{
	fSize_offset_map_info -= (fSize0 + fSize_offset_map_info > 8) ? 1 : 0
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_map_info_plus")
{
	fSize_offset_map_info += 1
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_map_info_reset")
{
	fSize_offset_map_info := 0
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "map_info_opac_minus")
{
	mapinfo_trans -= (mapinfo_trans > 100) ? 30 : 0
	IniWrite, %mapinfo_trans%, ini\map info.ini, Settings, transparency
}
If (A_GuiControl = "map_info_opac_plus")
{
	mapinfo_trans += (mapinfo_trans < 250) ? 30 : 0
	IniWrite, %mapinfo_trans%, ini\map info.ini, Settings, transparency
}
LLK_FontSize(fSize0 + fSize_offset_map_info, font_height_mapinfo, font_width_mapinfo)
LLK_MapInfo("refresh")
Return


LLK_MapInfo(mode := "")
{
	global
	local map_mods := [], map_mods_parsed := {}, speed, multiplier := 1, quantity := 0, rarity := 0, size := 0, map_mods_count := 0, outer, sample
	
	If InStr(clipboard, "`nUnidentified") || InStr(clipboard, "Rarity: Normal") || InStr(clipboard, "Rarity: Unique")
	{
		LLK_ToolTip("not supported:`nnormal, unique, un-ID")
		Return
	}
	
	If !InStr("refresh,switch", mode) || !mode
		mapinfo_metadata := SubStr(Clipboard, 1, InStr(Clipboard, "--------",,, 2) - 3), mapinfo_mods := SubStr(Clipboard, InStr(Clipboard, "--------",,, 3) + 10)
	
	If !mapinfo_metadata
	{
		IniRead, sample, data\map mods.ini, sample map,, % A_Space
		sample := StrReplace(sample, "(r)", "`r")
		If !sample
		{
			LLK_ToolTip("couldn't load sample map", 2)
			Return
		}
		mapinfo_metadata := SubStr(sample, 1, InStr(sample, "--------",,, 2) - 3), mapinfo_mods := SubStr(sample, InStr(sample, "--------",,, 3) + 10)
	}
	
	Loop, Parse, mapinfo_metadata, `n, `r
	{
		If InStr(A_LoopField, "rarity: ")
			rarity := SubStr(A_LoopField, InStr(A_LoopField, "+") + 1), rarity := SubStr(rarity, 1, InStr(rarity, "%") - 1)
		If InStr(A_LoopField, "quantity: ")
			quantity := SubStr(A_LoopField, InStr(A_LoopField, "+") + 1), quantity := SubStr(quantity, 1, InStr(quantity, "%") - 1)
		If InStr(A_LoopField, "pack size: ") || InStr(A_LoopField, "maximum alive reinforcements: ")
			size := SubStr(A_LoopField, InStr(A_LoopField, "+") + 1), size := SubStr(size, 1, InStr(size, "%") - 1)
	}
	
	StringLower, mapinfo_mods, mapinfo_mods
	mapinfo_switched := 0
	local missing_mods := ""
	Loop, Parse, mapinfo_mods, `r, `n ;parse map-mods affix by affix
	{
		If InStr(A_LoopField, "----") || !InStr(A_LoopField, "(enchant)") && !InStr(A_LoopField, "(implicit)") && !InStr(A_LoopField, "{")
			continue
		
		local affix0 := A_LoopField, modgroup_text := ""
		If InStr(A_LoopField, "{ prefix modifier ") || InStr(A_LoopField, "{ suffix modifier ")
			map_mods_count += 1
		
		Loop, Parse, A_LoopField, `n ;parse affixes line by line
		{
			If InStr("({", SubStr(A_LoopField, 1, 1)) ;|| InStr(A_LoopField, "(implicit)") || InStr(A_LoopField, "(enchant)")
				continue
			
			local affix_line := StrReplace(A_LoopField, " (implicit)"), affix_line := StrReplace(A_LoopField, " (enchant)")
			While InStr(affix_line, "(")
			{
				local affix_replace := SubStr(affix_line, InStr(affix_line, "(")), affix_replace := SubStr(affix_replace, 1, InStr(affix_replace, ")"))
				affix_line := StrReplace(affix_line, affix_replace)
			}
			affix_line := StrReplace(affix_line, " — unscalable value"), affix_line := InStr(affix_line, "per 25% alert level") ? StrReplace(affix_line, "per 25% alert level", "per alert level") : affix_line
			
			Loop, Parse, affix_line
			{
				If (A_Index = 1)
					local affix_line_text := "", affix_line_value := ""
				If LLK_IsAlpha(A_LoopField) || InStr(" ',", A_LoopField)
					affix_line_text .= A_LoopField
				If IsNumber(A_LoopField) || InStr(".", A_LoopField)
					affix_line_value .= A_LoopField
			}
			While (SubStr(affix_line_text, 1, 1) = " ")
				affix_line_text := SubStr(affix_line_text, 2)
			While (SubStr(affix_line_text, 0) = " ")
				affix_line_text := SubStr(affix_line_text, 1, -1)
			affix_line_text := StrReplace(affix_line_text, "  ", " ")
			
			If (affix_line_text = "increased explicit modifier magnitudes") ;implicit on atlas memories
			{
				multiplier += affix_line_value/100
				multiplier := Format("{:0.2f}", multiplier)
			}
			
			If !InStr(mapinfo_mods_database, "`n"affix_line_text) && !InStr(mapinfo_mods_database, affix_line_text "`n") && !InStr(mapinfo_mods_database, "|"affix_line_text) ;if mod is not a regular map-modifier (i.e. enchant or implicit exclusive to special map-types)
			{
				If enable_startup_beep
					missing_mods .= affix_line_text "`n"
				continue
			}
			
			If InStr(mapinfo_mods_database, affix_line_text "|") || InStr(mapinfo_mods_database, "|" affix_line_text)
				modgroup_text .= affix_line_text "|"
			Else map_mods.Push(affix_line_text)
			
			If map_mods_parsed.HasKey(affix_line_text)
				map_mods_parsed[affix_line_text] += InStr(affix0, "prefix") || InStr(affix0, "suffix") ? Floor(affix_line_value * multiplier) : affix_line_value
			Else map_mods_parsed[affix_line_text] := InStr(affix0, "prefix") || InStr(affix0, "suffix") ? (affix_line_value > 1) ? Floor(affix_line_value * multiplier) : Format("{:0.1f}", affix_line_value * multiplier) : affix_line_value
				
			If (map_mods_parsed[affix_line_text] = 0)
				map_mods_parsed[affix_line_text] := ""
		}
		modgroup_text := SubStr(modgroup_text, 1, -1)
		map_mods_parsed["monsters inflict withered for seconds on hit"] := ""
		
		If modgroup_text
			map_mods.Push(modgroup_text)
	}
	If missing_mods && enable_startup_beep && (mode != "switch")
		LLK_ToolTip(missing_mods, 2.5)
	
	local text, ini_text, mod_value, key, value, ID, type, map_mods_difficulties := [], map_mods_player := {}, map_mods_bosses := {}, map_mods_monsters := {}, map_mods_area := {}, map_mods_heist := {}, mod, show, rank, ranks := ["d", "c", "b", "a"]
	For key, value in map_mods
	{
		IniRead, ini_text, data\map mods.ini, % value, text, % A_Space
		text := "", mod_value := ""
		/*
		Loop, Parse, value, |
		{
			If InStr(value, "|")
				text .= (A_Index = 1) ? mod map_mods_parsed[A_LoopField] SubStr(ini_text, 1, InStr(ini_text, "|") - 1) : ", " mod map_mods_parsed[A_LoopField] SubStr(ini_text, InStr(ini_text, "|") + 1)
			Else text := mod map_mods_parsed[A_LoopField] ini_text
		}
		*/
		
		If InStr(value, "|")
		{
			Loop, Parse, value, |
			{
				mod_value .= map_mods_parsed[A_LoopField] "/"
				If InStr(A_LoopField, "damage as chaos")
					break
			}
			mod_value := SubStr(mod_value, 1, -1)
			text := StrReplace(ini_text, "%", mod_value "%")
			;text := StrReplace(ini_text, "%", map_mods_parsed[SubStr(value, 1, InStr(value, "|") - 1)] "/" map_mods_parsed[SubStr(value, InStr(value, "|") + 1)] "%")
		}
		Else text := InStr(ini_text, "%") ? StrReplace(ini_text, "%", map_mods_parsed[value] "%") : StrReplace(ini_text, "+", "+" map_mods_parsed[value])
		IniRead, ID, data\map mods.ini, % value, ID, % A_Space
		IniRead, type, data\map mods.ini, % value, type, % A_Space
		IniRead, show, ini\map info.ini, % ID, show, 1
		IniRead, rank, ini\map info.ini, % ID, rank, 1
		rank := ranks[rank]
		show := !show ? "z" rank " " : rank " "
		map_mods_%type%[show text] := ID
	}
	
	local style, style0, style_diff, hwnd, width, width1, wTarget := 0, outer, player, monsters, bosses, area, heist, cMod, gLabel := (mode = "switch") ? "" : " gLLK_MapInfoModRank", option := (mode = "switch") ? "+E0x20" : ""
	Loop 2
	{
		style := "Section xs y+0", style .= (mode = "switch") ? " right" : " center", outer := A_Index
		Gui, mapinfo_panel: New, -DPIScale %option% -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_mapinfo_panel
		Gui, mapinfo_panel: Margin, % font_width_mapinfo/2, 0
		Gui, mapinfo_panel: Color, Black
		If (mode = "switch")
			WinSet, Transparent, 255
		Gui, mapinfo_panel: Font, % "s"fSize0 + fSize_offset_map_info " cWhite", Fontin SmallCaps
		
		;Gui, mapinfo_panel: Margin, % font_width_mapinfo/2, 0
		If (A_Index = 2)
			style .= " w"wTarget
		
		Loop, Parse, % "player,monsters,bosses,area,heist", `,
		{
			For key, value in map_mods_%A_LoopField%
			{
				If (outer = 1 && A_Index = 1)
					%A_LoopField% := 0
				If (mode != "switch" && A_Index = 1) || (mode = "switch" && outer = 2 && %A_LoopField% > 0 && A_Index = 1)
				{
					Gui, mapinfo_panel: Font, underline
					Gui, mapinfo_panel: Add, Text, % style " BackgroundTrans c"mapinfo_colors[0] " HWNDhwnd", % A_LoopField ":"
					WinGetPos,,, width,, ahk_id %hwnd%
					wTarget := (width > wTarget) ? width : wTarget
					Gui, mapinfo_panel: Font, norm
					;style .= " xs"
				}
				IniRead, show, ini\map info.ini, % value, show, 1
				IniRead, rank, ini\map info.ini, % value, rank, 1
				If (outer = 1) && (show || rank > 2 && mode != "switch")
					map_mods_difficulties.Push((rank > 2 && !show) ? rank 0 : rank)
				%A_LoopField% += show
				cMod := mapinfo_colors[rank]
				;cMod := show ? cMod : "Gray"
				If (mode != "switch") || (mode = "switch" && show)
				{
					If !show
						Gui, mapinfo_panel: Font, strike
					Gui, mapinfo_panel: Add, Text, % style " BackgroundTrans c"cMod gLabel " vmapinfo_panelentry"value " HWNDhwnd", % SubStr(key, InStr(key, " ") + 1)
					Gui, mapinfo_panel: Font, norm
					WinGetPos,,, width,, ahk_id %hwnd%
					wTarget := (width > wTarget) ? width : wTarget
				}
			}
		}
		If (A_Index = 2)
			style0 := (mode = "switch") ? "right" : "center", style0 .= " w"wTarget
		Gui, mapinfo_panel: Add, Text, % style0 " Section BackgroundTrans HWNDhwnd", % map_mods_count "m | " quantity "q | " rarity "r | " size "p"
		WinGetPos,,, width,, ahk_id %hwnd%
		wTarget := (width > wTarget) ? width : wTarget
		If (A_Index = 1)
			width1 := width ;get the width of the text-box
		
		If map_mods_difficulties.Count()
		{
			map_mods_difficulties := LLK_SortArray(map_mods_difficulties, "R")
			While Mod(width1, map_mods_difficulties.Count())
				width1 += 1
		}
		
		Loop, % map_mods_difficulties.Count()
		{
			local background := InStr(map_mods_difficulties[A_Index], "0") ? "White" : "Black"
			If (mode != "switch")
				style_diff := (A_Index = 1) ? "y+0 xp+"font_width_mapinfo/4 + (wTarget - width1)/2 - 2 : "yp x+0"
			Else style_diff := (A_Index = 1) ? "y+0 x+-"(width1 // map_mods_difficulties.Count()) * map_mods_difficulties.Count() - 1 : "yp x+0"
			Gui, mapinfo_panel: Add, Progress, % style_diff " Background"background " Disabled c"mapinfo_colors[StrReplace(map_mods_difficulties[A_Index], "0")] " h"font_height_mapinfo/3 " w"width1 // map_mods_difficulties.Count(), 100
		}
	}
	
	Gui, mapinfo_panel: Margin, % font_width_mapinfo/2, % font_height_mapinfo/4
	
	
	local xPos, yPos, height, xPosTarget, yPosTarget
	Gui, mapinfo_panel: Show, NA x10000 y10000
	WinGetPos,,, mapinfo_width, height, ahk_id %hwnd_mapinfo_panel%
	MouseGetPos, xPos, yPos
	
	xPosTarget := (xPos - mapinfo_width/2 < xScreenOffset) ? xScreenOffset : xPos - mapinfo_width/2
	yPosTarget := (yPos - height - poe_height*(5/240) < yScreenOffSet) ? yScreenOffSet : yPos - height - poe_height*(5/240)
	
	If (mode != "switch")
	{
		Gui, mapinfo_panel: Show, NA x%xPosTarget% y%yPosTarget%
		LLK_Overlay("mapinfo_panel", "show")
	}
	Else
	{
		Gui, mapinfo_panel: Show, % "Hide x"xScreenOffset + poe_width - mapinfo_width " yCenter"
		LLK_Overlay("mapinfo_panel", "hide")
	}
}

LLK_MapInfoClose()
{
	global
	Gui, mapinfo_panel: Destroy
	hwnd_mapinfo_panel := ""
	LLK_MapInfo("switch")
	mapinfo_switched := 1
}

LLK_MapInfoModRank()
{
	global
	local hwnd, ID := StrReplace(A_GuiControl, "mapinfo_panelentry"), show, cMod, rank
	IniRead, show, ini\map info.ini, % ID, show, 1
	IniRead, rank, ini\map info.ini, % ID, rank, 1
	
	If (click = 1)
	{
		/*
		If !show
		{
			LLK_ToolTip("unhide mod first")
			Return
		}
		*/
		mapinfo_control_selected := ID
		KeyWait, LButton
		mapinfo_control_selected := ""
		If mapinfo_control_selected_rank
			IniWrite, % mapinfo_control_selected_rank, ini\map info.ini, % ID, rank
		mapinfo_control_selected_rank := ""
		WinActivate, ahk_group poe_window
		Return
	}
	Else If (click = 2)
	{
		show := !show
		IniWrite, % show, ini\map info.ini, % ID, show
		cMod := mapinfo_colors[rank] ;,cMod := show ? cMod : "Gray"
		;GuiControl, mapinfo_panel: +c%cMod%, % A_GuiControl
		If !show
			Gui, mapinfo_panel: Font, strike
		Else Gui, mapinfo_panel: Font, norm
		GuiControl, mapinfo_panel: font, % A_GuiControl
		GuiControl, mapinfo_panel: +c%cMod%, % A_GuiControl
		Gui, mapinfo_panel: Font, norm
		GuiControl, mapinfo_panel: movedraw, % A_GuiControl
		WinActivate, ahk_group poe_window
		Return
	}
}