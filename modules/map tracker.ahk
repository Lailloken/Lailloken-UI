Init_maptracker()
{
	local
	global vars, settings

	settings.features.maptracker := (settings.general.lang_client = "unknown") ? 0 : LLK_IniRead("ini\config.ini", "Features", "enable map tracker", 0)

	If !IsObject(settings.maptracker)
		settings.maptracker := {}
	settings.maptracker.loot := LLK_IniRead("ini\map tracker.ini", "Settings", "enable loot tracker", 0)
	settings.maptracker.hide := LLK_IniRead("ini\map tracker.ini", "Settings", "hide panel when paused", 0)
	settings.maptracker.kills := LLK_IniRead("ini\map tracker.ini", "Settings", "enable kill tracker", 0)
	settings.maptracker.mapinfo := LLK_IniRead("ini\map tracker.ini", "Settings", "log mods from map-info panel", 0)
	settings.maptracker.notes := LLK_IniRead("ini\map tracker.ini", "Settings", "enable notes", 0)
	settings.maptracker.fSize := LLK_IniRead("ini\map tracker.ini", "Settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.maptracker.fSize, height, width)
	settings.maptracker.fWidth := width, settings.maptracker.fHeight := height
	settings.maptracker.rename := LLK_IniRead("ini\map tracker.ini", "settings", "rename boss maps", 1)
	settings.maptracker.sidecontent := LLK_IniRead("ini\map tracker.ini", "Settings", "track side-areas", 0)
	settings.maptracker.mechanics := LLK_IniRead("ini\map tracker.ini", "Settings", "track league mechanics", 0)
	settings.maptracker.portal_reminder := LLK_IniRead("ini\map tracker.ini", "Settings", "portal-scroll reminder", 0)
	settings.maptracker.portal_hotkey := LLK_IniRead("ini\map tracker.ini", "Settings", "portal-scroll hotkey")
	If !Blank(settings.maptracker.portal_hotkey)
	{
		Hotkey, If, (vars.log.areaID = vars.maptracker.map.id) && settings.features.maptracker && settings.maptracker.mechanics && settings.maptracker.portal_reminder && vars.maptracker.map.content.Count() && WinActive("ahk_id " vars.hwnd.poe_client)
		If settings.maptracker.portal_hotkey_old
			Hotkey, % "~" settings.maptracker.portal_hotkey_old, MaptrackerReminder, Off
		Hotkey, % "~" settings.maptracker.portal_hotkey, MaptrackerReminder, On
		settings.maptracker.portal_hotkey_old := settings.maptracker.portal_hotkey_single := settings.maptracker.portal_hotkey
		Loop, Parse, % "+!^#"
			settings.maptracker.portal_hotkey_single := StrReplace(settings.maptracker.portal_hotkey_single, A_LoopField)
		If Blank(settings.maptracker.portal_hotkey_single)
			settings.maptracker.portal_hotkey_single := settings.maptracker.portal_hotkey
	}
	settings.maptracker.xCoord := LLK_IniRead("ini\map tracker.ini", "Settings", "x-coordinate")
	settings.maptracker.yCoord := LLK_IniRead("ini\map tracker.ini", "Settings", "y-coordinate")
	settings.maptracker.dColors := {"date_unselected": "404040", "date_selected": "606060", "league 1": "330000", "league 2": "001933", "league 3": "003300", "league 4": "330066"}
	settings.maptracker.colors := {}
	If !IsObject(vars.maptracker)
		vars.maptracker := {"keywords": [], "mechanics": {"blight": 1, "delirium": 1, "expedition": 1, "legion": 2, "ritual": 2, "harvest": 1, "incursion": 1, "bestiary": 1, "betrayal": 1, "delve": 1, "ultimatum": 1, "maven": 1}}, vars.maptracker.leagues := [["crucible", 20230407, 20230815], ["ancestor", 20230818, 20231205], ["affliction", 20231208, 20240401], ["necropolis", 20240329, 20250101]], vars.maptracker.notes := LLK_IniRead("ini\map tracker.ini", "UI", "notes")
	For mechanic in vars.maptracker.mechanics
		settings.maptracker[mechanic] := LLK_IniRead("ini\map tracker.ini", "mechanics", mechanic, 0)

	settings.maptracker.colors.date_unselected := LLK_IniRead("ini\map tracker.ini", "UI", "date_unselected color", settings.maptracker.dColors.date_unselected)
	settings.maptracker.colors.date_selected := LLK_IniRead("ini\map tracker.ini", "UI", "date_selected color", settings.maptracker.dColors.date_selected)
	For index, array in vars.maptracker.leagues
		settings.maptracker.colors["league " index] := LLK_IniRead("ini\map tracker.ini", "UI", "league " index " color", settings.maptracker.dColors["league " index])
	vars.maptracker.dialog := InStr(LLK_FileRead(vars.system.config), "output_all_dialogue_to_chat=true")
}

Maptracker(cHWND := "", hotkey := "")
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.maptracker, cHWND)
	If check
	{
		If (check = "drag")
		{
			If (hotkey = 2)
				settings.maptracker.xCoord := settings.maptracker.yCoord := "", write := 1
			start := A_TickCount
			While (hotkey = 1) && GetKeyState("LButton", "P")
				If (A_TickCount >= start + 500)
				{
					If !width
					{
						WinGetPos,,, width, height, % "ahk_id " vars.hwnd.maptracker.main
						vars.maptracker.drag := 1, gui_name := GuiName(vars.hwnd.maptracker.main)
					}
					LLK_Drag(width, height, xPos, yPos,, gui_name, 1)
					Sleep 1
				}
			If !Blank(xPos) || !Blank(yPos)
				settings.maptracker.xCoord := Blank(xPos) ? "center" : xPos + (xPos >= vars.monitor.w / 2 ? 1 : 0), settings.maptracker.yCoord := yPos + (yPos >= vars.monitor.h / 2 ? 1 : 0), write := 1
			If write
			{
				IniWrite, % settings.maptracker.xCoord, ini\map tracker.ini, Settings, x-coordinate
				IniWrite, % settings.maptracker.yCoord, ini\map tracker.ini, Settings, y-coordinate
				MaptrackerGUI(), vars.maptracker.drag := 0
			}
			Return
		}
		If (check = "notes")
		{
			MaptrackerNoteEdit("edit")
			Return
		}
		If (hotkey = 2)
			Return
		If MaptrackerTowncheck() && (vars.maptracker.refresh_kills = 2)
			MaptrackerKills()
		Else If MaptrackerCheck(2)
			LLK_ToolTip(LangTrans("maptracker_save", 2), 1.5,,,, "Red")
		Else If !MaptrackerCheck(2) && vars.maptracker.map.date_time && LLK_Progress(vars.hwnd.maptracker.delbar, "LButton")
		{
			MaptrackerSave(), vars.maptracker.Delete("map"), MaptrackerGUI()
			LLK_ToolTip(LangTrans("maptracker_save", 1),,,,, "Lime")
			KeyWait, LButton
		}
		Return
	}

	If (hotkey = 1) && !WinExist("ahk_id " vars.hwnd.maptracker_logs.main)
		MaptrackerLogs()
	Else If (hotkey = 1) && WinExist("ahk_id " vars.hwnd.maptracker_logs.main)
	{
		LLK_Overlay(vars.hwnd.maptracker_logs.main, "destroy")
		WinActivate, ahk_group poe_window
	}
	Else If (hotkey = 2)
	{
		GuiControl,, % vars.hwnd.LLK_panel.maptracker, % "img\GUI\maptracker" . (vars.maptracker.pause ? "" : "0") . ".png"
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
		If !mode && !Blank(LLK_HasVal(mode_check, key)) || (mode = 1) && Blank(LLK_HasVal(mode_check, key))
			Continue
		If InStr(vars.log.areaID, key) && (!val || val && !InStr(vars.log.areaID, val))
			Return 1
	}
}

