Init_itemchecker:
IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
IniRead, enable_itemchecker_ID, ini\item-checker.ini, settings, enable wisdom-scroll trigger, 0
IniRead, fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset, 0
itemchecker_default_colors := ["3399ff", "00ff00", "008000", "ffff00", "ff8c00", "dc143c", "800000", "00ffff"]
IniRead, itemchecker_t0_color, ini\item-checker.ini, UI, tier 0, % "3399ff"
IniRead, itemchecker_t1_color, ini\item-checker.ini, UI, tier 1, % "00ff00"
IniRead, itemchecker_t2_color, ini\item-checker.ini, UI, tier 2, % "008000"
IniRead, itemchecker_t3_color, ini\item-checker.ini, UI, tier 3, % "ffff00"
IniRead, itemchecker_t4_color, ini\item-checker.ini, UI, tier 4, % "ff8c00"
IniRead, itemchecker_t5_color, ini\item-checker.ini, UI, tier 5, % "dc143c"
IniRead, itemchecker_t6_color, ini\item-checker.ini, UI, tier 6, % "800000"
IniRead, itemchecker_t7_color, ini\item-checker.ini, UI, fractured, % "00ffff"
Return

Itemchecker:
;Function quick-jump: LLK_ItemCheck(), LLK_ItemCheckHighlight()

