Init_qol()
{
	local
	global vars, settings

	settings.qol := {"alarm": LLK_IniRead("ini\qol tools.ini", "features", "alarm", 0), "notepad": LLK_IniRead("ini\qol tools.ini", "features", "notepad", 0), "lab": LLK_IniRead("ini\qol tools.ini", "features", "lab", 0)}

	settings.alarm := {"fSize": LLK_IniRead("ini\qol tools.ini", "alarm", "font-size", settings.general.fSize)}
	LLK_FontDimensions(settings.alarm.fSize, font_height, font_width), settings.alarm.fHeight := font_height, settings.alarm.fWidth := font_width
	settings.alarm.color := LLK_IniRead("ini\qol tools.ini", "alarm", "font-color", "White")
	;settings.alarm.trans := LLK_IniRead("ini\qol tools.ini", "alarm", "transparency", 250)
	settings.alarm.xPos := LLK_IniRead("ini\qol tools.ini", "alarm", "x-coordinate")
	settings.alarm.yPos := LLK_IniRead("ini\qol tools.ini", "alarm", "y-coordinate")
	vars.alarm := {"timestamp": LLK_IniRead("ini\qol tools.ini", "alarm", "timestamp")}, vars.alarm.timestamp := (vars.alarm.timestamp < A_Now) ? "" : vars.alarm.timestamp

	settings.notepad := {"fSize": LLK_IniRead("ini\qol tools.ini", "notepad", "font-size", settings.general.fSize)}
	LLK_FontDimensions(settings.notepad.fSize, font_height, font_width), settings.notepad.fHeight := font_height, settings.notepad.fWidth := font_width
	settings.notepad.color := LLK_IniRead("ini\qol tools.ini", "notepad", "font-color", "White")
	settings.notepad.trans := LLK_IniRead("ini\qol tools.ini", "notepad", "transparency", 250)
	settings.notepad.xButton := LLK_IniRead("ini\qol tools.ini", "notepad", "x-coordinate button")
	settings.notepad.yButton := LLK_IniRead("ini\qol tools.ini", "notepad", "y-coordinate button")
	settings.notepad.oButton := LLK_IniRead("ini\qol tools.ini", "notepad", "button-offset", 1)
	settings.notepad.sButton := vars.monitor.w * 0.03 * settings.notepad.oButton
	vars.notepad := {"toggle": 0}, vars.notepad_widgets := {}, vars.hwnd.notepad_widgets := {}

	If InStr(vars.log.areaID, "labyrinth_")
		Lab("init")
}