MaptrackerDateSelect()
{
	local
	global vars, settings
	static toggle := 0, pick, leagues

	KeyWait, LButton
	entries := vars.maptracker.entries, active_date := vars.maptracker.active_date
	If !leagues
		leagues := vars.maptracker.leagues
	If !IsObject(vars.hwnd.maptracker_dates)
		vars.hwnd.maptracker_dates := {}

	runs := {}, years := {}, months := {}, lMonth := 0, month_names := []
	Loop 12
	{
		FormatTime, month, % 200000 + A_Index, MMM
		lMonth := (StrLen(month) > lMonth) ? StrLen(month) : lMonth, month_names.Push(LLK_StringCase(month))
	}

	For date, array in entries
		For index, object in array
			runs[date "," object.time] := "", years[SubStr(date, 1, 4)] := "", months[SubStr(date, 6, 2) " " month_names[SubStr(date, 6, 2)]] := ""

	If !runs.Count()
	{
		If A_Gui
			LLK_ToolTip(LangTrans("global_match"), 1.5,,,, "red")
		LLK_Overlay(vars.hwnd.maptracker_dates.main, "destroy")
		Return
	}

	WinGetPos, xLogs, yLogs, wLogs, hLogs, % "ahk_id " vars.hwnd.maptracker_logs.main
	WinGetPos, xButton, yButton,,, % "ahk_id " vars.hwnd.maptracker_logs.date_selected
	toggle := !toggle, GUI_name := "maptracker_dates" toggle, pick := !pick ? vars.maptracker.active_date : pick
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDmaptracker_dates"
	Gui, %GUI_name%: Color, 800080
	WinSet, TransColor, 800080
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize + 2 " cWhite", % vars.system.font
	;Gui, %GUI_name%: Add, Pic, % "BackgroundTrans w" wLogs " h" hLogs, % "img\GUI\square_black.png"

	hwnd_old := vars.hwnd.maptracker_dates.main, vars.hwnd.maptracker_dates := {"main": maptracker_dates, "toggle": toggle}, column := []

	If Blank(LLK_HasKey(runs, SubStr(pick, 1, 4), 1))
		year_override := 1

	For index, array in leagues
	{
		run_count := 0
		For run in runs
			If LLK_IsBetween(StrReplace(SubStr(run, 1, 10), "/"), array.2, array.3)
				run_count += 1
		If !run_count
			Continue
		column.Push(array.1 " (" run_count ")")
	}
	If column.Count()
		LLK_PanelDimensions(column, settings.maptracker.fSize + 2, wColumn, hColumn)

	For year in years
	{
		If (years.Count() > 1) && (A_Index = 1)
		{
			Gui, %GUI_name%: Add, Text, % "Section Hidden Center Border BackgroundTrans", % ""
			allButton := 1
		}

		If !league_count
			For index, array in leagues
			{
				run_count_league := 0
				For run in runs
					If LLK_IsBetween(StrReplace(SubStr(run, 1, 10), "/"), array.2, array.3)
						run_count_league += 1
				If !run_count_league
					Continue

				Gui, %GUI_name%: Add, Text, % "xs" (!league_count ? " Section" (allButton ? " y+-1" : "") : " y+-1") " Border BackgroundTrans" (active_date = array.1 ? " cLime" : "") . " w" wColumn, % " " array.1 " (" run_count_league ")"
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd Border Range0-500 cRed Background" settings.maptracker.colors["league " index], 0
				vars.hwnd.maptracker_dates[array.1] := hwnd, league_count .= "|"
				ControlGetPos,,,, hRow,, ahk_id %hwnd%
			}

		If league_count && (A_Index = 1)
			Gui, %GUI_name%: Add, Progress, % "ys x+-1 Section Background606060 w" settings.maptracker.fWidth/2 " h" hRow * StrLen(league_count) - (StrLen(league_count) - 1)

		If wControl
			LLK_PanelDimensions(["  " year " (" LLK_HasKey(runs, year, 1,, 1).Count() ")  "], settings.maptracker.fSize + 2, wControl1, hControl1), width0 := (wControl >= wControl1) ? " wp" : " w" wControl1
		pick := (A_Index = years.Count()) && year_override && !Blank(LLK_HasKey(runs, year, 1)) ? year : pick
		Gui, %GUI_name%: Add, Text, % "ys" (A_Index = 1 ? " Section" : "") " x+-1 Center Border BackgroundTrans" (StrMatch(year, active_date, 1) ? " cLime" : "") . (width0 ? width0 : ""), % "  " year " (" LLK_HasKey(runs, year, 1,, 1).Count() ")  "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd Border Range0-500 cRed Background" settings.maptracker.colors["date_" (InStr(pick, year) ? "" : "un") "selected"], 0
		vars.hwnd.maptracker_dates[year] := hwnd

		If (A_Index = years.Count())
		{
			Gui, %GUI_name%: Add, Pic, % "ys x+-1 hp-2 w-1 Border BackgroundTrans", img\GUI\help.png
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border HWNDhwnd Background" settings.maptracker.colors.date_unselected, 0
			vars.hwnd.help_tooltips["maptracker_logviewer date help"] := hwnd
		}
		ControlGetPos, xControl, yYear, wControl, hYear,, ahk_id %hwnd%
		wYears := xControl + wControl
		If (years.Count() > 1) && (A_Index = years.Count())
		{
			Gui, %GUI_name%: Add, Text, % "x0 y0 Center Border HWNDhwnd00 BackgroundTrans w" wYears . (active_date = "all" ? " cLime" : ""), % LangTrans("maptracker_all") " (" runs.Count() ")"
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd0 Border Range0-500 cRed Background" settings.maptracker.colors.date_unselected, 0
			vars.hwnd.maptracker_dates.all := hwnd0, vars.hwnd.maptracker_dates.all_button := hwnd00
		}
	}

	For year in years
		If InStr(pick, year)
			For month in months
			{
				run_count := LLK_HasKey(runs, year "/" SubStr(month, 1, 2), 1,, 1).Count()
				If run_count
				{
					color := StrMatch(active_date, year "/" SubStr(month, 1, 2), 1) ? " cLime" : ""
					Gui, %GUI_name%: Add, Text, % (!added ? "xs y" yYear + hYear - 1 : "ys x+-1") " Section Border BackgroundTrans" color, % " " SubStr(month, InStr(month, " ") + 1) . (run_count ? " (" run_count ") " : " ")
					Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd Border Range0-500 cRed Background" settings.maptracker.colors.date_selected, 0
					added := 1, vars.hwnd.maptracker_dates[year "/" SubStr(month, 1, 2)] := hwnd
					For date, array in entries
					{
						If !InStr(date, year "/" SubStr(month, 1, 2))
							Continue
						For index, array0 in leagues
							If LLK_IsBetween(StrReplace(date, "/"), array0.2, array0.3)
							{
								color := settings.maptracker.colors["league " index]
								Break
							}
							Else color := settings.maptracker.colors.date_unselected
						Gui, %GUI_name%: Add, Text, % "xs y+-1 Border Right wp BackgroundTrans" (InStr(active_date, date) ? " cLime": ""), % " " SubStr(date, 9, 2) + 0 " (" Format("{:0" StrLen(run_count) "}", array.Count()) ") "
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd Border Range0-500 cRed Background" color, 0
						vars.hwnd.maptracker_dates[date] := hwnd
					}
				}
			}
	Gui, %GUI_name%: Show, % "x" xButton " y" yButton
	LLK_Overlay(maptracker_dates, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	WinWaitActive, ahk_id %maptracker_dates%
	KeyWait, LButton
	While WinActive("ahk_id " maptracker_dates) 	;loop that waits for inputs while the date selection is on screen
	{									;some drawbacks: GetKeyState doesn't work with certain keys (similar loops in the script use dedicated hotkeys, but the hotkeys section has become bloated)
		check := LLK_HasVal(vars.hwnd.maptracker_dates, vars.general.cMouse)
		If !Blank(check) && GetKeyState("LButton", "P")
		{
			pick := check, selection := 1
			If IsNumber(pick)
			{
				KeyWait, LButton
				KeyWait, LButton, D T0.2
				double_click := !ErrorLevel
			}
			If InStr(pick, "/") && (StrLen(check) > 4) || LLK_HasVal(vars.maptracker.leagues, pick,,,, 1) || double_click || (pick = "all")
			{
				vars.maptracker.active_date := pick, MaptrackerLogs()
				Break
			}
			SetTimer, MaptrackerDateSelect, -100
			Break
		}
		If GetKeyState("DEL", "P") && vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.maptracker_dates, vars.general.cMouse))
		{
			delHWND := vars.general.cMouse
			If LLK_Progress(delHWND, "DEL")
			{
				delDate := LLK_HasVal(vars.hwnd.maptracker_dates, vars.general.cMouse)
				league_check := LLK_HasVal(leagues, delDate,,,, 1)
				Loop, Parse, % LLK_IniRead("ini\map tracker log.ini"), `n, `r
					If (league_check && LLK_IsBetween(StrReplace(SubStr(A_LoopField, 1, InStr(A_LoopField, " ") - 1), "/"), leagues[league_check].2, leagues[league_check].3) || StrMatch(A_LoopField, delDate) || (delDate = "all")) && runs.HasKey(StrReplace(A_LoopField, " ", ","))
						IniDelete, ini\map tracker log.ini, % A_LoopField
				KeyWait, DEL
				If InStr(active_date, delDate)
				{
					vars.maptracker.active_date := "all"
					If (delDate = "all")
						vars.maptracker.keywords := []
				}
				MaptrackerLogs(StrMatch(active_date, delDate) || delDate = "all" || (active_date = "all") ? "DEL" : "refresh")
				SetTimer, MaptrackerDateSelect, -100
				Break
			}
		}
		Sleep 10
	}
	If !delDate && (pick = "all" || double_click || !selection || InStr(pick, "/") && (StrLen(pick) > 4) || LLK_HasVal(vars.maptracker.leagues, pick,,,, 1))
		LLK_Overlay(maptracker_dates, "destroy") ;, pick := vars.maptracker.active_date
}

