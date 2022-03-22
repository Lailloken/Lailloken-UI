#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "LLK_Rightclick")
SetKeyDelay, 200
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
OnExit, Exit
Menu, Tray, Tip, Lailloken UI
#Include Class_CustomFont.ahk
font1 := New CustomFont("Fontin-SmallCaps.ttf")

If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

GroupAdd, poe_window, ahk_exe PathOfExile.exe
GroupAdd, poe_window, ahk_exe PathOfExile_x64.exe
GroupAdd, poe_window, ahk_exe PathOfExileSteam.exe
GroupAdd, poe_window, ahk_exe PathOfExile_x64Steam.exe
GroupAdd, poe_window, ahk_exe GeForceNOW.exe

; Seconds until LUI will exit if PoE is not detected. -1 to disable.
IniRead, startup_timeout, ini\config.ini, Settings, startup_timeout
If startup_timeout is not number
	IniWrite, % startup_timeout := 60, ini\config.ini, Settings, startup_timeout
timeout_time := startup_timeout * 1000 + A_TickCount
timeout := 1
While !WinExist("ahk_group poe_window")
{
	If (startup_timeout >= 0 && A_TickCount >= timeout_time)
		ExitApp
	Sleep, 1000
}

global xScreenOffset, yScreenOffset, poe_width, poe_height
WinGetPos, xScreenOffset, yScreenOffset, poe_width, poe_height, ahk_group poe_window

IniRead, fSize0, ini\resolutions.ini, %poe_height%p, font-size0
IniRead, fSize1, ini\resolutions.ini, %poe_height%p, font-size1

IniRead, force_resolution, ini\config.ini, Settings, force-resolution
If (force_resolution = "") || (force_resolution = "ERROR")
{
	IniWrite, 0, ini\config.ini, Settings, force-resolution
	force_resolution := 0
}

IniRead, forced_resolution, ini\config.ini, Settings, custom-height
If (force_resolution = 1)
{
	If forced_resolution is not number
	{
		IniRead, resolutions_all, ini\resolutions.ini
		Loop, Parse, resolutions_all, `n,`n
		{
			If (poe_height >= StrReplace(A_LoopField, "p", "")) && !(InStr(A_LoopField, "768") || InStr(A_LoopField, "1024") || InStr(A_LoopField, "1050"))
				resolutionsDDL := (resolutionsDDL = "") ? StrReplace(A_LoopField, "p", "") : StrReplace(A_LoopField, "p", "") "|" resolutionsDDL 
		}
		Gui, resolutionGUI: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
		hwnd_resolutionGUI := WinExist()
		Gui, resolutionGUI: Margin, 6, 10
		Gui, resolutionGUI: Color, Black
		WinSet, Transparent, 220
		Gui, resolutionGUI: Font, s%fSize0% cWhite, Fontin SmallCaps
		Gui, resolutionGUI: Add, Text, BackgroundTrans, set custom resolution
		Gui, resolutionGUI: Font, s%fSize1%
		Gui, resolutionGUI: Add, Checkbox, BackgroundTrans vcheck0, remember settings
		Gui, resolutionGUI: Add, Text, BackgroundTrans Section HWNDmain_text, %poe_width% x
		ControlGetPos,,, width,,, ahk_id %main_text%
		Gui, resolutionGUI: Add, DDL, % "ys w"width*2 " vforced_resolution gResolution_choice", %resolutionsDDL%
		Gui, resolutionGUI: Show, Center AutoSize
		While WinExist("ahk_id " hwnd_resolutionGUI)
		{
			If !WinExist("ahk_group poe_window")
				ExitApp
			Sleep, 1000
		}
		If (check0 = 1)
			IniWrite, %forced_resolution%, ini\config.ini, Settings, custom-height
	}
	If (forced_resolution > poe_height)
	{
		MsgBox, Incorrect configuration detected: custom height > current height`nThe script will now exit.
		ExitApp
	}
	WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %forced_resolution%
	poe_height := forced_resolution
}

global hwnd_archnemesis_window, all_nemesis, trans := 220, guilist, xWindow, xWindow1, fSize0, fSize1, Burn_number, reverse := 0, click := 1, sorting_order := "descending", sorting := "quantity", background_scanned := 0, auto_highlight := 0, previous_highlight
global archnemesis := 0, archnemesis1_x, archnemesis1_y, archnemesis1_color, archnemesis2_x, archnemesis2_y, archnemesis2_color, archnemesis_inventory, arch_inventory := [], pixelsearch_variation

IniRead, all_nemesis, ini\db_archnemesis.ini,
all_nemesis_unsorted := "-empty-`n" all_nemesis
Loop, Parse, all_nemesis, `n,`n
{
	all_nemesis_inverted := (A_Index = 1) ? A_LoopField "," : A_LoopField "," all_nemesis_inverted
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (read != "") && (read != "ERROR")
		global arch_recipes := (arch_recipes = "") ? A_LoopField "," : A_LoopField "," arch_recipes
	If (read = "") || (read = "ERROR")
		global arch_bases := (arch_bases = "") ? A_LoopField "," : A_LoopField "," arch_bases
}
arch_recipes_sorted := arch_recipes
Sort, arch_recipes_sorted, C D`,
arch_bases_sorted := arch_bases
Sort, arch_bases_sorted, C D`,
Sort, all_nemesis, C D`n

IniRead, previous_highlight, ini\config.ini, Archnemesis, previous-highlight
If (previous_highlight = "ERROR")
{
	previous_highlight := ""
	IniWrite, %previous_highlight%, ini\config.ini, Archnemesis, previous-highlight
}
IniRead, archnemesis_inventory, ini\config.ini, Archnemesis, inventory
Loop, 9
{
	If InStr(archnemesis_inventory, A_Index)
	{
		archnemesis_inventory := ""
		break
	}
}
If (archnemesis_inventory != "") && (archnemesis_inventory != "ERROR")
{
	Loop, Parse, archnemesis_inventory, `,,`,
		arch_inventory.Push(A_LoopField)
}
If (arch_inventory.Length() != 64)
{
	archnemesis_inventory := ""
	arch_inventory := []
}

IniRead, archnemesis1_x, ini\resolutions.ini, %poe_height%p, xCoord1
IniRead, archnemesis2_x, ini\resolutions.ini, %poe_height%p, xCoord2
IniRead, archnemesis1_y, ini\resolutions.ini, %poe_height%p, yCoord
IniRead, archnemesis2_y, ini\resolutions.ini, %poe_height%p, yCoord
archnemesis1_x += xScreenOffset
archnemesis2_x += xScreenOffset
archnemesis1_y += yScreenOffset
archnemesis2_y += yScreenOffset
IniRead, fSize0, ini\resolutions.ini, %poe_height%p, font-size0
IniRead, fSize1, ini\resolutions.ini, %poe_height%p, font-size1
IniRead, archnemesis1_color, ini\config.ini, PixelSearch, color1
IniRead, archnemesis2_color, ini\config.ini, PixelSearch, color2
IniRead, game_version, ini\config.ini, PixelSearch, game-version
IniRead, resolution, ini\config.ini, PixelSearch, resolution
IniRead, fSize_offset, ini\config.ini, PixelSearch, font-offset, 0
IniRead, fallback, ini\config.ini, PixelSearch, fallback
If (fallback = "ERROR")
{
	IniWrite, 0, ini\config.ini, PixelSearch, fallback
	fallback := 0
}
IniRead, pixelsearch_variation, ini\config.ini, PixelSearch, variation
If (pixelsearch_variation = "ERROR")
{
	IniWrite, 0, ini\config.ini, PixelSearch, variation
	pixelsearch_variation := 0
}
fSize0 += fSize_offset
fSize1 += fSize_offset
IniRead, favorite_recipes, ini\config.ini, Settings, favorite recipes
global favorite_recipes := (favorite_recipes = "ERROR") ? "" : favorite_recipes
IniRead, blacklist_recipes, ini\config.ini, Settings, blacklist recipes
global blacklist_recipes := (blacklist_recipes = "ERROR") ? "" : blacklist_recipes
IniRead, pause_list, ini\config.ini, Settings, pause-list
global pause_list := (pause_list = "ERROR") ? "" : pause_list
IniRead, Burn_number, ini\config.ini, Settings, Burn-number
If (Burn_number = "" || Burn_number = "ERROR")
	Burn_number := 10
IniRead, sorting_settings, ini\config.ini, Settings, sorting
If (sorting_settings = "ERROR")
{
	sorting := "quantity"
	sorting_order := "descending"
}
Else
{
	Loop, Parse, sorting_settings, `,,`,
	{
		If (A_Index = 1)
			sorting := A_LoopField
		Else sorting_order := A_LoopField
	}
}
IniRead, yLetters, ini\resolutions.ini, %poe_height%p, yLetters
IniRead, xWindow, ini\resolutions.ini, %poe_height%p, xWindow
IniRead, invBox, ini\resolutions.ini, %poe_height%p, invBox
Loop, Parse, invBox, `,,`,
{
	If (A_Index < 3)
		invBox%A_Index% := A_LoopField + xScreenOffset
	Else	invBox%A_Index% := A_LoopField + yScreenOffset
}
IniRead, xScan, ini\resolutions.ini, %poe_height%p, xScan
IniRead, yScan, ini\resolutions.ini, %poe_height%p, yScan
IniRead, dBitMap, ini\resolutions.ini, %poe_height%p, dBitMap
global yLetters += yScreenOffset
global xWindow += xScreenOffset

If (archnemesis1_x = "ERROR") || (archnemesis1_x = "")
{
	MsgBox, %poe_height%p is not supported in this version. This may be due to a recent game update. If that is not the case, please request your resolution on GitHub and provide a screenshot with the archnemesis inventory open. 
	ExitApp
}

; Seconds until LUI will exit if PoE is closed and not restarted. -1 to disable.
IniRead, restart_timeout, ini\config.ini, Settings, restart_timeout
If restart_timeout is not number
	IniWrite, % restart_timeout := 60, ini\config.ini, Settings, restart_timeout
If (restart_timeout >= 0)
{
	SetTimer, DetectExit, 1000
	SetTimer, RestartTimeout, 1000
	SetTimer, RestartTimeout, off
}

If (archnemesis1_color = "ERROR") || (archnemesis1_color = "") || (resolution != poe_width "x" poe_height) || (game_version = "ERROR") || (game_version < "31710")
{
	If (archnemesis1_color = "ERROR") || (archnemesis1_color = "")
		MsgBox, This seems to be the first time this script has been started. Please follow the upcoming instructions.`n`n`nINFO: If you ever need to go through this first-time setup again, delete the ini\config.ini file and restart the script.
	Else	MsgBox, Your resolution has changed since last launch, or the game has been updated. First-time setup is required. 
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	ToolTip, 1) Open the archnemesis inventory.`n2) Keep the cursor away from the archnemesis inventory.`n3) Hold the 7-key until this tooltip disappears., % poe_width//2+xScreenOffset, poe_height//2+yScreenOffset, 1
	KeyWait, 7, D
	PixelGetColor, archnemesis1_color, %archnemesis1_x%, %archnemesis1_y%, RGB
	PixelGetColor, archnemesis2_color, %archnemesis2_x%, %archnemesis2_y%, RGB
	IniWrite, %archnemesis1_color%, ini\config.ini, PixelSearch, color1
	IniWrite, %archnemesis2_color%, ini\config.ini, PixelSearch, color2
	IniWrite, %poe_width%x%poe_height%, ini\config.ini, PixelSearch, resolution
	IniWrite, 31710, ini\config.ini, PixelSearch, game-version
	ToolTip,,,, 1
	KeyWait, 7
}

If (force_resolution = 1)
	WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
SoundBeep, 100
GoSub, GUI
GoSub, Favored_recipes
SetTimer, MainLoop, 200
timeout := ""
Return

Archnemesis:
LLK_Recipes(A_GuiControl, 1)
Return

Archnemesis2:
If InStr(A_GuiControl, "prev")
	param := previous_highlight
Else	param := InStr(A_GuiControl, "x ") ? SubStr(A_GuiControl, InStr(A_GuiControl, "x ")+2) : A_GuiControl
LLK_Recipes(param, 2)
Return

Archnemesis_letter:
If WinExist("ahk_id " hwnd_archnemesis_list) && (letter_clicked = A_GuiControl)
{
	Gui, archnemesis_list: Destroy
	hwnd_archnemesis_list := ""
	letter_clicked := ""
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	Return
}

