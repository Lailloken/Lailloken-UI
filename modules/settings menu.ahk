Settings_betrayal()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Betrayal-Info">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd0 x+"2*settings.general.fWidth, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb website</a>
	
	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_betrayal2 HWNDhwnd Checked"settings.features.betrayal, % "enable the betrayal-info overlay"
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_betrayal enable"] := hwnd, vars.hwnd.help_tooltips["settings_rgb website"] := hwnd0
	If !settings.features.betrayal
		Return
	
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_betrayal2 HWNDhwnd Checked"settings.betrayal.ruthless, % "ruthless rewards && highlighting"
	vars.hwnd.settings.ruthless := vars.hwnd.help_tooltips["settings_betrayal ruthless"] := hwnd

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "image-recognition:"
	Gui, %GUI%: Font, % "norm"

	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans Border gSettings_betrayal2 HWNDhwnd", % " open img folder "
	vars.hwnd.settings.folder := hwnd, vars.hwnd.help_tooltips["settings_betrayal folder"] := hwnd

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "ui settings:"
	Gui, %GUI%: Font, % "norm"

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", text-size:
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/2 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*2, % "–"
	vars.hwnd.settings.mFont := hwnd, vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*3, % settings.betrayal.fSize
	vars.hwnd.settings.rFont := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.pFont := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", reward-colors:
	Loop 3
	{
		Gui, %GUI%: Add, Text, % "ys x+"(A_Index = 1 ? settings.general.fWidth/2 : settings.general.fWidth/4) " Center HWNDhwnd gSettings_betrayal2 Border c"settings.betrayal.colors[A_Index], % " tier " A_Index " "
		handle .= "|"
		vars.hwnd.settings["tier"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_betrayal color"] := hwnd0, vars.hwnd.help_tooltips["settings_betrayal color"handle] := hwnd
	}

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "reward customization:"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
	vars.hwnd.help_tooltips["settings_betrayal rewards"] := hwnd
	Gui, %GUI%: Font, % "norm"

	For member in vars.betrayal.members
	{
		If (A_Index = 1)
			pos := "Section xs"
		Else If Mod(A_Index - 1, 6)
			pos := "xs y+"settings.general.fWidth/4
		Else pos := "Section ys x+"settings.general.fWidth/4
		Gui, %GUI%: Add, Text, % pos " Border gSettings_betrayal2 HWNDhwnd w"9* settings.general.fWidth, % " " member
		vars.hwnd.settings[member] := hwnd
	}
}

