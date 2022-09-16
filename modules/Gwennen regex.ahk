Gwennen_search:
If (A_GuiControl = "gwennen_regex_edit")
{
	Gui, gwennen_setup: Submit
	IniWrite, %gwennen_regex_edit%, ini\gwennen.ini, regex, regex
	Gui, gwennen_setup: Destroy
	hwnd_gwennen_setup := ""
	Return
}
start := A_TickCount
While GetKeyState(ThisHotkey_copy, "P")
{
	If (A_TickCount >= start + 300)
	{
		Gui, gwennen_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gwennen_setup
		Gui, gwennen_setup: Margin, 12, 4
		Gui, gwennen_setup: Color, Black
		WinSet, Transparent, %trans%
		Gui, gwennen_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
		Gui, gwennen_setup: Add, Link, % "Section HWNDlink_text", <a href="https://xanthics.github.io/poe_gen_gwennen/">regex-string generator by xanthics</a>
		Gui, gwennen_setup: Font, % "s"fSize0 - 4
		Gui, gwennen_setup: Add, Edit, xs wp Section vgwennen_regex_edit gGwennen_search HWNDmain_text BackgroundTrans center cBlack,
		Gui, gwennen_setup: Font, % "s"fSize0
		Gui, gwennen_setup: Show
		LLK_Overlay("gwennen_setup", "show", 0)
		ControlFocus,, ahk_id %link_text%
		KeyWait, %ThisHotkey_copy%
		Return
	}
}
IniRead, gwennen_check, ini\gwennen.ini, regex, regex
If (hotstringboard = "") && (gwennen_check = "ERROR" || gwennen_check = "")
{
	LLK_ToolTip("no regex string saved")
	Return
}
IniRead, gwennen_regex, ini\gwennen.ini, regex, regex
gwennen_regex = "%gwennen_regex%"
If (hotstringboard = "") && (gwennen_regex != "ERROR" && gwennen_regex != "")
{
	Clipboard := gwennen_regex
	ClipWait
	SendInput, ^{f}^{v}
}
Return

Init_gwennen:
IniRead, gwennen_regex, ini\gwennen.ini, regex, regex
Return