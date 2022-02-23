#NoEnv
#SingleInstance, Force
#KeyHistory 0
#InstallMouseHook
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
SetKeyDelay, 200
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode Input
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

If !WinExist("ahk_group poe_window")
{
	MsgBox, This script only runs while Path of Exile is running.
	ExitApp
}

global hwnd_archnemesis_window, hwnd_favored_recipes, hwnd_archnemesis_list, all_nemesis, trans := 220, guilist, xWindow, recal_hide := 1, fSize0, fSize1
global archnemesis := 0, archnemesis1_x, archnemesis1_y, archnemesis1_color, archnemesis2_x, archnemesis2_y, archnemesis2_color, available_recipes, archnemesis_inventory, arch_recipes, arch_bases, prio_list, prio_list0, unwanted_recipes, favorite_recipes, arch_inventory := []
IniRead, all_nemesis, ini\db_archnemesis.ini,
all_nemesis_unsurted := all_nemesis
Loop, Parse, all_nemesis, `n,`n
{
	all_nemesis_inverted := (A_Index = 1) ? A_LoopField "," : A_LoopField "," all_nemesis_inverted
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (read != "") && (read != "ERROR")
		arch_recipes := (arch_recipes = "") ? A_LoopField "," : A_LoopField "," arch_recipes
	If (read = "") || (read = "ERROR")
		arch_bases := (arch_bases = "") ? A_LoopField "," : A_LoopField "," arch_bases
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
IniRead, archnemesis1_x, ini\resolutions.ini, %A_ScreenHeight%p, xCoord1
IniRead, archnemesis2_x, ini\resolutions.ini, %A_ScreenHeight%p, xCoord2
IniRead, archnemesis1_y, ini\resolutions.ini, %A_ScreenHeight%p, yCoord
IniRead, archnemesis2_y, ini\resolutions.ini, %A_ScreenHeight%p, yCoord
IniRead, fSize0, ini\resolutions.ini, %A_ScreenHeight%p, font-size0
IniRead, fSize1, ini\resolutions.ini, %A_ScreenHeight%p, font-size1
IniRead, archnemesis1_color, ini\config.ini, PixelSearch, color1
IniRead, archnemesis2_color, ini\config.ini, PixelSearch, color2
IniRead, game_version, ini\config.ini, PixelSearch, game-version
IniRead, resolution, ini\config.ini, PixelSearch, resolution
IniRead, fSize_offset, ini\config.ini, PixelSearch, font-offset, 0
IniRead, fallback, ini\config.ini, PixelSearch, fallback,
If (fallback = "ERROR")
{
	IniWrite, 0, ini\config.ini, PixelSearch, fallback
	fallback := 0
}
fSize0 += fSize_offset
fSize1 += fSize_offset
IniRead, favorite_recipes, ini\config.ini, Settings, favorite recipes
favorite_recipes := (favorite_recipes = "ERROR") ? "" : favorite_recipes
IniRead, yLetters, ini\resolutions.ini, %A_ScreenHeight%p, yLetters
IniRead, xWindow, ini\resolutions.ini, %A_ScreenHeight%p, xWindow
IniRead, invBox, ini\resolutions.ini, %A_ScreenHeight%p, invBox
IniRead, xScan, ini\resolutions.ini, %A_ScreenHeight%p, xScan
IniRead, yScan, ini\resolutions.ini, %A_ScreenHeight%p, yScan
IniRead, dBitMap, ini\resolutions.ini, %A_ScreenHeight%p, dBitMap

Loop, Parse, invBox, `,,`,
	invBox%A_Index% := A_LoopField

If (archnemesis1_x = "ERROR") || (archnemesis1_x = "")
{
	MsgBox, %A_ScreenHeight%p is not supported in this version. This may be due to a recent game update. If that is not the case, please request your resolution on GitHub and provide a screenshot with the archnemesis inventory open. 
	ExitApp
}

SetTimer, Loop, 1000

If (archnemesis1_color = "ERROR") || (archnemesis1_color = "") || (resolution != A_ScreenWidth "x" A_ScreenHeight) || (game_version = "ERROR") || (game_version < "31710")
{
	If (archnemesis1_color = "ERROR") || (archnemesis1_color = "")
		MsgBox, This seems to be the first time this script has been started. Please follow the upcoming instructions.`n`n`nINFO: If you ever need to go through this first-time setup again, delete the ini\config.ini file and restart the script.
	Else	MsgBox, Your resolution has changed since last launch, or the game has been updated. First-time setup is required. 
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	ToolTip, 1) Open the archnemesis inventory.`n2) Keep the cursor away from the archnemesis inventory.`n3) Hold the 7-key until this tooltip disappears., % A_ScreenWidth//2, A_ScreenHeight//2, 1
	KeyWait, 7, D
	PixelGetColor, archnemesis1_color, %archnemesis1_x%, %archnemesis1_y%, RGB
	PixelGetColor, archnemesis2_color, %archnemesis2_x%, %archnemesis2_y%, RGB
	IniWrite, %archnemesis1_color%, ini\config.ini, PixelSearch, color1
	IniWrite, %archnemesis2_color%, ini\config.ini, PixelSearch, color2
	IniWrite, %A_ScreenWidth%x%A_ScreenHeight%, ini\config.ini, PixelSearch, resolution
	IniWrite, 31710, ini\config.ini, PixelSearch, game-version
	ToolTip,,,, 1
	KeyWait, 7
}

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
LLK_Recipes(A_GuiControl, 2)
Return

Archnemesis_letter:
If WinExist("ahk_id " hwnd_archnemesis_list) && (letter_clicked = A_GuiControl)
{
	Gui, archnemesis_list: Destroy
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
	IniRead, components, ini\db_archnemesis.ini, %A_LoopField%, components
	If (SubStr(A_LoopField, 1, 1) = A_GuiControl) && (components != "ERROR")
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
SplitPath, A_GuiControl,,,, mod_base
IniRead, maps, ini\db_archnemesis.ini, %mod_base%, maps
Sort, maps, D`,
Gui, base_info: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, base_info: Margin, 20, 0
Gui, base_info: Color, Black
WinSet, Transparent, %trans%
Gui, base_info: Font, cWhite s%fSize0%, Fontin SmallCaps
Gui, base_info: Add, Text, Center Section BackgroundTrans vheader0, % mod_base ":"
Gui, base_info: Font, s%fSize1%
Loop, Parse, maps, `,,`,
{
	If (A_Index = 1)
		Gui, base_info: Add, Text, Center xs y+6 Section BackgroundTrans, % A_LoopField
	Else
	{
		If (Mod(A_Index-1, 4) = 0) && (A_Index > 3)
			Gui, base_info: Add, Text, Center ys Section BackgroundTrans, % A_LoopField
		Else Gui, base_info: Add, Text, Center xs BackgroundTrans, % A_LoopField
	}
	
}
Gui, base_info: Show, Hide
WinGetPos,,, width
MouseGetPos, outX
Gui, base_info: Show, % "Hide x"outX-width//2 " y"yTree
WinGetPos, outxx,
If (outxx < 0)
	Gui, base_info: Show, % "x0 y"yTree
Else	Gui, base_info: Show, % "x"outX-width//2 " y"yTree
KeyWait, LButton, D
KeyWait, LButton
Gui, base_info: Destroy
WinActivate, ahk_group poe_window
Return

Base_lootGuiClose:
LLK_Overlay("base_loot", 2)
base_loot_toggle := 0
Return

Exit:
Gdip_Shutdown(pToken)
IniWrite, %favorite_recipes%, ini\config.ini, Settings, favorite recipes
If (archnemesis_inventory != "")
	IniWrite, %archnemesis_inventory%, ini\config.ini, Archnemesis, inventory
ExitApp
Return

GUI:
Gui, archnemesis_letters: -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
global hwnd_archnemesis_letters := WinExist()
guilist := "archnemesis_letters"
guilist := guilist "|base_loot"
guilist := guilist "|archnemesis_list"
guilist := guilist "|archnemesis_window"
guilist := guilist "|favored_recipes"
Gui, archnemesis_letters: Margin, 0, 2
Gui, archnemesis_letters: Color, Black
;WinSet, TransColor, Blue
WinSet, Transparent, %trans%
Gui, archnemesis_letters: Font, s%fSize0% cWhite, Fontin SmallCaps
letter := ""
Gui, archnemesis_letters: Add, Text, x0 Center BackgroundTrans, % "    "
Loop, Parse, all_nemesis, `n, `n
{
	IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
	If (read != "ERROR") && (letter != SubStr(A_LoopField, 1, 1))
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
Gui, archnemesis_letters: Show, % "Hide x" (xWindow*0.96)//2-guiwidth//2 " y"yLetters
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
	Gui, recalibrate_list: Show, % "NA x"mouseX-30 " y"outY-10-height
}
Return

Surplus:
If (arch_surplus != "")
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
	Gui, surplus_view: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, surplus_view: Margin, 20, 0
	Gui, surplus_view: Color, Black
	WinSet, Transparent, %trans%
	Gui, surplus_view: Font, cWhite s%fSize0%, Fontin SmallCaps
	Gui, surplus_view: Add, Text, BackgroundTrans Section HWNDmain_text vheader3 Center, current prio surplus:
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
	Gui, surplus_view: Show, x0 y%yTree%
}
KeyWait, LButton, D
KeyWait, LButton
Gui, surplus_view: Destroy
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
	If (inactive_counter>3)
	{
		LLK_Overlay("hide")
		inactive := 1
		WinWaitActive, ahk_group poe_window
		LLK_Overlay("show")
	}
}
If WinActive("ahk_group poe_window")
{
	inactive := 0
	inactive_counter := 0
	If (fallback = 0) || (fallback_override = 1)
		LLK_PixelSearch("archnemesis")
	If (archnemesis = 1)
	{
		MouseGetPos, mouseXpos, mouseYpos
		If (invBox1 < mouseXpos && mouseXpos < invBox2 && invbox3 < mouseYpos && mouseYpos < invBox4)
			LLK_Overlay("favored_recipes", 2)
		If !WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 1)
		If !WinExist("ahk_id " hwnd_favored_recipes) && (hwnd_favored_recipes != "") && (favorite_recipes != "")
			If !(invBox1 < mouseXpos && mouseXpos < invBox2 && invBox3 < mouseYpos && mouseYpos < invBox4)
				LLK_Overlay("favored_recipes", 1)
		If !WinExist("ahk_id " hwnd_archnemesis_window) && (hwnd_archnemesis_window != "")
			LLK_Overlay("archnemesis_window", 1)
	}
	If (archnemesis = 0)
	{
		If WinExist("ahk_id " hwnd_archnemesis_letters)
			LLK_Overlay("archnemesis_letters", 2)
		If WinExist("ahk_id " hwnd_archnemesis_list)
			LLK_Overlay("archnemesis_list", 2)
		If WinExist("ahk_id " hwnd_archnemesis_window)
			LLK_Overlay("archnemesis_window", 2)
		If WinExist("ahk_id " hwnd_favored_recipes)
			LLK_Overlay("favored_recipes", 2)
		fallback_override := 0
	}
}
Return

