#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "LLK_Rightclick")
;OnMessage(0x0202, "LLK_Leftclick")
;OnMessage(0x0201, "LLK_Leftclick")
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

startup := A_TickCount
While !WinExist("ahk_group poe_window")
{
	If (A_TickCount >= startup + 60000)
		ExitApp
	sleep, 5000
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

global hwnd_archnemesis_window, all_nemesis, trans := 220, guilist, xWindow, xWindow1, fSize0, fSize1, Burn_number, reverse := 0, click := 1, sorting_order := "descending", sorting := "quantity"
global archnemesis := 0, archnemesis1_x, archnemesis1_y, archnemesis1_color, archnemesis2_x, archnemesis2_y, archnemesis2_color, archnemesis_inventory, arch_inventory := [], pixelsearch_variation

IniRead, all_nemesis, ini\db_archnemesis.ini,
Loop, Parse, all_nemesis, `n,`n
{
	all_nemesis_inverted := (A_Index = 1) ? A_LoopField "," : A_LoopField "," all_nemesis_inverted
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (read != "") && (read != "ERROR")
		global arch_recipes := (arch_recipes = "") ? A_LoopField "," : A_LoopField "," arch_recipes
	If (read = "") || (read = "ERROR")
		global arch_bases := (arch_bases = "") ? A_LoopField "," : A_LoopField "," arch_bases
}
Sort, all_nemesis, C D`n

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
IniRead, pause_list, ini\config.ini, Settings, pause-list
global pause_list := (pause_list = "ERROR") ? "" : pause_list
IniRead, Burn_number, ini\config.ini, Settings, Burn-number
If (Burn_number = "" || Burn_number = "ERROR")
	Burn_number := 10
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

SetTimer, Loop, 1000

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
Return

Archnemesis:
LLK_Recipes(A_GuiControl, 1)
Return

Archnemesis2:
param := InStr(A_GuiControl, "x ") ? SubStr(A_GuiControl, InStr(A_GuiControl, "x ")+2) : A_GuiControl
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
Gui, archnemesis_list: Margin, 6, 2
Gui, archnemesis_list: Color, Black
WinSet, Transparent, %trans%
Gui, archnemesis_list: Font, s%fSize0% cWhite underline, Fontin SmallCaps
no_letter := 1
section := 0
Loop, Parse, all_nemesis, `n, `n
{
	color := InStr(favorite_recipes, A_LoopField) ? "Yellow" : "White"
	If (SubStr(A_LoopField, 1, 1) = A_GuiControl)
	{
		Gui, archnemesis_list: Font, s%fSize0% underline
		If (section = 0)
		{
			Gui, archnemesis_list: Add, Text, c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
			section := 1
		}
		Else	Gui, archnemesis_list: Add, Text, xs c%color% Section HWNDmain_text gFavored_recipes, % A_LoopField
		IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
		IniRead, modifiers, ini\db_archnemesis.ini, %A_LoopField%, modifiers
		ControlGetPos,, ypos,, height,, ahk_id %main_text%
		Loop, Parse, rewards, `,,`,
			Gui, archnemesis_list: Add, Picture, ys BackgroundTrans h%height% w-1 y%ypos%, img\Rewards\%A_LoopField%.png
		Gui, archnemesis_list: Font, norm s%fSize1%
		If (modifiers != "ERROR") && (modifiers != "")
			Gui, archnemesis_list: Add, Text, cSilver xs+20 BackgroundTrans, % modifiers
		no_letter := 0
	}
}
If (no_letter=0)
{
	MouseGetPos, mouseX, mouseY
	Gui, archnemesis_list: Show, Hide
	WinGetPos,,,, height
	Gui, archnemesis_list: Show, % "NA x"mouseX-30 " y"yLetters-10-height
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
	/*
Gui, base_info: Show, Hide
WinGetPos,,, width
MouseGetPos, outX
Gui, base_info: Show, % "Hide x"outX-width//2 " y"yScreenOffset
WinGetPos, outxx,
If (outxx < xScreenOffset)
	Gui, base_info: Show, % "NA x"xScreenOffset " y"yScreenOffset
Else	
*/
Gui, base_info: Show, % "NA x"xScreenOffset+poe_width//2 " y"yScreenOffset
WinActivate, ahk_group poe_window
Return

Base_lootGuiClose:
LLK_Overlay("base_loot", 2)
base_loot_toggle := 0
Return

Burn_all:
search_term := ""
unwanted_mods_quant0 := unwanted_mods_quant
Sort, unwanted_mods_quant, D`, N R
Loop, Parse, unwanted_mods_quant, `,,`,
{
	If (A_LoopField = "")
		break
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
IniWrite, %favorite_recipes%, ini\config.ini, Settings, favorite recipes
IniWrite, %pause_list%, ini\config.ini, Settings, pause-list
IniWrite, %Burn_number%, ini\config.ini, Settings, Burn-number
If (archnemesis_inventory != "")
	IniWrite, %archnemesis_inventory%, ini\config.ini, Archnemesis, inventory
ExitApp
Return

GUI:
Gui, archnemesis_letters: -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
global hwnd_archnemesis_letters := WinExist(), guilist := "archnemesis_letters"
guilist := guilist "|base_loot"
guilist := guilist "|archnemesis_list"
guilist := guilist "|archnemesis_window"
;guilist := guilist "|favored_recipes"
guilist := guilist "|surplus_view"
Gui, archnemesis_letters: Margin, 0, 2
Gui, archnemesis_letters: Color, Black
WinSet, Transparent, %trans%
Gui, archnemesis_letters: Font, s%fSize0% cWhite, Fontin SmallCaps
letter := ""
Gui, archnemesis_letters: Add, Text, x0 Center BackgroundTrans, % "    "
Loop, Parse, all_nemesis, `n, `n
{
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (letter != SubStr(A_LoopField, 1, 1)) ; && (read != "ERROR")
	{
		If (SubStr(A_LoopField, 1, 1) = "a")	
			Gui, archnemesis_letters: Add, Text, x6 y2 wp Section gArchnemesis_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		Else	Gui, archnemesis_letters: Add, Text, ys x+2 wp gArchnemesis_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		letter := SubStr(A_LoopField, 1, 1)
	}
}
Gui, archnemesis_letters: Add, Text, ys x+6 Center gFont_offset Border, % " – "
Gui, archnemesis_letters: Add, Text, ys x+2 wp Section Center gFont_offset Border, % "+"
Gui, archnemesis_letters: Add, Text, Center ys x+6 gScan Border, % " scan "
Gui, archnemesis_letters: Margin, 6, 2
Gui, archnemesis_letters: Show, Hide
WinGetPos,,, guiwidth,
Gui, archnemesis_letters: Show, % "Hide x" xScreenOffset+((xWindow-xScreenOffset)*0.96)//2-guiwidth//2 " y"yLetters
WinGetPos, outx
If (outx < xScreenOffset)
	Gui, archnemesis_letters: Show, % "Hide x" xScreenOffset " y"yLetters
Return

Help:
Gui, help_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, help_panel: Margin, 6, 4
Gui, help_panel: Color, Black
WinSet, Transparent, %trans%
Gui, help_panel: Font, s%fSize1% cWhite underline, Fontin SmallCaps
Gui, help_panel: Add, Text, Section BackgroundTrans, clear list:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-r-click on "prio-list"
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, view prio-surplus:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, click "prio-list"
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, remove recipe:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-r-click on recipe
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, pause recipe:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click on recipe
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, tree-view:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, long-click recipe
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, map search:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, click "missing"
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, bases cheat sheet:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click "missing"
Gui, help_panel: Font, underline
Gui, help_panel: Add, Text, xs Section BackgroundTrans, open image folder:
Gui, help_panel: Font, norm
Gui, help_panel: Add, Text, ys BackgroundTrans, r-click "scan"
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
			GoSub, Favored_recipes
			KeyWait, RButton
			Return
		}
	}
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