Alarm(click := 0)
{
	local
	global vars, settings

	If (A_Gui = "alarm_set")
	{
		time := A_Now, input := LLK_ControlGet(vars.hwnd.alarm.edit), input := !input ? 0 : input, sections := [], units := ["seconds", "minutes", "hours"]
		WinGetPos, x, y, w, h, % "ahk_id " vars.hwnd.alarm.edit
		Loop, Parse, input, :
		{
			If Blank(A_LoopField) || (A_Index > 3) || !IsNumber(A_LoopField)
				error := 1
			sections.InsertAt(1, A_LoopField)
		}
		If !InStr(input, ":") && !IsNumber(input) || error
		{
			LLK_ToolTip("invalid input",, x, y + h,, "red")
			Return
		}
		For index, section in sections
			EnvAdd, time, section, % units[index]
		vars.alarm.timestamp := time, x := y := w := h := ""
		IniWrite, % time, ini\qol tools.ini, alarm, timestamp
		WinActivate, ahk_group poe_window
	}

	start := A_TickCount, vars.alarm.drag := 1
	If (click = 1)
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.alarm.main
	While (click = 1) && GetKeyState("LButton", "P")
	{
		If (A_TickCount >= start + 500)
		{
			If !transform
			{
				Gui, % vars.hwnd.alarm.main ": +E0x20"
				transform := 1
			}			
			LLK_Drag(w, h, x, y,, vars.hwnd.alarm.main)
			Sleep 1
		}
	}
	If WinExist("ahk_id "vars.hwnd.alarm.main)
		Gui, % vars.hwnd.alarm.main ": -E0x20"
	If x
	{
		settings.alarm.xPos := x, settings.alarm.yPos := y
		IniWrite, % x, ini\qol tools.ini, alarm, x-coordinate
		IniWrite, % y, ini\qol tools.ini, alarm, y-coordinate
	}
	Else If (click = 2)
	{
		KeyWait, RButton
		vars.alarm.timestamp := ""
		IniDelete, ini\qol tools.ini, alarm, timestamp
		If !vars.alarm.toggle
		{
			LLK_Overlay(vars.hwnd.alarm.main, "destroy")
			Return
		}
	}
	Else If (click = 1)
	{
		KeyWait, LButton
		WinActivate, ahk_group poe_window
		If (vars.alarm.timestamp && vars.alarm.timestamp < A_Now)
			vars.alarm.timestamp := A_Now
		Else If !vars.alarm.timestamp
		{
			Gui, alarm_set: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDalarm_set"
			Gui, alarm_set: Color, Black
			Gui, alarm_set: Margin, 0, 0
			Gui, alarm_set: Font, % "s" settings.alarm.fSize//2 " cWhite", Fontin SmallCaps
			vars.hwnd.alarm.alarm_set := alarm_set
			
			Gui, alarm_set: Add, Edit, % "Section cBlack HWNDhwnd r1 w"vars.alarm.wPanel - 2,
			vars.hwnd.alarm.edit := hwnd
			Gui, alarm_set: Add, Button, % "xp yp hp wp Hidden Default gAlarm cBlack HWNDhwnd", OK
			;ControlFocus,, ahk_id %hwnd%
			Gui, alarm_set: Show, % "x"vars.alarm.xPanel " y"vars.alarm.yPanel
			While WinActive("ahk_id "alarm_set)
				Sleep 10
			Gui, alarm_set: Destroy
		}
	}

	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDalarm"(vars.alarm.toggle || vars.alarm.timestamp <= A_Now ? "" : " +E0x20")
	Gui, %alarm%: Color, Black
	Gui, %alarm%: Margin, % 0, 0
	Gui, %alarm%: Font, % "s" settings.alarm.fSize " c"settings.alarm.color, Fontin SmallCaps
	hwnd_old := vars.hwnd.alarm.main, vars.hwnd.alarm := {"main": alarm}

	If vars.alarm.timestamp
	{
		timer := vars.alarm.timestamp
		EnvSub, timer, A_Now, seconds
	}
	
	Gui, %alarm%: Add, Text, % "Center HWNDhwnd", % (IsNumber(vars.alarm.timestamp) && (vars.alarm.timestamp < A_Now) ? " +" : " ") FormatSeconds(Abs(timer), 0) " "
	vars.hwnd.alarm.timer := hwnd

	Gui, %alarm%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %alarm%
	vars.alarm.wPanel := w, vars.alarm.hPanel := h
	If IsNumber(settings.alarm.xPos)
		xPos := (settings.alarm.xPos > vars.monitor.w/2 - 1) ? vars.monitor.x + settings.alarm.xPos - (w - 1) : vars.monitor.x + settings.alarm.xPos
	Else xPos := vars.client.xc - w/2
	yPos := !IsNumber(settings.alarm.yPos) ? vars.client.y : (settings.alarm.yPos > vars.monitor.h/2 - 1) ? settings.alarm.yPos - (h - 1) : settings.alarm.yPos
	Gui, %alarm%: Show, % "NA x"xPos " y"vars.monitor.y + yPos
	WinGetPos, x, y,,, ahk_id %alarm%
	vars.alarm.xPanel := x, vars.alarm.yPanel := y
	LLK_Overlay(alarm, "show"), LLK_Overlay(hwnd_old, "destroy"), vars.alarm.drag := 0
}

