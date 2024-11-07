Init_log(mode := "")
{
	local
	global vars, settings

	If !IsObject(vars.log.file) ;at script-startup
		vars.log.file := FileOpen(vars.log.file_location, "r", "UTF-8"), log_content := vars.log.file.Read()
	Else ;when specifying "active character" in the settings menu
	{
		If !Blank(settings.general.character)
		{
			log_file := FileOpen(vars.log.file_location, "r", "UTF-8"), log_content := log_file.Read(), log_file.Close()
			check := InStr(log_content, " " settings.general.character " " Lang_Trans("system_parenthesis"),, 0, 1)
			check1 := InStr(log_content, " " settings.general.character " " Lang_Trans("log_whois"),, 0, 1), check := Max(check, check1)
		}
		Else
		{
			vars.log.level := 0
			Return
		}
	}

	If mode
		vars.log.level := ""
	Else
	{
		vars.log.parsing := "areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class"
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
			vars.log[A_LoopField] := ""

		If !settings.general.lang_client
			check := InStr(log_content, " Generating level ", 1, 0, 10), Lang_Client(SubStr(log_content, InStr(log_content, " Generating level ", 1, 0, check ? 10 : 1)))

		If !Blank(settings.general.character := LLK_IniRead("ini" vars.poe_version "\config.ini", "settings", "active character"))
		{
			check := InStr(log_content, " " settings.general.character " " Lang_Trans("system_parenthesis"),, 0, 1)
			check1 := InStr(log_content, " " settings.general.character " " Lang_Trans("log_whois"),, 0, 1), check := Max(check, check1)
		}
		Else check := 0
	}

	If check
		log_content_level := SubStr(log_content, check), log_content_level := SubStr(log_content_level, 1, InStr(log_content_level, "`r") - 1)
		, Log_Parse(log_content_level, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class)

	If mode
	{
		vars.log.level := level ? level : 0, vars.log.character_class := character_class
		Return
	}
	log_content := SubStr(log_content, InStr(log_content, " Generating level ", 1, 0, 2))
	Log_Parse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class) ;pass log-chunk to parse-function to extract the required information: the info is returned via ByRef variables
	Loop, Parse, % vars.log.parsing, `,, %A_Space%
		If Blank(vars.log[A_LoopField]) && !Blank(%A_LoopField%)
			vars.log[A_LoopField] := %A_LoopField%
	vars.log.level := !vars.log.level ? 0 : vars.log.level, settings.general.lang_client := settings.general.lang_client ? settings.general.lang_client : "unknown"
}

Log_Loop(mode := 0)
{
	local
	global vars, settings
	static button_color

	Critical
	If settings.qol.alarm && !vars.alarm.drag
	{
		For timestamp, timer in vars.alarm.timers
			If IsNumber(StrReplace(timestamp, "|")) && (timestamp <= A_Now)
				expired := "expired"
		If (expired || vars.alarm.toggle) && !WinExist("ahk_id " vars.hwnd.alarm.alarm_set)
			Alarm("", "", vars.alarm.toggle ? "" : expired)
	}

	guide := vars.leveltracker.guide ;short-cut variable
	If !WinActive("ahk_group poe_ahk_window") || !vars.log.file_location || !WinExist("ahk_group poe_window")
		Return

	If IsObject(vars.maptracker)
		vars.maptracker.hideout := Maptracker_Towncheck() ? 1 : 0 ;flag to determine if the player is using a portal to re-enter the map (as opposed to re-entering from side-content)

	log_content := vars.log.file.Read(), level0 := vars.log.level
	If !Blank(log_content)
	{
		Log_Parse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class)
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
		{
			If !Blank(%A_LoopField%)
				vars.log[A_LoopField] := %A_LoopField%
			If (A_Index = 1) && !Blank(%A_LoopField%)
				vars.log.areaname := "" ;make it blank because there sometimes is a desync between it and areaID, i.e. they are parsed in two separate loop-ticks
		}
		If !LLK_HasVal(vars.leveltracker.guide.group1, "an_end_to_hunger", 1) && !InStr(vars.log.areaID, "labyrinth_") && (!Blank(areaID) && (areaID != vars.leveltracker.guide.target_area) || IsNumber(level) && (level0 != level)) && LLK_Overlay(vars.hwnd.leveltracker.main, "check") ;player has leveled up or moved to a different location: update overlay for zone-layouts, exp-gain, and act clarifications
			Leveltracker_Progress()

		If settings.qol.alarm && (areaID = "1_1_1") && IsNumber(StrReplace((check := LLK_HasVal(vars.alarm.timers, "oni", 1)), "|")) ;for oni-goroshi farming: re-entering Twilight Strand resets timer to 0:00
			vars.alarm.timers.Delete(check), vars.alarm.timers[A_Now "|"] := "oni"

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

		If character_class && WinExist("ahk_id " vars.hwnd.settings.main) && (vars.settings.active = "general")
			Settings_menu("general",, 0)
	}

	If mode
		Return

	If settings.qol.lab && InStr(vars.log.areaID, "labyrinth_") && !InStr(vars.log.areaID, "Airlock") && vars.log.areaseed && vars.lab.rooms.Count() && !vars.lab.rooms[vars.lab.room.1].seed
		vars.lab.rooms[vars.lab.room.1].seed := vars.log.areaseed, vars.lab.room.3 := vars.log.areaseed

	If settings.features.leveltracker && (A_TickCount > vars.leveltracker.last_manual + 2000) && vars.hwnd.leveltracker.main && (vars.log.areaID = vars.leveltracker.guide.target_area) && !vars.leveltracker.fast ;advance the guide when entering target-location
		vars.leveltracker.guide.target_area := "", Leveltracker(vars.log.areaID = "login" ? "mule" : "+")

	If settings.features.mapinfo && vars.mapinfo.expedition_areas && vars.log.areaname && !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, vars.log.areaname)) && !vars.mapinfo.active_map.expedition_filter
	{
		Loop, % vars.mapinfo.categories.Count()
		{
			parse := InStr(vars.mapinfo.categories[A_Index], "(") ? SubStr(vars.mapinfo.categories[A_Index], 1, InStr(vars.mapinfo.categories[A_Index], "(") - 2) : vars.mapinfo.categories[A_Index]
			If !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, parse)) && (parse != vars.log.areaname)
				vars.mapinfo.categories[A_Index] := ""
		}
		vars.mapinfo.active_map.name := Lang_Trans("maps_logbook") ": " vars.log.areaname, vars.mapinfo.active_map.expedition_filter := 1
	}

	Maptracker_Timer()
	Leveltracker_Timer()

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

Log_Parse(content, ByRef areaID, ByRef areaname, ByRef areaseed, ByRef arealevel, ByRef areatier, ByRef act, ByRef level, ByRef date_time, ByRef character_class)
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

		If Lang_Match(A_LoopField, vars.lang.log_enter)
			parse := SubStr(A_LoopField, InStr(A_LoopField, vars.lang.log_enter.1)), areaname := LLK_StringCase(Lang_Trim(parse, vars.lang.log_enter, Lang_Trans("log_location")))

		If !Blank(settings.general.character) && InStr(A_LoopField, " " settings.general.character " ")
		{
			If Lang_Match(A_LoopField, vars.lang.log_level)
			{
				level := SubStr(A_Loopfield, InStr(A_Loopfield, vars.lang.log_level.1)), level := Lang_Trim(level, vars.lang.log_level)
				If InStr(A_LoopField, settings.general.character " " Lang_Trans("system_parenthesis"))
					character_class := SubStr(A_LoopField, InStr(A_LoopField, Lang_Trans("system_parenthesis")) + 1)
					, character_class := LLK_StringCase(SubStr(character_class, 1, InStr(character_class, Lang_Trans("system_parenthesis", 2)) - 1))
			}
			Else If Lang_Match(A_LoopField, vars.lang.log_whois)
			{
				level0 := SubStr(A_LoopField, InStr(A_LoopField, settings.general.character)), parse := ""
				Loop, Parse, level0
				{
					If (A_Index = 1)
						level := ""
					If IsNumber(A_LoopField)
						parse := !parse ? A_Index : parse, level .= A_LoopField
				}
				level0 := SubStr(level0, parse), level0 := SubStr(level0, InStr(level0, " ") + 1), character_class := LLK_StringCase(SubStr(level0, 1, InStr(level0, " ") - 1))
			}

			If settings.leveltracker.geartracker && vars.hwnd.geartracker.main
				Geartracker_GUI("refresh")
		}

		If settings.features.maptracker && (vars.log.areaID = vars.maptracker.map.id) && (Lang_Match(A_LoopField, vars.lang.log_slain) || Lang_Match(A_LoopField, vars.lang.log_suicide))
			vars.maptracker.map.deaths += 1

		If settings.features.maptracker && settings.maptracker.kills && vars.maptracker.refresh_kills && Lang_Match(A_LoopField, vars.lang.log_killed)
		{
			parse := SubStr(A_LoopField, InStr(A_LoopField, vars.lang.log_killed.1)), parse := Lang_Trim(parse, vars.lang.log_killed)
			Loop, Parse, parse
				parse := (A_Index = 1) ? "" : parse, parse .= IsNumber(A_LoopField) ? A_LoopField : ""
			If (vars.maptracker.refresh_kills = 1)
				vars.maptracker.map.kills := [parse], LLK_ToolTip(Lang_Trans("maptracker_kills", 2),,,,, "Lime"), vars.tooltip_mouse := "", vars.maptracker.refresh_kills := 2
			Else If (vars.maptracker.refresh_kills > 1) && Maptracker_Towncheck()
				vars.maptracker.map.kills.2 := parse, LLK_ToolTip(Lang_Trans("maptracker_kills", 2),,,,, "Lime"), vars.maptracker.refresh_kills := 3
		}

		If settings.features.maptracker && settings.maptracker.mechanics && vars.maptracker.map.id && (vars.log.areaID = vars.maptracker.map.id)
			Maptracker_ParseDialogue(A_LoopField)
	}
}
