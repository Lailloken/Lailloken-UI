Init_map_tracker:
IniRead, enable_loottracker, ini\map tracker.ini, Settings, enable loot tracker, 0
IniRead, enable_killtracker, ini\map tracker.ini, Settings, enable kill tracker, 0
IniRead, xpos_offset_map_tracker, ini\map tracker.ini, UI, map tracker x-offset, 0
IniRead, ypos_offset_map_tracker, ini\map tracker.ini, UI, map tracker y-offset, 0
IniRead, fSize_offset_map_tracker, ini\map tracker.ini, Settings, font-offset, 0
IniRead, map_tracker_panel_offset, ini\map tracker.ini, Settings, button-offset, 1
map_tracker_panel_dimensions := poe_width*0.03*map_tracker_panel_offset
IniRead, map_tracker_panel_xpos, ini\map tracker.ini, UI, button xcoord, % A_Space
If !map_tracker_panel_xpos
	map_tracker_panel_xpos := poe_width/2 - (map_tracker_panel_dimensions + 2)/2
IniRead, map_tracker_panel_ypos, ini\map tracker.ini, UI, button ycoord, % A_Space
If !map_tracker_panel_ypos
	map_tracker_panel_ypos := poe_height - (map_tracker_panel_dimensions + 2)
IniRead, map_tracker_enable_side_areas, ini\map tracker.ini, Settings, track side-areas, 0
Return

Map_tracker:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "map_tracker_panel") ;dragging the tracker-button
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		map_tracker_panel_xpos := panelXpos
		map_tracker_panel_ypos := panelYpos
		IniWrite, % map_tracker_panel_xpos, ini\map tracker.ini, UI, button xcoord
		IniWrite, % map_tracker_panel_ypos, ini\map tracker.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}

If (A_Gui = "map_tracker_panel") ;clicking the tracker-button
{
	If (click = 1)
		LLK_MapTrackGUI()
	Else
	{
		map_tracker_paused := !map_tracker_paused ? 1 : 0
		LLK_Overlay("map_tracker")
		If map_tracker_paused
		{
			GuiControl, map_tracker_panel:, map_tracker_panel_img, img\GUI\map_tracker_disabled.jpg
			If WinExist("ahk_id " hwnd_map_tracker_log)
				LLK_MapTrackGUI()
		}
		Else GuiControl, map_tracker_panel:, map_tracker_panel_img, img\GUI\map_tracker.jpg
	}
	WinActivate, ahk_group poe_window
	Return
}

If (A_GuiControl = "xpos_offset_map_tracker") ;adjusting x-coord offset
{
	If (A_TickCount < map_tracker_clicked + 1000) ;workaround for stupid UpDown behavior
		Return
	Gui, settings_menu: Submit, NoHide
	If IsNumber(xpos_offset_map_tracker)
	{
		LLK_MapTrack()
		IniWrite, % xpos_offset_map_tracker, ini\map tracker.ini, UI, map tracker x-offset
	}
	Return
}

If (A_GuiControl = "ypos_offset_map_tracker") ;adjusting y-coord offset
{
	If (A_TickCount < map_tracker_clicked + 1000) ;workaround for stupid UpDown behavior
		Return
	Gui, settings_menu: Submit, NoHide
	If IsNumber(ypos_offset_map_tracker)
	{
		LLK_MapTrack()
		IniWrite, % ypos_offset_map_tracker, ini\map tracker.ini, UI, map tracker y-offset
	}
	Return
}

If InStr(A_GuiControl, "button_map_tracker") ;adjusting tracker-button size
{
	If InStr(A_GuiControl, "minus")
		map_tracker_panel_offset -= (map_tracker_panel_offset > 0.4) ? 0.1 : 0
	If InStr(A_GuiControl, "reset")
		map_tracker_panel_offset := 1
	If InStr(A_GuiControl, "plus")
		map_tracker_panel_offset += (map_tracker_panel_offset < 1) ? 0.1 : 0
	map_tracker_panel_dimensions := poe_width*0.03*map_tracker_panel_offset
	IniWrite, % map_tracker_panel_offset, ini\map tracker.ini, Settings, button-offset
	GoSub, GUI
}

