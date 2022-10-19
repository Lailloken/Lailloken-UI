﻿Leveling_guide:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "leveling_guide_panel") ;dragging the button
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		leveling_guide_panel_xpos := panelXpos
		leveling_guide_panel_ypos := panelYpos
		IniWrite, % leveling_guide_panel_xpos, ini\leveling tracker.ini, UI, button xcoord
		IniWrite, % leveling_guide_panel_ypos, ini\leveling tracker.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}
If (A_Gui = "leveling_guide_panel") && (click = 1) ;left-clicking the button
{
	If WinExist("ahk_id " hwnd_leveling_guide2)
	{
		;LLK_Overlay("leveling_guide1", "hide")
		LLK_Overlay("leveling_guide2", "hide")
		LLK_Overlay("leveling_guide3", "hide")
		WinActivate, ahk_group poe_window
		Return
	}
	If !WinExist("ahk_id " hwnd_leveling_guide2) || (A_Gui = "settings_menu")
	{
		If (hwnd_leveling_guide2 = "")
			GoSub, Leveling_guide_progress
		Else
		{
			;LLK_Overlay("leveling_guide1", "show")
			LLK_Overlay("leveling_guide2", "show")
			LLK_Overlay("leveling_guide3", "show")
		}
		WinActivate, ahk_group poe_window
	}
	Return
}

If (A_Gui = "leveling_guide_panel") && (click = 2) ;right-clicking the button
{
	GoSub, Leveling_guide_gear
	Return
}

