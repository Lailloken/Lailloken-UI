Init_itemchecker:
IniRead, itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods, %A_Space%
IniRead, itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods, %A_Space%
Return

Itemchecker:
;Function quick-jump: LLK_ItemCheck(), LLK_ItemCheckHighlight()
If (A_Gui = "itemchecker")
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