If InStr(A_GuiControl, "map_tracker_log_entry") ;clicking a log-entry in the log-viewer
{
	GuiControlCopy_map_tracker := StrReplace(A_GuiControl, "map_tracker_log_entry")
	If (click = 1)
		LLK_MapTrackLoot(GuiControlCopy_map_tracker)
	Else
	{
		If LLK_ProgressBar("map_tracker_log", "map_tracker_log_delete_entry"GuiControlCopy_map_tracker)
		{
			IniDelete, ini\map tracker log.ini, % map_tracker_log_ini%GuiControlCopy_map_tracker%
			LLK_MapTrackGUI("refresh")
		}
	}
	Return
}

If InStr(A_GuiControl, "fSize") ;adjusting mapping tracker font-size
{
	If InStr(A_GuiControl, "minus")
		fSize_offset_map_tracker -= (fSize0 + fSize_offset_map_tracker > 8) ? 1 : 0
	If InStr(A_GuiControl, "reset")
		fSize_offset_map_tracker := 0
	If InStr(A_GuiControl, "plus")
		fSize_offset_map_tracker += 1
	IniWrite, % fSize_offset_map_tracker, ini\map tracker.ini, Settings, font-offset
	LLK_MapTrack()
	If WinExist("ahk_id " hwnd_map_tracker_log)
		LLK_MapTrackGUI("refresh")
}

If (A_GuiControl = "settings_enable_maptracker") ;toggling mapping tracker feature on/off
{
	Gui, settings_menu: Submit, NoHide
	
	If !settings_enable_maptracker
	{
		Gui, loottracker: Destroy
		hwnd_loottracker := ""
		Gui, map_tracker_panel: Destroy
		hwnd_map_tracker_panel := ""
		map_tracker_paused := 0
		Gui, map_tracker_log: Destroy
		hwnd_map_tracker_log := ""
		map_tracker_log_selected_date := ""
		;LLK_MapTrackGUI()
	}
	IniWrite, %settings_enable_maptracker%, ini\config.ini, Features, enable map tracker
	GoSub, GUI
	GoSub, Settings_menu
	Return
}

If (A_GuiControl = "enable_loottracker") ;toggling loot tracker feature on/off
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, %enable_loottracker%, ini\map tracker.ini, Settings, enable loot tracker
	LLK_ScreenChecksValid()
	Return
}

If (A_GuiControl = "enable_killtracker") ;toggling kill tracker feature on/off
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, %enable_killtracker%, ini\map tracker.ini, Settings, enable kill tracker
	Return
}

If (A_GuiControl = "map_tracker_enable_side_areas") ;toggling side-area tracking on/off
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, %map_tracker_enable_side_areas%, ini\map tracker.ini, Settings, track side-areas
	Return
}

If (A_GuiControl = "map_tracker_button_complete") ;manually marking the current map as completed
{
	If (map_tracker_map = "")
	{
		LLK_ToolTip("not tracking, cannot save", 1.5)
		KeyWait, LButton
		WinActivate, ahk_group poe_window
		Return
	}
	If LLK_ProgressBar("map_tracker", "map_tracker_button_complete_bar")
	{
		LLK_MapTrackSave()
		LLK_MapTrack()
		KeyWait, LButton
		LLK_ToolTip("map logged")
	}
	Return
}

If (A_GuiControl = "map_tracker_log_ddl") ;selecting an entry from the log-viewer's drop-down-list
{
	Gui, map_tracker_log: Submit, NoHide
	GuiControlGet, map_tracker_log_selected_date,, map_tracker_log_ddl
	LLK_MapTrackGUI("refresh")
	Return
}

