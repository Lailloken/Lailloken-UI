Bestiary_search:
If (A_Gui = "")
{
	Gui, bestiary_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_bestiary_menu
	Gui, bestiary_menu: Margin, 4, 2
	Gui, bestiary_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, bestiary_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, bleed
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, curse
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, freeze
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, ignite
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, poison
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, shock
	MouseGetPos, mouseXpos, mouseYpos
	Gui, bestiary_menu: Show, x%mouseXpos% y%mouseYpos%
	Return
}
If (A_GuiControl = "curse")
	clipboard := "warding"
Else If (A_GuiControl = "bleed")
	clipboard := "sealing|lizard"
Else If (A_GuiControl = "shock")
	clipboard := "earthing|conger"
Else If (A_GuiControl = "freeze")
	clipboard := "convection|deer"
Else If (A_GuiControl = "ignite")
	clipboard := "damping|urchin"
Else If (A_GuiControl = "poison")
	clipboard := "antitoxin|skunk"
Else clipboard := ""
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
SendInput, ^{f}^{v}
Gui, bestiary_menu: Destroy
Return