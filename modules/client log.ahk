Init_log(mode := "")
{
	local
	global vars, settings

	If mode
	{
		vars.log.level := 0, vars.log.character_last := !settings.general.character ? "" : vars.log.character_last
		If !settings.general.character
			Return
	}
	Else start := A_TickCount

	FileGetSize, filesize, % vars.log.file_location, M

	If !mode
		settings.general.character := LLK_IniRead("ini" vars.poe_version "\config.ini", "settings", "active character")
		, log_file := vars.log.file := FileOpen(vars.log.file_location, "a", "UTF-8"), vars.log.file_size := filesize
	Else log_file := FileOpen(vars.log.file_location, "a", "UTF-8")

	max_pointer := log_file.Tell()
	Loop
	{
		move := Min(max_pointer, 5 * A_Index * 1024000), log_file.Seek(-move, 2), log_read := log_file.Read(5*1024000)
		If !mode && !IsObject(log_content) && (check := InStr(log_read, " Generating level ", 1, 0, 3))
			log_content := StrSplit(SubStr(log_read, check), "`n", "`r" vars.lang.system_fullstop.1)

		If Blank(vars.general.input_method) && (check := InStr(log_read, "current input mode = ",, 0))
		{
			method := SubStr(log_read, 1, check + 23), method := SubStr(method, InStr(method, "`n",, 0) + 1)
			timestamp := SubStr(method, 1, InStr(method, " ",,, 2) - 1)
			Loop, Parse, timestamp
				timestamp := (A_Index = 1) ? "" : timestamp, timestamp .= IsNumber(A_LoopField) ? A_LoopField : ""
			method := SubStr(method, InStr(method, " ",, 0) + 1), method := Trim(method, "'")
			vars.general.input_method := [method, timestamp]
		}

		If settings.general.character && Blank(log_character.1)
		&& (InStr(log_read, " " settings.general.character " " Lang_Trans("system_parenthesis")) || InStr(log_read, " " settings.general.character " " Lang_Trans("log_whois")))
			log_character := StrSplit(log_read, "`n", "`r" vars.lang.system_fullstop.1), log_character := [log_character[Log_FindLines(log_character, "character")]]

		If (max_pointer = move) || (IsObject(log_content) || mode) && (!settings.general.character || !Blank(log_character.1))
			Break
	}
	log_file.Seek(0, 2)

	If !mode
	{
		vars.log.parsing := "areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class"
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
			vars.log[A_LoopField] := ""
	}
	If settings.general.character && !Blank(log_character.1)
		Log_Parse(log_character, bla, bla, bla, bla, bla, bla, level, bla, character_class)

	If mode
	{
		vars.log.level := level ? level : 0, vars.log.character_class := character_class, log_file.Close()
		Return
	}

	Log_Parse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, bla, date_time, bla)

	Loop, Parse, % vars.log.parsing, `,, %A_Space%
		If Blank(vars.log[A_LoopField]) && !Blank(%A_LoopField%)
			vars.log[A_LoopField] := %A_LoopField%

	If vars.general.MultiThreading
		StringSend("areaID=" vars.log.areaID)

	vars.log.level := !vars.log.level ? 0 : vars.log.level
	If !mode
		vars.log.access_time := A_TickCount - start
}

Log_Backup()
{
	local
	global vars, settings

	WinClose, % "ahk_id " vars.hwnd.poe_client
	WinWaitClose, % "ahk_id " vars.hwnd.poe_client,, 3
	If WinExist("ahk_id " vars.hwnd.poe_client)
	{
		MsgBox, % "Backup failed:`nCannot close the game-client."
		Return
	}
	file := StrReplace(vars.log.file_location, "client.txt", "Client (old).txt")
	For index, loop in ["Loop", "Log_Loop", "Loop_main"]
		SetTimer, % loop, Delete
	LLK_Overlay(vars.hwnd.help_tooltips.main, "destroy"), LLK_Overlay(vars.hwnd.ClientFiller, "destroy")
	Sleep 1000
	LLK_Overlay("hide"), vars.log.file.Close()
	LLK_ToolTip("copying...", 0, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "Yellow",,,, 1)

	If !FileExist(file)
	{
		FileMove, % vars.log.file_location, % file, 1
		If ErrorLevel
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nCannot move the old file.`nThe tool will restart."
			LLK_Restart()
			Return
		}
		source_file := FileOpen(file, "r", "UTF-8"), source_file.Seek(-Min(512000, source_file.Length), 2), dest_file := FileOpen(vars.log.file_location, "w", "UTF-8")
		If !IsObject(dest_file)
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nCannot create the new file.`n`nRestart the game to let it create the new file.`nYou'll have to waypoint-travel around a few times before relaunching the tool."
			ExitApp
		}
		append := source_file.Read(), append := SubStr(append, InStr(append, "`n") + 1) . (vars.log.character_last ? vars.log.character_last "`r`n" : "")
		dest_file.Write(append), source_file.Close(), dest_file.Close()

		If !FileExist(vars.log.file_location) || !FileExist(file)
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nSomething went wrong while copying the file. The game's log folder will open after closing this message."
			Run, % "explore " SubStr(vars.log.file_location, 1, InStr(vars.log.file_location, "\",, 0) - 1)
			MsgBox, % "Trouble-shooting steps:`n- If ""Client (old).txt"" doesn't exist, nothing happened and the original log-file wasn't changed.`n`n- If only ""Client (old).txt"" exists, the old file was moved but a new one wasn't created. Launching the game will create a new one, but you have to waypoint-travel around a bit before relaunching the tool."
			ExitApp
		}
	}
	Else
	{
		source_file := FileOpen(vars.log.file_location, "r", "UTF-8"), dest_file := FileOpen(file, "r", "UTF-8"), dest_file.Seek(-1 * Min(512000, dest_file.Length), 2)
		dest_overlap := dest_file.Read(), dest_overlap := SubStr(dest_overlap, InStr(dest_overlap, "`n") + 1), dest_file.Seek(0, 2)
		If !IsObject(source_file) || !IsObject(dest_file)
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nCannot access the current or backup file.`nThe tool will restart."
			LLK_Restart()
		}
		Loop
		{
			log_read := source_file.Read(10 * 1024000)
			Loop, Parse, log_read, `n, `r
			{
				If (A_Index = 1)
					log_read := ""
				date := SubStr(A_LoopField, 1, InStr(A_LoopField, " ",,, 2) - 1), date := StrReplace(StrReplace(StrReplace(date, " "), "/"), ":")
				If (date < prev_date)
					Continue
				prev_date := date
				If !InStr(dest_overlap, A_LoopField)
					log_read .= A_LoopField "`r`n"
			}
			dest_file.Write(log_read)
			If source_file.AtEOF
				Break
		}

		source_file.Close()
		FileDelete, % vars.log.file_location
		If FileExist(vars.log.file_location)
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nCannot delete the ""Client.txt"" log-file.`n. You'll have to delete it manually (the folder will open once you close this message).`n`nAfter deleting, restart the game, waypoint-travel around a few times, then restart the tool."
			Run, % "explore " SubStr(vars.log.file_location, 1, InStr(vars.log.file_location, "\",, 0) - 1)
			ExitApp
		}
		source_file := "", source_file := FileOpen(vars.log.file_location, "w", "UTF-8")
		If !IsObject(source_file)
		{
			LLK_Overlay(vars.hwnd.tooltip1, "destroy")
			MsgBox, % "Backup failed:`nCannot create the new file.`n`nRestart the game to let it create the new file.`nYou'll have to waypoint-travel around a few times before relaunching the tool."
			ExitApp
		}

		dest_file.Seek(-512000, 2), append := dest_file.Read(), append := SubStr(append, InStr(append, "`n") + 1) . (vars.log.character_last ? vars.log.character_last "`r`n" : ""), source_file.Write(append)
		source_file.Close(), dest_file.Close()
	}

	If FileExist(vars.log.file_location) && FileExist(file)
	{
		LLK_ToolTip("backup successful:`nyou can launch the game again,`nthe tool will restart automatically.", 0, vars.monitor.x + vars.client.xc, vars.monitor.y + vars.client.yc,, "Lime",,,, 1)
		WinWait, ahk_group poe_window,, 60
		LLK_Overlay(vars.hwnd.tooltip1, "destroy")
		Sleep 4000
		LLK_Restart()
	}
}

