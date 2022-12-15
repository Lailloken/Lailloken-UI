Lab_info:
If (A_Gui = "context_menu") || InStr(A_ThisHotkey, ":")
{
	lab_mode := 1
	Run, https://www.poelab.com
	Return
}
If (A_GuiControl = "Lab_marker")
{
	Gui, lab_marker: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lab_marker
	Gui, lab_marker: Color, White
	WinSet, Transparent, 100
	MouseGetPos, mouseXpos, mouseYpos
	Gui, lab_marker: Show, % "NA w"poe_width * 3/160 * 212/235 " h"poe_width * 3/160 * 212/235 " x"mouseXpos - (poe_width * 3/160 * 212/235)/2 " y"mouseYpos - (poe_width * 3/160 * 212/235)/2
	LLK_Overlay("lab_marker", "show")
	WinActivate, ahk_group poe_window
	Return
}
If (A_ThisHotkey = "Tab")
{
	If (hwnd_lab_layout = "")
	{
		pLab := Gdip_CreateBitmapFromClipboard()
		If (pLab < 0)
		{
			LLK_ToolTip("no image-data in clipboard", 1.5, xScreenOffSet + poe_width/2, yScreenOffSet + poe_height/2)
			KeyWait, Tab
			Return
		}
		pLab_source := Gdip_CloneBitmapArea(pLab, 257, 42, 1175, 521)
		wLab_source := 1175
		hLab_source := 521
		hbmLab_source := CreateDIBSection(wLab_source, hLab_source)
		hdcLab_source := CreateCompatibleDC()
		obmLab_source := SelectObject(hdcLab_source, hbmLab_source)
		gLab_source := Gdip_GraphicsFromHDC(hdcLab_source)
		Gdip_SetInterpolationMode(gLab_source, 0)
		Gdip_DrawImage(gLab_source, pLab_source, 0, 0, wLab_source, hLab_source, 0, 0, wLab_source, hLab_source, 1)
		Gui, lab_layout: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lab_layout, Lailloken UI: lab-info
		Gui, lab_layout: Color, Black
		Gui, lab_layout: Margin, 0, 0
		Gui, lab_layout: Font, s%fSize0% cWhite, Fontin SmallCaps
		Gui, lab_layout: Add, Picture, % "BackgroundTrans vLab_marker gLab_info w" poe_width * 53/128 " h-1", HBitmap:*%hbmLab_source%
		Gui, lab_layout: Show, Hide
		WinGetPos,,,, hWin
		Gui, lab_layout: Show, % "NA x"xScreenOffSet + poe_width * 75/256 " y"yScreenOffSet + poe_height - hWin
		LLK_Overlay("lab_layout", "show")
		SelectObject(hdcLab_source, obmLab_source)
		DeleteObject(hbmLab_source)
		DeleteDC(hdcLab_source)
		Gdip_DeleteGraphics(gLab_source)
		Gdip_DisposeImage(pLab_source)
		Gdip_DisposeImage(pLab)
	}
	Else
	{
		LLK_Overlay("lab_layout", "toggle")
		LLK_Overlay("lab_marker", "toggle")
	}
	KeyWait, Tab
}
Return