Stash_search:
If (A_Gui != "") || (stash_search_trigger = 1)
{
	If (stash_search_trigger != 1)
	{
		string_number := (click = 2) ? 2 : 1
		IniRead, stash_search_string, ini\stash search.ini, % StrReplace(A_GuiControl, " ", "_"), string %string_number%
		IniRead, stash_search_scroll, ini\stash search.ini, % StrReplace(A_GuiControl, " ", "_"), string %string_number% enable scrolling, 0
		KeyWait, LButton
		Gui, stash_search_context_menu: Destroy
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
	}
	Else
	{
		IniRead, stash_search_string, ini\stash search.ini, % Loopfield_copy, string 1
		IniRead, stash_search_scroll, ini\stash search.ini, % Loopfield_copy, string 1 enable scrolling, 0
	}
	
	Loop
	{
		If (scrollboard%A_Index% != "")
			scrollboard%A_Index% := ""
		Else break
	}
	
	If InStr(stash_search_string, ";")
	{
		scrollboards := 0
		Loop, Parse, stash_search_string, `;, `;
		{
			If (A_Loopfield = "")
				continue
			scrollboard%A_Index% := A_Loopfield
			scrollboards += 1
		}
		scrollboard_active := 1
	}
	
	clipboard := (scrollboard1 = "") ? stash_search_string : scrollboard1
	ClipWait, 0.05
	SendInput, ^{f}^{v}
	If (stash_search_scroll = 1)
	{
		SetTimer, Stash_search_scroll, 100
		stash_search_scroll_mode := 1
	}
	Return
}
MouseGetPos, mouseXpos, mouseYpos
Gui, stash_search_context_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_stash_search_context_menu
Gui, stash_search_context_menu: Margin, 4, 2
Gui, stash_search_context_menu: Color, Black
WinSet, Transparent, %trans%
Gui, stash_search_context_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

IniRead, stash_search_shortcuts, ini\stash search.ini, Settings, % stash_search_type, % A_Space
stash_search_shortcuts_enabled := 0
enabled_shortcuts := ""

Loop, Parse, stash_search_shortcuts, `,,`,
{
	If (A_Loopfield = "")
		continue
	Loopfield_copy := StrReplace(SubStr(A_Loopfield, 2, -1), "|", "vertbar")
	IniRead, stash_search_%Loopfield_copy%_enabled, ini\stash search.ini, % StrReplace(Loopfield_copy, "vertbar", "|"), enable, 0
	stash_search_shortcuts_enabled += stash_search_%Loopfield_copy%_enabled
	enabled_shortcuts .= (stash_search_%Loopfield_copy%_enabled = 1) ? Loopfield_copy "," : ""
}
If (stash_search_shortcuts = "" || stash_search_shortcuts_enabled < 1)
{
	LLK_ToolTip("no strings for this search")
	Return
}

If (stash_search_shortcuts_enabled = 1) ;if only one search-string is enabled, check whether it has two strings
{
	Loopfield_copy := StrReplace(SubStr(enabled_shortcuts, 1, -1), "vertbar", "|")
	IniRead, parse_secondary_click, ini\stash search.ini, % Loopfield_copy, string 2
	If (parse_secondary_click = "")
	{
		Gui, stash_search_context_menu: Destroy
		hwnd_stash_search_context_menu := ""
		stash_search_trigger := 1
		GoSub, Stash_search
		stash_search_trigger := 0
		Return
	}
}

Loop, Parse, stash_search_shortcuts, `,, `,
{
	If (A_LoopField = "")
		continue
	Loopfield_copy := StrReplace(SubStr(A_Loopfield, 2, -1), "|", "vertbar")
	If (stash_search_%Loopfield_copy%_enabled = 1)
		Gui, stash_search_context_menu: Add, Text, gStash_search BackgroundTrans Center, % StrReplace(SubStr(A_LoopField, 2, -1), "_", " ")
}

Gui, Show, x%mouseXpos% y%mouseYpos%
WinWaitActive, ahk_group poe_window
If WinExist("ahk_id " hwnd_stash_search_context_menu)
	Gui, stash_search_context_menu: destroy
Return

