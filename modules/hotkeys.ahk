Init_hotkeys:
IniRead, advanced_items_rebound, ini\hotkeys.ini, Settings, advanced item-info rebound, 0
IniRead, ckey_rebound, ini\hotkeys.ini, Settings, c-key rebound, 0
IniRead, omnikey_hotkey, ini\hotkeys.ini, Hotkeys, omni-hotkey, % A_Space
IniRead, omnikey_hotkey2, ini\hotkeys.ini, Hotkeys, omni-hotkey2, % A_Space
IniRead, alt_modifier, ini\hotkeys.ini, Hotkeys, item-descriptions key, % A_Space
IniRead, tab_hotkey, ini\hotkeys.ini, Hotkeys, tab replacement, % A_Space
If !omnikey_hotkey
	omnikey_hotkey := "MButton"

If !tab_hotkey
	tab_hotkey := "TAB"

Hotkey, If, enable_killtracker && settings_enable_maptracker && (map_tracker_refresh_kills = 1)
Hotkey, % omnikey_hotkey, LLK_MapTrackKills, On

Hotkey, IfWinActive, ahk_group poe_ahk_window
If !ckey_rebound
{
	Hotkey, % "*~" omnikey_hotkey, Omnikey, On
	Hotkey, % "*~" omnikey_hotkey " UP", LLK_OmnikeyRelease, On
}
Else
{
	Hotkey, % "*~" omnikey_hotkey2, Omnikey, On
	Hotkey, % "*~" omnikey_hotkey2 " UP", LLK_OmnikeyRelease, On
	Hotkey, % "*~" omnikey_hotkey, Omnikey2, On
	Hotkey, % "*~" omnikey_hotkey " UP", LLK_OmnikeyRelease, On
}

Hotkey, If, cheatsheet_overlay_image && WinExist("ahk_id " hwnd_cheatsheet)
Hotkey, % tab_hotkey, LLK_TabCheatSheetAll, On
	
Hotkey, IfWinActive, ahk_group poe_ahk_window
Hotkey, % tab_hotkey, LLK_TabKey, On
Return

Hotkeys:
Return

#If enable_killtracker && settings_enable_maptracker && (map_tracker_refresh_kills = 1)

#If enable_omnikey_pob && settings_enable_levelingtracker && WinActive("ahk_exe Path of Building.exe")

MButton::
LLK_ScreencapPoB()
Return

#If mapinfo_switched

$~alt::
{
	If (A_TickCount < alt_press + 500)
	{
		LLK_Overlay("mapinfo_panel", "show")
		KeyWait, alt
		LLK_Overlay("mapinfo_panel", "hide")
		Return
	}
	alt_press := A_TickCount
	KeyWait, alt
}
Return

#If mapinfo_control_selected
	
1::
2::
3::
4::
mapinfo_control_selected_rank := A_ThisHotkey
cMod := mapinfo_colors[A_ThisHotkey]
GuiControl, mapinfo_panel: +c%cMod%, mapinfo_panelentry%mapinfo_control_selected%
GuiControl, mapinfo_panel: movedraw, mapinfo_panelentry%mapinfo_control_selected%
;WinSet, Redraw,, ahk_id %hwnd_mapinfo_panel%
Return

#If searchstrings_scroll_contents && WinActive("ahk_group poe_window")

ESC::
searchstrings_scroll_contents := ""
Return

WheelDown::
If searchstrings_scroll_progress
	Return
If IsObject(searchstrings_scroll_contents) && (searchstrings_scroll_index = searchstrings_scroll_contents.Count())
	Return

searchstrings_scroll_progress := 1

If IsObject(searchstrings_scroll_contents)
{
	searchstrings_scroll_index += 1
	Clipboard := StrReplace(searchstrings_scroll_contents[searchstrings_scroll_index], ";")
}
Else
{
	searchstrings_scroll_index -= 1
	Clipboard := StrReplace(searchstrings_scroll_contents, ";" searchstrings_scroll_number ";", searchstrings_scroll_number + searchstrings_scroll_index)
	Clipboard := StrReplace(Clipboard, ";")
}
SendInput, ^{f}
sleep 100
SendInput, ^{v}{Enter}
sleep 150
searchstrings_scroll_progress := 0
Return

