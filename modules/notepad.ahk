Notepad:
If (A_GuiControl = "enable_notepad")
{
	Gui, settings_menu: Submit, NoHide
	
	If (enable_notepad = 0)
	{
		Gui, notepad_sample: Destroy
		hwnd_notepad_sample := ""
		Gui, notepad_edit: Submit, NoHide
		notepad_text := StrReplace(notepad_text, "[", "(")
		notepad_text := StrReplace(notepad_text, "]", ")")
		Gui, notepad_edit: Destroy
		hwnd_notepad_edit := ""
		Gui, notepad: Destroy
		hwnd_notepad := ""
		Loop 100
		{
			Gui, notepad%A_Index%: Destroy
			hwnd_notepad%A_Index% := ""
			Gui, notepad_drag%A_Index%: Destroy
			hwnd_notepad_drag%A_Index% := ""
		}
	}
	IniWrite, %enable_notepad%, ini\config.ini, Features, enable notepad
	GoSub, GUI
	GoSub, Settings_menu
	Return
}
If InStr(A_GuiControl, "button_notepad")
{
	If (A_GuiControl = "button_notepad_minus")
		notepad_panel_offset -= (notepad_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_notepad_reset")
		notepad_panel_offset := 1
	If (A_GuiControl = "button_notepad_plus")
		notepad_panel_offset += (notepad_panel_offset < 1) ? 0.1 : 0
	IniWrite, % notepad_panel_offset, ini\notepad.ini, Settings, button-offset
	notepad_panel_dimensions := poe_width*0.03*notepad_panel_offset
	GoSub, GUI
	Return
}
If (A_GuiControl = "fSize_notepad_minus")
{
	fSize_offset_notepad -= 1
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_notepad_plus")
{
	fSize_offset_notepad += 1
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_notepad_reset")
{
	fSize_offset_notepad := 0
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "notepad_opac_minus")
{
	notepad_trans -= (notepad_trans > 100) ? 30 : 0
	IniWrite, %notepad_trans%, ini\notepad.ini, Settings, transparency
}
If (A_GuiControl = "notepad_opac_plus")
{
	notepad_trans += (notepad_trans < 250) ? 30 : 0
	IniWrite, %notepad_trans%, ini\notepad.ini, Settings, transparency
}
If InStr(A_GuiControl, "fontcolor_")
{
	notepad_fontcolor := StrReplace(A_GuiControl, "fontcolor_", "")
	IniWrite, %notepad_fontcolor%, ini\notepad.ini, Settings, font-color
	/*
	If (StrLen(Clipboard) != 6) && (StrLen(Clipboard) != 7 && !InStr(Clipboard, "#"))
	{
		LLK_ToolTip("invalid rgb-hexcode`nin clipboard", 2)
		Return
	}
	notepad_fontcolor := StrReplace(Clipboard, "#")
	IniWrite, %notepad_fontcolor%, ini\notepad.ini, Settings, font-color
	*/
}

start := A_TickCount
Gui, notepad_edit: Submit, NoHide
While GetKeyState("LButton", "P") && InStr(A_Gui, "notepad")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		If InStr(A_Gui, "notepad_drag")
		{
			notepad_gui := "notepad" StrReplace(A_Gui, "notepad_drag")
			WinGetPos,,, wGui2, hGui2, % "ahk_id " hwnd_%notepad_gui%
		}
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		If InStr(A_GuiControl, "notepad_drag")
		{
			LLK_Overlay(notepad_gui, "show")
			LLK_Overlay(A_Gui, "show")
		}
		Else
		{
			notepad_panel_xpos := panelXpos
			notepad_panel_ypos := panelYpos
			IniWrite, % notepad_panel_xpos, ini\notepad.ini, UI, button xcoord
			IniWrite, % notepad_panel_ypos, ini\notepad.ini, UI, button ycoord
		}
		WinActivate, ahk_group poe_window
		Return
	}
}
If InStr(A_GuiControl, "notepad_drag")
{
	If (A_GuiControl = "notepad_drag_grouped")
	{
		notepad_grouptext := (click = 1) ? (notepad_grouptext > 1) ? notepad_grouptext - 1 : notepad_grouptext : (notepad_grouptext < notepad_notes.Length()) ? notepad_grouptext + 1 : notepad_grouptext
		SetTextAndResize(hwnd_notepad_header, "note " notepad_grouptext "/" notepad_notes.Length() , "s" fSize_notepad, "Fontin SmallCaps")
		SetTextAndResize(hwnd_notepad_text, notepad_notes[notepad_grouptext] , "s" fSize_notepad, "Fontin SmallCaps")
		Gui, notepad: Show, NA Autosize
		WinGetPos, notepad_drag_xPos, notepad_drag_yPos, wDrag, hDrag, ahk_id %hwnd_notepad_drag%
		WinGetPos,,, width, height, ahk_id %hwnd_notepad%
		xPos := (notepad_drag_xPos > xScreenOffSet + poe_width/2) ? notepad_drag_xPos - width + wDrag : notepad_drag_xPos
		yPos := (notepad_drag_yPos > yScreenOffSet + poe_height/2) ? notepad_drag_yPos - height + hDrag : notepad_drag_yPos
		Gui, notepad: Show, % "NA x"xPos " y"yPos
		Gui, notepad_drag: Show, NA
	}
	If (A_GuiControl = "notepad_drag") && (click = 2)
	{
		gui := StrReplace(A_Gui, "notepad_drag")
		LLK_Overlay("notepad" gui, "hide")
		LLK_Overlay("notepad_drag" gui, "hide")
		Gui, notepad%gui%: Destroy
		hwnd_notepad%gui% := ""
		Gui, notepad_drag%gui%: Destroy
		hwnd_notepad_drag%gui% := ""
	}
	WinActivate, ahk_group poe_window
	Return
}
notepad_fontcolor := (notepad_fontcolor = "") ? "White" : notepad_fontcolor
fSize_notepad := fSize0 + fSize_offset_notepad

If InStr(A_GuiControl, "notepad_context_") || InStr(GuiControl_copy, "notepad_context_")
{	
	Gui, notepad_edit: Submit, NoHide
	LLK_Overlay("notepad_edit", "hide")
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	notepad_anchor := poe_height*0.14
	
	If (A_GuiControl = "notepad_context_simple") || (GuiControl_copy = "notepad_context_simple")
	{
		Gui, notepad_drag: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag
		Gui, notepad_drag: Margin, 0, 0
		Gui, notepad_drag: Color, Black
		WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
		Gui, notepad_drag: Font, % "s"fSize_notepad//2, Fontin SmallCaps
		Gui, notepad_drag: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag gNotepad HWNDhwnd_notepad_dragbutton, % "    "
		ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
		
		text := ""
		If InStr(notepad_text, "#")
		{
			text := SubStr(notepad_text, InStr(notepad_text, "#") + 1)
			text := (SubStr(text, 1, 1) = "`n") ? SubStr(text, 2) : text
			text := (SubStr(text, 1, 1) = " ") ? SubStr(text, 2) : text
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
		}
		
		Gui, notepad: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad
		Gui, notepad: Margin, % wDrag + 2, 0
		Gui, notepad: Color, Black
		WinSet, Transparent, %notepad_trans%
		Gui, notepad: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
		Gui, notepad: Add, Text, BackgroundTrans, % (text = "") ? (SubStr(notepad_text, 0) = "`n")? StrReplace(SubStr(notepad_text, 1, -1), "&", "&&") : StrReplace(notepad_text, "&", "&&") : StrReplace(text, "&", "&&")
		Gui, notepad: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		Gui, notepad_drag: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		LLK_Overlay("notepad", "show")
		LLK_Overlay("notepad_drag", "show")
		notepad_edit := 0
		WinActivate, ahk_group poe_window
	}
	If (A_GuiControl = "notepad_context_multi") || (GuiControl_copy = "notepad_context_multi")
	{
		loop := ""
		Loop, Parse, notepad_text, "#", "#"
		{
			If (A_Loopfield = "") || (A_Index = 1)
				continue
			gui := loop
			loop += 1
			Gui, notepad_drag%gui%: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag%gui%
			Gui, notepad_drag%gui%: Margin, 0, 0
			Gui, notepad_drag%gui%: Color, Black
			WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
			Gui, notepad_drag%gui%: Font, % "s"fSize_notepad//2, Fontin SmallCaps
			Gui, notepad_drag%gui%: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag gNotepad HWNDhwnd_notepad_dragbutton, % "    "
			ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
			
			Gui, notepad%gui%: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad%gui%, notepad
			Gui, notepad%gui%: Margin, % wDrag + 2, 0
			Gui, notepad%gui%: Color, Black
			WinSet, Transparent, %notepad_trans%
			Gui, notepad%gui%: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
			text := (SubStr(A_Loopfield, 1, 1) = " ") ? SubStr(A_Loopfield, 2) : A_Loopfield
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
			Gui, notepad%gui%: Add, Text, BackgroundTrans, % StrReplace(text, "&", "&&")
			Gui, notepad%gui%: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
			Gui, notepad_drag%gui%: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
			WinGetPos,,,, height, % "ahk_id " hwnd_notepad%gui%
			notepad_anchor += height*1.1
			
			guilist .= InStr(guilist, "notepad" gui "|") ? "" : "notepad" gui "|"
			guilist .= InStr(guilist, "notepad_drag" gui "|") ? "" : "notepad_drag" gui "|"
			
			LLK_Overlay("notepad" gui, "show")
			LLK_Overlay("notepad_drag" gui, "show")
		}
		notepad_edit := 0
		WinActivate, ahk_group poe_window
	}
	If (A_GuiControl = "notepad_context_grouped") || (GuiControl_copy = "notepad_context_grouped")
	{
		loop := 0
		notepad_notes := []
		Loop, Parse, notepad_text, "#", "#"
		{
			If (A_LoopField = "") || (A_Index = 1)
				continue
			loop += 1
			text := (SubStr(A_Loopfield, 1, 1) = " ") ? SubStr(A_Loopfield, 2) : A_Loopfield
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
			notepad_notes.Push(text)
		}
		Gui, notepad_drag: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag
		Gui, notepad_drag: Margin, 0, 0
		Gui, notepad_drag: Color, Black
		WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
		Gui, notepad_drag: Font, % "s"fSize_notepad//2, Fontin SmallCaps
		Gui, notepad_drag: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag_grouped gNotepad HWNDhwnd_notepad_dragbutton, % "    "
		ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
		
		Gui, notepad: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad
		Gui, notepad: Margin, % wDrag + 2, 0
		Gui, notepad: Color, Black
		WinSet, Transparent, %notepad_trans%
		Gui, notepad: Font, c%notepad_fontcolor% s%fSize_notepad% underline, Fontin SmallCaps
		Gui, notepad: Add, Text, BackgroundTrans HWNDhwnd_notepad_header, % "note 1/" loop
		Gui, notepad: Font, norm
		Gui, notepad: Add, Text, BackgroundTrans HWNDhwnd_notepad_text y+0, % StrReplace(notepad_notes[1], "&", "&&")
		Gui, notepad: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		Gui, notepad_drag: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		LLK_Overlay("notepad", "show")
		LLK_Overlay("notepad_drag", "show")
		notepad_edit := 0
		notepad_grouptext := 1
		WinActivate, ahk_group poe_window
	}
	GuiControl_copy := ""
	Return
}

If (A_Gui = "settings_menu")
{
	Gui, notepad_edit: Submit, NoHide
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	Loop
	{
		If !LLK_hwnd("hwnd_notepad")
			break
		If (A_Index = 1)
		{
			Gui, notepad: Destroy
			hwnd_notepad := ""
			Gui, notepad_drag: Destroy
			hwnd_notepad_drag := ""
		}
		Gui, notepad%A_Index%: Destroy
		hwnd_notepad%A_Index% := ""
		Gui, notepad_drag%A_Index%: Destroy
		hwnd_notepad_drag%A_Index% := ""
	}
	Gui, notepad_sample: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_notepad_sample, Lailloken UI: overlay-text preview
	Gui, notepad_sample: Margin, 12, 4
	Gui, notepad_sample: Color, Black
	WinSet, Transparent, %notepad_trans%
	Gui, notepad_sample: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
	Gui, notepad_sample: Add, Text, BackgroundTrans, this is what text-`nwidgets look like with`nthe current settings
	Gui, notepad_sample: Show, % "NA AutoSize"
	WinGetPos,,, win_width, win_height, ahk_id %hwnd_notepad_sample%
	Gui, notepad_sample: Show, % "Hide AutoSize x"xScreenOffSet + poe_width/2 - win_width/2 " y"yScreenOffSet
	LLK_Overlay("notepad_sample", "show")
	Return
}

If (click = 2) || (!WinExist("ahk_id " hwnd_notepad_edit) && !LLK_hwnd("hwnd_notepad"))
{
	If !WinExist("ahk_id " hwnd_notepad_edit) && (click = 2) && !LLK_WinExist("hwnd_notepad")
	{
		WinActivate, ahk_group poe_window
		Return
	}
	If WinExist("ahk_id " hwnd_notepad_edit)
	{
		Gui, notepad_edit: Submit, NoHide
		WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
		notepad_width -= xborder*2
		notepad_height -= caption + yborder*2
		notepad_text := StrReplace(notepad_text, "[", "(")
		notepad_text := StrReplace(notepad_text, "]", ")")
	}
	If (notepad_text != "") || !WinExist("ahk_id " hwnd_notepad_edit)
	{
		If (notepad_edit = 0) || !WinExist("ahk_id " hwnd_notepad_edit)
		{
			Loop
			{
				If (A_Index = 1)
				{
					Gui, notepad: Destroy
					hwnd_notepad := ""
					Gui, notepad_drag: Destroy
					hwnd_notepad_drag := ""
				}
				If (hwnd_notepad%A_Index% = "")
					break
				Gui, notepad%A_Index%: Destroy
				hwnd_notepad%A_Index% := ""
				Gui, notepad_drag%A_Index%: Destroy
				hwnd_notepad_drag%A_Index% := ""
			}
			;LLK_Overlay("notepad_drag", "hide")
			Gui, notepad_edit: New, -DPIScale +Resize +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_notepad_edit, Lailloken-UI: notepad
			Gui, notepad_edit: Margin, 12, 4
			Gui, notepad_edit: Color, Black
			WinSet, Transparent, 220
			Gui, notepad_edit: Font, cBlack s%fSize_notepad%, Fontin SmallCaps
			Gui, notepad_edit: Add, Edit, x0 y0 w1000 h1000 vnotepad_text Lowercase, %notepad_text%
			Gui, notepad_edit: Show, % "x"xScreenOffset + poe_width/2 - notepad_width/2 " y"yScreenOffset + poe_height/2 - notepad_height/2 " w"notepad_width " h"notepad_height
			SendInput, {Right}
			LLK_Overlay("notepad_edit", "show")
			notepad_edit := 1
		}
		Else
		{
			If LLK_InStrCount(notepad_text, "#")
			{
				MouseGetPos, mouseXpos, mouseYpos
				Gui, notepad_contextmenu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_notepad_contextmenu
				Gui, notepad_contextmenu: Margin, 4, 2
				Gui, notepad_contextmenu: Color, Black
				WinSet, Transparent, %trans%
				Gui, notepad_contextmenu: Font, s%fSize0% cWhite, Fontin SmallCaps
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_simple gNotepad BackgroundTrans Center, simple
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_multi gNotepad BackgroundTrans Center, multi
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_grouped gNotepad BackgroundTrans Center, grouped
				Gui, notepad_contextmenu: Show, NA
				WinGetPos,,, width, height, ahk_id %hwnd_notepad_contextmenu%
				mouseXpos := (mouseXpos + width > xScreenOffSet + poe_width) ? xScreenOffset + poe_width - width : mouseXpos
				mouseYpos := (mouseYpos + height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - height : mouseYpos
				Gui, notepad_contextmenu: Show, % "x"mouseXpos " y"mouseYpos
				WinWaitNotActive, ahk_id %hwnd_notepad_contextmenu%
				Gui, notepad_contextmenu: destroy
			}
			Else
			{
				GuiControl_copy := "notepad_context_simple"
				GoSub, Notepad
				Return
			}
		}
	}
	Return
}

If WinExist("ahk_id " hwnd_notepad_edit)
{
	If (notepad_edit != 0)
	{
		WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
		notepad_width -= xborder*2
		notepad_height -= caption + yborder*2
	}
	Gui, notepad: Submit, NoHide
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	If (notepad_edit = 1)
		LLK_Overlay("notepad_edit", "hide")
}
Else
{
	If LLK_WinExist("hwnd_notepad")
	{
		Loop 100
		{
			If (A_Index = 1) && (hwnd_notepad != "")
			{
				LLK_Overlay("notepad", "hide")
				LLK_Overlay("notepad_drag", "hide")
			}
			If (hwnd_notepad%A_Index% != "")
			{
				LLK_Overlay("notepad" A_Index, "hide")
				LLK_Overlay("notepad_drag" A_Index, "hide")
			}
		}
		WinActivate, ahk_group poe_window
	}
	Else
	{
		Loop 100
		{
			If (A_Index = 1) && (hwnd_notepad != "")
			{
				LLK_Overlay("notepad", "show")
				LLK_Overlay("notepad_drag", "show")
			}
			If (hwnd_notepad%A_Index% != "")
			{
				LLK_Overlay("notepad" A_Index, "show")
				LLK_Overlay("notepad_drag" A_Index, "show")
			}
		}
	}
}
WinActivate, ahk_group poe_window
Return

Init_notepad:
IniRead, notepad_width, ini\notepad.ini, UI, width, 400
IniRead, notepad_height, ini\notepad.ini, UI, height, 400
IniRead, notepad_text, ini\notepad.ini, Text, text, %A_Space%
If (notepad_text != "")
	notepad_text := StrReplace(notepad_text, ",,", "`n")
IniRead, fSize_offset_notepad, ini\notepad.ini, Settings, font-offset, 0
IniRead, notepad_fontcolor, ini\notepad.ini, Settings, font-color, White
IniRead, notepad_trans, ini\notepad.ini, Settings, transparency, 250
IniRead, notepad_panel_offset, ini\notepad.ini, Settings, button-offset, 1
notepad_panel_dimensions := poe_width*0.03*notepad_panel_offset
IniRead, notepad_panel_xpos, ini\notepad.ini, UI, button xcoord, % A_Space
If !notepad_panel_xpos
	notepad_panel_xpos := poe_width/2 - (notepad_panel_dimensions + 2)/2
IniRead, notepad_panel_ypos, ini\notepad.ini, UI, button ycoord, % A_Space
If !notepad_panel_ypos
	notepad_panel_ypos := poe_height - (notepad_panel_dimensions + 2)
Return

notepad_editGuiClose()
{
	global
	If WinExist("ahk_id " hwnd_notepad_edit)
	{
		If (notepad_edit != 0)
		{
			WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
			notepad_width -= xborder*2
			notepad_height -= caption + yborder*2
		}
		Gui, notepad_edit: Submit, NoHide
		notepad_text := StrReplace(notepad_text, "[", "(")
		notepad_text := StrReplace(notepad_text, "]", ")")
		Gui, notepad_edit: Destroy
		hwnd_notepad_edit := ""
	}
}