Settings_betrayal2(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), divisions := {"t": "transportation", "f": "fortification", "r": "research", "i": "intervention"}

	If (check = "enable")
	{
		settings.features.betrayal := LLK_ControlGet(cHWND)
		IniWrite, % settings.features.betrayal, ini\config.ini, Features, enable betrayal-info
		Settings_menu("betrayal-info")
	}
	Else If (check = "ruthless")
	{
		settings.betrayal.ruthless := LLK_ControlGet(cHWND)
		IniWrite, % settings.betrayal.ruthless, ini\betrayal info.ini, settings, ruthless
		Init_betrayal()
	}
	Else If (check = "folder")
	{
		If FileExist("img\Recognition ("vars.client.h "p)\Betrayal\")
			Run, % "explore img\Recognition ("vars.client.h "p)\Betrayal\"
		Else LLK_ToolTip("folder doesn't exist")
	}
	Else If InStr(check, "font")
	{
		While GetKeyState("LButton", "P")
		{
			If (SubStr(check, 1, 1) = "m") && (settings.betrayal.fSize > 6)
				settings.betrayal.fSize -= 1
			Else If (SubStr(check, 1, 1) = "r")
				settings.betrayal.fSize := settings.general.fSize
			Else If (SubStr(check, 1, 1) = "p")
				settings.betrayal.fSize += 1
			GuiControl, text, % vars.hwnd.settings.rFont, % settings.betrayal.fSize
			Sleep 150
		}
		IniWrite, % settings.betrayal.fSize, ini\betrayal info.ini, settings, font-size
		LLK_FontDimensions(settings.betrayal.fSize, height, width), settings.betrayal.fWidth := width, settings.betrayal.fHeight := height
		BetrayalInfo("aisling"), vars.tooltip[vars.hwnd.betrayal_info.main] := A_TickCount + 1000 ;use the vars.tooltip object to destroy the GUI after a delay (via Loop_main())
	}
	Else If InStr(check, "tier")
	{
		If (vars.system.click = 1)
		{
			If !(StrLen(Clipboard) = 6 || (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#")) || (Clipboard = "202020" || Clipboard = "#202020")
			{
				LLK_ToolTip("invalid rgb-code in clipboard", 1.5,,,, "red")
				Return
			}
			color := (StrLen(Clipboard) = 7) ? SubStr(Clipboard, 2) : Clipboard
		}
		Else color := settings.betrayal.dColors[StrReplace(check, "tier")]
		GuiControl, +c%color%, % cHWND
		GuiControl, movedraw, % cHWND
		IniWrite, % color, ini\betrayal info.ini, settings, % "rank "StrReplace(check, "tier") " color"
		settings.betrayal.colors[StrReplace(check, "tier")] := color
	}
	Else If vars.betrayal.members.HasKey(check)
	{
		BetrayalInfo(check)
		KeyWait, LButton
		vars.hwnd.betrayal_info.active := ""
		LLK_Overlay(vars.hwnd.betrayal_info.main, "destroy")
	}
	Else LLK_ToolTip("no action")
}

Settings_cheatsheets()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main, Init_cheatsheets()
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Cheat-sheet-Overlay-Toolkit">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd0 x+"2*settings.general.fWidth, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb website</a>
	
	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_cheatsheets2 HWNDhwnd Checked"settings.features.cheatsheets, % "enable the cheat-sheet toolkit"
	vars.hwnd.settings.feature := hwnd, vars.hwnd.help_tooltips["settings_rgb website"] := hwnd0, vars.hwnd.help_tooltips["settings_cheatsheets enable"] := hwnd
	If !settings.features.cheatsheets
		Return

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "hotkey settings:"
	Gui, %GUI%: Font, % "norm"
	
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "omni-key modifier: "
	Loop, Parse, % "alt, ctrl, shift", `,, %A_Space%
	{
		Gui, %GUI%: Add, Radio, % "ys x+0 hp HWNDhwnd gSettings_cheatsheets2 checked"(settings.cheatsheets.modifier = A_LoopField ? 1 : 0), % A_LoopField
		handle .= "|", vars.hwnd.settings["modifier_"A_LoopField] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets modifier-key"] := hwnd0, vars.hwnd.help_tooltips["settings_cheatsheets modifier-key"handle] := hwnd
	}

	If vars.cheatsheets.count_advanced
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % "ui settings: advanced sheets"
		Gui, %GUI%: Font, norm

		Loop 4
		{
			style := (A_Index = 1) ? "xs Section" : "ys x+"settings.general.fWidth/4, handle1 .= "|"
			Gui, %GUI%: Add, Text, % style " Center Border HWNDhwnd gSettings_cheatsheets2 c"settings.cheatsheets.colors[A_Index], % " color "A_Index " "
			vars.hwnd.settings["color"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets color"handle1] := hwnd
		}

		Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans HWNDhwnd0", % "text-size: "
		Gui, %GUI%: Add, Text, % "ys x+0 Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := hwnd, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*3, % settings.cheatsheets.fSize
		vars.hwnd.settings.font_reset := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.font_plus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "create new sheet:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans", % "name: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 w"settings.general.fWidth*10 " cBlack HWNDhwnd",
	vars.hwnd.settings.name := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd0 x+"settings.general.fWidth, % "type: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, DDL, % "ys hp x+0 w"settings.general.fWidth*8 " r10 cBlack HWNDhwnd", % "images||app|advanced|"
	vars.hwnd.help_tooltips["settings_cheatsheets types"] := hwnd0, vars.hwnd.settings.type := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets types|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "ys hp Border gSettings_cheatsheets2 HWNDhwnd", % " add "
	vars.hwnd.settings.add := hwnd, handle := ""

	For cheatsheet in vars.cheatsheets.list
	{
		If (A_Index = 1)
		{
			Gui, %GUI%: Font, bold underline
			Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % "list of available cheat-sheets:"
			Gui, %GUI%: Font, norm
		}
		
		If !IsNumber(vars.cheatsheets.list[cheatsheet].enable)
			vars.cheatsheets.list[cheatsheet].enable := LLK_IniRead("cheat-sheets\"cheatsheet "\info.ini", "general", "enable", 1)
		color := !vars.cheatsheets.list[cheatsheet].enable ? " cGray" : !FileExist("cheat-sheets\"cheatsheet "\[check].*") ? " cRed" : "", handle .= "|"
		Gui, %GUI%: Add, Text, % "xs Section border HWNDhwnd y+"settings.general.fSize*0.4 color (vars.cheatsheets.list[cheatsheet].enable ? " gSettings_cheatsheets2" : ""), % " cal "
		vars.hwnd.settings["calibrate_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets calibrate"handle] := (color = " cGray") ? "" : hwnd
		color := !vars.cheatsheets.list[cheatsheet].enable ? " cGray" : !vars.cheatsheets.list[cheatsheet].x1 ? " cRed" : ""
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border HWNDhwnd" color (vars.cheatsheets.list[cheatsheet].enable ? " gSettings_cheatsheets2" : ""), % " test "
		vars.hwnd.settings["test_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets test"handle] := (color = " cGray") ? "" : hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border HWNDhwnd gSettings_cheatsheets2", % " edit "
		vars.hwnd.settings["edit_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border BackgroundTrans gSettings_cheatsheets2 HWNDhwnd0", % " del "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp border BackgroundBlack Disabled cRed range0-500 HWNDhwnd", 0
		vars.hwnd.settings["delbar_"cheatsheet] := vars.hwnd.help_tooltips["settings_cheatsheets delete"handle] := hwnd, vars.hwnd.settings["delete_"cheatsheet] := hwnd0
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " w"settings.general.fWidth*2 " Center gSettings_cheatsheets2 Border HWNDhwnd", % "?"
		vars.hwnd.settings["info_"cheatsheet] := vars.hwnd.help_tooltips["settings_cheatsheets info"handle] := hwnd
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_cheatsheets2 HWNDhwnd c"(!vars.cheatsheets.list[cheatsheet].enable ? "Gray" : "White") " Checked"vars.cheatsheets.list[cheatsheet].enable, % cheatsheet
		vars.hwnd.settings["enable_"cheatsheet] := vars.hwnd.help_tooltips["settings_cheatsheets toggle"handle] := hwnd
	}
}

Settings_cheatsheets2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	
	If (check = "feature") ;toggling the feature on/off
	{
		If !FileExist("cheat-sheets\")
		{
			FileCreateDir, cheat-sheets
			Sleep 250
		}
		If !FileExist("cheat-sheets\")
		{
			LLK_FilePermissionError("create", "cheat-sheets")
			GuiControl,, % cHWND, 0
			Return
		}
		IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, features, enable cheat-sheets
		settings.features.cheatsheets := LLK_ControlGet(cHWND)
		If !settings.features.cheatsheets
		{
			LLK_Overlay(vars.hwnd.cheatsheet.main, "hide")
			LLK_Overlay(vars.hwnd.cheatsheet_menu.main, "hide")
		}
		Settings_menu("cheat-sheets")
	}
	Else If (check = "add") ;adding a new sheet
		CheatsheetAdd(LLK_ControlGet(vars.hwnd.settings.name), LLK_ControlGet(vars.hwnd.settings.type))
	Else If (check = "quick") ;toggling the quick-access feature
	{
		settings.cheatsheets.quick := LLK_ControlGet(cHWND)
		IniWrite, % settings.cheatsheets.quick, ini\cheat-sheets.ini, settings, quick access
	}
	Else If InStr(check, "modifier_") ;setting the omni-key modifier
	{
		If (settings.cheatsheets.modifier = control)
			Return
		settings.cheatsheets.modifier := control
		IniWrite, % control, ini\cheat-sheets.ini, settings, modifier-key
	}
	Else If InStr(check, "color") ;applying a text-color
	{
		control := StrReplace(check, "color")
		If (vars.system.click = 1)
		{
			If !(StrLen(Clipboard) = 6 || (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#"))
			{
				LLK_ToolTip("invalid rgb-code in clipboard", 1.5,,,, "red")
				Return
			}
			color := (StrLen(Clipboard) = 7) ? SubStr(Clipboard, 2) : Clipboard
		}
		Else color := settings.cheatsheets.dColors[control]
		GuiControl, +c%color%, % cHWND
		GuiControl, movedraw, % cHWND
		IniWrite, % color, ini\cheat-sheets.ini, UI, % "rank "control " color"
		settings.cheatsheets.colors[control] := color
	}
	Else If InStr(check, "font_") ;resizing the font
	{
		While GetKeyState("LButton", "P")
		{
			If (control = "minus") && (settings.cheatsheets.fSize > 6)
				settings.cheatsheets.fSize -= 1
			Else If (control = "reset")
				settings.cheatsheets.fSize := settings.general.fSize
			Else If (control = "plus")
				settings.cheatsheets.fSize += 1
			GuiControl, text, % vars.hwnd.settings.font_reset, % settings.cheatsheets.fSize
			Sleep 150
		}
		IniWrite, % settings.cheatsheets.fSize, ini\cheat-sheets.ini, settings, font-size
		LLK_FontDimensions(settings.cheatsheets.fSize, font_width, font_height), settings.cheatsheets.fWidth := font_width, settings.cheatsheets.fHeight := font_height
		LLK_ToolTip("sample text:`nle toucan has arrived", 2, vars.general.xMouse, vars.general.yMouse,,, settings.cheatsheets.fSize, "center")
	}
	Else If InStr(check, "calibrate_") ;clicking calibrate
	{
		pBitmap := Screenchecks_ImageRecalibrate()
		If (pBitmap > 0)
		{
			Gdip_SaveBitmapToFile(pBitmap, "cheat-sheets\"control "\[check].bmp", 100)
			Gdip_DisposeImage(pBitmap)
			IniDelete, % "cheat-sheets\"control "\info.ini", image search
			Settings_menu("cheat-sheets")
		}
	}
	Else If InStr(check, "test_")
	{
		If CheatsheetSearch(control)
		{
			;Settings_menu("cheat-sheets")
			GuiControl, +cWhite, % vars.hwnd.settings["test_"control]
			GuiControl, movedraw, % vars.hwnd.settings["test_"control]
			Init_cheatsheets()
			LLK_ToolTip("positive",,,,, "Lime")
		}
	}
	Else If InStr(check, "info_")
		CheatsheetInfo(control)
	Else If InStr(check, "edit_")
		CheatsheetMenu(control)
	Else If InStr(check, "delete_")
	{
		If LLK_Progress(vars.hwnd.settings["delbar_"control], "LButton", cHWND)
		{
			FileRemoveDir, % "cheat-sheets\"control "\", 1
			Settings_menu("cheat-sheets")
			KeyWait, LButton
		}
		Else Return
	}
	Else If InStr(check, "enable_")
	{
		vars.cheatsheets.list[control].enable := LLK_ControlGet(vars.hwnd.settings[check])
		IniWrite, % vars.cheatsheets.list[control].enable, % "cheat-sheets\"control "\info.ini", general, enable
		Settings_menu("cheat-sheets")
	}
	Else LLK_ToolTip("no action")
}

Settings_cloneframes()
{
	local
	global vars, settings

	Init_cloneframes()
	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames">wiki page</a>
	
	If (vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") || vars.log.file_location) && settings.features.pixelchecks
	{
		Gui, %GUI%: Font, underline bold
		Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "automatic toggling:"
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
		Gui, %GUI%: Font, norm
		vars.hwnd.help_tooltips["settings_cloneframes toggle-info"] := hwnd
	}

	If vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") && settings.features.pixelchecks
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.pixelchecks, hide outside the gamescreen
		vars.hwnd.settings.hide_menu := hwnd, vars.hwnd.help_tooltips["settings_cloneframes pixelchecks"] := hwnd
	}
	If vars.log.file_location
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.hide, hide in hideouts/towns
		vars.hwnd.settings.hide_town := hwnd, vars.hwnd.help_tooltips["settings_cloneframes hideout"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % "list of available clone-frames:"
	WinGetPos,,, width,, % "ahk_id " hwnd
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Border gSettings_cloneframes2 HWNDhwnd Center w"settings.general.fWidth*8.25, % "add new"
	vars.hwnd.settings.add := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new"] := hwnd
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default gSettings_cloneframes2 HWNDhwnd", % "ok"
	vars.hwnd.settings.add2 := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd w"width - settings.general.fWidth*9
	vars.hwnd.settings.name := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	For cloneframe, val in vars.cloneframes.list
	{
		If (cloneframe = "settings_cloneframe")
			continue
		Gui, %GUI%: Add, Text, % "xs w"settings.general.fWidth*4 " Section Border Center gSettings_cloneframes2 HWNDhwnd", % "edit"
		handle .= "|", vars.hwnd.settings["edit_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys hp x+"settings.general.fWidth/4 " w"settings.general.fWidth*4 " Border gSettings_cloneframes2 BackgroundTrans Center HWNDhwnd0", % "del"
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack range0-500 cRed HWNDhwnd", 0
		vars.hwnd.settings["delbar_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes delete"handle] := hwnd, vars.hwnd.settings["del_"cloneframe] := hwnd0
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_cloneframes2 HWNDhwnd Checked"val.enable " c"(val.enable ? "White" : "Gray"), % cloneframe
		vars.hwnd.settings["enable_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes toggle"handle] := hwnd
		Gui, %GUI%: Font, norm
	}

	If (vars.cloneframes.list.Count() = 1)
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % "clone-frame editing:"
	colors := ["3399FF", "DC3220", "Yellow"], handle := "", vars.hwnd.settings.edit_text := vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	Gui, %GUI%: Font, norm
	Loop 3
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/2 " Center BackgroundTrans Border cBlack w"settings.general.fWidth*3, % "f" A_Index
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd c"colors[A_Index], 100
		handle .= "|", vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	}
	Gui, %GUI%: Add, Text, % "xs Section c3399FFlue", % "source x/y: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.x + 4 - vars.monitor.x
	vars.hwnd.settings.xSource := vars.cloneframes.scroll.xSource := vars.hwnd.help_tooltips["settings_cloneframes scroll"] := hwnd
	ControlGetPos, x, y,,,, ahk_id %hwnd%
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.y + 4 - vars.monitor.y
	vars.hwnd.settings.ySource := vars.cloneframes.scroll.ySource := vars.hwnd.help_tooltips["settings_cloneframes scroll|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	
	Gui, %GUI%: Add, Text, % "ys cDC3220", % "w/h: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % 200
	vars.hwnd.settings.width := vars.cloneframes.scroll.width := vars.hwnd.help_tooltips["settings_cloneframes scroll||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % 200
	vars.hwnd.settings.height := vars.cloneframes.scroll.height := vars.hwnd.help_tooltips["settings_cloneframes scroll|||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "xs Section cYellow", % "target x/y: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x"x - 1 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % Format("{:0.0f}", vars.client.xc - 100 - vars.monitor.x)
	vars.hwnd.settings.xTarget := vars.cloneframes.scroll.xTarget := vars.hwnd.help_tooltips["settings_cloneframes scroll||||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.y + 13 - vars.monitor.y
	vars.hwnd.settings.yTarget := vars.cloneframes.scroll.yTarget := vars.hwnd.help_tooltips["settings_cloneframes scroll|||||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "ys", % "scale: "
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*3, 100
	vars.hwnd.settings.xScale := vars.cloneframes.scroll.xScale := vars.hwnd.help_tooltips["settings_cloneframes scroll||||||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*3, 100
	vars.hwnd.settings.yScale := vars.cloneframes.scroll.yScale := vars.hwnd.help_tooltips["settings_cloneframes scroll|||||||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "xs Section", % "opacity: "
	Gui, %GUI%: Add, Text, % "ys x+0 0x200 hp Border Center HWNDhwnd w"settings.general.fWidth*2, 5
	;Gui, %GUI%: Add, UpDown, % "ys hp Disabled range0-5 gSettings_cloneframes2 HWNDhwnd", 5
	vars.hwnd.settings.opacity := vars.cloneframes.scroll.opacity := vars.hwnd.help_tooltips["settings_cloneframes scroll||||||||"] := hwnd
	
	Gui, %GUI%: Add, Text, % "ys cGray Border HWNDhwnd", % " save "
	vars.hwnd.settings.save := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " cGray Border HWNDhwnd", % " discard "
	vars.hwnd.settings.discard := hwnd
}

/*
Settings_cloneframes()
{
	local
	global vars, settings

	Init_cloneframes()
	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames">wiki page</a>
	
	If (vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") || vars.log.file_location) && settings.features.pixelchecks
	{
		Gui, %GUI%: Font, underline bold
		Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "automatic toggling:"
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
		Gui, %GUI%: Font, norm
		vars.hwnd.help_tooltips["settings_cloneframes toggle-info"] := hwnd
	}

	If vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") && settings.features.pixelchecks
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.pixelchecks, hide outside the gamescreen
		vars.hwnd.settings.hide_menu := hwnd, vars.hwnd.help_tooltips["settings_cloneframes pixelchecks"] := hwnd
	}
	If vars.log.file_location
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.hide, hide in hideouts/towns
		vars.hwnd.settings.hide_town := hwnd, vars.hwnd.help_tooltips["settings_cloneframes hideout"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % "list of available clone-frames:"
	WinGetPos,,, width,, % "ahk_id " hwnd
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Border gSettings_cloneframes2 HWNDhwnd Center w"settings.general.fWidth*8.25, % "add new"
	vars.hwnd.settings.add := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new"] := hwnd
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default gSettings_cloneframes2 HWNDhwnd", % "ok"
	vars.hwnd.settings.add2 := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd w"width - settings.general.fWidth*9
	vars.hwnd.settings.name := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	For cloneframe, val in vars.cloneframes.list
	{
		If (cloneframe = "settings_cloneframe")
			continue
		Gui, %GUI%: Add, Text, % "xs w"settings.general.fWidth*4 " Section Border Center gSettings_cloneframes2 HWNDhwnd", % "edit"
		handle .= "|", vars.hwnd.settings["edit_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys hp x+"settings.general.fWidth/4 " w"settings.general.fWidth*4 " Border gSettings_cloneframes2 BackgroundTrans Center HWNDhwnd0", % "del"
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack range0-500 cRed HWNDhwnd", 0
		vars.hwnd.settings["delbar_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes delete"handle] := hwnd, vars.hwnd.settings["del_"cloneframe] := hwnd0
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_cloneframes2 HWNDhwnd Checked"val.enable " c"(val.enable ? "White" : "Gray"), % cloneframe
		vars.hwnd.settings["enable_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes toggle"handle] := hwnd
		Gui, %GUI%: Font, norm
	}

	If (vars.cloneframes.list.Count() = 1)
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % "clone-frame editing:"
	colors := ["3399FF", "DC3220", "Yellow"], handle := "", vars.hwnd.settings.edit_text := vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	Gui, %GUI%: Font, norm
	Loop 3
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/2 " Center BackgroundTrans Border cBlack w"settings.general.fWidth*3, % A_Index
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd c"colors[A_Index], 100
		handle .= "|", vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	}
	Gui, %GUI%: Add, Text, % "xs Section", % "scaling (%): "
	Gui, %GUI%: Add, Text, % "ys x+0 hp Center Border w"settings.general.fWidth*5
	Gui, %GUI%: Add, UpDown, % "ys hp range10-300 Disabled gSettings_cloneframes2 HWNDhwnd w"settings.general.fWidth, 100
	vars.hwnd.settings.xScale := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " hp Center Border w"settings.general.fWidth*5
	Gui, %GUI%: Add, UpDown, % "ys hp range10-300 Disabled gSettings_cloneframes2 HWNDhwnd w"settings.general.fWidth, 100
	vars.hwnd.settings.yScale := hwnd
	Gui, %GUI%: Add, Text, % "ys", % "opacity: "
	Gui, %GUI%: Add, Text, % "ys x+0 0x200 hp Border Center w"settings.general.fWidth*3,
	Gui, %GUI%: Add, UpDown, % "ys hp Disabled range0-5 gSettings_cloneframes2 HWNDhwnd", 5
	vars.hwnd.settings.opacity := hwnd
	;Gui, %GUI%: Add, UpDown, % "xs Section hp Disabled gSettings_cloneframes2 horz -16 HWNDhwnd range0-"vars.monitor.w-1 " w"settings.general.fWidth*2, 0
	;vars.hwnd.settings.xSource := hwnd
	;Gui, %GUI%: Add, UpDown, % "ys x+"settings.general.fWidth/4 " hp Disabled gSettings_cloneframes2 -16 HWNDhwnd range-"vars.monitor.h-1 "-0 w"settings.general.fWidth, 0
	;vars.hwnd.settings.ySource := hwnd
	Gui, %GUI%: Add, Text, % "xs Section cGray Border HWNDhwnd", % " save "
	vars.hwnd.settings.save := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " cGray Border HWNDhwnd", % " discard "
	vars.hwnd.settings.discard := hwnd

	;Gui, %GUI%: Add, UpDown, % "xs Section hp Disabled gSettings_cloneframes2 left horz -16 HWNDhwnd range1-"vars.monitor.w " w"settings.general.fWidth*2, 200
	;vars.hwnd.settings.width := hwnd
	;Gui, %GUI%: Add, UpDown, % "ys x+"settings.general.fWidth/4 " hp Disabled gSettings_cloneframes2 left -16 HWNDhwnd range-"vars.monitor.h "--1 w"settings.general.fWidth, -200
	;vars.hwnd.settings.height := hwnd
	
	;Gui, %GUI%: Add, UpDown, % "xs Section hp Disabled wp gSettings_cloneframes2 left horz -16 HWNDhwnd range0-"vars.monitor.w-1 " w"settings.general.fWidth*2, % vars.monitor.w/2 - 100
	;vars.hwnd.settings.xTarget := hwnd
	;Gui, %GUI%: Add, UpDown, % "ys x+"settings.general.fWidth/4 " hp Disabled gSettings_cloneframes2 left -16 HWNDhwnd range-"vars.monitor.h "--1 w"settings.general.fWidth, 0
	;vars.hwnd.settings.yTarget := hwnd
}
*/

Settings_cloneframes2(cHWND)
{
	local
	global vars, settings
	
	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), name := vars.cloneframes.editing

	If (check = "hide_menu")
	{
		settings.cloneframes.pixelchecks := LLK_ControlGet(cHWND)
		IniWrite, % settings.cloneframes.pixelchecks, ini\clone frames.ini, settings, enable pixel-check
	}
	Else If (check = "hide_town")
	{
		settings.cloneframes.hide := LLK_ControlGet(cHWND)
		IniWrite, % settings.cloneframes.hide, ini\clone frames.ini, settings, hide in hideout
	}
	Else If (check = "add" || check = "add2")
		CloneframesSettingsAdd()
	Else If InStr(check, "edit_")
		CloneframesSettingsRefresh(control)
	Else If InStr(check, "del_")
	{
		If vars.cloneframes.editing
		{
			LLK_ToolTip("exit edit-mode first", 1.5,,,, "red")
			Return
		}
		If LLK_Progress(vars.hwnd.settings["delbar_"control], "LButton", cHWND)
		{
			IniDelete, ini\clone frames.ini, % control
			Init_cloneframes()
			Settings_menu("clone-frames")
		}
		Else Return
	}
	Else If InStr(check, "enable_")
	{
		If vars.cloneframes.editing
		{
			LLK_ToolTip("exit edit-mode first", 1.5,,,, "red")
			GuiControl,, % cHWND, % vars.cloneframes.list[control].enable
			Return
		}
		vars.cloneframes.list[control].enable := LLK_ControlGet(cHWND)
		GuiControl, % "+c"(LLK_ControlGet(cHWND) ? "White" : "Gray"), % cHWND
		GuiControl, movedraw, % cHWND
		IniWrite, % vars.cloneframes.list[control].enable, ini\clone frames.ini, % control, enable
		Init_cloneframes()
	}
	Else If (check = "save")
		CloneframesSettingsSave()
	Else If (check = "discard")
		CloneframesSettingsRefresh()
	Else If (check = "opacity")
		vars.cloneframes.list[name].opacity := LLK_ControlGet(cHWND)
	Else LLK_ToolTip("no action")
}

Settings_general()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki">llk-ui wiki && setup guide</a>
	
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "script settings:"
	Gui, %GUI%: Font, norm
	
	Gui, %GUI%: Add, Checkbox, % "xs Section hp gSettings_general2 HWNDhwnd Checked" settings.general.kill[1], % "exit"
	vars.hwnd.settings.kill_timer := hwnd, vars.hwnd.help_tooltips["settings_kill timer"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fsize - 4 "norm"
	Gui, %GUI%: Add, Edit, % "ys x+0 hp cBlack Number gSettings_general2 Center Limit2 HWNDhwnd w"2* settings.general.fwidth, % settings.general.kill[2]
	vars.hwnd.settings.kill_timeout := hwnd, vars.hwnd.help_tooltips["settings_kill timer|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fsize
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd x+"settings.general.fwidth/2, % "minute" (settings.general.kill[2] = 1 ? "" : "s") " after closing the game   "
	vars.hwnd.settings.minutes := hwnd, vars.hwnd.help_tooltips["settings_kill timer||"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_general2 Checked"settings.features.browser, % "enable browser features"
	vars.hwnd.settings.browser := hwnd, vars.hwnd.help_tooltips["settings_browser features"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_general2 Checked"LLK_IniRead("ini\config.ini", "Settings", "enable CapsLock-toggling", 1), % "enable capslock-toggling"
	vars.hwnd.settings.capslock := hwnd, vars.hwnd.help_tooltips["settings_capslock toggling"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % "general text-size:"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd
	Gui, %GUI%: Add, Text, % "ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.settings.font_minus := hwnd, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "wp x+"settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*3, % settings.general.fSize
	vars.hwnd.settings.font_reset := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "wp x+"settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	
	If vars.log.file_location
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd c"(vars.log.level ? "Lime" : settings.general.character? "Yellow" : "Red"), % "active character: "
		vars.hwnd.settings.character_text := hwnd, vars.hwnd.help_tooltips["settings_active character status"] := hwnd
		Gui, %GUI%: Font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+0 cBlack wp r1 hp gSettings_general2 HWNDhwnd", % LLK_StringCase(settings.general.character)
		If vars.log.level
			Gui, %GUI%: Add, Text, % "ys x+-1 hp 0x200 Center Border", % " lvl " vars.log.level " "
		Gui, %GUI%: Font, % "s"settings.general.fSize
		vars.hwnd.settings.character := hwnd, vars.hwnd.help_tooltips["settings_active character"] := hwnd
		Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default gSettings_general2 HWNDhwnd", % "save"
		vars.hwnd.settings.save_character := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "game-client settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd gSettings_general2", % " apply && restart "
	vars.hwnd.settings.apply := hwnd, check := ""
	
	Loop, Files, data\lang_*
		parse := SubStr(A_LoopFileName, InStr(A_LoopFileName, "_") + 1), parse := LLK_StringCase(StrReplace(parse, ".txt")), check .= parse "|"

	If (LLK_InStrCount(check, "|") > 1)
	{
		parse := 0
		Loop, Parse, check, |
			parse := (StrLen(A_LoopField) > parse) ? StrLen(A_LoopField) : parse
		Gui, %GUI%: Add, Text, % "xs Section", % "language: "
		Gui, %GUI%: Font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, DDL, % "ys x+0 HWNDhwnd0 gSettings_general2 r"LLK_InStrCount(check, "|") " w"settings.general.fWidth * parse + settings.general.fWidth, % StrReplace(check, settings.general.lang, settings.general.lang "|")
		Gui, %GUI%: Font, % "s"settings.general.fSize
		Gui, %GUI%: Add, Text, % "ys HWNDhwnd x+"settings.general.fWidth, (translators)
		vars.hwnd.settings.language := hwnd0, vars.hwnd.help_tooltips["settings_lang translators"] := hwnd
	}

	Gui, %GUI%: Add, Text, % "xs Section", % "detected mode: "
	Gui, %GUI%: Add, Text, % "ys x+0 cAqua HWNDhwnd w"settings.general.fwidth* 20, % (vars.client.fullscreen = "true") ? "windowed fullscreen" : !vars.client.borderless ? "windowed" : "borderless windowed"
	vars.hwnd.settings.window_mode := hwnd
	
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", force resolution:
	vars.hwnd.help_tooltips["settings_force resolution"] := hwnd
	If (vars.client.fullscreen = "true")
	{
		Gui, %GUI%: Add, Text, % "ys hp BackgroundTrans HWNDhwnd x+"settings.general.fwidth/2, % vars.monitor.w
		vars.hwnd.settings.custom_width := hwnd, vars.hwnd.help_tooltips["settings_force resolution|"] := hwnd
	}
	Else
	{
		Gui, %GUI%: Font, % "s"settings.general.fsize - 4
		Gui, %GUI%: Add, Edit, % "ys hp Limit4 Number Center cBlack BackgroundTrans gSettings_general2 HWNDhwnd x+"settings.general.fwidth/2 " w"settings.general.fWidth*4, % vars.client.w0
		vars.hwnd.settings.custom_width := hwnd, vars.hwnd.help_tooltips["settings_force resolution||"] := hwnd
		Gui, %GUI%: Font, % "s"settings.general.fsize
	}
	Gui, %GUI%: Add, Text, % "ys hp BackgroundTrans x+0", % " x "
	
	Gui, %GUI%: Font, % "s"settings.general.fsize - 4
	If vars.general.safe_mode
		vars.general.available_resolutions := StrReplace(vars.general.available_resolutions, vars.monitor.h "|")
	Gui, %GUI%: Add, DDL, % "ys hp BackgroundTrans HWNDhwnd gSettings_general2 r10 x+0 w"5* settings.general.fwidth, % StrReplace(vars.general.available_resolutions, vars.client.h "|", vars.client.h "||")
	vars.hwnd.settings.custom_resolution := hwnd, vars.hwnd.help_tooltips["settings_force resolution|||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fsize
	
	WinGetPos,,, wCheck, hCheck, ahk_group poe_window
	If !vars.general.safe_mode && (wCheck < vars.monitor.w || hCheck < vars.monitor.h)
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", window-position:
		vars.hwnd.help_tooltips["settings_window position"] := hwnd
		Gui, %GUI%: Font, % "s"settings.general.fsize - 4
		If (wCheck < vars.monitor.w)
		{
			Gui, %GUI%: Add, DDL, % "ys hp r3 HWNDhwnd w"Floor(settings.general.fWidth* 6.5) " gSettings_general2", % StrReplace("left|center|right|", vars.client.docked "|", vars.client.docked "||")
			vars.hwnd.settings.dock := hwnd, vars.hwnd.help_tooltips["settings_window position|"] := hwnd
		}
		If (hCheck < vars.monitor.h)
		{
			Gui, %GUI%: Add, DDL, % "ys hp r3 HWNDhwnd gSettings_general2" (wCheck < vars.monitor.w ? " wp" : " w"settings.general.fWidth * 6.5), % StrReplace("top|center|bottom|", vars.client.docked2 "|", vars.client.docked2 "||")
			vars.hwnd.settings.dock2 := hwnd, vars.hwnd.help_tooltips["settings_window position||"] := hwnd
			Gui, %GUI%: Font, % "s"settings.general.fsize
		}
		If (vars.client.fullscreen = "false")
		{
			Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd Checked"vars.client.borderless " gSettings_general2", force borderless-windowed mode
			vars.hwnd.settings.remove_borders := hwnd, vars.hwnd.help_tooltips["settings_window borders"] := hwnd
		}
	}
	
	;If (vars.client.fullscreen = "false")
	;	Gui, %GUI%: Add, Checkbox, % "ys BackgroundTrans Checked" window_docking " vwindow_docking gSettings_general", % "top-docked"
	;removed for future dynamic repositioning
	
	If (vars.client.h0 / vars.client.w0 < (5/12))
	{
		settings.general.blackbars := LLK_IniRead("ini\config.ini", "Settings", "black-bar compensation", 0)
		Gui, %GUI%: Add, Checkbox, % "hp xs Section BackgroundTrans gSettings_general2 HWNDhwnd Center Checked"settings.general.blackbars, % "the client has black bars on the sides"
		vars.hwnd.settings.blackbars := hwnd, vars.hwnd.help_tooltips["settings_black bars"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans HWNDhwnd y+"vars.settings.spacing, % "script write-permissions test:"
	vars.hwnd.settings.permissions_test := hwnd
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", img\GUI\help.png
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans Border gSettings_WriteTest", % " start test "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cGreen Range0-700 HWNDhwnd", 0
	Gui, %GUI%: Add, Text, % "ys BackgroundTrans Border gSettings_WriteTest", % " restart script as admin "
	vars.hwnd.help_tooltips["settings_write permissions"] := hwnd0, vars.hwnd.settings.bar_writetest := hwnd
}

Settings_general2(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), update := vars.update
	If !check
		check := A_GuiControl
	
	Switch check
	{
		Case "LLK-UI":
			start := A_TickCount
			While GetKeyState("LButton", "P") ;dragging the LLK-UI button
			{
				If (A_TickCount >= start + 250)
				{
					WinGetPos,,, width, height, % "ahk_id " vars.hwnd.LLK_panel
					While GetKeyState("LButton", "P")
					{
						LLK_Drag(width, height, xPos, yPos)
						Sleep 1
					}
					KeyWait, LButton
					IniWrite, % xPos, ini\config.ini, UI, button xcoord
					IniWrite, % yPos, ini\config.ini, UI, button ycoord
					settings.general.xButton := xPos, settings.general.yButton := yPos
					WinActivate, ahk_group poe_window
					Return
				}
			}

			If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main) || WinExist("ahk_id " vars.hwnd.searchstrings_menu.main) || WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main)
				LLK_ToolTip("close the configuration`nwindow first", 2,,,, "yellow")
			Else If (vars.system.click = 2)
			{
				KeyWait, RButton
				Reload
				ExitApp
			}
			Else If WinExist("ahk_id "vars.hwnd.settings.main)
				Settings_menuClose()
			Else Settings_menu("general")
		Case "winbar":
			start := A_TickCount
			While GetKeyState("LButton", "P") ;dragging the window
			{
				If (A_TickCount >= start + 250)
				{
					WinGetPos,,, width, height, % "ahk_id " vars.hwnd.settings.main
					While GetKeyState("LButton", "P")
					{
						LLK_Drag(width, height, xPos, yPos, 1)
						sleep 1
					}
					KeyWait, LButton
					WinGetPos, xPos, yPos, w, h, % "ahk_id " vars.hwnd.settings.main
					vars.settings.x := xPos, vars.settings.y := yPos
					Return
				}
			}
		Case "kill_timer":
			settings.general.kill.1 := LLK_ControlGet(cHWND)
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, Settings, kill script
		Case "kill_timeout":
			parse := LLK_ControlGet(cHWND)
			If (parse = "")
				parse := 1
			settings.general.kill.2 := parse
			GuiControl, text, % vars.hwnd.settings.minutes, % "minute" (parse = 1 ? "" : "s") " after closing the game   "
			IniWrite, % parse, ini\config.ini, Settings, kill-timeout
		Case "browser":
			settings.features.browser := LLK_ControlGet(cHWND)
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, settings, enable browser features
		Case "capslock":
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, settings, enable capslock-toggling
			IniWrite, general, ini\config.ini, versions, reload settings
			Reload
			ExitApp
		Case "character":
			GuiControl, +cRed, % vars.hwnd.settings.character
			GuiControl, movedraw, % vars.hwnd.settings.character
		Case "save_character":
			parse := LLK_ControlGet(vars.hwnd.settings.character), settings.general.character := InStr(parse, " (") ? SubStr(parse, 1, InStr(parse, " (") - 1) : parse
			IniWrite, % settings.general.character, ini\config.ini, Settings, active character
			Init_log()
			If WinExist("ahk_id "vars.hwnd.geartracker.main)
				GeartrackerGUI()
			Else If settings.leveltracker.geartracker && vars.hwnd.geartracker.main
				GeartrackerGUI("refresh")
			If WinExist("ahk_id "vars.hwnd.leveltracker.main)
				GuiControl, text, % vars.hwnd.leveltracker.experience, % LeveltrackerExperience()
			Settings_menu("general")
		Case "language":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "custom_width":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "custom_resolution":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "apply":
			width := (LLK_ControlGet(vars.hwnd.settings.custom_width) > vars.monitor.w) ? vars.monitor.w : LLK_ControlGet(vars.hwnd.settings.custom_width)
			height := LLK_ControlGet(vars.hwnd.settings.custom_resolution)
			If !IsNumber(height) || !IsNumber(width)
			{
				LLK_ToolTip("incorrect settings",,,,, "red")
				Return
			}
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.dock), ini\config.ini, Settings, window-position
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.dock2), ini\config.ini, Settings, window-position vertical
			IniWrite, % height, ini\config.ini, Settings, custom-resolution
			IniWrite, % width, ini\config.ini, Settings, custom-width
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.remove_borders), ini\config.ini, settings, remove window-borders
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.language), ini\config.ini, settings, language
			If vars.hwnd.settings.blackbars
				IniWrite, % LLK_ControlGet(vars.hwnd.settings.blackbars), ini\config.ini, Settings, black-bar compensation
			IniWrite, % vars.settings.active, ini\config.ini, Versions, reload settings
			Reload
			ExitApp
		Case "dock":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "dock2":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "remove_borders":
			state := LLK_ControlGet(cHWND), ddl_state := LLK_ControlGet(vars.hwnd.settings.custom_resolution)
			For key in vars.general.supported_resolutions
				If state && (key <= vars.monitor.h) || !state && (key < vars.monitor.h)
					ddl := !ddl ? key : key "|" ddl
			ddl := !InStr(ddl, ddl_state) ? "|" StrReplace(ddl, "|", "||",, 1) : "|" StrReplace(ddl, InStr(ddl, ddl_state "|") ? ddl_state "|" : ddl_state, ddl_state "||")
			GuiControl,, % vars.hwnd.settings.custom_resolution, % ddl
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "blackbars":
			GuiControl, +cRed, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Default:
			If InStr(check, "font_")
			{
				While GetKeyState("LButton", "P")
				{
					If (control = "minus")
						settings.general.fSize -= (settings.general.fSize > 6) ? 1 : 0
					Else If (control = "reset")
						settings.general.fSize := LLK_FontDefault()
					Else settings.general.fSize += 1
					GuiControl, text, % vars.hwnd.settings.font_reset, % settings.general.fSize
					Sleep 150
				}
				LLK_FontDimensions(settings.general.fSize, font_height, font_width)
				settings.general.fheight := font_height, settings.general.fwidth := font_width
				IniWrite, % settings.general.fSize, ini\config.ini, Settings, font-size
				Init_GUI()
				Settings_menu("general")
			}
			Else LLK_ToolTip("no action")
	}
}

Settings_help(hwnd := "")
{
	LLK_ToolTip(hwnd)
}

Settings_hotkeys()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://www.autohotkey.com/docs/v1/KeyList.htm">ahk: list of keys</a>
	Gui, %GUI%: Add, Link, % "ys x+"settings.general.fWidth, <a href="https://www.autohotkey.com/docs/v1/Hotkeys.htm">ahk: formatting</a>
	
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "in-game keybind settings:"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", img\GUI\help.png
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.rebound_alt, % "<show advanced item descriptions>`nis not bound to the alt-key"
	vars.hwnd.settings.rebound_alt := hwnd, vars.hwnd.help_tooltips["settings_hotkeys ingame-keybinds"] := hwnd0
	If settings.hotkeys.rebound_alt
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "–> instead, it is bound to "
		Gui, %GUI%: font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+0 hp gSettings_hotkeys2 w"settings.general.fWidth*10 " HWNDhwnd cBlack", % settings.hotkeys.item_descriptions
		vars.hwnd.help_tooltips["settings_hotkeys altkey"] := hwnd0, vars.hwnd.settings.item_descriptions := vars.hwnd.help_tooltips["settings_hotkeys altkey|"] := hwnd
		Gui, %GUI%: font, % "s"settings.general.fSize
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.rebound_c, % "the c-key is used for something`nother than <character screen>"
	vars.hwnd.settings.rebound_c := hwnd

	If settings.features.leveltracker
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "move-key: "
		Gui, %GUI%: font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+0 hp gSettings_hotkeys2 w"settings.general.fWidth*10 " HWNDhwnd cBlack", % settings.hotkeys.movekey
		vars.hwnd.help_tooltips["settings_hotkeys movekey"] := hwnd0, vars.hwnd.settings.movekey := hwnd, vars.hwnd.help_tooltips["settings_hotkeys movekey|"] := hwnd
		Gui, %GUI%: font, % "s"settings.general.fSize
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, omni-key settings:
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
	vars.hwnd.help_tooltips["settings_hotkeys omnikey-info"] := hwnd
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "replace m-mouse with:"
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd gSettings_hotkeys2 x+"settings.general.fWidth/2 " w"settings.general.fWidth*10, % (settings.hotkeys.omnikey = "MButton") ? "" : LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "omni-hotkey")
	vars.hwnd.help_tooltips["settings_hotkeys omnikey"] := hwnd0, vars.hwnd.settings.omnikey := vars.hwnd.help_tooltips["settings_hotkeys omnikey|"] := hwnd
	ControlGetPos, x, y,,,, % "ahk_id "hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	If settings.hotkeys.rebound_c
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", omni-key 2 (for items):
		Gui, %GUI%: font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "yp x"x-1 " hp cBlack HWNDhwnd gSettings_hotkeys2 w"settings.general.fWidth*10, % LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "omni-hotkey2")
		vars.hwnd.help_tooltips["settings_hotkeys omnikey2"] := hwnd0, vars.hwnd.settings.omnikey2 := vars.hwnd.help_tooltips["settings_hotkeys omnikey2|"] := hwnd
		Gui, %GUI%: font, % "s"settings.general.fSize
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.omniblock, % "block the key"(settings.hotkeys.rebound_c ? "s'" : "'s") " native function"(settings.hotkeys.rebound_c ? "s" : "")
	vars.hwnd.settings.omniblock := hwnd, vars.hwnd.help_tooltips["settings_hotkeys omniblock"] := hwnd
	;Gui, %GUI%: Add, Hotkey, % "ys hp Disabled gSettings_hotkeys2 HWNDhwnd x+"settings.general.fWidth/2 " cBlack w"settings.general.fWidth* 6, % (settings.hotkeys.omnikey = "MButton") ? "" : settings.hotkeys.omnikey
	;vars.hwnd.settings.omnikey := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, miscellaneous keys:
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "replace tab-key with:"
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd gSettings_hotkeys2 x+"settings.general.fWidth/2 " w"settings.general.fWidth*10, % (settings.hotkeys.tab = "TAB") ? "" : LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "tab replacement", "tab")
	vars.hwnd.help_tooltips["settings_hotkeys tab"] := hwnd0, vars.hwnd.settings.tab := hwnd, vars.hwnd.help_tooltips["settings_hotkeys tab|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.tabblock, % "block the key's native function"
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "emergency restart: win + space"
	vars.hwnd.help_tooltips["settings_hotkeys restart"] := hwnd0, vars.hwnd.settings.tabblock := hwnd, vars.hwnd.help_tooltips["settings_hotkeys omniblock|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize + 4
	Gui, %GUI%: Add, Text, % "xs Border gSettings_hotkeys2 Section HWNDhwnd y+"vars.settings.spacing, % " apply && restart "
	vars.hwnd.settings.apply := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
}

Settings_hotkeys2(cHWND)
{
	local
	global vars, settings
	
	check := LLK_HasVal(vars.hwnd.settings, cHWND), keycheck := {}
	If (check = 0)
		check := A_GuiControl

	settings.hotkeys.item_descriptions := LLK_ControlGet(vars.hwnd.settings.item_descriptions)
	settings.hotkeys.omnikey2 := LLK_ControlGet(vars.hwnd.settings.omnikey2)
	Switch check
	{
		Case "rebound_alt":
			settings.hotkeys.rebound_alt := LLK_ControlGet(cHWND)
			Settings_menu("hotkeys", 1)
		Case "rebound_c":
			settings.hotkeys.rebound_c := LLK_ControlGet(cHWND)
			Settings_menu("hotkeys", 1)
		Case "apply":
			Loop, Parse, % "item_descriptions, omnikey, omnikey2, tab", `,, % A_Space
			{
				If (A_LoopField != "item_descriptions")
				{
					If !vars.hwnd.settings[A_LoopField]
						Continue
					hotkey := LLK_ControlGet(vars.hwnd.settings[A_LoopField])
					If (StrLen(hotkey) != 1)
						Loop, Parse, % "+!^#"
							hotkey := StrReplace(hotkey, A_LoopField)
					
					If LLK_ControlGet(vars.hwnd.settings[A_LoopField]) && (!GetKeyVK(hotkey) || (hotkey = ""))
					{
						WinGetPos, x, y, w,, % "ahk_id "vars.hwnd.settings[A_LoopField]
						LLK_ToolTip("<– invalid hotkey",,x + w, y,, "red")
						Return
					}
				}
				
				If keycheck.HasKey(hotkey)
				{
					LLK_ToolTip("duplicate keybinds detected", 1.5,,,, "red")
					Return
				}
				If hotkey
					keycheck[hotkey] := 1
			}
			If LLK_ControlGet(vars.hwnd.settings.rebound_alt) && !LLK_ControlGet(vars.hwnd.settings.item_descriptions)
			{
				WinGetPos, xControl, yControl, wControl, hControl, % "ahk_id " vars.hwnd.settings.item_descriptions
				LLK_ToolTip("<– alt-key rebound, but no`n    alternative key set up", 3, xControl + wControl, yControl,, "red")
				Return
			}
			If LLK_ControlGet(vars.hwnd.settings.rebound_c) && !LLK_ControlGet(vars.hwnd.settings.omnikey2)
			{
				WinGetPos, xControl, yControl, wControl, hControl, % "ahk_id " vars.hwnd.settings.omnikey2
				LLK_ToolTip("<– c-key rebound, but`n    omni-key 2 not set up", 3, xControl + wControl, yControl,, "red")
				Return
			}
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.rebound_alt), ini\hotkeys.ini, settings, advanced item-info rebound
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.item_descriptions), ini\hotkeys.ini, hotkeys, item-descriptions key
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.rebound_c), ini\hotkeys.ini, settings, c-key rebound
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.omnikey), ini\hotkeys.ini, hotkeys, omni-hotkey
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.omniblock), ini\hotkeys.ini, hotkeys, block omnikey's native function
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.omnikey2), ini\hotkeys.ini, hotkeys, omni-hotkey2
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.tab), ini\hotkeys.ini, hotkeys, tab replacement
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.tabblock), ini\hotkeys.ini, hotkeys, block tab-key's native function
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.movekey), ini\hotkeys.ini, hotkeys, move-key
			IniWrite, hotkeys, ini\config.ini, versions, reload settings
			Reload
			ExitApp
	}
	GuiControl, +cRed, % vars.hwnd.settings.apply
	GuiControl, movedraw, % vars.hwnd.settings.apply
}

