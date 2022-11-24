Init_itemchecker:
IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
IniRead, enable_itemchecker_ID, ini\item-checker.ini, settings, enable wisdom-scroll trigger, 0
IniRead, enable_itemchecker_ilvl, ini\item-checker.ini, Settings, enable item-levels, 0
IniRead, fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset, 0
itemchecker_default_colors := ["3399ff", "00ff00", "008000", "ffff00", "ff8c00", "dc143c", "800000", "00eeee"]
itemchecker_default_colors_ilvl := ["ffffff", "00ff00", "008000", "ffff00", "ff8c00", "dc143c", "800000", "ff00ff", "800080"]
itemchecker_default_ilvls := ["83+", "78+", "73+", "68+", "64+", "60+", "56+", "56>"]
IniRead, itemchecker_t0_color, ini\item-checker.ini, UI, tier 0, % "3399ff"
IniRead, itemchecker_t1_color, ini\item-checker.ini, UI, tier 1, % "00ff00"
IniRead, itemchecker_t2_color, ini\item-checker.ini, UI, tier 2, % "008000"
IniRead, itemchecker_t3_color, ini\item-checker.ini, UI, tier 3, % "ffff00"
IniRead, itemchecker_t4_color, ini\item-checker.ini, UI, tier 4, % "ff8c00"
IniRead, itemchecker_t5_color, ini\item-checker.ini, UI, tier 5, % "dc143c"
IniRead, itemchecker_t6_color, ini\item-checker.ini, UI, tier 6, % "800000"
IniRead, itemchecker_t7_color, ini\item-checker.ini, UI, fractured, % "00eeee"

IniRead, itemchecker_ilvl1_color, ini\item-checker.ini, UI, ilvl tier 1, % "ffffff"
IniRead, itemchecker_ilvl2_color, ini\item-checker.ini, UI, ilvl tier 2, % "00ff00"
IniRead, itemchecker_ilvl3_color, ini\item-checker.ini, UI, ilvl tier 3, % "008000"
IniRead, itemchecker_ilvl4_color, ini\item-checker.ini, UI, ilvl tier 4, % "ffff00"
IniRead, itemchecker_ilvl5_color, ini\item-checker.ini, UI, ilvl tier 5, % "ff8c00"
IniRead, itemchecker_ilvl6_color, ini\item-checker.ini, UI, ilvl tier 6, % "dc143c"
IniRead, itemchecker_ilvl7_color, ini\item-checker.ini, UI, ilvl tier 7, % "800000"
IniRead, itemchecker_ilvl8_color, ini\item-checker.ini, UI, ilvl tier 8, % "ff00ff"
itemchecker_width := 0
Return

Itemchecker:
;Function quick-jump: LLK_ItemCheck(), LLK_ItemCheckHighlight()