If (A_GuiControl = "map_tracker_log_delete_day") ;long-clicking the delete button
{
	If LLK_ProgressBar("map_tracker_log", "map_tracker_log_delete_bar")
	{
		Gui, map_tracker_log: Submit, NoHide
		GuiControlGet, log_selected,, map_tracker_log_ddl
		If (log_selected != "")
		{
			IniRead, map_tracker_logs, ini\map tracker log.ini
			Loop, Parse, map_tracker_logs, `n
			{
				If InStr(A_LoopField, log_selected)
					IniDelete, ini\map tracker log.ini, % A_LoopField
			}
		}
		LLK_MapTrackGUI("refresh")
	}
	Return
}

If InStr(A_GuiControl, "map_tracker_log_export") ;clicking the export buttons
{
	If (A_GuiControl = "map_tracker_log_export_day")
		LLK_MapTrackExport(map_tracker_log_selected_date)
	Else LLK_MapTrackExport()
}

If InStr(A_GuiControl, "loottracker_item") ;clicking an item on the loot-list to remove it
{
	GuiControlGet, loottracker_clicked,, % A_GuiControl, text
	
	Loop, Parse, loottracker_loot, `,, %A_Space%
		loottracker_parse := (A_Index = 1) ? A_LoopField : A_LoopField ", " loottracker_parse
	
	If (loottracker_clicked = loottracker_parse)
	{
		loottracker_parse := ""
		loottracker_loot := ""
	}
	Else loottracker_parse := StrReplace(loottracker_parse, loottracker_clicked,,, 1)
	
	Loop, Parse, loottracker_parse, `,, %A_Space%
	{
		If (A_Index = 1)
			loottracker_loot := ""
		If (A_LoopField = "")
			continue
		loottracker_loot := (loottracker_loot = "") ? A_LoopField : A_LoopField "," loottracker_loot
	}
	LLK_MapTrack("refresh")
}
Return

LLK_MapTrack(mode := "")
{
	global
	If (mode = "add")
	{
		Clipboard := ""
		SendInput, % GetKeyState("LShift", "P") ? "{LControl Down}{c}{LShift Down}{LButton}{LControl Up}{LShift Up}" : "{LControl Down}{c}{LButton}{LControl Up}"
		ClipWait, 0.05
		If (Clipboard = "")
			Return
		loottracker_stack_size := ""
		loottracker_item_name := ""
		If !InStr(Clipboard, "Contract: ", 1) && !InStr(Clipboard, "Blueprint: ", 1)
		{
			Loop, Parse, Clipboard, `n, `r
			{
				If (A_Index = 3)
					loottracker_item_name := StrReplace(A_LoopField, "superior ")
				If InStr(A_LoopField, "stack size:")
					loottracker_stack_size := SubStr(A_LoopField, InStr(A_LoopField, "stack size: ") + 12, InStr(A_LoopField, "/") - 13), loottracker_stack_size := StrReplace(loottracker_stack_size, "."), loottracker_stack_size := StrReplace(loottracker_stack_size, ",")
			}
		}
		Else If InStr(Clipboard, "Contract: ", 1) || InStr(Clipboard, "Blueprint: ", 1)
		{
			Loop, Parse, Clipboard, `n, `r
			{
				If InStr(A_LoopField, "Contract: ", 1)
					loottracker_item_name := SubStr(A_LoopField, InStr(A_LoopField, "Contract: ", 1))
				Else If InStr(A_LoopField, "Blueprint: ", 1)
					loottracker_item_name := SubStr(A_LoopField, InStr(A_LoopField, "Blueprint: ", 1))
				If InStr(loottracker_item_name, " of ")
					loottracker_item_name := SubStr(loottracker_item_name, 1, InStr(loottracker_item_name, " of ") - 1)
			}
		}
		StringLower, loottracker_item_name, loottracker_item_name
		loottracker_stack_size := (loottracker_stack_size = "") ? "" : " (" loottracker_stack_size ")"
		loottracker_loot .= (loottracker_loot = "") ? loottracker_item_name loottracker_stack_size : "," loottracker_item_name loottracker_stack_size
	}
	
	Gui, map_tracker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_tracker
	Gui, map_tracker: Margin, % fSize0//2, 0
	Gui, map_tracker: Color, Black
	WinSet, Trans, %trans%
	Gui, map_tracker: Font, % "cWhite s"fSize0 + fSize_offset_map_tracker, Fontin SmallCaps
	
	Gui, map_tracker: Add, Text, % "xs Section BackgroundTrans vmap_tracker_button_complete gMap_tracker", % (current_location_verbose = "") ? "not tracking" : current_location_verbose " (" current_map_tier ")"
	Gui, map_tracker: Add, Progress, % "xs Disabled BackgroundTrans cGreen wp range0-400 vmap_tracker_button_complete_bar h"fSize0//2, 0
	If !enable_killtracker
		Gui, map_tracker: Add, Text, % "ys BackgroundTrans vmap_tracker_label_time", % (map_tracker_time = "") ? "00:00" : map_tracker_time
	Else Gui, map_tracker: Add, Text, % "ys BackgroundTrans gLLK_MapTrackKills vmap_tracker_label_time", % (map_tracker_time = "") ? "00:00" : map_tracker_time
	
	If (mode = "add" || mode = "refresh")
	{
		map_tracker_display_loot := 1
		Loop, Parse, loottracker_loot, `,, %A_Space%
			Gui, map_tracker: Add, Text, % "xs Section BackgroundTrans vloottracker_item" A_Index " gMap_tracker", % A_LoopField
	}
	
	Gui, map_tracker: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_map_tracker%
	Gui, map_tracker: Show, % "NA x"xScreenOffSet + poe_width - poe_height*0.6155 - width + xpos_offset_map_tracker " y"yScreenOffSet + poe_height - poe_height*0.0215 - height + ypos_offset_map_tracker
	LLK_Overlay("map_tracker", "show")
}

LLK_MapTrackExport(date := "")
{
	IniRead, ini_read, ini\map tracker log.ini
	If (date != "") && FileExist("Mapping tracker " StrReplace(date, "/", "-") ".csv")
		FileDelete, % "Mapping tracker " StrReplace(date, "/", "-") ".csv"
	Else If (date = "") && FileExist("Mapping tracker.csv")
		FileDelete, % "Mapping tracker.csv"
	Loop, Parse, ini_read, `n
	{
		If (A_Index = 1)
			FileAppend, % "date,map,tier,time,portals,deaths,loot,content,kills`n" , % (date = "") ? "Mapping tracker.csv" : "Mapping tracker " StrReplace(date, "/", "-") ".csv"
		If (date != "") && !InStr(A_LoopField, date)
			continue
		IniRead, ini_read_map, ini\map tracker log.ini, % A_LoopField, map, unknown map
		ini_read_map := (ini_read_map = "") ? "unknown map" : ini_read_map
		IniRead, ini_read_tier, ini\map tracker log.ini, % A_LoopField, tier, 00
		ini_read_tier := (ini_read_tier = "") ? 00 : ini_read_tier
		IniRead, ini_read_time, ini\map tracker log.ini, % A_LoopField, time, 00:00
		ini_read_time := (ini_read_time = "") ? "00:00" : ini_read_time
		IniRead, ini_read_portals, ini\map tracker log.ini, % A_LoopField, portals, 0
		ini_read_portals := (ini_read_portals = "") ? 0 : ini_read_portals
		IniRead, ini_read_loot, ini\map tracker log.ini, % A_LoopField, loot, % A_Space
		ini_read_loot := StrReplace(ini_read_loot, ", ", "`n")
		IniRead, ini_read_deaths, ini\map tracker log.ini, % A_LoopField, deaths, 0
		ini_read_deaths := (ini_read_deaths = "") ? 0 : ini_read_deaths
		IniRead, ini_read_content, ini\map tracker log.ini, % A_LoopField, content, % A_Space
		ini_read_content := StrReplace(ini_read_content, ", ", "`n")
		IniRead, ini_read_kills, ini\map tracker log.ini, % A_LoopField, kills, 0
		ini_read_kills := (ini_read_kills = "") ? 0 : ini_read_kills
		FileAppend, % A_LoopField ",""" ini_read_map """," ini_read_tier "," ini_read_time "," ini_read_portals "," ini_read_deaths ",""" ini_read_loot """,""" ini_read_content """," ini_read_kills "`n", % (date = "") ? "Mapping tracker.csv" : "Mapping tracker " StrReplace(date, "/", "-") ".csv"
	}
	If (date = "")
		LLK_ToolTip("all logs exported")
	Else LLK_ToolTip("selected log exported")
}
	
LLK_MapTrackGUI(mode := "")
{
	global
	FormatTime, today, % A_Now, yyyy/MM/dd

	If WinExist("ahk_id " hwnd_map_tracker_log) && (mode != "refresh")
	{
		Gui, map_tracker_log: Destroy
		hwnd_map_tracker_log := ""
		map_tracker_log_selected_date := ""
		Return
	}
	
	IniRead, map_tracker_logs, ini\map tracker log.ini,
	Loop, Parse, map_tracker_logs, `n
	{
		If (A_Index = 1)
			map_tracker_dates := ""
		parse_date := SubStr(A_LoopField, 1, 10)
		If (map_tracker_log_selected_date = "")
			map_tracker_dates .= (map_tracker_dates = "") ? parse_date "|" : !InStr(map_tracker_dates, parse_date) ? (parse_date = today) ? parse_date "||" : parse_date "|" : ""
		Else map_tracker_dates .= (map_tracker_dates = "") ? (parse_date = map_tracker_log_selected_date) ? parse_date "||" : parse_date "|" : !InStr(map_tracker_dates, parse_date) ? (parse_date = map_tracker_log_selected_date) ? parse_date "||" : parse_date "|" : ""
	}
	map_tracker_dates .= InStr(map_tracker_dates, "||") ? "" : "|"
	
	Gui, map_tracker_log: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_tracker_log
	Gui, map_tracker_log: Margin, % fSize0//2, % fSize0//2
	Gui, map_tracker_log: Color, Black
	WinSet, Trans, %trans%
	Gui, map_tracker_log: Font, % "cWhite s"fSize0 + fSize_offset_map_tracker + 2, Fontin SmallCaps
	
	Gui, map_tracker_log: Add, Text, % "Section BackgroundTrans HWNDmain_text", % "logs:"
	ControlGetPos,,, width,,, ahk_id %main_text%
	Gui, map_tracker_log: Font, % "s"fSize0 + fSize_offset_map_tracker - 2
	Gui, map_tracker_log: Add, DDL, % "ys BackgroundTrans hp cBlack vmap_tracker_log_ddl gMap_tracker r"LLK_InStrCount(map_tracker_dates, "|") + 1 " w"width*2, % map_tracker_dates
	Gui, map_tracker_log: Font, % "s"fSize0 + fSize_offset_map_tracker + 2
	Gui, map_tracker_log: Add, Progress, % "ys x+0 hp Disabled BackgroundTrans cRed vmap_tracker_log_delete_bar range0-400 Vertical w"fSize0, 0
	Gui, map_tracker_log: Add, Text, % "ys x+0 Border BackgroundTrans vmap_tracker_log_delete_day gMap_tracker", % " del "
	If (StrLen(map_tracker_dates) >= 10)
	{
		Gui, map_tracker_log: Add, Text, % "ys BackgroundTrans", % "export:"
		Gui, map_tracker_log: Add, Text, % "ys Border BackgroundTrans vmap_tracker_log_export_day gMap_tracker", % " day "
		Gui, map_tracker_log: Add, Text, % "ys Border BackgroundTrans vmap_tracker_log_export_all gMap_tracker", % " all "
	}
	
	Gui, map_tracker_log: Submit, NoHide
	GuiControlGet, map_tracker_log_selected_date,, map_tracker_log_ddl
	
	map_tracker_log_entries := 0
	map_tracker_log_section := 0
	map_tracker_log_section_count := 0
	map_tracker_log_x_offset := 0
	map_tracker_log_height := 0
	map_tracker_entry_width := poe_width*0.95//4
	
	Loop, Parse, map_tracker_logs, `n
	{
		If InStr(A_LoopField, map_tracker_log_selected_date)
		{
			map_tracker_log_entries += 1
			map_tracker_log_ini%map_tracker_log_entries% := A_LoopField
			map_tracker_log_datetime := SubStr(A_LoopField, -7, 5)
			IniRead, map_tracker_log_map, ini\map tracker log.ini, % A_LoopField, map, unknown map
			map_tracker_log_map := (map_tracker_log_map = "") ? "unknown map" : map_tracker_log_map
			IniRead, map_tracker_log_tier, ini\map tracker log.ini, % A_LoopField, tier, 00
			map_tracker_log_tier := (map_tracker_log_tier = "") ? 00 : map_tracker_log_tier
			IniRead, map_tracker_log_time, ini\map tracker log.ini, % A_LoopField, time, 00:00
			map_tracker_log_time := (map_tracker_log_time = "") ? "00:00" : map_tracker_log_time
			IniRead, map_tracker_log_portals, ini\map tracker log.ini, % A_LoopField, portals, 0
			map_tracker_log_portals := (map_tracker_log_portals = "") ? 0 : map_tracker_log_portals
			IniRead, map_tracker_log_loot%map_tracker_log_entries%, ini\map tracker log.ini, % A_LoopField, loot, % A_Space
			map_tracker_log_loot%map_tracker_log_entries% := (map_tracker_log_loot%map_tracker_log_entries% != "") ? StrReplace(map_tracker_log_loot%map_tracker_log_entries%, ", ", "`n") : "none"
			map_tracker_log_loot_binary := (map_tracker_log_loot%map_tracker_log_entries% = "none") ? 0 : 1
			IniRead, map_tracker_log_deaths, ini\map tracker log.ini, % A_LoopField, deaths, 0
			map_tracker_log_deaths := (map_tracker_log_deaths = "") ? 0 : map_tracker_log_deaths
			IniRead, map_tracker_log_content%map_tracker_log_entries%, ini\map tracker log.ini, % A_LoopField, content, % A_Space
			map_tracker_log_content%map_tracker_log_entries% := (map_tracker_log_content%map_tracker_log_entries% != "") ? StrReplace(map_tracker_log_content%map_tracker_log_entries%, ", ", "`n") : "none"
			map_tracker_log_content_count := (map_tracker_log_content%map_tracker_log_entries% = "none") ? 0 : LLK_InStrCount(map_tracker_log_content%map_tracker_log_entries%, "`n") + 1
			IniRead, map_tracker_kills%map_tracker_log_entries%, ini\map tracker log.ini, % A_LoopField, kills, 0
			
			color := (map_tracker_log_content_count + map_tracker_log_loot_binary + map_tracker_kills%map_tracker_log_entries% = 0) ? "White" : "Aqua"
			
			map_tracker_log_text := " " map_tracker_log_datetime " t" map_tracker_log_tier " " map_tracker_log_time " " map_tracker_log_portals "p " map_tracker_log_deaths "d " map_tracker_log_map " " 
			If (map_tracker_log_entries = 1)
				Gui, map_tracker_log: Add, Text, % "xs hp Section BackgroundTrans Border c"color " gMap_tracker -wrap HWNDmain_text vmap_tracker_log_entry"map_tracker_log_entries " w"map_tracker_entry_width, % map_tracker_log_text
			Else Gui, map_tracker_log: Add, Text, % (map_tracker_log_section = 1) || (!Mod(map_tracker_log_entries, map_tracker_log_section_count) && (map_tracker_log_section_count != 0)) ? "ys hp Section BackgroundTrans Border c"color " gMap_tracker -wrap HWNDmain_text x"map_tracker_log_x_offset + fSize0 " vmap_tracker_log_entry"map_tracker_log_entries " w"map_tracker_entry_width " h"map_tracker_log_height0 : "xs hp y+0 BackgroundTrans Border c"color " gMap_tracker -wrap HWNDmain_text vmap_tracker_log_entry"map_tracker_log_entries " w"map_tracker_entry_width " h"map_tracker_log_height0, % map_tracker_log_text
			Gui, map_tracker_log: Add, Progress, % "xs y+0 wp BackgroundTrans cRed range0-400 vmap_tracker_log_delete_entry"map_tracker_log_entries " h"fSize0//2, 0
			ControlGetPos, map_tracker_log_x,, map_tracker_log_width, map_tracker_log_height0,, ahk_id %main_text%
			map_tracker_log_x_offset := (map_tracker_log_x + map_tracker_log_width > map_tracker_log_x_offset) ? map_tracker_log_x + map_tracker_log_width : map_tracker_log_x_offset
			Gui, map_tracker_log: Show, NA AutoSize
			WinGetPos,,,, map_tracker_log_height, ahk_id %hwnd_map_tracker_log%
			map_tracker_log_section += (map_tracker_log_height >= poe_height*0.9) ? 1 : 0
			If (map_tracker_log_height >= poe_height*0.9) && (map_tracker_log_section_count = 0)
				map_tracker_log_section_count := map_tracker_log_entries
		}
	}
	;WinSet, Redraw,, ahk_id %hwnd_map_tracker_log%
	
	Gui, Show, NA Center AutoSize
	LLK_Overlay("map_tracker_log", "show")
}

LLK_MapTrackInstance(log_line)
{
	If InStr(log_line, "mapworlds") || InStr(log_line, "Maven") || InStr(log_line, "betrayal") || InStr(log_line, "incursion") || (InStr(log_line, "heist") && !InStr(log_line, "heisthub")) || InStr(log_line, "mapatziri") || InStr(log_line, "legionleague") || InStr(log_line, "expedition") || InStr(log_line, "atlasexilesboss")
		Return 1
	Else Return 0
}

LLK_MapTrackKills()
{
	global
	If (map_tracker_map = "")
	{
		WinActivate, ahk_group poe_window
		Return
	}
	Clipboard := "/kills"
	KeyWait, LButton
	KeyWait, % omnikey_hotkey
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, {Enter}^{a}^{v}{Enter}
	LLK_ToolTip((map_tracker_refresh_kills = 1) ? "kill-tracker activated" : "kill-count refreshed")
	map_tracker_refresh_kills := 0
	map_tracker_panel_color := "Black"
	Gui, map_tracker: Color, Black
	GuiControl, map_tracker: +BackgroundBlack, map_tracker_button_complete_bar
	WinSet, Redraw,, ahk_id %hwnd_map_tracker%
	WinActivate, ahk_group poe_window
	map_tracker_kills_refreshed := A_TickCount
}

LLK_MapTrackKillStart()
{
	global
	ToolTip, % "          omni-key: start`n          kill-tracker",,, 11
	If (map_tracker_refresh_kills = 0)
	{
		SetTimer, LLK_MapTrackKillStart, Delete
		ToolTip,,,, 11
	}
}

LLK_MapTrackLoot(entry)
{
	global
	MouseGetPos, map_tracker_loot_mouseX, map_tracker_loot_mouseY
	Gui, map_tracker_loot: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_tracker_loot
	Gui, map_tracker_loot: Margin, % fSize0//2, % fSize0//2
	Gui, map_tracker_loot: Color, Black
	Gui, map_tracker_loot: Font, % "cWhite s"fSize0 + fSize_offset_map_tracker, Fontin SmallCaps
	
	map_tracker_loot_style := (map_tracker_log_loot%entry% != "none") ? "ys x+" fSize0*2 : ""
	If (map_tracker_log_loot%entry% != "none")
		Gui, map_tracker_loot: Add, Text, % "Section BackgroundTrans", % "loot:`n" map_tracker_log_loot%entry%
	If (map_tracker_log_content%entry% != "none")
		Gui, map_tracker_loot: Add, Text, % map_tracker_loot_style " Section BackgroundTrans", % "content:`n" map_tracker_log_content%entry%
	map_tracker_loot_style := (map_tracker_log_loot%entry% = "none") && (map_tracker_log_content%entry% = "none") ? "" : "ys x+" fSize0*2
	If (map_tracker_kills%entry% != 0)
		Gui, map_tracker_loot: Add, Text, % map_tracker_loot_style "BackgroundTrans", % "kills:`n" map_tracker_kills%entry%
	Gui, map_tracker_loot: Show, NA x10000 y10000
	WinGetPos, map_tracker_loot_xpos, map_tracker_loot_ypos, map_tracker_loot_width, map_tracker_loot_height, ahk_id %hwnd_map_tracker_loot%
	map_tracker_loot_mouseX := (map_tracker_loot_mouseX + map_tracker_loot_width > xScreenOffSet + poe_width) ? xScreenOffSet + poe_width - map_tracker_loot_width : map_tracker_loot_mouseX
	map_tracker_loot_mouseY := (map_tracker_loot_mouseY + map_tracker_loot_height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - map_tracker_loot_height : map_tracker_loot_mouseY
	Gui, map_tracker_loot: Show, NA x%map_tracker_loot_mouseX% y%map_tracker_loot_mouseY%
	KeyWait, LButton
	Gui, map_tracker_loot: Destroy
}

LLK_MapTrackSave()
{
	global loottracker_loot, map_tracker_deaths, map_tracker_time, current_location_verbose, map_tracker_map, portals, date_time, hwnd_loottracker, map_tracker_content, map_tracker_side_area, map_tracker_kills, map_tracker_panel_color
	parsed_loot := []
	Sort, loottracker_loot, D`,
	Loop, Parse, loottracker_loot, `,, %A_Space%
	{
		If (A_LoopField = "")
			continue
		item := InStr(A_LoopField, "(") ? StrReplace(SubStr(A_LoopField, 1, InStr(A_LoopField, "(") - 2), A_Space, "_") : StrReplace(A_LoopField, A_Space, "_")
		item := StrReplace(item, "'", "_apostrophe_")
		item := StrReplace(item, "-", "_dash_")
		item := StrReplace(item, ":", "_colon_")
		If !LLK_ArrayHasVal(parsed_loot, item)
			parsed_loot.Push(item)
		%item% += InStr(A_LoopField, "(") ? SubStr(A_LoopField, InStr(A_LoopField, "(") + 1, InStr(A_LoopField, ")") - InStr(A_LoopField, "(") + 1) : 1
	}
	Loop, % parsed_loot.Count()
	{
		item := parsed_loot[A_Index]
		item_name := StrReplace(parsed_loot[A_Index], "_apostrophe_", "'")
		item_name := StrReplace(item_name, "_dash_", "-")
		item_name := StrReplace(item_name, "_colon_", ":")
		item_name := StrReplace(item_name, "_", A_Space)
		item_count := (%item% > 1) ? " (" %item% ")" : ""
		loottracker_loot := (A_Index = 1) ? item_name item_count : loottracker_loot ", " item_name item_count
	}
	Loop, Parse, map_tracker_content, |
	{
		If (A_Index = 1)
			map_tracker_content := ""
		If (A_LoopField = "")
			continue
		map_tracker_content .= (map_tracker_content = "") ? A_LoopField : ", " A_LoopField
	}
	map_tracker_kills := (map_tracker_kills = "") ? 0 : map_tracker_kills
	IniWrite, % "map=" current_location_verbose "`ntier=" SubStr(map_tracker_map, InStr(map_tracker_map, "|",,, 1) + 1, InStr(map_tracker_map, "|",,, 2) - InStr(map_tracker_map, "|",,, 1) - 1) "`ntime=" map_tracker_time "`nportals=" portals "`ndeaths=" map_tracker_deaths "`nloot=" loottracker_loot "`nkills=" map_tracker_kills "`ncontent=" map_tracker_content, ini\map tracker log.ini, % date_time
	loottracker_loot := ""
	map_tracker_map := ""
	current_location_verbose := ""
	map_tracker_panel_color := "Black"
	map_tracker_time := ""
	map_tracker_deaths := 0
	map_tracker_kills := 0
	map_tracker_content := "|"
	map_tracker_side_area := ""
	LLK_MapTrack()
}