If (A_GuiControl = "enable_leveling_guide") ;checking the enable-checkbox in the settings menu
{
	Gui, settings_menu: Submit, NoHide
	GoSub, GUI
	IniWrite, % enable_leveling_guide, ini\config.ini, Features, enable leveling guide
	If (enable_leveling_guide = 0)
	{
		Gui, leveling_guide2: Destroy
		Gui, leveling_guide3: Destroy
		hwnd_leveling_guide2 := ""
		hwnd_leveling_guide3 := ""
		Gui, gear_tracker: Destroy
		hwnd_gear_tracker := ""
		gear_tracker_limit := 6
		gear_tracker_filter := 1
		Gui, gear_tracker_indicator: Destroy
		hwnd_gear_tracker_indicator := ""
		gear_tracker_char := ""
		IniWrite, % "", ini\leveling tracker.ini, Settings, character
	}
	Else GoSub, Init_leveling_guide
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "leveling_guide_generate") ;generate-button in the settings menu
{
	Run, https://heartofphos.github.io/exile-leveling/
	Return
}
If (A_GuiControl = "leveling_guide_import") ;import-button in the settings menu
{
	Gui, leveling_guide1: Destroy
	Gui, leveling_guide2: Destroy
	Gui, leveling_guide3: Destroy
	hwnd_leveling_guide1 := ""
	hwnd_leveling_guide2 := ""
	hwnd_leveling_guide3 := ""
	build_gems_skill_str := ""
	build_gems_supp_str := ""
	build_gems_skill_dex := ""
	build_gems_supp_dex := ""
	build_gems_skill_int := ""
	build_gems_supp_int := ""
	FileRead, json_areas, data\leveling tracker\areas.json
	FileRead, json_gems, data\leveling tracker\gems.json
	FileRead, json_quests, data\leveling tracker\quests.json
	json_import := (SubStr(clipboard, 1, 2) = "[[") ? clipboard : ""
	If (json_import = "")
	{
		LLK_ToolTip("invalid import data")
		json_areas := ""
		json_gems := ""
		json_quests := ""
		Return
	}

	parsed := Json.Load(json_import)
	areas := Json.Load(json_areas)
	gems := Json.Load(json_gems)
	quests := Json.Load(json_quests)
	guide_text := ""

	Loop, % parsed.Length() ;parse all acts
	{
		loop := A_Index
		Loop, % parsed[loop].Length() ;parse steps in individual acts
		{
			step := parsed[loop][A_Index]
			step_text := ""
			If (step.type = "fragment_step")
			{
				parts := step.parts
				Loop, % parts.Length()
				{
					If !IsObject(parts[A_Index])
					{
						If (SubStr(parts[A_Index], -3) = "get ")
							text := StrReplace(parts[A_Index], "get ", "activate the ")
						Else If (InStr(parts[A_Index], "take") && InStr(step_text, "kill")) ;omit quest-items related to killing bosses
							text := ""
						Else text := InStr(parts[A_Index], " ➞ ") ? StrReplace(parts[A_Index], " ➞", ", enter") : StrReplace(parts[A_Index], "➞", "enter")
						step_text .= text
					}
					Else
					{
						type := parts[A_Index].type
						value := parts[A_Index].value
						areaID := parts[A_Index].areaId
						target_areaID := parts[A_Index].targetAreaId
						questID := parts[A_Index].questId
						version := parts[A_Index].version
						direction := StrReplace(parts[A_Index].dirIndex, 0, "north,")
						direction := StrReplace(direction, 1, "north-east,")
						direction := StrReplace(direction, 2, "east,")
						direction := StrReplace(direction, 3, "south-east,")
						direction := StrReplace(direction, 4, "south,")
						direction := StrReplace(direction, 5, "south-west,")
						direction := !InStr(step_text, "follow") && !InStr(step_text, "search") ? StrReplace(direction, 6, "west,") : StrReplace(direction, 6, "west")
						direction := StrReplace(direction, 7, "north-west,")
						Switch type  ;thing I never knew existed but really wanted
						{
							Case "enter":
								step_text .= "areaID" areaID
							Case "kill":
								step_text .= InStr(value, ",") ? SubStr(parts[A_Index].value, 1, InStr(parts[A_Index].value, ",") - 1) : StrReplace(value, "alira darktongue", "alira") ;shorten boss names
							Case "quest":
								step_text .= quests[questID].name
							Case "quest_text":
								step_text .= !InStr(step_text, "kill") ? value : "" ;omit quest-items related to killing bosses
							Case "get_waypoint":
								step_text .= "waypoint"
							Case "waypoint":
								step_text .= (areaID != "") ? "waypoint-travel to areaID" areaID : InStr(step_text, "for the broken") ? "waypoint" : "the waypoint"
							Case "logout":
								step_text .= "relog, enter areaID" areaID
							Case "portal":
								If (target_areaID = "")
									step_text .= "portal"
								Else step_text .= "portal to areaID" target_areaID
							Case "trial":
								step_text .= "the lab-trial"
							Case "arena":
								step_text .= value
							Case "area":
								step_text .= areas[areaID].name
							Case "dir":
								step_text .= direction
							Case "crafting":
								step_text .= "crafting recipe"
							Case "generic":
								step_text .= value
							Case "ascend":
								step_text .= "enter and complete the " version " lab"
						}
					}
				}
			}
			If (step.type = "gem_step")
			{
				rewardType := step.rewardType
				gemID := step.requiredGem.id
				step_text .= (rewardType = "vendor") ? "buy " : "take reward: "
				step_text .= gems[gemID].name
				Switch gems[gemID].primary_attribute ;group gems into strings for search-strings feature
				{
					Case "strength":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_str .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support")
							build_gems_supp_str .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
					Case "dexterity":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_dex .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support")
							build_gems_supp_dex .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
					Case "intelligence":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_int .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support") || InStr(gems[gemID].name, "arcanist brand")
							build_gems_supp_int .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
				}
			}
			guide_text .= StrReplace(step_text, ",,", ",") "`n"
		}
	}
	
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int ;create single gem-string for gear tracker feature
	
	IniDelete, ini\leveling tracker.ini, Gems
	IniDelete, ini\stash search.ini, tracker_gems
	IniRead, placeholder, ini\stash search.ini, Settings, vendor, % A_Space
	If InStr(placeholder, "(tracker_gems)")
		IniWrite, % StrReplace(placeholder, "(tracker_gems),"), ini\stash search.ini, Settings, vendor
	If (build_gems_all != "")
	{
		Sort, build_gems_all, D`, P2 N
		Sort, build_gems_skill_str, D`, P2 N
		Sort, build_gems_supp_str, D`, P2 N
		Sort, build_gems_skill_dex, D`, P2 N
		Sort, build_gems_supp_dex, D`, P2 N
		Sort, build_gems_skill_int, D`, P2 N
		Sort, build_gems_supp_int, D`, P2 N
		
		build_gems_all := StrReplace(build_gems_all, ")", ") ")	
		build_gems_all := StrReplace(build_gems_all, " support", "")	
		IniWrite, % SubStr(StrReplace(build_gems_all, ",", "`n"), 1, -1), ini\leveling tracker.ini, Gems ;save gems for gear tracker feature
	}
	
	parse := "skill_str,supp_str,skill_dex,supp_dex,skill_int,supp_int"
	
	search_string_skill_str := ""
	search_string_supp_str := ""
	search_string_skill_dex := ""
	search_string_supp_dex := ""
	search_string_skill_int := ""
	search_string_supp_int := ""
	search_string_all := ""
	
	If (all_gems = "")
		FileRead, all_gems, data\leveling tracker\gems.txt
	
	Loop, Parse, parse, `,, `, ;create advanced search-string
	{
		loop := A_Loopfield
		parse_string := ""
		If (build_gems_%A_Loopfield% = "")
			continue
		Loop, Parse, build_gems_%A_Loopfield%, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse_gem := SubStr(A_Loopfield, 5)
			Loop, Parse, parse_gem
			{
				If (parse_gem = "arc") && (A_Index = 1)
				{
					parse_gem := "arc$"
					break
				}
				If (A_Index = 1)
					parse_gem := ""
				parse_gem .= A_Loopfield
				If (LLK_SubStrCount(all_gems, parse_gem, "`n", 1) = 1) && (StrLen(parse_gem) >= 3)
					break
			}
			If (StrLen(parse_string parse_gem) <= 47)
				parse_string .= parse_gem "|"
			Else
			{
				search_string_%loop% .= "^(" StrReplace(SubStr(parse_string, 1, -1), " ", ".") ");"
				parse_string := parse_gem "|"
			}
		}
		search_string_%loop% .= "^(" StrReplace(SubStr(parse_string, 1, -1), " ", ".") ")"
	}
	
	Loop, Parse, parse, `,, `,
	{
		If (search_string_%A_Loopfield% != "")
			search_string_all .= search_string_%A_Loopfield% ";"
	}
	
	If (search_string_all != "")
	{
		search_string_all := SubStr(search_string_all, 1, -1)
		IniRead, placeholder, ini\stash search.ini, Settings, vendor, % A_Space
		If !InStr(placeholder, "(tracker_gems)")
			IniWrite, % placeholder "(tracker_gems),", ini\stash search.ini, Settings, vendor
		IniWrite, 1, ini\stash search.ini, tracker_gems, enable
		IniWrite, "%search_string_all%", ini\stash search.ini, tracker_gems, string 1
		IniWrite, 1, ini\stash search.ini, tracker_gems, string 1 enable scrolling
		IniWrite, "", ini\stash search.ini, tracker_gems, string 2
		IniWrite, 0, ini\stash search.ini, tracker_gems, string 2 enable scrolling
	}
	
	guide_text := StrReplace(guide_text, "&", "&&")
	StringLower, guide_text, guide_text
	IniDelete, ini\leveling guide.ini, Steps
	IniWrite, % guide_text, ini\leveling guide.ini, Steps
	
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	guide_progress_percent := (guide_progress != "" & guide_text_original != "") ? Format("{:0.2f}", (LLK_InStrCount(guide_progress, "`n")/LLK_InStrCount(guide_text_original, "`n"))*100) : 0
	guide_progress_percent := (guide_progress_percent >= 99) ? 100 : guide_progress_percent
	GuiControl, settings_menu:, leveling_guide_progress, % "current progress: " guide_progress_percent "%"
	
	guide_text := ""
	parsed := ""
	areas := ""
	gems := ""
	quests := ""
	json_areas := ""
	json_gems := ""
	json_quests := ""
	clipboard := ""
	LLK_ToolTip("success")
	Return
}
If (A_GuiControl = "leveling_guide_delete") ;delete-button in the settings menu
{
	IniDelete, ini\leveling guide.ini, Steps
	IniDelete, ini\leveling tracker.ini, gems
	GuiControl, settings_menu:, leveling_guide_progress, % "current progress: 0%"
	Gui, leveling_guide2: Destroy
	hwnd_leveling_guide2 := ""
	Gui, leveling_guide3: Destroy
	hwnd_leveling_guide3 := ""
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
	Return
}
If (A_GuiControl = "leveling_guide_reset") ;reset-button in the settings menu
{
	IniDelete, ini\leveling guide.ini, Progress
	guide_progress := ""
	GuiControl, settings_menu:, leveling_guide_progress, % "current progress: 0%"
	hwnd_leveling_guide2 := ""
	guide_panel1_text := "n/a"
	GoSub, Leveling_guide_progress
	Return
}
If InStr(A_GuiControl, "button_leveling_guide") ;button-settings in the settings menu
{
	If (A_GuiControl = "button_leveling_guide_minus")
		leveling_guide_panel_offset -= (leveling_guide_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_leveling_guide_reset")
		leveling_guide_panel_offset := 1
	If (A_GuiControl = "button_leveling_guide_plus")
		leveling_guide_panel_offset += (leveling_guide_panel_offset < 1) ? 0.1 : 0
	IniWrite, % leveling_guide_panel_offset, ini\leveling tracker.ini, Settings, button-offset
	leveling_guide_panel_dimensions := poe_width*0.03*leveling_guide_panel_offset
	GoSub, GUI
	Return
}
;UI-settings in the settings menu
If (A_GuiControl = "fSize_leveling_guide_minus")
{
	fSize_offset_leveling_guide -= 1
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_leveling_guide_plus")
{
	fSize_offset_leveling_guide += 1
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_leveling_guide_reset")
{
	fSize_offset_leveling_guide := 0
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "leveling_guide_opac_minus")
{
	leveling_guide_trans -= (leveling_guide_trans > 100) ? 30 : 0
	IniWrite, %leveling_guide_trans%, ini\leveling tracker.ini, Settings, transparency
}
If (A_GuiControl = "leveling_guide_opac_plus")
{
	leveling_guide_trans += (leveling_guide_trans < 250) ? 30 : 0
	IniWrite, %leveling_guide_trans%, ini\leveling tracker.ini, Settings, transparency
}
If InStr(A_GuiControl, "fontcolor_")
{
	leveling_guide_fontcolor := StrReplace(A_GuiControl, "fontcolor_", "")
	IniWrite, %leveling_guide_fontcolor%, ini\leveling tracker.ini, Settings, font-color
}
If InStr(A_GuiControl, "leveling_guide_position_")
{
	leveling_guide_position := StrReplace(A_GuiControl, "leveling_guide_position_")
	IniWrite, % leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position
}
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
If (hwnd_leveling_guide2 != "")
{
	hwnd_leveling_guide2 := ""
	GoSub, Leveling_guide_progress
}
If (hwnd_gear_tracker != "")
{
	hwnd_gear_tracker := ""
	GoSub, Leveling_guide_gear
}
Return

Leveling_guide_gear:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "gear_tracker_indicator") ;dragging the gear tracker indicator
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		gear_tracker_indicator_xpos := panelXpos
		gear_tracker_indicator_ypos := panelYpos
		IniWrite, % gear_tracker_indicator_xpos, ini\leveling tracker.ini, UI, indicator xcoord
		IniWrite, % gear_tracker_indicator_ypos, ini\leveling tracker.ini, UI, indicator ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}

If (A_Gui = "gear_tracker_indicator")
	Return

If (A_GuiControl = "gear_tracker_filter") ;clicking the checkbox
{
	gear_tracker_char_backup := gear_tracker_char
	Gui, gear_tracker: Submit, NoHide
	gear_tracker_char := gear_tracker_char_backup
	gear_tracker_limit := (gear_tracker_filter = 1) ? 6 : 100
}

If InStr(A_GuiControl, "select character") ;clicking the 'select character' label
{
	If (click = 1)
	{
		If (gear_tracker_parse = "`n")
		{
			LLK_ToolTip("nothing to highlight")
			Return
		}
		regex_length := Floor((47 - gear_tracker_count)/gear_tracker_count)
		regex_string := "^("
		Loop, Parse, gear_tracker_parse, `n, `n
		{
			If (A_Loopfield = "")
				continue
			
			If (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char])
			{
				If (SubStr(A_Loopfield, 6) = "arc")
				{
					regex_string .= "arc$|"
					continue
				}
				regex_string .= InStr(A_Loopfield, ":") ? SubStr(A_Loopfield, InStr(A_Loopfield, ":") + 2, regex_length) "|" : SubStr(A_Loopfield, 6, regex_length) "|"
			}
		}
		regex_string := StrReplace(SubStr(regex_string, 1, -1), " ", ".") ")"
		If (StrLen(regex_string) <= 3)
		{
			LLK_ToolTip("nothing to highlight")
			Return
		}
		clipboard := regex_string
		KeyWait, LButton
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		SendInput, ^{f}^{v}
	}
	Return
}