Stash_search_apply:
Gui, settings_menu: Submit, NoHide
GuiControl_copy := StrReplace(A_GuiControl, "stash_search_")
GuiControl_copy := StrReplace(GuiControl_copy, "_enable")
GuiControl_copy := StrReplace(GuiControl_copy, "vertbar", "|")
IniWrite, % %A_GuiControl%, ini\stash search.ini, % GuiControl_copy, enable
Return

Stash_search_delete:
delete_string := StrReplace(A_GuiControl, "delete_", "")
delete_string := StrReplace(delete_string, " ", "_")
delete_string := StrReplace(delete_string, "vertbar", "|")
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, stash_search_%A_Loopfield%_parse, ini\stash search.ini, Settings, % A_Loopfield
	If InStr(stash_search_%A_Loopfield%_parse, "(" delete_string "),")
		IniWrite, % StrReplace(stash_search_%A_Loopfield%_parse, "(" delete_string "),"), ini\stash search.ini, Settings, % A_Loopfield
}
IniDelete, ini\stash search.ini, %delete_string%
new_stash_search_menu_closed := 1
GoSub, Settings_menu
Return

Stash_search_new:
Gui, settings_menu: Submit
LLK_Overlay("settings_menu", "hide")

If (stash_search_edit_mode = 1)
{
	edit_name := StrReplace(A_GuiControl, "edit_", "")
	edit_name := StrReplace(edit_name, "vertbar", "|")
	Loop, Parse, stash_search_usecases, `,, `,
	{
		IniRead, stash_search_%A_LoopField%_parse, ini\stash search.ini, Settings, % A_LoopField
		stash_search_edit_use_%A_Loopfield% := InStr(stash_search_%A_LoopField%_parse, edit_name) ? 1 : 0
	}
	IniRead, stash_search_edit_scroll1, ini\stash search.ini, % edit_name, string 1 enable scrolling, 0
	IniRead, stash_search_edit_string1, ini\stash search.ini, % edit_name, string 1, % A_Space
	IniRead, stash_search_edit_scroll2, ini\stash search.ini, % edit_name, string 2 enable scrolling, 0
	IniRead, stash_search_edit_string2, ini\stash search.ini, % edit_name, string 2, % A_Space
	stash_search_edit_mode := 0
}
Else
{
	edit_name := ""
	Loop, Parse, stash_search_usecases, `,, `,
		stash_search_edit_use_%A_Loopfield% := 0
	stash_search_edit_scroll1 := 0
	stash_search_edit_scroll2 := 0
	stash_search_edit_string1 := ""
	stash_search_edit_string2 := ""
}


Gui, stash_search_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_stash_search_menu, Lailloken UI: search-strings configuration
Gui, stash_search_menu: Color, Black
Gui, stash_search_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, stash_search_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

Gui, stash_search_menu: Add, Text, Section BackgroundTrans HWNDmain_text, % "unique search name: "
ControlGetPos,,, width,,, ahk_id %main_text%

Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack lowercase vStash_search_new_name wp", % StrReplace(edit_name, "_", " ")

Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0, % "use-cases: "
Loop, Parse, stash_search_usecases, `,, `,
{
	If (A_Index = 1 || A_Index = 5)
		Gui, stash_search_menu: Add, Checkbox, % "xs Section BackgroundTrans vStash_search_use_" A_Loopfield " w"width/2 " Checked"stash_search_edit_use_%A_Loopfield%, % A_Loopfield
	Else Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_use_" A_Loopfield " w"width/2 " Checked"stash_search_edit_use_%A_Loopfield%, % A_Loopfield
}

Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0, % "search string 1:"
Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_new_scroll Checked"stash_search_edit_scroll1, enable scrolling
Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "xs Section hp BackgroundTrans lowercase cBlack vStash_search_new_string w"width*2, % stash_search_edit_string1
Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0, % "search string 2:"
Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_new_scroll1 Checked"stash_search_edit_scroll2, enable scrolling
Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "xs Section hp BackgroundTrans lowercase cBlack vStash_search_new_string1 w"width*2, % stash_search_edit_string2
Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, xs Section Border BackgroundTrans vStash_search_save gStash_search_save y+%fSize0%, % " save && close "
Gui, stash_search_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vStash_search_new_help hp w-1", img\GUI\help.png

