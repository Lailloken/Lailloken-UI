Init_GUI(name := "")
{
	local
	global vars, settings
	
	If !IsObject(vars.GUI)
		vars.GUI := []
	update := vars.update
	If !name || (name = "LLK_panel")
	{
		Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
		Gui, LLK_panel: Margin, % settings.general.fWidth/4, 0
		Gui, LLK_panel: Color, % !IsNumber(update.1) || (update.1 = 0) ? "Black" : (update.1 > 0) ? "Green" : "Maroon"
		Gui, LLK_panel: Font, % "s"settings.general.fSize " cWhite underline", % vars.system.font
		vars.hwnd.LLK_panel := hwnd
		
		Gui, LLK_panel: Add, Text, Section Center BackgroundTrans gSettings_general2, % "LLK-UI"
		Gui, LLK_panel: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.LLK_panel
		
		xPos := (settings.general.xButton > vars.monitor.w / 2 - 1) ? settings.general.xButton - w + 1 : settings.general.xButton ;apply right-alignment if applicable (i.e. if button is on the right half of monitor)
		xPos := (xPos + (w - 1) > vars.monitor.w - 1) ? vars.monitor.w - 1 - w : xPos ;correct the coordinates if panel ends up out of monitor-bounds
		
		yPos := (settings.general.yButton > vars.monitor.h / 2 - 1) ? settings.general.yButton - h + 1 : settings.general.yButton ;apply top-alignment if applicable (i.e. if button is on the top half of monitor)
		yPos := (yPos + (h - 1) > vars.monitor.h - 1) ? vars.monitor.h - 1 - h : yPos ;correct the coordinates if panel ends up out of monitor-bounds
		
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
	LLK_Overlay(vars.hwnd[name "_button"].main, "show")
}
