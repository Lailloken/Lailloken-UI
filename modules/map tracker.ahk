Init_maptracker()
{
	local
	global vars, settings
	
	settings.features.maptracker := (settings.general.lang_client = "unknown") ? 0 : LLK_IniRead("ini\config.ini", "Features", "enable map tracker", 0)
	
	settings.maptracker := {"loot": LLK_IniRead("ini\map tracker.ini", "Settings", "enable loot tracker", 0)}
	settings.maptracker.kills := LLK_IniRead("ini\map tracker.ini", "Settings", "enable kill tracker", 0)
	settings.maptracker.mapinfo := LLK_IniRead("ini\map tracker.ini", "Settings", "log mods from map-info panel", 0)
	settings.maptracker.fSize := LLK_IniRead("ini\map tracker.ini", "Settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.maptracker.fSize, height, width)
	settings.maptracker.fWidth := width, settings.maptracker.fHeight := height
	settings.maptracker.oButton := LLK_IniRead("ini\map tracker.ini", "Settings", "button-offset", 1)
	settings.maptracker.sButton := Floor(vars.monitor.w* 0.03* settings.maptracker.oButton)
	settings.maptracker.xButton := LLK_IniRead("ini\map tracker.ini", "UI", "button xcoord")
	settings.maptracker.yButton := LLK_IniRead("ini\map tracker.ini", "UI", "button ycoord")
	settings.maptracker.rename := LLK_IniRead("ini\map tracker.ini", "settings", "rename boss maps", 1)
	settings.maptracker.sidecontent := LLK_IniRead("ini\map tracker.ini", "Settings", "track side-areas", 0)
	settings.maptracker.mechanics := LLK_IniRead("ini\map tracker.ini", "Settings", "track league mechanics", 0)
	settings.maptracker.portal_reminder := LLK_IniRead("ini\map tracker.ini", "Settings", "portal-scroll reminder", 0)
	settings.maptracker.xOffset := LLK_IniRead("ini\map tracker.ini", "UI", "map tracker x-offset", 0)
	settings.maptracker.yOffset := LLK_IniRead("ini\map tracker.ini", "UI", "map tracker y-offset", 0)
	If !IsObject(vars.maptracker)
		vars.maptracker := {"mechanics": {"blight": 1, "delirium": 1, "expedition": 1, "legion": 2, "ritual": 2, "harvest": 1, "incursion": 1, "bestiary": 1, "betrayal": 1, "delve": 1, "ultimatum": 1, "maven": 1}}
	For mechanic in vars.maptracker.mechanics
		settings.maptracker[mechanic] := LLK_IniRead("ini\map tracker.ini", "mechanics", mechanic, 0)

	vars.maptracker.dialog := InStr(LLK_FileRead(vars.system.config), "output_all_dialogue_to_chat=true")
}

Maptracker(cHWND := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.maptracker, cHWND)
	If check
	{
		If MaptrackerTowncheck() && (vars.maptracker.refresh_kills = 2)
			MaptrackerKills()
		Else If MaptrackerCheck(2)
			LLK_ToolTip(LangTrans("maptracker_save", 2), 1.5,,,, "Red")
		Else If !MaptrackerCheck(2) && vars.maptracker.map.date_time && LLK_Progress(vars.hwnd.maptracker.delbar, "LButton")
		{
			MaptrackerSave()
			vars.maptracker.Delete("map")
			MaptrackerGUI()
			LLK_ToolTip(LangTrans("maptracker_save", 1),,,,, "Lime")
			KeyWait, LButton
		}
		Return
	}

	start := A_TickCount
	While (A_Gui = "maptracker_button") && GetKeyState("LButton", "P")
	{
		If (A_TickCount >= start + 250)
		{
			WinGetPos,,, w, h, % "ahk_id "vars.hwnd.maptracker_button.main
			While GetKeyState("LButton", "P")
			{
				LLK_Drag(w, h, xPos, yPos)
				Sleep 1
			}
			KeyWait, LButton
			WinActivate, ahk_group poe_window
			settings.maptracker.xButton := xPos, settings.maptracker.yButton := yPos
			IniWrite, % settings.maptracker.xButton, ini\map tracker.ini, UI, button xcoord
			IniWrite, % settings.maptracker.yButton, ini\map tracker.ini, UI, button ycoord
			Return
		}
	}

	If (vars.system.click = 1) && !WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
		MaptrackerLogs()
	Else If (vars.system.click = 1) && WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
	{
		LLK_Overlay(vars.hwnd.maptracker_logs.main, "destroy")
		WinActivate, ahk_group poe_window
	}
	Else If (vars.system.click = 2)
	{
		GuiControl,, % vars.hwnd.maptracker_button.img, % "img\GUI\maptracker" . (vars.maptracker.pause ? "" : "0") . ".jpg"
		vars.maptracker.pause := vars.maptracker.pause ? 0 : 1
		MaptrackerGUI()
		WinActivate, ahk_group poe_window
	}
}

MaptrackerCheck(mode := 0) ;checks if player is in a map or map-related content
{
	local
	global vars, settings
	
	mode_check := ["abyssleague", "endgame_labyrinth_trials", "mapsidearea"]
	For key, val in {"mapworlds": 0, "maven": 0, "betrayal": 0, "incursion": 0, "heist": "heisthub", "mapatziri": 0, "legionleague": 0, "expedition": 0, "atlasexilesboss": 0, "breachboss": 0, "affliction": 0, "bestiary": 0, "sanctum": "sanctumfoyer", "synthesis": 0, "abyssleague": 0, "labyrinth_trials": 0, "mapsidearea": 0}
	{
		If !mode && LLK_HasVal(mode_check, key) || (mode = 1) && !LLK_HasVal(mode_check, key)
			Continue
		If InStr(vars.log.areaID, key) && (!val || val && !InStr(vars.log.areaID, val))
			Return 1
	}
		
}