letter_clicked := A_GuiControl
Gui, archnemesis_list: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
global hwnd_archnemesis_list := WinExist()
Gui, archnemesis_list: Margin, 2, 2
Gui, archnemesis_list: Color, Black
WinSet, Transparent, %trans%
Gui, archnemesis_list: Font, s%fSize0% cWhite, Fontin SmallCaps
no_letter := 1
section := 0
If InStr(A_GuiControl, "t1")
{
	Loop, Parse, arch_bases_sorted, `,,`,
	{
		If (A_LoopField = "")
			break
		color := InStr(favorite_recipes, A_LoopField) ? "Yellow" : "White"
		color := InStr(blacklist_recipes, A_LoopField) ? "Red" : color
		If (A_Index = 1)
			Gui, archnemesis_list: Add, Text, x6 y2 c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
		Else	Gui, archnemesis_list: Add, Text, xs c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
		IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
		ControlGetPos,, ypos,, height,, ahk_id %main_text%
		Loop, Parse, rewards, `,,`,
			Gui, archnemesis_list: Add, Picture, ys BackgroundTrans h%height% w-1 y%ypos%, img\Rewards\%A_LoopField%.png
		no_letter := 0
	}
}
Else If (A_GuiControl = " bl ") && (blacklist_recipes != "")
{
	Sort, blacklist_recipes, C D`,
	Loop, Parse, blacklist_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		color := "red"
		If (A_Index = 1)
			Gui, archnemesis_list: Add, Text, x6 y2 c%color% Section HWNDmain_text gBlacklist_recipes, % A_LoopField
		Else	Gui, archnemesis_list: Add, Text, xs c%color% Section HWNDmain_text gBlacklist_recipes, % A_LoopField
		IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
		IniRead, modifiers, ini\db_archnemesis.ini, %A_LoopField%, modifiers
		ControlGetPos,, ypos,, height,, ahk_id %main_text%
		Loop, Parse, rewards, `,,`,
			Gui, archnemesis_list: Add, Picture, ys BackgroundTrans h%height% w-1 y%ypos%, img\Rewards\%A_LoopField%.png
		If (modifiers != "ERROR")
		{
			Gui, archnemesis_list: Font, s%fSize1% cWhite
			Gui, archnemesis_list: Add, Text, cSilver xs BackgroundTrans Section, % "    "
			Gui, archnemesis_list: Add, Text, cSilver ys BackgroundTrans, % modifiers
			Gui, archnemesis_list: Font, s%fSize0% cWhite
		}
		no_letter := 0
	}
}
Else
{
	Loop, Parse, arch_recipes_sorted, `,,`,
	{
		color := InStr(favorite_recipes, A_LoopField) ? "Yellow" : "White"
		color := InStr(blacklist_recipes, A_LoopField) ? "Red" : color
		If (SubStr(A_LoopField, 1, 1) = A_GuiControl)
		{
			Gui, archnemesis_list: Font, s%fSize0%
			If (section != 1)
			{
				Gui, archnemesis_list: Add, Text, x6 y2 c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
				section := 1
			}
			Else	Gui, archnemesis_list: Add, Text, xs c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
			IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
			IniRead, modifiers, ini\db_archnemesis.ini, %A_LoopField%, modifiers
			ControlGetPos,, ypos,, height,, ahk_id %main_text%
			Loop, Parse, rewards, `,,`,
				Gui, archnemesis_list: Add, Picture, ys BackgroundTrans h%height% w-1 y%ypos%, img\Rewards\%A_LoopField%.png
			If (modifiers != "ERROR")
			{
				Gui, archnemesis_list: Font, s%fSize1% cWhite
				Gui, archnemesis_list: Add, Text, cSilver xs BackgroundTrans Section, % "    "
				Gui, archnemesis_list: Add, Text, cSilver ys BackgroundTrans, % modifiers
				Gui, archnemesis_list: Font, s%fSize0% cWhite
			}
			no_letter := 0
		}
	}
}
Gui, archnemesis_list: Margin, 6, 2
If (no_letter=0)
{
	MouseGetPos, mouseX, mouseY
	Gui, archnemesis_list: Show, Hide
	WinGetPos,,,, height
	If (height > yScreenOffset + yLetters - 10)
		Gui, archnemesis_list: Show, % "NA x"archnemesis1_x+10 " y"yScreenOffset
	Else	Gui, archnemesis_list: Show, % "NA x"mouseX " y"yLetters-10-height
}
WinActivate, ahk_group poe_window
Return

Base_info:
IniRead, maps, ini\db_archnemesis.ini, %A_GuiControl%, maps
Sort, maps, D`,
Gui, base_info: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border, map tab search: %A_GuiControl%
Gui, base_info: Margin, 20, 0
Gui, base_info: Color, Black
WinSet, Transparent, %trans%
Gui, base_info: Font, cWhite s%fSize0%, Fontin SmallCaps
search_term := ""
Loop, Parse, maps, `,,`,
{
	If (A_Index = 1)
		Gui, base_info: Add, Text, Center Section BackgroundTrans gMap_highlight, % A_LoopField
	Else	Gui, base_info: Add, Text, Center xs BackgroundTrans gMap_highlight, % A_LoopField
}
Gui, base_info: Show, % "NA x"xScreenOffset+poe_width//2 " y"yScreenOffset
WinActivate, ahk_group poe_window
Return

Base_lootGuiClose:
LLK_Overlay("base_loot", 2)
base_loot_toggle := 0
Return

Blacklist_recipes:
blacklist_recipes := StrReplace(blacklist_recipes, A_GuiControl ",", "")
SetTimer, Favored_recipes, 10
Return

Burn_all:
search_term := ""
unwanted_mods_quant0 := unwanted_mods_quant
If (unwanted_mods_quant = "")
{
	WinActivate, ahk_group poe_window
	Return
}
Sort, unwanted_mods_quant, D`, N R
Loop, Parse, unwanted_mods_quant, `,,`,
{
	If (A_LoopField = "")
		break
	If InStr(blacklist_recipes, SubStr(A_LoopField, InStr(A_LoopField, "x ")+2))
		continue
	If (StrLen("^(" search_term ")") < 42)
	{
		If InStr(A_LoopField, "frost ") || InStr(A_LoopField, "frostw") || InStr(A_LoopField, "flame") || InStr(A_LoopField, "storm")
		{
			search_term := (search_term = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 7) : search_term "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 7)
			continue
		}
		If InStr(A_LoopField, "cor")
		{
			search_term := (search_term = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 4) : search_term "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 4)
			continue
		}
		If InStr(A_LoopField, "soul")
		{
			search_term := (search_term = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 6) : search_term "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 6)
			continue
		}
		If InStr(A_LoopField, "empower")
		{
			search_term := (search_term = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8) : search_term "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8)
			continue
		}
		search_term := (search_term = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 3) : search_term "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 3)
	}
}

clipboard := "^(" StrReplace(search_term, A_Space, ".") ")"
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
SendInput, ^{f}^{v}{Enter}
Return

BurnEdit:
Gui, surplus_view: Submit, NoHide
Return

Exit:
Gdip_Shutdown(pToken)
If (timeout != 1)
{
	IniWrite, %favorite_recipes%, ini\config.ini, Settings, favorite recipes
	IniWrite, %blacklist_recipes%, ini\config.ini, Settings, blacklist recipes
	IniWrite, %pause_list%, ini\config.ini, Settings, pause-list
	IniWrite, %Burn_number%, ini\config.ini, Settings, Burn-number
	If (archnemesis_inventory != "")
		IniWrite, %archnemesis_inventory%, ini\config.ini, Archnemesis, inventory
	IniWrite, %previous_highlight%, ini\config.ini, Archnemesis, previous-highlight
	IniWrite, %sorting%`,%sorting_order%, ini\config.ini, Settings, sorting
}
ExitApp
Return

GUI:
Gui, archnemesis_letters: -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
global hwnd_archnemesis_letters := WinExist(), guilist := "archnemesis_letters"
guilist := guilist "|base_loot"
guilist := guilist "|archnemesis_list"
guilist := guilist "|archnemesis_window"
guilist := guilist "|surplus_view"
Gui, archnemesis_letters: Margin, 0, 2
Gui, archnemesis_letters: Color, Black
WinSet, Transparent, %trans%
Gui, archnemesis_letters: Font, s%fSize0% cWhite, Fontin SmallCaps
letter := ""
Gui, archnemesis_letters: Add, Text, x0 y2 Center BackgroundTrans HWNDbutton_width, % "    "
ControlGetPos,,, width,,, ahk_id %button_width%
Gui, archnemesis_letters: Add, Text, x6 y2 Center BackgroundTrans Section Border gArchnemesis_letter, % " t1 "
Loop, Parse, arch_recipes_sorted, `,,`,
{
	If (A_LoopField = "")
		break
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (letter != SubStr(A_LoopField, 1, 1))
	{
		If (A_Index = 1)	
			Gui, archnemesis_letters: Add, Text, ys x+2 w%width% gArchnemesis_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		Else	Gui, archnemesis_letters: Add, Text, ys x+2 wp gArchnemesis_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		letter := SubStr(A_LoopField, 1, 1)
	}
}
Gui, archnemesis_letters: Add, Text, ys x+6 Center BackgroundTrans Border gArchnemesis_letter, % " bl "
Gui, archnemesis_letters: Add, Text, ys x+6 Center gFont_offset Border, % " – "
Gui, archnemesis_letters: Add, Text, ys x+2 wp Section Center gFont_offset Border, % "+"
Gui, archnemesis_letters: Add, Text, Center ys x+6 gArchnemesis2 Border, % " prev "
Gui, archnemesis_letters: Add, Text, Center ys x+6 gScan Border, % " scan "
Gui, archnemesis_letters: Margin, 6, 2
Gui, archnemesis_letters: Show, Hide
WinGetPos,,, guiwidth,
Gui, archnemesis_letters: Show, % "Hide x" xScreenOffset+((xWindow-xScreenOffset)*0.96)//2-guiwidth//2 " y"yLetters
WinGetPos, outx,, guiwidth
xScan_button := (outx + guiwidth) * 0.9
If (outx < xScreenOffset)
{
	Gui, archnemesis_letters: Show, % "Hide x" xScreenOffset " y"yLetters
	xScan_button := guiwidth * 0.9
}
Return

Help:
If (click = 2)
{
	Run, explore img\Recognition\%poe_height%p\Archnemesis
	Return
}
Gui, help_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, help_panel: Margin, 6, 4
Gui, help_panel: Color, Black
WinSet, Transparent, %trans%
Gui, help_panel: Font, s%fSize1% cWhite underline, Fontin SmallCaps
Gui, help_panel: Add, Text, Section BackgroundTrans, clear list:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-r-click on 'prio-list'
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, view prio-surplus:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, click 'prio-list'
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, remove recipe:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-r-click prio-entry
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, pause recipe:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click prio-entry
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, tree-view:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-click prio-entry
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, map search:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, click 'missing'
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, bases cheat sheet:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click 'missing'
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, open image folder:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click '?'
MouseGetPos, mousex, mousey
Gui, help_panel: Show, % "NA x"xWindow1 " y"mousey
KeyWait, LButton
Gui, help_panel: Destroy
WinActivate, ahk_group poe_window
Return

Recalibrate_letter:
letter_clicked := A_GuiControl
Gui, recalibrate_list: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
global hwnd_recalibrate_list := WinExist()
Gui, recalibrate_list: Margin, 6, 2
Gui, recalibrate_list: Color, Black
WinSet, Transparent, %trans%
Gui, recalibrate_list: Font, s%fSize0% cWhite underline, Fontin SmallCaps
no_letter := 1
section := 0
Loop, Parse, all_nemesis, `n, `n
{
	If (SubStr(A_LoopField, 1, 1) = A_GuiControl)
	{
		If (section = 0)
		{
			Gui, recalibrate_list: Add, Text, Section gRecalibrate_UI, % A_LoopField
			section := 1
		}
		Else	Gui, recalibrate_list: Add, Text, xs y+6 Section gRecalibrate_UI, % A_LoopField
		no_letter := 0
	}
}
If (no_letter=0)
{
	MouseGetPos, mouseX, mouseY
	Gui, recalibrate_list: Show, Hide
	WinGetPos,,,, height
	WinGetPos,, outY,,, ahk_id %recalibration%
	Gui, recalibrate_list: Show, % "NA x"mouseX-30 " y"outY-10-height+yScreenOffset
}
Return

Surplus:
If (click = 2)
{
	holdstart := A_TickCount
	While GetKeyState("RButton", "P")
	{
		If (A_TickCount >= holdstart + 500)
		{
			Gui, surplus_view: Destroy
			hwnd_surplus_view := ""
			favorite_recipes := ""
			GoSub, Favored_recipes
			Return
		}
	}
	Return
}
If WinExist("ahk_id " hwnd_surplus_view)
{
	Gui, surplus_view: Destroy
	hwnd_surplus_view := ""
	WinActivate, ahk_group poe_window
	Return
}
If (arch_surplus != "") && !WinExist("ahk_id " hwnd_surplus_view)
{
	Sort, arch_surplus, D`,
	check := ""
	surplus_list := ""
	count := 0
	Loop, Parse, arch_surplus, `,,`,
	{
		If (A_Index = 1) || (check = A_LoopField)
		{
			check := A_LoopField
			count += 1
		}
		If (A_Index != 1) && (check != A_LoopField)
		{
			surplus_list := (surplus_list = "") ? count "x " check "," : surplus_list count "x " check ","
			check := A_LoopField
			count := 1
		}
	}
	Sort, surplus_list, N R D`,
	global hwnd_surplus_view := ""
	Gui, surplus_view: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border, current prio surplus:
	Gui, surplus_view: Margin, 12, 0
	Gui, surplus_view: Color, Black
	WinSet, Transparent, %trans%
	Gui, surplus_view: Font, cWhite s%fSize0%, Fontin SmallCaps
	Gui, surplus_view: Add, Text, BackgroundTrans Section HWNDmain_text vheader3 Center, burn surplus above:
	ControlGetPos,,,, height,, ahk_id %main_text%
	Gui, surplus_view: Font, % "s"fSize1-2
	Gui, surplus_view: Add, Edit, ys cBlack BackgroundTrans hp w%height% gBurnEdit vBurn_number, %Burn_number%
	Gui, surplus_view: Font, s%fSize1%
	Loop, Parse, surplus_list, `,,`,
	{
		If (A_LoopField = "")
			break
		If (A_Index = 1)
		{
			Gui, surplus_view: Add, Text, BackgroundTrans y+6 xs Section Center, % A_LoopField
			clipboard := SubStr(A_LoopField, InStr(A_LoopField, A_Space,, 1, 1)+1)
		}
		Else	Gui, surplus_view: Add, Text, BackgroundTrans xs Center, % A_LoopField
	}
	MouseGetPos, outx, outy
	Gui, surplus_view: Show, % "Hide x"outx " y"outy+20
	WinGetPos,, outwiny,, height
	If (outwiny+height > xScreenOffset+poe_height)
		Gui, surplus_view: Show, % "x"outx+20 " y"yScreenOffset+poe_height-height
	Else	Gui, surplus_view: Show, % "Hide x"outx+20 " y"outy+20
	hwnd_surplus_view := WinExist()
}
WinActivate, ahk_group poe_window
Return

#Include Fallback.ahk

DetectExit:
If !WinExist("ahk_group poe_window")
{ 
	timeout_time := restart_timeout * 1000 + A_TickCount
	SetTimer, DetectExit, off
	SetTimer, RestartTimeout, on
	Gosub, RestartTimeout		; For 0 second timeout
}
Return

RestartTimeout:
	If WinExist("ahk_group poe_window")
	{
		SetTimer, DetectExit, on
		SetTimer, RestartTimeout, off
	}
	Else If (A_TickCount > timeout_time)
		ExitApp
Return

MainLoop:
If !WinActive("ahk_group poe_window") && !WinActive("ahk_class AutoHotkeyGUI")
{
	inactive_counter += 1
	If (inactive_counter > 3)
	{
		LLK_Overlay("hide")
		WinWaitActive, ahk_group poe_window
		LLK_Overlay("show")
	}
}
If WinActive("ahk_group poe_window")
{
	inactive_counter := 0
	If (fallback = 0) || (fallback_override = 1)
		LLK_PixelSearch("archnemesis")
	If (archnemesis = 1)
	{
		If !WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 1)
		If !WinExist("ahk_id " hwnd_archnemesis_window) && (hwnd_archnemesis_window != "")
			LLK_Overlay("archnemesis_window", 1)
		If !WinExist("ahk_id " hwnd_surplus_view) && (hwnd_surplus_view != "")
			LLK_Overlay("surplus_view", 1)
		If (background_scanned = 0)
		{
			MouseGetPos, outXmouse
			If (outXmouse > invBox2)
			{
				background_scanned := 2
				SetTimer, Scan_background, 10
			}
		}
	}
	If (archnemesis = 0)
	{
		If (background_scanned != 0)
			background_scanned := (background_scanned = 1) ? 0 : 2
		If WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 2)
		If WinExist("ahk_id " hwnd_archnemesis_list)
			LLK_Overlay("archnemesis_list", 2)
		If WinExist("ahk_id " hwnd_archnemesis_window)
			LLK_Overlay("archnemesis_window", 2)
		If WinExist("ahk_id " hwnd_surplus_view)
			LLK_Overlay("surplus_view", 2)
		fallback_override := 0
	}
}
Return

Map_highlight:
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
If (A_Gui = "base_info")
	Clipboard := SubStr(StrReplace(A_GuiControl, A_Space, "."), 1)
Else Clipboard := StrReplace(SubStr(A_GuiControl, InStr(A_GuiControl, "in ")+3), A_Space, ".")
SendInput, ^{f}^{v}{Enter}
Return

Map_suggestion:
If (list_remaining = "")
{
	WinActivate, ahk_group poe_window
	Return
}
If (click = 2)
{
	If !WinExist("ahk_id " hwnd_base_loot)
	{
		LLK_Overlay("base_loot", 1)
		base_loot_toggle := 1
	}
	Else
	{
		LLK_Overlay("base_loot", 2)
		base_loot_toggle := 0
	}
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	Return
}
map_list := []
map_counter := []
optimal_maps := ""
map_pool := ""
list_remaining_single := ""
all_maps := ""
Loop, Parse, list_remaining, `,,`,
{
	If (A_LoopField = "")
		break
	If !InStr(list_remaining_single, A_LoopField)
		list_remaining_single := (list_remaining_single = "") ? A_LoopField "," : list_remaining_single A_LoopField ","
}

Loop, Parse, list_remaining_single, `,,`,
{
	If (A_LoopField = "")
		break
	IniRead, maps, ini\db_archnemesis.ini, %A_LoopField%, maps
	map_pool := (map_pool = "") ? maps "," : map_pool maps ","
}

Loop, Parse, map_pool, `,,`,
{
	If (A_LoopField = "")
		break
	If !InStr(all_maps, A_LoopField)
	{
		all_maps := (all_maps = "") ? A_LoopField "," : all_maps A_LoopField ","
		map_list.Push(A_LoopField)
	}
}
Loop, Parse, all_maps, `,,`,
{
	If (A_LoopField = "")
		break
	count := 0
	While (InStr(map_pool, A_LoopField,,, A_Index) != 0)
	{
		count += 1
	}
	map_counter.Push(count)
}

Loop, % map_list.Length()
	optimal_maps := (optimal_maps = "") ? map_counter[A_Index] " mods in " map_list[A_Index] "," : optimal_maps map_counter[A_Index] " mods in " map_list[A_Index] ","

