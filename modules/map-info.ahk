Map_info:
If (A_GuiControl = "enable_map_info")
{
	Gui, settings_menu: Submit, NoHide
	If (enable_map_info = 0)
	{
		Gui, map_mods_window: Destroy
		hwnd_map_mods_window := ""
		Gui, map_mods_toggle: Destroy
		hwnd_map_mods_toggle := ""
	}
	IniWrite, % enable_map_info, ini\config.ini, Features, enable map-info panel
	GoSub, Settings_menu
	Return
}

If InStr(Clipboard, "item class: maps") && (InStr(clipboard, "Unidentified") || InStr(clipboard, "Rarity: Normal") || InStr(clipboard, "Rarity: Unique"))
{
	LLK_ToolTip("not supported:`nnormal, unique, un-ID")
	Return
}

If (A_Gui = "")
{
	map_mods_clipped := Clipboard
	map_mods_sample := 0
}
monsters := ""
player := ""
bosses := ""
area := ""
map_mods_panel_player := ""
map_mods_panel_monsters := ""
map_mods_panel_bosses := ""
map_mods_panel_area := ""
map_mods_mod_count := 0
If (map_mods_clipped = "")
{
	IniRead, parseboard, data\Map mods.ini, sample map
	parseboard := SubStr(parseboard, InStr(parseboard, "Item Level:"))
	map_mods_sample := 1
}
Else parseboard := SubStr(map_mods_clipped, InStr(map_mods_clipped, "Item Level:"))
IniRead, map_mods_list, data\Map mods.ini

