Init_GUI(mode := "")
{
	local
	global vars, settings

	update := vars.update, settings.gui := {"oToolbar": LLK_IniRead("ini" vars.poe_version "\config.ini", "UI", "toolbar-orientation", "horizontal"), "sToolbar": LLK_IniRead("ini" vars.poe_version "\config.ini", "UI", "toolbar-size", Round(vars.monitor.h / 72))}, orientation := settings.gui.oToolbar, size := settings.gui.sToolbar, hide := settings.general.hide_toolbar, margin := settings.general.fWidth/6
	Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd +E0x02000000 +E0x00080000
	Gui, LLK_panel: Color, % !IsNumber(update.1) || (update.1 = 0) ? "Black" : (update.1 > 0) ? "Green" : "Maroon"
	Gui, LLK_panel: Margin, % margin, % margin
	Gui, LLK_panel: Font, % "s" size " cWhite Bold", % vars.system.font
	vars.hwnd.LLK_panel := {"main": hwnd}, height := 2 * size

	;Gui, LLK_panel: Add, Text, Center BackgroundTrans Hidden HWNDhwnd, % "LLK`nUI"
	;ControlGetPos,,,, height,, ahk_id %hwnd%
	;While Mod(height, 2)
	;	height += 1

	Gui, LLK_panel: Add, Pic, % "Section h" height " w-1 Border HWNDhwnd", % "img\GUI\settings.png"
	vars.hwnd.LLK_panel.settings := hwnd, style := (orientation = "horizontal") ? "ys" : "xs", style .= " " (orientation = "horizontal" ? " h" height " w" height : " w" height " h" height)

	;Gui, LLK_panel: Margin, % settings.general.fWidth/2, % settings.general.fWidth/2
	Gui, LLK_panel: Add, Pic, % style " Section Border BackgroundTrans HWNDhwnd0 " (orientation = "horizontal" ? "h" height/2 - 1 " w-1" : "w" height/2 - 1 " h-1"), % "HBitmap:*" vars.pics.global.reload
	Gui, LLK_panel: Add, Progress, % "xp yp wp hp BackgroundBlack cGreen Range0-500 HWNDhwnd01"
	Gui, LLK_panel: Margin, 0, 0
	Gui, LLK_panel: Add, Pic, % (orientation = "vertical" ? "ys" : "xs") " Border BackgroundTrans HWNDhwnd " (orientation = "horizontal" ? "h" height/2 - 1 " w-1" : "w" height/2 - 1 " h-1"), % "img\GUI\close.png"
	Gui, LLK_panel: Add, Progress, % "xp yp wp hp BackgroundBlack cRed Range0-500 HWNDhwnd1"
	vars.hwnd.LLK_panel.restart := hwnd0, vars.hwnd.LLK_panel["restart|"] := vars.hwnd.LLK_panel.restart_bar := hwnd01, vars.hwnd.LLK_panel.close := hwnd, vars.hwnd.LLK_panel["close|"] := vars.hwnd.LLK_panel.close_bar := hwnd1

	Gui, LLK_panel: Margin, % margin, % margin
	Loop, Parse, % "leveltracker, maptracker, notepad", `,, %A_Space%
	{
		If (settings.features[A_LoopField] || settings.qol[A_LoopField])
		{
			file := (A_LoopField = "leveltracker" && !(vars.hwnd.leveltracker.main || vars.leveltracker.toggle)) ? "0" : ""
			file := (A_LoopField = "maptracker" && vars.maptracker.pause) ? 0 : file
			If (A_LoopField = "leveltracker")
			{
				Gui, LLK_panel: Add, Text, % style " BackgroundTrans Center 0x200 HWNDhwnd0 cLime", % ""
				Gui, LLK_panel: Add, Pic, % "xp yp wp hp Border BackgroundTrans HWNDhwnd", % "img\GUI\" A_LoopField . file ".png"
				vars.hwnd.LLK_panel.leveltracker_text := hwnd0, vars.leveltracker.gear_counter := 0
			}
			Else Gui, LLK_panel: Add, Pic, % style " Border BackgroundTrans HWNDhwnd", % "img\GUI\" A_LoopField . file ".png"
			added := 1, vars.hwnd.LLK_panel[A_LoopField] := hwnd
		}
	}
	Gui, LLK_panel: Show, NA x10000 y10000
	WinGetPos,,, w, h, % "ahk_id " vars.hwnd.LLK_panel.main

	If (w + h < 20) ;there's some weird instance where GUI-creation can fail, leading to the toolbar being 1x1 pixels in size
	{
		Init_GUI(mode)
		Return
	}

	xPos := (settings.general.xButton >= vars.monitor.w / 2) ? settings.general.xButton - w + 1 : settings.general.xButton ;apply right-alignment if applicable (i.e. if button is on the right half of monitor)
	xPos := (xPos + (w - 1) > vars.monitor.w - 1) ? vars.monitor.w - 1 - w : xPos ;correct the coordinates if panel ends up out of monitor-bounds

	yPos := (settings.general.yButton >= vars.monitor.h / 2) ? settings.general.yButton - h + 1 : settings.general.yButton ;apply top-alignment if applicable (i.e. if button is on the top half of monitor)
	yPos := (yPos + (h - 1) > vars.monitor.h - 1) ? vars.monitor.h - 1 - h : yPos ;correct the coordinates if panel ends up out of monitor-bounds

	Gui, LLK_panel: Show, % (hide ? "hide" : "NA") " x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
	LLK_Overlay(vars.hwnd.LLK_panel.main, hide ? "hide" : "show",, "LLK_panel"), vars.toolbar := {"x": vars.monitor.x + xPos, "y": vars.monitor.y + yPos, "x2": vars.monitor.x + xPos + w, "y2": vars.monitor.y + yPos + h}

	If (mode = "refresh") || GetKeyState(vars.hotkeys.tab, "P")
	{
		LLK_Overlay(vars.hwnd.LLK_panel.main, "show")
		If hide && !GetKeyState(vars.hotkeys.tab, "P")
		{
			vars.toolbar.drag := 1
			SetTimer, Gui_ToolbarHide, -1000
		}
	}
}

Gui_CheckBounds(ByRef xPos, ByRef yPos, width, height)
{
	local
	global vars, settings

	xPos := (xPos < vars.monitor.x) ? vars.monitor.x : (xPos + width >= vars.monitor.x + vars.monitor.w ? vars.monitor.x + vars.monitor.w - width : xPos)
	yPos := (yPos < vars.monitor.y) ? vars.monitor.y : (yPos + height >= vars.monitor.y + vars.monitor.h ? vars.monitor.y + vars.monitor.h - height : yPos)
}

Gui_ClientFiller(mode := "") ;creates a black full-screen GUI to fill blank space between the client and monitor edges when using custom resolutions
{
	local
	global vars, settings

	If Blank(mode)
	{
		Gui, ClientFiller: New, -Caption +ToolWindow +LastFound HWNDhwnd
		Gui, ClientFiller: Color, Black
		WinSet, TransColor, Fuchsia
		Gui, ClientFiller: Add, Progress, % "Disabled BackgroundFuchsia x" vars.client.x - vars.monitor.x " y" vars.client.y - vars.monitor.y " w" vars.client.w " h" vars.client.h, 0
		vars.hwnd.ClientFiller := hwnd
	}
	Else If (mode = "show")
	{
		WinSet, AlwaysOnTop, On, % "ahk_id " vars.hwnd.poe_client
		Gui, ClientFiller: Show, % "NA x" vars.monitor.x " y" vars.monitor.y " Maximize"
		LLK_Overlay(vars.hwnd.ClientFiller, "show",, "ClientFiller")
		WinWait, % "ahk_id " vars.hwnd.ClientFiller
		WinSet, AlwaysOnTop, Off, % "ahk_id " vars.hwnd.poe_client
	}
}

Gui_Dummy(hwnd) ;used for A_Gui checks: "If (A_Gui = hwnd)" doesn't work reliably if the hwnd is blank, so this function returns -1 instead
{
	local

	If Blank(hwnd)
		Return -1
	Else Return hwnd
}

Gui_HelpToolTip(HWND_key)
{
	local
	global vars, settings
	static toggle := 0

	If vars.general.drag
		Return

	WinGetPos,, y,, h, % "ahk_id " vars.hwnd.help_tooltips[HWND_key]
	If Blank(y) || Blank(h)
	{
		MouseGetPos, x, y
		h := settings.general.fHeight
	}
	HWND_key := StrReplace(HWND_key, "|"), check := SubStr(HWND_key, 1, InStr(HWND_key, "_") - 1), control := SubStr(HWND_key, InStr(HWND_key, "_") + 1)
	If (check = "donation")
		check := "settings", donation := 1
	HWND_checks := {"cheatsheets": "cheatsheet_menu", "maptracker": "maptracker_logs", "maptrackernotes": "maptrackernotes_edit", "notepad": 0, "leveltracker": "leveltracker_screencap", "leveltrackereditor": "leveltracker_editor", "leveltrackerschematics": "skilltree_schematics", "lootfilter": 0, "snip": 0, "lab": 0, "searchstrings": "searchstrings_menu", "updater": "update_notification", "geartracker": 0, "seed-explorer": "legion", "recombination": 0}
	If (check != "settings")
		WinGetPos, xWin, yWin, wWin,, % "ahk_id "vars.hwnd[(HWND_checks[check] = 0) ? check : HWND_checks[check]][(check = "leveltrackerschematics") ? "info" : "main"]
	If (check = "lab" && InStr(control, "square"))
		vars.help.lab[control] := [vars.lab.compass.rooms[StrReplace(control, "square")].name], vars.help.lab[control].1 .= (vars.help.lab[control].1 = vars.lab.room.2) ? " (" Lang_Trans("lab_movemarker") ")" : ""
	If (check = "lootfilter" && InStr(control, "tooltip"))
		database := vars.lootfilter.filter, lootfilter := 1
	Else database := donation ? vars.settings.donations : !IsObject(vars.help[check][control]) ? vars.help2 : vars.help

	tooltip_width := (check = "settings") ? vars.settings.w - vars.settings.wSelection : (wWin - 2) * (check = "cheatsheets" && vars.cheatsheet_menu.type = "advanced" ? 0.5 : (check = "leveltrackereditor") ? 0.75 : 1)
	If !tooltip_width
		Return

	toggle := !toggle, GUI_name := "help_tooltip" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDtooltip
	Gui, %GUI_name%: Color, 202020
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s" settings.general.fSize - 2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.help_tooltips.main, vars.hwnd.help_tooltips.main := tooltip, vars.general.active_tooltip := vars.general.cMouse

	;LLK_PanelDimensions(vars.help[check][control], settings.general.fSize, width, height,,, 0)
	If lootfilter
	{
		target_array := Lootfilter_ChunkCompare(database[StrReplace(control, "tooltip ")],,, lootfilter_chunk), target_array := StrSplit(lootfilter_chunk, "`n", "`r`t")
		Loop, % (count := target_array.Count())
			If LLK_StringCompare(target_array[count - (A_Index - 1)], ["class", "#"])
				target_array.RemoveAt(count - (A_Index - 1))
	}
	Else target_array := (donation ? database[control].2 : database[check][control])

	If InStr(control, "update changelog")
		For index0, val in vars.updater.changelog
		{
			If !InStr(control, val.1.1)
				Continue
			For index, text in val
				If (index > 1)
				{
					Gui, %GUI_name%: Add, Text, % "x0 y-1000 Hidden w"tooltip_width - settings.general.fWidth, % StrReplace(StrReplace(text, "&", "&&"), "(/highlight)")
					Gui, %GUI_name%: Add, Text, % (index = 2 ? "x0 y0" : "xs") " Section Border BackgroundTrans hp+"settings.general.fWidth " w"tooltip_width, % ""
					Gui, %GUI_name%: Add, Text, % "HWNDhwnd xp+"settings.general.fWidth/2 " yp+"settings.general.fWidth/2 " w"tooltip_width - settings.general.fWidth . (InStr(text, "(/highlight)") ? " cFF8000" : ""), % StrReplace(StrReplace(text, "&", "&&"), "(/highlight)")
				}
		}
	Else
		For index, text in target_array
		{
			font := InStr(text, "(/bold)") ? "bold" : "", font .= InStr(text, "(/underline)") ? (font ? " " : "") "underline" : "", font := !font ? "norm" : font
			Gui, %GUI_name%: Font, % font
			Gui, %GUI_name%: Add, Text, % "x0 y-1000 Hidden w"tooltip_width - settings.general.fWidth, % StrReplace(StrReplace(StrReplace(text, "&", "&&"), "(/underline)"), "(/bold)")
			Gui, %GUI_name%: Add, Text, % (A_Index = 1 ? "Section x0 y0" : "Section xs") " Border BackgroundTrans hp+"settings.general.fWidth " w"tooltip_width, % ""
			Gui, %GUI_name%: Add, Text, % "Center xp+"settings.general.fWidth/2 " yp+"settings.general.fWidth/2 " w"tooltip_width - settings.general.fWidth (vars.lab.room.2 && InStr(text, vars.lab.room.2) ? " cLime" : ""), % LLK_StringCase(StrReplace(StrReplace(StrReplace(text, "&", "&&"), "(/underline)"), "(/bold)"))
		}

	Gui, %GUI_name%: Show, NA AutoSize x10000 y10000
	WinGetPos,,, width, height, ahk_id %tooltip%
	xPos := (check = "settings") ? vars.settings.x + vars.settings.wSelection - 1 : xWin + (check = "leveltrackereditor" ? (wWin - 2)//8 : 0), yPos := InStr(control, "update changelog") && (height > vars.monitor.h - (y + h)) ? y - height - 1 : (y + h + height + 1 > vars.monitor.y + vars.monitor.h) ? y - height : y + h
	If (check = "lootfilter")
		yPos := vars.lootfilter.yPos - height, yPos := (yPos < vars.monitor.y) ? vars.monitor.y : yPos
	Gui, %GUI_name%: Show, % "NA x"xPos " y"(InStr("notepad, lab, leveltracker, snip, searchstrings, maptracker", check) ? yWin - (InStr("maptracker", check) ? height - 1 : 0) : yPos)
	LLK_Overlay(tooltip, (width < 10) ? "hide" : "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

Gui_Name(GuiHWND)
{
	local
	global vars

	For index, val in vars.GUI
		If !Blank(LLK_HasVal(val, GuiHWND))
			Return val.name
}

Gui_ToolbarButtons(cHWND, hotkey)
{
	local
	global vars, settings

	start := A_TickCount, check := LLK_HasVal(vars.hwnd.LLK_panel, cHWND)
	If (check = "settings")
	{
		vars.toolbar.drag := 1
		While (check = "settings") && GetKeyState("LButton", "P") ;dragging the toolbar
		{
			If (A_TickCount >= start + 250)
			{
				WinGetPos,,, width, height, % "ahk_id " vars.hwnd.LLK_panel.main
				While GetKeyState("LButton", "P")
				{
					LLK_Drag(width, height, xPos, yPos,, "LLK_panel")
					Sleep 1
				}
				KeyWait, LButton
				IniWrite, % xPos, % "ini" vars.poe_version "\config.ini", UI, button xcoord
				IniWrite, % yPos, % "ini" vars.poe_version "\config.ini", UI, button ycoord
				settings.general.xButton := xPos, settings.general.yButton := yPos, vars.general.drag := 0
				Init_GUI()
				WinActivate, ahk_group poe_window
				vars.toolbar.drag := 0
				Return
			}
		}
		vars.toolbar.drag := 0

		If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main) || WinExist("ahk_id " vars.hwnd.searchstrings_menu.main) || WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main) || WinExist("ahk_id " vars.hwnd.leveltracker_editor.main)
			LLK_ToolTip(Lang_Trans("global_configwindow"), 2,,,, "yellow")
		Else If (hotkey = 2)
		{
			KeyWait, RButton
			settings.gui.oToolbar := (settings.gui.oToolbar = "horizontal") ? "vertical" : "horizontal"
			IniWrite, % settings.gui.oToolbar, % "ini" vars.poe_version "\config.ini", UI, toolbar-orientation
			Init_GUI("refresh")
		}
		Else If WinExist("ahk_id "vars.hwnd.settings.main)
			Settings_menuClose()
		Else Settings_menu(vars.settings.active_last ? vars.settings.active_last : "general",, 0)
	}
	Else If InStr(check, "restart")
	{
		If LLK_Progress(vars.hwnd.LLK_panel.restart_bar, "LButton")
		{
			If GetKeyState(vars.hotkeys.tab, "P")
			{
				LLK_ToolTip(Lang_Trans("global_releasekey") " " vars.hotkeys.tab, 10000)
				KeyWait, % vars.hotkeys.tab
			}
			KeyWait, LButton
			Reload
			ExitApp
		}
	}
	Else If InStr(check, "close")
	{
		If LLK_Progress(vars.hwnd.LLK_panel.close_bar, "LButton")
		{
			If GetKeyState(vars.hotkeys.tab, "P")
			{
				LLK_ToolTip(Lang_Trans("global_releasekey") " " vars.hotkeys.tab, 10000)
				KeyWait, % vars.hotkeys.tab
			}
			ExitApp
		}
	}
	Else If InStr(check, "leveltracker")
		Leveltracker(cHWND, hotkey)
	Else If (check = "maptracker")
		Maptracker(cHWND, hotkey)
	Else If (check = "notepad")
		Notepad(cHWND, hotkey)
}