Sort, optimal_maps, N R D`,
Gui, map_suggestions: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border, map tab search
Gui, map_suggestions: Margin, 20, 0
Gui, map_suggestions: Color, Black
WinSet, Transparent, %trans%
Gui, map_suggestions: Font, cWhite s%fSize0%, Fontin SmallCaps
Gui, map_suggestions: Add, Text, Center Section BackgroundTrans vheader01, common drop locations:
Gui, map_suggestions: Font, s%fSize1% underline

heightsuggestions := ""
Loop, Parse, optimal_maps, `,,`,
{
	If (A_LoopField = "") || (heightsuggestions > poe_height*0.9)
		break
	If InStr(A_LoopField, "1 mods")
		map_text := StrReplace(A_LoopField, "1 mods", "1 mod")
	Else map_text := A_LoopField
	If (A_Index = 1)
		Gui, map_suggestions: Add, Text, BackgroundTrans HWNDmain_text y+6 xs Section Center gMap_highlight, % map_text
	Else	Gui, map_suggestions: Add, Text, BackgroundTrans HWNDmain_text xs Center gMap_highlight, % map_text
	Gui, map_suggestions: Show, Hide AutoSize
	WinGetPos,,,, heightsuggestions
}
Gui, map_suggestions: Show, % "NA x"xScreenOffset+poe_width//2 " y"yScreenOffset
WinActivate, ahk_group poe_window
Return

Map_suggestionsGUIClose:
Gui, map_suggestions: Destroy
Return

Pause_list:
If InStr(pause_list, A_GuiControl)
	pause_list := StrReplace(pause_list, A_GuiControl ",", "")
Else pause_list := (pause_list = "") ? A_GuiControl "," : pause_list A_GuiControl ","
GoSub, Favored_recipes
Return

Recalibrate:
recal_choice := ""
GoSub, Recalibrate_UI
Gui, recal_arrow: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow
Gui, recal_arrow: Color, Black
WinSet, TransColor, Black
Gui, recal_arrow: Add, Picture, BackgroundTrans w%dBitMap% h-1, img\GUI\arrow_red.png
Gui, recal_arrow: Show, Hide
WinGetPos,,, width, height
Gui, recal_arrow: Show, % "NA x"xArrow-width//2 " y"yArrow-height*1.2
LLK_Overlay("Hide")
ToolTip,,,, 17
While (recal_choice = "")
	Sleep, 100
Gui, recal_arrow: Hide
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
If !FileExist("img\Recognition\" poe_height "p\Archnemesis\")
	FileCreateDir, img\Recognition\%poe_height%p\Archnemesis\
count := ""
While FileExist("img\Recognition\" poe_height "p\Archnemesis\" recal_choice count ".png")
	count += 1
Gdip_SaveBitmapToFile(Gdip_BitmapFromScreen(xBitMap "|" yBitMap "|" dBitMap "|" dBitMap), "img\Recognition\" poe_height "p\Archnemesis\" recal_choice count ".png", 100)
archnemesis_inventory_prelim := (archnemesis_inventory_prelim = "") ? recal_choice : archnemesis_inventory_prelim "," recal_choice
Return

Recalibrate_UI:
If InStr(A_GuiControl, "cancel")
{
	Gdip_DisposeImage(background_Needle)
	Gdip_DisposeImage(bmpNeedle)
	Gdip_DisposeImage(bmpHaystack)
	Gdip_DisposeImage(background_Haystack)
	Reload
	ExitApp
}
If InStr(A_GuiControl, "empty")
{
	recal_choice := "-empty-"
	Gui, recalibrate_list: Destroy
	Gui, recalibration: Destroy
	Return
}
If (A_Gui = "recalibrate_list")
{
	recal_choice := A_GuiControl
	Gui, recalibrate_list: Destroy
	Gui, recalibration: Destroy
	WinActivate, ahk_group poe_window
	Return
}
Gui, recalibration: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDrecalibration
global hwnd_recalibration := WinExist()
Gui, recalibration: Margin, 6, 2
Gui, recalibration: Color, Black
WinSet, Transparent, %trans%
Gui, recalibration: Font, cWhite s%fSize0%, Fontin SmallCaps
Gui, recalibration: Add, Text, BackgroundTrans, Please specify the indicated mod type.
letter := ""
Gui, recalibration: Add, Text, x6 Section Center gRecalibrate_UI Border, % " empty "
Gui, recalibration: Add, Text, xs wp Center gRecalibrate_UI Border, % "cancel"
Gui, recalibration: Add, Text, ys x-5 Center BackgroundTrans, % "     "
Loop, Parse, all_nemesis, `n, `n
{
	If (letter != SubStr(A_LoopField, 1, 1))
	{
		If (A_Index = 1)
			Gui, recalibration: Add, Text, ys wp gRecalibrate_letter Section BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		Else
		{
			If (SubStr(A_LoopField, 1, 1) != "k")
				Gui, recalibration: Add, Text, ys wp gRecalibrate_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
			Else	Gui, recalibration: Add, Text, xs wp gRecalibrate_letter Section BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		}
		letter := SubStr(A_LoopField, 1, 1)
	}
}
Gui, recalibration: Show, % "x"xWindow " y"yScreenOffset+poe_height//2
Return

Fallback:
hotkey0 := StrReplace(A_ThisHotkey, "$", "")
LLK_PixelSearch("archnemesis")
If (archnemesis = 0)
{
	SendInput, {%hotkey0%}
	fallback_override := 1
}
else fallback_override := 1
Return

Favored_recipes:
SetTimer, Favored_recipes, Delete
Gui, archnemesis_list: Hide
If (A_Gui = "Archnemesis_list")
{
	If (click = 1)
		favor_choice := InStr(blacklist_recipes, A_GuiControl) ? "" : A_GuiControl
	Else blacklist_choice := InStr(favorite_recipes, A_GuiControl) ? "" : A_GuiControl
}
If (favor_choice != "")
{
	If InStr(favorite_recipes, favor_choice)
		favorite_recipes := StrReplace(favorite_recipes, favor_choice ",", "")
	Else favorite_recipes := (favorite_recipes = "") ? favor_choice "," : favorite_recipes favor_choice ","
}
If (blacklist_choice != "")
{
	If InStr(blacklist_recipes, blacklist_choice)
		blacklist_recipes := StrReplace(blacklist_recipes, blacklist_choice ",", "")
	Else blacklist_recipes := (blacklist_recipes = "") ? blacklist_choice "," : blacklist_recipes blacklist_choice ","
}	
global prio_list := "", prio_list_active := "", prio_list_recipes := "", list_remaining := ""
fav_in_inv :=
fav_not_inv :=
If (favorite_recipes != "")
{
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(pause_list, A_LoopField) || InStr(archnemesis_inventory, A_LoopField)
			fav_in_inv := (fav_in_inv = "") ? A_LoopField "," : fav_in_inv A_LoopField ","
		Else	fav_not_inv := (fav_not_inv = "") ? A_LoopField "," : fav_not_inv A_LoopField ","
	}
	favorite_recipes := fav_not_inv fav_in_inv
	
	global is_base := ""
	global not_base := ""
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
		If (recipe = "ERROR")
			is_base := (is_base = "") ? A_LoopField "," : is_base A_LoopField ","
		Else not_base := (not_base = "") ? A_LoopField "," : not_base A_LoopField ","
	}
	favorite_recipes := not_base is_base
	
	global is_paused := ""
	global not_paused := ""
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(pause_list, A_LoopField)
			is_paused := (is_paused = "") ? A_LoopField "," : is_paused A_LoopField ","
		Else not_paused := (not_paused = "") ? A_LoopField "," : not_paused A_LoopField ","
	}
	favorite_recipes := not_paused is_paused
	
	list_remaining := ""
	archnemesis_inventory_leftover := archnemesis_inventory ","
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(pause_list, A_LoopField)
			continue
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
		If (recipe != "ERROR")
		{
			Loop, Parse, recipe, `,,`,
			{
				If !InStr(archnemesis_inventory_leftover, A_LoopField)
				{
					IniRead, recipe0, ini\db_archnemesis.ini, %A_LoopField%, components
					If (recipe0 != "ERROR")
					{
						Loop, Parse, recipe0, `,,`,
						{
							If !InStr(archnemesis_inventory_leftover, A_LoopField)
							{
								IniRead, recipe1, ini\db_archnemesis.ini, %A_LoopField%, components
								If (recipe1 != "ERROR")
								{
									Loop, Parse, recipe1, `,,`,
									{
										If !InStr(archnemesis_inventory_leftover, A_LoopField)
										{
											IniRead, recipe2, ini\db_archnemesis.ini, %A_LoopField%, components
											If (recipe2 != "ERROR")
											{
												Loop, Parse, recipe2, `,,`,
												{
													If !InStr(archnemesis_inventory_leftover, A_LoopField)
														list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
													Else archnemesis_inventory_leftover := StrReplace(archnemesis_inventory_leftover, A_LoopField ",", "",, 1)
												}
											}
											Else list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
										}
										Else archnemesis_inventory_leftover := StrReplace(archnemesis_inventory_leftover, A_LoopField ",", "",, 1)
									}
								}
								Else list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
							}
							Else archnemesis_inventory_leftover := StrReplace(archnemesis_inventory_leftover, A_LoopField ",", "",, 1)
						}
					}
					Else list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
				}
				Else archnemesis_inventory_leftover := StrReplace(archnemesis_inventory_leftover, A_LoopField ",", "",, 1)
			}
		}
		Else list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
	}
	
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		prio_list%A_Index% := ""
		loop := A_Index
		prio_list%loop% := (prio_list%loop% = "") ? A_LoopField "," : prio_list%loop% A_LoopField ","
		IniRead, components0, ini\db_archnemesis.ini, %A_LoopField%, components
		If (components0 != "ERROR")
		{
			prio_list%loop% := prio_list%loop% components0 ","
			Loop, Parse, components0, `,,`,
			{
				IniRead, components1, ini\db_archnemesis.ini, %A_LoopField%, components
				If (components1 != "ERROR")
				{
					prio_list%loop% := prio_list%loop% components1 ","
					Loop, Parse, components1, `,,`,
					{
						IniRead, components2, ini\db_archnemesis.ini, %A_LoopField%, components
						If (components2 != "ERROR")
						{
							prio_list%loop% := prio_list%loop% components2 ","
							Loop, Parse, components2, `,,`,
							{
								IniRead, components3, ini\db_archnemesis.ini, %A_LoopField%, components
								If (components3 != "ERROR")
									prio_list%loop% := prio_list%loop% components3 ","
							}
						}
					}
				}
			}
		}
		prio_list := (prio_list = "") ? prio_list%A_Index% : prio_list prio_list%A_Index%
	}
	
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		prio_list%A_Index%_active := ""
		loop := A_Index
		If InStr(Pause_list, A_LoopField)
			continue
		prio_list%loop%_active := (prio_list%loop%_active = "") ? A_LoopField "," : prio_list%loop%_active A_LoopField ","
		IniRead, components0, ini\db_archnemesis.ini, %A_LoopField%, components
		If (components0 != "ERROR")
		{
			Loop, Parse, components0, `,,`,
			{
				If !InStr(archnemesis_inventory, A_LoopField)
					prio_list%loop%_active := (prio_list%loop%_active = "") ? A_LoopField "," : prio_list%loop%_active A_LoopField ","
				Else continue
				IniRead, components1, ini\db_archnemesis.ini, %A_LoopField%, components
				If (components1 != "ERROR")
				{
					Loop, Parse, components1, `,,`,
					{
						If !InStr(archnemesis_inventory, A_LoopField)
							prio_list%loop%_active := (prio_list%loop%_active = "") ? A_LoopField "," : prio_list%loop%_active A_LoopField ","
						Else continue
						IniRead, components2, ini\db_archnemesis.ini, %A_LoopField%, components
						If (components2 != "ERROR")
						{
							Loop, Parse, components2, `,,`,
							{
								If !InStr(archnemesis_inventory, A_LoopField)
									prio_list%loop%_active := (prio_list%loop%_active = "") ? A_LoopField "," : prio_list%loop%_active A_LoopField ","
								Else continue
							}
						}
					}
				}
			}
		}
		If !InStr(pause_list, A_LoopField)
			prio_list_active := (prio_list_active = "") ? prio_list%A_Index%_active : prio_list_active prio_list%A_Index%_active
	}
	
	global arch_surplus := ""
	Loop, Parse, archnemesis_inventory_leftover, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(prio_list, A_LoopField) && (!InStr(favorite_recipes, A_LoopField) || InStr(is_base, A_LoopField))
			arch_surplus := (arch_surplus = "") ? A_LoopField "," : arch_surplus A_LoopField ","
	}
	
	Loop, Parse, arch_surplus, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(arch_surplus, A_LoopField,,, Burn_number+1)
			prio_list := StrReplace(prio_list, A_LoopField ",", "")
	}
	
	archnemesis_inventory_surplus := archnemesis_inventory
	global prio_list_leftover := prio_list_active
	favored_bases := ""
	
	Loop, Parse, arch_bases, `,,`,
	{
		If InStr(prio_list, A_LoopField) && !InStr(favored_bases, A_LoopField)
			favored_bases := (favored_bases = "") ? A_LoopField "," : A_LoopField "," favored_bases
	}
	Loop, Parse, archnemesis_inventory, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(prio_list_recipes_leftover, A_LoopField)
		{
			archnemesis_inventory_surplus := StrReplace(archnemesis_inventory_surplus, A_LoopField ",", "",, 1)
			prio_list_recipes_leftover := StrReplace(prio_list_recipes_leftover, A_LoopField ",", "",, 1)
		}
	}
	Sort, list_remaining, C D`,
}

If WinExist("ahk_id " hwnd_base_loot)
	WinGetPos, xbase_loot, ybase_loot,,, ahk_id %hwnd_base_loot%
list_remaining_single := ""
global list_remaining_count := 0
Loop, Parse, list_remaining, `,,`,
{
	If (A_LoopField = "")
		break
	list_remaining_count += 1
	If !InStr(list_remaining_single, A_LoopField)
		list_remaining_single := (list_remaining_single = "") ? A_LoopField "," : list_remaining_single A_LoopField ","
}
Gui, base_loot: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_base_loot, Missing bases:
Gui, base_loot: Margin, 15, 0
Gui, base_loot: Color, Black
WinSet, Transparent, 200
Gui, base_loot: Font, cWhite s%fSize0%, Fontin SmallCaps

Loop, Parse, list_remaining_single, `,,`,
{
	If (A_LoopField = "")
		break
	If (A_Index = 1)
		Gui, base_loot: Add, Text, Center Section BackgroundTrans gBase_info, % A_LoopField
	Else Gui, base_loot: Add, Text, Center xs BackgroundTrans gBase_info, % A_LoopField
}
xbase_loot := (xbase_loot = "") ? xScreenOffset+poe_width//2 : xbase_loot
ybase_loot := (ybase_loot = "") ? yScreenOffset+0 : ybase_loot
style := (base_loot_toggle = 1) ? "NA" : "Hide"
Gui, base_loot: Show, % style "x"xbase_loot " y"ybase_loot
blacklist_choice := ""
favor_choice := ""
GoSub, Recipes
Return

Font_offset:
If InStr(A_GuiControl, "–")
	fSize_offset -= 1
If InStr(A_GuiControl, "+")
	fSize_offset += 1
IniWrite, %fSize_offset%, ini\config.ini, PixelSearch, font-offset
Reload
ExitApp
Return