WheelUp::
If searchstrings_scroll_progress
	Return
If IsObject(searchstrings_scroll_contents) && (searchstrings_scroll_index = 1)
	Return

searchstrings_scroll_progress := 1

If IsObject(searchstrings_scroll_contents)
{
	searchstrings_scroll_index -= 1
	Clipboard := StrReplace(searchstrings_scroll_contents[searchstrings_scroll_index], ";")
}
Else
{
	searchstrings_scroll_index += 1
	Clipboard := StrReplace(searchstrings_scroll_contents, ";" searchstrings_scroll_number ";", searchstrings_scroll_number + searchstrings_scroll_index)
	Clipboard := StrReplace(Clipboard, ";")
}
SendInput, ^{f}
sleep 100
SendInput, ^{v}{Enter}
sleep 150
searchstrings_scroll_progress := 0
Return

#If WinActive("ahk_id " hwnd_cheatsheets_menu)

ESC::cheatsheets_menuGuiClose()

#If WinActive("ahk_id " hwnd_snip)
	
ESC::snipGuiClose()

*Up::
*Down::
*Left::
*Right::
WinGetPos, xSnip, ySnip, wSnip, hSnip, ahk_id %hwnd_snip%
Switch A_ThisHotkey
{
	Case "*up":
		If GetKeyState("Alt", "P")
			hSnip -= GetKeyState("Ctrl", "P") ? 10 : 1
		Else ySnip -= GetKeyState("Ctrl", "P") ? 10 : 1
	Case "*down":
		If GetKeyState("Alt", "P")
			hSnip += GetKeyState("Ctrl", "P") ? 10 : 1
		Else ySnip += GetKeyState("Ctrl", "P") ? 10 : 1
	Case "*left":
		If GetKeyState("Alt", "P")
			wSnip -= GetKeyState("Ctrl", "P") ? 10 : 1
		Else xSnip -= GetKeyState("Ctrl", "P") ? 10 : 1
	Case "*right":
		If GetKeyState("Alt", "P")
			wSnip += GetKeyState("Ctrl", "P") ? 10 : 1
		Else xSnip += GetKeyState("Ctrl", "P") ? 10 : 1
}
WinMove, ahk_id %hwnd_snip%,, %xSnip%, %ySnip%, %wSnip%, %hSnip%
Return

#If WinExist("ahk_id " hwnd_pob_crop1)

ESC::
pob_crop_x1 := "", pob_crop_y1 := "", pob_crop_x2 := "", pob_crop_y2 := "", hwnd_pob_crop1 := ""
Loop 4
{
	Gui, pob_crop%A_Index%: Destroy
	hwnd_pob_crop%A_Index% := ""
}
Return

#If WinExist("ahk_id " hwnd_screencap_setup)

ESC::
leveling_guide_screencap_caption := ""
Gui, screencap_setup: Destroy
hwnd_screencap_setup := ""
Return

#If WinExist("ahk_id " hwnd_cheatsheet)

ESC::LLK_CheatSheetsClose()

#If cheatsheet_overlay_tab
	
Space::
cheatsheet_overlay_tab := 0
Gui, cheatsheet: Destroy
hwnd_cheatsheet := ""
cheatsheet_overlay_type := ""
KeyWait, Space
Return

#If cheatsheet_overlay_advanced && WinExist("ahk_id " hwnd_cheatsheet)

*1::
*2::
*3::
*4::
*Space::
hotkey_copy := InStr(A_ThisHotkey, "Space") ? 0 : StrReplace(A_ThisHotkey, "*")
MouseGetPos,,,, cheatsheets_control_hover, 2
cheatsheet_panel_selected := ""
If (cheatsheets_control_hover = hwnd_cheatsheets_overlay_panel1)
	cheatsheet_panel_selected := 1
If (cheatsheets_control_hover = hwnd_cheatsheets_overlay_panel2)
	cheatsheet_panel_selected := 2
If (cheatsheets_control_hover = hwnd_cheatsheets_overlay_panel3)
	cheatsheet_panel_selected := 3
