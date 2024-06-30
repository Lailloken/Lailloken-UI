Init_qol()
{
	local
	global vars, settings

	If !FileExist("ini\qol tools.ini")
		IniWrite, % "", ini\qol tools.ini, settings

	ini := IniBatchRead("ini\qol tools.ini")
	settings.qol := {"alarm": !Blank(check := ini.features.alarm) ? check : 0, "notepad": !Blank(check1 := ini.features.notepad) ? check1 : 0}
	settings.qol.lab := (settings.general.lang_client = "unknown") ? 0 : !Blank(check := ini.features.lab) ? check : 0

	settings.alarm := {"fSize": !Blank(check := ini.alarm["font-size"]) ? check : settings.general.fSize}
	LLK_FontDimensions(settings.alarm.fSize, font_height, font_width), settings.alarm.fHeight := font_height, settings.alarm.fWidth := font_width
	settings.alarm.color := !Blank(check := ini.alarm["font-color"]) ? check : "FFFFFF"
	settings.alarm.color1 := !Blank(check := ini.alarm["background color"]) ? check : "000000"
	settings.alarm.xPos := !Blank(check := ini.alarm["x-coordinate"]) ? check : ""
	settings.alarm.yPos := !Blank(check := ini.alarm["y-coordinate"]) ? check : ""
	vars.alarm := {"timestamp": !Blank(check := ini.alarm["timestamp"]) ? check : ""}, vars.alarm.timestamp := (vars.alarm.timestamp < A_Now) ? "" : vars.alarm.timestamp

	If InStr(vars.log.areaID, "labyrinth_")
		Lab("init")

	settings.notepad := {"fSize": !Blank(check := ini.notepad["font-size"]) ? check : settings.general.fSize}
	LLK_FontDimensions(settings.notepad.fSize, font_height, font_width), settings.notepad.fHeight := font_height, settings.notepad.fWidth := font_width
	settings.notepad.color := !Blank(check := ini.notepad["font-color"]) ? check : "FFFFFF"
	settings.notepad.color1 := !Blank(check := ini.notepad["background color"]) ? check : "000000"
	settings.notepad.trans := !Blank(check := ini.notepad["transparency"]) ? check : 5, settings.notepad.trans := (settings.notepad.trans > 5) ? 5 : settings.notepad.trans
	settings.notepad.xQuickNote := !Blank(check := ini.notepad["x-coordinate quicknote"]) ? check : ""
	settings.notepad.yQuickNote := !Blank(check := ini.notepad["y-coordinate quicknote"]) ? check : ""
	vars.notepad := {"toggle": 0}, vars.notepad_widgets := {}, vars.hwnd.notepad_widgets := {}
}

Alarm(click := 0)
{
	local
	global vars, settings
	static toggle := 0

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
			LLK_ToolTip(LangTrans("global_error"),, x, y + h,, "red")
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
				Gui, % GuiName(vars.hwnd.alarm.main) ": +E0x20"
				transform := 1
			}
			LLK_Drag(w, h, x, y,, "alarm" toggle, 1)
			Sleep 1
		}
	}
	vars.general.drag := 0
	If WinExist("ahk_id "vars.hwnd.alarm.main)
		Gui, % GuiName(vars.hwnd.alarm.main) ": -E0x20"
	If !Blank(y)
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
			Gui, alarm_set: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDalarm_set", LLK-UI: alarm set
			Gui, alarm_set: Color, Black
			Gui, alarm_set: Margin, 0, 0
			Gui, alarm_set: Font, % "s" settings.alarm.fSize//2 " cWhite", % vars.system.font
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

	toggle := !toggle, GUI_name := "alarm" toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDalarm"(vars.alarm.toggle || vars.alarm.timestamp <= A_Now ? "" : " +E0x20")
	Gui, %GUI_name%: Color, % settings.alarm.color1
	Gui, %GUI_name%: Margin, % 0, 0
	Gui, %GUI_name%: Font, % "s" settings.alarm.fSize " c"settings.alarm.color, % vars.system.font
	hwnd_old := vars.hwnd.alarm.main, vars.hwnd.alarm := {"main": alarm}

	If vars.alarm.timestamp
	{
		timer := vars.alarm.timestamp
		EnvSub, timer, A_Now, seconds
	}

	Gui, %GUI_name%: Add, Text, % "Center HWNDhwnd", % (IsNumber(vars.alarm.timestamp) && (vars.alarm.timestamp < A_Now) ? " +" : " ") FormatSeconds(Abs(timer), 0) " "
	vars.hwnd.alarm.timer := hwnd

	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %alarm%
	vars.alarm.wPanel := w, vars.alarm.hPanel := h
	xPos := Blank(settings.alarm.xPos) ? vars.client.xc - w / 2 + 1 : settings.alarm.xPos, xPos := (xPos >= vars.monitor.w / 2) ? xPos - w + 1 : xPos
	yPos := Blank(settings.alarm.yPos) ? vars.client.y - vars.monitor.y : settings.alarm.yPos, yPos := (yPos >= vars.monitor.h / 2) ? yPos - h + 1 : yPos
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	WinGetPos, x, y,,, ahk_id %alarm%
	vars.alarm.xPanel := x, vars.alarm.yPanel := y
	LLK_Overlay(alarm, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy"), vars.alarm.drag := 0
}

