Settings_betrayal()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Betrayal-Info">wiki page</a>

	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_betrayal2 HWNDhwnd Checked"settings.features.betrayal, % LangTrans("m_betrayal_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_betrayal enable"] := hwnd

	If !settings.features.betrayal
		Return

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_betrayal2 HWNDhwnd Checked"settings.betrayal.ruthless, % LangTrans("m_betrayal_ruthless")
	vars.hwnd.settings.ruthless := vars.hwnd.help_tooltips["settings_betrayal ruthless"] := hwnd

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_betrayal_recognition", 1)
	Gui, %GUI%: Font, % "norm"

	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans Border gSettings_betrayal2 HWNDhwnd", % " " LangTrans("global_imgfolder") " "
	vars.hwnd.settings.folder := hwnd, vars.hwnd.help_tooltips["settings_betrayal folder"] := hwnd

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, % "norm"

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/2 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*2, % "–"
	vars.hwnd.settings.mFont := hwnd, vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*3, % settings.betrayal.fSize
	vars.hwnd.settings.rFont := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd gSettings_betrayal2 Border w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.pFont := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("m_betrayal_colors")
	Loop 3
	{
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/(A_Index = 1 ? 2 : 4) " Center HWNDhwnd gSettings_betrayal2 Border c"settings.betrayal.colors[A_Index], % " " LangTrans("global_tier") " " A_Index " "
		handle .= "|", vars.hwnd.settings["tier"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_betrayal color"] := hwnd0, vars.hwnd.help_tooltips["settings_betrayal color"handle] := hwnd
	}

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_betrayal_rewards")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_betrayal rewards"] := hwnd
	Gui, %GUI%: Font, % "norm"
	wMembers := []
	For key in vars.betrayal.members ; create an array with every member in order to find the widest
		wMembers.Push(LangTrans("betrayal_" key))
	LLK_PanelDimensions(wMembers, settings.betrayal.fSize, width, height)

	For member_loc, member in vars.betrayal.members_localized
	{
		If (A_Index = 1)
			pos := "Section xs"
		Else If Mod(A_Index - 1, 6)
			pos := "xs y+"settings.general.fWidth/4
		Else pos := "Section ys x+"settings.general.fWidth/4
		Gui, %GUI%: Add, Text, % pos " Border gSettings_betrayal2 HWNDhwnd w"width, % " " LangTrans("betrayal_" member)
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
		Init_betrayal(), Settings_menu("betrayal-info")
	}
	Else If (check = "folder")
	{
		If FileExist("img\Recognition ("vars.client.h "p)\Betrayal\")
			Run, % "explore img\Recognition ("vars.client.h "p)\Betrayal\"
		Else LLK_ToolTip(LangTrans("cheat_filemissing"))
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
	}
	Else If InStr(check, "tier")
	{
		If (vars.system.click = 1)
			picked_rgb := RGB_Picker(settings.betrayal.colors[StrReplace(check, "tier")])
		If (vars.system.click = 1) && Blank(picked_rgb)
			Return
		Else color := (vars.system.click = 2) ? settings.betrayal.dColors[StrReplace(check, "tier")] : picked_rgb
		GuiControl, +c%color%, % cHWND
		GuiControl, movedraw, % cHWND
		IniWrite, % color, ini\betrayal info.ini, settings, % "rank "StrReplace(check, "tier") " color"
		settings.betrayal.colors[StrReplace(check, "tier")] := color
	}
	Else If vars.betrayal.members.HasKey(check)
	{
		BetrayalInfo(check)
		KeyWait, LButton
		vars.hwnd.betrayal_info.active := "", LLK_Overlay(vars.hwnd.betrayal_info.main, "destroy")
	}
	Else LLK_ToolTip("no action")
}

Settings_cheatsheets()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, Init_cheatsheets()
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Cheat-sheet-Overlay-Toolkit">wiki page</a>

	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_cheatsheets2 HWNDhwnd Checked"settings.features.cheatsheets, % LangTrans("m_cheat_enable")
	vars.hwnd.settings.feature := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets enable"] := hwnd
	If !settings.features.cheatsheets
		Return

	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_cheat_hotkeys")
	Gui, %GUI%: Font, % "norm"

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("m_cheat_modifier")
	Loop, Parse, % "alt, ctrl, shift", `,, %A_Space%
	{
		Gui, %GUI%: Add, Radio, % "ys x+" (A_Index = 1 ? settings.general.fWidth/2 : 0) " hp HWNDhwnd gSettings_cheatsheets2 checked"(settings.cheatsheets.modifier = A_LoopField ? 1 : 0), % LangTrans("m_cheat_modifier", A_Index + 1)
		handle .= "|", vars.hwnd.settings["modifier_"A_LoopField] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets modifier-key"] := hwnd0, vars.hwnd.help_tooltips["settings_cheatsheets modifier-key"handle] := hwnd
	}

	If vars.cheatsheets.count_advanced
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % LangTrans("global_ui") " " LangTrans("m_cheat_advance")
		Gui, %GUI%: Font, norm

		Loop 4
		{
			style := (A_Index = 1) ? "xs Section" : "ys x+"settings.general.fWidth/4, handle1 .= "|"
			Gui, %GUI%: Add, Text, % style " Center Border HWNDhwnd gSettings_cheatsheets2 c"settings.cheatsheets.colors[A_Index], % " " LangTrans("global_color")" " A_Index " "
			vars.hwnd.settings["color"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets color"handle1] := hwnd
		}

		Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans HWNDhwnd0", % LangTrans("global_font")
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := hwnd, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*3, % settings.cheatsheets.fSize
		vars.hwnd.settings.font_reset := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center HWNDhwnd Border gSettings_cheatsheets2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.font_plus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_cheat_create")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans", % LangTrans("global_name")
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+" settings.general.fWidth/2 " w"settings.general.fWidth*10 " cBlack HWNDhwnd",
	vars.hwnd.settings.name := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd0 x+"settings.general.fWidth, % LangTrans("global_type")
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, DDL, % "ys hp x+" settings.general.fWidth/2 " w"settings.general.fWidth*8 " r10 cBlack HWNDhwnd", % LangTrans("m_cheat_images") "||" LangTrans("m_cheat_app") "|" LangTrans("m_cheat_advanced") "|"
	vars.hwnd.help_tooltips["settings_cheatsheets types"] := hwnd0, vars.hwnd.settings.type := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets types|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Text, % "ys hp Border gSettings_cheatsheets2 HWNDhwnd", % " " LangTrans("global_add") " "
	vars.hwnd.settings.add := hwnd, handle := ""

	For cheatsheet in vars.cheatsheets.list
	{
		If (A_Index = 1)
		{
			Gui, %GUI%: Font, bold underline
			Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % LangTrans("m_cheat_list")
			Gui, %GUI%: Font, norm
		}

		If !IsNumber(vars.cheatsheets.list[cheatsheet].enable)
			vars.cheatsheets.list[cheatsheet].enable := LLK_IniRead("cheat-sheets\"cheatsheet "\info.ini", "general", "enable", 1)
		color := !vars.cheatsheets.list[cheatsheet].enable ? " cGray" : !FileExist("cheat-sheets\"cheatsheet "\[check].*") ? " cRed" : "", handle .= "|"
		Gui, %GUI%: Add, Text, % "xs Section border HWNDhwnd y+"settings.general.fSize*0.4 color (vars.cheatsheets.list[cheatsheet].enable ? " gSettings_cheatsheets2" : ""), % " " LangTrans("global_calibrate") " "
		vars.hwnd.settings["calibrate_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets calibrate"handle] := (color = " cGray") ? "" : hwnd
		color := !vars.cheatsheets.list[cheatsheet].enable ? " cGray" : !vars.cheatsheets.list[cheatsheet].x1 ? " cRed" : ""
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border HWNDhwnd" color (vars.cheatsheets.list[cheatsheet].enable ? " gSettings_cheatsheets2" : ""), % " " LangTrans("global_test") " "
		vars.hwnd.settings["test_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets test"handle] := (color = " cGray") ? "" : hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border HWNDhwnd gSettings_cheatsheets2", % " " LangTrans("global_edit") " "
		vars.hwnd.settings["edit_"cheatsheet] := hwnd, vars.hwnd.help_tooltips["settings_cheatsheets edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " border BackgroundTrans gSettings_cheatsheets2 HWNDhwnd0", % " " LangTrans("global_delete", 2) " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp border BackgroundBlack Disabled cRed range0-500 HWNDhwnd", 0
		vars.hwnd.settings["delbar_"cheatsheet] := vars.hwnd.help_tooltips["settings_cheatsheets delete"handle] := hwnd, vars.hwnd.settings["delete_"cheatsheet] := hwnd0
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fSize/4 " Center gSettings_cheatsheets2 Border HWNDhwnd", % " " LangTrans("global_info") " "
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
			LLK_FilePermissionError("create", A_ScriptDir "\cheat-sheets")
			GuiControl,, % cHWND, 0
			Return
		}
		IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, features, enable cheat-sheets
		settings.features.cheatsheets := LLK_ControlGet(cHWND)
		If !settings.features.cheatsheets
			LLK_Overlay(vars.hwnd.cheatsheet.main, "hide"), LLK_Overlay(vars.hwnd.cheatsheet_menu.main, "hide")
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
			picked_rgb := RGB_Picker(settings.cheatsheets.colors[control])
		If (vars.system.click = 1) && Blank(picked_rgb)
			Return
		Else color := (vars.system.click = 2) ? settings.cheatsheets.dColors[control] : picked_rgb
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
			LLK_ToolTip(LangTrans("global_positive"),,,,, "Lime")
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
	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames">wiki page</a>

	If (vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") || vars.log.file_location) && settings.features.pixelchecks
	{
		Gui, %GUI%: Font, underline bold
		Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_clone_toggle")
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
		Gui, %GUI%: Font, norm
		vars.hwnd.help_tooltips["settings_cloneframes toggle-info"] := hwnd
	}

	If vars.pixelsearch.gamescreen.x1 && (vars.pixelsearch.gamescreen.x1 != "ERROR") && settings.features.pixelchecks
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.pixelchecks, % LangTrans("m_clone_gamescreen")
		vars.hwnd.settings.hide_menu := hwnd, vars.hwnd.help_tooltips["settings_cloneframes pixelchecks"] := hwnd
	}
	If vars.log.file_location
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_cloneframes2 HWNDhwnd Checked"settings.cloneframes.hide, % LangTrans("m_clone_hideout")
		vars.hwnd.settings.hide_town := hwnd, vars.hwnd.help_tooltips["settings_cloneframes hideout"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % LangTrans("m_clone_list")
	WinGetPos,,, width,, % "ahk_id " hwnd
	Gui, %GUI%: Font, norm
	LLK_PanelDimensions([LangTrans("m_clone_new")], settings.general.fSize, width0, height0), LLK_PanelDimensions([LangTrans("global_edit"), LangTrans("global_delete", 2)], settings.general.fSize, width1, height1), width0 := Floor(width0), width1 := Floor(width1)
	While Mod(width0, 2)
		width += 1
	If (width0 >= 2 * width1)
		width1 := width0 / 2
	Else width0 := 2 * width1
	Gui, %GUI%: Add, Text, % "xs Section Border gSettings_cloneframes2 HWNDhwnd Center w"width0, % LangTrans("m_clone_new")
	vars.hwnd.settings.add := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new"] := hwnd
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default gSettings_cloneframes2 HWNDhwnd", % "ok"
	vars.hwnd.settings.add2 := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd w"width - width0 - settings.general.fWidth * 0.75
	vars.hwnd.settings.name := hwnd, vars.hwnd.help_tooltips["settings_cloneframes new|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	For cloneframe, val in vars.cloneframes.list
	{
		If (cloneframe = "settings_cloneframe")
			continue
		Gui, %GUI%: Add, Text, % "xs w"width1 " Section Border Center gSettings_cloneframes2 HWNDhwnd", % LangTrans("global_edit")
		handle .= "|", vars.hwnd.settings["edit_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys hp x+0 w"width1 " Border gSettings_cloneframes2 BackgroundTrans Center HWNDhwnd0", % LangTrans("global_delete", 2)
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack range0-500 cRed HWNDhwnd", 0
		vars.hwnd.settings["delbar_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes delete"handle] := hwnd, vars.hwnd.settings["del_"cloneframe] := hwnd0
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_cloneframes2 HWNDhwnd Checked"val.enable " c"(val.enable ? "White" : "Gray"), % cloneframe
		vars.hwnd.settings["enable_"cloneframe] := vars.hwnd.help_tooltips["settings_cloneframes toggle"handle] := hwnd
		Gui, %GUI%: Font, norm
	}

	If (vars.cloneframes.list.Count() = 1)
		Return

	LLK_PanelDimensions([LangTrans("global_coordinates"), LangTrans("global_width") "/" LangTrans("global_height")], settings.general.fSize, width, height)
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd y+"vars.settings.spacing, % LangTrans("m_clone_editing")
	colors := ["3399FF", "Yellow", "DC3220"], handle := "", vars.hwnd.settings.edit_text := vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	Gui, %GUI%: Font, norm
	For index, val in vars.lang.global_mouse
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/2 " Center BackgroundTrans Border cBlack w"settings.general.fWidth*3, % val
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd c"colors[index], 100
		handle .= "|", vars.hwnd.help_tooltips["settings_cloneframes corners"handle] := hwnd
	}
	Gui, %GUI%: Add, Text, % "xs Section c3399FF", % LangTrans("global_coordinates") ":"
	Gui, %GUI%: Font, % "s" settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x" x_anchor + width " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.x + 4 - vars.monitor.x
	vars.hwnd.settings.xSource := vars.cloneframes.scroll.xSource := vars.hwnd.help_tooltips["settings_cloneframes scroll"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.y + 4 - vars.monitor.y
	vars.hwnd.settings.ySource := vars.cloneframes.scroll.ySource := vars.hwnd.help_tooltips["settings_cloneframes scroll|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "ys", % LangTrans("m_clone_scale")
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+" settings.general.fWidth/2 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*3, 100
	vars.hwnd.settings.xScale := vars.cloneframes.scroll.xScale := vars.hwnd.help_tooltips["settings_cloneframes scroll||||||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*3, 100
	vars.hwnd.settings.yScale := vars.cloneframes.scroll.yScale := vars.hwnd.help_tooltips["settings_cloneframes scroll|||||||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "xs Section cYellow", % LangTrans("global_coordinates") ":"
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x" x_anchor + width " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % Format("{:0.0f}", vars.client.xc - 100)
	vars.hwnd.settings.xTarget := vars.cloneframes.scroll.xTarget := vars.hwnd.help_tooltips["settings_cloneframes scroll||||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % vars.client.y + 13 - vars.monitor.y
	vars.hwnd.settings.yTarget := vars.cloneframes.scroll.yTarget := vars.hwnd.help_tooltips["settings_cloneframes scroll|||||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "ys", % LangTrans("global_opacity")
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " 0x200 hp Border Center HWNDhwnd w"settings.general.fWidth*2, 5
	;Gui, %GUI%: Add, UpDown, % "ys hp Disabled range0-5 gSettings_cloneframes2 HWNDhwnd", 5
	vars.hwnd.settings.opacity := vars.cloneframes.scroll.opacity := vars.hwnd.help_tooltips["settings_cloneframes scroll||||||||"] := hwnd

	Gui, %GUI%: Add, Text, % "xs Section cDC3220", % LangTrans("global_width") "/" LangTrans("global_height") ":"
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x" x_anchor + width " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % 200
	vars.hwnd.settings.width := vars.cloneframes.scroll.width := vars.hwnd.help_tooltips["settings_cloneframes scroll||"] := hwnd
	Gui, %GUI%: Add, Edit, % "ys x+"settings.general.fWidth/4 " hp Disabled Number cBlack Right gCloneframesSettingsApply HWNDhwnd w"settings.general.fWidth*4, % 200
	vars.hwnd.settings.height := vars.cloneframes.scroll.height := vars.hwnd.help_tooltips["settings_cloneframes scroll|||"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	Gui, %GUI%: Add, Text, % "xs Section cGray Border HWNDhwnd", % " " LangTrans("global_save") " "
	vars.hwnd.settings.save := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " cGray Border HWNDhwnd", % " " LangTrans("global_discard") " "
	vars.hwnd.settings.discard := hwnd
}

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
			LLK_ToolTip(LangTrans("m_clone_exitedit"), 1.5,,,, "red")
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
			LLK_ToolTip(LangTrans("m_clone_exitedit"), 1.5,,,, "red")
			GuiControl,, % cHWND, % vars.cloneframes.list[control].enable
			Return
		}
		vars.cloneframes.list[control].enable := LLK_ControlGet(cHWND)
		GuiControl, % "+c"(LLK_ControlGet(cHWND) ? "White" : "Gray"), % cHWND
		GuiControl, movedraw, % cHWND
		IniWrite, % vars.cloneframes.list[control].enable, ini\clone frames.ini, % control, enable
		Init_cloneframes()
		GuiControl, % "+c" (!vars.cloneframes.enabled ? "Gray" : "White"), % vars.hwnd.settings["clone-frames"]
		GuiControl, % "movedraw", % vars.hwnd.settings["clone-frames"]
	}
	Else If (check = "save")
		CloneframesSettingsSave()
	Else If (check = "discard")
		CloneframesSettingsRefresh()
	Else If (check = "opacity")
		vars.cloneframes.list[name].opacity := LLK_ControlGet(cHWND)
	Else LLK_ToolTip("no action")
}

Settings_donations()
{
	local
	global vars, settings, JSON
	static last_update, live_list, patterns := [["000000", "F99619"], ["000000", "F05A23"], ["FFFFFF", "F05A23"], ["Red", "FFFFFF"]]
	, placeholder := "these are placeholders, not actual donations:`ncouldn't download the list, or it doesn't exist yet"

	If !vars.settings.donations
		vars.settings.donations := {"Le Toucan": [1, ["june 17, 2024:`ni have arrived. caw, caw"]], "Lightwoods": [4, ["december 23, 2015:`ni can offer you 2 exalted orbs for your mirror", "december 23, 2015:`nsince i'm feeling happy today, i'll give you some maps on top", "december 23, 2015:`n<necropolis map> 5 of these?"]], "Average Redditor": [1, ["june 18, 2024:`nbruh, just enjoy the game"]], "Sanest Redditor": [3, ["august 5, 2023:`nyassss keep making more powerful and intrusive tools so ggg finally bans all ahk scripts"]], "ILoveLootsy": [2, ["february 1, 2016:`ndang yo"]]}

	If (last_update + 120000 < A_TickCount)
	{
		Try donations_new := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/img/readme/donations.json")
		If (SubStr(donations_new, 1, 1) . SubStr(donations_new, 0) = "{}")
			vars.settings.donations := JSON.load(donations_new), live_list := 1
	}

	last_update := A_TickCount, dimensions := [], rearrange := []
	For key, val in vars.settings.donations
		If !val.0
			new_key := LLK_PanelDimensions([key], settings.general.fSize, width0, height0,,,, 1), dimensions.Push(new_key), rearrange.Push([key, new_key])
		Else dimensions.Push(key)

	For index, val in rearrange
	{
		If (val.1 != val.2)
			vars.settings.donations[val.2] := vars.settings.donations[val.1].Clone(), vars.settings.donations.Delete(val.1)
		vars.settings.donations[val.2].0 := 1
	}

	LLK_PanelDimensions(dimensions, settings.general.fSize - 2, width, height), LLK_PanelDimensions([placeholder], settings.general.fSize, wPlaceholder, hPlaceholder,,, 0)
	columns := wPlaceholder//width
	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Text, % "Section x" x_anchor " y" vars.settings.yselection, special thanks to these people for donating:
	Gui, %GUI%: Font, % "s" settings.general.fSize - 2
	For key, val in vars.settings.donations
	{
		pos := (A_Index = 1) || !Mod(A_Index - 1, columns) ? "xs Section" (A_Index = 1 ? " y+" vars.settings.spacing : "") : "ys"
		Gui, %GUI%: Add, Text, % pos " Center Border HWNDhwnd BackgroundTrans w" width " h" height " c" patterns[val.1].1 . (!InStr(key, "`n") ? " 0x200" : ""), % key
		Gui, %GUI%: Add, Progress, % "xp+3 yp+3 wp-6 hp-6 Disabled HWNDhwnd Background" patterns[val.1].2, 0
		Gui, %GUI%: Add, Progress, % "xp-3 yp-3 wp+6 hp+6 Disabled Background" patterns[val.1].1, 0
		vars.hwnd.help_tooltips["donation_" key] := hwnd
	}
	Gui, %GUI%: Font, % "s" settings.general.fSize
	If !live_list
		Gui, %GUI%: Add, Text, % "xs Section cAqua y+" vars.settings.spacing, % placeholder
	Gui, %GUI%: Add, Link, % "xs Section y+" vars.settings.spacing, <a href="https://github.com/Lailloken/Lailloken-UI/discussions/407">how to donate</a>
}

