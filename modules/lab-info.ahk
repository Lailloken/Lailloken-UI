Lab_info:
If (A_Gui = "context_menu") || (A_GuiControl = "lab_button")
{
	lab_mode := 0
	lab_mismatch := 1 ;workaround to fix bugs introduced by refreshing lab-progress while import is running
	If (A_GuiControl = "lab_button")
	{
		MouseGetPos, lab_mouseX, lab_mouseY
		ToolTip, release TAB, % lab_mouseX * 1.025, % lab_mouseY, 2
		KeyWait, % tab_hotkey
		LLK_Overlay("lab_layout", "hide")
		ToolTip,,,, 2
	}
	Run, https://www.poelab.com
	WinWaitNotActive, ahk_group poe_window
	Clipboard := ""
	pLab := ""
	While !WinActive("ahk_group poe_window")
	{
		sleep, 250
		If !lab_mode && (!pLab || pLab < 0)
			pLab := Gdip_CreateBitmapFromClipboard()
		If !lab_mode && (pLab > 0)
		{
			LLK_ToolTip("img-import successful", 1.5)
			Clipboard := ""
			FileDelete, img\lab compass.json
			lab_mode := 1
		}
		If (lab_mode = 1) && InStr(Clipboard, "www.poelab.com") && InStr(Clipboard, ".json")
		{
			lab_mode := 2
			lab_json_raw := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			lab_json_raw.Open("GET", Clipboard, true)
			lab_json_raw.Send()
			lab_json_raw.WaitForResponse()
			FileAppend, % lab_json_raw.ResponseText, img\lab compass.json
			lab_json_raw := ""
		}
		If (lab_mode = 2)
		{
			LLK_ToolTip("compass-import successful", 1.5)
			Clipboard := ""
			Break
		}
	}
	WinWaitActive, ahk_group poe_window
	If !lab_mode
	{
		LLK_ToolTip("lab-import aborted", 2)
		Gdip_DisposeImage(pLab)
		lab_mismatch := 0
		Return
	}
	pLab_source := Gdip_CloneBitmapArea(pLab, 257, 42, 1175, 556)
	Gdip_DisposeImage(pLab)
	pLab := Gdip_ResizeBitmap(pLab_source, poe_width * 53/128, 10000, 1, 7)
	Gdip_SaveBitmapToFile(pLab, "img\lab.jpg", 100)
	Gdip_DisposeImage(pLab_source)
	Gdip_DisposeImage(pLab)
}

If (A_ThisHotkey = tab_hotkey) && (A_GuiControl != "lab_button")
{
	lab_mismatch := 0
	If (lab_mode = 2) && IsObject(lab_json) && InStr(current_location, "labyrinth_") && !InStr(current_location, "airlock")
	{
		Switch lab_json.difficulty
		{
			Case "uber":
				If (current_area_level < 75)
					lab_mismatch := 1
			Case "merciless":
				If (current_area_level != 68)
					lab_mismatch := 1
			Case "cruel":
				If (current_area_level != 55)
					lab_mismatch := 1
			Case "normal":
				If (current_area_level != 33)
					lab_mismatch := 1
		}
	}
	If lab_mismatch ;clear squares and text-labels BEFORE displaying overlay in order to prevent flashing
	{
		Loop, % lab_json.rooms.Count()
		{
			GuiControl, lab_layout:, lab_room%A_Index%, img\GUI\square_blank.png
			GuiControl, lab_layout: text, lab_text%A_Index%,
		}
	}
	LLK_Overlay("lab_layout", "show") ;show overlay BEFORE displaying tooltip
	If lab_mismatch
		ToolTip, layout doesn't match the lab you're currently in!, % xScreenOffSet + poe_width * 75/256, % yScreenOffSet + poe_height - hLab + 46*lab_scaling, 2 ;show tooltip AFTER overlay
	KeyWait, % tab_hotkey
	LLK_Overlay("lab_layout", "hide")
	ToolTip,,,, 2
	Return
}

lab_scaling := (poe_width * 53/128) / 1175
lab_xOffset := 37*lab_scaling, lab_yOffset := 73*lab_scaling
Gui, lab_layout: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lab_layout
Gui, lab_layout: Color, Black
Gui, lab_layout: Margin, 0, 0
Gui, lab_layout: Font, s%fSize0% cWhite, Fontin SmallCaps

If FileExist("img\lab.jpg")
{
	Gui, lab_layout: Add, Picture, % "BackgroundTrans", img\lab.jpg
	lab_mode := 1
}
Else
{
	Gui, lab_layout: Add, Text, % "BackgroundTrans Center 0x200 w"poe_width * 53/128 " h"556*lab_scaling, couldn't find lab-layout image
	FileDelete, img\lab compass.json
}

If FileExist("img\lab compass.json")
{
	FileRead, lab_json, img\lab compass.json
	lab_json := Json.Load(lab_json)
	Loop, % lab_json.rooms.Count()
	{
		Gui, lab_layout: Add, Picture, % "BackgroundTrans vlab_room"A_Index " w"poe_width * 3/160 * 212/235 " h"poe_width * 3/160 * 212/235 " x"lab_xOffset + lab_json.rooms[A_Index].x * lab_scaling - (poe_width * 3/160 * 212/235)/2 " y"lab_yOffset + lab_json.rooms[A_Index].y * lab_scaling - (poe_width * 3/160 * 212/235)/2, img\GUI\square_blank.png
		Gui, lab_layout: Add, Text, % "BackgroundTrans Center vlab_text"A_Index " xp-"(poe_width * 3/160 * 212/235)/2 " yp-"font_height*0.85 " w"(poe_width * 3/160 * 212/235)*2,
	}
	lab_mode := 2
}
Else lab_json := ""
	
Gui, lab_layout: Add, Picture, % "x-1 y-1 BackgroundTrans Border vlab_button gLab_info h"46*lab_scaling " w-1", % !lab_mode ? "img\GUI\lab3.png" : (lab_mode = 1) ? "img\GUI\lab2.png" : "img\GUI\lab1.png"
Gui, lab_layout: Show, x10000 y10000
WinGetPos,,,, hLab
Gui, lab_layout: Show, % "Hide x"xScreenOffSet + poe_width * 75/256 " y"yScreenOffSet + poe_height - hLab
;LLK_Overlay("lab_layout", "hide")
SelectObject(hdcLab_source, obmLab_source)
DeleteObject(hbmLab_source)
DllCall("DeleteObject", "ptr", hbmLab_source)
DeleteDC(hdcLab_source)
Gdip_DeleteGraphics(gLab_source)
Gdip_DisposeImage(pLab_source)
Gdip_DisposeImage(pLab)
lab_checkpoint := 0
lab_mismatch := 0
lab_current_id := ""
lab_previous_verbose := ""
lab_previous := ""
pLab := ""
Return