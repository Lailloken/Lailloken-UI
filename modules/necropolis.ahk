Init_necropolis(mode := 0)
{
	local
	global vars, settings, db, Json

	If !FileExist("ini\necropolis.ini")
		IniWrite, % "", ini\necropolis.ini, settings

	If !IsObject(settings.OCR)
		settings.OCR := {}
	settings.OCR.allow := LLK_IniRead("ini\ocr.ini", "Settings", "allow ocr", 0) * (vars.client.h > 720 ? 1 : 0), ini := IniBatchRead("ini\necropolis.ini")

	If !IsObject(settings.necropolis)
		settings.necropolis := {"mods": {}, "profile": !Blank(check := ini.settings["profile"]) ? check : 1}

	settings.necropolis.debug := !Blank(check := ini.settings["debug"]) ? check : 0
	settings.necropolis.dColors := ["00FF00", "FF8000", "FF0000", "FF00FF", "00FFFF"], settings.necropolis.dColors.0 := "FFFFFF"
	settings.necropolis.colors := []
	settings.necropolis.opac := !Blank(check := ini.UI["opacity"]) ? check : 50

	For index, color in settings.necropolis.dColors
		If !Blank(check := ini.UI["color " index])
			settings.necropolis.colors[index] := check
		Else settings.necropolis.colors[index] := color

	For key, val in {"g": "Gap", "x": "Xpos", "y": "Ypos", "w": "Width", "h": "Height"}
		settings.necropolis["o" val] := !Blank(check := ini.UI[val " offset"]) ? check : 0

	settings.features.necropolis := LLK_IniRead("ini\config.ini", "features", "enable necropolis", 0) * settings.OCR.allow
	If !IsObject(db.necropolis)
	{
		db.necropolis := Json.Load(LLK_FileRead("data\english\necropolis.json")), db.necropolis.dictionary := []
		For index, mod in db.necropolis.mods
		{
			settings.necropolis.mods[mod] := !Blank(check := ini["profile " settings.necropolis.profile][mod]) ? check : 0
			Loop, Parse, mod, % A_Space
				If !LLK_HasVal(db.necropolis.dictionary, A_LoopField)
					db.necropolis.dictionary.Push(A_LoopField)
		}
	}
}

