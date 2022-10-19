Init_map_tracker:
IniRead, enable_loottracker, ini\map tracker.ini, Settings, enable loot tracker, 0
IniRead, xpos_offset_map_tracker, ini\map tracker.ini, UI, map tracker x-offset, 0
IniRead, ypos_offset_map_tracker, ini\map tracker.ini, UI, map tracker y-offset, 0
IniRead, fSize_offset_map_tracker, ini\map tracker.ini, Settings, font-offset, 0
IniRead, map_tracker_panel_offset, ini\map tracker.ini, Settings, button-offset, 1
map_tracker_panel_dimensions := poe_width*0.03*map_tracker_panel_offset
IniRead, map_tracker_panel_xpos, ini\map tracker.ini, UI, button xcoord, % poe_width/2 - (map_tracker_panel_dimensions + 2)/2
IniRead, map_tracker_panel_ypos, ini\map tracker.ini, UI, button ycoord, % poe_height - (map_tracker_panel_dimensions + 2)
Return

Map_tracker:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "map_tracker_panel")
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

If (A_Gui = "map_tracker_panel")
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

If (A_GuiControl = "xpos_offset_map_tracker")
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

If (A_GuiControl = "ypos_offset_map_tracker")
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

If InStr(A_GuiControl, "button_map_tracker")
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

If InStr(A_GuiControl, "map_tracker_log_entry")
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

If InStr(A_GuiControl, "fSize")
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

If (A_GuiControl = "enable_map_tracker")
{
	Gui, settings_menu: Submit, NoHide
	
	If (enable_map_tracker = 0)
	{
		Gui, loottracker: Destroy
		hwnd_loottracker := ""
		Gui, map_tracker_panel: Destroy
		hwnd_map_tracker_panel := ""
		LLK_MapTrackGUI()
	}
	IniWrite, %enable_map_tracker%, ini\config.ini, Features, enable map tracker
	GoSub, GUI
	GoSub, Settings_menu
	Return
}

If (A_GuiControl = "enable_loottracker")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, %enable_loottracker%, ini\map tracker.ini, Settings, enable loot tracker
	Return
}

If (A_GuiControl = "map_tracker_button_complete") ;manually marking the current map as completed
{
	If (map_tracker_map = "")
	{
		LLK_ToolTip("not tracking, cannot save", 1.5)
		WinActivate, ahk_group poe_window
		Return
	}
	If LLK_ProgressBar("map_tracker", "map_tracker_button_complete_bar")
	{
		LLK_MapTrackSave()
		LLK_MapTrack()
		sleep, 50
		LLK_ToolTip("map logged")
	}
	Return
	/*
	map_tracker_bar := 0
	map_tracker_bar_start := A_TickCount
	While GetKeyState("LButton", "P")
	{
		If (map_tracker_bar >= 700)
		{
			LLK_MapTrackSave()
			LLK_MapTrack()
			LLK_ToolTip("map logged")
			KeyWait, LButton
			Break
		}
		If (A_TickCount >= map_tracker_bar_start + 10)
		{
			map_tracker_bar += 10
			map_tracker_bar_start := A_TickCount
			GuiControl, map_tracker:, map_tracker_button_complete_bar, % map_tracker_bar
		}
	}
	GuiControl, map_tracker:, map_tracker_button_complete_bar, 0
	WinActivate, ahk_group poe_window
	*/
}

If (A_GuiControl = "map_tracker_log_ddl")
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

If (A_GuiControl = "map_tracker_log_export")
{
	If (click = 1)
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