Map_highlight:
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
Clipboard := StrReplace(SubStr(A_GuiControl, InStr(A_GuiControl, "mods in ")+8), A_Space, ".")
SendInput, ^{f}^{a}^{v}
Return

Map_suggestion:
/*
If GetKeyState("Shift", "P")
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
*/
If (list_remaining = "")
	Return
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
Gui, map_suggestions: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border, Use this for map tab searches
;Else	Gui, map_suggestions: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, map_suggestions: Margin, 20, 0
Gui, map_suggestions: Color, Black
WinSet, Transparent, %trans%
Gui, map_suggestions: Font, cWhite s%fSize0%, Fontin SmallCaps
Gui, map_suggestions: Add, Text, Center Section BackgroundTrans vheader01, maps with drop overlaps:
Gui, map_suggestions: Font, s%fSize1% underline

search_term := ""
Loop, Parse, optimal_maps, `,,`,
{
	If (A_LoopField = "") || (A_Index > 10)
		break
	If !InStr(A_LoopField, "1 mods") ; && !InStr(A_LoopField, "2 mods")
	{
		If (A_Index = 1)
			Gui, map_suggestions: Add, Text, BackgroundTrans HWNDmain_text y+6 xs Section Center gMap_highlight, % A_LoopField
		Else	Gui, map_suggestions: Add, Text, BackgroundTrans HWNDmain_text xs Center gMap_highlight, % A_LoopField
	}
}
Gui, map_suggestions: Show, NA Center
WinActivate, ahk_group poe_window
Return