Gui, stash_search_menu: Show, % "Hide Center"
LLK_Overlay("stash_search_menu", "show", 0)
Return

Stash_search_menuGuiClose:
new_stash_search_menu_closed := 1
GoSub, Settings_menu
Gui, stash_search_menu: Destroy
Return

Stash_search_preview_list:
MouseGetPos, mouseXpos, mouseYpos
GuiControl_copy := StrReplace(A_GuiControl, " ", "_")
If (click = 2)
{
	GuiControl_copy := StrReplace(GuiControl_copy, "|", "vertbar")
	Gui, stash_search_context_menu: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_stash_search_context_menu
	Gui, stash_search_context_menu: Margin, % fSize0//2, fSize0//2
	Gui, stash_search_context_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, stash_search_context_menu: Font, cWhite s%fSize0%, Fontin SmallCaps
	stash_search_edit_mode := 1
	Gui, stash_search_context_menu: Add, Text, Section BackgroundTrans vEdit_%GuiControl_copy% gStash_search_new, edit
	Gui, stash_search_context_menu: Add, Text, % "xs BackgroundTrans vDelete_" GuiControl_copy " gStash_search_delete y+"fSize0//2, delete
	Gui, stash_search_context_menu: Show, % "AutoSize x"mouseXpos + fSize0 " y"mouseYpos + fSize0
	WinWaitNotActive, ahk_id %hwnd_stash_search_context_menu%
	stash_search_edit_mode := 0
	Gui, stash_search_context_menu: Destroy
	Return
}
Gui, stash_search_preview_list: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +Border HWNDhwnd_stash_search_preview_list
Gui, stash_search_preview_list: Margin, % 12, 4
Gui, stash_search_preview_list: Color, Black
WinSet, Transparent, %trans%
Gui, stash_search_preview_list: Font, cWhite s%fSize0%, Fontin SmallCaps

use_case := ""
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, stash_search_%A_Loopfield%_parse, ini\stash search.ini, Settings, % A_Loopfield
	use_case := InStr(stash_search_%A_Loopfield%_parse, GuiControl_copy) ? use_case A_Loopfield "," : use_case
}
use_case := (SubStr(use_case, 0) = ",") ? SubStr(use_case, 1, -1) : use_case
IniRead, primary_string, ini\stash search.ini, % GuiControl_copy, string 1, % A_Space
IniRead, secondary_string, ini\stash search.ini, % GuiControl_copy, string 2, % A_Space
secondary_string := (secondary_string = "") ? "" : "`nstring 2: " secondary_string
Gui, stash_search_preview_list: Add, Text, Section BackgroundTrans, % "use-cases: " StrReplace(use_case, ",", ", ") "`nstring 1: " primary_string secondary_string
Gui, stash_search_preview_list: Show, NA x%mouseXpos% y%mouseYpos%
KeyWait, LButton
Gui, stash_search_preview_list: Destroy
Return

Stash_search_scroll:
ToolTip, % "              scrolling...`n              ESC to exit",,, 11
KeyWait, ESC, D T0.05
If !ErrorLevel
{
	SetTimer, stash_search_scroll, delete
	ToolTip,,,, 11
	stash_search_scroll_mode := 0
}
Return

Stash_search_save:
Gui, stash_search_menu: Submit, NoHide
stash_search_new_name_first_letter := SubStr(stash_search_new_name, 1, 1)
checkbox_sum := 0
If (stash_search_new_name = "")
{
	LLK_ToolTip("enter a name")
	Return
}
Loop, Parse, stash_search_usecases, `,, `,
	checkbox_sum += stash_search_use_%A_Loopfield%
If (checkbox_sum = 0)
{
	LLK_ToolTip("set at least one use-case")
	Return
}
If (stash_search_new_string = "") && (stash_search_new_string1 = "")
{
	LLK_ToolTip("enter a string")
	Return
}
If (stash_search_new_string = "") && (stash_search_new_string1 != "")
{
	LLK_ToolTip("first string is empty, but second is not")
	Return
}
If (stash_search_new_name = "settings")
{
	LLK_ToolTip("The selected name is not allowed.`nPlease choose a different name.", 3)
	GuiControl, stash_search_menu: Text, stash_search_new_name,
	Return
}
If stash_search_new_name_first_letter is not alnum
{
	LLK_ToolTip("Unsupported first character in frame-name detected.`nPlease choose a different name.", 3)
	GuiControl, stash_search_menu: Text, stash_search_new_name,
	Return
}