Recipes:
global available_recipes := "", unwanted_recipes := "", unwanted_mods := ""
leftover_recipes := all_nemesis_inverted
If (prio_list != "")
{
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(Pause_list, A_LoopField)
			continue
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
		If (recipe != "") && (recipe != "ERROR")
		{
			recipe_match := 1
			Loop, Parse, recipe, `,,`,
				recipe_match *= InStr(archnemesis_inventory, A_LoopField)
			If (recipe_match != 0)
				available_recipes := (available_recipes = "") ? A_LoopField "," : available_recipes A_LoopField ","
		}
	}
	
	Loop, Parse, prio_list_leftover, `,,`,
	{
		If (A_LoopField = "")
			break
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
		If (recipe != "") && (recipe != "ERROR")
		{
			recipe_match := 1
			Loop, Parse, recipe, `,,`,
				recipe_match *= InStr(archnemesis_inventory, A_LoopField)
			If (recipe_match != 0) && !InStr(available_recipes, A_LoopField)
				available_recipes := (available_recipes = "") ? A_LoopField "," : available_recipes A_LoopField ","
		}
	}
	
	Loop, Parse, all_nemesis_inverted, `,,`,
	{
		If (A_LoopField = "")
			break
		If !InStr(prio_list, A_LoopField)
		{
			IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
			recipe_match := 1
			If (recipe != "ERROR")
			{
				Loop, Parse, recipe, `,,`,
				{
					If !InStr(prio_list, A_LoopField)
						recipe_match *= InStr(archnemesis_inventory, A_LoopField)
					Else recipe_match := 0
				}
			}
			Else recipe_match := 0
			If (recipe_match != 0)
				unwanted_recipes := (unwanted_recipes = "") ? A_LoopField "," : unwanted_recipes A_LoopField ","
		}	
	}
	
	If InStr(A_GuiControl, "/")
	{
		If (click = 1)
			sorting_order := (sorting_order = "descending") ? "ascending" : "descending"
		Else sorting := (sorting = "quantity") ? "ranking" : "quantity"
	}
	Loop, Parse, all_nemesis_inverted, `,,`,
	{
		If (A_LoopField = "")
			break
		If (!InStr(prio_list, A_LoopField) && InStr(archnemesis_inventory, A_LoopField)) || InStr(arch_surplus, A_LoopField,,, Burn_number + 1)
		{
			If (reverse = 0)
				unwanted_mods := (unwanted_mods = "") ? A_LoopField "," : unwanted_mods A_LoopField ","
			Else	unwanted_mods := (unwanted_mods = "") ? A_LoopField "," : A_LoopField "," unwanted_mods
		}
	}
}
Else
{
	Loop, Parse, arch_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
		recipe_match := 1
		Loop, Parse, recipe, `,,`,
			recipe_match *= InStr(archnemesis_inventory, A_LoopField)
		If (recipe_match != 0)
			available_recipes := (available_recipes = "") ? A_LoopField "," : available_recipes A_LoopField ","
	}
}

Gui, archnemesis_window: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, archnemesis_window: Margin, 4, 0
Gui, archnemesis_window: Color, Black
WinSet, Transparent, %trans%
Gui, archnemesis_window: Font, % "s"fSize1-1 "norm cWhite", Fontin SmallCaps
window_text := (prio_list != "") ? "prio-list:" : "ready:"
;If (window_text = "prio-list:")
;	Gui, archnemesis_window: Add, Checkbox, x12 y2 Center Checked%auto_highlight% vauto_highlight, % "auto-highlight after scan"
Gui, archnemesis_window: Font, s%fSize0%
If InStr(window_text, "prio")
{
	Gui, archnemesis_window: Font, underline
	Gui, archnemesis_window: Add, Text, x12 y4 cYellow BackgroundTrans Section gSurplus, %window_text%
	Gui, archnemesis_window: Font, norm
}
Else	Gui, archnemesis_window: Add, Text, x12 y4 cYellow BackgroundTrans Section, %window_text%
If (prio_list != "")
{
	If (list_remaining_count = 1)
		Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys x+6, % list_remaining_count " base"
	Else	Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys x+6, % list_remaining_count " bases"
	Gui, archnemesis_window: Font, s%fSize0% underline
	Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys gMap_suggestion HWNDmain_text, % "missing"
	ControlGetPos,,,, height,, ahk_id %main_text%
	Gui, archnemesis_window: Add, Picture, BackgroundTrans ys gHelp hp w-1, img\GUI\help.png
	Gui, archnemesis_window: Font, s%fSize0% norm
}
listed_recipes := ""
If (favorite_recipes != "")
{
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		check := A_LoopField
		prio_number := A_Index
		color := (InStr(archnemesis_inventory, A_LoopField)) ? "Lime" : "Silver"
		color := (InStr(Pause_list, A_LoopField)) ? "Fuchsia" : color
		count := 0
		While InStr(archnemesis_inventory, check,,, A_Index)
			count := A_Index
		Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section gRecipe_tree HWNDmain_text, % A_LoopField
		If (color = "Lime" || color = "Fuchsia") && (count != 0)
			Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans ys, % "("count "x)"
		If InStr(pause_list, A_LoopField)
			continue
		Loop, Parse, available_recipes, `,,`,
		{
			If (A_LoopField = "")
				break
			If InStr(prio_list%prio_number%_active, A_LoopField)
			{
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section, % "     "
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys gArchnemesis, % A_LoopField
				IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
				If (recipe != "ERROR")
				{
					count := 0
					Loop, Parse, recipe, `,,`,
						count += 1
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, % "(" count ")"
				}
			}
		}
	}
}
Else
{
	Loop, Parse, available_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(blacklist_recipes, A_LoopField)
			continue
		Gui, archnemesis_window: Font, s%fSize0% norm
		Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section HWNDmain_text gArchnemesis, % A_LoopField
		IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
		comp_no := 0
		Loop, Parse, read, `,,`,
			comp_no += 1
		Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, (%comp_no%)
		IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
		ControlGetPos,, ypos,, height,, ahk_id %main_text%
		Loop, Parse, read, `,,`,
			Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
	}
}
If (favorite_recipes != "")
{
	Gui, archnemesis_window: Font, % "s"fSize1-3 norm
	Gui, archnemesis_window: Add, Text, xs Section cRed BackgroundTrans, % " "
	Gui, archnemesis_window: Font, s%fSize0%
	Gui, archnemesis_window: Add, Text, xs Section cRed BackgroundTrans, available burn recipes:
	If (unwanted_recipes != "")
	{
		Loop, Parse, unwanted_recipes, `,,`,
		{
			If (A_LoopField = "")
				break
			If InStr(blacklist_recipes, A_LoopField)
				continue
			IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
			comp_no := 0
			color := 0
			Loop, Parse, read, `,,`,
			{
				If InStr(arch_surplus, A_LoopField,,, Burn_number+1)
					color += 1
				comp_no += 1
			}
			color := (color > 0) ? "Yellow" : "White"
			Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans Section xs HWNDmain_text gArchnemesis, % A_LoopField
			Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans ys, (%comp_no%)
			IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
			ControlGetPos,, ypos,, height,, ahk_id %main_text%
			Loop, Parse, read, `,,`,
				Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
		}
	}
	Gui, archnemesis_window: Font, % "s"fSize1-3 norm
	Gui, archnemesis_window: Add, Text, xs Section cRed BackgroundTrans, % " "
	Gui, archnemesis_window: Font, s%fSize0% underline
	Gui, archnemesis_window: Add, Text, xs Section cRed BackgroundTrans HWNDmain_text gBurn_all, available burn mods:
	ControlGetPos,,,, height,, ahk_id %main_text%
	sort_text0 := (sorting = "quantity") ? " q" : " t"
	sort_text1 := (sorting_order = "descending") ? "– " : "+ "
	Gui, archnemesis_window: Add, Text, ys x+10 BackgroundTrans gRecipes, % sort_text1 "/" sort_text0
	Gui, archnemesis_window: Font, s%fSize0% norm
	heightwin := ""
	If (unwanted_mods != "")
	{
		unwanted_mods_quant := ""
		Loop, Parse, unwanted_mods, `,,`,
		{
			If (A_LoopField = "") || (heightwin > poe_height*0.90)
				break
			count := 0
			Loop
			{
				If !InStr(archnemesis_inventory, A_LoopField,,, A_Index)
					break
				count += 1
			}
			If InStr(arch_surplus, A_LoopField)
			{
				count0 := 0
				Loop
				{
					If !InStr(arch_surplus, A_LoopField,,, A_Index)
						break
					count0 += 1
				}
				count := count0 - Burn_number
			}
			unwanted_mods_quant := (unwanted_mods_quant = "") ? count "x " A_LoopField "," : unwanted_mods_quant count "x " A_LoopField ","
		}
		unwanted_mods_quant0 := unwanted_mods_quant
		If (sorting = "quantity")
		{
			If (sorting_order = "descending")
				Sort, unwanted_mods_quant, D`, N R
			If (sorting_order = "ascending")
				Sort, unwanted_mods_quant, D`, N
		}
		Else
		{
			If (sorting_order = "ascending")
			{
				unwanted_mods_quant := ""
				Loop, Parse, unwanted_mods_quant0, `,,`,
				{
					If (A_LoopField = "")
						break
					unwanted_mods_quant := (unwanted_mods_quant = "") ? A_LoopField "," : A_LoopField "," unwanted_mods_quant
				}
			}
		}
		Loop, Parse, unwanted_mods_quant, `,,`,
		{
			If (A_LoopField = "")
				break
			color := InStr(arch_surplus, SubStr(A_LoopField, InStr(A_LoopField, "x ")+2)) ? "Yellow" : "White"
			color := InStr(blacklist_recipes, SubStr(A_LoopField, InStr(A_LoopField, "x ")+2)) ? "Red" : color
			Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section HWNDmain_text gRecipe_tree, % A_LoopField
			ini_section := SubStr(A_LoopField, InStr(A_LoopField, "x ")+2)
			IniRead, read, ini\db_archnemesis.ini, %ini_section%, rewards
			IniRead, modifiers, ini\db_archnemesis.ini, %ini_section%, modifiers
			ControlGetPos,, ypos,, height,, ahk_id %main_text%
			Loop, Parse, read, `,,`,
				Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
			If (modifiers != "ERROR")
			{
				Gui, archnemesis_window: Font, % "s"fSize1-1
				Gui, archnemesis_window: Add, Text, cSilver BackgroundTrans xs Section, % "    "
				Gui, archnemesis_window: Add, Text, cSilver BackgroundTrans ys, % modifiers
				Gui, archnemesis_window: Font, s%fSize0%
			}
			Gui, archnemesis_window: Show, Hide AutoSize
			WinGetPos,,,, heightwin
		}
	}
	Else unwanted_mods_quant := ""
}
Gui, archnemesis_window: Margin, 4, 4
Gui, archnemesis_window: Show, Hide AutoSize
WinGetPos,,, width, height
xWindow1 := xWindow + width
Gui, archnemesis_window: Show, % "NA x"xWindow " y"poe_height-height+yScreenOffset
hwnd_archnemesis_window := WinExist()
Return

Recipe_tree:
holdstart := A_TickCount
While GetKeyState("RButton", "P")
{
	If (A_TickCount >= holdstart + 250)
	{
		favor_choice := A_GuiControl
		GoSub, Favored_recipes
		Return
	}
}
If (click = 2) && InStr(favorite_recipes, A_GuiControl)
{
	GoSub, Pause_list
	Return
}
While GetKeyState("LButton", "P") && !InStr(arch_bases, SubStr(A_GuiControl, InStr(A_GuiControl, "x ")+2))
{
	If (A_TickCount >= holdstart + 100)
	{
		IniRead, components, ini\db_archnemesis.ini, %A_GuiControl%, components
		If (components = "ERROR")
		{
			KeyWait, LButton
			WinActivate, ahk_group poe_window
			Return
		}
		Gui, recipe_tree: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
		Gui, recipe_tree: Color, Black
		WinSet, Transparent, %trans%
		Gui, recipe_tree: Font, cWhite s%fSize0%, Fontin SmallCaps
		Gui, recipe_tree: Margin, 20, 0
		Loop, Parse, components, `,,`,
		{
			mod := A_LoopField
			count := 0
			Loop
			{
				check := InStr(archnemesis_inventory, mod,,, A_Index)
				If (check = 0)
					break
				Else count += 1
			}
			count := (count = 0) ? "" : " (" count ")"
			color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
			If (A_Index = 1)
				Gui, recipe_tree: Add, Text, x6 y2 BackgroundTrans c%color% HWNDmain_text Section Center, % A_LoopField count
			Else	Gui, recipe_tree: Add, Text, BackgroundTrans c%color% ys HWNDmain_text Section Center, % A_LoopField count
			IniRead, components, ini\db_archnemesis.ini, %A_LoopField%, components
			If (components != "ERROR") && (components != "")
			{
				Loop, Parse, components, `,,`,
				{
					mod := A_LoopField
					count := 0
					Loop
					{
						check := InStr(archnemesis_inventory, mod,,, A_Index)
						If (check = 0)
							break
						Else count += 1
					}
					count := (count = 0) ? "" : " (" count ")"
					color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
					Gui, recipe_tree: Add, Text, BackgroundTrans c%color% xs HWNDmain_text Center, % "    |–" A_LoopField count
					IniRead, components, ini\db_archnemesis.ini, %A_LoopField%, components
					If (components != "ERROR") && (components != "")
					{
						Loop, Parse, components, `,,`,
						{
							mod := A_LoopField
							count := 0
							Loop
							{
								check := InStr(archnemesis_inventory, mod,,, A_Index)
								If (check = 0)
									break
								Else count += 1
							}
							count := (count = 0) ? "" : " (" count ")"
							color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
							Gui, recipe_tree: Add, Text, BackgroundTrans c%color% xs HWNDmain_text Center, % "    |     |–" A_LoopField count
							IniRead, components, ini\db_archnemesis.ini, %A_LoopField%, components
							If (components != "ERROR") && (components != "")
							{
								Loop, Parse, components, `,,`,
								{
									mod := A_LoopField
									count := 0
									Loop
									{
										check := InStr(archnemesis_inventory, mod,,, A_Index)
										If (check = 0)
											break
										Else count += 1
									}
									count := (count = 0) ? "" : " (" count ")"
									color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
										Gui, recipe_tree: Add, Text, BackgroundTrans c%color% xs HWNDmain_text Center, % "    |     |     |–" A_LoopField count
									IniRead, components, ini\db_archnemesis.ini, %A_LoopField%, components
								}
							}
						}
					}
				}
			}
		}
		Gui, recipe_tree: Margin, 6, 4
		Gui, recipe_tree: Show, Hide
		MouseGetPos, mousex, mousey
		WinGetPos,,, width, height
		Gui, recipe_tree: Show, % "Hide x"xWindow1 " y"mousey
		WinGetPos, winx, winy, width, height
		If (winy+height > yScreenOffset+poe_height)
			ywincoord := yScreenOffset+poe_height-height
		Else ywincoord := mousey
		If (winx+width > xScreenOffset+poe_width)
			xwincoord := xScreenOffset+poe_width-width
		Else	xwincoord := xWindow1
		Gui, recipe_tree: Show, % "NA x"xwincoord " y"ywincoord
		KeyWait, LButton
		Gui, recipe_tree: Destroy
		WinActivate, ahk_group poe_window
		Return
	}
}
If InStr(archnemesis_inventory, SubStr(A_GuiControl, InStr(A_GuiControl, "x ")+2))
{
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	clipboard := InStr(A_GuiControl, "x ") ? "^"SubStr(StrReplace(SubStr(A_GuiControl, InStr(A_GuiControl, "x ")+2), A_Space, "."), 1, 8) : "^"SubStr(StrReplace(A_GuiControl, A_Space, "."), 1, 8)
	SendInput, ^{f}^{v}{Enter}
}
Else WinActivate, ahk_group poe_window
Return

Resolution_choice:
Gui, resolutionGUI: Submit, NoHide
If forced_resolution is number
	Gui, resolutionGUI: Destroy
Return

Scan:
If (xScan = "") || (xScan = "ERROR")
{
	MsgBox, Scanning the archnemesis inventory at this resolution is not yet supported.
	Return
}
Gui, archnemesis_list: Destroy
hwnd_archnemesis_list := ""
Gui, surplus_view: Destroy
hwnd_surplus_view := ""
clipboard := ""
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
If (click = 2)
	SendInput, ^{f}^{x}{Enter}
Else SendInput, ^{f}{ESC}
KeyWait, LButton
sleep, 100
scan_in_progress := 1
bmpHaystack := Gdip_BitmapFromScreen(xScreenOffset "|" yScreenOffset "|" poe_width "|" poe_height)
start := A_TickCount
archnemesis_inventory_prelim := ""
xGrid := []
yGrid := []
progress := 0
Loop, Parse, xScan, `,,`,
	xGrid.Push(A_LoopField+xScreenOffset)
Loop, Parse, yScan, `,,`,
	yGrid.Push(A_LoopField+yScreenOffset)
