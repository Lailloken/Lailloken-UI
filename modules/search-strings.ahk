Init_searchstrings()
{
	local
	global vars, settings

	If !vars.poe_version && !FileExist("ini\search-strings.ini")
	{
		IniWrite, 1, ini\search-strings.ini, searches, beast crafting
		IniWrite, % "", ini\search-strings.ini, beast crafting, last coordinates
		IniWrite, "warding", ini\search-strings.ini, beast crafting, 00-flasks: curse
		IniWrite, "sealing|lizard", ini\search-strings.ini, beast crafting, 00-flasks: bleed
		IniWrite, "earthing|conger", ini\search-strings.ini, beast crafting, 00-flasks: shock
		IniWrite, "convection|deer", ini\search-strings.ini, beast crafting, 00-flasks: freeze
		IniWrite, "damping|urchin", ini\search-strings.ini, beast crafting, 00-flasks: ignite
		IniWrite, "antitoxin|skunk", ini\search-strings.ini, beast crafting, 00-flasks: poison
	}
	Else If vars.poe_version && !FileExist("ini 2\search-strings.ini")
		IniWrite, % "", ini 2\search-strings.ini, searches

	If !IsObject(vars.searchstrings)
		vars.searchstrings := {}
	vars.searchstrings.list := {}, vars.searchstrings.enabled := 0, ini := IniBatchRead("ini" vars.poe_version "\search-strings.ini")
	For key, val in ini.searches
	{
		If (settings.general.lang_client != "english" && !vars.client.stream && key = "beast crafting")
			Continue
		vars.searchstrings.list[key] := {"enable": val}
		If val
			vars.searchstrings.enabled += 1
	}

	For key in vars.searchstrings.list
	{
		Loop, Parse, % ini[key]["last coordinates"], `,
		{
			If (A_Index = 1)
				vars.searchstrings.list[key].x1 := A_LoopField
			Else if (A_Index = 2)
				vars.searchstrings.list[key].y1 := A_LoopField
			Else if (A_Index = 3)
				vars.searchstrings.list[key].x2 := A_LoopField + vars.searchstrings.list[key].x1
			Else vars.searchstrings.list[key].y2 := A_LoopField + vars.searchstrings.list[key].y1
		}

		For inikey, inival in ini[key]
		{
			If InStr(inikey, "last coordinates")
				Continue
			If !IsObject(vars.searchstrings.list[key].strings)
				vars.searchstrings.list[key].strings := {}
			vars.searchstrings.list[key].strings[inikey] := []
			Loop, Parse, % StrReplace(inival, " `;`;`; ", "`n"), `n
			{
				If Blank(A_LoopField)
					Continue
				vars.searchstrings.list[key].strings[inikey].Push(A_LoopField)
			}
			vars.searchstrings.list[key].strings[inikey].0 := StrReplace(inival, " `;`;`; ", "`n")
		}
	}
}

String_ContextMenu(name := "")
{
	local
	global vars, settings

	strings := vars.searchstrings.list[name].strings ;short-cut
	If (name = "exile-leveling")
		vars.searchstrings.active := ["exile-leveling", "vendor"], string := "vendor"

	If (A_Gui = "searchstrings_context") || (name = "exile-leveling") || (strings.Count() = 1)
	{
		KeyWait, LButton
		If (name = "exile-leveling")
			Clipboard := vars.leveltracker.string.1
		Else If (strings.Count() = 1)
			For key in strings
				string := key, vars.searchstrings.active := [name, key]
		Else If (name != "exile-leveling")
			name := vars.searchstrings.active.1, string := vars.searchstrings.list[name].strings.HasKey("00-"A_GuiControl) ? "00-"A_GuiControl : A_GuiControl, vars.searchstrings.active.2 := string
		Gui, searchstrings_context: Destroy
		vars.hwnd.Delete("searchstrings_context")
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		If (name != "exile-leveling")
			vars.searchstrings.clipboard := vars.searchstrings.list[name].strings[string].1, Clipboard := StrReplace(vars.searchstrings.list[name].strings[string].1, ";")
		SendInput, ^{f}
		Sleep, 100
		SendInput, ^{v}{Enter}

		If (name != "exile-leveling") && (vars.searchstrings.list[name].strings[string].2 = "") && !InStr(vars.searchstrings.list[name].strings[string].1, ";") || (name = "exile-leveling" && Blank(vars.leveltracker.string.2))
			Return
		If (name != "exile-leveling") && (vars.searchstrings.list[name].strings[string].Length() > 1)
			vars.searchstrings.active.3 := 1, vars.searchstrings.active.4 := vars.searchstrings.list[name].strings[string].Length()
		Else If (name = "exile-leveling") && !Blank(vars.leveltracker.string.2)
			vars.searchstrings.active := ["exile-leveling", "vendor", 1, vars.leveltracker.string.Count()]
		ToolTip_Mouse("searchstring")
		Return
	}

	If !vars.searchstrings.list[name].strings.Count()
	{
		LLK_ToolTip(Lang_Trans("cheat_entrynotext", 1, [name]), 1.5,,,, "yellow")
		Return
	}
	Gui, searchstrings_context: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
	Gui, searchstrings_context: Margin, % settings.general.fWidth, % settings.general.fHeight/3
	Gui, searchstrings_context: Color, Black
	Gui, searchstrings_context: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
	vars.hwnd.searchstrings_context := hwnd, vars.searchstrings.active := [name]

	For key, val in strings
		Gui, searchstrings_context: Add, Text, % "y+"settings.general.fHeight/3 (Blank(val.0) ? " cGray" : " gString_ContextMenu"), % StrReplace(key, "00-")
	Gui, searchstrings_context: Show, % "NA x"vars.general.xMouse " y"vars.general.yMouse
}

