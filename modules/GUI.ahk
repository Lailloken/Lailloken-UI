GUI:
Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_LLK_panel
Gui, LLK_panel: Margin, 2, 2
Gui, LLK_panel: Color, Black
WinSet, Transparent, %trans%
Gui, LLK_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
Gui, LLK_panel: Add, Text, Section Center BackgroundTrans vLLK_panel HWNDmain_text gSettings_menu, % " LLK-UI "
Gui, LLK_panel: Show, % "NA"
WinGetPos,,, wPanel, hPanel, ahk_id %hwnd_LLK_panel%
panel_xpos_target := (panel_xpos + wPanel > poe_width) ? poe_width - wPanel : panel_xpos ;correct coordinates if panel would end up out of client-bounds
panel_ypos_target := (panel_ypos + hPanel > poe_height) ? poe_height - hPanel : panel_ypos ;correct coordinates if panel would end up out of client-bounds
If (panel_xpos_target + wPanel >= poe_width - pixel_gamescreen_x1 - 1) && (panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
	panel_ypos_target := pixel_gamescreen_y1 + 2
Gui, LLK_panel: Show, % "Hide x"xScreenOffset + panel_xpos_target " y"yScreenOffset + panel_ypos_target
LLK_Overlay("LLK_panel", (hide_panel = 1) ? "hide" : "show")

If (enable_alarm = 1)
{
	guilist .= InStr(guilist, "alarm_panel|") ? "" : "alarm_panel|"
	Gui, alarm_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_alarm_panel
	Gui, alarm_panel: Margin, 0, 0
	Gui, alarm_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, alarm_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, alarm_panel: Add, Picture, % "Center BackgroundTrans Border gAlarm w" alarm_panel_dimensions " h-1", img\GUI\alarm.jpg
	alarm_panel_xpos_target := (alarm_panel_xpos + alarm_panel_dimensions + 2 > poe_width) ? poe_width - alarm_panel_dimensions - 1 : alarm_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	alarm_panel_ypos_target := (alarm_panel_ypos + alarm_panel_dimensions + 2 > poe_height) ? poe_height - alarm_panel_dimensions - 1 : alarm_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (alarm_panel_xpos_target + alarm_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (alarm_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		alarm_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, alarm_panel: Show, % "NA x"xScreenOffset + alarm_panel_xpos_target  " y"yScreenoffset + alarm_panel_ypos_target
	LLK_Overlay("alarm_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "alarm_panel|")
	Gui, alarm_panel: Destroy
	hwnd_alarm_panel := ""
}

If (enable_delve = 1)
{
	guilist .= InStr(guilist, "delve_panel|") ? "" : "delve_panel|"
	Gui, delve_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_delve_panel
	Gui, delve_panel: Margin, 0, 0
	Gui, delve_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, delve_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, delve_panel: Add, Picture, % "Center BackgroundTrans Border gdelve w" delve_panel_dimensions " h-1", img\GUI\delve.jpg
	delve_panel_xpos_target := (delve_panel_xpos + delve_panel_dimensions + 2 > poe_width) ? poe_width - delve_panel_dimensions - 1 : delve_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	delve_panel_ypos_target := (delve_panel_ypos + delve_panel_dimensions + 2 > poe_height) ? poe_height - delve_panel_dimensions - 1 : delve_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (delve_panel_xpos_target + delve_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (delve_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		delve_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, delve_panel: Show, % "NA x"xScreenOffset + delve_panel_xpos_target " y"yScreenoffset + delve_panel_ypos_target
	If (enable_delvelog = 1)
		LLK_Overlay("delve_panel", "hide")
	Else LLK_Overlay("delve_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "delve_panel|")
	Gui, delve_panel: Destroy
	hwnd_delve_panel := ""
}

If (enable_notepad = 1)
{
	guilist .= InStr(guilist, "notepad_panel|") ? "" : "notepad_panel|"
	Gui, notepad_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_notepad_panel
	Gui, notepad_panel: Margin, 0, 0
	Gui, notepad_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, notepad_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, notepad_panel: Add, Picture, % "Center BackgroundTrans Border gNotepad w" notepad_panel_dimensions " h-1", img\GUI\notepad.jpg
	notepad_panel_xpos_target := (notepad_panel_xpos + notepad_panel_dimensions + 2 > poe_width) ? poe_width - notepad_panel_dimensions - 1 : notepad_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	notepad_panel_ypos_target := (notepad_panel_ypos + notepad_panel_dimensions + 2 > poe_height) ? poe_height - notepad_panel_dimensions - 1 : notepad_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (notepad_panel_xpos_target + notepad_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (notepad_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		notepad_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, notepad_panel: Show, % "NA x"xScreenOffset + notepad_panel_xpos_target " y"yScreenoffset + notepad_panel_ypos_target
	LLK_Overlay("notepad_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "notepad_panel|")
	Gui, notepad_panel: Destroy
	hwnd_notepad_panel := ""
}

If (settings_enable_levelingtracker = 1)
{
	guilist .= InStr(guilist, "leveling_guide_panel|") ? "" : "leveling_guide_panel|"
	Gui, leveling_guide_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_leveling_guide_panel
	Gui, leveling_guide_panel: Margin, 0, 0
	Gui, leveling_guide_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, leveling_guide_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, leveling_guide_panel: Add, Picture, % "Center BackgroundTrans Border gleveling_guide w" leveling_guide_panel_dimensions " h-1", img\GUI\leveling_guide.jpg
	leveling_guide_panel_xpos_target := (leveling_guide_panel_xpos + leveling_guide_panel_dimensions + 2 > poe_width) ? poe_width - leveling_guide_panel_dimensions - 1 : leveling_guide_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	leveling_guide_panel_ypos_target := (leveling_guide_panel_ypos + leveling_guide_panel_dimensions + 2 > poe_height) ? poe_height - leveling_guide_panel_dimensions - 1 : leveling_guide_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (leveling_guide_panel_xpos_target + leveling_guide_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (leveling_guide_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		leveling_guide_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, leveling_guide_panel: Show, % "NA x"xScreenOffset + leveling_guide_panel_xpos_target " y"yScreenoffset + leveling_guide_panel_ypos_target
	LLK_Overlay("leveling_guide_panel", "show")
	
	If (gear_tracker_char != "")
	{
		IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
		IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
		
		gear_tracker_parse := gear_tracker_items "`n" gear_tracker_gems
		Sort, gear_tracker_parse, P2 D`n N
		StringLower, gear_tracker_parse, gear_tracker_parse
		LLK_GearTrackerGUI(1)
	}
}
Else
{
	guilist := StrReplace(guilist, "leveling_guide_panel|")
	Gui, leveling_guide_panel: Destroy
	hwnd_leveling_guide_panel := ""
}

If !map_tracker_paused
{
	If settings_enable_maptracker
	{
		guilist .= InStr(guilist, "map_tracker_panel|") ? "" : "map_tracker_panel|"
		Gui, map_tracker_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_map_tracker_panel
		Gui, map_tracker_panel: Margin, 0, 0
		Gui, map_tracker_panel: Color, Black
		Gui, map_tracker_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
		Gui, map_tracker_panel: Add, Picture, % "Center BackgroundTrans Border gMap_tracker vmap_tracker_panel_img w" map_tracker_panel_dimensions " h-1", % (map_tracker_paused != 1) ? "img\GUI\map_tracker.jpg" : "img\GUI\map_tracker_disabled.jpg"
		map_tracker_panel_xpos_target := (map_tracker_panel_xpos + map_tracker_panel_dimensions + 2 > poe_width) ? poe_width - map_tracker_panel_dimensions - 1 : map_tracker_panel_xpos ;correct coordinates if panel would end up out of client-bounds
		map_tracker_panel_ypos_target := (map_tracker_panel_ypos + map_tracker_panel_dimensions + 2 > poe_height) ? poe_height - map_tracker_panel_dimensions - 1 : map_tracker_panel_ypos ;correct coordinates if panel would end up out of client-bounds
		If (map_tracker_panel_xpos_target + map_tracker_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (map_tracker_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
			map_tracker_panel_ypos_target := pixel_gamescreen_y1 + 2
		Gui, map_tracker_panel: Show, % "NA x"xScreenOffset + map_tracker_panel_xpos_target " y"yScreenoffset + map_tracker_panel_ypos_target
		LLK_Overlay("map_tracker_panel", "show")
		LLK_MapTrack()
	}
	Else
	{
		guilist := StrReplace(guilist, "map_tracker_panel|")
		Gui, map_tracker_panel: Destroy
		hwnd_map_tracker_panel := ""
		Gui, map_tracker: Destroy
		hwnd_map_tracker := ""
	}
}

If enable_itemchecker_gear
{
	Loop, Parse, gear_slots, `,
	{
		guilist .= InStr(guilist, "itemchecker_gear_" A_LoopField "|") ? "" : "itemchecker_gear_" A_LoopField "|"
		;style := WinExist("ahk_id " hwnd_settings_menu) ? "" : "+E0x20"
		Gui, itemchecker_gear_%A_LoopField%: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_itemchecker_gear_%A_LoopField%
		Gui, itemchecker_gear_%A_LoopField%: Margin, 0, 0
		Gui, itemchecker_gear_%A_LoopField%: Color, White
		WinSet, Trans, 150
		;WinSet, TransColor, Blue, ahk_id %hwnd_itemchecker_gear%
		Gui, itemchecker_gear_%A_LoopField%: Font, % "s"fSize1 " cWhite", Fontin SmallCaps
		Gui, itemchecker_gear_%A_LoopField%: Add, Text, % "BackgroundTrans gItemchecker w"%A_LoopField%_width " h"%A_LoopField%_height,
		Gui, itemchecker_gear_%A_LoopField%: Show, % "Hide x"xScreenOffSet + poe_width - 1 - itemchecker_gear_baseline + %A_LoopField%_x_offset " y"yScreenOffSet + %A_LoopField%_y_offset
		;LLK_Overlay("itemchecker_gear_" A_LoopField, "hide")
	}
}
Else
{
	Loop, Parse, gear_slots, `,
	{
		guilist := StrReplace(guilist, "itemchecker_gear_" A_LoopField "|")
		Gui, itemchecker_gear_%A_LoopField%: Destroy
		hwnd_itemchecker_gear_%A_LoopField% := ""
	}
}

If (continue_alarm = 1)
	GoSub, Alarm
Return

GUI_betrayal_prioview:
Loop, Parse, betrayal_divisions, `,, `,
{
	Gui, betrayal_prioview_%A_Loopfield%: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_betrayal_prioview_%A_Loopfield%
	Gui, betrayal_prioview_%A_Loopfield%: Margin, 0, 0
	Gui, betrayal_prioview_%A_Loopfield%: Color, White
	WinSet, Transparent, 150
	Gui, betrayal_prioview_%A_Loopfield%: Font, % "s"fSize0 * 2 " cBlack", Fontin SmallCaps
	dimensions := (betrayal_info_prio_dimensions = 0) ? 100 : betrayal_info_prio_dimensions
	IniRead, betrayal_info_prio_%A_Loopfield%, ini\betrayal info.ini, Settings, %A_Loopfield% coords, 0`,0
	Loop, Parse, betrayal_info_prio_%A_Loopfield%, `,, `,
	{
		If (A_Index = 1)
			x_coord := A_LoopField
		Else y_coord := A_LoopField
	}
	Gui, betrayal_prioview_%A_Loopfield%: Add, Text, % " Center BackgroundTrans gBetrayal_prio_drag vprio_" A_Loopfield " w"dimensions " h"dimensions, % SubStr(A_Loopfield, 1, 1)
	If (betrayal_info_prio_%A_Loopfield% = "0,0") || !IsNumber(x_coord) || !IsNumber(y_coord)
		Gui, Show, % "NA x"xScreenOffSet + A_Index * poe_width/5 " y" yScreenOffSet + poe_height/4
	Else Gui, Show, % "NA x"xScreenOffSet + x_coord " y" yScreenOffset + y_coord
	LLK_Overlay("betrayal_prioview_" A_LoopField, "show")
}
Return

GUI_clone_frames:
Loop, Parse, clone_frames_enabled, `,, `,
{
	If (A_Loopfield = "")
		Break
	Gui, clone_frames_%A_Loopfield%: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_%A_Loopfield%
	guilist := InStr(guilist, A_Loopfield) ? guilist : guilist "clone_frames_" A_Loopfield "|"
}
Return