If InStr(A_GuiControl, "minus") ;minus-button was clicked
{
	itemchecker_width := 0
	fSize_offset_itemchecker -= 1
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}
If (A_GuiControl = "fSize_itemchecker_reset") ;reset-button was clicked
{
	itemchecker_width := 0
	fSize_offset_itemchecker := 0
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}
If InStr(A_GuiControl, "plus") ;plus-button was clicked
{
	itemchecker_width := 0
	fSize_offset_itemchecker += 1
	IniWrite, % fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If InStr(A_GuiControl, "_reset") ;a reset-button was clicked
{
	value := InStr(A_GuiControl, "_t") ? StrReplace(A_GuiControl, "itemchecker_t") : StrReplace(A_GuiControl, "itemchecker_ilvl")
	value := StrReplace(value, "_reset")
	If InStr(A_GuiControl, "_t")
	{
		itemchecker_t%value%_color := itemchecker_default_colors[value + 1]
		GuiControl, settings_menu:, itemchecker_t%value%_color, % itemchecker_t%value%_color
	}
	Else
	{
		itemchecker_ilvl%value%_color := itemchecker_default_colors_ilvl[value]
		GuiControl, settings_menu:, itemchecker_ilvl%value%_color, % itemchecker_ilvl%value%_color
		If (itemchecker_ilvl%value%_color = "ffffff") && (value = 1)
			GuiControl, settings_menu: +cRed, itemchecker_ilvl%value%_text,
	}
	GuiControl, settings_menu: +cRed, itemchecker_apply_color
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Return
}

If InStr(A_GuiControl, "_color") && !InStr(A_GuiControl, "apply") ;an edit field received input
{
	Gui, settings_menu: Submit, NoHide
	value := InStr(A_GuiControl, "_t") ? StrReplace(A_GuiControl, "itemchecker_t") : StrReplace(A_GuiControl, "itemchecker_ilvl")
	value := StrReplace(value, "_color")
	GuiControl, settings_menu: +cRed, itemchecker_apply_color
	If (StrLen(%A_GuiControl%) = 6)
	{
		GuiControl, % "settings_menu: +c"%A_GuiControl%, % InStr(A_GuiControl, "_t") ? "itemchecker_bar"value : "itemchecker_bar_ilvl"value
		If (%A_GuiControl% = "ffffff") && (value = 1)
			GuiControl, settings_menu: +cRed, itemchecker_ilvl%value%_text,
		Else GuiControl, settings_menu: +cBlack, itemchecker_ilvl%value%_text,
		WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	}
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
		If enable_itemchecker_ilvl && (A_Index > 2)
		{
			value := A_Index
			StringLower, itemchecker_ilvl%value%_color, itemchecker_ilvl%value%_color
			IniWrite, % itemchecker_ilvl%value%_color, ini\item-checker.ini, UI, % "ilvl tier " value
		}
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

If (A_GuiControl = "enable_itemchecker_ilvl")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_ilvl, ini\item-checker.ini, Settings, enable item-levels
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Gosub, settings_menu
	Return
}

If (A_Gui = "itemchecker") ;an item affix was clicked
{
	GuiControlGet, itemchecker_mod,, % A_GuiControl
	itemchecker_mod := StrReplace(itemchecker_mod, "`n", ";")
	itemchecker_errorlvl := LLK_ItemCheckHighlight(StrReplace(itemchecker_mod, " (fractured)"), click)
	color := (click = 1) ? "00eeee" : "Red"
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
	global itemchecker_mod_data, itemchecker_base_item_data, itemchecker_width, enable_itemchecker_ilvl
	global itemchecker_t0_color, itemchecker_t1_color, itemchecker_t2_color, itemchecker_t3_color, itemchecker_t4_color, itemchecker_t5_color, itemchecker_t6_color, itemchecker_t7_color
	global itemchecker_ilvl0_color, itemchecker_ilvl1_color, itemchecker_ilvl2_color, itemchecker_ilvl3_color, itemchecker_ilvl4_color, itemchecker_ilvl5_color, itemchecker_ilvl6_color, itemchecker_ilvl7_color, itemchecker_ilvl8_color
	global ThisHotkey_copy, fSize0, xScreenOffSet, yScreenOffset, poe_height, poe_width, hwnd_itemchecker, fSize_offset_itemchecker, xPos_itemchecker, yPos_itemchecker, itemchecker_clipboard, itemchecker_panel_cluster, shift_down
	global itemchecker_panel1, itemchecker_panel2, itemchecker_panel3, itemchecker_panel4, itemchecker_panel5, itemchecker_panel6, itemchecker_panel7, itemchecker_panel8, itemchecker_panel9, itemchecker_panel10, itemchecker_panel11, itemchecker_panel12, itemchecker_panel13, itemchecker_panel14, itemchecker_panel15
	global itemchecker_corruption_implicit1, itemchecker_corruption_implicit2, itemchecker_corruption_implicit3, itemchecker_corruption_implicit4, itemchecker_corruption_implicit5, itemchecker_corruption_implicit6
	
	If (itemchecker_width = 0)
	{
		Gui, itemchecker_width: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker_width
		Gui, itemchecker_width: Margin, 0, 0
		Gui, itemchecker_width: Color, Black
		Gui, itemchecker_width: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
		Gui, itemchecker_width: Add, Text, % "Border HWNDmain_text", % "77777"
		GuiControlGet, itemchecker_, Pos, % main_text
		While (Mod(itemchecker_w, 2) != 0)
			itemchecker_w += 1
		width_margin := itemchecker_w//16
		While (Mod(width_margin, 2) != 0)
			width_margin += 1
		itemchecker_width := itemchecker_w + width_margin
		Gui, itemchecker_width: Destroy
		hwnd_itemchecker_width := ""
	}
	
	If config ;apply changes made in the settings menu
	{
		WinGetPos, xPos_itemchecker, yPos_itemchecker,,, ahk_id %hwnd_itemchecker%
		Clipboard := itemchecker_clipboard
	}
	Else itemchecker_clipboard := Clipboard
	itemchecker_metadata := SubStr(Clipboard, 1, InStr(Clipboard, "---") - 3)
	
	If InStr(Clipboard, "`nUnidentified", 1) || InStr(Clipboard, "`nUnmodifiable", 1) || InStr(Clipboard, "`nRarity: Gem", 1) || (InStr(Clipboard, "`nRarity: Normal", 1) && !InStr(Clipboard, "cluster jewel")) || InStr(Clipboard, "`nRarity: Currency", 1) || InStr(Clipboard, "`nRarity: Divination Card", 1) || InStr(Clipboard, "item class: pieces") || InStr(Clipboard, "item class: maps") || InStr(Clipboard, "item class: contracts") || InStr(Clipboard, "timeless jewel") ;certain exclusion criteria
	{
		If (shift_down != "wisdom")
			LLK_ToolTip("item-info: item not supported")
		Return
	}
	
	If (!InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier")) && !(InStr(Clipboard, "`nRarity: Normal", 1) && InStr(Clipboard, "cluster jewel")) ;could not copy advanced item-info
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

	itemcheck_parse := "(-.)|[]%" ;characters that indicate numerical values/strings
	loop := 0 ;count affixes
	unique := InStr(Clipboard, "rarity: unique") ? 1 : 0 ;is item unique?
	;jewel := InStr(Clipboard, "viridian jewel") || InStr(Clipboard, "crimson jewel") || InStr(Clipboard, "cobalt jewel") ? 1 : 0 ;is item a jewel?
	affixes := [] ;array to store affix information
	
	If InStr(itemchecker_metadata, "crimson jewel") || InStr(itemchecker_metadata, "viridian jewel") || InStr(itemchecker_metadata, "cobalt jewel")
	{
		itemchecker_item_class := "base jewel"
		If InStr(itemchecker_metadata, "crimson jewel")
			itemchecker_item_base := "crimson jewel"
		Else itemchecker_item_base := InStr(itemchecker_metadata, "viridian jewel") ? "viridian jewel" : "cobalt jewel"
	}
	
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
		If InStr(A_LoopField, "corruption implicit")
			corruption_implicits .= StrReplace(A_LoopField, " (implicit)") "|"
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
		itemcheck_clip := StrReplace(itemcheck_clip, "`n", "[hybrid]`n[hybrid]")
	itemcheck_clip := StrReplace(itemcheck_clip, "};;", "}`n")
	affix_levels := [] ;array to store the affix level-requirements
	affix_tiers := [] ;array to store the affix tiers
	
	Loop, Parse, itemcheck_clip, | ;parse the item-info affix by affix
	{
		If (unique = 1) && !InStr(A_LoopField, "(") ;skip unscalable unique affix
			continue
		loop += 1
		If (itemchecker_item_class != "base jewel")
			tier := unique ? "u" : InStr(A_LoopField, "tier:") ? SubStr(A_LoopField, InStr(A_LoopField, "tier: ") + 6, InStr(A_LoopField, ")") - InStr(A_LoopField, "tier: ") - 6) : 0 ;determine affix tier
		affix_name := unique ? "" : SubStr(A_LoopField, InStr(A_LoopField, """",,, 1) + 1, InStr(A_LoopField, """",,, 2) - InStr(A_LoopField, """",,, 1) - 1)
		mod := A_LoopField
		
		If !unique
		{
			If InStr(affix_name, "veil")
				affix_levels.Push(60)
			Loop, % itemchecker_mod_data[affix_name].Count()
			{
				outer_loop := A_Index
				target_loop := 0
				mod_check := 0
				
				If (itemchecker_item_class = "base jewel")
				{
					tag_check := 0
					Loop, % itemchecker_mod_data[affix_name].Count()
					{
						tag_check += itemchecker_mod_data[affix_name][A_Index].HasKey("LLK_tag")
						If (tag_check = 1)
						{
							target_loop := A_Index
							Break
						}
					}
				}
				
				If ((itemchecker_item_class = "base jewel") && (tag_check = 1))
				{
					Loop, % itemchecker_mod_data[affix_name][target_loop]["strings"].Count()
					{
						parse := StrReplace(itemchecker_mod_data[affix_name][target_loop]["strings"][A_Index], "1 Added Passive Skill is ")
						mod_check += InStr(mod, parse) ? 1 : 0
					}
				}
				Else
				{
					Loop, % itemchecker_mod_data[affix_name][outer_loop]["strings"].Count()
					{
						parse := StrReplace(itemchecker_mod_data[affix_name][outer_loop]["strings"][A_Index], "1 Added Passive Skill is ")
						mod_check += InStr(mod, parse) ? 1 : 0
					}
				}
				
				If (!InStr(mod, "[hybrid]") && (mod_check != 0)) || (InStr(mod, "[hybrid]") && (mod_check >= 2))
				{
					If (itemchecker_item_class != "base jewel")
					{
						Loop, % LLK_InStrCount(mod, "`n")
							affix_levels.Push(itemchecker_mod_data[affix_name][outer_loop]["level"])
					}
					Else
					{
						read_loop := (target_loop = 0) ? outer_loop : target_loop
						Loop, % itemchecker_mod_data[affix_name][read_loop]["weights"].Count()
						{
							If LLK_ArrayHasVal(itemchecker_base_item_data[itemchecker_item_base], itemchecker_mod_data[affix_name][read_loop]["weights"][A_Index]["tag"])
							{
								tier := itemchecker_mod_data[affix_name][read_loop]["weights"][A_Index]["weight"]
								tier := InStr(mod, "[hybrid]") ? tier "*" : tier ;MsgBox, % itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["tag"] "`n" itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["weight"]
								Break 2
							}
						}
					}
					;If InStr(parse_loopfield, "(hybrid)")
					;	affix_levels.Push(itemchecker_mod_data[affix_name][outer_loop]["level"])
					Break
				} 
			}
			;If (itemchecker_item_class != "simple jewel") && (affix_levels[loop2] = "")
			;	affix_levels.Push("?")
			;Else If (itemchecker_item_class = "simple jewel") && (tier = "")
			;	tier := InStr(tier, "h") ? "?h" : "?"
		}
		
		Loop, Parse, A_LoopField, `n ;parse affix info line by line
		{
			;check if affix is veiled
			If InStr(A_LoopField, "'s veil")
				betrayal := InStr(A_LoopField, """of ") ? SubStr(A_LoopField, InStr(A_LoopField, """of ") + 4, InStr(A_LoopField, "s v") - InStr(A_LoopField, """of ") - 2) : SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s v") - InStr(A_LoopField, """") + 1)
			Else If InStr(A_LoopField, "s' veil")
				betrayal := InStr(A_LoopField, """of ") ? SubStr(A_LoopField, InStr(A_LoopField, """of ") + 4, InStr(A_LoopField, "s' v") - InStr(A_LoopField, """of ") - 1) : SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s' v") - InStr(A_LoopField, """") + 2)
			Else If InStr(A_LoopField, """veiled""") || InStr(A_LoopField, """of the veil""")
				betrayal := ""
			If (A_Index = 1) ;skip first line of affix group (containing tier, tags, etc.)
				Continue
			
			loop2 += 1
			parse_loopfield := A_LoopField
			tier .= (tier != "u") && InStr(A_LoopField, "[hybrid]") && !InStr(tier, "*") ? "*" : ""
			affix_tiers.Push(InStr(A_LoopField, "(fractured)") ? affix_name "," tier "f" : affix_name "," tier) ;mark tier as hybrid if applicable
			mod := betrayal A_LoopField ;StrReplace(A_LoopField, "[hybrid]") ;store mod-text in variable
			
			/*
			If !unique ; (affix_levels[loop2] = "") ;skip if array-entry has already been filled by the first line of the hybrid mod
			{
				Loop, % itemchecker_mod_data[affix_name].Count()
				{
					outer_loop := A_Index
					Loop, % itemchecker_mod_data[affix_name][outer_loop]["strings"].Count()
					{
						parse := StrReplace(itemchecker_mod_data[affix_name][outer_loop]["strings"][A_Index], "1 Added Passive Skill is ")
						;parse := InStr(parse, "`n") ? SubStr(parse, 1, InStr(parse, "`n")) : parse
						If InStr(mod, parse)
						{
							If InStr(parse, "chance to bleed")
								MsgBox, % parse "`n" mod
							If (itemchecker_item_class != "simple jewel")
								affix_levels.Push(itemchecker_mod_data[affix_name][outer_loop]["level"])
							Else
							{
								Loop, % itemchecker_mod_data[affix_name][outer_loop]["weights"].Count()
								{
									If LLK_ArrayHasVal(itemchecker_base_item_data[itemchecker_item_base], itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["tag"])
									{
										tier := itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["weight"]
										tier := hybrid ? tier "h" : tier ;MsgBox, % itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["tag"] "`n" itemchecker_mod_data[affix_name][outer_loop]["weights"][A_Index]["weight"]
										Break 2
									}
								}
							}
							;If InStr(parse_loopfield, "(hybrid)")
							;	affix_levels.Push(itemchecker_mod_data[affix_name][outer_loop]["level"])
							Break 2
						}
					}
				}
				If (itemchecker_item_class != "simple jewel") && (affix_levels[loop2] = "")
					affix_levels.Push("?")
				Else If (itemchecker_item_class = "simple jewel") && (tier = "")
					tier := InStr(tier, "h") ? "?h" : "?"
			}
			*/
			
			
			mod1 := (InStr(mod, "adds") || InStr(mod, "added")) && InStr(mod, "to") ? StrReplace(mod, "to", "|",, 1) : mod ;workaround for flat-dmg affixes where x and/or y in 'adds x to y damage' doesn't scale (unique vaal sword, maybe more)
			mods.Push(A_LoopField ";;" tier)
			
			roll := "" ;variable in which to store the numerical values of the affix
			Loop, Parse, % StrReplace(mod1, " (fractured)") ;parse mod-text character by character
			{
				If IsNumber(A_LoopField) || InStr(itemcheck_parse, A_LoopField) ;number or numerical character
					roll .= A_LoopField
			}
			
			If InStr(roll, "(") ;numerical value has scaling
			{
				Loop, Parse, roll, | ;parse numerical value string value by value (in 'adds x to y damage', x and y are values)
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
			affixes.Push(mod ";" roll_qual) ;push mod-text, tier, and roll-values into array
		}
	}
	
	If (loop = 0) && (cluster_type = "")
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
		Gui, itemchecker: Add, Text, % "Section xs Border w"itemchecker_width*5, % " p-dps: " pdps
		Gui, itemchecker: Add, Text, % "ys Border wp", % " c-dps: " cdps
		Gui, itemchecker: Add, Text, % "Section xs Border wp", % " e-dps: " edps0
		Gui, itemchecker: Add, Text, % "ys Border wp", % " total: " tdps
	}
	
	color := (item_lvl >= 86) ? "Green" : "505050" ;highlight ilvl bar green if ilvl >= 86
	
	If !unique ;if item is not unique, determine affix configuration and add bar to visualize it and ilvl
	{
		Gui, itemchecker: Add, Text, % "xs Hidden Border w"itemchecker_width*5, placeholder ;add hidden text label as dummy to get the correct dimensions
		Gui, itemchecker: Add, Progress, xp yp Border Section hp wp range66-86 BackgroundBlack c%color%, % item_lvl ;place progress bar on top of dummy label and inherit dimensions
		Gui, itemchecker: Add, Text, % "xp yp Border BackgroundTrans wp", % " ilvl:" item_lvl ;add actual text label
		
		If InStr(Clipboard, "right click to drink")
			max_affixes := 1
		Else max_affixes := InStr(Clipboard, "Right click to remove from the Socket") ? 2 : 3 ;set max value for the affix bar (4 for jewels, 6 for the rest)
		
		color := (LLK_SubStrCount(Clipboard, "prefix modifier", "`n") < max_affixes) && !InStr(Clipboard, "`nCorrupted", 1) && !InStr(Clipboard, "`nMirrored", 1) ? "Green" : "505050" ;determine bar-color for affixes: green if open affix-slots available
		Gui, itemchecker: Add, Progress, % "ys w"itemchecker_width*2.5 " hp Border BackgroundTrans range0-"max_affixes " BackgroundBlack c"color, % LLK_SubStrCount(Clipboard, "prefix modifier", "`n") ;add prefix bar
		Gui, itemchecker: Add, Text, % "yp xp Center Border BackgroundTrans wp", % itemcheck_prefixes ;add affix text label
		
		color := (LLK_SubStrCount(Clipboard, "suffix modifier", "`n") < max_affixes) && !InStr(Clipboard, "`nCorrupted", 1) && !InStr(Clipboard, "`nMirrored", 1) ? "Green" : "505050" ;determine bar-color for affixes: green if open affix-slots available
		Gui, itemchecker: Add, Progress, % "ys wp hp Border BackgroundTrans range0-"max_affixes " BackgroundBlack c"color, % LLK_SubStrCount(Clipboard, "suffix modifier", "`n") ;add suffix bar
		Gui, itemchecker: Add, Text, % "yp xp Center Border BackgroundTrans wp", % itemcheck_suffixes ;add affix text label
	}
	
	If (corruption_implicits != "")
	{
		loop_corruption := 0
		Loop, Parse, corruption_implicits, `n, `n
		{
			If (A_Index = 1)
				corruption_implicits := ""
			If (SubStr(A_LoopField, 1, 1) = "(")
				continue
			corruption_implicits .= A_LoopField "`n"
		}
		Loop, Parse, corruption_implicits, |, `n
		{
			If (A_LoopField = "")
				continue
			loop_corruption += 1
			parse := SubStr(A_LoopField, InStr(A_LoopField, "`n") + 1)
			parse := StrReplace(parse, " — Unscalable Value")
			Loop, Parse, parse
			{
				If (A_Index = 1)
					parse := ""
				If IsNumber(A_LoopField) || InStr(itemcheck_parse, A_LoopField)
					continue
				parse .= A_LoopField
			}
			parse := (SubStr(parse, 1, 1) = " ") ? SubStr(parse, 2) : parse
			parse := StrReplace(parse, "  ", " ")
			parse := StrReplace(parse, "`n ", "`n")
			parse := StrReplace(parse, ", with increased effect")
			
			If (LLK_ItemCheckHighlight(StrReplace(parse, "`n", ";")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "White"
			Else color := (LLK_ItemCheckHighlight(StrReplace(parse, "`n", ";")) = 1) ? "00eeee" : "Red" ;determine which is the case
			
			Gui, itemchecker: Add, Text, % "xs Hidden Center Border w"itemchecker_width*10, % parse ;add hidden text label as dummy to get the correct dimensions
			Gui, itemchecker: Add, Progress, xp yp Border Disabled Section hp wp Background390000, 0
			Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp gItemchecker vitemchecker_corruption_implicit"loop_corruption " HWNDhwnd_itemchecker_corruption_implicit"loop_corruption " c"color, % parse
		}
	}
	
	If (cluster_type != "") ;if item is a cluster jewel, add passive-skills and enchant info
	{
		color := (cluster_passives >= cluster_passives_optimal) ? "Green" : "505050"
		Gui, itemchecker: Add, Text, % "xs Hidden Border w"itemchecker_width*10, placeholder ;add hidden text label as dummy to get the correct dimensions
		Gui, itemchecker: Add, Progress, xp yp Border Disabled Section hp wp range%cluster_passives_max%-%cluster_passives_optimal% BackgroundBlack c%color%, % cluster_passives ;place progress bar on top of dummy label and inherit dimensions
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp", % " passive skills: " cluster_passives*(-1) "(" cluster_passives_min "-" cluster_passives_max*(-1) ")" ;add actual text label
		
		If (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
			color := "White"
		Else color := (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";")) = 1) ? "00eeee" : "Red" ;determine which is the case
		Gui, itemchecker: Add, Text, % "xs Border Center BackgroundTrans vitemchecker_panel_cluster HWNDhwnd_itemchecker_panel_cluster gItemchecker wp c"color, % cluster_enchant ;add actual text label
	}
	
	affix_heights := [] ;array to store the heights of the individual lines
	
	Loop, % affixes.Count() ;n = number of parsed mod lines
	{
		style := !unique ? "w"itemchecker_width*9 : "w"itemchecker_width*10 ;width of the mod list: non-unique list is narrower for extra tier-column on the far right
		
		Loop, Parse, % affixes[A_Index], % ";" ;parse info from current array entry
		{
			Switch A_Index
			{
				Case 1:
					mod := A_LoopField
				Case 2:
					quality := A_LoopField
			}
		}
		
		If !InStr(mod, "(") && unique ;!InStr(mod, "(hybrid)") && unique ;skip unscalable values within hybrid affixes
			continue
		
		hybrid += (hybrid = 0 || hybrid = "") && InStr(mod, "[hybrid]") ? 1 : 0
		
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
		mod_text := StrReplace(mod, "[hybrid]")
		Gui, itemchecker: Add, Text, % (A_Index = 1) ? "Section xs Border hidden "style : "xs Border hidden "style, % StrReplace(mod_text, " (fractured)") ;add dummy text label for dimensions
		
		;add progress bar and inherit dimensions from dummy label
		Gui, itemchecker: Add, Progress, % (A_Index = 1) ? "xp yp Section Disabled Border hp wp range" lower_bound "-" upper_bound " BackgroundBlack c"color : "xp yp hp wp Disabled Border range" lower_bound "-" upper_bound " BackgroundBlack c"color, % value
		
		If !unique
		{
			If (LLK_ItemCheckHighlight(StrReplace(mod_text, " (fractured)")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "White"
			Else color := (LLK_ItemCheckHighlight(StrReplace(mod_text, " (fractured)")) = 1) ? "00eeee" : "Red" ;determine which is the case
		}
		Else color := "White" ;uniques always have white text
		
		If !unique
			Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% gItemchecker %style% Border HWNDhwnd_itemchecker_panel%A_Index% BackgroundTrans xp yp, % StrReplace(mod_text, " (fractured)") ;non-unique items have clickable mod-texts for highlighting/blacklisting
		Else Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% %style% Border BackgroundTrans xp yp, % mod_text ;unique items don't need that
		GuiControlGet, itemchecker_, Pos, % hwnd_itemchecker_panel%A_Index%
		
		affix_heights.Push(itemchecker_h)
	}
	
	hybrid := 0
	
	Loop, % affix_tiers.Count()
	{
		loop := A_Index
		affix_name := SubStr(affix_tiers[A_Index], 1, InStr(affix_tiers[A_Index], ",") - 1)
		;tier := SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1)
		tier := StrReplace(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "*")
		tier := StrReplace(tier, "f")
		If (hybrid != 0)
		{
			hybrid -= 1
			continue
		}
		If InStr(affix_tiers[A_Index], "*") && InStr(affix_tiers[A_Index + 1], affix_name)
			hybrid += (InStr(affix_tiers[A_Index +2], affix_name) && ((affix_tiers[A_Index + 3] != "") && !InStr(affix_tiers[A_Index + 3], affix_name))) ? 2 : 1
		If (itemchecker_item_class != "base jewel")
		{
			Switch tier ;set correct highlight color according to tier
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
		}
		Else
		{
			If (tier = 100) || (tier = 150)
			{
				color := "e3f2fd"
				color1 := "Black"
			}
			Else If (tier = 200) || (tier = 250)
			{
				color := "90caf9"
				color1 := "Black"
			}
			Else If (tier = 300) || (tier = 350)
			{
				color := "42a5f5"
				color1 := "Black"
			}
			Else If (tier = 400) || (tier = 450)
			{
				color := "1e88e5"
				color1 := "White"
			}
			Else If (tier = 500)
			{
				color := "1565c0"
				color1 := "White"
			}
		}
		
		If !unique
		{
			If (tier = 0) || InStr(affix_tiers[A_Index], "chosen") || InStr(affix_tiers[A_Index], "subterranean") || InStr(affix_tiers[A_Index], "of the underground") || InStr(affix_tiers[A_Index], "veil")
			{
				color := itemchecker_t0_color
				tier := 0
			}
			If InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ;override color in case mod is fractured
				color := itemchecker_t7_color
			color1 := (itemchecker_item_class != "base jewel") ? "Black" : InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ? "Black" : "White"
			width := enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel") ? itemchecker_width/2 : itemchecker_width
			If (hybrid = 2)
				height := affix_heights[A_Index] + affix_heights[A_Index + 1] + affix_heights[A_Index + 2]
			Else height := (hybrid = 1) ? affix_heights[A_Index] + affix_heights[A_Index + 1] : affix_heights[A_Index]
			style := (A_Index = 1) ? "section ys " : "Section xs "
			Gui, itemchecker: Add, Progress, % style "h"height " w"width " BackgroundBlack Border c"color, 100 ;add colored progress bar as background for tier-column
			Gui, itemchecker: Add, Text, % "yp xp 0x200 Border Center cBlack hp wp BackgroundTrans", % tier ;add number label to tier-column
			;If (itemchecker_item_class != "base jewel")
			;	Gui, itemchecker: Add, Text, ys Border Center hp wp BackgroundTrans, % affix_levels[A_Index] ;add number label to tier-column
			
			If enable_itemchecker_ilvl && !enable_itemchecker_dynamic && (itemchecker_item_class != "base jewel")
			{
				level := affix_levels[A_Index]
				If (level >= 83)
					color := itemchecker_ilvl1_color
				Else If (level >= 78)
					color := itemchecker_ilvl2_color
				Else If (level >= 73)
					color := itemchecker_ilvl3_color
				Else If (level >= 68)
					color := itemchecker_ilvl4_color
				Else If (level >= 64)
					color := itemchecker_ilvl5_color
				Else If (level >= 60)
					color := itemchecker_ilvl6_color
				Else If (level <= 59)
					color := itemchecker_ilvl7_color
				Else If (level <= 55)
					color := itemchecker_ilvl8_color
				
				If (tier = 0) || InStr(affix_tiers[A_Index], "chosen") || InStr(affix_tiers[A_Index], "subterranean") || InStr(affix_tiers[A_Index], "of the underground") || InStr(affix_tiers[A_Index], "veil")
					color := itemchecker_t0_color
				If InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ;override color in case mod is fractured
					color := itemchecker_t7_color
				
				If (hybrid = 2)
					height := affix_heights[A_Index] + affix_heights[A_Index + 1] + affix_heights[A_Index + 2]
				Else height := (hybrid = 1) ? affix_heights[A_Index] + affix_heights[A_Index + 1] : affix_heights[A_Index]
				
				Gui, itemchecker: Add, Progress, % "ys h"height " w"itemchecker_width/2 " BackgroundBlack Border c"color, 100 ;add colored progress bar as background for tier-column
				color1 := (level >= 83) && (color = "ffffff") ? "Red" : "Black"
				Gui, itemchecker: Add, Text, % "yp xp 0x200 Border Center c"color1 " hp wp BackgroundTrans", % affix_levels[A_Index] ;add number label to tier-column
			}
		}
	}
	
	Gui, itemchecker: Show, NA x10000 y10000 ;show GUI outside of monitor
	WinGetPos,,, width, height, ahk_id %hwnd_itemchecker% ;get GUI position and dimensions
	MouseGetPos, mouseXpos, mouseYpos
	mouseXpos := (config != 0) ? xPos_itemchecker + width + poe_height*0.047*0.5 : mouseXpos ;override cursor-position if feature is being configured in settings menu
	mouseYpos := (config != 0) ? yPos_itemchecker + height + poe_height*0.047*0.5 : mouseYpos
	winXpos := (mouseXpos - poe_height*0.047*0.5 - width < xScreenOffSet) ? xScreenOffSet : mouseXpos - width - poe_height*0.047*0.5 ;reposition coordinates in case tooltip would land outside monitor area
	winYpos := (mouseypos - poe_height*0.047*0.5 - height < yScreenOffSet) ? yScreenOffSet : mouseYpos - height - poe_height*0.047*0.5
	Gui, itemchecker: Show, % "NA x"winXpos " y"winYpos ;show GUI next to cursor
	LLK_Overlay("itemchecker", "show") ;trigger GUI for auto-hiding when alt-tabbed
}

LLK_ItemCheckClose()
{
	global
	Gui, itemchecker: Destroy
	hwnd_itemchecker := ""
	hwnd_itemchecker_panel_cluster := ""
	Loop
	{
		If (hwnd_itemchecker_panel%A_Index% = "")
			break
		hwnd_itemchecker_panel%A_Index% := ""
	}
	Loop
	{
		If (hwnd_itemchecker_corruption_implicit%A_Index% = "")
			break
		hwnd_itemchecker_corruption_implicit%A_Index% := ""
	}
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
	
	string := StrReplace(string, "`n ", "`n")
	string := StrReplace(string, "`n", ";")
	
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
	MouseGetPos, itemchecker_vendor_mouseX, itemchecker_vendor_mouseY, itemchecker_win_hover, itemchecker_control_hover, 2
	itemchecker_highlightable := 0
	
	Loop
	{
		If (hwnd_itemchecker_panel%A_Index% = "") && (hwnd_itemchecker_corruption_implicit%A_Index% = "") && (hwnd_itemchecker_panel_cluster = "")
			break
		If (itemchecker_control_hover = hwnd_itemchecker_panel%A_Index%) || (itemchecker_control_hover = hwnd_itemchecker_corruption_implicit%A_Index%) || (itemchecker_control_hover = hwnd_itemchecker_panel_cluster)
		{
			itemchecker_highlightable := 1
			break
		}
	}
	
	If !itemchecker_highlightable
	{
		WinActivate, ahk_group poe_window
		Return
	}
	
	If (itemchecker_win_hover = hwnd_itemchecker)
	{
		GuiControlGet, itemchecker_panel_text,, % itemchecker_control_hover
		itemchecker_errorlvl := LLK_ItemCheckHighlight(itemchecker_panel_text, 2)
		Switch itemchecker_errorlvl
		{
			Case -1:
				Return
			Case 0:
				color := "White"
			Case 1:
				color := "Red"
		}
		GuiControl, +c%color%, %itemchecker_control_hover%
		WinSet, Redraw,, ahk_id %hwnd_itemchecker%
		Return
	}
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