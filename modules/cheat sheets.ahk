Init_cheatsheets()
{
	global
	local iniread, iniread1, font_height, font_width, key, parse, parse1
	
	settings.features.cheatsheets := LLK_IniRead("ini\config.ini", "Features", "enable cheat-sheets", 0)
	
	settings.cheatsheets := {}
	settings.cheatsheets.fSize := LLK_IniRead("ini\cheat-sheets.ini", "settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.cheatsheets.fSize, font_height, font_width)
	settings.cheatsheets.fHeight := font_height, settings.cheatsheets.fWidth := font_width
	settings.cheatsheets.dColors := ["Lime", "Yellow", "Red", "Aqua"]
	settings.cheatsheets.colors := []
	settings.cheatsheets.colors[0] := "White"
	;settings.cheatsheets.quick := LLK_IniRead("ini\cheat-sheets.ini", "settings", "quick access", 0)
	settings.cheatsheets.modifiers := ["alt", "ctrl", "shift"]
	settings.cheatsheets.modifier := LLK_IniRead("ini\cheat-sheets.ini", "settings", "modifier-key", "alt")
	If !LLK_HasVal(settings.cheatsheets.modifiers, settings.cheatsheets.modifier) ;force alt if modifier-key is an unexpected key
		settings.cheatsheets.modifier := "alt"
	
	Loop 4
		settings.cheatsheets.colors[A_Index] := LLK_IniRead("ini\cheat-sheets.ini", "UI", "rank " A_Index " color", settings.cheatsheets.dColors[A_Index])

	vars.cheatsheets.count_advanced := 0 ;save number of advanced sheets (used in the settings menu to determine if list of advanced sheets will be shown or not)
	
	;rebuild list of cheat-sheets
	vars.cheatsheets.list := {}
	Loop, Files, cheat-sheets\*, D
		vars.cheatsheets.list[A_LoopFileName] := {}
	
	For key in vars.cheatsheets.list
	{
		If !IsObject(vars.cheatsheets[key])
			vars.cheatsheets[key] := {}
		vars.cheatsheets.list[key].enable := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "enable", 1)
		vars.cheatsheets.list[key].area := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "image search", "static")
		vars.cheatsheets.list[key].type := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "type", "images")
		vars.cheatsheets.list[key].activation := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "activation", "hold")
		vars.cheatsheets.list[key].scale := LLK_IniRead("cheat-sheets\" key "\info.ini", "UI", "scale", 1)
		vars.cheatsheets.list[key].pos := LLK_IniRead("cheat-sheets\" key "\info.ini", "UI", "position", "2,2")
		vars.cheatsheets.list[key].pos := [SubStr(vars.cheatsheets.list[key].pos, 1, 1), SubStr(vars.cheatsheets.list[key].pos, 3, 1)]
		iniread := LLK_IniRead("cheat-sheets\" key "\info.ini", "image search", "last coordinates")
		Loop, Parse, iniread, `,
		{
			If (A_Index = 1)
				vars.cheatsheets.list[key].x1 := A_LoopField
			Else If (A_Index = 2)
				vars.cheatsheets.list[key].y1 := A_LoopField
			Else If (A_Index = 3)
				vars.cheatsheets.list[key].x2 := A_LoopField
			Else vars.cheatsheets.list[key].y2 := A_LoopField
		}
		
		If (vars.cheatsheets.list[key].type = "advanced")
		{
			vars.cheatsheets.count_advanced += 1
			vars.cheatsheets.list[key].variation := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "image search variation", 0) ;each sheet has its own imgsearch-variation (strictness) which is determined on-the-fly, then saved for future use
			iniread := LLK_IniRead("cheat-sheets\" key "\info.ini", "entries") ;load a sheet's entries from ini
			vars.cheatsheets.list[key].entries := {} ;store the entries here
			Loop, Parse, iniread, `n
			{
				parse1 := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
				vars.cheatsheets.list[key].entries[parse1] := {"panels": [], "ranks": []} ;each entry has panels which may also be ranked
				Loop 4
				{
					vars.cheatsheets.list[key].entries[parse1].panels[A_Index] := StrReplace(LLK_IniRead("cheat-sheets\" key "\info.ini", parse1, "panel "A_Index), "^^^", "`n")
					vars.cheatsheets.list[key].entries[parse1].ranks[A_Index] := LLK_IniRead("cheat-sheets\" key "\info.ini", parse1, "panel " A_Index " rank", 0)
				}
			}
		}
		Else If (vars.cheatsheets.list[key].type = "app")
			vars.cheatsheets.list[key].title := LLK_IniRead("cheat-sheets\" key "\info.ini", "general", "app title")
		Else If (vars.cheatsheets.list[key].type = "images")
			vars.cheatsheets.list[key].header := LLK_IniRead("cheat-sheets\"key "\info.ini", "general", "00-position", "top")
	}
}

CheatsheetActivate(name, hotkey)
{
	local
	global vars 
	
	type := vars.cheatsheets.list[name].type, activation := vars.cheatsheets.list[name].activation
	vars.cheatsheets.active := {"name": name, "type": type, "toggle": GetKeyState("alt", "P") + GetKeyState("ctrl", "P") + GetKeyState("shift", "P")}
	
	Switch type
	{
		Case "images":
			CheatsheetImage(name)
			If (activation = "hold") && (vars.cheatsheets.active.toggle < 2)
			{
				While GetKeyState(hotkey, "P") ;key-release cannot be placed in the function itself because it may be called multiple times via hotkeys (unlike app-based and advanced sheets)
					Sleep 50
				CheatsheetClose()
			}
		Case "app":
			CheatsheetApp(name, hotkey)
		Case "advanced":
			CheatsheetAdvanced(name, hotkey)
	}
}

CheatsheetAdd(name, type)
{
	local
	global vars

	WinGetPos, xPos, yPos, width, height, % "ahk_id " vars.hwnd.settings.name
	While (SubStr(name, 1, 1) = " ")
		name := SubStr(name, 2)
	While (SubStr(name, 0) = " ")
		name := SubStr(name, 1, -1)
	Loop, Parse, name
	{
		If !LLK_IsType(A_LoopField, "alnum")
		{
			LLK_ToolTip("regular letters, spaces,`nand numbers only", 2, xPos, yPos + height,, "red")
			Return
		}
	}
	If (name = "")
	{
		LLK_ToolTip("name cannot be blank", 1.5, xPos, yPos + height,, "red")
		Return
	}
	If FileExist("cheat-sheets\"name "\")
	{
		MsgBox, 4, name conflict, A cheat-sheet with the same name already exists and will be overwritten. Do you want to continue?
		IfMsgBox No
		{
			WinActivate, % "ahk_id " vars.hwnd.settings.main
			Return
		}
	}
	FileRemoveDir, cheat-sheets\%name%, 1
	If FileExist("cheat-sheets\"name "\")
		error := 1, LLK_FilePermissionError("delete")
	FileCreateDir, cheat-sheets\%name%
	If !error && !FileExist("cheat-sheets\"name "\")
		error := 1, LLK_FilePermissionError("create")
	If error
		Return
	IniWrite, 1, cheat-sheets\%name%\info.ini, general, enable
	IniWrite, % type, cheat-sheets\%name%\info.ini, general, type
	IniWrite, 1, cheat-sheets\%name%\info.ini, UI, scale
	IniWrite, % "2,2", cheat-sheets\%name%\info.ini, UI, position
	IniWrite, static, cheat-sheets\%name%\info.ini, general, image search
	IniWrite, hold, cheat-sheets\%name%\info.ini, general, activation
	Settings_menu("cheat-sheets")
}

CheatsheetAdvanced(name, hotkey)
{
	local
	global vars, settings
	
	variation := vars.imagesearch.variation
	If GetKeyState("RButton", "P") && !A_Gui
	{
		CheatsheetCalibrate()
		Return
	}
	
	If (A_Gui != DummyGUI(vars.hwnd.cheatsheet_menu.main))
	{
		pHaystack := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
		LLK_ToolTip("checking...", 10, vars.general.xMouse + vars.client.w/100, vars.general.yMouse, "cheatsheet")
		While GetKeyState(hotkey, "P") && (variation <= 75)
		{
			Loop, Files, % "cheat-sheets\" name "\[check] *.bmp"
			{
				pNeedle := Gdip_LoadImageFromFile(A_LoopFilePath)
				If (pNeedle <= 0)
					Continue
				x1 := (vars.general.xMouse - vars.client.x - vars.client.w/3 < 0) ? 0 : vars.general.xMouse - vars.client.x - vars.client.w/3
				x2 := (vars.general.xMouse - vars.client.x + vars.client.w/3 > vars.client.w) ? vars.client.w - 1 : vars.general.xMouse - vars.client.x + vars.client.w/3
				y1 := (vars.general.yMouse - vars.client.y - vars.client.h/4 < 0) ? 0 : vars.general.yMouse - vars.client.y - vars.client.h/4
				y2 := (vars.general.yMouse - vars.client.y + vars.client.h/4 > vars.client.h) ? vars.client.h - 1 : vars.general.yMouse - vars.client.y + vars.client.h/4 > vars.client.h
				pResult := Gdip_ImageSearch(pHaystack, pNeedle,, x1, y1, x2, y2, variation,,, 1)
				Gdip_DisposeImage(pNeedle)
				If (pResult > 0)
				{
					result := StrReplace(A_LoopFileName, "." A_LoopFileExt), result := SubStr(result, InStr(result, "[check] ") + 8)
					Break 2
				}
			}
			variation += 10
		}
		vars.tooltip[vars.hwnd.tooltipcheatsheet] := A_TickCount
		Gdip_DisposeImage(pHaystack)
	}
	Else
	{
		result := vars.cheatsheet_menu.entry
		Gui, cheatsheet_menu: Submit, NoHide
	}

	vars.cheatsheets.entry := result
	
	If !result
	{
		LLK_ToolTip("no match")
		Return
	}
	
	If result && WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main) && vars.cheatsheet_menu.entry
		CheatsheetMenuEntrySave()
	
	Loop 4
		panel%A_Index% := vars.cheatsheets.list[name].entries[result].panels[A_Index]
	

	If (panel1 panel2 panel3 panel4 = "")
	{
		If (A_Gui != DummyGUI(vars.hwnd.cheatsheet_menu.main))
			LLK_ToolTip("entry <"result "> was`nfound but has no text", 2)
		Else LLK_ToolTip("entry <"result "> has no text", 2)
		Return
	}
	
	vars.cheatsheets.active.type := "advanced", width := 0
	Loop 2 ;GUI drawn twice (first one determines max required width)
	{
		Gui, cheatsheet: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
		Gui, cheatsheet: Color, Black
		Gui, cheatsheet: Margin, 0, 0
		WinSet, Transparent, 255
		Gui, cheatsheet: Font, % "s"settings.cheatsheets.fSize " cWhite", Fontin SmallCaps
		vars.hwnd.cheatsheet := {"main": hwnd}
		
		style := (A_Index = 2) ? "w"width : ""
		Loop, Parse, % vars.cheatsheets.entry "^" panel1 "^" panel2 "^" panel3 "^" panel4, `^
		{
			If (A_LoopField = "")
				continue
			color := settings.cheatsheets.colors[vars.cheatsheets.list[name].entries[result].ranks[A_Index]]
			If (A_Index = 1)
				Gui, cheatsheet: Add, Text, % "Section "style " xs Border Center HWNDhwnd", % vars.cheatsheets.entry
			Else Gui, cheatsheet: Add, Text, % "Section "style " c"color " xs Border Center HWNDhwnd", % StrReplace(A_LoopField, "&", "&&")
			ControlGetPos,,, w,,, % "ahk_id "hwnd ;panels have an HWND in order to check if the cursor is hovering over them
			vars.hwnd.cheatsheet["panel"A_Index] := hwnd
			width := (1.1*w > width) ? 1.1*w : width
		}
	}
	
	Gui, cheatsheet: Show, NA x10000 y10000
	WinGetPos,,, width, height, % "ahk_id " vars.hwnd.cheatsheet.main
	If (vars.general.xMouse - width/2 < vars.monitor.x)
		xPos := xScreenOffset
	Else xPos := (vars.general.xMouse + width/2 > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - width : vars.general.xMouse - width/2
	yPos := (vars.general.yMouse + height > vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - height : vars.general.yMouse
	Gui cheatsheet: Show, NA x%xPos% y%yPos%
	LLK_Overlay(vars.hwnd.cheatsheet.main, "show")
	
	If (vars.cheatsheets.list[name].activation = "hold") && (vars.cheatsheets.active.toggle < 2)
	{
		KeyWait, % hotkey
		If (A_Gui = DummyGUI(vars.hwnd.cheatsheet_menu.main))
			KeyWait, LButton
		LLK_Overlay(vars.hwnd.cheatsheet.main, "hide")
		vars.cheatsheets.active.type := "advanced"
	}
}

CheatsheetApp(name, hotkey)
{
	local
	global vars, settings

	If !vars.cheatsheets.list[name].title
	{
		LLK_ToolTip("cheat-sheet was activated but`nhas no window title", 2,,,, "red")
		Return
	}
	
	If !WinExist(vars.cheatsheets.list[name].title)
	{
		If !FileExist("cheat-sheets\"name "\app.lnk")
		{
			LLK_ToolTip("window title doesn't exist:`n"""vars.cheatsheets.list[name].title """", 1.5,,,, "red")
			Return
		}
		Run, % "cheat-sheets\"name "\app.lnk",
		WinWaitActive, % vars.cheatsheets.list[name].title
		WinMaximize, % vars.cheatsheets.list[name].title
	}
	
	vars.cheatsheets.active.type := "app"
	If WinExist(vars.cheatsheets.list[name].title)
	{
		WinActivate, % vars.cheatsheets.list[name].title
		If (vars.cheatsheets.list[name].activation = "hold") && (vars.cheatsheets.active.toggle < 2)
		{
			KeyWait, % hotkey
			WinActivate, ahk_group poe_window
			;WinSet, Bottom,, % cheatsheets_apptitle_%parse%
			WinMinimize, % vars.cheatsheets.list[name].title
		}
		Else WinWaitActive, ahk_group poe_window
	}
	CheatsheetClose()
}

CheatsheetCalibrate()
{
	local
	global vars, settings

	name := vars.cheatsheets.active.name, prohibited := ["general", "ui", "image search", "entries"]
	If (A_Gui = "cheatsheet_calibration")
	{
		parse := LLK_ControlGet(vars.hwnd.cheatsheet_calibration.choice)
		While (SubStr(parse, 1, 1) = " ")
			parse := SubStr(parse, 2)
		While (SubStr(parse, 0) = " ")
			parse := SubStr(parse, 1, -1)
		If !parse
		{
			LLK_ToolTip("entry-name cannot be blank", 1.5,,,, "red")
			Return
		}
		If LLK_HasVal(prohibited, parse) ;entry-name cannot be the same as existing ini-sections (otherwise, they will be deleted when the entry is deleted)
		{
			LLK_ToolTip("entry-name invalid",,,,, "red")
			Return
		}
		Loop, Parse, parse
		{
			If !LLK_IsType(A_LoopField, "alnum")
			{
				LLK_ToolTip("regular letters, spaces,`nand numbers only", 2,,,, "red")
				Return
			}
		}
		vars.cheatsheets.active.choice := LLK_ControlGet(vars.hwnd.cheatsheet_calibration.choice, "cheatsheet_calibration")
		If InStr(A_GuiControl, "edit")
		{
			If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main) && (vars.cheatsheet_menu.type = "advanced") && vars.cheatsheet_menu.entry
				CheatsheetMenuEntrySave()
			
			vars.cheatsheet_menu := {"active": name, "entry": vars.cheatsheets.active.choice}
			If !WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main)
				CheatsheetMenu(name, 1)
		}
		Return
	}

	Clipboard := ""
	SendInput, #+{s}
	WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
	WinWaitNotActive, ahk_exe ScreenClippingHost.exe
	pBitmap := Gdip_CreateBitmapFromClipboard()
	If (pBitmap <= 0)
	{
		LLK_ToolTip("screen-cap aborted",,,,, "red")
		Return
	}

	Gdip_GetImageDimensions(pBitmap, width, height)
	Gui, cheatsheet_calibration: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd
	Gui, cheatsheet_calibration: Margin, % settings.general.fWidth//2, % settings.general.fHeight//4
	Gui, cheatsheet_calibration: Color, Black
	Gui, cheatsheet_calibration: Font, % "cWhite s"settings.general.fSize " underline", Fontin SmallCaps
	vars.hwnd.cheatsheet_calibration := {"main": hwnd}
	
	hbmBitmap := CreateDIBSection(width, height), hdcBitmap := CreateCompatibleDC(), obmBitmap := SelectObject(hdcBitmap, hbmBitmap), gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
	Gdip_SetInterpolationMode(gBitmap, 0)
	Gdip_DrawImage(gBitmap, pBitmap, 0, 0, width, height, 0, 0, width, height, 1)
	Gui, cheatsheet_calibration: Add, Picture, % "Section Border BackgroundTrans", HBitmap:*%hbmBitmap%
	SelectObject(hdcBitmap, obmBitmap)
	DeleteObject(hbmBitmap)
	DeleteDC(hdcBitmap)
	Gdip_DeleteGraphics(gBitmap)
	
	For entry in vars.cheatsheets.list[name].entries
		ddl .= entry "|"

	Gui, cheatsheet_calibration: Add, Text, % "Section BackgroundTrans", % "specify which entry this screen-check is linked to"
	Gui, cheatsheet_calibration: Font, norm
	Gui, cheatsheet_calibration: Add, ComboBox, % "Section xs BackgroundTrans HWNDhwnd wp-"settings.general.fWidth*16 " cBlack r"vars.cheatsheets.list[name].entries.Count(), % ddl
	vars.hwnd.cheatsheet_calibration.choice := hwnd
	Gui, cheatsheet_calibration: Add, Text, % "ys hp 0x200 Border Center w"settings.general.fWidth*5 " gCheatsheetCalibrate", % " save "
	Gui, cheatsheet_calibration: Add, Text, % "ys hp 0x200 Border Center w"settings.general.fWidth*10 " gCheatsheetCalibrate", % " save && edit "
	;Gui, cheatsheet_calibration: Add, Button, % "x0 y0 BackgroundTrans Hidden Default gCheatsheets vCheatsheets_calibration_save2", % "save"
	
	Gui, cheatsheet_calibration: Show
	While !vars.cheatsheets.active.choice && WinActive("ahk_id " vars.hwnd.cheatsheet_calibration.main)
		sleep 50
	
	If vars.cheatsheets.active.choice
	{
		Gdip_SaveBitmapToFile(pBitmap, "cheat-sheets\" name "\[check] " vars.cheatsheets.active.choice ".bmp", 100)
		If !LLK_HasVal(vars.cheatsheets.list[name].entries, vars.cheatsheets.active.choice)
		{
			If !IsObject(vars.cheatsheets.list[name].entries[vars.cheatsheets.active.choice])
				vars.cheatsheets.list[name].entries[vars.cheatsheets.active.choice] := {"panels": [], "ranks": []}
			IniWrite, 1, % "cheat-sheets\" name "\info.ini", entries, % vars.cheatsheets.active.choice
		}
		If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main)
			CheatsheetMenu(name, 1)
	}
	Else LLK_ToolTip("screen-cap aborted",,,,, "red")
	
	Gdip_DisposeImage(pBitmap)
	Gui, cheatsheet_calibration: Destroy
	vars.hwnd.Delete("cheatsheet_calibration")
}

CheatsheetClose()
{
	global

	vars.cheatsheets.active := ""
	LLK_Overlay(vars.hwnd.cheatsheet.main, "hide")
}

CheatsheetImage(name := "", hotkey := "") ;'hotkey' parameter used when overlay is modified (resized, moved, images added, etc.) by specific hotkeys
{
	local
	global vars, settings

	ignore := ["Up", "Down", "Left", "Right", "F1", "F2", "F3", "RButton", "Space", settings.hotkeys.tab]	
	If !name
		name := vars.cheatsheets.active.name
	Loop, Files, % "cheat-sheets\"name "\[*"
	{
		If !InStr(A_LoopFileName, "[check]") && !InStr(A_LoopFileName, "[sample]") && InStr("jpg,png,bmp", A_LoopFileExt)
			valid += 1
	}
	If !valid
	{
		If (A_Gui = DummyGUI(vars.hwnd.cheatsheet_menu.main))
			LLK_ToolTip("sheet contains no files", 2,,,, "red")
		Else LLK_ToolTip("sheet was activated but`ncontains no files", 2,,,, "red")
		vars.cheatsheets[name].include := []
		cheatsheets_loaded_images := ""
		Return
	}

	If (StrLen(hotkey) > 1)
		Loop, Parse, % "*~!+#^"
			hotkey := StrReplace(hotkey, A_LoopField)
	
	If (hotkey = 0)
		hotkey := 10
	
	If !IsObject(vars.cheatsheets[name].include)
		vars.cheatsheets[name].include := []
	has_00 := FileExist("cheat-sheets\"name "\[00].*")

	If LLK_HasVal(ignore, hotkey)
	{
		If (hotkey = "Space")
			vars.cheatsheets[name].include := []
		Else If InStr("up,down,left,right", hotkey)
		{
			vars.cheatsheets.list[name].pos.1 += (hotkey = "left" && vars.cheatsheets.list[name].pos.1 > 1) ? -1 : (hotkey = "right" && vars.cheatsheets.list[name].pos.1 < 3) ? 1 : 0
			vars.cheatsheets.list[name].pos.2 += (hotkey = "up" && vars.cheatsheets.list[name].pos.2 > 1) ? -1 : (hotkey = "down" && vars.cheatsheets.list[name].pos.2 < 3) ? 1 : 0
			IniWrite, % vars.cheatsheets.list[name].pos.1 "," vars.cheatsheets.list[name].pos.2, % "cheat-sheets\"name "\info.ini", UI, position
		}
		Else If InStr("F1,F2,F3", hotkey)
		{
			vars.cheatsheets.list[name].scale += (hotkey = "F1" && vars.cheatsheets.list[name].scale > 0.5) ? -0.1 : ((hotkey = "F2" && vars.cheatsheets.list[name].scale < 2)) ? 0.1 : 0
			vars.cheatsheets.list[name].scale /= (hotkey = "F3") ? vars.cheatsheets.list[name].scale : 1
			IniWrite, % Format("{:0.1f}", vars.cheatsheets.list[name].scale), % "cheat-sheets\"name "\info.ini", UI, scale
		}
		Else If (hotkey = "RButton")
		{
			WinGetPos, x, y,,, % "ahk_id "vars.hwnd.cheatsheet.main
			If has_00
			{
				LLK_ToolTip("cannot flip through images`nin segmented sheets", 2, x, y,, "Yellow")
				Return
			}
			If !IsNumber(vars.cheatsheets[name].include.1)
			{
				LLK_ToolTip("cannot flip through images`nif letter-key was used", 2, x, y,, "Yellow")
				Return
			}
			start := A_TickCount, key := 1, index := 1
			While GetKeyState("RButton", "P")
			{
				If (A_TickCount >= start + 300)
				{
					key := (vars.cheatsheets[name].include.1 > 1) ? -1 : 0
					index := key
					Break
				}
			}
			
			While !FileExist("cheat-sheets\"name "\["vars.cheatsheets[name].include.1 + index "]*") && !FileExist("cheat-sheets\"name "\[0"vars.cheatsheets[name].include.1 + index "]*")
			{
				If (A_Index = 100)
				{
					index := 0
					Break
				}
				index += key
			}
			vars.cheatsheets[name].include.1 += index
			vars.cheatsheets[name].include.1 := (vars.cheatsheets[name].include.1 < 10) ? "0" vars.cheatsheets[name].include.1 : vars.cheatsheets[name].include.1
		}
		Else If (hotkey = settings.hotkeys.tab)
		{
			If !has_00
				Return
			vars.cheatsheets[name].include0 := []
			For key, index in vars.cheatsheets[name].include
				vars.cheatsheets[name].include0.Push(index)
			vars.cheatsheets[name].include := []
			Loop, Files, % "cheat-sheets\"name "\[*"
			{
				If InStr(A_LoopFileName, "check") || InStr(A_LoopFileName, "sample") || !InStr("jpg,png,bmp", A_LoopFileExt)
					continue
				vars.cheatsheets[name].include.Push(SubStr(A_LoopFileName, 2, 2))
			}
		}
		hotkey := ""
	}
	
	For key, index in vars.cheatsheets[name].include
	{
		If !FileExist("cheat-sheets\"name "\["index "]*") && !FileExist("cheat-sheets\"name "\*] "index ".*") ;previously-loaded image is no longer available
		|| has_00 && !LLK_HasVal(vars.cheatsheets[name].include, "00") ;overlay was previously activated as non-segmented, but it has since been modified into a segmented one
		{
			vars.cheatsheets[name].include := [] ;reset overlay to blank
			Break
		}
	}

	If !vars.cheatsheets[name].include.Count() ;activated overlay is 'blank'
	{
		If has_00
			vars.cheatsheets[name].include.1 := "00" ;if segmented, set overlay to base-state
		Else
		{
			Loop, Files, % "cheat-sheets\"name "\[*" ;if not segmented, load first available image
			{
				If InStr(A_LoopFileName, "check") || InStr(A_LoopFileName, "sample") || !InStr("jpg,png,bmp", A_LoopFileExt)
					continue
				vars.cheatsheets[name].include.1 := SubStr(A_LoopFileName, 2, 2)
				Break
			}
		}
	}

	If hotkey && (LLK_HasVal(vars.cheatsheets[name].include, hotkey) || !FileExist("cheat-sheets\"name "\["hotkey "]*.*") && !FileExist("cheat-sheets\"name "\*] "hotkey ".*") ;cont
	&& !FileExist("cheat-sheets\"name "\[0"hotkey "]*.*"))
		Return
	Else If LLK_IsType(hotkey, "alnum") && has_00
		vars.cheatsheets[name].include.Push((hotkey < 10) ? "0" hotkey : hotkey)
	Else If LLK_IsType(hotkey, "alnum") && !has_00
		vars.cheatsheets[name].include := [(hotkey < 10) ? "0" hotkey : hotkey]
	
	Gui, cheatsheet: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
	Gui, cheatsheet: Color, Black
	Gui, cheatsheet: Margin, 0, 0
	WinSet, Transparent, 255
	Gui, cheatsheet: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	vars.hwnd.cheatsheet := {"main": hwnd}

	For key, index in vars.cheatsheets[name].include
	{
		file := ""
		If IsNumber(index)
		{
			Loop, Files, % "cheat-sheets\"name "\["index "]*"
			{
				If InStr("jpg,png,bmp", A_LoopFileExt)
				{
					file := A_LoopFilePath
					Break
				}
			}
		}
		Else
		{
			Loop, Files, % "cheat-sheets\"name "\*] "index ".*"
			{
				If InStr("jpg,png,bmp", A_LoopFileExt)
				{
					file := A_LoopFilePath
					Break
				}
			}
		}
		If !file
			Return
		
		If (index = "00")
			style := (vars.cheatsheets.list[name].header = "top") ? "xs" : "ys"

		pBitmap := Gdip_LoadImageFromFile(file)
		If (pBitmap <= 0)
		{
			MsgBox, % "The file """ file """ could not be loaded correctly."
			Return
		}
		Gdip_GetImageDimensions(pBitmap, width, height)
		If (height >= vars.monitor.h*0.9)
		{
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, ((vars.monitor.h*0.9) / height) * width, 10000, 1, 7)
			Gdip_DisposeImage(pBitmap_copy)
		}
		Else If (width >= vars.monitor.w*0.9)
		{
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, vars.monitor.w*0.9, 10000, 1, 7)
			Gdip_DisposeImage(pBitmap_copy)
		}

		Gdip_GetImageDimensions(pBitmap, width, height)
		If (vars.cheatsheets.list[name].scale != 1)
		{
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, width* vars.cheatsheets.list[name].scale, 10000, 1, 7)
			Gdip_DisposeImage(pBitmap_copy)
			Gdip_GetImageDimensions(pBitmap, width, height)
		}
		
		hbmBitmap := CreateDIBSection(width, height), hdcBitmap := CreateCompatibleDC(), obmBitmap := SelectObject(hdcBitmap, hbmBitmap), gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
		Gdip_SetInterpolationMode(gBitmap, 0)
		Gdip_DrawImage(gBitmap, pBitmap, 0, 0, width, height, 0, 0, width, height, 1)
		If (index = "00")
			Gui, cheatsheet: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmBitmap%
		Else Gui, cheatsheet: Add, Picture, % style " Section BackgroundTrans", HBitmap:*%hbmBitmap%
		added += 1
		SelectObject(hdcBitmap, obmBitmap)
		DeleteObject(hbmBitmap)
		DeleteDC(hdcBitmap)
		Gdip_DeleteGraphics(gBitmap)
		Gdip_DisposeImage(pBitmap)
	}

	If added
	{
		Gui, cheatsheet: Show, NA x10000 y10000
		WinGetPos,,, width, height, % "ahk_id " vars.hwnd.cheatsheet.main
		style := ""
		Switch vars.cheatsheets.list[name].pos.1
		{
			Case 1:
				style .= "x"vars.client.x
			Case 2:
				style .= "x"vars.client.xc - width//2
			Case 3:
				style .= "x"vars.client.x + vars.client.w - width
		}
		Switch vars.cheatsheets.list[name].pos.2
		{
			Case 1:
				style .= " y"vars.client.y
			Case 2:
				style .= " y"vars.client.yc - height//2
			Case 3:
				style .= " y"vars.client.y + vars.client.h - height
		}
		Gui, cheatsheet: Show, NA AutoSize %style%
		LLK_Overlay(vars.hwnd.cheatsheet.main, "show")
		vars.cheatsheets.active.type := "image"
	}
}

CheatsheetInfo(name)
{
	local
	global vars, settings

	Gui, cheatsheet_info: New, -Caption +E0x20 +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd
	Gui, cheatsheet_info: Margin, % settings.general.fWidth, % settings.general.fHeight/2
	Gui, cheatsheet_info: Color, Black
	WinSet, Transparent, 255
	Gui, cheatsheet_info: Font, % " cWhite s"settings.general.fSize, Fontin SmallCaps
	vars.hwnd.cheatsheet_info := hwnd
	image := ""
	
	If FileExist("cheat-sheets\"name "\[sample].*") || FileExist("cheat-sheets\"name "\[check].bmp")
	{
		Loop, Files, % "cheat-sheets\"name "\[sample].*"
		{
			If InStr("jpg,bmp,png", A_LoopFileExt)
			{
				image := A_LoopFilePath
				Break
			}
		}
		If (image = "")
			image := "cheat-sheets\"name "\[check].bmp"
		
		pBitmap := Gdip_CreateBitmapFromFile(image)
		Gdip_GetImageDimensions(pBitmap, width, height)
		
		If (width > settings.general.fWidth*35)
		{
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, settings.general.fWidth*35, 10000, 1, 7)
			Gdip_GetImageDimensions(pBitmap, width, height)
			Gdip_DisposeImage(pBitmap_copy)
		}
		hbmBitmap := CreateDIBSection(width, height)
		hdcBitmap := CreateCompatibleDC()
		obmBitmap := SelectObject(hdcBitmap, hbmBitmap)
		gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
		Gdip_SetInterpolationMode(gBitmap, 0)
		Gdip_DrawImage(gBitmap, pBitmap, 0, 0, width, height, 0, 0, width, height, 1)
		Gui, cheatsheet_info: Add, Picture, % "Section Border BackgroundTrans", HBitmap:*%hbmBitmap%
		SelectObject(hdcBitmap, obmBitmap)
		DeleteObject(hbmBitmap)
		DeleteDC(hdcBitmap)
		Gdip_DeleteGraphics(gBitmap)
		Gdip_DisposeImage(pBitmap)
	}
	Else Gui, cheatsheet_info: Add, Text, % "Border 0x200 Center w"settings.general.fWidth*35 " h"settings.general.fWidth*16, no image available
	
	If (image != "")
	{
		Gui, cheatsheet_info: Font, underline
		Gui, cheatsheet_info: Add, Text, % "Section xs BackgroundTrans w"settings.general.fWidth*35, % "instructions:"
		Gui, cheatsheet_info: Font, norm
		IniRead, ini, % "cheat-sheets\" name "\info.ini", general, instructions, % "to recalibrate, screen-cap the area displayed above"
		While (ini != "")
		{
			Gui, cheatsheet_info: Add, Text, % "xs y+0 BackgroundTrans w"settings.general.fWidth*35, % "–> " ini
			IniRead, ini, % "cheat-sheets\" name "\info.ini", general, instructions%A_Index%, % A_Space
		}
	}
	Gui, cheatsheet_info: Font, underline
	Gui, cheatsheet_info: Add, Text, % "xs y+"settings.general.fHeight//2 " w"settings.general.fWidth*35, % "information:"
	Gui, cheatsheet_info: Font, norm
	Gui, cheatsheet_info: Add, Text, % "xs y+0 w"settings.general.fWidth*35 ;cont
	, % "–> type: " vars.cheatsheets.list[name].type "`n–> screen-check: " vars.cheatsheets.list[name].area "`n–> activation: " vars.cheatsheets.list[name].activation
	
	IniRead, ini, % "cheat-sheets\" name "\info.ini", general, description, % A_Space
	While (ini != "")
	{
		If (A_Index = 1)
			Gui, cheatsheet_info: Add, Text, % "xs y+"settings.general.fHeight/2 " BackgroundTrans w"settings.general.fWidth*35, % "description"
		Gui, cheatsheet_info: Add, Text, % "xs y+0 BackgroundTrans w"settings.general.fWidth*35, % "–> " ini
		IniRead, ini, % "cheat-sheets\"name "\info.ini", general, description%A_Index%, % A_Space
	}
	Gui, cheatsheet_info: Show, NA x10000 y10000
	WinGetPos,,, width, height, % "ahk_id "vars.hwnd.cheatsheet_info
	xPos := (vars.general.xMouse - vars.client.x + width > vars.client.w) ? vars.client.x + vars.client.w - width : vars.general.xMouse
	yPos := (vars.general.yMouse - vars.client.y + height > vars.client.h) ? vars.client.y + vars.client.h - height : vars.general.yMouse
	Gui, cheatsheet_info: Show, NA x%xPos% y%yPos%
	KeyWait, LButton
	Gui, cheatsheet_info: Destroy
	vars.hwnd.Delete("cheatsheet_info")
}

CheatsheetMenu2(cHWND) ;function to handle inputs within the 'cheatsheet_menu' GUI (similar to the secondary functions for the settings menu)
{
	local
	global vars, settings

	name := vars.cheatsheet_menu.active, check := LLK_HasVal(vars.hwnd.cheatsheet_menu, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If (check = "check") ;toggling the screen-check DDL
	{
		vars.cheatsheets.list[name].area := LLK_ControlGet(cHWND)
		IniWrite, % LLK_ControlGet(cHWND), % "cheat-sheets\"name "\info.ini", general, image search
	}
	Else If (check = "activation") ;toggling the activation DDL
	{
		vars.cheatsheets.list[name].activation := LLK_ControlGet(cHWND)
		IniWrite, % LLK_ControlGet(cHWND), % "cheat-sheets\"name "\info.ini", general, activation
	}
	Else If InStr(check, "preview_") && !InStr(check, "sheet") ;long-clicking an img-index for preview
		CheatsheetMenuPreview(name, "["control "]*")
	Else If InStr(check, "paste_") ;clicking a paste button to load an img into an index-slot
		CheatsheetMenuPaste(control)
	Else If InStr(check, "snip_") ;clicking a snip button to initiate screen-capping for an index-slot
	{
		pBitmap := SnippingTool((control = "00") || FileExist("cheat-sheets\"name "\[00]*") ? 1 : 0)
		If (pBitmap <= 0)
			Return
		FileDelete, % "cheat-sheets\"name "\["control "]*"
		Gdip_SaveBitmapToFile(pBitmap, "cheat-sheets\"name "\["control "].png", 100)
		Gdip_DisposeImage(pBitmap)
		CheatsheetMenu(name)
	}	
	Else If InStr(check, "del_") ;long-clicking a del button to delete the image of an index-slot
	{
		If LLK_Progress(vars.hwnd.cheatsheet_menu["delbar_"control], "LButton", cHWND)
		{
			FileDelete, % "cheat-sheets\"name "\["control "]*"
			CheatsheetMenu(name)
		}
		Else Return
	}
	Else If (check = "position") ;setting the header-position for image-sheets
	{
		vars.cheatsheets.list[name].header := LLK_ControlGet(cHWND)
		IniWrite, % LLK_ControlGet(cHWND), % "cheat-sheets\"name "\info.ini", general, 00-position
	}
	Else If InStr(check, "tag_") ;assigning a hotkey to an index-slot
		CheatsheetMenuTag(cHWND, control)
	Else If (check = "preview_sheet") ;long-clicking the preview button
		CheatsheetActivate(name, "LButton")
	Else If (check = "test_title") ;clicking the test button to test a chosen window-title
	{
		title := LLK_ControlGet(vars.hwnd.cheatsheet_menu.title)
		If (StrLen(title) < 4)
			LLK_ToolTip("title is too short",,,,, "red")
		Else If WinExist(title)
		{
			WinActivate, % title
			vars.cheatsheets.list[name].title := title
			IniWrite, % title, % "cheat-sheets\"name "\info.ini", general, app title
			KeyWait, LButton
			WinActivate, ahk_group poe_window
		}
	}
	Else If (check = "pick") ;clicking the pick button to pick an exe/shortcut file
	{
		FileSelectFile, app, 35, %A_Desktop%, Choose which file to launch, applications/shortcuts (*.exe; *.lnk)
		If ErrorLevel || !app
		{
			LLK_ToolTip("file selection aborted")
			Return
		}
		If InStr(app, ".lnk")
			FileCopy, % app, % "cheat-sheets\"name "\app.lnk", 1
		Else If InStr(app, ".exe")
			FileCreateShortcut, % app, % "cheat-sheets\"name "\app.lnk"
		If FileExist("cheat-sheets\"name "\app.lnk")
		{
			GuiControl, +cLime, % vars.hwnd.cheatsheet_menu.pick
			GuiControl, movedraw, % vars.hwnd.cheatsheet_menu.pick
		}
		While !WinActive("ahk_group poe_window")
			WinActivate, ahk_group poe_window
	}
	Else If (check = "exe_del") ;long-clicking the del button to remove an app
	{
		If LLK_Progress(vars.hwnd.cheatsheet_menu.exe_delbar, "LButton", cHWND)
		{
			FileDelete, % "cheat-sheets\"name "\app.lnk"
			GuiControl, +cWhite, % vars.hwnd.cheatsheet_menu.pick
			GuiControl, movedraw, % vars.hwnd.cheatsheet_menu.pick
		}
		Else Return
	}
	Else If (check = "test_exe") ;clicking the test button to test the exe/shortcut file
	{
		If !FileExist("cheat-sheets\"name "\app.lnk")
		{
			LLK_ToolTip("file hasn't been`npicked yet", 1.5,,,, "red")
			Return
		}
		Else Run, % "cheat-sheets\"name "\app.lnk"
	}
	Else If (check = "entryadd") ;clicking the add button to add a new entry
	{
		CheatsheetMenuEntrySave()
		CheatsheetMenuEntryAdd()
		Return
	}
	Else If InStr(check, "previewentry_") ;long-clicking the preview button to view an entry's img-file
		CheatsheetMenuPreview(name, "[check] "control "*")
	Else If InStr(check, "delentry_") ;long-clicking the delete button to delete an entry
	{
		If LLK_Progress(vars.hwnd.cheatsheet_menu["delbarentry_"control], "LButton", cHWND)
		{
			IniDelete, % "cheat-sheets\"name "\info.ini", entries, % control
			IniDelete, % "cheat-sheets\"name "\info.ini", % control
			FileDelete, % "cheat-sheets\"name "\[check] "control ".*"
			vars.cheatsheets.list[name].entries.Delete(control)
			If (control = vars.cheatsheet_menu.entry)
				CheatsheetMenu(name)
			Else
			{
				CheatsheetMenuEntrySave()
				CheatsheetMenu(name, 1)
			}
			KeyWait, LButton
			Return
		}
		Else Return
	}
	Else If InStr(check, "selectentry_") ;clicking an entry in the list
	{
		If (control = vars.cheatsheet_menu.entry)
			Return
		GuiControl, +cWhite, % vars.hwnd.cheatsheet_menu["selectentry_"vars.cheatsheet_menu.entry]
		GuiControl, movedraw, % vars.hwnd.cheatsheet_menu["selectentry_"vars.cheatsheet_menu.entry]
		CheatsheetMenuEntrySave()
		Loop 4
			GuiControl, text, % vars.hwnd.cheatsheet_menu["panelentry_"A_Index], % vars.cheatsheets.list[name].entries[control].panels[A_Index]
		vars.cheatsheet_menu.entry := control
		GuiControl, +cFuchsia, % cHWND
		GuiControl, movedraw, % cHWND
	}
	Else If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.cheatsheet_menu.main
		While GetKeyState("LButton", "P")
		{
			If (A_TickCount >= start + 100)
				LLK_Drag(w, h, xPos, yPos, 1, A_Gui)
			Sleep 1
		}
	}
	Else LLK_Tooltip("no action")
	
	If !InStr(check, "snip_") && !InStr(check, "tag_")
		GuiControl, Focus, % vars.hwnd.cheatsheet_menu.name
}

CheatsheetMenu(name, refresh := 0) ;refresh = 0 will flush data stored in vars.cheatsheet_menu and build the window from scratch
{
	local
	global vars, settings
	
	If !refresh
		vars.cheatsheet_menu := {"active": name}
	LLK_Overlay(vars.hwnd.settings.main, "hide")
	
	If WinExist("ahk_id " vars.hwnd.cheatsheet_menu.main)
		WinGetPos, xPos, yPos,,, % "ahk_id " vars.hwnd.cheatsheet_menu.main
	Gui, New, -DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDcheatsheet_menu, Lailloken UI: cheat-sheet configuration
	Gui, %cheatsheet_menu%: Color, Black
	Gui, %cheatsheet_menu%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/8
	;WinSet, Transparent, %trans%
	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.cheatsheet_menu.main, vars.hwnd.cheatsheet_menu := {"main": cheatsheet_menu}

	Gui, %cheatsheet_menu%: Add, Text, % "Section x-1 y-1 Border Hidden gCheatsheetMenu2 Center HWNDhwnd", % "cheat-sheet config"
	vars.hwnd.cheatsheet_menu.winbar := hwnd
	Gui, %cheatsheet_menu%: Add, Text, % "ys x+-1 Border Hidden Center gCheatsheetMenuClose HWNDhwnd w"settings.general.fWidth*2, % "x"
	vars.hwnd.cheatsheet_menu.winx := hwnd

	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
	Gui, %cheatsheet_menu%: Add, Text, % "xs Section x"settings.general.fWidth/2 " cSilver Center HWNDhwnd", % "name:"
	vars.hwnd.cheatsheet_menu.name := hwnd
	ControlGetPos,, ySection,,,, ahk_id %hwnd%
	Gui, %cheatsheet_menu%: Add, Text, % "ys Center", % name
	Gui, %cheatsheet_menu%: Add, Text, % "Section xs cSilver Center", % "type:"
	Gui, %cheatsheet_menu%: Add, Text, % "ys Center HWNDmain_text", % vars.cheatsheets.list[name].type
	Gui, %cheatsheet_menu%: Add, Text, % "Section xs cSilver Center HWNDhwnd0", % "screen-check:"
	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
	Gui, %cheatsheet_menu%: Add, DDL, % "ys w"settings.general.fWidth*8 " hp r2 gCheatsheetMenu2 HWNDhwnd", % StrReplace("static|dynamic|", vars.cheatsheets.list[name].area "|", vars.cheatsheets.list[name].area "||")
	vars.hwnd.help_tooltips["cheatsheets_menu screencheck"] := hwnd0, vars.hwnd.cheatsheet_menu.check := vars.hwnd.help_tooltips["cheatsheets_menu screencheck|"] := hwnd
	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
	Gui, %cheatsheet_menu%: Add, Text, % "Section xs cSilver Center HWNDhwnd0", % "activation:"
	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
	Gui, %cheatsheet_menu%: Add, DDL, % "ys w"settings.general.fWidth*7 " hp r2 gCheatsheetMenu2 HWNDhwnd", % StrReplace("hold|toggle|", vars.cheatsheets.list[name].activation "|", vars.cheatsheets.list[name].activation "||")
	vars.hwnd.help_tooltips["cheatsheets_menu activation"] := hwnd0, vars.hwnd.cheatsheet_menu.activation := vars.hwnd.help_tooltips["cheatsheets_menu activation|"] := hwnd
	Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
	
	If (vars.cheatsheets.list[name].type = "images")
	{
		vars.cheatsheet_menu.type := "images", files := 0, handle := ""
		Loop, 99
		{
			If FileExist("cheat-sheets\"name "\[0" A_Index "]*") || FileExist("cheat-sheets\"name "\[" A_Index "]*")
				files := (A_Index < 10) ? "0" A_Index : A_Index
		}
		
		Gui, %cheatsheet_menu%: Font, underline
		Gui, %cheatsheet_menu%: Add, Text, % "y+"settings.general.fHeight//2 " Section xs", % "manage image-files:"
		Gui, %cheatsheet_menu%: Add, Pic, % "ys hp w-1 BackgroundTrans HWNDhwnd0", img\GUI\help.png
		Gui, %cheatsheet_menu%: Font, norm
		Gui, %cheatsheet_menu%: Add, Text, % "Section xs HWNDhwnd1 Center w"settings.general.fWidth*2, % "00"
		Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/2 " Border gCheatsheetMenu2 HWNDhwnd", % " paste "
		vars.hwnd.help_tooltips["cheatsheets_menu image-files"] := hwnd0, vars.hwnd.help_tooltips["cheatsheets_menu 00"] := hwnd1, vars.hwnd.cheatsheet_menu.paste_00 := vars.hwnd.help_tooltips["cheatsheets_menu paste"] := hwnd
		Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gCheatsheetMenu2 HWNDhwnd", % " snip "
		vars.hwnd.cheatsheet_menu.snip_00 := vars.hwnd.help_tooltips["cheatsheets_menu snip0"] := hwnd

		If FileExist("cheat-sheets\" name "\[00]*")
		{
			IniRead, position, % "cheat-sheets\" name "\info.ini", general, 00-position, top
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gCheatsheetMenu2 HWNDhwnd Center", % " show "
			file_00 := 1, vars.hwnd.cheatsheet_menu.preview_00 := vars.hwnd.help_tooltips["cheatsheets_menu show"] := hwnd
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans gCheatsheetMenu2 HWNDhwnd0", % " del "
			Gui, %cheatsheet_menu%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd",
			vars.hwnd.cheatsheet_menu.del_00 := hwnd0, vars.hwnd.cheatsheet_menu.delbar_00 := vars.hwnd.help_tooltips["cheatsheets_menu delete"] := hwnd			
			Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
			Gui, %cheatsheet_menu%: Add, DDL, % "ys x+"settings.general.fWidth/2 " w"settings.general.fWidth*5 " cBlack gCheatsheetMenu2 HWNDhwnd", % StrReplace("top|left|", position, position "|")
			vars.hwnd.cheatsheet_menu.position := vars.hwnd.help_tooltips["cheatsheets_menu header"] := hwnd
			Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
		}
		
		Loop, % files
		{
			loop := (A_Index < 10) ? "0" A_Index : A_Index, handle .= "|"
			Gui, %cheatsheet_menu%: Add, Text, % "Section xs HWNDhwnd Center w"settings.general.fWidth*2, % loop
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/2 " Border gCheatsheetMenu2 HWNDhwnd", % " paste "
			vars.hwnd.cheatsheet_menu["paste_"loop] := vars.hwnd.help_tooltips["cheatsheets_menu paste"handle] := hwnd
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gCheatsheetMenu2 HWNDhwnd", % " snip "
			vars.hwnd.cheatsheet_menu["snip_"loop] := vars.hwnd.help_tooltips["cheatsheets_menu snip" (file_00 ? "0" : "") handle] := hwnd

			If FileExist("cheat-sheets\"name "\["loop "]*")
			{
				Loop, Files, % "cheat-sheets\"name "\["loop "]*"
					file := SubStr(A_LoopFileName, 1, InStr(A_LoopFileName, ".") - 1)
				If (StrLen(file) = 4 || StrLen(file) > 6) ;file not tagged or tagged incorrectly
					file := ""
				Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gCheatsheetMenu2 HWNDhwnd BackgroundTrans", % " show "
				vars.hwnd.cheatsheet_menu["preview_"loop] := vars.hwnd.help_tooltips["cheatsheets_menu show"handle] := hwnd
				Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gCheatsheetMenu2", % " del "
				Gui, %cheatsheet_menu%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack cRed range0-500 HWNDhwnd", 0
				vars.hwnd.cheatsheet_menu["del_"loop] := hwnd0, vars.hwnd.cheatsheet_menu["delbar_"loop] := vars.hwnd.help_tooltips["cheatsheets_menu delete"handle] := hwnd
				Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
				Gui, %cheatsheet_menu%: Add, Edit, % "ys x+"settings.general.fWidth/2 " w"settings.general.fWidth*2 " cBlack Center Limit1 gCheatsheetMenu2 HWNDhwnd", % SubStr(file, 0)
				vars.hwnd.cheatsheet_menu["tag_"loop] := vars.hwnd.help_tooltips["cheatsheets_menu hotkey"handle] := hwnd
				Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
			}
		}
		file := (files < 9) ? "0" files + 1 : files + 1
		Gui, %cheatsheet_menu%: Add, Text, % "Section xs cLime Center w"settings.general.fWidth*2, % file
		Gui, %cheatsheet_menu%: Add, Text, % "ys Border cLime gCheatsheetMenu2 HWNDhwnd", % " paste "
		vars.hwnd.cheatsheet_menu["paste_"file] := vars.hwnd.help_tooltips["cheatsheets_menu paste|"handle] := hwnd
		Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border cLime gCheatsheetMenu2 HWNDhwnd", % " snip "
		vars.hwnd.cheatsheet_menu["snip_"file] := vars.hwnd.help_tooltips["cheatsheets_menu snip|"handle] := hwnd
		
		If files
		{
			Gui, %cheatsheet_menu%: Add, Text, % "Section xs Hidden Center w"settings.general.fWidth*2, % file
			Gui, %cheatsheet_menu%: Add, Text, % "ys Border gCheatsheetMenu2 HWNDhwnd", % " preview "
			vars.hwnd.cheatsheet_menu.preview_sheet := vars.hwnd.help_tooltips["cheatsheets_menu preview"] := hwnd
		}
	}
	Else If (vars.cheatsheets.list[name].type = "app")
	{
		vars.cheatsheet_menu.type := "app", handle := ""
		Gui, %cheatsheet_menu%: Add, Text, % "Section xs y+"settings.general.fHeight/2, % "window title:"
		Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
		Gui, %cheatsheet_menu%: Add, Edit, % "Section xs w"settings.general.fWidth*18 " cBlack HWNDhwnd", % vars.cheatsheets.list[name].title
		vars.hwnd.cheatsheet_menu.title := vars.hwnd.help_tooltips["cheatsheets_menu windowtitle"] := hwnd
		Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
		Gui, %cheatsheet_menu%: Add, Text, % "ys Border HWNDhwnd gCheatsheetMenu2", % " test "
		vars.hwnd.cheatsheet_menu.test_title := hwnd
		
		Gui, %cheatsheet_menu%: Add, Text, % "xs y+"settings.general.fHeight/2 " Section", % "if window is not found,`nlaunch app instead:"
		Gui, %cheatsheet_menu%: Add, Text, % "xs Section Border "(FileExist("cheat-sheets\" name "\app.lnk") ? "cLime" : "cWhite") " gCheatsheetMenu2 HWNDhwnd", % " pick .exe/shortcut "
		vars.hwnd.cheatsheet_menu.pick := vars.hwnd.help_tooltips["cheatsheets_menu exe-pick"] := hwnd
		Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans gCheatsheetMenu2 HWNDhwnd0", % " del "
		Gui, %cheatsheet_menu%: Add, Progress, % "xp yp wp hp Border BackgroundBlack cRed range0-500 Disabled HWNDhwnd", 0
		vars.hwnd.cheatsheet_menu.exe_del := hwnd0, vars.hwnd.cheatsheet_menu.exe_delbar := vars.hwnd.help_tooltips["cheatsheets_menu exe-delete"] := hwnd
		Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gCheatsheetMenu2 HWNDhwnd", % " test "
		vars.hwnd.cheatsheet_menu.test_exe := vars.hwnd.help_tooltips["cheatsheets_menu exe-test"] := hwnd
	}
	Else If (vars.cheatsheets.list[name].type = "advanced")
	{
		vars.cheatsheet_menu.type := "advanced", handle := ""
		Gui, %cheatsheet_menu%: Font, underline
		Gui, %cheatsheet_menu%: Add, Text, % "y+"settings.general.fHeight//2 " Section xs BackgroundTrans", % "add new entry:"
		Gui, %cheatsheet_menu%: Font, norm
		Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize - 4
		Gui, %cheatsheet_menu%: Add, Edit, % "Section xs w"settings.general.fWidth*18 " cBlack HWNDhwnd"
		vars.hwnd.cheatsheet_menu.entryname := vars.hwnd.help_tooltips["cheatsheets_menu entry-about"] := hwnd
		Gui, %cheatsheet_menu%: Font, % "s"settings.general.fSize
		Gui, %cheatsheet_menu%: Add, Text, % "ys Border BackgroundTrans HWNDhwnd gCheatsheetMenu2", % " add "
		vars.hwnd.cheatsheet_menu.entryadd := vars.hwnd.help_tooltips["cheatsheets_menu entry-about|"] := hwnd
		ControlGetPos, xSection,, wSection,,, ahk_id %hwnd%
		width := xSection + wSection
		
		If vars.cheatsheets.list[name].entries.Count()
		{
			Gui, %cheatsheet_menu%: Font, underline
			Gui, %cheatsheet_menu%: Add, Text, % "Section xs y+"settings.general.fHeight//2, % "list of added entries:"
			Gui, %cheatsheet_menu%: Font, norm
		}
		
		For entry in vars.cheatsheets.list[name].entries
		{
			If (A_Index = 1) && !vars.cheatsheet_menu.entry
				vars.cheatsheet_menu.entry := entry
			Gui, %cheatsheet_menu%: Add, Text, % "Section xs w"settings.general.fWidth*2 " Center HWNDhwnd", % A_Index
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border Center gCheatsheetMenu2 HWNDhwnd"(FileExist("cheat-sheets\"name "\[check] " entry ".*") ? "" : " cGray"), % " img "
			vars.hwnd.cheatsheet_menu["previewentry_"entry] := vars.hwnd.help_tooltips["cheatsheets_menu entry-image"handle] := hwnd
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/4 " Center Border BackgroundTrans HWNDhwnd0 gCheatsheetMenu2", % " del "
			Gui, %cheatsheet_menu%: Add, Progress, % "xp yp wp hp Disabled Border range0-500 BackgroundBlack cRed HWNDhwnd", 0
			vars.hwnd.cheatsheet_menu["delentry_"entry] := hwnd0, vars.hwnd.cheatsheet_menu["delbarentry_"entry] := vars.hwnd.help_tooltips["cheatsheets_menu entry-delete"handle] := hwnd
			Gui, %cheatsheet_menu%: Add, Text, % "ys x+"settings.general.fWidth/2 " BackgroundTrans c"(entry = vars.cheatsheet_menu.entry ? "Fuchsia" : "White") " HWNDhwnd gCheatsheetMenu2", % entry
			vars.hwnd.cheatsheet_menu["selectentry_"entry] := vars.hwnd.help_tooltips["cheatsheets_menu entry-select"handle] := hwnd
			ControlGetPos, xSection,, wSection,,, ahk_id %hwnd%
			width := (xSection + wSection > width) ? xSection + wSection : width, handle .= "|"
		}
		
		Gui, %cheatsheet_menu%: Add, Text, % "Section x"width + settings.general.fWidth*2 " y"ySection - 1 " BackgroundTrans", % "enter notes for the overlay-panels: "
		Gui, %cheatsheet_menu%: Add, Edit, % "xs Hidden Center r4"
		Loop 4
		{
			style := (A_Index = 1) ? "Section xp yp " : "Section xs "
			Gui, %cheatsheet_menu%: Add, Text, % style "hp 0x200 Section Border w"settings.general.fWidth*2 " Center", % A_Index ":"
			Gui, %cheatsheet_menu%: Add, Edit, % "ys hp x+0 Center Border Limit cBlack HWNDhwnd w"settings.general.fWidth*32 (!vars.cheatsheet_menu.entry ? " ReadOnly" : "") ;cont
			, % vars.cheatsheets.list[name].entries[vars.cheatsheet_menu.entry].panels[A_Index]
			vars.hwnd.cheatsheet_menu["panelentry_"A_Index] := hwnd
		}
		If vars.cheatsheet_menu.entry
		{
			Gui, %cheatsheet_menu%: Add, Text, % "Section xs Border Center gCheatsheetMenu2 HWNDhwnd", % " preview "
			vars.hwnd.cheatsheet_menu.preview_sheet := vars.hwnd.help_tooltips["cheatsheets_menu entry-preview"] := hwnd
		}
	}
	
	Gui, %cheatsheet_menu%: Show, % "x10000 y10000"
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.cheatsheet_menu.main
	ControlMove,,,, w + 1 - settings.general.fWidth*2,, % "ahk_id "vars.hwnd.cheatsheet_menu.winbar
	GuiControl, -Hidden, % vars.hwnd.cheatsheet_menu.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.cheatsheet_menu.winx
	GuiControl, -Hidden, % vars.hwnd.cheatsheet_menu.winx
	Sleep 50
	If !Blank(xPos)
		xPos := (xPos + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos, yPos := (yPos + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : yPos
	Gui, %cheatsheet_menu%: Show, % "x"(!Blank(xPos) ? xPos " y"yPos : vars.client.x " y"vars.client.yc - h//2)
	LLK_Overlay(hwnd_old, "destroy")
	If !WinExist("ahk_id "vars.hwnd.snip.main)
		GuiControl, Focus, % vars.hwnd.cheatsheet_menu.name
	Else WinActivate, % "ahk_id "vars.hwnd.snip.main
}

CheatsheetMenuClose()
{
	local
	global vars

	name := vars.cheatsheet_menu.active
	If (vars.cheatsheets.list[name].type = "app") && (LLK_ControlGet(vars.hwnd.cheatsheet_menu.title) = "")
	{
		vars.cheatsheets.list[name].title := ""
		IniWrite, % "", % "cheat-sheets\"name "\info.ini", general, app title
	}
	Else If (vars.cheatsheets.list[name].type = "app") && (LLK_ControlGet(vars.hwnd.cheatsheet_menu.title) != "") && (LLK_ControlGet(vars.hwnd.cheatsheet_menu.title) != "a")
	{
		vars.cheatsheets.list[name].title := LLK_ControlGet(vars.hwnd.cheatsheet_menu.title)
		IniWrite, % vars.cheatsheets.list[name].title, % "cheat-sheets\"name "\info.ini", general, app title
	}
	Else If (vars.cheatsheet_menu.type = "advanced") && (vars.cheatsheet_menu.entry)
		CheatsheetMenuEntrySave()

	Gui, % vars.hwnd.cheatsheet_menu.main ": Destroy"
	SnipGuiClose()
	WinActivate, ahk_group poe_window
	If vars.hwnd.settings.main
		LLK_Overlay(vars.hwnd.settings.main, "show")
}

CheatsheetMenuEntryAdd()
{
	local
	global vars, settings
	
	name := vars.cheatsheet_menu.active
	WinGetPos, x, y,, h, % "ahk_id " vars.hwnd.cheatsheet_menu.entryname
	entryname := LLK_ControlGet(vars.hwnd.cheatsheet_menu.entryname)
	While (SubStr(entryname, 1, 1) = " ")
		entryname := SubStr(entryname, 2)
	While (SubStr(entryname, 0) = " ")
		entryname := SubStr(entryname, 1, -1)
	If !entryname
	{
		LLK_ToolTip("name cannot be blank",, x, y + h,, "red")
		Return
	}
	Loop, Parse, % "general,ui,image search,entries", `,
	{
		If (entryname = A_LoopField)
		{
			LLK_ToolTip("invalid name",, x, y + h,, "red")
			Return
		}
	}
	Loop, Parse, entryname
	{
		If !LLK_IsType(A_LoopField, "alnum")
		{
			LLK_ToolTip("regular letters, spaces,`nand numbers only", 2, x, y + h,, "red")
			Return
		}
	}
	If LLK_IniRead("cheat-sheets\"name "\info.ini", "entries", entryname)
	{
		LLK_ToolTip("name is already in use", 1.5,,,, "red")
		Return
	}
	IniWrite, 1, % "cheat-sheets\"name "\info.ini", entries, % entryname
	vars.cheatsheets.list[name].entries[entryname] := {"panels": [], "ranks": []}
	Loop 4
	{
		IniWrite, % "", % "cheat-sheets\"name "\info.ini", % entryname, panel %A_Index%
		vars.cheatsheets.list[name].entries[entryname].panels.Push("")
		IniWrite, 0, % "cheat-sheets\"name "\info.ini", % entryname, panel %A_Index% rank
		vars.cheatsheets.list[name].entries[entryname].ranks.Push(0)
	}
	CheatsheetMenu(name, 1)
}

CheatsheetMenuEntrySave()
{
	local
	global vars
	
	name := vars.cheatsheet_menu.active
	Loop 4
	{
		vars.cheatsheets.list[name].entries[vars.cheatsheet_menu.entry].panels[A_Index] := LLK_ControlGet(vars.hwnd.cheatsheet_menu["panelentry_"A_Index])
		If (StrReplace(LLK_ControlGet(vars.hwnd.cheatsheet_menu["panelentry_"A_Index]), "`n", "^^^") != LLK_IniRead("cheat-sheets\"name "\info.ini", vars.cheatsheet_menu.entry, "panel "A_Index))
			IniWrite, % """" StrReplace(LLK_ControlGet(vars.hwnd.cheatsheet_menu["panelentry_"A_Index]), "`n", "^^^") """", % "cheat-sheets\"name "\info.ini", % vars.cheatsheet_menu.entry, % "panel " A_Index
	}
}

CheatsheetMenuPaste(index)
{
	local
	global vars
	
	name := vars.cheatsheet_menu.active
	If InStr(Clipboard, ":\",,, 2) && InStr(Clipboard, "`r`n") ;multiple files in clipboard
	{
		If (index = "00")
		{
			LLK_ToolTip("cannot paste multiple`nfiles into index 00", 2,,,, "red")
			Return
		}
		MsgBox, 4, Multiple files in the clipboard, There are multiple files in the clipboard.`nEvery index starting from %index% will be overwritten.`n`nContinue?
		IfMsgBox, No
			Return
		IfMsgBox, Yes
		{
			Loop, Parse, Clipboard, `n, `r
			{
				If !InStr(".bmp.png.jpg", SubStr(A_LoopField, -3))
					continue
				FileCopy, % A_LoopField, % "cheat-sheets\"name "\["index "].*", 1
				index += 1, index := (index < 10) ? "0" index : index
			}
			Return
		}
	}
	Else If InStr(Clipboard, ":\") && InStr(".bmp.png.jpg", SubStr(Clipboard, -3)) ;single img-file in clipboard
		FileCopy, % Clipboard, % "cheat-sheets\"name "\["index "].*", 1
	Else
	{
		pBitmap := Gdip_CreateBitmapFromClipboard()
		If (pBitmap <= 0)
		{
			LLK_ToolTip("couldn't find image-`ndata in clipboard", 1.5,,,, "red")
			Return
		}
		Else
		{
			FileDelete, "cheat-sheets\"name "\["index "]*"
			Gdip_SaveBitmapToFile(pBitmap, "cheat-sheets\"name "\["index "].png", 100)
			Gdip_DisposeImage(pBitmap)
		}
	}
	CheatsheetMenu(name)
}

CheatsheetMenuPreview(name, filename)
{
	local
	global vars, settings

	If !FileExist("cheat-sheets\"name "\"filename)
	{
		LLK_ToolTip("file doesn't exist",,,,, "red")
		KeyWait, LButton
		Return
	}
	Gui, cheatsheet_tooltip: New, -Caption +E0x20 +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd
	Gui, cheatsheet_tooltip: Margin, 0, 0
	Gui, cheatsheet_tooltip: Color, Black
	Gui, cheatsheet_tooltip: Font, % "cWhite s"settings.general.fSize, Fontin SmallCaps
	vars.hwnd.cheatsheet_tooltip := hwnd

	file := ""
	Loop, Files, % "cheat-sheets\"name "\"filename
	{
		If InStr("jpg,bmp,png", A_LoopFileExt)
		{
			file := A_LoopFilePath
			Break
		}
	}
	pBitmap := Gdip_LoadImageFromFile(file)
	If (pBitmap <= 0)
	{
		LLK_ToolTip("cannot load img-file", 1.5,,,, "red")
		Return
	}
	Else
	{
		Gdip_GetImageDimensions(pBitmap, width, height)
		
		If (height > vars.monitor.h*0.9)
		{
			ratio := (vars.monitor.h * 0.9) / height
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, ratio * width, ratio * height, 1, 7)
			Gdip_DisposeImage(pBitmap_copy)
		}
		Else If (width > vars.monitor.w*0.9)
		{
			pBitmap_copy := pBitmap
			pBitmap := Gdip_ResizeBitmap(pBitmap_copy, vars.monitor.w * 0.9, 10000, 1, 7)
			Gdip_DisposeImage(pBitmap_copy)
		}
		
		Gdip_GetImageDimensions(pBitmap, width, height)
		
		hbmBitmap := CreateDIBSection(width, height)
		hdcBitmap := CreateCompatibleDC()
		obmBitmap := SelectObject(hdcBitmap, hbmBitmap)
		gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
		Gdip_SetInterpolationMode(gBitmap, 0)
		Gdip_DrawImage(gBitmap, pBitmap, 0, 0, width, height, 0, 0, width, height, 1)
		Gui, cheatsheet_tooltip: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmBitmap%
		SelectObject(hdcBitmap, obmBitmap)
		DeleteObject(hbmBitmap)
		DeleteDC(hdcBitmap)
		Gdip_DeleteGraphics(gBitmap)
		Gdip_DisposeImage(pBitmap)

		Gui, cheatsheet_tooltip: Show, NA x10000 y10000
		WinGetPos,,, width, height, % "ahk_id " vars.hwnd.cheatsheet_tooltip
		xPos := (vars.general.xMouse - vars.client.x + vars.client.w/100 + width > vars.client.w) ? vars.client.x + vars.client.w - width : vars.general.xMouse + vars.client.w/100
		yPos := (vars.general.yMouse - vars.client.y + height/2 > vars.client.h) ? vars.client.y + vars.client.h - height ;cont
		: (vars.general.yMouse - vars.client.y - height/2 < vars.client.y) ? vars.client.y : vars.general.yMouse - height/2
		Gui, cheatsheet_tooltip: Show, NA x%xPos% y%yPos%
	}
	KeyWait, LButton
	Gui, cheatsheet_tooltip: Destroy
	vars.hwnd.Delete("cheatsheet_tooltip")
}
/*
CheatsheetMenuSnip(index)
{
	local
	global vars, settings

	name := vars.cheatsheet_menu.active
	KeyWait, LButton
	If (index = "00") || FileExist("cheat-sheets\"name "\[00]*")
	{
		If !WinExist("ahk_id " vars.hwnd.cheatsheet_snip.main)
		{
			Gui, cheatsheet_snip: New, -DPIScale +LastFound +ToolWindow +AlwaysOnTop +Resize HWNDhwnd, Lailloken UI: snipping widget
			Gui, cheatsheet_snip: Color, Aqua
			WinSet, trans, 100
			vars.hwnd.cheatsheet_snip := {"main": hwnd}
			
			Gui, cheatsheet_snip: Add, Picture, % "x"settings.general.fWidth*5 " y"settings.general.fHeight*2 " h"settings.general.fHeight " w-1 BackgroundTrans gSettings_help HWNDhwnd", img\GUI\help.png
			vars.hwnd.cheatsheet_snip.help := hwnd
			If vars.snip.w
				Gui, cheatsheet_snip: Show, % "w"vars.snip.w " h"vars.snip.h
			Else Gui, cheatsheet_snip: Show, % "w"settings.general.fWidth*31 " h"settings.general.fHeight*11
			Return
		}
	}
	Else
	{
		If WinExist("ahk_id " hwnd_snip)
			cheatsheet_snipGUIClose()
	}
	
	vars.general.gui_hide := 1
	LLK_Overlay("hide")
	Gui, cheatsheet_menu: Hide

	If (index = "00") || FileExist("cheat-sheets\"name "\[00]*")
	{
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.cheatsheet_snip.main
		Gui, cheatsheet_snip: Hide
		sleep 100
		pBitmap := Gdip_BitmapFromScreen(x + vars.system.xborder "|" y + vars.system.yborder + vars.system.caption "|" w - vars.system.xborder*2 "|" h - vars.system.yborder*2 - vars.system.caption)
		Gui, cheatsheet_snip: Show
	}
	Else
	{
		Clipboard := ""
		SendInput, #+{s}
		WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
		WinWaitNotActive, ahk_exe ScreenClippingHost.exe
		pBitmap := Gdip_CreateBitmapFromClipboard()
	}

	vars.general.gui_hide := 0
	Gui, cheatsheet_menu: Show, NA
	If (pBitmap <= 0)
	{
		LLK_ToolTip("screen-cap failed",,,,, "red")
		Return
	}
	Else
	{
		FileDelete, % "cheat-sheets\"name "\["index "]*"
		Gdip_SaveBitmapToFile(pBitmap, "cheat-sheets\"name "\["index "].png", 100)
		Gdip_DisposeImage(pBitmap)
		CheatsheetMenu(name)
	}
	If WinExist("ahk_id "vars.hwnd.cheatsheet_snip.main)
		WinActivate, % "ahk_id "vars.hwnd.cheatsheet_snip.main
}
*/

CheatsheetMenuTag(cHWND, index)
{
	local
	global vars
	
	key := LLK_ControlGet(cHWND), name := vars.cheatsheet_menu.active
	WinGetPos, x, y, w,, % "ahk_id "cHWND

	If key && (!LLK_IsType(key, "alpha") || (key = " "))
	{
		LLK_ToolTip("regular letters only", 1.5, x + w, y,, "red")
		GuiControl,, % cHWND, % ""
		Return
	}
	If FileExist("cheat-sheets\"name "\*] "key ".*")
	{
		LLK_ToolTip("hotkey already in use", 1.5, x + w, y,, "red")
		GuiControl,, % cHWND, % ""
		Return
	}

	If key
		FileMove, % "cheat-sheets\"name "\["index "]*", % "cheat-sheets\"name "\["index "] "key ".*", 1
	Else FileMove, % "cheat-sheets\"name "\["index "]*", % "cheat-sheets\"name "\["index "].*", 1
}

CheatsheetRank()
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.cheatsheet, vars.general.cMouse), name := vars.cheatsheets.active.name, control := StrReplace(check, "panel"), rank := (A_ThisHotkey = "space") ? 0 : A_ThisHotkey, entry := vars.cheatsheets.entry
	If InStr(check, "panel")
	{
		vars.cheatsheets.list[name].entries[entry].ranks[control] := rank
		IniWrite, % rank, % "cheat-sheets\"name "\info.ini", % entry, % "panel "control " rank"
		GuiControl, % "+c"settings.cheatsheets.colors[rank], % vars.general.cMouse
		GuiControl, % "movedraw", % vars.general.cMouse
	}
}

CheatsheetSearch(name)
{
	local
	global vars

	If !FileExist("cheat-sheets\"name "\[check].bmp") ;return 0 if reference img-file is missing
	{
		If (A_Gui = DummyGUI(vars.hwnd.settings.main))
			LLK_ToolTip("calibrate first",,,,, "yellow")
		Return 0
	}
	
	If !vars.cheatsheets.list[name].x1 && (A_Gui != vars.hwnd.settings.main) ;return 0 if check has not been tested before
		Return 0
	
	pHaystack := (A_Gui = DummyGUI(vars.hwnd.settings.main)) ? Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1) : vars.cheatsheets.pHaystack
	If (A_Gui = DummyGUI(vars.hwnd.settings.main)) ;search whole client-area if search was initiated from settings menu
		x1 := 0, y1 := 0, x2 := 0, y2 := 0
	Else ;otherwise, load last-known coordinates
	{
		x1 := (vars.cheatsheets.list[name].area = "static") ? vars.cheatsheets.list[name].x1 : (vars.cheatsheets.list[name].x1 - 100 <= 0) ? 0 : vars.cheatsheets.list[name].x1 - 100
		y1 := (vars.cheatsheets.list[name].area = "static") ? vars.cheatsheets.list[name].y1 : (vars.cheatsheets.list[name].y1 - 100 <= 0) ? 0 : vars.cheatsheets.list[name].y1 - 100
		x2 := (vars.cheatsheets.list[name].area = "static") ? vars.cheatsheets.list[name].x1 + vars.cheatsheets.list[name].x2 ;cont
		: (vars.cheatsheets.list[name].x1 + vars.cheatsheets.list[name].x2 + 100 >= vars.client.w) ? vars.client.w - 1 : vars.cheatsheets.list[name].x1 + vars.cheatsheets.list[name].x2 + 100
		y2 := (vars.cheatsheets.list[name].area = "static") ? vars.cheatsheets.list[name].y1 + vars.cheatsheets.list[name].y2 ;cont
		: (vars.cheatsheets.list[name].y1 + vars.cheatsheets.list[name].y2 + 100 >= vars.client.h) ? vars.client.h - 1 : vars.cheatsheets.list[name].y1 + vars.cheatsheets.list[name].y2 + 100
	}

	pNeedle := Gdip_CreateBitmapFromFile("cheat-sheets\"name "\[check].bmp") ;load reference img-file that will be searched for in the screenshot
	If (pNeedle <= 0)
	{
		MsgBox, % "The reference bmp-file could not be loaded correctly.`n`nYou should recalibrate this sheet: " name
		Gdip_DisposeImage(pHaystack)
		Return 0
	}
	If (Gdip_ImageSearch(pHaystack, pNeedle, LIST, x1, y1, x2, y2, vars.imagesearch.variation,, 1, 1) > 0) ;reference img-file was found in the screenshot
	{
		If (A_Gui = DummyGUI(vars.hwnd.settings.main)) ;if search was initiated from settings menu, save positive coordinates
		{
			Gdip_GetImageDimension(pNeedle, width, height) ;get dimensions of the reference img-file
			IniWrite, % LIST "," Format("{:0.0f}", width) "," Format("{:0.0f}", height), % "cheat-sheets\"name "\info.ini", image search, last coordinates ;write string to ini-file
		}
		Gdip_DisposeImage(pNeedle) ;clear reference-img file from memory
		If (A_Gui = DummyGUI(vars.hwnd.settings.main))
			Gdip_DisposeImage(pHaystack) ;clear screenshot from memory
		Return 1
	}
	Gdip_DisposeImage(pNeedle)
	If (A_Gui = DummyGUI(vars.hwnd.settings.main))
	{
		LLK_ToolTip("negative",,,,, "Red")
		Gdip_DisposeImage(pHaystack)
	}
	Return 0
}

CheatsheetTAB()
{
	local
	global vars, settings

	If FileExist("cheat-sheets\"vars.cheatsheets.active.name "\[00].*")
	{
		CheatsheetImage("", settings.hotkeys.tab)
		KeyWait, % A_ThisHotkey
		vars.cheatsheets[vars.cheatsheets.active.name].include := []
		For key, val in vars.cheatsheets[vars.cheatsheets.active.name].include0
			vars.cheatsheets[vars.cheatsheets.active.name].include.Push(val)
		CheatsheetImage()
	}
	KeyWait, % A_ThisHotkey
}