Lab(mode := "", override := 0)
{
	local
	global vars, settings, Json

	If !IsObject(vars.lab) || (mode = "init")
		vars.lab := {"rooms": []}

	If (mode = "link")
	{
		If GetKeyState(settings.hotkeys.tab, "P")
			LLK_ToolTip("release key: "settings.hotkeys.tab, 0,,, "poelab")
		KeyWait, % settings.hotkeys.tab
		LLK_Overlay(vars.hwnd["tooltippoelab"], "destroy"), LLK_Overlay(vars.hwnd.lab.main, "destroy"), LLK_Overlay(vars.hwnd.lab.button, "destroy"), vars.lab.toggle := 0
		Run, % "https://www.poelab.com/"
		If settings.features.browser
		{
			WinWaitNotActive, ahk_group poe_ahk_window,, 2
			ToolTip_Mouse("lab", 1)
		}
	}

	If (mode = "import" || mode = "link")
	{
		WinWaitNotActive, ahk_group poe_window, 2
		Clipboard := ""
		While !WinActive("ahk_group poe_window")
		{
			If !step
				pBitmap := Gdip_CreateBitmapFromClipboard()
			If !step && (pBitmap > 0)
			{
				LLK_ToolTip("img-import successful", 1.5,,,, "lime")
				Clipboard := "", vars.lab := {"rooms": []}
				FileDelete, img\lab compass.json
				step := 1
			}
			If (step = 1) && InStr(Clipboard, "www.poelab.com") && InStr(Clipboard, ".json")
			{
				step := 2, lab_compass := ComObjCreate("WinHttp.WinHttpRequest.5.1")
				lab_compass.Open("GET", Clipboard, true), lab_compass.Send(), lab_compass.WaitForResponse()
				lab_compass_json := Json.Load(lab_compass.ResponseText)
				If lab_compass_json.Count()
				{
					For index, room in lab_compass_json.rooms
					{
						If (room.name = "aspirant's trial")
							Continue
						For dir, number in room.exits
							lab_compass_json.rooms[number].exits["backtrack_to_"index] := index
					}
					LLK_ToolTip("compass-import successful", 1.5,,,, "lime")
					FileAppend, % Json.Dump(lab_compass_json), img\lab compass.json
					Break
				}
				Else LLK_ToolTip("compass-import failed", 1.5,,,, "lime")
				Clipboard := ""
			}
			Sleep 250
		}
		WinWaitActive, ahk_group poe_window
		If !step
		{
			LLK_ToolTip("lab-import aborted", 1.5, vars.client.xc, vars.client.yc,, "red"), Gdip_DisposeImage(pBitmap)
			Return
		}
		pBitmap_copy := Gdip_CloneBitmapArea(pBitmap, 257, 42, 1175, 556), Gdip_DisposeImage(pBitmap)
		pBitmap := Gdip_ResizeBitmap(pBitmap_copy, vars.client.w * 53/128, 10000, 1, 7)
		Gdip_SaveBitmapToFile(pBitmap, "img\lab.jpg", 100), Gdip_DisposeImage(pBitmap_copy), Gdip_DisposeImage(pBitmap)
		Return
	}
	
	If !IsObject(vars.lab.compass) && FileExist("img\lab compass.json")
		vars.lab.compass := LLK_FileRead("img\lab compass.json"), vars.lab.compass := Json.Load(vars.lab.compass)
	If !vars.lab.scale
		pBitmap := Gdip_LoadImageFromFile("img\lab.jpg"), Gdip_GetImageDimensions(pBitmap, w, h), vars.lab.width := !w ? vars.client.w * 53/128 : w, vars.lab.height := !h ? (vars.client.w * 53/128)/2.112 : h ;cont
		, vars.lab.scale := vars.lab.width/1175, Gdip_DisposeImage(pBitmap)
	
	scale := vars.lab.scale, dim := 50 * scale, difficulties := {33: "normal", 55: "cruel", 68: "merciless", 75: "uber", 83: "uber"}, text_height := dim/2
	If !vars.lab.custom_font
		vars.lab.custom_font := LLK_FontSizeGet(text_height, width)

	If !vars.lab.rooms.Count()
		vars.lab.room := [1, vars.lab.compass.rooms.1.name], vars.lab.rooms.1 := {"name": vars.lab.compass.rooms.1.name, "seed": ""}, started := 1, vars.lab.outdated := !Blank(vars.lab.compass.date) && (StrReplace(vars.lab.compass.date, "-") != SubStr(A_NowUTC, 1, 8)) ? 1 : 0
	
	If (mode = "progress") && !started
	{
		vars.lab.room := [vars.lab.exits.numbers[LLK_HasVal(vars.lab.exits.names, vars.log.areaname)], vars.lab.exits.names[LLK_HasVal(vars.lab.exits.names, vars.log.areaname)], vars.log.areaID]
		vars.lab.rooms[vars.lab.room.1] := {"name": vars.log.areaname, "seed": vars.log.areaseed}
	}
	Else If (mode = "backtrack")
		vars.lab.room := [override, vars.lab.rooms[override].name]
	
	vars.lab.exits := {"numbers": [], "names": []}
	For dir, number in vars.lab.compass.rooms[vars.lab.room.1].exits
		vars.lab.exits.numbers.Push(number), vars.lab.exits.names.Push(vars.lab.compass.rooms[number].name)
	If InStr("progress,init,backtrack", mode) && !vars.lab.toggle
		Return

	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDlab"
	Gui, %lab%: Color, Black
	Gui, %lab%: Margin, 0, 0
	Gui, %lab%: Font, % "s"vars.lab.custom_font " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.lab.main, hwnd_old2 := vars.hwnd.lab.button, vars.hwnd.lab := {"main": lab}

	If vars.lab.outdated
	{
		Gui, %lab%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %lab%: Add, Text, % "BackgroundTrans Center w"vars.lab.width " h"vars.lab.height, % "`n`nlayout is outdated!`n`nloaded: "vars.lab.compass.date "`nlatest: "SubStr(A_NowUTC, 1, 4) "-" SubStr(A_NowUTC, 5, 2) "-" SubStr(A_NowUTC, 7, 2)
		Gui, %lab%: Font, % "s"vars.lab.custom_font
		Gui, %lab%: Add, Pic, % "x0 y0 BackgroundTrans w"vars.lab.width " h"vars.lab.height, img\GUI\square_red_trans.png
	}
	Else If !InStr(vars.log.areaID, "airlock") && !Blank(vars.lab.compass.difficulty) && (difficulties[vars.log.arealevel] != vars.lab.compass.difficulty)
	{
		Gui, %lab%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %lab%: Add, Text, % "BackgroundTrans Center w"vars.lab.width " h"vars.lab.height, % "`n`nlayouts don't match!`n`nloaded: "vars.lab.compass.difficulty "`nentered: " difficulties[vars.log.arealevel]
		Gui, %lab%: Font, % "s"vars.lab.custom_font
		Gui, %lab%: Add, Pic, % "x0 y0 BackgroundTrans w"vars.lab.width " h"vars.lab.height, img\GUI\square_red_trans.png
		mismatch := 1
	}

	For index, room in vars.lab.compass.rooms
	{
		If InStr(vars.log.areaID, "airlock") || !LLK_HasVal(vars.lab.exits.numbers, index) && !vars.lab.rooms[index] && (index != vars.lab.room.1)
			Continue
		If LLK_HasVal(vars.lab.exits.numbers, index) && (vars.lab.exits.numbers.Count() > 1) && !(vars.lab.room.2 = "aspirant's trial" && index > vars.lab.room.1)
			Gui, %lab%: Add, Text, % "BackgroundTrans Center x"(room.x + 12) * scale - dim/2 " w"dim*2 " y"(room.y + 47) * scale - text_height, % SubStr(room.name, 1, 2) " " SubStr(room.name, InStr(room.name, " ") + 1, 2)
		If (vars.lab.room.1 = index)
			Gui, %lab%: Add, Pic, % "BackgroundTrans x"(room.x + 12) * scale " w"dim " h"dim " y"(room.y + 47) * scale, img\GUI\square_purple_trans.png
		Else If vars.lab.rooms[index].Count()
			Gui, %lab%: Add, Pic, % "BackgroundTrans x"(room.x + 12) * scale " w"dim " h"dim " y"(room.y + 47) * scale, img\GUI\square_green_trans.png 
	}
	If FileExist("img\lab.jpg")
		Gui, %lab%: Add, Pic, % "x0 y0", img\lab.jpg
	Else
	{
		Gui, %lab%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %lab%: Add, Text, % "x0 y0 Center 0x200 w"vars.client.w * 53/128 " h"(vars.client.w * 53/128)/2.112, couldn't load img-file
		Gui, %lab%: Font, % "s"vars.lab.custom_font
		file_missing := 1
	}
	
	Gui, %lab%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %lab%
	Gui, %lab%: Show, % "NA xCenter y"vars.monitor.y + vars.monitor.h - h
	WinGetPos, x, y,,, ahk_id %lab%

	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDlab2"
	Gui, %lab2%: Color, Black
	Gui, %lab2%: Margin, 0, 0
	Gui, %lab2%: Font, % "s"vars.lab.custom_font " cWhite", Fontin SmallCaps
	
	Gui, %lab2%: Add, Pic, % "h"dim*0.95 " w-1 HWNDhwnd", % "img\GUI\lab"(file_missing || vars.lab.outdated || mismatch ? "3" : Blank(vars.lab.compass.difficulty) ? "2" : "1") ".png"
	vars.hwnd.lab.button := lab2, vars.hwnd.help_tooltips["lab_button"] := hwnd
	Gui, %lab2%: Show, % "NA x"x " y"y
	LLK_Overlay(hwnd_old, "destroy"), LLK_Overlay(hwnd_old2, "destroy")
}