MaptrackerEdit(cHWND := "")
{
	local
	global vars, settings

	edit := vars.maptracker.selected_edit ;short-cut variable
	If cHWND
	{
		text := LLK_ControlGet(vars.hwnd.maptracker_logs.mapedit)
		While InStr(text, "  ")
			text := StrReplace(text, "  ", " ")
		While (SubStr(text, 1, 1) = " ")
			text := SubStr(text, 2)
		While (SubStr(text, 0) = " ")
			text := SubStr(text, 1, -1)
		If Blank(text)
			Return
		IniWrite, % text, ini\map tracker log.ini, % vars.maptracker.active_date " " edit.1, map
		MaptrackerLogs()
		Gui, maptracker_edit: Destroy
		Return
	}
	Gui, maptracker_edit: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDmaptracker_edit"
	Gui, maptracker_edit: Color, Black
	Gui, maptracker_edit: Margin, 0, 0
	Gui, maptracker_edit: Font, % "s"settings.maptracker.fSize " cBlack", % vars.system.font
	vars.hwnd.maptracker_logs.maptracker_edit := maptracker_edit

	Gui, maptracker_edit: Add, Edit, % "HWNDhwnd w"edit.5 " h"edit.6, % SubStr(edit.2, 2)
	vars.hwnd.maptracker_logs.mapedit := hwnd
	Gui, maptracker_edit: Add, Button, % "HWNDhwnd xp yp hp Default Hidden gMaptrackerEdit", ok
	Gui, maptracker_edit: Show, % "x"edit.3 " y"edit.4

	While WinActive("ahk_id "maptracker_edit)
		Sleep, 100
	Gui, maptracker_edit: Destroy
}

MaptrackerGUI(mode := 0)
{
	local
	global vars, settings
	static wait

	If wait
		Return
	wait := 1
	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmaptracker" (vars.maptracker.toggle || vars.maptracker.pause ? " +E0x20" : "")
	Gui, %maptracker%: Color, Black
	Gui, %maptracker%: Margin, % settings.maptracker.fWidth/2, % settings.maptracker.fWidth/4
	Gui, %maptracker%: Font, % "s"settings.maptracker.fSize . (vars.maptracker.pause ? " cGray" : " cWhite"), % vars.system.font
	hwnd_old := vars.hwnd.maptracker.main, vars.hwnd.maptracker := {"main": maptracker}

	Gui, %maptracker%: Add, Text, % "Section BackgroundTrans HWNDhwnd", % Blank(vars.maptracker.map.name) ? "not tracking" : (InStr(vars.maptracker.map.name, ":") ? SubStr(vars.maptracker.map.name, InStr(vars.maptracker.map.name, ":") + 2) : vars.maptracker.map.name) " ("vars.maptracker.map.tier ")" (vars.maptracker.map.time ? " " FormatSeconds(vars.maptracker.map.time, 0) : "")
	vars.hwnd.maptracker.save := hwnd
	Gui, %maptracker%: Add, Progress, % "xp yp wp hp Disabled range0-500 BackgroundBlack cGreen HWNDhwnd", 0
	vars.hwnd.maptracker.delbar := hwnd

	For index, content in vars.maptracker.map.content
		Gui, %maptracker%: Add, Pic, % "ys hp w-1 BackgroundTrans", % "img\GUI\mapping tracker\" content ".png"
	
	If mode
	{
		vars.maptracker.loot := vars.maptracker.map.loot.Count() ? 1 : 0 ;flag to determine if the loot-list is on display
		For loot, stack in vars.maptracker.map.loot
		{
			loot := (StrLen(loot) > 30) ? SubStr(loot, 1, 30) . " [...]" : loot
			Gui, %maptracker%: Add, Text, % "xs Section"(A_Index = 1 ? " y+"settings.maptracker.fWidth/2 : " y+0"), % loot (stack > 1 ? " (" stack ")" : "")
		}
	}
	Else vars.maptracker.loot := 0

	Gui, %maptracker%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %maptracker%
	Gui, %maptracker%: Show, % "NA x"vars.client.x + vars.client.w - Floor(vars.client.h * 0.6155) - w " y"vars.client.y + vars.client.h - h
	;LLK_Overlay(vars.hwnd.maptracker.main, "show")
	LLK_Overlay(hwnd_old, "destroy"), wait := 0
}

MaptrackerKills()
{
	local
	global vars, settings

	If IsNumber(vars.maptracker.refresh_kills_last) && (vars.maptracker.refresh_kills_last + 500 > A_TickCount) ;prevent spamming this function
		Return

	Clipboard := "/kills"
	KeyWait, % settings.hotkeys.omnikey
	KeyWait, LButton
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, {Enter}^{a}^{v}{Enter}
	vars.maptracker.refresh_kills_last := A_TickCount
	Sleep, 100
	LogLoop(1)
}

