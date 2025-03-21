Init_OCR()
{
	local
	global vars, settings, db, Json

	If vars.poe_version
		Return

	If !FileExist("ini" vars.poe_version "\ocr.ini")
		IniWrite, % "", % "ini" vars.poe_version "\ocr.ini", settings
	If !FileExist("ini" vars.poe_version "\ocr - altars.ini")
		IniWrite, % "", % "ini" vars.poe_version "\ocr - altars.ini", settings
	If !FileExist("ini" vars.poe_version "\ocr - vaal areas.ini")
		IniWrite, % "", % "ini" vars.poe_version "\ocr - vaal areas.ini", settings

	ini := IniBatchRead("ini" vars.poe_version "\ocr.ini"), settings.OCR := {"profile": 1} ;in case profiles are desired in the future
	settings.OCR.allow := vars.poe_version ? 0 : (!Blank(check := ini.settings["allow ocr"]) ? check : 0) * (vars.client.h > 720 ? 1 : 0)
	settings.OCR.hotkey := !Blank(check := ini.settings["hotkey"]) ? check : ""
	settings.OCR.hotkey_single := settings.OCR.hotkey
	If (StrLen(settings.OCR.hotkey) > 1)
		Loop, Parse, % "+!^#"
			settings.OCR.hotkey_single := StrReplace(settings.OCR.hotkey_single, A_LoopField)
	If !GetKeyVK(settings.OCR.hotkey_single)
		settings.OCR.hotkey_single := ""
	settings.OCR.hotkey_block := !Blank(check := ini.settings["block native key-function"]) ? check : 0
	settings.OCR.z_hotkey := !Blank(check := ini.settings["toggle highlighting hotkey"]) ? check : "z"
	settings.OCR.debug := !Blank(check := ini.settings["enable debug"]) ? check : 0
	settings.OCR.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.OCR.fSize, font_height, font_width), settings.OCR.fHeight := font_height, settings.OCR.fWidth := font_width
	settings.OCR.dColors := [["00FF00", "00000"], ["FF8000", "00000"], ["FF0000", "00000"], ["FF00FF", "00000"], ["FF0000", "FFFFFF"]], settings.OCR.dColors.0 := ["FFFFFF", "000000"]
	settings.OCR.colors := []
	For index, color in settings.OCR.dColors
		If !Blank(check := ini.UI["pattern " index])
			settings.OCR.colors[index] := StrSplit(check, ",")
		Else settings.OCR.colors[index] := color.Clone()

	settings.features.OCR := LLK_IniRead("ini" vars.poe_version "\config.ini", "Features", "enable ocr", 0) * settings.OCR.allow
	If settings.features.OCR && !Blank(settings.OCR.hotkey)
	{
		Hotkey, IfWinActive, ahk_group poe_ahk_window
		Hotkey, % "*" (settings.OCR.hotkey_block ? "" : "~") . Hotkeys_Convert(settings.OCR.hotkey), OCR
	}
}