Loop, Parse, parseboard, `n, `n
{
	If InStr(A_Loopfield, "{")
	{
		If InStr(A_Loopfield, "prefix" || "suffix")
			map_mods_mod_count += 1
		continue
	}
	If (A_LoopField = "") || (SubStr(A_Loopfield, 1, 1) = "(") || InStr(A_Loopfield, "delirium reward type")
		continue
	check := InStr(A_Loopfield, "(") ? SubStr(A_LoopField, 1, InStr(A_Loopfield, "(",,, 1) - 1) SubStr(A_Loopfield, InStr(A_Loopfield, ")") + 1) : A_Loopfield
	check_characters := "-0123456789%"
	map_mod_pretext := ""
	Loop, Parse, check
	{
		If InStr(check_characters, A_LoopField)
			map_mod_pretext := (map_mod_pretext = "") ? A_LoopField : map_mod_pretext A_LoopField
	}
	While (SubStr(map_mod_pretext, 0) = "-")
		map_mod_pretext := SubStr(map_mod_pretext, 1, -1)
	Loop, Parse, map_mods_list, `n, `r`n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		If InStr(check, A_LoopField)
		{
			loopfield_copy := A_LoopField
			IniRead, map_mod_type, data\Map mods.ini, %A_LoopField%, type
			IniRead, map_mod_modifier, data\Map mods.ini, %A_LoopField%, mod
			If (A_LoopField = "increased area") && InStr(check, "monster")
				map_mod_type := "monsters"
			Else If (A_LoopField = "increased area") && InStr(check, "boss")
			{
				map_mod_type := "bosses"
				loopfield_copy := "increased area of"
			}
			IniRead, map_mod_ID, data\Map mods.ini, %loopfield_copy%, ID
			If (map_info_short = 1)
				IniRead, map_mod_text, data\Map mods.ini, %loopfield_copy%, text
			Else IniRead, map_mod_text, data\Map mods.ini, %loopfield_copy%, text1
			IniRead, map_mod_mod, data\Map mods.ini, %loopfield_copy%, mod
			If (map_mod_type = "player")
				map_mods_panel_player := (map_mods_panel_player = "") ? map_mod_text : map_mods_panel_player "`n" map_mod_text
			Else If (map_mod_type = "monsters")
			{
				If (map_mod_text = "more life") && InStr(map_mods_panel_monsters, map_mod_text)
				{
					map_mod_pretext := SubStr(map_mod_pretext, 1, 2)
					more_life := SubStr(monsters, InStr(monsters, "," map_mod_ID) - 3, 2)
					monsters := StrReplace(monsters, more_life "%," map_mod_ID map_mod_text, map_mod_pretext + more_life "%," map_mod_ID map_mod_text)
					break
				}
				map_mods_panel_monsters := (map_mods_panel_monsters = "") ? map_mod_text : map_mods_panel_monsters "`n" map_mod_text
			}
			Else If (map_mod_type = "bosses")
				map_mods_panel_bosses := (map_mods_panel_bosses = "") ? map_mod_text : map_mods_panel_bosses "`n" map_mod_text
			Else If (map_mod_type = "area")
				map_mods_panel_area := (map_mods_panel_area = "") ? map_mod_text : map_mods_panel_area "`n" map_mod_text
			
			map_mod_pretext := (map_mod_mod = "?") ? "" : map_mod_pretext
			map_mod_text := (map_mod_pretext != "") ? map_mod_pretext "," map_mod_ID map_mod_text : "," map_mod_ID map_mod_text
			If (map_mod_modifier = "+")
				map_mod_text := "+" map_mod_text
			If (map_mod_modifier = "-")
				map_mod_text := "-" map_mod_text
			IniRead, map_mod_rank, ini\map info.ini, %map_mod_ID%, rank
			If (map_mod_type = "player") && (map_mod_rank > 0)
				player := (player = "") ? map_mod_text : player "`n" map_mod_text
			Else If (map_mod_type = "monsters") && (map_mod_rank > 0)
				monsters := (monsters = "") ? map_mod_text : monsters "`n" map_mod_text
			Else If (map_mod_type = "bosses") && (map_mod_rank > 0)
				bosses := (bosses = "") ? map_mod_text : bosses "`n" map_mod_text
			Else If (map_mod_type = "area") && (map_mod_rank > 0)
				area := (area = "") ? map_mod_text : area "`n" map_mod_text
			break
		}
	}
}
map_mods_panel_text := map_mods_panel_player "`n" map_mods_panel_monsters "`n" map_mods_panel_bosses "`n" map_mods_panel_area
width := ""
Loop 2
{
	map_info_difficulty := 0
	map_info_mod_count := 0
	Gui, map_mods_window: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_mods_window
	If (A_Index = 1)
		Gui, map_mods_window: Margin, 0, 0
	Else Gui, map_mods_window: Margin, 8, 2
	Gui, map_mods_window: Color, Black
	WinSet, Transparent, %map_info_trans%
	style_map_mods := (width = "") ? "" : " w"width
	Gui, map_mods_window: Font, % "s"fSize0 + fSize_offset_map_info " cAqua underline", Fontin SmallCaps
	If (player != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans %map_info_side% %style_map_mods%, player:
		Gui, map_mods_window: Font, norm
		Loop, Parse, player, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "?", "`n")
			window_text := StrReplace(window_text, "$")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (monsters != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, monsters:
		Gui, map_mods_window: Font, norm
		Loop, Parse, monsters, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "?", "`n")
			window_text := StrReplace(window_text, "$")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (bosses != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, boss:
		Gui, map_mods_window: Font, norm
		Loop, Parse, bosses, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "0f", "of")
			window_text := StrReplace(window_text, "a0e", "aoe")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (area != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, area:
		Gui, map_mods_window: Font, norm
		Loop, Parse, area, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (A_Index = 1)
	{
		Gui, map_mods_window: Show, NA x10000 y10000
		WinGetPos,,, width,, ahk_id %hwnd_map_mods_window%
	}
	Else
	{
		Gui, map_mods_toggle: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_mods_toggle
		Gui, map_mods_toggle: Margin, 8, 0
		Gui, map_mods_toggle: Color, Black
		WinSet, Transparent, %map_info_trans%
		Gui, map_mods_toggle: Font, % "s"fSize0 + fSize_offset_map_info " cWhite", Fontin SmallCaps
		Gui, map_mods_toggle: Add, Text, BackgroundTrans %style_map_mods% Center gMap_mods_toggle, % map_mods_mod_count " @ " Format("{:0.1f}", map_info_difficulty/map_info_mod_count)
		Gui, map_mods_toggle: Show, NA x10000 y10000
		WinGetPos,,, width, height ;, ahk_id %hwnd_map_mods_toggle%
		map_info_xPos_target := (map_info_xPos > poe_width) ? poe_width : map_info_xPos
		map_info_xPos_target := (map_info_xPos_target >= poe_width/2) ? map_info_xPos_target - width : map_info_xPos_target
		map_info_yPos_target := (map_info_yPos + height > poe_height) ? poe_height - height : map_info_yPos
		If (map_info_xPos >= poe_width - pixel_gamescreen_x1 - 1) && (map_info_yPos_target <= pixel_gamescreen_y1 + 1)
			map_info_yPos_target := pixel_gamescreen_y1 + 1
		Gui, map_mods_window: Show, NA
		WinGetPos,,, width_window, height_window, ahk_id %hwnd_map_mods_window%
		map_info_yPos_target1 := (map_info_yPos > poe_height/2) ? map_info_yPos_target - height_window + 1 : map_info_yPos_target + height - 1
		Gui, map_mods_window: Show, % "NA x"xScreenOffset + map_info_xPos_target " y"yScreenOffset + map_info_yPos_target1
		Gui, map_mods_toggle: Show, % "Hide x"xScreenOffset + map_info_xPos_target " y"yScreenOffset + map_info_yPos_target
		LLK_Overlay("map_mods_toggle", "show")		
		LLK_Overlay("map_mods_window", "show")
		If WinExist("ahk_id " hwnd_map_info_menu) && !WinExist("ahk_id " hwnd_settings_menu)
		{
			WinGetPos,,, edit_width, edit_height, ahk_id %hwnd_map_info_menu%
			edit_xPos := (map_info_xPos_target >= poe_width/2) ? map_info_xPos_target - edit_width + 1 : map_info_xPos_target + width_window - 1
			edit_yPos := (map_info_yPos_target1 + edit_height >= poe_height) ? poe_height - edit_height : map_info_yPos_target1
			WinMove, ahk_id %hwnd_map_info_menu%,, % xScreenOffset + edit_xPos, % yScreenoffset +  edit_yPos
		}
		toggle_map_mods_panel := 1
		map_mods_panel_fresh := 1
	}
	If ((player != "") || (monsters != "") || (bosses != "") || (area != "")) && (A_Gui = "")
		LLK_ToolTip("success", 0.5)
	Else If (player = "") && (monsters = "") && (bosses = "") && (area = "") && (map_info_search = "")
	{
		LLK_ToolTip("no mods", 0.5)
		Gui, map_mods_window: Destroy
		Gui, map_mods_toggle: Destroy
		hwnd_map_mods_toggle := ""
		hwnd_map_mods_window := ""
		map_mods_panel_fresh := 0
		break
	}
}
Return

Map_info_customization:
GuiControl_copy := A_GuiControl
Gui, map_info_menu: destroy
Gui, map_info_menu: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_info_menu, Lailloken UI: map mod customization
Gui, map_info_menu: Color, Black
Gui, map_info_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, map_info_menu: Font, % "cWhite s"fSize0, Fontin SmallCaps

If (GuiControl_copy = "Map_info_search")
{
	map_info_hits := ""
	section := 0
	Gui, settings_menu: Submit, NoHide
	If (StrLen(map_info_search) < 3)
		Return
	IniRead, map_mods_search_db, data\Map search.ini
	Loop, Parse, map_mods_search_db, `n, `n
	{
		If InStr(A_LoopField, map_info_search)
		{
			IniRead, map_info_ID, data\Map search.ini, %A_LoopField%, ID
			IniRead, map_mod_%map_info_ID%_rank, ini\map info.ini, %map_info_ID%, rank, 1
			IniRead, map_mod_%map_info_ID%_type, ini\map info.ini, %map_info_ID%, type
			map_mod_text := A_Loopfield
			If (section = 0)
			{
				Gui, map_info_menu: Add, Text, Section BackgroundTrans, set mod difficulty (0-4):
				Gui, map_info_menu: Add, Picture, ys BackgroundTrans vMap_info gSettings_menu_help hp w-1, img\GUI\help.png
				section := 1
			}
			Gui, map_info_menu: Font, % "s"fSize0 - 4
			Gui, map_info_menu: Add, Edit, xs hp Section BackgroundTrans center vMap_mod_edit_%map_info_ID% gMap_mods_save number limit1 cBlack, % map_mod_%map_info_ID%_rank
			Gui, map_info_menu: Font, % "s"fSize0
			Gui, map_info_menu: Add, Text, ys BackgroundTrans, % map_mod_text
		}
	}
	If (section != 0)
	{
		WinGetPos, winXpos, winYpos, winwidth, winheight, ahk_id %hwnd_settings_menu%
		Gui, map_info_menu: Show, % "NA x"winXpos " y"winYpos + winheight
	}
	Return
}

IniRead, map_info_parse, data\Map mods.ini
map_info_parse := StrReplace(map_info_parse, "-")
loop := ""
IDs_hit := ""
Loop, Parse, map_mods_panel_text, `n, `n
{
	If (A_LoopField = "")
		continue
	loop += 1
	check := A_LoopField
	Loop, Parse, map_info_parse, `n, `n
	{
		If (map_info_short = 1)
			IniRead, map_info_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, map_info_text, data\Map mods.ini, %A_LoopField%, text1
		If (map_info_text = check)
		{
			IniRead, map_info_ID, data\Map mods.ini, %A_LoopField%, ID
			break
		}
	}
	IniRead, map_mod_%map_info_ID%_rank, ini\map info.ini, %map_info_ID%, rank, 1
	IniRead, map_mod_%map_info_ID%_type, ini\map info.ini, %map_info_ID%, type
	If (loop = 1)
	{
		Gui, map_info_menu: Add, Text, Section BackgroundTrans, set mod difficulty (0-4):
		Gui, map_info_menu: Add, Picture, ys BackgroundTrans vMap_info gSettings_menu_help hp w-1, img\GUI\help.png
	}
	Gui, map_info_menu: Font, % "s"fSize0 - 4
	Gui, map_info_menu: Add, Edit, xs hp Section BackgroundTrans center vMap_mod_edit_%map_info_ID% gMap_mods_save number limit1 cBlack, % map_mod_%map_info_ID%_rank
	Gui, map_info_menu: Font, % "s"fSize0
	map_info_cfg_text := StrReplace(A_LoopField, "-?")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "?", " ")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "0f", "of")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "a0e", "aoe")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "$")
	Gui, map_info_menu: Add, Text, ys BackgroundTrans, % map_info_cfg_text " (" map_mod_%map_info_ID%_type ")"
}
Gui, map_info_menu: Show, Hide
WinGetPos, winx, winy, winw,, ahk_id %hwnd_map_mods_window%
WinGetPos,,, widthedit, height,
If (map_info_side = "right")
	Gui, map_info_menu: Show, % "x"winx - widthedit + 1 " y"winy