Gui_ToolbarHide()
{
	local
	global vars

	LLK_Overlay(vars.hwnd.LLK_panel.main, "hide"), vars.toolbar.drag := 0
}

LLK_ControlGet(cHWND, GUI_name := "", subcommand := "")
{
	local

	If GUI_name
		GUI_name := GUI_name ": "
	GuiControlGet, parse, % GUI_name subcommand, % cHWND
	Return parse
}

LLK_ControlGetPos(cHWND, return_val)
{
	local

	ControlGetPos, x, y, width, height,, ahk_id %cHWND%
	Switch return_val
	{
		Case "x":
			Return x
		Case "y":
			Return y
		Case "w":
			Return width
		Case "h":
			Return height
	}
}

LLK_Drag(width, height, ByRef xPos, ByRef yPos, top_left := 0, gui_name := "", snap := 0, xOffset := "", yOffset := "", ignore_bounds := 0) ; top_left parameter: GUI will be aligned based on top-left corner
{
	local
	global vars, settings

	protect := (vars.pixelsearch.gamescreen.x1 < 8) ? 8 : vars.pixelsearch.gamescreen.x1 + 1, vars.general.drag := 1
	MouseGetPos, xMouse, yMouse

	If !Blank(xOffset)
		xPos := xMouse - xOffset, yPos := yMouse - yOffset
	Else xPos := xMouse, yPos := yMouse

	If !gui_name
		gui_name := A_Gui

	If !gui_name
	{
		LLK_ToolTip("missing gui-name",,,,, "red")
		sleep 1000
		Return
	}

	If !ignore_bounds
	{
		xPos := (xPos < vars.monitor.x) ? vars.monitor.x : xPos, yPos := (yPos < vars.monitor.y) ? vars.monitor.y : yPos
		xPos -= vars.monitor.x, yPos -= vars.monitor.y
		If (xPos >= vars.monitor.w)
			xPos := vars.monitor.w - 1
		If (yPos >= vars.monitor.h)
			yPos := vars.monitor.h - 1
	}

	If (xPos >= vars.monitor.w / 2) && !top_left
		xTarget := xPos - width + 1
	Else xTarget := xPos

	If (yPos >= vars.monitor.h / 2) && !top_left
		yTarget := yPos - height + 1
	Else yTarget := yPos

	If !ignore_bounds
	{
		If top_left && (xTarget + width > vars.monitor.w)
			xTarget := vars.monitor.w - width, xPos := xTarget
		If top_left && (yTarget + height > vars.monitor.h)
			yTarget := vars.monitor.h - height, yPos := yTarget
	}
	
	If snap && LLK_IsBetween(xTarget + width/2, vars.monitor.x + vars.client.xc * 0.9, vars.monitor.x + vars.client.xc * 1.1)
		xPos := "", xTarget := vars.client.xc - width/2 + 1

	Gui, %gui_name%: Show, % (vars.client.stream ? "" : "NA ") "x" vars.monitor.x + xTarget " y" vars.monitor.y + yTarget
}