If InStr(A_GuiControl, "minus") ;minus-button was clicked
{
	fSize_offset_itemchecker -= 1
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}
If (A_GuiControl = "fSize_itemchecker_reset") ;reset-button was clicked
{
	fSize_offset_itemchecker := 0
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}
If InStr(A_GuiControl, "plus") ;plus-button was clicked
{
	fSize_offset_itemchecker += 1
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If InStr(A_GuiControl, "_reset") ;a reset-button was clicked
{
	value := StrReplace(A_GuiControl, "itemchecker_t")
	value := StrReplace(value, "_reset")
	itemchecker_t%value%_color := itemchecker_default_colors[value + 1]
	GuiControl, settings_menu:, itemchecker_t%value%_color, % itemchecker_t%value%_color
	GuiControl, settings_menu: +cRed, itemchecker_apply_color
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Return
}

If InStr(A_GuiControl, "_color") && !InStr(A_GuiControl, "apply") ;an edit field received input
{
	Gui, settings_menu: Submit, NoHide
	value := StrReplace(A_GuiControl, "itemchecker_t")
	value := StrReplace(value, "_color")
	GuiControl, settings_menu: +cRed, itemchecker_apply_color
	If (StrLen(%A_GuiControl%) = 6)
		GuiControl, % "settings_menu: +c"%A_GuiControl%, itemchecker_bar%value%
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Return
}

If (A_GuiControl = "itemchecker_apply_color") ;save-button was clicked
{
	GuiControl, settings_menu: +cWhite, itemchecker_apply_color
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Gui, settings_menu: Submit, NoHide
	Loop 8
	{
		value := A_Index - 1
		StringLower, itemchecker_t%value%_color, itemchecker_t%value%_color
		IniWrite, % itemchecker_t%value%_color, ini\item-checker.ini, UI, % (A_Index = 8) ? "fractured" : "tier " value
	}
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If (A_GuiControl = "enable_itemchecker_ID")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_ID, ini\item-checker.ini, Settings, enable wisdom-scroll trigger
	Return
}

If (A_Gui = "itemchecker") ;an item affix was clicked
{
	GuiControlGet, itemchecker_mod,, % A_GuiControl
	itemchecker_mod := StrReplace(itemchecker_mod, "`n", ";")
	itemchecker_errorlvl := LLK_ItemCheckHighlight(StrReplace(itemchecker_mod, " (fractured)"), click)
	color := (click = 1) ? "Aqua" : "Red"
	If (itemchecker_errorlvl = 1)
		GuiControl, itemchecker: +c%color%, % A_GuiControl
	Else If (itemchecker_errorlvl = 0)
		GuiControl, itemchecker: +cWhite, % A_GuiControl
	WinSet, Redraw,, ahk_id %hwnd_itemchecker%
	WinActivate, ahk_group poe_window
	Return
}
Return

LLK_ItemCheck(config := 0) ;parse item-info and create tooltip GUI
{
	global itemchecker_t0_color, itemchecker_t1_color, itemchecker_t2_color, itemchecker_t3_color, itemchecker_t4_color, itemchecker_t5_color, itemchecker_t6_color, itemchecker_t7_color
	global ThisHotkey_copy, fSize0, xScreenOffSet, yScreenOffset, poe_height, poe_width, hwnd_itemchecker, fSize_offset_itemchecker, xPos_itemchecker, yPos_itemchecker, itemchecker_clipboard, itemchecker_panel_cluster, shift_down
	global itemchecker_panel1, itemchecker_panel2, itemchecker_panel3, itemchecker_panel4, itemchecker_panel5, itemchecker_panel6, itemchecker_panel7, itemchecker_panel8, itemchecker_panel9, itemchecker_panel10, itemchecker_panel11, itemchecker_panel12, itemchecker_panel13, itemchecker_panel14, itemchecker_panel15
	
	itemchecker_width := poe_width//65
	
	If config ;for changing UI settings in the menu
	{
		WinGetPos, xPos_itemchecker, yPos_itemchecker,,, ahk_id %hwnd_itemchecker%
		Clipboard := itemchecker_clipboard
	}
	Else itemchecker_clipboard := Clipboard
	
	If InStr(Clipboard, "`nUnidentified", 1) || InStr(Clipboard, "`nUnmodifiable", 1) || InStr(Clipboard, "`nRarity: Gem", 1) || InStr(Clipboard, "`nRarity: Normal", 1) || InStr(Clipboard, "`nRarity: Currency", 1) || InStr(Clipboard, "`nRarity: Divination Card", 1) || InStr(Clipboard, "item class: pieces") || InStr(Clipboard, "item class: maps") ;certain exclusion criteria
	{
		If (shift_down != "wisdom")
			LLK_ToolTip("item-info: item not supported")
		Return
	}
	
	If !InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier") ;could not copy advanced item-info
	{
		If (shift_down != "wisdom")
			LLK_ToolTip("item-info: omni-key setup required (?)", 2)
		Return
	}
	
	If InStr(Clipboard, "attacks per second: ") ;calculate dps values if item is a weapon
	{
		phys_dmg := 0
		pdps := 0
		ele_dmg := 0
		ele_dmg3 := 0
		ele_dmg4 := 0
		ele_dmg5 := 0
		edps0 := 0
		chaos_dmg := 0
		cdps := 0
		speed := 0
		Loop, Parse, clipboard, `r`n, `r`n
		{
			If InStr(A_LoopField,"Physical Damage: ")
			{
				phys_dmg := A_LoopField
				Loop, Parse, phys_dmg, " "
					If (A_Index=3)
						phys_dmg := A_LoopField
			}
			If InStr(A_LoopField,"Elemental Damage: ")
			{
				ele_dmg := StrReplace(A_LoopField, "`r`n")
				ele_dmg := StrReplace(ele_dmg, " (augmented)")
				ele_dmg := StrReplace(ele_dmg, ",")
				Loop, Parse, ele_dmg, " "
					If A_Index between 3 and 5
						ele_dmg%A_Index% := A_LoopField
			}
			If InStr(A_LoopField, "Chaos Damage: ")
			{
				chaos_dmg := StrReplace(A_LoopField, "`r`n")
				chaos_dmg := StrReplace(chaos_dmg, " (augmented)")
				Loop, Parse, chaos_dmg, " "
					If (A_Index=3)
						chaos_dmg := A_LoopField
			}
			If InStr(A_LoopField, "Attacks per Second: ")
			{
				speed := A_LoopField
				Loop, Parse, speed, " "
					If (A_Index=4)
						speed := SubStr(A_LoopField,1,4)
				break
			}
		}
		If (phys_dmg!=0)
		{
			Loop, Parse, phys_dmg, "-"
				phys%A_Index% := A_LoopField
			pdps := ((phys1+phys2)/2)*speed
			pdps := Format("{:0.2f}", pdps)
		}
		If (ele_dmg!=0)
		{
			edps2 := 0
			edps3 := 0
			Loop, Parse, ele_dmg3, "-"
				ele_dmg3_%A_Index% := A_LoopField
			edps1 := ((ele_dmg3_1+ele_dmg3_2)/2)*speed
			If (ele_dmg4!=0)
			{
				Loop, Parse, ele_dmg4, "-"
					ele_dmg4_%A_Index% := A_LoopField
				edps2 := ((ele_dmg4_1+ele_dmg4_2)/2)*speed
			}
			If (ele_dmg5!=0)
			{
				Loop, Parse, ele_dmg5, "-"
					ele_dmg5_%A_Index% := A_LoopField
				edps3 := ((ele_dmg5_1+ele_dmg5_2)/2)*speed
			}
			edps0 := edps1+edps2+edps3
			edps0 := Format("{:0.2f}", edps0)
		}
		If (chaos_dmg!=0)
		{
			Loop, Parse, chaos_dmg, "-"
				chaos_dmg%A_Index% := A_LoopField
			cdps := ((chaos_dmg1+chaos_dmg2)/2)*speed
			cdps := Format("{:0.2f}", cdps)
		}
		tdps := pdps+edps0+cdps
		tdps := Format("{:0.2f}", tdps)
	}
	
	;wanted to calculate the roll of the defense stat, but you can't copy it from item-info
	/*
	Loop, Parse, Clipboard, `n, `r
	{
		If InStr(A_LoopField, "armour:") || InStr(A_LoopField, "evasion rating:") || InStr(A_LoopField, "energy shield:")
		{
			defense := StrReplace(A_LoopField, "armour: ")
			defense := StrReplace(defense, "evasion rating: ")
			defense := StrReplace(defense, "energy shield: ")
			MsgBox, % defense
		}
	}
	*/
	
	;itemcheck_affixes := " affixes: " LLK_SubStrCount(Clipboard, "prefix modifier", "`n") " + " LLK_SubStrCount(Clipboard, "suffix modifier", "`n") ;affix configuration label
	itemcheck_prefixes := "prefix: " LLK_SubStrCount(Clipboard, "prefix modifier", "`n") ;prefix-label text
	itemcheck_suffixes := "suffix: " LLK_SubStrCount(Clipboard, "suffix modifier", "`n") ;suffix-label text
	itemcheck_clip := SubStr(Clipboard, InStr(Clipboard, "item level:"))
	item_lvl := SubStr(itemcheck_clip, 1, InStr(itemcheck_clip, "`r`n",,, 1) - 1)
	item_lvl := StrReplace(item_lvl, "item level:")
	itemcheck_clip := StrReplace(itemcheck_clip, "`r`n", "|") ;combine single item-info lines into affix groups
	StringLower, itemcheck_clip, itemcheck_clip

	itemcheck_parse := "(-.)|" ;characters that indicate numerical values/strings
	loop := 0 ;count affixes
	unique := InStr(Clipboard, "rarity: unique") ? 1 : 0 ;is item unique?
	;jewel := InStr(Clipboard, "viridian jewel") || InStr(Clipboard, "crimson jewel") || InStr(Clipboard, "cobalt jewel") ? 1 : 0 ;is item a jewel?
	affixes := [] ;array to store affix information
	
	Loop, Parse, itemcheck_clip, | ;remove unnecessary item-info: implicits, crafted mods, etc.
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If InStr(A_LoopField, "passive skills (enchant)") ;is the item a cluster jewel?
		{
			If InStr(Clipboard, "small cluster jewel") ;is it a small one?
			{
				cluster_type := "small" ;define type
				cluster_passives_min := 2
				cluster_passives_max := -3 ;negative values for better representation in bars (full bar shows optimal count)
				cluster_passives_optimal := -2
			}
			Else
			{
				cluster_type := InStr(Clipboard, "medium cluster jewel") ? "medium" : "large"
				cluster_passives_min := (cluster_type = "medium") ? 4 : 8
				cluster_passives_max := (cluster_type = "medium") ? -6 : -12
				cluster_passives_optimal := (cluster_type = "medium") ? -5 : -8
			}
			cluster_passives := "-" SubStr(A_LoopField, 6, 2) ;save passive-count
			cluster_passives := StrReplace(cluster_passives, " ")
		}
		If (cluster_type != "") && InStr(A_LoopField, "Added Small Passive Skills grant: ") && InStr(A_LoopField, "(enchant)") ;parse cluster enchant
		{
			cluster_parse := "+%"
			Loop, Parse, A_LoopField, `n, `n
			{
				If (SubStr(A_LoopField, 1, 1) = "(")
					continue
				cluster_enchant .= (cluster_enchant = "") ? A_LoopField : "`n" A_LoopField
				cluster_enchant := StrReplace(cluster_enchant, "Added Small Passive Skills grant: ")
				cluster_enchant := StrReplace(cluster_enchant, " (enchant)")
			}
		}
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") || InStr(A_LoopField, "crafted")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	Loop, Parse, cluster_enchant
	{
		If (A_Index = 1)
			cluster_enchant := ""
		If IsNumber(A_LoopField) || InStr(cluster_parse, A_LoopField)
			continue
		cluster_enchant .= A_LoopField
	}
	
	cluster_enchant := StrReplace(cluster_enchant, "  ", " ")
	cluster_enchant := StrReplace(cluster_enchant, "`n ", "`n")
	cluster_enchant := StrReplace(cluster_enchant, "damage over time", "dmg over time")
	cluster_enchant := (SubStr(cluster_enchant, 1, 1) = " ") ? SubStr(cluster_enchant, 2) : cluster_enchant
	cluster_enchant := (SubStr(cluster_enchant, 1, 3) = "to ") ? SubStr(cluster_enchant, 4) : cluster_enchant
	
	Loop, Parse, itemcheck_clip, `n ;remove tooltips from item-info
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "(")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	itemcheck_clip := StrReplace(itemcheck_clip, " — Unscalable Value")
	itemcheck_clip := StrReplace(itemcheck_clip, "Added Small Passive Skills also grant: ")
	itemcheck_clip := StrReplace(itemcheck_clip, "1 Added Passive Skill is ")
	
	While (SubStr(itemcheck_clip, 0) = "`n") ;remove white-space at the end
		itemcheck_clip := SubStr(itemcheck_clip, 1, -1)
	
	;mark lines belonging to hybrid mods, and put lines of an affix into a group
	itemcheck_clip := StrReplace(itemcheck_clip, "}`n", "};;")
	itemcheck_clip := StrReplace(itemcheck_clip, "`n{", "|{")
	If !unique
		itemcheck_clip := StrReplace(itemcheck_clip, "`n", "(hybrid)`n(hybrid)")
	itemcheck_clip := StrReplace(itemcheck_clip, "};;", "}`n")
	
	Loop, Parse, itemcheck_clip, | ;parse the item-info affix by affix
	{
		If (unique = 1) && !InStr(A_LoopField, "(") ;skip unscalable unique affix
			continue
		loop += 1
		tier := (unique = 1) ? "u" : InStr(A_LoopField, "tier:") ? SubStr(A_LoopField, InStr(A_LoopField, "tier: ") + 6, InStr(A_LoopField, ")") - InStr(A_LoopField, "tier: ") - 6) : 0 ;determine affix tier
		Loop, Parse, A_LoopField, `n ;parse affix info line by line
		{
			;check if affix is veiled
			If InStr(A_LoopField, "'s veiled")
				betrayal := SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s v") - InStr(A_LoopField, """") + 1)
			Else If InStr(A_LoopField, "s' veiled")
				betrayal := SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s' v") - InStr(A_LoopField, """") + 2)
			Else If InStr(A_LoopField, """veiled""") || InStr(A_LoopField, """of the veil""")
				betrayal := ""

			If (A_Index = 1) ;skip first line of affix group (containing tier, tags, etc.)
				Continue
			
			tier .= (tier != "u") && InStr(A_LoopField, "(hybrid)") && !InStr(tier, "h") ? "h" : "" ;mark tier as hybrid if applicable
			mod := betrayal StrReplace(A_LoopField, "(hybrid)") ;store mod-text in variable
			mod1 := InStr(mod, "adds") && InStr(mod, "to") ? StrReplace(mod, "to", "|",, 1) : mod ;workaround for flat-dmg affixes where x and/or y in 'adds x to y damage' doesn't scale (unique vaal sword, maybe more)
			mods.Push(A_LoopField ";;" tier)
			
			roll := "" ;variable in which to store the numerical values of the affix
			Loop, Parse, % StrReplace(mod1, " (fractured)") ;parse mod-text character by character
			{
				If IsNumber(A_LoopField) || InStr(itemcheck_parse, A_LoopField) ;number or numerical character
					roll .= A_LoopField
			}
			
			If InStr(roll, "(") ;numerical value has scaling
			{
				Loop, Parse, roll, `| ;parse numerical value string value by value (in 'adds x to y damage', x and y are values)
				{
					If (A_Index = 1)
						roll_count := 0 ;count number of values, i.e. does the mod only have x, or x and y
					If (A_LoopField = "")
						continue
					roll_count += 1
					roll_trigger := 0 ;three-step trigger to deconstruct the string
					trigger_index := 0 ;position within the string at which something was triggered
					
					Loop, Parse, % InStr(A_LoopField, "(") ? A_LoopField : A_LoopField "(" A_LoopField "-" A_LoopField ")" ;if given value is scalable, parse string character by character as is: x(x_lower-x_upper) | otherwise, create pseudo-string and parse: x(x-x)
					{
						If (A_Index = 1)
						{
							roll%roll_count% := InStr(mod, "reduced") && (InStr(mod, "(-") || InStr(mod, "--")) ? "-" : "" ;'reduced' in mod-text signals negative value without minus-sign, so it needs to be added manually | also check if range even includes negative values, or if it's a negative value due to kalandra
							roll%roll_count%_1 := "" ;lower bound of the affix roll
							roll%roll_count%_2 := "" ;upper bound of the affix roll
						}
						If IsNumber(A_LoopField) || (A_LoopField = ".") || (A_LoopField = "-" && A_Index = trigger_index + 1) ;3rd condition = only include minus-sign if it immediately follows a trigger, i.e. '('
						{
							If (roll_trigger = 0)
								roll%roll_count% .= A_LoopField
							If (roll_trigger = 1)
								roll%roll_count%_1 .= A_LoopField
							If (roll_trigger = 2)
								roll%roll_count%_2 .= A_LoopField
						}
						If (A_LoopField = "(") || (A_LoopField = "-" && A_Index != trigger_index + 1) ;'(' and minus-sign increase trigger, but minus-sign only if not preceded by trigger, i.e. if it means 'to' and not 'minus'
						{
							roll_trigger += 1
							trigger_index := A_Index
						}
					}
				}
				;create a string with the range of the roll and current value: either "x_lower,x,x_upper" or "x_lower+y_lower,x+y,x_upper+y_upper"
				roll_qual := (roll_count = 1) ? Min(roll1_1, roll1_2) "," roll1 "," Max(roll1_1, roll1_2) : Min(roll1_1, roll1_2) + Min(roll2_1, roll2_2) "," roll1 + roll2 "," Max(roll1_1, roll1_2) + Max(roll2_1, roll2_2)
			}
			Else roll_qual := 0 "," 100 "," 100 ;if numerical value doesn't scale, create a string "0,100,100" where 0 serves as x_lower and 100 as x and x_upper
			affixes.Push(mod ";" tier ";" roll_qual) ;push mod-text, tier, and roll-values into array
		}
	}
	
	If (loop = 0)
	{
		LLK_ToolTip("item is not scalable")
		Return
	}
	
	;create tooltip GUI
	Gui, itemchecker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker
	Gui, itemchecker: Margin, 0, 0
	Gui, itemchecker: Color, Black
	Gui, itemchecker: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
	
	If InStr(Clipboard, "attacks per second: ") ;create top-area with DPS values if item is weapon
	{
		Gui, itemchecker: Add, Text, % "Section xs Border w"itemchecker_width*6, % " p-dps: " pdps
		Gui, itemchecker: Add, Text, % "ys Border wp", % " c-dps: " cdps
		Gui, itemchecker: Add, Text, % "Section xs Border wp", % " e-dps: " edps0
		Gui, itemchecker: Add, Text, % "ys Border wp", % " total: " tdps
	}
	
	color := (item_lvl >= 86) ? "Green" : "505050" ;highlight ilvl bar green if ilvl >= 86
	
	If !unique ;if item is not unique, determine affix configuration and add bar to visualize it and ilvl
	{
		Gui, itemchecker: Add, Text, % "xs Hidden Border w"itemchecker_width*6, placeholder ;add hidden text label as dummy to get the correct dimensions
		Gui, itemchecker: Add, Progress, xp yp Border Section hp wp range66-86 BackgroundBlack c%color%, % item_lvl ;place progress bar on top of dummy label and inherit dimensions
		Gui, itemchecker: Add, Text, % "xp yp Border BackgroundTrans wp", % " ilvl:" item_lvl ;add actual text label
		
		If InStr(Clipboard, "right click to drink")
			max_affixes := 1
		Else max_affixes := InStr(Clipboard, "Right click to remove from the Socket") ? 2 : 3 ;set max value for the affix bar (4 for jewels, 6 for the rest)
		
		color := (LLK_SubStrCount(Clipboard, "prefix modifier", "`n") < max_affixes) && !InStr(Clipboard, "`nCorrupted", 1) && !InStr(Clipboard, "`nMirrored", 1) ? "Green" : "505050" ;determine bar-color for affixes: green if open affix-slots available
		Gui, itemchecker: Add, Progress, % "ys w"itemchecker_width*3 " hp Border BackgroundTrans range0-"max_affixes " BackgroundBlack c"color, % LLK_SubStrCount(Clipboard, "prefix modifier", "`n") ;add prefix bar
		Gui, itemchecker: Add, Text, % "yp xp Center Border BackgroundTrans wp", % itemcheck_prefixes ;add affix text label
		
		color := (LLK_SubStrCount(Clipboard, "suffix modifier", "`n") < max_affixes) && !InStr(Clipboard, "`nCorrupted", 1) && !InStr(Clipboard, "`nMirrored", 1) ? "Green" : "505050" ;determine bar-color for affixes: green if open affix-slots available
		Gui, itemchecker: Add, Progress, % "ys wp hp Border BackgroundTrans range0-"max_affixes " BackgroundBlack c"color, % LLK_SubStrCount(Clipboard, "suffix modifier", "`n") ;add suffix bar
		Gui, itemchecker: Add, Text, % "yp xp Center Border BackgroundTrans wp", % itemcheck_suffixes ;add affix text label
	}
	
	If (cluster_type != "") ;if item is a cluster jewel, add passive-skills and enchant info
	{
		color := (cluster_passives >= cluster_passives_optimal) ? "Green" : "505050"
		Gui, itemchecker: Add, Text, % "xs Hidden Border w"itemchecker_width*12, placeholder ;add hidden text label as dummy to get the correct dimensions
		Gui, itemchecker: Add, Progress, xp yp Border Section hp wp range%cluster_passives_max%-%cluster_passives_optimal% BackgroundBlack c%color%, % cluster_passives ;place progress bar on top of dummy label and inherit dimensions
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp", % " passive skills: " cluster_passives*(-1) "(" cluster_passives_min "-" cluster_passives_max*(-1) ")" ;add actual text label
		
		If (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
			color := "White"
		Else color := (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";")) = 1) ? "Aqua" : "Red" ;determine which is the case
		Gui, itemchecker: Add, Text, % "xs Border Center BackgroundTrans vitemchecker_panel_cluster gItemchecker wp c"color, % cluster_enchant ;add actual text label
	}
	
	Loop, % affixes.Count() ;n = number of parsed mod lines
	{
		style := !unique ? "w"itemchecker_width*11 : "w"itemchecker_width*12 ;width of the mod list: non-unique list narrower for extra tier-column on the far right
		
		Loop, Parse, % affixes[A_Index], % ";" ;parse info from current array entry
		{
			Switch A_Index
			{
				Case 1:
					mod := A_LoopField
				Case 2:
					tier := A_LoopField
				Case 3:
					quality := A_LoopField
			}
		}
		
		If !InStr(mod, "(") && !InStr(mod, "(hybrid)") && unique ;skip unscalable values within hybrid affixes
			continue
		
		Loop, Parse, quality, `, ;determine lower & upper bound, and value
		{
			Switch A_Index
			{
				Case 1:
					lower_bound := A_LoopField*100
				Case 2:
					value := A_LoopField*100
				Case 3:
					upper_bound := A_LoopField*100
			}
		}
		
		color := (unique = 0) ? "505050" : "994C00" ;gray or brown color for background bars
		Gui, itemchecker: Add, Text, % "Section xs Border hidden "style, % StrReplace(mod, " (fractured)") ;add dummy text label for dimensions
		If InStr(mod, "fractured")
			Gui, itemchecker: Font, norm, Fontin SmallCaps
		
		;add progress bar and inherit dimensions from dummy label
		Gui, itemchecker: Add, Progress, % (A_Index = 1) ? "xp yp Section Disabled Border hp wp range" lower_bound "-" upper_bound " BackgroundBlack c"color : "xp yp hp wp Disabled Border range" lower_bound "-" upper_bound " BackgroundBlack c"color, % value
		
		If !unique
		{
			If (LLK_ItemCheckHighlight(StrReplace(mod, " (fractured)")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "White"
			Else color := (LLK_ItemCheckHighlight(StrReplace(mod, " (fractured)")) = 1) ? "Aqua" : "Red" ;determine which is the case
		}
		Else color := "White" ;uniques always have white text
		
		If !unique
			Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% gItemchecker %style% Border BackgroundTrans xp yp, % StrReplace(mod, " (fractured)") ;non-unique items have clickable mod-texts for highlighting/blacklisting
		Else Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% %style% Border BackgroundTrans xp yp, % mod ;unique items don't need that
		
		Switch StrReplace(tier, "h") ;set correct highlight color according to tier
		{
			Case 0:
				color := itemchecker_t0_color ;untiered affixes, e.g. delve, veiled, etc.
			Case "u":
				color := "994C00" ;unique
			Case 1:
				color := itemchecker_t1_color ;tier x
			Case 2:
				color := itemchecker_t2_color
			Case 3:
				color := itemchecker_t3_color
			Case 4:
				color := itemchecker_t4_color
			Case 5:
				color := itemchecker_t5_color
			Default:
				color := itemchecker_t6_color
		}
		
		If !unique
		{
			If InStr(mod, "fractured") ;override color in case mod is fractured
				color := itemchecker_t7_color
			Gui, itemchecker: Add, Progress, % "ys hp w"itemchecker_width " BackgroundBlack Border C"color, 100 ;add colored progress bar as background for tier-column
			Gui, itemchecker: Add, Text, yp xp Border Center cBlack hp wp BackgroundTrans, % (tier = "u") ? " " : tier ;add number label to tier-column
		}
	}
	
	Gui, itemchecker: Show, NA x10000 y10000 ;show GUI outside of monitor
	WinGetPos,,, width, height, ahk_id %hwnd_itemchecker% ;get GUI position and dimensions
	MouseGetPos, mouseXpos, mouseYpos
	mouseXpos := (config != 0) ? xPos_itemchecker + width + 15 : mouseXpos ;override cursor-position if feature is being configured in settings menu
	mouseYpos := (config != 0) ? yPos_itemchecker + height + 15 : mouseYpos
	winXpos := (mouseXpos - 15 - width < xScreenOffSet) ? xScreenOffSet : mouseXpos - width - 15 ;reposition coordinates in case tooltip would land outside monitor area
	winYpos := (mouseypos - 15 - height < yScreenOffSet) ? yScreenOffSet : mouseYpos - height - 15
	Gui, itemchecker: Show, % "NA x"winXpos " y"winYpos ;show GUI next to cursor
	LLK_Overlay("itemchecker", "show") ;trigger GUI for auto-hiding when alt-tabbed
}

LLK_ItemCheckHighlight(string, mode := 0) ;check if mod is highlighted or blacklisted
{
	global itemchecker_highlight, itemchecker_blacklist
	itemchecker_highlight_parse := "+-()%"
	Loop, Parse, string ;parse string handed to function character by character
	{
		If (A_Index = 1)
			string := "" ;clear string
		If !IsNumber(A_LoopField) && !InStr(itemchecker_highlight_parse, A_LoopField) ;remove numbers and numerical signs
			string .= A_LoopField
	}
	
	Loop, Parse, string, %A_Space%, %A_Space% ;clean up double-spaces
	{
		If (A_Index = 1)
			string := ""
		string .= (string = "") ? A_LoopField : " " A_LoopField
	}
	If (mode = 0) ;check if mod is highlighted/blacklisted in order to determine color
	{
		If !InStr(itemchecker_highlight, "|" string "|") && !InStr(itemchecker_blacklist, "|" string "|")
			Return 0
		Else If InStr(itemchecker_highlight, "|" string "|")
			Return 1
		Else If InStr(itemchecker_blacklist, "|" string "|")
			Return -1
	}
	If (mode = 1) ;mod was left-clicked: check for current highlight-state
	{
		If InStr(itemchecker_blacklist, "|" string "|") ;first, check if mod is actually blacklisted
		{
			LLK_ToolTip("set to neutral first")
			Return -1
		}
		If !InStr(itemchecker_highlight, "|" string "|") ;mod is not highlighted: add it to highlighted mods and save
		{
			itemchecker_highlight .= "|" string "|"
			IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
			Return 1
		}
		Else ;mod is highlighted: remove it from highlighted mods and save
		{
			itemchecker_highlight := StrReplace(itemchecker_highlight, "|" string "|")
			IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
			Return 0
		}
	}
	If (mode = 2) ;mod was right-clicked: check for current blacklist-state
	{
		If InStr(itemchecker_highlight, "|" string "|") ;first, check if mod is actually highlighted
		{
			LLK_ToolTip("set to neutral first")
			Return -1
		}
		If !InStr(itemchecker_blacklist, "|" string "|") ;mod is not blacklisted: add it to blacklisted mods and save
		{
			itemchecker_blacklist .= "|" string "|"
			IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
			Return 1
		}
		Else ;mod is blacklisted: remove it from blacklisted mods and save
		{
			itemchecker_blacklist := StrReplace(itemchecker_blacklist, "|" string "|")
			IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
			Return 0
		}
	}
}

LLK_ItemCheckVendor()
{
	global
	MouseGetPos, itemchecker_vendor_mouseX, itemchecker_vendor_mouseY
	itemchecker_vendor_dimensions := poe_height*0.047*0.50
	itemchecker_vendor_count += 1
	;create GUI
	Gui, itemchecker_vendor%itemchecker_vendor_count%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker_vendor%itemchecker_vendor_count%
	Gui, itemchecker_vendor%itemchecker_vendor_count%: Margin, 0, 0
	Gui, itemchecker_vendor%itemchecker_vendor_count%: Color, Red
	WinSet, Trans, 250
	Gui, itemchecker_vendor%itemchecker_vendor_count%: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
	Gui, itemchecker_vendor%itemchecker_vendor_count%: Add, Text, % "Center BackgroundTrans Border w"itemchecker_vendor_dimensions " h"itemchecker_vendor_dimensions,
	Gui, Show, % "NA x"itemchecker_vendor_mouseX - 0.5*itemchecker_vendor_dimensions " y"itemchecker_vendor_mouseY - 0.5*itemchecker_vendor_dimensions
}