If (A_Gui = "gear_tracker") && (A_GuiControl != "gear_tracker_char") && (A_GuiControl != "gear_tracker_filter") ;clicking anything but the drop-down list and checkbox
{
	If (click = 1)
	{
		clipboard := (SubStr(A_GuiControl, 6) = "arc") ? "arc$" : InStr(A_GuiControl, ":") ? SubStr(A_GuiControl, InStr(A_GuiControl, ":") + 2, 47) : SubStr(A_GuiControl, 6, 47)
		KeyWait, LButton
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		SendInput, ^{f}^{v}
		Return
	}
	Else
	{
		IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
		IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
		If InStr(gear_tracker_items, A_GuiControl)
		{
			gear_tracker_items := InStr(gear_tracker_items, A_GuiControl "`n") ? StrReplace(gear_tracker_items, A_GuiControl "`n") : StrReplace(gear_tracker_items, A_GuiControl)
			IniDelete, ini\leveling tracker.ini, gear
			IniWrite, % gear_tracker_items, ini\leveling tracker.ini, gear
		}
		If InStr(gear_tracker_gems, A_GuiControl)
		{
			gear_tracker_gems := InStr(gear_tracker_gems, A_GuiControl "`n") ? StrReplace(gear_tracker_gems, A_GuiControl "`n") : StrReplace(gear_tracker_gems, A_GuiControl)
			IniDelete, ini\leveling tracker.ini, gems
			IniWrite, % gear_tracker_gems, ini\leveling tracker.ini, gems
		}
		GoSub, Log_loop
	}
}