Loop, % xGrid.Length()
{
	xArrow := xGrid[A_Index] + dBitMap//2
	xGridScan0 := xGrid[A_Index]
	xGridScan1 := xGrid[A_Index] + dBitMap
	xBitMap := xGridScan0
	Loop, % yGrid.Length()
	{
		progress += 1
		comparison := 0
		ToolTip, % "Progress: " progress "/64", xScan_button, yLetters+50, 17
		yArrow := yGrid[A_Index]
		yGridScan0 := yGrid[A_Index]
		yGridScan1 := yGrid[A_Index] + dBitMap
		yBitMap := yGridScan0
		If !FileExist("img\Recognition\" poe_height "p\Archnemesis\*.png")
			GoSub, Recalibrate
		Else
		{
			If (arch_inventory != "")
			{
				compare := arch_inventory[progress]
				If (compare != "")
				{
					Loop, Files, img\Recognition\%poe_height%p\Archnemesis\%compare%*.png
					{
						bmpNeedle := Gdip_CreateBitmapFromFile(A_LoopFilePath)
						comparison := Gdip_ImageSearch(bmpHaystack, bmpNeedle, LIST, xGridScan0, yGridScan0, xGridScan1, yGridScan1, 25,, 1, 1)
						Gdip_DisposeImage(bmpNeedle)
						If (comparison = 1)
							break
					}
				}
			}
			If (comparison != 1)
			{
				match := ""
				Loop, Parse, all_nemesis_unsorted, `n,`n ;Loop, Files, img\Recognition\%poe_height%p\Archnemesis\*.png
				{
					file_check := "img\Recognition\" poe_height "p\Archnemesis\" A_LoopField "*.png"
					Loop, Files, %file_check%
					{
						bmpNeedle := Gdip_CreateBitmapFromFile(A_LoopFilePath)
						comparison := Gdip_ImageSearch(bmpHaystack, bmpNeedle, LIST, xGridScan0, yGridScan0, xGridScan1, yGridScan1, 25,, 1 , 1)
						Gdip_DisposeImage(bmpNeedle)
						If (comparison = 1)
						{
							SplitPath, A_LoopFileName,,,, match,
							break
						}
					}
					If (comparison = 1)
						break
				}
			}
			Else match := compare
			Loop, 10
			{
				If (A_Index = 10)
					match := StrReplace(match, "0", "")
				Else match := StrReplace(match, A_Index, "")
			}
			If (match = "")
				GoSub, Recalibrate
			else	archnemesis_inventory_prelim := (archnemesis_inventory_prelim = "") ? match : archnemesis_inventory_prelim "," match
		}
	}
}
Gdip_DisposeImage(bmpHaystack)
archnemesis_inventory := archnemesis_inventory_prelim
background_inventory_prelim := archnemesis_inventory_prelim
arch_inventory := []
Loop, Parse, archnemesis_inventory, `,,`,
	arch_inventory.Push(A_LoopField)
Gui, recal_arrow: Destroy
ToolTip,,,,17
GoSub, Favored_recipes
scan_in_progress := (background_scan_in_progress = 1) ? 1 : ""
If (click = 2)
{
	LLK_Recipes("auto_highlight")
	Return
}
Return

Scan_background:
SetTimer, Scan_background, Delete
start := A_TickCount
scan_unknown := 0
background_scan_in_progress := 1
background_Haystack := Gdip_BitmapFromScreen(xScreenOffset "|" yScreenOffset "|" poe_width "|" poe_height)
background_inventory := (background_inventory_prelim = "") ? archnemesis_inventory : background_inventory_prelim
back_inventory := []
Loop, Parse, background_inventory, `,,`,
	back_inventory.Push(A_LoopField)
background_inventory_prelim := ""
background_xGrid := []
background_yGrid := []
background_progress := 0
Loop, Parse, xScan, `,,`,
	background_xGrid.Push(A_LoopField+xScreenOffset)
Loop, Parse, yScan, `,,`,
	background_yGrid.Push(A_LoopField+yScreenOffset)
Loop, % background_xGrid.Length()
{
	background_xGridScan0 := background_xGrid[A_Index]
	background_xGridScan1 := background_xGrid[A_Index] + dBitMap
	background_xBitMap := background_xGridScan0
	Loop, % background_yGrid.Length()
	{
		background_progress += 1
		background_comparison := 0
		background_yGridScan0 := background_yGrid[A_Index]
		background_yGridScan1 := background_yGrid[A_Index] + dBitMap
		background_yBitMap := background_yGridScan0
		If !FileExist("img\Recognition\" poe_height "p\Archnemesis\*.png") || (scan_unknown > 2) || (scan_in_progress = 1)
		{
			Gdip_DisposeImage(background_Haystack)
			background_scanned := 1
			background_inventory_prelim := ""
			scan_in_progress = ""
			background_scan_in_progress = ""
			Return
		}
		Else
		{
			If (background_inventory != "")
			{
				background_compare := back_inventory[background_progress]
				If (background_compare != "")
				{
					Loop, Files, img\Recognition\%poe_height%p\Archnemesis\%background_compare%*.png
					{
						background_Needle := Gdip_CreateBitmapFromFile(A_LoopFilePath)
						background_comparison := Gdip_ImageSearch(background_Haystack, background_Needle, LIST, background_xGridScan0, background_yGridScan0, background_xGridScan1, background_yGridScan1, 25,, 1, 1)
						Gdip_DisposeImage(background_Needle)
						If (background_comparison = 1)
							break
					}
				}
			}
			If (background_comparison != 1)
			{
				background_match := ""
				Loop, Parse, all_nemesis_unsorted, `n,`n ;Loop, Files, img\Recognition\%poe_height%p\Archnemesis\*.png
				{
					file_check := "img\Recognition\" poe_height "p\Archnemesis\" A_LoopField "*.png"
					Loop, Files, %file_check%
					{
						background_Needle := Gdip_CreateBitmapFromFile(A_LoopFilePath)
						background_comparison := Gdip_ImageSearch(background_Haystack, background_Needle, LIST, background_xGridScan0, background_yGridScan0, background_xGridScan1, background_yGridScan1, 25,, 1 , 1)
						Gdip_DisposeImage(background_Needle)
						If (background_comparison = 1)
						{
							SplitPath, A_LoopFileName,,,, background_match,
							break
						}
					}
					If (background_comparison = 1)
						break
				}
			}
			Else background_match := background_compare
			Loop, 10
			{
				If (A_Index = 10)
					background_match := StrReplace(background_match, "0", "")
				Else background_match := StrReplace(background_match, A_Index, "")
			}
			If (background_match = "")
			{
				background_match := "-empty-"
				scan_unknown += 1
			}
			background_inventory_prelim := (background_inventory_prelim = "") ? background_match : background_inventory_prelim "," background_match
		}
	}
}
Gdip_DisposeImage(background_Haystack)
background_inventory := background_inventory_prelim
arch_inventory := []
Loop, Parse, background_inventory, `,,`,
	arch_inventory.Push(A_LoopField)
background_scanned := 1
background_scan_in_progress := ""
Return

LLK_Rightclick()
{
	global
	click := 2
	SendInput, {LButton}
	KeyWait, RButton
	click := 1
}

LLK_Recipes(x := 0, y := 0)
{
	global
	If (x = "auto_highlight")
	{
		If (clipboard != "")
		{
			clipboard_check := clipboard
			clipboard_check := StrReplace(clipboard_check, "^", "")
			clipboard_check := StrReplace(clipboard_check, "(", "")
			clipboard_check := StrReplace(clipboard_check, ")", "")
			count := 0
			Loop, Parse, clipboard_check, |, |
				count += 1
		}
		Else
		{
			count := 0
			clipboard_check := ""
		}
		prio_chosen := 0
		burn_chosen := 0
		highlight := 0
		If (count < 4)
		{
			If (available_recipes != "")
			{
				Loop, Parse, available_recipes, `,,`,
				{
					If (A_LoopField = "")
						break
					comp_count := 0
					IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
					recipe0 := ""
					Loop, Parse, recipe, `,,`,
					{
						comp_count += InStr(clipboard_check, StrReplace(SubStr(A_LoopField, 1, 8), A_Space, ".")) ? 5 : 1
						recipe0 := (recipe0 = "") ? SubStr(A_LoopField, 1, 8) : recipe0 "|" SubStr(A_LoopField, 1, 8)
					}
					If (count + comp_count < 5)
					{
						prio_chosen := 1
						highlight := 1
						clipboard_check := (clipboard_check = "") ? recipe0 : clipboard_check "|" recipe0
						x := clipboard_check
						y := 2
						break
					}
				}
			}
			If (unwanted_recipes != "") && (highlight = 0)
			{
				Loop, Parse, unwanted_recipes, `,,`,
				{
					If (A_LoopField = "")
						break
					If InStr(blacklist_recipes, A_LoopField)
						continue
					comp_count := 0
					IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
					recipe0 := ""
					Loop, Parse, recipe, `,,`,
					{
						comp_count += InStr(clipboard_check, StrReplace(SubStr(A_LoopField, 1, 8), A_Space, ".")) ? 5 : 1
						recipe0 := (recipe0 = "") ? SubStr(A_LoopField, 1, 8) : recipe0 "|" SubStr(A_LoopField, 1, 8)
					}
					If (count + comp_count < 5)
					{
						burn_chosen := 1
						highlight := 1
						clipboard_check := (clipboard_check = "") ? recipe0 : clipboard_check "|" recipe0
						x := clipboard_check
						y := 2
						break
					}
				}
			}
			If (unwanted_mods_quant != "") && (highlight = 0)
			{
				Loop, Parse, unwanted_mods_quant, `,,`,
				{
					If (A_LoopField = "")
						break
					If InStr(blacklist_recipes, SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8))
						continue
					comp_count := 0
					comp_count += InStr(clipboard_check, StrReplace(SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8), A_Space, ".")) ? 5 : 1
					If (count + comp_count < 5)
					{
						burn_chosen := 1
						clipboard_check := (clipboard_check = "") ? SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8) : clipboard_check "|" SubStr(A_LoopField, InStr(A_LoopField, "x ")+2, 8)
						x := clipboard_check
						y := 2
						break
					}
				}
			}
			If (prio_chosen = 0 && burn_chosen = 0) && (clipboard_check != "")
			{
				x := clipboard_check
				y := 2
			}
		}
		Else
		{
			x := clipboard_check
			y := 2
		}
	}
	If (x != 0)
	{
		search_term := ""
		If (y = 2)
			search_term := x
		If (y = 1)
		{
			IniRead, read, ini\db_archnemesis.ini, %x%, components
			If (read != "ERROR")
			{
				Loop, Parse, read, `,,`,
					search_term := (search_term = "") ? SubStr(A_LoopField, 1, 8) : search_term "|" SubStr(A_LoopField, 1, 8)
			}
		}
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		search_term := StrReplace(search_term, A_Space, ".")
		clipboard := "^(" search_term ")"
		previous_highlight := search_term
		SendInput, ^{f}^{v}{Enter}
		;Return
	}
}

LLK_Overlay(x, y:=0)
{
	global
	If (x="hide")
	{
		Loop, Parse, guilist, |, |
			Gui, %A_LoopField%: Hide
		Return
	}
	If (x="show")
	{
		Loop, Parse, guilist, |, |
			If (state_%A_LoopField%=1) && (hwnd_%A_LoopField% != "")
				Gui, %A_LoopField%: Show, NA
		Return
	}
	If (y=0)
	{
		If !WinExist("ahk_id " hwnd_%x%) && (hwnd_%x% != "")
		{
			Gui, %x%: Show, NA
			state_%x% := 1
			Return
		}
		If WinExist("ahk_id " hwnd_%x%)
		{
			Gui, %x%: Hide
			state_%x% := 0
			Return
		}
	}
	If (y=1)
	{
		Gui, %x%: Show, NA
		state_%x% := 1
	}
	If (y=2)
	{
		Gui, %x%: Hide
		state_%x% := 0
	}
}

LLK_PixelSearch(x)
{
	global
	PixelSearch, OutputVarX, OutputVarY, %x%1_x, %x%1_y, %x%1_x, %x%1_y, %x%1_color, %pixelsearch_variation%, Fast RGB
		If (ErrorLevel=0)
			PixelSearch, OutputVarX, OutputVarY, %x%2_x, %x%2_y, %x%2_x, %x%2_y, %x%2_color, %pixelsearch_variation%, Fast RGB
	%x% := (ErrorLevel=0) ? 1 : 0
	value := %x%
	Return value
}

HasVal(haystack, needle)
{
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

Gdip_BitmapFromScreen(Screen=0, Raster="")
{
	if (Screen = 0)
	{
		Sysget, x, 76
		Sysget, y, 77	
		Sysget, w, 78
		Sysget, h, 79
	}
	else if (SubStr(Screen, 1, 5) = "hwnd:")
	{
		Screen := SubStr(Screen, 6)
		if !WinExist( "ahk_id " Screen)
			return -2
		WinGetPos,,, w, h, ahk_id %Screen%
		x := y := 0
		hhdc := GetDCEx(Screen, 3)
	}
	else if (Screen&1 != "")
	{
		Sysget, M, Monitor, %Screen%
		x := MLeft, y := MTop, w := MRight-MLeft, h := MBottom-MTop
	}
	else
	{
		StringSplit, S, Screen, |
		x := S1, y := S2, w := S3, h := S4
	}

	if (x = "") || (y = "") || (w = "") || (h = "")
		return -1

	chdc := CreateCompatibleDC(), hbm := CreateDIBSection(w, h, chdc), obm := SelectObject(chdc, hbm), hhdc := hhdc ? hhdc : GetDC()
	BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
	ReleaseDC(hhdc)
	
	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
	return pBitmap
}

GetDC(hwnd=0)
{
	return DllCall("GetDC", A_PtrSize ? "UPtr" : "UInt", hwnd)
}

GetDCEx(hwnd, flags=0, hrgnClip=0)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
    return DllCall("GetDCEx", Ptr, hwnd, Ptr, hrgnClip, "int", flags)
}

CreateCompatibleDC(hdc=0)
{
   return DllCall("CreateCompatibleDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

CreateDIBSection(w, h, hdc="", bpp=32, ByRef ppvBits=0)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	hdc2 := hdc ? hdc : GetDC()
	VarSetCapacity(bi, 40, 0)
	
	NumPut(w, bi, 4, "uint")
	, NumPut(h, bi, 8, "uint")
	, NumPut(40, bi, 0, "uint")
	, NumPut(1, bi, 12, "ushort")
	, NumPut(0, bi, 16, "uInt")
	, NumPut(bpp, bi, 14, "ushort")
	
	hbm := DllCall("CreateDIBSection"
					, Ptr, hdc2
					, Ptr, &bi
					, "uint", 0
					, A_PtrSize ? "UPtr*" : "uint*", ppvBits
					, Ptr, 0
					, "uint", 0, Ptr)

	if !hdc
		ReleaseDC(hdc2)
	return hbm
}

SelectObject(hdc, hgdiobj)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	return DllCall("SelectObject", Ptr, hdc, Ptr, hgdiobj)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster="")
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	return DllCall("gdi32\BitBlt"
					, Ptr, dDC
					, "int", dx
					, "int", dy
					, "int", dw
					, "int", dh
					, Ptr, sDC
					, "int", sx
					, "int", sy
					, "uint", Raster ? Raster : 0x00CC0020)
}

ReleaseDC(hdc, hwnd=0)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	return DllCall("ReleaseDC", Ptr, hwnd, Ptr, hdc)
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette=0)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", Ptr, hBitmap, Ptr, Palette, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
	return pBitmap
}

DeleteObject(hObject)
{
   return DllCall("DeleteObject", A_PtrSize ? "UPtr" : "UInt", hObject)
}