Loop 2
{
	loop := A_Index
	string_mod := (A_Index = 1) ? "" : 1
	If (stash_search_new_scroll%string_mod% = 1)
	{
		parse_string := ""
		numbers := 0
		Loop, Parse, stash_search_new_string%string_mod%
		{
			If A_Loopfield is number
				parse_string := (parse_string = "") ? A_Loopfield : parse_string A_Loopfield
			Else parse_string := (parse_string = "") ? "," : parse_string ","
		}
		If !InStr(stash_search_new_string%string_mod%, ";")
		{
			Loop, Parse, parse_string, `,, `,
			{
				If A_Loopfield is number
					numbers += 1
				If (numbers > 1)
				{
					LLK_ToolTip("cannot scroll:`nstring " loop " has more than`none number", 2)
					Return
				}
			}
		}
		If (numbers = 0) && !InStr(stash_search_new_string%string_mod%, ";")
		{
			LLK_ToolTip("cannot scroll string " loop ":`nno number or semi-colon")
			Return
		}
	}
}

stash_search_new_name_save := ""
Loop, Parse, stash_search_new_name
{
	If (A_LoopField = A_Space)
		add_character := "_"
	Else If (A_Loopfield = "|")
		add_character := "|"
	Else If A_LoopField is not alnum
		add_character := "_"
	Else add_character := A_LoopField
	stash_search_new_name_save := (stash_search_new_name_save = "") ? add_character : stash_search_new_name_save add_character
}

usecases := ""
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, ThisUsecase, ini\stash search.ini, Settings, % A_Loopfield
	If (stash_search_use_%A_Loopfield% = 1) && !InStr(ThisUsecase, "(" stash_search_new_name_save "),")
		IniWrite, % ThisUsecase "(" stash_search_new_name_save "),", ini\stash search.ini, Settings, % A_Loopfield
	Else If (stash_search_use_%A_Loopfield% = 0) && InStr(ThisUsecase, "(" stash_search_new_name_save "),")
		IniWrite, % StrReplace(ThisUsecase, "(" stash_search_new_name_save "),"), ini\stash search.ini, Settings, % A_Loopfield
}

stash_search_new_string := (SubStr(stash_search_new_string, 0) = ";") ? SubStr(stash_search_new_string, 1, -1) : stash_search_new_string
stash_search_new_string := StrReplace(stash_search_new_string, ";;", ";")
stash_search_new_string1 := (SubStr(stash_search_new_string1, 0) = ";") ? SubStr(stash_search_new_string1, 1, -1) : stash_search_new_string1
stash_search_new_string1 := StrReplace(stash_search_new_string1, ";;", ";")
IniWrite, 1, ini\stash search.ini, % stash_search_new_name_save, enable
IniWrite, "%stash_search_new_string%", ini\stash search.ini, % stash_search_new_name_save, string 1
IniWrite, % stash_search_new_scroll, ini\stash search.ini, % stash_search_new_name_save, string 1 enable scrolling
IniWrite, "%stash_search_new_string1%", ini\stash search.ini, % stash_search_new_name_save, string 2
IniWrite, % stash_search_new_scroll1, ini\stash search.ini, % stash_search_new_name_save, string 2 enable scrolling
GoSub, settings_menu
Gui, stash_search_menu: Destroy
Return

Init_searchstrings:
If !FileExist("ini\stash search.ini")
	IniWrite, stash=`nvendor=, ini\stash search.ini, Settings
IniRead, stash_search_check, ini\stash search.ini, Settings
Loop, Parse, stash_search_usecases, `,, `,
{
	If !InStr(stash_search_check, A_Loopfield "=")
		IniWrite, % A_Space, ini\stash search.ini, Settings, % A_Loopfield
}
Return