If (cheatsheets_control_hover = hwnd_cheatsheets_overlay_panel4)
	cheatsheet_panel_selected := 4

If !cheatsheet_panel_selected || (cheatsheets_rank_%cheatsheet_object_triggered1%_panel%cheatsheet_panel_selected% = hotkey_copy)
	Return

cheatsheets_rank_%cheatsheet_object_triggered1%_panel%cheatsheet_panel_selected% := hotkey_copy
IniWrite, % hotkey_copy, % "cheat-sheets\" cheatsheet_triggered "\info.ini", % cheatsheet_object_triggered, % "panel " cheatsheet_panel_selected " rank"
GuiControl, % "cheatsheet: +c"cheatsheets_panel_colors[hotkey_copy], %cheatsheets_control_hover%
GuiControl, cheatsheet: movedraw, %cheatsheets_control_hover%
;WinSet, Redraw,, ahk_id %hwnd_cheatsheet%
KeyWait, % StrReplace(A_ThisHotkey, "*")
Return

#If cheatsheet_overlay_image && WinExist("ahk_id " hwnd_cheatsheet)

Up::
Down::
Left::
Right::
F1::
F2::
F3::LLK_CheatSheetsMove()

RButton::
Space::
1::
2::
3::
4::
5::
6::
7::
8::
9::
0::
a::
b::
c::
d::
e::
f::
g::
h::
i::
j::
k::
l::
m::
n::
o::
p::
q::
r::
s::
t::
u::
v::
w::
x::
y::
z::
LLK_CheatSheetsImages(cheatsheet_overlay_active)
KeyWait, % A_ThisHotkey
Return

#If (leveling_guide_skilltree_open = 1)

RButton::
start := A_TickCount
While GetKeyState("RButton", "P")
{
	If (A_TickCount >= start + 300)
	{
		If (leveling_guide_skilltree_active > 1)
		{
			leveling_guide_skilltree_active -= 1
			LLK_LevelGuideSkillTree()
		}
		KeyWait, RButton
		Return
	}
}
If (leveling_guide_skilltree_active < leveling_guide_valid_skilltree_files)
{
	leveling_guide_skilltree_active += 1
	LLK_LevelGuideSkillTree()
}
Return

1::
2::
3::
4::
5::
6::
7::
8::
9::
0::
If (A_ThisHotkey != leveling_guide_skilltree_active) && ((0 < A_ThisHotkey) && (A_ThisHotkey <= leveling_guide_valid_skilltree_files) || (A_ThisHotkey = 0) && (leveling_guide_valid_skilltree_files >= 10))
{
	leveling_guide_skilltree_active := (A_ThisHotkey = 0) ? 10 : A_ThisHotkey
	LLK_LevelGuideSkillTree()
}
Return

#If WinActive("ahk_group poe_window") && (enable_itemchecker_ID = 1) && (shift_down = "wisdom")

+RButton::LLK_ItemCheckVendor() ;shift-right-clicking an item to place a red marker

#If WinActive("ahk_group poe_window") && (enable_itemchecker_ID = 1 || enable_map_info_shiftclick) && (gamescreen = 0) && (hwnd_win_hover != hwnd_itemchecker)
	
~+RButton:: ;shift-right-clicking a currency item to start shift-trigger for item-info tooltips
Clipboard := ""
SendInput, ^{c}
ClipWait, 0.05
If enable_itemchecker_ID && (InStr(Clipboard, "scroll of wisdom") || InStr(Clipboard, "chaos orb") || InStr(Clipboard, " guarantee") || InStr(Clipboard, "eldritch ichor`r") || InStr(Clipboard, "eldritch ember`r"))
	shift_down := "wisdom"
If enable_map_info_shiftclick && (InStr(Clipboard, "orb of alchemy") || InStr(Clipboard, "chaos orb") || InStr(Clipboard, "orb of binding") || InStr(Clipboard, "scroll of wisdom"))
	shift_down := "wisdom"
KeyWait, Shift
shift_down := ""
If WinExist("ahk_id " hwnd_itemchecker)
	LLK_ItemCheckClose()