If (A_GuiControl = "gear_tracker_char") ;clicking the drop-down list
{
	Gui, gear_tracker: Submit, NoHide
	gear_tracker_char := SubStr(gear_tracker_char, 1, InStr(gear_tracker_char, "(") - 2)
	IniWrite, % gear_tracker_char, ini\leveling tracker.ini, Settings, character
}

If (WinExist("ahk_id " hwnd_gear_tracker) && (A_Gui != "gear_tracker") && (update_gear_tracker != 1))
{
	LLK_GearTrackerGUI(1)
	GoSub, Log_loop
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
	gear_tracker_limit := 6
	gear_tracker_filter := 1
	WinActivate, ahk_group poe_window
	Return
}
Else
{
	LLK_GearTrackerGUI()
	update_gear_tracker := 0
	GoSub, Log_loop
	Gui, gear_tracker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gear_tracker
	Gui, gear_tracker: Margin, 12, 4
	Gui, gear_tracker: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, gear_tracker: Font, % "cWhite s"fSize_leveling_guide, Fontin SmallCaps
	gear_tracker_DDL := ""
	For a, b in gear_tracker_characters
		gear_tracker_DDL .= (a = gear_tracker_char) ? a " (" b ")||" : a " (" b ")|"
	;gear_tracker_DDL := (SubStr(gear_tracker_DDL, -2) = "||") ? SubStr(gear_tracker_DDL, 1, -2) : SubStr(gear_tracker_DDL, 1, -1)
	Gui, gear_tracker: Add, Text, % "Section BackgroundTrans gLeveling_guide_gear", % "select character: "
	Gui, gear_tracker: Font, % "s"fSize_leveling_guide - 4
	Gui, gear_tracker: Add, DDL, % "ys x+0 BackgroundTrans cBlack vgear_tracker_char gLeveling_guide_gear wp hp r"gear_tracker_characters.Count(), % gear_tracker_DDL
	Gui, gear_tracker: Add, Picture, ys BackgroundTrans vMap_info vgear_tracker_help gSettings_menu_help hp w-1, img\GUI\help.png
	Gui, gear_tracker: Font, % "s"fSize_leveling_guide
	Gui, gear_tracker: Add, Checkbox, % "xs BackgroundTrans vgear_tracker_filter gLeveling_guide_gear Checked"gear_tracker_filter, % "limit to +5 levels"
	
	IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
	IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
	
	gear_tracker_parse := gear_tracker_items "`n" gear_tracker_gems
	Sort, gear_tracker_parse, P2 D`n N
	StringLower, gear_tracker_parse, gear_tracker_parse
	Loop, Parse, gear_tracker_parse, `n, `n
	{
		If (A_Loopfield = "")
			continue
		If (SubStr(A_Loopfield, 2, 2) < gear_tracker_characters[gear_tracker_char] + gear_tracker_limit)
			Gui, gear_tracker: Add, Text, % (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char]) ? "xs cLime gLeveling_guide_gear BackgroundTrans" : "xs gLeveling_guide_gear BackgroundTrans", % A_Loopfield
	}
	
	If (gear_tracker_parse = "`n")
		Gui, gear_tracker: Add, Text, % "xs BackgroundTrans", % "no items added"
	Gui, gear_tracker: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_gear_tracker%
	Gui, gear_tracker: Show, % "NA xCenter y"yScreenOffSet + poe_height - height

	guilist .= InStr(guilist, "|gear_tracker|") ? "" : "gear_tracker|"
	LLK_Overlay("gear_tracker", "show")
	WinActivate, ahk_group poe_window
}
Return