DeleteDC(hdc)
{
   return DllCall("DeleteDC", A_PtrSize ? "UPtr" : "UInt", hdc)
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality=75)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	SplitPath, sOutput,,, Extension
	if Extension not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
		return -1
	Extension := "." Extension

	DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
	VarSetCapacity(ci, nSize)
	DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
	if !(nCount && nSize)
		return -2
	
	If (A_IsUnicode){
		StrGet_Name := "StrGet"
		Loop, %nCount%
		{
			sString := %StrGet_Name%(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
			if !InStr(sString, "*" Extension)
				continue
			
			pCodec := &ci+idx
			break
		}
	} else {
		Loop, %nCount%
		{
			Location := NumGet(ci, 76*(A_Index-1)+44)
			nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
			VarSetCapacity(sString, nSize)
			DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
			if !InStr(sString, "*" Extension)
				continue
			
			pCodec := &ci+76*(A_Index-1)
			break
		}
	}
	
	if !pCodec
		return -3

	if (Quality != 75)
	{
		Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
		if Extension in .JPG,.JPEG,.JPE,.JFIF
		{
			DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
			VarSetCapacity(EncoderParameters, nSize, 0)
			DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
			Loop, % NumGet(EncoderParameters, "UInt")      ;%
			{
				elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
				if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
				{
					p := elem+&EncoderParameters-pad-4
					NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
					break
				}
			}      
		}
	}

	if (!A_IsUnicode)
	{
		nSize := DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, 0, "int", 0)
		VarSetCapacity(wOutput, nSize*2)
		DllCall("MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sOutput, "int", -1, Ptr, &wOutput, "int", nSize)
		VarSetCapacity(wOutput, -1)
		if !VarSetCapacity(wOutput)
			return -4
		E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &wOutput, Ptr, pCodec, "uint", p ? p : 0)
	}
	else
		E := DllCall("gdiplus\GdipSaveImageToFile", Ptr, pBitmap, Ptr, &sOutput, Ptr, pCodec, "uint", p ? p : 0)
	return E ? -5 : 0
}

Gdip_Startup()
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("LoadLibrary", "str", "gdiplus")
	VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
	return pToken
}

Gdip_Shutdown(pToken)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
	if hModule := DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("FreeLibrary", Ptr, hModule)
	return 0
}

Gdip_GetImageDimensions(pBitmap, ByRef Width, ByRef Height)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	DllCall("gdiplus\GdipGetImageWidth", Ptr, pBitmap, "uint*", Width)
	DllCall("gdiplus\GdipGetImageHeight", Ptr, pBitmap, "uint*", Height)
}

Gdip_LockBits(pBitmap, x, y, w, h, ByRef Stride, ByRef Scan0, ByRef BitmapData, LockMode = 3, PixelFormat = 0x26200a)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	CreateRect(Rect, x, y, w, h)
	VarSetCapacity(BitmapData, 16+2*(A_PtrSize ? A_PtrSize : 4), 0)
	E := DllCall("Gdiplus\GdipBitmapLockBits", Ptr, pBitmap, Ptr, &Rect, "uint", LockMode, "int", PixelFormat, Ptr, &BitmapData)
	Stride := NumGet(BitmapData, 8, "Int")
	Scan0 := NumGet(BitmapData, 16, Ptr)
	return E
}

CreateRect(ByRef Rect, x, y, w, h)
{
	VarSetCapacity(Rect, 16)
	NumPut(x, Rect, 0, "uint"), NumPut(y, Rect, 4, "uint"), NumPut(w, Rect, 8, "uint"), NumPut(h, Rect, 12, "uint")
}

Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format=0x26200A)
{
	DllCall("gdiplus\GdipCloneBitmapArea"
					, "float", x
					, "float", y
					, "float", w
					, "float", h
					, "int", Format
					, A_PtrSize ? "UPtr" : "UInt", pBitmap
					, A_PtrSize ? "UPtr*" : "UInt*", pBitmapDest)
	return pBitmapDest
}

Gdip_DisposeImage(pBitmap)
{
   return DllCall("gdiplus\GdipDisposeImage", A_PtrSize ? "UPtr" : "UInt", pBitmap)
}

Gdip_UnlockBits(pBitmap, ByRef BitmapData)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	return DllCall("Gdiplus\GdipBitmapUnlockBits", Ptr, pBitmap, Ptr, &BitmapData)
}

Gdip_FromARGB(ARGB, ByRef A, ByRef R, ByRef G, ByRef B)
{
	A := (0xff000000 & ARGB) >> 24
	R := (0x00ff0000 & ARGB) >> 16
	G := (0x0000ff00 & ARGB) >> 8
	B := 0x000000ff & ARGB
}

Gdip_CreateBitmapFromFile(sFile, IconNumber=1, IconSize="")
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	, PtrA := A_PtrSize ? "UPtr*" : "UInt*"
	
	SplitPath, sFile,,, ext
	if ext in exe,dll
	{
		Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
		BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))
		
		VarSetCapacity(buf, BufSize, 0)
		Loop, Parse, Sizes, |
		{
			DllCall("PrivateExtractIcons", "str", sFile, "int", IconNumber-1, "int", A_LoopField, "int", A_LoopField, PtrA, hIcon, PtrA, 0, "uint", 1, "uint", 0)
			
			if !hIcon
				continue

			if !DllCall("GetIconInfo", Ptr, hIcon, Ptr, &buf)
			{
				DestroyIcon(hIcon)
				continue
			}
			
			hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4))
			hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
			if !(hbmColor && DllCall("GetObject", Ptr, hbmColor, "int", BufSize, Ptr, &buf))
			{
				DestroyIcon(hIcon)
				continue
			}
			break
		}
		if !hIcon
			return -1

		Width := NumGet(buf, 4, "int"), Height := NumGet(buf, 8, "int")
		hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
		if !DllCall("DrawIconEx", Ptr, hdc, "int", 0, "int", 0, Ptr, hIcon, "uint", Width, "uint", Height, "uint", 0, Ptr, 0, "uint", 3)
		{
			DestroyIcon(hIcon)
			return -2
		}
		
		VarSetCapacity(dib, 104)
		DllCall("GetObject", Ptr, hbm, "int", A_PtrSize = 8 ? 104 : 84, Ptr, &dib) ; sizeof(DIBSECTION) = 76+2*(A_PtrSize=8?4:0)+2*A_PtrSize
		Stride := NumGet(dib, 12, "Int"), Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0)) ; padding
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", Stride, "int", 0x26200A, Ptr, Bits, PtrA, pBitmapOld)
		pBitmap := Gdip_CreateBitmap(Width, Height)
		G := Gdip_GraphicsFromImage(pBitmap)
		, Gdip_DrawImage(G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
		SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
		Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapOld)
		DestroyIcon(hIcon)
	}
	else
	{
		if (!A_IsUnicode)
		{
			VarSetCapacity(wFile, 1024)
			DllCall("kernel32\MultiByteToWideChar", "uint", 0, "uint", 0, Ptr, &sFile, "int", -1, Ptr, &wFile, "int", 512)
			DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &wFile, PtrA, pBitmap)
		}
		else
			DllCall("gdiplus\GdipCreateBitmapFromFile", Ptr, &sFile, PtrA, pBitmap)
	}
	
	return pBitmap
}

DestroyIcon(hIcon)
{
	return DllCall("DestroyIcon", A_PtrSize ? "UPtr" : "UInt", hIcon)
}

Gdip_CreateBitmap(Width, Height, Format=0x26200A)
{
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", Width, "int", Height, "int", 0, "int", Format, A_PtrSize ? "UPtr" : "UInt", 0, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
    Return pBitmap
}

Gdip_GraphicsFromImage(pBitmap)
{
	DllCall("gdiplus\GdipGetImageGraphicsContext", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "UInt*", pGraphics)
	return pGraphics
}

Gdip_DrawImage(pGraphics, pBitmap, dx="", dy="", dw="", dh="", sx="", sy="", sw="", sh="", Matrix=1)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	if (Matrix&1 = "")
		ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
	else if (Matrix != 1)
		ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")

	if (sx = "" && sy = "" && sw = "" && sh = "")
	{
		if (dx = "" && dy = "" && dw = "" && dh = "")
		{
			sx := dx := 0, sy := dy := 0
			sw := dw := Gdip_GetImageWidth(pBitmap)
			sh := dh := Gdip_GetImageHeight(pBitmap)
		}
		else
		{
			sx := sy := 0
			sw := Gdip_GetImageWidth(pBitmap)
			sh := Gdip_GetImageHeight(pBitmap)
		}
	}

	E := DllCall("gdiplus\GdipDrawImageRectRect"
				, Ptr, pGraphics
				, Ptr, pBitmap
				, "float", dx
				, "float", dy
				, "float", dw
				, "float", dh
				, "float", sx
				, "float", sy
				, "float", sw
				, "float", sh
				, "int", 2
				, Ptr, ImageAttr
				, Ptr, 0
				, Ptr, 0)
	if ImageAttr
		Gdip_DisposeImageAttributes(ImageAttr)
	return E
}

Gdip_DeleteGraphics(pGraphics)
{
   return DllCall("gdiplus\GdipDeleteGraphics", A_PtrSize ? "UPtr" : "UInt", pGraphics)
}

Gdip_SetImageAttributesColorMatrix(Matrix)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	
	VarSetCapacity(ColourMatrix, 100, 0)
	Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", "", 1), "[^\d-\.]+", "|")
	StringSplit, Matrix, Matrix, |
	Loop, 25
	{
		Matrix := (Matrix%A_Index% != "") ? Matrix%A_Index% : Mod(A_Index-1, 6) ? 0 : 1
		NumPut(Matrix, ColourMatrix, (A_Index-1)*4, "float")
	}
	DllCall("gdiplus\GdipCreateImageAttributes", A_PtrSize ? "UPtr*" : "uint*", ImageAttr)
	DllCall("gdiplus\GdipSetImageAttributesColorMatrix", Ptr, ImageAttr, "int", 1, "int", 1, Ptr, &ColourMatrix, Ptr, 0, "int", 0)
	return ImageAttr
}

Gdip_GetImageWidth(pBitmap)
{
   DllCall("gdiplus\GdipGetImageWidth", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Width)
   return Width
}

Gdip_GetImageHeight(pBitmap)
{
   DllCall("gdiplus\GdipGetImageHeight", A_PtrSize ? "UPtr" : "UInt", pBitmap, "uint*", Height)
   return Height
}

Gdip_DisposeImageAttributes(ImageAttr)
{
	return DllCall("gdiplus\GdipDisposeImageAttributes", A_PtrSize ? "UPtr" : "UInt", ImageAttr)
}

;**********************************************************************************
;
; Gdip_ImageSearch()
; by MasterFocus - 02/APRIL/2013 00:30h BRT
; Thanks to guest3456 for helping me ponder some ideas
; Requires GDIP, Gdip_SetBitmapTransColor() and Gdip_MultiLockedBitsSearch()
; http://www.autohotkey.com/board/topic/71100-gdip-imagesearch/
;
; Licensed under CC BY-SA 3.0 -> http://creativecommons.org/licenses/by-sa/3.0/
; I waive compliance with the "Share Alike" condition of the license EXCLUSIVELY
; for these users: tic , Rseding91 , guest3456
;
;==================================================================================
;
; This function searches for pBitmapNeedle within pBitmapHaystack
; The returned value is the number of instances found (negative = error)
;
; ++ PARAMETERS ++
;
; pBitmapHaystack and pBitmapNeedle
;   Self-explanatory bitmap pointers, are the only required parameters
;
; OutputList
;   ByRef variable to store the list of coordinates where a match was found
;
; OuterX1, OuterY1, OuterX2, OuterY2
;   Equivalent to ImageSearch's X1,Y1,X2,Y2
;   Default: 0 for all (which searches the whole haystack area)
;
; Variation
;   Just like ImageSearch, a value from 0 to 255
;   Default: 0
;
; Trans
;   Needle RGB transparent color, should be a numerical value from 0 to 0xFFFFFF
;   Default: blank (does not use transparency)
;
; SearchDirection
;   Haystack search direction
;     Vertical preference:
;       1 = top->left->right->bottom [default]
;       2 = bottom->left->right->top
;       3 = bottom->right->left->top
;       4 = top->right->left->bottom
;     Horizontal preference:
;       5 = left->top->bottom->right
;       6 = left->bottom->top->right
;       7 = right->bottom->top->left
;       8 = right->top->bottom->left
;
; Instances
;   Maximum number of instances to find when searching (0 = find all)
;   Default: 1 (stops after one match is found)
;
; LineDelim and CoordDelim
;   Outer and inner delimiters for the list of coordinates (OutputList)
;   Defaults: "`n" and ","
;
; ++ RETURN VALUES ++
;
; -1001 ==> invalid haystack and/or needle bitmap pointer
; -1002 ==> invalid variation value
; -1003 ==> X1 and Y1 cannot be negative
; -1004 ==> unable to lock haystack bitmap bits
; -1005 ==> unable to lock needle bitmap bits
; any non-negative value ==> the number of instances found
;
;==================================================================================
;
;**********************************************************************************

Gdip_ImageSearch(pBitmapHaystack,pBitmapNeedle,ByRef OutputList=""
,OuterX1=0,OuterY1=0,OuterX2=0,OuterY2=0,Variation=0,Trans=""
,SearchDirection=1,Instances=1,LineDelim="`n",CoordDelim=",") {

    ; Some validations that can be done before proceeding any further
    If !( pBitmapHaystack && pBitmapNeedle )
        Return -1001
    If Variation not between 0 and 255
        return -1002
    If ( ( OuterX1 < 0 ) || ( OuterY1 < 0 ) )
        return -1003
    If SearchDirection not between 1 and 8
        SearchDirection := 1
    If ( Instances < 0 )
        Instances := 0

    ; Getting the dimensions and locking the bits [haystack]
    Gdip_GetImageDimensions(pBitmapHaystack,hWidth,hHeight)
    ; Last parameter being 1 says the LockMode flag is "READ only"
    If Gdip_LockBits(pBitmapHaystack,0,0,hWidth,hHeight,hStride,hScan,hBitmapData,1)
    OR !(hWidth := NumGet(hBitmapData,0,"UInt"))
    OR !(hHeight := NumGet(hBitmapData,4,"UInt"))
        Return -1004

    ; Careful! From this point on, we must do the following before returning:
    ; - unlock haystack bits

    ; Getting the dimensions and locking the bits [needle]
    Gdip_GetImageDimensions(pBitmapNeedle,nWidth,nHeight)
    ; If Trans is correctly specified, create a backup of the original needle bitmap
    ; and modify the current one, setting the desired color as transparent.
    ; Also, since a copy is created, we must remember to dispose the new bitmap later.
    ; This whole thing has to be done before locking the bits.
    If Trans between 0 and 0xFFFFFF
    {
        pOriginalBmpNeedle := pBitmapNeedle
        pBitmapNeedle := Gdip_CloneBitmapArea(pOriginalBmpNeedle,0,0,nWidth,nHeight)
        Gdip_SetBitmapTransColor(pBitmapNeedle,Trans)
        DumpCurrentNeedle := true
    }

    ; Careful! From this point on, we must do the following before returning:
    ; - unlock haystack bits
    ; - dispose current needle bitmap (if necessary)

    If Gdip_LockBits(pBitmapNeedle,0,0,nWidth,nHeight,nStride,nScan,nBitmapData)
    OR !(nWidth := NumGet(nBitmapData,0,"UInt"))
    OR !(nHeight := NumGet(nBitmapData,4,"UInt"))
    {
        If ( DumpCurrentNeedle )
            Gdip_DisposeImage(pBitmapNeedle)
        Gdip_UnlockBits(pBitmapHaystack,hBitmapData)
        Return -1005
    }
    
    ; Careful! From this point on, we must do the following before returning:
    ; - unlock haystack bits
    ; - unlock needle bits
    ; - dispose current needle bitmap (if necessary)

    ; Adjust the search box. "OuterX2,OuterY2" will be the last pixel evaluated
    ; as possibly matching with the needle's first pixel. So, we must avoid going
    ; beyond this maximum final coordinate.
    OuterX2 := ( !OuterX2 ? hWidth-nWidth+1 : OuterX2-nWidth+1 )
    OuterY2 := ( !OuterY2 ? hHeight-nHeight+1 : OuterY2-nHeight+1 )

    OutputCount := Gdip_MultiLockedBitsSearch(hStride,hScan,hWidth,hHeight
    ,nStride,nScan,nWidth,nHeight,OutputList,OuterX1,OuterY1,OuterX2,OuterY2
    ,Variation,SearchDirection,Instances,LineDelim,CoordDelim)

    Gdip_UnlockBits(pBitmapHaystack,hBitmapData)
    Gdip_UnlockBits(pBitmapNeedle,nBitmapData)
    If ( DumpCurrentNeedle )
        Gdip_DisposeImage(pBitmapNeedle)

    Return OutputCount
}

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

