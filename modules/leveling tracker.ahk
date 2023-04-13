Init_leveling_guide:
IniRead, settings_enable_levelingtracker, ini\config.ini, Features, enable leveling guide, 0
IniRead, leveling_guide_enable_timer, ini\leveling tracker.ini, Settings, enable timer, 0
IniRead, fSize_offset_leveling_guide, ini\leveling tracker.ini, Settings, font-offset, 0
IniRead, gem_notes, ini\leveling tracker.ini, Gem notes,, %A_Space%
IniRead, enable_omnikey_pob, ini\leveling tracker.ini, Settings, enable pob-screencap, 0

IniRead, leveling_guide_time, ini\leveling tracker.ini, current run, time, 0
IniRead, leveling_guide_name, ini\leveling tracker.ini, current run, name, %A_Space%
leveling_guide_act := 1
Loop 11
{
	If (A_Index = 11)
	{
		leveling_guide_act := 11
		Break
	}
	IniRead, pAct, ini\leveling tracker.ini, current run, act %A_Index%, %A_Space%
	leveling_guide_act := A_Index
	If !pAct
		Break
	leveling_guide_time_total += pAct
}
If !IsNumber(leveling_guide_time_total)
	leveling_guide_time_total := 0

IniRead, leveling_guide_skilltree_last, ini\leveling tracker.ini, Settings, last skilltree-image, % A_Space
If (leveling_guide_skilltree_last != "") && !FileExist(leveling_guide_skilltree_last)
	leveling_guide_skilltree_last := ""
If (leveling_guide_skilltree_last != "")
	LLK_LevelGuideSkillTree(2)
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
LLK_FontSize(fSize_leveling_guide, font_height_leveling_guide, font_width_leveling_guide)
IniRead, leveling_guide_fontcolor, ini\leveling tracker.ini, Settings, font-color, White
IniRead, leveling_guide_trans, ini\leveling tracker.ini, Settings, transparency, 250
IniRead, leveling_guide_panel_offset, ini\leveling tracker.ini, Settings, button-offset, 1
IniRead, leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position, bottom
leveling_guide_panel_dimensions := poe_width*0.03*leveling_guide_panel_offset
IniRead, leveling_guide_panel_xpos, ini\leveling tracker.ini, UI, button xcoord, % A_Space
If !leveling_guide_panel_xpos
	leveling_guide_panel_xpos := poe_width/2 - (leveling_guide_panel_dimensions + 2)/2
IniRead, leveling_guide_panel_ypos, ini\leveling tracker.ini, UI, button ycoord, % A_Space
If !leveling_guide_panel_ypos
	leveling_guide_panel_ypos := poe_height - (leveling_guide_panel_dimensions + 2)
IniRead, gear_tracker_char, ini\leveling tracker.ini, Settings, character, % A_Space
IniRead, gear_tracker_indicator_xpos, ini\leveling tracker.ini, UI, indicator xcoord, % 0.3*poe_width
IniRead, gear_tracker_indicator_ypos, ini\leveling tracker.ini, UI, indicator ycoord, % 0.91*poe_height
If (poe_log_file != 0)
{
	poe_log_content_short := SubStr(poe_log_content, -5000)
	Loop, Parse, poe_log_content_short, `n, `r
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
	If (settings_enable_levelingtracker = 1)
	{
		;FileRead, poe_log_content, % poe_log_file
		gear_tracker_characters := []
		parsed_characters := ","
		Loop
		{
			poe_log_content_short := SubStr(poe_log_content, -0.05*A_Index*StrLen(poe_log_content)) ;parse only the last 5% of the log-file (extend on every loop if nothing found)
			
			If (A_Index = 10) && (gear_tracker_characters.Count() = 0) ;abort if no character found within the second half of the log-file
			{
				gear_tracker_characters["lvl 2 required"] := 0
				break
			}
			
			If !InStr(poe_log_content_short, "is now level ") ;skip current chunk if no character-info is found
				continue
			
			Loop, Parse, poe_log_content_short, `n, `r ;parse current chunk for characters
			{
				If (A_LoopField = "")
					continue
				If InStr(A_Loopfield, "is now level ") && InStr(A_Loopfield, "/") ;line contains character
				{
					parsed_level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level "))
					parsed_level := StrReplace(parsed_level, "is now level ")
					parsed_character := SubStr(A_Loopfield, InStr(A_Loopfield, " : ") + 3, InStr(A_Loopfield, ")"))
					parsed_character := SubStr(parsed_character, 1, InStr(parsed_character, "(") - 2)
					parsed_characters .= !InStr(parsed_characters, "," parsed_character ",") ? parsed_character "," : "" ;list found characters
					If (LLK_InStrCount(parsed_characters, ",") > 6) ;only keep the 5 most recent characters in the list
						parsed_characters := SubStr(parsed_characters, InStr(parsed_characters, ",",,, 2))
				}
			}
			
			If (LLK_InStrCount(parsed_characters, ",") > 0) ;if list contains at least one character, parse chunk again for char-level
			{
				Loop, Parse, poe_log_content_short, `n, `r
				{
					If (A_LoopField = "")
						continue
					If InStr(A_Loopfield, "is now level ") && InStr(A_Loopfield, "/")
					{
						parsed_level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level "))
						parsed_level := StrReplace(parsed_level, "is now level ")
						parsed_character := SubStr(A_Loopfield, InStr(A_Loopfield, " : ") + 3, InStr(A_Loopfield, ")"))
						parsed_character := SubStr(parsed_character, 1, InStr(parsed_character, "(") - 2)
						If InStr(parsed_characters, "," parsed_character ",")
							gear_tracker_characters[parsed_character] := parsed_level
					}
				}
			}
			If (gear_tracker_characters.Count() > 0)
				break
		}
		
		;poe_log_content := ""
		poe_log_content_short := ""
	}
	GoSub, Log_loop
}
Return