Leveling_guide_progress:
If (areas = "")
{
	FileRead, json_areas, data\leveling tracker\areas.json
	areas := Json.Load(json_areas)
}
If (A_Gui = "leveling_guide_panel" && hwnd_leveling_guide2 = "") || (A_GuiControl = "leveling_guide_reset") || InStr(A_GuiControl, "jump")
{
	If InStr(A_GuiControl, "jump")
	{
		If (A_GuiControl = "leveling_guide_jump_forward")
		{
			If InStr(guide_panel2_text, "an end to hunger")
				Return
			guide_progress .= (guide_progress = "") ? guide_panel2_text : "`n" guide_panel2_text
		}
		Else
		{
			guide_text := guide_text_original
			guide_progress := StrReplace(guide_progress, "`n" guide_panel1_text)
		}
	}
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	;IniRead, guide_text, ini\leveling guide.ini, Steps,, % A_Space
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space

	If (guide_text_original = "")
	{
		LLK_ToolTip("no imported guide")
		Return
	}
	guide_text := guide_text_original
	Loop, Parse, guide_progress, `n, `n
	{
		If (A_Loopfield = "")
			break
		guide_text := StrReplace(guide_text, A_LoopField "`n",,, 1)
	}
}
/*
Else
{
	IniRead, guide_text, ini\leveling guide.ini, Steps,, % A_Space
	Loop, Parse, guide_progress, `n, `n
		guide_text := StrReplace(guide_text, A_LoopField "`n",,, 1)
}
*/

