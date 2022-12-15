Init_sanctum:
IniRead, sanctum_rooms_ini, data\sanctum.ini, Rooms,, %A_Space%
sanctum_rooms := {}
Loop, Parse, sanctum_rooms_ini, `n
{
	If (A_LoopField = "")
		continue
	parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
	sanctum_rooms[StrReplace(parse, " ", "_")] := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
}
Return

Sanctum:
If (A_Gui = "sanctum_setup")
	Gui, sanctum_setup: Submit, NoHide
sanctum_hotkey := StrReplace(A_ThisHotkey, "*")
sanctum_hotkey := StrReplace(sanctum_hotkey, "~")

If InStr(A_GuiControl, "sanctum_choice_")
{
	KeyWait, LButton
	sanctum_choice := StrReplace(A_GuiControl, "sanctum_choice_")
	sanctum_choice := StrReplace(A_GuiControl, "sanctum_choice_")
	If (sanctum_choice != "abort")
		Gdip_SaveBitmapToFile(pSanctum_screencap, "img\Recognition (" poe_height "p)\Sanctum\" sanctum_choice ".bmp", 100)
	sanctum_choice := ""
	SelectObject(hdcSanctum_screencap, obmSanctum_screencap)
	DeleteObject(hbmSanctum_screencap)
	DeleteDC(hdcSanctum_screencap)
	Gdip_DeleteGraphics(gSanctum_screencap)
	Gdip_DisposeImage(pSanctum_screencap)
	Gui, sanctum_setup: Destroy
	hwnd_sanctum_setup := 2
	Gui, sanctum_setup2: Destroy
	hwnd_sanctum_setup2 := 2
	Return
}

If GetKeyState("RButton", "P")
{
	Clipboard := ""
	sanctum_edit := ""
	sanctum_screencap := 0
	SendInput, +#{s}
	Sleep, 1000
	WinWaitActive, ahk_group poe_window
	pSanctum_screencap := Gdip_CreateBitmapFromClipboard()
	If (pSanctum_screencap < 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		sanctum_screencap := 1
		;pSanctum_screencap := Gdip_CreateBitmapFromClipboard()
		Clipboard := ""
		Gdip_GetImageDimensions(pSanctum_screencap, wSanctum_screencap, hSanctum_screencap)
		hbmSanctum_screencap := CreateDIBSection(wSanctum_screencap, hSanctum_screencap)
		hdcSanctum_screencap := CreateCompatibleDC()
		obmSanctum_screencap := SelectObject(hdcSanctum_screencap, hbmSanctum_screencap)
		gSanctum_screencap := Gdip_GraphicsFromHDC(hdcSanctum_screencap)
		Gdip_SetInterpolationMode(gSanctum_screencap, 0)
		Gdip_DrawImage(gSanctum_screencap, pSanctum_screencap, 0, 0, wSanctum_screencap, hSanctum_screencap, 0, 0, wSanctum_screencap, hSanctum_screencap, 1)
	}
}

If sanctum_screencap
{
	Gui, sanctum_setup: Submit, NoHide
	Gui, sanctum_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_sanctum_setup, Lailloken UI: Sanctum screen-cap
	Gui, sanctum_setup: Margin, 12, 4
	Gui, sanctum_setup: Color, Black
	WinSet, Transparent, %trans%
	Gui, sanctum_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
	Gui, sanctum_setup: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmSanctum_screencap%
	Gui, sanctum_setup: Add, Edit, ys BackgroundTrans cBlack vSanctum_edit gSanctum HWNDmain_text, % sanctum_edit
	LLK_Overlay("sanctum_setup", "show", 0)
	WinGetPos, sanctum_xPos, sanctum_yPos, sanctum_w, sanctum_h, ahk_id %hwnd_sanctum_setup%
}

If (A_GuiControl = "sanctum_edit") && (StrLen(sanctum_edit) >= 2) || sanctum_screencap || (A_GuiControl = "sanctum_edit") && (StrLen(sanctum_edit) <= 1)
{
	sanctum_screencap := 0
	sanctum_matches := 0
	Gui, sanctum_setup2: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_sanctum_setup2, Lailloken UI: Sanctum screen-cap
	Gui, sanctum_setup2: Margin, 12, 4
	Gui, sanctum_setup2: Color, Black
	WinSet, Transparent, %trans%
	Gui, sanctum_setup2: Font, % "s"fSize0 " cWhite underline", Fontin SmallCaps
	If (A_GuiControl = "sanctum_edit") && (StrLen(sanctum_edit) >= 2)
	{
		For parse_room, parse_description in sanctum_rooms
		{
			If (sanctum_edit = SubStr(StrReplace(parse_room, "_", " "), 1, StrLen(sanctum_edit)))
			{
				Gui, sanctum_setup2: Add, Text, % "BackgroundTrans gSanctum vSanctum_choice_"parse_room, % StrReplace(parse_room, "_", " ")
				sanctum_matches += 1
			}
		}
	}
	If !sanctum_matches
		Gui, sanctum_setup2: Add, Text, % "BackgroundTrans gSanctum vsanctum_choice_abort", % "abort screen-cap"
	Gui, sanctum_setup2: Show, % "NA x10000 y10000"
	WinGetPos,,, sanctum_w2, sanctum_h2, ahk_id %hwnd_sanctum_setup2%
	Gui, sanctum_setup2: Show, % "NA x"sanctum_xPos + sanctum_w - sanctum_w2 " y"sanctum_yPos + sanctum_h
	Return
}

While GetKeyState(sanctum_hotkey, "P")
{
	sanctum_room := ""
	MouseGetPos, sanctum_mouseX, sanctum_mouseY
	sanctum_mouseX -= xScreenOffset
	sanctum_mouseY -= yScreenOffset
	If (sanctum_mouseX = sanctum_mouseX_old && sanctum_mouseY = sanctum_mouseY_old)
	{
		sleep, 100
		continue
	}
	sanctum_mouseX_old := sanctum_mouseX
	sanctum_mouseY_old := sanctum_mouseY
	pHaystack_sanctum := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop, Files, img\Recognition (%poe_height%p)\Sanctum\*.bmp
	{
		pNeedle_sanctum := Gdip_CreateBitmapFromFile(A_LoopFilePath)
		Gdip_GetImageDimensions(pNeedle_sanctum, sanctum_needle_w, sanctum_needle_h)
		sanctum_search_x1 := (sanctum_mouseX - poe_width/8 < 0) ? 0 : sanctum_mouseX - poe_width/8
		sanctum_search_y1 := (sanctum_mouseY - poe_height/4 < 0) ? 0 : sanctum_mouseY - poe_height/4
		sanctum_search_x2 := (sanctum_mouseX + poe_width/8 > poe_width) ? poe_width : sanctum_mouseX + poe_width/8
		sanctum_search_y2 := sanctum_mouseY
		pSearch_sanctum := Gdip_ImageSearch(pHaystack_sanctum, pNeedle_sanctum, sanctum_matches, sanctum_search_x1, sanctum_search_y1, sanctum_search_x2, sanctum_search_y2, imagesearch_variation + 10,, 1, 1)
		Gdip_DisposeImage(pNeedle_sanctum)
		Gdip_DisposeImage(pSearch_sanctum)
		If (pSearch_sanctum > 0)
		{
			sanctum_room := StrReplace(A_LoopFileName, ".bmp")
			sanctum_needle_x := SubStr(sanctum_matches, 1, InStr(sanctum_matches, ",") - 1)
			sanctum_needle_y := SubStr(sanctum_matches, InStr(sanctum_matches, ",") + 1)
			Break
		}
	}
	Gdip_DisposeImage(pHaystack_sanctum)
	If !sanctum_room
	{
		sanctum_needle_x_old := ""
		sanctum_needle_y_old := ""
		Gui, sanctum_tooltip: Destroy
		hwnd_sanctum_tooltip := ""
	}
	If sanctum_room && (sanctum_needle_y != sanctum_needle_y_old || sanctum_needle_x != sanctum_needle_x_old)
	{
		sanctum_needle_x_old := sanctum_needle_x
		sanctum_needle_y_old := sanctum_needle_y
		Gui, sanctum_tooltip: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_sanctum_tooltip, Lailloken UI: Sanctum screen-cap
		Gui, sanctum_tooltip: Margin, 0, 0
		Gui, sanctum_tooltip: Color, Black
		WinSet, Transparent, %trans%
		Gui, sanctum_tooltip: Font, % "s"fSize0+2 " cWhite", Fontin SmallCaps
		Gui, sanctum_tooltip: Add, Text, % "BackgroundTrans cAqua Center", % " "sanctum_rooms[sanctum_room] " "
		Gui, sanctum_tooltip: Show, % "NA x10000 y10000"
		WinGetPos,,, sanctum_tooltip_w
		Gui, sanctum_tooltip: Show, % "NA x"xScreenOffset + sanctum_needle_x + sanctum_needle_w/2 - sanctum_tooltip_w/2 " y"yScreenOffset + sanctum_needle_y + sanctum_needle_h
	}
	sleep, 100
}
sanctum_needle_x_old := ""
sanctum_needle_y_old := ""
Gui, sanctum_tooltip: Destroy
hwnd_sanctum_tooltip := ""
Return

Settings_menu_sanctum:
settings_menu_section := "sanctum"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki">wiki page</a>

Return