Settings_iteminfo()
{
	local
	global vars, settings
	
	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Item-info">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys hp HWNDhwnd x+"2*settings.general.fWidth, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb website</a>
	vars.hwnd.help_tooltips["settings_rgb website"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, % "profile settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % "profile selection: "
	Loop 5
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border HWNDhwnd gSettings_iteminfo2 c"(InStr(settings.iteminfo.profile, A_Index) ? "Fuchsia" : "White"), % " "A_Index " "
		vars.hwnd.help_tooltips["settings_iteminfo profiles"] := hwnd0, handle .= "|", vars.hwnd.settings["profile_"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_iteminfo profiles"handle] := hwnd
	}

	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % "reset profile's: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center Border BackgroundTrans cBlack HWNDhwnd gSettings_iteminfo2", % " desired "
	vars.hwnd.help_tooltips["settings_iteminfo reset"] := hwnd0, vars.hwnd.settings.desired := hwnd
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 cRed HWNDhwnd Background"settings.iteminfo.colors_tier.1, 0
	vars.hwnd.settings.delbar_desired := vars.hwnd.help_tooltips["settings_iteminfo reset|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border BackgroundTrans cBlack HWNDhwnd0 gSettings_iteminfo2", % " undesired "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 cRed HWNDhwnd Background"settings.iteminfo.colors_tier.6, 0
	vars.hwnd.settings.undesired := hwnd0, vars.hwnd.settings.delbar_undesired := vars.hwnd.help_tooltips["settings_iteminfo reset||"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans y+"vars.settings.spacing, % "general settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd0", % "text-size: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*3, % settings.iteminfo.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.trigger, % "shift-clicking activates item-info"
	vars.hwnd.settings.trigger := hwnd, vars.hwnd.help_tooltips["settings_iteminfo shift-click"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.compare, % "enable league-start mode"
	vars.hwnd.settings.compare := hwnd, vars.hwnd.help_tooltips["settings_iteminfo league-start"] := hwnd

	If !settings.iteminfo.compare
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.itembase, % "show item-base stats"
		vars.hwnd.settings.itembase := hwnd, vars.hwnd.help_tooltips["settings_iteminfo base-info"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.ilvl, % "display ilvl-requirements"
	vars.hwnd.settings.ilvl := hwnd, vars.hwnd.help_tooltips["settings_iteminfo enable item-level"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans y+"vars.settings.spacing, % "highlight customization:"
	Gui, %GUI%: Font, norm

	Loop, 8
	{
		parse := (A_Index = 1) ? 7 : A_Index - 2
		If (A_Index = 1)
			Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "tier "
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " w"settings.general.fWidth*3 " cBlack Center Border BackgroundTrans gSettings_iteminfo2 HWNDhwnd", % (A_Index = 1) ? "fr" : (A_Index = 2) ? "#" : parse
		vars.hwnd.help_tooltips["settings_iteminfo item-tier"] := hwnd0, vars.hwnd.settings["tier_"parse] := hwnd
		Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack HWNDhwnd Disabled c"settings.iteminfo.colors_tier[parse], 100
		vars.hwnd.settings["tierbar_"parse] := hwnd, handle .= "|", vars.hwnd.help_tooltips["settings_iteminfo item-tier"handle] := hwnd
	}

	If settings.iteminfo.ilvl
	{
		Loop, 8
		{
			If (A_Index = 1)
				Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd0", % "ilvl "
			color := (settings.iteminfo.colors_ilvl[A_Index] = "ffffff") && (A_Index = 1) ? "Red" : "Black", vars.hwnd.help_tooltips["settings_iteminfo item-level"] .= (A_Index = 1) ? hwnd0 : ""
			Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " w"settings.general.fWidth*3 " c"color " Border Center BackgroundTrans gSettings_iteminfo2 HWNDhwnd0", % settings.iteminfo.ilevels[A_Index]
			Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack HWNDhwnd Disabled c"settings.iteminfo.colors_ilvl[A_Index], 100
			vars.hwnd.settings["ilvl_"A_Index] := hwnd0, vars.hwnd.settings["ilvlbar_"A_Index] := hwnd, handle1 .= "|", vars.hwnd.help_tooltips["settings_iteminfo item-level"handle1] := hwnd
		}
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section hp gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.override, % "<undesired> overrides tier/ilvl color"
	vars.hwnd.settings.override := hwnd, vars.hwnd.help_tooltips["settings_iteminfo override"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd0 y+"vars.settings.spacing, % "global rules/overrides:"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", img\GUI\help.png
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.6 " Checked"settings.iteminfo.rules.res_weapons, % "weapon res"
	vars.hwnd.help_tooltips["settings_iteminfo rules"] := hwnd0, vars.hwnd.settings.rule_res_weapons := hwnd
	GuiControlGet, text_, Pos, % hwnd
	checkbox_spacing := text_w + settings.general.fWidth/2

	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.6 " Checked"settings.iteminfo.rules.attacks, % "attack dmg" ;venable_itemchecker_rule_attacks
	vars.hwnd.settings.rule_attacks := hwnd
	GuiControlGet, text_, Pos, % hwnd
	checkbox_spacing1 := text_w + settings.general.fWidth/2

	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing1 "BackgroundTrans gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.6 " Checked"settings.iteminfo.rules.spells, % "spell dmg" ;venable_itemchecker_rule_spells
	vars.hwnd.settings.rule_spells := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section BackgroundTrans gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.1 " Checked"settings.iteminfo.rules.res, % "resists" ;venable_itemchecker_rule_res
	vars.hwnd.settings.rule_res := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.6 "" " Checked"settings.iteminfo.rules.hitgain, % "life/mana gain on hit/kill" ;venable_itemchecker_rule_lifemana_gain
	vars.hwnd.settings.rule_hitgain := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section BackgroundTrans gSettings_iteminfo2 HWNDhwnd c"settings.iteminfo.colors_tier.6 " Checked"settings.iteminfo.rules.crit, % "crit" ;venable_itemchecker_rule_crit
	vars.hwnd.settings.rule_crit := hwnd
}

Settings_iteminfo2(cHWND)
{
	local
	global vars, settings
	
	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)

	If InStr(check, "profile_")
	{
		GuiControl, +cWhite, % vars.hwnd.settings["profile_"settings.iteminfo.profile]
		GuiControl, movedraw, % vars.hwnd.settings["profile_"settings.iteminfo.profile]
		GuiControl, +cFuchsia, % vars.hwnd.settings[check]
		GuiControl, movedraw, % vars.hwnd.settings[check]
		settings.iteminfo.profile := control
		IniWrite, % control, ini\item-checker.ini, settings, current profile
		Init_iteminfo()
	}
	Else If (check = "desired")
	{
		If LLK_Progress(vars.hwnd.settings.delbar_desired, "LButton", cHWND)
		{
			IniRead, parse, ini\item-checker.ini, % "highlighting "settings.iteminfo.profile
			Loop, Parse, parse, `n
			{
				key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
				If InStr(key, "highlight")
					IniWrite, % "", ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % key
			}
			Init_iteminfo()
		}
		Else Return
	}
	Else If (check = "undesired")
	{
		If LLK_Progress(vars.hwnd.settings.delbar_undesired, "LButton", cHWND)
		{
			IniRead, parse, ini\item-checker.ini, % "highlighting "settings.iteminfo.profile
			Loop, Parse, parse, `n
			{
				key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
				If InStr(key, "blacklist")
					IniWrite, % "", ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % key
			}
			Init_iteminfo()
		}
		Else Return
	}
	Else If InStr(check, "font_")
	{
		While GetKeyState("LButton", "P")
		{
			If (control = "minus")
				settings.iteminfo.fSize -= (settings.iteminfo.fSize > 6) ? 1 : 0
			Else If (control = "reset")
				settings.iteminfo.fSize := settings.general.fSize
			Else settings.iteminfo.fSize += 1
			GuiControl, text, % vars.hwnd.settings.font_reset, % settings.iteminfo.fSize
			Sleep 150
		}
		LLK_FontDimensions(settings.iteminfo.fSize, height, width), settings.iteminfo.fWidth := width, settings.iteminfo.fHeight := height, vars.iteminfo.UI := {}
		IniWrite, % settings.iteminfo.fSize, ini\item-checker.ini, settings, font-size
		If !WinExist("ahk_id "vars.hwnd.iteminfo.main)
			Iteminfo(1)
	}
	Else If (check = "trigger")
	{
		settings.iteminfo.trigger := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.trigger, ini\item-checker.ini, settings, enable wisdom-scroll trigger
	}
	Else If (check = "compare")
	{
		settings.iteminfo.compare := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.compare, ini\item-checker.ini, settings, enable gear-tracking
		Init_iteminfo()
		Settings_menu("item-info")
	}
	Else If (check = "itembase")
	{
		settings.iteminfo.itembase := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.itembase, ini\item-checker.ini, settings, enable base-info
	}
	Else If (check = "ilvl")
	{
		settings.iteminfo.ilvl := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.ilvl, ini\item-checker.ini, settings, enable item-levels
		Settings_menu("item-info")
	}
	Else If InStr(check, "tier_")
	{
		If (vars.system.click = 1)
		{
			If !(StrLen(Clipboard) = 6 || (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#"))
			{
				LLK_ToolTip("invalid rgb-code in clipboard", 1.5,,,, "red")
				Return
			}
			color := (StrLen(Clipboard) = 7) ? SubStr(Clipboard, 2) : Clipboard
		}
		Else color := settings.iteminfo.dColors_tier[control]
		GuiControl, +c%color%, % vars.hwnd.settings["tierbar_"control]
		GuiControl, movedraw, % vars.hwnd.settings["tierbar_"control]
		If (control = 1 || control = 6)
		{
			GuiControl, +Background%color%, % vars.hwnd.settings[(control = 1) ? "delbar_desired" : "delbar_undesired"]
			GuiControl, movedraw, % vars.hwnd.settings[(control = 1) ? "delbar_desired" : "delbar_undesired"]
			If (control = 6)
				Loop, Parse, % "res_weapons, attacks, spells, hitgain, crit", `,, %A_Space%
				{
					GuiControl, +c%color%, % vars.hwnd.settings["rule_"A_LoopField]
					GuiControl, movedraw, % vars.hwnd.settings["rule_"A_LoopField]
				}
			If (control = 1)
			{
				GuiControl, +c%color%, % vars.hwnd.settings.rule_res
				GuiControl, movedraw, % vars.hwnd.settings.rule_res
			}
		}
		IniWrite, % color, ini\item-checker.ini, UI, % (control = 7) ? "fractured" : "tier "control
		settings.iteminfo.colors_tier[control] := color
	}
	Else If InStr(check, "ilvl_")
	{
		If (vars.system.click = 1)
		{
			If !(StrLen(Clipboard) = 6 || (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#"))
			{
				LLK_ToolTip("invalid rgb-code in clipboard", 1.5,,,, "red")
				Return
			}
			color := (StrLen(Clipboard) = 7) ? SubStr(Clipboard, 2) : Clipboard
		}
		Else color := settings.iteminfo.dColors_ilvl[control]
		GuiControl, +c%color%, % vars.hwnd.settings["ilvlbar_"control]
		GuiControl, movedraw, % vars.hwnd.settings["ilvlbar_"control]
		If (control = 1)
		{
			GuiControl, % "+c"(color = "ffffff" ? "Red" : "Black"), % cHWND
			GuiControl, movedraw, % cHWND
		}
		IniWrite, % color, ini\item-checker.ini, UI, % "ilvl tier "control
		settings.iteminfo.colors_ilvl[control] := color
	}
	Else If (check = "override")
	{
		settings.iteminfo.override := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.override, ini\item-checker.ini, settings, enable blacklist-override
	}
	Else If InStr(check, "rule_")
	{
		settings.iteminfo.rules[control] := LLK_ControlGet(cHWND)
		parse := (control = "res_weapons") ? "weapon res" : (control = "hitgain") ? "lifemana gain" : control
		IniWrite, % settings.iteminfo.rules[control], ini\item-checker.ini, settings, % parse " override"
	}
	Else LLK_ToolTip("no action")

	If WinExist("ahk_id "vars.hwnd.iteminfo.main)
		Iteminfo(1)
}

Settings_leveltracker()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Leveling-Tracker">wiki page</a>

	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_leveltracker2 HWNDhwnd Checked"settings.features.leveltracker, % "enable the leveling tracker"
	vars.hwnd.help_tooltips["settings_rgb website"] := hwnd0, vars.hwnd.settings.enable := hwnd, vars.hwnd.help_tooltips["settings_leveltracker enable"] := hwnd

	If !settings.features.leveltracker
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, general settings:
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.timer, % "enable timer"
	vars.hwnd.settings.timer := vars.hwnd.help_tooltips["settings_leveltracker timer"] := hwnd
	If settings.leveltracker.timer
	{
		Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth/2 " gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.pausetimer, % "pause timer in hideouts"
		vars.hwnd.settings.pausetimer := hwnd, vars.hwnd.help_tooltips["settings_leveltracker timer-pause"] := hwnd
	}
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.fade, % "fade out after"
	vars.hwnd.settings.fade := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade-timer"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 hp cBlack Center gSettings_leveltracker2 Limit1 Number HWNDhwnd w"settings.general.fWidth*2, % !settings.leveltracker.fadetime ? 0 : Format("{:0.0f}", settings.leveltracker.fadetime/1000)
	vars.hwnd.settings.fadetime := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade-timer|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd x+"settings.general.fWidth//2, % "second" (settings.leveltracker.fadetime = 1000 ? "   " : "s") 
	vars.hwnd.settings.seconds := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade-timer||"] := hwnd

	If settings.leveltracker.fade
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.fade_hover, % "fade in on mouse-hover"
		vars.hwnd.settings.fade_hover := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade mouse"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.geartracker, % "enable gear tracker"
	vars.hwnd.settings.geartracker := hwnd, vars.hwnd.help_tooltips["settings_leveltracker geartracker"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.layouts, % "enable zone-layout overlay"
	vars.hwnd.settings.layouts := hwnd, vars.hwnd.help_tooltips["settings_leveltracker layouts"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.hints, % "show additional hints in the guide"
	vars.hwnd.settings.hints := vars.hwnd.help_tooltips["settings_leveltracker hints"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "skill-tree overlay settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Picture, % "ys BackgroundTrans hp HWNDhwnd0 w-1", img\gui\help.png
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.pob, % "pob: middle-click opens screen-cap menu"
	vars.hwnd.help_tooltips["settings_leveltracker skilltree-info"] := hwnd0, vars.hwnd.settings.pob := vars.hwnd.help_tooltips["settings_leveltracker pob"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section gSettings_leveltracker2 Border HWNDhwnd", % " screen-cap menu "
	vars.hwnd.settings.screencap := vars.hwnd.help_tooltips["settings_leveltracker screen-cap menu"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " gSettings_leveltracker2 Border HWNDhwnd", % " open img-folder "
	vars.hwnd.settings.folder := vars.hwnd.help_tooltips["settings_leveltracker folder"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs y+"vars.settings.spacing " Section", % "guide settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Border Center gSettings_leveltracker2 HWNDhwnd", % " generate "
	vars.hwnd.settings.generate := vars.hwnd.help_tooltips["settings_leveltracker generate"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_leveltracker2 HWNDhwnd", % " import "
	vars.hwnd.settings.import := vars.hwnd.help_tooltips["settings_leveltracker import"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border BackgroundTrans gSettings_leveltracker2 HWNDhwnd0", % " reset progress: "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd range0-500", 0
	vars.hwnd.settings.reset := hwnd0, vars.hwnd.settings.resetbar := vars.hwnd.help_tooltips["settings_leveltracker reset"] := hwnd

	If !vars.leveltracker.guide.progress.Count()
		LeveltrackerLoad()
	guide := vars.leveltracker.guide, guide_progress := guide.import.Count() && guide.progress.Count() ? Format("{:0.1f}", guide.progress.Count() / (guide.import.Count() - 2) *100) : 0
	Gui, %GUI%: Add, Text, % "ys BackgroundTrans", % (guide_progress = 100 ? 100 : guide_progress) "%"
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans", % "credit: "
	Gui, %GUI%: Add, Link, % "ys x+0 hp", <a href="https://github.com/HeartofPhos/exile-leveling">exile-leveling</a>
	Gui, %GUI%: Add, Text, % "ys Center BackgroundTrans x+0", % " by "
	Gui, %GUI%: Add, Link, % "ys hp x+0", <a href="https://github.com/HeartofPhos">HeartofPhos</a>

	Gui, %GUI%: Font, underline bold
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % "ui settings:"
	Gui, %GUI%: Font, norm
	
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", text-size:
	Gui, %GUI%: Add, Text, % "ys Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*3, % settings.leveltracker.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	
	Gui, %GUI%: Add, Text, % "ys Center", opacity:
	Gui, %GUI%: Add, Text, % "ys Center gSettings_leveltracker2 Border HWNDhwnd", % " – "
	vars.hwnd.settings.opac_minus := hwnd
	Gui, %GUI%: Add, Text, % "ys wp x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd", % "+"
	vars.hwnd.settings.opac_plus := hwnd
	
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", button size:
	Gui, %GUI%: Add, Text, % "ys Center gSettings_leveltracker2 Border HWNDhwnd", % " – "
	vars.hwnd.help_tooltips["settings_button-size"] := hwnd0, vars.hwnd.settings.button_minus := vars.hwnd.help_tooltips["settings_button-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys wp x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd", % "r"
	vars.hwnd.settings.button_reset := vars.hwnd.help_tooltips["settings_button-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys wp x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd", % "+"
	vars.hwnd.settings.button_plus := vars.hwnd.help_tooltips["settings_button-size|||"] := hwnd
}

Settings_leveltracker2(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If (check = "enable")
	{
		settings.features.leveltracker := LLK_ControlGet(cHWND)
		If !settings.features.leveltracker && IsNumber(vars.leveltracker.timer.current_split) && (vars.leveltracker.timer.current_split != LLK_IniRead("ini\leveling tracker.ini", "current run", "time", 0)) ;save current timer state
			IniWrite, % vars.leveltracker.timer.current_split, ini\leveling tracker.ini, current run, time
		IniWrite, % settings.features.leveltracker, ini\config.ini, features, enable leveling guide
		LLK_Overlay(vars.hwnd.leveltracker.main, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker.background, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker.controls2, "destroy") ;destroy controls2 first because it's owned by controls1
		LLK_Overlay(vars.hwnd.leveltracker.controls1, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker_timer.main, "destroy")
		LLK_Overlay(vars.hwnd.geartracker.main, "destroy")
		vars.leveltracker := {}, vars.hwnd.Delete("leveltracker"), vars.hwnd.Delete("leveltracker_timer"), vars.hwnd.Delete("geartracker")
		If settings.features.leveltracker
			Init_leveltracker()
		Settings_menu("leveling tracker")
		Init_GUI("leveltracker")
	}
	Else If (check = "timer")
	{
		settings.leveltracker.timer := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.timer, ini\leveling tracker.ini, settings, enable timer
		If !settings.leveltracker.timer && IsNumber(vars.leveltracker.timer.current_split) && (vars.leveltracker.timer.current_split != LLK_IniRead("ini\leveling tracker.ini", "current run", "time", 0))
			IniWrite, % vars.leveltracker.timer.current_split, ini\leveling tracker.ini, current run, time
		If !settings.leveltracker.timer
			LLK_Overlay(vars.hwnd.leveltracker_timer.main, "destroy")
		vars.leveltracker.timer.pause := -1
		Settings_menu("leveling tracker")
	}
	Else If (check = "pausetimer")
	{
		settings.leveltracker.pausetimer := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.pausetimer, ini\leveling tracker.ini, settings, hideout pause
	}
	Else If (check = "fade")
	{
		settings.leveltracker.fade := LLK_ControlGet(cHWND)
		If !settings.leveltracker.fade && WinExist("ahk_id "vars.hwnd.leveltracker.main)
		{
			WinSet, Trans, Off, % "ahk_id "vars.hwnd.leveltracker.main
			WinSet, TransColor, Black, % "ahk_id "vars.hwnd.leveltracker.main
			WinSet, Trans, % settings.leveltracker.trans, % "ahk_id "vars.hwnd.leveltracker.background
			WinSet, Trans, 140, % "ahk_id "vars.hwnd.leveltracker.controls1
			WinSet, TransColor, Black, % "ahk_id "vars.hwnd.leveltracker.controls2
			vars.leveltracker.fade := 0
		}
		IniWrite, % settings.leveltracker.fade, ini\leveling tracker.ini, settings, enable fading
		Settings_menu("leveling tracker")
	}
	Else If (check = "fadetime")
	{
		settings.leveltracker.fadetime := !LLK_ControlGet(cHWND) ? 0 : Format("{:0.0f}", LLK_ControlGet(cHWND)*1000)
		GuiControl, text, % vars.hwnd.settings.seconds, % (settings.leveltracker.fadetime = 1000) ? "second" : "seconds"
		IniWrite, % settings.leveltracker.fadetime, ini\leveling tracker.ini, settings, fade-time
	}
	Else If (check = "fade_hover")
	{
		settings.leveltracker.fade_hover := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.fade_hover, ini\leveling tracker.ini, settings, show on hover
	}
	Else If (check = "geartracker")
	{
		settings.leveltracker.geartracker := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.geartracker, ini\leveling tracker.ini, settings, enable geartracker
		If settings.leveltracker.geartracker
			GeartrackerGUI("refresh")
	}
	Else If (check = "layouts")
	{
		settings.leveltracker.layouts := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.layouts, ini\leveling tracker.ini, settings, enable zone-layout overlay
		If WinExist("ahk_id "vars.hwnd.leveltracker.main)
			LeveltrackerProgress(1)
	}
	Else If (check = "hints")
	{
		settings.leveltracker.hints := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.hints, ini\leveling tracker.ini, settings, enable additional hints
		If WinExist("ahk_id "vars.hwnd.leveltracker.main)
			LeveltrackerProgress(1)
	}
	Else If (check = "pob")
	{
		settings.leveltracker.pob := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.pob, ini\leveling tracker.ini, settings, enable pob-screencap
	}
	Else If (check = "screencap")
	{
		KeyWait, LButton
		LLK_Overlay(vars.hwnd.settings.main, "hide")
		LeveltrackerScreencapMenu()
	}
	Else If (check = "folder")
	{
		KeyWait, LButton
		Run, explore img\GUI\skill-tree\
	}
	Else If (check = "generate")
	{
		KeyWait, LButton
		Run, https://heartofphos.github.io/exile-leveling/
	}
	Else If (check = "import")
	{
		KeyWait, LButton
		If LeveltrackerImport() && WinExist("ahk_id "vars.hwnd.leveltracker.main)
			LeveltrackerProgress()
	}
	Else If (check = "reset")
	{
		If LLK_Progress(vars.hwnd.settings.resetbar, "LButton")
			LeveltrackerProgressReset()
		Else Return
	}
	Else If InStr(check, "font_")
	{
		While GetKeyState("LButton", "P")
		{
			If (control = "minus") && (settings.leveltracker.fSize > 6)
				settings.leveltracker.fSize -= 1
			Else If (control = "reset")
				settings.leveltracker.fSize := settings.general.fSize
			Else If (control = "plus")
				settings.leveltracker.fSize += 1
			GuiControl, text, % vars.hwnd.settings.font_reset, % settings.leveltracker.fSize
			Sleep 150
		}
		IniWrite, % settings.leveltracker.fSize, ini\leveling tracker.ini, settings, font-size
		LLK_FontDimensions(settings.leveltracker.fSize, height, width), settings.leveltracker.fHeight := height, settings.leveltracker.fWidth := width
		If WinExist("ahk_id "vars.hwnd.leveltracker.main)
			Leveltracker()
		If WinExist("ahk_id "vars.hwnd.geartracker.main)
			GeartrackerGUI()
		Init_GUI("leveltracker")
	}
	Else If InStr(check, "opac_")
	{
		If (control = "minus")
			settings.leveltracker.trans -= 20
		Else settings.leveltracker.trans += 20
		settings.leveltracker.trans := (settings.leveltracker.trans < 140) ? 140 : (settings.leveltracker.trans > 250) ? 250 : settings.leveltracker.trans
		Leveltracker(), vars.leveltracker.fade := 0
		IniWrite, % settings.leveltracker.trans, ini\leveling tracker.ini, settings, transparency
	}
	Else If (check = "top" || check = "bottom")
	{
		settings.leveltracker.pos := check
		IniWrite, % check, ini\leveling tracker.ini, settings, overlay-position
		If WinExist("ahk_id "vars.hwnd.leveltracker.main)
			Leveltracker()
	}
	Else If InStr(check, "button_")
	{
		If (control = "minus") && (settings.leveltracker.oButton > 0.5)
			settings.leveltracker.oButton -= 0.1
		Else If (control = "reset")
			settings.leveltracker.oButton := 1
		Else If (control = "plus") && (settings.leveltracker.oButton < 1)
			settings.leveltracker.oButton += 0.1
		settings.leveltracker.oButton := Format("{:0.1f}", settings.leveltracker.oButton), settings.leveltracker.sButton := vars.monitor.w* 0.03* settings.leveltracker.oButton
		IniWrite, % settings.leveltracker.oButton, ini\leveling tracker.ini, settings, button-offset
		Init_GUI("leveltracker")
	}
	Else LLK_ToolTip("no action")
}

Settings_mapinfo()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Map-info-panel">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd0 x+"2*settings.general.fWidth, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb website</a>

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 y+"vars.settings.spacing " HWNDhwnd Checked"settings.features.mapinfo, enable the map-info panel
	vars.hwnd.help_tooltips["settings_rgb website"] := hwnd0, vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_mapinfo enable"] := hwnd

	If !settings.features.mapinfo
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, % "general settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 HWNDhwnd Checked"settings.mapinfo.trigger, shift-clicking activates the panel
	vars.hwnd.settings.shiftclick := vars.hwnd.help_tooltips["settings_mapinfo shift-click"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 HWNDhwnd Checked"settings.mapinfo.tabtoggle, show panel while holding tab
	vars.hwnd.settings.tabtoggle := vars.hwnd.help_tooltips["settings_mapinfo tab"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "ui settings:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "text-size: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*3, % settings.mapinfo.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "text-colors: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center Border gSettings_mapinfo2 HWNDhwnd c"settings.mapinfo.color.5, % " header "
	vars.hwnd.help_tooltips["settings_mapinfo colors"] := hwnd0, vars.hwnd.settings.color_5 := vars.hwnd.help_tooltips["settings_mapinfo colors|"] := hwnd, handle := "|"
	Loop 4
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd c"settings.mapinfo.color[A_Index], % " " A_Index " "
		handle .= "|", vars.hwnd.settings["color_"A_Index] := vars.hwnd.help_tooltips["settings_mapinfo colors"handle] := hwnd
	}

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "logbook-mod colors: "
	Loop 4
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd c"settings.mapinfo.eColor[A_Index], % " " A_Index " "
		vars.hwnd.help_tooltips["settings_mapinfo logbooks"] := hwnd0, handle1 .= "|", vars.hwnd.settings["colorlogbook_"A_Index] := vars.hwnd.help_tooltips["settings_mapinfo logbooks"handle] := hwnd
	}
}

Settings_mapinfo2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	Switch check
	{
		Case "enable":
			settings.features.mapinfo := LLK_ControlGet(cHWND)
			IniWrite, % settings.features.mapinfo, ini\config.ini, features, enable map-info panel
			Settings_menu("map-info")
			LLK_Overlay(vars.hwnd.mapinfo.main, "destroy")
		Case "shiftclick":
			settings.mapinfo.trigger := LLK_ControlGet(cHWND)
			IniWrite, % settings.mapinfo.trigger, ini\map info.ini, settings, enable shift-clicking
		Case "tabtoggle":
			settings.mapinfo.tabtoggle := LLK_ControlGet(cHWND)
			IniWrite, % settings.mapinfo.tabtoggle, ini\map info.ini, settings, show panel while holding tab
		Default:
			If InStr(check, "font_")
			{
				While GetKeyState("LButton", "P")
				{
					If (control = "reset")
						settings.mapinfo.fSize := settings.general.fSize
					Else settings.mapinfo.fSize += (control = "minus") ? -1 : 1, settings.mapinfo.fSize := (settings.mapinfo.fSize < 6) ? 6 : settings.mapinfo.fSize
					GuiControl, text, % vars.hwnd.settings.font_reset, % settings.mapinfo.fSize
					Sleep 150
				}
				IniWrite, % settings.mapinfo.fSize, ini\map info.ini, settings, font-size
				LLK_FontDimensions(settings.mapinfo.fSize, height, width), settings.mapinfo.fWidth := width, settings.mapinfo.fHeight := height
			}
			Else If InStr(check, "color_")
			{
				If (vars.system.click = 1) && !ClipRGB()
					Return
				Else settings.mapinfo.color[control] := (vars.system.click = 1) ? ClipRGB() : settings.mapinfo.dColor[control]
				IniWrite, % settings.mapinfo.color[control], ini\map info.ini, UI, % (control = 5 ? "header" : "difficulty " control) " color"
				GuiControl, % "+c"settings.mapinfo.color[control], % cHWND
				GuiControl, movedraw, % cHWND
			}
			Else If InStr(check, "colorlogbook_")
			{
				If (vars.system.click = 1) && !ClipRGB()
					Return
				Else settings.mapinfo.eColor[control] := (vars.system.click = 1) ? ClipRGB() : settings.mapinfo.eColor_default[control]
				IniWrite, % settings.mapinfo.eColor[control], ini\map info.ini, UI, % "logbook " control " color"
				GuiControl, % "+c"settings.mapinfo.eColor[control], % cHWND
				GuiControl, movedraw, % cHWND
			}
			Else LLK_ToolTip("no action")
			If WinExist("ahk_id "vars.hwnd.mapinfo.main)
				MapinfoParse(0), MapinfoGUI(GetKeyState(settings.hotkeys.tab, "P") ? 2 : 0)
	}
}

Settings_maptracker()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Mapping-tracker">wiki page</a>
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 y+"vars.settings.spacing " HWNDhwnd Checked"settings.features.maptracker, enable the mapping tracker
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_maptracker enable"] := hwnd

	If !settings.features.maptracker
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, general settings:
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.loot, enable loot tracker
	vars.hwnd.settings.loot := vars.hwnd.help_tooltips["settings_maptracker loot-tracker"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.kills, enable kill tracker
	vars.hwnd.settings.kills := vars.hwnd.help_tooltips["settings_maptracker kill-tracker"] := hwnd
	If settings.features.mapinfo
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.mapinfo, include map-info panel mods
		vars.hwnd.settings.mapinfo := vars.hwnd.help_tooltips["settings_maptracker mapinfo"] := hwnd
	}
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.sidecontent, track side-areas in maps
	vars.hwnd.settings.sidecontent := vars.hwnd.help_tooltips["settings_maptracker side-content"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.mechanics, track optional content
	vars.hwnd.settings.mechanics := vars.hwnd.help_tooltips["settings_maptracker mechanics"] := hwnd
	If settings.maptracker.mechanics
	{
		Gui, %GUI%: Add, Text, % "xs Section Center xp+"settings.general.fWidth * 2, % "–> dialogue tracking:"
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
		vars.hwnd.help_tooltips["settings_maptracker dialogue tracking"] := hwnd, added := 0, ingame_dialogs := InStr(LLK_FileRead(vars.system.config), "output_all_dialogue_to_chat=true") ? 1 : 0
		Gui, %GUI%: Font, c505050
		For mechanic, type in vars.maptracker.mechanics
		{
			If (type != 1)
				Continue
			added += 1, color := !ingame_dialogs ? " cRed" : settings.maptracker[mechanic] ? " cLime" : ""
			Gui, %GUI%: Add, Text, % (added = 1 || !Mod(added - 1, 4) ? "xs Section" : "ys x+"settings.general.fWidth/4) " Border Center gSettings_maptracker2 HWNDhwnd"color, % " " mechanic " "
			vars.hwnd.settings["mechanic_"mechanic] := vars.hwnd.help_tooltips["settings_maptracker dialoguemechanic"handle] := hwnd, handle .= "|"
		}
		Gui, %GUI%: Font, cWhite
		
		Gui, %GUI%: Add, Text, % "xs Section Center", % "–> screen tracking:"
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
		vars.hwnd.help_tooltips["settings_maptracker screen tracking"] := hwnd, handle := "", added := 0
		Gui, %GUI%: Font, c505050
		For mechanic, type in vars.maptracker.mechanics
		{
			If (type != 2)
				Continue
			added += 1, color := !FileExist("img\Recognition ("vars.client.h "p)\Mapping Tracker\"mechanic ".bmp") ? "red" : settings.maptracker[mechanic] ? " cLime" : ""
			Gui, %GUI%: Add, Text, % (added = 1 || !Mod(added - 1, 4) ? "xs Section" : "ys x+"settings.general.fWidth/4) " Border Center gSettings_maptracker2 HWNDhwnd c"color, % " " mechanic " "
			vars.hwnd.settings["screenmechanic_"mechanic] := vars.hwnd.help_tooltips["settings_maptracker screenmechanic"handle] := hwnd, handle .= "|"
		}
		Gui, %GUI%: Font, cWhite
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.portal_reminder, portal-scroll reminder
		vars.hwnd.settings.portal_reminder := vars.hwnd.help_tooltips["settings_maptracker portal reminder"] := hwnd, handle := ""
	}
	
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing " x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2, ui settings:
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % "text-size: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center gSettings_maptracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4 " w"settings.general.fWidth*3, % settings.maptracker.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4 " w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % "button size: "
	Gui, %GUI%: Add, Text, % "ys x+0 Center gSettings_maptracker2 Border HWNDhwnd", % " – "
	vars.hwnd.help_tooltips["settings_button-size"] := hwnd0, vars.hwnd.settings.button_minus := vars.hwnd.help_tooltips["settings_button-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys wp Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4, % "r"
	vars.hwnd.settings.button_reset := vars.hwnd.help_tooltips["settings_button-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys wp Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4, % "+"
	vars.hwnd.settings.button_plus := vars.hwnd.help_tooltips["settings_button-size|||"] := hwnd
}

Settings_maptracker2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	Switch check
	{
		Case "enable":
			settings.features.maptracker := LLK_ControlGet(cHWND)
			IniWrite, % settings.features.maptracker, ini\config.ini, features, enable map tracker
			If !settings.features.maptracker
				vars.maptracker.Delete("map"), LLK_Overlay(vars.hwnd.maptracker.main, "destroy")
			Init_GUI("maptracker")
			Settings_menu("mapping tracker")
		Case "loot":
			settings.maptracker.loot := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.loot, ini\map tracker.ini, settings, enable loot tracker
			Settings_ScreenChecksValid()
		Case "kills":
			settings.maptracker.kills := LLK_ControlGet(cHWND), vars.maptracker.refresh_kills := ""
			IniWrite, % settings.maptracker.kills, ini\map tracker.ini, settings, enable kill tracker
		Case "mapinfo":
			settings.maptracker.mapinfo := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.mapinfo, ini\map tracker.ini, settings, log mods from map-info panel
		Case "sidecontent":
			settings.maptracker.sidecontent := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.sidecontent, ini\map tracker.ini, settings, track side-areas
		Case "mechanics":
			settings.maptracker.mechanics := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.mechanics, ini\map tracker.ini, settings, track league mechanics
			Settings_menu("mapping tracker")
		Case "portal_reminder":
			settings.maptracker.portal_reminder := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.portal_reminder, ini\map tracker.ini, settings, portal-scroll reminder
		Default:
			If InStr(check, "font_")
			{
				While GetKeyState("LButton", "P")
				{
					If (control = "minus")
						settings.maptracker.fSize -= (settings.maptracker.fSize > 6) ? 1 : 0
					Else If (control = "reset")
						settings.maptracker.fSize := settings.general.fSize
					Else If (control = "plus")
						settings.maptracker.fSize += 1
					GuiControl, text, % vars.hwnd.settings.font_reset, % settings.maptracker.fSize
					Sleep 150
				}
				LLK_FontDimensions(settings.maptracker.fSize, height, width), settings.maptracker.fWidth := width, settings.maptracker.fHeight := height
				IniWrite, % settings.maptracker.fSize, ini\map tracker.ini, settings, font-size
				If WinExist("ahk_id "vars.hwnd.maptracker.main)
					MaptrackerGUI()
				If WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
					MaptrackerLogs()
			}
			Else If InStr(check, "button_")
			{
				If (control = "minus")
					settings.maptracker.oButton -= (settings.maptracker.oButton > 0.5) ? 0.1 : 0
				Else If (control = "reset")
					settings.maptracker.oButton := 1
				Else If (control = "plus")
					settings.maptracker.oButton += (settings.maptracker.oButton < 1) ? 0.1 : 0

				IniWrite, % settings.maptracker.oButton, ini\map tracker.ini, Settings, button-offset
				settings.maptracker.sButton := vars.monitor.w* 0.03* settings.maptracker.oButton
				Init_Gui("maptracker")
			}
			Else If InStr(check, "mechanic_")
			{
				If InStr(check, "screen") && (vars.system.click = 2)
				{
					KeyWait, RButton
					Clipboard := ""
					SendInput, #+{s}
					WinWaitActive, ahk_group snipping_tools,, 2
					WinWaitNotActive, ahk_group snipping_tools
					pClipboard := Gdip_CreateBitmapFromClipboard()
					If (0 >= pClipboard)
					{
						LLK_ToolTip("screen-cap failed", 1.5,,,, "red")
						Return
					}
					Gdip_SaveBitmapToFile(pClipboard, "img\Recognition ("vars.client.h "p)\Mapping Tracker\"control ".bmp"), Gdip_DisposeImage(pClipboard)
					GuiControl, % "+c"(settings.maptracker[control] ? "Lime" : "505050"), % vars.hwnd.settings["screenmechanic_"control]
					GuiControl, movedraw, % vars.hwnd.settings["screenmechanic_"control]
					Return
				}
				If InStr(check, "screen") && !FileExist("img\Recognition ("vars.client.h "p)\Mapping Tracker\"control ".bmp")
					Return
				If !InStr(check, "screen") && !InStr(LLK_FileRead(vars.system.config), "output_all_dialogue_to_chat=true")
				{
					LLK_ToolTip("<output dialogue to chat> has to`nbe enabled in the game's <ui> settings", 3,,,, "red")
					Return
				}
				settings.maptracker[control] := !settings.maptracker[control] ? 1 : 0
				IniWrite, % settings.maptracker[control], ini\map tracker.ini, mechanics, % control
				GuiControl, % "+c"(settings.maptracker[control] ? "Lime" : "505050"), % cHWND
				GuiControl, movedraw, % cHWND
			}
			Else LLK_ToolTip("no action")
	}
}

Settings_menu(section, mode := 0) ;mode parameter used when manually calling this function to refresh the window
{
	local
	global vars, settings
	
	If !IsObject(vars.settings)
		vars.settings := {"sections": ["general", "betrayal-info", "cheat-sheets", "clone-frames", ;list of sections in the settings menu
		, "hotkeys", "item-info", "leveling tracker", "mapping tracker", "map-info", "minor qol tools", "screen-checks", "search-strings", "stream-clients", "updater"]}
	
	If LLK_HasVal(vars.hwnd.settings, section) ;instead of using the first parameter for section/cHWND depending on context, get the section name from the control's text
		section := LLK_HasVal(vars.hwnd.settings, section) ? LLK_HasVal(vars.hwnd.settings, section) : section

	vars.settings.xMargin := settings.general.fWidth*0.75, vars.settings.yMargin := settings.general.fHeight*0.15, vars.settings.line1 := settings.general.fHeight/4
	vars.settings.spacing := settings.general.fHeight*0.8

	If !IsNumber(mode)
		mode := 0
	vars.settings.active := section ;which section of the settings menu is currently active (for purposes of reloading the correct section after restarting)

	If WinExist("ahk_id "vars.hwnd.settings.main)
	{
		WinGetPos, xPos, yPos,,, % "ahk_id " vars.hwnd.settings.main
		vars.settings.x := xPos, vars.settings.y := yPos
	}
	
	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDsettings_menu"
	Gui, %settings_menu%: Color, Black
	Gui, %settings_menu%: Margin, % vars.settings.xMargin, % vars.settings.line1
	Gui, %settings_menu%: Font, % "s" settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.settings.main ;backup of the old GUI's HWND with which to destroy it after drawing the new one
	vars.hwnd.settings := {"main": settings_menu} ;settings-menu HWNDs are stored here
	
	Gui, %settings_menu%: Add, Text, % "Section x-1 y-1 Border Center BackgroundTrans gSettings_general2 HWNDhwnd", % "lailloken ui: settings menu"
	vars.hwnd.settings.winbar := hwnd
	ControlGetPos,,,, hWinbar,, ahk_id %hwnd%
	Gui, %settings_menu%: Add, Text, % "ys w"settings.general.fWidth*2 " Border Center gSettings_menuClose HWNDhwnd", % "x"
	vars.hwnd.settings.winx := hwnd
	
	LLK_PanelDimensions(vars.settings.sections, settings.general.fSize, section_width, height)
	Gui, %settings_menu%: Font, % "s" settings.general.fSize
	Gui, %settings_menu%: Add, Text, % "xs x-1 y+-1 Section BackgroundTrans Border gSettings_menu HWNDhwnd 0x200 h"settings.general.fHeight*1.5 " w"section_width, % " general "
	Gui, %settings_menu%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd1 BackgroundBlack cBlack", 100
	ControlGetPos, x, y,,,, ahk_id %hwnd%
	vars.hwnd.settings.general := hwnd, vars.settings.xSelection := x, vars.settings.ySelection := y + vars.settings.line1, vars.settings.wSelection := section_width, vars.hwnd.settings["background_general"] := hwnd1
	
	If !vars.general.buggy_resolutions.HasKey(vars.client.h) && !vars.general.safe_mode
	{
		For key, val in vars.settings.sections
		{
			If (val = "general") || (val = "screen-checks") && !IsNumber(vars.pixelsearch.gamescreen.x1) || !vars.log.file_location && (val = "leveling tracker" || val = "mapping tracker") ;cont
			|| (!WinExist("ahk_exe GeForceNOW.exe") && !WinExist("ahk_exe boosteroid.exe") && val = "stream-clients")
				continue
			color := (val = "updater" && IsNumber(vars.update.1) && vars.update.1 < 0) ? " cRed" : (val = "updater" && IsNumber(vars.update.1) && vars.update.1 > 0) ? " cLime" : ""
			Gui, %settings_menu%: Add, Text, % "Section xs y+-1 wp BackgroundTrans Border gSettings_menu HWNDhwnd 0x200 h"settings.general.fHeight*1.5 color, % " " val " "
			Gui, %settings_menu%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd1 BackgroundBlack cBlack", 100
			vars.hwnd.settings[val] := hwnd, vars.hwnd.settings["background_"val] := hwnd1
		}
	}
	ControlGetPos, x, yLast_section, w, hLast_section,, ahk_id %hwnd%
	Gui, %settings_menu%: Font, norm

	;if aspect-ratio is wider than officially supported by PoE, show message and force-open the general section
	If !vars.general.safe_mode && !settings.general.warning_ultrawide && (vars.client.h0/vars.client.w0 < (5/12))
	{
		text =
		(LTrim
		Giga-Ultrawide resolution detected. Some settings may need to be adjusted for proper support.
		
		If your client has black bars on the sides, you need to find the checkbox regarding black bars, read its instructions, and then click it.
		
		If you don't have black bars, you can ignore this message.
		)
		MsgBox, % text
		IniWrite, 1, ini\config.ini, Versions, ultrawide warning
		settings.general.warning_ultrawide := 1
		settings.general.pending_ultrawide := 1
		vars.settings.restart := "general"
		IniDelete, ini\config.ini, Versions, reload settings	
	}
	
	If vars.settings.restart
		section := vars.settings.restart
	
	;highlight selected section
	GuiControl, %settings_menu%: +c303030, % vars.hwnd.settings["background_"vars.settings.active]
	GuiControl, %settings_menu%: movedraw, % vars.hwnd.settings["background_"vars.settings.active]
	
	If vars.settings.active0 && (vars.settings.active0 != vars.settings.active) ;remove highlight from previously-selected section
	{
		GuiControl, %settings_menu%: +cBlack, % vars.hwnd.settings["background_"vars.settings.active0]
		GuiControl, %settings_menu%: movedraw, % vars.hwnd.settings["background_"vars.settings.active0]
	}
	
	vars.settings.active0 := section
	Settings_ScreenChecksValid() ;check if 'screen-checks' section needs to be highlighted red
	
	Settings_menu2(section, mode)
	Gui, %settings_menu%: Margin, % vars.settings.xMargin, -1
	Gui, %settings_menu%: Show, % "NA AutoSize x10000 y10000"
	ControlFocus,, % "ahk_id "vars.hwnd.settings.general
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.settings.main

	If (h > yLast_section + hLast_section)
	{
		Gui, %settings_menu%: Add, Text, % "x-1 Border BackgroundTrans y"vars.settings.ySelection - 1 - vars.settings.line1 " w"section_width " h"h - hWinbar + vars.settings.line1
		h := h + vars.settings.line1 - 1
	}
	
	GuiControl, Move, % vars.hwnd.settings.winbar, % "w"w - settings.general.fWidth*2 + 2
	GuiControl, Move, % vars.hwnd.settings.winx, % "x"w - settings.general.fWidth*2 " y-1"
	sleep 50

	If (vars.settings.x != "") && (vars.settings.y != "")
	{
		vars.settings.x := (vars.settings.x + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w - 1 : vars.settings.x
		vars.settings.y := (vars.settings.y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : vars.settings.y
		Gui, %settings_menu%: Show, % "NA x"vars.settings.x " y"vars.settings.y " w"w - 1 " h"h - 2
	}
	Else
	{
		Gui, %settings_menu%: Show, % "NA x"vars.client.x " y"vars.client.yc - h//2 " w"w - 1 " h"h - 2
		vars.settings.x := vars.client.x
	}
	LLK_Overlay(vars.hwnd.settings.main, "show"), LLK_Overlay(hwnd_old, "destroy"), vars.settings.w := w, vars.settings.h := h
	
	vars.settings.restart := ""
	If settings.general.pending_ultrawide
		settings.general.pending_ultrawide := ""
}

Settings_menu2(section, mode := 0) ;mode parameter used when manually calling this function to refresh the window
{
	local
	global vars, settings
	
	Switch section
	{
		Case "general":
			Settings_general()
		Case "betrayal-info":
			Settings_betrayal()
		Case "cheat-sheets":
			Settings_cheatsheets()
		Case "clone-frames":
			Settings_cloneframes()
		Case "hotkeys":
			If !mode
				Init_hotkeys() ;reload settings from ini when accessing this section (makes it easier to discard unsaved settings if apply-button wasn't clicked)
			Settings_hotkeys()
		Case "item-info":
			Settings_iteminfo()
		Case "leveling tracker":
			Settings_leveltracker()
		Case "mapping tracker":
			Settings_maptracker()
		Case "map-info":
			Settings_mapinfo()
		Case "minor qol tools":
			Settings_qol()
		Case "screen-checks":
			Settings_screenchecks()
		Case "search-strings":
			Init_searchstrings()
			Settings_searchstrings()
		Case "updater":
			Settings_updater()
	}
}

Settings_menuClose()
{
	local
	global vars, settings
	
	KeyWait, LButton
	WinGetPos, xsettings_menu, ysettings_menu,,, % "ahk_id " vars.hwnd.settings.main
	LLK_Overlay(vars.hwnd.settings.main, "destroy")
	vars.settings.active := "", vars.hwnd.Delete("settings")

	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
	Gui, loottracker: Destroy
	hwnd_loottracker := ""

	If WinExist("ahk_id " hwnd_notepad_sample)
	{
		Gui, notepad_sample: Destroy
		hwnd_notepad_sample := ""
	}

	If WinExist("ahk_id " hwnd_alarm_sample)
	{
		Gui, alarm_sample: Destroy
		hwnd_alarm_sample := ""
	}
	WinActivate, ahk_group poe_window
}

Settings_qol()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Minor-Features">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd0 x+"settings.general.fWidth*2, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb website</a>

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs HWNDhwnd1 y+"vars.settings.spacing " Section", % "alarm-timer:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.alarm, % "enable"
	vars.hwnd.help_tooltips["settings_rgb website"] := hwnd0, vars.hwnd.help_tooltips["settings_alarm enable"] := hwnd1, vars.hwnd.settings.enable_alarm := vars.hwnd.help_tooltips["settings_alarm enable|"] := hwnd

	If (settings.qol.alarm)
	{
		Gui, %GUI%: Add, Text, % "xs HWNDhwnd0 Section", % "text-size: "
		Gui, %GUI%: Add, Text, % "ys x+0 HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.alarmfont_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*3, % settings.alarm.fSize
		vars.hwnd.settings.alarmfont_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.alarmfont_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth " HWNDhwnd Border Center gSettings_qol2 c"settings.alarm.color, % " color "
		vars.hwnd.settings.color_alarm := vars.hwnd.help_tooltips["settings_generic color"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs HWNDhwnd0 y+"vars.settings.spacing " Section", % "notepad:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.notepad, % "enable"
	vars.hwnd.help_tooltips["settings_notepad enable"] := hwnd0, vars.hwnd.settings.enable_notepad := vars.hwnd.help_tooltips["settings_notepad enable|"] := hwnd

	If (settings.qol.notepad)
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "text-size: "
		Gui, %GUI%: Add, Text, % "ys x+0 HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.notepadfont_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*3, % settings.notepad.fSize
		vars.hwnd.settings.notepadfont_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.notepadfont_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth " HWNDhwnd Border Center gSettings_qol2 c"settings.notepad.color, % " color "
		vars.hwnd.settings.color_notepad := vars.hwnd.help_tooltips["settings_generic color|"] := hwnd
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % "widget opacity: "
		Gui, %GUI%: Add, Text, % "ys x+0 HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.settings.notepadopac_minus := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.notepadopac_plus := hwnd
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % "button-size: "
		Gui, %GUI%: Add, Text, % "ys x+0 HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_button-size"] := hwnd0, vars.hwnd.settings.notepadbutton_minus := vars.hwnd.help_tooltips["settings_button-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.notepadbutton_plus := vars.hwnd.help_tooltips["settings_button-size||"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs HWNDhwnd0 y+"vars.settings.spacing " Section", % "lab overlay:"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.lab, % "enable"
	vars.hwnd.help_tooltips["settings_lab enable"] := hwnd0, vars.hwnd.settings.enable_lab := vars.hwnd.help_tooltips["settings_lab enable|"] := hwnd
}

Settings_qol2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), control1 := SubStr(check, 1, InStr(check, "_") - 1)
	If InStr(check, "enable_")
	{
		settings.qol[control] := LLK_ControlGet(cHWND)
		IniWrite, % settings.qol[control], ini\qol tools.ini, features, % control
		If (control = "alarm") && !settings.qol.alarm
			vars.alarm.timestamp := "", LLK_Overlay(vars.hwnd.alarm.main, "destroy")
		If (control = "notepad")
			Init_GUI("notepad")
		If (control = "notepad") && !settings.qol.notepad
			LLK_Overlay(vars.hwnd.notepad.main, "destroy")
		If (control = "notepad") && !settings.qol.notepad && vars.hwnd.notepad_widgets.Count()
		{
			For key, val in vars.hwnd.notepad_widgets
				LLK_Overlay(val, "destroy")
			vars.hwnd.Delete("notepad_widgets")
		}
		Settings_menu("minor qol tools")
	}
	Else If InStr(check, "color_")
	{
		If (vars.system.click = 1) && !ClipRGB()
			Return
		Else settings[control].color := (vars.system.click = 1) ? ClipRGB() : "White"
		IniWrite, % settings[control].color, ini\qol tools.ini, % control, font-color
		GuiControl, % "+c"settings[control].color, % cHWND
		GuiControl, movedraw, % cHWND
		If (control = "notepad") && vars.hwnd.notepad_widgets.Count()
			For key, val in vars.hwnd.notepad_widgets
				NotepadWidget(key)
		If (control = "notepad") && !vars.hwnd.notepad_widgets.Count()
			LLK_ToolTip("le toucan has arrived", 1.5,,,, settings.notepad.color, settings.notepad.fSize,, settings.notepad.trans)
	}
	Else If InStr(check, "font_")
	{
		control1 := StrReplace(control1, "font")
		While GetKeyState("LButton")
		{
			If (control = "minus") && (settings[control1].fSize > 6)
				settings[control1].fSize -= 1
			Else If (control = "reset")
				settings[control1].fSize := settings.general.fSize
			Else If (control = "plus")
				settings[control1].fSize += 1
			GuiControl, text, % vars.hwnd.settings[control1 "font_reset"], % settings[control1].fSize
			If !(control1 = "notepad" && (WinExist("ahk_id "vars.hwnd.notepad.main) || vars.hwnd.notepad_widgets.Count()))
				LLK_ToolTip((control1 = "alarm") ? "13:37" : "le toucan has arrived",,,,, settings[control1].color, settings[control1].fSize,, settings[control1].trans ? settings[control1].trans : 255)
			If (control = "reset")
				Break
			Sleep 100
		}
		LLK_FontDimensions(settings[control1].fSize, height, width), settings[control1].fWidth := width, settings[control1].fHeight := height
		IniWrite, % settings[control1].fSize, ini\qol tools.ini, % control1, font-size
		If (control1 = "notepad") && WinExist("ahk_id "vars.hwnd.notepad.main)
			Notepad("save"), Notepad()
		If (control1 = "notepad") && vars.hwnd.notepad_widgets.Count()
			For key, val in vars.hwnd.notepad_widgets
				NotepadWidget(key)
	}
	Else If InStr(check, "opac_")
	{
		control1 := StrReplace(control1, "opac")
		If (control = "minus")
			settings[control1].trans -= (settings[control1].trans > 100) ? 30 : 0
		Else If (control = "plus")
			settings[control1].trans += (settings[control1].trans < 250) ? 30 : 0
		settings[control1].trans := (settings[control1].trans < 100) ? 100 : (settings[control1].trans > 250) ? 250 : settings[control1].trans
		IniWrite, % settings[control1].trans, ini\qol tools.ini, % control1, transparency
		If (control1 = "notepad") && !vars.hwnd.notepad_widgets.Count()
			LLK_ToolTip("le toucan has arrived", 1.5,,,, settings.notepad.color, settings.notepad.fSize,, settings.notepad.trans)
		If (control1 = "notepad") && vars.hwnd.notepad_widgets.Count()
			For key, val in vars.hwnd.notepad_widgets
				NotepadWidget(key)
	}
	Else If InStr(check, "button_")
	{
		control1 := StrReplace(control1, "button")
		If (control = "minus")
			settings[control1].oButton -= (settings[control1].oButton > 0.5) ? 0.1 : 0
		Else If (control = "reset")
			settings[control1].oButton := 1
		Else If (control = "plus")
			settings[control1].oButton += (settings[control1].oButton < 1) ? 0.1 : 0
		IniWrite, % settings[control1].oButton, ini\qol tools.ini, % control1, button-offset
		settings[control1].sButton := vars.monitor.w* 0.03* settings[control1].oButton
		GuiButton(control1)
	}
	Else LLK_ToolTip("no action")
}

Settings_screenchecks()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Screen-checks">wiki page</a>
	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "list of active pixel-checks:"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
	Gui, %GUI%: Font, % "norm"
	vars.hwnd.help_tooltips["settings_screenchecks pixel-about"] := hwnd

	For key in vars.pixelsearch.list
	{
		If (key = "inventory") && !(settings.iteminfo.compare || settings.maptracker.mechanics && settings.maptracker.portal_reminder)
			continue
		Gui, %GUI%: Add, Text, % "xs Section border gSettings_screenchecks2 HWNDhwnd", % " info "
		vars.hwnd.settings["info_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-info"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd"(Blank(vars.pixelsearch[key].color1) ? " cRed" : ""), % " cal "
		vars.hwnd.settings["cPixel_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-calibration"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd", % " test "
		vars.hwnd.settings["tPixel_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-test"handle] := hwnd, handle .= "|"
		Gui, %GUI%: Add, Text, % "ys", % key
	}
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "hp xs Section gSettings_screenchecks2 HWNDhwnd Checked"settings.features.pixelchecks, % "enable background pixel-checks"
	vars.hwnd.settings.pixelchecks := vars.hwnd.help_tooltips["settings_screenchecks pixel-background"] := hwnd

	count := 0
	For key in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot)) ;|| (key = "trade" && !settings.qol.trade)
			continue
		count += 1
	}
	If !count
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % "list of active image-checks:"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
	Gui, %GUI%: Font, norm
	vars.hwnd.help_tooltips["settings_screenchecks image-about"] := hwnd, handle := ""

	For key in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot)) ;|| (key = "trade" && !settings.qol.trade)
			continue
		Gui, %GUI%: Add, Text, % "xs Section border gSettings_screenchecks2 HWNDhwnd", % " info "
		vars.hwnd.settings["info_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-info"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd"(!FileExist("img\Recognition (" vars.client.h "p)\GUI\" key ".bmp") ? " cRed" : ""), % " cal "
		vars.hwnd.settings["cImage_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-calibration"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd"(!vars.imagesearch[key].x1 ? " cRed" : ""), % " test "
		vars.hwnd.settings["tImage_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-test"handle] := hwnd, handle .= "|"
		Gui, %GUI%: Add, Text, % "ys", % key
	}
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center Border gSettings_screenchecks2 HWNDhwnd", % " open img folder "
	vars.hwnd.settings.folder := vars.hwnd.help_tooltips["settings_screenchecks folder"] := hwnd
}

Settings_screenchecks2(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If (check = 0)
		check := A_GuiControl

	Switch check
	{
		Case "pixelchecks":
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, settings, background pixel-checks
			settings.features.pixelchecks := LLK_ControlGet(cHWND)
			Return
		Case "folder":
			If FileExist("img\Recognition ("vars.client.h "p)\GUI")
				Run, % "explore img\Recognition ("vars.client.h "p)\GUI\"
			Else LLK_ToolTip("folder doesn't exist",,,,, "red")
			Return
		Default:
			If InStr(check, "Pixel")
			{
				Switch SubStr(check, 1, 1)
				{
					Case "t":
						If Screenchecks_PixelSearch(control)
							LLK_ToolTip("positive",,,,, "lime")
						Else LLK_ToolTip("negative",,,,, "red")
					Case "c":
						Screenchecks_PixelRecalibrate(control)
						LLK_ToolTip("success",,,,, "lime")
						GuiControl, +cWhite, % cHWND
						GuiControl, movedraw, % cHWND
						Settings_ScreenChecksValid()
				}
			}
			Else If InStr(check, "Image")
			{
				Switch SubStr(check, 1, 1)
				{
					Case "t":
						If (Screenchecks_ImageSearch(control) > 0)
						{
							LLK_ToolTip("positive",,,,, "lime")
							GuiControl, +cWhite, % cHWND
							GuiControl, movedraw, % cHWND
							Settings_ScreenChecksValid()
						}
						Else LLK_ToolTip("negative",,,,, "red")
					Case "c":
						pClipboard := Screenchecks_ImageRecalibrate()
						If (pClipboard < 0)
						{
							vars.general.gui_hide := 0
							While !WinExist("ahk_id " vars.hwnd.settings.main)
								sleep, 10
							LLK_ToolTip("screen-cap failed",,,,, "red")
							Return
						}
						Else
						{
							Gdip_SaveBitmapToFile(pClipboard, "img\Recognition (" vars.client.h "p)\GUI\" control ".bmp", 100)
							For key in vars.imagesearch[control]
							{
								If (SubStr(key, 1, 1) = "x" || SubStr(key, 1, 1) = "y") && IsNumber(SubStr(key, 2, 1))
									vars.imagesearch[control][key] := ""
							}
							IniWrite, % "", % "ini\screen checks ("vars.client.h "p).ini", % control, last coordinates
							Gdip_DisposeImage(pClipboard)
							GuiControl, +cWhite, % vars.hwnd.settings["cImage_"control]
							GuiControl, movedraw, % vars.hwnd.settings["cImage_"control]
							GuiControl, +cRed, % vars.hwnd.settings["tImage_"control]
							GuiControl, movedraw, % vars.hwnd.settings["tImage_"control]
							Settings_ScreenChecksValid()
						}
				}
			}
			Else If InStr(check, "info_")
				Screenchecks_Info(control)
			Else LLK_ToolTip("no action")
	}
}

Settings_ScreenChecksValid()
{
	local
	global vars, settings
	
	valid := 1
	For key, val in vars.pixelsearch.list
	{
		If (key = "inventory" && !(settings.iteminfo.compare || settings.maptracker.mechanics && settings.maptracker.portal_reminder))
			continue
		valid *= vars.pixelsearch[key].color1 ? 1 : 0
	}

	For key, val in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot)) ;|| (key = "trade" && !settings.qol.trade)
			continue
		valid *= FileExist("img\Recognition ("vars.client.h "p)\GUI\"key ".bmp") && (vars.imagesearch[key].x1) ? 1 : 0
	}
	
	If valid
		GuiControl, % vars.hwnd.settings.main ": +cWhite", % vars.hwnd.settings["screen-checks"]
	Else GuiControl, % vars.hwnd.settings.main ": +cRed", % vars.hwnd.settings["screen-checks"]
	GuiControl, % vars.hwnd.settings.main ": movedraw", % vars.hwnd.settings["screen-checks"]
}

Settings_searchstrings()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Search-strings">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd x+"2*settings.general.fWidth, <a href="https://poe.re/">poe regex</a>
	vars.hwnd.help_tooltips["settings_searchstrings poe-regex"] := hwnd

	For string, val in vars.searchstrings.list
	{
		If (A_Index = 1)
		{
			Gui, %GUI%: Font, bold underline
			Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % "use-cases currently set up:"
			Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd69", img\GUI\help.png
			Gui, %GUI%: Font, norm
		}
		vars.hwnd.help_tooltips["settings_searchstrings about"] := hwnd69, var := vars.searchstrings.list[string] ;short-cut variable
		color := !var.enable ? "Gray" : !FileExist("img\Recognition ("vars.client.h "p)\GUI\[search-strings] "string ".bmp") ? "Red" : "White", style := !var.enable ? "" : " gSettings_searchstrings2"
		Gui, %GUI%: Add, Text, % "Section xs Border HWNDhwnd c"color style, % " cal "
		vars.hwnd.settings["cal_"string] := vars.hwnd.help_tooltips["settings_searchstrings calibrate"handle] := hwnd
		color := !var.enable ? "Gray" : !var.x1 ? "Red" : "White"
		Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd x+"settings.general.fWidth/4 " c"color style, % " test "
		vars.hwnd.settings["test_"string] := vars.hwnd.help_tooltips["settings_searchstrings test"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys Border cWhite gSettings_searchstrings2 HWNDhwnd x+"settings.general.fWidth/4, % " edit "
		vars.hwnd.settings["edit_"string] := vars.hwnd.help_tooltips["settings_searchstrings edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd0 x+"settings.general.fWidth/4 " c"(string = "beast crafting" ? "Gray" : "White") (string = "beast crafting" ? "" : " gSettings_searchstrings2"), % " del "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled cRed range0-500 HWNDhwnd", 0
		vars.hwnd.settings["del_"string] := hwnd0, vars.hwnd.settings["delbar_"string] := vars.hwnd.help_tooltips["settings_searchstrings delete"handle] := hwnd
		color := !var.enable ? "Gray" : "White"
		Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " c"color " gSettings_searchstrings2 HWNDhwnd Checked"vars.searchstrings.list[string].enable, % string
		vars.hwnd.settings["enable_"string] := vars.hwnd.help_tooltips["settings_searchstrings enable"(string = "hideout lilly" ? "-lilly" : (string = "beast crafting" ? "-beastcrafting" : "")) handle] := hwnd, handle .= "|"
	}

	Gui, %GUI%: Add, Text, % "Section xs HWNDhwnd0 y+"vars.settings.spacing, % "add use-case: "
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden default HWNDhwnd gSettings_searchstrings2", ok
	vars.hwnd.help_tooltips["settings_searchstrings add"] := hwnd0, vars.hwnd.settings.add := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys cBlack x+0 hp HWNDhwnd w"settings.general.fWidth*15
	vars.hwnd.settings.name := vars.hwnd.help_tooltips["settings_searchstrings add|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
}

Settings_searchstrings2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If InStr(check, "cal_")
	{
		pBitmap := Screenchecks_ImageRecalibrate()
		If (pBitmap > 0)
		{
			Gdip_SaveBitmapToFile(pBitmap, "img\Recognition ("vars.client.h "p)\GUI\[search-strings] "control ".bmp", 100)
			Gdip_DisposeImage(pBitmap)
			IniDelete, % "ini\search-strings.ini", % control, last coordinates
			Settings_menu("search-strings")
		}
	}
	Else If InStr(check, "test_")
	{
		If StringSearch(control)
		{
			GuiControl, +cWhite, % vars.hwnd.settings["test_"control]
			GuiControl, movedraw, % vars.hwnd.settings["test_"control]
			Init_searchstrings()
		}
	}
	Else If InStr(check, "edit_")
		StringMenu(control)
	Else If InStr(check, "del_")
	{
		If LLK_Progress(vars.hwnd.settings["delbar_"control], "LButton")
		{
			IniDelete, ini\search-strings.ini, searches, % control
			IniDelete, ini\search-strings.ini, % control
			Settings_menu("search-strings")
		}
		Else Return
	}
	Else If InStr(check, "enable_")
	{
		IniWrite, % LLK_ControlGet(cHWND), ini\search-strings.ini, searches, % control
		Settings_menu("search-strings")
	}
	Else If (check = "add")
	{
		name := LLK_ControlGet(vars.hwnd.settings.name)
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.settings.name
		While (SubStr(name, 1, 1) = " ")
			name := SubStr(name, 2)
		While (SubStr(name, 0) = " ")
			name := SubStr(name, 1, -1)
		If (name = "searches" || name = "exile-leveling")
			error := ["invalid name", 1]
		If vars.searchstrings.list.HasKey(name)
			error := ["name already in use", 1.5]
		Loop, Parse, name
			If !LLK_IsType(A_LoopField, "alnum")
				error := ["regular letters, spaces,`nand numbers only", 2]
		If (name = "")
			error := ["name cannot be blank", 1.5]
		If error.1
		{
			LLK_ToolTip(error.1, error.2, x, y + h,, "red")
			Return
		}
		IniWrite, 1, ini\search-strings.ini, searches, % name
		IniWrite, % "", ini\search-strings.ini, % name, last coordinates
		Settings_menu("search-strings")
	}
	Else LLK_ToolTip("no action")
}

Settings_updater()
{
	local
	global vars, settings

	GUI := vars.hwnd.settings.main
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, general settings:
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "Section xs HWNDhwnd gSettings_updater2 checked"settings.updater.update_check, automatically check for updates
	vars.hwnd.settings.update_check := vars.hwnd.help_tooltips["settings_update check"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section xs y+"vars.settings.spacing, version information:
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Text, % "Section xs Center Border HWNDpage gSettings_updater2", % " github page "
	Gui, %GUI%: Add, Text, % "ys Center Border HWNDreleases gSettings_updater2", % " releases "
	vars.hwnd.settings["githubpage_"(InStr(LLK_FileRead("data\versions.json"), "main.zip") ? "main" : "beta")] := page, vars.hwnd.settings.releases_page := releases
	Gui, %GUI%: Add, Text, % "ys Center Border BackgroundTrans HWNDhwnd gSettings_updater2", % " refresh "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Disabled Border HWNDhwnd0 BackgroundBlack cGreen Range0-10", 0
	vars.hwnd.settings.update_refresh := hwnd, vars.hwnd.settings.update_refresh_bar := hwnd0

	Gui, %GUI%: Add, Text, % "Section xs", % "current: "vars.updater.version.2
	color := vars.updater.skip && (vars.updater.latest.1 = vars.updater.skip) ? " cYellow" : (IsNumber(vars.updater.latest.1) && vars.updater.latest.1 > vars.updater.version.1) ? " cLime" : ""
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth*2 color, % "latest: "vars.updater.latest.2
	If IsNumber(vars.updater.latest.1) && (vars.updater.latest.1 > vars.updater.version.1) && (vars.updater.latest.1 != vars.updater.skip)
	{
		Gui, %GUI%: Add, Text, % "Section xs Border Center BackgroundTrans gSettings_updater2 HWNDhwnd", % " restart && install "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd0", 0
		ControlGetPos,,, wButton,,, ahk_id %hwnd%
		If IsObject(vars.updater.changelog)
		{
			Gui, %GUI%: Add, Text, % "ys Border Center HWNDchangelog", % " changelog "
			vars.hwnd.help_tooltips["settings_update changelog"] := changelog
		}
		vars.hwnd.settings.restart_install := hwnd, vars.hwnd.settings.restart_bar := vars.hwnd.help_tooltips["settings_update restart"] := hwnd0
		Gui, %GUI%: Add, Text, % "Section xs Border Center BackgroundTrans gSettings_updater2 HWNDhwnd w"wButton, % " skip this version "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd0", 0
		vars.hwnd.settings.skip := hwnd, vars.hwnd.settings.skip_bar := vars.hwnd.help_tooltips["settings_update skip"] := hwnd0
	}
	If IsNumber(vars.update.1) && (vars.update.1 < 0)
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "Section xs cRed y+"vars.settings.spacing, update failed:
		Gui, %GUI%: Font, norm
	}
	
	If IsNumber(vars.update.1) && (vars.update.1 < 0)
	{
		If InStr("126", StrReplace(vars.update.1, "-"))
		{
			Gui, %GUI%: Add, Text, % "Section xs", the last update attempt failed because`nof write-permission errors. please open`nthe <general> section of the settings`nand run the test at the bottom.`n
			Gui, %GUI%: Add, Text, % "Section xs y+0", fixing these issues is critical not`njust for the updater but for many`nother features as well.
		}
		Else If (vars.update.1 = -4)
		{
			Gui, %GUI%: Add, Text, % "Section xs", the last update attempt failed because`nthe script couldn't download the`nlatest version-list. this could be a`nrandom error that will fix itself on`nthe next try.`n
			Gui, %GUI%: Add, Text, % "Section xs y+0", if it doesn't fix itself, you'll have`nto update manually.
		}
		Else If (vars.update.1 = -3)
		{
			Gui, %GUI%: Add, Text, % "Section xs", the last update attempt failed because`nthe script couldn't verify the`ncurrent version-list. this indicates a`ndamaged installation and needs to be`nfixed manually as soon as possible.
		}
		Else If InStr("5", StrReplace(vars.update.1, "-"))
		{
			Gui, %GUI%: Add, Text, % "Section xs", the last update attempt failed because`nsome files couldn't be downloaded.`nthis could be a random error that`nwill fix itself on the next try.`n
			Gui, %GUI%: Add, Text, % "Section xs y+0", if it doesn't fix itself, you'll have`nto update manually.
		}
		If InStr("345", StrReplace(vars.update.1, "-"))
		{
			Gui, %GUI%: Add, Text, % "Section xs Center Border BackgroundTrans HWNDmanual gSettings_updater2 y+"vars.settings.spacing, % " update manually "
			Gui, %GUI%: Add, Progress, % "xp yp wp hp Border HWNDbar range0-10 BackgroundBlack cGreen", 0
			Gui, %GUI%: Add, Text, % "ys Center Border HWNDgithub gSettings_updater2", % " github download "
			vars.hwnd.settings.manual := manual, vars.hwnd.settings.manual_bar := vars.hwnd.help_tooltips["settings_update manual"] := bar, vars.hwnd.settings.github := vars.hwnd.help_tooltips["settings_update github"] := github
		}
	}
}

Settings_updater2(cHWND := "")
{
	local
	global vars, settings, Json
	static in_progress, refresh_tick

	If in_progress
		Return
	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If InStr(check, "githubpage_")
		Run, % "https://github.com/Lailloken/Lailloken-UI/tree/"control
	Else If (check = "releases_page")
		Run, % "https://github.com/Lailloken/Lailloken-UI/releases"
	Else If (check = "update_check")
	{
		settings.updater.update_check := LLK_ControlGet(cHWND)
		IniWrite, % settings.updater.update_check, ini\config.ini, settings, update auto-check
	}
	Else If (check = "update_refresh")
	{
		If vars.updater.latest.2 && (A_TickCount < refresh_tick + 10000)
			Return
		in_progress := 1, UpdateCheck(1)
		Loop 10
		{
			GuiControl,, % vars.hwnd.settings.update_refresh_bar, % A_Index
			Sleep 25
		}
		in_progress := 0
		refresh_tick := A_TickCount, Settings_menu("updater")
	}
	Else If (check = "restart_install")
	{
		If LLK_Progress(vars.hwnd.settings.restart_bar, "LButton")
		{
			KeyWait, LButton
			IniWrite, 1, ini\config.ini, versions, apply update
			Reload
			ExitApp
		}
	}
	Else If (check = "manual")
	{
		in_progress := 1, UpdateDownload(vars.hwnd.settings.manual_bar)
		UrlDownloadToFile, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/heads/"vars.update.2 ".zip", % "update\update_"vars.updater.latest.1 ".zip"
		error := ErrorLevel || !FileExist("update\update_"vars.updater.latest.1 ".zip") ? 1 : 0
		in_progress := 0
		SetTimer, UpdateDownload, Delete
		UpdateDownload("reset")
		If error
		{
			LLK_ToolTip("download failed,`nuse the github button", 2,,,, "red")
			Return
		}
		Run, explore %A_ScriptDir%
		Run, % "update\update_"vars.updater.latest.1 ".zip"
		ExitApp
	}
	Else If (check = "github")
	{
		Run, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/heads/"vars.update.2 ".zip"
		Run, explore %A_ScriptDir%
		ExitApp
	}
	Else If (check = "skip")
	{
		If LLK_Progress(vars.hwnd.settings.skip_bar, "LButton")
		{
			KeyWait, LButton
			vars.updater.skip := vars.updater.latest.1, vars.update := [0]
			IniWrite, % vars.updater.latest.1, ini\config.ini, versions, skip
			Gui, LLK_panel: Color, Black
			Settings_menu("updater")
		}
	}
	Else LLK_ToolTip("no action")
}

Settings_WriteTest()
{
	local
	global vars, settings
	static running

	If (A_GuiControl = " restart script as admin ")
	{
		IniWrite, % vars.settings.active, ini\config.ini, Versions, reload settings
		Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
		ExitApp
	}
	
	If running
		Return
	running := 1, HWND_bar := vars.hwnd.settings.bar_writetest
	FileRemoveDir, data\write-test\, 1
	If FileExist("data\write-test\")
	{
		running := 0
		MsgBox,, Write-permissions test, There are some leftover files from a previous test, and the script cannot delete them.`n`nPlease delete the 'write-test' folder within the folder that will open after closing this message.
		Run, explore %A_WorkingDir%\data\
		Return
	}
	If A_IsAdmin
		status .= "script launched with admin rights: yes`n`n"
	Else status .= "script launched with admin rights: no`n`n"
	FileCreateDir, data\write-test\
	GuiControl,, % HWND_bar, 100
	sleep, 250
	If FileExist("data\write-test\")
	{
		status .= "can create folders: yes`n`n"
		folder_creation := 1
	}
	Else status .= "can create folders: no`n`n"
	
	FileAppend,, data\write-test.ini
	GuiControl,, % HWND_bar, 200
	sleep, 250
	If FileExist("data\write-test.ini")
	{
		status .= "can create ini-files: yes`n`n"
		ini_creation := 1
	}
	Else status .= "can create ini-files: no`n`n"
	
	IniWrite, 1, data\write-test.ini, write-test, test
	GuiControl,, % HWND_bar, 300
	sleep, 250
	IniRead, ini_test, data\write-test.ini, write-test, test, 0
	If ini_test
		status .= "can write to ini-files: yes`n`n"
	Else status .= "can write to ini-files: no`n`n"
	
	pWriteTest := Gdip_BitmapFromScreen("0|0|100|100")
	Gdip_SaveBitmapToFile(pWriteTest, "data\write-test.bmp", 100)
	Gdip_DisposeImage(pWriteTest)
	GuiControl,, % HWND_bar, 400
	sleep, 250
	If FileExist("data\write-test.bmp")
	{
		status .= "can create image-files: yes`n`n"
		img_creation := 1
	}
	Else status .= "can create image-files: no`n`n"
	
	If folder_creation
	{
		FileRemoveDir, data\write-test\
		sleep, 250
		If !FileExist("data\write-test\")
			status .= "can delete folders: yes`n`n"
		Else status .= "can delete folders: no`n`n"
	}
	Else status .= "can delete folders: unknown`n`n"
	GuiControl,, % HWND_bar, 500
	
	If ini_creation
	{
		FileDelete, data\write-test.ini
		sleep, 250
		If !FileExist("data\write-test.ini")
			status .= "can delete ini-files: yes`n`n"
		Else status .= "can delete ini-files: no`n`n"
	}
	Else status .= "can delete ini-files: unknown`n`n"
	GuiControl,, % HWND_bar, 600
	
	If img_creation
	{
		FileDelete, data\write-test.bmp
		sleep, 250
		If !FileExist("data\write-test.bmp")
			status .= "can delete image-files: yes`n`n"
		Else status .= "can delete image-files: no`n`n"
	}
	Else status .= "can delete image-files: unknown`n`n"
	GuiControl,, % HWND_bar, 700
	
	MsgBox, 4096, Test results, % status
	GuiControl,, % HWND_bar, 0
	running := 0
}