Settings_general()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki">llk-ui wiki && setup guide</a>

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_general_settings")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Checkbox, % "xs Section hp gSettings_general2 HWNDhwnd Checked" settings.general.kill[1], % LangTrans("m_general_kill")
	vars.hwnd.settings.kill_timer := hwnd, vars.hwnd.help_tooltips["settings_kill timer"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fsize - 4 "norm"
	Gui, %GUI%: Add, Edit, % "ys x+0 hp cBlack Number gSettings_general2 Center Limit2 HWNDhwnd w"2* settings.general.fwidth, % settings.general.kill[2]
	vars.hwnd.settings.kill_timeout := hwnd, vars.hwnd.help_tooltips["settings_kill timer|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fsize
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_general2 Checked"settings.features.browser, % LangTrans("m_general_browser")
	vars.hwnd.settings.browser := hwnd, vars.hwnd.help_tooltips["settings_browser features"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys HWNDhwnd gSettings_general2 Checked" settings.general.capslock, % LangTrans("m_general_capslock")
	vars.hwnd.settings.capslock := hwnd, vars.hwnd.help_tooltips["settings_capslock toggling"] := hwnd, check := ""

	If vars.log.file_location
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd c"(settings.general.lang_client = "unknown" ? "Gray" : vars.log.level ? "Lime" : settings.general.character ? "Yellow" : "Red"), % LangTrans("m_general_character") " "
		vars.hwnd.settings.character_text := hwnd
		If (settings.general.lang_client != "unknown")
			vars.hwnd.help_tooltips["settings_active character status"] := hwnd
		Else vars.hwnd.help_tooltips["settings_lang incompatible"] := hwnd

		Gui, %GUI%: Font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+0 cBlack wp r1 hp gSettings_general2 HWNDhwnd" (settings.general.lang_client = "unknown" ? " Disabled" : ""), % LLK_StringCase(settings.general.character)
		If vars.log.level
			Gui, %GUI%: Add, Text, % "ys x+-1 hp 0x200 Center Border", % " " LangTrans("m_general_level") " " vars.log.level " "
		Gui, %GUI%: Font, % "s"settings.general.fSize
		vars.hwnd.settings.character := hwnd
		If (settings.general.lang_client != "unknown")
		{
			vars.hwnd.help_tooltips["settings_active character"] := hwnd
			Gui, %GUI%: Add, Button, % "xp yp wp hp Default Hidden gSettings_general2 HWNDhwnd", % "save"
			vars.hwnd.settings.save_character := hwnd
		}
		Else vars.hwnd.help_tooltips["settings_lang incompatible|"] := hwnd
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm

	Loop, Files, data\*, R
		If (A_LoopFileName = "client.txt")
			parse := StrReplace(StrReplace(A_LoopFilePath, "data\"), "\client.txt"), check .= parse "|"
	If (LLK_InStrCount(check, "|") > 1)
	{
		parse := 0
		Loop, Parse, check, |
			parse := (StrLen(A_LoopField) > parse) ? StrLen(A_LoopField) : parse
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd00", % LangTrans("m_general_language") " "
		Gui, %GUI%: Font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, DDL, % "ys x+0 HWNDhwnd0 gSettings_general2 r"LLK_InStrCount(check, "|") " w"settings.general.fWidth * parse + settings.general.fWidth, % StrReplace(check, settings.general.lang, settings.general.lang "|")
		Gui, %GUI%: Font, % "s"settings.general.fSize
		Gui, %GUI%: Add, Text, % "ys HWNDhwnd Border x+"settings.general.fWidth, % " " LangTrans("global_credits") " "
		vars.hwnd.help_tooltips["settings_lang language"] := vars.hwnd.settings.language := hwnd0, vars.hwnd.help_tooltips["settings_lang translators"] := hwnd, vars.hwnd.help_tooltips["settings_lang language|"] := hwnd00
	}

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("global_font")
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd
	Gui, %GUI%: Add, Text, % "ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.settings.font_minus := hwnd, vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "x+" settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd", % " " settings.general.fSize " "
	vars.hwnd.settings.font_reset := hwnd, vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "wp x+" settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Text, % "x+" settings.general.fwidth " ys gSettings_general2 Center HWNDhwnd w"settings.general.fWidth*2, % LangTrans("m_general_toolbar")
	vars.hwnd.help_tooltips["settings_font-size||||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.settings.toolbar_minus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||||"] := hwnd
	Gui, %GUI%: Add, Text, % "x+" settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd", % " " settings.gui.sToolbar " "
	vars.hwnd.settings.toolbar_reset := hwnd, vars.hwnd.help_tooltips["settings_font-size||||||"] := hwnd
	Gui, %GUI%: Add, Text, % "wp x+" settings.general.fwidth / 4 " ys gSettings_general2 Border Center HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.toolbar_plus := hwnd, vars.hwnd.help_tooltips["settings_font-size|||||||"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_general2 Checked" settings.general.hide_toolbar, % LangTrans("m_general_hidetoolbar")
	vars.hwnd.settings.toolbar_hide := vars.hwnd.help_tooltips["settings_toolbar hide"] := hwnd

	If !vars.client.stream
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_general_client")
		Gui, %GUI%: Font, norm
		Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd Hidden cRed gSettings_general2", % " " LangTrans("global_restart") " "
		vars.hwnd.settings.apply := hwnd

		Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_general_language", 2) " "
		Gui, %GUI%: Add, Text, % "ys x+0 c" (settings.general.lang_client = "unknown" ? "Red" : "Lime"), % (settings.general.lang_client = "unknown") ? LangTrans("m_general_language", 3) : settings.general.lang_client

		If (settings.general.lang_client = "unknown")
			Gui, %GUI%: Add, Text, % "xs Section cRed", % "(some features will not be available)"

		If !InStr("unknown,english", settings.general.lang_client)
		{
			Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd", % " " LangTrans("global_credits") " "
			vars.hwnd.help_tooltips["settings_lang contributors"] := hwnd
		}

		Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_general_display", 1) " "
		Gui, %GUI%: Add, Text, % "ys x+0 cAqua HWNDhwnd", % (vars.client.fullscreen = "true") ? LangTrans("m_general_display", 2) : !vars.client.borderless ? LangTrans("m_general_display", 3) : LangTrans("m_general_display", 4)
		vars.hwnd.settings.window_mode := hwnd

		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_general_resolution")
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
			Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_general_position")
			vars.hwnd.help_tooltips["settings_window position"] := hwnd
			Gui, %GUI%: Font, % "s"settings.general.fsize - 4
			If (wCheck < vars.monitor.w)
			{
				Gui, %GUI%: Add, DDL, % "ys hp r3 HWNDhwnd w"Floor(settings.general.fWidth* 6.5) " gSettings_general2", % StrReplace(LangTrans("m_general_posleft") "|" LangTrans("m_general_poscenter") "|" LangTrans("m_general_posright") "|", LangTrans("m_general_pos" vars.client.docked) "|", LangTrans("m_general_pos" vars.client.docked) "||")
				vars.hwnd.settings.dock := hwnd, vars.hwnd.help_tooltips["settings_window position|"] := hwnd
			}
			If (hCheck < vars.monitor.h)
			{
				Gui, %GUI%: Add, DDL, % "ys hp r3 HWNDhwnd gSettings_general2" (wCheck < vars.monitor.w ? " wp" : " w"settings.general.fWidth * 6.5), % StrReplace(LangTrans("m_general_postop") "|" LangTrans("m_general_poscenter") "|" LangTrans("m_general_posbottom") "|", LangTrans("m_general_pos" vars.client.docked2) "|", LangTrans("m_general_pos" vars.client.docked2) "||")
				vars.hwnd.settings.dock2 := hwnd, vars.hwnd.help_tooltips["settings_window position||"] := hwnd
				Gui, %GUI%: Font, % "s"settings.general.fsize
			}
			If (vars.client.fullscreen = "false")
			{
				Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd Checked"vars.client.borderless " gSettings_general2", % LangTrans("m_general_borderless")
				vars.hwnd.settings.remove_borders := hwnd, vars.hwnd.help_tooltips["settings_window borders"] := hwnd
			}
		}

		If settings.general.FillerAvailable
		{
			Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_general2 HWNDhwnd Checked" settings.general.ClientFiller, % LangTrans("m_general_filler")
			vars.hwnd.settings.ClientFiller := vars.hwnd.help_tooltips["settings_client filler"] := hwnd
		}

		If (vars.client.h0 / vars.client.w0 < (5/12))
		{
			settings.general.blackbars := LLK_IniRead("ini\config.ini", "Settings", "black-bar compensation", 0)
			Gui, %GUI%: Add, Checkbox, % "hp xs Section BackgroundTrans gSettings_general2 HWNDhwnd Center Checked"settings.general.blackbars, % LangTrans("m_general_blackbars")
			vars.hwnd.settings.blackbars := hwnd, vars.hwnd.help_tooltips["settings_black bars"] := hwnd
		}
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans HWNDhwnd y+"vars.settings.spacing, % LangTrans("m_general_permissions")
	vars.hwnd.settings.permissions_test := hwnd
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans Border gSettings_WriteTest", % " " LangTrans("m_general_start") " "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cGreen Range0-700 HWNDhwnd", 0
	Gui, %GUI%: Add, Text, % "ys BackgroundTrans Border gSettings_WriteTest HWNDhwnd1", % " " LangTrans("m_general_admin") " "
	vars.hwnd.help_tooltips["settings_write permissions"] := hwnd0, vars.hwnd.settings.bar_writetest := hwnd, vars.hwnd.settings.writetest := hwnd1
}

Settings_general2(cHWND := "")
{
	local
	global vars, settings
	static char_wait

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), update := vars.update

	Switch check
	{
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
					vars.settings.x := xPos, vars.settings.y := yPos, vars.general.drag := 0
					Return
				}
			}
		Case "dev_env":
			settings.general.dev_env := LLK_ControlGet(cHWND)
			IniWrite, % settings.general.dev_env, ini\config.ini, Settings, dev env
		Case "kill_timer":
			settings.general.kill.1 := LLK_ControlGet(cHWND)
			IniWrite, % settings.general.kill.1, ini\config.ini, Settings, kill script
		Case "kill_timeout":
			settings.general.kill.2 := Blank(LLK_ControlGet(cHWND)) ? 0 : LLK_ControlGet(cHWND)
			IniWrite, % settings.general.kill.2, ini\config.ini, Settings, kill-timeout
		Case "browser":
			settings.features.browser := LLK_ControlGet(cHWND)
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, settings, enable browser features
		Case "capslock":
			IniWrite, % LLK_ControlGet(cHWND), ini\config.ini, settings, enable capslock-toggling
			IniWrite, general, ini\config.ini, versions, reload settings
			KeyWait, LButton
			Reload
			ExitApp
		Case "character":
			GuiControl, +cRed, % vars.hwnd.settings.character
			GuiControl, movedraw, % vars.hwnd.settings.character
		Case "save_character":
			If char_wait
				Return
			char_wait := 1, parse := LLK_StringCase(LLK_ControlGet(vars.hwnd.settings.character)), parse := InStr(parse, " (") ? SubStr(parse, 1, InStr(parse, " (") - 1) : parse
			While (SubStr(parse, 1, 1) = " ")
				parse := SubStr(parse, 2)
			While (SubStr(parse, 0) = " ")
				parse := SubStr(parse, 1, -1)
			settings.general.character := parse
			GuiControl, text, % vars.hwnd.settings.character, % parse
			GuiControl, +disabled, % vars.hwnd.settings.character
			IniWrite, % settings.general.character, ini\config.ini, Settings, active character
			Init_log("refresh")
			If WinExist("ahk_id " vars.hwnd.geartracker.main)
				GeartrackerGUI()
			Else If settings.leveltracker.geartracker && vars.hwnd.geartracker.main
				GeartrackerGUI("refresh")
			If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			{
				exp := LeveltrackerExperience("", 1)
				GuiControl, text, % vars.hwnd.leveltracker.experience, % StrReplace(exp, (exp = "100%") ? "" : "100%")
				GuiControl, % "+c" (InStr(exp, "100%") ? "Lime" : "Red"), % vars.hwnd.leveltracker.experience
			}
			Settings_menu("general"), char_wait := 0
		Case "language":
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.language), ini\config.ini, settings, language
			IniWrite, % vars.settings.active, ini\config.ini, Versions, reload settings
			KeyWait, LButton
			Reload
			ExitApp
		Case "custom_width":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "custom_resolution":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "apply":
			width := (LLK_ControlGet(vars.hwnd.settings.custom_width) > vars.monitor.w) ? vars.monitor.w : LLK_ControlGet(vars.hwnd.settings.custom_width)
			height := LLK_ControlGet(vars.hwnd.settings.custom_resolution)
			If !IsNumber(height) || !IsNumber(width)
			{
				LLK_ToolTip(LangTrans("global_errorname", 2),,,,, "red")
				Return
			}
			horizontal := LLK_ControlGet(vars.hwnd.settings.dock), vertical := LLK_ControlGet(vars.hwnd.settings.dock2)
			For key, val in vars.lang
				If InStr(key, "m_general_pos") && (val.1 = horizontal || val.1 = vertical)
					horizontal := (val.1 = horizontal) ? StrReplace(key, "m_general_pos") : horizontal, vertical := (val.1 = vertical) ? StrReplace(key, "m_general_pos") : vertical
			If InStr("left, right, center", horizontal) && InStr("top, bottom, center", vertical)
			{
				IniWrite, % horizontal, ini\config.ini, Settings, window-position
				IniWrite, % vertical, ini\config.ini, Settings, window-position vertical
			}
			IniWrite, % height, ini\config.ini, Settings, custom-resolution
			IniWrite, % width, ini\config.ini, Settings, custom-width
			IniWrite, % LLK_ControlGet(vars.hwnd.settings.remove_borders), ini\config.ini, settings, remove window-borders
			If vars.hwnd.settings.ClientFiller
				IniWrite, % LLK_ControlGet(vars.hwnd.settings.ClientFiller), ini\config.ini, Settings, client background filler
			If vars.hwnd.settings.blackbars
				IniWrite, % LLK_ControlGet(vars.hwnd.settings.blackbars), ini\config.ini, Settings, black-bar compensation
			IniWrite, % vars.settings.active, ini\config.ini, Versions, reload settings
			KeyWait, LButton
			Reload
			ExitApp
		Case "ClientFiller":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "dock":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "dock2":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "remove_borders":
			state := LLK_ControlGet(cHWND), ddl_state := LLK_ControlGet(vars.hwnd.settings.custom_resolution)
			For key in vars.general.supported_resolutions
				If state && (key <= vars.monitor.h) || !state && (key < vars.monitor.h)
					ddl := !ddl ? key : key "|" ddl
			ddl := !InStr(ddl, ddl_state) ? "|" StrReplace(ddl, "|", "||",, 1) : "|" StrReplace(ddl, InStr(ddl, ddl_state "|") ? ddl_state "|" : ddl_state, ddl_state "||")
			GuiControl,, % vars.hwnd.settings.custom_resolution, % ddl
			GuiControl, -Hidden, % vars.hwnd.settings.apply
			GuiControl, movedraw, % vars.hwnd.settings.apply
		Case "blackbars":
			GuiControl, -Hidden, % vars.hwnd.settings.apply
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
				LLK_FontDimensions(settings.general.fSize, font_height, font_width), settings.general.fheight := font_height, settings.general.fwidth := font_width
				IniWrite, % settings.general.fSize, ini\config.ini, Settings, font-size
				Init_GUI()
				Settings_menu("general")
			}
			Else If InStr(check, "toolbar_")
			{
				If (control = "hide")
				{
					settings.general.hide_toolbar := LLK_ControlGet(cHWND)
					IniWrite, % settings.general.hide_toolbar, ini\config.ini, UI, hide toolbar
					Init_GUI()
					Return
				}
				While GetKeyState("LButton", "P")
				{
					If (control = "minus")
						settings.gui.sToolbar -= (settings.gui.sToolbar > Round((vars.monitor.h / 72) / 2)) ? 1 : 0
					Else If (control = "reset")
						settings.gui.sToolbar := Round(vars.monitor.h / 72)
					Else settings.gui.sToolbar += 1
					GuiControl, text, % vars.hwnd.settings.toolbar_reset, % settings.gui.sToolbar
					Sleep 150
				}
				IniWrite, % settings.gui.sToolbar, ini\config.ini, UI, toolbar-size
				Init_GUI("refresh")
			}
			Else LLK_ToolTip("no action")
	}
}

Settings_hotkeys()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://www.autohotkey.com/docs/v1/KeyList.htm">ahk: list of keys</a>
	Gui, %GUI%: Add, Link, % "ys x+"settings.general.fWidth, <a href="https://www.autohotkey.com/docs/v1/Hotkeys.htm">ahk: formatting</a>

	If !vars.client.stream || settings.features.leveltracker
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_hotkeys_settings")
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
		Gui, %GUI%: Font, norm
	}

	If !vars.client.stream
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.rebound_alt, % LangTrans("m_hotkeys_descriptions")
		vars.hwnd.settings.rebound_alt := hwnd, vars.hwnd.help_tooltips["settings_hotkeys ingame-keybinds"] := hwnd0
		If settings.hotkeys.rebound_alt
		{
			Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 xp+" settings.general.fWidth * 1.5, % LangTrans("m_hotkeys_descriptions", 2)
			Gui, %GUI%: font, % "s"settings.general.fSize - 4
			Gui, %GUI%: Add, Edit, % "ys x+" settings.general.fWidth/2 " hp gSettings_hotkeys2 w"settings.general.fWidth*10 " HWNDhwnd cBlack", % settings.hotkeys.item_descriptions
			vars.hwnd.help_tooltips["settings_hotkeys altkey"] := hwnd0, vars.hwnd.settings.item_descriptions := vars.hwnd.help_tooltips["settings_hotkeys altkey|"] := hwnd
			Gui, %GUI%: font, % "s"settings.general.fSize
		}
		Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked" settings.hotkeys.rebound_c " x" x_anchor, % LangTrans("m_hotkeys_ckey")
		vars.hwnd.settings.rebound_c := hwnd
	}

	If settings.features.leveltracker
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 x" x_anchor, % LangTrans("m_hotkeys_movekey")
		Gui, %GUI%: font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+" settings.general.fWidth/2 " hp gSettings_hotkeys2 w"settings.general.fWidth*10 " HWNDhwnd cBlack", % settings.hotkeys.movekey
		vars.hwnd.help_tooltips["settings_hotkeys movekey"] := hwnd0, vars.hwnd.settings.movekey := hwnd, vars.hwnd.help_tooltips["settings_hotkeys movekey|"] := hwnd
		Gui, %GUI%: font, % "s"settings.general.fSize
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing " x" x_anchor, % LangTrans("m_hotkeys_omnikey")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_hotkeys omnikey-info"] := hwnd
	Gui, %GUI%: Font, norm

	LLK_PanelDimensions([LangTrans("m_hotkeys_omnikey", 2), settings.hotkeys.rebound_c ? LangTrans("m_hotkeys_omnikey", 3) : ""], settings.general.fSize, wText, hText,,, 0)
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 w" wText, % LangTrans("m_hotkeys_omnikey", 2)
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd gSettings_hotkeys2 x+" settings.general.fWidth/2 " w"settings.general.fWidth*10, % (settings.hotkeys.omnikey = "MButton") ? "" : settings.hotkeys.omnikey
	vars.hwnd.help_tooltips["settings_hotkeys omnikey"] := hwnd0, vars.hwnd.settings.omnikey := vars.hwnd.help_tooltips["settings_hotkeys omnikey|"] := hwnd
	ControlGetPos, x, y,,,, % "ahk_id "hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	If settings.hotkeys.rebound_c
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 w" wText, % LangTrans("m_hotkeys_omnikey", 3)
		Gui, %GUI%: font, % "s"settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "yp x+" settings.general.fWidth/2 " hp cBlack HWNDhwnd gSettings_hotkeys2 w"settings.general.fWidth*10, % settings.hotkeys.omnikey2
		vars.hwnd.help_tooltips["settings_hotkeys omnikey2"] := hwnd0, vars.hwnd.settings.omnikey2 := vars.hwnd.help_tooltips["settings_hotkeys omnikey2|"] := hwnd
		Gui, %GUI%: font, % "s"settings.general.fSize
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.omniblock, % LangTrans("m_hotkeys_keyblock")
	vars.hwnd.settings.omniblock := hwnd, vars.hwnd.help_tooltips["settings_hotkeys omniblock"] := hwnd
	;Gui, %GUI%: Add, Hotkey, % "ys hp Disabled gSettings_hotkeys2 HWNDhwnd x+"settings.general.fWidth/2 " cBlack w"settings.general.fWidth* 6, % (settings.hotkeys.omnikey = "MButton") ? "" : settings.hotkeys.omnikey
	;vars.hwnd.settings.omnikey := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_hotkeys_misc")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("m_hotkeys_tab")
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp cBlack HWNDhwnd gSettings_hotkeys2 x+"settings.general.fWidth/2 " w"settings.general.fWidth*10, % (settings.hotkeys.tab = "TAB") ? "" : settings.hotkeys.tab
	vars.hwnd.help_tooltips["settings_hotkeys tab"] := hwnd0, vars.hwnd.settings.tab := hwnd, vars.hwnd.help_tooltips["settings_hotkeys tab|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_hotkeys2 Checked"settings.hotkeys.tabblock, % LangTrans("m_hotkeys_keyblock")
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 cAqua", % LangTrans("m_hotkeys_emergency") " win + space"
	vars.hwnd.help_tooltips["settings_hotkeys restart"] := hwnd0, vars.hwnd.settings.tabblock := hwnd, vars.hwnd.help_tooltips["settings_hotkeys omniblock|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize + 4
	Gui, %GUI%: Add, Text, % "xs Border gSettings_hotkeys2 Hidden cRed Section HWNDhwnd y+"vars.settings.spacing, % " " LangTrans("global_restart") " "
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
						LLK_ToolTip(LangTrans("m_hotkeys_error"),, x + w, y,, "red")
						Return
					}
				}

				If keycheck.HasKey(hotkey)
				{
					LLK_ToolTip(LangTrans("m_hotkeys_error", 2), 1.5,,,, "red")
					Return
				}
				If hotkey
					keycheck[hotkey] := 1
			}
			If LLK_ControlGet(vars.hwnd.settings.rebound_alt) && !LLK_ControlGet(vars.hwnd.settings.item_descriptions)
			{
				WinGetPos, xControl, yControl, wControl, hControl, % "ahk_id " vars.hwnd.settings.item_descriptions
				LLK_ToolTip(LangTrans("m_hotkeys_error", 3), 3, xControl + wControl, yControl,, "red")
				Return
			}
			If LLK_ControlGet(vars.hwnd.settings.rebound_c) && !LLK_ControlGet(vars.hwnd.settings.omnikey2)
			{
				WinGetPos, xControl, yControl, wControl, hControl, % "ahk_id " vars.hwnd.settings.omnikey2
				LLK_ToolTip(LangTrans("m_hotkeys_error", 4), 3, xControl + wControl, yControl,, "red")
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
			KeyWait, LButton
			Reload
			ExitApp
	}
	GuiControl, -Hidden, % vars.hwnd.settings.apply
	GuiControl, movedraw, % vars.hwnd.settings.apply
}