Leveling_guide:
If (A_GuiControl = "pob_screencap")
{
	If (click = 1)
		MouseGetPos, pob_crop_x1, pob_crop_y1
	Else MouseGetPos, pob_crop_x2, pob_crop_y2
	
	Loop, Parse, % "pob_crop_x1,pob_crop_x2,pob_crop_y1,pob_crop_y2", `,
	{
		If !IsNumber(%A_Loopfield%)
			Return
	}
	
	If (pob_crop_x1 < pob_crop_x2) && (pob_crop_y1 < pob_crop_y2)
	{
		Loop 4
		{
			loop_crop := A_Index - 1
			pob_crop_x1_copy := pob_crop_x1 - loop_crop, pob_crop_y1_copy := pob_crop_y1 - loop_crop, pob_crop_x2_copy := pob_crop_x2 + loop_crop, pob_crop_y2_copy := pob_crop_y2 + loop_crop
			Gui, pob_crop%A_Index%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_pob_crop%A_Index%
			Gui, pob_crop%A_Index%: Margin, 0, 0
			Gui, pob_crop%A_Index%: Color, Black
			WinSet, Transparent, 255
			WinSet, TransColor, Black
			Gui, pob_crop%A_Index%: Show, % "NA x"pob_crop_x1_copy " y"pob_crop_y1_copy " w"pob_crop_x2_copy - pob_crop_x1_copy " h"pob_crop_y2_copy - pob_crop_y1_copy
		}
		
		Gdip_DisposeImage(pScreencap_crop)
		pScreencap_crop := Gdip_BitmapFromScreen(pob_crop_x1 + 1 "|" pob_crop_y1 + 1 "|" pob_crop_x2 - pob_crop_x1 - 1 "|" pob_crop_y2 - pob_crop_y1 - 1)
	}
	Else
	{
		Gdip_DisposeImage(pScreencap_crop)
		Loop 4
		{
			Gui, pob_crop%A_Index%: Destroy
			hwnd_pob_crop%A_Index% := ""
		}
	}
	Return
}
If (A_GuiControl = "leveling_guide_enable_timer") ;toggling the timer checkbox
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % %A_GuiControl%, ini\leveling tracker.ini, Settings, enable timer
	If !%A_GuiControl%
	{
		IniWrite, % leveling_guide_time, ini\leveling tracker.ini, current run, time
		leveling_guide_fresh_login := 1
	}
	If hwnd_leveling_guide2
		GoSub, Leveling_guide_progress
	Return
}
If (A_GuiControl = "leveling_guide_screencap_caption")
{
	Gui, screencap_setup: Submit, NoHide
	Loop, Parse, leveling_guide_screencap_caption
	{
		If InStr("\/:*?""<>|", A_Loopfield) && !InStr(leveling_guide_screencap_caption, "lab: ") && !InStr(leveling_guide_screencap_caption, "overwrite: ")
		{
			WinGetPos, x_screencap, y_screencap,, h_screencap, ahk_id %hwnd_screencap_caption%
			LLK_ToolTip("caption cannot contain \/:*?""<>|", 2, x_screencap, y_screencap - h_screencap)
			GuiControl, text, leveling_guide_screencap_caption, % (A_Index = StrLen(leveling_guide_screencap_caption)) ? SubStr(leveling_guide_screencap_caption, 1, -1) : (leveling_guide_valid_skilltree_files < 9) ? "[0" leveling_guide_valid_skilltree_files + 1 "] " : "[" leveling_guide_valid_skilltree_files + 1 "] "
			leveling_guide_screencap_caption := ""
			SendInput, {END}
			Return
		}
	}
	
	If (SubStr(leveling_guide_screencap_caption, 1, 5) = "lab: ")
	{
		
		Switch SubStr(leveling_guide_screencap_caption, 6)
		{
			Case "normal":
				leveling_guide_screencap_caption := "[lab1]"
			Case "cruel":
				leveling_guide_screencap_caption := "[lab2]"
			Case "merciless":
				leveling_guide_screencap_caption := "[lab3]"
			Case "uber":
				leveling_guide_screencap_caption := "[lab4]"
			Case "endgame respec":
				leveling_guide_screencap_caption := "[lab5]"
		}
		
	}
	If (click = 2) && (SubStr(leveling_guide_screencap_caption, 1, 4) = "[lab")
	{
		FileDelete, % "img\GUI\skill-tree\" leveling_guide_screencap_caption ".*"
		LLK_LevelGuideSkillTree(1)
		GuiControl, text, leveling_guide_screencap_caption, % (leveling_guide_valid_skilltree_files < 9) ? "[0" leveling_guide_valid_skilltree_files + 1 "] " : "[" leveling_guide_valid_skilltree_files + 1 "] "
		WinActivate, ahk_id %hwnd_screencap_setup%
		WinWaitActive, ahk_id %hwnd_screencap_setup%
		Sleep, 100
		SendInput, {END}
		Return
	}
	If (click = 2) && InStr(leveling_guide_screencap_caption, "overwrite: ")
	{
		FileDelete, % "img\GUI\skill-tree\" StrReplace(leveling_guide_screencap_caption, "overwrite: ") ".*"
		LLK_LevelGuideSkillTree(1)
		leveling_guide_original_caption := StrReplace(leveling_guide_original_caption, "|" leveling_guide_screencap_caption "|", "|")
		GuiControl,, leveling_guide_screencap_caption, % leveling_guide_original_caption
		GuiControl, text, leveling_guide_screencap_caption, % (leveling_guide_valid_skilltree_files < 9) ? "[0" leveling_guide_valid_skilltree_files + 1 "] " : "[" leveling_guide_valid_skilltree_files + 1 "] "
		WinActivate, ahk_id %hwnd_screencap_setup%
		WinWaitActive, ahk_id %hwnd_screencap_setup%
		Sleep, 100
		SendInput, {END}
		Return
	}
	If (SubStr(leveling_guide_screencap_caption, 1, 11) = "overwrite: ") || (SubStr(leveling_guide_screencap_caption, 1, 4) = "[lab")
	{
		leveling_guide_screencap_caption := StrReplace(leveling_guide_screencap_caption, "overwrite: ")
		Gui, screencap_setup: Destroy
		hwnd_screencap_setup := ""
		Loop 4
			Gui, pob_crop%A_Index%: Destroy
		hwnd_screencap_caption := ""
	}
	Return
}
If (A_GuiControl = "enable_omnikey_pob")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_omnikey_pob, ini\leveling tracker.ini, Settings, enable pob-screencap
	Return
}
If (A_GuiControl = "leveling_guide_screencap_ok")
{
	Gui, screencap_setup: Submit, NoHide
	screencap_failed := 0
	While InStr(leveling_guide_screencap_caption, "  ")
		leveling_guide_screencap_caption := StrReplace(leveling_guide_screencap_caption, "  ", " ")
	While (SubStr(leveling_guide_screencap_caption, 0) = " ")
		leveling_guide_screencap_caption := SubStr(leveling_guide_screencap_caption, 1, -1)
	If (leveling_guide_screencap_caption = "")
		screencap_failed := 1

	Loop 9
	{
		If (InStr(leveling_guide_screencap_caption, "act" A_Index) || InStr(leveling_guide_screencap_caption, "act " A_Index)) && !InStr(leveling_guide_screencap_caption, "act 10") && !InStr(leveling_guide_screencap_caption, "act10") 
			leveling_guide_screencap_caption := StrReplace(leveling_guide_screencap_caption, "act" A_Index, "act0"A_Index), leveling_guide_screencap_caption := StrReplace(leveling_guide_screencap_caption, "act " A_Index, "act 0"A_Index)
	}
	
	If (screencap_failed != 0)
	{
		WinGetPos, x_screencap, y_screencap,, h_screencap, ahk_id %hwnd_screencap_caption%
		LLK_ToolTip("caption cannot be blank", 2, x_screencap, y_screencap - h_screencap)
		GuiControl, text, leveling_guide_screencap_caption, % (leveling_guide_valid_skilltree_files < 9) ? "[0" leveling_guide_valid_skilltree_files + 1 "] " : "[" leveling_guide_valid_skilltree_files + 1 "] "
		leveling_guide_screencap_caption := ""
		SendInput, {END}
		Return
	}
	
	Gui, screencap_setup: Destroy
	hwnd_screencap_setup := ""
	Loop 4
		Gui, pob_crop%A_Index%: Destroy
	hwnd_screencap_caption := ""
	Return
}
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
		text2_backup := text2
		text2 := ""
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
			text2 := text2_backup
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

If (A_GuiControl = "leveling_guide_skilltree_folder")
{
	KeyWait, LButton
	Run, explore img\GUI\skill-tree\
	Return
}

If (A_GuiControl = "settings_enable_levelingtracker") ;checking the enable-checkbox in the settings menu
{
	Gui, settings_menu: Submit, NoHide
	GoSub, GUI
	IniWrite, % settings_enable_levelingtracker, ini\config.ini, Features, enable leveling guide
	If !settings_enable_levelingtracker
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
	build_gems_none := ""
	FileRead, json_areas, data\leveling tracker\areas.json
	FileRead, json_gems, data\leveling tracker\gems.json
	FileRead, json_quests, data\leveling tracker\quests.json
	json_import := (SubStr(clipboard, 1, 2) = "[{") && InStr(clipboard, "enter") ? clipboard : ""
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
	gem_notes := ""

	Loop, % parsed.Length() ;parse all acts
	{
		loop := A_Index
		Loop, % parsed[loop].steps.Length() ;parse steps in nth act
		{
			step := parsed[loop].steps[A_Index]
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
						Else If InStr(parts[A_Index], "take") && InStr(step_text, "kill") ;omit quest-items related to killing bosses
							text := ""
						Else text := InStr(parts[A_Index], " ➞ ") ? StrReplace(parts[A_Index], " ➞", ", enter") : StrReplace(parts[A_Index], "➞", "enter")
						step_text .= text
					}
					Else
					{
						type := parts[A_Index].type
						value := parts[A_Index].value
						areaID := parts[A_Index].areaId
						target_areaID := parts[A_Index].dstAreaId
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
						Switch type ;thing I never knew existed but really wanted
						{
							Case "enter":
								step_text .= "areaID" areaID
							Case "kill":
								step_text .= InStr(value, ",") ? SubStr(parts[A_Index].value, 1, InStr(parts[A_Index].value, ",") - 1) : StrReplace(value, "alira darktongue", "alira") ;shorten boss names
							Case "quest":
								npc := quests[questID]["reward_offers"][questID]["quest_npc"]
								Switch npc
								{
									Case "lady dialla":
										npc := "dialla"
									Case "captain fairgraves":
										npc := "fairgraves"
									Case "commander kirac":
										npc := "kirac"
								}
								npc := InStr(npc, " ") ? SubStr(npc, 1, InStr(npc, " ") - 1) : npc
								step_text := npc ? StrReplace(step_text, "hand in ", npc ": ") "<" quests[questID].name ">" : step_text "<" quests[questID].name ">"
							Case "quest_text":
								value := StrReplace(value, "glyph", " glyph"), value := StrReplace(value, "platinum bust", " platinum bust"), value := StrReplace(value, "golden page", " golden page"), value := StrReplace(value, "kitava's torment", " kitava's torment"), value := StrReplace(value, "firefly", " firefly")
								step_text .= !InStr(step_text, "kill") ? value : "" ;omit quest-items related to killing bosses
							Case "waypoint_get":
								step_text .= "waypoint"
							Case "waypoint_use":
								step_text .= "waypoint-travel to areaID" target_areaID
							Case "waypoint":
								step_text .= InStr(step_text, "broken ") ? "waypoint" : "the waypoint"
							Case "logout":
								step_text .= "relog, enter areaID" areaID
							Case "portal_use":
								step_text .= "portal to areaID" target_areaID
							Case "portal_set":
								step_text .= "portal"
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
							Case "reward_vendor":
								step_text .= "buy item: " step.parts[A_Index].item
							Case "reward_quest":
								step_text .= "take reward: " step.parts[A_Index].item
							Default:
								If enable_startup_beep ;startup-beep = pseudo dev-mode
									MsgBox, unknown type: "%type%"
								Else
								{
									LLK_ToolTip("incompatible guide-data,`nupdate required")
									json_areas := ""
									json_gems := ""
									json_quests := ""
									Return
								}
						}
					}
				}
			}
			If (step.type = "gem_step")
			{
				rewardType := step.rewardType
				gemID := step.requiredGem.id
				If !gems[gemID].name
					continue
				step_text .= (rewardType = "vendor") ? "buy gem: " : "take reward: "
				step_text .= gems[gemID].name
				If (step.requiredGem.note != "")
					gem_notes .= gems[gemID].name "=" step.requiredGem.note "`n"
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
					Default:
						build_gems_none .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
				}
			}
			If (SubStr(step_text, 0) = ",")
				step_text := SubStr(step_text, 1, -1)
			guide_text .= StrReplace(step_text, ",,", ",") "`n"
		}
	}
	
	While (SubStr(gem_notes, 0) = "`n")
		gem_notes := SubStr(gem_notes, 1, -1)
	IniDelete, ini\leveling tracker.ini, Gem notes
	If (gem_notes != "")
	{
		StringLower, gem_notes, gem_notes
		gem_notes := StrReplace(gem_notes, "&", "&&")
		IniWrite, % gem_notes, ini\leveling tracker.ini, Gem notes
	}
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int build_gems_none ;create single gem-string for gear tracker feature
	
	IniDelete, ini\leveling tracker.ini, Gems
	IniDelete, ini\search-strings.ini, 00-exile leveling gems
	IniDelete, ini\search-strings.ini, searches, hideout lilly
	searchstrings_enable_hideout_lilly := 0
	
	If (build_gems_all != "")
	{
		Sort, build_gems_all, D`, P2 N
		Sort, build_gems_skill_str, D`, P2 N
		Sort, build_gems_supp_str, D`, P2 N
		Sort, build_gems_skill_dex, D`, P2 N
		Sort, build_gems_supp_dex, D`, P2 N
		Sort, build_gems_skill_int, D`, P2 N
		Sort, build_gems_supp_int, D`, P2 N
		Sort, build_gems_none, D`, P2 N
		
		build_gems_all := StrReplace(build_gems_all, ")", ") ")	
		build_gems_all := StrReplace(build_gems_all, " support", "")	
		IniWrite, % SubStr(StrReplace(build_gems_all, ",", "`n"), 1, -1), ini\leveling tracker.ini, Gems ;save gems for gear tracker feature
	}
	
	parse := "skill_str,supp_str,skill_dex,supp_dex,skill_int,supp_int,none"
	
	search_string_skill_str := ""
	search_string_supp_str := ""
	search_string_skill_dex := ""
	search_string_supp_dex := ""
	search_string_skill_int := ""
	search_string_supp_int := ""
	search_string_none := ""
	search_string_all := ""
	
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
			IniRead, gem_regex, data\leveling tracker\gems.ini, % parse_gem, regex, % A_Space
			If !gem_regex
				gem_regex := parse_gem
			gem_regex := StrReplace(gem_regex, " ", "\s")
			
			If (StrLen(parse_string gem_regex) <= 47)
				parse_string .= gem_regex "|"
			Else
			{
				search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ");"
				parse_string := gem_regex "|"
			}
		}
		search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ")"
	}
	
	Loop, Parse, parse, `,, `,
	{
		If (search_string_%A_Loopfield% != "")
			search_string_all .= search_string_%A_Loopfield% ";"
	}
	
	If (search_string_all != "")
	{
		search_string_all := SubStr(search_string_all, 1, -1)
		IniWrite, 1, ini\search-strings.ini, searches, hideout lilly
		IniWrite, % """" StrReplace(search_string_all, ";", " " ";;;" " ") """", ini\search-strings.ini, hideout lilly, 00-exile leveling gems
	}
	GoSub, Init_searchstrings
	
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
	If (click = 1)
	{
		If (StrLen(StrReplace(Clipboard, "#")) != 6)
		{
			LLK_ToolTip("invalid RGB-code in clipboard", 1.5)
			Return
		}
		leveling_guide_fontcolor := StrReplace(Clipboard, "#")
		GuiControl, settings_menu: +c%leveling_guide_fontcolor%, % A_GuiControl
	}
	Else
	{
		If (leveling_guide_fontcolor = "White")
			Return
		GuiControl, settings_menu: +cWhite, % A_GuiControl
		leveling_guide_fontcolor := "White"
	}
	GuiControl, settings_menu: movedraw, % A_GuiControl
	IniWrite, % leveling_guide_fontcolor, ini\leveling tracker.ini, Settings, font-color
}
If InStr(A_GuiControl, "leveling_guide_position_")
{
	leveling_guide_position := StrReplace(A_GuiControl, "leveling_guide_position_")
	IniWrite, % leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position
}
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
LLK_FontSize(fSize_leveling_guide, font_height_leveling_guide, font_width_leveling_guide)
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
		SendInput, ^{f}
		Sleep, 100
		SendInput, ^{v}
		Sleep, 100
		SendInput, {Enter}
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
		SendInput, ^{f}
		Sleep, 100
		SendInput, ^{v}
		Sleep, 100
		SendInput, {Enter}
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
	;WinSet, Transparent, %leveling_guide_trans%
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
	json_areas := ""
}
If (A_Gui = "leveling_guide_panel" && hwnd_leveling_guide2 = "") || (A_GuiControl = "leveling_guide_reset") || InStr(A_GuiControl, "jump")
{
	If InStr(A_GuiControl, "jump")
	{
		If (click = 2)
		{
			If leveling_guide_enable_timer && (current_location = "1_1_1") && !guide_progress
			{
				FormatTime, leveling_guide_name, % A_Now, yyyy-MM-dd`, HH:mm
				IniWrite, 0, ini\leveling tracker.ini, current run, time
				IniWrite, % leveling_guide_name, ini\leveling tracker.ini, current run, name
				Loop 10
					IniWrite, % "", ini\leveling tracker.ini, current run, act %A_Index%
				leveling_guide_act := 1
				leveling_guide_time_total := 0
				leveling_guide_time := 0
				leveling_guide_fresh_login := 1
				SetTimer, Log_loop, 1000
				LLK_LevelGuideTimerPause()
				LLK_LevelGuideTimer(0, 0)
			}
			Else If leveling_guide_enable_timer
				LLK_LevelGuideTimerPause()
			WinActivate, ahk_group poe_window
			Return
		}
		
		If (A_GuiControl = "leveling_guide_jump_forward")
		{
			If InStr(guide_panel2_text, "an end to hunger")
				Return
			guide_progress .= (guide_progress = "") ? guide_panel2_text : "`n" guide_panel2_text
		}
		Else
		{
			If (click = 2)
				Return
			guide_text := guide_text_original
			guide_progress := SubStr(guide_progress, 1, - 1 - StrLen(guide_panel1_text)) ;StrReplace(guide_progress, "`n" guide_panel1_text)
		}
	}
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	;IniRead, guide_text, ini\leveling guide.ini, Steps,, % A_Space
	If (guide_progress = "") && (A_gui != "leveling_guide3")
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
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to"))
	&& !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
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
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to"))
	&& !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
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
text2 := InStr(guide_panel2_text, "`n") ? "- " StrReplace(guide_panel2_text, "`n", "`n- ") : guide_panel2_text ;text2 = variable used to display the guide-text in the panel (can be altered without messing up saved progress)

If InStr(text2, "areaID")
	text2 := LLK_ReplaceAreaID(text2)
stash_search_string_leveling := ""
stash_search_string_leveling_gems := ""
stash_search_string_leveling_items := ""

str_skills := "", str_supports := "", dex_skills := "", dex_supports := "", int_skills := "", int_supports := "", none_skills := "", none_supports := ""

If InStr(text2, "buy gem: ") ;check if there are steps for buying gems, then group them together
{
	stash_search_string_leveling_gems := "^("
	Loop, Parse, guide_panel2_text, `n, `n ;parse panel-text line by line
	{
		If InStr(A_Loopfield, "buy gem: ") ;if line is a gem-step, read the appropriate regex string for that gem
		{
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "buy gem: ") + 9)
			IniRead, parse, data\leveling tracker\gems.ini, % parse, regex, % A_Space
			If (parse = "")
				parse := StrReplace(SubStr(A_Loopfield, InStr(A_Loopfield, "buy gem: ") + 9), " support")
			parse := StrReplace(parse, " ", "\s")
			If !InStr(guide_panel2_text, "a fixture of fate") ;buying gems from normal vendors does not require sorting
			{
				If (StrLen(SubStr(stash_search_string_leveling_gems, InStr(stash_search_string_leveling_gems, "`n",,, LLK_InStrCount(stash_search_string_leveling_gems, "`n")) + 1) parse) <= 49)
					stash_search_string_leveling_gems .= parse "|"
				Else stash_search_string_leveling_gems := SubStr(stash_search_string_leveling_gems, 1, -1) ")`n^(" parse "|"
			}
			Else ;buying gems from Siosa requires the gems to be sorted (for the specific tabs)
			{
				IniRead, primary_attribute, data\leveling tracker\gems.ini, % SubStr(A_Loopfield, InStr(A_Loopfield, "buy gem: ") + 9), attribute, none ;read a gem's primary attribute
				If InStr(A_LoopField, " support") || InStr(A_LoopField, "arcanist brand")
				{
					If (%primary_attribute%_supports = "")
						%primary_attribute%_supports := "^("
					If (StrLen(SubStr(%primary_attribute%_supports, InStr(%primary_attribute%_supports, "`n",,, LLK_InStrCount(%primary_attribute%_supports, "`n")) + 1) parse) <= 49) ;(StrLen(%primary_attribute%_supports parse) <= 49)
						%primary_attribute%_supports .= parse "|"
					Else %primary_attribute%_supports := SubStr(%primary_attribute%_supports, 1, -1) ")`n^(" parse "|" ;if the string gets too long, close the current one and start a new one (scrolling string-search)
				}
				Else
				{
					If (%primary_attribute%_skills = "")
						%primary_attribute%_skills := "^("
					If (StrLen(SubStr(%primary_attribute%_skills, InStr(%primary_attribute%_skills, "`n",,, LLK_InStrCount(%primary_attribute%_skills, "`n")) + 1) parse) <= 49) ;(StrLen(%primary_attribute%_skills parse) <= 49)
						%primary_attribute%_skills .= parse "|"
					Else %primary_attribute%_skills := SubStr(%primary_attribute%_skills, 1, -1) ")`n^(" parse "|"
				}
			}
		}
	}
	
	If InStr(guide_panel2_text, "a fixture of fate") ;combine the tab-specific strings into a single one
	{
		Loop, Parse, % "str,dex,int,none", `,, `,
		{
			If (SubStr(%A_LoopField%_skills, 0) = "|")
				%A_LoopField%_skills := SubStr(%A_LoopField%_skills, 1, -1) ")`n"
			If (SubStr(%A_LoopField%_supports, 0) = "|")
				%A_LoopField%_supports := SubStr(%A_LoopField%_supports, 1, -1) ")`n"
		}
		
		stash_search_string_leveling_gems := str_skills str_supports dex_skills dex_supports int_skills int_supports none_skills none_supports
		If (SubStr(stash_search_string_leveling_gems, 0) = "`n")
			stash_search_string_leveling_gems := SubStr(stash_search_string_leveling_gems, 1, -1)
	}
	
	str_skills := "", str_supports := "", dex_skills := "", dex_supports := "", int_skills := "", int_supports := "", none_skills := "", none_supports := ""
	
	If (SubStr(stash_search_string_leveling_gems, 0) = "|")
		stash_search_string_leveling_gems := SubStr(stash_search_string_leveling_gems, 1, -1) ")"
	
	Loop, Parse, text2, `n, `n ;merge gem-buy steps into a collective one
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "buy gem: ")
		{
			If !InStr(text2, "buy gems")
				text2 .= (text2 = "") ? "- buy gems (highlight: hold omni-key)" : "`n- buy gems (highlight: hold omni-key)"
			continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
	stash_search_string_leveling := stash_search_string_leveling_gems
}