Necropolis_(mode := "")
{
	local
	global vars, settings, db
	static toggle := 0

	If !IsObject(vars.necropolis)
		vars.necropolis := {}
	necro := settings.necropolis, lantern := vars.imagesearch.necro_lantern.found.2 + vars.imagesearch.necro_lantern.found.4
	hBox := Round(vars.client.h * (4/45)) + necro.oHeight, wBox := Round(3.22 * hBox) + necro.oWidth, xUI := vars.imagesearch.necro_lantern.found.1 - hBox + necro.oXpos, yUI := lantern + hBox//2 + necro.oYpos
	toggle := !toggle, GUI_name := "necropolis" toggle, vars.necropolis.buttons := [], height := (vars.client.h//2 - yUI) * 2.2
	If (mode != "refresh")
		pBitmap0 := Gdip_CloneBitmapArea(vars.imagesearch.necro_lantern.pHaystack, xUI + settings.general.oGamescreen, yUI, wBox, height,, 1), Gdip_DisposeImage(vars.imagesearch.necro_lantern.pHaystack), vars.necropolis.texts := [], Gdip_GetImageDimensions(pBitmap0, wBitmap, hBitmap), pBitmap := Gdip_ResizeBitmap(pBitmap0, wBitmap * 2, hBitmap * 2, 1, 7, 1), Gdip_DisposeImage(pBitmap0)
	vars.necropolis.debug := debug := (settings.necropolis.debug && GetKeyState("RControl", "P"))
	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_necropolis" (debug ? " +Border" : "")
	Gui, %GUI_name%: Font, % "s" settings.general.fSize " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, % debug ? "Black" : "Purple"
	WinSet, TransColor, % "Purple" (debug ? "" : " " necro.opac)
	Gui, %GUI_name%: Margin, % debug ? settings.general.fWidth : 0, % debug ? settings.general.fWidth / 2 : 0
	hwnd_old := vars.hwnd.necropolis.main, vars.hwnd.necropolis := {"main": hwnd_necropolis, "GUI_name": GUI_name}, xLast := yLast := 0

	If debug
	{
		hbmBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap), Gdip_DisposeImage(pBitmap), pStream := HBitmapToRandomAccessStream(hbmBitmap), text := ocr(pStream), ObjRelease(pStream)
		Gui, %GUI_name%: Add, Pic, % "Section Border w" wBitmap " h-1", HBitmap:*%hbmBitmap%
		Gui, %GUI_name%: Add, Text, % "ys Section HWNDhwnd", % "client-res: " vars.client.w "x" vars.client.h " " LangTrans("omnikey_escape")
		Gui, %GUI_name%: Font, % "s" settings.general.fSize - 4
		Gui, %GUI_name%: Add, Edit, % "xs Section cBlack", % LLK_StringCase(text)
		Gui, %GUI_name%: Font, % "s" settings.general.fSize
		ControlFocus,, ahk_id %hwnd%
		DeleteObject(hbmBitmap)
	}
	Else
	{
		If (mode != "refresh")
		{
			Loop
			{
				If (yLast + hBox*2 - 1 + necro.oGap >= hBitmap*2)
				{
					vars.necropolis.x1_enter := vars.client.x + xUI, vars.necropolis.y1_enter := vars.client.y + yLast//2 + yUI
					vars.necropolis.x2_enter := vars.client.x + xUI + wBox, vars.necropolis.y2_enter := vars.client.y + yLast//2 + hBox + yUI
					;MsgBox, % vars.necropolis.x1_enter ", " vars.necropolis.y1_enter ", " vars.necropolis.x2_enter ", " vars.necropolis.y2_enter
					Break
				}
				pHaystack := Gdip_CloneBitmapArea(pBitmap, xLast, yLast, wBox * 2, hBox * 2,, 1), hHaystack := Gdip_CreateHBITMAPFromBitmap(pHaystack), Gdip_DisposeImage(pHaystack)
				pStream := HBitmapToRandomAccessStream(hHaystack), DeleteObject(hHaystack), text0 := ""
				text0 := ocr(pStream), ObjRelease(pStream), text := Necropolis_Parse(text0), vars.necropolis.texts.Push(text), yLast += hBox*2 - 1 + necro.oGap
			}
			Gdip_DisposeImage(pBitmap)
		}

		yLast := 0
		For index, mod in vars.necropolis.texts
		{
			color := mod ? settings.necropolis.colors[settings.necropolis.mods[mod]] : "Black"
			Gui, %GUI_name%: Add, Progress, % "Section xs " (A_Index = 1 ? "" : "y+" necro.oGap - 1) " BackgroundBlack Border HWNDhwnd h" hBox " w" wBox " c" color, 100
			ControlGetPos, xLast, yLast,,,, ahk_id %hwnd%
			handle := "", mod := Blank(mod) ? "blank" : mod
			While vars.hwnd.necropolis.HasKey(mod . handle)
				handle .= "|"
			vars.hwnd.necropolis[mod . handle] := hwnd, vars.necropolis.buttons.Push(hwnd)
		}
	}

	If debug
	{
		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos, x, y, w, h, ahk_id %hwnd_necropolis%
		Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + vars.client.xc - w/2 " y" vars.monitor.y + vars.client.yc - h/2
	}
	Else
	{
		Gui, %GUI_name%: Show, % "NA x" vars.client.x + xUI " y" vars.client.y + yUI
		WinGetPos, x, y, w, h, ahk_id %hwnd_necropolis%
		vars.necropolis.GUI := 1, vars.necropolis.x1 := x, vars.necropolis.x2 := x + w, vars.necropolis.y1 := y, vars.necropolis.y2 := y + h
	}
	LLK_Overlay(hwnd_necropolis, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

Necropolis_Click()
{
	local
	global vars, settings

	If vars.necropolis.debug
		Return
	MouseGetPos, xMouse, yMouse, wMouse, cMouse, 2
	If (wMouse != vars.hwnd.necropolis.main)
		Return
	button := LLK_HasVal(vars.necropolis.buttons, cMouse), text := vars.necropolis.texts[button], hwnd := LLK_HasVal(vars.hwnd.necropolis, cMouse)
	Sleep, 100
	If GetKeyState("LButton", "P")
	{
		Gui, % vars.hwnd.necropolis.GUI_name ": +E0x20"
		SendInput, {LButton Down}
		KeyWait, LButton
		SendInput, {LButton Up}
		Gui, % vars.hwnd.necropolis.GUI_name ": -E0x20"
	}
	Else Return
	Sleep, 50
	MouseGetPos, xMouse, yMouse, wMouse, cMouse1, 2
	button1 := LLK_HasVal(vars.necropolis.buttons, cMouse1), hwnd1 := LLK_HasVal(vars.hwnd.necropolis, cMouse1)
	If !Blank(text) && button && button1 && (button != button1)
	{
		copy := vars.necropolis.texts[button], vars.necropolis.texts[button] := vars.necropolis.texts[button1], vars.necropolis.texts[button1] := copy
		copy := vars.hwnd.necropolis[hwnd], vars.hwnd.necropolis[hwnd] := vars.hwnd.necropolis[hwnd1], vars.hwnd.necropolis[hwnd1] := copy
		color := settings.necropolis.colors[settings.necropolis.mods[vars.necropolis.texts[button]]], color1 := settings.necropolis.colors[settings.necropolis.mods[vars.necropolis.texts[button1]]]
		GuiControl, % "+c" (!color ? "Black" : color), % cMouse
		GuiControl, % "+c" (!color1 ? "Black" : color1), % cMouse1
	}
}

Necropolis_Close()
{
	local
	global vars, settings

	vars.necropolis.GUI := vars.necropolis.debug := 0, LLK_Overlay(vars.hwnd.necropolis.main, "destroy")
}

Necropolis_Highlight(cHWND, hotkey)
{
	local
	global vars, settings

	Loop 5
		If InStr(hotkey, A_Index)
			hotkey := A_Index
	hotkey := IsNumber(hotkey) ? hotkey : 0

	button := LLK_HasVal(vars.necropolis.buttons, cHWND), text := vars.necropolis.texts[button]
	check := LLK_HasVal(vars.hwnd.necropolis, cHWND), control := StrReplace(check, "|")
	If !check || !text
		Return
	settings.necropolis.mods[control] := hotkey
	IniWrite, % hotkey, ini\necropolis.ini, % "profile " settings.necropolis.profile, % control
	GuiControl, % "+c" settings.necropolis.colors[hotkey], % cHWND
}

Necropolis_Parse(text)
{
	local
	global vars, settings, db

	Loop, Parse, % LLK_StringCase(text), `n, % "`r`t" A_Space
		text := (A_Index = 1) ? "" : text, text .= Blank(A_LoopField) || (StrLen(A_LoopField) < 3) ? "" : (!text ? "" : " ") A_LoopField
	Loop, Parse, text
		text := (A_Index = 1) || (A_LoopField = ":") ? "" : text, text .= LLK_IsType(A_LoopField, "alpha") ? A_LoopField : ""
	;If InStr(text, ":")
	;	text := SubStr(text, InStr(text, ":") + 1)
	While InStr(text, "  ")
		text := StrReplace(text, "  ", " ")
	While (SubStr(text, 1, 1) = " ")
		text := SubStr(text, 2)
	While (SubStr(text, 0) = " ")
		text := SubStr(text, 1, -1)

	If LLK_HasVal(db.necropolis.mods, text)
		Return text
	Else
	{
		regex_array := StrSplit(text, A_Space), regex_array_copy := regex_array.Clone()
		For index, word in regex_array
			If !LLK_HasVal(db.necropolis.dictionary, word)
				regex_array_copy[index] := ""
		regex_check := LLK_HasRegex(db.necropolis.mods, OCR_RegexCheck(regex_array_copy, 0, ""), 1)
		regex_check1 := LLK_HasRegex(db.necropolis.mods, StrReplace((OCR_RegexCheck(regex_array_copy, 0, "")), "im)", "i)^") "$", 1)
		If (regex_check.Count() = 1 || regex_check1.Count() = 1)
			Return db.necropolis.mods[regex_check.1]
		Else If !regex_check.Count()
			Return
		mod_lookup := []
		For index, mod_index in regex_check
			mod_lookup.Push(db.necropolis.mods[mod_index])
		For index, word in regex_array_copy
		{
			If Blank(word)
			{
				regex := ""
				Loop, Parse, % regex_array[index]
				{
					If (regex_check := LLK_HasRegex(mod_lookup, OCR_RegexCheck(regex_array_copy, index, regex . A_LoopField), 1))
						regex .= A_LoopField
					Else regex .= (SubStr(regex, -1) = ".*") ? "" : ".*"

					If (regex_check.Count() = 1)
						Return mod_lookup[regex_check.1]
				}
				If (regex != ".*")
					regex_array_copy[index] := regex
			}
		}
		regex_check := LLK_HasRegex(mod_lookup, OCR_RegexCheck(regex_array_copy, 0, "") "$", 1)
		If (regex_check.Count() = 1)
			Return mod_lookup[regex_check.1]
	}
}