LLK_FontDefault()
{
	local
	global vars, settings

	Return LLK_IniRead("data\Resolutions.ini", vars.monitor.h "p", "font", 16)
}

LLK_FontDimensions(size, ByRef font_height_x, ByRef font_width_x)
{
	local
	global vars

	Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, font_size: Margin, 0, 0
	Gui, font_size: Color, Black
	Gui, font_size: Font, % "cWhite s"size, % vars.system.font
	Gui, font_size: Add, Text, % "Border HWNDhwnd", % "7"
	GuiControlGet, font_check_, Pos, % hwnd
	font_height_x := font_check_h
	font_width_x := font_check_w
	Gui, font_size: Destroy
}

LLK_FontSizeGet(height, ByRef font_width) ;returns a font-size that approximates the height passed to the function
{
	local
	global vars

	Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow
	Gui, font_size: Margin, 0, 0
	Gui, font_size: Color, Black
	Loop
	{
		Gui, font_size: Font, % "cWhite s"A_Index, % vars.system.font
		Gui, font_size: Add, Text, % "Border HWNDhwnd", % "7"
		ControlGetPos,,, font_width, font_height,, % "ahk_id "hwnd
		check += (font_height > height) ? 1 : 0
		If check
		{
			Gui, font_size: Destroy ;it would be technically correct to return A_Index - 1 (i.e. the last index where font_height was still lower than height), but there is a lot of leeway with font-heights ;cont
			Return A_Index + 2 ;because every text exclusively uses lower-case letters
		}
	}
}