;**********************************************************************************
;
; Gdip_SetBitmapTransColor()
; by MasterFocus - 02/APRIL/2013 00:30h BRT
; Requires GDIP
; http://www.autohotkey.com/board/topic/71100-gdip-imagesearch/
;
; Licensed under CC BY-SA 3.0 -> http://creativecommons.org/licenses/by-sa/3.0/
; I waive compliance with the "Share Alike" condition of the license EXCLUSIVELY
; for these users: tic , Rseding91 , guest3456
;
;**********************************************************************************

;==================================================================================
;
; This function modifies the Alpha component for all pixels of a certain color to 0
; The returned value is 0 in case of success, or a negative number otherwise
;
; ++ PARAMETERS ++
;
; pBitmap
;   A valid pointer to the bitmap that will be modified
;
; TransColor
;   The color to become transparent
;   Should range from 0 (black) to 0xFFFFFF (white)
;
; ++ RETURN VALUES ++
;
; -2001 ==> invalid bitmap pointer
; -2002 ==> invalid TransColor
; -2003 ==> unable to retrieve bitmap positive dimensions
; -2004 ==> unable to lock bitmap bits
; -2005 ==> DllCall failed (see ErrorLevel)
; any non-negative value ==> the number of pixels modified by this function
;
;==================================================================================