Map_suggestionsGUIClose:
Gui, map_suggestions: Destroy
Return

Max_recipe:
clipboard := "!used"
KeyWait, LButton
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
sleep, 250
SendInput, ^{f}^{v}{Enter}
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
If !FileExist("img\Recognition\" A_ScreenHeight "p\Archnemesis\")
	FileCreateDir, img\Recognition\%A_ScreenHeight%p\Archnemesis\
count := ""
While FileExist("img\Recognition\" A_ScreenHeight "p\Archnemesis\" recal_choice count ".png")
	count += 1
Gdip_SaveBitmapToFile(Gdip_BitmapFromScreen(xBitMap "|" yBitMap "|" dBitMap "|" dBitMap), "img\Recognition\" A_ScreenHeight "p\Archnemesis\" recal_choice count ".png", 100)
archnemesis_inventory := (archnemesis_inventory = "") ? recal_choice : archnemesis_inventory "," recal_choice
Return

Recalibrate_UI:
If InStr(A_GuiControl, "cancel")
	Reload
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
		else
		{
			If (SubStr(A_LoopField, 1, 1) != "k")
				Gui, recalibration: Add, Text, ys wp gRecalibrate_letter BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
			Else	Gui, recalibration: Add, Text, xs wp gRecalibrate_letter Section BackgroundTrans Center Border, % SubStr(A_LoopField, 1, 1)
		}
		letter := SubStr(A_LoopField, 1, 1)
	}
}
Gui, recalibration: Show, x%xWindow% yCenter
Return

Fallback:
hotkey0 := StrReplace(A_ThisHotkey, "$", "")
;LLK_Overlay("archnemesis")
LLK_PixelSearch("archnemesis")
If (archnemesis = 0)
{
	SendInput, {%hotkey0%}
	fallback_override := 1
}
else fallback_override := 1
Return

Favored_recipes:
Gui, archnemesis_window: Destroy
Gui, archnemesis_list: Hide
If InStr(A_GuiControl, "clr")
{
	Gui, favored_recipes: Destroy
	favorite_recipes := ""
}
favor_choice := (InStr(A_GuiControl, "scan") || InStr(A_GuiControl, "clr")) ? "" : A_GuiControl
{
	hwnd_favored_recipes := ""
	LLK_Overlay("favored_recipes", 2)
}
If (favor_choice != "")
{
	If InStr(favorite_recipes, favor_choice)
		favorite_recipes := StrReplace(favorite_recipes, favor_choice ",", "")
	Else favorite_recipes := (favorite_recipes = "") ? favor_choice "," : favorite_recipes favor_choice ","
}
prio_list := ""
prio_list_recipes := ""
list_remaining := ""
fav_in_inv :=
fav_not_inv :=
If (favorite_recipes != "")
{
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(archnemesis_inventory, A_LoopField)
			fav_in_inv := (fav_in_inv = "") ? A_LoopField "," : fav_in_inv A_LoopField ","
		Else	fav_not_inv := (fav_not_inv = "") ? A_LoopField "," : fav_not_inv A_LoopField ","
	}
	favorite_recipes := fav_not_inv fav_in_inv
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		prio_list := (prio_list = "") ? A_LoopField "," : prio_list A_LoopField ","
		IniRead, components0, ini\db_archnemesis.ini, %A_LoopField%, components
		If (components0 != "ERROR")
		{
			prio_list := prio_list components0 ","
			Loop, Parse, components0, `,,`,
			{
				IniRead, components1, ini\db_archnemesis.ini, %A_LoopField%, components
				If (components1 != "ERROR")
				{
					prio_list_recipes := (prio_list_recipes = "") ? A_LoopField "," : prio_list_recipes A_LoopField ","
					prio_list := prio_list components1 ","
					Loop, Parse, components1, `,,`,
					{
						IniRead, components2, ini\db_archnemesis.ini, %A_LoopField%, components
						If (components2 != "ERROR")
						{
							prio_list_recipes := (prio_list_recipes = "") ? A_LoopField "," : prio_list_recipes A_LoopField ","
							prio_list := prio_list components2 ","
							Loop, Parse, components2, `,,`,
							{
								IniRead, components3, ini\db_archnemesis.ini, %A_LoopField%, components
								If (components3 != "ERROR")
								{
									prio_list_recipes := (prio_list_recipes = "") ? A_LoopField "," : prio_list_recipes A_LoopField ","
									prio_list := prio_list components3 ","
								}
							}
						}
					}
				}
			}
		}
	}
	list_remaining := ""
	archnemesis_inventory_leftover := archnemesis_inventory
	Loop, Parse, favorite_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		IniRead, recipe, ini\db_archnemesis.ini, %A_LoopField%, components
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
								Loop, Parse, recipe1, `,,`, ;gargantuan
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
				else list_remaining := (list_remaining = "") ? A_LoopField "," : list_remaining A_LoopField ","
			}
			Else	archnemesis_inventory_leftover := StrReplace(archnemesis_inventory_leftover, A_LoopField ",", "",, 1)
		}
	}
	arch_surplus := ""
	Loop, Parse, archnemesis_inventory_leftover, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(prio_list, A_LoopField) && !InStr(favorite_recipes, A_LoopField)
			arch_surplus := (arch_surplus = "") ? A_LoopField "," : arch_surplus A_LoopField ","
	}
	archnemesis_inventory_surplus := archnemesis_inventory
	prio_list_leftover := prio_list
	prio_list_recipes_leftover := prio_list_recipes
	global ignore_list := ""
	Loop, Parse, arch_bases, `,,`,
	{
		If !InStr(prio_list, A_LoopField)
			ignore_list := (ignore_list = "") ? A_LoopField "," : A_LoopField "," ignore_list
	}
	Loop, Parse, archnemesis_inventory, `,,`,
	{
		If (A_LoopField = "")
			break
		If InStr(prio_list_leftover, A_LoopField)
			prio_list_leftover := StrReplace(prio_list_leftover, A_LoopField ",", "",, 1)
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
list_remaining_single := ""
Loop, Parse, list_remaining, `,,`,
{
	If !InStr(list_remaining_single, A_LoopField)
		list_remaining_single := (list_remaining_single = "") ? A_LoopField "," : list_remaining_single A_LoopField ","
}
Gui, base_loot: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_base_loot, Missing base mods:
Gui, base_loot: Margin, 15, 0
Gui, base_loot: Color, Black
WinSet, Transparent, 200
Gui, base_loot: Font, cWhite s%fSize1%, Fontin SmallCaps
Loop, Parse, list_remaining_single, `,,`,
{
	If (A_LoopField = "")
		break
	If (A_Index = 1)
		Gui, base_loot: Add, Text, Center Section BackgroundTrans, % A_LoopField
	Else	Gui, base_loot: Add, Text, Center ys BackgroundTrans, % A_LoopField
}
Gui, base_loot: Show, Hide x0 y0
WinGetPos,,, width, height
style := (base_loot_toggle = 1) ? "NA" : "Hide"
Gui, base_loot: Show, % style "y0 x"A_ScreenWidth//2-width//2
favor_choice := ""
Gui, favored_recipes: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, favored_recipes: Margin, 10, 2
Gui, favored_recipes: Color, Black
WinSet, Transparent, %trans%
Gui, favored_recipes: Font, s%fSize0% cWhite underline, Fontin SmallCaps
Gui, favored_recipes: Add, Text, cYellow BackgroundTrans Section HWNDmain_text Center gSurplus, prio:
Gui, favored_recipes: Font, % "s"fSize1-2 "norm"
ControlGetPos,, ypos,, height,, ahk_id %main_text%
Gui, favored_recipes: Add, Button, gFavored_recipes h%height% ys y%ypos%, clr

Loop, Parse, favorite_recipes, `,,`,
{
	If (A_LoopField = "") || (favorite_recipes = "")
		break
	Gui, favored_recipes: Font, s%fSize0% underline
	color := InStr(archnemesis_inventory, A_LoopField) ? "Lime" : "White"
	Gui, favored_recipes: Add, Text, c%color% ys BackgroundTrans HWNDmain_text gRecipe_tree, % A_LoopField
	IniRead, rewards, ini\db_archnemesis.ini, %A_LoopField%, rewards
	ControlGetPos,, ypos,, height,, ahk_id %main_text%
	Gui, favored_recipes: Font, s%fSize0% norm
}
If (list_remaining != "") && (arch_inventory.Length() = 64)
{
	Gui, favored_recipes: Margin, 6, 2
	Gui, favored_recipes: Font, underline
	Gui, favored_recipes: Add, Text, xs BackgroundTrans Section gMap_suggestion, missing:
	Gui, favored_recipes: Font, norm
	Loop, Parse, arch_bases, `,,`,
	{
		If (A_LoopField = "")
			break
		base_mod := A_LoopField
		count := 0
		Loop
		{
			check := InStr(list_remaining, base_mod,,, A_Index)
			If (check = 0)
				break
			Else count := A_Index
		}
		If (count != 0)
		{
			Gui, favored_recipes: Add, Text, ys BackgroundTrans HWNDmain_text, %count%x
			ControlGetPos,,,, height,, ahk_id %main_text%
			Gui, favored_recipes: Add, Picture, h%height% w-1 BackgroundTrans ys gBase_info, img\Archnemesis Icons\%base_mod%.png
		}
	}
}
Gui, favored_recipes: Show, Hide x0 y0
WinGetPos,,, width, height
global yTree := height + 10
hwnd_favored_recipes := WinExist()
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
Return

Font_offset:
If InStr(A_GuiControl, "–")
	fSize_offset -= 1
If InStr(A_GuiControl, "+")
	fSize_offset += 1
IniWrite, %fSize_offset%, ini\config.ini, PixelSearch, font-offset
Reload
Return

Recipes:
global available_recipes := ""
global unwanted_recipes := ""
global unwanted_mods := ""
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
	Loop, Parse, all_nemesis_inverted, `,,`,
	{
		If (A_LoopField = "")
			break
		If !InStr(prio_list, A_LoopField) && InStr(archnemesis_inventory, A_LoopField)
			unwanted_mods := (unwanted_mods = "") ? A_LoopField "," : unwanted_mods A_LoopField ","	
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
Gui, recipe_tree: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
Gui, recipe_tree: Color, Black
WinSet, Transparent, %trans%
Gui, recipe_tree: Font, cWhite s%fSize0%, Fontin SmallCaps
/*
IniRead, rewards, ini\db_archnemesis.ini, %A_GuiControl%, rewards
Loop, Parse, rewards, `,,`,
	Gui, recipe_tree: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
IniRead, modifiers, ini\db_archnemesis.ini, %A_GuiControl%, modifiers
If (modifiers != "ERROR") && (modifiers != "")
	Gui, recipe_tree: Add, Text, cSilver xs BackgroundTrans Section Center, %modifiers%
Gui, recipe_tree: Font, cWhite s%fSize0%

count := 0
Loop
{
	check := InStr(archnemesis_inventory, A_GuiControl,,, A_Index)
	If (check = 0)
		break
	Else count += 1
}
count := (count = 0) ? "" : " (" count ")"
*/
color := InStr(archnemesis_inventory, A_GuiControl) ? "Lime" : "White"
ControlGetPos,, ypos,, height,, ahk_id %main_text0%
Gui, recipe_tree: Font, cWhite s%fSize1%
IniRead, components, ini\db_archnemesis.ini, %A_GuiControl%, components
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
WinGetPos,,, width
MouseGetPos, outx
Gui, recipe_tree: Show, % "Hide x"outx-width//2
WinGetPos, winx
If (winx < 0)
	Gui, recipe_tree: Show, % "x0 y"yTree
Else	Gui, recipe_tree: Show, % "x"outx-width//2 " y"yTree
KeyWait, LButton, D
KeyWait, LButton
Gui, recipe_tree: Destroy
WinActivate, ahk_group poe_window
Return

Scan:
If (xScan = "") || (xScan = "ERROR")
{
	MsgBox, Scanning the archnemesis inventory at this resolution is not yet supported.
	Return
}
If GetKeyState("Shift", "P")
{
	Run, explore img\Recognition\%A_ScreenHeight%p\Archnemesis
	Return
}
hwnd_archnemesis_window := ""
Gui, archnemesis_list: Destroy
Gui, archnemesis_window: Destroy
KeyWait, LButton
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
sleep, 200
SendInput, ^{f}{ESC}
sleep, 200
archnemesis_inventory := ""
xGrid := []
yGrid := []
progress := 0
MouseGetPos, outX
ToolTip, % "Don't move the cursor!`n" "Progress: " progress "/64", outX-60, yLetters+50, 17
Loop, Parse, xScan, `,,`,
	xGrid.Push(A_LoopField)
Loop, Parse, yScan, `,,`,
	yGrid.Push(A_LoopField)
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
		If !FileExist("img\Recognition\" A_ScreenHeight "p\Archnemesis\*.png")
			GoSub, Recalibrate
		Else
		{
			If (arch_inventory != "")
			{
				compare := arch_inventory[progress]
				If (compare != "")
				{
					Loop, Files, img\Recognition\%A_ScreenHeight%p\Archnemesis\%compare%*.png
					{
						ImageSearch, outX, outY, xGridScan0, yGridScan0, xGridScan1, yGridScan1, *50 %A_LoopFilePath%
						comparison := ErrorLevel
						If (ErrorLevel = 0)
							break
					}
				}
			}
			If (comparison != 0)
			{
				match := ""
				Loop, Files, img\Recognition\%A_ScreenHeight%p\Archnemesis\*.png
				{
					ImageSearch, outX, outY, xGridScan0, yGridScan0, xGridScan1, yGridScan1, *50 %A_LoopFilePath%
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

LLK_Recipes(x := 0, y := 0)
{
	hwnd_archnemesis_window := ""
	If (x != 0)
	{
		search_term := ""
		If (y = 2)
			search_term := A_GuiControl
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
	KeyWait, LButton
	sleep, 250
	SendInput, ^{f}^{v}{Enter}
	}
	Gui, archnemesis_window: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, archnemesis_window: Margin, 6, 2
	Gui, archnemesis_window: Color, Black
	WinSet, Transparent, %trans%
	Gui, archnemesis_window: Font, s%fSize0% cWhite, Fontin SmallCaps
	window_text := (prio_list != "") ? "ready (prioritized):" : "ready:"
	Gui, archnemesis_window: Add, Text, cYellow BackgroundTrans Section, %window_text%
	Gui, archnemesis_window: Margin, 6, 2
	listed_recipes := ""
	Loop, Parse, available_recipes, `,,`,
	{
		If (A_LoopField = "")
			break
		style := (x = A_LoopField) ? "Border" : ""
		Gui, archnemesis_window: Font, s%fSize0% underline
		If (A_Index = 1)
		{
			Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section HWNDmain_text gArchnemesis %style%, % A_LoopField
			listed_recipes := A_LoopField ","
		}
		Else
		{
			Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs y+5 Section HWNDmain_text gArchnemesis %style%, % A_LoopField
			listed_recipes := listed_recipes A_LoopField ","
		}
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
	If (favorite_recipes != "")
	{
		Gui, archnemesis_window: Font, s%fSize0% norm
		Gui, archnemesis_window: Add, Text, xs y+20 Section cRed BackgroundTrans, available burn recipes:
		Gui, archnemesis_window: Margin, 6, 2
		If (unwanted_recipes != "")
		{
			Loop, Parse, unwanted_recipes, `,,`,
			{
				If (A_LoopField = "")
					break
				Gui, archnemesis_window: Font, s%fSize0% underline
				style := (x = A_LoopField) ? "Border" : ""
				;If (A_Index = 1)
				{
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans Section xs HWNDmain_text gArchnemesis %style%, % A_LoopField
				}
				;Else Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs y+6 Section HWNDmain_text gArchnemesis %style%, % A_LoopField
				;If !InStr(archnemesis_inventory, A_LoopField)
				;{
					IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, components
					comp_no := 0
					Loop, Parse, read, `,,`,
						comp_no += 1
					Gui, archnemesis_window: Font, s%fSize0% norm
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, (%comp_no%)
					
					
				;}
				/*
				Else
				{
					Gui, archnemesis_window: Font, s%fSize0% norm
					Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans ys, (1)
				}
				*/
				IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
				ControlGetPos,, ypos,, height,, ahk_id %main_text%
				Loop, Parse, read, `,,`,
					Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
			}
		}
		Gui, archnemesis_window: Font, s%fSize0% norm
		Gui, archnemesis_window: Add, Text, xs y+20 Section cRed BackgroundTrans, available burn mods:
		If (unwanted_mods != "")
		{
			Loop, Parse, unwanted_mods, `,,`,
			{
				If (A_LoopField = "") || (A_Index > 7)
					break
				Gui, archnemesis_window: Font, s%fSize0% underline
				style := (x = A_LoopField) ? "Border" : ""
				Gui, archnemesis_window: Add, Text, cWhite BackgroundTrans xs Section HWNDmain_text gArchnemesis2 %style%, % A_LoopField
				IniRead, read, ini\db_archnemesis.ini, %A_LoopField%, rewards
				ControlGetPos,, ypos,, height,, ahk_id %main_text%
				Loop, Parse, read, `,,`,
					Gui, archnemesis_window: Add, Picture, h%height% w-1 BackgroundTrans ys y%ypos%, img\rewards\%A_LoopField%.png
			}
		}
	}
	Gui, archnemesis_window: Margin, 6, 2
	Gui, archnemesis_window: Show, Hide
	WinGetPos,,,, height
	Gui, archnemesis_window: Show, % "NA x"xWindow " y"A_ScreenHeight-height
	hwnd_archnemesis_window := WinExist()
}

LLK_Overlay(x, y:=0)
{
	global
	If (x="hide")
	{
		Loop, Parse, guilist, |
			Gui, %A_LoopField%: Hide
		Return
	}
	If (x="show")
	{
		Loop, Parse, guilist, |
			If (state_%A_LoopField%=1)
				Gui, %A_LoopField%: Show, NA
		Return
	}
	If (y=0)
	{
		If !WinExist("ahk_id " hwnd_%x%)
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
	PixelSearch, OutputVarX, OutputVarY, %x%1_x, %x%1_y, %x%1_x, %x%1_y, %x%1_color, 0, Fast RGB
		If (ErrorLevel=0)
			PixelSearch, OutputVarX, OutputVarY, %x%2_x, %x%2_y, %x%2_x, %x%2_y, %x%2_color, 0, Fast RGB
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