Init_GUI(name := "")
{
	local
	global vars, settings, update
	
	If !IsObject(vars.GUI)
		vars.GUI := []
	
	If !name || (name = "LLK_panel")
	{
		Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
		Gui, LLK_panel: Margin, % settings.general.fWidth/4, 0
		Gui, LLK_panel: Color, % !IsNumber(update.1) ? "Black" : (update.1 > 0) ? "Green" : (update.1 < 0) ? "Maroon" : "Black"
		Gui, LLK_panel: Font, % "s"settings.general.fSize " cWhite underline", Fontin SmallCaps
		vars.hwnd.LLK_panel := hwnd
		
		Gui, LLK_panel: Add, Text, Section Center BackgroundTrans gSettings_general2, % "LLK-UI"
		Gui, LLK_panel: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.LLK_panel
		
		xPos := (settings.general.xButton > vars.monitor.w / 2 - 1) ? settings.general.xButton - (w - 1) : settings.general.xButton ;apply right-alignment if applicable (i.e. if button is on the right half of monitor)
		xPos := (xPos + (w - 1) >= vars.monitor.w - 1) ? (vars.monitor.w - 1) - (w - 1) : xPos ;correct the coordinates if panel ends up out of monitor-bounds
		
		yPos := (settings.general.yButton > vars.monitor.h / 2 - 1) ? settings.general.yButton - (h - 1) : settings.general.yButton ;apply top-alignment if applicable (i.e. if button is on the top half of monitor)
		yPos := (yPos + (h - 1) >= vars.monitor.h - 1) ? (vars.monitor.h - 1) - (h - 1): yPos ;correct the coordinates if panel ends up out of monitor-bounds
		
		Gui, LLK_panel: Show, % "Hide x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
		LLK_Overlay(vars.hwnd.LLK_panel, "show") ;LLK_Overlay(vars.hwnd.LLK_panel, settings.general.hide_button ? "hide" : "show")
	}

	Loop, Parse, % "leveltracker, maptracker, notepad", `,, %A_Space%
	{
		If (settings.features[A_LoopField] || settings.qol[A_LoopField]) && (!name || name = A_LoopField)
			GuiButton(A_LoopField)
		Else If !settings.features[A_LoopField] && !settings.qol[A_LoopField]
			LLK_Overlay(vars.hwnd[A_LoopField "_button"].main, "destroy")
	}

	/*
	If settings.features.leveltracker && (!name || name = "leveltracker")
	{
		If WinExist("ahk_id "vars.hwnd.leveltracker_button.main)
			LLK_Overlay(vars.hwnd.leveltracker_button.main, "destroy")
		Gui, leveltracker_button: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd ; +E0x02000000 +E0x00080000
		Gui, leveltracker_button: Margin, 0, 0
		Gui, leveltracker_button: Color, Aqua
		WinSet, TransColor, Aqua
		Gui, leveltracker_button: Font, % "s"settings.general.fSize " cYellow w1000", Fontin SmallCaps
		vars.hwnd.leveltracker_button := {"main": hwnd}
		
		Gui, leveltracker_button: Add, Picture, % "BackgroundTrans Border gLeveltracker w"settings.leveltracker.sButton " h-1", % "img\GUI\leveling_guide"(!vars.hwnd.leveltracker.main ? "0" : "") ".jpg"
		Gui, leveltracker_button: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_button.main

		If !Blank(settings.leveltracker.xButton)
		{
			xPos := (settings.leveltracker.xButton > vars.monitor.w/2 - 1) ? settings.leveltracker.xButton - (w - 1) : settings.leveltracker.xButton
			xPos := (xPos + w > vars.monitor.w - 1) ? (vars.monitor.w - 1) - (w - 1) : xPos ;prevent panel from leaving screen
			yPos := (settings.leveltracker.yButton > vars.monitor.h/2 - 1) ? settings.leveltracker.yButton - (h - 1) : settings.leveltracker.yButton
			yPos := (yPos + h > vars.monitor.h - 1) ? (vars.monitor.h - 1) - (h - 1) : yPos ;prevent panel from leaving screen
		}
		Else xPos := vars.client.xc, yPos := vars.client.y + (vars.client.h - 1) - (h - 1)
		
		Gui, leveltracker_button: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
		LLK_Overlay(vars.hwnd.leveltracker_button.main, "show")
	}
	Else If !settings.features.leveltracker
		LLK_Overlay(vars.hwnd.leveltracker_button.main, "destroy")

	If settings.features.maptracker && (!name || name = "maptracker")
	{
		If WinExist("ahk_id "vars.hwnd.maptracker_button.main)
			LLK_Overlay(vars.hwnd.maptracker_button.main, "destroy")
		Gui, maptracker_button: New, -DPIScale -Caption +Border +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd ; +E0x02000000 +E0x00080000
		Gui, maptracker_button: Margin, 0, 0
		Gui, maptracker_button: Color, Aqua
		WinSet, TransColor, Aqua
		Gui, maptracker_button: Font, % "s"settings.maptracker.fSize " cYellow w1000", Fontin SmallCaps
		vars.hwnd.maptracker_button := {"main": hwnd}
		
		Gui, maptracker_button: Add, Picture, % "BackgroundTrans gMaptracker w"settings.maptracker.sButton " h-1", % "img\GUI\map_tracker.jpg"
		Gui, maptracker_button: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.maptracker_button.main
		
		If !Blank(settings.maptracker.xButton)
		{
			xPos := (settings.maptracker.xButton > vars.monitor.w/2 - 1) ? settings.maptracker.xButton - (w - 1) : settings.maptracker.xButton
			xPos := (xPos + w > vars.monitor.w - 1) ? (vars.monitor.w - 1) - (w - 1) : xPos ;prevent panel from leaving screen
			yPos := (settings.maptracker.yButton > vars.monitor.h/2 - 1) ? settings.maptracker.yButton - (h - 1) : settings.maptracker.yButton
			yPos := (yPos + h > vars.monitor.h - 1) ? (vars.monitor.h - 1) - (h - 1) : yPos ;prevent panel from leaving screen
		}
		Else xPos := vars.client.xc, yPos := vars.client.y + (vars.client.h - 1) - (h - 1)
		
		Gui, maptracker_button: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
		LLK_Overlay(vars.hwnd.maptracker_button.main, "show")
	}
	Else If !settings.features.maptracker
		LLK_Overlay(vars.hwnd.maptracker_button.main, "destroy")
	*/
	;#################################################################################################
	
	/*
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
		If (alarm_panel_xpos_target + alarm_panel_dimensions + 2 >= poe_width - pixelsearch.gamescreen.x1 - 1) && (alarm_panel_ypos_target <= pixelsearch.gamescreen.y1 + 1) ;protect pixel-check area in case panel gets resized
			alarm_panel_ypos_target := pixelsearch.gamescreen.y1 + 2
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
		If (delve_panel_xpos_target + delve_panel_dimensions + 2 >= poe_width - pixelsearch.gamescreen.x1 - 1) && (delve_panel_ypos_target <= pixelsearch.gamescreen.y1 + 1) ;protect pixel-check area in case panel gets resized
			delve_panel_ypos_target := pixelsearch.gamescreen.y1 + 2
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
		If (notepad_panel_xpos_target + notepad_panel_dimensions + 2 >= poe_width - pixelsearch.gamescreen.x1 - 1) && (notepad_panel_ypos_target <= pixelsearch.gamescreen.y1 + 1) ;protect pixel-check area in case panel gets resized
			notepad_panel_ypos_target := pixelsearch.gamescreen.y1 + 2
		Gui, notepad_panel: Show, % "NA x"xScreenOffset + notepad_panel_xpos_target " y"yScreenoffset + notepad_panel_ypos_target
		LLK_Overlay("notepad_panel", "show")
	}
	Else
	{
		guilist := StrReplace(guilist, "notepad_panel|")
		Gui, notepad_panel: Destroy
		hwnd_notepad_panel := ""
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
			If (map_tracker_panel_xpos_target + map_tracker_panel_dimensions + 2 >= poe_width - pixelsearch.gamescreen.x1 - 1) && (map_tracker_panel_ypos_target <= pixelsearch.gamescreen.y1 + 1) ;protect pixel-check area in case panel gets resized
				map_tracker_panel_ypos_target := pixelsearch.gamescreen.y1 + 2
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
	*/
}

GuiButton(name := "", x := "", y := "")
{
	local
	global vars, settings

	If WinExist("ahk_id "vars.hwnd[name "_button"].main)
		LLK_Overlay(vars.hwnd[name "_button"].main, "destroy")
	Gui, %name%_button: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd"(!Blank(x) || !Blank(y) ? " +E0x20" : "") ; +E0x02000000 +E0x00080000
	Gui, %name%_button: Margin, % (name = "leveltracker") ? 2 : 0, % (name = "leveltracker") ? 2 : 0
	Gui, %name%_button: Color, % (name = "leveltracker") ? "Aqua" : "Black"
	If (name = "leveltracker")
		WinSet, TransColor, Aqua
	Else WinSet, Trans, 255
	;Gui, %name%_button: Font, % "s"settings.general.fSize " cYellow w1000", Fontin SmallCaps
	vars.hwnd[name "_button"] := {"main": hwnd}
	
	Gui, %name%_button: Add, Picture, % "BackgroundTrans Border HWNDhwnd g"name " w"settings[name].sButton " h-1", % "img\GUI\"name (name = "leveltracker" && !vars.hwnd.leveltracker.main ? "0" : "") ".jpg"
	vars.hwnd[name "_button"].img := hwnd
	Gui, %name%_button: Show, NA x10000 y10000
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd[name "_button"].main

	If !Blank(settings[name].xButton)
	{
		xPos := (settings[name].xButton > vars.monitor.w/2 - 1) ? settings[name].xButton - (w - 1) : settings[name].xButton
		xPos := (xPos + w > vars.monitor.w - 1) ? (vars.monitor.w - 1) - (w - 1) : xPos ;prevent panel from leaving screen
		yPos := (settings[name].yButton > vars.monitor.h/2 - 1) ? settings[name].yButton - (h - 1) : settings[name].yButton
		yPos := (yPos + h > vars.monitor.h - 1) ? (vars.monitor.h - 1) - (h - 1) : yPos ;prevent panel from leaving screen
	}
	Else xPos := vars.client.xc - w/2, yPos := vars.client.y + (vars.client.h - 1) - (h - 1)

	Gui, %name%_button: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
	LLK_Overlay(vars.hwnd[name "_button"].main, "show")
}

GuiButtonDestroy() ;only used for timed destruction of a GUI-button after changing its size
{
	local
	global vars

	For key, val in vars.button_destroy
		If val && !vars[key].toggle
			LLK_Overlay(vars.hwnd[key "_button"].main, "destroy"), vars.button_destroy[key] := 0
}