Else Gui, map_info_menu: Show, % "x"winx + winw - 1 " y"winy
If (winy + height > yScreenOffSet + poe_height)
	WinMove, ahk_id %hwnd_map_info_menu%,,, % yScreenOffSet + poe_height - height
Return

Map_info_settings_apply:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "enable_map_info_shiftclick")
{
	IniWrite, % enable_map_info_shiftclick, ini\map info.ini, Settings, enable shift-clicking
	Return
}
If (A_GuiControl = "map_info_short")
{
	IniWrite, % map_info_short, ini\map info.ini, Settings, short descriptions
	IniRead, map_info_parse, data\Map mods.ini
	Loop, Parse, map_info_parse, `n, `n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		IniRead, parse_ID, data\Map mods.ini, %A_LoopField%, ID
		If (map_info_short = 1)
			IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text1
		IniWrite, %parse_text%, ini\map info.ini, %parse_ID%, text
	}
	GoSub, Map_info
	Return
}
If (A_GuiControl = "Map_info_pixelcheck_enable")
{
	If (pixel_gamescreen_color1 = "") || (pixel_gamescreen_color1 = "ERROR")
	{
		LLK_ToolTip("pixel-check setup required")
		map_info_pixelcheck_enable := 0
		GuiControl, settings_menu: , Map_info_pixelcheck_enable, 0
		Return
	}
	IniWrite, %map_info_pixelcheck_enable%, ini\map info.ini, Settings, enable pixel-check
	LLK_GameScreenCheck()
	Return
}
If (A_GuiControl = "fSize_map_info_minus")
{
	fSize_offset_map_info -= 1
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
	map_info_trans -= (map_info_trans > 100) ? 30 : 0
	IniWrite, %map_info_trans%, ini\map info.ini, Settings, transparency
}
If (A_GuiControl = "map_info_opac_plus")
{
	map_info_trans += (map_info_trans < 250) ? 30 : 0
	IniWrite, %map_info_trans%, ini\map info.ini, Settings, transparency
}
GoSub, Map_info
Return