LLK_ImageCache(file)
{
	local
	global vars, settings

	pBitmap := Gdip_CreateBitmapFromFile(file), pHBM := Gdip_CreateHBITMAPFromBitmap(pBitmap, 0), Gdip_DisposeImage(pBitmap)
	Return pHBM
}

LLK_Overlay(guiHWND, mode := "show", NA := 1, gui_name0 := "")
{
	local
	global vars, settings

	If Blank(guiHWND)
		Return

	If !Blank(gui_name0)
		vars.GUI.Push({"name": gui_name0, "hwnd": guiHWND, "show": 0, "dummy": ""})

	For index, val in vars.GUI
		If !Blank(LLK_HasVal(val, guiHWND))
		{
			gui_name := val.name, gui_index := index
			Break
		}

	If !InStr("showhide", guiHWND) && (Blank(gui_name) || Blank(gui_index))
		Return

	If (guiHWND = "hide")
	{
		For index, val in vars.GUI
		{
			If (val.hwnd = vars.hwnd.settings.main) && (vars.settings.active = "betrayal-info") || !WinExist("ahk_id " val.hwnd) || InStr(vars.hwnd.cheatsheet_menu.main "," vars.hwnd.searchstrings_menu.main "," vars.hwnd.leveltracker_screencap.main "," vars.hwnd.notepad.main "," vars.hwnd.leveltracker_editor.main, val.hwnd)
				Continue
			Gui, % val.name ": Hide"
		}
	}
	Else If (guiHWND = "show")
	{
		For index, val in vars.GUI
		{
			ControlGetPos, x,,,,, % "ahk_id " val.dummy
			If !val.show || Blank(x)
				Continue
			Gui, % val.name ": Show", NA
		}
	}
	Else If (mode = "show") || (mode = "hide") && !Blank(gui_name0)
	{
		If !vars.GUI[gui_index].dummy
		{
			Gui, %gui_name%: Add, Text, Hidden x0 y0 HWNDhwnd, % "" ;add a dummy text-control to the GUI with which to check later on if it has been destroyed already (via ControlGetPos)
			vars.GUI[gui_index].dummy := hwnd, vars.GUI[gui_index].show := (mode = "show") ? 1 : 0
		}
		Else vars.GUI[gui_index].show := 1
		Gui, %gui_name%: Show, % (mode = "show" ? (NA ? "NA" : "") : "Hide")
	}
	Else If (mode = "hide")
	{
		If WinExist("ahk_id " guiHWND)
			Gui, %gui_name%: Hide
		vars.GUI[gui_index].show := 0
	}
	Else If (mode = "destroy")
	{
		If vars.GUI[gui_index].dummy
			ControlGetPos, x,,,,, % "ahk_id " vars.GUI[gui_index].dummy
		If WinExist("ahk_id " guiHWND) || !Blank(x)
			Gui, %gui_name%: Destroy
	}
	Else If (mode = "check")
	{
		If vars.GUI[gui_index].dummy
			ControlGetPos, x,,,,, % "ahk_id " vars.GUI[gui_index].dummy
		Return x
	}

	For index, val in vars.GUI ;check for GUIs that have already been destroyed
	{
		ControlGetPos, x,,,,, % "ahk_id " val.dummy
		If Blank(x)
			remove .= index ";"
	}
	Loop, Parse, remove, `;
		If IsNumber(A_LoopField)
			vars.GUI.RemoveAt(A_LoopField)
}

LLK_PanelDimensions(array, fSize, ByRef width, ByRef height, align := "left", header_offset := 0, margins := 1, min_width := 0)
{
	local
	global vars

	Gui, panel_dimensions: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow
	Gui, panel_dimensions: Margin, 0, 0
	Gui, panel_dimensions: Color, Black
	Gui, panel_dimensions: Font, % "s"fSize + header_offset " cWhite", % vars.system.font
	width := min_width ? 9999 : 0, height := 0, string := array.1

	If min_width
	{
		array := []
		Loop, % Max(LLK_InStrCount(string, " "), 1)
		{
			outer := A_Index, new_string := ""
			Loop, Parse, string, %A_Space%
				new_string .= A_LoopField . (outer = A_Index ? "`n" : " ")
			If (SubStr(new_string, 0) = "`n")
				new_string := SubStr(new_string, 1, -1)
			array.Push(new_string)
		}
	}

	For index, val in array
	{
		font := InStr(val, "(/bold)") ? "bold" : "", font .= InStr(val, "(/underline)") ? (font ? " " : "") "underline" : "", font := !font ? "norm" : font
		Gui, panel_dimensions: Font, % font
		val := StrReplace(StrReplace(StrReplace(val, "&&", "&"), "(/bold)"), "(/underline)"), val := StrReplace(val, "&", "&&")
		Gui, panel_dimensions: Add, Text, % align " HWNDhwnd Border", % header_offset && (index = 1) ? " " val : margins ? " " StrReplace(val, "`n", " `n ") " " : val
		Gui, panel_dimensions: Font, % "norm s"fSize
		WinGetPos,,, w, h, ahk_id %hwnd%
		height := (h > height) ? h : height
		width := (min_width && w < width || !min_width && w > width) ? w : width
		min_string := (w = width) ? val : min_string
	}

	Gui, panel_dimensions: Destroy
	;width := Format("{:0.0f}", width* 1.25)
	If min_width
		Return min_string
	While Mod(width, 2)
		width += 1
	While Mod(height, 2)
		height += 1
}

