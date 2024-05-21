Init_GUI(mode := "")
{
	local
	global vars, settings

	update := vars.update, settings.gui := {"oToolbar": LLK_IniRead("ini\config.ini", "UI", "toolbar-orientation", "horizontal"), "sToolbar": LLK_IniRead("ini\config.ini", "UI", "toolbar-size", Round(vars.monitor.h / 72))}, orientation := settings.gui.oToolbar, size := settings.gui.sToolbar, hide := settings.general.hide_toolbar, margin := settings.general.fWidth/6
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
	Gui, LLK_panel: Add, Pic, % style " Section Border BackgroundTrans HWNDhwnd0 " (orientation = "horizontal" ? "h" height/2 - 1 " w-1" : "w" height/2 - 1 " h-1"), % "img\GUI\restart.png"
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

	If (mode = "refresh") || GetKeyState(settings.hotkeys.tab, "P")
	{
		LLK_Overlay(vars.hwnd.LLK_panel.main, "show")
		If hide && !GetKeyState(settings.hotkeys.tab, "P")
		{
			vars.toolbar.drag := 1
			SetTimer, GuiToolbarHide, -1000
		}
	}
}

GuiButton(name := "", x := "", y := "")
{
	local
	global vars, settings

	If WinExist("ahk_id "vars.hwnd[name "_button"].main)
		LLK_Overlay(vars.hwnd[name "_button"].main, "destroy")
	Gui, %name%_button: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd" (!Blank(x) || !Blank(y) ? " +E0x20" : "") ; +E0x02000000 +E0x00080000
	Gui, %name%_button: Margin, % (name = "leveltracker") ? 2 : 0, % (name = "leveltracker") ? 2 : 0
	Gui, %name%_button: Color, % (name = "leveltracker") ? "Aqua" : "Black"
	If (name = "leveltracker")
		WinSet, TransColor, Aqua
	Else WinSet, Trans, 255
	vars.hwnd[name "_button"] := {"main": hwnd}

	Gui, %name%_button: Add, Picture, % "BackgroundTrans Border HWNDhwnd g"name " w"settings[name].sButton " h-1", % "img\GUI\"name (name = "leveltracker" && !vars.hwnd.leveltracker.main ? "0" : "") ".jpg"
	vars.hwnd[name "_button"].img := hwnd
	Gui, %name%_button: Show, NA x10000 y10000
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd[name "_button"].main

	If !Blank(settings[name].xButton)
	{
		settings[name].xButton := (settings[name].xButton < 0) ? vars.client.x - vars.monitor.x : settings[name].xButton, settings[name].yButton := (settings[name].yButton < 0) ? vars.client.y - vars.monitor.y : settings[name].yButton
		xPos := (settings[name].xButton > vars.monitor.w/2 - 1) ? settings[name].xButton - w + 1 : settings[name].xButton
		xPos := (xPos + (w - 1) > vars.monitor.w - 1) ? vars.monitor.w - 1 - w : xPos ;prevent panel from leaving screen
		yPos := (settings[name].yButton > vars.monitor.h/2 - 1) ? settings[name].yButton - h + 1 : settings[name].yButton
		yPos := (yPos + (h - 1) > vars.monitor.h - 1) ? vars.monitor.h - 1 - h : yPos ;prevent panel from leaving screen
	}
	Else xPos := vars.client.x - vars.monitor.x, yPos := vars.client.y - vars.monitor.y

	Gui, %name%_button: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
	LLK_Overlay(vars.hwnd[name "_button"].main, "show",, name "_button")
}

GuiClientFiller(mode := "") ;creates a black full-screen GUI to fill blank space between the client and monitor edges when using custom resolutions
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
		WinWait, % "ahk_id " vars.hwnd.ClientFiller
		WinSet, AlwaysOnTop, Off, % "ahk_id " vars.hwnd.poe_client
	}
}

GuiName(GuiHWND)
{
	local
	global vars

	For index, val in vars.GUI
		If !Blank(LLK_HasVal(val, GuiHWND))
			Return val.name
}

GuiToolbarButtons(cHWND, hotkey)
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
				IniWrite, % xPos, ini\config.ini, UI, button xcoord
				IniWrite, % yPos, ini\config.ini, UI, button ycoord
				settings.general.xButton := xPos, settings.general.yButton := yPos
				Init_GUI()
				WinActivate, ahk_group poe_window
				vars.toolbar.drag := 0
				Return
			}
		}
		vars.toolbar.drag := 0

		If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main) || WinExist("ahk_id " vars.hwnd.searchstrings_menu.main) || WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main)
			LLK_ToolTip(LangTrans("global_configwindow"), 2,,,, "yellow")
		Else If (hotkey = 2)
		{
			settings.gui.oToolbar := (settings.gui.oToolbar = "horizontal") ? "vertical" : "horizontal"
			IniWrite, % settings.gui.oToolbar, ini\config.ini, UI, toolbar-orientation
			Init_GUI("refresh")
		}
		Else If WinExist("ahk_id "vars.hwnd.settings.main)
			Settings_menuClose()
		Else Settings_menu("general",, 0)
	}
	Else If InStr(check, "restart")
	{
		If LLK_Progress(vars.hwnd.LLK_panel.restart_bar, "LButton")
		{
			If GetKeyState(settings.hotkeys.tab, "P")
			{
				LLK_ToolTip(LangTrans("global_releasekey") " " settings.hotkeys.tab, 10000)
				KeyWait, % settings.hotkeys.tab
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
			If GetKeyState(settings.hotkeys.tab, "P")
			{
				LLK_ToolTip(LangTrans("global_releasekey") " "  settings.hotkeys.tab, 10000)
				KeyWait, % settings.hotkeys.tab
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

GuiToolbarHide()
{
	local
	global vars

	LLK_Overlay(vars.hwnd.LLK_panel.main, "hide"), vars.toolbar.drag := 0
}