OCR(mode := "GUI")
{
	local
	global vars, settings

	If !IsObject(vars.OCR)
		vars.OCR := {"wGUI": vars.client.h // 2.5, "hGUI": vars.client.h // 4.8}

	If vars.OCR.in_progress
		Return
	vars.OCR.in_progress := 1

	If !Blank(vars.hwnd.ocr_tooltip.main) && WinExist("ahk_id " vars.hwnd.ocr_tooltip.main)
	{
		OCR_Close()
		KeyWait, % settings.OCR.hotkey_single
		vars.OCR.in_progress := 0
		Return
	}

	If (mode != "compat")
	{
		If !WinActive("ahk_id " vars.hwnd.poe_client)
		{
			WinActivate, % "ahk_id " vars.hwnd.poe_client
			WinWaitActive, % "ahk_id " vars.hwnd.poe_client
		}
		SendInput, % "{" settings.OCR.z_hotkey "}"
		Sleep 100
	}

	If InStr("snip,compat", mode)
	{
		pBitmap := Screenchecks_ImageRecalibrate()
		If (pBitmap <= 0)
		{
			vars.OCR.in_progress := 0
			Return
		}
		Gdip_GetImageDimensions(pBitmap, w, h)
		If (w >= vars.client.w || h >= vars.client.h)
		{
			LLK_ToolTip(Lang_Trans("m_ocr_error", 2), 2, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "red", settings.general.fSize * 2,,, 1)
			Gdip_DisposeImage(pBitmap)
			vars.OCR.in_progress := 0
			Return
		}
	}
	Else If (mode = "GUI")
	{
		vars.OCR.GUI := 1, square := vars.client.h / 10, square1 := vars.client.h / 20
		Gui, ocr_GUI: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDocr_GUI
		Gui, ocr_GUI: Color, Gray
		WinSet, TransColor, Gray 75

		Gui, ocr_GUI2: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDocr_GUI2 +Ownerocr_GUI
		Gui, ocr_GUI2: Margin, 0, 0
		Gui, ocr_GUI2: Color, Gray
		WinSet, TransColor, Gray 75

		Loop
		{
			If (A_Index = 10)
			{
				Gui, ocr_GUI: Color, White
				Gui, ocr_GUI2: Color, White
			}
			MouseGetPos, xMouse, yMouse
			wGUI := vars.OCR.wGUI, hGUI := vars.OCR.hGUI
			xPos := (xMouse - wGUI < vars.client.x) ? vars.client.x : (xMouse + wGUI >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - wGUI * 2 : xMouse - wGUI
			yPos := (yMouse - hGUI < vars.client.y) ? vars.client.y : (yMouse + hGUI >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - hGUI * 2 : yMouse - hGUI
			xPos2 := (xMouse - square1 < vars.client.x) ? vars.client.x : (xMouse + square1 >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - square : xMouse - square1
			yPos2 := (yMouse - square1 < vars.client.y) ? vars.client.y : (yMouse + square1 >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - square : yMouse - square1
			Gui, ocr_GUI: Show, % "NA x" xPos " y" yPos " w" wGUI * 2 " h" hGUI * 2
			Gui, ocr_GUI2: Show, % "NA x" xPos2 " y" yPos2 " w" square " h" square

			If !GetKeyState(settings.OCR.hotkey_single, "P")
			{
				WinGetPos, xWin, yWin,,, ahk_id %ocr_GUI%
				vars.OCR.coords := {"xMouse": xMouse, "yMouse": yMouse, "hPanel": 0}
				If Blank(xWin) || Blank(yWin)
					Continue
				Gui, ocr_GUI: Destroy
				While WinExist("ahk_id " ocr_GUI)
					Sleep 100
				pBitmap0 := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1), pBitmap := Gdip_CloneBitmapArea(pBitmap0, xWin - vars.client.x + settings.general.oGamescreen, yWin - vars.client.y, wGUI * 2, hGUI * 2,, 1), Gdip_DisposeImage(pBitmap0)
				vars.OCR.GUI := 0
				Break
			}
			Sleep 10
		}
	}

	Gdip_GetImageDimensions(pBitmap, width, height)
	pBitmap_copy := pBitmap, pBitmap := Gdip_ResizeBitmap(pBitmap_copy, width*2, height*2, 1, 7, 1), Gdip_DisposeImage(pBitmap_copy)
	pEffect := Gdip_CreateEffect(5, 0, 35), Gdip_BitmapApplyEffect(pBitmap, pEffect), Gdip_DisposeEffect(pEffect)
	;pEffect := Gdip_CreateEffect(2, 0, 100), Gdip_BitmapApplyEffect(pBitmap, pEffect), Gdip_DisposeEffect(pEffect)
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap), pIRandomAccessStream := HBitmapToRandomAccessStream(hBitmap), Gdip_DisposeImage(pBitmap)
	text := ocr_uwp(pIRandomAccessStream), ObjRelease(pIRandomAccessStream), text := LLK_StringCase(text)

	vars.OCR.text_check := {}
	If (mode = "compat")
		Loop, Parse, text, `n, `r
			Loop, Parse, A_LoopField, % A_Space
				If (StrLen(A_LoopField) > 1)
				{
					loopfield_copy := ""
					Loop, Parse, A_LoopField
						If LLK_IsType(A_LoopField, "alpha")
							loopfield_copy .= A_LoopField
					If !vars.OCR.text_check.HasKey(loopfield_copy)
						vars.OCR.text_check[loopfield_copy] := ""
				}

	If (mode = "compat") && (vars.OCR.text_check.Count() >= 8) || (debug := settings.OCR.debug && GetKeyState("RCTRL", "P"))
	{
		Gui, compat_test: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_compat
		Gui, compat_test: Color, Black
		Gui, compat_test: Margin, % settings.general.fWidth, % settings.general.fWidth
		Gui, compat_test: Font, % "s" settings.general.fSize " cWhite", % vars.system.font
		vars.hwnd.compat_test := hwnd_compat

		Gui, compat_test: Add, Pic, % "Section Border w" width * (mode = "compat" ? 2 : 1) " h-1", HBitmap:*%hBitmap%
		If debug
		{
			vars.OCR.debug := 1
			Gui, compat_test: Font, % "s" settings.general.fSize - 4
			Gui, compat_test: Add, Edit, % "ys Section cBlack", % !Blank(text) ? text : Lang_Trans("ocr_notext")
			Gui, compat_test: Font, % "s" settings.general.fSize
			Gui, compat_test: Add, Text, % "xs HWNDhwnd", % "client-res: " vars.client.w "x" vars.client.h " " Lang_Trans("omnikey_escape")
			ControlFocus,, ahk_id %hwnd%
		}
		Else
		{
			Gui, compat_test: Add, Text, % "xs wp", % Lang_Trans("m_ocr_compatibility", 2)
			Gui, compat_test: Add, Edit, % "xs wp cBlack wp HWNDhwnd0 gSettings_OCR2",
			Gui, compat_test: Add, Text, % "xs wp HWNDhwnd1 cLime", % ""
			If (vars.system.click = 2)
				Gui, compat_test: Add, Text, % "ys Border", % text "`nclient-res: " vars.client.w "x" vars.client.h
			vars.hwnd.settings.compat_edit := hwnd0, vars.hwnd.settings.compat_correct := hwnd1
			LLK_Overlay(vars.hwnd.settings.main, "hide")
		}

		Gui, compat_test: Show, NA x10000 y10000
		WinGetPos,,, w, h, ahk_id %hwnd_compat%
		Gui, compat_test: Show, % "x" vars.monitor.x + vars.monitor.w / 2 - w//2 " y" vars.monitor.y + vars.monitor.h / 2 - h//2
	}
	DeleteObject(hBitmap)
	vars.OCR.in_progress := 0

	If Blank(text) && !debug
	{
		OCR_Error(Lang_Trans("ocr_notext"))
		Return
	}
	Else If (mode = "compat") && (vars.OCR.text_check.Count() < 8)
	{
		LLK_ToolTip(Lang_Trans("m_ocr_error"), 2.5,,,, "red")
		Return
	}
	Else If (mode = "compat") || debug
		Return text
	Else
	{
		vars.OCR.text := text
		If InStr(text, Lang_Trans("items_mapquantity"))
			OCR_VaalAreas()
		Else If InStr(text, ":",,, 2)
			OCR_Altars()
		Else OCR_Error(Lang_Trans("ocr_nousecase"))
	}
}

OCR_Altars()
{
	local
	global db, vars, settings
	static toggle := 0

	vars.OCR.toggle := toggle := !toggle, GUI_name := "ocr_tooltip" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_altars
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s" settings.OCR.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.ocr_tooltip.main, vars.hwnd.ocr_tooltip := {"main": hwnd_altars, "type": "altars"}, panels := [[], []], header := 0, parsed_text := [[], []], header_check := ["boss", "minions", "player"]
	header_dictionary := ["map", "boss", "gains", "eldritch", "minions", "gain", "player"], header_lookup := ["map boss gains:", "eldritch minions gain:", "player gains:"]
	text := vars.OCR.text, square1 := vars.client.h / 20

	If !IsObject(db.altars)
		DB_Load("OCR")

	Loop, Parse, text, `n, % "`r`t" A_Space
	{
		loopfield_copy := ""
		Loop, Parse, A_LoopField
			If LLK_IsType(A_LoopField, "alpha")
				loopfield_copy .= A_LoopField
		If Blank(loopfield_copy)
			Continue
		While InStr(loopfield_copy, "  ")
			loopfield_copy := StrReplace(loopfield_copy, "  ", " ")
		While (SubStr(loopfield_copy, 1, 1) = " ")
			loopfield_copy := SubStr(loopfield_copy, 2)
		While (SubStr(loopfield_copy, 0) = " ")
			loopfield_copy := SubStr(loopfield_copy, 1, -1)

		If (SubStr(A_LoopField, 0) = ":")
		{
			regex := regex_all := "", regex_array := StrSplit(loopfield_copy, A_Space), regex_array_copy := regex_array.Clone()
			For index, val in regex_array
				If !LLK_HasVal(header_dictionary, val)
					regex_array_copy[index] := ""
				Else regex .= (!regex ? "" : ".*") val

			regex_results := LLK_HasRegex(header_lookup, regex, 1)
			If (regex_results.Count() > 1)
			{
				regex := ""
				For index, key in regex_array_copy
				{
					If Blank(key)
					{
						blank_regex := ""
						Loop, Parse, % regex_array[index]
						{
							If LLK_HasRegex(header_lookup, OCR_RegexCheck(regex_array_copy, index, blank_regex . A_LoopField), 1)
								blank_regex .= A_LoopField
							Else blank_regex .= (SubStr(blank_regex, -1) = ".*") ? "" : ".*"
						}
						If (blank_regex != ".*")
							regex .= (!regex || SubStr(regex, -1) = ".*" ? "" : ".*") regex_array_copy[index] := blank_regex
					}
				}
				regex_results := LLK_HasRegex(header_lookup, regex, 1)
			}
			If (regex_results.Count() = 1) && (key != header_check[regex_results.1])
				key := header_check[regex_results.1], header += 1, parsed_text[header].Push(key ":")
		}
		Else If key
		{
			line := ""
			Loop, Parse, A_LoopField
				If LLK_IsType(A_LoopField, "alpha") || InStr("-',", A_LoopField)
					line .= A_LoopField
			While InStr(line, "  ")
				line := StrReplace(line, "  ", " ")
			While (SubStr(line, 1, 1) = " ")
				line := SubStr(line, 2)
			While (SubStr(line, 0) = " ")
				line := SubStr(line, 1, -1)
			parsed_text[header].Push(line)
		}
	}

	For index0, array in parsed_text
	{
		parsed_mods := []
		For index, line in array
		{
			If (index = 1)
			{
				key := StrReplace(line, ":"), panels[index0].Push(line), mod_lookup := db.altars[key "_check"]
				Continue
			}
			If (LLK_InStrCount(line, " ") < 2) && !InStr(line, "armour")
				Continue
			check := LLK_HasVal(mod_lookup, line)
			If check
			{
				If !LLK_HasVal(parsed_mods, line)
					parsed_mods.Push(line)
				Continue
			}

			regex := "i)", regex_array := StrSplit(line, A_Space), regex_array_copy := regex_array.Clone(), regex_all := "i)"
			For iRegex, vRegex in regex_array
			{
				If !LLK_HasVal(db.altar_dictionary, vRegex)
					regex_array_copy[iRegex] := 0
				Else regex .= (regex = "i)") ? vRegex : ".*" vRegex
			}

			If (LLK_HasRegex(mod_lookup, regex, 1).Count() = 1)
				regex_all := regex
			Else If (LLK_HasVal(regex_array_copy, 0,,, 1).Count() < regex_array_copy.Count()//2)
			{
				For iRegex, vRegex in regex_array_copy
				{
					If !vRegex
					{
						blank_regex := ""
						Loop, Parse, % regex_array[iRegex]
						{
							If LLK_HasRegex(mod_lookup, OCR_RegexCheck(regex_array_copy, iRegex, blank_regex . A_LoopField), 1)
								blank_regex .= A_LoopField
							Else blank_regex .= (SubStr(blank_regex, -1) = ".*") ? "" : ".*"
						}
						regex_array_copy[iRegex] := (blank_regex = ".*") ? "" : blank_regex
					}
				}

				For iRegex, vRegex in regex_array_copy
					If vRegex
						regex_all .= (regex_all = "i)" ? "" : ".*") vRegex
			}
			If (regex_all != "i)") && (regex_result := LLK_HasRegex(mod_lookup, regex_all, 1))
				parsed_mods.Push(regex_result.Count() > 1 ? "???" : mod_lookup[regex_result.1])
		}

		skip := 0
		For index, mod in parsed_mods
		{
			If skip
			{
				skip := 0
				Continue
			}
			prev_line := parsed_mods[index - 1], next_line := parsed_mods[index + 1], push := ""
			If next_line && (check := LLK_HasVal(db.altars[key], mod "`r`n" next_line, 1,, 1, 1)) && (check.Count() = 1)
			|| prev_line && (check := LLK_HasVal(db.altars[key], prev_line "`r`n" mod, 1,, 1, 1)) && (check.Count() = 1)
			|| (check := LLK_HasVal(db.altars[key], mod "`r`n", 1,, 1, 1)) && (check.Count() = 1) || (check := LLK_HasVal(db.altars[key], "`r`n" mod, 1,, 1, 1)) && (check.Count() = 1)
				push := db.altars[key][check.1].2
			Else If (check := LLK_HasVal(db.altars[key], mod "`r`n", 1,, 1, 1)) && InStr(next_line, "?")
				push := mod " | ???", skip := 1
			Else If (check := LLK_HasVal(db.altars[key], mod,,,, 1))
				push := db.altars[key][check].2
			Else If InStr(mod, "?") && next_line && (check := LLK_HasVal(db.altars[key], "`r`n" next_line, 1,, 1, 1))
				push := (check.Count() != 1) ? "??? | " next_line : db.altars[key][check.1].2, skip := 1
			Else push := "???"

			If push && (!LLK_HasVal(panels[index0], push) || InStr(push, "?"))
				panels[index0].Push(push)
		}
	}

	If (panels.1.Count() < 3) || (panels.2.Count() < 3) || !LLK_HasVal(panels, ":", 1,,, 1)
		OCR_Error(Lang_Trans("ocr_erroraltar"))
	Else
	{
		LLK_PanelDimensions(panels.1, settings.OCR.fSize, w1, h1), LLK_PanelDimensions(panels.2, settings.OCR.fSize, w2, h2)
		width := Max(w1, w2), ini := IniBatchRead("ini\ocr - altars.ini")
		For index, array in panels
			For index1, panel_text in array
			{
				If (index = 2 && index1 = 1)
					vars.OCR.coords.hPanel := yControl + hControl
				If (index1 = 1)
					key := StrReplace(panel_text, ":")
				rank := !Blank(check := ini["profile " settings.OCR.profile " " key][panel_text]) ? check : 0
				colors := (index1 = 1) ? ["FFFFFF", "000000"] : settings.OCR.colors[rank].Clone()
				Gui, %GUI_name%: Add, Text, % (index = 2 && index1 = 1 ? "y+" vars.client.h / 10 : (index = 1 && index1 = 1) ? "" : "y+-1") " xs Section Center Border BackgroundTrans HWNDhwnd0 w" width " c" colors.1, % StrReplace(panel_text, "&", "&&")
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border HWNDhwnd BackgroundBlack c" colors.2, 100
				ControlGetPos,, yControl, wControl, hControl,, ahk_id %hwnd%
				If (index1 != 1) && !InStr(panel_text, "?")
					vars.hwnd.ocr_tooltip[key "_" panel_text] := hwnd, vars.hwnd.ocr_tooltip[key "_" panel_text "_text"] := hwnd0
			}

		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, wWin, hWin, ahk_id %hwnd_altars%
		xPos := vars.OCR.coords.xMouse - wWin / 2, yPos := vars.OCR.coords.yMouse - vars.OCR.coords.hPanel - square1
		xPos := (xPos < vars.client.x) ? vars.client.x : (xPos + wWin >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - wWin : xPos
		yPos := (yPos < vars.client.y) ? vars.client.y : (yPos + hWin >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - hWin : yPos
		Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
		LLK_Overlay(hwnd_altars, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy"), vars.OCR.last := "_altars"
	}
}

OCR_Close()
{
	local
	global vars, settings

	If !WinActive("ahk_id " vars.hwnd.poe_client)
	{
		WinActivate, % "ahk_id " vars.hwnd.poe_client
		WinWaitActive, % "ahk_id " vars.hwnd.poe_client
	}
	SendInput, % "{" settings.OCR.z_hotkey "}"
	LLK_Overlay(vars.hwnd.ocr_tooltip.main, "destroy"), vars.hwnd.ocr_tooltip.main := ""
}

OCR_Error(error)
{
	local
	global vars, settings

	Gui, ocr_tooltip: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_altars
	Gui, ocr_tooltip: Color, Black
	Gui, ocr_tooltip: Margin, 0, 0
	Gui, ocr_tooltip: Font, % "s" settings.OCR.fSize * 1.5 " cRed", % vars.system.font
	Gui, ocr_tooltip: Add, Text, % "Center Border", % " " error " "
	vars.hwnd.ocr_tooltip := {"main": hwnd_altars}

	Gui, ocr_tooltip: Show, NA x10000 y10000
	WinGetPos, xWin, yWin, wWin, hWin, % "ahk_id " hwnd_altars
	xPos := vars.OCR.coords.xMouse - wWin / 2, yPos := vars.OCR.coords.yMouse - hWin
	xPos := (xPos < vars.client.x) ? vars.client.x : (xPos + wWin >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - wWin : xPos
	yPos := (yPos < vars.client.y) ? vars.client.y : (yPos + hWin >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - hWin : yPos
	Gui, ocr_tooltip: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(hwnd_altars, "show",, "ocr_tooltip")
}

OCR_FilterInput(text) ;WIP, currently not in use
{
	local
	global vars, settings, db

	parsed := []
	Loop, Parse, text, `n, "`r`t" A_Space
	{
		loopfield_copy := ""
		Loop, Parse, A_LoopField
			If LLK_IsType(A_LoopField, "alnum")
				loopfield_copy .= A_LoopField
		loopfield_copy := InStr(loopfield_copy, ":") ? SubStr(loopfield_copy, 1, InStr(loopfield_copy, ":") - 1) : loopfield_copy
		If !InStr(loopfield_copy, ":") && !InStr(loopfield_copy, " ",,, 2)
			Continue
		parsed.Push(loopfield_copy)
	}

	lookup := {"altars": ["map boss gains:", "eldritch minions gain:", "player gains:"], "vaalareas": [Lang_Trans("items_mapquantity")]}
	dictionary := {"altars": ["map", "boss", "gains", "eldritch", "minions", "gain", "player"], "vaalareas": []}
	Loop, Parse, % Lang_Trans("items_mapquantity"), % A_Space, % ":"
		dictionary.vaalareas.Push(A_LoopField)
	For index, text in parsed
	{
		text := "mep boss gains:"
		If (SubStr(text, 0) != ":") || usecase || (usecase := LLK_HasVal(lookup, text,,,, 1))
			Continue
		Else
		{
			regex := "i)", results := 0, regex_array := StrSplit(text, A_Space, ":"), regex_array_copy := regex_array.Clone()
			For index, word in regex_array
				If !LLK_HasVal(dictionary, word,,,, 1)
					regex_array_copy[index] := 0
				Else regex .= (InStr(".*i)", SubStr(regex, -1)) ? "" : ".*") word

			For k, array in lookup
				results += (check := LLK_HasRegex(array, regex, 1).Count()) ? check : 0, usecase0 := check ? k : usecase0
			If (results = 1)
			{
				usecase := usecase0
				Break
			}
		}
	}
	MsgBox, % usecase
}

OCR_Highlight(hotkey)
{
	local
	global vars, settings

	If !vars.general.cMouse || Blank(LLK_HasVal(vars.hwnd.ocr_tooltip, vars.general.cMouse))
		Return

	hotkey0 := Hotkeys_RemoveModifiers(hotkey)
	hotkey := GetKeyName(hotkey0)
	hotkey := (hotkey = "space") ? 0 : hotkey
	cHWND := vars.general.cMouse, check := LLK_HasVal(vars.hwnd.ocr_tooltip, vars.general.cMouse), category := StrReplace(SubStr(check, 1, InStr(check, "_") - 1), ":")
	mod := (vars.hwnd.ocr_tooltip.type = "altars") ? SubStr(check, InStr(check, "_") + 1) : check, text_cHWND := vars.hwnd.ocr_tooltip[check "_text"]
	GuiControl, % "+c" settings.OCR.colors[hotkey].2, % cHWND
	GuiControl, movedraw, % cHWND
	GuiControl, % "+c" settings.OCR.colors[hotkey].1, % text_cHWND
	GuiControl, movedraw, % text_cHWND

	If vars.hwnd.ocr_tooltip.type
		IniWrite, % hotkey, % "ini\ocr - " vars.hwnd.ocr_tooltip.type ".ini", % "profile " settings.OCR.profile (vars.hwnd.ocr_tooltip.type = "altars" ? " " category : ""), % mod
	KeyWait, % hotkey0
}

OCR_RegexCheck(array, insert_index, insert_val, newline := 0) ;takes an array with blanks derived from an ambiguous regex match, inserts a new value into a chosen blank, and returns the new regex string
{
	local

	If !IsObject(array) || Blank(insert_index) || Blank(insert_val) && insert_index
		Return 0
	array[insert_index] := insert_val
	For index, val in array
		If !Blank(val)
			regex .= (!regex ? "i" (!newline ? "m" : "") ")" : ".*") val
	Return regex
}

OCR_VaalAreas()
{
	local
	global db, vars, settings
	static toggle := 0

	vars.OCR.toggle := toggle := !toggle, GUI_name := "ocr_tooltip" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_vaalareas
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s" settings.OCR.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.ocr_tooltip.main, vars.hwnd.ocr_tooltip := {"main": hwnd_vaalareas, "type": "vaal areas"}
	square1 := vars.client.h / 20, lines := {"player": [], "monsters": [], "boss": [], "area": [], "vessel": [], "z_unclear": []}
	text := SubStr(vars.OCR.text, InStr(vars.OCR.text, ":",, 0) + 1), text := SubStr(text, InStr(text, "`n") + 1)

	If !IsObject(db.vaalareas)
		DB_Load("OCR")

	Loop, Parse, text, `n, % " `r`t"
	{
		loopfield_copy := ""
		Loop, Parse, A_LoopField
			loopfield_copy .= LLK_IsType(A_LoopField, "alpha") ? A_LoopField : ""
		While InStr(loopfield_copy, "  ")
			loopfield_copy := StrReplace(loopfield_copy, "  ", " ")
		While (SubStr(loopfield_copy, 1, 1) = " ")
			loopfield_copy := SubStr(loopfield_copy, 2)
		While (SubStr(loopfield_copy, 0) = " ")
			loopfield_copy := SubStr(loopfield_copy, 1, -1)
		If !loopfield_copy || !InStr(loopfield_copy, " ",,, 2)
			Continue
		If !db.vaalareas.HasKey(loopfield_copy)
		{
			regex_array := StrSplit(loopfield_copy, A_Space), regex_array_copy := regex_array.Clone()
			For index, val in regex_array
				If !LLK_HasVal(db.vaalareas_dictionary, val)
					regex_array_copy[index] := ""
			For index, val in regex_array_copy
				If Blank(val)
				{
					regex := ""
					Loop, Parse, % regex_array[index]
					{
						check := LLK_HasRegex(db.vaalareas, OCR_RegexCheck(regex_array_copy, index, regex . A_LoopField), 1, 1)
						regex .= check.Count() ? A_LoopField : (SubStr(regex, -1) = ".*" ? "" : ".*")
						If (check.Count() = 1)
						{
							regex_array_copy[index] := regex
							Break 2
						}
					}
				}
			If ((check := LLK_HasRegex(db.vaalareas, OCR_RegexCheck(regex_array_copy, 0, ""), 1, 1)).Count() = 1) && !LLK_HasVal(lines[db.vaalareas[check.1].2], (line1 := db.vaalareas[check.1].1))
			{
				If InStr(line1, "corr. packs") && !extra_pack
				{
					extra_pack := 1
					Continue
				}
				lines[db.vaalareas[check.1].2].Push(db.vaalareas[check.1].1)
			}
			Else If (check.Count() > 1)
				For iCheck, vCheck in check
					lines.z_unclear.Push(db.vaalareas[vCheck].1 " (?)")
		}
		Else If db.vaalareas.HasKey(loopfield_copy) && !LLK_HasVal(lines[db.vaalareas[loopfield_copy].2], (line1 := db.vaalareas[loopfield_copy].1))
		{
			If InStr(line1, "corr. packs") && !extra_pack
			{
				extra_pack := 1
				Continue
			}
			lines[db.vaalareas[loopfield_copy].2].Push(db.vaalareas[loopfield_copy].1)
		}
	}

	categories := [], wPanels := 0
	For key, val in lines
	{
		If (key = "z_unclear")
			key := "unclear"
		categories.Push(Lang_Trans("ocr_vaal" key))
		If val.Count()
			LLK_PanelDimensions(val, settings.OCR.fSize, w%key%, h%key%), wPanels := (w%key% > wPanels) ? w%key% : wPanels
	}
	LLK_PanelDimensions(categories, settings.OCR.fSize, wCategories, hCategories), added := -1, ini := IniBatchRead("ini\ocr - vaal areas.ini")
	For key, val in lines
	{
		If !val.Count()
			Continue
		If (key = "z_unclear")
			key := "unclear"
		For index, line in val
		{
			rank := !Blank(check := ini["profile " settings.OCR.profile][StrReplace(line, "`n", ";")]) ? check : 0, colors := settings.OCR.colors[rank].Clone(), added += 1
			Gui, %GUI_name%: Add, Text, % "xs x" wCategories - 1 . (added = 0 ? "" : " y+-1") " Section Border BackgroundTrans HWNDhwnd c" colors.1 " w" wPanels, % " " StrReplace(StrReplace(line, "`n", "`n "), "&", "&&") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd1 c" colors.2, 100
			If (index = 1)
			{
				yPrev := yControl + hControl ? yControl + hControl : 0
				ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
			}
			(key != "unclear")
				line := StrReplace(line, "`n", ";"), vars.hwnd.ocr_tooltip[line] := hwnd1, vars.hwnd.ocr_tooltip[line "_text"] := hwnd
		}
		ControlGetPos, xControl1, yControl1, wControl1, hControl1,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Text, % "x0 y" yControl " w" wCategories " h" yControl1 + hControl1 - yControl " Border BackgroundTrans Right 0x200", % Lang_Trans("ocr_vaal" key) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Border", 0
	}
	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, wWin, hWin, ahk_id %hwnd_vaalareas%
	xPos := vars.OCR.coords.xMouse - wWin//2, yPos := vars.OCR.coords.yMouse - hWin
	xPos := (xPos < vars.client.x) ? vars.client.x : (xPos + wWin >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - wWin : xPos
	yPos := (yPos < vars.client.y) ? vars.client.y : (yPos + hWin >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - hWin : yPos
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(vars.hwnd.ocr_tooltip.main, "show",, GUI_name)
}