String_Menu(name)
{
	local
	global vars, settings
	static toggle := 0

	LLK_Overlay(vars.hwnd.settings.main, "hide")
	If WinExist("ahk_id "vars.hwnd.searchstrings_menu.main)
		WinGetPos, x, y,,, % "ahk_id "vars.hwnd.searchstrings_menu.main
	If !IsObject(vars.searchstrings.menu)
		vars.searchstrings.menu := {}
	vars.searchstrings.menu.active := [name, vars.searchstrings.menu.active.2], active := vars.searchstrings.menu.active
	toggle := !toggle, GUI_name := "searchstrings_menu" toggle
	Gui, %GUI_name%: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDsearchstrings_menu, Lailloken UI: search-string configuration
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/4
	Gui, %GUI_name%: Font, % "s"settings.general.fSize - 2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.searchstrings_menu.main, vars.hwnd.searchstrings_menu := {"main": searchstrings_menu}

	Gui, %GUI_name%: Add, Text, % "x-1 y-1 Section Border Center gString_Menu2 HWNDhwnd", % Lang_Trans("search_header") " " name
	vars.hwnd.searchstrings_menu.winbar := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+-1 Border gString_MenuClose Center HWNDhwnd w"settings.general.fWidth*2, % "x"
	vars.hwnd.searchstrings_menu.winx := hwnd

	Gui, %GUI_name%: Font, % "bold underline s"settings.general.fSize
	Gui, %GUI_name%: Add, Text, % "Section xs HWNDhwnd x"settings.general.fWidth/2, % Lang_Trans("global_newentry")
	WinGetPos,, yPos,,, ahk_id %hwnd%
	Gui, %GUI_name%: Font, % "norm s"settings.general.fSize - 2
	Gui, %GUI_name%: Add, Picture, % "ys BackgroundTrans hp w-1 HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI_name%: Add, Edit, % "xs w"settings.general.fWidth*15 " cBlack HWNDhwnd",
	vars.hwnd.help_tooltips["searchstrings_config entry-about"] := hwnd0, vars.hwnd.searchstrings_menu.name := hwnd
	WinGetPos, xPos,, width,, ahk_id %hwnd%
	xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max

	For key, value in vars.searchstrings.list[name].strings
	{
		If InStr(key, "00-")
			Continue
		If !header
		{
			Gui, %GUI_name%: Font, % "bold underline s"settings.general.fSize
			Gui, %GUI_name%: Add, Text, % "Section xs y+"settings.general.fHeight*0.8 " Center BackgroundTrans", % Lang_Trans("global_savedentry")
			Gui, %GUI_name%: Font, norm
			Gui, %GUI_name%: Add, Picture, % "ys BackgroundTrans hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
			WinGetPos, xPos,, width, height, ahk_id %hwnd%
			vars.hwnd.help_tooltips["searchstrings_config entry-list"] := hwnd, xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max, added := 0, header := 1
		}

		If !vars.searchstrings.menu.active.2
			vars.searchstrings.menu.active.2 := key
		style := !added ? "y+0" : "y+"settings.general.fHeight/6, added += 1
		Gui, %GUI_name%: Add, Text, % "Section xs Border "style " Center BackgroundTrans", % " " Lang_Trans("global_delete", 2) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp range0-500 Disabled BackgroundBlack cRed HWNDhwnd",
		vars.hwnd.searchstrings_menu["delbar_"key] := hwnd
		Gui, %GUI_name%: Add, Text, % "xp yp wp hp gString_Menu2 HWNDhwnd", % ""
		vars.hwnd.searchstrings_menu["del_"key] := hwnd
		cEntry := Blank(value.1) ? " cGray" : " cWhite", cEntry := (key = vars.searchstrings.menu.active.2) ? " cFuchsia" : cEntry
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/2 cEntry " HWNDhwnd gString_Menu2", % key
		vars.hwnd.searchstrings_menu["select_"key] := hwnd
		WinGetPos, xPos,, width,, ahk_id %hwnd%
		xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max
	}

	;Gui, %GUI_name%: Font, % "s"settings.general.fSize
	Gui, %GUI_name%: Add, Button, hidden x0 y0 default gString_Menu2 HWNDhwnd, ok
	vars.hwnd.searchstrings_menu.add := hwnd
	style := (Blank(active.2) ? "ReadOnly " : "cBlack ") " w"settings.general.fWidth*40
	Gui, %GUI_name%: Add, Edit, % "x"xPos_max + settings.general.fWidth " y"yPos " r12 Border HWNDhwnd "style, % Blank(active.2) ? "" : vars.searchstrings.list[active.1].strings[active.2].0
	vars.hwnd.searchstrings_menu.edit := hwnd
	Gui, %GUI_name%: Show, % "x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.searchstrings_menu.main
	ControlMove,,,, w + 1 - settings.general.fWidth*2,, % "ahk_id "vars.hwnd.searchstrings_menu.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.searchstrings_menu.winx
	Sleep, 50
	If !Blank(x)
		x := (x + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : x, y := (y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : y
	Gui, %GUI_name%: Show, % Blank(x) ? "x"vars.client.x " y" vars.monitor.y +vars.client.yc - h//2 : "x"x " y"y
	LLK_Overlay(searchstrings_menu, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

String_Menu2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.searchstrings_menu, cHWND), control := SubStr(check, InStr(check, "_") + 1), active := vars.searchstrings.menu.active
	String_MenuSave()
	If InStr(check, "del_")
	{
		If LLK_Progress(vars.hwnd.searchstrings_menu["delbar_"control], "LButton")
		{
			IniDelete, % "ini" vars.poe_version "\search-strings.ini", % active.1, % control
			Init_searchstrings()
			If (active.2 = control)
				active.2 := ""
		}
		Else Return
	}
	Else If InStr(check, "select_")
		active.2 := control
	Else If (check = "add")
	{
		name := LLK_ControlGet(vars.hwnd.searchstrings_menu.name)
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.searchstrings_menu.name
		While (SubStr(name, 1, 1) = " ")
			name := SubStr(name, 2)
		While (SubStr(name, 0) = " ")
			name := SubStr(name, 1, -1)
		If (name = "last coordinates")
			error := ["invalid name", 1]
		If vars.searchstrings.list[active.1].strings.HasKey(name)
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
		IniWrite, % "", % "ini" vars.poe_version "\search-strings.ini", % active.1, % name
		active.2 := name
		Init_searchstrings()
	}
	Else If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos, xWin, yWin, wWin, hWin, % "ahk_id "vars.hwnd.searchstrings_menu.main
		MouseGetPos, xMouse, yMouse
		While GetKeyState("LButton", "P")
		{
			If (A_TickCount >= start + 100)
				LLK_Drag(wWin, hWin, xPos, yPos, 1, A_Gui,, xMouse - xWin, yMouse - yWin)
			Sleep 1
		}
		vars.general.drag := 0
		Return
	}

	If InStr(check, "del_") || InStr(check, "select_") || (check = "add")
		String_Menu(vars.searchstrings.menu.active.1)
}

String_MenuClose()
{
	local
	global vars, settings

	String_MenuSave()
	WinActivate, ahk_group poe_window
	LLK_Overlay(vars.hwnd.settings.main, "show"), vars.searchstrings.menu.active.2 := ""
	Gui, % Gui_Name(vars.hwnd.searchstrings_menu.main) ": Destroy"
}

String_MenuSave()
{
	local
	global vars, settings

	active := vars.searchstrings.menu.active, edit := LLK_ControlGet(vars.hwnd.searchstrings_menu.edit)
	If Blank(active.2) || !WinExist("ahk_id "vars.hwnd.searchstrings_menu.main)
		Return
	While (SubStr(edit, 1, 1) = " ") || (SubStr(edit, 1, 1) = "`n")
		edit := SubStr(edit, 2)
	While (SubStr(edit, 0) = " ") || (SubStr(edit, 0) = "`n")
		edit := SubStr(edit, 1, -1)
	If (edit != vars.searchstrings.list[active.1].strings[active.2].0)
	{
		IniWrite, % """" StrReplace(edit, "`n", " `;`;`; ") """", % "ini" vars.poe_version "\search-strings.ini", % active.1, % active.2
		Init_searchstrings()
	}
}

String_Scroll(hotkey)
{
	local
	global vars, settings

	If (A_TickCount < vars.searchstrings.scroll + 300)
		Return

	active := vars.searchstrings.active, clip := vars.searchstrings.clipboard, vars.searchstrings.scroll := A_TickCount
	If InStr(hotkey, "WheelUp")
	{
		If InStr(clip, ";")
			index := SubStr(clip, InStr(clip, ";") + 1), index := SubStr(index, 1, InStr(index, ";") - 1), original := ";"index ";", index += 1 ;isolate scroll-index and increase by 1
		Else If (active.3 > 1)
			active.3 -= 1
		Else Return
	}
	Else If InStr(hotkey, "WheelDown")
	{
		If InStr(clip, ";")
			index := SubStr(clip, InStr(clip, ";") + 1), index := SubStr(index, 1, InStr(index, ";") - 1), original := ";"index ";", index -= 1 ;isolate scroll-index and increase by 1
		Else If (active.3 < active.4)
			active.3 += 1
		Else Return
	}
	Else
	{
		SetTimer, ToolTip_Mouse, Delete
		Gui, tooltip_mouse: Destroy
		vars.Delete("tooltip_mouse"), vars.searchstrings.Delete("active"), vars.hwnd.Delete("tooltip_mouse")
		ToolTip_Mouse("reset")
		Return
	}

	If !InStr(clip, ";")
		GuiControl, text, % vars.hwnd.tooltip_mouse.text, % Lang_Trans("omnikey_scroll") " " vars.searchstrings.active.3 "/" vars.searchstrings.active.4 "`n" Lang_Trans("omnikey_escape")
	If index
		vars.searchstrings.clipboard := StrReplace(vars.searchstrings.clipboard, original, ";"index ";"), Clipboard := StrReplace(vars.searchstrings.clipboard, ";")
	Else Clipboard := (active.1 = "exile-leveling") ? vars.leveltracker.string[active.3] : vars.searchstrings.list[active.1].strings[active.2][active.3]
	SendInput, ^{f}
	Sleep, 100
	SendInput, ^{v}{Enter}
}

String_Search(name)
{
	local
	global vars, settings

	var := vars.searchstrings.list[name]
	If !FileExist("img\Recognition ("vars.client.h "p)\GUI\[search-strings" vars.poe_version "] "name ".bmp") ;return 0 if reference img-file is missing
	{
		If InStr(A_Gui, "settings_menu")
			LLK_ToolTip(Lang_Trans("global_calibrate", 2),,,,, "yellow")
		Return 0
	}

	If !var.x1 && !InStr(A_Gui, "settings_menu") ;return 0 if search doesn't have coordinates or strings
		Return 0

	pHaystack_searchstrings := InStr(A_Gui, "settings_menu") ? Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1) : vars.searchstrings.pHaystack
	If InStr(A_Gui, "settings_menu") ;search whole client-area if search was initiated from settings menu, or if this specific search doesn't have last-known coordinates
		x1 := 0, y1 := 0, x2 := 0, y2 := 0
	Else	x1 := var.x1, y1 := var.y1, x2 := var.x2, y2 := var.y2

	pNeedle_searchstrings := Gdip_CreateBitmapFromFile("img\Recognition ("vars.client.h "p)\GUI\[search-strings" vars.poe_version "] "name ".bmp") ;load reference img-file that will be searched for in the screenshot
	If InStr(A_Gui, "settings_menu") && (pNeedle_searchstrings <= 0)
	{
		MsgBox, % Lang_Trans("cheat_loaderror") " " name
		Return 0
	}

	If (Gdip_ImageSearch(pHaystack_searchstrings, pNeedle_searchstrings, LIST, x1, y1, x2, y2, vars.imagesearch.variation,, 1, 1) > 0) ;reference img-file was found in the screenshot
	{
		If InStr(A_Gui, "settings_menu") ;if search was initiated from settings menu, save positive coordinates
		{
			Gdip_GetImageDimension(pNeedle_searchstrings, width, height) ;get dimensions of the reference img-file
			IniWrite, % LIST "," Format("{:0.0f}", width) "," Format("{:0.0f}", height), % "ini" vars.poe_version "\search-strings.ini", % name, last coordinates ;write coordinates to ini-file
		}
		Gdip_DisposeImage(pNeedle_searchstrings) ;clear reference-img file from memory
		If InStr(A_Gui, "settings_menu")
			LLK_ToolTip(Lang_Trans("global_positive"),,,,, "lime")
		Return 1
	}
	Else Gdip_DisposeImage(pNeedle_searchstrings)
	If InStr(A_Gui, "settings_menu")
		LLK_ToolTip(Lang_Trans("global_negative"),,,,, "red")
	Return 0
}