If (guide_progress = "")
	guide_panel1_text := "n/a"

Loop, Parse, guide_progress, `n, `n
{
	If (A_LoopField = "")
		break
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to")) && !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
	{
		parsed_step1 .= (parsed_step1 = "") ? A_Loopfield : "`n" A_Loopfield
		guide_section1 := 1
	}
	Else
	{
		parsed_step1 := (guide_section1 = 1) ? A_Loopfield : parsed_step1 "`n" A_Loopfield
		guide_section1 := 0
	}
	
	If (guide_section1 = 1)
	{
		parsed_step1 := (SubStr(parsed_step1, 1, 1) = "`n") ? SubStr(parsed_step1, 2) : parsed_step1
		guide_panel1_text := parsed_step1
		guide_section1 := 0
		parsed_step1 := ""
	}
}

Loop, Parse, guide_text, `n, `n ;check progression and create texts for panels
{
	If (A_Loopfield = "") 
		break
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to")) && !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
	{
		parsed_step .= (parsed_step = "") ? A_Loopfield : "`n" A_Loopfield
		guide_section := 1
	}
	Else
	{
		parsed_step := (guide_section = 1) ? A_Loopfield : parsed_step "`n" A_Loopfield
		guide_section := 0
	}
	
	If (guide_section = 1 || InStr(A_Loopfield, "an end to hunger"))
	{
		parsed_step := (SubStr(parsed_step, 1, 1) = "`n") ? SubStr(parsed_step, 2) : parsed_step
		guide_panel2_text := parsed_step
		guide_section := 0
		parsed_step := ""
		break
	}
}

;text1 := StrReplace(guide_panel1_text, ", kill", "`nkill")
;text1 := ((InStr(text1, ",") > 20) && (StrLen(text1) > 30)) ? StrReplace(text1, ", ", "`n",, 1) : text1
;text1 := "- " StrReplace(text1, "`n", "`n- ")
text1 := "- " StrReplace(guide_panel1_text, "`n", "`n- ")
If InStr(text1, "areaID")
	text1 := LLK_ReplaceAreaID(text1)

;text2 := StrReplace(guide_panel2_text, ", kill", "`nkill")
;text2 := ((InStr(text2, ",") > 20) && (StrLen(text2) > 30)) ? StrReplace(text2, ", ", "`n",, 1) : text2
;text2 := "- " StrReplace(text2, "`n", "`n- ")
text2 := InStr(guide_panel2_text, "`n") ? "- " StrReplace(guide_panel2_text, "`n", "`n- ") : guide_panel2_text
If InStr(text2, "areaID")
	text2 := LLK_ReplaceAreaID(text2)