EssenceTooltip(cHWND)
{
	local
	global vars, settings, db
	static control, widths := {}, toggle := 0

	check := LLK_HasVal(vars.hwnd.essences, cHWND)
	If WinExist("ahk_id "vars.hwnd.essences.main) && (control = check)
		Return
	control := check

	name := vars.omnikey.item.name, tier := SubStr(name, 1, InStr(name, " ") - 1), tier := LLK_HasVal(db.essences._tiers, tier), left_column := [], right_column := [], columns := {}
	For type0 in db.essences
		If InStr(vars.omnikey.item.name, type0)
			type := type0
	If !type
		Return
	For index, val in db.essences[type][tier].1
		left_column.Push(val)
	For index, val in db.essences[type][tier + 1].1
		left_column.Push(val)
	For index, val in db.essences[type][tier].2
		right_column.Push(val)
	For index, val in db.essences[type][tier + 1].2
		right_column.Push(val)
	If !widths.HasKey(type "_"tier)
		LLK_PanelDimensions(left_column, settings.general.fSize, wColumn1, height), LLK_PanelDimensions(right_column, settings.general.fSize, wColumn2, height), widths[type "_"tier] := [wColumn1, wColumn2]

	toggle := !toggle, GUI_name := "essences" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDessences
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.essences.main, vars.hwnd.essences := {"main": essences}

	For index, val in db.essences[type][tier].1
	{
		Gui, %GUI_name%: Add, Text, % "Center Border 0x200 HWNDhwnd w"widths[type "_"tier].1 (A_Index = 1 ? " Section" : " xs Section"), % LLK_HasVal(db.essences[type][tier + 1].1, val) && (check = val) ? val "`n" : val
		columns[val] := 1
		If !Blank(LLK_HasVal(db.essences[type][tier + 1].1, val))
			vars.hwnd.essences[val] := hwnd
		Gui, %GUI_name%: Add, Text, % "Border BackgroundTrans ys w"widths[type "_"tier].2, % " " db.essences[type][tier].2[index] (LLK_HasVal(db.essences[type][tier + 1].1, val) && (check = val) ? "`n " : "")
		If !Blank(LLK_HasVal(db.essences[type][tier + 1].1, val)) && (check = val)
			Gui, %GUI_name%: Add, Text, % "Border xp wp wp hp cLime", % " `n " db.essences[type][tier + 1].2[LLK_HasVal(db.essences[type][tier + 1].1, val)]
	}
	For index, val in db.essences[type][tier + 1].1
	{
		If columns[val]
			Continue
		Gui, %GUI_name%: Add, Text, % "xs Section Center Border 0x200 cLime w"widths[type "_"tier].1, % val
		Gui, %GUI_name%: Add, Text, % "Border BackgroundTrans ys cLime w"widths[type "_"tier].2, % " " db.essences[type][tier + 1].2[index]
	}
	If WinExist("ahk_id "hwnd_old)
		WinGetPos, xPos, yPos,,, ahk_id %hwnd_old%
	Else
	{
		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, w, h, ahk_id %essences%
		xPos := (vars.general.xMouse + vars.monitor.w/100 + w - 1 > vars.monitor.x + vars.monitor.w - 1) ? vars.monitor.x + vars.monitor.w - w + 1 : vars.general.xMouse + vars.monitor.w/100
		yPos := (vars.general.yMouse - h/2 > vars.monitor.y + vars.monitor.h - 1) ? vars.monitor.y + vars.monitor.h - h + 1 : vars.general.yMouse - h/2
	}
	Gui, %GUI_name%: Show, % "NA x"xPos " y"yPos
	LLK_Overlay(essences, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

HorizonsTooltip(mode := "")
{
	local
	global vars, settings, db
	static toggle := 0

	If !mode
		Loop, Parse, A_ThisHotkey
			If LLK_IsType(A_LoopField, "alpha")
				mode .= A_LoopField

	If (StrLen(mode) = 1) && LLK_IsType(mode, "alpha") && !db.mapinfo.maps[mode]
	{
		LLK_ToolTip(LangTrans("global_errorname", 2),,,,, "red")
		Return
	}
	toggle := !toggle, GUI_name := "horizons" toggle
	Gui, %GUI_name%: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDhorizons
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.general.fWidth/2, 0
	Gui, %GUI_name%: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.horizons.main, vars.hwnd.horizons := {"main": horizons}

	If LLK_IsType(mode, "alpha") && (mode != "shaper")
		Gui, %GUI_name%: Add, Text, xs, % LLK_StringCase(db.mapinfo.maps[mode])
	Else If LLK_IsType(mode, "number") || (mode = "shaper")
	{
		Gui, %GUI_name%: Font, underline bold
		Gui, %GUI_name%: Add, Text, xs, horizons:
		Gui, %GUI_name%: Font, norm
		Gui, %GUI_name%: Add, Text, xs, % (mode = "shaper") ? "forge of the phoenix`nlair of the hydra`nmaze of the minotaur`npit of the chimera" : LLK_StringCase(db.mapinfo.maps[mode])
		If vars.log.level
		{
			Gui, %GUI_name%: Font, underline bold
			Gui, %GUI_name%: Add, Text, Section xs, e-exp:
			Gui, %GUI_name%: Font, norm
			Gui, %GUI_name%: Add, Text, ys, % LeveltrackerExperience(67 + vars.omnikey.item.tier,, "horizon")
		}
	}

	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %horizons%
	xPos := (vars.general.xMouse + w/2 > vars.monitor.x + vars.monitor.w - 1) ? vars.monitor.x + vars.monitor.w - w + 1 : (vars.general.xMouse - w/2 < vars.monitor.x ) ? vars.monitor.x : vars.general.xMouse - w/2
	yPos := (vars.general.yMouse - h < vars.monitor.y) ? vars.monitor.y : vars.general.yMouse - h
	Gui, %GUI_name%: Show, % "NA x"xPos " y"yPos
	LLK_Overlay(horizons, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	If (StrLen(mode) = 1) && LLK_IsType(mode, "alpha")
		KeyWait, % mode
}

Lab(mode := "", override := 0)
{
	local
	global vars, settings, Json
	static toggle := 0

	start := A_TickCount, check := LLK_HasVal(vars.hwnd.lab, vars.general.cMouse), control := SubStr(check, InStr(check, "_") + 1)
	While (mode = "override") && GetKeyState("LButton", "P") && (vars.lab.compass.rooms[control].name = vars.log.areaname)
		If (A_TickCount >= start + 250)
			vars.lab.rooms[vars.lab.room.1] := "", mode := "progress", override := control

	If (mode = "override")
		Return

	If !IsObject(vars.lab) || (mode = "init")
		vars.lab := {"rooms": []}

	If (mode = "link")
	{
		If GetKeyState(settings.hotkeys.tab, "P")
			LLK_ToolTip(LangTrans("global_releasekey") " " settings.hotkeys.tab, 0,,, "poelab")
		KeyWait, % settings.hotkeys.tab
		LLK_Overlay(vars.hwnd["tooltippoelab"], "destroy"), LLK_Overlay(vars.hwnd.lab.main, "destroy"), LLK_Overlay(vars.hwnd.lab.button, "destroy"), vars.lab.toggle := 0
		Run, % "https://www.poelab.com/"
		If settings.features.browser
		{
			WinWaitActive, ahk_group snipping_tools,, 2
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
				LLK_ToolTip(LangTrans("global_success"), 1.5,,,, "lime")
				Clipboard := "", vars.lab := {"rooms": []}
				FileDelete, img\lab compass.json
				step := 1
			}
			If (step = 1) && InStr(Clipboard, "www.poelab.com") && InStr(Clipboard, ".json")
			{
				step := 2
				Try lab_compass_json := Json.Load(HTTPtoVar(Clipboard))
				If lab_compass_json.Count()
				{
					LLK_ToolTip(LangTrans("global_success"), 1.5,,,, "lime")
					Loop, % lab_compass_json.rooms.Count()
						roomname := lab_compass_json.rooms[A_Index].name, lab_compass_json.rooms[A_Index].name := LangTrans("lab_" roomname) ? LangTrans("lab_" roomname) : roomname
					FileAppend, % Json.Dump(lab_compass_json), img\lab compass.json
					vars.tooltip_mouse := ""
					Break
				}
				Else LLK_ToolTip(LangTrans("global_fail"), 1.5,,,, "red")
				Clipboard := ""
			}
			Sleep 250
		}
		WinWaitActive, ahk_group poe_window
		If !step
		{
			LLK_ToolTip(LangTrans("global_abort"), 1.5, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "red", settings.general.fSize + 8,,, 1), Gdip_DisposeImage(pBitmap)
			Return
		}
		pBitmap_copy := Gdip_CloneBitmapArea(pBitmap, 257, 42, 1175, 556,, 1), Gdip_DisposeImage(pBitmap)
		pBitmap := Gdip_ResizeBitmap(pBitmap_copy, vars.client.w * 53/128, 10000, 1, 7, 1)
		Gdip_SaveBitmapToFile(pBitmap, "img\lab.jpg", 100), Gdip_DisposeImage(pBitmap_copy), Gdip_DisposeImage(pBitmap)
		Return
	}

	If !FileExist("img\lab.jpg")
		FileDelete, img\lab compass.json

	If !IsObject(vars.lab.compass) && FileExist("img\lab compass.json")
		vars.lab.compass := LLK_FileRead("img\lab compass.json"), vars.lab.compass := Json.Load(vars.lab.compass)
	If !vars.lab.scale
		pBitmap := Gdip_LoadImageFromFile("img\lab.jpg"), Gdip_GetImageDimensions(pBitmap, w, h), vars.lab.width := !w ? vars.client.w * 53/128 : w, vars.lab.height := !h ? (vars.client.w * 53/128)/2.112 : h, vars.lab.scale := vars.lab.width/1175, Gdip_DisposeImage(pBitmap)

	scale := vars.lab.scale, dim := 50 * scale, difficulties := {33: "normal", 55: "cruel", 68: "merciless", 75: "uber", 83: "uber"}, text_height := dim/2
	If !vars.lab.custom_font
		vars.lab.custom_font := LLK_FontSizeGet(text_height, width)

	If !vars.lab.rooms.Count()
	{
		If InStr(vars.log.areaID, "labyrinth_") && !InStr(vars.log.areaID, "airlock")
		{
			For index, room in vars.lab.compass.rooms
				If (room.name = vars.log.areaname)
				{
					vars.lab.room := [index, room.name], vars.lab.rooms[index] := {"name": room.name, "seed": ""}
					Break
				}
		}
		Else vars.lab.room := [1, vars.lab.compass.rooms.1.name], vars.lab.rooms.1 := {"name": vars.lab.compass.rooms.1.name, "seed": ""}
		started := 1, vars.lab.outdated := !Blank(vars.lab.compass.date) && (StrReplace(vars.lab.compass.date, "-") != SubStr(A_NowUTC, 1, 8)) ? 1 : 0
	}

	If (mode = "progress") && !started
	{
		vars.lab.room := [override ? override : vars.lab.exits.numbers[LLK_HasVal(vars.lab.exits.names, vars.log.areaname)], override ? vars.lab.compass.rooms[override].name : vars.lab.exits.names[LLK_HasVal(vars.lab.exits.names, vars.log.areaname)], vars.log.areaID]
		vars.lab.rooms[vars.lab.room.1] := {"name": vars.log.areaname, "seed": vars.log.areaseed}
	}
	Else If (mode = "backtrack")
		vars.lab.room := [override, vars.lab.rooms[override].name]

	If (vars.lab.room.2 = "aspirant's trial")
		Loop, % vars.lab.compass.rooms.Count()
		{
			If (A_Index = vars.lab.room.1)
				Continue
			Else If (A_Index < vars.lab.room.1)
				vars.lab.rooms[A_Index] := {"name": vars.lab.rooms[A_Index].name ? 1 : 0, "seed": vars.lab.rooms[A_Index].seed ? 1 : 0}
			Else vars.lab.rooms[A_Index] := ""
		}

	vars.lab.exits := {"numbers": [], "names": []}
	For dir, number in vars.lab.compass.rooms[vars.lab.room.1].exits
		vars.lab.exits.numbers.Push(number), vars.lab.exits.names.Push(vars.lab.compass.rooms[number].name)
	If mode && InStr("progress,init,backtrack", mode) && !GetKeyState(settings.hotkeys.tab, "P")
		Return

	toggle := !toggle, GUI_name := "lab_overlay" toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDlab"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"vars.lab.custom_font " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.lab.main, hwnd_old2 := vars.hwnd.lab.button, vars.hwnd.lab := {"main": lab}

	If vars.lab.outdated
	{
		Gui, %GUI_name%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Center w"vars.lab.width " h"vars.lab.height, % "`n`n" LangTrans("lab_outdated") "`n`n" LangTrans("lab_outdated", 2) " " vars.lab.compass.date "`n" LangTrans("lab_outdated", 3) " " SubStr(A_NowUTC, 1, 4) "-" SubStr(A_NowUTC, 5, 2) "-" SubStr(A_NowUTC, 7, 2)
		Gui, %GUI_name%: Font, % "s"vars.lab.custom_font
		Gui, %GUI_name%: Add, Pic, % "x0 y0 BackgroundTrans w"vars.lab.width " h"vars.lab.height, img\GUI\square_red_trans.png
	}
	Else If !InStr(vars.log.areaID, "airlock") && !Blank(vars.lab.compass.difficulty) && (difficulties[vars.log.arealevel] != vars.lab.compass.difficulty)
	{
		Gui, %GUI_name%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Center w"vars.lab.width " h"vars.lab.height, % "`n`n" LangTrans("lab_mismatch") "`n`n" LangTrans("lab_outdated", 2) " " vars.lab.compass.difficulty "`n" LangTrans("lab_mismatch", 2) " " difficulties[vars.log.arealevel]
		Gui, %GUI_name%: Font, % "s"vars.lab.custom_font
		Gui, %GUI_name%: Add, Pic, % "x0 y0 BackgroundTrans w"vars.lab.width " h"vars.lab.height, img\GUI\square_red_trans.png
		vars.lab.mismatch := 1
	}

	For index, room in vars.lab.compass.rooms
	{
		If InStr(vars.log.areaID, "airlock") || vars.lab.mismatch || vars.lab.outdated
			Continue
		If !Blank(LLK_HasVal(vars.lab.exits.numbers, index)) && (vars.lab.exits.numbers.Count() > 1) && !(vars.lab.room.2 = "aspirant's trial" && index > vars.lab.room.1) ;&& !(vars.lab.room.1 > index)
			Gui, %GUI_name%: Add, Text, % "BackgroundTrans Center x"(room.x + 12) * scale - dim/2 " w"dim*2 " y"(room.y + 48) * scale - text_height, % SubStr(room.name, 1, 2) " " SubStr(room.name, InStr(room.name, " ") + 1, 2)
		If (vars.lab.room.1 = index)
			Gui, %GUI_name%: Add, Pic, % "BackgroundTrans HWNDhwnd x"(room.x + 12) * scale " w"dim " h"dim " y"(room.y + 48) * scale, img\GUI\square_purple_trans.png
		Else If vars.lab.rooms[index].Count() && vars.lab.rooms[index].name
			Gui, %GUI_name%: Add, Pic, % "BackgroundTrans HWNDhwnd x"(room.x + 12) * scale " w"dim " h"dim " y"(room.y + 48) * scale, img\GUI\square_green_trans.png
		Else Gui, %GUI_name%: Add, Pic, % "BackgroundTrans HWNDhwnd x"(room.x + 12) * scale " w"dim " h"dim " y"(room.y + 48) * scale, img\GUI\square_trans.png
		vars.hwnd.lab["square_"index] := vars.hwnd.help_tooltips["lab_square"room.id] := hwnd
	}
	If FileExist("img\lab.jpg")
		Gui, %GUI_name%: Add, Pic, % "x0 y0", img\lab.jpg
	Else
	{
		Gui, %GUI_name%: Font, % "s"LLK_FontSizeGet(vars.lab.height/8, width)
		Gui, %GUI_name%: Add, Text, % "x0 y0 Center 0x200 w"vars.client.w * 53/128 " h"(vars.client.w * 53/128)/2.112, % LangTrans("cheat_loaderror") " img\lab.jpg"
		Gui, %GUI_name%: Font, % "s"vars.lab.custom_font
		file_missing := 1
	}

	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %lab%
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + vars.client.xc - w/2 " y"vars.monitor.y + vars.monitor.h - h
	WinGetPos, x, y,,, ahk_id %lab%

	GUI_name2 := "lab_button" toggle
	Gui, %GUI_name2%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDlab2"
	Gui, %GUI_name2%: Color, Black
	Gui, %GUI_name2%: Margin, 0, 0
	Gui, %GUI_name2%: Font, % "s"vars.lab.custom_font " cWhite", % vars.system.font

	Gui, %GUI_name2%: Add, Pic, % "h"dim*0.95 " w-1 HWNDhwnd", % "img\GUI\lab" (file_missing || vars.lab.outdated || vars.lab.mismatch ? "3" : Blank(vars.lab.compass.difficulty) ? "2" : "1") ".png"
	vars.hwnd.lab.button := lab2, vars.hwnd.help_tooltips["lab_button"] := hwnd
	Gui, %GUI_name2%: Show, % "NA x"x " y"y
	LLK_Overlay(lab, "show",, GUI_name), LLK_Overlay(lab2, "show",, GUI_name2)
	LLK_Overlay(hwnd_old, "destroy"), LLK_Overlay(hwnd_old2, "destroy")
}

Notepad(cHWND := "", hotkey := "", color := 0)
{
	local
	global vars, settings
	static toggle := 0, hwnd_reminder, hwnd_reminder_edit

	If (cHWND = "save") ;save any changes made to a note
	{
		If Blank(vars.notepad.selected_entry)
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
			If vars.hwnd.notepad_widgets.HasKey(vars.notepad.selected_entry)
				NotepadWidget(vars.notepad.selected_entry, 5, color)
		}
		Return
	}
	Else If (cHWND = "color")
	{
		Clipboard := ""
		SendInput, ^{c}
		ClipWait, 0.1
		If !Blank(Clipboard)
		{
			check := LLK_InStrCount(Clipboard, "§")
			If check && ((check != 2) || SubStr(Clipboard, 1, 1) != "§")
			{
				LLK_ToolTip(LangTrans("global_error") ": §",,,,, "red"), Clipboard := ""
				Return
			}
			prev_color := InStr(Clipboard, "§") && InStr(Clipboard, ": ") ? SubStr(Clipboard, InStr(Clipboard, "§") + 1, 6): "", color := LLK_StringCase(RGB_Picker(prev_color))
			If !Blank(color)
			{
				Sleep, 100
				parse := Clipboard
				While (SubStr(parse, 1, 1) = " ")
					parse := SubStr(parse, 2)
				While (SubStr(parse, 0) = " ")
					parse := SubStr(parse, 1, -1)
				If (SubStr(parse, 1, 1) = "§")
					Clipboard := StrReplace(Clipboard, SubStr(parse, 1, 9)), Clipboard := StrReplace(Clipboard, "§"), parse := SubStr(parse, 10, -1)
				If (color != prev_color)
					Clipboard := StrReplace(Clipboard, parse, "§" color ": " StrReplace(parse, "`r`n", "§`r`n§" color ": ") "§")
				SendInput, ^{v}
				Sleep 100
				Notepad("save",, 1)
			}
		}
		Return
	}

	start := A_TickCount, check := LLK_HasVal(vars.hwnd.notepad, cHWND), control := SubStr(check, InStr(check, "_") + 1), sum_height := 0, max_width := vars.monitor.w*0.9, max_height := vars.monitor.h*0.9

	If (check = "winbar")
	{
		start := A_TickCount
		While GetKeyState("LButton", "P")
		{
			If (A_TickCount >= start + 200)
			{
				LLK_Drag(vars.notepad.w, vars.notepad.h, xPos, yPos, 1, "notepad" toggle, 1)
				Sleep 1
			}
		}
		vars.general.drag := 0
		If !Blank(yPos)
			vars.notepad.x := xPos, vars.notepad.y := yPos
		Return
	}
	Else If InStr(check, "color_")
	{
		index := InStr(check, "textcolor_") ? 1 : 2
		If (vars.system.click = 1)
			rgb_picked := RGB_Picker(vars.notepad.settings[control][index])
		If (vars.system.click = 1) && Blank(rgb_picked)
			Return
		Else vars.notepad.settings[control][index] := (vars.system.click = 1) ? rgb_picked : ""
		IniWrite, % (vars.notepad.settings[control].1 = settings.notepad.color ? "" : vars.notepad.settings[control].1) "|" (vars.notepad.settings[control].2 = settings.notepad.color1 ? "" : vars.notepad.settings[control].2), ini\qol tools.ini, notepad tab settings, % control
		Notepad("save"), refresh_widget := vars.hwnd.notepad_widgets.HasKey(control) ? 1 : 0
	}
	Else If (A_Gui = "notepad_reminder")
	{
		NotepadWidget(LLK_ControlGet(hwnd_reminder_edit), -1)
		Gui, notepad_reminder: Destroy
		WinActivate, ahk_group poe_window
		Return
	}
	Else If (cHWND = vars.hwnd.LLK_panel.notepad && (hotkey = 2 || vars.system.click = 2)) && !WinExist("ahk_id " vars.hwnd.notepad.main)
	{
		If !WinExist("ahk_id " vars.hwnd.notepad_widgets.notepad_reminder_feature)
		{
			Gui, notepad_reminder: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_reminder", LLK-UI: notepad reminder
			Gui, notepad_reminder: Color, Black
			Gui, notepad_reminder: Margin, % settings.general.fWidth/2, % settings.general.fWidth/2
			Gui, notepad_reminder: Font, % "s" settings.general.fSize - 2 " cWhite", % vars.system.font

			Gui, notepad_reminder: Add, Text, Section, quick-note:
			Gui, notepad_reminder: Add, Edit, % "xs cBlack r1 HWNDhwnd_reminder_edit w"settings.general.fWidth*25
			Gui, notepad_reminder: Add, Button, % "Default Hidden xp yp wp hp gNotepad"
			Gui, notepad_reminder: Show, % "NA x10000 y10000"
			WinGetPos,,, width, height, ahk_id %hwnd_reminder%
			Gui, notepad_reminder: Show, % "x" vars.monitor.x + vars.client.xc - width/2 " y" vars.monitor.y + vars.client.yc - height/2
			vars.system.click := 1
			While WinActive("ahk_id " hwnd_reminder)
				Sleep 10
			If WinExist("ahk_id " hwnd_reminder)
				Gui, notepad_reminder: Destroy
		}
		Else LLK_Overlay(vars.hwnd.notepad_widgets.notepad_reminder_feature, "destroy"), vars.hwnd.notepad_widgets.Delete("notepad_reminder_feature")
		WinActivate, ahk_group poe_window
		Return
	}
	Else If (check = "winx") || (cHWND = vars.hwnd.LLK_panel.notepad) && WinExist("ahk_id " vars.hwnd.notepad.main)
	{
		KeyWait, LButton
		Notepad("save"), LLK_Overlay(vars.hwnd.notepad.main, "destroy"), vars.hwnd.notepad.main := ""
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
			error := InStr("[=]", A_LoopField) ? LangTrans("global_errorname", 5) . "[=]" : error
		If InStr(ini, "`n" name "=")
			error := LangTrans("global_errorname", 4)
		If Blank(name) || error
		{
			WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.notepad.name
			LLK_ToolTip(LangTrans("global_errorname", 2) . (error ? ":`n" error : ""), error ? 2 : 1, x, y + h,, "red")
			Return
		}
		Notepad("save"), vars.notepad.selected_entry := name
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
		If (hotkey = 2 || vars.system.click = 2)
		{
			If LLK_Progress(vars.hwnd.notepad["delbar_"control], "RButton")
			{
				IniDelete, ini\qol tools.ini, notepad, % control
				IniDelete, ini\qol tools.ini, notepad tab settings, % control
				vars.notepad.selected_entry := (control = vars.notepad.selected_entry) ? "" : vars.notepad.selected_entry
				If vars.hwnd.notepad_widgets.HasKey(control)
					LLK_Overlay(vars.hwnd.notepad_widgets[control], "destroy"), vars.hwnd.notepad_widgets.Delete(control)
				KeyWait, RButton
			}
			Else Return
		}
		If !Blank(vars.notepad.selected_entry)
			Notepad("save")
		vars.notepad.selected_entry := (hotkey = 1 || vars.system.click = 1) ? control : vars.notepad.selected_entry
	}
	Else If (check = "drag")
	{
		WinGetPos, x0, y0, w0, h0, % "ahk_id " vars.hwnd.notepad.note
		Notepad("save")
		While GetKeyState("LButton", "P")
		{
			MouseGetPos, xMouse, yMouse
			wBox := (xMouse - x0 < settings.general.fWidth*20) ? settings.general.fWidth*20 : (xMouse - x0 > max_width) ? max_width : xMouse - x0
			hBox := (yMouse - y0 < settings.general.fWidth*30) ? settings.general.fWidth*30 : (yMouse - y0 > max_height) ? max_height : yMouse - y0
			Sleep 1
		}
	}
	wBox := !wBox ? settings.notepad.fWidth*20 : wBox, hBox := !hBox ? settings.notepad.fWidth*30 : hBox
	toggle := !toggle, GUI_name := "notepad" toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDnotepad"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.general.fWidth/2, % settings.general.fWidth/2
	Gui, %GUI_name%: Font, % "s" settings.general.fSize - 2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.notepad.main, vars.hwnd.notepad := {"main": notepad}

	Gui, %GUI_name%: Add, Text, % "x-1 y-1 Section HWNDhwnd Center Border gNotepad", lailloken ui: notepad
	vars.hwnd.notepad.winbar := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+-1 HWNDhwnd Center Border gNotepad w"settings.general.fWidth*2, x
	vars.hwnd.notepad.winx := hwnd

	Gui, %GUI_name%: Font, % "s" settings.general.fSize
	Gui, %GUI_name%: Add, Text, % "xs Section Hidden Border cBlack x"settings.general.fWidth/2, % "  "
	Gui, %GUI_name%: Add, Text, % "ys x+-1 Hidden Border HWNDhwnd cBlack", % "  "
	ControlGetPos,,, w2,,, ahk_id %hwnd%
	Gui, %GUI_name%: Add, Text, % "ys x+-1 BackgroundTrans HWNDhwnd", % LangTrans("notepad_add") " "
	Gui, %GUI_name%: Font, % "s" settings.general.fSize - 4
	ControlGetPos,,, w,,, ahk_id %hwnd%
	Gui, %GUI_name%: Add, Edit, % "ys x+-1 r1 cBlack HWNDhwnd w"wBox
	vars.hwnd.notepad.name := hwnd
	Gui, %GUI_name%: Add, Button, % "xp yp wp hp Hidden Default gNotepad HWNDhwnd", OK
	vars.hwnd.notepad.add := hwnd
	Gui, %GUI_name%: Font, % "s" settings.general.fSize

	NotepadReload(), check := 0, entry_count := 0
	For entry, text in vars.notepad.entries
	{
		If (entry = "notepad_reminder_feature")
			Continue
		entry_count += 1, vars.notepad.selected_entry .= (entry_count = 1 && Blank(vars.notepad.selected_entry)) ? entry : ""
		If (vars.notepad.selected_entry = entry)
			Gui, %GUI_name%: Font, underline
		Gui, %GUI_name%: Add, Text, % "xs w" w . (entry_count = 1 ? " Section" : " y+-1") " BackgroundTrans Border Center HWNDhwnd gNotepad c" vars.notepad.settings[entry].1, % StrReplace(entry, "&", "&&")
		ControlGetPos,,,, h,, ahk_id %hwnd%
		If (vars.notepad.selected_entry = entry)
			Gui, %GUI_name%: Font, norm
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwndbar Range0-500 Background" vars.notepad.settings[entry].2 " c" vars.notepad.settings[entry].1, 0
		vars.hwnd.notepad["select_"entry] := hwnd, sum_height += h - 1, vars.hwnd.notepad["delbar_"entry] := vars.hwnd.help_tooltips["notepad_widget"handle] := hwndbar
		Gui, %GUI_name%: Add, Text, % "x+-1 hp Border BackgroundTrans HWNDhwnd0 gNotepad", % "  "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd01 c" vars.notepad.settings[entry].1, 100
		Gui, %GUI_name%: Add, Text, % "x+-1 hp Border BackgroundTrans HWNDhwnd1 gNotepad", % "  "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd11 c" vars.notepad.settings[entry].2, 100
		vars.hwnd.notepad["textcolor_" entry] := hwnd0, vars.hwnd.notepad["textcolor_" entry "_bar"] := vars.hwnd.help_tooltips["notepad_colors" handle] := hwnd01, check += !Blank(text) ? 1 : 0
		vars.hwnd.notepad["backcolor_" entry] := hwnd1, vars.hwnd.notepad["backcolor_" entry "_bar"] := vars.hwnd.help_tooltips["notepad_colors1" handle] := hwnd11, handle1 := handle "|", handle .= "|"
	}
	If (sum_height)
	{
		Gui, %GUI_name%: Add, Text, % "xs Center BackgroundTrans HWNDhwnd0 w" w + 2 * w2 - 2, % LangTrans("notepad_howto")
		ControlGetPos,,,, h0,, ahk_id %hwnd0%
		Gui, %GUI_name%: Font, % "s" settings.notepad.fSize
		Gui, %GUI_name%: Add, Edit, % "ys x+-1 cBlack -Wrap Multi Hidden HWNDhwnd"(Blank(vars.notepad.entries[vars.notepad.selected_entry]) ? " w"wBox : ""), % vars.notepad.entries[vars.notepad.selected_entry]
		ControlGetPos,,, w, h,, ahk_id %hwnd%
		w := (w < wBox) ? wBox : (w > max_width) ? max_width : w, sum_height += h0 - 1
		h := (h < hBox) ? hBox : (h > max_height) ? max_height : h
		ControlMove,,,, w,, % "ahk_id "vars.hwnd.notepad.name
		Gui, %GUI_name%: Add, Edit, % "xp yp cBlack -Wrap Multi HWNDhwnd w"w " h"h, % vars.notepad.entries[vars.notepad.selected_entry]
		vars.hwnd.help_tooltips["notepad_widget help"] := hwnd0, vars.hwnd.notepad.note := hwnd, size := settings.general.fWidth/2
		ControlGetPos, x, y, w, h,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Text, % "x"x + w - 1 " y"y + h - 1 " w"size " h"size " BackgroundWhite HWNDhwnd gNotepad BackgroundTrans", % ""
		vars.hwnd.notepad.drag := hwnd
		Gui, %GUI_name%: Add, Progress, % "x"x + w - 1 " y"y + h - 1 " w"size " h"size " BackgroundWhite", 0
		Gui, %GUI_name%: Margin, 0, 0
	}

	Gui, %GUI_name%: Show, NA x10000 y10000 AutoSize
	ControlFocus,, % "ahk_id "vars.hwnd.notepad.winbar
	WinGetPos, x, y, w, h, ahk_id %notepad%
	vars.notepad.w := w, vars.notepad.h := h
	ControlMove,,,, w - settings.general.fWidth*2 + 1,, % "ahk_id "vars.hwnd.notepad.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.notepad.winx
	Sleep 50
	xPos := Blank(vars.notepad.x) ? vars.monitor.x + vars.client.xc - w/2 : (vars.notepad.x + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : vars.notepad.x
	yPos := Blank(vars.notepad.y) ? vars.monitor.y + vars.client.yc - h/2 : (vars.notepad.y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : vars.notepad.y
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(notepad, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	If refresh_widget
		NotepadWidget(control)
}

NotepadReload()
{
	local
	global vars, settings
	static skip := ["font-color", "font-size", "button-offset", "x-coordinate button", "y-coordinate button", "transparency", "x-coordinate quicknote", "y-coordinate quicknote", "background color"]

	vars.notepad.entries := {"notepad_reminder_feature": vars.notepad.entries.notepad_reminder_feature}, vars.notepad.settings := {}
	ini := IniBatchRead("ini\qol tools.ini", "notepad"), ini1 := IniBatchRead("ini\qol tools.ini", "notepad tab settings")
	For key, val in ini.notepad
	{
		val := StrReplace(val, "(n)", "`n")
		If LLK_HasVal(skip, key)
			Continue
		vars.notepad.entries[key] := val, vars.notepad.settings[key] := StrSplit(!Blank(check := ini1[key]) ? check : settings.notepad.color "|" settings.notepad.color1, "|")
		Loop 2
			If Blank(vars.notepad.settings[key][A_Index])
				vars.notepad.settings[key][A_Index] := settings.notepad["color" (A_Index = 1 ? "" : "1")]
	}
}

NotepadWidget(tab, mode := 0, color := 0)
{
	local
	global vars, settings
	static toggle := 0, reminder_text

	If (mode = -1)
	{
		If Blank(tab)
			Return
		reminder_text := tab, tab := "notepad_reminder_feature"
		If !IsObject(vars.notepad.entries)
			vars.notepad.entries := {}
		LLK_PanelDimensions([reminder_text], settings.notepad.fSize, width, height)
		vars.notepad.entries[tab] := reminder_text, vars.notepad_widgets[tab] := {"x": Blank(settings.notepad.xQuickNote) ? vars.client.xc - width/2 + 1 : settings.notepad.xQuickNote, "y": Blank(settings.notepad.yQuickNote) ? vars.client.y - vars.monitor.y : settings.notepad.yQuickNote}
	}
	Else
	{
		If Blank(vars.notepad.entries[tab]) && A_Gui
		{
			LLK_ToolTip(LangTrans("cheat_entrynotext", 1, [StrReplace(tab, "&", "&&")]), 2,,,, "Red")
			Return
		}
		If (mode = 2) && GetKeyState("LButton", "P") ;prevent widget destruction while dragging
			Return
		start := A_TickCount
		If (mode = 2)
		{
			LLK_Overlay(vars.hwnd.notepad_widgets[tab], "destroy"), vars.hwnd.notepad_widgets.Delete(tab)
			KeyWait, RButton
			Return
		}

		If (mode != 5) ;mode 5 is used to refresh a widget whenever the text in the corresponding tab is changed
		{
			longpress := InStr(A_Gui, "notepad") ? 1 : 0
			While GetKeyState("LButton", "P") && !longpress
				If (A_TickCount >= start + 200)
					longpress := 1
		}

		If InStr(vars.notepad.entries[tab], "`n#`n") && (mode = 4)
			vars.notepad_widgets[tab].page += (vars.notepad_widgets[tab].page != vars.notepad_widgets[tab].text.Count()) ? 1 : 0, mode := 0
		Else If InStr(vars.notepad.entries[tab], "`n#`n") && (mode = 3)
			vars.notepad_widgets[tab].page -= (vars.notepad_widgets[tab].page > 1) ? 1 : 0, mode := 0
		Else If !A_Gui && !longpress && !color
			Return

		If InStr(vars.notepad.entries[tab], "`n#`n") && (InStr(A_Gui, "notepad") || color)
		{
			vars.notepad_widgets[tab] := {"text": [], "page": (vars.notepad_widgets[tab].page ? vars.notepad_widgets[tab].page : "1"), "x": vars.notepad_widgets[tab].x, "y": vars.notepad_widgets[tab].y}
			Loop, Parse, % StrReplace(vars.notepad.entries[tab], "`n#`n", "¢"), % "¢", % "`r`n"
				vars.notepad_widgets[tab].text.Push(A_LoopField)
			vars.notepad_widgets[tab].page := (vars.notepad_widgets[tab].page > vars.notepad_widgets[tab].text.Count()) ? vars.notepad_widgets[tab].text.Count() : vars.notepad_widgets[tab].page
		}
		Else If !InStr(vars.notepad.entries[tab], "`n#`n") && InStr(A_Gui, "notepad")
			vars.notepad_widgets[tab].Delete("text") ;simply delete this key in case a scrollable widget turns into a regular one
	}

	Loop, Parse, tab
		parse_name .= LLK_IsType(A_LoopField, "alnum") ? A_LoopField : "_"
	toggle := !toggle, GUI_name := "widget_" StrReplace(parse_name, " ", "_") . toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDwidget"(vars.notepad.toggle ? "" : " +E0x20")
	Gui, %GUI_name%: Color, % (tab = "notepad_reminder_feature") ? "White" : vars.notepad.settings[tab].2
	Gui, %GUI_name%: Margin, % settings.notepad.fWidth/2, 0
	Gui, %GUI_name%: Font, % "s" settings.notepad.fSize " c" (tab = "notepad_reminder_feature" ? "Red" : vars.notepad.settings[tab].1), % vars.system.font
	hwnd_old := vars.hwnd.notepad_widgets[tab], vars.hwnd.notepad_widgets[tab] := widget
	If (InStr(A_Gui, "notepad") || mode = 1)
		LLK_Overlay(hwnd_old, "destroy")

	/*
	If IsObject(vars.notepad_widgets[tab].text)
	{
		page := vars.notepad_widgets[tab].page, pages := vars.notepad_widgets[tab].text.Count()
		Gui, %GUI_name%: Add, Text, % "Section", % StrReplace(tab, "&", "&&") " (" page "/" pages "):`n" StrReplace(vars.notepad_widgets[tab].text[page], "&", "&&")
	}
	Else Gui, %GUI_name%: Add, Text, % "Section" (tab = "notepad_reminder_feature" ? " cRed" : ""), % StrReplace(vars.notepad.entries[tab], "&", "&&")
	*/

	If IsObject(vars.notepad_widgets[tab].text)
	{
		page := vars.notepad_widgets[tab].page, pages := vars.notepad_widgets[tab].text.Count(), multi := 1
		Gui, %GUI_name%: Add, Text, % "Section", % StrReplace(tab, "&", "&&") " (" page "/" pages "):" ;StrReplace(vars.notepad_widgets[tab].text[page], "&", "&&")
	}

	If (tab = "notepad_reminder_feature")
		Gui, %GUI_name%: Add, Text, % "Section cRed", % StrReplace(vars.notepad.entries[tab], "&", "&&")
	Else
	{
		Loop, Parse, % multi ? StrReplace(vars.notepad_widgets[tab].text[page], "&", "&&") : StrReplace(vars.notepad.entries[tab], "&", "&&"), `n
		{
			style := "xs Section y+0", segment := color := colon := rgb := ""
			If InStr(A_LoopField, "§",, 2) && (SubStr(A_LoopField, InStr(A_LoopField, "§") + 7, 2) = ": ")
			{
				Loop, Parse, A_LoopField
				{
					continue := 0
					If (A_LoopField = "§") && Blank(color)
					{
						If !Blank(segment)
						{
							Gui, %GUI_name%: Add, Text, % style, % segment
							style := "ys x+0"
						}
						color := "start", segment := "", continue := rgb := 1
					}
					Else If (A_LoopField = "§")
					{
						Gui, %GUI_name%: Add, Text, % style " c" color, % segment
						style := "ys x+0", color := segment := colon := rgb := "", continue := 1
					}
					Else If (color = "start") || !Blank(color) && (StrLen(color) < 6)
						color := (color = "start") ? A_LoopField : color . A_LoopField, continue := 1
					Else If !colon && rgb && (A_LoopField = ":")
						colon := A_Index
					If continue || colon && LLK_IsBetween(A_Index, colon, colon + 1)
						Continue
					segment .= A_LoopField
				}
			}
			Else segment := A_LoopField
			If !Blank(segment)
				Gui, %GUI_name%: Add, Text, % style, % segment
		}
	}

	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %widget%
	While longpress && (InStr(A_Gui, "notepad") || mode = 1) && GetKeyState("LButton", "P")
	{
		LLK_Drag(w, h, x, y,, GUI_name, 1)
		Sleep 1
	}
	vars.general.drag := 0
	If longpress && (tab = "notepad_reminder_feature") && !Blank(y)
	{
		settings.notepad.xQuickNote := x, settings.notepad.yQuickNote := y
		IniWrite, % x, ini\qol tools.ini, notepad, x-coordinate quicknote
		IniWrite, % y, ini\qol tools.ini, notepad, y-coordinate quicknote
	}

	If !vars.notepad.toggle && (tab != "notepad_reminder_feature")
		WinSet, Transparent, % 50 * settings.notepad.trans, % "ahk_id "widget
	If !IsObject(vars.notepad_widgets[tab])
		vars.notepad_widgets[tab] := {}
	If !Blank(y)
		vars.notepad_widgets[tab].x := x, vars.notepad_widgets[tab].y := y

	xPos := Blank(vars.notepad_widgets[tab].x) ? vars.client.xc - w/2 + 1 : vars.notepad_widgets[tab].x, xPos := (xPos >= vars.monitor.w / 2) ? xPos - w + 1 : xPos
	yPos := vars.notepad_widgets[tab].y, yPos := (yPos >= vars.monitor.h / 2) ? yPos - h + 1 : yPos
	Gui, %GUI_name%: Show, % "NA x"vars.monitor.x + xPos " y"vars.monitor.y + yPos
	LLK_Overlay(widget, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}
