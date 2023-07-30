Init_log()
{
	local
	global vars, settings

	If !IsObject(vars.log.file)
	{
		vars.log.file := FileOpen(vars.log.file_location, "r")
		log_content := vars.log.file.Read()
	}
	Else FileRead, log_content, % vars.log.file_location

	vars.log.parsing := "areaID, areaname, areaseed, arealevel, areatier, act, level, date_time"
	Loop, Parse, % vars.log.parsing, `,, %A_Space%
		vars.log[A_LoopField] := ""
	
	log_length := StrLen(log_content), settings.general.character := LLK_IniRead("ini\config.ini", "settings", "active character")
	check := Blank(settings.general.character) ? 0 : InStr(log_content, " " settings.general.character " (")
	
	While !vars.log.areaID || !vars.log.level ;parse log until current area and level was found
	{
		log_chunk := SubStr(log_content, 1 - 5000*A_Index, 5500), log_chunk := SubStr(log_chunk, InStr(log_chunk, "`n") + 1) ;break up log into smaller chunks of 5000 characters (with 10% buffer to avoid incomplete lines)
		While (SubStr(log_chunk, 0) != "`r") ;remove incomplete line at the end
			log_chunk := SubStr(log_chunk, 1, -1)
		log_chunk := SubStr(log_chunk, 1, -1)
		
		If vars.log.areaID && !check || (5000*A_Index >= log_length) ;break if character could not be found in the whole log
			Break
		If vars.log.areaID && !InStr(log_chunk, " " settings.general.character " (") ;skip chunk if it doesn't contain level-up messages
			Continue

		LogParse(log_chunk, areaID, areaname, areaseed, arealevel, areatier, act, level, date_time) ;pass log-chunk to parse-function to extract the required information: the info is returned via ByRef variables
		Loop, Parse, % vars.log.parsing, `,, %A_Space%
			If Blank(vars.log[A_LoopField]) && !Blank(%A_LoopField%)
				vars.log[A_LoopField] := %A_LoopField% ;store parsed info globally (only once, and as close to the end of the log as possible)
	}
	vars.log.level := !vars.log.level ? 0 : vars.log.level
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
		vars.maptracker.hideout := InStr(vars.log.areaID, "hideout") ? 1 : 0 ;flag to determine if the player is using a portal to re-enter the map (as opposed to re-entering from side-content)

	log_content := vars.log.file.Read()
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
		If !Blank(areaID) && (areaID != vars.leveltracker.guide.target_area) && WinExist("ahk_id "vars.hwnd.leveltracker.main) ;player has moved to a different location: update overlay for zone-layouts, exp-gain, and act clarifications
			LeveltrackerProgress(1)
		If settings.qol.alarm && vars.alarm.timestamp && (areaID = "1_1_1") ;for oni-goroshi farming: re-entering Twilight Strand resets timer to 0:00
			vars.alarm.timestamp := A_Now

		If settings.qol.lab && InStr(areaID, "labyrinth_airlock") ;entering Aspirants' Plaza: reset previous lab-progress (if there is any)
			Lab("init")
		Else If settings.qol.lab && (InStr(vars.log.areaID, "labyrinth_") && !InStr(vars.log.areaID, "Airlock") || InStr(areaID, "labyrinth_") && !InStr(areaID, "Airlock")) && areaname ;entering a new room
		{
			For index, room in vars.lab.rooms ;go through previously-entered rooms to check if player is backtracking or not
				If (room.name = areaname && room.seed = vars.log.areaseed)
				{
					check := index
					Break
				}
			If check
				Lab("backtrack", check)
			Else If LLK_HasVal(vars.lab.exits.names, areaname) ;check which adjacent room has been entered
				Lab("progress")
		}
	}
	
	If mode
		Return

	If settings.qol.lab && InStr(vars.log.areaID, "labyrinth_") && !InStr(vars.log.areaID, "Airlock") && vars.log.areaseed && vars.lab.rooms.Count() && !vars.lab.rooms.1.seed
		vars.lab.rooms.1.seed := vars.log.areaseed, vars.lab.room.3 := vars.log.areaseed

	If settings.features.leveltracker && (A_TickCount > vars.leveltracker.last_manual + 2000) && vars.hwnd.leveltracker.main && (vars.log.areaID = vars.leveltracker.guide.target_area) && !vars.leveltracker.fast ;advance the guide when entering target-location
	{
		Leveltracker("+")
		If vars.leveltracker.overlays
			LeveltrackerOverlays()
	}
	
	If settings.features.mapinfo && vars.mapinfo.expedition_areas && vars.log.areaname && LLK_HasVal(vars.mapinfo.expedition_areas, vars.log.areaname) && !vars.mapinfo.active_map.expedition_filter
	{
		Loop, % vars.mapinfo.categories.Count()
		{
			parse := InStr(vars.mapinfo.categories[A_Index], "(") ? SubStr(vars.mapinfo.categories[A_Index], 1, InStr(vars.mapinfo.categories[A_Index], "(") - 2) : vars.mapinfo.categories[A_Index]
			If LLK_HasVal(vars.mapinfo.expedition_areas, parse) && (parse != vars.log.areaname)
				vars.mapinfo.categories[A_Index] := ""
		}
			
		vars.mapinfo.active_map.expedition_filter := 1
	}

	MaptrackerTimer()
	LeveltrackerTimer()

	If vars.leveltracker.gear_ready && WinExist("ahk_id "vars.hwnd.leveltracker_button.main)
	{
		button_color := (button_color = "Lime") ? "Aqua" : "Lime"
		Gui, leveltracker_button: Color, % button_color
	}
	Else If !vars.leveltracker.gear_ready && (button_color = "Lime")
	{
		Gui, leveltracker_button: Color, Aqua
		button_color := "Aqua"
	}
}

LogParse(content, ByRef areaID, ByRef areaname, ByRef areaseed, ByRef arealevel, ByRef areatier, ByRef act, ByRef level, ByRef date_time)
{
	local
	global vars, settings, db

	StringLower, content, content
	Loop, Parse, content, `n, `r
	{
		If InStr(A_LoopField, "generating level")
		{
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6), areaID := SubStr(parse, 1, InStr(parse, """") -1) ;store PoE-internal location name in var
			areaseed := SubStr(A_Loopfield, InStr(A_Loopfield, "with seed ") + 10), areaname := ""
			date_time := SubStr(A_LoopField, 1, InStr(A_LoopField, " ",,, 2) - 1)
			act := db.leveltracker.areas[areaID].act ;store current act
			arealevel := parse := SubStr(A_LoopField, InStr(A_LoopField, "level ") + 6, InStr(A_LoopField, " area """) - InStr(A_LoopField, "level ") - 6)
			If (parse - 67 > 0)
				areatier := (parse - 67 < 10) ? 0 . parse - 67 : parse - 67
		}
		Else If InStr(A_LoopField, " connected to ") && InStr(A_LoopField, ".login.")
			areaID := "login"

		If InStr(A_LoopField, "you have entered ")
			parse := SubStr(A_LoopField, InStr(A_LoopField, "you have entered") + 17), areaname := SubStr(parse, 1, -1)

		If !Blank(settings.general.character) && InStr(A_LoopField, " " settings.general.character " ") && InStr(A_LoopField, " is now level ")
		{
			level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level ")), level := StrReplace(level, "is now level ")
			If vars.hwnd.geartracker.main
				GeartrackerGUI("refresh")
		}

		If settings.features.maptracker && (vars.log.areaID = vars.maptracker.map.id) && (InStr(A_LoopField, " has been slain.") || InStr(A_LoopField, " has committed suicide."))
			vars.maptracker.map.deaths += 1

		If settings.features.maptracker && settings.maptracker.kills && vars.maptracker.refresh_kills && InStr(A_LoopField, "you have killed ")
		{
			parse := SubStr(A_LoopField, InStr(A_LoopField, "you have killed ") + 16), parse := SubStr(parse, 1, InStr(parse, " monsters") - 1)
			Loop, Parse, parse
			{
				If (A_Index = 1)
					parse := ""
				If !IsNumber(A_LoopField)
					Continue
				parse .= A_LoopField
			}
			If (vars.maptracker.refresh_kills = 1)
				vars.maptracker.map.kills := [parse], LLK_ToolTip("kill-count updated",,,,, "Lime"), vars.tooltip_mouse := "", vars.maptracker.refresh_kills := 2
			Else If (vars.maptracker.refresh_kills > 1) && InStr(vars.log.areaID, "hideout")
				vars.maptracker.map.kills.2 := parse, LLK_ToolTip("kill-count updated",,,,, "Lime"), vars.maptracker.refresh_kills := 3
		}
	}
}