If InStr(text2, "buy item: ") ;check if there are steps for buying items, then group them together
{
	stash_search_string_leveling_items := "("
	Loop, Parse, guide_panel2_text, `n, `n ;parse panel-text line by line
	{
		If InStr(A_Loopfield, "buy item: ") ;if line is an item-step, create a search-string
		{
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "buy item: ") + 10)
			parse := StrReplace(parse, " ", ".")
			If (StrLen(SubStr(stash_search_string_leveling_items, InStr(stash_search_string_leveling_items, "`n",,, LLK_InStrCount(stash_search_string_leveling_items, "`n")) + 1) parse) <= 49) ;(StrLen(stash_search_string_leveling_items parse) <= 49)
				stash_search_string_leveling_items .= parse "|"
			Else stash_search_string_leveling_items := SubStr(stash_search_string_leveling_items, 1, -1) ")`n(" parse "|" ;if the string gets too long, close the current one and start a new one (scrolling string-search)
		}
	}
	If (SubStr(stash_search_string_leveling_items, 0) = "|")
		stash_search_string_leveling_items := SubStr(stash_search_string_leveling_items, 1, -1) ")"
	
	Loop, Parse, text2, `n, `n ;merge item-buy steps into a collective one
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "buy item: ")
		{
			If !InStr(text2, "buy items")
				text2 .= (text2 = "") ? "- buy items (highlight: hold omni-key)" : "`n- buy items (highlight: hold omni-key)"
			continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
	
	stash_search_string_leveling := stash_search_string_leveling_items "`n" stash_search_string_leveling
}