LLK_Progress(HWND_bar, key, HWND_control := "", key_wait := 1) ;HWND_bar = HWND of the progress bar, key = key that is held down to fill the progress bar, HWND_control = HWND of the button (to undo clipping)
{
	local

	start := A_TickCount
	While GetKeyState(key, "P")
	{
		GuiControl,, %HWND_bar%, % A_TickCount - start
		If (A_TickCount >= start + 600)
		{
			GuiControl,, %HWND_bar%, 0 ;reset the progress bar to 0
			If HWND_control
				GuiControl, movedraw, %HWND_control% ;redraw the button that was held down (otherwise the progress bar will remain on top of it)
			If key_wait
				KeyWait, % key
			Return 1
		}
		Sleep 20
	}
	GuiControl,, %HWND_bar%, 0
	If HWND_control
		GuiControl, movedraw, %HWND_control%
	Return 0
}

LLK_ToolTip(message, duration := 1, x := "", y := "", name := "", color := "White", size := "", align := "", trans := "", center := 0, background := "", center_text := 0)
{
	local
	global vars, settings

	If !name
		name := 1

	vars.tooltip.wait := 1

	If !size
		size := settings.general.fSize

	If Blank(trans)
		trans := 255

	If align
		align := " " align

	xPos := InStr(x, "+") || InStr(x, "+-") ? vars.general.xMouse + StrReplace(x, "+") : (x != "") ? x : vars.general.xMouse
	yPos := InStr(y, "+") || InStr(y, "+-") ? vars.general.yMouse + StrReplace(y, "+") : (y != "") ? y : vars.general.yMouse

	Gui, tooltip%name%: New, % "-DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border +E0x02000000 +E0x00080000 HWNDhwnd"
	Gui, tooltip%name%: Color, % Blank(background) ? "Black" : background
	Gui, tooltip%name%: Margin, % settings.general.fwidth / 2, 0
	WinSet, Transparent, % trans
	Gui, tooltip%name%: Font, % "s" size* (name = "update" ? 1.4 : 1) " cWhite", % vars.system.font
	vars.hwnd["tooltip" name] := hwnd

	Gui, tooltip%name%: Add, Text, % "c"color align (center_text ? " Center" : ""), % message
	Gui, tooltip%name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %hwnd%

	If center
		xPos -= w//2

	xPos := (xPos + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : (xPos < vars.monitor.x ? vars.monitor.x : xPos)
	If IsNumber(y)
		yPos := (yPos + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : yPos
	Else yPos := (yPos - h < vars.monitor.y) ? vars.monitor.y + h : yPos

	Gui, tooltip%name%: Show, % "NA x"xPos " y"yPos - (y = "" || InStr(y, "+") || InStr(y, "-") ? h : 0)
	LLK_Overlay(hwnd, "show",, "tooltip" name)
	If duration
		vars.tooltip[hwnd] := A_TickCount + duration*1000
	vars.tooltip.wait := 0
}

RGB_Convert(RGB)
{
	local

	If InStr(RGB, " ")
	{
		Loop, Parse, RGB, % A_Space
			If (A_Index < 4)
				converted .= Format("{:02X}", A_LoopField)
		Return converted
	}
	For index, val in ["red", "green", "blue"]
		%val% := Format("{:i}", "0x" SubStr(RGB, 1 + 2*(index - 1), 2))
	Return [red, green, blue]
}

RGB_Picker(RGB := "")
{
	local
	global vars, settings
	static palette, hwnd_r, hwnd_g, hwnd_b, hwnd_edit_r, hwnd_edit_g, hwnd_edit_b, hwnd_final, sliders

	If !palette
	{
		palette := []
		palette.Push(["330000", "660000", "990000", "CC0000", "FF0000", "FF3333", "FF6666", "FF9999", "FFCCCC"])
		palette.Push(["331900", "663300", "994C00", "CC6600", "FF8000", "FF9933", "FFB266", "FFCC99", "FFE5CC"])
		palette.Push(["333300", "666600", "999900", "CCCC00", "FFFF00", "FFFF33", "FFFF66", "FFFF99", "FFFFCC"])
		palette.Push(["193300", "336600", "4C9900", "66CC00", "80FF00", "99FF33", "B2FF66", "CCFF99", "E5FFCC"])
		palette.Push(["003300", "006600", "009900", "00CC00", "00FF00", "33FF33", "66FF66", "99FF99", "CCFFCC"])
		palette.Push(["003319", "006633", "00994C", "00CC66", "00FF80", "33FF99", "66FFB2", "99FFCC", "CCFFE5"])
		palette.Push(["003333", "006666", "009999", "00CCCC", "00FFFF", "33FFFF", "66FFFF", "99FFFF", "CCFFFF"])
		palette.Push(["001933", "003366", "004C99", "0066CC", "0080FF", "3399FF", "66B2FF", "99CCFF", "CCE5FF"])
		palette.Push(["000033", "000066", "000099", "0000CC", "0000FF", "3333FF", "6666FF", "9999FF", "CCCCFF"])
		palette.Push(["190033", "330066", "4C0099", "6600CC", "7F00FF", "9933FF", "B266FF", "CC99FF", "E5CCFF"])
		palette.Push(["330033", "660066", "990099", "CC00CC", "FF00FF", "FF33FF", "FF66FF", "FF99FF", "FFCCFF"])
		palette.Push(["330019", "660033", "99004C", "CC0066", "FF007F", "FF3399", "FF66B2", "FF99CC", "FFCCE5"])
		palette.Push(["000000", "202020", "404040", "606060", "808080", "A0A0A0", "C0C0C0", "E0E0E0", "FFFFFF"])
	}

	If (A_Gui = "RGB_palette")
	{
		Loop, Parse, % "rgb"
			If (RGB = hwnd_%A_LoopField%)
				GuiControl,, % hwnd_edit_%A_LoopField%, % (input := LLK_ControlGet(RGB))
			Else If (RGB = hwnd_edit_%A_LoopField%)
			{
				If ((input := LLK_ControlGet(RGB)) > 255)
				{
					GuiControl, -gRGB_Picker, % RGB
					GuiControl,, % RGB, % (input := 255)
					GuiControl, +gRGB_Picker, % RGB
				}
				GuiControl,, % hwnd_%A_LoopField%, % input
			}
		Return
	}

	hwnd_GUI := {}
	Gui, RGB_palette: New, -Caption -DPIScale +LastFound +ToolWindow +AlwaysOnTop +Border HWNDhwnd +E0x02000000 +E0x00080000 HWNDhwnd_palette
	Gui, RGB_palette: Color, Black
	Gui, RGB_palette: Font, % "s" settings.general.fSize " cWhite", % vars.system.font
	Gui, RGB_palette: Margin, % settings.general.fWidth, % settings.general.fWidth

	For index0, val0 in palette
		For index, val in val0
		{
			style := (A_Index = 1) ? "Section " (index0 != 1 ? "ys x+-1" : "") : "xs y+" (LLK_IsBetween(index, 5, 6) ? settings.general.fWidth / 5 : -1), columns := index0
			Gui, RGB_palette: Add, Text, % style " Center 0x200 BackgroundTrans HWNDhwnd_" val " w" settings.general.fWidth * 2 " h" settings.general.fWidth * 2 " c" (index >= 5 ? "Black" : "White"), % (RGB = val) ? "X" : ""
			If (RGB = val)
				marked := val
			Gui, RGB_palette: Add, Progress, % "xp yp Disabled Background646464 c" val " w" settings.general.fWidth * 2 " h" settings.general.fWidth * 2 " HWNDhwnd", 100
			hwnd_GUI[hwnd] := """" val """"
		}

	For index, val in RGB_Convert(RGB)
	{
		letter := (index = 1 ? "R" : (index = 2 ? "G" : "B"))
		Gui, RGB_palette: Add, Text, % "Section Border Center " (index = 1 ? "x" settings.general.fWidth " y+-1" : "xs y+-1") " w" settings.general.fWidth*3, % letter
		Gui, RGB_palette: Add, Slider, % "ys x+-1 hp Border Range0-255 Tooltip gRGB_Picker HWNDhwnd_" letter " w" settings.general.fWidth*20 - 9, % val
		Gui, RGB_palette: Font, % "s" settings.general.fSize - 4
		Gui, RGB_palette: Add, Edit, % "ys Number Right Limit3 x+-1 hp cBlack gRGB_Picker HWNDhwnd_edit_" letter " w" settings.general.fWidth*3 - 1, % val
		Gui, RGB_palette: Font, % "s" settings.general.fSize
	}
	Gui, RGB_palette: Add, Progress, % "Disabled xs y+-1 Section hp HWNDhwnd_final Background646464 c" (Blank(RGB) ? "000000" : RGB) " w" settings.general.fWidth*3, 100
	Gui, RGB_palette: Add, Text, % "ys x+-1 Border HWNDhwnd_save 0x200", % " " Lang_Trans("global_apply") " "

	Gui, RGB_palette: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %hwnd_palette%
	xPos := vars.general.xMouse - (vars.general.xMouse - vars.monitor.x + w >= vars.monitor.w ? w - settings.general.fWidth : settings.general.fWidth)
	yPos := vars.general.yMouse - (vars.general.yMouse - vars.monitor.y + h >= vars.monitor.h ? h - settings.general.fWidth : settings.general.fWidth)

	ControlFocus,, ahk_id %hwnd_save%
	Gui, RGB_palette: Show, % "x" xPos " y" yPos
	While (vars.general.wMouse != hwnd_palette) && !timeout
	{
		If !start
			start := A_TickCount
		If (A_TickCount >= start + 1000) && (vars.general.wMouse != hwnd_palette)
			timeout := 1
		Sleep 10
	}
	While Blank(picked_rgb) && (vars.general.wMouse = hwnd_palette)
	{
		KeyWait, LButton, D T0.1
		If !ErrorLevel && hwnd_GUI.HasKey(vars.general.cMouse)
			hover_last := vars.general.cMouse, rgb := StrReplace(hwnd_GUI[hover_last], """")
		Else If !ErrorLevel && (vars.general.cMouse = hwnd_save)
		{
			picked_rgb := current_rgb
		}
		Else
		{
			current_rgb := ""
			Loop, Parse, % "rgb"
				current_rgb .= Format("{:02X}", LLK_ControlGet(hwnd_%A_LoopField%))
			GuiControl, +c%current_rgb%, % hwnd_final
			If (current_rgb != marked)
				GuiControl, Text, % hwnd_%marked%, % ""
			If (hwnd_%current_rgb%)
			{
				GuiControl, Text, % hwnd_%current_rgb%, % "X"
				marked := current_rgb
			}
			Sleep 10
			Continue
		}
		KeyWait, LButton
		If (rgb != rgb_last)
		{
			rgb_last := rgb, sliders := RGB_Convert(rgb)
			For index, val in ["r", "g", "b"]
			{
				GuiControl,, % hwnd_%val%, % sliders[index]
				GuiControl,, % hwnd_edit_%val%, % sliders[index]
				GuiControl, Text, % hwnd_%marked%, % ""
				GuiControl, Text, % hwnd_%rgb%, % "X"
				marked := rgb
			}
		}
	}
	KeyWait, LButton
	Gui, RGB_palette: Destroy
	Return picked_rgb
}

ToolTip_Mouse(mode := "", timeout := 0)
{
	local
	global vars, settings
	static name, start

	If mode
	{
		If (mode = "reset")
			name := "", start := ""
		Else
		{
			vars.tooltip_mouse := {"name": mode, "timeout": timeout}
			SetTimer, ToolTip_Mouse, 10
		}
		Return
	}

	Switch vars.tooltip_mouse.name
	{
		Case "chromatics":
			text := Lang_Trans("omnikey_chromes") . "`n" . Lang_Trans("omnikey_escape")
			If GetKeyState("Space", "P") ;GetKeyState("Ctrl", "P") && GetKeyState("v", "P")
			{
				SetTimer, ToolTip_Mouse, Delete
				KeyWait, Space
				Sleep, 100
				SendInput, % "^{a}{BS}" vars.omnikey.item.sockets "{TAB}" vars.omnikey.item.str "{TAB}" vars.omnikey.item.dex "{TAB}" vars.omnikey.item.int "{TAB}{TAB}"
				vars.tooltip_mouse := ""
			}
		Case "cluster":
			text := Lang_Trans("omnikey_clustersearch") . "`n" . Lang_Trans("omnikey_escape")
			If GetKeyState("Control", "P") && GetKeyState("F", "P")
			{
				SetTimer, ToolTip_Mouse, Delete
				Clipboard := vars.omnikey.item.cluster_enchant
				KeyWait, F
				Sleep, 100
				SendInput, ^{a}^{v}
				Sleep, 100
				vars.tooltip_mouse := ""
			}
		Case "searchstring":
			text := Lang_Trans("omnikey_scroll") . " " . (InStr(vars.searchstrings.clipboard, ";") ? "" : vars.searchstrings.active.3 "/" vars.searchstrings.active.4) . "`n" . Lang_Trans("omnikey_escape")
		Case "killtracker":
			text := Lang_Trans("maptracker_kills")
		Case "lab":
			text := "-> " . Lang_Trans("omnikey_labimport") . "`n-> " . Lang_Trans("omnikey_labimport", 2) . "`n-> " . Lang_Trans("omnikey_labimport", 3) . "`n-> " . Lang_Trans("omnikey_labimport", 4) . "`n-> " . Lang_Trans("omnikey_labimport", 5) . "`n" . Lang_Trans("omnikey_escape")
	}

	If vars.tooltip_mouse.timeout && WinActive("ahk_group poe_window") && IsNumber(start) && (A_TickCount >= start + 1000) || GetKeyState("ESC", "P") && (name != "killtracker") || !vars.tooltip_mouse
	{
		Gui, tooltip_mouse: Destroy
		vars.hwnd.Delete("tooltip_mouse"), name := "", start := "", vars.tooltip_mouse := ""
		SetTimer, ToolTip_Mouse, Delete
		Return
	}

	If vars.hwnd.tooltip_mouse.main && !WinExist("ahk_id " vars.hwnd.tooltip_mouse.main) || (name != vars.tooltip_mouse.name)
	{
		start := A_TickCount
		Gui, tooltip_mouse: New, % "-DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd +E0x02000000 +E0x00080000"
		Gui, tooltip_mouse: Color, Black
		Gui, tooltip_mouse: Margin, % settings.general.fwidth / 2, 0
		WinSet, Transparent, 255
		Gui, tooltip_mouse: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
		Gui, tooltip_mouse: Add, Text, % "HWNDhwnd1"(vars.tooltip_mouse.name = "searchstring" ? " w"settings.general.fWidth*14 : ""), % text
		vars.hwnd.tooltip_mouse := {"main": hwnd, "text": hwnd1}
	}

	name := vars.tooltip_mouse.name
	MouseGetPos, xPos, yPos
	Gui, tooltip_mouse: Show, % "NA x"xPos + settings.general.fWidth*3 " y"yPos
}