If LLK_SubStrCount(text2, "buy", "`n") ;check if there are steps for buying gems
{
	search2 := ""
	If (all_gems = "")
		FileRead, all_gems, data\leveling tracker\gems.txt
	loop := 0
	required_gems := LLK_SubStrCount(guide_panel2_text, "buy ", "`n")
	Loop, Parse, guide_panel2_text, `n, `n ;check how many gems fit into the search-string
	{
		If InStr(A_Loopfield, "buy")
		{
			loop += 1
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "buy") + 4)
			parsed_gem := ""
			Loop, Parse, parse
			{
				If (parse = "arc")
				{
					parse := "arc$"
					break
				}
				parsed_gem .= A_Loopfield
				If (LLK_SubStrCount(all_gems, parsed_gem, "`n", 1) = 1) && (StrLen(parsed_gem) > 2)
				{
					parse := parsed_gem
					break
				}
			}
			If (StrLen(search2 parse) >= 47)
				break
			search2 .= parse "|"
		}
	}
	parsed_gems := LLK_InStrCount(search2, "|")
	skipped_gems := 0
	Loop, Parse, text2, `n, `n ;merge gem-buy bullet-points into a collective one
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "buy")
		{
			If !InStr(text2, "buy gems")
				text2 .= (text2 = "") ? "- buy gems (highlight: ctrl-f-v)" : "`n- buy gems (highlight: ctrl-f-v)"
			skipped_gems += 1
			If (skipped_gems <= parsed_gems) ;only merge gems that fit into search-string
				continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
}

If (InStr(text2, "kill doedre") && InStr(text2, "kill maligaro") && InStr(text2, "kill shavronne")) ;merge multi-boss kills into a single line
{
	Loop, Parse, text2, `n, `n
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "find and kill")
		{
			If !InStr(text2, "find and kill")
				text2 .= (text2 = "") ? "- find and kill doedre, maligaro, and shavronne" : "`n- find and kill doedre, maligaro, and shavronne"
			continue
		}
		Else If InStr(A_Loopfield, "kill") && !InStr(A_Loopfield, "depraved trinity") && !InStr(A_Loopfield, "malachai")
		{
			If !InStr(text2, "kill")
				text2 .= (text2 = "") ? "- kill doedre, maligaro, and shavronne" : "`n- kill doedre, maligaro, and shavronne"
			continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
}

text2 := StrReplace(text2, "shavronne the returned && reassembled brutus", "shavronne && brutus")

/*
Loop, Parse, text2, `n, `n
{
	If (A_Index = 1)
		text2 := ""
	If ((InStr(A_Loopfield, ",") > 20) && (StrLen(A_Loopfield) > 30))
		text2 := (text2 = "") ? StrReplace(A_Loopfield, ", ", ",`n",, 1) : text2 "`n" StrReplace(A_Loopfield, ", ", ",`n",, 1)
	Else text2 := (text2 = "") ? A_Loopfield : text2 "`n" A_Loopfield
}
*/

If (hwnd_leveling_guide2 = "")
{
	Gui, leveling_guide1: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide1
	Gui, leveling_guide1: Margin, 12, 0
	Gui, leveling_guide1: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, leveling_guide1: Font, % "cLime s"fSize_leveling_guide, Fontin SmallCaps
	Gui, leveling_guide1: Add, Text, % "BackgroundTrans HWNDhwnd_levelingguidetext1", % (guide_panel1_text = "") ? "n/a" : text1

	Gui, leveling_guide2: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide2
	Gui, leveling_guide2: Margin, 12, 0
	Gui, leveling_guide2: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, leveling_guide2: Font, c%leveling_guide_fontcolor% s%fSize_leveling_guide%, Fontin SmallCaps
	Gui, leveling_guide2: Add, Text, % "BackgroundTrans HWNDhwnd_levelingguidetext2", % text2

	;Gui, leveling_guide1: Show, NA x10000 y10000
	Gui, leveling_guide2: Show, NA x10000 y10000
	guilist .= InStr(guilist, "|leveling_guide2|leveling_guide3|") ? "" : "leveling_guide2|leveling_guide3|"
}
Else
{
	SetTextAndResize(hwnd_levelingguidetext2, text2, "s" fSize_leveling_guide, "Fontin SmallCaps")
	;SetTextAndResize(hwnd_levelingguidetext1, text1, "s" fSize_leveling_guide, "Fontin SmallCaps")
	;Gui, leveling_guide1: Show, NA x10000 y10000 AutoSize
	Gui, leveling_guide2: Show, NA x10000 y10000 AutoSize
}

