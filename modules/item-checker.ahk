Init_itemchecker:
IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
IniRead, fSize_offset_itemchecker, ini\item-checker.ini, UI, font-offset, 0
itemchecker_default_colors := ["3399ff", "00ff00", "008000", "ffff00", "ff8c00", "dc143c", "800000"]
IniRead, itemchecker_t0_color, ini\item-checker.ini, UI, tier 0, % "3399ff"
IniRead, itemchecker_t1_color, ini\item-checker.ini, UI, tier 1, % "00ff00"
IniRead, itemchecker_t2_color, ini\item-checker.ini, UI, tier 2, % "008000"
IniRead, itemchecker_t3_color, ini\item-checker.ini, UI, tier 3, % "ffff00"
IniRead, itemchecker_t4_color, ini\item-checker.ini, UI, tier 4, % "ff8c00"
IniRead, itemchecker_t5_color, ini\item-checker.ini, UI, tier 5, % "dc143c"
IniRead, itemchecker_t6_color, ini\item-checker.ini, UI, tier 6, % "800000"
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
	Loop 7
	{
		value := A_Index - 1
		StringLower, itemchecker_t%value%_color, itemchecker_t%value%_color
		IniWrite, % itemchecker_t%value%_color, ini\item-checker.ini, UI, tier %value%
	}
	If WinExist("ahk_id " hwnd_itemchecker)
		LLK_ItemCheck(1)
	Return
}

If (A_Gui = "itemchecker") ;an item affix was clicked
{
	GuiControlGet, itemchecker_mod,, % A_GuiControl
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