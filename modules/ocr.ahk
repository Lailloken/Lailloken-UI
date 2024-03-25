Init_OCR()
{
	local
	global vars, settings

	settings.OCR := {"profile": 1} ;in case profiles are desired in the future
	settings.OCR.allow := LLK_IniRead("ini\ocr.ini", "Settings", "allow ocr", 0) * (vars.client.h > 720 ? 1 : 0)
	settings.OCR.hotkey := LLK_IniRead("ini\ocr.ini", "Settings", "hotkey")
	settings.OCR.hotkey_single := settings.OCR.hotkey
	If (StrLen(settings.OCR.hotkey) > 1)
		Loop, Parse, % "+!^#"
			settings.OCR.hotkey_single := StrReplace(settings.OCR.hotkey_single, A_LoopField)
	If !GetKeyVK(settings.OCR.hotkey_single)
		settings.OCR.hotkey_single := ""
	settings.OCR.hotkey_block := LLK_IniRead("ini\ocr.ini", "Settings", "block native key-function", 0)
	settings.OCR.z_hotkey := LLK_IniRead("ini\ocr.ini", "Settings", "toggle highlighting hotkey", "z")
	settings.OCR.debug := LLK_IniRead("ini\ocr.ini", "Settings", "enable debug", 0)
	settings.OCR.fSize := LLK_IniRead("ini\ocr.ini", "Settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.OCR.fSize, font_height, font_width)
	settings.OCR.fHeight := font_height, settings.OCR.fWidth := font_width
	settings.OCR.dColors := [["00FF00", "00000"], ["FF8000", "00000"], ["FF0000", "00000"], ["FF00FF", "00000"], ["FF0000", "FFFFFF"]], settings.OCR.dColors.0 := ["FFFFFF", "000000"]
	settings.OCR.colors := []
	For index, color in settings.OCR.dColors
		If (iniread := LLK_IniRead("ini\ocr.ini", "UI", "pattern " index))
			settings.OCR.colors[index] := StrSplit(iniread, ",")
		Else settings.OCR.colors[index] := color.Clone()

	settings.features.OCR := LLK_IniRead("ini\config.ini", "Features", "enable ocr", 0) * settings.OCR.allow
	If settings.features.OCR && !Blank(settings.OCR.hotkey)
	{
		Hotkey, IfWinActive, ahk_group poe_ahk_window
		Hotkey, % "*" (settings.OCR.hotkey_block ? "" : "~") . settings.OCR.hotkey, OCR_
	}
}

OCR_(mode := "GUI")
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
		Clipboard := ""
		SendInput, #+{s}
		WinWaitActive, ahk_group snipping_tools,, 2
		WinWaitActive, ahk_group poe_ahk_window
		pBitmap := Gdip_CreateBitmapFromClipboard()
		If (pBitmap < 0)
		{
			LLK_ToolTip(LangTrans("global_screencap") "`n" LangTrans("global_fail"),,,,, "red")
			vars.OCR.in_progress := 0
			Return
		}
		Gdip_GetImageDimensions(pBitmap, w, h)
		If (w >= vars.client.w || h >= vars.client.h)
		{
			LLK_ToolTip(LangTrans("m_ocr_error", 2), 2, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "red", settings.general.fSize * 2,,, 1)
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
				vars.OCR.GUI := 0
				Gui, ocr_GUI: Destroy
				While WinExist("ahk_id " ocr_GUI)
					Sleep 100
				pBitmap := Gdip_BitmapFromScreen(xWin "|" yWin "|" wGUI * 2 "|" hGUI * 2)
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
	text := ocr(pIRandomAccessStream), ObjRelease(pIRandomAccessStream)

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

		Gui, compat_test: Add, Pic, % "Section Border w" width " h-1", HBitmap:*%hBitmap%
		If debug
		{
			vars.OCR.debug := 1
			Gui, compat_test: Font, % "s" settings.general.fSize - 4
			Gui, compat_test: Add, Edit, % "ys Section cBlack", % !Blank(text) ? LLK_StringCase(text) : LangTrans("ocr_notext")
			Gui, compat_test: Font, % "s" settings.general.fSize
			Gui, compat_test: Add, Text, % "xs HWNDhwnd", % "client-res: " vars.client.w "x" vars.client.h " " LangTrans("omnikey_escape")
			ControlFocus,, ahk_id %hwnd%
		}
		Else
		{
			Gui, compat_test: Add, Text, % "xs wp", % LangTrans("m_ocr_compatibility", 2)
			Gui, compat_test: Add, Edit, % "xs wp cBlack wp HWNDhwnd0 gSettings_OCR2",
			Gui, compat_test: Add, Text, % "xs wp HWNDhwnd1 cLime", % ""
			If (vars.system.click = 2)
				Gui, compat_test: Add, Text, % "ys Border", % LLK_StringCase(text) "`nclient-res: " vars.client.w "x" vars.client.h
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
		OCR_Error(LangTrans("ocr_notext"))
		Return
	}
	Else If (mode = "compat") && (vars.OCR.text_check.Count() < 8)
	{
		LLK_ToolTip(LangTrans("m_ocr_error"), 2.5,,,, "red")
		Return
	}
	Else If (mode = "compat") || debug
		Return text
	Else
	{
		vars.OCR.text := text
		If InStr(text, ":",,, 2)
			OCR_Altars()
		;Else If InStr(text, " essence of ")
		;	OCR_Essences()
		Else OCR_Error(LangTrans("ocr_nousecase"))
	}
}

OCR_Altars()
{
	local
	global db, vars, settings, json
	static toggle := 0

	vars.OCR.toggle := toggle := !toggle, GUI_name := "ocr_tooltip" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_altars
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s" settings.OCR.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.ocr_tooltip.main, vars.hwnd.ocr_tooltip := {"main": hwnd_altars}, panels := [[], []], header := 0, parsed_text := [[], []], header_check := ["boss", "minions", "player"]
	header_dictionary := ["map", "boss", "gains", "eldritch", "minions", "gain", "player"], header_lookup := ["map boss gains:", "eldritch minions gain:", "player gains:"]
	text := vars.OCR.text, square1 := vars.client.h / 20

	Loop, Parse, % LLK_StringCase(text), `n, % "`r`t" A_Space
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

		If InStr(A_LoopField, ":")
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
		;Msgbox, % regex ", " key
	}

	skip := extra := 0
	For index0, array in parsed_text
		For index, line in array
		{
			If (index = 1)
			{
				key := StrReplace(line, ":"), panels[index0].Push(line), mod_lookup := db.altars[key "_check"]
				Continue
			}
			If skip || (LLK_InStrCount(line, " ") < 2)
			{
				skip -= 1
				Continue
			}
			check := "", line2 := parsed_text[index0][index + 1]
			For iKey, vKey in mod_lookup
				If !check && (InStr(vKey, line "`r`n" line2) || vKey = line)
					check := iKey, skip += (vKey = line) ? 0 : LLK_InStrCount(vKey, "`n") - extra
			If check
			{
				If !LLK_HasVal(panels[index0], db.altars[key][check].2)
					panels[index0].Push(db.altars[key][check].2)
				Continue
			}

			regex := extra ? regex ".*\r\n.*" : "", regex1 := ""
			Loop 2
			{
				tag := (A_Index = 1) ? 1 : ""
				regex_array%tag% := StrSplit(tag ? line2 : line, A_Space), regex_array%tag%_copy := regex_array%tag%.Clone()
				For iRegex, vRegex in regex_array%tag%
				{
					If !LLK_HasVal(db.altar_dictionary, vRegex)
						regex_array%tag%_copy[iRegex] := ""
					Else regex%tag% := !regex%tag% ? (tag ? "" : !extra ? "i)" : "") vRegex : regex%tag% ".*" vRegex
				}
			}

			If (LLK_HasRegex(mod_lookup, regex, 1).Count() = 1)
				regex_all := regex
			Else If LLK_HasRegex(mod_lookup, regex ".*\r\n.*" regex1)
			{
				regex_all := regex, extra += 1
				Continue
			}
			Else
			{
				Loop 2
				{
					tag := (A_Index = 1) ? 1 : ""
					For iRegex, vRegex in regex_array%tag%_copy
					{
						If Blank(vRegex)
						{
							blank_regex%tag% := ""
							Loop, Parse, % regex_array%tag%[iRegex]
							{
								If LLK_HasRegex(mod_lookup, OCR_RegexCheck(regex_array%tag%_copy, iRegex, blank_regex%tag% . A_LoopField, extra), 1)
									blank_regex%tag% .= A_LoopField
								Else blank_regex%tag% .= (SubStr(blank_regex%tag%, -1) = ".*") ? "" : ".*"
							}
							regex_array%tag%_copy[iRegex] := (blank_regex%tag% = ".*") ? "" : blank_regex%tag%
						}
					}
				}

				regex_all := extra ? regex_all ".*\r\n.*" : "", regex_all1 := ""
				Loop 2
				{
					tag := (A_Index = 1) ? 1 : ""
					For iRegex, vRegex in regex_array%tag%_copy
						If vRegex
							regex_all%tag% .= (!regex_all%tag% ? !tag && !extra ? "i)" : "" : ".*") vRegex
				}

				If LLK_HasRegex(mod_lookup, regex_all ".*\r\n.*" regex_all1)
				{
					extra += 1
					Continue
				}
			}
			regex_result := LLK_HasRegex(mod_lookup, regex_all, 1)
			For iRegex, vRegex in regex_result
			{
				If !LLK_HasVal(panels[index0], db.altars[key][vRegex].2)
					panels[index0].Push(db.altars[key][vRegex].2 . (regex_result.Count() > 1 ? " (?)" : ""))
				skip += (regex_result.Count() = 1) ? LLK_InStrCount(db.altars[key][vRegex].1, "`n") - extra : 0
			}
			extra := 0
		}

	If (panels.1.Count() < 3) || (panels.2.Count() < 3) || !LLK_HasVal(panels, ":", 1,,, 1)
		OCR_Error(LangTrans("ocr_erroraltar"))
	Else
	{
		LLK_PanelDimensions(panels.1, settings.OCR.fSize, w1, h1), LLK_PanelDimensions(panels.2, settings.OCR.fSize, w2, h2)
		width := Max(w1, w2)
		For index, array in panels
			For index1, panel_text in array
			{
				If (index = 2 && index1 = 1)
					vars.OCR.coords.hPanel := yControl + hControl
				If (index1 = 1)
					key := StrReplace(panel_text, ":")
				rank := LLK_IniRead("ini\altars.ini", "profile " settings.OCR.profile " " key, panel_text, 0)
				colors := (index1 = 1) ? ["FFFFFF", "000000"] : settings.OCR.colors[rank].Clone()
				Gui, %GUI_name%: Add, Text, % (index = 2 && index1 = 1 ? "y+" vars.client.h / 10 : (index = 1 && index1 = 1) ? "" : "y+-1") " xs Section Center Border BackgroundTrans HWNDhwnd0 w" width " c" colors.1, % StrReplace(panel_text, "&", "&&")
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border HWNDhwnd BackgroundBlack c" colors.2, 100
				ControlGetPos,, yControl, wControl, hControl,, ahk_id %hwnd%
				If (index1 != 1)
					vars.hwnd.ocr_tooltip[key "_" panel_text] := hwnd, vars.hwnd.ocr_tooltip[key "_" panel_text "_text"] := hwnd0
			}

		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, wWin, hWin, ahk_id %hwnd_altars%
		xPos := vars.OCR.coords.xMouse - wWin / 2, yPos := vars.OCR.coords.yMouse - vars.OCR.coords.hPanel - square1
		xPos := (xPos < vars.client.x) ? vars.client.x : (xPos + wWin >= vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - wWin : xPos
		yPos := (yPos < vars.client.y) ? vars.client.y : (yPos + hWin >= vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - hWin : yPos
		Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
		LLK_Overlay(hwnd_altars, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy"), vars.OCR.last := "altars"
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

OCR_Highlight(hotkey)
{
	local
	global vars, settings

	Loop, Parse, hotkey
		hotkey := (A_Index = 1) ? "" : hotkey, hotkey .= LLK_IsType(A_LoopField, "alnum") ? A_LoopField : ""
	If (hotkey = "Space")
		hotkey := 0
	If !vars.general.cMouse || Blank(LLK_HasVal(vars.hwnd.ocr_tooltip, vars.general.cMouse))
		Return

	cHWND := vars.general.cMouse, check := LLK_HasVal(vars.hwnd.ocr_tooltip, vars.general.cMouse), category := StrReplace(SubStr(check, 1, InStr(check, "_") - 1), ":"), mod := SubStr(check, InStr(check, "_") + 1)
	text_cHWND := vars.hwnd.ocr_tooltip[check "_text"]
	GuiControl, % "+c" settings.OCR.colors[hotkey].2, % cHWND
	GuiControl, movedraw, % cHWND
	GuiControl, % "+c" settings.OCR.colors[hotkey].1, % text_cHWND
	GuiControl, movedraw, % text_cHWND

	IniWrite, % hotkey, ini\altars.ini, % "profile " settings.OCR.profile " " category, % mod
}

OCR_RegexCheck(array, insert_index, insert_val, newline := 0) ;takes an array with blanks derived from an ambiguous regex match, inserts a new value into a chosen blank, and returns the new regex string
{
	local

	If !IsObject(array) || Blank(insert_index) || Blank(insert_val)
		Return 0
	array[insert_index] := insert_val
	For index, val in array
		If !Blank(val)
			regex .= (!regex ? "i" (!newline ? "m" : "") ")" : ".*") val
	Return regex
}