Log_FindLines(log_array, data)
{
	local
	global vars, settings

	count := log_array.Count()
	Loop
	{
		line := count - (A_Index - 1)
		If (data = "area") && InStr(log_array[line], " Generating Level ", 1)
			found := line, hits += 1
		Else If (data = "character")
		&& (InStr(log_array[line], " " settings.general.character " " Lang_Trans("system_parenthesis")) || InStr(log_array[line], " " settings.general.character " " Lang_Trans("log_whois")))
		{
			found := line
			Break
		}
		If (hits >= 5)
			Break
	}
	Return found
}

Log_Get(log_text, data)
{
	local
	global vars, settings

	If (data = "areaname")
		If !LLK_StringCompare(log_text, ["map", "breach", "ritual"])
			%data% := log_text
		Else
		{
			If LLK_StringCompare(log_text, ["breach"])
			{
				If settings.maptracker.rename
					Return Lang_Trans("maps_boss") ": " Lang_Trans("maps_xesht")
				Else Return Lang_Trans("maps_xesht", 2) " (" Lang_Trans("maps_boss") ")"
			}
			Else If LLK_StringCompare(log_text, ["ritual"])
			{
				If settings.maptracker.rename
					Return Lang_Trans("maps_boss") ": " Lang_Trans("maps_ritualboss")
				Else Return Lang_Trans("maps_ritualboss", 2) " (" Lang_Trans("maps_boss") ")"
			}
			Else If InStr(log_text, "uberboss_monolith")
			{
				If settings.maptracker.rename
					Return Lang_Trans("maps_boss") ": " Lang_Trans("maps_arbiter")
				Else Return Lang_Trans("maps_arbiter", 2) " (" Lang_Trans("maps_boss") ")"
			}
			Else If RegExMatch(log_text, "Hideout.*_Claimable")
			{
				hideout := LLK_StringCase(StrReplace(StrReplace(log_text, "_claimable"), "maphideout"))
				Return LLK_StringCase(Lang_Trans("maps_" hideout "_hideout") ? Lang_Trans("maps_" hideout "_hideout") : hideout " " Lang_Trans("maps_hideout"))
			}
			%data% := StrReplace(SubStr(log_text, 4), "_noboss"), %data% := StrReplace(%data%, "SwampTower", "SinkingSpire")
			If InStr(%data%, "uberboss_")
				%data% := (settings.maptracker.rename ? Lang_Trans("maps_boss") ":" : "") . StrReplace(%data%, "uberboss_") . (settings.maptracker.rename ? "" : " (" Lang_Trans("maps_boss") ")")
			Else If LLK_StringCompare(%data%, ["unique"])
				%data% := Lang_Trans("items_unique") ": " (InStr(%data%, "merchant") ? Lang_Trans("maps_seer") : InStr(%data%, "vault") ? Lang_Trans("maps_vaults") : SubStr(%data%, 7))
			Else If LLK_PatternMatch(log_text, "", ["losttowers", "swamptower", "mesa", "bluff", "alpineridge"],,, 0)
				%data% .= !InStr(log_text, "losttowers") ? " (" Lang_Trans("maps_tower") ")" : ""
			Else %data% .= (!InStr(log_text, "_noboss") && !InStr(log_text, "unique") ? " (" Lang_Trans("maps_boss") ")" : "")

			Loop, Parse, % %data%
				%data% := (A_Index = 1) ? "" : %data%, %data% .= (A_Index != 1 && RegExMatch(A_LoopField, "[A-Z]") ? " " : "") . A_LoopField

			If InStr(%data%, "(" Lang_Trans("maps_tower") ")") || InStr(%data%, "lost towers")
			{
				check_localization := StrReplace(%data%, " (" Lang_Trans("maps_tower") ")")
				If Lang_Trans("maps_" StrReplace(check_localization, " ", "_"))
					%data% := Lang_Trans("maps_" StrReplace(check_localization, " ", "_")) . (!InStr(check_localization, "lost towers") ? " (" Lang_Trans("maps_tower") ")" : "")
			}
			Else If InStr(%data%, "citadel")
				For index, val in ["stone", "iron", "copper"]
					If InStr(%data%, val) && Lang_Trans("maps_" val "_citadel")
					{
						%data% := StrReplace(%data%, val " citadel", Lang_Trans("maps_" val "_citadel"))
						Break
					}

		}
	Return LLK_StringCase(%data%)
}