MaptrackerEdit(cHWND := "")
{
	local
	global vars, settings

	edit := vars.maptracker.selected_edit ;short-cut variable
	If cHWND
	{
		text := LLK_ControlGet(vars.hwnd.maptracker_logs.mapedit)
		If LLK_PatternMatch(text, "", ["[", "=", "]"])
		{
			LLK_ToolTip(LangTrans("global_errorname", 5) "[=]", 2,,,, "red")
			Return
		}
		While InStr(text, "  ")
			text := StrReplace(text, "  ", " ")
		While (SubStr(text, 1, 1) = " ")
			text := SubStr(text, 2)
		While (SubStr(text, 0) = " ")
			text := SubStr(text, 1, -1)
		If Blank(text)
			Return
		IniWrite, % text, ini\map tracker log.ini, % edit.1, map
		MaptrackerLogs()
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
		Sleep, 10
	Gui, maptracker_edit: Destroy
}

MaptrackerFilter(content) ;checks a run's characteristics based on the current search-filter
{
	local
	global vars

	category_check := vars.maptracker.category_check
	If !vars.maptracker.keywords.Count()
		Return 1
	For index, val in vars.maptracker.keywords
	{
		check := 0
		If LangMatch(val, [":", "|"], 0)
		{
			category := SubStr(val, InStr(val, "!") + 1), category := SubStr(category, 1, InStr(category, ":") - 1)
			If category_check.HasKey(category) || !Blank(LLK_HasVal(category_check, category))
				val := StrReplace(val, "|", "|" category ":")
			Else category := ""
		}
		Loop, Parse, val, |, %A_Space%
		{
			runtime := [0, 0, 0], keyword := StrReplace(A_LoopField, "!"), category := InStr(keyword, ":") ? SubStr(keyword, 1, InStr(keyword, ":") - 1) : "", category_keyword := SubStr(keyword, InStr(keyword, ":") + 1)
			If category_check[category] || !Blank(LLK_HasVal(category_check, category))
				category := category_check[category]
			Else category := ""
			While (SubStr(category_keyword, 1, 1) = " ")
				category_keyword := SubStr(category_keyword, 2)
			If (category = "run")
			{
				Loop, Parse, category_keyword, `:
					runtime.InsertAt(1, Blank(A_LoopField) ? 0 : A_LoopField)
				category_keyword := runtime.1 + 60 * runtime.2 + 3600 * runtime.3, category_keyword := !category_keyword ? "" : category_keyword
			}

			If (category = "mapinfo") && IsNumber(SubStr(category_keyword, 1, -1)) && LLK_HasVal(vars.lang.maps_stats, SubStr(category_keyword, 0))
			{
				If Blank(content.mapinfo)
					Return
				Loop, Parse, % SubStr(content.mapinfo, 1, InStr(content.mapinfo, ";") - 1), |, % A_Space
					If (SubStr(A_LoopField, 0) = SubStr(category_keyword, 0) && SubStr(A_LoopField, 1, -1) >= SubStr(category_keyword, 1, -1))
						Return 1
			}
			Else If !Blank(category) && content.HasKey(category) && content[category]
			&& (InStr("kills,deaths,portals", category) && (category_keyword <= content[category]) || (category = "run") && (category_keyword >= content[category]) || !IsNumber(category_keyword) && InStr(content[category], category_keyword))
				check += InStr(val, "!") ? 0 : 1
			Else If IsNumber(keyword) && (content.tier = keyword) || !category && !IsNumber(keyword) && InStr(content.map, keyword) ;|| InStr(content.content, keyword))
				check += InStr(val, "!") ? 0 : 1
			Else If InStr(val, "!")
				check += 1
		}
		If !check
			Return
	}
	Return 1
}

MaptrackerGUI(mode := 0)
{
	local
	global vars, settings
	static wait, toggle := 0

	If wait
		Return
	wait := 1, toggle := !toggle, GUI_name := "maptracker" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmaptracker" (vars.maptracker.pause ? " +E0x20" : "")
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.maptracker.fWidth/2, % settings.maptracker.fWidth/4
	Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize . (vars.maptracker.pause ? " c" settings.maptracker.colors.date_unselected : " cWhite"), % vars.system.font
	hwnd_old := vars.hwnd.maptracker.main, vars.hwnd.maptracker := {"main": maptracker}

	Gui, %GUI_name%: Add, Progress, % "x0 y0 BackgroundWhite HWNDhwnd w" settings.maptracker.fWidth * 0.6 " h" settings.maptracker.fWidth * 0.6, 0
	vars.hwnd.maptracker.drag := hwnd
	Gui, %GUI_name%: Add, Text, % "Section x" settings.maptracker.fWidth/2 " y" settings.maptracker.fWidth/4 " BackgroundTrans HWNDhwnd" (vars.maptracker.pause ? " c"settings.maptracker.colors.date_unselected : ""), % Blank(vars.maptracker.map.name) ? "not tracking" : (InStr(vars.maptracker.map.name, ":") ? SubStr(vars.maptracker.map.name, InStr(vars.maptracker.map.name, ":") + 2) : vars.maptracker.map.name) " ("vars.maptracker.map.tier ")" (vars.maptracker.map.time ? " " FormatSeconds(vars.maptracker.map.time, 0) : "")
	vars.hwnd.maptracker.save := hwnd
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled range0-500 BackgroundBlack cGreen HWNDhwnd", 0
	vars.hwnd.maptracker.delbar := hwnd

	If settings.maptracker.notes
	{
		Gui, %GUI_name%: Add, Pic, % "ys hp w-1 HWNDhwnd BackgroundTrans", % "img\GUI\mapping tracker\notes" (IsObject(vars.maptracker.notes) ? "" : 0) ".png"
		vars.hwnd.maptracker.notes := hwnd
	}

	For index, content in vars.maptracker.map.content
		Gui, %GUI_name%: Add, Pic, % "ys hp w-1 BackgroundTrans", % "img\GUI\mapping tracker\" content ".png"

	If mode
	{
		vars.maptracker.loot := vars.maptracker.map.loot.Count() ? 1 : 0 ;flag to determine if the loot-list is on display
		For loot, stack in vars.maptracker.map.loot
		{
			loot := (StrLen(loot) > 30) ? SubStr(loot, 1, 30) . " [...]" : loot
			Gui, %GUI_name%: Add, Text, % "xs Section"(A_Index = 1 ? " y+"settings.maptracker.fWidth/2 : " y+0"), % loot (stack > 1 ? " (" stack ")" : "")
		}
	}
	Else vars.maptracker.loot := 0

	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %maptracker%
	xPos := Blank(settings.maptracker.xCoord) ? vars.client.x - vars.monitor.x + vars.client.w - Floor(vars.client.h * 0.6155) : (settings.maptracker.xCoord = "center") ? vars.client.xc - w/2 + 1 : settings.maptracker.xCoord
	xPos := (xPos >= vars.monitor.w / 2) ? xPos - w : xPos
	yPos := Blank(settings.maptracker.yCoord) ? vars.client.y - vars.monitor.y + vars.client.h : settings.maptracker.yCoord, yPos := (yPos >= vars.monitor.h / 2) ? yPos - h : yPos
	style := vars.maptracker.pause && settings.maptracker.hide ? "Hide" : "Show"
	vars.maptracker.panelPos := {"x": vars.monitor.x + xPos, "y": vars.monitor.y + yPos, "w": w, "h": h}
	Gui, %GUI_name%: %style%, % "NA x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	LLK_Overlay(maptracker, style,, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	wait := 0
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

MaptrackerLogs(mode := "")
{
	local
	global vars, settings
	static toggle := 0

	entries := vars.maptracker.entries := {}, max_lines := Floor(vars.monitor.h*0.75 / settings.maptracker.fHeight)
	vars.maptracker.category_check := {"r": "run", "d": "deaths", "p": "portals", "k": "kills", "l": "loot", "m": "mapinfo", "n": "notes", "c": "content"}

	FileRead, ini, ini\map tracker log.ini
	Loop, Parse, ini, `n, `r
	{
		If Blank(A_LoopField)
			Continue
		If InStr(A_LoopField, "[")
		{
			If object.Count()
				entries[date].InsertAt(1, object)
			date := SubStr(A_LoopField, 2, -1), time := SubStr(date, InStr(date, " ") + 1), date := SubStr(date, 1, InStr(date, " ") - 1)
			If !IsObject(entries[date])
				entries[date] := []
			object := {"time": time}
		}
		Else
		{
			key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), val := (SubStr(val, 1, 1) = """") ? SubStr(val, 2, -1) : val
			val := (key = "tier" && SubStr(val, 1, 1) = "0") ? SubStr(val, 2) : val
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

	If entries.Count()
	{
		date_isLeague := LLK_HasVal(vars.maptracker.leagues, vars.maptracker.active_date,,,, 1)
		If (vars.maptracker.active_date != "all") && vars.maptracker.active_date && !date_isLeague && !LLK_HasKey(entries, vars.maptracker.active_date, 1) ;reset selected date if the previous one no longer exists
			vars.maptracker.active_date := "all"
		entries_copy := {}, ddl := [], entries_backup := entries.Clone(), active_date := vars.maptracker.active_date
		For date, runs in entries
			For run, content in runs
			{
				If InStr("all", active_date) && !vars.maptracker.keywords.Count() || MaptrackerFilter(content)
				{
					If !IsObject(entries_copy[date])
						entries_copy[date] := []
					entries_copy[date].Push(content)
					If Blank(LLK_HasVal(ddl, date))
						ddl.Push(date)
				}
				If (run = runs.Count())
					If !Blank(LLK_HasVal(ddl, date))
						ddl[LLK_HasVal(ddl, date)] := date " (" Format("{:03}", entries_copy[date].Count()) ")"
			}
		entries := vars.maptracker.entries := entries_copy.Clone()

		If !WinExist("ahk_id " vars.hwnd.maptracker_logs.main) && !ddl.Count()
		{
			vars.maptracker.keywords := []
			SetTimer, MaptrackerLogs, -200
			Return
		}

		If !vars.maptracker.active_date ;&& !Blank(LLK_HasVal(ddl, vars.maptracker.active_date, 1)))
			active_date := vars.maptracker.active_date := "all" ;SubStr(ddl[ddl.Count()], 1, InStr(ddl[ddl.Count()], " ") - 1)
		Else If (mode = "refresh")
			Return

		If !ddl.Count() && vars.maptracker.keywords.Count()
		{
			WinGetPos, x, y,,, % "ahk_id " vars.hwnd.maptracker_logs.filter
			If (mode != "DEL")
			{
				LLK_ToolTip(LangTrans("global_match"), 1.5, x, y,, "red"), vars.maptracker.keywords := vars.maptracker.keywords_lastworking.Clone(), vars.maptracker.entries := vars.maptracker.entries_lastworking.Clone()
				Return
			}
			Else
			{
				vars.maptracker.keywords := [], MaptrackerLogs()
				Return
			}
		}
		vars.maptracker.keywords_lastworking := vars.maptracker.keywords.Clone(), vars.maptracker.entries_lastworking := vars.maptracker.entries.Clone()
	}
	Else vars.maptracker.active_date := LangTrans("global_none"), entries := {"1970/01/01": []}

	;If vars.maptracker.active_date && InStr(ddl, vars.maptracker.active_date)
	;	ddl := StrReplace(ddl, ddl_replace, ddl_replace . (InStr(ddl, ddl_replace "|") ? "|" : "||")) ;pre-select a previously-selected date
	;Else vars.maptracker.active_date := "", choice := LLK_InStrCount(ddl, "|") + 1 ;else pre-select the last entry

	toggle := !toggle, GUI_name := "maptracker_logs" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDmaptracker_logs"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1
	Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.maptracker_logs.main, vars.hwnd.maptracker_logs := {"main": maptracker_logs, "toggle": toggle}

	;Gui, %GUI_name%: Add, Text, % "x-1 y-1 Border Center Section HWNDhwnd0", % " lailloken ui: " LangTrans("maptracker_header") " "
	;Gui, %GUI_name%: Add, Text, % "ys Border Center HWNDhwnd gMaptrackerLogs2 w"settings.maptracker.fWidth*2, % "x"
	;vars.hwnd.maptracker_logs.winbar := hwnd0, vars.hwnd.maptracker_logs.winx := hwnd

	Gui, %GUI_name%: Add, Text, % "xs Section HWNDhwnd y+"settings.maptracker.fHeight/4 " x"settings.maptracker.fWidth/2 . (vars.maptracker.keywords.Count() ? " cLime" : ""), % LangTrans("maptracker_logs")
	vars.hwnd.maptracker_logs.focus_control := hwnd
	;Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize - 4
	;LLK_PanelDimensions(["7777/77/77 (777)7777"], settings.maptracker.fSize - 4, wDDL, hDDL,,, 0)
	;Gui, %GUI_name%: Add, DDL, % "ys x+" settings.general.fWidth/2 " w" wDDL " hp gMaptrackerLogs2 HWNDhwnd r"LLK_InStrCount(ddl, "|") + 1 . (choice ? " Choose"choice : ""), % StrReplace(ddl, "/", "–")
	;vars.hwnd.maptracker_logs.ddl := vars.hwnd.help_tooltips["maptracker_logviewer day-select"] := hwnd
	Gui, %GUI_name%: Add, Text, % "ys Center yp-1 Border HWNDhwnd gMaptrackerDateSelect x+" settings.general.fWidth/2 . (vars.maptracker.active_date = LangTrans("global_none") ? " cRed" : ""), % " " StrReplace(vars.maptracker.active_date, "/", "-") " "
	vars.hwnd.maptracker_logs.date_selected := vars.hwnd.help_tooltips["maptracker_logviewer day-select"] := hwnd
	;Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize
	;vars.maptracker.active_date := !vars.maptracker.active_date ? SubStr(StrReplace(LLK_ControlGet(hwnd), "–", "/"), 1, 10) : vars.maptracker.active_date

	Gui, %GUI_name%: Add, Text, % "ys yp Border BackgroundTrans 0x200 Center HWNDhwnd00 gMaptrackerLogs2 x+" settings.maptracker.fWidth / 2 . (!vars.maptracker.keywords.Count() ? "" : " cLime"), % " " LangTrans("maptracker_export") " "
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cGreen HWNDhwnd range0-500", 0
	vars.hwnd.maptracker_logs.export := hwnd00, vars.hwnd.maptracker_logs.export_progress := vars.hwnd.help_tooltips["maptracker_logviewer export"] := hwnd

	run_count := 0
	For date, array in entries
		If (active_date = "all") || InStr(date, vars.maptracker.active_date) || date_isLeague && LLK_IsBetween(StrReplace(date, "/"), vars.maptracker.leagues[date_isLeague].2, vars.maptracker.leagues[date_isLeague].3)
			run_count += array.Count()

	If (run_count > max_lines)
	{
		vars.maptracker.active_page := !vars.maptracker.active_page ? 1 : vars.maptracker.active_page
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.maptracker.fWidth, % LangTrans("maptracker_page")
		Loop, % Ceil(run_count / max_lines)
		{
			Gui, %GUI_name%: Add, Text, % "ys " (A_Index = 1 ? "yp-1" : "yp") " Border Center gMaptrackerLogs2 HWNDhwnd x+"(A_Index = 1 ? settings.maptracker.fWidth/2 : settings.maptracker.fWidth/4) " w"settings.maptracker.fWidth*2 . (A_Index = vars.maptracker.active_page ? " cFuchsia" : ""), % A_Index
			vars.hwnd.maptracker_logs["page_"A_Index] := hwnd
		}
	}
	Else vars.maptracker.active_page := 1

	Gui, %GUI_name%: Add, Text, % "ys HWNDhwnd00 x+" settings.maptracker.fWidth / 2 . (!vars.maptracker.keywords.Count() ? "" : " cLime"), % LangTrans("maptracker_search")
	Gui, %GUI_name%: Add, Pic, % "ys yp-1 hp w-1 Border BackgroundTrans gMaptrackerLogs2 HWNDhwnd1 x+" settings.maptracker.fWidth / 4, % "img\GUI\close.png"
	Gui, %GUI_name%: Font, % "s" settings.maptracker.fSize - 2

	For index, val in vars.maptracker.keywords
	{
		Gui, %GUI_name%: Add, Text, % "ys yp hp Border 0x200 BackgroundTrans Center gMaptrackerLogs2 HWNDhwnd69 x+" settings.maptracker.fWidth/4, % " " StrReplace(StrReplace(val, "|", " | "), "  ", " ") " "
		vars.hwnd.maptracker_logs["removesearch_" val] := hwnd69
	}

	Gui, %GUI_name%: Font, % "s" settings.maptracker.fSize - 4
	Gui, %GUI_name%: Add, Edit, % "ys yp hp cBlack HWNDhwnd0 x+" settings.maptracker.fWidth/4 " w"settings.maptracker.fWidth
	Gui, %GUI_name%: Add, Button, % "xp yp wp hp Default HWNDhwnd gMaptrackerLogs2 cBlack", % "OK"
	Gui, %GUI_name%: Font, % "s" settings.maptracker.fSize
	ControlGetPos, x, y,,,, ahk_id %hwnd0%
	vars.hwnd.maptracker_logs.filter := hwnd0, vars.hwnd.maptracker_logs.filter_button := vars.hwnd.help_tooltips["maptracker_logviewer filter"] := hwnd
	vars.maptracker.xFilter := x, vars.maptracker.yFilter := y, vars.hwnd.maptracker_logs.filter_reset := hwnd1, vars.hwnd.help_tooltips["maptracker_logviewer global"] := vars.hwnd.maptracker_logs.global := hwnd000

	;array with sub-arrays: sub-array.1 is the column's heading, 2 is the column-alignment
	table := [["#", "center"], ["time", "right"], ["map", "left"], ["tier", "right"], ["run", "right"], ["e-exp", "right"], ["deaths", "right"], ["portals", "right"], ["kills", "right"], ["loot", "center"], ["mapinfo", "center"], ["notes", "center"], ["content", "center"]], columns := {}, custom_widths := {"#": "7777", "map": "777777777777777777777777777777777", "time": "77:77", "run": "7:77:77", "e-exp": "77.7%", "deaths": "77", "portals": "77", "kills": "77777"}

	combined_runs := 0
	For date, array in entries
	{
		reverse_object := date (!reverse_object ? "" : ", " reverse_object)
		If (active_date = "all") || InStr(date, vars.maptracker.active_date) || date_isLeague && LLK_IsBetween(StrReplace(date, "/"), vars.maptracker.leagues[date_isLeague].2, vars.maptracker.leagues[date_isLeague].3)
			combined_runs += array.Count()
	}

	For index, val in table
	{
		header := val.1, icon := InStr(" deaths, portals, kills, loot, mapinfo, notes,", " " val.1 ",") ? 1 : 0, index_sum := 0
		If !date_check && (header = "time") && (vars.maptracker.active_date != LangTrans("global_none"))
			date_check := IsNumber(StrReplace(vars.maptracker.active_date, "/")) && (StrLen(StrReplace(vars.maptracker.active_date, "/")) < 7) || !IsNumber(StrReplace(vars.maptracker.active_date, "/")) ? 1 : 0

		Loop, Parse, reverse_object, `,, %A_Space% ;create arrays for each column that contain the text-values for each line: these are used in a dummy-GUI to check if the width of any line exceeds the minimum width
		{
			date := A_LoopField, array := entries[date]
			If !IsObject(columns[header])
				columns[header] := !icon ? [(header = "#") ? combined_runs : LangTrans("maptracker_" header, (header = "time" && date_check) ? 2 : 1)] : ["."]
			If (active_date = "all") || InStr(date, vars.maptracker.active_date) || date_isLeague && LLK_IsBetween(StrReplace(date, "/"), vars.maptracker.leagues[date_isLeague].2, vars.maptracker.leagues[date_isLeague].3)
				For index, content in array
				{
					index_sum += 1
					If (index_sum >= max_lines * vars.maptracker.active_page || index_sum < (vars.maptracker.active_page - 1) * max_lines)
						Continue
					text := (header = "#") ? index_sum : (header = "time") ? SubStr(content[val.1], 1, 5) : (header = "run") ? FormatSeconds(content[val.1], 0) : content[val.1]
					text := (header = "time" && date_check) ? StrReplace(date, "/", "-") ", " text : text
					If Blank(LLK_HasVal(columns[header], text)) && !InStr(" loot, content, mapinfo, notes,", " " val.1 ",")
						columns[header].Push(text)
				}
		}

		columns[header].Push(custom_widths[header]), gLabel := InStr(" run, deaths, portals, kills, loot, mapinfo, notes, content,", " " val.1 ",") ? " gMaptrackerLogsFilter" : ""
		LLK_PanelDimensions(columns[header], settings.maptracker.fSize, width, height,, 4)
		Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize + 4
		LLK_FontDimensions(settings.maptracker.fSize + 4, font_height, font_width)
		width := (width < font_height) ? font_height : width * (header = "content" ? 2.5 : 1), header_tooltips := ["map", "e-exp", "kills", "loot", "mapinfo", "notes", "content", "tier", "run"]
		If (header = "#")
		{
			Gui, %GUI_name%: Add, Text, % "xs x-1 y+"settings.maptracker.fHeight/4 " Section BackgroundTrans Border HWNDhwnd w" width, % ""
			Gui, %GUI_name%: Add, Pic, % "xp+" (width - font_height) / 2 " BackgroundTrans HWNDhwnd h" font_height, % "img\GUI\help.png"
			vars.hwnd.help_tooltips["maptracker_logviewer headers"] := hwnd
		}
		Else Gui, %GUI_name%: Add, Text, % "ys Section BackgroundTrans Border Center HWNDhwnd w"width . gLabel, % icon ? "" : (header = "#") ? "" : LangTrans("maptracker_" header, (header = "time" && date_check) ? 2 : 1)
		vars.hwnd.maptracker_logs["column_" val.1] := hwnd
		Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize
		If icon
			Gui, %GUI_name%: Add, Pic, % "xp+" (width - font_height)/2 " yp hp w-1 HWNDhwnd", % "img\GUI\mapping tracker\"header ".png"
		If !Blank(LLK_HasVal(header_tooltips, header))
			vars.hwnd.help_tooltips["maptracker_logviewer header "header] := hwnd
		index_sum := 0, index_page := 0
		Loop, Parse, reverse_object, `,, %A_Space% ;create the table line by line
		{
			date := A_LoopField, array := entries[date], outer := A_Index
			If (active_date = "all") || InStr(date, vars.maptracker.active_date) || date_isLeague && LLK_IsBetween(StrReplace(date, "/"), vars.maptracker.leagues[date_isLeague].2, vars.maptracker.leagues[date_isLeague].3)
				For index, content in array
				{
					index_sum += 1
					If (!sum_row || outer = sum_row) && (index = 1) ;add an extra row for sum/average-tooltips
					{
						If (header = "#")
							Gui, %GUI_name%: Font, % "s" settings.maptracker.fSize * 0.6, Times New Roman
						text := (header = "#") ? "Σ" : ""
						Gui, %GUI_name%: Add, Text, % "xs Border HWNDhwnd Center BackgroundTrans w" width . (hSum ? " h" hSum : "") . (InStr("#,time,e-exp", header) ? "" : " gMaptrackerLogs2") . (vars.maptracker.keywords.Count() ? " cLime" : ""), % text
						vars.hwnd.maptracker_logs["avgsum_" header] := hwnd
						If (text = "Σ")
						{
							ControlGetPos,,,, hSum,, ahk_id %hwnd%
							vars.hwnd.help_tooltips["maptracker_logviewer sum avg"] := hwnd
						}
						If !InStr("#,time,e-exp", header)
							Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack c"settings.maptracker.colors.date_unselected, 100
						If (header = "#")
							Gui, %GUI_name%: Font, % "s" settings.maptracker.fSize, % vars.system.font
						sum_row := outer
					}
					If (index_sum >= max_lines * vars.maptracker.active_page || index_sum < (vars.maptracker.active_page - 1) * max_lines)
						Continue
					vars.maptracker.max_lines := index_page += 1
					runs := combined_runs + 1, color := vars.maptracker.keywords.Count() && (header = "#") ? " cLime" : ""
					text := InStr(" loot, content, mapinfo, notes,", " "val.1 ",") ? "" : (header = "#") ? runs - index_sum : (val.2 = "left" ? " " : "") . (Blank(content[val.1]) ? (header = "e-exp") ? "" : 0 : content[val.1]) . (val.2 = "right" ? " " : "")
					text := (header = "time") ? SubStr(text, 1, 5) . " " : (header = "run") ? FormatSeconds(text, 0) " " : text
					text := (header = "time" && date_check) ? StrReplace(date, "/", "-") ", " text : text
					gLabel1 := (InStr(" loot, mapinfo,", " "val.1 ",") && content[val.1] || InStr(" map, notes,", " " header ",") ? " gMaptrackerLogs2" : (header = "tier") ? " gMaptrackerLogsFilter" : "")
					Gui, %GUI_name%: Add, Text, % "xs Border BackgroundTrans HWNDhwnd0 "val.2 " w"width . gLabel1 . color, % text
					If (header = "map")
					{
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed HWNDhwnd range0-500", 0
						vars.hwnd.maptracker_logs["delbar_" date " " content.time] := hwnd
					}
					vars.hwnd.maptracker_logs[header "_" date " " content.time] := hwnd0
					If (!second_row)
						second_row := vars.maptracker.second_row := hwnd0 ;store the handle of a cell in the second row
					If (header = "content") && content[header]
						Loop, Parse, % content[header], `;, %A_Space%
						{
							Gui, %GUI_name%: Add, Pic, % (A_Index = 1 ? "xp+"settings.maptracker.fWidth/4 + 1 " yp+1 hp-2" : "x+"settings.maptracker.fWidth/4 " yp hp") " HWNDicon gMaptrackerLogsFilter BackgroundTrans w-1", % "img\GUI\mapping tracker\" A_LoopField ".png"
							vars.hwnd.maptracker_logs["icon_" A_LoopField . icon_handle] := icon, icon_handle .= "|"
						}
					If InStr(" loot, mapinfo, notes,", " "val.1 ",")
						Gui, %GUI_name%: Add, Progress, % "xp yp w"width " hp Border BackgroundBlack c" settings.maptracker.colors.date_unselected " Range0-1", % content[val.1] && (content[val.1] != "¢¢¢") ? 1 : 0
				}
		}
	}
	vars.maptracker.displayed_runs := index_sum

	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.maptracker_logs.main
	ControlMove,,,, % w - vars.maptracker.xFilter - settings.maptracker.fWidth/2,, % "ahk_id " vars.hwnd.maptracker_logs.filter
	ControlMove,,,, % w - vars.maptracker.xFilter - settings.maptracker.fWidth/2,, % "ahk_id " vars.hwnd.maptracker_logs.filter_button
	;If (mode != "filter")
	;	ControlFocus,, % "ahk_id " vars.hwnd.maptracker_logs.focus_control
	ControlFocus,, % "ahk_id " vars.hwnd.maptracker_logs.filter
	If (mode = "filter")
		SendInput, ^{a}{Right}
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + vars.client.xc - w/2 " y" vars.monitor.y + vars.monitor.h/10
	LLK_Overlay(vars.hwnd.maptracker_logs.main, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

MaptrackerLogs2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.maptracker_logs, cHWND), control := StrReplace(SubStr(check, InStr(check, "_") + 1), !InStr(check, "removesearch_") ? "|" : "")
	Switch check
	{
		Case "export":
			If (vars.system.click = 2)
			{
				If !FileExist("exports\")
					LLK_FilePermissionError("create", A_ScriptDir "\exports")
				Else Run, explore exports\
			}
			Else If vars.maptracker.displayed_runs && LLK_Progress(vars.hwnd.maptracker_logs.export_progress, "LButton")
				MaptrackerLogsCSV()
		Case "filter_button":
			If !IsObject(vars.maptracker.keywords)
				vars.maptracker.keywords := []
			Loop, Parse, % LLK_ControlGet(vars.hwnd.maptracker_logs.filter), `,, %A_Space%
				If !Blank(A_LoopField) && !LLK_HasVal(vars.maptracker.keywords, A_LoopField, 1)
					vars.maptracker.keywords.Push(A_LoopField)
			MaptrackerLogs()
		Case "filter_reset":
		{
			KeyWait, LButton
			KeyWait, RButton
			If vars.maptracker.keywords.Count()
				vars.maptracker.keywords := [], MaptrackerLogs()
			Else GuiControl,, % vars.hwnd.maptracker_logs.filter, % ""
		}
		Default:
			If InStr(check, "page_")
				vars.maptracker.active_page := control, MaptrackerLogs()
			Else If InStr(check, "loot_")
				MaptrackerLogsTooltip(control, "loot", cHWND)
			Else If InStr(check, "mapinfo_")
				MaptrackerLogsTooltip(control, "mapinfo", cHWND)
			Else If InStr(check, "notes_")
				If (vars.system.click = 1)
					MaptrackerLogsTooltip(control, "notes", cHWND)
				Else
				{
					WinGetPos, x, y,,, % "ahk_id " cHWND
					MaptrackerNoteEdit("", [x, y, "map tracker log", control])
				}
			Else If InStr(check, "removesearch_")
			{
				KeyWait, LButton
				While LLK_HasVal(vars.maptracker.keywords, control)
					vars.maptracker.keywords.RemoveAt(LLK_HasVal(vars.maptracker.keywords, control))
				MaptrackerLogs()
			}
			Else If InStr(check, "map_")
			{
				If (vars.system.click = 1)
				{
					start := A_TickCount
					While GetKeyState("LButton", "P")
						If (A_TickCount >= start + 300)
						{
							WinGetPos, x, y, w, h, % "ahk_id "cHWND
							vars.maptracker.selected_edit := [control, A_GuiControl, x, y, w, h]
							MaptrackerEdit()
							KeyWait, LButton
							Return
						}
					MaptrackerLogsFilter(cHWND)
				}
				Else
				{
					start := A_TickCount, current_input := LLK_ControlGet(vars.hwnd.maptracker_logs.filter)
					While GetKeyState("RButton", "P")
						If (A_TickCount >= start + 200)
							If LLK_Progress(vars.hwnd.maptracker_logs["delbar_" control], "RButton")
							{
								IniDelete, ini\map tracker log.ini, % control
								KeyWait, RButton
								MaptrackerLogs("DEL")
								Return
							}
							Else Return
					MaptrackerLogsFilter(cHWND)
				}
			}
			Else If InStr(check, "icon_") || InStr(check, "column_") || InStr(check, "tier_")
			{
				KeyWait, LButton
				KeyWait, RButton
				current_input := LLK_ControlGet(vars.hwnd.maptracker_logs.filter), search := InStr(check, "tier_") ? SubStr(A_GuiControl, 1, 2) + 0 : (InStr(check, "icon_") ? "c:" control : SubStr(control, 1, 1) ":")
				last_keyword := InStr(current_input, ",") ? InStr(current_input, ",",, 0) + 1 : current_input
				While (SubStr(last_keyword, 1, 1) = " ")
					last_keyword := SubStr(last_keyword, 2)
				If (vars.system.click = 1) && (InStr("run,portals", control) || !Blank(LLK_HasVal(vars.maptracker.keywords, search, 1))) || (vars.system.click = 2) && (InStr(current_input, search) || LLK_HasVal(vars.maptracker.keywords, search, 1)) || !Blank(LLK_HasVal(vars.maptracker.keywords, SubStr(search, InStr(search, ":") + 1), 1))
					Return
				If (vars.system.click = 1) && Blank(LLK_HasVal(vars.maptracker.keywords, SubStr(search, InStr(search, ":") + 1), 1))
					vars.maptracker.keywords.Push(search), MaptrackerLogs()
				Else If (vars.system.click = 2)
				{
					If !Blank(last_keyword) && InStr(last_keyword, "c:") && (SubStr(current_input, InStr(current_input, ":",, 0) - 1, 1) = "c") || InStr(check, "tier_") && IsNumber(search) && IsNumber(StrReplace(last_keyword, "|"))
						search := "|" StrReplace(search, "c:"), or_override := 1
					GuiControl,, % vars.hwnd.maptracker_logs.filter, % current_input . (Blank(current_input) || or_override || (SubStr(current_input, 0) = "!") ? "" : ", ") . search
					ControlFocus,, % "ahk_id " vars.hwnd.maptracker_logs.filter
					SendInput, ^{a}{Right}
				}
			}
			Else If InStr(check, "avgsum_")
				MaptrackerLogsTooltip("avgsum", control, cHWND)
			Else LLK_ToolTip("no action")
	}
}

MaptrackerLogsCSV()
{
	local
	global vars, settings, json

	active_date := vars.maptracker.active_date, leagues := vars.maptracker.leagues, entries := {}
	For key, array in vars.maptracker.entries
	{
		date_check := LLK_HasVal(vars.maptracker.leagues, StrReplace(active_date, "/"),,,, 1)
		If InStr(key, active_date) || (active_date = "all") || date_check && LLK_IsBetween(active_date, leagues[date_check][2], leagues[date_check][3])
			For index, object in array
			{
				entries[key ", " object.time] := {}
				For key1, val in object
					If (key != "time")
						entries[key ", " object.time][key1] := val
			}
	}

	file := "map logs (" StrReplace(active_date, "/", "-") ").csv"
	;append := """date, time"",map,tier/level,run,e-exp,deaths,portals,kills,loot,map info,content"
	append := """" LangTrans("maptracker_time", 2) """," LangTrans("maptracker_map") "," LangTrans("maptracker_tier", 2) "," LangTrans("maptracker_run") "," LangTrans("maptracker_e-exp") "," LangTrans("maptracker_deaths") "," LangTrans("maptracker_portals") "," LangTrans("maptracker_kills1") "," LangTrans("maptracker_loot1") "," LangTrans("ms_map-info") "," LangTrans("maptracker_content")
	For date, val in entries
	{
		date := """" StrReplace(date, "/", "-") """", val.map := """" val.map """", val.run := """" FormatSeconds(val.run) ".00""", val.loot := """" (!val.loot ? "" : StrReplace(val.loot, "; ", "`r`n")) """"
		val.mapinfo := """" StrReplace(val.mapinfo, "; ", "`r`n") """"
		Loop, Parse, % val.content, `;, % A_Space
		{
			If (A_Index = 1)
				val.content := ""
			val.content .= (!val.content ? "" : "`r`n") (LangTrans("mechanic_" A_LoopField) ? LangTrans("mechanic_" A_LoopField) : (A_LoopField = 0) ? "" : A_LoopField)
		}
		append .= "`n" date "," val.map "," val.tier "," val.run "," val["e-exp"] "," val.deaths "," val.portals "," val.kills "," val.loot "," val.mapinfo ",""" val.content """"
	}

	For index, val in vars.maptracker.keywords
		append .= (index = 1 ? "`n`nsearch-filter:" : "") "`n" StrReplace(StrReplace(val, "|", " | "), "  ", " ")

	If !FileExist("exports\")
	{
		folder_missing := 1
		FileCreateDir, exports\
		Sleep 250
	}
	If !FileExist("exports\") && folder_missing
	{
		LLK_FilePermissionError("create", A_ScriptDir "\exports")
		Return
	}

	FileDelete, % "exports\" file
	FileAppend, % append, % "exports\" file
	LLK_ToolTip(LangTrans("maptracker_export") "`n" LangTrans("global_" (!ErrorLevel ? "success" : "fail")), 1.5,,,, !ErrorLevel ? "Lime" : "Red")
}

MaptrackerLogsFilter(cHWND) ;adds operators/keywords to the search-bar when icons or headers are clicked
{
	local
	global vars

	KeyWait, LButton
	KeyWait, RButton

	If (vars.system.click = 1)
		KeyWait, LButton, D T0.2
	Else KeyWait, RButton, D T0.2
	double_click := !ErrorLevel ? 1 : 0, check := LLK_HasVal(vars.hwnd.maptracker_logs, cHWND), control := SubStr(StrReplace(check, "|"), InStr(check, "_") + 1), input := LLK_ControlGet(vars.hwnd.maptracker_logs.filter), last_key := SubStr(input, InStr(input, ",",, 0) + 1)
	While (SubStr(last_key, 1, 1) = " ")
		last_key := SubStr(last_key, 2)
	While (SubStr(input, 1, 1) = " ")
		input := SubStr(input, 2)
	While (SubStr(input, 0) = " ")
		input := SubStr(input, 1, -1)

	If InStr(check, "map_")
	{
		If !double_click && InStr(last_key, SubStr(A_GuiControl, 2))
			Return
		search := (!IsNumber(last_key) && !InStr(last_key, ":") && !Blank(last_key) && (vars.system.click = 1) && !InStr(last_key, "!") && !double_click ? "|" : Blank(input) ? "" : ", ") SubStr(A_GuiControl, 2)
	}
	Else If InStr(check, "tier_")
	{
		If !double_click && InStr(last_key, SubStr(A_GuiControl, 1, -1))
			Return
		search := (IsNumber(last_key) && (vars.system.click = 1) && !InStr(last_key, "!") && !double_click ? "|" : Blank(input) ? "" : ", ") SubStr(A_GuiControl, 1, -1)
	}
	Else If InStr(check, "icon_")
	{
		If !double_click && InStr(last_key, control)
			Return
		search := (InStr(last_key, "c:") && (vars.system.click = 1) && !InStr(last_key, "!") && !double_click ? "|" : Blank(input) ? "c:" : ", c:") control
	}
	Else
	{
		If !double_click && InStr(last_key, SubStr(control, 1, 1) ":")
			Return
		search := (Blank(input) ? "" : ", ") SubStr(control, 1, 1) ":"
	}

	If Blank(search)
		Return
	input .= (vars.system.click = 2 ? (SubStr(search, 1, 1) = "," ? StrReplace(search, ", ", ", !") : "!" search) : search)
	If InStr("!r:!p:", " " input)
		Return
	If double_click
		Loop, Parse, search, % "!,|", % A_Space
		{
			If Blank(A_LoopField)
				Continue
			vars.maptracker.keywords.Push((vars.system.click = 2 ? "!" : "") A_LoopField), MaptrackerLogs()
			Return
		}
	GuiControl,, % vars.hwnd.maptracker_logs.filter, % input
	SendInput, ^{a}{Right}
	Return

	If (vars.system.click = 2) && InStr(current_input, SubStr(A_GuiControl, 2))
		Return
	last_keyword := InStr(current_input, ",") ? InStr(current_input, ",",, 0) + 1 : current_input
	While (SubStr(last_keyword, 1, 1) = " ")
		last_keyword := SubStr(last_keyword, 2)
	If !Blank(last_keyword) && !(LLK_PatternMatch(last_keyword, ":", vars.maptracker.category_check, 1, 0, 0) || LLK_PatternMatch(last_keyword, ":", vars.maptracker.category_check, 1, 1, 0)) && !IsNumber(last_keyword) && (SubStr(current_input, 0) != "!")
		current_input .= "|", override := 1
	GuiControl,, % vars.hwnd.maptracker_logs.filter, % current_input . (Blank(current_input) || override || (SubStr(current_input, 0) = "!") ? "" : ", ") . SubStr(A_GuiControl, 2)
	ControlFocus,, % "ahk_id " vars.hwnd.maptracker_logs.filter
	SendInput, ^{a}{Right}




	KeyWait, LButton
	KeyWait, RButton
	current_input := LLK_ControlGet(vars.hwnd.maptracker_logs.filter), search := InStr(check, "tier_") ? SubStr(A_GuiControl, 1, 2) + 0 : (InStr(check, "icon_") ? "c:" control : SubStr(control, 1, 1) ":")
	last_keyword := InStr(current_input, ",") ? InStr(current_input, ",",, 0) + 1 : current_input
	While (SubStr(last_keyword, 1, 1) = " ")
		last_keyword := SubStr(last_keyword, 2)
	If (vars.system.click = 1) && (InStr("run,portals", control) || !Blank(LLK_HasVal(vars.maptracker.keywords, search, 1))) || (vars.system.click = 2) && (InStr(current_input, search) || LLK_HasVal(vars.maptracker.keywords, search, 1)) || !Blank(LLK_HasVal(vars.maptracker.keywords, SubStr(search, InStr(search, ":") + 1), 1))
		Return
	If (vars.system.click = 1) && Blank(LLK_HasVal(vars.maptracker.keywords, SubStr(search, InStr(search, ":") + 1), 1))
		vars.maptracker.keywords.Push(search), MaptrackerLogs()
	Else If (vars.system.click = 2)
	{
		If !Blank(last_keyword) && InStr(last_keyword, "c:") && (SubStr(current_input, InStr(current_input, ":",, 0) - 1, 1) = "c") || InStr(check, "tier_") && IsNumber(search) && IsNumber(StrReplace(last_keyword, "|"))
			search := "|" StrReplace(search, "c:"), or_override := 1
		GuiControl,, % vars.hwnd.maptracker_logs.filter, % current_input . (Blank(current_input) || or_override || (SubStr(current_input, 0) = "!") ? "" : ", ") . search
		ControlFocus,, % "ahk_id " vars.hwnd.maptracker_logs.filter
		SendInput, ^{a}{Right}
	}
}

MaptrackerLogsTooltip(ini_section, ini_key, cHWND)
{
	local
	global vars, settings, json

	If (ini_section = "avgsum") ;clicking a cell for totals/averages
	{
		active_date := vars.maptracker.active_date, date_isLeague := LLK_HasVal(vars.maptracker.leagues, StrReplace(active_date, "/"),,,, 1), totals := {}, runs := 0, column := ini_key
		For date, array in vars.maptracker.entries
		{
			If (active_date = "all") || InStr(date, vars.maptracker.active_date) || date_isLeague && LLK_IsBetween(StrReplace(date, "/"), vars.maptracker.leagues[date_isLeague].2, vars.maptracker.leagues[date_isLeague].3)
			{
				For run, object in array
				{
					runs += 1
					If Blank(totals[object[column]])
						totals[object[column]] := 0
					totals[object[column]] += 1
				}
			}
		}
		For key, val in totals
			list .= (Blank(list) ? "" : "`n") val "x " key
		Sort, list, D`n N R
		boxes := [InStr("deaths,portals,kills,run,loot", column) ? LangTrans("maptracker_sum") : "#"], boxes1 := [InStr("deaths,portals,kills,run,loot", column) ? LangTrans("maptracker_average") : "%"], sum := 0, sum_content := {}
		If !InStr("deaths,portals,kills,run", column)
			boxes2 := [(column = "tier" ? "t/l" : column)]
		Loop, Parse, list, `n
		{
			count := SubStr(A_LoopField, 1, InStr(A_LoopField, "x") - 1)
			percent := Format("{:0.2f}", count/runs*100), text := A_Index, percent := (InStr(percent, ".") >= 4) ? SubStr(percent, 1, InStr(percent, ".") - 1) : percent
			key := SubStr(A_LoopField, InStr(A_LoopField, " ") + 1)
			If !key && (column != "content")
				Continue
			sum += count * key
			If InStr("content ,loot ,notes ,mapinfo ", column " ")
			{
				Loop, Parse, % (column = "notes") ? StrReplace(key, "(n)", "`n") : key, % (column = "notes") ? "§¢" : ";" . (column = "mapinfo" ? "|" : ""), %A_Space%
				{
					key_content := !A_LoopField ? (column = "content" ? LangTrans("global_none") : "") : (column = "mapinfo" && InStr(A_LoopField, ":")) ? SubStr(A_LoopField, 1, InStr(A_LoopField, ":") -1) : A_LoopField, count_content := 0
					If (column = "mapinfo") && IsNumber(SubStr(A_LoopField, 1, -1)) ;currently unused: list occurrence of 1-20, 21-40, 41-60%... quant, rarity, pack-size
					{
						Continue
						pValue0 := SubStr(A_LoopField, 1, -1), unit := SubStr(A_LoopField, 0)
						Loop
						{
							pValue := (A_Index - 1) * 20 + 1, pValue1 := (A_Index) * 20
							If LLK_IsBetween(pValue0, pValue, pValue1)
								key_content := pValue "-" pValue1 . unit
							If (pValue >= 300)
								Break
						}
					}
					If !key_content || (column = "mapinfo") && (SubStr(key_content, 1, 1) = "-")
						Continue
					If (column = "loot" && InStr(key_content, "("))
						count_content := SubStr(key_content, InStr(key_content, "(") + 1), count_content := SubStr(count_content, 1, InStr(count_content, ")") - 1), key_content := SubStr(key_content, 1, InStr(key_content, " (") - 1)
					If Blank(sum_content[key_content])
						sum_content[key_content] := 0
					sum_content[key_content] += count * (count_content ? count_content : 1)
				}
			}
			If InStr("map ,tier ", column " ")
			{
				boxes.Push(count), boxes1.Push(percent), boxes2.Push(key)
				;If (boxes.Count() = vars.maptracker.max_lines)
				;	Break
			}
		}
		If InStr("deaths,portals,kills,run", column)
			boxes.Push((column = "run") ? FormatSeconds(sum, 0) : sum), boxes1.Push((column = "run") ? FormatSeconds(Round(sum/runs), 0) : Format("{:0.2f}", sum/runs))
		Else If InStr("content ,loot ,notes ,mapinfo ", column " ")
		{
			For key, val in sum_content
				list_content .= (Blank(list_content) ? "" : "§") val "x " key
			Sort, list_content, D§ N R
			Loop, Parse, list_content, §
			{
				count := SubStr(A_LoopField, 1, InStr(A_LoopField, "x") - 1)
				percent := Format("{:0.2f}", count/runs * (column = "loot" ? 1 : 100)), text := A_Index, key := SubStr(A_LoopField, InStr(A_LoopField, " ") + 1)
				percent := (InStr(percent, ".") >= 4) ? SubStr(percent, 1, InStr(percent, ".") - 1) : percent
				boxes.Push(count), boxes1.Push(percent), boxes2.Push(StrReplace(key, "`n", " `n "))
				;If (boxes.Count() = vars.maptracker.max_lines)
				;	Break
			}
		}
		text := (boxes.Count() > 1) ? "." : ""
	}
	Else
	{
		text := StrReplace(LLK_IniRead("ini\map tracker log.ini", ini_section, ini_key), (ini_key = "notes") ? "(n)" : "; ", "`n")
		If (ini_key = "mapinfo")
			text := StrReplace(StrReplace(text, "`n- ", "¢"), "`n", "`n   ")
		Else If (ini_key = "notes")
			text := StrReplace(text, "§", "¢")
	}

	If !Blank(text)
	{
		If (ini_section != "avgsum")
		{
			boxes := []
			Loop, Parse, text, % (ini_key = "loot") ? "`n" : "¢", % A_Space
				If !Blank(A_LoopField)
					boxes.Push(StrReplace(A_LoopField, "`n", " `n "))
		}

		Gui, maptracker_tooltip: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDmaptracker_tooltip"
		Gui, maptracker_tooltip: Color, % settings.maptracker.colors.date_unselected
		Gui, maptracker_tooltip: Margin, 0, 0
		Gui, maptracker_tooltip: Font, % "s"settings.maptracker.fSize " cWhite", % vars.system.font

		LLK_PanelDimensions(boxes, settings.maptracker.fSize, width, height), LLK_PanelDimensions(boxes1, settings.maptracker.fSize, width1, height1), LLK_PanelDimensions(boxes2, settings.maptracker.fSize, width2, height2)

		For index, text in boxes
		{
			If (column = "notes") && (ini_section = "avgsum")
				LLK_PanelDimensions([boxes2[index]], settings.maptracker.fSize, wRow, hRow)
			style := (ini_section = "avgsum") ? " 0x200" (index = 1 ? " Center" : " Right") : (ini_key = "mapinfo" && index = 1) ? " Center" : ""
			Gui, maptracker_tooltip: Add, Text, % "Section HWNDhwnd" (index = 1 ? "" : " xs y+-1") . style " Border w" width . (hRow ? " h" hRow : ""), % " " text " "
			If (ini_section = "avgsum")
			{
				Gui, maptracker_tooltip: Add, Text, % "ys x+-1 0x200 Border w" width1 . (hRow ? " h" hRow : "") . (index = 1 ? " Center" : " Right"), % " " boxes1[index] " "
				If !Blank(boxes2[index])
					Gui, maptracker_tooltip: Add, Text, % "ys x+-1 Border w" width2 . (index = 1 ? " Center" : (column = "tier") ? " Right" : ""), % " " boxes2[index] " "
			}
			ControlGetPos,, yControl,, hControl,, ahk_id %hwnd%
			If (yControl + hControl >= vars.monitor.h * 0.69)
				Break
		}

		Gui, maptracker_tooltip: Show, NA x10000 y10000
		WinGetPos, x, y, w, h, % "ahk_id " cHWND
		If (ini_section = "avgsum")
			WinGetPos,, y,,, % "ahk_id " vars.maptracker.second_row
		WinGetPos,,, wGui, hGui, ahk_id %maptracker_tooltip%
		xPos := (x + wGui >= vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - wGui : x
		yPos := (y >= vars.monitor.y + vars.monitor.h/2) ? (y + h - hGui < vars.monitor.y ? vars.monitor.y : y + h - hGui) : (y + hGui >= vars.monitor.y + vars.monitor.h ? vars.monitor.y + vars.monitor.h - hGui : y)
		Gui, maptracker_tooltip: Show, % "x" xPos " y" yPos
		vars.hwnd.maptracker_logs.sum_tooltip := maptracker_tooltip
	}
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
		If StrMatch(A_LoopField, LangTrans("items_rarity"))
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
	parse := map.summary "; "
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
		If (type != 2) || !Blank(LLK_HasVal(vars.maptracker.map.content, mechanic))
			Continue
		pNeedle := Gdip_LoadImageFromFile("img\Recognition ("vars.client.h "p)\Mapping Tracker\"mechanic ".bmp")
		If (0 < Gdip_ImageSearch(pScreen, pNeedle, LIST,,,,, 10))
			vars.maptracker.map.content.Push(mechanic)
		Gdip_DisposeImage(pNeedle)
	}
	Gdip_DisposeImage(pScreen), MaptrackerGUI(), wait := 0
}

MaptrackerNoteAdd(cHWND := "")
{
	local
	global vars

	Clipboard := ""
	SendInput, ^{c}
	ClipWait, 0.05
	If Blank(Clipboard)
	{
		LLK_ToolTip(LangTrans("global_fail"),,,,, "red")
		Return
	}

	Clipboard := LLK_StringCase(Clipboard)
	Loop, Parse, Clipboard, `n, `r
		If (A_Index = 3)
			item := A_LoopField

	If LangMatch(Clipboard, [LangTrans("items_voidstone"), " (enchant)"], 0)
	{
		info := SubStr(Clipboard, InStr(Clipboard, "---`r`n",,, 2) + 5), info := SubStr(info, 1, InStr(info, "`r`n---") - 1), info := SubStr(info, 1, InStr(info, "`r",, 0) - 1), info := StrReplace(info, "`r")
		info := "`n" StrReplace(info, " (enchant)"), item .= ":"
	}
	Else If LangMatch(item, [LangTrans("items_voidstone")], 0)
	{
		LLK_ToolTip(LangTrans("global_match"),,,,, "red")
		Return
	}
	add := item (!Blank(info) ? info : ""), LLK_ToolTip(LangTrans("global_success"), 0.5,,,, "Lime")
	MaptrackerNoteEdit(,, [add])
}

MaptrackerNoteEdit(cHWND := "", array0 := "", add := "") ;array = [xPos, yPos, ini-file, section]
{
	local
	global vars, settings
	static edit, toggle := 0, notes := {"logs": [[], [], []], "tracker": [[], [], []]}, file, section, xTarget, yTarget, category

	KeyWait, RButton
	check := LLK_HasVal(vars.hwnd.maptrackernotes_edit, cHWND), panelPos := vars.maptracker.panelPos

	If (cHWND = "refresh") ;notes tagged with "#" are limited to X map runs, so the static arrays inside this function need to be refreshed each time notes "expire" after saving a run
	{
		notes.tracker := [[], [], []]
		If IsObject(vars.maptracker.notes)
			For index0, array in vars.maptracker.notes
				For index, note in array
					notes.tracker[index0][index] := note
		Return
	}
	Else If IsNumber(SubStr(check, 1, 1)) ;long-clicking an entry in the panel which are arranged in arrays within an array: [[user-notes], [items], [voidstones]]
	{
		If !LLK_Progress(vars.hwnd.maptrackernotes_edit[check "_bar"], "LButton") ;long-clicking prevents annoying misclicks
			Return
		If (check = 0)
			notes[category] := [[], [], []]
		Else notes[category][SubStr(check, 1, 1)].RemoveAt(SubStr(check, InStr(check, "_") + 1)) ;else remove note X.Y
		remove := 1
	}
	Else If (check != "save") && !IsObject(add)
		category := !Blank(LLK_PatternMatch(A_Gui, "maptracker_logs", ["0", "1"])) ? "logs" : "tracker"

	If (cHWND = "edit") ;clicking the notes-icon in the maptracker panel
		array0 := [vars.general.xMouse, vars.general.yMouse]
	Else If IsObject(add) ;omni-clicking an item while the note-editor is open
	{
		If InStr(add.1, LangTrans("items_voidstone") ":")
		{
			notes_check := LLK_HasVal(notes[category].3, SubStr(add.1, 1, InStr(add.1, ":") - 1), 1)
			If notes_check
				notes[category].3[notes_check] := add.1
			Else notes[category].3.Push(add.1)
		}
		Else
		{
			If LLK_HasVal(notes[category].2, add.1)
				Return
			notes[category].2.InsertAt(1, add.1)
			If (notes[category].2.Count() > 4)
				notes[category].2.Pop()
		}
	}
	Else If (check = "save") ;hitting ENTER when the edit-field is focused
	{
		input := LLK_ControlGet(vars.hwnd.maptrackernotes_edit.notes)
		While (SubStr(input, 1, 1) = " ")
			input := SubStr(input, 2)
		While (SubStr(input, 0) = " ")
			input := SubStr(input, 1, -1)
		If Blank(input)
			Return
		notes[category].1.Push(input)
	}
	Else If !Blank(array0.3) ;right-clicking a notes-entry in the log-viewer
	{
		file := array0.3, section := array0.4, notes.logs := [[], [], []]
		Loop, Parse, % LLK_IniRead("ini\" file ".ini", section, "notes"), ¢
		{
			If Blank(A_LoopField)
				Continue
			outer := A_Index
			Loop, Parse, A_LoopField, §
			{
				notes.logs[outer].Push(StrReplace(A_LoopField, "(n)", "`n"))
			}
		}
	}

	If (category = "logs") && (add.1 || remove || input)
	{
		For key, array in notes.logs
		{
			For index, note in array
				ini_string .= (index = 1 ? "" : "§") . StrReplace(note, "`n", "(n)")
			ini_string .= "¢"
		}
		IniWrite, % """" ini_string """", ini\map tracker log.ini, % section, notes
		If (ini_string = "¢¢¢")
			LLK_Overlay(vars.hwnd.maptrackernotes_edit.main, "destroy"), MaptrackerLogs()
	}

	If IsObject(array0)
		xTarget := array0.1, yTarget := array0.2
	toggle := !toggle, GUI_name := "maptrackernotes_edit" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDmaptracker_edit"
	Gui, %GUI_name%: Color, Fuchsia
	WinSet, TransColor, Fuchsia
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.maptrackernotes_edit.main, vars.hwnd.maptrackernotes_edit := {"main": maptracker_edit}, notes_copy := ["777777777777777777777777777777"]

	For key, array in notes[category]
		For index, note in array
			notes_copy.Push(InStr(note, LangTrans("items_voidstone") ":") && (category = "tracker") ? SubStr(note, 1, InStr(note, ":") - 1) : note)
	LLK_PanelDimensions(notes_copy, settings.maptracker.fSize, width, height)

	If (category = "tracker")
		vars.maptracker.notes := ""

	Gui, %GUI_name%: Add, Text, % "Section BackgroundTrans Center HWNDhwnd Border w" width . (notes_copy.Count() > 1 ? " gMaptrackerNoteEdit" : ""), % LangTrans("m_maptracker_notes") ":"
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd0 Disabled BackgroundBlack cRed Range0-500", 0
	vars.hwnd.maptrackernotes_edit.0 := hwnd, vars.hwnd.maptrackernotes_edit.0_bar := hwnd0
	For index0, array in notes[category]
		For index, note in array
		{
			note_copy := InStr(note, LangTrans("items_voidstone") ":") && (category = "tracker") ? SubStr(note, 1, InStr(note, ":") - 1) : note
			Gui, %GUI_name%: Add, Text, % "xs y+-1 BackgroundTrans Section Border HWNDhwnd gMaptrackerNoteEdit w" width, % " " StrReplace(note_copy, "`n", " `n ")
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd0 Disabled BackgroundBlack cRed Range0-500", 0
			notes_added := 1, vars.hwnd.maptrackernotes_edit[index0 "_" index] := hwnd, vars.hwnd.maptrackernotes_edit[index0 "_" index "_bar"] := hwnd0
			If (category = "tracker")
			{
				If !IsObject(vars.maptracker.notes)
					vars.maptracker.notes := [[], [], []]
				vars.maptracker.notes[index0].Push(note)
			}
		}

	Gui, %GUI_name%: Font, % "s"settings.maptracker.fSize - 4
	Gui, %GUI_name%: Add, Edit, % "Section xs y+-1 HWNDhwnd Lowercase cBlack -Wrap r1 w" width . (add.1 || remove || input ? "" : " Disabled")
	Gui, %GUI_name%: Add, Pic, % "Section ys x+-1 Border BackgroundTrans hp-2 w-1", img\GUI\help.png
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border HWNDhwnd00 BackgroundBlack", 0
	Gui, %GUI_name%: Add, Button, % "xp yp wp hp Default Hidden Center HWNDhwnd0 gMaptrackerNoteEdit", ok
	vars.hwnd.maptrackernotes_edit.notes := hwnd, vars.hwnd.maptrackernotes_edit.save := hwnd0, vars.hwnd.help_tooltips["maptrackernotes_help"] := hwnd00

	If vars.hwnd.maptracker_logs.main && WinActive("ahk_id " vars.hwnd.maptracker_logs.main)
	{
		WinActivate, % "ahk_id " vars.hwnd.poe_client
		WinWaitActive, % "ahk_id " vars.hwnd.poe_client
	}

	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %maptracker_edit%
	If (category = "logs")
		xPos := xTarget, yPos := (yTarget > vars.monitor.y + vars.monitor.h / 2) ? yTarget - h : yTarget
	Else xPos := panelPos.x, yPos := panelPos.y + (panelPos.y < vars.monitor.y + vars.monitor.h/2 ? panelPos.h - 1 : -h)

	xPos := (xPos + w >= vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos
	yPos := (yPos + h >= vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : (yPos < vars.monitor.y) ? vars.monitor.y : yPos

	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(maptracker_edit, "show", 1, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	KeyWait, % settings.hotkeys.tab
	ControlFocus,, ahk_id %hwnd0%
	GuiControl, -Disabled, % hwnd
	If (category = "tracker")
		MaptrackerGUI()
	WinActivate, % "ahk_id " vars.hwnd.poe_client
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
		If (type != 1) || !settings.maptracker[mechanic] || !Blank(LLK_HasVal(vars.maptracker.map.content, mechanic))
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

	ignore := ["vaal area", "abyssal depths", "lab trial", "maven", "delirium"]
	For index, mechanic in vars.maptracker.map.content
	{
		For index0, mechanic0 in ignore
			If InStr(mechanic, mechanic0)
				Continue 2
		mechanics += 1
	}

	If mechanics
		LLK_ToolTip(LangTrans("maptracker_check"), 3, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "aqua", settings.general.fSize + 4,,, 1)
	KeyWait, % settings.maptracker.portal_hotkey_single
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
	{
		For index0, array in vars.maptracker.notes
		{
			For index, note in array
			{
				run_count := ""
				If InStr(note, "#") && IsNumber(SubStr(note, 1, InStr(note, "#") - 1))
					run_count := SubStr(note, 1, InStr(note, "#") - 1)
				note_count := Blank(note_count) ? 0 : note_count
				If InStr(note, LangTrans("items_voidstone") ":`n")
					note := SubStr(note, InStr(note, ":`n") + 2)
				note := StrReplace(SubStr(note, run_count ? StrLen(run_count) + 2 : 1), "`n", "(n)")
				While (SubStr(note, 1, 1) = " ")
					note := SubStr(note, 2)
				While (SubStr(note, 0) = " ")
					note := SubStr(note, 1, -1)
				notes .= (index = 1 ? "" : "§") . note
				If run_count
					If (run_count = 1)
					{
						vars.maptracker.notes[index0][index] := "_remove_"
						Continue
					}
					Else vars.maptracker.notes[index0][index] := StrReplace(vars.maptracker.notes[index0][index], run_count "#", run_count - 1 "#")
				note_count += 1
			}
			notes .= "¢"
		}

		If !Blank(note_count) ;non-blank var implies that notes were present prior to saving, so check whether notes need to be removed after a map-run
		{
			Loop, % vars.maptracker.notes.Count()
			{
				outer := A_Index
				Loop, % vars.maptracker.notes[outer].Count()
					If (vars.maptracker.notes[outer][A_Index] = "_remove_")
						vars.maptracker.notes[outer].RemoveAt(A_Index)
			}
			If !note_count ;if there aren't any notes left, clear the notes-array
				vars.maptracker.notes := ""
			MaptrackerNoteEdit("refresh"), MaptrackerGUI()
		}
		IniWrite, % "map=" map.name "`ntier=" map.tier "`nrun=" map.time "`nportals=" map.portals "`ndeaths=" map.deaths "`nkills=" map.kills "`ncontent=" (!content ? 0 : content) "`nloot=" (!loot ? 0 : loot) "`nmapinfo=" vars.maptracker.map.mapinfo "`ne-exp="map.experience (map.experience ? "%" : "") "`nnotes=""" (settings.maptracker.notes ? notes : "") """", ini\map tracker log.ini, % map.date_time
	}
	vars.maptracker.map := {"date_time": vars.log.date_time, "id": vars.log.areaID, "seed": vars.log.areaseed, "tier": vars.log.areatier, "level": vars.log.arealevel, "portals": 1, "time": -1, "deaths": 0, "loot": {}, "content": []}
	MaptrackerLoot("clear")
	If WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
		MaptrackerLogs()
}

MaptrackerTimer()
{
	local
	global vars, settings
	static inactive, mapname_replace, mapname_add

	If !settings.features.maptracker || vars.maptracker.drag
		Return

	If !mapname_replace
	{
		mapname_replace := {"mavenboss": LangTrans("maps_maven"), "mavenhub": LangTrans("maps_maven_invitation"), "MapWorldsPrimordialBoss1": LangTrans("maps_hunger"), "MapWorldsPrimordialBoss2": LangTrans("maps_blackstar"), "MapWorldsPrimordialBoss3": LangTrans("maps_exarch"), "MapWorldsPrimordialBoss4": LangTrans("maps_eater"), "MapWorldsShapersRealm": LangTrans("maps_shaper"), "MapWorldsElderArena": LangTrans("maps_elder"), "MapWorldsElderArenaUber": LangTrans("maps_elder", 2), "harvestleagueboss": LangTrans("maps_oshabi"), "mapatziri1": LangTrans("maps_atziri"), "mapatziri2": LangTrans("maps_atziri", 2), "atlasexilesboss5": LangTrans("maps_sirus")}
		mapname_add := {"heist": LangTrans("maps_heist"), "expedition": LangTrans("maps_logbook"), "affliction": LangTrans("maps_delirium")}
	}

	If !(settings.maptracker.hide && vars.maptracker.pause) && !MaptrackerCheck(2) && !WinExist("ahk_id "vars.hwnd.maptracker.main) && (WinActive("ahk_group poe_window") || WinActive("ahk_id "vars.hwnd.maptracker_logs.main) || vars.settings.active = "mapping tracker") || vars.maptracker.toggle ;when in hideout or holding down TAB, show tracker GUI
		MaptrackerGUI(), inactive := 0
	Else If WinExist("ahk_id "vars.hwnd.maptracker.main) && (MaptrackerCheck(2) && !vars.maptracker.toggle && !vars.maptracker.pause || settings.maptracker.hide && vars.maptracker.pause) ;else hide it
		inactive += 1
	Else inactive := 0
	If WinExist("ahk_id "vars.hwnd.maptracker.main) && (inactive = 2)
		LLK_Overlay(vars.hwnd.maptracker.main, "destroy")

	If MaptrackerCheck() && (vars.maptracker.refresh_kills > 2) ;when re-entering a map after updating the kill-tracker, set its state to 2 so it starts flashing again the next time the hideout is entered
		vars.maptracker.refresh_kills := 2

	If MaptrackerTowncheck() && (vars.maptracker.refresh_kills = 2) && WinExist("ahk_id "vars.hwnd.maptracker.main) && !vars.maptracker.pause ;flash the tracker as a reminder to update the kill-count
	{
		Gui, % GuiName(vars.hwnd.maptracker.main) ": Color", % (vars.maptracker.color = "Maroon") ? "Black" : "Maroon"
		Gui, % GuiName(vars.hwnd.maptracker.main) ": -E0x20"
		vars.maptracker.color := (vars.maptracker.color = "Maroon") ? "Black" : "Maroon"
		GuiControl, % "+Background" vars.maptracker.color, % vars.hwnd.maptracker.delbar
	}
	Else If (!MaptrackerTowncheck() || (vars.maptracker.refresh_kills > 2)) && (vars.maptracker.color = "Maroon") && WinExist("ahk_id "vars.hwnd.maptracker.main) ;reset the tracker to black after updating the kill-count
	{
		Gui, % GuiName(vars.hwnd.maptracker.main) ": Color", Black
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
				If !Blank(LLK_HasVal(vars.maptracker.map.content, key)) || !InStr(vars.log.areaID, val)
					Continue
				vars.maptracker.map.content.Push(key)
			}

		If settings.features.mapinfo && settings.maptracker.mapinfo && !vars.maptracker.map.mapinfo && !vars.mapinfo.active_map.expired && vars.mapinfo.active_map.name
		&& (vars.maptracker.map.name && InStr(vars.mapinfo.active_map.name, vars.maptracker.map.name) || LLK_HasVal(vars.mapinfo.categories, vars.log.areaname, 1) || vars.mapinfo.active_map.tag && InStr(vars.log.areaID, vars.mapinfo.active_map.tag))
		{
			If LLK_PatternMatch(vars.mapinfo.active_map.tag, "", ["mavenhub", "heist", "blight"])
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
