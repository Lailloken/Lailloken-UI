Init_log(mode := "")
{
	local
	global vars, settings

	If !IsObject(vars.log.file) ;at script-startup
		vars.log.file := FileOpen(vars.log.file_location, "r", "UTF-8"), log_content := vars.log.file.Read()
	Else ;when specifying "active character" in the settings menu
	{
		If !Blank(settings.general.character)
			log_file := FileOpen(vars.log.file_location, "r", "UTF-8"), log_content := log_file.Read(), log_file.Close()
		If Blank(settings.general.character) || !(check := InStr(log_content, " " settings.general.character " " LangTrans("system_parenthesis"),, 0, 1))
		{
			vars.log.level := 0
			Return
		}
	}

	If mode
		vars.log.level := ""
	Else
	{
		vars.log.parsing := "areaID, areaname, areaseed, arealevel, areatier, act, level, date_time"
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
			vars.log[A_LoopField] := ""

		If !settings.general.lang_client
			check := InStr(log_content, " Generating level ", 1, 0, 10), LangClient(SubStr(log_content, InStr(log_content, " Generating level ", 1, 0, check ? 10 : 1)))

		settings.general.character := LLK_IniRead("ini\config.ini", "settings", "active character"), check := Blank(settings.general.character) ? 0 : InStr(log_content, " " settings.general.character " " LangTrans("system_parenthesis"),, 0, 1)
	}

	If check
		log_content_level := SubStr(log_content, check), log_content_level := SubStr(log_content_level, 1, InStr(log_content_level, "`r") - 1), LogParse(log_content_level, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time)

	If mode
	{
		vars.log.level := level ? level : 0
		Return
	}
	log_content := SubStr(log_content, InStr(log_content, " Generating level ", 1, 0, 2))
	LogParse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time) ;pass log-chunk to parse-function to extract the required information: the info is returned via ByRef variables
	Loop, Parse, % vars.log.parsing, `,, %A_Space%
		If Blank(vars.log[A_LoopField]) && !Blank(%A_LoopField%)
			vars.log[A_LoopField] := %A_LoopField%
	vars.log.level := !vars.log.level ? 0 : vars.log.level, settings.general.lang_client := settings.general.lang_client ? settings.general.lang_client : "unknown"
}

LogLoop(mode := 0)
{
	local
	global vars, settings
	static button_color

	Critical
	If settings.qol.alarm && !vars.alarm.drag && vars.alarm.timestamp && (vars.alarm.timestamp <= A_Now || vars.alarm.toggle)
		Alarm()

	guide := vars.leveltracker.guide ;short-cut variable
	If !WinActive("ahk_group poe_ahk_window") || !vars.log.file_location || !WinExist("ahk_group poe_window")
		Return

	If IsObject(vars.maptracker)
		vars.maptracker.hideout := MaptrackerTowncheck() ? 1 : 0 ;flag to determine if the player is using a portal to re-enter the map (as opposed to re-entering from side-content)

	log_content := vars.log.file.Read(), level0 := vars.log.level
	If !Blank(log_content)
	{
		LogParse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time)
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
		{
			If !Blank(%A_LoopField%)
				vars.log[A_LoopField] := %A_LoopField%
			If (A_Index = 1) && !Blank(%A_LoopField%)
				vars.log.areaname := "" ;make it blank because there sometimes is a desync between it and areaID, i.e. they are parsed in two separate loop-ticks
		}
		If !LLK_HasVal(vars.leveltracker.guide.group1, "an_end_to_hunger", 1) && !InStr(vars.log.areaID, "labyrinth_") && (!Blank(areaID) && (areaID != vars.leveltracker.guide.target_area) || IsNumber(level) && (level0 != level)) && LLK_Overlay(vars.hwnd.leveltracker.main, "check") ;player has leveled up or moved to a different location: update overlay for zone-layouts, exp-gain, and act clarifications
			LeveltrackerProgress()
		If settings.qol.alarm && vars.alarm.timestamp && (areaID = "1_1_1") ;for oni-goroshi farming: re-entering Twilight Strand resets timer to 0:00
			vars.alarm.timestamp := A_Now

		If settings.qol.lab && InStr(areaID, "labyrinth_airlock") ;entering Aspirants' Plaza: reset previous lab-progress (if there is any)
			Lab("init")
		Else If settings.qol.lab && areaname && (InStr(vars.log.areaID, "labyrinth_") && !LLK_PatternMatch(vars.log.areaID, "", ["Airlock", "_trials_"]) || InStr(areaID, "labyrinth_") && !LLK_PatternMatch(areaID, "", ["Airlock", "_trials_"])) ;entering a new room
		{
			For index, room in vars.lab.rooms ;go through previously-entered rooms to check if player is backtracking or not
				If (room.name = areaname && room.seed = vars.log.areaseed)
				{
					check := index
					Break
				}
			If check
				Lab("backtrack", check)
			Else If !Blank(LLK_HasVal(vars.lab.exits.names, areaname)) ;check which adjacent room has been entered
				For index, room in vars.lab.exits.names
					If (room = areaname) && Blank(vars.lab.rooms[vars.lab.exits.numbers[index]].seed)
					{
						Lab("progress", vars.lab.exits.numbers[index])
						Break
					}
		}
	}

	If mode
		Return

	If settings.qol.lab && InStr(vars.log.areaID, "labyrinth_") && !InStr(vars.log.areaID, "Airlock") && vars.log.areaseed && vars.lab.rooms.Count() && !vars.lab.rooms[vars.lab.room.1].seed
		vars.lab.rooms[vars.lab.room.1].seed := vars.log.areaseed, vars.lab.room.3 := vars.log.areaseed

	If settings.features.leveltracker && (A_TickCount > vars.leveltracker.last_manual + 2000) && vars.hwnd.leveltracker.main && (vars.log.areaID = vars.leveltracker.guide.target_area) && !vars.leveltracker.fast ;advance the guide when entering target-location
		Leveltracker("+")

	If settings.features.mapinfo && vars.mapinfo.expedition_areas && vars.log.areaname && !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, vars.log.areaname)) && !vars.mapinfo.active_map.expedition_filter
	{
		Loop, % vars.mapinfo.categories.Count()
		{
			parse := InStr(vars.mapinfo.categories[A_Index], "(") ? SubStr(vars.mapinfo.categories[A_Index], 1, InStr(vars.mapinfo.categories[A_Index], "(") - 2) : vars.mapinfo.categories[A_Index]
			If !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, parse)) && (parse != vars.log.areaname)
				vars.mapinfo.categories[A_Index] := ""
		}
		vars.mapinfo.active_map.name := LangTrans("maps_logbook") ": " vars.log.areaname, vars.mapinfo.active_map.expedition_filter := 1
	}

	MaptrackerTimer()
	LeveltrackerTimer()

	If settings.leveltracker.geartracker && vars.leveltracker.gear_ready && (vars.leveltracker.gear_ready != vars.leveltracker.gear_counter)
	{
		GuiControl, Text, % vars.hwnd.LLK_panel.leveltracker_text, % vars.leveltracker.gear_ready
		vars.leveltracker.gear_counter := vars.leveltracker.gear_ready
	}
	Else If (!vars.leveltracker.gear_ready || !settings.leveltracker.geartracker) && vars.leveltracker.gear_counter
	{
		GuiControl, Text, % vars.hwnd.LLK_panel.leveltracker_text, % ""
		vars.leveltracker.gear_counter := 0
	}
}

LogParse(content, ByRef areaID, ByRef areaname, ByRef areaseed, ByRef arealevel, ByRef areatier, ByRef act, ByRef level, ByRef date_time)
{
	local
	global vars, settings, db

	Loop, Parse, content, `n, % "`r" vars.lang.system_fullstop.1
	{
		If InStr(A_LoopField, "Generating level ", 1)
		{
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6), areaID := SubStr(parse, 1, InStr(parse, """") -1) ;store PoE-internal location name in var
			areaseed := SubStr(A_Loopfield, InStr(A_Loopfield, "with seed ") + 10), areaname := ""
			date_time := SubStr(A_LoopField, 1, InStr(A_LoopField, " ",,, 2) - 1)
			act := db.leveltracker.areas[areaID].act ;store current act
			arealevel := parse := SubStr(A_LoopField, InStr(A_LoopField, "level ") + 6, InStr(A_LoopField, " area """) - InStr(A_LoopField, "level ") - 6)
			If (parse - 67 > 0)
				areatier := (parse - 67 < 10 ? "0" : "") parse - 67
			Else areatier := arealevel
		}
		Else If InStr(A_LoopField, " connected to ") && InStr(A_LoopField, ".login.") || InStr(A_LoopField, "*****")
			areaID := "login"

		If LangMatch(A_LoopField, vars.lang.log_enter)
			parse := SubStr(A_LoopField, InStr(A_LoopField, vars.lang.log_enter.1)), areaname := LLK_StringCase(LangTrim(parse, vars.lang.log_enter, LangTrans("log_location")))

		If !Blank(settings.general.character) && InStr(A_LoopField, " " settings.general.character " ") && LangMatch(A_LoopField, vars.lang.log_level)
		{
			level := SubStr(A_Loopfield, InStr(A_Loopfield, vars.lang.log_level.1)), level := LangTrim(level, vars.lang.log_level)
			If settings.leveltracker.geartracker && vars.hwnd.geartracker.main
				GeartrackerGUI("refresh")
		}

		If settings.features.maptracker && (vars.log.areaID = vars.maptracker.map.id) && (LangMatch(A_LoopField, vars.lang.log_slain) || LangMatch(A_LoopField, vars.lang.log_suicide))
			vars.maptracker.map.deaths += 1

		If settings.features.maptracker && settings.maptracker.kills && vars.maptracker.refresh_kills && LangMatch(A_LoopField, vars.lang.log_killed)
		{
			parse := SubStr(A_LoopField, InStr(A_LoopField, vars.lang.log_killed.1)), parse := LangTrim(parse, vars.lang.log_killed)
			Loop, Parse, parse
				parse := (A_Index = 1) ? "" : parse, parse .= IsNumber(A_LoopField) ? A_LoopField : ""
			If (vars.maptracker.refresh_kills = 1)
				vars.maptracker.map.kills := [parse], LLK_ToolTip(LangTrans("maptracker_kills", 2),,,,, "Lime"), vars.tooltip_mouse := "", vars.maptracker.refresh_kills := 2
			Else If (vars.maptracker.refresh_kills > 1) && MaptrackerTowncheck()
				vars.maptracker.map.kills.2 := parse, LLK_ToolTip(LangTrans("maptracker_kills", 2),,,,, "Lime"), vars.maptracker.refresh_kills := 3
		}

		If settings.features.maptracker && settings.maptracker.mechanics && vars.maptracker.map.id && (vars.log.areaID = vars.maptracker.map.id)
			MaptrackerParseDialogue(A_LoopField)
	}
}