If (SubStr(stash_search_string_leveling, 0) = "`n")
	stash_search_string_leveling := SubStr(stash_search_string_leveling, 1, -1)

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

;moved img-tagging here (rather than during importing) in order to avoid conflicts with progress saving/loading
Loop, Parse, leveling_guide_landmarks, `,, % A_Space
{
	If !InStr(text2, A_LoopField)
		continue
	Else text2 := StrReplace(text2, A_LoopField, A_LoopField " (hold tab: img)")
}

If (hwnd_leveling_guide2 = "")
{
	Gui, leveling_guide1: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide1
	Gui, leveling_guide1: Margin, font_width, 0
	Gui, leveling_guide1: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, leveling_guide1: Font, % "cLime s"fSize_leveling_guide, Fontin SmallCaps
	Gui, leveling_guide1: Add, Text, % "BackgroundTrans HWNDhwnd_levelingguidetext1", % (guide_panel1_text = "") ? "n/a" : text1

	Gui, leveling_guide2: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide2
	Gui, leveling_guide2: Margin, % font_width_leveling_guide, 0
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
	SetTextAndResize(hwnd_levelingguidetext2, text2, "s" fSize_leveling_guide, "Fontin SmallCaps", 2)
	;SetTextAndResize(hwnd_levelingguidetext1, text1, "s" fSize_leveling_guide, "Fontin SmallCaps")
	;Gui, leveling_guide1: Show, NA x10000 y10000 AutoSize
	Gui, leveling_guide2: Show, NA x10000 y10000 AutoSize
}

;WinGetPos,,, width, height, ahk_id %hwnd_leveling_guide1%
WinGetPos,,, width2, height, ahk_id %hwnd_leveling_guide2%
width2 := (width2 < 20 * font_width_leveling_guide) ? 20 * font_width_leveling_guide : width2
While Mod(width2, 2)
	width2 += 1
Gui, leveling_guide2: Show, % "NA x10000 y10000 w"width2-2
;width := (width > width2) ? width : width2
;height := (height > height2) ? height : height2

Gui, leveling_guide3: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide3
Gui, leveling_guide3: Margin, 0, 0
If leveling_guide_enable_timer && leveling_guide_fresh_login
	Gui, leveling_guide3: Color, Gray
Else Gui, leveling_guide3: Color, Black
WinSet, Transparent, %leveling_guide_trans%
Gui, leveling_guide3: Font, % "c" leveling_guide_fontcolor " s"fSize_leveling_guide*(2/3) " bold", Fontin SmallCaps
If !leveling_guide_enable_timer
{
	Gui, leveling_guide3: Add, Text, % "BackgroundTrans Section Border vleveling_guide_jump_back Center gLeveling_guide_progress w"width2/2 - 1, % "<<"
	Gui, leveling_guide3: Add, Text, % "BackgroundTrans ys Border vleveling_guide_jump_forward Center gLeveling_guide_progress w"width2/2 - 1, % ">>"
}
Else
{
	Gui, leveling_guide3: Add, Text, % "BackgroundTrans Section Border vleveling_guide_jump_back Center gLeveling_guide_progress w"width2/2 - 1, % ""
	Gui, leveling_guide3: Add, Text, % "BackgroundTrans ys Border vleveling_guide_jump_forward Center gLeveling_guide_progress w"width2/2 - 1, % ""
	If (leveling_guide_act = 11) ;if campaign is done
	{
		LLK_LevelGuideTimer(leveling_guide_time, leveling_guide_time_total)
		Gui, leveling_guide3: Color, Green
		WinSet, Redraw,, ahk_id %hwnd_leveling_guide3%
	}
	Else LLK_LevelGuideTimer(leveling_guide_time, leveling_guide_time_total + leveling_guide_time)
}
Gui, leveling_guide3: Show, NA x10000 y10000
WinGetPos,,, width3, height3, ahk_id %hwnd_leveling_guide3%

Switch leveling_guide_position
{
	Case "top":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + height3 - 1 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet ;" w"width2 - 2
	Case "bottom":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet + (47/48)*poe_height - height " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height - height3 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height3 + 1 ;" w"width2 - 2
}
;LLK_Overlay("leveling_guide1", "show")
LLK_Overlay("leveling_guide2", "show")
LLK_Overlay("leveling_guide3", "show")
Return

LLK_GearTrackerGUI(mode:=0)
{
	global
	guilist .= InStr(guilist, "gear_tracker_indicator|") ? "" : "gear_tracker_indicator|"
	If (mode = 0)
		Gui, gear_tracker_indicator: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gear_tracker_indicator
	Else Gui, gear_tracker_indicator: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_gear_tracker_indicator
	Gui, gear_tracker_indicator: Margin, 0, 0
	Gui, gear_tracker_indicator: Color, Black
	;If (mode = 0)
		;WinSet, Transparent, %leveling_guide_trans%
	If (mode != 0)
		WinSet, TransColor, Black
	Gui, gear_tracker_indicator: Font, % "cLime s"fSize_leveling_guide, Fontin SmallCaps
	Gui, gear_tracker_indicator: Add, Text, % "BackgroundTrans Center vgear_tracker_upgrades gLeveling_guide_gear", % "    "
	Gui, gear_tracker_indicator: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_gear_tracker_indicator%
	gear_tracker_indicator_xpos_target := (gear_tracker_indicator_xpos + width + 2 > poe_width) ? poe_width - width - 1 : gear_tracker_indicator_xpos ;correct coordinates if panel would end up out of client-bounds
	gear_tracker_indicator_ypos_target := (gear_tracker_indicator_ypos + height + 2 > poe_height) ? poe_height - height - 1 : gear_tracker_indicator_ypos ;correct coordinates if panel would end up out of client-bounds
	If (gear_tracker_indicator_xpos_target + width + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (gear_tracker_indicator_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		gear_tracker_indicator_ypos_target := pixel_gamescreen_y1 + 2
	Gui, gear_tracker_indicator: Show, % "NA x"xScreenOffset + gear_tracker_indicator_xpos_target " y"yScreenoffset + gear_tracker_indicator_ypos_target
	LLK_Overlay("gear_tracker_indicator", "show")
}

LLK_ReplaceAreaID(string)
{
	global areas
	Loop, Parse, string, % A_Space, `,
	{
		If !InStr(A_Loopfield, "areaid")
			continue
		areaID := StrReplace(A_Loopfield, "areaid")
		string := StrReplace(string, A_Loopfield, areas[areaID].name,, 1)
	}
	StringLower, string, string
	Return string
}

