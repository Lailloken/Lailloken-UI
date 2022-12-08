Init_itemchecker:
IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
IniRead, itemchecker_highlight_implicits, ini\item-checker.ini, settings, highlighted implicits, %A_Space%
IniRead, itemchecker_blacklist_implicits, ini\item-checker.ini, settings, blacklisted implicits, %A_Space%

IniRead, enable_itemchecker_ID, ini\item-checker.ini, settings, enable wisdom-scroll trigger, 0
IniRead, enable_itemchecker_ilvl, ini\item-checker.ini, Settings, enable item-levels, 0
IniRead, enable_itemchecker_bases, ini\item-checker.ini, Settings, enable base-info, 1
IniRead, enable_itemchecker_dps, ini\item-checker.ini, Settings, selective dps, 0
IniRead, enable_itemchecker_override, ini\item-checker.ini, Settings, enable blacklist-override, 0
IniRead, enable_itemchecker_gear, ini\item-checker.ini, Settings, enable gear-tracking, 0

Loop, Parse, gear_slots, `,
	IniRead, equipped_%A_LoopField%, ini\item-checker gear.ini, % A_LoopField,, % A_Space

If enable_itemchecker_gear
	enable_itemchecker_bases := 0, enable_itemchecker_dps := 0

itemchecker_gear_baseline := poe_height * (443/720) - 1
;itemchecker_gear_height_icon := Format("{:0.0f}", poe_height*0.047*0.5)

Loop, Parse, gear_slots, `,
{
	IniRead, %A_LoopField%_coords, ini\item-checker.ini, UI, %A_LoopField% coords, 0`,0
	Switch A_LoopField
	{
		Case "mainhand":
			%A_LoopField%_x_offset := poe_height * (1/16)
			%A_LoopField%_y_offset := poe_height * (1/9)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (1/5)
		Case "offhand":
			%A_LoopField%_x_offset := poe_height * (107/240)
			%A_LoopField%_y_offset := poe_height * (1/9)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (1/5)
		Case "helmet":
			%A_LoopField%_x_offset := poe_height * (23/90)
			%A_LoopField%_y_offset := poe_height * (7/72)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (5/48)
		Case "body":
			%A_LoopField%_x_offset := poe_height * (23/90)
			%A_LoopField%_y_offset := poe_height * (5/24)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (11/72)
		Case "amulet":
			%A_LoopField%_x_offset := poe_height * (3/8)
			%A_LoopField%_y_offset := poe_height * (7/36)
			%A_LoopField%_width := poe_height * (1/18)
			%A_LoopField%_height := poe_height * (1/18)
		Case "ring1":
			%A_LoopField%_x_offset := poe_height * (11/60)
			%A_LoopField%_y_offset := poe_height * (23/90)
			%A_LoopField%_width := poe_height * (1/18)
			%A_LoopField%_height := poe_height * (1/18)
		Case "ring2":
			%A_LoopField%_x_offset := poe_height * (3/8)
			%A_LoopField%_y_offset := poe_height * (23/90)
			%A_LoopField%_width := poe_height * (1/18)
			%A_LoopField%_height := poe_height * (1/18)
		Case "belt":
			%A_LoopField%_x_offset := poe_height * (23/90)
			%A_LoopField%_y_offset := poe_height * (35/96)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (1/18)
		Case "gloves":
			%A_LoopField%_x_offset := poe_height * (13/96)
			%A_LoopField%_y_offset := poe_height * (91/288)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (5/48)
		Case "boots":
			%A_LoopField%_x_offset := poe_height * (3/8)
			%A_LoopField%_y_offset := poe_height * (91/288)
			%A_LoopField%_width := poe_height * (5/48)
			%A_LoopField%_height := poe_height * (5/48)
	}
	If (%A_LoopField%_coords != "0,0")
	{
		%A_LoopField%_x_offset := SubStr(%A_LoopField%_coords, 1, InStr(%A_LoopField%_coords, ",") -1)
		%A_LoopField%_y_offset := SubStr(%A_LoopField%_coords, InStr(%A_LoopField%_coords, ",") + 1)
	}
	%A_LoopField%_xcoord1 := xScreenOffSet + poe_width - itemchecker_gear_baseline + %A_LoopField%_x_offset
	%A_LoopField%_xcoord2 := xScreenOffSet + poe_width - 1 - itemchecker_gear_baseline + %A_LoopField%_x_offset + %A_LoopField%_width
	%A_LoopField%_ycoord1 := yScreenOffSet + %A_LoopField%_y_offset
	%A_LoopField%_ycoord2 := yScreenOffSet + %A_LoopField%_y_offset - 1 + %A_LoopField%_height
}

IniRead, enable_itemchecker_rule_weapon_res, ini\item-checker.ini, Settings, weapon res override, 0
IniRead, enable_itemchecker_rule_spells, ini\item-checker.ini, Settings, spells override, 0
IniRead, enable_itemchecker_rule_res, ini\item-checker.ini, Settings, res override, 0
IniRead, enable_itemchecker_rule_attacks, ini\item-checker.ini, Settings, attacks override, 0
IniRead, enable_itemchecker_rule_lifemana_gain, ini\item-checker.ini, Settings, lifemana gain override, 0
IniRead, enable_itemchecker_rule_crit, ini\item-checker.ini, Settings, crit override, 0

IniRead, fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset, 0
itemchecker_default_colors := ["3399ff", "00bb00", "008000", "ffff00", "ff8c00", "ff4040", "aa0000", "00eeee"]
itemchecker_default_colors_ilvl := ["ffffff", "00bb00", "008000", "ffff00", "ff8c00", "ff4040", "aa0000", "ff00ff", "800080"]
itemchecker_default_ilvls := ["83+", "78+", "73+", "68+", "64+", "60+", "56+", "56>"]
IniRead, itemchecker_t0_color, ini\item-checker.ini, UI, tier 0, % "3399ff"
IniRead, itemchecker_t1_color, ini\item-checker.ini, UI, tier 1, % "00bb00"
IniRead, itemchecker_t2_color, ini\item-checker.ini, UI, tier 2, % "008000"
IniRead, itemchecker_t3_color, ini\item-checker.ini, UI, tier 3, % "ffff00"
IniRead, itemchecker_t4_color, ini\item-checker.ini, UI, tier 4, % "ff8c00"
IniRead, itemchecker_t5_color, ini\item-checker.ini, UI, tier 5, % "ff4040"
IniRead, itemchecker_t6_color, ini\item-checker.ini, UI, tier 6, % "aa0000"
IniRead, itemchecker_t7_color, ini\item-checker.ini, UI, fractured, % "00eeee"

IniRead, itemchecker_ilvl1_color, ini\item-checker.ini, UI, ilvl tier 1, % "ffffff"
IniRead, itemchecker_ilvl2_color, ini\item-checker.ini, UI, ilvl tier 2, % "00bb00"
IniRead, itemchecker_ilvl3_color, ini\item-checker.ini, UI, ilvl tier 3, % "008000"
IniRead, itemchecker_ilvl4_color, ini\item-checker.ini, UI, ilvl tier 4, % "ffff00"
IniRead, itemchecker_ilvl5_color, ini\item-checker.ini, UI, ilvl tier 5, % "ff8c00"
IniRead, itemchecker_ilvl6_color, ini\item-checker.ini, UI, ilvl tier 6, % "ff4040"
IniRead, itemchecker_ilvl7_color, ini\item-checker.ini, UI, ilvl tier 7, % "aa0000"
IniRead, itemchecker_ilvl8_color, ini\item-checker.ini, UI, ilvl tier 8, % "ff00ff"
itemchecker_width := 0
itemchecker_height := 0
Return

Itemchecker:
;Function quick-jump: LLK_ItemCheck(), LLK_ItemCheckHighlight()
start := A_TickCount
If (A_Gui = "itemchecker") || ((A_Gui = "") && (A_GuiControl = "") && (shift_down = "wisdom") && (click = 2)) ;an item mod was clicked
{
	implicit_highlight := InStr(control_name_checkvendor, "implicit") || InStr(control_name_checkvendor, "cluster") || InStr(A_GuiControl, "implicit") || (InStr(A_GuiControl, "cluster")) ? 1 : 0
	control_name_checkvendor := ""
	If (A_Gui = "itemchecker")
		GuiControlGet, itemchecker_mod,, % A_GuiControl "_text"
	Else If ((A_Gui = "") && (A_GuiControl = "") && (shift_down = "wisdom") && (click = 2))
	{
		MouseGetPos, itemchecker_vendor_mouseX, itemchecker_vendor_mouseY, itemchecker_win_hover, itemchecker_control_hover, 2
		GuiControlGet, control_name_checkvendor, name, % itemchecker_control_hover
		GuiControlGet, itemchecker_mod,, % hwnd_%control_name_checkvendor%_text
	}
	If (LLK_ItemCheckHighlight(StrReplace(itemchecker_mod, " (fractured)"), click, implicit_highlight) = -1)
		Return
	
	If (hwnd_itemchecker_cluster_text != "")
	{
		GuiControlGet, itemchecker_mod,, % hwnd_itemchecker_cluster_text
		If (LLK_ItemCheckHighlight(itemchecker_mod, 0, implicit_highlight) = 0)
		{
			color := "Black"
			color1 := "White"
		}
		Else
		{
			color := (LLK_ItemCheckHighlight(itemchecker_mod, 0, implicit_highlight) = 1) ? itemchecker_t1_color : itemchecker_t6_color
			color1 := "Black"
		}
		GuiControl, itemchecker: +c%color%, itemchecker_cluster_button
		GuiControl, itemchecker: +c%color%, itemchecker_cluster_button1
		GuiControl, itemchecker: +c%color1%, itemchecker_cluster_text
	}
	Loop
	{
		If (hwnd_itemchecker_implicit%A_Index%_text = "")
			Break
		GuiControlGet, itemchecker_mod,, % hwnd_itemchecker_implicit%A_Index%_text
		If (LLK_ItemCheckHighlight(itemchecker_mod, 0, 1) = 0)
		{
			color := "Black"
			color1 := "White"
		}
		Else
		{
			color := (LLK_ItemCheckHighlight(itemchecker_mod, 0, 1) = 1) ? itemchecker_t1_color : itemchecker_t6_color
			color1 := "Black"
		}
		GuiControl, itemchecker: +c%color%, itemchecker_implicit%A_Index%_button
		GuiControl, itemchecker: +c%color%, itemchecker_implicit%A_Index%_button1
		GuiControl, itemchecker: +c%color1%, itemchecker_implicit%A_Index%_text
	}
	Loop, % affixes.Count()
	{
		mod_check := SubStr(StrReplace(affixes[A_Index], "[hybrid]"), 1, InStr(StrReplace(affixes[A_Index], "[hybrid]"), ";") -1)
		mod_check := StrReplace(mod_check, " (fractured)")
		mod_check := StrReplace(mod_check, " (crafted)")
		If (LLK_ItemCheckHighlight(mod_check, 0, 0) = 0)
			color := "Black"
		Else color := LLK_ItemCheckHighlight(mod_check, 0, 0) = 1 ? itemchecker_t1_color : itemchecker_t6_color
		GuiControl, itemchecker: +c%color%, itemchecker_panel%A_Index%_button
	}
	WinSet, Redraw,, ahk_id %hwnd_itemchecker%
	;WinActivate, ahk_group poe_window
	Return
}

While InStr(A_Gui, "itemchecker_gear_") && GetKeyState("LButton", "P")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		parse := StrReplace(A_Gui, "itemchecker_gear_")
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		panelXpos := panelXpos - (poe_width - itemchecker_gear_baseline)
		IniWrite, % panelXpos "," panelYpos, ini\item-checker.ini, UI, % parse " coords"
		GoSub, Init_itemchecker
		Return
	}
}

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

If InStr(A_GuiControl, "_color") && !InStr(A_GuiControl, "apply") ;a highlight-panel was clicked
{
	If (StrLen(Clipboard) != 6) && (click = 1)
	{
		LLK_ToolTip("invalid rgb-code in clipboard", 1.5)
		Return
	}
	color := (click = 1) ? Clipboard : color
	value := InStr(A_GuiControl, "_t") ? StrReplace(A_GuiControl, "itemchecker_t") : StrReplace(A_GuiControl, "itemchecker_ilvl")
	value := StrReplace(value, "_color")
	
	If InStr(A_GuiControl, "_t")
		color_value := value + 1
	Else color_value := value
	
	GuiControl, settings_menu: +cRed, itemchecker_apply_color
	If (click = 1)
		GuiControl, % "settings_menu: +c"color, % InStr(A_GuiControl, "_t") ? "itemchecker_bar"value : "itemchecker_bar_ilvl"value
	Else
	{
		color := InStr(A_GuiControl, "_t") ? itemchecker_default_colors[color_value] : itemchecker_default_colors_ilvl[color_value]
		GuiControl, % "settings_menu: +c"color, % InStr(A_GuiControl, "_t") ? "itemchecker_bar"value : "itemchecker_bar_ilvl"value
	}
	
	If InStr(A_GuiControl, "_t")
		itemchecker_t%value%_color := (click = 1) ? color : itemchecker_default_colors[color_value]
	Else itemchecker_ilvl%value%_color := (click = 1) ? color : itemchecker_default_colors_ilvl[color_value]
	
	If InStr(A_GuiControl, "_ilvl")
	{
		If (color = "ffffff") && (value = 1)
			GuiControl, settings_menu: +cRed, itemchecker_ilvl%value%_color,
		Else GuiControl, settings_menu: +cBlack, itemchecker_ilvl%value%_color,
	}
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Return
}

If (A_GuiControl = "itemchecker_apply_color") ;save-button was clicked
{
	GuiControl, settings_menu: +cWhite, itemchecker_apply_color
	WinSet, Redraw,, ahk_id %hwnd_settings_menu%
	Loop 8
	{
		value := A_Index - 1
		StringLower, itemchecker_t%value%_color, itemchecker_t%value%_color
		IniWrite, % itemchecker_t%value%_color, ini\item-checker.ini, UI, % (A_Index = 8) ? "fractured" : "tier " value
		If enable_itemchecker_ilvl
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

If (A_GuiControl = "enable_itemchecker_bases")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_bases, ini\item-checker.ini, Settings, enable base-info
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If (A_GuiControl = "enable_itemchecker_dps")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_dps, ini\item-checker.ini, Settings, selective dps
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
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

If (A_GuiControl = "enable_itemchecker_override")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_override, ini\item-checker.ini, Settings, enable blacklist-override
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	;Gosub, settings_menu
	Return
}

If (A_GuiControl = "enable_itemchecker_gear")
{
	If (pixel_inventory_color1 = "")
	{
		GuiControl, settings_menu:, %A_GuiControl%, 0
		LLK_ToolTip("pixel-check setup required", 1.5)
		Return
	}
	SetTimer, MainLoop, Off
	Gui, settings_menu: Submit, NoHide
	IniWrite, % enable_itemchecker_gear, ini\item-checker.ini, Settings, enable gear-tracking
	If enable_itemchecker_gear
	{
		;enable_itemchecker_ilvl := 0
		enable_itemchecker_bases := 0
		enable_itemchecker_dps := 0
		;GuiControl, settings_menu:, enable_itemchecker_ilvl, 0
		GuiControl, settings_menu:, enable_itemchecker_bases, 0
		GuiControl, settings_menu:, enable_itemchecker_dps, 0
	}
	Else GoSub, Init_itemchecker
	GoSub, Settings_menu
	Gosub, GUI
	Sleep, 100
	SetTimer, MainLoop, On
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If InStr(A_GuiControl, "itemchecker_reset_")
{
	type := StrReplace(A_GuiControl, "itemchecker_reset_")
	SetTimer, MainLoop, Off
	If LLK_ProgressBar("settings_menu", "itemchecker_reset_"type "_bar")
	{
		If GetKeyState("LButton", "P")
		{
			Switch type
			{
				Case "gear":
					Loop, Parse, gear_slots, `,
					{
						IniDelete, ini\item-checker.ini, UI, %A_LoopField% coords
					}
					LLK_ToolTip("layout reset")
					GoSub, Init_itemchecker
					GoSub, GUI
				Default:
				itemchecker_%type% := ""
				itemchecker_%type%_implicits := ""
				IniWrite, % itemchecker_%type%, ini\item-checker.ini, settings, %type%ed mods
				IniWrite, % itemchecker_%type%_implicits, ini\item-checker.ini, settings, %type%ed implicits
				LLK_ToolTip("list cleared")
				If WinExist("ahk_id " hwnd_itemchecker)
					LLK_ItemCheck(1)
			}
			KeyWait, LButton
		}
	}
	SetTimer, MainLoop, On
	Return
}