Map_mods_save:
Gui, map_info_menu: Submit, NoHide
SendInput, ^{a}
map_mod_ID := StrReplace(A_GuiControl, "map_mod_edit_")
map_mod_difficulty := %A_GuiControl%
map_mod_difficulty := (map_mod_difficulty = "") ? 0 : map_mod_difficulty
map_mod_difficulty := (map_mod_difficulty > 4) ? 4 : map_mod_difficulty
IniWrite, %map_mod_difficulty%, ini\map info.ini, %map_mod_ID%, rank
GoSub, Map_info
Return

Map_mods_toggle:
start := A_TickCount
While GetKeyState("LButton", "P")
{
	If (A_TickCount >= start + 300)
	{
		If WinExist("ahk_id " hwnd_map_info_menu)
		{
			Gui, map_info_menu: Destroy
			hwnd_map_info_menu := ""
		}
		If !WinExist("ahk_id " hwnd_map_mods_window)
			LLK_Overlay("map_mods_window", "show")
		WinGetPos,,, wGui, hGui, ahk_id %hwnd_map_mods_toggle%
		WinGetPos,,,, hGui2, ahk_id %hwnd_map_mods_window%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		map_info_xPos := (panelXpos >= poe_width/2) ? panelXpos + wGui : panelXpos
		map_info_yPos := panelYpos
		map_info_side := (map_info_xPos > poe_width//2) ? "right" : "left"
		IniWrite, % map_info_xPos, ini\map info.ini, Settings, x-coordinate
		IniWrite, % map_info_yPos, ini\map info.ini, Settings, y-coordinate
		GoSub, map_info
		WinActivate, ahk_group poe_window
		Return
	}
}
If (click = 2)
{
	LLK_Overlay("map_mods_window", "show")
	GoSub, Map_info_customization
	Return
}
If WinExist("ahk_id " hwnd_map_info_menu)
{
	Gui, map_info_menu: Destroy
	hwnd_map_info_menu := ""
}
If WinExist("ahk_id " hwnd_map_mods_window)
{
	LLK_Overlay("map_mods_window", "hide")
	toggle_map_mods_panel := 0
}
Else
{
	LLK_Overlay("map_mods_window", "Show")
	toggle_map_mods_panel := 1
}
WinActivate, ahk_group poe_window
Return

Init_maps:
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

IniRead, map_info_pixelcheck_enable, ini\map info.ini, Settings, enable pixel-check, 1
IniRead, enable_map_info_shiftclick, ini\map info.ini, Settings, enable shift-clicking, 0
If (map_info_pixelcheck_enable = 1)
	pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
IniRead, fSize_offset_map_info, ini\map info.ini, Settings, font-offset, 0
IniRead, map_info_trans, ini\map info.ini, Settings, transparency, 220
If fSize_offset_map_info is not number
	fSize_offset_map_info := 0
IniRead, map_info_short, ini\map info.ini, Settings, short descriptions, 1
IniRead, map_info_xPos, ini\map info.ini, Settings, x-coordinate, 0
map_info_side := (map_info_xPos >= poe_width//2) ? "right" : "left"
IniRead, map_info_yPos, ini\map info.ini, Settings, y-coordinate, 0
IniRead, map_mod_ini_version_data, data\Map mods.ini, Version, version, 1
IniRead, map_mod_ini_version_user, ini\map info.ini, Version, version, 0
If !FileExist("ini\map info.ini") || (map_mod_ini_version_data > map_mod_ini_version_user)
{
	map_info_exists := FileExist("ini\map info.ini") ? 1 : 0
	IniWrite, %map_mod_ini_version_data%, ini\map info.ini, Version, version
	If (map_info_exists = 0)
	{
		IniWrite, 0, ini\map info.ini, Settings, enable pixel-check
		IniWrite, 0, ini\map info.ini, Settings, font-offset
		IniWrite, 220, ini\map info.ini, Settings, transparency
	}
	IniRead, map_info_parse, data\Map mods.ini
	Loop, Parse, map_info_parse, `n, `n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		IniRead, parse_ID, data\Map mods.ini, %A_LoopField%, ID
		If (map_info_short = 1)
			IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text1
		IniRead, parse_type, data\Map mods.ini, %A_LoopField%, type
		IniRead, parse_rank, ini\map info.ini, %parse_ID%, rank
		IniWrite, %parse_text%, ini\map info.ini, %parse_ID%, text
		IniWrite, %parse_type%, ini\map info.ini, %parse_ID%, type
		If (map_info_exists = 0) || (parse_rank = "") || (parse_rank = "ERROR")
			IniWrite, 1, ini\map info.ini, %parse_ID%, rank
	}
}
Return