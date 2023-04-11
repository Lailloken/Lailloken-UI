Init_itemchecker:
IniRead, itemchecker_profile, ini\item-checker.ini, settings, current profile, 1
IniRead, itemchecker_highlighting, ini\item-checker.ini, highlighting %itemchecker_profile%,, % A_Space
If (itemchecker_highlighting != "")
{
	Loop, Parse, itemchecker_highlighting, `n
	{
		parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), parse := StrReplace(parse, " ", "_")
		parse1 := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		itemchecker_%parse% := parse1
	}
}
IniRead, enable_itemchecker_ID, ini\item-checker.ini, settings, enable wisdom-scroll trigger, 0
IniRead, enable_itemchecker_ilvl, ini\item-checker.ini, Settings, enable item-levels, 0
IniRead, enable_itemchecker_bases, ini\item-checker.ini, Settings, enable base-info, 1
IniRead, enable_itemchecker_dps, ini\item-checker.ini, Settings, selective dps, 0
IniRead, enable_itemchecker_override, ini\item-checker.ini, Settings, enable blacklist-override, 0
IniRead, enable_itemchecker_gear, ini\item-checker.ini, Settings, enable gear-tracking, 0

Loop, Parse, gear_slots, `,
{
	If (equipped_%A_LoopField% != "") ;only read items on startup
		continue
	IniRead, equipped_%A_LoopField%, ini\item-checker gear.ini, % A_LoopField,, % A_Space
}

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
itemchecker_click_mod := 1
If (A_Gui = "itemchecker") || ((A_Gui = "") && (A_GuiControl = "") && (shift_down = "wisdom") && (click = 2)) ;an item mod was clicked
{
	If (A_TickCount < itemchecker_last_highlight + 250)
		Return
	itemchecker_last_highlight := A_TickCount
	implicit_highlight := InStr(control_name_checkvendor, "implicit") || InStr(control_name_checkvendor, "cluster") || InStr(A_GuiControl, "implicit") || (InStr(A_GuiControl, "cluster")) ? 1 : 0
	
	While (GetKeyState("LButton", "P") || GetKeyState("RButton", "P")) && !implicit_highlight
	{
		If (A_TickCount >= start + 500)
		{
			itemchecker_click_mod := -1
			Break
		}
		sleep, 25
	}
	
	control_name_checkvendor := ""
	If (A_Gui = "itemchecker")
		GuiControlGet, itemchecker_mod,, % A_GuiControl "_text"
	Else If ((A_Gui = "") && (A_GuiControl = "") && (shift_down = "wisdom") && (click = 2))
	{
		MouseGetPos, itemchecker_vendor_mouseX, itemchecker_vendor_mouseY, itemchecker_win_hover, itemchecker_control_hover, 2
		GuiControlGet, control_name_checkvendor, name, % itemchecker_control_hover
		GuiControlGet, itemchecker_mod,, % hwnd_%control_name_checkvendor%_text
	}
	
	If (LLK_ItemCheckHighlight(itemchecker_mod, click * itemchecker_click_mod, implicit_highlight) = -1) ;blocked by global rule
		Return
	
	highlight_check := LLK_ItemCheckHighlight(itemchecker_mod, 0, implicit_highlight)
	If (hwnd_itemchecker_cluster_text != "")
	{
		GuiControlGet, itemchecker_mod,, % hwnd_itemchecker_cluster_text
		If (highlight_check = 0)
		{
			color := "Black"
			color1 := "White"
		}
		Else
		{
			color := (highlight_check = 1) ? itemchecker_t1_color : itemchecker_t6_color
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
		highlight_check := LLK_ItemCheckHighlight(itemchecker_mod, 0, 1)
		If (highlight_check = 0)
		{
			color := "Black"
			color1 := "White"
		}
		Else
		{
			color := (highlight_check = 1) ? itemchecker_t1_color : itemchecker_t6_color
			color1 := "Black"
		}
		GuiControl, itemchecker: +c%color%, itemchecker_implicit%A_Index%_button
		GuiControl, itemchecker: +c%color%, itemchecker_implicit%A_Index%_button1
		GuiControl, itemchecker: +c%color1%, itemchecker_implicit%A_Index%_text
	}
	Loop, % affixes.Count()
	{
		mod_check := affixes[A_Index]
		mod_check := StrReplace(mod_check, " (fractured)")
		mod_check := StrReplace(mod_check, " (crafted)")
		highlight_check := LLK_ItemCheckHighlight(mod_check, 0, 0)
		If (highlight_check = 0)
			color := "Black"
		Else color := (highlight_check = 2) ? itemchecker_t7_color : (highlight_check = 1) ? itemchecker_t1_color : (highlight_check = -2) ? itemchecker_ilvl8_color : itemchecker_t6_color
		GuiControl, itemchecker: +c%color%, itemchecker_panel%A_Index%_button
	}
	
	Loop, % affix_groups.Count()
	{
		check_tier_highlight := 0
		color := itemchecker_affixgroup%A_Index%_color
		color1 := itemchecker_affixgroup%A_Index%_color2
		Loop, Parse, % affix_groups[A_Index], `n
		{
			If (SubStr(A_LoopField, 1, 1) = "{")
				continue
			highlight_check := LLK_ItemCheckHighlight(A_LoopField)
			check_tier_highlight += (highlight_check > 0) ? 1 : (highlight_check = 0) ? 0 : -1
		}
		GuiControl, itemchecker: -Hidden, itemchecker_affixgroup%A_Index%_icon
		If (itemchecker_item_class = "base jewel") && (check_tier_highlight >= LLK_InStrCount(affix_groups[A_Index], "`n"))
			color := itemchecker_t1_color
		/*
		Else If enable_itemchecker_override && (check_tier_highlight = - LLK_InStrCount(affix_groups[A_Index], "`n")*2)
		{
			color := itemchecker_ilvl8_color
			color1 := itemchecker_ilvl8_color
		}
		*/
		Else If (affix_tiers[A_Index] = 1) && (check_tier_highlight >= LLK_InStrCount(affix_groups[A_Index], "`n"))
		{
			color := "ffffff"
			color1 := itemchecker_affixgroup%A_Index%_color2
		}
		Else If enable_itemchecker_override && (check_tier_highlight <= - LLK_InStrCount(affix_groups[A_Index], "`n")) && !InStr(affix_groups_original[A_Index], "(fractured)")
		{
			color := itemchecker_t6_color
			color1 := itemchecker_t6_color
			GuiControl, itemchecker: +Hidden, itemchecker_affixgroup%A_Index%_icon
		}
		/*
		Else
		{
			color := itemchecker_affixgroup%A_Index%_color
			color1 := itemchecker_affixgroup%A_Index%_color2
		}
		*/
		/*
		If LLK_ItemCheckAffixes(affix_names[A_Index]) || InStr(affix_groups_original[A_Index], "(crafted)")
		{
			color := itemchecker_t0_color
			color1 := itemchecker_t0_color
		}
		*/
		If InStr(affix_groups_original[A_Index], "(fractured)")
		{
			color := itemchecker_t7_color
			color1 := itemchecker_t7_color
		}
		
		GuiControl, itemchecker: +c%color%, itemchecker_affixgroup%A_Index%_tier
		GuiControl, % (color = "ffffff") ? "itemchecker: +cRed" : (color = "Black") ? "itemchecker: +cWhite" : "itemchecker: +cBlack", itemchecker_affixgroup%A_Index%_tier_text
		If enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel")
		{
			GuiControl, itemchecker: +c%color1%, itemchecker_affixgroup%A_Index%_tier2
			color1 := (color1 = "ffffff") ? "Red" : "Black"
			GuiControl, itemchecker: +c%color1%, itemchecker_affixgroup%A_Index%_tier2_text
		}
		Else GuiControl, itemchecker: +c%color%, itemchecker_affixgroup%A_Index%_tier2
	}
	
	
	WinSet, Redraw,, ahk_id %hwnd_itemchecker%
	;WinActivate, ahk_group poe_window
	KeyWait, LButton
	KeyWait, RButton
	Return
}

If InStr(A_GuiControl, "itemchecker_profile")
{
	GuiControl, settings_menu: +cWhite, itemchecker_profile%itemchecker_profile%
	GuiControl, settings_menu: movedraw, itemchecker_profile%itemchecker_profile%
	IniRead, itemchecker_highlighting, ini\item-checker.ini, highlighting %itemchecker_profile%,, % A_Space
	If (itemchecker_highlighting != "")
	{
		Loop, Parse, itemchecker_highlighting, `n ;clear current lists before switching profiles
		{
			If (A_LoopField = "")
				continue
			parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), parse := StrReplace(parse, " ", "_")
			itemchecker_%parse% := ""
		}
	}
	itemchecker_profile := StrReplace(A_GuiControl, "itemchecker_profile")
	IniWrite, % itemchecker_profile, ini\item-checker.ini, settings, current profile
	GuiControl, settings_menu: +cFuchsia, itemchecker_profile%itemchecker_profile%
	GuiControl, settings_menu: movedraw, itemchecker_profile%itemchecker_profile%
	GoSub, Init_itemchecker
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
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
	GuiControl, settings_menu: movedraw, itemchecker_apply_color
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
	Gosub, Settings_menu
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
				IniRead, itemchecker_highlighting, ini\item-checker.ini, highlighting %itemchecker_profile%,, % A_Space
				Loop, Parse, itemchecker_highlighting, `n
				{
					If (A_LoopField = "")
						continue
					parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), parse := StrReplace(parse, " ", "_")
					If InStr(parse, type)
					{
						itemchecker_%parse% := ""
						IniWrite, % "", ini\item-checker.ini, highlighting %itemchecker_profile%, % StrReplace(parse, "_", " ")
					}
				}
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
	global affixes := [], affix_tiers := [], affix_levels := [], affix_groups := [], affix_groups_original := [], affix_names := [], gear_slots, itemchecker_item_class := "", itemchecker_meta_itemclass := ""
	global itemchecker_mod_data, itemchecker_base_item_data, itemchecker_width, itemchecker_height, enable_itemchecker_ilvl, enable_itemchecker_override, enable_itemchecker_bases, enable_itemchecker_dps, enable_itemchecker_gear, itemchecker_metadata
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
	global itemchecker_affixgroup1_color, itemchecker_affixgroup2_color, itemchecker_affixgroup3_color, itemchecker_affixgroup4_color, itemchecker_affixgroup5_color, itemchecker_affixgroup6_color
	global itemchecker_affixgroup1_color2, itemchecker_affixgroup2_color2, itemchecker_affixgroup3_color2, itemchecker_affixgroup4_color2, itemchecker_affixgroup5_color2, itemchecker_affixgroup6_color2
	global itemchecker_affixgroup1_tier, itemchecker_affixgroup2_tier, itemchecker_affixgroup3_tier, itemchecker_affixgroup4_tier, itemchecker_affixgroup5_tier, itemchecker_affixgroup6_tier
	global itemchecker_affixgroup1_icon, itemchecker_affixgroup2_icon, itemchecker_affixgroup3_icon, itemchecker_affixgroup4_icon, itemchecker_affixgroup5_icon, itemchecker_affixgroup6_icon
	global itemchecker_affixgroup1_tier_text, itemchecker_affixgroup2_tier_text, itemchecker_affixgroup3_tier_text, itemchecker_affixgroup4_tier_text, itemchecker_affixgroup5_tier_text, itemchecker_affixgroup6_tier_text
	global itemchecker_affixgroup1_tier2, itemchecker_affixgroup2_tier2, itemchecker_affixgroup3_tier2, itemchecker_affixgroup4_tier2, itemchecker_affixgroup5_tier2, itemchecker_affixgroup6_tier2
	global itemchecker_affixgroup1_tier2_text, itemchecker_affixgroup2_tier2_text, itemchecker_affixgroup3_tier2_text, itemchecker_affixgroup4_tier2_text, itemchecker_affixgroup5_tier2_text, itemchecker_affixgroup6_tier2_text
	oil_tiers := ["golden", "silver", "opalescent", "black", "crimson", "violet"]
	
	If (itemchecker_width = 0)
	{
		Gui, itemchecker_width: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker_width
		Gui, itemchecker_width: Margin, 0, 0
		Gui, itemchecker_width: Color, Black
		Gui, itemchecker_width: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
		Gui, itemchecker_width: Add, Text, % "Border HWNDmain_text", % "77777"
		GuiControlGet, itemchecker_, Pos, % main_text
		
		While (Mod(itemchecker_h, 4) != 0)
			itemchecker_h += 1
		;itemchecker_w := itemchecker_h
		;While (Mod(itemchecker_w, 4) != 0)
		;	itemchecker_w += 1
		;width_margin := itemchecker_w//16
		;While (Mod(width_margin, 4) != 0)
		;	width_margin += 1
		itemchecker_width := itemchecker_h*2 ;+ width_margin
		itemchecker_height := itemchecker_h
		Gui, itemchecker_width: Destroy
		hwnd_itemchecker_width := ""
	}
	
	itemchecker_width_segments := 10
	
	Clipboard := StrReplace(Clipboard, "for`neach warcry", "for each warcry")
	
	itemchecker_metadata := SubStr(Clipboard, InStr(Clipboard, "`n",,, 2) + 1), itemchecker_metadata := SubStr(itemchecker_metadata, 1, InStr(itemchecker_metadata, "---") - 3)
	If InStr(itemchecker_metadata, "`n")
		itemchecker_metadata := SubStr(itemchecker_metadata, InStr(itemchecker_metadata, "`n") + 1)
	
	If config ;apply changes made in the settings menu
	{
		WinGetPos, xPos_itemchecker, yPos_itemchecker,,, ahk_id %hwnd_itemchecker%
		Clipboard := itemchecker_clipboard
	}
	Else itemchecker_clipboard := Clipboard
	
	Loop, Parse, Clipboard, `n, `r
	{
		If InStr(A_LoopField, "Item Class: ", 1)
		{
			itemchecker_meta_itemclass := SubStr(A_LoopField, InStr(A_LoopField, "Item Class: ", 1) + 12), itemchecker_meta_itemclass := StrReplace(itemchecker_meta_itemclass, " ", "_")
			StringLower, itemchecker_meta_itemclass, itemchecker_meta_itemclass
		}
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
	Else item_type := ""
	
	If InStr(Clipboard, "`nUnmodifiable", 1) || InStr(Clipboard, "`nRarity: Gem", 1) || InStr(Clipboard, "`nRarity: Currency", 1) || InStr(Clipboard, "`nRarity: Divination Card", 1) || InStr(Clipboard, "item class: pieces") || InStr(Clipboard, "item class: maps")
	OR InStr(Clipboard, "item class: contracts") || InStr(Clipboard, "timeless jewel") || InStr(Clipboard, "item class: misc map items") || InStr(Clipboard, "rarity: quest") ;certain exclusion criteria
	{
		LLK_ToolTip("item-info: item not supported")
		Return
	}
	/*
	If (!InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier")) && !(InStr(Clipboard, "`nRarity: Normal", 1) && InStr(Clipboard, "cluster jewel")) ;could not copy advanced item-info
	{
		LLK_ToolTip("item-info: omni-key setup required (?)", 2)
		;Return
	}
	*/
	LLK_ItemCheckClose()
	
	item_lvl_max := 86
	item_stats_array := []
	For key, val in itemchecker_base_item_data
	{
		If (key = itemchecker_metadata) || InStr(itemchecker_metadata, " " key) || InStr(itemchecker_metadata, key " ")
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
					base_min_%defense_stat% := SubStr(defense_value, 1, InStr(defense_value, "-") - 1)
					base_best_%defense_stat% := SubStr(defense_value, InStr(defense_value, "-") + 1)
					base_best_combined += SubStr(defense_value, InStr(defense_value, "-") + 1)
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
				If InStr(A_LoopField, "increased ") && (InStr(A_LoopField, natural_defense_stat) || InStr(A_LoopField, StrReplace(natural_defense_stat, " rating"))) && !InStr(A_LoopField, " per ") && !InStr(A_LoopField, " when ") && !InStr(A_LoopField, " while ") && !InStr(A_LoopField, " during ") && !InStr(A_LoopField, " by ") && !InStr(A_LoopField, " if ") && !InStr(A_LoopField, " recovery ") && !InStr(A_LoopField, " maximum ") && !InStr(A_LoopField, "from equipped")
					defense_increased += SubStr(A_LoopField, 1, InStr(A_LoopField, "(") - 1)
				If InStr(A_LoopField, " to " defense_stat_prefix natural_defense_stat) && InStr(A_LoopField, "+") && !InStr(A_LoopField, " per ") && !InStr(A_LoopField, " when ") && !InStr(A_LoopField, " while ") && !InStr(A_LoopField, " during ") && !InStr(A_LoopField, " by ") && !InStr(A_LoopField, " if ") && !InStr(A_LoopField, " recovery ")
					defense_flat += SubStr(A_LoopField, 2, InStr(A_LoopField, "(") - 1)
			}
			defense_increased := Format("{:0.2f}", 1 + defense_increased/100)
			stat_value := Format("{:0.0f}", stat_value / defense_increased)
			stat_value -= defense_flat
			;MsgBox, % defense_increased ", " stat_value ", " defense_flat
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
		defense_roll := Format("{:0.0f}", (stat_value - base_min_%natural_defense_stat%)/(base_best_%natural_defense_stat% - base_min_%natural_defense_stat%)*100)
		;MsgBox, % defense_roll
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
		all_dps := "," pdps "," edps0 "," cdps
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
	affix_groups := [] ;array to store affix information
	
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
		If InStr(A_LoopField, "allocates ") && InStr(A_LoopField, "(enchant)")
		{
			implicits .= StrReplace(A_LoopField, " (enchant)") "`n|`n"
			If !enable_itemchecker_gear
			{
				anoint := StrReplace(A_LoopField, " (enchant)"), anoint := StrReplace(anoint, "allocates ")
				IniRead, anoint_recipe, data\item info\amulets.ini, anoints, % anoint, % A_Space
			}
		}
		If (InStr(A_LoopField, " towers") || InStr(A_LoopField, "freezebolt tower") || InStr(A_LoopField, "glacial cage take")) && InStr(A_LoopField, "(enchant)") && !InStr(implicits, " towers") && !InStr(implicits, "freezebolt tower") && !InStr(implicits, "glacial cage take")
		{
			implicits .= StrReplace(A_LoopField, " (enchant)") "`n|`n"
			If !enable_itemchecker_gear && (anoint_recipe = "")
			{
				anoint := StrReplace(A_LoopField, " (enchant)")
				IniRead, anoint_recipe, data\item info\rings.ini, anoints, % anoint, % A_Space
			}
		}
		If InStr(A_LoopField, "corruption implicit") || InStr(A_LoopField, "eater of worlds implicit") || InStr(A_LoopField, "searing exarch implicit") || (InStr(itemchecker_metadata, "synthesised ") && InStr(A_LoopField, "implicit modifier") && !enable_itemchecker_gear)
			implicits .= StrReplace(A_LoopField, " (implicit)") "`n|`n"
		If InStr(A_LoopField, "{ implicit modifier ") && enable_itemchecker_gear
			implicits .= StrReplace(A_LoopField, " (implicit)") "`n|`n"
		;If InStr(A_LoopField, "crafted")
		;	crafted_mods .= StrReplace(A_LoopField, " (crafted)") "`n"
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") || InStr(A_LoopField, "{ Allocated Crucible") ;|| InStr(A_LoopField, "crafted")
			continue
		/*
		If InStr(A_LoopField, "`n",,, 2) && (InStr(A_LoopField, "to maximum life") || InStr(A_LoopField, "increased maximum life"))
		{
			parse := StrReplace(itemcheck_clip, "}`n", "};")
			parse := StrReplace(parse, "`n", "(llktag_life)`n")
			parse := StrReplace(parse, "};", "}`n")
			itemcheck_clip .= parse "`n"
		}
		Else If InStr(A_LoopField, "`n",,, 2) && ((InStr(A_LoopField, "to maximum energy") || InStr(A_LoopField, "increased energy")) && !InStr(A_LoopField, "recharge"))
			itemcheck_clip .= StrReplace(A_LoopField, "`n", "(llktag_energy)`n") "`n"
		*/
		itemcheck_clip .= A_LoopField "`n"
	}
	
	Loop, Parse, implicits, |, `n ;parse implicits for league-start mode
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
			parse := InStr(parse, "pinnacle") ? "pinnacle: " SubStr(parse, InStr(parse, ",") + 2) : "unique: " SubStr(parse, InStr(parse, ",") + 2)
		
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
	
	While InStr(cluster_enchant, "  ")
		cluster_enchant := StrReplace(cluster_enchant, "  ", " ")
	cluster_enchant := StrReplace(cluster_enchant, "`n ", "`n")
	cluster_enchant := StrReplace(cluster_enchant, "dagger attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "sword attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "mace or sceptre attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "axe attacks deal increased damage with hits and ailments`n", "axe && sword attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "staff attacks deal increased damage with hits and ailments`n", "staff, mace or sceptre attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "claw attacks deal increased damage with hits and ailments`n", "claw && dagger attacks deal increased damage with hits and ailments")
	cluster_enchant := StrReplace(cluster_enchant, "damage over time", "dmg over time")
	While (SubStr(cluster_enchant, 1, 1) = " ")
		cluster_enchant := SubStr(cluster_enchant, 2)
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
		Loop, Parse, gear_slots, `, ;determine which item-slot the given item belongs in
		{
			If (A_LoopField = "mainhand" || A_LoopField = "offhand") && InStr(Clipboard, "attacks per second: ")
				item_slot := InStr(equipped_offhand, "speed=") ? "mainhand,offhand" : "mainhand"
			If (A_LoopField = "offhand") && (InStr(Clipboard, "item class: shield") || InStr(Clipboard, "item class: quiver"))
				item_slot := "offhand"
			If InStr(Clipboard, InStr(A_LoopField, "ring") ? "item class: " SubStr(A_LoopField, 1, -1) : "item class: " A_LoopField)
				item_slot := InStr(A_LoopField, "ring") ? "ring1,ring2" : A_LoopField
		}
		parse_comparison := (item_type != "attack") ? LLK_ItemCheckRemoveRolls(implicits2 defenses StrReplace(itemcheck_clip2, " (crafted)"), item_type) : LLK_ItemCheckRemoveRolls(offenses itemcheck_clip2) ;create a list of summarized stats for the given item
		Loop, Parse, parse_comparison, `n ;parse the list, read the individual stats, and declare variables
		{
			parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
			%parse% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1) ;declare variable, e.g. to_maximum_life := 100
			%parse%_1 := 0 ;set variable of potential slot 1 to 0
			%parse%_2 := 0 ;set variable of potential slot 2 to 0
			stats_item .= parse "," ;list stats that are present on the item
		}
		Loop, Parse, item_slot, `, ;read individual stats for all currently equipped items in the target slots
		{
			loop := A_Index
			Loop, Parse, equipped_%A_LoopField%, `n ;read stats, declare variables
			{
				parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
				%parse%_%loop% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1) ;declare variable, e.g. to_maximum_life_1 := 100 ("_n" denoting the n-th currently equipped item, e.g. ring1)
				%parse% := (%parse% = "") ? 0 : %parse% ;if the looted item doesn't have this stat, set its variable to 0
				stats_equipped_%loop% .= parse "," ;list stats that are present on the item
			}
		}
		Loop, % loop ;loop n times (n=number of target slots)
		{
			loop1 := A_Index
			losses_%A_Index% := {} ;clear array in which to store stat losses/gains
			Loop, Parse, stats_equipped_%A_Index%, `, ;parse the stats on item in slot n
			{
				If (A_LoopField = "")
					continue
				If (%A_LoopField%_%loop1% - %A_LoopField% != "") ;store the difference in stat-value in an array
					losses_%loop1%[A_LoopField] := (%A_LoopField%_%loop1% - %A_LoopField% = 0) ? (%A_LoopField%_%loop1% - %A_LoopField%) : (%A_LoopField%_%loop1% - %A_LoopField%) * (-1)
			}
		}
		item_comparisons := loop1 ;how many items the looted item will be compared to
	}
	
	;mark lines belonging to hybrid mods, and put lines of an affix into a group
	itemcheck_clip := StrReplace(itemcheck_clip, "`n{", "|{")
	affix_levels := [] ;array to store the affix level-requirements
	affix_tiers := [] ;array to store the affix tiers
	attack_count := 0 ;variable to store number of attack-specific affixes
	
	;create tooltip GUI
	Gui, itemchecker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker
	Gui, itemchecker: Margin, 0, 0
	Gui, itemchecker: Color, Black
	Gui, itemchecker: Font, % "cWhite s"fSize0 + fSize_offset_itemchecker, Fontin SmallCaps
	
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// DPS area
	
	If (item_type = "attack") && ((attack_count >= 3 && enable_itemchecker_dps) || unique || !enable_itemchecker_dps) && !enable_itemchecker_gear  ;create top-area with DPS values if item is weapon
	{
		Sort, all_dps, D`, N
		filler := 0, dps_added := 0, filler_width := itemchecker_width_segments - 6
		Loop, Parse, all_dps, `,
		{
			If (A_LoopField = 0) || (A_LoopField = "")
			{
				filler_width += (A_LoopField = 0) ? 1.5 : 0
				continue
			}
			
			dps_added += 1
			style := (dps_added = 1) ? "xs Section" : "ys"
			text := (cdps = A_LoopField) ? Format("{:0.1f}", cdps) : (edps0 = A_LoopField) ? Format("{:0.1f}", edps0) : Format("{:0.1f}", pdps)
			label := (cdps = A_LoopField) ? "chaos" : (edps0 = A_LoopField) ? "allres" : "phys"
			If !filler
			{
				Gui, itemchecker: Add, Text, % style " Right Border w"filler_width*itemchecker_width " h"itemchecker_height, % "dps "
				style := "ys"
				filler := 1
			}
			Gui, itemchecker: Add, Text, % style " Center Border w"itemchecker_width " h"itemchecker_height, % text
			Gui, itemchecker: Add, Text, % "ys Center Border w"itemchecker_width/2 " h"itemchecker_height,
			Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", % "img\GUI\item info\"label ".png"
		}
		Gui, itemchecker: Add, Text, % "ys Center Border w"itemchecker_width " h"itemchecker_height, % (tdps < 1000) ? Format("{:0.1f}", tdps) : Format("{:0.0f}", tdps)
		Gui, itemchecker: Add, Text, % "ys Center Border w"itemchecker_width/2 " h"itemchecker_height,
		Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", % "img\GUI\item info\damage.png"
	}
	
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// base-info / stat-comparison area
	
	If (enable_itemchecker_bases && ((!unique || anoint_recipe != "") || (item_type = "defense" && defense_roll != ""))) || enable_itemchecker_gear
	{
		If !enable_itemchecker_gear
		{
			Switch item_type
			{
				Case "attack":
					stats_present := "physical_damage,critical_strike_chance,attack_time,"
					physical_damage_text := item_physical_damage_rel "%"
					critical_strike_chance_text := item_critical_strike_chance_rel "%"
					attack_time_text := item_attack_time_rel "%"
				Case "defense":
					stat_order := "armour,evasion,energy_shield,ward,combined,block"
					armour_text := item_armour_rel "%"
					evasion_text := item_evasion_rel "%"
					energy_shield_text := item_energy_shield_rel "%"
					ward_text := item_ward_rel "%"
					combined_text := item_combined_rel "%"
					block_text := item_block_rel "%"
					Loop, Parse, stat_order, `,
					{
						If LLK_ArrayHasVal(item_stats_array, A_LoopField)
							stats_present .= A_LoopField ","
						;If InStr(stats_present, ",",,, 2) && !InStr(stats_present, "block") && !InStr(stats_present, "combined")
						;	stats_present .= "combined,"
						;If InStr(stats_present, ",",,, 3) && !InStr(stats_present, "combined") && !InStr(stats_present, "block")
						;	Break
					}
					stats_present .= defense ","
				Default:
					stats_present := ""
					If (anoint_recipe != "")
						stats_present := anoint_recipe ","
			}
			If unique && (anoint_recipe = "")
				stats_present := ""
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
									label := "allres" ;[sic!]
								Case "speed":
									label := "speed"
								Case "dps":
									label := "damage"
							}
							If losses_%loop%.HasKey(A_LoopField)
							{
								decimals := (A_LoopField = "speed") ? 0.2 : 0.0
								parse := (%A_LoopField%_%loop% != 0) ? Format("{:0.0f}", (losses_%loop%[A_LoopField] / %A_LoopField%_%loop%) * 100) : Format("{:"decimals "f}", (losses_%loop%[A_LoopField]))
								%A_LoopField%_text := (losses_%loop%[A_LoopField] > 0) ? parse : -parse
								%A_LoopField%_text .= (%A_LoopField%_%loop% != 0) ? "%" : ""
								%A_LoopField%_difference := parse
								losses_%loop%[A_LoopField] := ""
							}
							Else If !losses_%loop%.HasKey(A_LoopField) && (InStr(stats_item, A_LoopField) && %A_LoopField% != 0)
							{
								decimals := (A_LoopField = "speed") ? 0.2 : 0.0
								parse := Format("{:"decimals "f}", %A_LoopField%)
								%A_LoopField%_text := parse
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
							Else If (InStr(stats_item, "to_maximum_" A_LoopField) && !InStr(stats_item, "to_maximum_" A_LoopField "_")) || (InStr(stats_equipped_%loop%, "to_maximum_" A_LoopField) && !InStr(stats_equipped_%loop%, "to_maximum_" A_LoopField "_"))
								stats_present .= A_LoopField ","
						}
						Loop, Parse, stats_present, `,
						{
							%A_LoopField%_difference := ""
							If (A_LoopField = "")
								continue
							If losses_%loop%.HasKey("to_"A_LoopField "_resistance")
							{
								%A_LoopField%_text := (losses_%loop%["to_"A_LoopField "_resistance"] > 0) ? losses_%loop%["to_"A_LoopField "_resistance"] : -losses_%loop%["to_"A_LoopField "_resistance"]
								%A_LoopField%_difference := losses_%loop%["to_"A_LoopField "_resistance"]
								losses_%loop%["to_"A_LoopField "_resistance"] := ""
							}
							Else If !losses_%loop%.HasKey("to_"A_LoopField "_resistance") && (InStr(stats_item, "to_"A_LoopField "_resistance") && to_%A_LoopField%_resistance != 0)
							{
								parse := "to_"A_LoopField "_resistance"
								%A_LoopField%_text := %parse%
								%A_LoopField%_difference := %parse%
							}
							If losses_%loop%.HasKey("to_maximum_"A_LoopField) && !losses_%loop%.HasKey("to_maximum_"A_LoopField "_")
							{
								%A_LoopField%_text := (losses_%loop%["to_maximum_"A_LoopField] > 0) ? losses_%loop%["to_maximum_"A_LoopField] : -losses_%loop%["to_maximum_"A_LoopField]
								%A_LoopField%_difference := losses_%loop%["to_maximum_"A_LoopField]
								losses_%loop%["to_maximum_"A_LoopField] := ""
							}
							Else If !losses_%loop%.HasKey("to_maximum_"A_LoopField) && (InStr(stats_item, "to_maximum_"A_LoopField) && to_maximum_%A_LoopField% != 0)
							{
								parse := "to_maximum_"A_LoopField
								%A_LoopField%_text := %parse%
								%A_LoopField%_difference := %parse%
							}
						}
					}
				}
				loop_count := !enable_itemchecker_gear ? LLK_InStrCount(stats_present, ",") + 1 : LLK_InStrCount(stats_present, ",")
				/*
				While (Mod(40, loop_count) != 0) || (loop_count < 4)
				{
					loop_count += 1
					stats_present := "filler," stats_present
				}
				*/
				stats_present := "filler," stats_present
				;width := 40/loop_count*itemchecker_width*0.25 - itemchecker_width*0.5
				
				If InStr(stats_present, "life")
					life_width := (life_difference > 99 || life_difference < -99) ? 0.25 : 0
				Else life_width := 0
				
				If enable_itemchecker_gear
				{
					width := (item_type = "attack") ? itemchecker_width : itemchecker_width*0.5
					filler_width := (item_type = "attack") ? (itemchecker_width_segments - loop_count*1.5) * itemchecker_width : (itemchecker_width_segments - loop_count - life_width) * itemchecker_width
				}
				Else If (anoint_recipe != "")
				{
					width := itemchecker_width
					filler_width := !unique ? (itemchecker_width_segments - loop_count*2.5 + 1) * itemchecker_width : (itemchecker_width_segments - loop_count*2.5 + 2.5) * itemchecker_width
				}
				Else
				{
					width := itemchecker_width
					filler_width := (itemchecker_width_segments - loop_count*1.5) * itemchecker_width
				}
				
				filler := ""
				Loop, Parse, stats_present, `,, %A_Space%
				{
					If (A_LoopField = "")
						continue
					If (A_LoopField = "filler")
					{
						style := (filler = "") ? "xs Section" : "ys"
						;Gui, itemchecker: Add, Text, % style " Hidden Border w"filler_width " h"itemchecker_height, ;add hidden text label as dummy to get the correct dimensions
						;Gui, itemchecker: Add, Progress, %style% Border h%itemchecker_height% w%filler_width% Disabled BackgroundBlack c646464, ;place progress bar on top of dummy label and inherit dimensions
						If enable_itemchecker_gear
						{
							If InStr(item_slot, ",")
								parse := (loop = 1) ? StrReplace(SubStr(item_slot, 1, InStr(item_slot, ",") - 1), "ring1", "l-ring") " " : StrReplace(SubStr(item_slot, InStr(item_slot, ",") + 1), "ring2", "r-ring") " "
							Else parse := item_slot " "
						}
						Else parse := "base "
						Gui, itemchecker: Add, Text, % style " Border Right BackgroundTrans w"filler_width " h"itemchecker_height, % parse
						filler := 1
						continue
					}
					If (anoint_recipe != "")
						width_override := width*2.5
					Else width_override := (A_LoopField = "life") ? width + itemchecker_width*life_width : width
					style := (filler = 1) ? "ys h"itemchecker_height " w"width_override : "xs Section h"itemchecker_height " w"width_override
					filler := 1
					If (anoint_recipe != "")
					{
						parse := LLK_ArrayHasVal(oil_tiers, A_LoopField)
						%A_LoopField%_text := A_LoopField
						color := (parse = 0) ? itemchecker_t6_color : itemchecker_t%parse%_color
					}
					Else color := (base_best_%A_LoopField% = class_best_%A_LoopField%) ? itemchecker_t1_color : "505050"
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
					Gui, itemchecker: Add, Progress, % style " Border range0-100 BackgroundBlack c"color, % !enable_itemchecker_gear && (anoint_recipe = "") ? item_%A_LoopField%_rel : 100 ;place progress bar on top of dummy label and inherit dimensions
					color1 := (color != "505050") ? (color = "Black") ? "White" : "Black" : "White"
					Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1, % %A_LoopField%_text ;add actual text label
					If (anoint_recipe = "")
					{
						Gui, itemchecker: Add, Progress, % "ys Border BackgroundBlack w"itemchecker_width*0.5 " hp c"color, 100 ;place progress bar on top of dummy label and inherit dimensions
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1,
					}
					If enable_itemchecker_gear
					{
						If (item_type = "attack")
							label := (A_LoopField = "cdps") ? "chaos" : (A_LoopField = "pdps") ? "phys" : (A_LoopField = "edps") ? "allres" : (A_LoopField = "speed") ? "speed" : "damage"
						Else label := A_LoopField
					}
					Else
					{
						If (item_type = "attack")
							label := (A_LoopField = "physical_damage") ? "phys" : (A_LoopField = "critical_strike_chance") ? "crit" : "speed"
						Else label := (A_LoopField = "armour") ? "armor" : (A_LoopField = "energy_shield") ? "energy" : A_LoopField
						
						If (A_LoopField = "combined")
							label := InStr(stats_present, "armour,evasion") ? "armor_evasion" : InStr(stats_present, "armour,energy") ? "armor_energy" : "evasion_energy"
					}
					Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", % "img\GUI\item info\"label ".png"
					;If enable_itemchecker_gear
					;	Gui, itemchecker: Add, Picture, % "xp+"width/2 " yp+2 BackgroundTrans h"itemchecker_height -4 " w-1", img\GUI\item_info_gear_%A_LoopField%.png
				}
				
				If enable_itemchecker_gear
				{
					For key, value in losses_%loop%
					{
						If (value = "" || value >= 0) || (item_type = "attack" && key = "increased_attack_speed") || (LLK_ItemCheckHighlight(StrReplace(key, "_", " "), 0, 0) < 1 && LLK_ItemCheckHighlight(StrReplace(key, "_", " "), 0, 1) < 1)
							continue
						Gui, itemchecker: Add, Progress, % "xs Section Disabled Border BackgroundBlack w"itemchecker_width*itemchecker_width_segments " h"itemchecker_height, 0
						parse := StrReplace(key, "adds_to_")
						If (SubStr(parse, 1, 10) = "chance_to_") || (SubStr(parse, 1, 10) = "increased_") || (SubStr(parse, 1, 8) = "reduced_")
							parse := "%_" parse
						value *= (value < 0) ? -1 : 1
						If InStr(value, ".")
							value := Format("{:0.2f}", value)
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"itemchecker_t5_color, % InStr(parse, "%") ? value StrReplace(parse, "_", " ") : value " " StrReplace(parse, "_", " ") ;add actual text label
					}
					;If losses_displayed
						Gui, itemchecker: Add, Progress, % "xs Section Disabled Background646464 w"itemchecker_width*itemchecker_width_segments " h"divider_height*2.5, 0
				}
				Else
				{
					If (item_type = "defense")
					{
						;Gui, itemchecker: Add, Text, % "ys Hidden Border wp h"itemchecker_height, ;add hidden text label as dummy to get the correct dimensions
						color := (defense_roll >= 99) ? itemchecker_t1_color : "505050" ;highlight ilvl bar green if ilvl >= 86
						Gui, itemchecker: Add, Progress, ys Border h%itemchecker_height% w%itemchecker_width% range0-100 BackgroundBlack c%color%, % defense_roll ;place progress bar on top of dummy label and inherit dimensions
						color1 := (color != "505050") ? "Black" : "White"
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1, % defense_roll "%" ;add actual text label
						Gui, itemchecker: Add, Progress, % "ys Border BackgroundBlack w"itemchecker_width*0.5 " hp c"color, 100 ;place progress bar on top of dummy label and inherit dimensions
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1,
						Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item info\defense.png
					}
					If !unique
					{
						;Gui, itemchecker: Add, Text, % "ys Hidden Border wp h"itemchecker_height, ;add hidden text label as dummy to get the correct dimensions
						color := (item_lvl >= item_lvl_max) ? itemchecker_t1_color : "505050" ;highlight ilvl bar green if ilvl >= 86
						Gui, itemchecker: Add, Progress, ys Border h%itemchecker_height% w%itemchecker_width% range66-%item_lvl_max% BackgroundBlack c%color%, % item_lvl ;place progress bar on top of dummy label and inherit dimensions
						color1 := (color != "505050") ? "Black" : "White"
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1, % item_lvl "/" item_lvl_max ;add actual text label
						Gui, itemchecker: Add, Progress, % "ys Border BackgroundBlack w"itemchecker_width*0.5 " hp c"color, 100 ;place progress bar on top of dummy label and inherit dimensions
						Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp c"color1,
						Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", img\GUI\item info\ilvl.png
					}
				}
			}
		}
	}
	
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// implicit area
	
	If (implicits != "")
	{
		parse_rage := ""
		If InStr(implicits, "(Inherent effects from having Rage are:")
			implicits := StrReplace(implicits, SubStr(implicits, InStr(implicits, "(Inherent effects from having Rage are:"), 155))
		If InStr(implicits, ", no more than once every ")
		{
			Loop, parse, % SubStr(implicits, InStr(implicits, "no more than once every"), 30)
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
				parse := InStr(parse, "pinnacle") ? "pinnacle: " SubStr(parse, InStr(parse, ",") + 2) : "unique: " SubStr(parse, InStr(parse, ",") + 2)
			
			If InStr(parse, ", with ") && InStr(parse, "% increased effect")
				parse := SubStr(parse, 1, InStr(parse, ", with ") - 1)
			
			highlight_check := LLK_ItemCheckHighlight(StrReplace(parse, "`n", ";"), 0, 1)
			If (highlight_check = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
				color := "Black"
			Else color := (highlight_check = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
			
			removed_text := ""
			parse_prefix := InStr(parse, " (pinnacle)") ? "pinnacle: " : InStr(parse, " (unique)") ? "unique: " : ""
			Gui, itemchecker: Add, Text, % "xs Hidden Center Border w"itemchecker_width*(itemchecker_width_segments - 1.25) " HWNDmain_text", % parse_prefix LLK_ItemCheckRemoveRollsText(parse, removed_text) ;add hidden text label as dummy to get the correct dimensions
			
			GuiControlGet, check_, Pos, %main_text%
			height_text := (check_h <= itemchecker_height) ? itemchecker_height : check_h
			Gui, itemchecker: Add, Progress, % "xp yp Border Disabled Section h"height_text " wp BackgroundBlack c"color " HWNDhwnd_itemchecker_implicit"loop_implicits "_button1 vitemchecker_implicit"loop_implicits "_button1", 100
			color1 := (color = "Black") ? "White" : "Black"
			Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans wp hp HWNDhwnd_itemchecker_implicit"loop_implicits "_text vitemchecker_implicit"loop_implicits "_text c"color1, % parse_prefix LLK_ItemCheckRemoveRollsText(parse)
			
			Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width/4 " HWNDhwnd_itemchecker_implicit"loop_implicits "_button vitemchecker_implicit"loop_implicits "_button BackgroundBlack c"color, 100
			Gui, itemchecker: Add, Text, % "xp yp Border 0x200 Center BackgroundTrans hp wp gItemchecker vitemchecker_implicit"loop_implicits " HWNDhwnd_itemchecker_implicit"loop_implicits " cBlack", % " "
			
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
			type := InStr(A_LoopField, "item sells for much more to vendors") ? "delve" : InStr(A_LoopField, "allocates ") || (InStr(A_LoopField, " towers") || InStr(A_LoopField, "freezebolt tower") || InStr(A_LoopField, "glacial cage take")) ? "blight" : type
			
			width := (type = "") ? itemchecker_width : itemchecker_width/2
			Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"width " BackgroundBlack c"color, 100
			color1 := (tier = 1 || tier = 2) ? "Red" : "Black"
			Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center BackgroundTrans wp hp c"color1, % tier
			;Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width/2 " BackgroundWhite cBlack", 100
			;Gui, itemchecker: Add, Text, % "ys Border Hidden Center BackgroundTrans w"itemchecker_width/2 " hp cBlack",
			If (type != "")
			{
				Gui, itemchecker: Add, Progress, % "ys Disabled Border hp w"itemchecker_width/2 " BackgroundBlack c"color, 100
				Gui, itemchecker: Add, Text, % "xp yp 0x200 Border Center BackgroundTrans w"itemchecker_width/2 " hp",
				If (height_text <= itemchecker_height)
					Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center BackgroundTrans h"itemchecker_height-2 " w-1", % (type != "") ? "img\GUI\item info\"type ".png" : ""
				Else Gui, itemchecker: Add, Picture, % "xp+1 yp+"height_text//2 - itemchecker_height//2 + 1 " Center BackgroundTrans h"itemchecker_height-2 " w-1", % (type != "") ? "img\GUI\item info\"type ".png" : ""
			}
		}
		Gui, itemchecker: Add, Progress, % "xs w"itemchecker_width*itemchecker_width_segments " Disabled h"divider_height " Background"divider_color,
	}
	
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// cluster-enchant area
	
	If (cluster_type != "") ;if item is a cluster jewel, add passive-skills and enchant info
	{		
		highlight_check := LLK_ItemCheckHighlight(StrReplace(cluster_enchant, "`n", ";"), 0, 1)
		If (highlight_check = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
			color := "Black"
		Else color := (highlight_check = 1) ? itemchecker_t1_color : itemchecker_t6_color ;determine which is the case
		Gui, itemchecker: Add, Text, % "xs Section Border Hidden Center BackgroundTrans w"itemchecker_width*(itemchecker_width_segments - 1.25) " cWhite HWNDmain_text", % cluster_enchant ;dummy panel
		GuiControlGet, check_, Pos, %main_text%
		height_text := (check_h <= itemchecker_height) ? itemchecker_height : check_h
		Gui, itemchecker: Add, Progress, % "xp yp Border Disabled HWNDhwnd_itemchecker_cluster_button1 vitemchecker_cluster_button1 h"height_text " wp BackgroundBlack c"color, 100
		color1 := (color = "Black") ? "White" : "Black"
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans vitemchecker_cluster_text HWNDhwnd_itemchecker_cluster_text hp w"itemchecker_width*(itemchecker_width_segments - 1.25) " c"color1, % cluster_enchant ;add actual text label
		Gui, itemchecker: Add, Progress, % "ys Border Disabled HWNDhwnd_itemchecker_cluster_button vitemchecker_cluster_button hp w"itemchecker_width*0.25 " BackgroundBlack c"color, 100
		Gui, itemchecker: Add, Text, % "xp yp Border Center BackgroundTrans gItemchecker vitemchecker_cluster HWNDhwnd_itemchecker_cluster hp wp cBlack", % " "
		
		color := (cluster_passives >= cluster_passives_optimal) ? itemchecker_t1_color : "505050"
		Gui, itemchecker: Add, Progress, % "ys Border Disabled hp w"itemchecker_width " range"cluster_passives_max "-"cluster_passives_optimal " BackgroundBlack c"color, % cluster_passives ;place progress bar on top of dummy label and inherit dimensions
		color1 := (color = itemchecker_t1_color) ? "Black" : "White"
		Gui, itemchecker: Add, Text, % "xp yp Border 0x200 Center BackgroundTrans wp hp c"color1, % cluster_passives*(-1) "/" cluster_passives_max*(-1) ;add actual text label
		If !InStr(Clipboard, "rarity: normal")
			Gui, itemchecker: Add, Progress, % "xs Background"divider_color " h"divider_height " w"itemchecker_width*itemchecker_width_segments,
	}
	
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// explicit area
	
	affix_groups_count := ""
	
	Loop, Parse, itemcheck_clip, | ;parse the item-info affix by affix
	{
		If (unique = 1) && !InStr(A_LoopField, "(") ;skip unscalable unique affix
			continue
		affix_groups_count := A_Index
		If (itemchecker_item_class != "base jewel")
			tier := unique ? "u" : InStr(A_LoopField, "tier:") ? SubStr(A_LoopField, InStr(A_LoopField, "tier: ") + 6, InStr(A_LoopField, ")") - InStr(A_LoopField, "tier: ") - 6) : InStr(A_LoopField, "crafted") ? "c" : "—" ;determine affix tier
		Else tier := "?"
		affix_name := unique ? "" : SubStr(A_LoopField, InStr(A_LoopField, """",,, 1) + 1, InStr(A_LoopField, """",,, 2) - InStr(A_LoopField, """",,, 1) - 1)
		mod := A_LoopField
		affix_original := A_LoopField
		affix_copy := StrReplace(A_LoopField, " (fractured)"), affix_copy := StrReplace(affix_copy, " (crafted)")
		affix_groups.Push(affix_copy)
		affix_groups_original.Push(A_LoopField)
		affix_names.Push(affix_name)
		affix_tiers.Push(tier)
		hybrid := LLK_InStrCount(A_LoopField, "`n") - 1
		If (item_type = "attack") && ((InStr(A_LoopField, "adds ") && InStr(A_LoopField, " damage") && !InStr(A_LoopField, "spell")) || InStr(A_LoopField, "increased attack speed") || InStr(A_LoopField, "increased physical damage"))
			attack_count += (tier <= 3) ? 1.5 : 1
		
		If !unique ;determine ilvl-requirements or mod weights
		{
			Loop, % itemchecker_mod_data[affix_name].Count() ;parse the data for the given affix-name
			{
				If InStr(affix_name, "veil") ;break if affix is veiled
				{
					item_level := 60
					Break
				}
				outer_loop := A_Index
				target_loop := 0
				mod_check := 0
				
				If (itemchecker_item_class = "base jewel") ;check if the data for the given affix-name has a special tag (some jewel affixes share their name with some non-jewel ones, so I had to tag them in order to get the correct weights)
				{
					tag_check := 0
					target_loop0 := ""
					Loop, % itemchecker_mod_data[affix_name].Count()
					{
						If itemchecker_mod_data[affix_name][A_Index].HasKey("LLK_tag")
							target_loop0 .= A_Index ","
						/*
						tag_check += itemchecker_mod_data[affix_name][A_Index].HasKey("LLK_tag")
						If (tag_check = 1)
						{
							target_loop := A_Index ;the correct information is stored in the n-th entry
							Break
						}
						*/
					}
				}
				
				If ((itemchecker_item_class = "base jewel") && (target_loop0 != "")) ;item is jewel and there is a tagged weight-entry
				{
					Loop, Parse, target_loop0, `,
					{
						If (A_LoopField = "")
							continue
						target_loop0 := A_LoopField
						Loop, % itemchecker_mod_data[affix_name][target_loop0]["strings"].Count()
						{
							parse := StrReplace(itemchecker_mod_data[affix_name][target_loop0]["strings"][A_Index], "1 Added Passive Skill is ")
							If InStr(mod, parse)
								target_loop := target_loop0
							mod_check += InStr(mod, parse) ? 1 : 0 ;confirm whether affix-name and mod-text correlate
						}
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
				
				If (!hybrid && (mod_check != 0)) || (hybrid && (mod_check >= 2)) ;there is confirmation
				{
					If (itemchecker_item_class != "base jewel")
						item_level := itemchecker_mod_data[affix_name][outer_loop]["level"] ;save the ilvl-requirement
					Else
					{
						read_loop := (target_loop = 0) ? outer_loop : target_loop
						Loop, % itemchecker_mod_data[affix_name][read_loop]["weights"].Count() ;parse all weights for the given affix
						{
							If LLK_ArrayHasVal(itemchecker_base_item_data[itemchecker_item_base]["tags"], itemchecker_mod_data[affix_name][read_loop]["weights"][A_Index]["tag"]) ;current tag correlates with the item's tag
							{
								tier := itemchecker_mod_data[affix_name][read_loop]["weights"][A_Index]["weight"] ;save the weight
								Break 2
							}
						}
					}
					Break
				} 
			}
		}
		height := 0
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
			
			If unique && !InStr(A_LoopField, "(")
				continue
			
			affix_lines += 1
			affix_divider += (affix_divider = "" && affix_type = "prefix") || (affix_divider = 1 && affix_type = "suffix") ? 1 : 0
			If (affix_divider = 2)
			{
				affix_divider += 1
				Gui, itemchecker: Add, Progress, % "xs w"itemchecker_width*itemchecker_width_segments " Disabled h"divider_height " Background"divider_color,
			}
			modline_copy := StrReplace(A_LoopField, " (fractured)"), modline_copy := StrReplace(modline_copy, " (crafted)")
			mod := betrayal A_LoopField ;StrReplace(A_LoopField, "[hybrid]") ;store mod-text in variable
			
			mod1 := (InStr(mod, "adds") || InStr(mod, "added") || (InStr(mod, "additional") && InStr(mod, "damage"))) && InStr(mod, "to") ? StrReplace(mod, "to", "|",, 1) : mod ;workaround for flat-dmg affixes where x and/or y in 'adds x to y damage' doesn't scale (unique vaal sword, maybe more)
			mod1 := StrReplace(mod1, " (fractured)")
			mods.Push(A_LoopField ";;" tier)
			
			roll := "" ;variable in which to store the numerical values of the affix
			offset := 0
			While (IsNumber(SubStr(mod1, InStr(mod1, "(") - 1 - offset, 1)) || (SubStr(mod1, InStr(mod1, "(") - 1 - offset, 1) = ".") || (SubStr(mod1, InStr(mod1, "(") - 1 - offset, 1) = "-"))
				offset += 1
			starting_point := InStr(mod1, "(") - offset
			Loop, Parse, % InStr(mod1, "(") ? SubStr(mod1, starting_point, InStr(mod1, ")",,, LLK_InStrCount(mod1, ")")) - starting_point + 1) : mod1 ;parse mod-text character by character
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
							roll%roll_count% := "" ;(InStr(mod, "reduced") && (InStr(mod, "(-") || InStr(mod, "--"))) ? "-" : ;'reduced' in mod-text signals negative value without minus-sign, so it needs to be added manually | also check if range even includes negative values, or if it's a negative value due to kalandra
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
				roll_min := (roll_count = 1) ? Min(roll1_1, roll1_2) : Min(roll1_1, roll1_2) + Min(roll2_1, roll2_2)
				roll_present := (roll_count = 1) ? roll1 : roll1 + roll2
				roll_max := (roll_count = 1) ? Max(roll1_1, roll1_2) : Max(roll1_1, roll1_2) + Max(roll2_1, roll2_2)
				If LLK_ItemCheckInvert(mod)
				{
					roll_min_copy := roll_min
					roll_min := roll_max * -1
					roll_present *= -1
					roll_max := roll_min_copy * -1
				}
			}
			Else
			{
				roll_min := 0
				roll_present := 100
				roll_max := 100
			}
			affixes.Push(mod) ;push mod-text, tier, and roll-values into array
			mod := StrReplace(mod, " (crafted)")
			mod := StrReplace(mod, " (fractured)")
			
			style := (A_Index = 2) ? "Section " : ""
			width := unique ? itemchecker_width*itemchecker_width_segments : itemchecker_width*(itemchecker_width_segments - 1.25)
			Gui, itemchecker: Add, Text, % style "xs Border Hidden BackgroundTrans w"width " vitemchecker_panel"affix_lines "_text HWNDhwnd_itemchecker_panel"affix_lines "_text", % unique ? mod : LLK_ItemCheckRemoveRollsText(mod) ;LLK_ItemCheckRemoveRollsText(mod, clipped_text)
			GuiControlGet, check_, Pos, % hwnd_itemchecker_panel%affix_lines%_text
			height_text := (check_h <= itemchecker_height) ? itemchecker_height : check_h
			color := unique ? "994C00" : "505050"
			Gui, itemchecker: Add, Progress, % "xp yp h"height_text " wp Border Disabled BackgroundBlack range"roll_min*100 "-" roll_max*100 " c"color, % roll_present*100
			clipped_text := ""
			If InStr(Clipboard, "forbidden shako") && (LLK_InStrCount(mod, "(") > 1)
				mod := SubStr(mod, 1, InStr(mod, "(",,, LLK_InStrCount(mod, "(")) - 1)
			Gui, itemchecker: Add, Text, % "xp yp wp hp Border Center BackgroundTrans HWNDmain_text", % unique ? mod : LLK_ItemCheckRemoveRollsText(mod) ;LLK_ItemCheckRemoveRollsText(mod, clipped_text)
			GuiControlGet, main_text_, Pos, %main_text%
			height += main_text_h
			If !unique
			{
				highlight_check := LLK_ItemCheckHighlight(mod)
				If (highlight_check = 0) ;mod is neither highlighted (teal) nor blacklisted (red)
					color := "Black"
				Else color := (highlight_check = 2) ? itemchecker_t7_color : (highlight_check = 1) ? itemchecker_t1_color : (highlight_check = -2) ? itemchecker_ilvl8_color : itemchecker_t6_color ;determine which is the case
				Gui, itemchecker: Add, Progress, % "x+0 hp w"itemchecker_width/4 " Border Disabled BackgroundBlack c"color "HWNDhwnd_itemchecker_panel"affix_lines "_button vitemchecker_panel"affix_lines "_button", 100
				Gui, itemchecker: Add, Text, % "xp yp hp wp Border BackgroundTrans gItemchecker vitemchecker_panel"affix_lines " HWNDhwnd_itemchecker_panel"affix_lines,
			}
			Loop, Parse, clipped_text, `,
			{
				If (A_Index = 1)
				{
					multi_rolls := (LLK_InStrCount(clipped_text, "-") > 1) ? 1 : 0
					rolls := 0
					clipped_text := ""
				}
				If (A_LoopField = "") || !InStr(A_LoopField, "-")
					continue
				rolls += 1
				clipped_text .= multi_rolls ? "roll #" rolls ": "A_LoopField "`n" : "roll: " A_LoopField "`n"
			}
			While (SubStr(clipped_text, 0) = " ")
				clipped_text := SubStr(clipped_text, 1, -1)
			itemchecker_panel%affix_lines%_tooltip := clipped_text
		}
		;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		;////////////////////////////////////////// tiers & icons area
		If !unique
		{
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
				Else color := "Black"
				If IsNumber(tier)
					tier /= 10
			}
			
			If LLK_ItemCheckAffixes(affix_name)
			{
				color := itemchecker_t0_color
				tier := !InStr(A_LoopField, "(crafted)") ? "—" : "c"
				affix_tiers[affix_groups_count] := tier
			}
			
			itemchecker_affixgroup%affix_groups_count%_color := InStr(affix_original, "(fractured)") ? itemchecker_t7_color : color
			
			itemchecker_override := 0
			color1 := (color = "Black") ? "White" : "Black"
			Switch hybrid
			{
				Case 0:
				highlight_check := LLK_ItemCheckHighlight(SubStr(affix_copy, InStr(affix_copy, "`n") + 1))
				If enable_itemchecker_override && (highlight_check < 0)
				{
					color := itemchecker_t6_color
					itemchecker_override := 1
				}
				Else If (tier = 1) && (highlight_check > 0)
				{
					color := "ffffff"
					color1 := "Red"
				}
				Case 1:
				mod_check := SubStr(affix_copy, InStr(affix_copy, "`n") + 1, InStr(affix_copy, "`n",,, 2) - InStr(affix_copy, "`n") - 1)
				mod_check1 := SubStr(affix_copy, InStr(affix_copy, "`n",,, 2) + 1)
				highlight_check := LLK_ItemCheckHighlight(StrReplace(mod_check, " (fractured)"))
				highlight_check1 := LLK_ItemCheckHighlight(StrReplace(mod_check1, " (fractured)"))
				If enable_itemchecker_override && (highlight_check < 0) && (highlight_check1 < 0)
				{
					color := itemchecker_t6_color
					itemchecker_override := 1
				}
				Else If (tier = 1) && (highlight_check > 0) && (highlight_check1 > 0)
				{
					color := "ffffff"
					color1 := "Red"
				}
				Case 2:
				mod_check := SubStr(affix_copy, InStr(affix_copy, "`n") + 1, InStr(affix_copy, "`n",,, 2) - InStr(affix_copy, "`n") - 1)
				mod_check1 := SubStr(affix_copy, InStr(affix_copy, "`n",,, 2) + 1, InStr(affix_copy, "`n",,, 3) - InStr(affix_copy, "`n",,, 2) - 1)
				mod_check2 := SubStr(affix_copy, InStr(affix_copy, "`n",,, 3) + 1)
				highlight_check := LLK_ItemCheckHighlight(StrReplace(mod_check, " (fractured)"))
				highlight_check1 := LLK_ItemCheckHighlight(StrReplace(mod_check1, " (fractured)"))
				highlight_check2 := LLK_ItemCheckHighlight(StrReplace(mod_check2, " (fractured)"))
				If enable_itemchecker_override && (highlight_check < 0) && (highlight_check1 < 0) && (highlight_check2 < 0)
				{
					color := itemchecker_t6_color
					itemchecker_override := 1
				}
				Else If (tier = 1) && (highlight_check > 0) && (highlight_check1 > 0) && (highlight_check2 > 0)
				{
					color := "ffffff"
					color1 := "Red"
				}
			}
			
			highlight_check := LLK_ItemCheckHighlight(modline_copy)
			If (itemchecker_item_class = "base jewel") && (highlight_check = 1)
				color := itemchecker_t1_color
			
			If !itemchecker_override && (LLK_ItemCheckAffixes(affix_name) || InStr(affix_original, "(crafted)"))
				color := itemchecker_t0_color
			
			If InStr(affix_original, "(fractured)") ;override color in case mod is fractured
				color := itemchecker_t7_color
			
			width := enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel") || LLK_ItemCheckAffixes(affix_name, 1) || LLK_ItemCheckStats(SubStr(affix_copy, InStr(affix_copy, "`n") + 1), item_type) || InStr(affix_original, "(crafted)") ? itemchecker_width*0.5 : itemchecker_width
			Gui, itemchecker: Add, Progress, % "ys w"width " h"height " Border Disabled BackgroundBlack c"color " vItemchecker_affixgroup"affix_groups_count "_tier", 100
			Gui, itemchecker: Add, Text, % "xp yp hp wp +0x200 Center Border BackgroundTrans c"color1 " vItemchecker_affixgroup"affix_groups_count "_tier_text", % tier
			
			If LLK_ItemCheckAffixes(affix_name, 1) || LLK_ItemCheckStats(SubStr(affix_copy, InStr(affix_copy, "`n") + 1), item_type) || enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel") || InStr(affix_original, "(crafted)")
			{
				If enable_itemchecker_ilvl && (itemchecker_item_class != "base jewel")
				{
					If (item_level >= 83)
						color := itemchecker_ilvl1_color
					Else If (item_level >= 78)
						color := itemchecker_ilvl2_color
					Else If (item_level >= 73)
						color := itemchecker_ilvl3_color
					Else If (item_level >= 68)
						color := itemchecker_ilvl4_color
					Else If (item_level >= 64)
						color := itemchecker_ilvl5_color
					Else If (item_level >= 60)
						color := itemchecker_ilvl6_color
					Else If (item_level <= 59)
						color := itemchecker_ilvl7_color
					Else If (item_level <= 55)
						color := itemchecker_ilvl8_color
					
					color0 := color ;pre-override color
					
					If LLK_ItemCheckAffixes(affix_name) || InStr(affix_original, "(crafted)")
						color := itemchecker_t0_color
					
					If enable_itemchecker_override && itemchecker_override
						color := itemchecker_t6_color
					
					If InStr(affix_original, "(fractured)") ;override color in case mod is fractured
						color := itemchecker_t7_color
					
					itemchecker_affixgroup%affix_groups_count%_color2 := color
				}
				
				style_icon := enable_itemchecker_override && itemchecker_override && !InStr(affix_original, "(fractured)") ? "Hidden" : ""
				
				Gui, itemchecker: Add, Progress, % "ys wp hp Border Disabled BackgroundBlack c"color " vItemchecker_affixgroup"affix_groups_count "_tier2", 100
				If (!enable_itemchecker_ilvl && (LLK_ItemCheckAffixes(affix_name, 1) || LLK_ItemCheckStats(SubStr(affix_copy, InStr(affix_copy, "`n") + 1), item_type))) || (itemchecker_item_class = "base jewel")
				{
					Gui, itemchecker: Add, Text, % "xp yp hp wp +0x200 Center Border BackgroundTrans cBlack",
					type := InStr(affix_original, "(crafted)") ? "mastercraft" : (LLK_ItemCheckStats(SubStr(affix_copy, InStr(affix_copy, "`n") + 1), item_type) != 0) ? LLK_ItemCheckStats(SubStr(affix_copy, InStr(affix_copy, "`n") + 1), item_type) : LLK_ItemCheckAffixes(affix_name, 1)
					If (height <= itemchecker_height)
						Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center "style_icon " BackgroundTrans h"itemchecker_height-2 " w-1 vItemchecker_affixgroup"affix_groups_count "_icon", % "img\GUI\item info\"type ".png"
					Else Gui, itemchecker: Add, Picture, % "xp+1 yp+"height//2 - itemchecker_height//2 + 1 " Center "style_icon " BackgroundTrans h"itemchecker_height-2 " w-1 vItemchecker_affixgroup"affix_groups_count "_icon", % "img\GUI\item info\"type ".png"
				}
				Else
				{
					If LLK_ItemCheckAffixes(affix_name) || InStr(affix_original, "(crafted)")
					{
						type := InStr(affix_original, "(crafted)") ? "mastercraft" : LLK_ItemCheckAffixes(affix_name)
						Gui, itemchecker: Add, Text, % "xp yp hp wp +0x200 Center Border BackgroundTrans cBlack",
						If (height <= itemchecker_height)
							Gui, itemchecker: Add, Picture, % "xp+1 yp+1 Center "style_icon " BackgroundTrans h"itemchecker_height-2 " w-1 vItemchecker_affixgroup"affix_groups_count "_icon", % "img\GUI\item info\"type ".png"
						Else Gui, itemchecker: Add, Picture, % "xp+1 yp+"height//2 - itemchecker_height//2 + 1 " Center "style_icon " BackgroundTrans h"itemchecker_height-2 " w-1 vItemchecker_affixgroup"affix_groups_count "_icon", % "img\GUI\item info\"type ".png"
					}
					Else
					{
						itemchecker_affixgroup%affix_groups_count%_color2 := InStr(affix_original, "(fractured)") ? itemchecker_t7_color : color0
						color1 := (color = "ffffff") ? "Red" : "Black"
						Gui, itemchecker: Add, Text, % "xp yp hp wp +0x200 Center Border BackgroundTrans c"color1 " vItemchecker_affixgroup"affix_groups_count "_tier2_text", % item_level
					}
				}
			}
		}
	}
	/*
	If (affix_groups_count = "") && (cluster_type = "") && (item_type != "defense") && (item_type != "attack")
	{
		LLK_ToolTip("item is not scalable")
		;Gui, itemchecker: Destroy
		;hwnd_itemchecker := ""
		;Return
	}
	*/
	Gui, itemchecker: Show, NA x10000 y10000 ;show GUI outside of monitor
	WinGetPos,,, width, height, ahk_id %hwnd_itemchecker% ;get GUI dimensions
	If (width < 100)
	{
		LLK_ToolTip("item-info: nothing to display", 1)
		Gui, itemchecker: Destroy
		hwnd_itemchecker := ""
		Return
	}
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
	global
	
	itemchecker_highlight_parse := "+-.()%"
	itemchecker_rule_applies := ""
	;string := LLK_ItemCheckStrReplace(string)
	string := StrReplace(string, "unique: ")
	string := StrReplace(string, "pinnacle: ")
	string := StrReplace(string, " sec)")
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
			itemchecker_rule_applies := -1
		If enable_itemchecker_rule_spells && (InStr(string, " to spell") || (InStr(string, "spell damage") && !InStr(string, "suppress") && !InStr(string, "block")) || InStr(string, " for spell") || InStr(string, "spell skill") || InStr(string, "added spell") || (InStr(string, "with spell") && !InStr(string, "gain ")))
			itemchecker_rule_applies := -1
		If enable_itemchecker_rule_attacks && (InStr(string, "increased physical damage") || (InStr(string, "adds") && InStr(string, " damage") && !InStr(string, "to spell") && (item_type = "attack")) || ((InStr(string, "increased") || InStr(string, "added") || InStr(string, "adds")) && (InStr(string, "with") && !InStr(string, "speed") || InStr(string, "to")) && InStr(string, " attack")) || InStr(string, "attack damage"))
			itemchecker_rule_applies := -1
		If enable_itemchecker_rule_crit && (InStr(string, "critical strike"))
			itemchecker_rule_applies := -1
		
		If (item_type = "attack") || (itemchecker_rule_applies != "")
		{
			If (itemchecker_rule_applies = "") && enable_itemchecker_rule_weapon_res && (InStr(string, "resistance") && !InStr(string, "penetrate"))
				itemchecker_rule_applies := -1
			If (itemchecker_rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip("blocked by global rule")
					Return -1
				}
				Return itemchecker_rule_applies
			}
		}
		
		If ((item_type = "defense") || (item_type = "jewelry"))
		{
			If enable_itemchecker_rule_res && InStr(string, "to ") && InStr(string, " resistance") && !InStr(string, "minion")
				itemchecker_rule_applies := 1
			If (itemchecker_rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip("blocked by global rule")
					Return -1
				}
				Return itemchecker_rule_applies
			}
		}
	}
	implicit_check := !implicit ? "" : "_implicits"
	If (mode = 0) ;check if mod is highlighted/blacklisted in order to determine color
	{
		If !implicit && (itemchecker_meta_itemclass != "")
		{
			If InStr(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|")
				Return 2
			Else If InStr(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
				Return -2
		}
		If implicit && !InStr(itemchecker_highlight_implicits, "|" string "|") && !InStr(itemchecker_blacklist_implicits, "|" string "|")
			Return 0
		If !implicit && !InStr(itemchecker_highlight%implicit_check%, "|" string "|") && !InStr(itemchecker_blacklist%implicit_check%, "|" string "|") && !InStr(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|") && !InStr(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
			Return 0
		Else If InStr(itemchecker_highlight%implicit_check%, "|" string "|")
			Return 1
		Else If InStr(itemchecker_blacklist%implicit_check%, "|" string "|")
			Return -1
	}
	If (mode = 1) ;mod was left-clicked
	{
		If !implicit && InStr(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|")
		{
			LLK_ToolTip("clear class-specific highlighting first", 1.5)
			Return -1
		}
		If !InStr(itemchecker_highlight%implicit_check%, "|" string "|") ;mod is not highlighted: add it to highlighted mods and save
		{
			itemchecker_highlight%implicit_check% .= "|" string "|"
			IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "highlight" : "highlight implicits"
			If InStr(itemchecker_blacklist%implicit_check%, "|" string "|")
			{
				itemchecker_blacklist%implicit_check% := StrReplace(itemchecker_blacklist%implicit_check%, "|" string "|")
				IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "blacklist" : "blacklist implicits"
			}
			Return 1
		}
		Else ;mod is highlighted: remove it from highlighted mods and save
		{
			itemchecker_highlight%implicit_check% := StrReplace(itemchecker_highlight%implicit_check%, "|" string "|")
			IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "highlight" : "highlight implicits"
			Return 0
		}
	}
	Else If (mode = -1) ;mod was long-leftclicked
	{
		If !InStr(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|") ;mod is not highlighted: add it to class-specific highlighted mods and save
		{
			itemchecker_highlight_%itemchecker_meta_itemclass% .= "|" string "|"
			IniWrite, % itemchecker_highlight_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, highlight %itemchecker_meta_itemclass%
			If InStr(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
			{
				itemchecker_blacklist_%itemchecker_meta_itemclass% := StrReplace(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
				IniWrite, % itemchecker_blacklist_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, blacklist %itemchecker_meta_itemclass%
			}
			Return 2
		}
		Else ;mod is highlighted: remove it from class-specific highlighted mods and save
		{
			itemchecker_highlight_%itemchecker_meta_itemclass% := StrReplace(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|")
			IniWrite, % itemchecker_highlight_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, highlight %itemchecker_meta_itemclass%
			Return 0
		}
	}
	If (mode = 2) ;mod was right-clicked
	{
		If !implicit && InStr(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
		{
			LLK_ToolTip("clear class-specific highlight first")
			Return -1
		}
		If !InStr(itemchecker_blacklist%implicit_check%, "|" string "|") ;mod is not blacklisted: add it to blacklisted mods and save
		{
			itemchecker_blacklist%implicit_check% .= "|" string "|"
			IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "blacklist" : "blacklist implicits"
			If InStr(itemchecker_highlight%implicit_check%, "|" string "|")
			{
				itemchecker_highlight%implicit_check% := StrReplace(itemchecker_highlight%implicit_check%, "|" string "|")
				IniWrite, % itemchecker_highlight%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "highlight" : "highlight implicits"
			}
			Return 1
		}
		Else ;mod is blacklisted: remove it from blacklisted mods and save
		{
			itemchecker_blacklist%implicit_check% := StrReplace(itemchecker_blacklist%implicit_check%, "|" string "|")
			IniWrite, % itemchecker_blacklist%implicit_check%, ini\item-checker.ini, highlighting %itemchecker_profile%, % !implicit ? "blacklist" : "blacklist implicits"
			Return 0
		}
	}
	Else If (mode = -2)
	{
		If !InStr(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
		{
			itemchecker_blacklist_%itemchecker_meta_itemclass% .= "|" string "|"
			IniWrite, % itemchecker_blacklist_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, blacklist %itemchecker_meta_itemclass%
			If InStr(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|")
			{
				itemchecker_highlight_%itemchecker_meta_itemclass% := StrReplace(itemchecker_highlight_%itemchecker_meta_itemclass%, "|" string "|")
				IniWrite, % itemchecker_highlight_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, highlight %itemchecker_meta_itemclass%
			}
			Return 2
		}
		Else
		{
			itemchecker_blacklist_%itemchecker_meta_itemclass% := StrReplace(itemchecker_blacklist_%itemchecker_meta_itemclass%, "|" string "|")
			IniWrite, % itemchecker_blacklist_%itemchecker_meta_itemclass%, ini\item-checker.ini, highlighting %itemchecker_profile%, blacklist %itemchecker_meta_itemclass%
			Return 0
		}
	}
}

LLK_ItemCheckStrReplace(string, reverse := 0) ;was experimenting with a 'compact' mode ;on hold until tooltip is more or less finalized
{
	replace := ["of physical attack damage leeched as life", "life-leech (phys attacks)", "of physical attack damage leeched as mana", "mana-leech (phys attacks)", "of damage taken recouped as life", "life-recoup", "with one handed weapons", "(1-hand weapon)"
	, "with one handed melee weapons", "(1-hand melee weapon)", "with wand attacks", "(wand attacks)", "for 4 seconds", "(4 sec)", "movement speed", "move-speed", "if you've killed recently", "(killed recently)", "stun and block", "stun && block"
	, "projectiles", "proj", "projectile", "proj", "regeneration rate", "regen rate", "critical strike", "crit", "resistances", "res", "damage over time", "dot"
	, "multiplier", "multi", "maximum", "max", "suppress spell damage", "suppress", "damage", "dmg", "increased", "inc", "accuracy rating", "accuracy"
	, "resistance", "res", "physical", "phys", "regenerate", "regen", " per second", "/sec", "intelligence", "int", "strength", "str", "dexterity", "dex", "elemental", "ele", "energy shield", "es", "evasion rating", "evasion", "while holding a shield", "(shield)"
	, "while dual wielding", "(dual wield)", "with lightning skills", "(lightning skills)", "rarity of items found", "rarity", "quantity of items found", "quant"]
	
	Loop, % replace.Length()
	{
		If (reverse = 0) && (Mod(A_Index, 2) = 0)
			continue
		Else If (reverse = 1) && (Mod(A_Index, 2) != 0)
			continue
		string := (reverse = 0) ? StrReplace(string, replace[A_Index], replace[A_Index + 1]) : StrReplace(string, replace[A_Index], replace[A_Index - 1])
	}
	Return string
}

LLK_ItemCheckStats(string, item_type := "")
{
	resists := "fire,lightning,cold,chaos"
	stats := "strength,dexterity,intelligence"
	Loop, Parse, string, `n
	{
		If (A_LoopField = "")
			continue
		
		If (item_type = "attack")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, "adds ") && InStr(string, A_LoopField) && InStr(string, "damage") && !InStr(string, "spells")
					Return A_LoopField "_attack"
			}
			If (InStr(string, "adds ") && InStr(string, "physical") && InStr(string, "damage") && !InStr(string, "spells")) || InStr(string, "increased physical damage")
				Return "phys"
		}
		
		If InStr(string, "minion")
			Return "minion"
		Else If InStr(string, "totem")
			Return "totems"
		Else If InStr(string, "increased") && InStr(string, "damage")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_damage"
			}
			If InStr(string, "spell")
				Return "spell_damage"
			If InStr(string, "global physical")
				Return "phys"
		}
		Else If InStr(string, "adds") && InStr(string, "damage") && InStr(string, "to spells")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_spell"
			}
			If InStr(string, "physical")
				Return "phys_spell"
		}
		Else If InStr(string, "adds") && InStr(string, "damage to attacks")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_attack"
			}
			If InStr(string, "physical")
				Return "phys"
		}
		Else If InStr(string, "critical strike")
			Return "crit"
		Else If InStr(string, "attack speed")
			Return "speed"
		Else If InStr(string, "all elemental resistances") && !InStr(string, "penetrate")
			Return "allres"
		Else If InStr(string, "all attributes") || InStr(string, "increased attributes")
			Return "allstats"
		Else if InStr(string, "to maximum life") || InStr(string, "increased maximum life")
			Return "life"
		
		Loop, Parse, % resists "," stats, `,
		{
			If InStr(string, A_LoopField) && !InStr(string, " and ") && ((InStr(resists, A_LoopField) && InStr(string, "resistance") && !InStr(string, " enem") && !InStr(string, "penetrate")) || InStr(stats, A_LoopField))
				Return A_LoopField
			Else If InStr(string, A_LoopField) && InStr(stats, A_LoopField) && InStr(string, " and ")
				Return "allstats"
		}
		
		If InStr(string, "armour and evasion")
			Return "armor_evasion"
		If InStr(string, "armour and energy")
			Return "armor_energy"
		If InStr(string, "evasion and energy")
			Return "evasion_energy"
		
		If InStr(string, "+") && InStr(string, "to armour") && InStr(string, "to evasion rating")
			Return "armor_evasion"
		If InStr(string, "+") && InStr(string, "to armour") && InStr(string, "to maximum energy shield")
			Return "armor_energy"
		If InStr(string, "+") && InStr(string, "to evasion rating") && InStr(string, "to maximum energy shield")
			Return "evasion_energy"
		
		If (InStr(string, "increased ") && (InStr(string, "armour"))) || (InStr(string, "+") && InStr(string, " to ") && (InStr(string, "armour")))
			Return "armor"
		If (InStr(string, "increased ") && InStr(string, "evasion")) || (InStr(string, "+") && InStr(string, " to ") && InStr(string, "evasion"))
			Return "evasion"
		If InStr(string, "+") && InStr(string, "to maximum energy shield") || (InStr(string, "increased energy shield") && !InStr(string, "recharge")) || InStr(string, "increased maximum energy shield")
			Return "energy"
		If InStr(string, "+") && InStr(string, "to ward") || (InStr(string, "increased ward"))
			Return "ward"
		
		If InStr(string, " block") && !InStr(string, "block recovery")
			Return "block"
		
		If InStr(string, "to maximum mana") || InStr(string, "increased maximum mana")
			Return "mana"
		
		If InStr(string, "regenerate") && InStr(string, "mana per second") || InStr(string, "increased mana regeneration rate")
			Return "mana_regen"
		
		If InStr(string, "flask")
			Return "flasks"
		
		If InStr(string, "regenerate") && InStr(string, "life per second") || InStr(string, "increased life regeneration rate")
			Return "life_regen"
		
		If InStr(string, "to level of ") && InStr(string, " gem")
			Return "gem_level"
	}
	Return 0
}

LLK_ItemCheckAffixes(string, mode := 0)
{
	parse := "bestiary,delve,incursion,syndicate"
	If mode
		parse .= ",shaper,elder,crusader,redeemer,hunter,warlord,essence"
	bestiary := ["saqawal", "farrul", "craiceann", "fenumus"]
	delve := ["subterranean", "of the underground"]
	incursion := ["Citaqualotl", "Guatelitzi", "Matatl", "Tacati", "Topotante", "Xopec"]
	syndicate := ["chosen", "veil", "of the order"]
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
			If InStr(string, %A_LoopField%[A_Index]) && !InStr(string, "flame shaper's")
				Return A_LoopField
		}
	}
	Return 0
}

LLK_ItemCheckGear(slot)
{
	global equipped_mainhand, equipped_offhand, equipped_helmet, equipped_body, equipped_amulet, equipped_ring1, equipped_ring2, equipped_gloves, equipped_boots, equipped_belt, itemchecker_metadata
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
		
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") || InStr(A_LoopField, "{ Allocated Crucible") ;|| InStr(A_LoopField, "crafted")
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
}

LLK_ItemCheckInvert(mod)
{
	If InStr(mod, "(-") && InStr(mod, "damage taken") || InStr(mod, "lose") && !InStr(mod, "enem")
	|| (InStr(mod, "+") || InStr(mod, "increased")) && ((InStr(mod, "strength") || InStr(mod, "dexterity") || InStr(mod, "intelligence") || InStr(mod, "attribute")) && InStr(mod, "requirement") || InStr(mod, "damage taken") || InStr(mod, "charges per use"))
	|| (InStr(mod, "reduced") || InStr(mod, "less")) && (InStr(mod, "elemental resistances") || InStr(mod, "life") || (!InStr(mod, "take") && InStr(mod, "damage")) || InStr(mod, "rarity") || InStr(mod, "quantity") || (!InStr(mod, "enem") && InStr(mod, "stun and block"))
	|| (!InStr(mod, "--") && InStr(mod, "skill effect duration")) || InStr(mod, "cast speed") || InStr(mod, "maximum mana") || InStr(mod, "throwing speed") || InStr(mod, "strength") || InStr(mod, "dexterity") || InStr(mod, "intelligence") || InStr(mod, "amount recovered"))
	Return 1
	Else Return 0
}

LLK_ItemCheckRemoveRollsText(string, ByRef removed_text := "")
{
	removed_text := ""
	Loop, % LLK_InStrCount(string, "(")
	{
		parse_remove%A_Index% := SubStr(string, InStr(string, "(",,, A_Index), InStr(string, ")",,, A_Index) - InStr(string, "(",,, A_Index) + 1)
		removed_text .= parse_remove%A_Index% ","
	}
	loop := 1
	parse := string
	string_copy := string
	While InStr(parse, parse_remove%loop%) && (parse_remove%loop% != "")
	{
		If InStr(parse_remove%loop%, "sec)")
		{
			loop += 1
			continue
		}
		If (A_Index > LLK_InStrCount(string_copy, "("))
			break
		parse := InStr(parse, " " parse_remove%loop%) ? StrReplace(parse, " " parse_remove%loop%) : StrReplace(parse, parse_remove%loop%)
		loop += 1
	}
	Return parse
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
						If (A_LoopField = "chaos")
							continue
						to_%A_LoopField%_resistance += parse
						test .= InStr(test, ",to_"A_LoopField "_resistance,") ? "" : "to_"A_LoopField "_resistance,"
					}
					continue
				}
				Else If (InStr(parse_name, "resistance") && InStr(parse_name, "and") && !InStr(parse_name, "minion") && !InStr(parse_name, "maximum"))
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
	
	If !itemchecker_highlightable && (itemchecker_win_hover = hwnd_itemchecker)
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