Loop:
If !WinExist("ahk_group poe_window")
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
		/*
		MouseGetPos, mouseXpos, mouseYpos
		If (invBox1 < mouseXpos && mouseXpos < invBox2 && invbox3 < mouseYpos && mouseYpos < invBox4)
			LLK_Overlay("favored_recipes", 2)
		If !WinExist("ahk_id " hwnd_favored_recipes) && (hwnd_favored_recipes != "") && (favorite_recipes != "")
			If !(invBox1 < mouseXpos && mouseXpos < invBox2 && invBox3 < mouseYpos && mouseYpos < invBox4)
				LLK_Overlay("favored_recipes", 1)
		*/
		If !WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 1)
		If !WinExist("ahk_id " hwnd_archnemesis_window) && (hwnd_archnemesis_window != "")
			LLK_Overlay("archnemesis_window", 1)
		If !WinExist("ahk_id " hwnd_surplus_view) && (hwnd_surplus_view != "")
			LLK_Overlay("surplus_view", 1)
	}
	If (archnemesis = 0)
	{
		If WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 2)
		If WinExist("ahk_id " hwnd_archnemesis_list)
			LLK_Overlay("archnemesis_list", 2)
		If WinExist("ahk_id " hwnd_archnemesis_window)
			LLK_Overlay("archnemesis_window", 2)
		;If WinExist("ahk_id " hwnd_favored_recipes)
		;	LLK_Overlay("favored_recipes", 2)
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
archnemesis_inventory := (archnemesis_inventory = "") ? recal_choice : archnemesis_inventory "," recal_choice
Return