Return

#If WinActive("ahk_group poe_window") && (enable_itemchecker_ID = 1 || enable_map_info_shiftclick) && (gamescreen = 0) && (shift_down = "wisdom") && (hwnd_win_hover != hwnd_itemchecker)

~+LButton:: ;shift-trigger for item-info tooltip
Clipboard := ""
KeyWait, LButton
Sleep, 150
SendInput, ^!{c}
ClipWait, 0.05
If enable_map_info && enable_map_info_shiftclick && (InStr(Clipboard, "item class: maps") || InStr(Clipboard, "`nmaven's invitation: ") || InStr(Clipboard, "item class: blueprints") || InStr(Clipboard, "item class: contracts")) && !InStr(Clipboard, "fragment")
	LLK_MapInfo()
Else LLK_ItemCheck()
Return

#If WinActive("ahk_group poe_window") && enable_itemchecker_gear && inventory && !gamescreen && (gear_mouse_over != 0) && (hwnd_win_hover != hwnd_itemchecker)

~RButton:: ;clear gear-slot ('league-start' mode)
start_rbutton := A_TickCount
While GetKeyState("RButton", "P")
{
	If (A_TickCount >= start_rbutton + 500)
	{
		equipped_%gear_mouse_over% := ""
		LLK_ToolTip(gear_mouse_over " cleared")
		If WinExist("ahk_id " hwnd_itemchecker)
			LLK_ItemCheck(1)
		KeyWait, RButton
		Return
	}
}
Return

~LButton UP:: ;check which item was equipped
Clipboard := ""
Sleep, 100
SendInput, !^{c}
ClipWait, 0.05
If (Clipboard != "")
{
	LLK_ItemCheckGear(gear_mouse_over)
	LLK_ToolTip(gear_mouse_over, 0.5)
}
Return

#If settings_enable_maptracker && (enable_loottracker = 1) && (map_tracker_map != "") && !map_tracker_paused && WinActive("ahk_group poe_window") 

