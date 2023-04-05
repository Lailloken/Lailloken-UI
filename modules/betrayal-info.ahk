Betrayal_apply:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "settings_enable_betrayal")
{
	If !%A_GuiControl%
	{
		LLK_Overlay("betrayal_info", "hide")
		LLK_Overlay("betrayal_info_overview", "hide")
		LLK_Overlay("betrayal_info_members", "hide")
		Loop, Parse, betrayal_divisions, `,, `,
			LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")
	}
	IniWrite, % %A_GuiControl%, ini\config.ini, Features, enable betrayal-info
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "image_folder")
{
	Run, explore img\Recognition (%poe_height%p)\Betrayal\
	Return
}
If (A_GuiControl = "betrayal_perma_table")
{
	IniWrite, % %A_GuiControl%, ini\betrayal info.ini, Settings, permanent table
	Return
}
If (A_GuiControl = "betrayal_info_table_pos")
{
	IniWrite, % %A_GuiControl%, ini\betrayal info.ini, Settings, table-position
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_info_prio_apply")
{
	IniWrite, % betrayal_info_prio_dimensions, ini\betrayal info.ini, Settings, prioview-dimensions
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "betrayal_info_prio_dimensions")
{
	%A_GuiControl% := (%A_GuiControl% < 50) ? 50 : %A_GuiControl%
	GoSub, GUI_betrayal_prioview
	Return
}
If (A_GuiControl = "fSize_betrayal_minus")
{
	fSize_offset_betrayal -= 1
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "fSize_betrayal_plus")
{
	fSize_offset_betrayal += 1
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "fSize_betrayal_reset")
{
	fSize_offset_betrayal := 0
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_opac_minus")
{
	betrayal_trans -= (betrayal_trans > 100) ? 30 : 0
	IniWrite, %betrayal_trans%, ini\betrayal info.ini, Settings, transparency
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_opac_plus")
{
	betrayal_trans += (betrayal_trans < 250) ? 30 : 0
	IniWrite, %betrayal_trans%, ini\betrayal info.ini, Settings, transparency
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_enable_recognition")
{
	IniWrite, %betrayal_enable_recognition%, ini\betrayal info.ini, Settings, enable image recognition
	If (%A_GuiControl% = 1)
	{
		Gui, betrayal_info_members: Destroy
		hwnd_betrayal_info_members := ""
	}
	GoSub, Betrayal_info
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "betrayal_ddl")
{
	Gui, betrayal_setup: Submit
	If (betrayal_ddl != "abort screen-cap")
		test := Gdip_SaveBitmapToFile(pBetrayal_screencap, "img\Recognition (" poe_height "p)\Betrayal\" betrayal_ddl ".bmp", 100)
	Gdip_DisposeImage(test)
	Return
}
If InStr(A_GuiControl, "betrayal_info_combo_")
{
	betrayal_clicks := (betrayal_clicks = "") ? 0 : betrayal_clicks
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	WinGetPos,,, wMembers,, ahk_id %hwnd_betrayal_info_members%
	If InStr(A_GuiControl, parse_member1) && (parse_member1 != "") && (betrayal_clicks != 0)
	{
		LLK_ToolTip("same member selected twice")
		Return
	}
	If InStr(A_GuiControl, parse_division2) && (parse_division2 != "")
	{
		LLK_ToolTip("same division selected twice")
		Return
	}
	If (betrayal_clicks = 0)
	{
		parse_member1 := StrReplace(A_GuiControl, "betrayal_info_combo_")
		parse_division2 := SubStr(parse_member1, InStr(parse_member1, "_") + 1)
		parse_member1 := SubStr(parse_member1, 1, InStr(parse_member1, "_") - 1)
	}
	Else
	{
		parse_member2 := StrReplace(A_GuiControl, "betrayal_info_combo_")
		parse_division1 := SubStr(parse_member2, InStr(parse_member2, "_") + 1)
		parse_member2 := SubStr(parse_member2, 1, InStr(parse_member2, "_") - 1)
	}
	ToolTip, % parse_member1 " moves to " parse_division2, % wMembers + xScreenOffSet,
	betrayal_clicks += 1
	If (betrayal_clicks = 2)
	{
		ToolTip,,,,
		GoSub, Betrayal_search
		betrayal_clicks := 0
		parse_member1 := ""
		parse_member2 := ""
		parse_division1 := ""
		parse_division2 := ""
		betrayal_layout1 := ""
	}
	Return
}
If InStr(A_GuiControl, "betrayal_info_member_")
{
	ToolTip,,,,
	betrayal_clicks := 0
	parse_division1 := ""
	betrayal_info_click_member := StrReplace(A_GuiControl, "betrayal_info_member_")
	betrayal_info_click_member2 := ""
	parse_member2 := ""
	GoSub, Betrayal_search
	Return
}

check := 0
Loop, Parse, betrayal_list, `n, `n
	check += InStr(A_GuiControl, A_Loopfield) ? 1 : 0
If (check = 0)
	Return

parse_member := SubStr(A_GuiControl, InStr(A_GuiControl, "_",,, 3) + 1)
parse_member := SubStr(parse_member, 1, InStr(parse_member, "_",,, 1) - 1)
parse_division := SubStr(A_GuiControl, InStr(A_GuiControl, "_",,, 4) + 1)
parse_gui := SubStr(A_GuiControl, 1, InStr(A_GuiControl, "_",,, 3) - 3)
betrayal_%parse_member%_%parse_division% := (betrayal_%parse_member%_%parse_division% = "") ? 1 : betrayal_%parse_member%_%parse_division%
If (click != 2)
	betrayal_%parse_member%_%parse_division% -= (betrayal_%parse_member%_%parse_division% < 4) ? -1 : 2
Else betrayal_%parse_member%_%parse_division% := (betrayal_%parse_member%_%parse_division% = 1) ? 5 : 1
color := betrayal_color[betrayal_%parse_member%_%parse_division%]
IniWrite, % betrayal_%parse_member%_%parse_division%, ini\betrayal info.ini, %parse_member%, %parse_division%
GuiControl, +c%color%, %A_GuiControl%
WinSet, Redraw,, % "ahk_id " hwnd_%parse_gui%
WinActivate, ahk_group poe_window
Return

Betrayal_info:
If (betrayal_list_width = "")
{
	Gui, betrayal_info_members: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_members
	Gui, betrayal_info_members: Margin, 0, 0
	Gui, betrayal_info_members: Color, Black
	WinSet, Transparent, %betrayal_trans%
	Gui, betrayal_info_members: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps
	Gui, betrayal_info_members: Add, Text, BackgroundTrans Center Border HWNDgravicius, % " gravicius "
	Gui, betrayal_info_members: Add, Text, BackgroundTrans Center Border HWNDgravicius_t, % " t"
	Gui, betrayal_info_members: Show, Hide
	ControlGetPos,,, betrayal_list_width, betrayal_list_height,, ahk_id %gravicius%
	ControlGetPos,,, tWidth,,, ahk_id %gravicius_t%
	While (Mod(betrayal_list_width, 4) != 0)
		betrayal_list_width += 1
}

If (betrayal_perma_table = 1) || (betrayal_scan_failed = 1) || (betrayal_enable_recognition = 0) || (Gui_copy != "")
{	
	Gui, betrayal_info_members: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_members
	Gui, betrayal_info_members: Margin, 0, 0
	Gui, betrayal_info_members: Color, Black
	WinSet, Transparent, %betrayal_trans%
	Gui, betrayal_info_members: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps
	Loop, Parse, betrayal_divisions, `,, `,
		%A_Loopfield%_t0 := 0
	Loop, Parse, betrayal_list, `n, `n
	{
		color := (A_Loopfield = betrayal_info_click_member) || (A_Loopfield = betrayal_info_click_member2) || (A_Loopfield = parse_member1) || (A_LoopField = parse_member2) ? "Fuchsia" : "White"
		style := (A_Index != 1) ? "y+-1" : ""
		Gui, betrayal_info_members: Add, Text, % "xs " style " Section BackgroundTrans Left Border vbetrayal_info_member_" A_Loopfield " gBetrayal_apply w"betrayal_list_width " c"color, % " " A_Loopfield " "
		check := A_Loopfield
		Loop, Parse, betrayal_divisions, `,, `,
		{
			IniRead, rank, ini\betrayal info.ini, % check, % A_Loopfield, 1
			color := (rank = 1) ? "Black" : betrayal_color[rank]
			Gui, betrayal_info_members: Add, Progress, % "ys x+-1 Disabled Background"color " w"tWidth " hp"
			color := (color = "Black") ? "White" : "Black"
			%A_Loopfield%_t0 += (rank = 5) ? 1 : 0
			If (check = "Vorici")
			{
				Gui, betrayal_info_members: Add, Text, % "Section xp yp wp hp BackgroundTrans vbetrayal_info_combo_" check "_" A_Loopfield " Border gBetrayal_apply Center c"color, % SubStr(A_Loopfield, 1, 1)
				Gui, betrayal_info_members: Add, Text, % "xs y+-1 wp hp BackgroundTrans Border Center cAqua", % %A_Loopfield%_t0
			}
			Else Gui, betrayal_info_members: Add, Text, % "xp yp wp hp BackgroundTrans vbetrayal_info_combo_" check "_" A_Loopfield " Border gBetrayal_apply Center c"color, % SubStr(A_Loopfield, 1, 1)
			Gui, betrayal_info_members: Font, % "s"fSize0 + fSize_offset_betrayal " norm"
		}
	}
	Gui, betrayal_info_members: Show, Hide
	WinGetPos,,, width, height
	If (betrayal_info_table_pos = "left")
		Gui, betrayal_info_members: Show, % "NA x"xScreenOffSet " y"yScreenOffSet + (poe_height - height)/2
	Else Gui, betrayal_info_members: Show, % "NA x"xScreenOffSet + poe_width - width " y"yScreenOffSet + (poe_height - height)/2
	LLK_Overlay("betrayal_info_members", "show")
}

If WinExist("ahk_id " hwnd_betrayal_info_members) && (betrayal_perma_table = 0) && (betrayal_scan_failed = 0) && (betrayal_enable_recognition = 1) && (Gui_copy = "")
	LLK_Overlay("betrayal_info_members", "hide")

Gui, betrayal_info: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info
Gui, betrayal_info: Margin, 0, 0
Gui, betrayal_info: Color, Black
WinSet, Transparent, %betrayal_trans%
Gui, betrayal_info: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps

Gui, betrayal_info_overview: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_overview
Gui, betrayal_info_overview: Margin, 0, 0
Gui, betrayal_info_overview: Color, Black
WinSet, Transparent, %betrayal_trans%
Gui, betrayal_info_overview: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps

Loop, Parse, betrayal_divisions, `,, `,
{
	If (betrayal_layout = 1)
	{
		IniRead, betrayal_%betrayal_member%_%A_Loopfield%, ini\betrayal info.ini, % betrayal_member, % A_Loopfield, 1
		color := betrayal_color[betrayal_%betrayal_member%_%A_Loopfield%]
		If (parse_division1 = A_Loopfield)
		{
			Gui, betrayal_info: Add, Progress, % "ys Disabled Background303030 Center w"poe_width/4 " h"betrayal_list_height*2 - 2
			Gui, betrayal_info: Add, Text, % "xp yp Section BackgroundTrans Center Border vbetrayal_info_" A_Index "_" betrayal_member "_" A_Loopfield " gBetrayal_apply w"poe_width/4 " c"color, % %A_Loopfield%_text
		}
		Else Gui, betrayal_info: Add, Text, % "ys Section BackgroundTrans Center Border vbetrayal_info_" A_Index "_" betrayal_member "_" A_Loopfield " gBetrayal_apply w"poe_width/4 " c"color, % %A_Loopfield%_text
	}
	Else
	{
		ToolTip,,,,
		If (A_Index < 3)
		{
			betrayal_member := parse_member1
			betrayal_division := (A_Index = 1) ? parse_division1 : parse_division2
		}
		Else
		{
			betrayal_member := parse_member2
			betrayal_division := (A_Index = 3) ? parse_division2 : parse_division1
		}
		If (A_Index = 3)
		{
			Loop, Parse, betrayal_divisions, `,, `,
			{
				IniRead, rank, ini\betrayal info.ini, % betrayal_member, % A_LoopField, 1
				Gui, betrayal_info_overview: Add, Progress, % "ys Section w"poe_width//8 " h" betrayal_list_height//3 " disabled background"betrayal_color[rank]
				Gui, betrayal_info_overview: Add, Text, % "hp wp xp yp border BackgroundTrans", % A_Space
			}
		}
		If (A_Index = 1)
		{
			Loop, Parse, betrayal_divisions, `,, `,
			{
				IniRead, rank, ini\betrayal info.ini, % betrayal_member, % A_LoopField, 1
				Gui, betrayal_info_overview: Add, Progress, % "ys Section w"poe_width//8 " h" betrayal_list_height//3 " disabled background"betrayal_color[rank]
				Gui, betrayal_info_overview: Add, Text, % "hp wp xp yp border BackgroundTrans", % A_Space
			}
		}
		IniRead, betrayal_%betrayal_member%_%betrayal_division%, ini\betrayal info.ini, %betrayal_member%, %betrayal_division%, 1
		color := betrayal_color[betrayal_%betrayal_member%_%betrayal_division%]
		Gui, betrayal_info: Add, Text, % "ys Section BackgroundTrans Border Center vbetrayal_info_" A_Index "_" betrayal_member "_" betrayal_division " gBetrayal_apply w"poe_width/4 " c"color, % panel%A_Index%_text
	}
}

Gui, betrayal_info: Show, % "NA y" yScreenOffSet " x" xScreenOffSet
WinGetPos,,,, height, ahk_id %hwnd_betrayal_info%
LLK_Overlay("betrayal_info", "show")

If (betrayal_layout = 2)
{
	Gui, betrayal_info_overview: Show, % "NA x" xScreenOffSet " y"yScreenOffset + height
	LLK_Overlay("betrayal_info_overview", "show")
}
Return

Betrayal_prio_drag:
While GetKeyState("LButton", "P")
{
	MouseGetPos, mouseXpos, mouseYpos
	style := StrReplace(A_GuiControl, "prio_")
	Gui, betrayal_prioview_%style%: Show, NA x%mouseXpos% y%mouseYpos%
}
%style%_xcoord := mouseXpos - xScreenOffSet
%style%_ycoord := mouseYpos - yScreenOffSet
betrayal_info_%A_GuiControl% := %style%_xcoord "," %style%_ycoord
IniWrite, % betrayal_info_%A_GuiControl%, ini\betrayal info.ini, Settings, %style% coords
Return

Betrayal_search:
start := A_TickCount
Gui_copy := A_Gui

While GetKeyState(ThisHotkey_copy, "P")
{
	LLK_Overlay("betrayal_info_members", "hide")
	If (A_TickCount >= start + 200)
	{
		If (betrayal_info_prio_transportation = "0,0") || (betrayal_info_prio_fortification = "0,0") || (betrayal_info_prio_research = "0,0") || (betrayal_info_prio_intervention = "0,0") || (betrayal_info_prio_dimensions = 0)
		{
			LLK_ToolTip("betrayal prio-view not set up", 2)
			KeyWait, % ThisHotkey_copy
			LLK_Overlay("betrayal_info_members", "show")
			Return
		}
		Gui, betrayal_prioview: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_prioview
		Gui, betrayal_prioview: Margin, 0, 0
		Gui, betrayal_prioview: Color, Black
		WinSet, TransColor, Black
		Loop, Parse, betrayal_divisions, `,, `,
		{
			check := A_Loopfield
			pics_added := 0
			Loop, Parse, betrayal_list, `n, `n
			{
				IniRead, rank, ini\betrayal info.ini, % A_LoopField, % check, 1
				If (rank = 5)
				{
					If (pics_added = 6)
						break
					If (pics_added = 0)
						Gui, betrayal_prioview: Add, Picture, % "Section BackgroundTrans x" %check%_xcoord - betrayal_info_prio_dimensions/4 " y"%check%_ycoord - betrayal_info_prio_dimensions/2 " w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					Else If (pics_added = 3)
						Gui, betrayal_prioview: Add, Picture, % "Section BackgroundTrans x" %check%_xcoord - betrayal_info_prio_dimensions/4 " y"%check%_ycoord + betrayal_info_prio_dimensions " w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					Else Gui, betrayal_prioview: Add, Picture, % "ys BackgroundTrans  w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					pics_added += 1
				}
			}
		}
		Gui, betrayal_prioview: Show, NA x%xScreenOffSet% y%yScreenOffSet% w%poe_width%
		KeyWait, % ThisHotkey_copy
		If (betrayal_perma_table = 1) || (betrayal_enable_recognition = 0)
			LLK_Overlay("betrayal_info_members", "show")
		Gui, betrayal_prioview: Destroy
		Return
	}
}

If GetKeyState("RButton", "P") && (betrayal_enable_recognition = 1)
{
	Clipboard := ""
	SendInput, +#{s}
	WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
	WinWaitNotActive, ahk_exe ScreenClippingHost.exe
	pBetrayal_screencap := Gdip_CreateBitmapFromClipboard()
	If (pBetrayal_screencap < 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		Gdip_GetImageDimensions(pBetrayal_screencap, wBetrayal_screencap, hBetrayal_screencap)
		hbmBetrayal_screencap := CreateDIBSection(wBetrayal_screencap, hBetrayal_screencap)
		hdcBetrayal_screencap := CreateCompatibleDC()
		obmBetrayal_screencap := SelectObject(hdcBetrayal_screencap, hbmBetrayal_screencap)
		gBetrayal_screencap := Gdip_GraphicsFromHDC(hdcBetrayal_screencap)
		Gdip_SetInterpolationMode(gBetrayal_screencap, 0)
		Gdip_DrawImage(gBetrayal_screencap, pBetrayal_screencap, 0, 0, wBetrayal_screencap, hBetrayal_screencap, 0, 0, wBetrayal_screencap, hBetrayal_screencap, 1)
	}
	Gui, betrayal_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_betrayal_setup, Lailloken UI: Betrayal screen-cap
	Gui, betrayal_setup: Margin, 12, 4
	Gui, betrayal_setup: Color, Black
	WinSet, Transparent, %trans%
	Gui, betrayal_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
	Gui, betrayal_setup: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmBetrayal_screencap%
	Gui, betrayal_setup: Add, DDL, ys BackgroundTrans cBlack vBetrayal_ddl Choose1 gBetrayal_apply HWNDmain_text, % "abort screen-cap||transportation|fortification|research|intervention|" StrReplace(betrayal_list, "`n", "|")
	LLK_Overlay("betrayal_setup", "show", 0)
	WinWaitActive, ahk_group poe_window
	SelectObject(hdcBetrayal_screencap, obmBetrayal_screencap)
	DeleteObject(hbmBetrayal_screencap)
	DeleteDC(hdcBetrayal_screencap)
	Gdip_DeleteGraphics(gBetrayal_screencap)
	Gdip_DisposeImage(pBetrayal_screencap)
	Gui, betrayal_setup: Destroy
	Return
}

If (betrayal_clicks != 2)
{
	If (A_Gui = "betrayal_info_members") && !InStr(A_GuiControl, "combo")
		parse_member1 := betrayal_info_click_member
	Else
	{
		betrayal_member := ""
		If GetKeyState("LShift", "P")
		{
			parse_member2 := (parse_member1 = "") ? "" : parse_member1
			parse_division2 := (parse_member1 = "") ? "" : parse_division1
		}
		Else
		{
			parse_member2 := ""
			parse_division2 := ""
		}
		parse_member1 := ""
		parse_division1 := ""
	}
}

If (A_Gui = "settings_menu")
	parse_member1 := "aisling"

If (A_Gui = "") && (betrayal_enable_recognition = 0)
{
	ToolTip,,,,
	betrayal_member := ""
	parse_member1 := ""
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	betrayal_shift_clicks := 0
	Loop, Parse, betrayal_divisions, `,, `,
	{
		panel%A_Index%_text := A_Loopfield ":"
		%A_Loopfield%_text := A_Loopfield ":"
	}
	GoSub, Betrayal_info
	Return
}

If (betrayal_enable_recognition = 1) && (A_Gui = "")
{
	If FileExist("img\Recognition (" poe_height "p)\Betrayal\.bmp")
		FileDelete, img\Recognition (%poe_height%p)\Betrayal\.bmp
	pHaystack_betrayal := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop, Files, img\Recognition (%poe_height%p)\Betrayal\*.bmp
	{
		If InStr(A_LoopFilePath, "transportation") || InStr(A_LoopFilePath, "fortification") || InStr(A_LoopFilePath, "research") || InStr(A_LoopFilePath, "intervention")
			continue
		pNeedle_betrayal := Gdip_CreateBitmapFromFile(A_LoopFilePath)
		pSearch_betrayal := Gdip_ImageSearch(pHaystack_betrayal, pNeedle_betrayal,, 0, 0, poe_width - 1, poe_height - 1, imagesearch_variation + 10,, 1, 1)
		Gdip_DisposeImage(pNeedle_betrayal)
		Gdip_DisposeImage(pSearch_betrayal)
		If (pSearch_betrayal > 0)
		{
			parse_member1 := StrReplace(A_LoopFileName, ".bmp")
			parse_member1 := StrReplace(parse_member1, "1")
			Break
		}
	}
	Gdip_DisposeImage(pHaystack_betrayal)
	If (parse_member1 = parse_member2) && (parse_member1 != "")
		Return
	If (parse_member1 != "")
	{
		pHaystack_betrayal := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
		Loop, Parse, betrayal_divisions, `,, `,
		{
			pNeedle_betrayal := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\Betrayal\" A_Loopfield ".bmp")
			pSearch_betrayal := Gdip_ImageSearch(pHaystack_betrayal, pNeedle_betrayal,, 0, 0, poe_width - 1, poe_height - 1, imagesearch_variation + 10,, 1, 1)
			Gdip_DisposeImage(pNeedle_betrayal)
			Gdip_DisposeImage(pSearch_betrayal)
			If (pSearch_betrayal > 0)
			{
				parse_division1 := A_Loopfield
				parse_member1 := StrReplace(parse_member1, "1")
				Break
			}
		}
		LLK_ToolTip("match found", 0.5)
		Gdip_DisposeImage(pHaystack_betrayal)
	}
	Else LLK_ToolTip("no match", 0.5)
}

If (parse_member1 = "")
{
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	betrayal_scan_failed := 1
	betrayal_layout := 1
	parse_member1 := ""
	parse_division1 := ""
	parse_member2 := ""
	parse_division2 := ""
	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
	{
		panel%A_Index%_text := A_Loopfield ":"
		%A_Loopfield%_text := A_Loopfield ":"
	}
	GoSub, Betrayal_info
	Return
}
Else betrayal_scan_failed := 0

If ((parse_member1 != "") && (parse_member2 = "")) || (parse_division1 = "") || (parse_division2 = "") || (parse_division1 = parse_division2)
{
	betrayal_layout := 1
	parse_member2 := ""
	parse_division2 := ""
}
Else betrayal_layout := 2

If (betrayal_layout = 1)
{
	betrayal_member := parse_member1
	IniRead, transportation_text, data\Betrayal.ini, %betrayal_member%, transportation
	transportation_text := betrayal_member " transportation:`n" transportation_text
	IniRead, fortification_text, data\Betrayal.ini, %betrayal_member%, fortification
	fortification_text := betrayal_member " fortification:`n" fortification_text
	IniRead, research_text, data\Betrayal.ini, %betrayal_member%, research
	research_text := betrayal_member " research:`n" research_text
	IniRead, intervention_text, data\Betrayal.ini, %betrayal_member%, intervention
	intervention_text := betrayal_member " intervention:`n" intervention_text
	GoSub, Betrayal_info
}
Else
{
	IniRead, panel1_text, data\Betrayal.ini, %parse_member1%, %parse_division1%
	IniRead, panel2_text, data\Betrayal.ini, %parse_member1%, %parse_division2%
	IniRead, panel3_text, data\Betrayal.ini, %parse_member2%, %parse_division2%
	IniRead, panel4_text, data\Betrayal.ini, %parse_member2%, %parse_division1%
	If (panel1_text = "ERROR") || (panel2_text = "ERROR") || (panel3_text = "ERROR") || (panel4_text = "ERROR")
	{
		SoundBeep
		Return
	}
	panel1_text := parse_member1 " " parse_division1 " (current):`n" panel1_text
	panel2_text := parse_member1 " " parse_division2 " (target):`n" panel2_text
	panel3_text := parse_member2 " " parse_division2 " (current):`n" panel3_text
	panel4_text := parse_member2 " " parse_division1 " (target):`n" panel4_text
	GoSub, Betrayal_info
}
Return

Init_betrayal:
betrayal_divisions := "transportation,fortification,research,intervention"
betrayal_color := ["White", "00D000", "Yellow", "E90000", "Aqua"]
betrayal_shift_clicks := 0
IniRead, betrayal_list, data\Betrayal.ini
betrayal_list := StrReplace(betrayal_list, "version`n")
Sort, betrayal_list, D`n
IniRead, betrayal_ini_version_data, data\Betrayal.ini, Version, version, 1
IniRead, betrayal_ini_version_user, ini\betrayal info.ini, Version, version, 0
If !FileExist("ini\betrayal info.ini") || (betrayal_ini_version_user < betrayal_ini_version_data)
{
	betrayal_info_exists := FileExist("ini\betrayal info.ini") ? 1 : 0
	IniWrite, %betrayal_ini_version_data%, ini\betrayal info.ini, Version, version
	If (betrayal_info_exists = 0)
	{
		IniWrite, 0, ini\betrayal info.ini, Settings, font-offset
		IniWrite, 220, ini\betrayal info.ini, Settings, transparency
	}
	Loop, Parse, betrayal_list, `n, `n
	{
		check := A_Loopfield
		If (A_LoopField = "settings") || (A_Loopfield = "version")
			continue
		If (betrayal_info_exists = 0)
			IniWrite, transportation=1`nfortification=1`nresearch=1`nintervention=1, ini\betrayal info.ini, %check%
	}
}
IniRead, settings_enable_betrayal, ini\config.ini, Features, enable betrayal-info, 0
IniRead, fSize_offset_betrayal, ini\betrayal info.ini, Settings, font-offset, 0
IniRead, betrayal_trans, ini\betrayal info.ini, Settings, transparency, 220
IniRead, betrayal_enable_recognition, ini\betrayal info.ini, Settings, enable image recognition, 0
IniRead, betrayal_perma_table, ini\betrayal info.ini, Settings, permanent table, 0
IniRead, betrayal_info_table_pos, ini\betrayal info.ini, Settings, table-position, left
IniRead, betrayal_info_prio_dimensions, ini\betrayal info.ini, Settings, prioview-dimensions, 0
IniRead, betrayal_info_prio_transportation, ini\betrayal info.ini, Settings, transportation coords, 0`,0
IniRead, betrayal_info_prio_fortification, ini\betrayal info.ini, Settings, fortification coords, 0`,0
IniRead, betrayal_info_prio_research, ini\betrayal info.ini, Settings, research coords, 0`,0
IniRead, betrayal_info_prio_intervention, ini\betrayal info.ini, Settings, intervention coords, 0`,0
Loop, Parse, betrayal_divisions, `,, `,
{
	%A_LoopField%_xcoord := (betrayal_info_prio_%A_LoopField% != "0,0") ? SubStr(betrayal_info_prio_%A_LoopField%, 1, InStr(betrayal_info_prio_%A_LoopField%, ",") - 1) : ""
	%A_LoopField%_ycoord := (betrayal_info_prio_%A_LoopField% != "0,0") ? SubStr(betrayal_info_prio_%A_LoopField%, InStr(betrayal_info_prio_%A_LoopField%, ",") + 1) : ""
}
Return