;WinGetPos,,, width, height, ahk_id %hwnd_leveling_guide1%
WinGetPos,,, width2, height, ahk_id %hwnd_leveling_guide2%
;width := (width > width2) ? width : width2
;height := (height > height2) ? height : height2
height := height

Gui, leveling_guide3: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide3
Gui, leveling_guide3: Margin, 0, 0
Gui, leveling_guide3: Color, Black
WinSet, Transparent, %leveling_guide_trans%
Gui, leveling_guide3: Font, % "c" leveling_guide_fontcolor " s"fSize_leveling_guide*(2/3), Fontin SmallCaps
Gui, leveling_guide3: Add, Text, % "BackgroundTrans Section vleveling_guide_jump_back Center gLeveling_guide_progress w"width2/2, % " < "
Gui, leveling_guide3: Add, Text, % "BackgroundTrans ys vleveling_guide_jump_forward Center gLeveling_guide_progress w"width2/2, % " > "
Gui, leveling_guide3: Show, NA x10000 y10000
WinGetPos,,, width3, height3, ahk_id %hwnd_leveling_guide3%

Switch leveling_guide_position
{
	Case "top":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + height3 - 1 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet " w"width2 - 2
	Case "bottom":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet + (47/48)*poe_height - height " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height - height3 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height3 + 1 " w"width2 - 2
}
;LLK_Overlay("leveling_guide1", "show")
LLK_Overlay("leveling_guide2", "show")
LLK_Overlay("leveling_guide3", "show")
Return

Init_leveling_guide:
IniRead, enable_leveling_guide, ini\config.ini, Features, enable leveling guide, 0
IniRead, fSize_offset_leveling_guide, ini\leveling tracker.ini, Settings, font-offset, 0
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
IniRead, leveling_guide_fontcolor, ini\leveling tracker.ini, Settings, font-color, White
IniRead, leveling_guide_trans, ini\leveling tracker.ini, Settings, transparency, 250
IniRead, leveling_guide_panel_offset, ini\leveling tracker.ini, Settings, button-offset, 1
IniRead, leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position, bottom
leveling_guide_panel_dimensions := poe_width*0.03*leveling_guide_panel_offset
IniRead, leveling_guide_panel_xpos, ini\leveling tracker.ini, UI, button xcoord, % poe_width/2 - (leveling_guide_panel_dimensions + 2)/2
IniRead, leveling_guide_panel_ypos, ini\leveling tracker.ini, UI, button ycoord, % poe_height - (leveling_guide_panel_dimensions + 2)
IniRead, gear_tracker_char, ini\leveling tracker.ini, Settings, character, % A_Space
IniRead, gear_tracker_indicator_xpos, ini\leveling tracker.ini, UI, indicator xcoord, % 0.3*poe_width
IniRead, gear_tracker_indicator_ypos, ini\leveling tracker.ini, UI, indicator ycoord, % 0.91*poe_height
If FileExist(poe_log_file)
{
	poe_log_content_short := SubStr(poe_log_content, -5000)
	Loop, Parse, poe_log_content_short, `r`n, `r`n
	{
		If InStr(A_Loopfield, "generating level")
		{
			current_location := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6)
			Loop, Parse, current_location
			{
				If (A_Index = 1)
					current_location := ""
				If (A_Loopfield = """")
					break
				current_location .= A_Loopfield
			}
		}
	}
	If (enable_leveling_guide = 1)
	{
		;FileRead, poe_log_content, % poe_log_file
		gear_tracker_characters := []
		Loop
		{
			poe_log_content_short := SubStr(poe_log_content, -0.1*A_Index*StrLen(poe_log_content))
			Loop, Parse, poe_log_content_short, `r`n, `r`n
			{
				If InStr(A_Loopfield, "is now level ")
				{
					parsed_level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level "))
					parsed_level := StrReplace(parsed_level, "is now level ")
					parsed_character := SubStr(A_Loopfield, InStr(A_Loopfield, " : ") + 3, InStr(A_Loopfield, ")"))
					parsed_character := SubStr(parsed_character, 1, InStr(parsed_character, "(") - 2)
					gear_tracker_characters[parsed_character] := parsed_level
				}
			}
			If (A_Index = 5)
				gear_tracker_characters["none found, restart"] := 0
			If (gear_tracker_characters.Count() > 0)
				break
		}
		;poe_log_content := ""
		poe_log_content_short := ""
	}
	GoSub, Log_loop
}
Return