^+LButton:: ;check which item was ctrl-clicked into the stash
^LButton::
MouseGetPos, mouseX
If (map_tracker_map != "") && (mouseX > poe_width//2) && LLK_ImageSearch("stash")
	LLK_MapTrack("add")
;Else SendInput, % GetKeyState("LShift", "P") ? "{LControl Down}{LShift Down}{LButton}{LControl Up}{LShift Up}" : "{LControl Down}{LButton}{LControl Up}"
Return

#IfWinActive ahk_group poe_ahk_window

::r.llk::
SendInput, {ESC}
Reload
ExitApp
Return

::.llk::
SendInput, {ESC}
GoSub, Settings_menu ;LLK_HotstringClip(A_ThisHotkey, 1)
Return

:?:.wiki::
LLK_HotstringClip(A_ThisHotkey, 1)
Return

::.legion::
SendInput, {ESC}
GoSub, Legion_seeds
GoSub, Legion_seeds2
Return

ESC::
/*
If WinExist("ahk_id " hwnd_screencap)
{
	Gui, screencap: Destroy
	hwnd_screencap := ""
	Loop 4
	{
		Gui, screencap_frame%A_Index%: Destroy
		hwnd_screencap_frame%A_Index% := ""
	}
	screencap_x1 := "", screencap_x2 := "", screencap_y1 := "", screencap_y2 := ""
	Return
}
*/
If WinExist("ahk_id " hwnd_mapinfo_panel) && !mapinfo_switched
{
	LLK_MapInfoClose()
	Return
}
If WinExist("ahk_id " hwnd_cheatsheets_calibration)
{
	Gui, cheatsheets_calibration: Destroy
	hwnd_cheatsheets_calibration := ""
	Return
}
If WinExist("ahk_id " hwnd_gem_notes)
{
	Gui, gem_notes: Destroy
	hwnd_gem_notes := ""
	Return
}
If (update_available = 1)
{
	ToolTip
	update_available := 0
	Return
}
If WinExist("ahk_id " hwnd_itemchecker)
{
	LLK_ItemCheckClose()
	Return
}
If WinExist("ahk_id " hwnd_itemchecker_vendor1)
{
	Loop
	{
		If (hwnd_itemchecker_vendor%A_Index% != "")
		{
			Gui, itemchecker_vendor%A_Index%: Destroy
			hwnd_itemchecker_vendor%A_Index% := ""
		}
		Else Break
	}
	itemchecker_vendor_count := 0
	Return
}
If WinExist("ahk_id " hwnd_map_tracker_log)
{
	LLK_MapTrackGUI()
	Return
}
If WinExist("ahk_id " hwnd_context_menu)
{
	Gui, context_menu: Destroy
	hwnd_context_menu := ""
	Return
}
If WinExist("ahk_id " hwnd_map_tracker) && (map_tracker_display_loot = 1)
{
	map_tracker_display_loot := 0
	LLK_MapTrack()
	Return
}
If WinExist("ahk_id " hwnd_gear_tracker)
{
	LLK_GearTrackerGUI(1)
	GoSub, Log_loop
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
	gear_tracker_limit := 6
	gear_tracker_filter := 1
	WinActivate, ahk_group poe_window
	Return
}
If WinExist("ahk_id " hwnd_delve_grid)
{
	LLK_Overlay("delve_grid", "hide")
	LLK_Overlay("delve_grid2", "hide")
	WinActivate, ahk_group poe_window
	Return
}
If WinActive("ahk_id " hwnd_notepad_edit)
{
	Gui, notepad_edit: Submit, NoHide
	WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
	notepad_width -= xborder*2
	notepad_height -= caption + yborder*2
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	LLK_Overlay("notepad_edit", "hide")
	Return
}
If WinActive("ahk_id " hwnd_recombinator_window)
{
	recombinator_windowGuiClose()
	Return
}
If WinExist("ahk_id " hwnd_legion_treemap) || WinExist("ahk_id " hwnd_legion_window)
{
	Gui, legion_treemap: Destroy
	hwnd_legion_treemap := ""
	Gui, legion_treemap2: Destroy
	hwnd_legion_treemap2 := ""
	Gui, legion_window: Destroy
	hwnd_legion_window := ""
	Gui, legion_list: Destroy
	hwnd_legion_list := ""
	Gui, legion_help: Destroy
	Return
}
If WinExist("ahk_id " hwnd_betrayal_info) || WinExist("ahk_id " hwnd_betrayal_info_members)
{
	WinActivate, ahk_group poe_window
	LLK_Overlay("betrayal_info", "hide")
	If WinExist("ahk_id " hwnd_betrayal_info_overview)
		LLK_Overlay("betrayal_info_overview")
	If WinExist("ahk_id " hwnd_betrayal_info_members)
		LLK_Overlay("betrayal_info_members", "hide")
	If LLK_ImageSearch("betrayal")
		SendInput, {ESC}
	WinActivate, ahk_group poe_window
	Return
}
Else If WinExist("ahk_id " hwnd_map_info_menu)
{
	Gui, map_info_menu: Destroy
	hwnd_map_info_menu := ""
	WinActivate, ahk_group poe_window
	Return
}
Else SendInput, {ESC}
KeyWait, ESC
Return

#If WinExist("ahk_id " hwnd_clone_frames_menu)

F1::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_topleft_x := mouseXpos - xScreenOffSet
clone_frame_new_topleft_y := mouseYpos - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_x, % clone_frame_new_topleft_x
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_y, % clone_frame_new_topleft_y
GoSub, Clone_frames_dimensions
Return

F2::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_width := mouseXpos - clone_frame_new_topleft_x - xScreenOffSet
clone_frame_new_height := mouseYpos - clone_frame_new_topleft_y - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_width, % clone_frame_new_width
GuiControl, clone_frames_menu: Text, clone_frame_new_height, % clone_frame_new_height
GoSub, Clone_frames_dimensions
Return

F3::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_target_x := (mouseXpos + clone_frame_new_width * clone_frame_new_scale_x//100 > xScreenOffset + poe_width) ? poe_width - clone_frame_new_width * clone_frame_new_scale_x//100 : mouseXpos - xScreenOffSet
clone_frame_new_target_y := (mouseYpos + clone_frame_new_height * clone_frame_new_scale_y//100 > yScreenOffset + poe_height) ? poe_height - clone_frame_new_height * clone_frame_new_scale_y//100 : mouseYpos - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_target_x, % clone_frame_new_target_x
GuiControl, clone_frames_menu: Text, clone_frame_new_target_y, % clone_frame_new_target_y
GoSub, Clone_frames_dimensions
Return

#If (horizon_toggle = 1)
	
a::
b::
c::
d::
e::
f::
g::
h::
i::
j::
k::
l::
m::
n::
o::
p::
q::
r::
s::
t::
u::
v::
w::
x::
y::
z::LLK_Omnikey_ToolTip(maps_%A_ThisHotkey%)

#If
	
LLK_TabCheatSheetAll()
{
	global
	cheatsheet_tab_parse := StrReplace(cheatsheet_overlay_active, " ", "_")
	If !FileExist("cheat-sheets\"cheatsheet_overlay_active "\[00]*")
		Return
	
	cheatsheets_include_%cheatsheet_tab_parse%_copy := cheatsheets_include_%cheatsheet_tab_parse%
	cheatsheets_include_%cheatsheet_tab_parse% := ""
	Loop, Files, % "cheat-sheets\"cheatsheet_overlay_active "\[*]*"
	{
		If InStr(A_LoopFileName, "check") || InStr(A_LoopFileName, "sample")
			continue
		cheatsheets_include_%cheatsheet_tab_parse% .= SubStr(A_LoopFileName, 2, 2) ","
	}
	LLK_CheatSheetsImages(cheatsheet_overlay_active)
	KeyWait, % tab_hotkey
	cheatsheets_loaded_images := ""
	cheatsheets_include_%cheatsheet_tab_parse% := cheatsheets_include_%cheatsheet_tab_parse%_copy
	LLK_CheatSheetsImages(cheatsheet_overlay_active)
}

LLK_TabKey()
{
	global
	local start
	If WinExist("ahk_id " hwnd_delve_grid)
	{
		Loop 49
		{
			delve_hidden_nodes := ""
			delve_node%A_Index%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			If (delve_node_%A_Index% = "")
				continue
			delve_node_%A_Index% := ""	
			delve_node_u%A_Index%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_u%A_Index%, % delve_node_u%A_Index%_toggle
			delve_node_r%A_Index%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_r%A_Index%, % delve_node_r%A_Index%_toggle
			delve_node_d%A_Index%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_d%A_Index%, % delve_node_d%A_Index%_toggle
			delve_node_l%A_Index%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_l%A_Index%, % delve_node_l%A_Index%_toggle
		}
		Return
	}
	
	If in_lab
	{
		start := A_TickCount
		While GetKeyState(tab_hotkey, "P")
		{
			If (A_TickCount >= start + 200)
			{
				GoSub, Lab_info
				Return
			}
		}
	}
	
	If WinExist("ahk_id " hwnd_leveling_guide2) && InStr(text2, "(hold tab: img)")
	{
		start := A_TickCount
		While GetKeyState(tab_hotkey, "P")
		{
			If (A_TickCount >= start + 200)
			{
				LLK_LevelGuideImage()
				KeyWait, % tab_hotkey
				Gui, leveling_guide_img: Destroy
				Return
			}
		}
	}
	
	If hwnd_cheatsheet
	{
		start := A_TickCount
		While GetKeyState(tab_hotkey, "P")
		{
			If (A_TickCount >= start + 200)
			{
				Gui, cheatsheet: Show, % (cheatsheet_overlay_type = "advanced") ? "NA xCenter y"yScreenOffSet : "NA"
				cheatsheet_overlay_tab := 1
				KeyWait, % tab_hotkey
				cheatsheet_overlay_tab := 0
				Gui, cheatsheet: Hide
				Return
			}
		}
	}
	If (update_available = 1)
	{
		Run, https://github.com/Lailloken/Lailloken-UI/releases
		ExitApp
		Return
	}
	SendInput, {%tab_hotkey% DOWN}
	KeyWait, % tab_hotkey
	SendInput, {%tab_hotkey% UP}
}