Log_Loop(mode := 0)
{
	local
	global vars, settings

	Critical
	If settings.qol.alarm && !vars.alarm.drag
	{
		For timestamp, timer in vars.alarm.timers
			If IsNumber(StrReplace(timestamp, "|")) && (timestamp <= A_Now)
				expired := "expired"
		If (expired || vars.alarm.toggle) && !WinExist("ahk_id " vars.hwnd.alarm.alarm_set)
			Alarm("", "", vars.alarm.toggle ? "" : expired)
	}

	If vars.log.file_location ;for the unlikely event where the user manually deletes the client.txt while the tool is still running
		If IsObject(vars.log.file) && !FileExist(vars.log.file_location)
			vars.log.file.Close(), vars.log.file := ""
		Else If !IsObject(vars.log.file) && FileExist(vars.log.file_location)
			vars.log.file := FileOpen(vars.log.file_location, "a", "UTF-8")

	guide := vars.leveltracker.guide ;short-cut variable
	If !WinActive("ahk_group poe_ahk_window") || !vars.log.file_location || !WinExist("ahk_group poe_window") || !FileExist(vars.log.file_location)
		Return

	If IsObject(vars.maptracker)
		vars.maptracker.hideout := Maptracker_Towncheck() ? 1 : 0 ;flag to determine if the player is using a portal to re-enter the map (as opposed to re-entering from side-content)

	log_content := vars.log.file.Read(), level0 := vars.log.level, log_content := StrSplit(log_content, "`n", "`r" vars.lang.system_fullstop.1)

	If log_content.Count()
	{
		Log_Parse(log_content, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time, character_class)
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
		{
			If Blank(%A_LoopField%)
				Continue
			Else If (A_LoopField = "areaID") && vars.general.MultiThreading
				StringSend("areaID=" %A_LoopField%)
			vars.log[A_LoopField] := %A_LoopField%
			If (A_Index = 1)
				If !vars.poe_version
					vars.log.areaname := "" ;make it blank because there sometimes is a desync between it and areaID, i.e. they are parsed in two separate loop-ticks
				Else vars.log.areaname := Log_Get(areaID, "areaname")
		}
		If settings.features.leveltracker && !LLK_HasVal(vars.leveltracker.guide.group1, "an_end_to_hunger", 1) && !LLK_PatternMatch(vars.log.areaID, "", ["labyrinth_", "g3_10", "g2_13", "sanctum_"],,, 0) && (!Blank(areaID) && (areaID != vars.leveltracker.guide.target_area) || IsNumber(level) && (level0 != level)) && LLK_Overlay(vars.hwnd.leveltracker.main, "check") ;player has leveled up or moved to a different location: update overlay for zone-layouts, exp-gain, and act clarifications
			Leveltracker_Progress()

		If !vars.poe_version && settings.qol.alarm && (areaID = "1_1_1") && IsNumber(StrReplace((check := LLK_HasVal(vars.alarm.timers, "oni", 1)), "|")) ;for oni-goroshi farming: re-entering Twilight Strand resets timer to 0:00
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

	If !vars.poe_version && settings.features.mapinfo && vars.mapinfo.expedition_areas && vars.log.areaname && !Blank(LLK_HasVal(vars.mapinfo.expedition_areas, vars.log.areaname)) && !vars.mapinfo.active_map.expedition_filter
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

	If !vars.poe_version
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

	For index, loopfield in content
	{
		If InStr(loopfield, "Generating level ", 1)
		{
			parse := SubStr(loopfield, InStr(loopfield, "area """) + 6), areaID := SubStr(parse, 1, InStr(parse, """") -1) ;store PoE-internal location name in var
			areaseed := SubStr(loopfield, InStr(loopfield, "with seed ") + 10), areaname := ""
			If (areaID = "c_g2_9_2_" || areaID = "c_g3_16_") ;bugged PoE2 areaIDs
				areaID := SubStr(areaID, 1, -1)
			date_time := SubStr(loopfield, 1, InStr(loopfield, " ",,, 2) - 1)
			act := LLK_HasVal(db.leveltracker.areas, areaID,,,, 1), act := (vars.poe_version && act > 3 ? act - 3 : act) . (vars.poe_version && InStr(areaID, "C_") ? "c" : "") ;store current act
			arealevel := parse := SubStr(loopfield, InStr(loopfield, "level ") + 6, InStr(loopfield, " area """) - InStr(loopfield, "level ") - 6)
			If !vars.poe_version && (parse - 67 > 0)
				areatier := (parse - 67 < 10 ? "0" : "") parse - 67
			Else If vars.poe_version && (parse - 64 > 0)
				areatier := (parse - 64 < 10 ? "0" : "") parse - 64
			Else areatier := arealevel
		}
		Else If InStr(loopfield, " connected to ") && InStr(loopfield, ".login.") || InStr(loopfield, "*****")
			areaID := "login"
		Else If InStr(loopfield, "current input mode = ")
		{
			timestamp := SubStr(loopfield, 1, InStr(loopfield, " ",,, 2) - 1)
			Loop, Parse, timestamp
				timestamp := (A_Index = 1) ? "" : timestamp, timestamp .= IsNumber(A_LoopField) ? A_LoopField : ""
			method := SubStr(loopfield, InStr(loopfield, " ",, 0) + 1), method := Trim(method, "'")
			If (timestamp > vars.general.input_method.2)
			{
				vars.general.input_method := [method, timestamp]
				If (vars.settings.active = "general")
					Settings_menu("general")
			}
		}

		If Lang_Match(loopfield, vars.lang.log_enter)
			parse := SubStr(loopfield, InStr(loopfield, vars.lang.log_enter.1)), areaname := LLK_StringCase(Lang_Trim(parse, vars.lang.log_enter, Lang_Trans("log_location")))

		If !Blank(settings.general.character) && InStr(loopfield, " " settings.general.character " ")
		{
			If Lang_Match(loopfield, vars.lang.log_level)
			{
				level := SubStr(loopfield, InStr(loopfield, vars.lang.log_level.1)), level := Lang_Trim(level, vars.lang.log_level)
				If InStr(loopfield, settings.general.character " " Lang_Trans("system_parenthesis"))
					character_class := SubStr(loopfield, InStr(loopfield, Lang_Trans("system_parenthesis")) + 1)
					, character_class := LLK_StringCase(SubStr(character_class, 1, InStr(character_class, Lang_Trans("system_parenthesis", 2)) - 1))
				vars.log.character_last := loopfield
			}
			Else If Lang_Match(loopfield, vars.lang.log_whois)
			{
				level0 := SubStr(loopfield, InStr(loopfield, settings.general.character)), parse := ""
				Loop, Parse, level0
				{
					If (A_Index = 1)
						level := ""
					If IsNumber(A_LoopField)
						parse := !parse ? A_Index : parse, level .= A_LoopField
				}
				level0 := SubStr(level0, parse), level0 := SubStr(level0, InStr(level0, " ") + 1), character_class := LLK_StringCase(SubStr(level0, 1, InStr(level0, " ") - 1))
				vars.log.character_last := loopfield
			}

			If settings.leveltracker.geartracker && vars.hwnd.geartracker.main
				Geartracker_GUI("refresh")
		}

		If settings.features.maptracker && (vars.log.areaID = vars.maptracker.map.id) && (Lang_Match(loopfield, vars.lang.log_slain) || Lang_Match(loopfield, vars.lang.log_suicide))
			vars.maptracker.map.deaths += 1

		If settings.features.maptracker && settings.maptracker.kills && vars.maptracker.refresh_kills && Lang_Match(loopfield, vars.lang.log_killed)
		{
			parse := SubStr(loopfield, InStr(loopfield, vars.lang.log_killed.1)), parse := Lang_Trim(parse, vars.lang.log_killed)
			Loop, Parse, parse
				parse := (A_Index = 1) ? "" : parse, parse .= IsNumber(A_LoopField) ? A_LoopField : ""

			If (vars.maptracker.refresh_kills = 1)
				vars.maptracker.map.kills := [parse], LLK_ToolTip(Lang_Trans("maptracker_kills", 2),,,,, "Lime"), vars.tooltip_mouse := "", vars.maptracker.refresh_kills := 2
			Else If (vars.maptracker.refresh_kills > 1) && Maptracker_Towncheck()
				vars.maptracker.map.kills.2 := parse, LLK_ToolTip(Lang_Trans("maptracker_kills", 2),,,,, "Lime"), vars.maptracker.refresh_kills := 3, vars.maptracker.last_kills := parse
		}

		If settings.features.maptracker && settings.maptracker.mechanics && vars.maptracker.map.id && (vars.log.areaID = vars.maptracker.map.id)
			Maptracker_ParseDialogue(loopfield)
	}
}