If InStr(A_GuiControl, "enable_itemchecker_rule_")
{
	Gui, settings_menu: Submit, NoHide
	value := StrReplace(StrReplace(A_GuiControl, "enable_itemchecker_rule_"), "_", " ") " override"
	IniWrite, % %A_GuiControl%, ini\item-checker.ini, settings, % value
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
}
Return

LLK_ItemCheck(config := 0) ;parse item-info and create tooltip GUI
{
	global affixes := [], affix_tiers := [], affix_levels := [], gear_slots
	global itemchecker_mod_data, itemchecker_base_item_data, itemchecker_width, itemchecker_height, enable_itemchecker_ilvl, enable_itemchecker_override, enable_itemchecker_bases, enable_itemchecker_dps, enable_itemchecker_gear
	global itemchecker_t0_color, itemchecker_t1_color, itemchecker_t2_color, itemchecker_t3_color, itemchecker_t4_color, itemchecker_t5_color, itemchecker_t6_color, itemchecker_t7_color
	global itemchecker_ilvl0_color, itemchecker_ilvl1_color, itemchecker_ilvl2_color, itemchecker_ilvl3_color, itemchecker_ilvl4_color, itemchecker_ilvl5_color, itemchecker_ilvl6_color, itemchecker_ilvl7_color, itemchecker_ilvl8_color
	global itemchecker_cluster, itemchecker_cluster_text, itemchecker_cluster_button, itemchecker_cluster_button1
	global ThisHotkey_copy, fSize0, xScreenOffSet, yScreenOffset, poe_height, poe_width, hwnd_itemchecker, fSize_offset_itemchecker, xPos_itemchecker, yPos_itemchecker, shift_down, itemchecker_clipboard
	global itemchecker_panel1, itemchecker_panel2, itemchecker_panel3, itemchecker_panel4, itemchecker_panel5, itemchecker_panel6, itemchecker_panel7, itemchecker_panel8, itemchecker_panel9, itemchecker_panel10, itemchecker_panel11, itemchecker_panel12, itemchecker_panel13, itemchecker_panel14, itemchecker_panel15
	global itemchecker_panel1_text, itemchecker_panel2_text, itemchecker_panel3_text, itemchecker_panel4_text, itemchecker_panel5_text, itemchecker_panel6_text, itemchecker_panel7_text, itemchecker_panel8_text, itemchecker_panel9_text, itemchecker_panel10_text, itemchecker_panel11_text, itemchecker_panel12_text, itemchecker_panel13_text, itemchecker_panel14_text, itemchecker_panel15_text
	global itemchecker_panel1_button, itemchecker_panel2_button, itemchecker_panel3_button, itemchecker_panel4_button, itemchecker_panel5_button, itemchecker_panel6_button, itemchecker_panel7_button, itemchecker_panel8_button, itemchecker_panel9_button, itemchecker_panel10_button, itemchecker_panel11_button, itemchecker_panel12_button, itemchecker_panel13_button, itemchecker_panel14_button, itemchecker_panel15_button
	global itemchecker_tier1_button, itemchecker_tier2_button, itemchecker_tier3_button, itemchecker_tier4_button, itemchecker_tier5_button, itemchecker_tier6_button, itemchecker_tier7_button, itemchecker_tier8_button, itemchecker_tier9_button, itemchecker_tier10_button, itemchecker_tier11_button, itemchecker_tier12_button, itemchecker_tier13_button, itemchecker_tier14_button, itemchecker_tier15_button
	global itemchecker_ilvl1_button, itemchecker_ilvl2_button, itemchecker_ilvl3_button, itemchecker_ilvl4_button, itemchecker_ilvl5_button, itemchecker_ilvl6_button, itemchecker_ilvl7_button, itemchecker_ilvl8_button, itemchecker_ilvl9_button, itemchecker_ilvl10_button, itemchecker_ilvl11_button, itemchecker_ilvl12_button, itemchecker_ilvl13_button, itemchecker_ilvl14_button, itemchecker_ilvl15_button
	global itemchecker_implicit1, itemchecker_implicit2, itemchecker_implicit3, itemchecker_implicit4, itemchecker_implicit5, itemchecker_implicit6
	global itemchecker_implicit1_text, itemchecker_implicit2_text, itemchecker_implicit3_text, itemchecker_implicit4_text, itemchecker_implicit5_text, itemchecker_implicit6_text
	global itemchecker_implicit1_button, itemchecker_implicit2_button, itemchecker_implicit3_button, itemchecker_implicit4_button, itemchecker_implicit5_button, itemchecker_implicit6_button
	global itemchecker_implicit1_button1, itemchecker_implicit2_button1, itemchecker_implicit3_button1, itemchecker_implicit4_button1, itemchecker_implicit5_button1, itemchecker_implicit6_button1
	global itemchecker_gear_mainhand, itemchecker_gear_offhand, itemchecker_gear_helmet, itemchecker_gear_body, itemchecker_gear_amulet, itemchecker_gear_belt, itemchecker_gear_ring1, itemchecker_gear_ring2, itemchecker_gear_boots, itemchecker_gear_gloves
	global equipped_mainhand, equipped_offhand, equipped_helmet, equipped_body, equipped_amulet, equipped_ring1, equipped_ring2, equipped_gloves, equipped_boots, equipped_belt
	
	If (itemchecker_width = 0)
	{
		Gui, itemchecker_width: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker_width
		Gui, itemchecker_width: Margin, 0, 0
		Gui, itemchecker_width: Color, Black
		Gui, itemchecker_width: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
		Gui, itemchecker_width: Add, Text, % "Border HWNDmain_text", % "77777"
		GuiControlGet, itemchecker_, Pos, % main_text
		While (Mod(itemchecker_w, 4) != 0)
			itemchecker_w += 1
		;While (Mod(itemchecker_h, 2) != 0)
		;	itemchecker_h += 1
		width_margin := itemchecker_w//16
		While (Mod(width_margin, 4) != 0)
			width_margin += 1
		itemchecker_width := itemchecker_w + width_margin
		itemchecker_height := itemchecker_h
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
	
	Loop, Parse, Clipboard, `n, `r
	{
		If InStr(A_LoopField, "armour: ")
		{
			armor := StrReplace(A_LoopField, " (augmented)")
			armor := SubStr(armor, 9)
			defenses .= "armor,"
		}
		If InStr(A_LoopField, "evasion rating: ")
		{
			evasion := StrReplace(A_LoopField, " (augmented)")
			evasion := SubStr(evasion, 17)
			defenses .= "evasion,"
		}
		If InStr(A_LoopField, "energy shield: ")
		{
			energy := StrReplace(A_LoopField, " (augmented)")
			energy := SubStr(energy, 16)
			defenses .= "energy,"
		}
		If InStr(A_LoopField, "ward: ")
		{
			ward := StrReplace(A_LoopField, " (augmented)")
			ward := SubStr(ward, 7)
			defenses .= "ward,"
		}
		If InStr(A_LoopField, "requirements: ")
			break
	}
	
	Loop, Parse, defenses, `,
	{
		If (A_Index = 1)
			defenses := ""
		If (A_LoopField = "")
			continue
		defenses .= A_LoopField "=" %A_LoopField% "`n"
	}
	
	If InStr(Clipboard, "attacks per second: ")
		item_type := "attack"
	Else If InStr(Clipboard, "armour: ") || InStr(Clipboard, "evasion rating: ") || InStr(Clipboard, "energy shield: ") || InStr(Clipboard, "ward: ")
		item_type := "defense"
	Else If InStr(Clipboard, "item class: rings") || InStr(Clipboard, "item class: amulets") || InStr(Clipboard, "item class: belts") || (InStr(SubStr(Clipboard, InStr(Clipboard, "item class: "), 40), "item class: ") && InStr(SubStr(Clipboard, InStr(Clipboard, "item class: "), 40), "Jewels", 1))
		item_type := "jewelry"
	
	If InStr(Clipboard, "`nUnidentified", 1) || InStr(Clipboard, "`nUnmodifiable", 1) || InStr(Clipboard, "`nRarity: Gem", 1) || (InStr(Clipboard, "`nRarity: Normal", 1) && !InStr(Clipboard, "cluster jewel")) || InStr(Clipboard, "`nRarity: Currency", 1) || InStr(Clipboard, "`nRarity: Divination Card", 1) || InStr(Clipboard, "item class: pieces") || InStr(Clipboard, "item class: maps") || InStr(Clipboard, "item class: contracts") || InStr(Clipboard, "timeless jewel") ;certain exclusion criteria
	{
		LLK_ToolTip("item-info: item not supported")
		Return
	}
	
	If (!InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier")) && !(InStr(Clipboard, "`nRarity: Normal", 1) && InStr(Clipboard, "cluster jewel")) ;could not copy advanced item-info
	{
		LLK_ToolTip("item-info: omni-key setup required (?)", 2)
		Return
	}
	
	LLK_ItemCheckClose()
	
	item_lvl_max := 86
	item_stats_array := []
	For key, val in itemchecker_base_item_data
	{
		If InStr(itemchecker_metadata, key) && (InStr(itemchecker_metadata, " " key) || InStr(itemchecker_metadata, key " ") || InStr(itemchecker_metadata, "`n" key) || InStr(itemchecker_metadata, key "`n"))
		{
			If (item_type = "defense")
			{
				For defense_stat, defense_value in val.properties
				{
					If (defense_stat = "block")
					{
						block := 1
						continue
					}
					item_stats .= (item_stats = "") ? defense_stat : "_" defense_stat
					item_stats_array.Push(defense_stat)
					base_best_%defense_stat% := defense_value
					base_best_combined += defense_value
					class_best_%defense_stat% := val.properties_best[defense_stat]
					class_best_combined := val.properties_best["combined"]
				}
				If (item_stats_array.Count() = 2)
					item_stats_array.Push("combined")
				If (block = 1)
				{
					item_stats_array.Push("block")
					base_best_block := val.properties.block
					class_best_block := val.properties_best.block
					item_block_rel := Format("{:0.0f}", base_best_block/class_best_block*100)
				}
			}
			If (item_type = "attack")
			{
				For attack_stat, attack_value in val.properties
				{
					If (attack_stat = "range")
						continue
					item_stats_array.Push(attack_stat)
					base_best_%attack_stat% := (attack_stat != "attack_time") ? attack_value : Format("{:0.2f}", 1000/attack_value)
					class_best_%attack_stat% := (attack_stat != "attack_time") ? val.properties_best[attack_stat] : Format("{:0.2f}", 1000/val.properties_best[attack_stat])
					item_%attack_stat%_rel := Format("{:0.0f}", base_best_%attack_stat%/class_best_%attack_stat%*100)
				}
			}
			item_lvl_max := IsNumber(val["best ilvl"]) ? val["best ilvl"] : item_lvl_max
			If (item_type = "defense")
			{
				If (item_stats_array[1] = "energy_shield") && (item_stats_array[2] = "evasion")
					natural_defense_stat := "evasion rating"
				Else natural_defense_stat := (item_stats_array[1] = "evasion") ? "evasion rating" : StrReplace(item_stats_array[1], "_", " ")
				defense_flat := 0
			}
			break
		}
	}
	item_quality := 0, item_quality_norm := 0
	
	Loop, parse, Clipboard, `n, `r ;parse quality and defense-stats
	{
		If InStr(A_LoopField, "Quality: ")
		{
			item_quality := StrReplace(A_LoopField, " (augmented)")
			item_quality := SubStr(item_quality, 11)
			item_quality := StrReplace(item_quality, "%")
			item_quality_norm := Format("{:0.2f}", item_quality/100)
		}
		If InStr(A_LoopField, natural_defense_stat ": ")
		{
			stat_value := StrReplace(A_LoopField, " (augmented)")
			stat_value := SubStr(stat_value, StrLen(natural_defense_stat ":  "))
			stat_augmented := InStr(A_LoopField, " (augmented)") ? 1 : 0
		}
	}
	
	If (item_type = "defense") ;calculate the value of the base-defense roll (the one that's re-rolled with sacred orbs)
	{
		defense_stat_prefix := (natural_defense_stat = "energy shield") ? "maximum " : ""
		If (stat_augmented != 0)
		{
			If !InStr(Clipboard, "Quality does not increase Defences (enchant)")
				defense_increased += item_quality
			Loop, Parse, Clipboard, `n, `r
			{
				If InStr(A_LoopField, "increased ") && (InStr(A_LoopField, natural_defense_stat) || InStr(A_LoopField, StrReplace(natural_defense_stat, " rating"))) && !InStr(A_LoopField, " per ") && !InStr(A_LoopField, " when ") && !InStr(A_LoopField, " while ") && !InStr(A_LoopField, " during ") && !InStr(A_LoopField, " by ") && !InStr(A_LoopField, " if ") && !InStr(A_LoopField, " recovery ") && !InStr(A_LoopField, " maximum ")
					defense_increased += SubStr(A_LoopField, 1, InStr(A_LoopField, "(") - 1)
				If InStr(A_LoopField, " to " defense_stat_prefix natural_defense_stat) && InStr(A_LoopField, "+") && !InStr(A_LoopField, " per ") && !InStr(A_LoopField, " when ") && !InStr(A_LoopField, " while ") && !InStr(A_LoopField, " during ") && !InStr(A_LoopField, " by ") && !InStr(A_LoopField, " if ") && !InStr(A_LoopField, " recovery ")
					defense_flat += SubStr(A_LoopField, 2, InStr(A_LoopField, "(") - 1)
			}
			defense_increased := Format("{:0.2f}", 1 + defense_increased/100)
			stat_value := Format("{:0.0f}", stat_value / defense_increased)
			stat_value -= defense_flat
		}
		natural_defense_stat := StrReplace(natural_defense_stat, " rating")
		natural_defense_stat := StrReplace(natural_defense_stat, " ", "_")
		defense_roll := stat_value/base_best_%natural_defense_stat%*100
		Loop, % item_stats_array.Count()
		{
			parse := item_stats_array[A_Index]
			If (parse = "block") || (parse = "combined")
				continue
			item_%parse% := base_best_%parse%*defense_roll/100
			item_%parse%_rel := Format("{:0.0f}", item_%parse%/class_best_%parse%*100)
			item_%parse% := Format("{:0.0f}", base_best_%parse%*defense_roll/100)
			If (item_stats_array.Count() >= 2)
			{
				item_combined += item_%parse%
				item_combined_rel := Format("{:0.0f}", item_combined/class_best_combined*100)
			}
		}
		defense_roll := Format("{:0.0f}", stat_value/base_best_%natural_defense_stat%*100)
	}
	
	divider_height := itemchecker_height//9
	If (item_quality >= 25)
		divider_color := "ffd700"
	Else divider_color := InStr(Clipboard, "`nCorrupted", 1) ? "dc0000" : InStr(Clipboard, "`nMirrored", 1) ? "00cccc" : "e0e0e0"
	
	
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
		Loop, Parse, clipboard, `n, `r
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
		all_dps := pdps "," edps0 "," cdps
		offenses := "dps=" tdps "`npdps=" pdps "`nedps=" edps0 "`ncdps=" cdps "`nspeed=" speed "`n"
	}
	
	itemcheck_clip := SubStr(Clipboard, InStr(Clipboard, "item level:"))
	item_lvl := SubStr(itemcheck_clip, 1, InStr(itemcheck_clip, "`r`n",,, 1) - 1)
	item_lvl := StrReplace(item_lvl, "item level: ")
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
		If (InStr(A_LoopField, "allocates ") && InStr(A_LoopField, "(enchant)"))
			implicits .= StrReplace(A_LoopField, " (enchant)") "`n|`n"
		If InStr(A_LoopField, "corruption implicit") || InStr(A_LoopField, "eater of worlds implicit") || InStr(A_LoopField, "searing exarch implicit") || (InStr(itemchecker_metadata, "synthesised ") && InStr(A_LoopField, "implicit modifier"))
			implicits .= StrReplace(A_LoopField, " (implicit)") "`n|`n"
		If InStr(A_LoopField, "{ implicit modifier ") && enable_itemchecker_gear
			implicits .= StrReplace(A_LoopField, " (implicit)") "`n|`n"
		;If InStr(A_LoopField, "crafted")
		;	crafted_mods .= StrReplace(A_LoopField, " (crafted)") "`n"
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") ;|| InStr(A_LoopField, "crafted")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	Loop, Parse, implicits, |, `n
	{
		If (A_LoopField = "") || InStr(A_LoopField, "searing exarch") || InStr(A_LoopField, "eater of worlds") || InStr(A_LoopField, "corruption implicit")
			continue
		implicits2 .= A_LoopField "`n"
	}
	
	Loop, Parse, implicits2, `n
	{
		If (A_Index = 1)
			implicits2 := ""
		If (A_LoopField = "") || (A_LoopField = "|") || (SubStr(A_LoopField, 1, 1) = "{")
			continue
		parse := StrReplace(A_LoopField, " — Unscalable Value")
		parse := (SubStr(parse, 1, 1) = " ") ? SubStr(parse, 2) : parse
		While InStr(parse, "  ")
			parse := StrReplace(parse, "  ", " ")
		parse := StrReplace(parse, "`n ", "`n")
		parse := StrReplace(parse, "allocates ")
		If InStr(parse, " is in your presence,") && InStr(parse, "while a ")
			parse := InStr(parse, "pinnacle") ? SubStr(parse, InStr(parse, ",") + 1) " (pinnacle)" : SubStr(parse, InStr(parse, ",") + 1) " (unique)"
		
		If InStr(parse, ", with ") && InStr(parse, "% increased effect")
			parse := SubStr(parse, 1, InStr(parse, ", with ") - 1)
		implicits2 .= parse "`n"
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
	cluster_enchant := StrReplace(cluster_enchant, "dagger attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "sword attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "mace or sceptre attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "axe attacks deal increased damage with hits and ailments`n", "axe && sword attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "staff attacks deal increased damage with hits and ailments`n", "staff, mace or sceptre attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "claw attacks deal increased damage with hits and ailments`n", "claw && dagger attacks deal increased damage with hits and ailments")
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
	itemcheck_clip2 := StrReplace(itemcheck_clip, " (fractured)")
	
	While (SubStr(itemcheck_clip, 0) = "`n") ;remove white-space at the end
		itemcheck_clip := SubStr(itemcheck_clip, 1, -1)
	
	If enable_itemchecker_gear
	{
		Loop, Parse, gear_slots, `,
		{
			If (A_LoopField = "mainhand" || A_LoopField = "offhand") && InStr(Clipboard, "attacks per second: ")
				item_slot := InStr(equipped_offhand, "speed=") ? "mainhand,offhand" : "mainhand"
			If (A_LoopField = "offhand") && InStr(Clipboard, "item class: shield")
				item_slot := "offhand"
			If InStr(Clipboard, InStr(A_LoopField, "ring") ? "item class: " SubStr(A_LoopField, 1, -1) : "item class: " A_LoopField)
				item_slot := InStr(A_LoopField, "ring") ? "ring1,ring2" : A_LoopField
		}
		parse_comparison := (item_type != "attack") ? LLK_ItemCheckRemoveRolls(implicits2 defenses StrReplace(itemcheck_clip2, " (crafted)"), item_type) : LLK_ItemCheckRemoveRolls(offenses itemcheck_clip2)
		Loop, Parse, parse_comparison, `n
		{
			parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
			%parse% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
			%parse%_1 := 0
			%parse%_2 := 0
			stats_item .= parse ","
		}
		Loop, Parse, item_slot, `,
		{
			loop := A_Index
			Loop, Parse, equipped_%A_LoopField%, `n
			{
				parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
				%parse%_%loop% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
				%parse% := (%parse% = "") ? 0 : %parse%
				stats_equipped_%loop% .= parse ","
			}
		}
		Loop, % loop
		{
			loop1 := A_Index
			losses_%A_Index% := {}
			Loop, Parse, stats_equipped_%A_Index%, `,
			{
				If (A_LoopField = "")
					continue
				If (%A_LoopField%_%loop1% - %A_LoopField% != "")
					losses_%loop1%[A_LoopField] := (%A_LoopField%_%loop1% - %A_LoopField% = 0) ? (%A_LoopField%_%loop1% - %A_LoopField%) : (%A_LoopField%_%loop1% - %A_LoopField%) * (-1)
			}
		}
		item_comparisons := loop1
	}
	
	;mark lines belonging to hybrid mods, and put lines of an affix into a group
	itemcheck_clip := StrReplace(itemcheck_clip, "}`n", "};;")
	itemcheck_clip := StrReplace(itemcheck_clip, "`n{", "|{")
	If !unique
		itemcheck_clip := StrReplace(itemcheck_clip, "`n", "[hybrid]`n[hybrid]")
	itemcheck_clip := StrReplace(itemcheck_clip, "};;", "}`n")
	affix_levels := [] ;array to store the affix level-requirements
	affix_tiers := [] ;array to store the affix tiers
	attack_count := 0 ;variable to store number of attack-specific affixes
	
	Loop, Parse, itemcheck_clip, | ;parse the item-info affix by affix
	{
		If (unique = 1) && !InStr(A_LoopField, "(") ;skip unscalable unique affix
			continue
		loop += 1
		If (itemchecker_item_class != "base jewel")
			tier := unique ? "u" : InStr(A_LoopField, "tier:") ? SubStr(A_LoopField, InStr(A_LoopField, "tier: ") + 6, InStr(A_LoopField, ")") - InStr(A_LoopField, "tier: ") - 6) : InStr(A_LoopField, "crafted") ? "c" : "—" ;determine affix tier
		affix_name := unique ? "" : SubStr(A_LoopField, InStr(A_LoopField, """",,, 1) + 1, InStr(A_LoopField, """",,, 2) - InStr(A_LoopField, """",,, 1) - 1)
		mod := A_LoopField
		
		If (item_type = "attack") && ((InStr(A_LoopField, "adds ") && InStr(A_LoopField, " damage") && !InStr(A_LoopField, "spell")) || InStr(A_LoopField, "increased attack speed") || InStr(A_LoopField, "increased physical damage"))
			attack_count += (tier <= 3) ? 1.5 : 1
		
		If !unique
		{
			Loop, % itemchecker_mod_data[affix_name].Count()
			{
				If InStr(affix_name, "veil")
				{
					item_level := 60
					Break
				}
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
						item_level := itemchecker_mod_data[affix_name][outer_loop]["level"]
					Else
					{
						read_loop := (target_loop = 0) ? outer_loop : target_loop
						Loop, % itemchecker_mod_data[affix_name][read_loop]["weights"].Count()
						{
							If LLK_ArrayHasVal(itemchecker_base_item_data[itemchecker_item_base]["tags"], itemchecker_mod_data[affix_name][read_loop]["weights"][A_Index]["tag"])
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
			{
				affix_type := InStr(A_LoopField, "prefix") ? "prefix" : "suffix"
				Continue
			}
			
			loop2 += 1
			affix_divider += (affix_divider = "" && affix_type = "prefix") || (affix_divider = 1 && affix_type = "suffix") ? 1 : 0
			If (affix_divider = 2)
			{
				affixes.Push("divider")
				affix_tiers.Push("divider")
				affix_levels.Push("divider")
				affix_divider += 1
			}
			parse_loopfield := A_LoopField
			tier .= (tier != "u") && InStr(A_LoopField, "[hybrid]") && !InStr(tier, "*") ? "*" : ""
			affix_levels.Push(item_level)
			affix_tiers.Push(InStr(A_LoopField, "(fractured)") ? affix_name "," tier "f" : affix_name "," tier) ;mark tier as hybrid if applicable
			mod := betrayal A_LoopField ;StrReplace(A_LoopField, "[hybrid]") ;store mod-text in variable
			
			mod1 := (InStr(mod, "adds") || InStr(mod, "added")) && InStr(mod, "to") ? StrReplace(mod, "to", "|",, 1) : mod ;workaround for flat-dmg affixes where x and/or y in 'adds x to y damage' doesn't scale (unique vaal sword, maybe more)
			mod1 := StrReplace(mod1, " (fractured)")
			mods.Push(A_LoopField ";;" tier)
			
			roll := "" ;variable in which to store the numerical values of the affix
			Loop, Parse, % (InStr(mod1, "(") >= 5) ? SubStr(mod1, InStr(mod1, "(") - 4) : mod1 ;parse mod-text character by character
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
			/*
			If (affix_divider = 2)
			{
				affixes.Push("divider")
				affix_tiers.Push("divider")
				affix_divider += 1
			}
			*/
			affixes.Push(mod ";" roll_qual) ;push mod-text, tier, and roll-values into array
		}
	}

	If (loop = 0) && (cluster_type = "") && (item_type != "defense") && (item_type != "attack")
	{
		LLK_ToolTip("item is not scalable")
		Return
	}
	
	;create tooltip GUI
	Gui, itemchecker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker
	Gui, itemchecker: Margin, 0, 0
	Gui, itemchecker: Color, Black
	Gui, itemchecker: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
	
	If (item_type = "attack") && ((attack_count >= 3 && enable_itemchecker_dps) || unique || !enable_itemchecker_dps) && !enable_itemchecker_gear  ;create top-area with DPS values if item is weapon
	{
		Sort, all_dps, D`, N
		
		Loop, Parse, all_dps, `,
		{
			style := (A_Index = 1) ? "xs Section" : "ys"
			If (A_LoopField = 0)
				text := "—"
			Else text := (cdps = A_LoopField) ? "chaos: " cdps : (edps0 = A_LoopField) ? "ele: " edps0 : (pdps = A_LoopField) ? "phys: " pdps : "—"
			Gui, itemchecker: Add, Text, % style " Center Border w"itemchecker_width*2.5, % text
		}
		Gui, itemchecker: Add, Text, % "ys Center Border wp", % " dps: " tdps
	}
	
	If (enable_itemchecker_bases && (!unique || (item_type = "defense" && defense_roll != 0))) || enable_itemchecker_gear ;if item is not unique, determine base-stat strength and add bars to visualize it and the ilvl
	{
		If !enable_itemchecker_gear
		{
			Switch item_type
			{
				Case "attack":
					stats_present := "physical_damage,critical_strike_chance,attack_time,"
					physical_damage_text := "dmg: " item_physical_damage_rel "%"
					critical_strike_chance_text := "crit: " item_critical_strike_chance_rel "%"
					attack_time_text := "speed: " item_attack_time_rel "%"
				Case "defense":
					stat_order := "armour,evasion,energy_shield,ward,combined,block"
					armour_text := "arm: " item_armour_rel "%"
					evasion_text := "eva: " item_evasion_rel "%"
					energy_shield_text := "es: " item_energy_shield_rel "%"
					ward_text := "wrd: " item_ward_rel "%"
					combined_text := "hyb: " item_combined_rel "%"
					block_text := "blk: " item_block_rel "%"
					Loop, Parse, stat_order, `,
					{
						If LLK_ArrayHasVal(item_stats_array, A_LoopField)
							stats_present .= A_LoopField ","
						;If InStr(stats_present, ",",,, 2) && !InStr(stats_present, "block") && !InStr(stats_present, "combined")
						;	stats_present .= "combined,"
						;If InStr(stats_present, ",",,, 3) && !InStr(stats_present, "combined") && !InStr(stats_present, "block")
						;	Break
					}
				Default:
					stats_present := "filler,filler,filler,"
			}
			If unique
				stats_present := "filler,filler,filler,"
		}
		
		If (itemchecker_item_class != "base jewel")
		{
			Loop, % enable_itemchecker_gear ? item_comparisons : 1
			{
				loop := A_Index
				If enable_itemchecker_gear
				{
					Switch item_type
					{
						Case "attack":
						stat_order := "cdps,pdps,edps,speed,dps"
						Loop, Parse, stat_order, `,
						{
							If (A_Index = 1)
								stats_present := ""
							If (%A_LoopField% != 0)
								stats_present .= A_LoopField ","
						}
						Loop, Parse, stats_present, `,
						{
							%A_LoopField%_difference := ""
							If (A_LoopField = "")
								continue
							Switch A_LoopField
							{
								Case "cdps":
									label := "chaos"
								Case "pdps":
									label := "phys"
								Case "edps":
									label := "ele"
								Case "speed":
									label := "aps"
								Case "dps":
									label := "dps"
							}
							If losses_%loop%.HasKey(A_LoopField)
							{
								decimals := (A_LoopField = "speed") ? 0.2 : 0.1
								parse := (%A_LoopField%_%loop% != 0) ? Format("{:0.1f}", (losses_%loop%[A_LoopField] / %A_LoopField%_%loop%) * 100) : Format("{:"decimals "f}", (losses_%loop%[A_LoopField]))
								%A_LoopField%_text := (losses_%loop%[A_LoopField] >= 0) ? label ": +"parse : label ": "parse
								%A_LoopField%_text .= (%A_LoopField%_%loop% != 0) ? "%" : ""
								%A_LoopField%_difference := parse
								losses_%loop%[A_LoopField] := ""
							}
							Else If !losses_%loop%.HasKey(A_LoopField) && (InStr(stats_item, A_LoopField) && %A_LoopField% != 0)
							{
								decimals := (A_LoopField = "speed") ? 0.2 : 0.1
								parse := Format("{:"decimals "f}", %A_LoopField%)
								%A_LoopField%_text := label ": +" parse
								%A_LoopField%_difference := parse
							}
						}
						Default:
						stat_order := "chaos,fire,lightning,cold,life"
						Loop, Parse, stat_order, `,
						{
							If (A_Index = 1)
								stats_present := ""
							If (InStr(stats_item, "to_" A_LoopField "_resistance") && (to_%A_LoopField%_resistance != 0)) || (InStr(stats_equipped_%loop%, "to_" A_LoopField "_resistance") && to_%A_LoopField%_resistance_%loop% != 0)
								stats_present .= A_LoopField ","
							Else If InStr(stats_item, "to_maximum_" A_LoopField) || InStr(stats_equipped_%loop%, "to_maximum_" A_LoopField)
								stats_present .= A_LoopField ","
						}
						Loop, Parse, stats_present, `,
						{
							%A_LoopField%_difference := ""
							If (A_LoopField = "")
								continue
							If losses_%loop%.HasKey("to_"A_LoopField "_resistance")
							{
								%A_LoopField%_text := (losses_%loop%["to_"A_LoopField "_resistance"] >= 0) ? SubStr(A_LoopField, 1, 5) ": +" losses_%loop%["to_"A_LoopField "_resistance"] : SubStr(A_LoopField, 1, 5) ": " losses_%loop%["to_"A_LoopField "_resistance"]
								%A_LoopField%_difference := losses_%loop%["to_"A_LoopField "_resistance"]
								losses_%loop%["to_"A_LoopField "_resistance"] := ""
							}
							Else If !losses_%loop%.HasKey("to_"A_LoopField "_resistance") && (InStr(stats_item, "to_"A_LoopField "_resistance") && to_%A_LoopField%_resistance != 0)
							{
								parse := "to_"A_LoopField "_resistance"
								%A_LoopField%_text := SubStr(A_LoopField, 1, 5) ": +" %parse%
								%A_LoopField%_difference := %parse%
							}
							If losses_%loop%.HasKey("to_maximum_"A_LoopField)
							{
								%A_LoopField%_text := (losses_%loop%["to_maximum_"A_LoopField] >= 0) ? A_LoopField ": +" losses_%loop%["to_maximum_"A_LoopField] : A_LoopField ": " losses_%loop%["to_maximum_"A_LoopField]
								%A_LoopField%_difference := losses_%loop%["to_maximum_"A_LoopField]
								losses_%loop%["to_maximum_"A_LoopField] := ""
							}
							Else If !losses_%loop%.HasKey("to_maximum_"A_LoopField) && (InStr(stats_item, "to_maximum_"A_LoopField) && to_maximum_%A_LoopField% != 0)
							{
								parse := "to_maximum_"A_LoopField
								%A_LoopField%_text := SubStr(A_LoopField, 1, 5) ": +" %parse%
								%A_LoopField%_difference := %parse%
							}
						}
					}
				}
				loop_count := !enable_itemchecker_gear ? LLK_InStrCount(stats_present, ",") + 1 : LLK_InStrCount(stats_present, ",")
				While (Mod(40, loop_count) != 0) || (loop_count < 4)
				{
					loop_count += 1
					stats_present := "filler," stats_present
				}
				width := 40/loop_count*itemchecker_width*0.25
				
				If (loop_count <= 4)
				{
					combined_text := StrReplace(combined_text, "hyb: ", "hybrid: ")
					block_text := StrReplace(block_text, "blk: ", "block: ")
					ward_text := StrReplace(ward_text, "wrd: ", "ward: ")
				}
				filler := ""
				Loop, Parse, stats_present, `,
				{
					If (A_LoopField = "")
						continue
					If (A_LoopField = "filler")
					{
						style := (filler = "") ? "xs Section" : "ys"
						Gui, itemchecker: Add, Text, % style " Hidden Border w"width, ;add hidden text label as dummy to get the correct dimensions
						Gui, itemchecker: Add, Progress, xp yp Border hp wp range66-%item_lvl_max% BackgroundBlack, 0 ;place progress bar on top of dummy label and inherit dimensions
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp", % "—" ;add actual text label
						filler := 1
						continue
					}
					style := (filler = 1) ? "ys h"itemchecker_height " w"width : "xs Section h"itemchecker_height " w"width
					filler := 1
					color := (base_best_%A_LoopField% = class_best_%A_LoopField%) ? itemchecker_t1_color : "505050"
					If (%A_LoopField%_difference != "")
					{
						If (%A_LoopField%_difference >= 1)
							color := itemchecker_t2_color
						If (%A_LoopField%_difference >= 11)
							color := itemchecker_t1_color
						If (%A_LoopField%_difference = 0)
							color := "Black"
						If (%A_LoopField%_difference < 0)
							color := itemchecker_t5_color
						If (%A_LoopField%_difference <= -11)
							color := itemchecker_t6_color
					}
					;If enable_itemchecker_gear
					;	color := InStr(%A_LoopField%_text, "-") ? itemchecker_t6_color : InStr(%A_LoopField%_text, "+0") ? "Black" : itemchecker_t1_color
					Gui, itemchecker: Add, Progress, % style " Border range0-100 BackgroundBlack c"color, % !enable_itemchecker_gear ? item_%A_LoopField%_rel : 100 ;place progress bar on top of dummy label and inherit dimensions
					color := (color != "505050") ? (color = "Black") ? "White" : "Black" : "White"
					Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color, % %A_LoopField%_text ;add actual text label
					;If enable_itemchecker_gear
					;	Gui, itemchecker: Add, Picture, % "xp+"width/2 " yp+2 BackgroundTrans h"itemchecker_height -4 " w-1", img\GUI\item_info_gear_%A_LoopField%.png
				}
				
				If enable_itemchecker_gear
				{
					For key, value in losses_%loop%
					{
						If (value = "" || value >= 0) || (item_type = "attack" && key = "increased_attack_speed") || (LLK_ItemCheckHighlight(StrReplace(key, "_", " "), 0, 0) != 1 && LLK_ItemCheckHighlight(StrReplace(key, "_", " "), 0, 1) != 1)
							continue
						Gui, itemchecker: Add, Progress, % "xs Section Disabled Border BackgroundBlack w"itemchecker_width*10 " h"itemchecker_height, 0
						parse := StrReplace(key, "adds_to_")
						If (SubStr(parse, 1, 10) = "chance_to_") || (SubStr(parse, 1, 10) = "increased_") || (SubStr(parse, 1, 8) = "reduced_")
							parse := "%_" parse
						value *= (value < 0) ? -1 : 1
						If InStr(value, ".")
							value := Format("{:0.2f}", value)
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"itemchecker_t5_color, % InStr(parse, "%") ? value StrReplace(parse, "_", " ") : value " " StrReplace(parse, "_", " ") ;add actual text label
					}
					;If losses_displayed
						Gui, itemchecker: Add, Progress, % "xs Section Disabled BackgroundFuchsia w"itemchecker_width*10 " h"divider_height*2, 0
				}
				Else
				{
					If unique
					{
						Gui, itemchecker: Add, Text, % "ys Hidden Border wp", ;add hidden text label as dummy to get the correct dimensions
						color := (defense_roll >= 99) ? itemchecker_t1_color : "505050" ;highlight ilvl bar green if ilvl >= 86
						Gui, itemchecker: Add, Progress, xp yp Border hp wp range75-100 BackgroundBlack c%color%, % defense_roll ;place progress bar on top of dummy label and inherit dimensions
						color := (color != "505050") ? "Black" : "White"
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color, % "base: " defense_roll "%" ;add actual text label
					}
					Else
					{
						Gui, itemchecker: Add, Text, % "ys Hidden Border wp", ;add hidden text label as dummy to get the correct dimensions
						color := (item_lvl >= item_lvl_max) ? itemchecker_t1_color : "505050" ;highlight ilvl bar green if ilvl >= 86
						Gui, itemchecker: Add, Progress, xp yp Border hp wp range66-%item_lvl_max% BackgroundBlack c%color%, % item_lvl ;place progress bar on top of dummy label and inherit dimensions
						color := (color != "505050") ? "Black" : "White"
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color, % "ilvl: " item_lvl "/" item_lvl_max ;add actual text label
					}
				}
			}
		}
	}
	
	If (implicits != "")
	{
		parse_rage := ""
		If InStr(implicits, "(Inherent effects from having Rage are:")
			implicits := StrReplace(implicits, SubStr(implicits, InStr(implicits, "(Inherent effects from having Rage are:"), 155))
		If InStr(implicits, ", no more than once every ")
		{
			Loop, parse, % SubStr(implicits, InStr(implicits, "no more than once every"))
				parse_rage .= IsNumber(A_LoopField) || (A_LoopField = ".") ? A_LoopField : ""
			implicits := StrReplace(implicits, ", no more than once every " parse_rage " seconds", " (" parse_rage " sec)")
		}
		loop_implicits := 0
		Loop, Parse, implicits, `n, `n
		{
			If (A_Index = 1)
				implicits := ""
			If (SubStr(A_LoopField, 1, 1) = "(")
				continue
			implicits .= A_LoopField "`n"
		}
		Loop, Parse, implicits, |, `n
		{
			If (A_LoopField = "")
				continue
			loop_implicits += 1
			parse := SubStr(A_LoopField, InStr(A_LoopField, "`n") + 1)
			parse := StrReplace(parse, " — Unscalable Value")
			/*
			Loop, Parse, parse
			{
				If (A_Index = 1)
					parse := ""
				If IsNumber(A_LoopField) || InStr(itemcheck_parse, A_LoopField)
					continue
				parse .= A_LoopField
			}
			*/
			parse := (SubStr(parse, 1, 1) = " ") ? SubStr(parse, 2) : parse
			While InStr(parse, "  ")
				parse := StrReplace(parse, "  ", " ")
			parse := StrReplace(parse, "`n ", "`n")
			parse := StrReplace(parse, "allocates ")
			If InStr(parse, " is in your presence,") && InStr(parse, "while a ")
				parse := InStr(parse, "pinnacle") ? SubStr(parse, InStr(parse, ",") + 1) " (pinnacle)" : SubStr(parse, InStr(parse, ",") + 1) " (unique)"
			
			If InStr(parse, ", with ") && InStr(parse, "% increased effect")
				parse := SubStr(parse, 1, InStr(parse, ", with ") - 1)
			
			If (LLK_ItemCheckHighlight(StrReplace(parse, "`n", ";"), 0, 1) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "Black"
			Else color := (LLK_ItemCheckHighlight(StrReplace(parse, "`n", ";"), 0, 1) = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
			
			Gui, itemchecker: Add, Text, % "xs Hidden Center Border w"itemchecker_width*8.75, % parse ;add hidden text label as dummy to get the correct dimensions
			Gui, itemchecker: Add, Progress, % "xp yp Border Disabled Section hp wp BackgroundBlack c"color " HWNDhwnd_itemchecker_implicit"loop_implicits "_button1 vitemchecker_implicit"loop_implicits "_button1", 100
			color1 := (color = "Black") ? "White" : "Black"
			Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp HWNDhwnd_itemchecker_implicit"loop_implicits "_text vitemchecker_implicit"loop_implicits "_text c"color1, % StrReplace(parse, " (eldritch implicit)")
			
			Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width/4 " HWNDhwnd_itemchecker_implicit"loop_implicits "_button vitemchecker_implicit"loop_implicits "_button BackgroundBlack c"color, 100
			Gui, itemchecker: Add, Text, % "xp yp Border 0x200 Center BackgroundTrans hp wp gItemchecker vitemchecker_implicit"loop_implicits " HWNDhwnd_itemchecker_implicit"loop_implicits " cBlack", % " "
			GuiControlGet, implicit_, Pos, % hwnd_itemchecker_implicit%loop_implicits%
			
			switch_parse := SubStr(A_LoopField, InStr(A_LoopField, "(") + 1, InStr(A_LoopField, ")") - InStr(A_LoopField, "(") - 1)
			
			Switch switch_parse
			{
				Case "lesser":
					color := itemchecker_t4_color
					tier := 6
				Case "greater":
					color := itemchecker_t3_color
					tier := 5
				Case "grand":
					color := itemchecker_t2_color
					tier := 4
				Case "exceptional":
					color := itemchecker_t1_color
					tier := 3
				Case "exquisite":
					color := "White"
					tier := 2
				Case "perfect":
					color := "White"
					tier := 1
				Default:
					color := itemchecker_t0_color
					tier := "—"
			}
			
			If !InStr(A_LoopField, "searing exarch") && !InStr(A_LoopField, "eater of worlds")
				type := InStr(A_LoopField, "corruption implicit") ? "vaal" : InStr(Clipboard, "synthesised") ? "synthesis" : ""
			Else type := InStr(A_LoopField, "searing exarch") ? "exarch" : "eater"
			type := InStr(A_LoopField, "item sells for much more to vendors") ? "delve" : InStr(A_LoopField, "allocates ") ? "blight" : type
			
			Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width/2 " BackgroundBlack c"color, 100
			color1 := (tier = 1 || tier = 2) ? "Red" : "Black"
			Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center BackgroundTrans w"itemchecker_width/2 " hp c"color1, % tier
			;Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width/2 " BackgroundWhite cBlack", 100
			;Gui, itemchecker: Add, Text, % "ys Border Hidden Center BackgroundTrans w"itemchecker_width/2 " hp cBlack",
			Gui, itemchecker: Add, Progress, % "ys Disabled Border hp w"itemchecker_width/2 " BackgroundBlack c"color, 100
			Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center BackgroundTrans w"itemchecker_width/2 " hp",
			
			itemchecker_offset := itemchecker_width/2 - itemchecker_height
			While (Mod(itemchecker_offset, 2) != 0)
				itemchecker_offset -= 1
			itemchecker_offset /= 2
			If (implicit_h <= itemchecker_height)
				Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", % (type != "") ? "img\GUI\item_info_"type ".png" : ""
			Else Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+"implicit_h//2 - itemchecker_height//2 + 1 " Center BackgroundTrans h"itemchecker_height-2 " w-1", % (type != "") ? "img\GUI\item_info_"type ".png" : ""
		}
		Gui, itemchecker: Add, Progress, % "xs w"itemchecker_width*10 " Disabled h"divider_height " Background"divider_color,
	}
	
	If (cluster_type != "") ;if item is a cluster jewel, add passive-skills and enchant info
	{		
		If (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";"), 0, 1) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
			color := "Black"
		Else color := (LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";"), 0, 1) = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
		Gui, itemchecker: Add, Text, % "xs Section Border Hidden Center BackgroundTrans w"itemchecker_width*8.75 " cWhite", % cluster_enchant ;dummy panel
		Gui, itemchecker: Add, Progress, % "xp yp Border Disabled HWNDhwnd_itemchecker_cluster_button1 vitemchecker_cluster_button1 hp wp BackgroundBlack c"color, 100
		color1 := (color = "Black") ? "White" : "Black"
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans vitemchecker_cluster_text HWNDhwnd_itemchecker_cluster_text w"itemchecker_width*8.75 " c"color1, % cluster_enchant ;add actual text label
		Gui, itemchecker: Add, Progress, % "ys Border Disabled HWNDhwnd_itemchecker_cluster_button vitemchecker_cluster_button hp w"itemchecker_width*0.25 " BackgroundBlack c"color, 100
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans gItemchecker vitemchecker_cluster HWNDhwnd_itemchecker_cluster hp wp cBlack", % " "
		
		color := (cluster_passives >= cluster_passives_optimal) ? itemchecker_t1_color : "505050"
		Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width " range"cluster_passives_max "-"cluster_passives_optimal " BackgroundBlack c"color, % cluster_passives ;place progress bar on top of dummy label and inherit dimensions
		color1 := (color = itemchecker_t1_color) ? "Black" : "White"
		Gui, itemchecker: Add, Text, % "xp yp Border 0x200 Center BackgroundTrans wp hp c"color1, % cluster_passives*(-1) "/" cluster_passives_max*(-1) ;add actual text label
		If !InStr(Clipboard, "rarity: normal")
			Gui, itemchecker: Add, Progress, % "xs Background"divider_color " h"divider_height " w"itemchecker_width*10,
	}
	
	affix_heights := [] ;array to store the heights of the individual lines
	
	prefixes := 0
	affixes_divided := 0
	
	Loop, % affixes.Count() ;n = number of parsed mod lines
	{
		style := !unique ? "w"itemchecker_width*8.75 : "w"itemchecker_width*10 ;width of the mod list: non-unique list is narrower for extra tier-column on the far right
		
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
		
		If !unique && (affixes[A_Index] = "divider")
		{
			Gui, itemchecker: Add, Progress, % "xs w"itemchecker_width*9 " Disabled h"divider_height " Background"divider_color,
			affix_heights.Push("divider")
			hwnd_itemchecker_panel%A_Index% := 0
			Continue
		}
		
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
		mod_text := StrReplace(mod_text, " (crafted)")
		Gui, itemchecker: Add, Text, % (A_Index = 1) ? "Section xs Border hidden "style : "xs Border hidden "style, % StrReplace(mod_text, " (fractured)") ;add dummy text label for dimensions

		;add progress bar and inherit dimensions from dummy label
		Gui, itemchecker: Add, Progress, % (A_Index = 1) ? "xp yp Section Disabled Border hp wp range" lower_bound "-" upper_bound " BackgroundBlack c"color : "xp yp hp wp Disabled Border range" lower_bound "-" upper_bound " BackgroundBlack c"color, % value
		
		If !unique
			Gui, itemchecker: Add, Text, Center cWhite vitemchecker_panel%A_Index%_text HWNDhwnd_itemchecker_panel%A_Index%_text %style% Border BackgroundTrans xp yp, % StrReplace(mod_text, " (fractured)")
		Else Gui, itemchecker: Add, Text, Center cWhite %style% Border BackgroundTrans xp yp, % mod_text
			
		If !unique
		{
			If (LLK_ItemCheckHighlight(StrReplace(mod_text, " (fractured)")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "Black"
			Else color := (LLK_ItemCheckHighlight(StrReplace(mod_text, " (fractured)")) = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
			Gui, itemchecker: Add, Progress, % "yp x+0 hp w"itemchecker_width/4 " Disabled Border HWNDhwnd_itemchecker_panel"A_Index "_button vitemchecker_panel"A_Index "_button BackgroundBlack c"color, 100
			Gui, itemchecker: Add, Text, % "xp yp hp wp Border BackgroundTrans gItemchecker vitemchecker_panel"A_Index " HWNDhwnd_itemchecker_panel"A_Index, % " "
		}
		GuiControlGet, itemchecker_, Pos, % hwnd_itemchecker_panel%A_Index%
		
		affix_heights.Push(itemchecker_h)
	}
	
	hybrid := 0
	loop := 0
	
	Loop, % affix_tiers.Count()
	{
		If !unique && InStr(affixes[A_Index], "divider")
		{
			Gui, itemchecker: Add, Progress, % "xs w"itemchecker_width " Disabled h"divider_height " Background"divider_color,
			hwnd_itemchecker_tier%A_Index%_button := 0
			hwnd_itemchecker_ilvl%A_Index%_button := 0
			Continue
		}
		If (hybrid != 0)
		{
			hybrid -= 1
			hwnd_itemchecker_tier%A_Index%_button := 0
			hwnd_itemchecker_ilvl%A_Index%_button := 0
			continue
		}
		affix_name := SubStr(affix_tiers[A_Index], 1, InStr(affix_tiers[A_Index], ",") - 1)
		;tier := SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1)
		tier := StrReplace(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "*")
		tier := StrReplace(tier, "f")
		
		loop += 1
		If InStr(affix_tiers[A_Index], "*") && InStr(affix_tiers[A_Index + 1], affix_name)
			hybrid += (InStr(affix_tiers[A_Index + 2], affix_name) && !LLK_ItemCheckAffixes(affix_tiers[A_Index], 1)) ? 2 : 1 ; && ((affix_tiers[A_Index + 3] != "") && !InStr(affix_tiers[A_Index + 3], affix_name))
		If (itemchecker_item_class != "base jewel")
		{
			Switch tier ;set correct highlight color according to tier
			{
				Case "—":
					color := itemchecker_t0_color ;untiered affixes, e.g. delve, veiled, etc.
				Case "c":
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
				color := "e3f2fd"
			Else If (tier = 200) || (tier = 250)
				color := "90caf9"
			Else If (tier = 300) || (tier = 350)
				color := "42a5f5"
			Else If (tier = 400) || (tier = 450)
				color := "1e88e5"
			Else If (tier = 500)
				color := "1565c0"
		}
		
		If !unique
		{
			If LLK_ItemCheckAffixes(affix_tiers[A_Index])
			{
				color := itemchecker_t0_color
				tier := "—"
			}
			If (itemchecker_item_class != "base jewel") && (enable_itemchecker_ilvl || LLK_ItemCheckAffixes(affix_tiers[A_Index], 1) || InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") || InStr(affixes[A_Index], "(crafted)"))
				width := itemchecker_width/2
			Else If (itemchecker_item_class = "base jewel") || !LLK_ItemCheckAffixes(affix_tiers[A_Index], 1)
				width := itemchecker_width
			
			If (hybrid = 2)
				height := affix_heights[A_Index] + affix_heights[A_Index + 1] + affix_heights[A_Index + 2]
			Else height := (hybrid = 1) ? affix_heights[A_Index] + affix_heights[A_Index + 1] : affix_heights[A_Index]
				
			style := (A_Index = 1) ? "section ys " : "Section xs "
			
			;mod_highlight := SubStr(affixes[A_Index], 1, InStr(affixes[A_Index], ";") - 1)
			;If (LLK_ItemCheckHighlight(StrReplace(mod_highlight, " (fractured)")) = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
			;	color_highlight := "White"
			;Else color_highlight := (LLK_ItemCheckHighlight(StrReplace(mod_highlight, " (fractured)")) = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
			
			;Gui, itemchecker: Add, Progress, % style " h"height " w"itemchecker_width/4 " BackgroundBlack Border c"color_highlight, 100 
			;Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center cWhite hp wp BackgroundTrans", % ""
			
			itemchecker_override := 0
			If enable_itemchecker_override
			{
				Switch hybrid
				{
					Case 0:
						If (LLK_ItemCheckHighlight(StrReplace(SubStr(affixes[A_Index], 1, InStr(affixes[A_Index], ";") - 1), " (fractured)")) = -1)
						{
							color := itemchecker_t6_color
							itemchecker_override := 1
						}
					Case 1:
						mod_check := StrReplace(SubStr(affixes[A_Index], 1, InStr(affixes[A_Index], ";") - 1), "[hybrid]")
						mod_check1 := StrReplace(SubStr(affixes[A_Index + 1], 1, InStr(affixes[A_Index + 1], ";") - 1), "[hybrid]")
						If (LLK_ItemCheckHighlight(StrReplace(mod_check, " (fractured)")) = -1) && (LLK_ItemCheckHighlight(StrReplace(mod_check1, " (fractured)")) = -1)
						{
							color := itemchecker_t6_color
							itemchecker_override := 1
						}
					Case 2:
						mod_check := StrReplace(SubStr(affixes[A_Index], 1, InStr(affixes[A_Index], ";") - 1), "[hybrid]")
						mod_check1 := StrReplace(SubStr(affixes[A_Index + 1], 1, InStr(affixes[A_Index + 1], ";") - 1), "[hybrid]")
						mod_check2 := StrReplace(SubStr(affixes[A_Index + 2], 1, InStr(affixes[A_Index + 2], ";") - 1), "[hybrid]")
						If (LLK_ItemCheckHighlight(StrReplace(mod_check, " (fractured)")) = -1) && (LLK_ItemCheckHighlight(StrReplace(mod_check1, " (fractured)")) = -1) && (LLK_ItemCheckHighlight(StrReplace(mod_check2, " (fractured)")) = -1)
						{
							color := itemchecker_t6_color
							itemchecker_override := 1
						}
				}
			}
			
			If (itemchecker_item_class = "base jewel") && (LLK_ItemCheckHighlight(StrReplace(SubStr(affixes[A_Index], 1, InStr(affixes[A_Index], ";") - 1), " (fractured)")) = 1)
				color := itemchecker_t1_color
			
			If InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ;override color in case mod is fractured
				color := itemchecker_t7_color
			
			Gui, itemchecker: Add, Progress, % style " h"height " w"width " BackgroundBlack Border HWNDhwnd_itemchecker_tier"A_Index "_button c"color, 100 ;add colored progress bar as background for tier-column
			Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center cBlack hp wp BackgroundTrans", % tier ;add number label to tier-column
			
			If !enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel") && (LLK_ItemCheckAffixes(affix_tiers[A_Index], 1) || InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") || InStr(affixes[A_Index], "(crafted)")) ;InStr(affix_tiers[A_Index], "chosen") || InStr(affix_tiers[A_Index], "subterranean") || InStr(affix_tiers[A_Index], "of the underground") || InStr(affix_tiers[A_Index], "veil")
			{
				Gui, itemchecker: Add, Progress, % "ys hp wp BackgroundBlack HWND_itemchecker_ilvl"A_Index "_button Border c"color, 100
				Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center cBlack hp wp HWNDmain_text BackgroundTrans",
				GuiControlGet, implicit_, Pos, % main_text
				
				itemchecker_offset := itemchecker_width/2 - itemchecker_height
				While (Mod(itemchecker_offset, 2) != 0)
					itemchecker_offset -= 1
				itemchecker_offset /= 2
				
				type := InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ? "fractured" : InStr(affixes[A_Index], "(crafted)") ? "mastercraft" : LLK_ItemCheckAffixes(affix_tiers[A_Index], 1)
				If (implicit_h <= itemchecker_height)
					Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item_info_%type%.png
				Else Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+"implicit_h//2 - itemchecker_height//2 + 1 " Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item_info_%type%.png
			}
			;If (itemchecker_item_class != "base jewel")
			;	Gui, itemchecker: Add, Text, ys Border Center hp wp BackgroundTrans, % affix_levels[A_Index] ;add number label to tier-column
			
			If enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel")
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
				
				If LLK_ItemCheckAffixes(affix_tiers[A_Index]) || InStr(affixes[A_Index], "(crafted)")
					color := itemchecker_t0_color
				
				color := itemchecker_override ? itemchecker_t6_color : color
				
				If InStr(SubStr(affix_tiers[A_Index], InStr(affix_tiers[A_Index], ",") + 1), "f") ;override color in case mod is fractured
					color := itemchecker_t7_color
				
				If (hybrid = 2)
					height := affix_heights[A_Index] + affix_heights[A_Index + 1] + affix_heights[A_Index + 2]
				Else height := (hybrid = 1) ? affix_heights[A_Index] + affix_heights[A_Index + 1] : affix_heights[A_Index]
				
				Gui, itemchecker: Add, Progress, % "ys h"height " w"itemchecker_width/2 " BackgroundBlack Border HWNDhwnd_itemchecker_ilvl"A_Index "_button c"color, 100 ;add colored progress bar as background for tier-column
				color1 := (level >= 83) && (color = "ffffff") ? "Red" : "Black"
				Gui, itemchecker: Add, Text, % "yp xp 0x200 Border Center c"color1 " hp HWNDmain_text wp BackgroundTrans", % LLK_ItemCheckAffixes(affix_tiers[A_Index]) || InStr(affixes[A_Index], "(crafted)") ? "" : affix_levels[A_Index] ;add number label to tier-column
				GuiControlGet, implicit_, Pos, % main_text
				
				itemchecker_offset := itemchecker_width/2 - itemchecker_height
				While (Mod(itemchecker_offset, 2) != 0)
					itemchecker_offset -= 1
				itemchecker_offset /= 2
				If LLK_ItemCheckAffixes(affix_tiers[A_Index])  || InStr(affixes[A_Index], "(crafted)") ;InStr(affix_tiers[A_Index], "chosen") || InStr(affix_tiers[A_Index], "subterranean") || InStr(affix_tiers[A_Index], "of the underground") || InStr(affix_tiers[A_Index], "veil")
				{
					type := InStr(affixes[A_Index], "(crafted)") ? "mastercraft" : LLK_ItemCheckAffixes(affix_tiers[A_Index])
					If (implicit_h <= itemchecker_height)
						Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item_info_%type%.png
					Else Gui, itemchecker: Add, Picture, % "xp+"itemchecker_offset " yp+"implicit_h//2 - itemchecker_height//2 + 1 " Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item_info_%type%.png
				}
			}
		}
	}
	
	Gui, itemchecker: Show, NA x10000 y10000 ;show GUI outside of monitor
	WinGetPos,,, width, height, ahk_id %hwnd_itemchecker% ;get GUI position and dimensions
	MouseGetPos, mouseXpos, mouseYpos
	mouseXpos := (config != 0) ? xPos_itemchecker + width + poe_height*0.047*0.25 : mouseXpos ;override cursor-position if feature is being configured in settings menu
	mouseYpos := (config != 0) ? yPos_itemchecker + height + poe_height*0.047*0.25 : mouseYpos
	winXpos := (mouseXpos - poe_height*0.047*0.25 - width < xScreenOffSet) ? xScreenOffSet : mouseXpos - width - poe_height*0.047*0.25 ;reposition coordinates in case tooltip would land outside monitor area
	winYpos := (mouseypos - poe_height*0.047*0.25 - height < yScreenOffSet) ? yScreenOffSet : mouseYpos - height - poe_height*0.047*0.25
	Gui, itemchecker: Show, % "NA x"winXpos " y"winYpos ;show GUI next to cursor
	LLK_Overlay("itemchecker", "show") ;trigger GUI for auto-hiding when alt-tabbed
}

LLK_ItemCheckClose()
{
	global
	Gui, itemchecker: Destroy
	hwnd_itemchecker := ""
	hwnd_itemchecker_cluster := ""
	hwnd_itemchecker_cluster_text := ""
	hwnd_itemchecker_cluster_button := ""
	Loop
	{
		If (hwnd_itemchecker_panel%A_Index% = "")
			break
		hwnd_itemchecker_panel%A_Index% := ""
		hwnd_itemchecker_panel%A_Index%_text := ""
		hwnd_itemchecker_panel%A_Index%_button := ""
	}
	Loop
	{
		If (hwnd_itemchecker_implicit%A_Index% = "")
			break
		hwnd_itemchecker_implicit%A_Index% := ""
		hwnd_itemchecker_implicit%A_Index%_text := ""
		hwnd_itemchecker_implicit%A_Index%_button := ""
	}
	Loop
	{
		If (hwnd_itemchecker_tier%A_Index%_button = "") && (hwnd_itemchecker_ilvl%A_Index%_button = "")
			break
		hwnd_itemchecker_tier%A_Index%_button := ""
		hwnd_itemchecker_ilvl%A_Index%_button := ""
	}
}

LLK_ItemCheckHighlight(string, mode := 0, implicit := 0) ;check if mod is highlighted or blacklisted
{
	global itemchecker_highlight, itemchecker_blacklist, itemchecker_highlight_implicits, itemchecker_blacklist_implicits, item_type
	, enable_itemchecker_rule_weapon_res, enable_itemchecker_rule_res, enable_itemchecker_rule_attacks, enable_itemchecker_rule_lifemana_gain, enable_itemchecker_rule_spells, enable_itemchecker_rule_crit
	itemchecker_highlight_parse := "+-.()%"
	;string := LLK_ItemCheckStrReplace(string)
	string := StrReplace(string, " (unique)")
	string := StrReplace(string, " (pinnacle)")
	string := StrReplace(string, "`n", ";")
	
	Loop, Parse, string ;parse string handed to function character by character
	{
		If (A_Index = 1)
			string := "" ;clear string
		If !IsNumber(A_LoopField) && !InStr(itemchecker_highlight_parse, A_LoopField) ;remove numbers and numerical signs
			string .= A_LoopField
	}
	
	/*
	Loop, Parse, string, %A_Space%, %A_Space% ;clean up double-spaces
	{
		If (A_Index = 1)
			string := ""
		string .= (string = "") ? A_LoopField : " " A_LoopField
	}
	*/
	
	While (SubStr(string, 1, 1) = " ")
		string := SubStr(string, 2)
	While (SubStr(string, 0, 1) = " ")
		string := SubStr(string, 1, -1)
	While InStr(string, "  ")
		string := StrReplace(string, "  ", " ")
	If InStr(string, "strike skills target additional nearby ")
	{
		string := StrReplace(string, " enemy")
		string := StrReplace(string, " enemies")
	}
	string := StrReplace(string, "; ", ";")
	
	If !implicit
	{
		If enable_itemchecker_rule_lifemana_gain && (InStr(string, "life per enemy") || InStr(string, "mana per enemy"))
			rule_applies := -1
		If enable_itemchecker_rule_spells && (InStr(string, " to spell") || (InStr(string, "spell damage") && !InStr(string, "suppress") && !InStr(string, "block")) || InStr(string, " for spell") || InStr(string, "spell skill") || InStr(string, "added spell") || InStr(string, "with spell"))
			rule_applies := -1
		If enable_itemchecker_rule_attacks && (InStr(string, "increased physical damage") || (InStr(string, "adds") && InStr(string, " damage") && !InStr(string, "to spell") && (item_type = "attack")) || ((InStr(string, "increased") || InStr(string, "added") || InStr(string, "adds")) && (InStr(string, "with") && !InStr(string, "speed") || InStr(string, "to")) && InStr(string, " attack")) || InStr(string, "attack damage"))
			rule_applies := -1
		If enable_itemchecker_rule_crit && (InStr(string, "critical strike"))
			rule_applies := -1
		
		If (item_type = "attack") || (rule_applies != "")
		{
			If (rule_applies = "") && enable_itemchecker_rule_weapon_res && (InStr(string, "resistance") && !InStr(string, "penetrate"))
				rule_applies := -1
			If (rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip("blocked by global rule")
					Return -1
				}
				Return rule_applies
			}
		}
		
		If ((item_type = "defense") || (item_type = "jewelry"))
		{
			If enable_itemchecker_rule_res && InStr(string, "to ") && InStr(string, " resistance") && !InStr(string, "minion")
				rule_applies := 1
			If (rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip("blocked by global rule")
					Return -1
				}
				Return rule_applies
			}
		}
	}
	implicit_check := !implicit ? "" : "_implicits"
	If (mode = 0) ;check if mod is highlighted/blacklisted in order to determine color
	{
		If !InStr(itemchecker_highlight%implicit_check%, "|" string "|") && !InStr(itemchecker_blacklist%implicit_check%, "|" string "|")
			Return 0
		Else If InStr(itemchecker_highlight%implicit_check%, "|" string "|")
			Return 1
		Else If InStr(itemchecker_blacklist%implicit_check%, "|" string "|")
			Return -1
	}
	If (mode = 1) ;mod was left-clicked: check for current highlight-state
	{
		If !InStr(itemchecker_highlight%implicit_check%, "|" string "|") ;mod is not highlighted: add it to highlighted mods and save
		{
			itemchecker_highlight%implicit_check% .= "|" string "|"
			IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "highlighted mods" : "highlighted implicits"
			If InStr(itemchecker_blacklist%implicit_check%, "|" string "|")
			{
				itemchecker_blacklist%implicit_check% := StrReplace(itemchecker_blacklist%implicit_check%, "|" string "|")
				IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "blacklisted mods" : "blacklisted implicits"
			}
			Return 1
		}
		Else ;mod is highlighted: remove it from highlighted mods and save
		{
			itemchecker_highlight%implicit_check% := StrReplace(itemchecker_highlight%implicit_check%, "|" string "|")
			IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "highlighted mods" : "highlighted implicits"
			Return 0
		}
	}
	If (mode = 2) ;mod was right-clicked: check for current blacklist-state
	{
		If !InStr(itemchecker_blacklist%implicit_check%, "|" string "|") ;mod is not blacklisted: add it to blacklisted mods and save
		{
			itemchecker_blacklist%implicit_check% .= "|" string "|"
			IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "blacklisted mods" : "blacklisted implicits"
			If InStr(itemchecker_highlight%implicit_check%, "|" string "|")
			{
				itemchecker_highlight%implicit_check% := StrReplace(itemchecker_highlight%implicit_check%, "|" string "|")
				IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "highlighted mods" : "highlighted implicits"
			}
			Return 1
		}
		Else ;mod is blacklisted: remove it from blacklisted mods and save
		{
			itemchecker_blacklist%implicit_check% := StrReplace(itemchecker_blacklist%implicit_check%, "|" string "|")
			IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, settings, % !implicit ? "blacklisted mods" : "blacklisted implicits"
			Return 0
		}
	}
}

LLK_ItemCheckStrReplace(string, order := 0) ;was experimenting with a 'compact' mode ;on hold until tooltip is more or less finalized
{
	replace := ["of physical attack damage leeched as life", "life-leech (attacks)", "of physical attack damage leeched as mana", "mana-leech (attacks)", "of damage taken recouped as life", "life-recoup", "with one handed weapons", "(1-hand weapon)"
	, "with one handed melee weapons", "(1-hand melee weapon)", "with wand attacks", "(wand attacks)", "for 4 seconds", "(4 sec)", "movement speed", "move-speed", "if you've killed recently", "(killed recently)", "stun and block", "stun && block"
	, "projectiles", "proj", "projectile", "proj", "regeneration rate", "regen rate", "critical strike", "crit", "resistances", "res", "damage over time", "dot"
	, "multiplier", "multi", "maximum", "max", "suppress spell damage", "suppress", "damage", "dmg", "increased", "inc", "accuracy rating", "accuracy", "with", "w/"
	, "resistance", "res", "physical", "phys", "regenerate", "regen", " per second", "/sec", "intelligence", "int", "strength", "str", "dexterity", "dex", "elemental", "ele", "energy shield", "es", "evasion rating", "evasion", "while holding a shield", "(shield)"
	, "while dual wielding", "(dual wield)", "with lightning skills", "(lightning skills)", "rarity of items found", "rarity", "quantity of items found", "quant"]
	
	Loop, % replace.Length()
	{
		If (order = 0) && (Mod(A_Index, 2) = 0)
			continue
		Else If (order = 1) && (Mod(A_Index, 2) != 0)
			continue
		string := (order = 0) ? StrReplace(string, replace[A_Index], replace[A_Index + 1]) : StrReplace(string, replace[A_Index], replace[A_Index - 1])
	}
	Return string
}

LLK_ItemCheckAffixes(string, mode := 0)
{
	parse := "bestiary,delve,incursion,syndicate"
	If mode
		parse .= ",shaper,elder,crusader,redeemer,hunter,warlord,essence"
	bestiary := ["saqawal", "farrul", "craiceann", "fenumus"]
	delve := ["subterranean", "of the underground"]
	incursion := ["Citaqualotl", "Guatelitzi", "Matatl", "Tacati", "Topotante", "Xopec"]
	syndicate := ["chosen", "veil"]
	shaper := ["shaper", "shaping"]
	elder := ["elder"]
	crusader := ["crusader", " crusade"]
	redeemer := ["redeemer", "redemption"]
	hunter := ["hunter's", " hunt"]
	warlord := ["warlord", "conquest"]
	essence := ["essences", " essence"]
	
	Loop, parse, parse, `,
	{
		Loop, % %A_LoopField%.Length()
		{
			If InStr(string, %A_LoopField%[A_Index])
				Return A_LoopField
		}
	}
	Return 0
}

LLK_ItemCheckGear(slot)
{
	global equipped_mainhand, equipped_offhand, equipped_helmet, equipped_body, equipped_amulet, equipped_ring1, equipped_ring2, equipped_gloves, equipped_boots, equipped_belt
	global hwnd_itemchecker
	
	snip := SubStr(Clipboard, InStr(Clipboard, "item level: "))
	item_type := InStr(Clipboard, "attacks per second: ") ? "attack" : ""
	
	Loop, Parse, Clipboard, `n, `r
	{
		If InStr(A_LoopField, "armour: ")
		{
			armor := StrReplace(A_LoopField, " (augmented)")
			armor := SubStr(armor, 9)
			defenses .= "armor,"
		}
		If InStr(A_LoopField, "evasion rating: ")
		{
			evasion := StrReplace(A_LoopField, " (augmented)")
			evasion := SubStr(evasion, 17)
			defenses .= "evasion,"
		}
		If InStr(A_LoopField, "energy shield: ")
		{
			energy := StrReplace(A_LoopField, " (augmented)")
			energy := SubStr(energy, 16)
			defenses .= "energy,"
		}
		If InStr(A_LoopField, "ward: ")
		{
			ward := StrReplace(A_LoopField, " (augmented)")
			ward := SubStr(ward, 7)
			defenses .= "ward,"
		}
		If InStr(A_LoopField, "requirements: ")
			break
	}
	
	Loop, Parse, defenses, `,
	{
		If (A_Index = 1)
			defenses := ""
		If (A_LoopField = "")
			continue
		defenses .= A_LoopField "=" %A_LoopField% "`n"
	}
	
	If InStr(Clipboard, "attacks per second: ")
	{
		item_type := "attack"
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
		Loop, Parse, clipboard, `n, `r
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
		all_dps := pdps "," edps0 "," cdps
		edps := edps0
		dps := tdps
	}
	
	itemcheck_clip := SubStr(Clipboard, InStr(Clipboard, "item level:"))
	item_lvl := SubStr(itemcheck_clip, 1, InStr(itemcheck_clip, "`r`n",,, 1) - 1)
	item_lvl := StrReplace(item_lvl, "item level: ")
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
		If InStr(A_LoopField, "{ implicit modifier ")
		{
			parse := StrReplace(A_LoopField, "to accuracy rating", "to local accuracy rating")
			implicits .= StrReplace(parse, " (implicit)") "`n"
		}
		;If InStr(A_LoopField, "crafted")
		;	crafted_mods .= StrReplace(A_LoopField, " (crafted)") "`n"
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") ;|| InStr(A_LoopField, "crafted")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	Loop, Parse, implicits, `n
	{
		If (A_Index = 1)
			implicits := ""
		If (SubStr(A_LoopField, 1, 1) = "{")
			continue
		implicits .= A_LoopField "`n"
	}
	
	While (SubStr(implicits, 0) = "`n")
		implicits := SubStr(implicits, 1, -1)
	
	Loop, Parse, itemcheck_clip, `n ;remove tooltips from item-info
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "(")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	itemcheck_clip := StrReplace(itemcheck_clip, " — Unscalable Value")
	itemcheck_clip := StrReplace(itemcheck_clip, " (fractured)")
	itemcheck_clip := StrReplace(itemcheck_clip, " (crafted)")
	
	Loop, Parse, itemcheck_clip, `n
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "{")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	While (SubStr(itemcheck_clip, 0) = "`n")
		itemcheck_clip := SubStr(itemcheck_clip, 1, -1)
	
	equipped_%slot% := (item_type = "attack") ? "dps="tdps "`npdps="pdps "`nedps="edps0 "`ncdps="cdps "`nspeed=" speed "`n" LLK_ItemCheckRemoveRolls(implicits "`n" itemcheck_clip, item_type) : defenses LLK_ItemCheckRemoveRolls(implicits "`n" itemcheck_clip, item_type)
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	/*
	snip := StrReplace(snip, " (implicit)")
	snip := StrReplace(snip, " (crafted)")
	snip := StrReplace(snip, " (fractured)")
	parse := StrReplace(parse, "allocates ")
	If InStr(parse, " is in your presence,") && InStr(parse, "while a ")
		parse := InStr(parse, "pinnacle") ? SubStr(parse, InStr(parse, ",") + 1) " (pinnacle)" : SubStr(parse, InStr(parse, ",") + 1) " (unique)"
	
	If InStr(parse, ", with ") && InStr(parse, "% increased effect")
		parse := SubStr(parse, 1, InStr(parse, ", with ") - 1)
	
	Loop, Parse, snip, `n
	{
		If InStr(A_LoopField, "item level: ") || InStr(A_LoopField, "----") || InStr(A_LoopField, "Item`r", 1) ||  || (item_type = "attack" && InStr(A_LoopField, "adds ") && InStr(A_LoopField, " damage") && !InStr(A_LoopField, "spell")) 
			continue
		parse := StrReplace(A_LoopField, "allocates ")
		If InStr(parse, " is in your presence,") && InStr(parse, "while a ")
			parse := InStr(parse, "pinnacle") ? SubStr(parse, InStr(parse, ",") + 1) " (pinnacle)" : SubStr(parse, InStr(parse, ",") + 1) " (unique)"
		
		If InStr(parse, ", with ") && InStr(parse, "% increased effect")
			parse := SubStr(parse, 1, InStr(parse, ", with ") - 1)
		
		While (SubStr(parse, 1, 1) = " ")
			parse := SubStr(parse, 2)
		test_box .= StrReplace(parse, "`r") "`n"
	}
	;MsgBox, % test_box
	*/
}

LLK_ItemCheckRemoveRolls(string, item_type := "")
{
	resists := "cold,lightning,fire,chaos"
	attributes := "strength,dexterity,intelligence"
	test := ","
	
	Loop, Parse, resists, `,
	{
		parse := "to_"A_LoopField "_resistance"
		%parse% := 0
		test .= "to_"A_LoopField "_resistance,"
	}
	
	Loop, Parse, attributes, `,
	{
		parse := "to_"A_LoopField
		%parse% := 0
		test .= "to_"A_LoopField ","
	}
	
	Loop, Parse, string, `n, `r
	{
		If InStr(A_LoopField, "{")
			continue
		Loop, % LLK_InStrCount(A_LoopField, "(")
			parse_remove%A_Index% := SubStr(A_LoopField, InStr(A_LoopField, "(",,, A_Index), InStr(A_LoopField, ")",,, A_Index) - InStr(A_LoopField, "(",,, A_Index) + 1)
		loop := 1
		parse := A_LoopField
		loopfield_copy := A_LoopField
		While InStr(parse, parse_remove%loop%) && (parse_remove%loop% != "")
		{
			If (A_Index > LLK_InStrCount(loopfield_copy, "("))
				break
			parse := InStr(parse, " " parse_remove%loop%) ? StrReplace(parse, " " parse_remove%loop%) : StrReplace(parse, parse_remove%loop%)
			loop += 1
		}
		gear_clip .= parse "`n"
	}
	;gear_clip := gear_clip crafted_mods
	
	Loop, Parse, gear_clip, `n
	{
		If (A_LoopField = "") || ((item_type = "attack") && InStr(A_LoopField, "adds ") && InStr(A_LoopField, "damage") && !InStr(A_LoopField, "spell")) || ((item_type = "attack") && InStr(A_LoopField, "increased physical damage"))
			continue
		;If (LLK_ItemCheckHighlight(A_LoopField) != -1)
		{
			loopfield_original := A_LoopField
			If (InStr(A_LoopField, "adds") || InStr(A_LoopField, "added")) && InStr(A_LoopField, "to")
			{
				loopfield_copy := A_LoopField
				Loop, Parse, loopfield_copy
				{
					If (A_Index = 1)
						loopfield_copy := ""
					If LLK_IsAlpha(A_LoopField) || (A_LoopField = " ")
						loopfield_copy .= StrReplace(A_LoopField, " ", "_")
				}
			}
			While InStr(loopfield_copy, "__")
				loopfield_copy := StrReplace(loopfield_copy, "__", "_")
			While (SubStr(loopfield_copy, 1, 1) = "_")
				loopfield_copy := SubStr(loopfield_copy, 2)
			
			Loop, Parse, % (InStr(A_LoopField, "adds") || InStr(A_LoopField, "added")) && InStr(A_LoopField, "to") ? StrReplace(A_LoopField, " to ", "|",, 1) : A_LoopField
			{
				If (A_Index = 1)
				{
					parse := ""
					parse_name := ""
				}
				If IsNumber(A_LoopField) || (A_LoopField = "|") || (A_LoopField = ".")
					parse .= A_LoopField
				If LLK_IsAlpha(A_LoopField) || (A_LoopField = " ") 
					parse_name .= StrReplace(A_LoopField, " ", "_")
				;If (A_LoopField = "%")
				;	parse_name .= "percent_"
			}
			If InStr(parse, "|")
				parse := Format("{:0.0f}", (SubStr(parse, 1, InStr(parse, "|") - 1) + SubStr(parse, InStr(parse, "|") + 1)) / 2)
			While InStr(parse_name, "__")
				parse_name := StrReplace(parse_name, "__", "_")
			While (SubStr(parse_name, 1, 1) = "_")
				parse_name := SubStr(parse_name, 2)
			If (parse = "")
				%parse_name% := "absolute"
			Else
			{
				If InStr(parse_name, "all_attributes")
				{
					Loop, Parse, attributes, `,
					{
						to_%A_LoopField% += parse
						test .= InStr(test, ",to_"A_LoopField ",") ? "" : "to_"A_LoopField ","
					}
				}
				Else If ((InStr(parse_name, "strength") || InStr(parse_name, "dexterity") || InStr(parse_name, "intelligence")) && InStr(parse_name, "and"))
				{
					Loop, Parse, attributes, `,
					{
						If InStr(parse_name, A_LoopField)
						{
							to_%A_LoopField% += parse
							test .= InStr(test, ",to_"A_LoopField ",") ? "" : "to_"A_LoopField ","
						}
					}
					continue
				}
				Else If InStr(parse_name, "all_elemental") && !InStr(parse_name, "minion")
				{
					Loop, Parse, resists, `,
					{
						to_%A_LoopField%_resistance += parse
						test .= InStr(test, ",to_"A_LoopField "_resistance,") ? "" : "to_"A_LoopField "_resistance,"
					}
					continue
				}
				Else If (InStr(parse_name, "resistance") && InStr(parse_name, "and") && !InStr(parse_name, "minion"))
				{
					Loop, Parse, resists, `,
					{
						If InStr(parse_name, A_LoopField)
						{
							to_%A_LoopField%_resistance += parse
							test .= InStr(test, ",to_"A_LoopField "_resistance,") ? "" : "to_"A_LoopField "_resistance,"
						}
					}
					continue
				}
				Else
				{
					If (InStr(loopfield_original, "adds") || InStr(loopfield_original, "added")) && InStr(loopfield_original, "to")
						%loopfield_copy% += parse
					Else %parse_name% += parse
				}
			}
			If (InStr(loopfield_original, "adds") || InStr(loopfield_original, "added")) && InStr(loopfield_original, "to")
				test .= InStr(test, "," loopfield_copy ",") ? "" : loopfield_copy ","
			Else test .= InStr(test, "," parse_name ",") ? "" : parse_name ","
		}
	}
	Loop, Parse, test, `,
	{
		If (A_Index = 1)
			test := ""
		If (A_LoopField = "")
			continue
		test .= A_LoopField "=" %A_LoopField% "`n"
	}
	While (SubStr(test, 0) = "`n")
		test := SubStr(test, 1, -1)
	Return test
}

LLK_ItemCheckGearMouse(xcoord, ycoord)
{
	global
	Loop, Parse, gear_slots, `,
	{
		If (xcoord >= %A_LoopField%_xcoord1 && xcoord <= %A_LoopField%_xcoord2) && (ycoord >= %A_LoopField%_ycoord1 && ycoord <= %A_LoopField%_ycoord2)
			Return A_LoopField
	}
	Return 0
}

LLK_ItemCheckVendor()
{
	global
	MouseGetPos, itemchecker_vendor_mouseX, itemchecker_vendor_mouseY, itemchecker_win_hover, itemchecker_control_hover, 2
	itemchecker_highlightable := 0
	
	Loop
	{
		If (hwnd_itemchecker_panel%A_Index% = "") && (hwnd_itemchecker_implicit%A_Index% = "") && (hwnd_itemchecker_cluster = "")
			break
		If (itemchecker_control_hover = hwnd_itemchecker_panel%A_Index%) || (itemchecker_control_hover = hwnd_itemchecker_implicit%A_Index%) || (itemchecker_control_hover = hwnd_itemchecker_cluster)
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
		GuiControlGet, control_name_checkvendor, name, % itemchecker_control_hover
		GuiControlGet, itemchecker_panel_text,, % hwnd_%control_name_checkvendor%_text
		click := 2
		GoSub, Itemchecker
		control_name_checkvendor := ""
		click := 1
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