Notepad(cHWND := "")
{
	local
	global vars, settings

	If (cHWND = "save") ;save any changes made to a note
	{
		If !vars.notepad.selected_entry
			Return
		check_text := StrReplace(LLK_ControlGet(vars.hwnd.notepad.note), "&&", "&")
		While !Blank(check_text) && InStr(" `n", SubStr(check_text, 1, 1))
			check_text := SubStr(check_text, 2)
		While !Blank(check_text) && InStr(" `n", SubStr(check_text, 0))
			check_text := SubStr(check_text, 1, -1)
		check_text := StrReplace(check_text, "`n", "(n)")
		If (check_text != LLK_IniRead("ini\qol tools.ini", "notepad", vars.notepad.selected_entry))
		{
			IniWrite, % """" check_text """", ini\qol tools.ini, notepad, % vars.notepad.selected_entry
			vars.notepad.entries[vars.notepad.selected_entry] := StrReplace(check_text, "(n)", "`n")
		}
		Return
	}

	start := A_TickCount, check := LLK_HasVal(vars.hwnd.notepad, cHWND), skip := ["font-color", "font-size", "button-offset", "x-coordinate button", "y-coordinate button", "transparency", "grouped widget"]
	control := SubStr(check, InStr(check, "_") + 1), sum_height := 0, max_width := vars.monitor.w*0.9, max_height := vars.monitor.h*0.9
	While (A_Gui = "notepad_button") && GetKeyState("LButton", "P")
		If (A_TickCount >= start + 200)
		{
			LLK_Drag(settings.notepad.sButton + 2, settings.notepad.sButton + 2, x, y,, "notepad_button")
			Sleep 1
		}
	If !Blank(x)
	{
		settings.notepad.xButton := x - 1, settings.notepad.yButton := y - 1
		IniWrite, % settings.notepad.xButton, ini\qol tools.ini, notepad, x-coordinate button
		IniWrite, % settings.notepad.yButton, ini\qol tools.ini, notepad, y-coordinate button
		Return
	}

	If (check = "winbar")
	{
		start := A_TickCount
		While GetKeyState("LButton", "P")
		{
			If (A_TickCount >= start + 200)
			{
				LLK_Drag(vars.notepad.w, vars.notepad.h, xPos, yPos, 1, vars.hwnd.notepad.main)
				Sleep 1
			}
		}
		If !Blank(xPos)
			vars.notepad.x := xPos, vars.notepad.y := yPos
		Return
	}
	Else If (check = "winx") || (A_Gui = "notepad_button") && WinExist("ahk_id "vars.hwnd.notepad.main)
	{
		KeyWait, LButton
		Notepad("save")
		Gui, % vars.hwnd.notepad.main ": Destroy"
		WinActivate, ahk_group poe_window
		Return
	}
	Else If (check = "add")
	{
		name := LLK_ControlGet(vars.hwnd.notepad.name), ini := LLK_IniRead("ini\qol tools.ini", "notepad")
		While (SubStr(name, 1, 1) = " ")
			name := SubStr(name, 2)
		While (SubStr(name, 0) = " ")
			name := SubStr(name, 1, -1)
		Loop, Parse, name
			error := InStr("[=]", A_LoopField) ? "contains unsupported`ncharacters" : error
		If InStr(ini, "`n"name "=")
			error := "tab already exists"
		If Blank(name) || error
		{
			WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.notepad.name
			LLK_ToolTip("invalid name" (error ? ":`n" error : ""), error ? 2 : 1, x, y + h,, "red")
			Return
		}
		Notepad("save")
		IniWrite, % "", ini\qol tools.ini, notepad, % name
	}
	Else If InStr(check, "select_")
	{
		start := A_TickCount
		While GetKeyState("LButton", "P")
			If (A_TickCount >= start + 200)
			{
				Notepad("save"), NotepadWidget(control)
				KeyWait, LButton
				WinActivate, ahk_group poe_window
				Return
			}
		If (control = "grouped widget")
			Return
		If (vars.system.click = 2)
		{
			If LLK_Progress(vars.hwnd.notepad["delbar_"control], "RButton")
			{
				IniDelete, ini\qol tools.ini, notepad, % control
				vars.notepad.selected_entry := (control = vars.notepad.selected_entry) ? "" : vars.notepad.selected_entry
				If vars.hwnd.notepad_widgets.HasKey(control)
					LLK_Overlay(vars.hwnd.notepad_widgets[control], "destroy"), vars.hwnd.notepad_widgets.Delete(control)
				KeyWait, RButton
			}
			Else Return
		}
		If !Blank(vars.notepad.selected_entry)
			Notepad("save")
		vars.notepad.selected_entry := (vars.system.click = 1) ? control : vars.notepad.selected_entry
	}
	Else If (check = "drag")
	{
		WinGetPos, x0, y0, w0, h0, % "ahk_id "vars.hwnd.notepad.note
		Notepad("save")
		While GetKeyState("LButton", "P")
		{
			MouseGetPos, xMouse, yMouse
			wBox := (xMouse - x0 < settings.general.fWidth*20) ? settings.general.fWidth*20 : (xMouse - x0 > max_width) ? max_width : xMouse - x0
			hBox := (yMouse - y0 < settings.general.fWidth*30) ? settings.general.fWidth*30 : (yMouse - y0 > max_height) ? max_height : yMouse - y0
			Sleep 1
		}
	}
	wBox := !wBox ? settings.general.fWidth*20 : wBox, hBox := !hBox ? settings.general.fWidth*30 : hBox

	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDnotepad"
	Gui, %notepad%: Color, Black
	Gui, %notepad%: Margin, % settings.general.fWidth/2, % settings.general.fWidth/2
	Gui, %notepad%: Font, % "s" settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.notepad.main, vars.hwnd.notepad := {"main": notepad}

	Gui, %notepad%: Add, Text, % "x-1 y-1 Section HWNDhwnd Center Border gNotepad", lailloken ui: notepad
	vars.hwnd.notepad.winbar := hwnd
	Gui, %notepad%: Add, Text, % "ys x+-1 HWNDhwnd Center Border gNotepad w"settings.general.fWidth*2, x
	vars.hwnd.notepad.winx := hwnd

	Gui, %notepad%: Font, % "s" settings.general.fSize
	Gui, %notepad%: Add, Text, % "xs x"settings.general.fWidth/2 " Section HWNDhwnd", % "add a new tab: "
	Gui, %notepad%: Font, % "s" settings.general.fSize - 4
	ControlGetPos,,, w,,, ahk_id %hwnd%
	Gui, %notepad%: Add, Edit, % "ys x+-1 r1 cBlack HWNDhwnd w"wBox
	vars.hwnd.notepad.name := hwnd
	Gui, %notepad%: Add, Button, % "xp yp wp hp Hidden Default gNotepad HWNDhwnd", OK
	vars.hwnd.notepad.add := hwnd
	Gui, %notepad%: Font, % "s" settings.general.fSize

	vars.notepad.entries := {}
	Iniread, ini, ini\qol tools.ini, notepad
	Loop, Parse, ini, `n, `r
	{
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), "(n)", "`n"), val := (SubStr(val, 1, 1) = """") ? SubStr(val, 2, -1) : val
		If LLK_HasVal(skip, key)
			Continue
		vars.notepad.entries[key] := val, check := 0
	}
	For entry, text in vars.notepad.entries
	{
		vars.notepad.selected_entry .= (A_Index = 1 && Blank(vars.notepad.selected_entry)) ? entry : ""
		color := (vars.notepad.selected_entry = entry) ? " cFuchsia" : "" 
		Gui, %notepad%: Add, Text, % "xs" (A_Index = 1 ? " Section w"w " " : " y+-1 wp ") "BackgroundTrans Border Center HWNDhwnd gNotepad"color, % StrReplace(entry, "&", "&&")
		ControlGetPos,,,, h,, ahk_id %hwnd%
		Gui, %notepad%: Add, Progress, % "xp yp wp hp Disabled HWNDhwndbar BackgroundBlack cRed Range0-500", 0
		vars.hwnd.notepad["select_"entry] := hwnd, sum_height += h - 1, vars.hwnd.notepad["delbar_"entry] := vars.hwnd.help_tooltips["notepad_widget"handle] := hwndbar, handle .= "|", check += !Blank(text) ? 1 : 0
	}
	If (sum_height)
	{
		If (check > 1)
		{
			Gui, %notepad%: Add, Text, % "xs y+-1 wp Border Center HWNDhwnd gNotepad", % "grouped widget"
			ControlGetPos,,,, h,, ahk_id %hwnd%
			vars.hwnd.notepad["select_grouped widget"] := vars.hwnd.help_tooltips["notepad_widget grouped"] := hwnd, sum_height + h - 1
			
		}
		Gui, %notepad%: Add, Text, % "xs wp Center BackgroundTrans HWNDhwnd0", how to use widgets
		ControlGetPos,,,, h0,, ahk_id %hwnd0%
		Gui, %notepad%: Font, % "s" settings.notepad.fSize
		Gui, %notepad%: Add, Edit, % "ys x+-1 cBlack -Wrap Multi Hidden HWNDhwnd"(Blank(vars.notepad.entries[vars.notepad.selected_entry]) ? " w"wBox : ""), % vars.notepad.entries[vars.notepad.selected_entry]
		ControlGetPos,,, w, h,, ahk_id %hwnd%
		w := (w < wBox) ? wBox : (w > max_width) ? max_width : w, sum_height += h0 - 1
		h := (h < hBox) ? hBox : (h > max_height) ? max_height : h
		ControlMove,,,, w,, % "ahk_id "vars.hwnd.notepad.name
		Gui, %notepad%: Add, Edit, % "xp yp cBlack -Wrap Multi HWNDhwnd w"w " h"h, % vars.notepad.entries[vars.notepad.selected_entry]
		vars.hwnd.help_tooltips["notepad_widget help"] := hwnd0, vars.hwnd.notepad.note := hwnd, size := settings.general.fWidth/2
		ControlGetPos, x, y, w, h,, ahk_id %hwnd%
		Gui, %notepad%: Add, Text, % "x"x + w - 1 " y"y + h - 1 " w"size " h"size " BackgroundWhite HWNDhwnd gNotepad BackgroundTrans", % ""
		vars.hwnd.notepad.drag := hwnd
		Gui, %notepad%: Add, Progress, % "x"x + w - 1 " y"y + h - 1 " w"size " h"size " BackgroundWhite", 0
		Gui, %notepad%: Margin, 0, 0
	}

	Gui, %notepad%: Show, NA x10000 y10000 AutoSize
	ControlFocus,, % "ahk_id "vars.hwnd.notepad.winbar
	WinGetPos, x, y, w, h, ahk_id %notepad%
	vars.notepad.w := w, vars.notepad.h := h
	ControlMove,,,, w - settings.general.fWidth*2 + 1,, % "ahk_id "vars.hwnd.notepad.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.notepad.winx
	Sleep 50
	If !Blank(vars.notepad.x)
	{
		vars.notepad.x := (vars.notepad.x + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : vars.notepad.x
		vars.notepad.y := (vars.notepad.y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : vars.notepad.y
		Gui, %notepad%: Show, % "NA x"vars.notepad.x " y"vars.notepad.y
	}
	Else Gui, %notepad%: Show, % "NA Center"
	WinGetPos, x, y,,, ahk_id %notepad%
	vars.notepad.x := x, vars.notepad.y := y
	If WinExist("ahk_id "hwnd_old)
		Gui, % hwnd_old ": Destroy"
}

NotepadWidget(tab, mode := 0)
{
	local
	global vars, settings

	If (tab != "grouped widget") && Blank(vars.notepad.entries[tab]) && A_Gui
	{
		LLK_ToolTip("can't create widget:`ntab is blank", 2,,,, "Red")
		Return
	}
	start := A_TickCount
	If (mode = 2)
	{
		LLK_Overlay(vars.hwnd.notepad_widgets[tab], "destroy")
		If (tab = "grouped widget")
			vars.hwnd.Delete("notepad_widgets")
		Else vars.hwnd.notepad_widgets.Delete(tab)
		KeyWait, RButton
		Return
	}

	longpress := (A_Gui = DummyGUI(vars.hwnd.notepad.main)) ? 1 : 0
	While GetKeyState("LButton", "P") && !longpress
		If (A_TickCount >= start + 200)
			longpress := 1

	If (tab = "grouped widget" && mode = 4)
		vars.notepad.active_widget += (vars.notepad.active_widget != vars.notepad.grouped_widget.Count()) ? 1 : 0, mode := 0
	Else If (tab = "grouped widget" && mode = 3)
		vars.notepad.active_widget -= (vars.notepad.active_widget > 1) ? 1 : 0, mode := 0
	Else If !A_Gui && !longpress
		Return
	
	If (tab = "grouped widget") && (A_Gui = DummyGUI(vars.hwnd.notepad.main))
	{
		For key, val in vars.hwnd.notepad_widgets
			LLK_Overlay(val, "destroy")
		vars.hwnd.notepad_widgets := {}
		vars.notepad.grouped_widget := []
		For entry, text in vars.notepad.entries
			If !Blank(text)
				vars.notepad.grouped_widget.Push([entry, text])
	}		

	If (tab != "grouped widget")
		LLK_Overlay(vars.hwnd.notepad_widgets["grouped widget"], "destroy"), vars.hwnd.notepad_widgets.Delete("grouped widget")

	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDwidget"(vars.notepad.toggle ? "" : " +E0x20")
	Gui, %widget%: Color, Black
	Gui, %widget%: Margin, % settings.notepad.fWidth/2, 0
	Gui, %widget%: Font, % "s" settings.notepad.fSize " c"settings.notepad.color, Fontin SmallCaps
	;WinSet, Transparent, 255
	hwnd_old := vars.hwnd.notepad_widgets[tab], vars.hwnd.notepad_widgets[tab] := widget
	If (A_Gui = DummyGUI(vars.hwnd.notepad.main) || mode = 1)
		LLK_Overlay(hwnd_old, "destroy")
	
	If (tab = "grouped widget")
	{
		active := vars.notepad.active_widget := Blank(vars.notepad.active_widget) ? 1 : vars.notepad.active_widget
		Gui, %widget%: Add, Text, % "Section", % StrReplace(vars.notepad.grouped_widget[active].1, "&", "&&") " ("active "/" vars.notepad.grouped_widget.Count() "):`n" StrReplace(vars.notepad.grouped_widget[active].2, "&", "&&")
	}
	Else Gui, %widget%: Add, Text, % "Section", % StrReplace(vars.notepad.entries[tab], "&", "&&")
	Gui, %widget%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %widget%
	While longpress && (A_Gui = DummyGUI(vars.hwnd.notepad.main) || mode = 1) && GetKeyState("LButton", "P")
	{
		LLK_Drag(w, h, x, y,, widget)
		Sleep 1
	}
	If !vars.notepad.toggle
		WinSet, Transparent, % settings.notepad.trans, % "ahk_id "widget
	If !IsObject(vars.notepad_widgets[tab])
		vars.notepad_widgets[tab] := {}
	vars.notepad_widgets[tab].x := !Blank(x) ? x : vars.notepad_widgets[tab].x, xPos := (vars.notepad_widgets[tab].x > vars.monitor.w / 2 - 1) ? vars.notepad_widgets[tab].x - w + 1 : vars.notepad_widgets[tab].x
	vars.notepad_widgets[tab].y := !Blank(y) ? y : vars.notepad_widgets[tab].y, yPos := (vars.notepad_widgets[tab].y > vars.monitor.h / 2 - 1) ? vars.notepad_widgets[tab].y - h + 1 : vars.notepad_widgets[tab].y
	Gui, %widget%: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
	LLK_Overlay(widget, "show"), LLK_Overlay(hwnd_old, "destroy")
}