Gdip_SetBitmapTransColor(pBitmap,TransColor) {
    static _SetBmpTrans, Ptr, PtrA
    if !( _SetBmpTrans ) {
        Ptr := A_PtrSize ? "UPtr" : "UInt"
        PtrA := Ptr . "*"
        MCode_SetBmpTrans := "
            (LTrim Join
            8b44240c558b6c241cc745000000000085c07e77538b5c2410568b74242033c9578b7c2414894c24288da424000000
            0085db7e458bc18d1439b9020000008bff8a0c113a4e0275178a4c38013a4e01750e8a0a3a0e7508c644380300ff450083c0
            0483c204b9020000004b75d38b4c24288b44241c8b5c2418034c242048894c24288944241c75a85f5e5b33c05dc3,405
            34c8b5424388bda41c702000000004585c07e6448897c2410458bd84c8b4424304963f94c8d49010f1f800000000085db7e3
            8498bc1488bd3660f1f440000410fb648023848017519410fb6480138087510410fb6083848ff7507c640020041ff024883c
            00448ffca75d44c03cf49ffcb75bc488b7c241033c05bc3
            )"
        if ( A_PtrSize == 8 ) ; x64, after comma
            MCode_SetBmpTrans := SubStr(MCode_SetBmpTrans,InStr(MCode_SetBmpTrans,",")+1)
        else ; x86, before comma
            MCode_SetBmpTrans := SubStr(MCode_SetBmpTrans,1,InStr(MCode_SetBmpTrans,",")-1)
        VarSetCapacity(_SetBmpTrans, LEN := StrLen(MCode_SetBmpTrans)//2, 0)
        Loop, %LEN%
            NumPut("0x" . SubStr(MCode_SetBmpTrans,(2*A_Index)-1,2), _SetBmpTrans, A_Index-1, "uchar")
        MCode_SetBmpTrans := ""
        DllCall("VirtualProtect", Ptr,&_SetBmpTrans, Ptr,VarSetCapacity(_SetBmpTrans), "uint",0x40, PtrA,0)
    }
    If !pBitmap
        Return -2001
    If TransColor not between 0 and 0xFFFFFF
        Return -2002
    Gdip_GetImageDimensions(pBitmap,W,H)
    If !(W && H)
        Return -2003
    If Gdip_LockBits(pBitmap,0,0,W,H,Stride,Scan,BitmapData)
        Return -2004
    ; The following code should be slower than using the MCode approach,
    ; but will the kept here for now, just for reference.
    /*
    Count := 0
    Loop, %H% {
        Y := A_Index-1
        Loop, %W% {
            X := A_Index-1
            CurrentColor := Gdip_GetLockBitPixel(Scan,X,Y,Stride)
            If ( (CurrentColor & 0xFFFFFF) == TransColor )
                Gdip_SetLockBitPixel(TransColor,Scan,X,Y,Stride), Count++
        }
    }
    */
    ; Thanks guest3456 for helping with the initial solution involving NumPut
    Gdip_FromARGB(TransColor,A,R,G,B), VarSetCapacity(TransColor,0), VarSetCapacity(TransColor,3,255)
    NumPut(B,TransColor,0,"UChar"), NumPut(G,TransColor,1,"UChar"), NumPut(R,TransColor,2,"UChar")
    MCount := 0
    E := DllCall(&_SetBmpTrans, Ptr,Scan, "int",W, "int",H, "int",Stride, Ptr,&TransColor, "int*",MCount, "cdecl int")
    Gdip_UnlockBits(pBitmap,BitmapData)
    If ( E != 0 ) {
        ErrorLevel := E
        Return -2005
    }
    Return MCount
}

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

;**********************************************************************************
;
; Gdip_MultiLockedBitsSearch()
; by MasterFocus - 24/MARCH/2013 06:20h BRT
; Requires GDIP and Gdip_LockedBitsSearch()
; http://www.autohotkey.com/board/topic/71100-gdip-imagesearch/
;
; Licensed under CC BY-SA 3.0 -> http://creativecommons.org/licenses/by-sa/3.0/
; I waive compliance with the "Share Alike" condition of the license EXCLUSIVELY
; for these users: tic , Rseding91 , guest3456
;
;**********************************************************************************

;==================================================================================
;
; This function returns the number of instances found
; The 8 first parameters are the same as in Gdip_LockedBitsSearch()
; The other 10 parameters are the same as in Gdip_ImageSearch()
; Note: the default for the Intances parameter here is 0 (find all matches)
;
;==================================================================================

Gdip_MultiLockedBitsSearch(hStride,hScan,hWidth,hHeight,nStride,nScan,nWidth,nHeight
,ByRef OutputList="",OuterX1=0,OuterY1=0,OuterX2=0,OuterY2=0,Variation=0
,SearchDirection=1,Instances=0,LineDelim="`n",CoordDelim=",")
{
    OutputList := ""
    OutputCount := !Instances
    InnerX1 := OuterX1 , InnerY1 := OuterY1
    InnerX2 := OuterX2 , InnerY2 := OuterY2

    ; The following part is a rather ugly but working hack that I
    ; came up with to adjust the variables and their increments
    ; according to the specified Haystack Search Direction
    /*
    Mod(SD,4) = 0 --> iX = 2 , stepX = +0 , iY = 1 , stepY = +1
    Mod(SD,4) = 1 --> iX = 1 , stepX = +1 , iY = 1 , stepY = +1
    Mod(SD,4) = 2 --> iX = 1 , stepX = +1 , iY = 2 , stepY = +0
    Mod(SD,4) = 3 --> iX = 2 , stepX = +0 , iY = 2 , stepY = +0
    SD <= 4   ------> Vertical preference
    SD > 4    ------> Horizontal preference
    */
    ; Set the index and the step (for both X and Y) to +1
    iX := 1, stepX := 1, iY := 1, stepY := 1
    ; Adjust Y variables if SD is 2, 3, 6 or 7
    Modulo := Mod(SearchDirection,4)
    If ( Modulo > 1 )
        iY := 2, stepY := 0
    ; adjust X variables if SD is 3, 4, 7 or 8
    If !Mod(Modulo,3)
        iX := 2, stepX := 0
    ; Set default Preference to vertical and Nonpreference to horizontal
    P := "Y", N := "X"
    ; adjust Preference and Nonpreference if SD is 5, 6, 7 or 8
    If ( SearchDirection > 4 )
        P := "X", N := "Y"
    ; Set the Preference Index and the Nonpreference Index
    iP := i%P%, iN := i%N%

    While (!(OutputCount == Instances) && (0 == Gdip_LockedBitsSearch(hStride,hScan,hWidth,hHeight,nStride
    ,nScan,nWidth,nHeight,FoundX,FoundY,OuterX1,OuterY1,OuterX2,OuterY2,Variation,SearchDirection)))
    {
        OutputCount++
        OutputList .= LineDelim FoundX CoordDelim FoundY
        Outer%P%%iP% := Found%P%+step%P%
        Inner%N%%iN% := Found%N%+step%N%
        Inner%P%1 := Found%P%
        Inner%P%2 := Found%P%+1
        While (!(OutputCount == Instances) && (0 == Gdip_LockedBitsSearch(hStride,hScan,hWidth,hHeight,nStride
        ,nScan,nWidth,nHeight,FoundX,FoundY,InnerX1,InnerY1,InnerX2,InnerY2,Variation,SearchDirection)))
        {
            OutputCount++
            OutputList .= LineDelim FoundX CoordDelim FoundY
            Inner%N%%iN% := Found%N%+step%N%
        }
    }
    OutputList := SubStr(OutputList,1+StrLen(LineDelim))
    OutputCount -= !Instances
    Return OutputCount
}

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

;**********************************************************************************
;
; Gdip_LockedBitsSearch()
; by MasterFocus - 24/MARCH/2013 06:20h BRT
; Mostly adapted from previous work by tic and Rseding91
;
; Requires GDIP
; http://www.autohotkey.com/board/topic/71100-gdip-imagesearch/
;
; Licensed under CC BY-SA 3.0 -> http://creativecommons.org/licenses/by-sa/3.0/
; I waive compliance with the "Share Alike" condition of the license EXCLUSIVELY
; for these users: tic , Rseding91 , guest3456
;
;**********************************************************************************

;==================================================================================
;
; This function searches for a single match of nScan within hScan
;
; ++ PARAMETERS ++
;
; hStride, hScan, hWidth and hHeight
;   Haystack stuff, extracted from a BitmapData, extracted from a Bitmap
;
; nStride, nScan, nWidth and nHeight
;   Needle stuff, extracted from a BitmapData, extracted from a Bitmap
;
; x and y
;   ByRef variables to store the X and Y coordinates of the image if it's found
;   Default: "" for both
;
; sx1, sy1, sx2 and sy2
;   These can be used to crop the search area within the haystack
;   Default: "" for all (does not crop)
;
; Variation
;   Same as the builtin ImageSearch command
;   Default: 0
;
; sd
;   Haystack search direction
;     Vertical preference:
;       1 = top->left->right->bottom [default]
;       2 = bottom->left->right->top
;       3 = bottom->right->left->top
;       4 = top->right->left->bottom
;     Horizontal preference:
;       5 = left->top->bottom->right
;       6 = left->bottom->top->right
;       7 = right->bottom->top->left
;       8 = right->top->bottom->left
;   This value is passed to the internal MCoded function
;
; ++ RETURN VALUES ++
;
; -3001 to -3006 ==> search area incorrectly defined
; -3007 ==> DllCall returned blank
; 0 ==> DllCall succeeded and a match was found
; -4001 ==> DllCall succeeded but a match was not found
; anything else ==> the error value returned by the unsuccessful DllCall
;
;==================================================================================

Gdip_LockedBitsSearch(hStride,hScan,hWidth,hHeight,nStride,nScan,nWidth,nHeight
,ByRef x="",ByRef y="",sx1=0,sy1=0,sx2=0,sy2=0,Variation=0,sd=1)
{
    static _ImageSearch, Ptr, PtrA

    ; Initialize all MCode stuff, if necessary
    if !( _ImageSearch ) {
        Ptr := A_PtrSize ? "UPtr" : "UInt"
        PtrA := Ptr . "*"

        MCode_ImageSearch := "
            (LTrim Join
            8b44243883ec205355565783f8010f857a0100008b7c2458897c24143b7c24600f8db50b00008b44244c8b5c245c8b
            4c24448b7424548be80fafef896c242490897424683bf30f8d0a0100008d64240033c033db8bf5896c241c895c2420894424
            183b4424480f8d0401000033c08944241085c90f8e9d0000008b5424688b7c24408beb8d34968b54246403df8d4900b80300
            0000803c18008b442410745e8b44243c0fb67c2f020fb64c06028d04113bf87f792bca3bf97c738b44243c0fb64c06018b44
            24400fb67c28018d04113bf87f5a2bca3bf97c548b44243c0fb63b0fb60c068d04113bf87f422bca3bf97c3c8b4424108b7c
            24408b4c24444083c50483c30483c604894424103bc17c818b5c24208b74241c0374244c8b44241840035c24508974241ce9
            2dffffff8b6c24688b5c245c8b4c244445896c24683beb8b6c24240f8c06ffffff8b44244c8b7c24148b7424544703e8897c
            2414896c24243b7c24600f8cd5feffffe96b0a00008b4424348b4c246889088b4424388b4c24145f5e5d890833c05b83c420
            c383f8020f85870100008b7c24604f897c24103b7c24580f8c310a00008b44244c8b5c245c8b4c24448bef0fafe8f7d88944
            24188b4424548b742418896c24288d4900894424683bc30f8d0a0100008d64240033c033db8bf5896c2420895c241c894424
            243b4424480f8d0401000033c08944241485c90f8e9d0000008b5424688b7c24408beb8d34968b54246403df8d4900b80300
            0000803c03008b442414745e8b44243c0fb67c2f020fb64c06028d04113bf87f792bca3bf97c738b44243c0fb64c06018b44
            24400fb67c28018d04113bf87f5a2bca3bf97c548b44243c0fb63b0fb60c068d04113bf87f422bca3bf97c3c8b4424148b7c
            24408b4c24444083c50483c30483c604894424143bc17c818b5c241c8b7424200374244c8b44242440035c245089742420e9
            2dffffff8b6c24688b5c245c8b4c244445896c24683beb8b6c24280f8c06ffffff8b7c24108b4424548b7424184f03ee897c
            2410896c24283b7c24580f8dd5feffffe9db0800008b4424348b4c246889088b4424388b4c24105f5e5d890833c05b83c420
            c383f8030f85650100008b7c24604f897c24103b7c24580f8ca10800008b44244c8b6c245c8b5c24548b4c24448bf70faff0
            4df7d8896c242c897424188944241c8bff896c24683beb0f8c020100008d64240033c033db89742424895c2420894424283b
            4424480f8d76ffffff33c08944241485c90f8e9f0000008b5424688b7c24408beb8d34968b54246403dfeb038d4900b80300
            0000803c03008b442414745e8b44243c0fb67c2f020fb64c06028d04113bf87f752bca3bf97c6f8b44243c0fb64c06018b44
            24400fb67c28018d04113bf87f562bca3bf97c508b44243c0fb63b0fb60c068d04113bf87f3e2bca3bf97c388b4424148b7c
            24408b4c24444083c50483c30483c604894424143bc17c818b5c24208b7424248b4424280374244c40035c2450e92bffffff
            8b6c24688b5c24548b4c24448b7424184d896c24683beb0f8d0affffff8b7c24108b44241c4f03f0897c2410897424183b7c
            24580f8c580700008b6c242ce9d4feffff83f8040f85670100008b7c2458897c24103b7c24600f8d340700008b44244c8b6c
            245c8b5c24548b4c24444d8bf00faff7896c242c8974241ceb098da424000000008bff896c24683beb0f8c020100008d6424
            0033c033db89742424895c2420894424283b4424480f8d06feffff33c08944241485c90f8e9f0000008b5424688b7c24408b
            eb8d34968b54246403dfeb038d4900b803000000803c03008b442414745e8b44243c0fb67c2f020fb64c06028d04113bf87f
            752bca3bf97c6f8b44243c0fb64c06018b4424400fb67c28018d04113bf87f562bca3bf97c508b44243c0fb63b0fb60c068d
            04113bf87f3e2bca3bf97c388b4424148b7c24408b4c24444083c50483c30483c604894424143bc17c818b5c24208b742424
            8b4424280374244c40035c2450e92bffffff8b6c24688b5c24548b4c24448b74241c4d896c24683beb0f8d0affffff8b4424
            4c8b7c24104703f0897c24108974241c3b7c24600f8de80500008b6c242ce9d4feffff83f8050f85890100008b7c2454897c
            24683b7c245c0f8dc40500008b5c24608b6c24588b44244c8b4c2444eb078da42400000000896c24103beb0f8d200100008b
            e80faf6c2458896c241c33c033db8bf5896c2424895c2420894424283b4424480f8d0d01000033c08944241485c90f8ea600
            00008b5424688b7c24408beb8d34968b54246403dfeb0a8da424000000008d4900b803000000803c03008b442414745e8b44
            243c0fb67c2f020fb64c06028d04113bf87f792bca3bf97c738b44243c0fb64c06018b4424400fb67c28018d04113bf87f5a
            2bca3bf97c548b44243c0fb63b0fb60c068d04113bf87f422bca3bf97c3c8b4424148b7c24408b4c24444083c50483c30483
            c604894424143bc17c818b5c24208b7424240374244c8b44242840035c245089742424e924ffffff8b7c24108b6c241c8b44
            244c8b5c24608b4c24444703e8897c2410896c241c3bfb0f8cf3feffff8b7c24688b6c245847897c24683b7c245c0f8cc5fe
            ffffe96b0400008b4424348b4c24688b74241089088b4424385f89305e5d33c05b83c420c383f8060f85670100008b7c2454
            897c24683b7c245c0f8d320400008b6c24608b5c24588b44244c8b4c24444d896c24188bff896c24103beb0f8c1a0100008b
            f50faff0f7d88974241c8944242ceb038d490033c033db89742424895c2420894424283b4424480f8d06fbffff33c0894424
            1485c90f8e9f0000008b5424688b7c24408beb8d34968b54246403dfeb038d4900b803000000803c03008b442414745e8b44
            243c0fb67c2f020fb64c06028d04113bf87f752bca3bf97c6f8b44243c0fb64c06018b4424400fb67c28018d04113bf87f56
            2bca3bf97c508b44243c0fb63b0fb60c068d04113bf87f3e2bca3bf97c388b4424148b7c24408b4c24444083c50483c30483
            c604894424143bc17c818b5c24208b7424248b4424280374244c40035c2450e92bffffff8b6c24108b74241c0374242c8b5c
            24588b4c24444d896c24108974241c3beb0f8d02ffffff8b44244c8b7c246847897c24683b7c245c0f8de60200008b6c2418
            e9c2feffff83f8070f85670100008b7c245c4f897c24683b7c24540f8cc10200008b6c24608b5c24588b44244c8b4c24444d
            896c241890896c24103beb0f8c1a0100008bf50faff0f7d88974241c8944242ceb038d490033c033db89742424895c242089
            4424283b4424480f8d96f9ffff33c08944241485c90f8e9f0000008b5424688b7c24408beb8d34968b54246403dfeb038d49
            00b803000000803c18008b442414745e8b44243c0fb67c2f020fb64c06028d04113bf87f752bca3bf97c6f8b44243c0fb64c
            06018b4424400fb67c28018d04113bf87f562bca3bf97c508b44243c0fb63b0fb60c068d04113bf87f3e2bca3bf97c388b44
            24148b7c24408b4c24444083c50483c30483c604894424143bc17c818b5c24208b7424248b4424280374244c40035c2450e9
            2bffffff8b6c24108b74241c0374242c8b5c24588b4c24444d896c24108974241c3beb0f8d02ffffff8b44244c8b7c24684f
            897c24683b7c24540f8c760100008b6c2418e9c2feffff83f8080f85640100008b7c245c4f897c24683b7c24540f8c510100
            008b5c24608b6c24588b44244c8b4c24448d9b00000000896c24103beb0f8d200100008be80faf6c2458896c241c33c033db
            8bf5896c2424895c2420894424283b4424480f8d9dfcffff33c08944241485c90f8ea60000008b5424688b7c24408beb8d34
            968b54246403dfeb0a8da424000000008d4900b803000000803c03008b442414745e8b44243c0fb67c2f020fb64c06028d04
            113bf87f792bca3bf97c738b44243c0fb64c06018b4424400fb67c28018d04113bf87f5a2bca3bf97c548b44243c0fb63b0f
            b604068d0c103bf97f422bc23bf87c3c8b4424148b7c24408b4c24444083c50483c30483c604894424143bc17c818b5c2420
            8b7424240374244c8b44242840035c245089742424e924ffffff8b7c24108b6c241c8b44244c8b5c24608b4c24444703e889
            7c2410896c241c3bfb0f8cf3feffff8b7c24688b6c24584f897c24683b7c24540f8dc5feffff8b4424345fc700ffffffff8b
            4424345e5dc700ffffffffb85ff0ffff5b83c420c3,4c894c24204c89442418488954241048894c24085355565741544
            155415641574883ec188b8424c80000004d8bd94d8bd0488bda83f8010f85b3010000448b8c24a800000044890c24443b8c2
            4b80000000f8d66010000448bac24900000008b9424c0000000448b8424b00000008bbc2480000000448b9424a0000000418
            bcd410fafc9894c24040f1f84000000000044899424c8000000453bd00f8dfb000000468d2495000000000f1f80000000003
            3ed448bf933f6660f1f8400000000003bac24880000000f8d1701000033db85ff7e7e458bf4448bce442bf64503f7904d63c
            14d03c34180780300745a450fb65002438d040e4c63d84c035c2470410fb64b028d0411443bd07f572bca443bd17c50410fb
            64b01450fb650018d0411443bd07f3e2bca443bd17c37410fb60b450fb6108d0411443bd07f272bca443bd17c204c8b5c247
            8ffc34183c1043bdf7c8fffc54503fd03b42498000000e95effffff8b8424c8000000448b8424b00000008b4c24044c8b5c2
            478ffc04183c404898424c8000000413bc00f8c20ffffff448b0c24448b9424a000000041ffc14103cd44890c24894c24044
            43b8c24b80000000f8cd8feffff488b5c2468488b4c2460b85ff0ffffc701ffffffffc703ffffffff4883c418415f415e415
            d415c5f5e5d5bc38b8424c8000000e9860b000083f8020f858c010000448b8c24b800000041ffc944890c24443b8c24a8000
            0007cab448bac2490000000448b8424c00000008b9424b00000008bbc2480000000448b9424a0000000418bc9410fafcd418
            bc5894c2404f7d8894424080f1f400044899424c8000000443bd20f8d02010000468d2495000000000f1f80000000004533f
            6448bf933f60f1f840000000000443bb424880000000f8d56ffffff33db85ff0f8e81000000418bec448bd62bee4103ef496
            3d24903d3807a03007460440fb64a02418d042a4c63d84c035c2470410fb64b02428d0401443bc87f5d412bc8443bc97c554
            10fb64b01440fb64a01428d0401443bc87f42412bc8443bc97c3a410fb60b440fb60a428d0401443bc87f29412bc8443bc97
            c214c8b5c2478ffc34183c2043bdf7c8a41ffc64503fd03b42498000000e955ffffff8b8424c80000008b9424b00000008b4
            c24044c8b5c2478ffc04183c404898424c80000003bc20f8c19ffffff448b0c24448b9424a0000000034c240841ffc9894c2
            40444890c24443b8c24a80000000f8dd0feffffe933feffff83f8030f85c4010000448b8c24b800000041ffc944898c24c80
            00000443b8c24a80000000f8c0efeffff8b842490000000448b9c24b0000000448b8424c00000008bbc248000000041ffcb4
            18bc98bd044895c24080fafc8f7da890c24895424048b9424a0000000448b542404458beb443bda0f8c13010000468d249d0
            000000066660f1f84000000000033ed448bf933f6660f1f8400000000003bac24880000000f8d0801000033db85ff0f8e960
            00000488b4c2478458bf4448bd6442bf64503f70f1f8400000000004963d24803d1807a03007460440fb64a02438d04164c6
            3d84c035c2470410fb64b02428d0401443bc87f63412bc8443bc97c5b410fb64b01440fb64a01428d0401443bc87f48412bc
            8443bc97c40410fb60b440fb60a428d0401443bc87f2f412bc8443bc97c27488b4c2478ffc34183c2043bdf7c8a8b8424900
            00000ffc54403f803b42498000000e942ffffff8b9424a00000008b8424900000008b0c2441ffcd4183ec04443bea0f8d11f
            fffff448b8c24c8000000448b542404448b5c240841ffc94103ca44898c24c8000000890c24443b8c24a80000000f8dc2fef
            fffe983fcffff488b4c24608b8424c8000000448929488b4c2468890133c0e981fcffff83f8040f857f010000448b8c24a80
            0000044890c24443b8c24b80000000f8d48fcffff448bac2490000000448b9424b00000008b9424c0000000448b8424a0000
            0008bbc248000000041ffca418bcd4489542408410fafc9894c2404669044899424c8000000453bd00f8cf8000000468d249
            5000000000f1f800000000033ed448bf933f6660f1f8400000000003bac24880000000f8df7fbffff33db85ff7e7e458bf44
            48bce442bf64503f7904d63c14d03c34180780300745a450fb65002438d040e4c63d84c035c2470410fb64b028d0411443bd
            07f572bca443bd17c50410fb64b01450fb650018d0411443bd07f3e2bca443bd17c37410fb60b450fb6108d0411443bd07f2
            72bca443bd17c204c8b5c2478ffc34183c1043bdf7c8fffc54503fd03b42498000000e95effffff8b8424c8000000448b842
            4a00000008b4c24044c8b5c2478ffc84183ec04898424c8000000413bc00f8d20ffffff448b0c24448b54240841ffc14103c
            d44890c24894c2404443b8c24b80000000f8cdbfeffffe9defaffff83f8050f85ab010000448b8424a000000044890424443
            b8424b00000000f8dc0faffff8b9424c0000000448bac2498000000448ba424900000008bbc2480000000448b8c24a800000
            0428d0c8500000000898c24c800000044894c2404443b8c24b80000000f8d09010000418bc4410fafc18944240833ed448bf
            833f6660f1f8400000000003bac24880000000f8d0501000033db85ff0f8e87000000448bf1448bce442bf64503f74d63c14
            d03c34180780300745d438d040e4c63d84d03da450fb65002410fb64b028d0411443bd07f5f2bca443bd17c58410fb64b014
            50fb650018d0411443bd07f462bca443bd17c3f410fb60b450fb6108d0411443bd07f2f2bca443bd17c284c8b5c24784c8b5
            42470ffc34183c1043bdf7c8c8b8c24c8000000ffc54503fc4103f5e955ffffff448b4424048b4424088b8c24c80000004c8
            b5c24784c8b54247041ffc04103c4448944240489442408443b8424b80000000f8c0effffff448b0424448b8c24a80000004
            1ffc083c10444890424898c24c8000000443b8424b00000000f8cc5feffffe946f9ffff488b4c24608b042489018b4424044
            88b4c2468890133c0e945f9ffff83f8060f85aa010000448b8c24a000000044894c2404443b8c24b00000000f8d0bf9ffff8
            b8424b8000000448b8424c0000000448ba424900000008bbc2480000000428d0c8d00000000ffc88944240c898c24c800000
            06666660f1f840000000000448be83b8424a80000000f8c02010000410fafc4418bd4f7da891424894424084533f6448bf83
            3f60f1f840000000000443bb424880000000f8df900000033db85ff0f8e870000008be9448bd62bee4103ef4963d24903d38
            07a03007460440fb64a02418d042a4c63d84c035c2470410fb64b02428d0401443bc87f64412bc8443bc97c5c410fb64b014
            40fb64a01428d0401443bc87f49412bc8443bc97c41410fb60b440fb60a428d0401443bc87f30412bc8443bc97c284c8b5c2
            478ffc34183c2043bdf7c8a8b8c24c800000041ffc64503fc03b42498000000e94fffffff8b4424088b8c24c80000004c8b5
            c247803042441ffcd89442408443bac24a80000000f8d17ffffff448b4c24048b44240c41ffc183c10444894c2404898c24c
            8000000443b8c24b00000000f8ccefeffffe991f7ffff488b4c24608b4424048901488b4c246833c0448929e992f7ffff83f
            8070f858d010000448b8c24b000000041ffc944894c2404443b8c24a00000000f8c55f7ffff8b8424b8000000448b8424c00
            00000448ba424900000008bbc2480000000428d0c8d00000000ffc8890424898c24c8000000660f1f440000448be83b8424a
            80000000f8c02010000410fafc4418bd4f7da8954240c8944240833ed448bf833f60f1f8400000000003bac24880000000f8
            d4affffff33db85ff0f8e89000000448bf1448bd6442bf64503f74963d24903d3807a03007460440fb64a02438d04164c63d
            84c035c2470410fb64b02428d0401443bc87f63412bc8443bc97c5b410fb64b01440fb64a01428d0401443bc87f48412bc84
            43bc97c40410fb60b440fb60a428d0401443bc87f2f412bc8443bc97c274c8b5c2478ffc34183c2043bdf7c8a8b8c24c8000
            000ffc54503fc03b42498000000e94fffffff8b4424088b8c24c80000004c8b5c24780344240c41ffcd89442408443bac24a
            80000000f8d17ffffff448b4c24048b042441ffc983e90444894c2404898c24c8000000443b8c24a00000000f8dcefeffffe
            9e1f5ffff83f8080f85ddf5ffff448b8424b000000041ffc84489442404443b8424a00000000f8cbff5ffff8b9424c000000
            0448bac2498000000448ba424900000008bbc2480000000448b8c24a8000000428d0c8500000000898c24c800000044890c2
            4443b8c24b80000000f8d08010000418bc4410fafc18944240833ed448bf833f6660f1f8400000000003bac24880000000f8
            d0501000033db85ff0f8e87000000448bf1448bce442bf64503f74d63c14d03c34180780300745d438d040e4c63d84d03da4
            50fb65002410fb64b028d0411443bd07f5f2bca443bd17c58410fb64b01450fb650018d0411443bd07f462bca443bd17c3f4
            10fb603450fb6108d0c10443bd17f2f2bc2443bd07c284c8b5c24784c8b542470ffc34183c1043bdf7c8c8b8c24c8000000f
            fc54503fc4103f5e955ffffff448b04248b4424088b8c24c80000004c8b5c24784c8b54247041ffc04103c44489042489442
            408443b8424b80000000f8c10ffffff448b442404448b8c24a800000041ffc883e9044489442404898c24c8000000443b842
            4a00000000f8dc6feffffe946f4ffff8b442404488b4c246089018b0424488b4c2468890133c0e945f4ffff
            )"
        if ( A_PtrSize == 8 ) ; x64, after comma
            MCode_ImageSearch := SubStr(MCode_ImageSearch,InStr(MCode_ImageSearch,",")+1)
        else ; x86, before comma
            MCode_ImageSearch := SubStr(MCode_ImageSearch,1,InStr(MCode_ImageSearch,",")-1)
        VarSetCapacity(_ImageSearch, LEN := StrLen(MCode_ImageSearch)//2, 0)
        Loop, %LEN%
            NumPut("0x" . SubStr(MCode_ImageSearch,(2*A_Index)-1,2), _ImageSearch, A_Index-1, "uchar")
        MCode_ImageSearch := ""
        DllCall("VirtualProtect", Ptr,&_ImageSearch, Ptr,VarSetCapacity(_ImageSearch), "uint",0x40, PtrA,0)
    }

    ; Abort if an initial coordinates is located before a final coordinate
    If ( sx2 < sx1 )
        return -3001
    If ( sy2 < sy1 )
        return -3002

    ; Check the search box. "sx2,sy2" will be the last pixel evaluated
    ; as possibly matching with the needle's first pixel. So, we must
    ; avoid going beyond this maximum final coordinate.
    If ( sx2 > (hWidth-nWidth+1) )
        return -3003
    If ( sy2 > (hHeight-nHeight+1) )
        return -3004

    ; Abort if the width or height of the search box is 0
    If ( sx2-sx1 == 0 )
        return -3005
    If ( sy2-sy1 == 0 )
        return -3006

    ; The DllCall parameters are the same for easier C code modification,
    ; even though they aren't all used on the _ImageSearch version
    x := 0, y := 0
    , E := DllCall( &_ImageSearch, "int*",x, "int*",y, Ptr,hScan, Ptr,nScan, "int",nWidth, "int",nHeight
    , "int",hStride, "int",nStride, "int",sx1, "int",sy1, "int",sx2, "int",sy2, "int",Variation
    , "int",sd, "cdecl int")
    Return ( E == "" ? -3007 : E )
}