LLK_LevelGuideGemNote()
{
	global
	gem_note_text := ""
	Loop, Parse, gem_notes, `n
	{
		If (A_LoopField = "")
			continue
		If InStr(Clipboard, SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1))
			gem_note_text := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
	}
	If !gem_note_text
		Return 0
	Else
	{
		local mouseXpos_gem, mouseYpos_gem, gem_width, gem_height
		MouseGetPos, mouseXpos_gem, mouseYpos_gem
		Gui, gem_notes: New, -DPIScale +E0x20 -Caption +Border +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_gem_notes
		Gui, gem_notes: Margin, font_width/2, font_height/2
		Gui, gem_notes: Color, Black
		WinSet, Transparent, %trans%
		Gui, gem_notes: Font, % "cWhite s"fSize0, Fontin SmallCaps
		Gui, gem_notes: Add, Text, % "xs Section Center BackgroundTrans Border w"font_width*15, % gem_note_text
		Gui, gem_notes: Show, % "NA x10000 y10000"
		WinGetPos,,, gem_width, gem_height, ahk_id %hwnd_gem_notes%
		mouseXpos_gem := (mouseXpos_gem - gem_width*1.1 < xScreenOffSet) ? xScreenOffSet : mouseXpos_gem
		Gui, gem_notes: Show, % "NA x"mouseXpos_gem - gem_width*1.1 " y"mouseYpos_gem - gem_height*1.1
	}
	Return 1
}

LLK_LevelGuideImage()
{
	global text2, poe_height, leveling_guide_landmarks
	Loop, Parse, leveling_guide_landmarks, `,, % A_Space
	{
		If !InStr(text2, A_LoopField)
			continue
		Else
		{
			image := StrReplace(A_LoopField, " ", "_")
			break
		}
	}
	Gui, leveling_guide_img: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, leveling_guide_img: Margin, 0, 0
	Gui, leveling_guide_img: Color, Black
	WinSet, Transparent, 255
	If FileExist("img\GUI\leveling tracker\" image ".jpg")
	{
		Gui, leveling_guide_img: Add, Picture, % "h"poe_height//2 " w-1", img\GUI\leveling tracker\%image%.jpg
		Gui, leveling_guide_img: Show, NA AutoSize
	}
}

LLK_ScreencapPoB()
{
	global leveling_guide_valid_skilltree_files, leveling_guide_screencap_caption := "", leveling_guide_screencap_caption, leveling_guide_screencap_ok, xScreenOffSet, height_native, hwnd_screencap_setup, hwnd_screencap_caption
	, leveling_guide_original_caption, fSize0, leveling_guide_skilltree_cap_help, pob_screencap, hwnd_pob_crop1, pob_crop_x1 := "", pob_crop_x2 := "", pob_crop_y1 := "", pob_crop_y2 := "", pScreencap_crop, poe_width, poe_height
	Clipboard := ""
	SendInput, +#{s}
	WinWaitNotActive, ahk_exe Path of Building.exe,, 2
	Sleep, 500
	WinWaitActive, ahk_exe Path of Building.exe
	pScreencap := Gdip_CreateBitmapFromClipboard()
	If (pScreencap < 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		Gdip_GetImageDimensions(pScreencap, wScreencap, hScreencap)
		hbmScreencap := CreateDIBSection(wScreencap, hScreencap)
		hdcScreencap := CreateCompatibleDC()
		obmScreencap := SelectObject(hdcScreencap, hbmScreencap)
		gScreencap := Gdip_GraphicsFromHDC(hdcScreencap)
		Gdip_SetInterpolationMode(gScreencap, 0)
		Gdip_DrawImage(gScreencap, pScreencap, 0, 0, wScreencap, hScreencap, 0, 0, wScreencap, hScreencap, 1)
	}
	
	If (hScreencap <= height_native*0.95)
	{
		LLK_LevelGuideSkillTree(1)
		Gui, screencap_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_screencap_setup
		Gui, screencap_setup: Margin, 0, 0
		Gui, screencap_setup: Color, Black
		WinSet, Transparent, 255
		Gui, screencap_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
		Gui, screencap_setup: Add, ComboBox, % "Hidden x0 y0 HWNDmain_text", % StrReplace(leveling_guide_original_caption, "|",,, 1)
		WinGetPos,,,, heightt, ahk_id %main_text%
		Gui, screencap_setup: Add, Picture, % "Section xp yp BackgroundTrans vpob_screencap gLeveling_guide", HBitmap:*%hbmScreencap%
		leveling_guide_original_caption := "|lab: normal|lab: cruel|lab: merciless|lab: uber|lab: endgame respec|"
		Loop, Files, img\GUI\skill-tree\*
		{
			If !InStr("jpg,bmp,png", A_LoopFileExt) || (A_LoopFileExt = "") || (SubStr(A_LoopFileName, 1, 4) = "[lab")
				continue
			leveling_guide_original_caption .= "overwrite: " StrReplace(A_LoopFileName, "." A_LoopFileExt) "|"
		}
		;If (SubStr(caption, 0) = "|")
		;	leveling_guide_original_caption := SubStr(leveling_guide_original_caption, 1, -1)
		;Gui, screencap_setup: Add, Text, xs wp BackgroundTrans, % ""
		Gui, screencap_setup: Add, ComboBox, % "Section xs w"wScreencap - heightt " BackgroundTrans cBlack vleveling_guide_screencap_caption gLeveling_guide HWNDhwnd_screencap_caption", % StrReplace(leveling_guide_original_caption, "|",,, 1)
		Gui, screencap_setup: Add, Picture, % "ys BackgroundTrans hp w-1 gSettings_menu_help vleveling_guide_skilltree_cap_help", img\GUI\help.png
		
		GuiControl, text, leveling_guide_screencap_caption, % (leveling_guide_valid_skilltree_files < 9) ? "[0" leveling_guide_valid_skilltree_files + 1 "] " : "[" leveling_guide_valid_skilltree_files + 1 "] "
		Gui, screencap_setup: Add, Button, xs Hidden Default vleveling_guide_screencap_ok gLeveling_guide, OK
		Gui, screencap_setup: Show, x%xScreenOffSet% AutoSize
		WinWaitActive, ahk_id %hwnd_screencap_setup%
		Sleep, 100
		SendInput, {Right}
		Sleep, 1000
		
		While WinExist("ahk_id " hwnd_screencap_setup)
			Sleep, 100
		
		WinWaitNotActive, ahk_id %hwnd_screencap_setup%
		If (hwnd_pob_crop1 != "")
		{
			Gdip_DisposeImage(pScreencap)
			pScreencap := pScreencap_crop
		}
		If (leveling_guide_screencap_caption != "")
		{
			wScreencap := Gdip_GetImageWidth(pScreencap)
			If InStr(leveling_guide_screencap_caption, "[lab")
			{
				pScreencap_copy := Gdip_ResizeBitmap(pScreencap, Floor(poe_height/3), 10000, 1, 7)
				Gdip_DisposeImage(pScreencap)
				pScreencap := pScreencap_copy
			}
			Else If (wScreencap > poe_width*0.3)
			{
				pScreencap_copy := Gdip_ResizeBitmap(pScreencap, Floor(poe_width/3), 10000, 1, 7)
				Gdip_DisposeImage(pScreencap)
				pScreencap := pScreencap_copy
			}
			Gdip_SaveBitmapToFile(pScreencap, "img\GUI\skill-tree\" leveling_guide_screencap_caption ".jpg", 100)
		}
		Else LLK_ToolTip("screen-cap aborted", 2)
	}
	Else MsgBox, The screen-cap is too large (the resulting overlay wouldn't fit on screen).
	SelectObject(hdcScreencap, obmScreencap)
	DeleteObject(hbmScreencap)
	DeleteDC(hdcScreencap)
	Gdip_DeleteGraphics(gScreencap)
	Gdip_DisposeImage(pScreencap)
	Gdip_DisposeImage(pScreencap_copy)
	Gdip_DisposeImage(pScreencap_crop)
	DllCall("DeleteObject", "ptr", hbmScreencap)
	hbmScreencap := ""
	Gui, screencap_setup: Destroy
	hwnd_screencap_setup := ""
	Loop 4
	{
		Gui, pob_crop%A_Index%: Destroy
		hwnd_pob_crop%A_Index% := ""
	}
	hwnd_screencap_caption := ""
}

LLK_LevelGuideCSV()
{
	global
	local csv, time
	If !FileExist("campaign runs.csv")
		FileAppend, % """date, time"", act 1, act 2, act 3, act 4, act 5, act 6, act 7, act 8, act 9, act 10", campaign runs.csv
	FileRead, csv, campaign runs.csv
	If !leveling_guide_name
		FormatTime, leveling_guide_name, % A_Now, yyyy-MM-dd`, HH:mm
	
	time := FormatSeconds(leveling_guide_time) ".00"
	If InStr(csv, leveling_guide_name)
		FileAppend, % ",""" time """", campaign runs.csv
	Else FileAppend, % "`n""" leveling_guide_name """,""" time """", campaign runs.csv
}

LLK_LevelGuideTimer(seconds_act, seconds_run)
{
	global
	GuiControl, leveling_guide3:, leveling_guide_jump_back, % "<<   " FormatSeconds(seconds_act)
	GuiControl, leveling_guide3:, leveling_guide_jump_forward, % FormatSeconds(seconds_run) "   >>"
}

LLK_LevelGuideTimerPause()
{
	global
	If (leveling_guide_act = 11)
		Return
	leveling_guide_fresh_login := !leveling_guide_fresh_login
	If leveling_guide_fresh_login
		Gui, leveling_guide3: Color, Gray
	Else Gui, leveling_guide3: Color, Black
	WinSet, Redraw,, ahk_id %hwnd_leveling_guide3%
}

LLK_LevelGuideSkillTree(mode := 0)
{
	global leveling_guide_skilltree_active, leveling_guide_valid_skilltree_files, fSize0, skill_tree_prev, skill_tree_next, leveling_guide_skilltree_last, leveling_guide_lab_files, font_height, xScreenOffSet, yScreenOffSet, poe_width, poe_height, height_native
	, hwnd_leveling_guide_skilltree, hwnd_leveling_guide_labs, hwnd_leveling_guide_lab1, hwnd_leveling_guide_lab2, hwnd_leveling_guide_lab3, hwnd_leveling_guide_lab4, hwnd_leveling_guide_lab5, leveling_guide_skilltree_width, skilltree_img
	
	Gui, leveling_guide_skilltree_hover: Destroy
	global lab_hover_last := ""
	
	If mode
	{
		leveling_guide_valid_skilltree_files := 0
		leveling_guide_lab_files := ""
	}
	Else count := 0
	
	If (leveling_guide_skilltree_last != "") && !FileExist(leveling_guide_skilltree_last)
		leveling_guide_skilltree_active := 1
	
	Loop, Files, img\GUI\skill-tree\*
	{
		If mode && InStr(A_LoopFileName, "[lab")
			leveling_guide_lab_files .= A_LoopFileName ","
		If !InStr("jpg,bmp,png", A_LoopFileExt) || (A_LoopFileExt = "") || InStr(A_LoopFileName, "[lab")
			continue
		If mode
			leveling_guide_valid_skilltree_files += 1
		Else count += 1
		
		If (mode = 2) && (A_LoopFilePath = leveling_guide_skilltree_last)
			leveling_guide_skilltree_active := leveling_guide_valid_skilltree_files
		
		If !mode && (count = leveling_guide_skilltree_active)
		{
			img := A_LoopFilePath
			leveling_guide_skilltree_last := A_LoopFilePath
			img_name := StrReplace(A_LoopFileName, "." A_LoopFileExt)
			break
		}
	}
	If mode
		Return
	If (leveling_guide_valid_skilltree_files != 0) || (leveling_guide_lab_files != "")
	{
		Gui, leveling_guide_skilltree: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide_skilltree
		Gui, leveling_guide_skilltree: Margin, 0, 0
		Gui, leveling_guide_skilltree: Color, Black
		WinSet, Transparent, 255
		Gui, leveling_guide_skilltree: Font, s%fSize0% cWhite, Fontin SmallCaps
		If (leveling_guide_valid_skilltree_files != 0)
		{
			/*
			pSkilltree := Gdip_LoadImageFromFile(img)
			leveling_guide_skilltree_width := Gdip_GetImageWidth(pSkilltree), height := Gdip_GetImageHeight(pSkilltree)
			leveling_guide_skilltree_width := (leveling_guide_skilltree_width > poe_width/3) ? poe_width/3 : leveling_guide_skilltree_width
			Gdip_DisposeImage(pSkilltree)
			*/
			Gui, leveling_guide_skilltree: Add, Picture, Section vskilltree_img HWNDparse, % img
			WinGetPos,,,, height, ahk_id %parse%
			Gui, leveling_guide_skilltree: Add, Text, xs Hidden Border BackgroundTrans Center wp, % img_name
			Gui, leveling_guide_skilltree: Add, Progress, xp yp wp hp Disabled Border BackgroundBlack c404040 Center range0-%leveling_guide_valid_skilltree_files%, % leveling_guide_skilltree_active ;"img " leveling_guide_skilltree_active "/" leveling_guide_valid_skilltree_files ": " img_name
			If (SubStr(img_name, 1, 1) = "[")
				img_name := SubStr(img_name, InStr(img_name, "]") + 1)
			While (SubStr(img_name, 1, 1) = " ")
				img_name := SubStr(img_name, 2)
			Gui, leveling_guide_skilltree: Add, Text, xp yp Border BackgroundTrans Center wp, % img_name ;"img " leveling_guide_skilltree_active "/" leveling_guide_valid_skilltree_files ": " img_name
			Gui, leveling_guide_skilltree: Show, NA x10000 y10000
			WinGetPos,,,, height, ahk_id %hwnd_leveling_guide_skilltree%
			Gui, leveling_guide_skilltree: Show, % "NA x"xScreenOffSet " y"yScreenOffSet + poe_height//2 - height//2 " AutoSize"
		}
		/*
		Else
		{
			Gui, leveling_guide_skilltree: Add, Text, % "Section Center 0x200 h"poe_height//3 " w"poe_height//3, no regular skilltree images found
			;leveling_guide_skilltree_width := poe_height//3, height := poe_height//3
		}
		*/
		Gui, leveling_guide_labs: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_leveling_guide_labs
		Gui, leveling_guide_labs: Margin, 0, 0
		Gui, leveling_guide_labs: Color, Black
		WinSet, Transparent, 255
		;WinSet, TransColor, Silver
		Gui, leveling_guide_labs: Font, s%fSize0% cBlack Bold, Fontin SmallCaps
		Loop, Parse, leveling_guide_lab_files, `,
		{
			lab_lvls := [33, 55, 68, 75]
			style := (A_Index = 1) ? "Section" : "ys"
			If (A_LoopField = "")
				Continue
			parse := SubStr(A_LoopField, InStr(A_LoopField, "[lab") + 1, 4)
			Gui, leveling_guide_labs: Add, Picture, % style " BackgroundTrans w"poe_height//25 " h-1 HWNDhwnd_leveling_guide_lab"SubStr(parse, 0), img\GUI\%parse%.png
			;Gui, leveling_guide_labs: Add, Text, % "xp yp wp hp Center BackgroundTrans", % lab_lvls[StrReplace(parse, "lab")]
		}
		If (leveling_guide_lab_files != "")
		{
			Gui, leveling_guide_labs: Show, NA x10000 y10000
			WinGetPos,,, width2, height2
			Gui, leveling_guide_labs: Show, % "NA x"xScreenOffSet + poe_width//2 - width2//2 " y"yScreenOffSet + poe_height - height2 - poe_height*0.0215
		}
	}
}