MaptrackerLogs()
{
	local
	global vars, settings

	entries := {}, max_lines := Floor(vars.monitor.h*0.7 / settings.maptracker.fHeight)
	
	FileRead, ini, ini\map tracker log.ini
	Loop, Parse, ini, `n, `r
	{
		If InStr(A_LoopField, "[")
		{
			If object.Count()
				entries[date].InsertAt(1, object)
			date := SubStr(A_LoopField, 2, -1), time := SubStr(date, InStr(date, " ") + 1), date := SubStr(date, 1, InStr(date, " ") - 1), ddl .= InStr(ddl, date) ? "" : (!ddl ? "" : "|") . date
			If !IsObject(entries[date])
				entries[date] := []
			
			object := {"time": time}
		}
		Else
		{
			key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), val := (SubStr(val, 1, 1) = """") ? SubStr(val, 2, -1) : val
			Loop, Parse, val, `;, %A_Space% ;parse side-content info
			{
				If !A_LoopField || (key != "content")
					Continue
				If (A_Index = 1)
					val := "", parse := ""

				If InStr(A_LoopField, "(vaal area)")
					parse := "vaal area"
				Else If InStr(A_LoopField, "trial of ")
					parse := "lab trial"
				Else parse := A_LoopField
				val .= !val ? parse : "; " parse
			}
			object[key] := val
		}
	}
	If object.Count()
		entries[date].InsertAt(1, object)
	
	If vars.maptracker.active_date && InStr(ddl, vars.maptracker.active_date)
		ddl := StrReplace(ddl, vars.maptracker.active_date, vars.maptracker.active_date . (InStr(ddl, vars.maptracker.active_date "|") ? "|" : "||")) ;pre-select a previously-selected date
	Else vars.maptracker.active_date := "", choice := LLK_InStrCount(ddl, "|") + 1 ;else pre-select the last entry

	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmaptracker_logs"
	Gui, %maptracker_logs%: Color, Black
	Gui, %maptracker_logs%: Margin, -1, -1
	Gui, %maptracker_logs%: Font, % "s"settings.maptracker.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.maptracker_logs.main, vars.hwnd.maptracker_logs := {"main": maptracker_logs}

	Gui, %maptracker_logs%: Add, Text, % "x-1 y-1 Border Center Section HWNDhwnd0", % " lailloken ui: " LangTrans("maptracker_header") " "
	Gui, %maptracker_logs%: Add, Text, % "ys Border Center HWNDhwnd gMaptrackerLogs2 w"settings.maptracker.fWidth*2, % "x"
	vars.hwnd.maptracker_logs.winbar := hwnd0, vars.hwnd.maptracker_logs.winx := hwnd
	
	If ddl
	{
		Gui, %maptracker_logs%: Add, Text, % "xs Section y+"settings.maptracker.fHeight/4 " x"settings.maptracker.fWidth/2, % LangTrans("maptracker_logs")
		Gui, %maptracker_logs%: Font, % "s"settings.maptracker.fSize - 4
		Gui, %maptracker_logs%: Add, DDL, % "ys x+" settings.general.fWidth/2 " w"settings.maptracker.fWidth*8.5 " hp gMaptrackerLogs2 HWNDhwnd r"LLK_InStrCount(ddl, "|") + 1 . (choice ? " Choose"choice : ""), % ddl
		vars.hwnd.maptracker_logs.ddl := vars.hwnd.help_tooltips["maptracker_logviewer day-select"] := hwnd
		Gui, %maptracker_logs%: Font, % "s"settings.maptracker.fSize
		vars.maptracker.active_date := !vars.maptracker.active_date ? LLK_ControlGet(hwnd) : vars.maptracker.active_date

		Gui, %maptracker_logs%: Add, Text, % "ys x+-1 Border BackgroundTrans gMaptrackerLogs2 HWNDhwnd", % " " LangTrans("global_delete", 2) " "
		vars.hwnd.maptracker_logs.del_day := hwnd
		Gui, %maptracker_logs%: Add, Progress, % "xp yp wp hp Range0-500 HWNDhwnd BackgroundBlack cRed", 0
		vars.hwnd.maptracker_logs.delbar_day := vars.hwnd.help_tooltips["maptracker_logviewer day-delete"] := hwnd

		If (entries[vars.maptracker.active_date].Count() > max_lines)
		{
			vars.maptracker.active_page := !vars.maptracker.active_page ? 1 : vars.maptracker.active_page
			Gui, %maptracker_logs%: Add, Text, % "ys x+"settings.maptracker.fWidth, % LangTrans("maptracker_page")
			Loop, % Ceil(entries[vars.maptracker.active_date].Count() / max_lines)
			{
				Gui, %maptracker_logs%: Add, Text, % "ys Border Center gMaptrackerLogs2 HWNDhwnd x+"(A_Index = 1 ? settings.maptracker.fWidth/2 : settings.maptracker.fWidth/4) " w"settings.maptracker.fWidth*2 ;cont
				. (A_Index = vars.maptracker.active_page ? " cFuchsia" : ""), % A_Index
				vars.hwnd.maptracker_logs["page_"A_Index] := hwnd
			}
		}
		Else vars.maptracker.active_page := 1

		Gui, %maptracker_logs%: Add, Text, % "ys x+"settings.maptracker.fWidth, % LangTrans("maptracker_export", 1)
		Gui, %maptracker_logs%: Add, Text, % "ys Center BackgroundTrans Border gMaptrackerLogs2 HWNDhwnd x+" settings.general.fWidth/2, % " " LangTrans("maptracker_export", 2) " "
		vars.hwnd.maptracker_logs.export_day := hwnd
		Gui, %maptracker_logs%: Add, Progress, % "xp yp wp hp range0-500 HWNDhwnd BackgroundBlack cGreen", 0
		vars.hwnd.maptracker_logs.progress_day := vars.hwnd.help_tooltips["maptracker_logviewer export-day"] := hwnd
		Gui, %maptracker_logs%: Add, Text, % "ys Center BackgroundTrans Border gMaptrackerLogs2 HWNDhwnd x+"settings.maptracker.fWidth/4, %  " " LangTrans("maptracker_export", 3) " "
		vars.hwnd.maptracker_logs.export_all := hwnd
		Gui, %maptracker_logs%: Add, Progress, % "xp yp wp hp range0-500 HWNDhwnd BackgroundBlack cGreen", 0
		vars.hwnd.maptracker_logs.progress_all := vars.hwnd.help_tooltips["maptracker_logviewer export-all"] := hwnd
		Gui, %maptracker_logs%: Add, Text, % "ys Center BackgroundTrans Border gMaptrackerLogs2 HWNDhwnd x+"settings.maptracker.fWidth/4, %  " " LangTrans("maptracker_export", 4) " "
		vars.hwnd.maptracker_logs.export_folder := vars.hwnd.help_tooltips["maptracker_logviewer export-folder"] := hwnd
		Gui, %maptracker_logs%: Add, Text, % "yp x+0 w"settings.maptracker.fWidth/4, % " "
		
		;array with sub-arrays: sub-array.1 is the column's heading, 2 is the column-alignment
		table := [["#", "center"], ["time", "right"], ["map", "left"], ["tier", "right"], ["run", "right"], ["e-exp", "right"], ["deaths", "right"], ["portals", "right"], ["kills", "right"], ["loot", "center"] ;cont
		, ["mapinfo", "center"], ["content", "center"]], columns := {}
		
		For index, val in table
		{
			header := val.1, icon := InStr(" deaths, portals, kills, loot, mapinfo,", " "val.1 ",") ? 1 : 0, content_icons := 0
			For index, content in entries[vars.maptracker.active_date]
			{
				If (index > max_lines * vars.maptracker.active_page || index < (vars.maptracker.active_page - 1) * max_lines)
					Continue
				If !IsObject(columns[header])
					columns[header] := !icon ? [(header = "#") ? "." : LangTrans("maptracker_" header)] : ["."]
				If !LLK_HasVal(columns[header], (header = "#") ? index : (header = "time") ? SubStr(content[val.1], 1, 5) : (header = "run") ? FormatSeconds(content[val.1], 0) : content[val.1]) && !InStr(" loot, content, mapinfo,", " "val.1 ",")
					columns[header].Push((header = "#") ? index : (header = "time") ? SubStr(content[val.1], 1, 5) : (header = "run") ? FormatSeconds(content[val.1], 0) : content[val.1])
				If content.content
					content_icons := (LLK_InStrCount(content.content, ";") > content_icons) ? LLK_InStrCount(content.content, ";") : content_icons
			}
			;If !InStr("loot", header)
				LLK_PanelDimensions(columns[header], settings.maptracker.fSize, width, height,, 4)
			
			Gui, %maptracker_logs%: Font, % "s"settings.maptracker.fSize + 4
			LLK_FontDimensions(settings.maptracker.fSize + 4, font_height, font_width)
			width := (width < font_height) ? font_height : width, header_tooltips := ["map", "e-exp", "kills", "loot", "mapinfo", "content", "tier"]

			If (header = "content") && (width < content_icons * (settings.maptracker.fHeight * 1.33))
				width := content_icons * (settings.maptracker.fHeight * 1.33)

			Gui, %maptracker_logs%: Add, Text, % (A_Index = 1 ? "xs x-1 y+"settings.maptracker.fHeight/4 : "ys") . " Section BackgroundTrans Border Center HWNDhwnd w"width, % icon ? "" : (header = "#") ? "" : LangTrans("maptracker_" header)
			Gui, %maptracker_logs%: Font, % "s"settings.maptracker.fSize
			If icon
				Gui, %maptracker_logs%: Add, Pic, % "xp+"(width - font_height)/2 " yp hp w-1 HWNDhwnd", % "img\GUI\mapping tracker\"header ".png"
			If LLK_HasVal(header_tooltips, header)
				vars.hwnd.help_tooltips["maptracker_logviewer header "header] := hwnd

			For index, content in entries[vars.maptracker.active_date]
			{
				If (index > max_lines * vars.maptracker.active_page || index < (vars.maptracker.active_page - 1) * max_lines)
					Continue
				runs := entries[vars.maptracker.active_date].Count() + 1
				text := InStr(" loot, content, mapinfo,", " "val.1 ",") ? "" : (header = "#") ? runs - index : (val.2 = "left" ? " " : "") . (Blank(content[val.1]) ? (header = "e-exp") ? "" : 0 : content[val.1]) . (val.2 = "right" ? " " : "")
				text := (header = "time") ? SubStr(text, 1, 5) . " " : (header = "run") ? FormatSeconds(text, 0) " " : text
				Gui, %maptracker_logs%: Add, Text, % "xs Border BackgroundTrans HWNDhwnd0 "val.2 " w"width . (InStr(" loot, mapinfo,", " "val.1 ",") && content[val.1] || InStr(" map,", " "header ",") ? " gMaptrackerLogs2" : ""), % text
				If (header = "map")
				{
					Gui, %maptracker_logs%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd range0-500", 0
					vars.hwnd.maptracker_logs["delbar_"content.time] := hwnd
				}
				vars.hwnd.maptracker_logs[header "_"content.time] := hwnd0
				If (header = "content") && content[header]
				{
					Loop, Parse, % content[header], `;, %A_Space%
						Gui, %maptracker_logs%: Add, Pic, % (A_Index = 1 ? "xp+"settings.maptracker.fWidth/4 + 1 " yp+1 hp-2" : "x+"settings.maptracker.fWidth/4 " yp hp") " BackgroundTrans w-1", % "img\GUI\mapping tracker\" A_LoopField ".png"
				}
				If InStr(" loot, mapinfo,", " "val.1 ",")
					Gui, %maptracker_logs%: Add, Progress, % "xp yp w"width " hp Border BackgroundBlack cGreen Range0-1", % content[val.1] ? 1 : 0
			}
		}
	}
	Else Gui, %maptracker_logs%: Add, Text, % "xs Section cRed y+"settings.maptracker.fHeight/4 " x"settings.maptracker.fWidth/2, % LangTrans("maptracker_logs", 2)

	Gui, %maptracker_logs%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.maptracker_logs.main
	ControlMove,,,, % w - settings.maptracker.fWidth*2 + 1,, % "ahk_id "vars.hwnd.maptracker_logs.winbar
	ControlMove,, % w - settings.maptracker.fWidth*2,,,, % "ahk_id "vars.hwnd.maptracker_logs.winx
	ControlFocus,, % "ahk_id "vars.hwnd.maptracker_logs.winbar
	Gui, %maptracker_logs%: Show, % "NA x"vars.client.xc - w/2 " y"vars.monitor.y + vars.monitor.h/10
	LLK_Overlay(vars.hwnd.maptracker_logs.main, "show", 0)
	LLK_Overlay(hwnd_old, "destroy")
}

MaptrackerLogs2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.maptracker_logs, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	Switch check
	{
		Case "winx":
			LLK_Overlay(vars.hwnd.maptracker_logs.main, "destroy")
			WinActivate, ahk_group poe_window
		Case "ddl":
			vars.maptracker.active_date := LLK_ControlGet(cHWND), vars.maptracker.active_page := ""
			MaptrackerLogs()
		Case "del_day":
			If LLK_Progress(vars.hwnd.maptracker_logs.delbar_day, "LButton")
			{
				parse := LLK_IniRead("ini\map tracker log.ini")
				Loop, Parse, parse, `n, `r
					If InStr(A_LoopField, vars.maptracker.active_date)
						IniDelete, ini\map tracker log.ini, % A_LoopField
				vars.maptracker.active_date := "", MaptrackerLogs()
				KeyWait, LButton
			}
			If LLK_Progress(vars.hwnd.maptracker_logs.delbar_day, "RButton")
			{
				FileDelete, ini\map tracker log.ini
				Sleep, 250
				If FileExist("ini\map tracker log.ini")
				{
					LLK_FilePermissionError("delete", "ini\map tracker log.ini")
					Return
				}
				vars.maptracker.active_date := "", MaptrackerLogs()
				KeyWait, RButton
			}
		Case "export_day":
			If LLK_Progress(vars.hwnd.maptracker_logs.progress_day, "LButton")
				MaptrackerLogsCSV("day")
		Case "export_all":
			If LLK_Progress(vars.hwnd.maptracker_logs.progress_all, "LButton")
				MaptrackerLogsCSV("all")
		Case "export_folder":
			If !FileExist("exports\")
				LLK_FilePermissionError("create", "exports")
			Else Run, explore exports\
		Default:
			If InStr(check, "page_")
				vars.maptracker.active_page := control, MaptrackerLogs()
			Else If InStr(check, "loot_")
				MapTrackerLogTooltip(vars.maptracker.active_date " " control, "loot")
			Else If InStr(check, "mapinfo_")
				MapTrackerLogTooltip(vars.maptracker.active_date " " control, "mapinfo")
			Else If InStr(check, "map_")
			{
				If (vars.system.click = 1)
				{
					WinGetPos, x, y, w, h, % "ahk_id "cHWND
					vars.maptracker.selected_edit := [control, A_GuiControl, x, y, w, h]
					MaptrackerEdit()
				}
				Else If LLK_Progress(vars.hwnd.maptracker_logs["delbar_"control], "RButton")
				{
					IniDelete, ini\map tracker log.ini, % vars.maptracker.active_date " " control
					KeyWait, RButton
					MaptrackerLogs()
				}
			}
			Else LLK_ToolTip("no action")
	}
}

MaptrackerLogsCSV(mode)
{
	local
	global vars, settings

	entries := {}
	FileRead, ini, ini\map tracker log.ini
	Loop, Parse, ini, `n, `r
	{
		If InStr(A_LoopField, "[")
			date := SubStr(A_LoopField, 2, -1), date := StrReplace(date, " ", ", ",, 1), entries[date] := {}
		Else key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), entries[date][key] := val
	}
	
	file := "map logs" (mode = "day" ? " " StrReplace(vars.maptracker.active_date, "/", "-") : "") ".csv"
	;append := """date, time"",map,tier/level,run,e-exp,deaths,portals,kills,loot,map info,content"
	append := """" LangTrans("maptracker_time", 2) """," LangTrans("maptracker_map") "," LangTrans("maptracker_tier", 2) "," LangTrans("maptracker_run") "," LangTrans("maptracker_e-exp") "," LangTrans("maptracker_deaths") "," LangTrans("maptracker_portals") "," LangTrans("maptracker_kills1") "," LangTrans("maptracker_loot1") "," LangTrans("ms_map-info") "," LangTrans("maptracker_content")
	For date, val in entries
	{
		If (mode = "day") && !InStr(date, vars.maptracker.active_date)
			Continue
		date := """" date """", val.map := """" val.map """", val.run := """" FormatSeconds(val.run) ".00""", val.loot := """" (!val.loot ? "" : StrReplace(val.loot, "; ", "`r`n")) """"
		val.mapinfo := """" StrReplace(val.mapinfo, "; ", "`r`n") """"
		Loop, Parse, % val.content, `;, % A_Space
		{
			If (A_Index = 1)
				val.content := ""
			val.content .= (!val.content ? "" : "`r`n") (LangTrans("mechanic_" A_LoopField) ? LangTrans("mechanic_" A_LoopField) : (A_LoopField = 0) ? "" : A_LoopField)
		}
		append .= "`n" date "," val.map "," val.tier "," val.run "," val["e-exp"] "," val.deaths "," val.portals "," val.kills "," val.loot "," val.mapinfo ",""" val.content """"
	}

	If !FileExist("exports\")
	{
		folder_missing := 1
		FileCreateDir, exports\
		Sleep 250
	}
	If !FileExist("exports\") && folder_missing
	{
		LLK_FilePermissionError("create", "exports")
		Return
	}

	FileDelete, % "exports\"file
	FileAppend, % append, % "exports\"file
	LLK_ToolTip(LangTrans("maptracker_export") "`n" LangTrans("global_" (!ErrorLevel ? "success" : "fail")), 1.5,,,, !ErrorLevel ? "Lime" : "Red")
}

MapTrackerLogTooltip(ini_section, ini_key)
{
	local
	global vars, settings

	text := StrReplace(LLK_IniRead("ini\map tracker log.ini", ini_section, ini_key), "; ", "`n")
	LLK_ToolTip(text, 10000, vars.general.xMouse + settings.general.fWidth, vars.general.yMouse, "maptrackertooltip",, settings.maptracker.fSize)
	KeyWait, LButton
	vars.tooltip[vars.hwnd["tooltipmaptrackertooltip"]] := 1 ;manually overwrite the TickCount-value for this tooltip so it is destroyed immediately
}

MaptrackerLoot(mode := "")
{
	local
	global vars, settings
	static last := []

	If (mode = "clear")
		last := [], vars.maptracker.loot := 0 
	
	If !vars.maptracker.map.date_time || (mode = "clear") || !Screenchecks_ImageSearch("stash") || vars.maptracker.pause
		Return
	Else If (mode = "back")
	{
		If !last.Count() || !vars.maptracker.loot
			Return
		check := last.Pop()
		vars.maptracker.map.loot[check.1] -= check.2
		If !vars.maptracker.map.loot[check.1]
			vars.maptracker.map.loot.Delete(check.1)
		MaptrackerGUI(1)
		LLK_ToolTip(LangTrans("maptracker_loot", 2), 0.5,,,, "Lime")
		Return
	}
	
	Clipboard := ""
	;If settings.hotkeys.rebound_alt && settings.hotkeys.item_descriptions
	;	SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
	SendInput, ^{c}
	ClipWait, 0.1
	If !Clipboard
	{
		LLK_ToolTip(LangTrans("global_error"),,,,, "red")
		Return
	}
	Else Clipboard := LLK_StringCase(Clipboard)

	Loop, Parse, Clipboard, `n, `r
	{
		If (A_Index = 3)
			name := StrReplace(A_LoopField, "superior ")
		If (A_Index = 4) && !InStr(A_LoopField, "---")
			base := A_LoopField
		If StrMatch(A_LoopField, LangTrans("items_raity"))
			rarity := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)
		If StrMatch(A_LoopField, LangTrans("items_stack"))
		{
			stack := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), stack := SubStr(stack, 1, InStr(stack, "/") - 1)
			Loop, Parse, stack
				stack := (A_Index = 1) ? "" : stack, stack .= IsNumber(A_LoopField) ? A_LoopField : ""
		}
	}
	stack := !stack ? 1 : stack
	If (rarity = LangTrans("items_normal"))
		base := name
	Else If (rarity = LangTrans("items_unique"))
		base := ""
	
	If !name && !base
	{
		LLK_ToolTip(LangTrans("global_error", 3), 0.5,,,, "Red")
		Return
	}
	LLK_ToolTip(LangTrans("maptracker_loot", 1), 0.5,,,, "Lime")

	If Blank(vars.maptracker.map.loot[base ? base : name])
		vars.maptracker.map.loot[base ? base : name] := 0
	vars.maptracker.map.loot[base ? base : name] += stack

	last.Push([base ? base : name, stack])
	MaptrackerGUI(1)
}

MaptrackerMapinfo()
{
	local
	global vars, settings

	map := vars.mapinfo.active_map ;short-cut variable
	parse := map.mods . LangTrans("maps_stats", 1) " | " map.quantity . LangTrans("maps_stats", 2) " | " map.rarity . LangTrans("maps_stats", 4) . (map.packsize ? " | " map.packsize . LangTrans("maps_stats", 3) : "") "; "
	For index0, category in vars.mapinfo.categories
	{
		check := 0
		Loop 4
		{
			index1 := A_Index, check += map[category][A_Index].Count() ? 1 : 0
			check += map[category].0[A_Index].Count() ? 1 : 0
		}
		If !check
			Continue
		parse .= "- " category ":; "
		Loop 4
		{
			For index, val in map[category][5 - A_Index]
				parse .= val.1 "; "
			For index, val in map[category].0[5 - A_Index]
				parse .= val.1 "; "
		}
	}
	If (SubStr(parse, -1) = "; ")
		parse := SubStr(parse, 1, -2)
	vars.maptracker.map.mapinfo := parse, vars.mapinfo.active_map.expired := 1 ;flag to prevent the maptracker from logging the same map-info more than once
}

MaptrackerMechanicsCheck()
{
	local
	global vars, settings
	static wait

	check := 0, start := A_TickCount
	For mechanic, type in vars.maptracker.mechanics
		If (type = 2)
			check += !settings.maptracker[mechanic] || !FileExist("img\Recognition ("vars.client.h "p)\Mapping Tracker\"mechanic ".bmp") ? 0 : 1
	If wait || !check ;|| !LLK_IsBetween(vars.general.xMouse - vars.client.x, vars.client.x, vars.client.x + vars.client.w) || !LLK_IsBetween(vars.general.yMouse - vars.client.y, vars.client.y, vars.client.y + vars.client.h)
		Return
	wait := 1, pScreen := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
	If settings.general.blackbars ;crop the screenshot if there are black bars
		pScreen_copy := Gdip_CloneBitmapArea(pScreen, vars.client.x, 0, vars.client.w, vars.client.h,, 1), Gdip_DisposeImage(pScreen), pScreen := pScreen_copy

	For mechanic, type in vars.maptracker.mechanics
	{
		If (type != 2) || LLK_HasVal(vars.maptracker.map.content, mechanic)
			Continue
		pNeedle := Gdip_LoadImageFromFile("img\Recognition ("vars.client.h "p)\Mapping Tracker\"mechanic ".bmp")
		If (0 < Gdip_ImageSearch(pScreen, pNeedle, LIST,,,,, 10))
			vars.maptracker.map.content.Push(mechanic)
		Gdip_DisposeImage(pNeedle)
	}
	Gdip_DisposeImage(pScreen), MaptrackerGUI(), wait := 0
}

MaptrackerParseDialogue(line)
{
	local
	global vars, settings
	static blight, delirium, expedition, harvest, incursion, bestiary, betrayal, delve

	For mechanic, type in vars.maptracker.mechanics
		If (type = 1) && (InStr(vars.log.areaID, mechanic) || LLK_PatternMatch(vars.log.areaID, "", ["affliction", "maven", "heist", "sanctum", "primordialboss"])) ;don't track contents in league-specific instances (logbook, temple, syndicate hideouts, heists, etc.)
			Return

	For mechanic, type in vars.maptracker.mechanics
	{
		If (type != 1) || !settings.maptracker[mechanic] || LLK_HasVal(vars.maptracker.map.content, mechanic)
			Continue
		For index, identifier in vars.lang["log_" mechanic]
			If InStr(line, identifier, 1)
			{
				vars.maptracker.map.content.Push(mechanic)
				Return
			}
	}
}

MaptrackerReminder()
{
	local
	global vars, settings
	
	ignore := ["vaal area", "abyssal depths", "lab trial", "maven"]
	Clipboard := ""
	Sleep, 100

	If settings.hotkeys.item_descriptions && settings.hotkeys.rebound_alt
		SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
	Else SendInput, !^{c}
	ClipWait, 0.1
	For index, mechanic in vars.maptracker.map.content
	{
		For index0, mechanic0 in ignore
			If InStr(mechanic, mechanic0)
				Continue 2
		mechanics += 1
	}
	
	If InStr(Clipboard, "`r`nPortal Scroll`r`n", 1) && mechanics
		LLK_ToolTip(LangTrans("maptracker_check"), 3,,,, "aqua", settings.general.fSize + 4,,, 1)
}

MaptrackerSave(mode := 0)
{
	local
	global vars, settings

	map := vars.maptracker.map ;short-cut variable
	If settings.maptracker.kills
		vars.maptracker.map.kills := (vars.maptracker.map.kills.Count() = 2) ? vars.maptracker.map.kills.2 - vars.maptracker.map.kills.1 : 0
	Else vars.maptracker.map.kills := 0
	
	For key, val in vars.maptracker.map.content
		content .= !content ? val : "; " val

	For key, val in vars.maptracker.map.loot
		loot .= (!loot ? "" : "; ") . key . (val > 1 ? " ("val ")" : "")

	If !mode
		IniWrite, % "map=" map.name "`ntier=" map.tier "`nrun=" map.time "`nportals=" map.portals "`ndeaths=" map.deaths "`nkills=" map.kills "`ncontent=" (!content ? 0 : content) "`nloot=" (!loot ? 0 : loot) "`nmapinfo=" vars.maptracker.map.mapinfo "`ne-exp="map.experience (map.experience ? "%" : ""), ini\map tracker log.ini, % map.date_time
	vars.maptracker.map := {"date_time": vars.log.date_time, "id": vars.log.areaID, "seed": vars.log.areaseed, "tier": vars.log.areatier, "level": vars.log.arealevel, "portals": 1, "time": -1, "deaths": 0, "loot": {}, "content": []}
	MaptrackerLoot("clear")
	If WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
		MaptrackerLogs()
}

MaptrackerTimer()
{
	local
	global vars, settings
	static inactive
	
	If !settings.features.maptracker
		Return

	mapname_replace := {"mavenboss": LangTrans("maps_maven"), "mavenhub": LangTrans("maps_maven_invitation"), "MapWorldsPrimordialBoss1": LangTrans("maps_hunger"), "MapWorldsPrimordialBoss2": LangTrans("maps_blackstar"), "MapWorldsPrimordialBoss3": LangTrans("maps_exarch"), "MapWorldsPrimordialBoss4": LangTrans("maps_eater"), "MapWorldsShapersRealm": LangTrans("maps_shaper"), "MapWorldsElderArena": LangTrans("maps_elder"), "MapWorldsElderArenaUber": LangTrans("maps_elder", 2), "harvestleagueboss": LangTrans("maps_oshabi"), "mapatziri1": LangTrans("maps_atziri"), "mapatziri2": LangTrans("maps_atziri", 2), "atlasexilesboss5": LangTrans("maps_sirus")}
	mapname_add := {"heist": LangTrans("maps_heist"), "expedition": LangTrans("maps_logbook"), "affliction": LangTrans("maps_delirium")}

	If (!MaptrackerCheck(2) || vars.maptracker.pause) && !WinExist("ahk_id "vars.hwnd.maptracker.main) && (WinActive("ahk_group poe_window") || WinActive("ahk_id "vars.hwnd.maptracker_logs.main) || vars.settings.active = "mapping tracker") || vars.maptracker.toggle ;when in hideout or holding down TAB, show tracker GUI
		MaptrackerGUI(), inactive := 0
	Else If WinExist("ahk_id "vars.hwnd.maptracker.main) && (MaptrackerCheck(2) && !vars.maptracker.toggle && !vars.maptracker.pause) ;else hide it
		inactive += 1
	Else inactive := 0
	If WinExist("ahk_id "vars.hwnd.maptracker.main) && (inactive = 2)
		LLK_Overlay(vars.hwnd.maptracker.main, "destroy")

	If MaptrackerCheck() && (vars.maptracker.refresh_kills > 2) ;when re-entering a map after updating the kill-tracker, set its state to 2 so it starts flashing again the next time the hideout is entered
		vars.maptracker.refresh_kills := 2
	
	If MaptrackerTowncheck() && (vars.maptracker.refresh_kills = 2) && WinExist("ahk_id "vars.hwnd.maptracker.main) && !vars.maptracker.pause ;flash the tracker as a reminder to update the kill-count
	{
		Gui, % vars.hwnd.maptracker.main ": Color", % (vars.maptracker.color = "Maroon") ? "Black" : "Maroon"
		Gui, % vars.hwnd.maptracker.main ": -E0x20"
		vars.maptracker.color := (vars.maptracker.color = "Maroon") ? "Black" : "Maroon"
		GuiControl, % "+Background" vars.maptracker.color, % vars.hwnd.maptracker.delbar
	}
	Else If (!MaptrackerTowncheck() || (vars.maptracker.refresh_kills > 2)) && (vars.maptracker.color = "Maroon") && WinExist("ahk_id "vars.hwnd.maptracker.main) ;reset the tracker to black after updating the kill-count
	{
		Gui, % vars.hwnd.maptracker.main ": Color", Black
		vars.maptracker.color := "Black"
		GuiControl, +BackgroundBlack, % vars.hwnd.maptracker.delbar
	}

	If !MaptrackerCheck(2) || !settings.maptracker.sidecontent && MaptrackerCheck(1) || vars.maptracker.pause ;when outside a map, don't advance the timer (or track character-movement between maps/HO)
		Return

	If !IsObject(vars.maptracker.map) ;entering the very first map
		MaptrackerSave(1), new := 1 ;flag to specify that this is a new map
	Else
	{
		If !vars.maptracker.map.name && vars.log.areaname ;get the map's name from the client.txt's area-name
		{
			If settings.maptracker.rename
				For key, val in mapname_replace ;some area-names may be replaced for better filtering
					If (key = vars.log.areaID)
					{
						vars.maptracker.map.name := LangTrans("maps_boss") ": " val
						Break
					}
			For key, val in mapname_add ;some area-names are modified for better clarity, e.g. "heist: bunker", "logbook: XYZ"
				If StrMatch(vars.log.areaID, key)
				{
					vars.maptracker.map.name := val ": " vars.log.areaname
					Break
				}
			vars.maptracker.map.name := !vars.maptracker.map.name ? vars.log.areaname : vars.maptracker.map.name
		}
		If !MaptrackerCheck(1) && (vars.maptracker.map.id != vars.log.areaID || !InStr(vars.log.areaID, "sanctum") && vars.maptracker.map.seed != vars.log.areaseed) ;entering a new map
			MaptrackerSave(), new := 1

		vars.maptracker.map.portals += vars.maptracker.hideout && !new ? 1 : 0 ;entering through a portal from hideout? -> increase portal-count
		side_areas := {"lab trial": "endgame_labyrinth_trials_", "abyssal depths": "abyssleague", "vaal area": "mapsidearea"}

		If MaptrackerCheck(1)
			For key, val in side_areas
			{
				If LLK_HasVal(vars.maptracker.map.content, key) || !InStr(vars.log.areaID, val)
					Continue
				vars.maptracker.map.content.Push(key)
			}

		If settings.features.mapinfo && settings.maptracker.mapinfo && !vars.maptracker.map.mapinfo && !vars.mapinfo.active_map.expired && vars.mapinfo.active_map.name
		&& (InStr(vars.mapinfo.active_map.name, vars.maptracker.map.name) || LLK_HasVal(vars.mapinfo.categories, vars.log.areaname, 1) || vars.mapinfo.active_map.tag && InStr(vars.log.areaID, vars.mapinfo.active_map.tag))
		{
			If LLK_PatternMatch(vars.mapinfo.active_map.tag, "", ["mavenhub", "heist"])
				vars.maptracker.map.name := (settings.maptracker.rename && vars.mapinfo.active_map.tag = "mavenhub" ? LangTrans("maps_boss") ": " : "") LLK_StringCase(vars.mapinfo.active_map.name)
			MaptrackerMapinfo() ;include map-info in logs
		}

		If vars.log.level && !vars.maptracker.map.experience
			vars.maptracker.map.experience := StrReplace(LeveltrackerExperience(), "%")
	}
	If new && settings.maptracker.kills ;if entered map is new and kill-tracker is enabled, create a reminder-tooltip that follows the mouse
		ToolTip_Mouse("killtracker"), vars.maptracker.refresh_kills := 1 ;three-state flag used to determine which kill-count is parsed from the client-log and how the tracker needs to be colored
	vars.maptracker.map.time += 1 ;advance the timer
}

MaptrackerTowncheck()
{
	local
	global vars, settings

	If InStr(vars.log.areaID, "hideout") || InStr(vars.log.areaID, "heisthub") || InStr(vars.log.areaID, "menagerie") || InStr(vars.log.areaID, "sanctumfoyer")
		Return 1
}