Settings_iteminfo()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Item-info">wiki page</a>

	If (settings.general.lang_client = "unknown")
	{
		Settings_unsupported()
		Return
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, % LangTrans("m_iteminfo_profiles")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % LangTrans("m_iteminfo_profiles", 2)
	Loop 5
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/(A_Index = 1 ? 2 : 4) " Center Border HWNDhwnd gSettings_iteminfo2 c"(InStr(settings.iteminfo.profile, A_Index) ? "Fuchsia" : "White"), % " " A_Index " "
		vars.hwnd.help_tooltips["settings_iteminfo profiles"] := hwnd0, handle .= "|", vars.hwnd.settings["profile_"A_Index] := hwnd, vars.hwnd.help_tooltips["settings_iteminfo profiles"handle] := hwnd
	}

	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % LangTrans("m_iteminfo_profiles", 3)
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border BackgroundTrans cBlack HWNDhwnd gSettings_iteminfo2", % " " LangTrans("m_iteminfo_desired") " "
	vars.hwnd.help_tooltips["settings_iteminfo reset"] := hwnd0, vars.hwnd.settings.desired := hwnd
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 cRed HWNDhwnd Background"settings.iteminfo.colors_tier.1, 0
	vars.hwnd.settings.delbar_desired := vars.hwnd.help_tooltips["settings_iteminfo reset|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border BackgroundTrans cBlack HWNDhwnd0 gSettings_iteminfo2", % " " LangTrans("m_iteminfo_undesired") " "
	Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 cRed HWNDhwnd Background"settings.iteminfo.colors_tier.6, 0
	vars.hwnd.settings.undesired := hwnd0, vars.hwnd.settings.delbar_undesired := vars.hwnd.help_tooltips["settings_iteminfo reset||"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd0", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*3, % settings.iteminfo.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_iteminfo2 Border HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.modrolls, % LangTrans("m_iteminfo_modrolls")
	vars.hwnd.settings.modrolls := hwnd, vars.hwnd.help_tooltips["settings_iteminfo modrolls"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.trigger, % LangTrans("m_iteminfo_shift")
	vars.hwnd.settings.trigger := hwnd, vars.hwnd.help_tooltips["settings_iteminfo shift-click"] := hwnd

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.compare (settings.general.lang_client != "english" ? " cGray" : ""), % LangTrans("m_iteminfo_league")
	vars.hwnd.settings.compare := hwnd, vars.hwnd.help_tooltips["settings_" (settings.general.lang_client = "english" ? "iteminfo league-start" : "lang unavailable") ] := hwnd

	If !settings.iteminfo.compare
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.itembase, % LangTrans("m_iteminfo_base")
		vars.hwnd.settings.itembase := hwnd, vars.hwnd.help_tooltips["settings_iteminfo base-info"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.ilvl (settings.general.lang_client != "english" ? " cGray" : ""), % LangTrans("m_iteminfo_ilvl")
	vars.hwnd.settings.ilvl := hwnd, vars.hwnd.help_tooltips["settings_" (settings.general.lang_client = "english" ? "iteminfo enable item-level" : "lang unavailable||")] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans y+"vars.settings.spacing, % LangTrans("m_iteminfo_highlight")
	Gui, %GUI%: Font, norm
	LLK_PanelDimensions([LangTrans("global_tier"), LangTrans("global_ilvl")], settings.general.fSize, wText, hText,,, 0)

	Loop 8
	{
		parse := (A_Index = 1) ? 7 : A_Index - 2
		If (A_Index = 1)
			Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0 w" wText, % LangTrans("global_tier")
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/(A_Index = 1 ? 2 : 4) " w"settings.general.fWidth*3 " cBlack Center Border BackgroundTrans gSettings_iteminfo2 HWNDhwnd", % (A_Index = 1) ? LangTrans("m_iteminfo_fractured") : (A_Index = 2) ? "#" : parse
		vars.hwnd.help_tooltips["settings_iteminfo item-tier"] := hwnd0, vars.hwnd.settings["tier_"parse] := hwnd, handle := (A_Index = 1) ? "|" : handle "|"
		Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack HWNDhwnd Disabled c"settings.iteminfo.colors_tier[parse], 100
		vars.hwnd.settings["tierbar_"parse] := vars.hwnd.help_tooltips["settings_iteminfo item-tier"handle] := hwnd
	}

	If settings.iteminfo.ilvl
		Loop 8
		{
			If (A_Index = 1)
				Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd00 w" wText, % LangTrans("global_ilvl")
			color := (settings.iteminfo.colors_ilvl[A_Index] = "ffffff") && (A_Index = 1) ? "Red" : "Black", vars.hwnd.help_tooltips["settings_iteminfo item-level"] := hwnd00, handle := (A_Index = 1) ? "|" : handle "|"
			Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/(A_Index = 1 ? 2 : 4) " w"settings.general.fWidth*3 " c"color " Border Center BackgroundTrans gSettings_iteminfo2 HWNDhwnd0", % settings.iteminfo.ilevels[A_Index]
			Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack HWNDhwnd Disabled c"settings.iteminfo.colors_ilvl[A_Index], 100
			vars.hwnd.settings["ilvl_"A_Index] := hwnd0, vars.hwnd.settings["ilvlbar_"A_Index] := vars.hwnd.help_tooltips["settings_iteminfo item-level"handle] := hwnd
		}

	Gui, %GUI%: Add, Checkbox, % "xs Section hp gSettings_iteminfo2 HWNDhwnd Checked"settings.iteminfo.override, % LangTrans("m_iteminfo_override")
	vars.hwnd.settings.override := hwnd, vars.hwnd.help_tooltips["settings_iteminfo override"] := hwnd, colors := (settings.general.lang_client != "english") ? ["Gray", "Gray"] : [settings.iteminfo.colors_tier.1, settings.iteminfo.colors_tier.6]

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans HWNDhwnd0 y+"vars.settings.spacing, % LangTrans("m_iteminfo_rules")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_iteminfo2 HWNDhwnd01 c" colors.2 " Checked"settings.iteminfo.rules.res_weapons, % LangTrans("m_iteminfo_rules", 2)
	vars.hwnd.help_tooltips["settings_iteminfo rules"] := hwnd0, vars.hwnd.settings.rule_res_weapons := hwnd01
	GuiControlGet, text_, Pos, % hwnd01
	checkbox_spacing := text_w + settings.general.fWidth/2

	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gSettings_iteminfo2 HWNDhwnd02 c" colors.2 " Checked"settings.iteminfo.rules.attacks, % LangTrans("m_iteminfo_rules", 3)
	vars.hwnd.settings.rule_attacks := hwnd02
	GuiControlGet, text_, Pos, % hwnd02
	checkbox_spacing1 := text_w + settings.general.fWidth/2

	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing1 "BackgroundTrans gSettings_iteminfo2 HWNDhwnd03 c" colors.2 " Checked"settings.iteminfo.rules.spells, % LangTrans("m_iteminfo_rules", 4)
	vars.hwnd.settings.rule_spells := hwnd03
	Gui, %GUI%: Add, Checkbox, % "xs Section BackgroundTrans gSettings_iteminfo2 HWNDhwnd04 c" colors.1 " Checked"settings.iteminfo.rules.res, % LangTrans("m_iteminfo_rules", 5)
	vars.hwnd.settings.rule_res := hwnd04
	Gui, %GUI%: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gSettings_iteminfo2 HWNDhwnd05 c" colors.2 "" " Checked"settings.iteminfo.rules.hitgain, % LangTrans("m_iteminfo_rules", 6)
	vars.hwnd.settings.rule_hitgain := hwnd05
	Gui, %GUI%: Add, Checkbox, % "xs Section BackgroundTrans gSettings_iteminfo2 HWNDhwnd06 c" colors.2 " Checked"settings.iteminfo.rules.crit, % LangTrans("m_iteminfo_rules", 7)
	vars.hwnd.settings.rule_crit := hwnd06

	If (settings.general.lang_client != "english")
		Loop 6
			handle .= "|", vars.hwnd.help_tooltips["settings_lang unavailable" . handle] := hwnd0%A_Index%
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
		settings.iteminfo.trigger := LLK_ControlGet(cHWND), Settings_ScreenChecksValid()
		IniWrite, % settings.iteminfo.trigger, ini\item-checker.ini, settings, enable wisdom-scroll trigger
	}
	Else If (check = "modrolls")
	{
		settings.iteminfo.modrolls := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.modrolls, ini\item-checker.ini, settings, hide roll-ranges
	}
	Else If (check = "compare")
	{
		If (settings.general.lang_client != "english")
		{
			GuiControl,, % cHWND, 0
			Return
		}
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
		If (settings.general.lang_client != "english")
		{
			GuiControl,, % cHWND, 0
			Return
		}
		settings.iteminfo.ilvl := LLK_ControlGet(cHWND)
		IniWrite, % settings.iteminfo.ilvl, ini\item-checker.ini, settings, enable item-levels
		Settings_menu("item-info")
	}
	Else If InStr(check, "tier_")
	{
		If (vars.system.click = 1)
			picked_rgb := RGB_Picker(settings.iteminfo.colors_tier[control])
		If (vars.system.click = 1) && Blank(picked_rgb)
			Return
		Else color := (vars.system.click = 2) ? settings.iteminfo.dColors_tier[control] : picked_rgb
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
			picked_rgb := RGB_Picker(settings.iteminfo.Colors_ilvl[control])
		If (vars.system.click = 1) && Blank(picked_rgb)
			Return
		Else color := (vars.system.click = 2) ? settings.iteminfo.dColors_ilvl[control] : picked_rgb
		GuiControl, +c%color%, % vars.hwnd.settings["ilvlbar_"control]
		GuiControl, movedraw, % vars.hwnd.settings["ilvlbar_"control]
		If (control = 1)
		{
			GuiControl, % "+c"(color = "FFFFFF" ? "Red" : "Black"), % cHWND
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
		If (settings.general.lang_client != "english")
		{
			GuiControl,, % cHWND, 0
			Return
		}
		settings.iteminfo.rules[control] := LLK_ControlGet(cHWND)
		parse := (control = "res_weapons") ? "weapon res" : (control = "hitgain") ? "lifemana gain" : control
		IniWrite, % settings.iteminfo.rules[control], ini\item-checker.ini, settings, % parse " override"
	}
	Else LLK_ToolTip("no action")

	If WinExist("ahk_id " vars.hwnd.iteminfo.main)
		Iteminfo(1)
}

Settings_leveltracker()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Act‐Tracker">wiki page</a>

	Gui, %GUI%: Add, Checkbox, % "xs y+"vars.settings.spacing " Section gSettings_leveltracker2 HWNDhwnd Checked"settings.features.leveltracker, % LangTrans("m_lvltracker_enable")
	vars.hwnd.settings.enable := hwnd, vars.hwnd.help_tooltips["settings_leveltracker enable"] := hwnd

	If !settings.features.leveltracker
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	If !vars.client.stream
	{
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.timer, % LangTrans("m_lvltracker_timer")
		vars.hwnd.settings.timer := vars.hwnd.help_tooltips["settings_leveltracker timer"] := hwnd
		If settings.leveltracker.timer
		{
			Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth/2 " gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.pausetimer, % LangTrans("m_lvltracker_pause")
			vars.hwnd.settings.pausetimer := hwnd, vars.hwnd.help_tooltips["settings_leveltracker timer-pause"] := hwnd
		}
	}
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.fade, % LangTrans("m_lvltracker_fade")
	vars.hwnd.settings.fade := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade-timer"] := hwnd
	WinGetPos, xPos,,,, ahk_id %hwnd%
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys x+0 hp cBlack Center gSettings_leveltracker2 Limit1 Number HWNDhwnd w"settings.general.fWidth*2, % !settings.leveltracker.fadetime ? 0 : Format("{:0.0f}", settings.leveltracker.fadetime/1000)
	vars.hwnd.settings.fadetime := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade-timer|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize

	If settings.leveltracker.fade
	{
		Gui, %GUI%: Add, Checkbox, % "xs x" xPos + 2*settings.general.fWidth " gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.fade_hover, % LangTrans("m_lvltracker_fade", 2)
		vars.hwnd.settings.fade_hover := hwnd, vars.hwnd.help_tooltips["settings_leveltracker fade mouse"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.hints, % LangTrans("m_lvltracker_hints")
	vars.hwnd.settings.hints := vars.hwnd.help_tooltips["settings_leveltracker hints"] := hwnd

	If !vars.client.stream
	{
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.geartracker, % LangTrans("m_lvltracker_gear")
		vars.hwnd.settings.geartracker := hwnd, vars.hwnd.help_tooltips["settings_leveltracker geartracker"] := hwnd
		Gui, %GUI%: Add, Checkbox, % "ys gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.layouts, % LangTrans("m_lvltracker_zones")
		vars.hwnd.settings.layouts := hwnd, vars.hwnd.help_tooltips["settings_leveltracker layouts"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked" settings.leveltracker.hotkeys, % LangTrans("m_lvltracker_hotkeys")
	vars.hwnd.settings.hotkeys_enable := vars.hwnd.help_tooltips["settings_leveltracker hotkeys enable"] := hwnd
	If settings.leveltracker.hotkeys
	{
		Gui, %GUI%: Add, Button, % "ys Hidden hp Default gSettings_leveltracker2 HWNDhwnd0 w" settings.general.fWidth, ok
		width := settings.general.fWidth * 8
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "xs+" settings.general.fWidth * 1.8 " Section Right cBlack HWNDhwnd1 gSettings_leveltracker2 Limit w" width " h" settings.general.fHeight, % settings.leveltracker.hotkey_1
		Gui, %GUI%: Font, % "s" settings.general.fSize
		Gui, %GUI%: Add, Text, % "ys x+0 Center BackgroundTrans Border w" settings.general.fWidth * 2, % "<"
		Gui, %GUI%: Add, Text, % "ys x+0 Center BackgroundTrans Border wp", % ">"
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+0 cBlack HWNDhwnd2 Limit gSettings_leveltracker2 w" width " h" settings.general.fHeight, % settings.leveltracker.hotkey_2
		Gui, %GUI%: Font, % "s" settings.general.fSize
		vars.hwnd.settings.apply_button := hwnd0
		vars.hwnd.settings.hotkey_1 := vars.hwnd.help_tooltips["settings_leveltracker hotkeys"] := hwnd1, vars.hwnd.settings.hotkey_2 := vars.hwnd.help_tooltips["settings_leveltracker hotkeys|"] := hwnd2
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs y+"vars.settings.spacing " Section x" x_anchor, % LangTrans("m_lvltracker_guide")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "ys Border Center gSettings_leveltracker2 HWNDhwnd", % " " LangTrans("m_lvltracker_generate") " "
	vars.hwnd.settings.generate := vars.hwnd.help_tooltips["settings_leveltracker generate"] := hwnd, handle := ""
	Loop 3
	{
		file := !FileExist("ini\leveling guide" (A_Index = 1 ? "" : A_Index) ".ini") ? " cGray" : "", profile := (A_Index = 1) ? "" : A_Index
		Gui, %GUI%: Add, Text, % "xs Section Border Center " (!file ? "gSettings_leveltracker2" : "cGray") " HWNDhwnd0 w" settings.general.fWidth * 2 . (settings.leveltracker.profile = profile ? " cFuchsia" : ""), % A_Index
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_leveltracker2 HWNDhwnd1", % " " LangTrans("global_import") " "
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border BackgroundTrans " (!file ? "gSettings_leveltracker2" : "cGray") " HWNDhwnd2" color, % " " LangTrans("m_lvltracker_reset") " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd3 range0-500", 0
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys x+" settings.general.fWidth/4 " cBlack HWNDhwnd4 Limit r1 w" settings.general.fWidth*20 . (!file ? " gSettings_leveltracker2" : " Disabled"), % LLK_IniRead("ini\leveling guide" profile ".ini", "info", "name")
		Gui, %GUI%: Font, % "s" settings.general.fSize

		vars.hwnd.settings["profile" profile] := vars.hwnd.help_tooltips["settings_leveltracker profile select" handle] := hwnd0
		vars.hwnd.settings["import" profile] := vars.hwnd.help_tooltips["settings_leveltracker import" handle] := hwnd1
		vars.hwnd.settings["reset" profile] := hwnd2, vars.hwnd.settings["resetbar" profile] := vars.hwnd.help_tooltips["settings_leveltracker reset" handle] := hwnd3
		vars.hwnd.settings["name" profile] := vars.hwnd.help_tooltips["settings_leveltracker profile name" handle] := hwnd4, handle .= "|"
	}

	Gui, %GUI%: Add, Text, % "xs Section Center BackgroundTrans", % LangTrans("global_credits") ":"
	Gui, %GUI%: Add, Link, % "ys hp x+" settings.general.fWidth/2, <a href="https://github.com/HeartofPhos/exile-leveling">exile-leveling</a>
	Gui, %GUI%: Add, Text, % "ys Center BackgroundTrans x+0", % " ("
	Gui, %GUI%: Add, Link, % "ys hp x+0", <a href="https://github.com/HeartofPhos">HeartofPhos</a>
	Gui, %GUI%: Add, Text, % "ys Center BackgroundTrans x+0", % ")"

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_lvltracker_skilltree")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Picture, % "ys BackgroundTrans hp HWNDhwnd0 w-1", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_leveltracker2 HWNDhwnd Checked"settings.leveltracker.pob, % LangTrans("m_lvltracker_pob")
	vars.hwnd.help_tooltips["settings_leveltracker skilltree-info"] := hwnd0, vars.hwnd.settings.pob := vars.hwnd.help_tooltips["settings_leveltracker pob"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section gSettings_leveltracker2 Border HWNDhwnd", % " " LangTrans("m_lvltracker_screencap") " "
	vars.hwnd.settings.screencap := vars.hwnd.help_tooltips["settings_leveltracker screen-cap menu"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " gSettings_leveltracker2 Border HWNDhwnd", % " " LangTrans("global_imgfolder") " "
	vars.hwnd.settings.folder := vars.hwnd.help_tooltips["settings_leveltracker folder"] := hwnd

	Gui, %GUI%: Font, underline bold
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*3, % settings.leveltracker.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center gSettings_leveltracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Text, % "ys Center", % LangTrans("global_opacity")
	Loop 5
	{
		Gui, %GUI%: Add, Text, % "ys" (A_Index = 1 ? "" : " x+" settings.general.fWidth / 4) " Center gSettings_leveltracker2 Border HWNDhwnd w" settings.general.fWidth * 2 (settings.leveltracker.trans = A_Index ? " cFuchsia" : ""), % A_Index
		vars.hwnd.settings["opac_" A_Index] := hwnd
	}
}

Settings_leveltracker2(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If (check = "enable")
	{
		settings.features.leveltracker := LLK_ControlGet(cHWND), timer := vars.leveltracker.timer
		If !settings.features.leveltracker && IsNumber(timer.current_split) && (timer.current_split != timer.current_split0) ;save current timer state
			IniWrite, % (timer.current_split0 := timer.current_split), ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
		IniWrite, % settings.features.leveltracker, ini\config.ini, features, enable leveling guide
		LeveltrackerToggle("destroy"), LLK_Overlay(vars.hwnd.geartracker.main, "destroy")
		vars.leveltracker := {}, vars.hwnd.Delete("leveltracker"), vars.hwnd.Delete("geartracker")
		If settings.features.leveltracker
			Init_leveltracker()
		Settings_menu("leveling tracker"), Init_GUI()
	}
	Else If (check = "timer")
	{
		settings.leveltracker.timer := LLK_ControlGet(cHWND), timer := vars.leveltracker.timer
		IniWrite, % settings.leveltracker.timer, ini\leveling tracker.ini, settings, enable timer
		If !settings.leveltracker.timer && IsNumber(timer.current_split) && (timer.current_split != timer.current_split0)
			IniWrite, % (timer.current_split0 := timer.current_split), ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			LeveltrackerProgress(1)
		vars.leveltracker.timer.pause := -1, Settings_menu("leveling tracker")
	}
	Else If (check = "pausetimer")
	{
		settings.leveltracker.pausetimer := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.pausetimer, ini\leveling tracker.ini, settings, hideout pause
	}
	Else If (check = "fade")
	{
		settings.leveltracker.fade := LLK_ControlGet(cHWND)
		If !settings.leveltracker.fade && LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			LeveltrackerProgress(1)
		IniWrite, % settings.leveltracker.fade, ini\leveling tracker.ini, settings, enable fading
		Settings_menu("leveling tracker")
	}
	Else If (check = "fadetime")
	{
		settings.leveltracker.fadetime := !LLK_ControlGet(cHWND) ? 0 : Format("{:0.0f}", LLK_ControlGet(cHWND)*1000)
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
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			LeveltrackerProgress()
	}
	Else If (check = "hints")
	{
		settings.leveltracker.hints := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.hints, ini\leveling tracker.ini, settings, enable additional hints
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			LeveltrackerProgress(1)
	}
	Else If (check = "hotkeys_enable")
	{
		IniWrite, % (settings.leveltracker.hotkeys := LLK_ControlGet(cHWND)), ini\leveling tracker.ini, settings, enable page hotkeys
		settings.leveltracker.hotkey_01 := settings.leveltracker.hotkey_1, settings.leveltracker.hotkey_02 := settings.leveltracker.hotkey_2
		LeveltrackerHotkeys("refresh"), Settings_menu("leveling tracker")
	}
	Else If InStr(check, "hotkey_")
	{
		GuiControl, % "+c" (LLK_ControlGet(cHWND) != settings.leveltracker[check] ? "Red" : "Black"), % cHWND
		GuiControl, movedraw, % cHWND
	}
	Else If (check = "apply_button")
	{
		ControlGetFocus, hwnd, % "ahk_id " vars.hwnd.settings.main
		ControlGet, hwnd, HWND,, % hwnd
		If !InStr(vars.hwnd.settings.hotkey_1 "," vars.hwnd.settings.hotkey_2, hwnd)
			Return
		input0 := LLK_ControlGet(hwnd)
		If (StrLen(input0) > 1)
			Loop, Parse, % "^!+#"
				input := (A_Index = 1) ? input0 : input, input := StrReplace(input, A_LoopField)
		If !GetKeyVK(input)
		{
			WinGetPos, x, y, w, h, ahk_id %hwnd%
			LLK_ToolTip(LangTrans("m_hotkeys_error"), 1.5, x, y + h - 1,, "Red")
			Return
		}
		settings.leveltracker.hotkey_01 := settings.leveltracker.hotkey_1, settings.leveltracker.hotkey_02 := settings.leveltracker.hotkey_2
		control := (hwnd = vars.hwnd.settings.hotkey_1) ? 1 : 2
		IniWrite, % (settings.leveltracker["hotkey_" control] := input0), ini\leveling tracker.ini, settings, % "hotkey " control
		LeveltrackerHotkeys("refresh")
		GuiControl, +cBlack, % hwnd
		GuiControl, movedraw, % hwnd
	}
	Else If (check = "pob")
	{
		settings.leveltracker.pob := LLK_ControlGet(cHWND)
		IniWrite, % settings.leveltracker.pob, ini\leveling tracker.ini, settings, enable pob-screencap
	}
	Else If (check = "screencap")
	{
		KeyWait, LButton
		LLK_Overlay(vars.hwnd.settings.main, "hide"), LeveltrackerScreencapMenu()
	}
	Else If (check = "folder")
	{
		KeyWait, LButton
		Run, % "explore img\GUI\skill-tree" settings.leveltracker.profile "\"
	}
	Else If (check = "generate")
	{
		KeyWait, LButton
		Run, https://heartofphos.github.io/exile-leveling/
	}
	Else If InStr(check, "profile")
	{
		GuiControl, +cWhite, % vars.hwnd.settings["profile" settings.leveltracker.profile]
		GuiControl, movedraw, % vars.hwnd.settings["profile" settings.leveltracker.profile]
		timer := vars.leveltracker.timer
		If IsNumber(timer.current_split) && (timer.current_split != timer.current_split0)
			IniWrite, % (timer.current_split0 := timer.current_split), ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
		settings.leveltracker.profile := IsNumber(SubStr(check, 0)) ? SubStr(check, 0) : "", vars.leveltracker.timer.pause := -1
		IniWrite, % settings.leveltracker.profile, ini\leveling tracker.ini, Settings, profile
		GuiControl, +cFuchsia, % vars.hwnd.settings["profile" settings.leveltracker.profile]
		GuiControl, movedraw, % vars.hwnd.settings["profile" settings.leveltracker.profile]
		LeveltrackerLoad(), Init_leveltracker()
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			LeveltrackerProgress(1)
	}
	Else If InStr(check, "import")
	{
		KeyWait, LButton
		If LeveltrackerImport(IsNumber(SubStr(check, 0)) ? SubStr(check, 0) : "")
		{
			Settings_menu("leveling tracker")
			If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
				LeveltrackerProgress(1)
		}
	}
	Else If InStr(check, "reset")
	{
		If LLK_Progress(vars.hwnd.settings["resetbar" (IsNumber(SubStr(check, 0)) ? SubStr(check, 0) : "")], "LButton")
			LeveltrackerProgressReset(IsNumber(SubStr(check, 0)) ? SubStr(check, 0) : "")
		Else Return
	}
	Else If InStr(check, "name")
	{
		name := LLK_ControlGet(cHWND), number := IsNumber(SubStr(check, 0)) ? SubStr(check, 0) : ""
		IniWrite, % """" name """", % "ini\leveling guide" number ".ini", info, name
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
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			Leveltracker()
		If WinExist("ahk_id "vars.hwnd.geartracker.main)
			GeartrackerGUI()
	}
	Else If InStr(check, "opac_")
	{
		GuiControl, +cWhite, % vars.hwnd.settings["opac_" settings.leveltracker.trans]
		GuiControl, movedraw, % vars.hwnd.settings["opac_" settings.leveltracker.trans]
		settings.leveltracker.trans := control
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			Leveltracker()
		IniWrite, % settings.leveltracker.trans, ini\leveling tracker.ini, settings, transparency
		GuiControl, +cFuchsia, % vars.hwnd.settings["opac_" control]
		GuiControl, movedraw, % vars.hwnd.settings["opac_" control]
	}
	Else LLK_ToolTip("no action")
}

Settings_mapinfo()
{
	local
	global vars, settings, db

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Map-info-panel">wiki page</a>

	If (settings.general.lang_client = "unknown")
	{
		Settings_unsupported()
		Return
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 y+"vars.settings.spacing " HWNDhwnd Checked"settings.features.mapinfo, % LangTrans("m_mapinfo_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_mapinfo enable"] := hwnd

	If !settings.features.mapinfo
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 HWNDhwnd Checked"settings.mapinfo.trigger, % LangTrans("m_mapinfo_shift")
	vars.hwnd.settings.shiftclick := vars.hwnd.help_tooltips["settings_mapinfo shift-click"] := hwnd
	ControlGetPos, x, y, w, h,, ahk_id %hwnd%
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 HWNDhwnd Checked"settings.mapinfo.tabtoggle, % LangTrans("m_mapinfo_tab")
	vars.hwnd.settings.tabtoggle := vars.hwnd.help_tooltips["settings_mapinfo tab"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*3, % settings.mapinfo.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys", % LangTrans("m_mapinfo_textcolors")
	handle := ""
	Loop 4
	{
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_mapinfo2 HWNDhwnd c"settings.mapinfo.color[A_Index], % " " A_Index " "
		vars.hwnd.settings["color_"A_Index] := vars.hwnd.help_tooltips["settings_mapinfo colors"handle] := hwnd, handle .= "|"
	}
	ControlGetPos, xGui,, wGui,,, ahk_id %hwnd%

	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_mapinfo_logbook")
	Loop 4
	{
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/(A_Index = 1 ? 2 : 4) " Center Border gSettings_mapinfo2 HWNDhwnd c"settings.mapinfo.eColor[A_Index], % " " A_Index " "
		vars.hwnd.settings["colorlogbook_"A_Index] := vars.hwnd.help_tooltips["settings_mapinfo logbooks"handle1] := hwnd, handle1 .= "|"
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_mapinfo2 HWNDhwnd Checked" settings.mapinfo.roll_highlight, % LangTrans("m_mapinfo_roll_highlight")
	vars.hwnd.settings.roll_highlight := vars.hwnd.help_tooltips["settings_mapinfo roll highlight"] := hwnd, handle := ""
	ControlGetPos, xControl,,,,, ahk_id %hwnd%
	If settings.mapinfo.roll_highlight
	{
		Gui, %GUI%: Add, Text, % "ys Center BackgroundTrans HWNDhwnd1 Border c" settings.mapinfo.roll_colors.1 " x+" settings.general.fWidth / 4, % " 117" LangTrans("maps_stats", 2) " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp HWNDhwnd11 Border BackgroundBlack c" settings.mapinfo.roll_colors.2, 100
		Gui, %GUI%: Add, Text, % "ys x+-1 BackgroundTrans gSettings_mapinfo2 HWNDhwnd2 Border w" settings.general.fWidth, % " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp HWNDhwnd21 Border BackgroundBlack c" settings.mapinfo.roll_colors.1, % 100
		Gui, %GUI%: Add, Text, % "ys x+-1 BackgroundTrans gSettings_mapinfo2 HWNDhwnd3 Border w" settings.general.fWidth, % " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp HWNDhwnd31 Border BackgroundBlack c" settings.mapinfo.roll_colors.2, % 100
		Loop 3
			vars.hwnd.help_tooltips["settings_mapinfo roll colors" handle] := hwnd%A_Index%1, handle .= "|"
		vars.hwnd.settings.rollcolor_text := hwnd1, vars.hwnd.settings.rollcolor_back := hwnd11
		vars.hwnd.settings.rollcolor_1 := hwnd2, vars.hwnd.settings.rollcolor_11 := hwnd21
		vars.hwnd.settings.rollcolor_2 := hwnd3, vars.hwnd.settings.rollcolor_21 := hwnd31, dimensions := [], handle := ""
		Loop 6
		{
			Gui, %GUI%: Add, Text, % (A_Index = 1 ? "xs Section" : "ys x+" settings.general.fWidth//2) " Center HWNDhwnd Border w" settings.general.fWidth * 2, % LangTrans("maps_stats", A_Index + 1)
			Gui, %GUI%: Font, % "s" settings.general.fSize - 4
			Gui, %GUI%: Add, Edit, % "ys x+-1 hp Right cBlack Number HWNDhwnd1 Limit3 gSettings_mapinfo2 w" settings.general.fWidth * 3, % settings.mapinfo.roll_requirements[LangTrans("maps_stats_full", A_Index + 1)]
			Gui, %GUI%: Font, % "s" settings.general.fSize
			vars.hwnd.help_tooltips["settings_mapinfo requirements" handle] := hwnd, vars.hwnd.help_tooltips["settings_mapinfo requirements|" handle] := vars.hwnd.settings["thresh_" LangTrans("maps_stats_full", A_Index + 1)] := hwnd1, handle .= "||"
		}
	}

	Gui, %GUI%: Font, % "bold underline"
	Gui, %GUI%: Add, Text, % "xs Section x" x_anchor " y+" vars.settings.spacing, % LangTrans("m_mapinfo_modsettings")
	Gui, %GUI%: Font, % "norm"
	Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_mapinfo mod settings"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_mapinfo_pinned")
	For ID, val in settings.mapinfo.pinned
	{
		If !(check := LLK_HasVal(db.mapinfo.mods, ID,,,, 1)) || !val
			Continue
		ID := (ID < 100 ? "0" : "") . (ID < 10 ? "0" : "") . ID, ini := IniBatchRead("ini\map info.ini", ID)
		text := db.mapinfo.mods[check].text, text := InStr(text, ":") ? SubStr(text, 1, InStr(text, ":") - 1) : text, color := settings.mapinfo.color[!Blank(check := ini[ID].rank) ? check : 1]
		style := (xLast + wLast + StrLen(text) * settings.general.fWidth >= xGui + wGui) ? "xs Section" : "ys", show := !Blank(check := ini[ID].show) ? check : 1
		If !show
			Gui, %GUI%: Font, strike
		Gui, %GUI%: Add, Text, % style " Border Center HWNDhwnd c" color, % " " text " "
		Gui, %GUI%: Font, norm
		ControlGetPos, xLast,, wLast,,, ahk_id %hwnd%
		Gui, %GUI%: Add, Text, % "ys x+-1 Border Center HWNDhwnd1 gSettings_mapinfo2 cRed w" settings.general.fWidth * 2, % "–"
		vars.hwnd.settings["mapmod_" ID] := hwnd, vars.hwnd.settings["unpin_" ID] := hwnd1
	}
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_mapinfo_modsearch")
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default HWNDhwnd1 gSettings_mapinfo2", OK
	ControlGetPos, x1, y1, w1, h1,, ahk_id %hwnd%
	Gui, %GUI%: Font, % "norm s" settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys cBlack HWNDhwnd2 gSettings_mapinfo2 w" w - w1 - settings.general.fWidth, % vars.settings.mapinfo_search
	vars.hwnd.settings.modsearch := vars.hwnd.help_tooltips["settings_mapinfo modsearch"] := hwnd2, vars.hwnd.settings.modsearch_ok := hwnd1
	Gui, %GUI%: Font, % "s" settings.general.fSize

	If (search := vars.settings.mapinfo_search)
	{
		For outer in ["", ""]
		{
			If (outer = 2) && (added.Count() > 10)
			{
				Gui, %GUI%: Add, Text, % "xs Section cRed", % LangTrans("global_match", 2)
				Return
			}
			added := {}
			For mod, object in db.mapinfo.mods
			{
				If !InStr(mod, search) || added[object.ID] || settings.mapinfo.pinned[object.ID]
					Continue
				style := !added.Count() || (xLast + wLast + StrLen(text) * settings.general.fWidth >= xGui + wGui) ? "xs Section" : "ys", added[object.ID] := 1
				If (outer = 1)
					Continue
				ini := IniBatchRead("ini\map info.ini", object.ID), color := settings.mapinfo.color[!Blank(check := ini[object.ID].rank) ? check : 1]
				show := !Blank(check := ini[object.ID].show) ? check : 1, text := InStr(object.text, ":") ? SubStr(object.text, 1, InStr(object.text, ":") - 1) : object.text
				If !show
					Gui, %GUI%: Font, strike
				Gui, %GUI%: Add, Text, % style " Border Center HWNDhwnd c" color, % " " text " "
				Gui, %GUI%: Font, norm
				ControlGetPos, xLast,, wLast,,, ahk_id %hwnd%
				Gui, %GUI%: Add, Text, % "ys x+-1 Border Center HWNDhwnd1 gSettings_mapinfo2 cLime w" settings.general.fWidth * 2, % "+"
				vars.hwnd.settings["mapmod_" object.ID] := hwnd, vars.hwnd.settings["pin_" object.ID] := hwnd1
			}
		}
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
			settings.mapinfo.trigger := LLK_ControlGet(cHWND), Settings_ScreenChecksValid()
			IniWrite, % settings.mapinfo.trigger, ini\map info.ini, settings, enable shift-clicking
		Case "tabtoggle":
			settings.mapinfo.tabtoggle := LLK_ControlGet(cHWND)
			IniWrite, % settings.mapinfo.tabtoggle, ini\map info.ini, settings, show panel while holding tab
		Case "modsearch":
			GuiControl, +cBlack, % cHWND
		Case "modsearch_ok":
			vars.settings.mapinfo_search := LLK_ControlGet(cHWND := vars.hwnd.settings.modsearch), Settings_menu("map-info",, 0)
			Return
		Case "roll_highlight":
			IniWrite, % (settings.mapinfo.roll_highlight := LLK_ControlGet(cHWND)), ini\map info.ini, settings, highlight map rolls
			Settings_menu("map-info")
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
			Else If InStr(check, "thresh_")
			{
				IniWrite, % (settings.mapinfo.roll_requirements[control] := LLK_ControlGet(cHWND)), ini\map info.ini, UI, % control " requirement"
				Return
			}
			Else If InStr(check, "rollcolor")
			{
				KeyWait, LButton
				KeyWait, RButton
				color := (vars.system.click = 1) ? RGB_Picker(settings.mapinfo.roll_colors[control]) : (control = 1 ? "00FF00" : "000000")
				If Blank(color)
					Return
				GuiControl, % "+c" color, % vars.hwnd.settings["rollcolor_" control "1"]
				GuiControl, % "+c" color, % vars.hwnd.settings["rollcolor_" (control = 1 ? "text" : "back")]
				GuiControl, % "movedraw", % vars.hwnd.settings["rollcolor_" (control = 1 ? "text" : "back")]
				IniWrite, % (settings.mapinfo.roll_colors[control] := color), ini\map info.ini, UI, % "map rolls " (control = 1 ? "text" : "back") " color"
			}
			Else If InStr(check, "color")
			{
				key := InStr(check, "color_") ? "color" : "eColor"
				If (vars.system.click = 1)
					picked_rgb := RGB_Picker(settings.mapinfo[key][control])
				If (vars.system.click = 1) && Blank(picked_rgb)
					Return
				Else settings.mapinfo[key][control] := (vars.system.click = 1) ? picked_rgb : settings.mapinfo[InStr(check, "color_") ? "dColor" : "eColor_default"][control]

				IniWrite, % settings.mapinfo[key][control], ini\map info.ini, UI, % InStr(check, "color_") ? (control = 5 ? "header" : "difficulty " control) " color" : "logbook " control " color"
				GuiControl, % "+c" settings.mapinfo[key][control], % cHWND
				GuiControl, movedraw, % cHWND
			}
			Else If InStr(check, "pin_")
			{
				KeyWait, LButton
				IniWrite, % (settings.mapinfo.pinned[control] := InStr(check, "unpin_") ? 0 : 1), ini\map info.ini, pinned, % control
				Settings_menu("map-info",, 0)
				Return
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

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Map‐Tracker">wiki page</a>

	If (settings.general.lang_client = "unknown")
	{
		Settings_unsupported()
		Return
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 y+"vars.settings.spacing " HWNDhwnd Checked"settings.features.maptracker, % LangTrans("m_maptracker_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_maptracker enable"] := hwnd

	If !settings.features.maptracker
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.hide, % LangTrans("m_maptracker_hide")
	vars.hwnd.settings.hide := vars.hwnd.help_tooltips["settings_maptracker hide"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.loot, % LangTrans("m_maptracker_loot")
	vars.hwnd.settings.loot := hwnd, vars.hwnd.help_tooltips["settings_maptracker loot-tracker"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.kills, % LangTrans("m_maptracker_kills")
	vars.hwnd.settings.kills := vars.hwnd.help_tooltips["settings_maptracker kill-tracker"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.mapinfo (!settings.features.mapinfo ? " cGray" : ""), % LangTrans("m_maptracker_mapinfo")
	vars.hwnd.settings.mapinfo := hwnd, vars.hwnd.help_tooltips["settings_maptracker mapinfo"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.notes, % LangTrans("m_maptracker_notes")
	vars.hwnd.settings.notes := vars.hwnd.help_tooltips["settings_maptracker notes"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.sidecontent, % LangTrans("m_maptracker_sidearea")
	vars.hwnd.settings.sidecontent := vars.hwnd.help_tooltips["settings_maptracker side-content"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "ys gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.rename, % LangTrans("m_maptracker_rename")
	vars.hwnd.settings.rename := vars.hwnd.help_tooltips["settings_maptracker rename"] := hwnd
	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.mechanics, % LangTrans("m_maptracker_content")
	vars.hwnd.settings.mechanics := vars.hwnd.help_tooltips["settings_maptracker mechanics"] := hwnd
	If settings.maptracker.mechanics
	{
		Gui, %GUI%: Add, Text, % "xs Section Center xp+" settings.general.fWidth * 2, % LangTrans("m_maptracker_dialogue")
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_maptracker dialogue tracking"] := hwnd, added := 0, ingame_dialogs := vars.maptracker.dialog := InStr(LLK_FileRead(vars.system.config), "output_all_dialogue_to_chat=true") ? 1 : 0
		Gui, %GUI%: Font, c505050
		For mechanic, type in vars.maptracker.mechanics
		{
			If (type != 1)
				Continue
			added += 1, color := !ingame_dialogs ? " cRed" : settings.maptracker[mechanic] ? " cLime" : ""
			Gui, %GUI%: Add, Text, % (added = 1 || !Mod(added - 1, 4) ? "xs Section" : "ys x+"settings.general.fWidth/4) " Border Center gSettings_maptracker2 HWNDhwnd"color, % " " LangTrans("mechanic_" mechanic) " "
			vars.hwnd.settings["mechanic_"mechanic] := vars.hwnd.help_tooltips["settings_maptracker dialoguemechanic"handle] := hwnd, handle .= "|"
		}
		Gui, %GUI%: Font, cWhite

		Gui, %GUI%: Add, Text, % "xs Section Center", % LangTrans("m_maptracker_screen")
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_maptracker screen tracking"] := hwnd, handle := "", added := 0
		Gui, %GUI%: Font, c505050
		For mechanic, type in vars.maptracker.mechanics
		{
			If (type != 2)
				Continue
			added += 1, color := !FileExist("img\Recognition ("vars.client.h "p)\Mapping Tracker\"mechanic ".bmp") ? "red" : settings.maptracker[mechanic] ? " cLime" : ""
			Gui, %GUI%: Add, Text, % (added = 1 || !Mod(added - 1, 4) ? "xs Section" : "ys x+"settings.general.fWidth/4) " Border Center gSettings_maptracker2 HWNDhwnd c"color, % " " LangTrans("mechanic_" mechanic) " "
			vars.hwnd.settings["screenmechanic_"mechanic] := vars.hwnd.help_tooltips["settings_maptracker screenmechanic"handle] := hwnd, handle .= "|"
		}
		Gui, %GUI%: Font, cWhite
		Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_maptracker2 HWNDhwnd Checked"settings.maptracker.portal_reminder, % LangTrans("m_maptracker_portal")
		ControlGetPos,,, wControl,,, ahk_id %hwnd%
		vars.hwnd.settings.portal_reminder := vars.hwnd.help_tooltips["settings_maptracker portal reminder"] := hwnd, handle := ""
		If settings.maptracker.portal_reminder
		{
			Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("m_maptracker_portal", 2)
			ControlGetPos,,, wControl2,,, ahk_id %hwnd0%
			Gui, %GUI%: Font, % "s" settings.general.fSize - 4
			Gui, %GUI%: Add, Edit, % "ys cBlack gSettings_maptracker2 HWNDhwnd w" wControl - wControl2 - settings.general.fWidth, % settings.maptracker.portal_hotkey
			Gui, %GUI%: Font, % "s" settings.general.fSize
			vars.hwnd.settings.portal_hotkey := vars.hwnd.help_tooltips["settings_maptracker portal hotkey"] := hwnd
		}
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section Center y+"vars.settings.spacing " x" x_anchor, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center HWNDhwnd0", % LangTrans("global_panelsize") " "
	Gui, %GUI%: Add, Text, % "ys x+0 Center gSettings_maptracker2 Border HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4, % " " settings.maptracker.fSize " "
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys Center gSettings_maptracker2 Border HWNDhwnd x+"settings.general.fWidth/4 " w"settings.general.fWidth * 2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("global_color", 2) ": "
	Loop 2
	{
		Gui, %GUI%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd0 gSettings_maptracker2 x+" settings.general.fWidth * (A_Index = 1 ? 0 : 0.25) " w" settings.general.fHeight, % ""
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd BackgroundBlack c" settings.maptracker.colors["date_" (A_Index = 1 ? "un" : "") "selected"], % 100
		vars.hwnd.settings["color_date_" (A_Index = 1 ? "un" : "") "selected"] := hwnd0, vars.hwnd.settings["color_date_" (A_Index = 1 ? "un" : "") "selected_bar"] := vars.hwnd.help_tooltips["settings_maptracker color " (A_Index = 1 ? "un" : "") "selected"] := hwnd, handle := ""
	}

	For index, league in vars.maptracker.leagues
	{
		Gui, %GUI%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd0 gSettings_maptracker2 x+" settings.general.fWidth / 4 " w" settings.general.fHeight, % ""
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd BackgroundBlack c" settings.maptracker.colors["league " index], % 100
		vars.hwnd.settings["color_league " index] := hwnd0, vars.hwnd.settings["color_league " index "_bar"] := vars.hwnd.help_tooltips["settings_maptracker color leagues" handle] := hwnd, handle .= "|"
	}
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
			Init_GUI(), Settings_menu("mapping tracker")
		Case "hide":
			settings.maptracker.hide := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.hide, ini\map tracker.ini, settings, hide panel when paused
			If LLK_Overlay(vars.hwnd.maptracker.main, "check")
				MaptrackerGUI()
		Case "loot":
			settings.maptracker.loot := LLK_ControlGet(cHWND), Settings_ScreenChecksValid()
			IniWrite, % settings.maptracker.loot, ini\map tracker.ini, settings, enable loot tracker
		Case "kills":
			settings.maptracker.kills := LLK_ControlGet(cHWND), vars.maptracker.refresh_kills := ""
			IniWrite, % settings.maptracker.kills, ini\map tracker.ini, settings, enable kill tracker
		Case "mapinfo":
			If !settings.features.mapinfo
			{
				GuiControl,, % cHWND, 0
				Return
			}
			settings.maptracker.mapinfo := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.mapinfo, ini\map tracker.ini, settings, log mods from map-info panel
		Case "notes":
			settings.maptracker.notes := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.notes, ini\map tracker.ini, settings, enable notes
			MaptrackerGUI()
		Case "sidecontent":
			settings.maptracker.sidecontent := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.sidecontent, ini\map tracker.ini, settings, track side-areas
		Case "rename":
			settings.maptracker.rename := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.rename, ini\map tracker.ini, settings, rename boss maps
		Case "mechanics":
			settings.maptracker.mechanics := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.mechanics, ini\map tracker.ini, settings, track league mechanics
			Settings_menu("mapping tracker")
		Case "portal_reminder":
			settings.maptracker.portal_reminder := LLK_ControlGet(cHWND)
			IniWrite, % settings.maptracker.portal_reminder, ini\map tracker.ini, settings, portal-scroll reminder
			Settings_menu("mapping tracker")
		Case "portal_hotkey":
			input := LLK_ControlGet(cHWND)
			If (StrLen(input) != 1)
				Loop, Parse, % "#!^+"
					input := StrReplace(input, A_LoopField)
			If !Blank(input) && GetKeyVK(input)
			{
				settings.maptracker.portal_hotkey := LLK_ControlGet(cHWND)
				IniWrite, % settings.maptracker.portal_hotkey, ini\map tracker.ini, settings, portal-scroll hotkey
				GuiControl, +cBlack, % cHWND
				Init_maptracker()
			}
			Else GuiControl, +cRed, % cHWND
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
			Else If InStr(check, "mechanic_")
			{
				If InStr(check, "screen") && (vars.system.click = 2)
				{
					pClipboard := Screenchecks_ImageRecalibrate()
					If (pClipboard <= 0)
						Return
					Gdip_SaveBitmapToFile(pClipboard, "img\Recognition ("vars.client.h "p)\Mapping Tracker\"control ".bmp", 100), Gdip_DisposeImage(pClipboard)
					GuiControl, % "+c"(settings.maptracker[control] ? "Lime" : "505050"), % vars.hwnd.settings["screenmechanic_"control]
					GuiControl, movedraw, % vars.hwnd.settings["screenmechanic_"control]
					Return
				}
				If InStr(check, "screen") && !FileExist("img\Recognition ("vars.client.h "p)\Mapping Tracker\"control ".bmp")
					Return
				If !InStr(check, "screen") && !vars.maptracker.dialog
				{
					LLK_ToolTip(LangTrans("maptracker_dialogue"), 3,,,, "red")
					Return
				}
				settings.maptracker[control] := !settings.maptracker[control] ? 1 : 0
				IniWrite, % settings.maptracker[control], ini\map tracker.ini, mechanics, % control
				GuiControl, % "+c"(settings.maptracker[control] ? "Lime" : "505050"), % cHWND
				GuiControl, movedraw, % cHWND
			}
			Else If InStr(check, "color_")
			{
				If (vars.system.click = 1)
				{
					picked_rgb := RGB_Picker(settings.maptracker.colors[control])
					If Blank(picked_rgb)
						Return
				}
				settings.maptracker.colors[control] := (vars.system.click = 1) ? picked_rgb : settings.maptracker.dColors[control]
				IniWrite, % settings.maptracker.colors[control], ini\map tracker.ini, UI, % control " color"
				GuiControl, % "+c" settings.maptracker.colors[control], % vars.hwnd.settings[check "_bar"]
				If InStr(check, "selected") && WinExist("ahk_id " vars.hwnd.maptracker_logs.main)
					MaptrackerLogs()
			}
			Else LLK_ToolTip("no action")
			If WinExist("ahk_id " vars.hwnd.maptracker_logs.main)
				LLK_Overlay(vars.hwnd.settings.main, "show", 0)
	}
}

Settings_menu(section, mode := 0, NA := 1) ;mode parameter is used when manually calling this function to refresh the window
{
	local
	global vars, settings
	static toggle := 0

	If !IsObject(vars.settings)
	{
		vars.settings := {"sections": ["general", "hotkeys", "screen-checks", "updater", "donations", "leveling tracker", "betrayal-info", "cheat-sheets", "clone-frames", "item-info", "map-info", "mapping tracker", "minor qol tools", "necropolis", "search-strings", "stash-ninja", "tldr-tooltips"], "sections2": []} ;list of sections in the settings menu
		For index, val in vars.settings.sections
			vars.settings.sections2.Push(LangTrans("ms_" val))
	}

	If !Blank(LLK_HasVal(vars.hwnd.settings, section)) ;instead of using the first parameter for section/cHWND depending on context, get the section name from the control's text
		section := LLK_HasVal(vars.hwnd.settings, section) ? LLK_HasVal(vars.hwnd.settings, section) : section

	vars.settings.xMargin := settings.general.fWidth*0.75, vars.settings.yMargin := settings.general.fHeight*0.15, vars.settings.line1 := settings.general.fHeight/4
	vars.settings.spacing := settings.general.fHeight*0.8, vars.settings.wait := 1

	If !IsNumber(mode)
		mode := 0
	vars.settings.active := section ;which section of the settings menu is currently active (for purposes of reloading the correct section after restarting)

	If WinExist("ahk_id "vars.hwnd.settings.main)
	{
		WinGetPos, xPos, yPos,,, % "ahk_id " vars.hwnd.settings.main
		vars.settings.x := xPos, vars.settings.y := yPos
	}

	vars.settings.GUI_toggle := toggle := !toggle, GUI_name := "settings_menu" toggle, vars.settings.color := !vars.settings.color ? "Black" : vars.settings.color
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDsettings_menu"
	Gui, %GUI_name%: Color, % vars.settings.color
	Gui, %GUI_name%: Margin, % vars.settings.xMargin, % vars.settings.line1
	Gui, %GUI_name%: Font, % "s" settings.general.fSize - 2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.settings.main ;backup of the old GUI's HWND with which to destroy it after drawing the new one
	vars.hwnd.settings := {"main": settings_menu, "GUI_name": GUI_name} ;settings-menu HWNDs are stored here

	Gui, %GUI_name%: Add, Text, % "Section x-1 y-1 Border Center BackgroundTrans gSettings_general2 HWNDhwnd", % "lailloken ui: " LangTrans("global_window")
	vars.hwnd.settings.winbar := hwnd
	ControlGetPos,,,, hWinbar,, ahk_id %hwnd%
	Gui, %GUI_name%: Add, Text, % "ys w"settings.general.fWidth*2 " Border Center gSettings_menuClose HWNDhwnd", % "x"
	vars.hwnd.settings.winx := hwnd

	LLK_PanelDimensions(vars.settings.sections2, settings.general.fSize, section_width, height)
	Gui, %GUI_name%: Font, % "s" settings.general.fSize
	Gui, %GUI_name%: Add, Text, % "xs x-1 y+-1 Section BackgroundTrans Border gSettings_menu HWNDhwnd 0x200 h"settings.general.fHeight*1.5 " w"section_width, % " " LangTrans("ms_general") " "
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd1 BackgroundBlack cBlack", 100
	ControlGetPos, x, y,,,, ahk_id %hwnd%
	vars.hwnd.settings.general := hwnd, vars.settings.xSelection := x, vars.settings.ySelection := y + vars.settings.line1, vars.settings.wSelection := section_width, vars.hwnd.settings["background_general"] := hwnd1
	feature_check := {"betrayal-info": "betrayal", "cheat-sheets": "cheatsheets", "leveling tracker": "leveltracker", "mapping tracker": "maptracker", "map-info": "mapinfo", "necropolis": "necropolis", "tldr-tooltips": "OCR", "stash-ninja": "stash"}
	feature_check2 := {"item-info": 1, "mapping tracker": 1, "map-info": 1}

	If !vars.general.buggy_resolutions.HasKey(vars.client.h) && !vars.general.safe_mode
	{
		For key, val in vars.settings.sections
		{
			If (val = "general") || (val = "screen-checks") && !IsNumber(vars.pixelsearch.gamescreen.x1) || !vars.log.file_location && (val = "mapping tracker")
			|| (WinExist("ahk_exe GeForceNOW.exe") || WinExist("ahk_exe boosteroid.exe")) && InStr("item-info, map-info", val)
				continue
			color := (val = "updater" && IsNumber(vars.update.1) && vars.update.1 < 0) ? " cRed" : (val = "updater" && IsNumber(vars.update.1) && vars.update.1 > 0) ? " cLime" : ""
			color := feature_check[val] && !settings.features[feature_check[val]] || (val = "clone-frames") && !vars.cloneframes.enabled || (val = "search-strings") && !vars.searchstrings.enabled ? " cGray" : color, color := feature_check2[val] && (settings.general.lang_client = "unknown") ? " cGray" : color
			color := (val = "donations") ? " cCCCC00" : color
			Gui, %GUI_name%: Add, Text, % "Section xs y+-1 wp BackgroundTrans Border gSettings_menu HWNDhwnd 0x200 h"settings.general.fHeight*1.4 color, % " " LangTrans("ms_" val) " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd1 BackgroundBlack cBlack", 100
			vars.hwnd.settings[val] := hwnd, vars.hwnd.settings["background_"val] := hwnd1
			If (val = "donations")
				Gui, %GUI_name%: Add, Progress, % "Section xs y+0 wp Background606060 h" settings.general.fWidth//2, 0
		}
	}
	ControlGetPos, x, yLast_section, w, hLast_section,, ahk_id %hwnd%
	Gui, %GUI_name%: Font, norm

	;if aspect-ratio is wider than officially supported by PoE, show message and force-open the general section
	If !vars.general.safe_mode && !settings.general.warning_ultrawide && (vars.client.h0/vars.client.w0 < (5/12))
	{
		MsgBox, 4, % LangTrans("m_general_resolution"), % LangTrans("global_ultrawide") "`n" LangTrans("global_ultrawide", 2) "`n" LangTrans("global_ultrawide", 3)
		IniWrite, 1, ini\config.ini, Versions, ultrawide warning
		settings.general.warning_ultrawide := 1
		IfMsgBox, Yes
		{
			IniWrite, 1, ini\config.ini, Settings, black-bar compensation
			KeyWait, LButton
			Reload
			ExitApp
		}
	}

	If vars.settings.restart
		section := vars.settings.restart

	;highlight selected section
	GuiControl, %GUI_name%: +c303030, % vars.hwnd.settings["background_"vars.settings.active]
	GuiControl, %GUI_name%: movedraw, % vars.hwnd.settings["background_"vars.settings.active]

	If vars.settings.active0 && (vars.settings.active0 != vars.settings.active) ;remove highlight from previously-selected section
	{
		GuiControl, %GUI_name%: +cBlack, % vars.hwnd.settings["background_"vars.settings.active0]
		GuiControl, %GUI_name%: movedraw, % vars.hwnd.settings["background_"vars.settings.active0]
	}

	vars.settings.active0 := section
	Settings_ScreenChecksValid() ;check if 'screen-checks' section needs to be highlighted red

	Settings_menu2(section, mode)
	Gui, %GUI_name%: Margin, % vars.settings.xMargin, -1
	Gui, %GUI_name%: Show, % "NA AutoSize x10000 y10000"
	ControlFocus,, % "ahk_id "vars.hwnd.settings.general
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.settings.main

	If (h > yLast_section + hLast_section)
	{
		Gui, %GUI_name%: Add, Text, % "x-1 Border BackgroundTrans y"vars.settings.ySelection - 1 - vars.settings.line1 " w"section_width " h"h - hWinbar + vars.settings.line1
		h := h + vars.settings.line1 - 1
	}

	GuiControl, Move, % vars.hwnd.settings.winbar, % "w"w - settings.general.fWidth*2 + 2
	GuiControl, Move, % vars.hwnd.settings.winx, % "x"w - settings.general.fWidth*2 " y-1"
	sleep 50

	If (vars.settings.x != "") && (vars.settings.y != "")
	{
		vars.settings.x := (vars.settings.x + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w - 1 : vars.settings.x
		vars.settings.y := (vars.settings.y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : vars.settings.y
		Gui, %GUI_name%: Show, % "NA x"vars.settings.x " y"vars.settings.y " w"w - 1 " h"h - 2
	}
	Else
	{
		Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + vars.client.xc - w//2 " y" vars.monitor.y + vars.client.yc - h//2 " w"w - 1 " h"h - 2
		vars.settings.x := vars.monitor.x + vars.client.xc - w//2
	}
	LLK_Overlay(vars.hwnd.settings.main, "show", NA, GUI_name), LLK_Overlay(hwnd_old, "destroy"), vars.settings.w := w, vars.settings.h := h, vars.settings.restart := vars.settings.wait := vars.settings.color := ""
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
		Case "donations":
			Settings_donations()
		Case "tldr-tooltips":
			Settings_OCR()
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
		Case "necropolis":
			Settings_necropolis()
		Case "screen-checks":
			Settings_screenchecks()
		Case "search-strings":
			Init_searchstrings()
			Settings_searchstrings()
		Case "stash-ninja":
			Settings_stash()
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
	LLK_Overlay(vars.hwnd.settings.main, "destroy"), vars.settings.active := "", vars.hwnd.Delete("settings"), vars.settings.mapinfo_search := ""
	WinActivate, ahk_group poe_window
}

Settings_necropolis()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section HWNDhwnd x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Necropolis">wiki page</a>

	If (vars.client.h <= 720) ;&& !settings.general.dev
	{
		ControlGetPos, x,, w,,, ahk_id %hwnd%
		Gui, %GUI%: Add, Text, % "xs Section cRed w" w*4 " y+" vars.settings.spacing, % LangTrans("m_ocr_unsupported")
		Return
	}

	If (settings.general.lang_client != "english") && !vars.client.stream
	{
		Settings_unsupported()
		Return
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_necropolis2 HWNDhwnd Checked" settings.features.necropolis " y+"vars.settings.spacing . (!settings.OCR.allow ? " cRed" : ""), % LangTrans("m_necro_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_necro " (settings.OCR.allow ? "enable" : "compatibility")] := hwnd

	If !settings.features.necropolis
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd2 gSettings_necropolis2 Checked" settings.necropolis.debug, % LangTrans("m_ocr_debug")
	vars.hwnd.settings.debug := vars.hwnd.help_tooltips["settings_ocr debug"] := hwnd2

	Gui, %GUI%: Font, underline bold
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("global_opacity")
	Gui, %GUI%: Add, Text, % "ys gSettings_necropolis2 HWNDhwndminus Center Border w" settings.general.fWidth * 2, % "–"
	Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwndreset Center Border", % " " LangTrans("global_reset") " "
	Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwndplus Center Border w" settings.general.fWidth * 2, % "+"
	vars.hwnd.settings["opac_minus"] := hwndminus, vars.hwnd.settings["opac_reset"] := hwndreset, vars.hwnd.settings["opac_plus"] := hwndplus

	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % LangTrans("m_necro_offset")
	Gui, %GUI%: Add, Pic, % "ys HWNDhwnd hp w-1", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_necro offsets"] := hwnd
	LLK_PanelDimensions([LangTrans("global_width"), LangTrans("global_height")], settings.general.fSize, w1, h1), LLK_PanelDimensions([LangTrans("global_axis", 1), LangTrans("global_axis", 2)], settings.general.fSize, w2, h2), wControl := Max(w1, w2)
	For index, array in [["w", "width"], ["h", "height"], ["g", "gap"], ["x", "axis"], ["y", "axis"]]
	{
		Gui, %GUI%: Add, Text, % (InStr("14", index) ? "xs Section" : "ys") " gSettings_necropolis2 HWNDhwndminus Center Border w" settings.general.fWidth * 2, % "–"
		Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwndreset Center Border" (index != 3 ? " w" wControl : ""), % " " LangTrans("global_" array.2, (array.2 = "axis") ? (index = 4 ? 1 : 2) : 1) " "
		;Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwndreset Center Border w" settings.general.fWidth * 2, % "r"
		Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwndplus Center Border w" settings.general.fWidth * 2, % "+"
		vars.hwnd.settings[array.1 "minus"] := hwndminus, vars.hwnd.settings[array.1 "reset"] := hwndreset, vars.hwnd.settings[array.1 "plus"] := hwndplus
	}

	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % LangTrans("m_iteminfo_highlight")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_necro colors"] := hwnd
	For index, color in settings.necropolis.colors
	{
		Gui, %GUI%: Add, Text, % (index = 0 ? "xs Section" : "ys") " Border Center w" settings.general.fWidth * 2, % (index = 0 ? "s" : index)
		Gui, %GUI%: Add, Text, % "ys x+-1 gSettings_necropolis2 HWNDhwnd Border BackgroundTrans Center w" settings.general.fWidth * 3, % " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd1 c" color, 100
		vars.hwnd.settings["color_" index] := hwnd, vars.hwnd.settings["color_" index "_panel"] := hwnd1
	}
}

Settings_necropolis2(cHWND)
{
	local
	global vars, settings
	static in_progress := 0

	If in_progress
		Return

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), in_progress := 1
	Switch check
	{
		Case "enable":
		If !settings.OCR.allow
		{
			GuiControl,, % cHWND, 0
			compat_text := OCR_("compat"), in_progress := 0
			Return
		}
		settings.features.necropolis := LLK_ControlGet(cHWND)
		IniWrite, % settings.features.necropolis, ini\config.ini, features, enable necropolis
		If WinExist("ahk_id " vars.hwnd.necropolis.main)
			Necropolis_Close()
		Settings_menu("necropolis")

		Case "debug":
		settings.necropolis.debug := LLK_ControlGet(cHWND)
		IniWrite, % settings.necropolis.debug, ini\necropolis.ini, settings, enable debug

		Default:
		If !WinExist("ahk_id " vars.hwnd.necropolis.main)
			LLK_ToolTip(LangTrans("m_necro_nowindow"), 2,,,, "red")
		Else If vars.necropolis.debug
			Sleep 1
		Else
		{
			If InStr(check, "opac_")
			{
				If (control = "reset")
					settings.necropolis.opac := 50
				Else settings.necropolis.opac += (control = "minus") ? (settings.necropolis.opac >= 50 ? -25 : 0) : (settings.necropolis.opac <= 230 ? 25 : 0)
				IniWrite, % settings.necropolis.opac, ini\necropolis.ini, UI, opacity
				If WinExist("ahk_id " vars.hwnd.necropolis.main)
					Necropolis_("refresh")
			}
			Else If InStr(check, "color_")
			{
				color := (vars.system.click = 1) ? RGB_Picker(settings.necropolis.colors[control]) : settings.necropolis.dColors[control]
				If !Blank(color)
				{
					settings.necropolis.colors[control] := color
					IniWrite, % color, ini\necropolis.ini, UI, % "color " control
					GuiControl, % "+c" color, % vars.hwnd.settings["color_" control "_panel"]
					If WinExist("ahk_id " vars.hwnd.necropolis.main)
						Necropolis_("refresh")
				}
			}
			Else If InStr(check, "plus") || InStr(check, "minus") || InStr(check, "reset")
			{
				parse := {"g": "Gap", "x": "Xpos", "y": "Ypos", "w": "Width", "h": "Height"}
				setting := parse[StrReplace(StrReplace(StrReplace(check, "reset"), "minus"), "plus")]
				If InStr(check, "reset")
					settings.necropolis["o" setting] := 0
				Else settings.necropolis["o" setting] += InStr(check, "minus") ? -1 : 1
				IniWrite, % settings.necropolis["o" setting], ini\necropolis.ini, UI, % setting " offset"
				If WinExist("ahk_id " vars.hwnd.necropolis.main)
					Necropolis_("refresh")
			}
			Else LLK_ToolTip("no action: " check)
		}
	}
	in_progress := 0
}

Settings_OCR()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/TLDR‐Tooltips">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys x+" settings.general.fWidth, <a href="https://www.autohotkey.com/docs/v1/KeyList.htm">ahk: list of keys</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd x+" settings.general.fWidth, <a href="https://www.autohotkey.com/docs/v1/Hotkeys.htm">ahk: formatting</a>

	If (vars.client.h <= 720) ;&& !settings.general.dev
	{
		ControlGetPos, x,, w,,, ahk_id %hwnd%
		Gui, %GUI%: Add, Text, % "xs Section cRed w" x + w - x_anchor " y+" vars.settings.spacing, % LangTrans("m_ocr_unsupported")
		Return
	}

	If (settings.general.lang_client != "english") && !vars.client.stream
	{
		Settings_unsupported()
		Return
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section gSettings_OCR2 HWNDhwnd Checked" settings.features.ocr " y+"vars.settings.spacing . (!settings.OCR.allow ? " cRed" : ""), % LangTrans("m_ocr_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_ocr " (settings.OCR.allow ? "enable" : "compatibility")] := hwnd

	If !settings.features.ocr
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd1 gSettings_OCR2 cRed Hidden", % " " LangTrans("global_restart") " "

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_ocr_hotkey")
	Gui, %GUI%: Font, % "s" settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp HWNDhwnd0 cBlack gSettings_OCR2 w" settings.general.fWidth * 10, % settings.OCR.z_hotkey
	Gui, %GUI%: Font, % "s" settings.general.fSize
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("global_hotkey")
	Gui, %GUI%: Font, % "s" settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys hp HWNDhwnd cBlack gSettings_OCR2 w" settings.general.fWidth * 10, % settings.OCR.hotkey
	Gui, %GUI%: Font, % "s" settings.general.fSize

	Gui, %GUI%: Add, Checkbox, % "ys HWNDhwnd3 gSettings_OCR2 Checked" settings.OCR.hotkey_block, % LangTrans("m_hotkeys_keyblock")
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd2 gSettings_OCR2 Checked" settings.OCR.debug, % LangTrans("m_ocr_debug")
	vars.hwnd.settings.z_hotkey := vars.hwnd.help_tooltips["settings_ocr z hotkey"] := hwnd0
	vars.hwnd.settings.hotkey := vars.hwnd.help_tooltips["settings_ocr hotkey"] := hwnd
	vars.hwnd.settings.hotkey_set := hwnd1, vars.hwnd.settings.debug := vars.hwnd.help_tooltips["settings_ocr debug"] := hwnd2
	vars.hwnd.settings.hotkey_block := vars.hwnd.help_tooltips["settings_hotkeys omniblock"] := hwnd3

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_OCR2 HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_OCR2 HWNDhwnd w"settings.general.fWidth*3, % settings.OCR.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_OCR2 HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_iteminfo_highlight")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["settings_ocr colors"] := hwnd

	LLK_PanelDimensions([LangTrans("global_pattern") " 7"], settings.general.fSize, width, height)
	For index, array in settings.OCR.colors
	{
		Gui, %GUI%: Add, Text, % (InStr("14", A_Index) ? "xs Section" : "ys x+" settings.general.fWidth / 2) " Border Center HWNDhwndtext BackgroundTrans c" array.1 " w" width, % (index = 0 ? LangTrans("global_regular") : LangTrans("global_pattern") " " index)
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwndback c" array.2, 100
		Gui, %GUI%: Add, Text, % "ys x+-1 Border BackgroundTrans gSettings_OCR2 HWNDhwnd00", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd01 c" array.1, 100
		Gui, %GUI%: Add, Text, % "ys x+-1 Border BackgroundTrans gSettings_OCR2 HWNDhwnd10", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd11 c" array.2, 100
		vars.hwnd.settings["color_" index "1"] := hwnd00, vars.hwnd.settings["color_" index "_panel1"] := hwnd01, vars.hwnd.settings["color_" index "_text1"] := hwndtext
		vars.hwnd.settings["color_" index "2"] := hwnd10, vars.hwnd.settings["color_" index "_panel2"] := hwnd11, vars.hwnd.settings["color_" index "_text2"] := hwndback
	}
}

Settings_OCR2(cHWND)
{
	local
	global vars, settings
	static compat_text

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	Switch check
	{
		Case "enable":
		If !settings.OCR.allow
		{
			GuiControl,, % cHWND, 0
			compat_text := OCR_("compat")
			Return
		}

		settings.features.ocr := LLK_ControlGet(cHWND)
		IniWrite, % settings.features.ocr, ini\config.ini, Features, enable ocr
		If !Blank(settings.OCR.hotkey)
		{
			Hotkey, IfWinActive, ahk_group poe_window
			Hotkey, % "*" (settings.OCR.hotkey_block ? "" : "~") . settings.OCR.hotkey, OCR_, % settings.features.OCR ? "On" : "Off"
		}
		If WinExist("ahk_id " vars.hwnd.ocr_tooltip.main)
			OCR_Close()
		Settings_menu("tldr-tooltips")

		Case "compat_edit":
		If settings.OCR.allow
			Return
		compat_edit := LLK_ControlGet(vars.hwnd.settings.compat_edit), correct := ""
		input := [], count := 0
		Loop, Parse, compat_edit, % A_Space
			If (StrLen(A_LoopField) > 1) && !LLK_HasVal(input, A_LoopField)
				input.Push(A_LoopField)
		For index, word in input
			If vars.OCR.text_check.HasKey(word)
				count += 1, correct .= (Blank(correct) ? "" : ", ") word
		GuiControl, text, % vars.hwnd.settings.compat_correct, % (count >= 8 ? "" : "(" count "/8) ") . LangTrans("global_success") ": " (count >= 8 ? LangTrans("m_ocr_finish") : correct)
		If (count < 8)
			Return
		Else
		{
			settings.OCR.allow := 1
			IniWrite, 1, ini\ocr.ini, Settings, allow ocr
		}

		Case "debug":
		settings.OCR.debug := LLK_ControlGet(cHWND)
		IniWrite, % settings.OCR.debug, ini\ocr.ini, settings, enable debug

		Case "z_hotkey":
		input := LLK_ControlGet(cHWND)
		If (StrLen(input) != 1)
			Loop, Parse, % "+!^#"
				input := StrReplace(input, A_LoopField)

		If !Blank(input) && GetKeyVK(input)
		{
			settings.OCR.z_hotkey := input
			IniWrite, % input, ini\ocr.ini, settings, toggle highlighting hotkey
			GuiControl, +cBlack, % cHWND
		}
		Else GuiControl, +cRed, % cHWND

		Case "hotkey_set":
		input := LLK_ControlGet(vars.hwnd.settings.hotkey)
		If (StrLen(input) != 1)
			Loop, Parse, % "+!^#"
				input := StrReplace(input, A_LoopField)

		If LLK_ControlGet(vars.hwnd.settings.hotkey) && (!GetKeyVK(input) || (input = ""))
		{
			WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.settings.hotkey
			LLK_ToolTip(LangTrans("m_hotkeys_error"),, x, y + h,, "red")
			Return
		}
		IniWrite, % LLK_ControlGet(vars.hwnd.settings.hotkey_block), ini\ocr.ini, settings, block native key-function
		IniWrite, % input, ini\ocr.ini, settings, hotkey
		IniWrite, % "tldr-tooltips", ini\config.ini, versions, reload settings
		KeyWait, LButton
		Reload
		ExitApp

		Default:
		If InStr(check, "font")
		{
			While GetKeyState("LButton", "P")
			{
				If (control = "reset")
					settings.OCR.fSize := settings.general.fSize
				Else settings.OCR.fSize += (control = "minus") ? -1 : 1, settings.OCR.fSize := (settings.OCR.fSize < 6) ? 6 : settings.OCR.fSize
				GuiControl, text, % vars.hwnd.settings.font_reset, % settings.OCR.fSize
				Sleep 150
			}
			IniWrite, % settings.OCR.fSize, ini\ocr.ini, settings, font-size
			LLK_FontDimensions(settings.OCR.fSize, height, width), settings.OCR.fWidth := width, settings.OCR.fHeight := height
		}
		Else If InStr(check, "color_")
		{
			pattern := SubStr(control, 1, 1), type := SubStr(control, 2, 1)
			color := (vars.system.click = 1) ? RGB_Picker(settings.OCR.colors[pattern][type]) : settings.OCR.dColors[pattern][type]
			If !Blank(color)
			{
				settings.OCR.colors[pattern][type] := color
				IniWrite, % settings.OCR.colors[pattern].1 "," settings.OCR.colors[pattern].2, ini\ocr.ini, UI, % "pattern " pattern
				Loop, 2
				{
					GuiControl, % "+c" settings.OCR.colors[pattern][A_Index], % vars.hwnd.settings["color_" pattern "_text" A_Index]
					GuiControl, % "movedraw", % vars.hwnd.settings["color_" pattern "_text" A_Index]
					GuiControl, % "+c" settings.OCR.colors[pattern][A_Index], % vars.hwnd.settings["color_" pattern "_panel" A_Index]
					GuiControl, % "movedraw", % vars.hwnd.settings["color_" pattern "_panel" A_Index]
				}
			}
		}
		Else If (check = "hotkey" || check = "hotkey_block")
		{
			setting := LLK_ControlGet(cHWND)
			If (check = "hotkey")
			{
				If (StrLen(setting) > 1)
					Loop, Parse, % "+!^#"
						setting := StrReplace(setting, A_LoopField)
				GuiControl, % "+c" (!GetKeyVK(setting) ? "Red" : "Black"), % cHWND
				GuiControl, movedraw, % cHWND
			}
			GuiControl, % (setting != settings.OCR[check] ? "-Hidden" : "+Hidden"), % vars.hwnd.settings.hotkey_set
		}
		Else LLK_ToolTip("no action: " check)

		If (InStr(check, "color_") || InStr(check, "font")) && vars.hwnd.ocr_tooltip.main && WinExist("ahk_id " vars.hwnd.ocr_tooltip.main)
			mode := vars.OCR.last, OCR_%mode%()
	}
}

Settings_qol()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Minor-Features">wiki page</a>

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs HWNDhwnd1 y+"vars.settings.spacing " Section", % LangTrans("m_qol_alarm")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.alarm, % LangTrans("global_enable")
	vars.hwnd.help_tooltips["settings_alarm enable"] := hwnd1, vars.hwnd.settings.enable_alarm := vars.hwnd.help_tooltips["settings_alarm enable|"] := hwnd

	If settings.qol.alarm
	{
		Gui, %GUI%: Add, Text, % "xs HWNDhwnd0 Section", % LangTrans("global_font")
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.alarmfont_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*3, % settings.alarm.fSize
		vars.hwnd.settings.alarmfont_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.alarmfont_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth, % LangTrans("global_color", 2) ":"

		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " BackgroundTrans Border HWNDhwnd gSettings_qol2", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd1 c" settings.alarm.color, 100
		vars.hwnd.settings.color_alarm := hwnd, vars.hwnd.settings.color_alarm_bar := vars.hwnd.help_tooltips["settings_generic color double"] := hwnd1
		Gui, %GUI%: Add, Text, % "ys x+-1 BackgroundTrans Border HWNDhwnd gSettings_qol2", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd1 c" settings.alarm.color1, 100
		vars.hwnd.settings.color_alarm1 := hwnd, vars.hwnd.settings.color_alarm1_bar := vars.hwnd.help_tooltips["settings_generic color double1"] := hwnd1
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs HWNDhwnd0 y+"vars.settings.spacing " Section", % LangTrans("m_qol_notepad")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.notepad, % LangTrans("global_enable")
	vars.hwnd.help_tooltips["settings_notepad enable"] := hwnd0, vars.hwnd.settings.enable_notepad := vars.hwnd.help_tooltips["settings_notepad enable|"] := hwnd

	If settings.qol.notepad
	{
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd0", % LangTrans("global_font")
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "–"
		vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.notepadfont_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*3, % settings.notepad.fSize
		vars.hwnd.settings.notepadfont_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " HWNDhwnd Border Center gSettings_qol2 w"settings.general.fWidth*2, % "+"
		vars.hwnd.settings.notepadfont_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_qol_widgetcolor")
		vars.hwnd.help_tooltips["settings_notepad default color"] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " BackgroundTrans Border HWNDhwnd gSettings_qol2", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd1 c" settings.notepad.color, 100
		vars.hwnd.settings.color_notepad := hwnd, vars.hwnd.settings.color_notepad_bar := vars.hwnd.help_tooltips["settings_generic color double|"] := hwnd1
		Gui, %GUI%: Add, Text, % "ys x+-1 BackgroundTrans Border HWNDhwnd gSettings_qol2", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd1 c" settings.notepad.color1, 100
		vars.hwnd.settings.color_notepad1 := hwnd, vars.hwnd.settings.color_notepad1_bar := vars.hwnd.help_tooltips["settings_generic color double1|"] := hwnd1
		Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd", % LangTrans("m_qol_widget")
		vars.hwnd.help_tooltips["settings_notepad opacity"] := hwnd, handle := "|"
		Loop 6
		{
			Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth / (A_Index = 1 ? 2 : 4) " HWNDhwnd Border Center gSettings_qol2 w" settings.general.fWidth*2 (A_Index - 1 = settings.notepad.trans ? " cFuchsia" : ""), % A_Index - 1
			vars.hwnd.settings["notepadopac_" A_Index - 1] := vars.hwnd.help_tooltips["settings_notepad opacity" handle] := hwnd, handle .= "|"
		}
	}

	If vars.client.stream
		Return
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section xs HWNDhwnd0 y+"vars.settings.spacing (settings.general.lang_client = "unknown" ? " cGray" : ""), % LangTrans("m_qol_lab")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " gSettings_qol2 HWNDhwnd Checked"settings.qol.lab (settings.general.lang_client = "unknown" ? " cGray" : ""), % LangTrans("global_enable")
	If (settings.general.lang_client = "unknown")
		vars.hwnd.help_tooltips["settings_lang incompatible"] := hwnd0, vars.hwnd.settings.enable_lab := vars.hwnd.help_tooltips["settings_lang incompatible|"] := hwnd
	Else vars.hwnd.help_tooltips["settings_lab enable"] := hwnd0, vars.hwnd.settings.enable_lab := vars.hwnd.help_tooltips["settings_lab enable|"] := hwnd
}

Settings_qol2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), control1 := SubStr(check, 1, InStr(check, "_") - 1)
	If InStr(check, "enable_")
	{
		If (control = "lab" && settings.general.lang_client = "unknown")
		{
			GuiControl,, % cHWND, 0
			Return
		}
		settings.qol[control] := LLK_ControlGet(cHWND)
		IniWrite, % settings.qol[control], ini\qol tools.ini, features, % control
		If (control = "alarm") && !settings.qol.alarm
			vars.alarm.timestamp := "", LLK_Overlay(vars.hwnd.alarm.main, "destroy")
		If (control = "notepad")
			Init_GUI()
		If (control = "notepad") && !settings.qol.notepad
		{
			LLK_Overlay(vars.hwnd.notepad.main, "destroy"), vars.hwnd.notepad.main := ""
			For key, val in vars.hwnd.notepad_widgets
				LLK_Overlay(val, "destroy")
			vars.hwnd.notepad_widgets := {}, vars.notepad_widgets := {}
		}
		Settings_menu("minor qol tools")
	}
	Else If InStr(check, "color_")
	{
		If (vars.system.click = 1)
			picked_rgb := RGB_Picker(settings[(SubStr(control, 0) = "1") ? SubStr(control, 1, -1) : control]["color" (InStr(control, "1") ? "1" : "")])
		If (vars.system.click = 1) && Blank(picked_rgb)
			Return
		Else
		{
			If InStr(check, "1")
				control := StrReplace(control, "1"), settings[control].color1 := (vars.system.click = 1) ? picked_rgb : "000000"
			Else settings[control].color := (vars.system.click = 1) ? picked_rgb : "FFFFFF"
		}
		IniWrite, % settings[control]["color" (InStr(check, "1") ? "1" : "")], ini\qol tools.ini, % control, % (InStr(check, "1") ? "background " : "font-") "color"
		GuiControl, % "+c"settings[control]["color" (InStr(check, "1") ? "1" : "")], % vars.hwnd.settings[check "_bar"]
		GuiControl, movedraw, % vars.hwnd.settings[check "_bar"]
		If (control = "notepad")
		{
			NotepadReload()
			For key, val in vars.hwnd.notepad_widgets
					NotepadWidget(key)
			If WinExist("ahk_id " vars.hwnd.notepad.main)
				Notepad("save"), Notepad()
		}
		If (control = "alarm") && WinExist("ahk_id " vars.hwnd.alarm.main)
			Alarm()
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
		control1 := SubStr(control1, 1, InStr(control1, "opac") - 1)
		GuiControl, +cWhite, % vars.hwnd.settings[control1 "opac_" settings[control1].trans]
		GuiControl, movedraw, % vars.hwnd.settings[control1 "opac_" settings[control1].trans]
		settings[control1].trans := control
		IniWrite, % settings[control1].trans, ini\qol tools.ini, % control1, transparency
		GuiControl, +cFuchsia, % vars.hwnd.settings[control1 "opac_" settings[control1].trans]
		GuiControl, movedraw, % vars.hwnd.settings[control1 "opac_" settings[control1].trans]
		If (control1 = "notepad") && vars.hwnd.notepad_widgets.Count()
			For key, val in vars.hwnd.notepad_widgets
				WinSet, Transparent, % (key = "notepad_reminder_feature") ? 250 : 50 * settings.notepad.trans, % "ahk_id "val
	}
	Else LLK_ToolTip("no action")
}

Settings_screenchecks()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Screen-checks">wiki page</a>
	Gui, %GUI%: Font, % "underline bold"
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % LangTrans("m_screen_pixel")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Font, % "norm"
	vars.hwnd.help_tooltips["settings_screenchecks pixel-about"] := hwnd

	For key in vars.pixelsearch.list
	{
		If (key = "inventory") && !(settings.iteminfo.compare || settings.features.maptracker && settings.maptracker.mechanics && settings.maptracker.portal_reminder || settings.features.mapinfo && settings.mapinfo.trigger || settings.iteminfo.trigger)
			continue
		Gui, %GUI%: Add, Text, % "xs Section border gSettings_screenchecks2 HWNDhwnd", % " " LangTrans("global_info") " "
		vars.hwnd.settings["info_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-info"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd"(Blank(vars.pixelsearch[key].color1) ? " cRed" : ""), % " " LangTrans("global_calibrate") " "
		vars.hwnd.settings["cPixel_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-calibration"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd", % " " LangTrans("global_test") " "
		vars.hwnd.settings["tPixel_"key] := vars.hwnd.help_tooltips["settings_screenchecks pixel-test"handle] := hwnd, handle .= "|"
		Gui, %GUI%: Add, Text, % "ys", % LangTrans((key = "inventory" ? "global_" : "m_screen_") key)
	}
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Checkbox, % "hp xs Section gSettings_screenchecks2 HWNDhwnd Checked" settings.features.pixelchecks, % LangTrans("m_screen_pixel", 2)
	vars.hwnd.settings.pixelchecks := vars.hwnd.help_tooltips["settings_screenchecks pixel-background"] := hwnd

	If vars.client.stream
	{
		Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("global_variance") ":"
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys hp Number Limit3 r1 cBlack gSettings_screenchecks2 HWNDhwnd w" settings.general.fWidth * 3, % vars.pixelsearch.variation
		Gui, %GUI%: Font, % "s" settings.general.fSize
		Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd1", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_screenchecks variance"] := hwnd1, vars.hwnd.settings.variance_pixel := hwnd
	}

	count := 0
	For key in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot))
			Continue
		count += 1
	}
	If !count
		Return

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % LangTrans("m_screen_image")
	Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Font, norm
	vars.hwnd.help_tooltips["settings_screenchecks image-about"] := hwnd, handle := ""

	For key in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || InStr(key, "necro_") && !settings.features.necropolis || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot))
			Continue
		Gui, %GUI%: Add, Text, % "xs Section border gSettings_screenchecks2 HWNDhwnd", % " " LangTrans("global_info") " "
		vars.hwnd.settings["info_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-info"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd"(!FileExist("img\Recognition (" vars.client.h "p)\GUI\" key ".bmp") ? " cRed" : ""), % " " LangTrans("global_calibrate") " "
		vars.hwnd.settings["cImage_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-calibration"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " border gSettings_screenchecks2 HWNDhwnd" (Blank(vars.imagesearch[key].x1) ? " cRed" : ""), % " " LangTrans("global_test") " "
		vars.hwnd.settings["tImage_"key] := vars.hwnd.help_tooltips["settings_screenchecks image-test"handle] := hwnd, handle .= "|"
		Gui, %GUI%: Add, Text, % "ys", % LangTrans((key = "betrayal" ? "mechanic_" : "global_") key)
	}
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section Center Border gSettings_screenchecks2 HWNDhwnd", % " " LangTrans("global_imgfolder") " "
	vars.hwnd.settings.folder := vars.hwnd.help_tooltips["settings_screenchecks folder"] := hwnd

	If vars.client.stream
	{
		Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("global_variance") ":"
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys hp Number Limit3 r1 cBlack gSettings_screenchecks2 HWNDhwnd w" settings.general.fWidth * 3, % vars.imagesearch.variation
		Gui, %GUI%: Font, % "s" settings.general.fSize
		Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd1", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_screenchecks variance|"] := hwnd1, vars.hwnd.settings.variance_image := hwnd
	}
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
		Case "folder":
			If FileExist("img\Recognition ("vars.client.h "p)\GUI")
				Run, % "explore img\Recognition ("vars.client.h "p)\GUI\"
			Else LLK_ToolTip(LangTrans("cheat_filemissing"),,,,, "red")
		Default:
			If InStr(check, "variance_")
			{
				input := LLK_ControlGet(cHWND), input := (input > 255) ? 255 : Blank(input) ? 0 : input
				IniWrite, % (vars[control "search"].variation := input), ini\geforce now.ini, settings, % control "-check variation"
			}
			Else If InStr(check, "Pixel")
			{
				Switch SubStr(check, 1, 1)
				{
					Case "t":
						If Screenchecks_PixelSearch(control)
							LLK_ToolTip(LangTrans("global_positive"),,,,, "lime")
						Else LLK_ToolTip(LangTrans("global_negative"),,,,, "red")
					Case "c":
						Screenchecks_PixelRecalibrate(control)
						LLK_ToolTip(LangTrans("global_success"),,,,, "lime"), Settings_ScreenChecksValid()
						GuiControl, +cWhite, % cHWND
						GuiControl, movedraw, % cHWND
				}
			}
			Else If InStr(check, "Image")
			{
				Switch SubStr(check, 1, 1)
				{
					Case "t":
						If (Screenchecks_ImageSearch(control) > 0)
						{
							LLK_ToolTip(LangTrans("global_positive"),,,,, "lime"), Settings_ScreenChecksValid()
							GuiControl, +cWhite, % cHWND
							GuiControl, movedraw, % cHWND
						}
						Else LLK_ToolTip(LangTrans("global_negative"),,,,, "red")
					Case "c":
						pClipboard := Screenchecks_ImageRecalibrate("", control)
						If (pClipboard <= 0)
							Return
						Else
						{
							Gdip_SaveBitmapToFile(pClipboard, "img\Recognition (" vars.client.h "p)\GUI\" control ".bmp", 100), Gdip_DisposeImage(pClipboard)
							For key in vars.imagesearch[control]
							{
								If (SubStr(key, 1, 1) = "x" || SubStr(key, 1, 1) = "y") && IsNumber(SubStr(key, 2, 1))
									vars.imagesearch[control][key] := ""
							}
							IniWrite, % "", % "ini\screen checks ("vars.client.h "p).ini", % control, last coordinates
							Settings_ScreenChecksValid()
							GuiControl, +cWhite, % vars.hwnd.settings["cImage_"control]
							GuiControl, movedraw, % vars.hwnd.settings["cImage_"control]
							GuiControl, +cRed, % vars.hwnd.settings["tImage_"control]
							GuiControl, movedraw, % vars.hwnd.settings["tImage_"control]
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
		If (key = "inventory" && !(settings.iteminfo.compare || settings.iteminfo.trigger || settings.mapinfo.trigger))
			continue
		valid *= vars.pixelsearch[key].color1 ? 1 : 0
	}

	For key, val in vars.imagesearch.list
	{
		If (settings.features[key] = 0) || InStr(key, "necro_") && !settings.features.necropolis || (key = "skilltree" && !settings.features.leveltracker) || (key = "stash" && (!settings.features.maptracker || !settings.maptracker.loot))
			continue
		valid *= FileExist("img\Recognition ("vars.client.h "p)\GUI\"key ".bmp") && !Blank(vars.imagesearch[key].x1) ? 1 : 0
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

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Add, Link, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Search-strings">wiki page</a>
	Gui, %GUI%: Add, Link, % "ys HWNDhwnd x+"2*settings.general.fWidth, <a href="https://poe.re/">poe regex</a>
	vars.hwnd.help_tooltips["settings_searchstrings poe-regex"] := hwnd

	For string, val in vars.searchstrings.list
	{
		If (A_Index = 1)
		{
			Gui, %GUI%: Font, bold underline
			Gui, %GUI%: Add, Text, % "xs Section BackgroundTrans y+"vars.settings.spacing, % LangTrans("m_search_usecases")
			Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd69", % "HBitmap:*" vars.pics.global.help
			Gui, %GUI%: Font, norm
		}
		vars.hwnd.help_tooltips["settings_searchstrings about"] := hwnd69, var := vars.searchstrings.list[string] ;short-cut variable
		color := !var.enable ? "Gray" : !FileExist("img\Recognition ("vars.client.h "p)\GUI\[search-strings] "string ".bmp") ? "Red" : "White", style := !var.enable ? "" : " gSettings_searchstrings2"
		Gui, %GUI%: Add, Text, % "Section xs Border HWNDhwnd c"color style, % " " LangTrans("global_calibrate") " "
		vars.hwnd.settings["cal_"string] := vars.hwnd.help_tooltips["settings_searchstrings calibrate"handle] := hwnd
		color := !var.enable ? "Gray" : !var.x1 ? "Red" : "White"
		Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd x+"settings.general.fWidth/4 " c"color style, % " " LangTrans("global_test") " "
		vars.hwnd.settings["test_"string] := vars.hwnd.help_tooltips["settings_searchstrings test"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys Border cWhite gSettings_searchstrings2 HWNDhwnd x+"settings.general.fWidth/4, % " " LangTrans("global_edit") " "
		vars.hwnd.settings["edit_"string] := vars.hwnd.help_tooltips["settings_searchstrings edit"handle] := hwnd
		Gui, %GUI%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd0 x+"settings.general.fWidth/4 " c"(string = "beast crafting" ? "Gray" : "White") (string = "beast crafting" ? "" : " gSettings_searchstrings2"), % " " LangTrans("global_delete", 2) " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled cRed range0-500 HWNDhwnd", 0
		vars.hwnd.settings["del_"string] := hwnd0, vars.hwnd.settings["delbar_"string] := vars.hwnd.help_tooltips["settings_searchstrings delete"handle] := hwnd
		color := !var.enable ? "Gray" : "White"
		Gui, %GUI%: Add, Checkbox, % "ys x+"settings.general.fWidth " c"color " gSettings_searchstrings2 HWNDhwnd Checked"vars.searchstrings.list[string].enable, % (vars.lang["m_search_" string] || vars.lang2["m_search_" string]) ? LangTrans("m_search_" string) : string
		vars.hwnd.settings["enable_"string] := vars.hwnd.help_tooltips["settings_searchstrings enable"(string = "hideout lilly" ? "-lilly" : (string = "beast crafting" ? "-beastcrafting" : "")) handle] := hwnd, handle .= "|"
	}

	Gui, %GUI%: Add, Text, % "Section xs HWNDhwnd0 y+"vars.settings.spacing, % LangTrans("m_search_add")
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden default HWNDhwnd gSettings_searchstrings2", ok
	vars.hwnd.help_tooltips["settings_searchstrings add"] := hwnd0, vars.hwnd.settings.add := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize - 4
	Gui, %GUI%: Add, Edit, % "ys cBlack x+" settings.general.fWidth/2 " hp HWNDhwnd w"settings.general.fWidth*15
	If !vars.searchstrings.list.Count()
	{
		Gui, %GUI%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd69", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_searchstrings about"] := hwnd69
	}
	vars.hwnd.settings.name := vars.hwnd.help_tooltips["settings_searchstrings add|"] := hwnd
	Gui, %GUI%: Font, % "s"settings.general.fSize
	GuiControl, % "+c" (!vars.searchstrings.enabled ? "Gray" : "White"), % vars.hwnd.settings["search-strings"]
	GuiControl, % "movedraw", % vars.hwnd.settings["search-strings"]
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

Settings_stash()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle, x_anchor := vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2
	Gui, %GUI%: Add, Link, % "Section x" x_anchor " y" vars.settings.ySelection, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Stash‐Ninja">wiki page</a>

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_stash2 y+" vars.settings.spacing " Checked" settings.features.stash, % LangTrans("m_stash_enable")
	vars.hwnd.settings.enable := vars.hwnd.help_tooltips["settings_stash enable"] := hwnd

	If !settings.features.stash
		Return

	Gui, %GUI%: Font, underline bold
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % LangTrans("global_general")
	Gui, %GUI%: Add, Button, % "xp yp wp hp Hidden Default HWNDhwnd gSettings_stash2", OK
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_stash_leagues")
	leagues := settings.stash.leagues, vars.hwnd.settings.apply_button := hwnd
	For index, array in leagues
	{
		Gui, %GUI%: Add, Text, % "ys HWNDhwnd Border Center gSettings_stash2" (index = 1 ? "" : " x+" settings.general.fWidth//2) . (array.2 = settings.stash.league ? " cLime" : ""), % " " array.1 " "
		vars.hwnd.settings["league_" array.2] := hwnd
	}

	If vars.client.stream
	{
		Gui, %GUI%: Add, Text, % "xs Section ", % LangTrans("global_hotkey")
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys HWNDhwnd Limit cBlack r1 gSettings_stash2 w" settings.general.fWidth * 8, % settings.stash.hotkey
		Gui, %GUI%: Font, % "s" settings.general.fSize
		vars.hwnd.settings.hotkey := vars.hwnd.help_tooltips["settings_stash hotkey"] := hwnd
	}

	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd gSettings_stash2 Checked" settings.stash.history, % LangTrans("m_stash_history")
	Gui, %GUI%: Add, Checkbox, % "ys HWNDhwnd1 gSettings_stash2 Checked" settings.stash.show_exalt, % LangTrans("m_stash_exalt")
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd4 gSettings_stash2 Checked" settings.stash.bulk_trade, % LangTrans("m_stash_bulk")
	If settings.stash.bulk_trade
	{
		Gui, %GUI%: Add, Text, % "xs+" settings.general.fWidth * 1.5 " Section HWNDhwnd3", % LangTrans("m_stash_mintrade")
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI%: Add, Edit, % "ys cBlack Number HWNDhwnd2 gSettings_stash2 Limit hp Right w" settings.general.fWidth * 3, % settings.stash.min_trade
		Gui, %GUI%: Font, % "s" settings.general.fSize
		Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd00 gSettings_stash2 Checked" settings.stash.autoprofiles, % LangTrans("m_stash_profiles")
		vars.hwnd.settings.min_trade := hwnd2, vars.hwnd.help_tooltips["settings_stash mintrade"] := hwnd2, vars.hwnd.help_tooltips["settings_stash mintrade|"] := hwnd3
		vars.hwnd.settings.autoprofiles := vars.hwnd.help_tooltips["settings_stash autoprofiles"] := hwnd00
	}
	vars.hwnd.settings.history := vars.hwnd.help_tooltips["settings_stash history"] := hwnd, vars.hwnd.settings.exalt := vars.hwnd.help_tooltips["settings_stash exalt"] := hwnd1
	vars.hwnd.settings.bulk_trade := vars.hwnd.help_tooltips["settings_stash bulk"] := hwnd4

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing " x" x_anchor, % LangTrans("global_ui")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("stash_pricetags")
	colors := settings.stash.colors.Clone()
	Loop 2
	{
		color1 := colors[Floor(A_Index * 1.5)], color2 := colors[A_Index * 2]
		Gui, %GUI%: Add, Text, % "ys Border Center HWNDhwndtext BackgroundTrans c" color1, % " 69.42 "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwndback c" color2, 100
		Gui, %GUI%: Add, Text, % "ys x+-1 Border BackgroundTrans gSettings_stash2 HWNDhwnd00", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd01 c" color1, 100
		Gui, %GUI%: Add, Text, % "ys x+-1 Border BackgroundTrans gSettings_stash2 HWNDhwnd10", % "  "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd11 c" color2, 100
		vars.hwnd.settings["color_" Floor(A_Index * 1.5)] := hwnd00, vars.hwnd.settings["color_" Floor(A_Index * 1.5) "_panel"] := hwnd01, vars.hwnd.settings["color_" Floor(A_Index * 1.5) "_text"] := hwndtext
		vars.hwnd.settings["color_" A_Index * 2] := hwnd10, vars.hwnd.settings["color_" A_Index * 2 "_panel"] := hwnd11, vars.hwnd.settings["color_" A_Index * 2 "_text"] := hwndback
		vars.hwnd.help_tooltips["settings_generic color double" (A_Index = 2 ? "|" : "")] := hwnd01, vars.hwnd.help_tooltips["settings_generic color double1" (A_Index = 2 ? "|" : "")] := hwnd11
		vars.hwnd.help_tooltips["settings_stash color tag" A_Index] := hwndback
	}


	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("global_font")
	Gui, %GUI%: Add, Text, % "ys x+" settings.general.fWidth/2 " Center Border gSettings_stash2 HWNDhwnd w"settings.general.fWidth*2, % "–"
	vars.hwnd.help_tooltips["settings_font-size"] := hwnd0, vars.hwnd.settings.font_minus := vars.hwnd.help_tooltips["settings_font-size|"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_stash2 HWNDhwnd w"settings.general.fWidth*3, % settings.stash.fSize
	vars.hwnd.settings.font_reset := vars.hwnd.help_tooltips["settings_font-size||"] := hwnd
	Gui, %GUI%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border gSettings_stash2 HWNDhwnd w"settings.general.fWidth*2, % "+"
	vars.hwnd.settings.font_plus := vars.hwnd.help_tooltips["settings_font-size|||"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "xs Section y+" vars.settings.spacing, % LangTrans("m_stash_tabs")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Pic, % "ys BackgroundTrans HWNDhwnd hp w-1", % "HBitmap:*" vars.pics.global.help

	vars.hwnd.help_tooltips["settings_stash config"] := hwnd
	If WinExist("ahk_id " vars.hwnd.stash.main) && vars.stash.active
		vars.settings.selected_tab := vars.stash.active
	Gui, %GUI%: Add, Text, % "xs Section HWNDhwnd2", % LangTrans("m_stash_active")
	Gui, %GUI%: Add, Text, % "ys Center Left c" (vars.settings.selected_tab ? "Lime" : "Red"), % (vars.settings.selected_tab ? LangTrans("m_stash_" vars.settings.selected_tab) : LangTrans("global_none"))
	If !vars.settings.selected_tab
		Return

	Gui, %GUI%: Add, Text, % "ys HWNDhwnd2", % "    " LangTrans("global_gap") ":"
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd3 gSettings_stash2 Center Border w" settings.general.fWidth * 2, % "–"
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd4 gSettings_stash2 Center Border wp x+" settings.general.fWidth//2, % "+"
	Gui, %GUI%: Add, Checkbox, % "xs Section HWNDhwnd5 gSettings_stash2 Checked" settings.stash[vars.stash.active].in_folder, % LangTrans("m_stash_folder")
	;vars.hwnd.settings["cal_" tab] := vars.hwnd.help_tooltips["settings_stash calibrate"] := hwnd
	vars.hwnd.settings.test := vars.hwnd.help_tooltips["settings_stash test"] := hwnd1, tab := vars.settings.selected_tab
	vars.hwnd.settings["gap-_" tab] := hwnd3, vars.hwnd.settings["gap+_" tab] vars.hwnd.help_tooltips["settings_stash gap"] := hwnd2
	vars.hwnd.settings["gap+_" tab] := hwnd4, vars.hwnd.settings["infolder_" tab] := vars.hwnd.help_tooltips["settings_stash in folder"] := hwnd5

	Gui, %GUI%: Add, Text, % "xs Section", % LangTrans("m_stash_limits")
	Gui, %GUI%: Add, Pic, % "ys HWNDhwnd hp w-1", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI%: Font, % "s" settings.general.fSize - 4 " cBlack"
	vars.hwnd.help_tooltips["settings_stash limits"] := hwnd, currencies := ["c", "e", "d", "%"]
	Loop 5
	{
		style := (A_Index != 5) && settings.stash.bulk_trade && settings.stash.min_trade && settings.stash.autoprofiles ? " Disabled" : ""
		If style
			Gui, %GUI%: Add, Edit, % (A_Index = 1 ? "xs" : "ys x+" settings.general.fWidth/2) " Section Border Center w" settings.stash.fWidth * 2 " h" settings.stash.fHeight . style, % A_Index
		Else
		{
			Gui, %GUI%: Add, Text, % (A_Index = 1 ? "xs" : "ys x+" settings.general.fWidth/2) " Section cWhite 0x200 Border Center w" settings.stash.fWidth * 2 " h" settings.stash.fHeight, % A_Index
			;Gui, %GUI%: Add, Progress, % "Disabled xp yp wp hp BackgroundWhite", 0
		}
		Gui, %GUI%: Add, Edit, % "xs y+-1 Center HWNDhwnd2 gSettings_stash2 Limit1 wp hp" style, % currencies[settings.stash[tab].limits[A_Index].3]
		Gui, %GUI%: Add, Edit, % "ys Section x+-1 Center HWNDhwnd gSettings_stash2 Limit w" settings.general.fWidth * 4 " hp" style, % settings.stash[tab].limits[A_Index].2
		Gui, %GUI%: Add, Edit, % "xs y+-1 Center HWNDhwnd1 Limit gSettings_stash2 wp hp" style, % settings.stash[tab].limits[A_Index].1

		vars.hwnd.settings["limits" A_Index "top_" tab] := hwnd, vars.hwnd.settings["limits" A_Index "bot_" tab] := hwnd1, vars.hwnd.settings["limits" A_Index "cur_" tab] := hwnd2
	}
	/*
	Loop 5
	{
		style := (A_Index != 5) && settings.stash.bulk_trade && settings.stash.min_trade && settings.stash.autoprofiles ? "Disabled " : ""
		Gui, %GUI%: Add, Text, % (A_Index = 1 ? "xs Section" : "ys x+" settings.general.fWidth//2) " Border Center 0x200 h" settings.general.fHeight * 2 - 1 " w" settings.general.fWidth * 2, % A_Index
		Gui, %GUI%: Font, % "s" settings.general.fSize - 4 " cBlack"
		Gui, %GUI%: Add, Edit, % style "ys x+-1 Section Center HWNDhwnd gSettings_stash2 Limit w" settings.general.fWidth * 3 " h" settings.general.fHeight, % settings.stash[tab].limits[A_Index].2
		ControlGetPos, x, y,,,, ahk_id %hwnd%
		Gui, %GUI%: Add, Edit, % style "xs y+-1 Center HWNDhwnd1 Limit gSettings_stash2 wp h" settings.general.fHeight, % settings.stash[tab].limits[A_Index].1
		Gui, %GUI%: Add, Edit, % style "ys Center x+0 HWNDhwnd2 gSettings_stash2 Limit1 y" y + settings.general.fHeight/2 - 1 " w" settings.general.fWidth * 2, % currencies[settings.stash[tab].limits[A_Index].3]
		Gui, %GUI%: Font, % "s" settings.general.fSize " cWhite"
		vars.hwnd.settings["limits" A_Index "top_" tab] := hwnd, vars.hwnd.settings["limits" A_Index "bot_" tab] := hwnd1, vars.hwnd.settings["limits" A_Index "cur_" tab] := hwnd2
	}
	*/
}

Settings_stash2(cHWND)
{
	local
	global vars, settings
	static in_progress

	If in_progress
		Return
	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1), in_progress := 1
	If !InStr(check, "test") && !InStr(check, "font_")
		KeyWait, LButton

	If (check = "enable")
	{
		IniWrite, % (settings.features.stash := LLK_ControlGet(cHWND)), ini\config.ini, features, enable stash-ninja
		If !settings.features.stash
			Stash_Close()
		Settings_menu("stash-ninja")
	}
	Else If (check = "hotkey")
	{
		GuiControl, +cRed, % cHWND
		GuiControl, movedraw, % cHWND
	}
	Else If (check = "apply_button")
	{
		ControlGetFocus, hwnd, % "ahk_id " vars.hwnd.settings.main
		ControlGet, hwnd, HWND,, % hwnd
		If !InStr(vars.hwnd.settings.hotkey "," vars.hwnd.settings.min_trade, hwnd)
		{
			in_progress := 0
			Return
		}
		If (hwnd = vars.hwnd.settings.min_trade)
		{
			input := LLK_ControlGet(vars.hwnd.settings.min_trade)
			IniWrite, % (settings.stash.min_trade := !input ? "" : input), ini\stash-ninja.ini, settings, minimum trade value
			Init_stash("bulk_trade"), Settings_menu("stash-ninja"), in_progress := 0
			Return
		}
		Else If (hwnd = vars.hwnd.settings.hotkey)
		{
			If (StrLen(input0 := LLK_ControlGet(vars.hwnd.settings.hotkey)) > 1)
				Loop, Parse, % "^!#+"
					input := (A_Index = 1) ? input0 : input, input := StrReplace(input, A_LoopField)
			If !GetKeyVK(input)
			{
				WinGetPos, x, y, w, h, % "ahk_id " vars.hwnd.settings.hotkey
				LLK_ToolTip(LangTrans("m_hotkeys_error"), 1.5, x + w - 1, y,, "Red")
			}
			Else
			{
				Hotkey, IfWinActive, ahk_group poe_window
				Hotkey, % settings.stash.hotkey, Stash_Selection, Off
				Hotkey, % (settings.stash.hotkey := input0), Stash_Selection, On
				IniWrite, % """" input0 """", ini\stash-ninja.ini, settings, hotkey
				GuiControl, +cBlack, % vars.hwnd.settings.hotkey
				GuiControl, movedraw, % vars.hwnd.settings.hotkey
			}
			in_progress := 0
			Return
		}
	}
	Else If InStr(check, "enable_")
	{
		IniWrite, % (settings.stash[control].enable := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, % control, enable
		Settings_menu("stash-ninja")
	}
	Else If InStr(check, "league_")
	{
		GuiControl, +cWhite, % vars.hwnd.settings["league_" settings.stash.league]
		GuiControl, movedraw, % vars.hwnd.settings["league_" settings.stash.league]
		IniWrite, % (settings.stash.league := control), ini\stash-ninja.ini, settings, league
		GuiControl, +cLime, % cHWND
		GuiControl, movedraw, % cHWND
		Stash_PriceFetch("flush")
	}
	Else If (check = "history")
		IniWrite, % (settings.stash.history := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, settings, enable price history
	Else If (check = "exalt")
		IniWrite, % (settings.stash.show_exalt := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, settings, show exalt conversion
	Else If (check = "bulk_trade")
	{
		IniWrite, % (settings.stash.bulk_trade := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, settings, show bulk-sale suggestions
		If !settings.stash.bulk_trade && WinExist("ahk_id " vars.hwnd.stash_picker.main)
			Stash_PricePicker("destroy"), vars.stash.enter := 0
		Init_stash("bulk_trade"), Settings_menu("stash-ninja")
	}
	Else If (check = "min_trade")
	{
		GuiControl, +cRed, % cHWND
		GuiControl, movedraw, % cHWND
	}
	Else If (check = "autoprofiles")
	{
		IniWrite, % (settings.stash.autoprofiles := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, settings, enable trade-value profiles
		Init_stash("bulk_trade"), Settings_menu("stash-ninja")
	}
	Else If InStr(check, "font_")
	{
		If (control = "minus") && (settings.stash.fSize <= 6)
		{
			in_progress := 0
			Return
		}
		While GetKeyState("LButton", "P") ;&& !InStr(check, "reset")
		{
			If (control = "reset")
				settings.stash.fSize := settings.general.fSize
			Else settings.stash.fSize += (control = "minus" && settings.stash.fSize > 6) ? -1 : (control = "plus" ? 1 : 0)
			GuiControl, Text, % vars.hwnd.settings.font_reset, % settings.stash.fSize
			Sleep 150
		}
		IniWrite, % settings.stash.fSize, ini\stash-ninja.ini, settings, font-size
		Init_stash("font")
	}
	Else If InStr(check, "color_")
	{
		color := (vars.system.click = 1) ? RGB_Picker(settings.stash.colors[control]) : (InStr("13", control) ? "000000" : (control = 2) ? "00FF00" : "FF8000")
		If Blank(color)
		{
			in_progress := 0
			Return
		}
		GuiControl, % "+c" color, % vars.hwnd.settings["color_" control "_panel"]
		GuiControl, % "+c" color, % vars.hwnd.settings["color_" control "_text"]
		GuiControl, % "movedraw", % vars.hwnd.settings["color_" control "_text"]
		IniWrite, % (settings.stash.colors[control] := color), ini\stash-ninja.ini, UI, % (InStr("13", control) ? "text" : "background") " color" (control > 2 ? "2" : "")
	}
	Else If InStr(check, "gap")
	{
		If InStr(check, "-") && (settings.stash[control].gap = 0)
		{
			in_progress := 0
			Return
		}
		settings.stash[control].gap += InStr(check, "-") ? -1 : 1
		IniWrite, % settings.stash[control].gap, ini\stash-ninja.ini, % control, gap
		Init_stash("gap")
	}
	Else If InStr(check, "infolder_")
	{
		groups := [["fragments", "scarabs", "breach"], ["currency1", "currency2"], ["delve"], ["blight"], ["delirium"], ["essences"], ["ultimatum"]], gCheck := LLK_HasVal(groups, control,,,, 1)
		For index, tab in groups[gCheck]
			IniWrite, % (settings.stash[tab].in_folder := LLK_ControlGet(cHWND)), ini\stash-ninja.ini, % tab, tab is in folder
		Init_stash(1)
	}
	Else If InStr(check, "limits")
	{
		types := {"bot": 1, "top": 2, "cur": 3}
		input := StrReplace(LLK_ControlGet(cHWND), ",", "."), lIndex := SubStr(check, 7, 1), lType := types[SubStr(check, 8, 3)], tab := control, currencies := ["c", "e", "d", "%"]
		If (SubStr(input, 1, 1) = "." || SubStr(input, 0) = ".") || InStr(input, "+")
			input := "invalid"
		If Blank(input)
			settings.stash[tab].limits0[lIndex][lType] := settings.stash[tab].limits[lIndex][lType] := "", input := "null"
		Else
		{
			lTop := settings.stash[tab].limits[lIndex].2, lBot := settings.stash[tab].limits[lIndex].1
			If (lType < 3) && !IsNumber(input) || (lType = 1 && !Blank(lTop) && input > lTop) || (lType = 2 && !Blank(lBot) && input < lBot)
			|| (lType = 3) && !InStr("ced%", input)
				valid := 0
			Else valid := 1
			GuiControl, % "+c" (!valid ? "Red" : "Black"), % cHWND
			GuiControl, movedraw, % cHWND
			If !valid
			{
				in_progress := 0
				Return
			}
			If (lType = 3)
				input := InStr("ced%", input)
			settings.stash[tab].limits0[lIndex][lType] := settings.stash[tab].limits[lIndex][lType] := input
			While InStr(settings.stash[tab].limits[lIndex][lType], ".") && InStr(".0", SubStr(settings.stash[tab].limits[lIndex][lType], 0))
				input := settings.stash[tab].limits0[lIndex][lType] := settings.stash[tab].limits[lIndex][lType] := SubStr(settings.stash[tab].limits[lIndex][lType], 1, -1)
		}
		IniWrite, % input, ini\stash-ninja.ini, % tab, % "limit " lIndex " " SubStr(check, 8, 3)
	}
	Else If InStr(check, "test")
		Stash_(vars.settings.selected_stash, 1)
	Else LLK_ToolTip("no action")

	For index, val in ["limits", "gap", "color_", "font_", "league_", "history", "folder"]
		If InStr(check, val) && WinExist("ahk_id " vars.hwnd.stash.main)
			Stash_("refresh", (val = "gap") ? 1 : 0)
	in_progress := 0
}

Settings_unsupported()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "xs Section y+"vars.settings.spacing, % "this feature is not available on clients`nwith an unsupported language.`n`nit will be available once a language-`npack for the current language has been`ninstalled.`n`nthese packs have to be created by the`ncommunity. to find out if there are any`nfor your language or how to`ncreate one, click the link below.`n"
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Link, % "Section xs", <a href="https://github.com/Lailloken/Lailloken-UI/discussions/categories/translations-localization">llk-ui discussions: translations</a>
}

Settings_updater()
{
	local
	global vars, settings

	GUI := "settings_menu" vars.settings.GUI_toggle
	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section x"vars.settings.xSelection + vars.settings.wSelection + vars.settings.xMargin*2 " y"vars.settings.ySelection, % LangTrans("global_general")
	Gui, %GUI%: Font, norm

	Gui, %GUI%: Add, Checkbox, % "Section xs HWNDhwnd gSettings_updater2 checked"settings.updater.update_check, % LangTrans("m_updater_autocheck")
	Gui, %GUI%: Add, Text, % "ys", % "        " ;to make the window a bit wider and improve changelog tooltips
	WinGetPos,,, wCheckbox, hCheckbox, ahk_id %hwnd%
	vars.hwnd.settings.update_check := vars.hwnd.help_tooltips["settings_update check"] := hwnd

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section xs y+"vars.settings.spacing, % LangTrans("m_updater_version")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Pic, % "ys hp w-1 Center Border BackgroundTrans HWNDhwnd gSettings_updater2", % "img\GUI\restart.png"
	vars.hwnd.settings.update_refresh := hwnd, LLK_PanelDimensions([LangTrans("m_updater_version", 2), LangTrans("m_updater_version", 3)], settings.general.fSize, width, height)

	If settings.general.dev
	{
		Gui, %GUI%: Add, Checkbox, % "ys hp gSettings_general2 HWNDhwnd Checked" settings.general.dev_env, % "dev branch"
		vars.hwnd.settings.dev_env := hwnd
	}

	Gui, %GUI%: Add, Text, % "Section xs w" width, % LangTrans("m_updater_version", 2)
	Gui, %GUI%: Add, Text, % "ys HWNDhwnd x+0", % vars.updater.version.2
	ControlGetPos, x,,,,, ahk_id %hwnd%
	color := vars.updater.skip && (vars.updater.latest.1 = vars.updater.skip) ? " cYellow" : (IsNumber(vars.updater.latest.1) && vars.updater.latest.1 > vars.updater.version.1) ? " cLime" : ""
	Gui, %GUI%: Add, Text, % "Section xs w" width . color, % LangTrans("m_updater_version", 3) " "
	Gui, %GUI%: Add, Text, % "ys x" x . color, % vars.updater.latest.2

	If InStr(vars.updater.latest.1, ".")
	{
		Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_update hotfix"] := hwnd
	}

	If !InStr(vars.updater.latest.1, ".") && IsNumber(vars.updater.latest.1) && (vars.updater.latest.1 > vars.updater.version.1) && (vars.updater.latest.1 != vars.updater.skip)
	{
		Gui, %GUI%: Add, Text, % "ys Border Center BackgroundTrans gSettings_updater2 HWNDhwnd", % " " LangTrans("m_updater_skip") " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd0", 0
		vars.hwnd.settings.skip := hwnd, vars.hwnd.settings.skip_bar := vars.hwnd.help_tooltips["settings_update skip"] := hwnd0
	}

	If IsNumber(vars.updater.latest.1) && IsObject(vars.updater.changelog)
	{
		Gui, %GUI%: Font, underline bold
		Gui, %GUI%: Add, Text, % "Section xs y+" vars.settings.spacing, % LangTrans("m_updater_versions")
		added := {}, selected := vars.updater.selected, selected_sub := SubStr(selected, InStr(selected, ".",, 0) + 1)
		Gui, %GUI%: Font, norm
		Gui, %GUI%: Add, Pic, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["settings_update versions"] := hwnd

		For index, val in vars.updater.changelog
		{
			major := SubStr(val.1.1, 1, 5)
			If (val.1.2 < 15200) || added[major]
				Continue
			added[major] := 1, version_match := InStr(selected, major) ? 1 : 0
			Gui, %GUI%: Add, Text, % "Section xs", % major
			Loop, % SubStr(val.1.2, -1) + 1
			{
				minor := SubStr(val.1.2, -1) + 1 - A_Index, color := (version_match && selected_sub = minor) ? " cFuchsia" : ""
				Gui, %GUI%: Add, Text, % "ys Border HWNDhwnd gSettings_updater2 Center w" settings.general.fWidth * 2 . color . (A_Index = 1 ? " x+0" : " x+" settings.general.fWidth/2), % minor
				vars.hwnd.settings["versionselect_" major . minor] := vars.hwnd.help_tooltips["settings_update changelog " major . minor] := hwnd
			}
		}
	}

	If vars.updater.selected
	{
		Gui, %GUI%: Add, Text, % "Section xs Border Center BackgroundTrans gSettings_updater2 HWNDhwnd00", % " " LangTrans("m_updater_changelog") " "
		Gui, %GUI%: Add, Text, % "ys Border Center BackgroundTrans gSettings_updater2 HWNDhwnd cFuchsia", % " " LangTrans("global_restart") " "
		Gui, %GUI%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd0", 0
		ControlGetPos,,, wButton,,, ahk_id %hwnd%
		vars.hwnd.settings["fullchangelog_" vars.updater.selected] := vars.hwnd.help_tooltips["settings_update full changelog"] := hwnd00
		vars.hwnd.settings.restart_install := hwnd, vars.hwnd.settings.restart_bar := vars.hwnd.help_tooltips["settings_update restart"] := hwnd0
	}

	If IsNumber(vars.update.1) && (vars.update.1 < 0)
	{
		Gui, %GUI%: Font, bold underline
		Gui, %GUI%: Add, Text, % "Section xs cRed y+"vars.settings.spacing, % LangTrans("m_updater_failed")
		Gui, %GUI%: Font, norm

		If InStr("126", StrReplace(vars.update.1, "-"))
			Gui, %GUI%: Add, Text, % "Section xs w" wCheckbox, % LangTrans("m_updater_error1") "`n`n" LangTrans("m_updater_error1", 2)
		Else If (vars.update.1 = -4)
			Gui, %GUI%: Add, Text, % "Section xs w" wCheckbox, % LangTrans("m_updater_error2") " " LangTrans("m_updater_error2", 2) "`n`n" LangTrans("m_updater_error2", 3)
		Else If (vars.update.1 = -3)
			Gui, %GUI%: Add, Text, % "Section xs w" wCheckbox, % LangTrans("m_updater_error3")
		Else If InStr("5", StrReplace(vars.update.1, "-"))
			Gui, %GUI%: Add, Text, % "Section xs w" wCheckbox, % LangTrans("m_updater_error4") " " LangTrans("m_updater_error2", 2) "`n`n" LangTrans("m_updater_error2", 3)

		If InStr("35", StrReplace(vars.update.1, "-"))
		{
			Gui, %GUI%: Add, Text, % "Section xs Center Border BackgroundTrans HWNDmanual gSettings_updater2", % " " LangTrans("m_updater_manual") " "
			Gui, %GUI%: Add, Progress, % "xp yp wp hp Border HWNDbar range0-10 BackgroundBlack cGreen", 0
			Gui, %GUI%: Add, Text, % "ys Center Border HWNDgithub gSettings_updater2", % " " LangTrans("m_updater_manual", 2) " "
			vars.hwnd.settings.manual := manual, vars.hwnd.settings.manual_bar := vars.hwnd.help_tooltips["settings_update manual"] := bar, vars.hwnd.settings.github := vars.hwnd.help_tooltips["settings_update github"] := github
		}
	}

	Gui, %GUI%: Font, bold underline
	Gui, %GUI%: Add, Text, % "Section xs y+"vars.settings.spacing, % LangTrans("m_updater_github")
	Gui, %GUI%: Font, norm
	Gui, %GUI%: Add, Text, % "Section xs Center Border HWNDpage gSettings_updater2", % " " LangTrans("m_updater_github", 2) " "
	Gui, %GUI%: Add, Text, % "ys Center Border HWNDreleases gSettings_updater2", % " " LangTrans("m_updater_github", 3) " "
	vars.hwnd.settings["githubpage_"(InStr(LLK_FileRead("data\versions.json"), "main.zip") ? "main" : "beta")] := page, vars.hwnd.settings.releases_page := releases
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
		If vars.updater.latest.2 && (A_TickCount < refresh_tick + 10000 && !settings.general.dev)
			Return
		in_progress := 1, UpdateCheck(1), in_progress := 0, refresh_tick := A_TickCount, Settings_menu("updater")
	}
	Else If InStr(check, "versionselect_")
	{
		vars.updater.selected := SubStr(check, InStr(check, "_") + 1)
		Settings_menu("updater")
	}
	Else If InStr(check, "fullchangelog_")
		Run, % "https://github.com/Lailloken/Lailloken-UI/releases/tag/v" control
	Else If (check = "restart_install")
	{
		If LLK_Progress(vars.hwnd.settings.restart_bar, "LButton")
		{
			KeyWait, LButton
			IniWrite, % vars.updater.selected, ini\config.ini, versions, apply update
			Reload
			ExitApp
		}
	}
	Else If (check = "manual")
	{
		in_progress := 1, UpdateDownload(vars.hwnd.settings.manual_bar)
		UrlDownloadToFile, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/tags/v" vars.update.2 ".zip", % "update\update_" vars.updater.target_version.2 ".zip"
		error := ErrorLevel || !FileExist("update\update_" vars.updater.target_version.2 ".zip") ? 1 : 0
		in_progress := 0
		SetTimer, UpdateDownload, Delete
		UpdateDownload("reset")
		If error
		{
			LLK_ToolTip(LangTrans("m_updater_download"), 3,,,, "red")
			Return
		}
		Run, explore %A_ScriptDir%
		Run, % "update\update_" vars.updater.target_version.2 ".zip"
		ExitApp
	}
	Else If (check = "github")
	{
		Run, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/tags/v" vars.update.2 ".zip"
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

Settings_WriteTest(cHWND := "")
{
	local
	global vars, settings
	static running

	If (cHWND = vars.hwnd.settings.writetest)
	{
		IniWrite, % vars.settings.active, ini\config.ini, Versions, reload settings
		Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
		ExitApp
	}

	If running
		Return
	running := 1, HWND_bar := vars.hwnd.settings.bar_writetest, yes := LangTrans("m_permission_yes"), no := LangTrans("m_permission_no"), unknown := LangTrans("m_permission_unknown")
	FileRemoveDir, data\write-test\, 1
	If FileExist("data\write-test\")
	{
		running := 0
		MsgBox,, % LangTrans("m_general_permissions"), % LangTrans("m_permission_error", 1) "`n`n" LangTrans("m_permission_error", 2)
		Run, explore %A_WorkingDir%\data\
		Return
	}
	status .= LangTrans("m_permission_admin") " " (A_IsAdmin ? yes : no) "`n`n"
	FileCreateDir, data\write-test\
	GuiControl,, % HWND_bar, 100
	sleep, 250
	status .= LangTrans("m_permission_folder", 1) " " (FileExist("data\write-test\") ? yes : no) "`n`n", folder_creation := FileExist("data\write-test\") ? 1 : 0

	FileAppend,, data\write-test.ini
	GuiControl,, % HWND_bar, 200
	sleep, 250
	status .= LangTrans("m_permission_ini", 1) " " (FileExist("data\write-test.ini") ? yes : no) "`n`n", ini_creation := FileExist("data\write-test.ini") ? 1 : 0

	IniWrite, 1, data\write-test.ini, write-test, test
	GuiControl,, % HWND_bar, 300
	sleep, 250
	IniRead, ini_test, data\write-test.ini, write-test, test, 0
	status .= LangTrans("m_permission_ini", 2) " " (ini_test ? yes : no) "`n`n"

	pWriteTest := Gdip_BitmapFromScreen("0|0|100|100"), Gdip_SaveBitmapToFile(pWriteTest, "data\write-test.bmp", 100), Gdip_DisposeImage(pWriteTest)
	GuiControl,, % HWND_bar, 400
	sleep, 250
	status .= LangTrans("m_permission_image", 1) " " (FileExist("data\write-test.bmp") ? yes : no) "`n`n", img_creation := FileExist("data\write-test.bmp") ? 1 : 0

	If folder_creation
	{
		FileRemoveDir, data\write-test\
		sleep, 250
		status .= LangTrans("m_permission_folder", 2) " " (!FileExist("data\write-test\") ? yes : no) "`n`n"
	}
	Else status .= LangTrans("m_permission_folder", 2) " " unknown "`n`n"
	GuiControl,, % HWND_bar, 500

	If ini_creation
	{
		FileDelete, data\write-test.ini
		sleep, 250
		status .= LangTrans("m_permission_ini", 3) " " (!FileExist("data\write-test.ini") ? yes : no) "`n`n"
	}
	Else status .= LangTrans("m_permission_ini", 3) " " unknown "`n`n"
	GuiControl,, % HWND_bar, 600

	If img_creation
	{
		FileDelete, data\write-test.bmp
		sleep, 250
		status .= LangTrans("m_permission_image", 2) " " (!FileExist("data\write-test.bmp") ? yes : no) "`n`n"
	}
	Else status .= LangTrans("m_permission_image", 2) " " unknown "`n`n"
	GuiControl,, % HWND_bar, 700

	MsgBox, 4096, % LangTrans("m_permission_header"), % status
	GuiControl,, % HWND_bar, 0
	running := 0
}