Recalibrate_UI:
If InStr(A_GuiControl, "cancel")
{
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
Gui, archnemesis_list: Hide
If InStr(A_GuiControl, "prio")
{
	;Gui, favored_recipes: Destroy
	Gui, surplus_view: Destroy
	hwnd_surplus_view := ""
	favorite_recipes := ""
}
If !InStr(A_GuiControl, "prio") && GetKeyState("RButton", "P") || (A_Gui = "Archnemesis_list") ;(A_Gui != "archnemesis_window")
	favor_choice := InStr(A_GuiControl, "scan") ? "" : A_GuiControl
global hwnd_favored_recipes := ""
If (favor_choice != "")
{
	If InStr(favorite_recipes, favor_choice)
		favorite_recipes := StrReplace(favorite_recipes, favor_choice ",", "")
	Else favorite_recipes := (favorite_recipes = "") ? favor_choice "," : favorite_recipes favor_choice ","
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
	archnemesis_inventory_leftover := archnemesis_inventory
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
	/*
	Loop, Parse, archnemesis_inventory, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(prio_list_leftover, A_LoopField)
			prio_list_leftover := StrReplace(prio_list_leftover, A_LoopField ",", "",, 1)
	}
	*/
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
Gui, base_loot: Show, % style Center ;" x"xbase_loot " y"ybase_loot

favor_choice := ""
/*
Gui, favored_recipes: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, favored_recipes: Margin, 10, 2
Gui, favored_recipes: Color, Black
WinSet, Transparent, %trans%
Gui, favored_recipes: Font, s%fSize0% cWhite underline, Fontin SmallCaps
Gui, favored_recipes: Add, Text, cYellow BackgroundTrans Section HWNDmain_text Center gSurplus, prio:
ControlGetPos,,, width, height,, ahk_id %main_text%

Loop, Parse, not_base, `,,`,
{
	If (A_LoopField = "") || (favorite_recipes = "")
		break
	Gui, favored_recipes: Font, s%fSize0% underline
	color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
	Gui, favored_recipes: Add, Text, c%color% ys BackgroundTrans HWNDmain_text gRecipe_tree, % A_LoopField
	IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
	;ControlGetPos,, ypos,, height,, ahk_id %main_text%
	Gui, favored_recipes: Font, s%fSize0% norm
}
Gui, favored_recipes: Font, % "s"fSize1-2 "norm"
Gui, favored_recipes: Add, Button, gFavored_recipes w%width% h%height% xs Section, clr

Loop, Parse, is_base, `,,`,
{
	If (A_LoopField = "") || (favorite_recipes = "")
		break
	Gui, favored_recipes: Font, s%fSize0% underline
	color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
	Gui, favored_recipes: Add, Text, c%color% ys BackgroundTrans HWNDmain_text gBase_info, % A_LoopField
	IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
	ControlGetPos,, ypos,, height,, ahk_id %main_text%
	Gui, favored_recipes: Font, s%fSize0% norm
}

Gui, favored_recipes: Show, Hide x%xScreenOffset% y%yScreenOffset%
WinGetPos,,, width, height
global yTree := height + 10
hwnd_favored_recipes := WinExist()
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
*/
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
LLK_Recipes()
Return

Recipe_tree:
holdstart := A_TickCount
While GetKeyState("RButton", "P")
{
	If (A_TickCount >= holdstart + 250)
	{
		GoSub, Favored_recipes
		Return
	}
}
If (click = 2)
{
	GoSub, Pause_list
	Return
}
While GetKeyState("LButton", "P")
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
				Gui, recipe_tree: Add, Text, BackgroundTrans c%color% HWNDmain_text Section Center, % A_LoopField count
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
If InStr(archnemesis_inventory, A_GuiControl)
{
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	clipboard := "^"StrReplace(A_GuiControl, A_Space, ".")
	SendInput, ^{f}^{v}{Enter}
}
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
If (click = 2)
{
	If FileExist("img\Recognition\" poe_height "p\Archnemesis")
		Run, explore img\Recognition\%poe_height%p\Archnemesis
	Return
}
hwnd_archnemesis_window := ""
Gui, archnemesis_list: Destroy
hwnd_archnemesis_list := ""
Gui, surplus_view: Destroy
hwnd_surplus_view := ""
;KeyWait, LButton
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
SendInput, ^{f}{ESC}
sleep, 200
archnemesis_inventory := ""
xGrid := []
yGrid := []
progress := 0
MouseGetPos, outX
ToolTip, % "Don't move the cursor!`n" "Progress: " progress "/64", outX-60, yLetters+50, 17
Loop, Parse, xScan, `,,`,
	xGrid.Push(A_LoopField+xScreenOffset)
Loop, Parse, yScan, `,,`,
	yGrid.Push(A_LoopField+yScreenOffset)
Loop, % xGrid.Length()
{
	xArrow := xGrid[A_Index] + dBitMap//2
	xGridScan0 := xGrid[A_Index]
	xGridScan1 := xGrid[A_Index] + dBitMap - 1
	xBitMap := xGridScan0
	Loop, % yGrid.Length()
	{
		progress += 1
		comparison := 1
		MouseGetPos, outX
		ToolTip, % "Don't move the cursor!`n" "Progress: " progress "/64", outX-60, yLetters+50, 17
		yArrow := yGrid[A_Index]
		yGridScan0 := yGrid[A_Index]
		yGridScan1 := yGrid[A_Index] + dBitMap - 1
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
						ImageSearch, outX, outY, xGridScan0, yGridScan0, xGridScan1, yGridScan1, *25 %A_LoopFilePath%
						comparison := ErrorLevel
						If (ErrorLevel = 0)
							break
					}
				}
			}
			If (comparison != 0)
			{
				match := ""
				Loop, Files, img\Recognition\%poe_height%p\Archnemesis\*.png
				{
					ImageSearch, outX, outY, xGridScan0, yGridScan0, xGridScan1, yGridScan1, *25 %A_LoopFilePath%
					If (ErrorLevel = 0)
					{
						SplitPath, A_LoopFileName,,,, match,
						break
					}
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
			else	archnemesis_inventory := (archnemesis_inventory = "") ? match : archnemesis_inventory "," match
		}
	}
}
arch_inventory := []
Loop, Parse, archnemesis_inventory, `,,`,
	arch_inventory.Push(A_LoopField)
Gui, recal_arrow: Destroy
ToolTip,,,,17
GoSub, Favored_recipes
GoSub, Recipes
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
	;hwnd_archnemesis_window := ""
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
		sleep, 250
		SendInput, ^{f}^{v}{Enter}
		Return
	}
	Gui, archnemesis_window: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, archnemesis_window: Margin, 4, 0
	Gui, archnemesis_window: Color, Black
	WinSet, Transparent, %trans%
	Gui, archnemesis_window: Font, s%fSize0% norm cWhite, Fontin SmallCaps
	window_text := (prio_list != "") ? "prio-list:" : "ready:"
	
	If InStr(window_text, "prio")
	{
		Gui, archnemesis_window: Font, underline
		Gui, archnemesis_window: Add, Text, x12 cYellow BackgroundTrans Section gSurplus, %window_text%
		Gui, archnemesis_window: Font, norm
	}
	Else	Gui, archnemesis_window: Add, Text, x12 cYellow BackgroundTrans Section, %window_text%
		
	If (prio_list != "")
	{
		If (list_remaining_count = 1)
			Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys x+6, % list_remaining_count " base"
		Else	Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys x+6, % list_remaining_count " bases"
		Gui, archnemesis_window: Font, s%fSize0% underline
		Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans ys gMap_suggestion HWNDmain_text, % "missing"
		ControlGetPos,,,, height,, ahk_id %main_text%
		Gui, archnemesis_window: Add, Picture, BackgroundTrans ys+2 x+10 gHelp hp w-1, img\GUI\help.png
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
			style := (x = A_LoopField) ? "Border" : ""
			count := 0
			Loop
			{
				If InStr(archnemesis_inventory, check,,, A_Index)
					count := A_Index
				Else break
			}
			If (A_Index = 1)
				Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section gRecipe_tree HWNDmain_text %style%, % A_LoopField
			Else	Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section gRecipe_tree HWNDmain_text %style%, % A_LoopField
				If (color = "Lime" || color = "Fuchsia") && (count != 0)
					Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans ys, % "("count "x)"
			If InStr(pause_list, A_LoopField)
				continue
			Loop, Parse, available_recipes, `,,`,
			{
				If (A_LoopField = "")
					break
				style := (x = A_LoopField) ? "Border" : ""
				If InStr(prio_list%prio_number%_active, A_LoopField)
				{
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section, % "      "
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys gArchnemesis %style%, % A_LoopField
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
			style := (x = A_LoopField) ? "Border" : ""
			Gui, archnemesis_window: Font, s%fSize0% underline
			
			If (A_Index = 1)
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section HWNDmain_text gArchnemesis %style%, % A_LoopField
			Else
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs y+5 Section HWNDmain_text gArchnemesis %style%, % A_LoopField
			
			IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
			comp_no := 0
			Loop, Parse, read, `,,`,
				comp_no += 1
			Gui, archnemesis_window: Font, s%fSize0% norm
			Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, (%comp_no%)
			IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
			ControlGetPos,, ypos,, height,, ahk_id %main_text%
			Loop, Parse, read, `,,`,
				Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
		}
	}
	If (favorite_recipes != "")
	{
		Gui, archnemesis_window: Font, s%fSize0% norm
		Gui, archnemesis_window: Add, Text, xs y+20 Section cRed BackgroundTrans, available burn recipes:
		If (unwanted_recipes != "")
		{
			Loop, Parse, unwanted_recipes, `,,`,
			{
				If (A_LoopField = "")
					break
				IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
				comp_no := 0
				color := 0
				Loop, Parse, read, `,,`,
				{
					If InStr(arch_surplus, A_LoopField,,, Burn_number+1)
						color += 1
					comp_no += 1
				}
				style := (x = A_LoopField) ? "Border" : ""
				color := (color > 0) ? "Yellow" : "White"
				Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans Section xs HWNDmain_text gArchnemesis %style%, % A_LoopField
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, (%comp_no%)
				IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
				ControlGetPos,, ypos,, height,, ahk_id %main_text%
				Loop, Parse, read, `,,`,
					Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
			}
		}
		Gui, archnemesis_window: Font, s%fSize0% underline
		Gui, archnemesis_window: Add, Text, xs y+10 Section cRed BackgroundTrans HWNDmain_text gBurn_all, available burn mods:
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
				style := (x = A_LoopField) ? "Border" : ""
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
				;Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section HWNDmain_text gArchnemesis2, % count "x "
				;Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans ys HWNDmain_text gArchnemesis2 %style%, % A_LoopField
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
				Gui, archnemesis_window: Add, Text, c%color% BackgroundTrans xs Section HWNDmain_text gArchnemesis2, % A_LoopField
				ini_section := SubStr(A_LoopField, InStr(A_LoopField, "x ")+2)
				IniRead, read, ini\db_archnemesis.ini, %ini_section%, rewards
				ControlGetPos,, ypos,, height,, ahk_id %main_text%
				Loop, Parse, read, `,,`,
					Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
				Gui, archnemesis_window: Show, Hide AutoSize
				WinGetPos,,,, heightwin
			}
		}
	}
	Gui, archnemesis_window: Show, Hide AutoSize
	WinGetPos,,, width, height
	xWindow1 := xWindow + width
	Gui, archnemesis_window: Show, % "NA x"xWindow " y"poe_height-height+yScreenOffset
	hwnd_archnemesis_window := WinExist()
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