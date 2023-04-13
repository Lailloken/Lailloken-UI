Init_cheatsheets:
cheatsheets_enabled := [], cheatsheets_list := [], cheatsheets_panel_colors_default := ["Lime", "Yellow", "Red", "Aqua"], cheatsheets_advanced_count := 0
cheatsheets_omnikey_alt := 0, cheatsheets_omnikey_ctrl := 0, cheatsheets_omnikey_shift := 0, cheatsheets_panel_colors := ["Lime", "Yellow", "Red", "Aqua"], cheatsheets_panel_colors[0] := "White"
Loop 4
{
	IniRead, cheatsheet_panel_color, ini\cheat-sheets.ini, UI, rank %A_Index% color, %A_Space%
	If cheatsheet_panel_color
		cheatsheets_panel_colors[A_Index] := cheatsheet_panel_color
}
IniRead, cheatsheets_omnikey_modifier, ini\cheat-sheets.ini, settings, modifier-key, alt
IniRead, fSize_cheatsheets, ini\cheat-sheets.ini, settings, font size, % fSize0
LLK_FontSize(fSize_cheatsheets, font_height_cheatsheets, font_width_cheatsheets)
IniRead, features_enable_cheatsheets, ini\config.ini, Features, enable cheat-sheets, 0
If !InStr("alt,ctrl,shift", cheatsheets_omnikey_modifier)
	cheatsheets_omnikey_modifier := "alt"
cheatsheets_omnikey_%cheatsheets_omnikey_modifier% := 1
Loop, Files, cheat-sheets\*, D
	cheatsheets_list.Push(A_LoopFileName)
Loop, % cheatsheets_list.Length()
{
	index_copy := A_Index
	cheatsheets_parse := StrReplace(cheatsheets_list[A_Index], " ", "_")
	IniRead, cheatsheets_enable_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, enable, 1
	IniRead, cheatsheets_searchtype_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, image search, static
	IniRead, cheatsheets_type_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, type, images
	IniRead, cheatsheets_scale_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", UI, scale, 1
	IniRead, cheatsheets_pos_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", UI, position, % "2,2"
	IniRead, cheatsheets_searchcoords_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", image search, last coordinates, % A_Space
	IniRead, cheatsheets_activation_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, activation, hold
	If (cheatsheets_type_%cheatsheets_parse% = "advanced")
	{
		cheatsheets_advanced_count += 1
		IniRead, cheatsheets_imgvariation_%cheatsheets_parse%_ini, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, image search variation, 0
		cheatsheets_imgvariation_%cheatsheets_parse% := cheatsheets_imgvariation_%cheatsheets_parse%_ini
		IniRead, cheatsheets_objects_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", objects,, % A_Space
		Loop, Parse, cheatsheets_objects_%cheatsheets_parse%, `n
		{
			If (A_Index = 1)
				cheatsheets_objects_%cheatsheets_parse% := ""
			cheatsheets_objects_%cheatsheets_parse% .= SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1) "`n"
		}
		If (SubStr(cheatsheets_objects_%cheatsheets_parse%, 0) = "`n")
			cheatsheets_objects_%cheatsheets_parse% := SubStr(cheatsheets_objects_%cheatsheets_parse%, 1, -1)
		
		Sort, cheatsheets_objects_%cheatsheets_parse%
		Loop, Parse, cheatsheets_objects_%cheatsheets_parse%, `n
		{
			If (A_Index = 1)
				cheatsheets_objects_%cheatsheets_parse% := []
			If (A_Index = "")
				continue
			cheatsheets_objects_%cheatsheets_parse%.Push(A_LoopField)
			cheatsheets_parse1 := StrReplace(A_LoopField, " ", "_")
			Loop 4
			{
				IniRead, cheatsheets_rank_%cheatsheets_parse1%_panel%A_Index%, % "cheat-sheets\" cheatsheets_list[index_copy] "\info.ini", % A_LoopField, panel %A_Index% rank, 0
				IniRead, cheatsheets_%cheatsheets_parse%_object_%cheatsheets_parse1%_panel%A_Index%, % "cheat-sheets\" cheatsheets_list[index_copy] "\info.ini", % A_LoopField, panel %A_Index%, % A_Space
				cheatsheets_%cheatsheets_parse%_object_%cheatsheets_parse1%_panel%A_Index% := StrReplace(cheatsheets_%cheatsheets_parse%_object_%cheatsheets_parse1%_panel%A_Index%, "^^^", "`n")
			}
		}
		If !IsObject(cheatsheets_objects_%cheatsheets_parse%)
			cheatsheets_objects_%cheatsheets_parse% := []
	}
	If (cheatsheets_type_%cheatsheets_parse% = "app")
		IniRead, cheatsheets_apptitle_%cheatsheets_parse%, % "cheat-sheets\" cheatsheets_list[A_Index] "\info.ini", general, app title, % A_Space
	If cheatsheets_enable_%cheatsheets_parse% && !LLK_ArrayHasVal(cheatsheets_enabled, cheatsheets_parse)
		cheatsheets_enabled.Push(cheatsheets_parse)
}
Return

Cheatsheets:
If WinExist("ahk_id " hwnd_settings_menu)
	Gui, settings_menu: Submit, NoHide
If WinExist("ahk_id " hwnd_cheatsheets_menu)
	Gui, cheatsheets_menu: Submit, NoHide
If (A_GuiControl = "features_enable_cheatsheets")
{
	If !FileExist("cheat-sheets\")
	{
		FileCreateDir, cheat-sheets\
		sleep, 250
	}
	If !FileExist("cheat-sheets\")
	{
		LLK_FilePermissionError("create")
		GuiControl, settings_menu:, % A_GuiControl, 0
		Return
	}
	IniWrite, % %A_GuiControl%, ini\config.ini, Features, enable cheat-sheets
	If (%A_GuiControl% = 0)
	{
		LLK_CheatSheetsClose()
		Gui, cheatsheet: Destroy
		hwnd_cheatsheet := ""
		cheatsheet_overlay_type := ""
	}
	GoSub, Settings_menu
	Return
}
If cheatsheets_omni_trigger
{
	cheatsheets_omni_trigger := 0
	LLK_CheatSheetsClose()
	pHaystack_cheatsheets := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	cheatsheet_triggered1 := "", cheatsheet_triggered := ""
	cheatsheet_toggle_check := (GetKeyState("Shift", "P") + GetKeyState("Alt", "P") + GetKeyState("Ctrl", "P"))
	rAdvanced := ""
	Loop, % cheatsheets_enabled.Length()
	{
		If LLK_SheetSearch(StrReplace(cheatsheets_enabled[A_Index], "_", " "))
		{
			cheatsheet_triggered1 := cheatsheets_enabled[A_Index], cheatsheet_triggered := StrReplace(cheatsheet_triggered1, "_", " ")
			Switch cheatsheets_type_%cheatsheet_triggered1%
			{
				Case "images":
					LLK_CheatSheetsImages(StrReplace(cheatsheets_enabled[A_Index], "_", " "))
					If (cheatsheets_activation_%cheatsheet_triggered1% = "hold") && (cheatsheet_toggle_check < 2)
					{	
						While GetKeyState(cheatsheets_hotkey, "P")
							Sleep 50
						LLK_CheatSheetsClose()
					}
				Case "app":
					LLK_CheatSheetsApp(StrReplace(cheatsheets_enabled[A_Index], "_", " "))
				Case "advanced":
					rAdvanced := LLK_CheatSheetsAdvanced(StrReplace(cheatsheets_enabled[A_Index], "_", " "))
			}
			Break
		}
	}
	Gdip_DisposeImage(pHaystack_cheatsheets)
	If !rAdvanced
		Return
}
;################################################################## cheat-sheet configuration (images): long-clicking the <preview> button
If (A_GuiControl = "cheatsheets_menu_preview")
{
	cheatsheet_triggered := cheatsheet_selected, cheatsheet_triggered1 := cheatsheet_selected1
	LLK_CheatSheetsImages(cheatsheet_selected)
	KeyWait, LButton
	LLK_CheatSheetsClose()
	Return
}
;################################################################## cheat-sheet configuration (advanced): long-clicking the <preview> button
If (A_GuiControl = "cheatsheets_edit_panelpreview")
{
	Loop 4
		cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
	cheatsheet_triggered := cheatsheet_selected, cheatsheet_triggered1 := cheatsheet_selected1
	LLK_CheatSheetsAdvanced(cheatsheet_selected, cheatsheet_object_selected)
	Return
}
;################################################################## screen-check calibration (advanced): picking an entry in the ddl
If InStr(A_GuiControl, "cheatsheets_calibration_save")
{
	Gui, cheatsheets_calibration: Submit, NoHide
	While (SubStr(cheatsheets_calibration_choice, 1, 1) = " ")
		cheatsheets_calibration_choice := SubStr(cheatsheets_calibration_choice, 2)
	While (SubStr(cheatsheets_calibration_choice, 0) = " ")
		cheatsheets_calibration_choice := SubStr(cheatsheets_calibration_choice, 1, -1)
	If (cheatsheets_calibration_choice = "")
	{
		LLK_ToolTip("object-name cannot be blank", 1.5)
		Return
	}
	If InStr(",general,ui,image search,objects", "," cheatsheets_calibration_choice ",")
	{
		LLK_ToolTip("object-name prohibited", 1.5)
		Return
	}
	Return
}
;################################################################## settings menu: clicking a text-sample to apply an RGB-code
If InStr(A_GuiControl, "cheatsheets_color_picker")
{
	If (click = 1)
	{
		If (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#")
			Clipboard := SubStr(Clipboard, 2)
		
		If (StrLen(Clipboard) != 6)
		{
			LLK_ToolTip("invalid rgb-code in clipboard", 1.5)
			Return
		}
		GuiControl, settings_menu: +c%Clipboard%, % A_GuiControl
		IniWrite, % Clipboard, ini\cheat-sheets.ini, UI, % "rank " StrReplace(A_GuiControl, "cheatsheets_color_picker") " color"
		cheatsheets_panel_colors[StrReplace(A_GuiControl, "cheatsheets_color_picker")] := Clipboard
	}
	Else
	{
		cheatsheets_panel_colors[StrReplace(A_GuiControl, "cheatsheets_color_picker")] := cheatsheets_panel_colors_default[StrReplace(A_GuiControl, "cheatsheets_color_picker")]
		IniDelete, ini\cheat-sheets.ini, UI, % "rank " StrReplace(A_GuiControl, "cheatsheets_color_picker") " color"
		GuiControl, % "settings_menu: +c"cheatsheets_panel_colors[StrReplace(A_GuiControl, "cheatsheets_color_picker")], % A_GuiControl
	}
	GuiControl, settings_menu: movedraw, % A_GuiControl
	Return
}
;################################################################## settings menu: clicking a resize button
If InStr(A_GuiControl, "cheatsheets_fontsize_")
{
	If InStr(A_GuiControl, "minus")
		fSize_cheatsheets -= (fSize_cheatsheets > 8) ? 1 : 0
	If InStr(A_GuiControl, "reset")
		fSize_cheatsheets := fSize0
	If InStr(A_GuiControl, "plus")
		fSize_cheatsheets += 1
	SetTimer, LLK_CheatSheetsFontPreview, -1
	LLK_FontSize(fSize_cheatsheets, font_height_cheatsheets, font_width_cheatsheets)
	Return
}
;################################################################## cheat-sheet configuration (advanced): clicking an entry from the objects-list
If InStr(A_GuiControl, "cheatsheets_edit_objectselect_")
{
	If hwnd_cheatsheet_edit_check ;if the right side (UI for setting panel-texts) of the window is already open
	{
		Loop 4 ;before switching to the new object, save the texts for the previously selected object
		{
			cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
			IniWrite, % """" StrReplace(cheatsheets_edit_panel%A_Index%, "`n", "^^^") """", % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%
		}
		cheatsheet_object_check := LLK_ArrayHasVal(cheatsheets_objects_%cheatsheet_selected1%, cheatsheet_object_selected) ;check index-number of previously-clicked clicked object
		GuiControl, cheatsheets_menu: +cWhite, cheatsheets_edit_objectselect_%cheatsheet_object_check% ;reset previous object's label to white
		GuiControl, cheatsheets_menu: movedraw, cheatsheets_edit_objectselect_%cheatsheet_object_check% ;reset previous object's label to white
		GuiControlGet, cheatsheet_object_selected,, % A_GuiControl, text ;get text-label of the clicked object
		cheatsheet_object_selected1 := StrReplace(cheatsheet_object_selected, " ", "_")
		cheatsheet_object_check := LLK_ArrayHasVal(cheatsheets_objects_%cheatsheet_selected1%, cheatsheet_object_selected) ;check index-number of clicked object
		If cheatsheet_object_check
		{
			GuiControl, cheatsheets_menu: +cFuchsia, cheatsheets_edit_objectselect_%cheatsheet_object_check% ;set clicked objects label to purple
			GuiControl, cheatsheets_menu: movedraw, cheatsheets_edit_objectselect_%cheatsheet_object_check% ;set clicked objects label to purple
			
			Loop 4 ;manually set texts in the edit-fields, rather than re-building the whole window (window would flash)
			{
				IniRead, cheatsheets_edit_panel%A_Index%, % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%, % A_Space
				cheatsheets_edit_panel%A_Index% := StrReplace(cheatsheets_edit_panel%A_Index%, "^^^", "`n")
				cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
				GuiControl, cheatsheets_menu: text, cheatsheets_edit_panel%A_Index%, % cheatsheets_edit_panel%A_Index%
			}
			GuiControl, Focus, cheatsheets_edit_textheader ;focus a disabled control to prevent accidental inputs
		}
	}
	GuiControlGet, cheatsheet_object_selected,, % A_GuiControl, text
	cheatsheet_object_selected1 := StrReplace(cheatsheet_object_selected, " ", "_")
	If hwnd_cheatsheet_edit_check
		Return ;return here to prevent GUI from being re-built from the ground up (window would flash)
}

;################################################################## cheat-sheet configuration (advanced): long-clicking an index to see screen-check preview
If InStr(A_GuiControl, "cheatsheets_edit_objectcheck_")
{
	cheatsheet_objectcheck_selected := StrReplace(A_GuiControl, "cheatsheets_edit_objectcheck_")
	cheatsheet_file_selected := "cheat-sheets\" cheatsheet_selected "\[check] " cheatsheets_objects_%cheatsheet_selected1%[cheatsheet_objectcheck_selected] ".bmp"
	If !FileExist(cheatsheet_file_selected)
	{
		LLK_ToolTip("screen-check file`ndoesn't exist", 1.5)
		Return
	}
	
	If (click = 1)
		LLK_CheatSheetsPreview(cheatsheet_file_selected, 1)
	Return
}
;################################################################## cheat-sheet configuration (advanced): edit-field receives input
If (A_GuiControl = "cheatsheets_edit_objectname")
{
	Loop, Parse, % %A_GuiControl%
	{
		If !LLK_IsAlpha(A_LoopField) && (A_LoopField != " ")
		{
			WinGetPos, cheatsheets_xEdit, cheatsheets_yEdit,, cheatsheets_hEdit, ahk_id %hwnd_cheatsheets_objectname%
			LLK_ToolTip("only letters and spaces are allowed", 1.5, cheatsheets_xEdit, cheatsheets_yEdit + cheatsheets_hEdit)
			GuiControl, cheatsheets_menu: text, cheatsheets_edit_objectname, % StrReplace(%A_GuiControl%, A_LoopField)
			SendInput, {END}
			Return
		}
	}
	Return
}
;################################################################## cheat-sheet configuration (advanced): clicking the add button
If (A_GuiControl = "cheatsheets_edit_objectadd")
{
	While (SubStr(cheatsheets_edit_objectname, 1, 1) = " ")
		cheatsheets_edit_objectname := SubStr(cheatsheets_edit_objectname, 2)
	While (SubStr(cheatsheets_edit_objectname, 0) = " ")
		cheatsheets_edit_objectname := SubStr(cheatsheets_edit_objectname, 1, -1)
	If (cheatsheets_edit_objectname = "")
	{
		LLK_ToolTip("object-name cannot be blank", 1.5)
		Return
	}
	If InStr(",general,ui,image search,objects", "," cheatsheets_edit_objectname ",")
	{
		LLK_ToolTip("object-name prohibited", 1.5)
		Return
	}
	If LLK_ArrayHasVal(cheatsheets_objects_%cheatsheet_selected1%, cheatsheets_edit_objectname)
	{
		LLK_ToolTip("an object with the same`nname already exists", 2)
		Return
	}
	If hwnd_cheatsheet_edit_check ;if the right side (UI for setting panel-texts) of the window is already open
	{
		Loop 4 ;before adding the new object, save potentially edited panel-texts
		{
			cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
			IniWrite, % """" StrReplace(cheatsheets_edit_panel%A_Index%, "`n", "^^^") """", % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%
		}
	}
	cheatsheets_objects_%cheatsheet_selected1%.Push(cheatsheets_edit_objectname)
	cheatsheets_objects_%cheatsheet_selected1% := LLK_SortArray(cheatsheets_objects_%cheatsheet_selected1%)
	IniWrite, 1, % "cheat-sheets\" cheatsheet_selected "\info.ini", objects, % cheatsheets_edit_objectname
}
;################################################################## cheat-sheet configuration (advanced): long-clicking the del button
If InStr(A_GuiControl, "cheatsheets_edit_objectdel_")
{
	cheatsheet_objectdel_selected := StrReplace(A_GuiControl, "cheatsheets_edit_objectdel_")
	GuiControlGet, cheatsheet_objectdel_selected,, cheatsheets_edit_objectselect_%cheatsheet_objectdel_selected%, text
	cheatsheet_objectdel_check := LLK_ArrayHasVal(cheatsheets_objects_%cheatsheet_selected1%, cheatsheet_objectdel_selected)
	If LLK_ProgressBar("cheatsheets_menu", "cheatsheets_edit_objectdelbar_" StrReplace(A_GuiControl, "cheatsheets_edit_objectdel_"))
	{
		If cheatsheet_objectdel_check
		{
			cheatsheets_objects_%cheatsheet_selected1%.RemoveAt(cheatsheet_objectdel_check)
			IniDelete, % "cheat-sheets\" cheatsheet_selected "\info.ini", objects, % cheatsheet_objectdel_selected
			IniDelete, % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_objectdel_selected
			FileDelete, % "cheat-sheets\" cheatsheet_selected "\[check] " cheatsheet_objectdel_selected ".*"
		}
		
		If (cheatsheet_objectdel_selected = cheatsheet_object_selected)
		{
			cheatsheet_object_selected := ""
			Loop 4
				GuiControl, cheatsheets_menu: text, cheatsheets_edit_panel%A_Index%,
		}
	}
	Else Return
}
;################################################################## cheat-sheet configuration: clicking the pick-app button
If (A_GuiControl = "cheatsheets_applaunch_pick")
{
	If (click = 1)
	{
		FileSelectFile, cheatsheet_app, 35, %A_Desktop%, Choose which file to launch, applications/shortcuts (*.exe; *.lnk)
		If ErrorLevel || !cheatsheet_app
		{
			LLK_ToolTip("file selection aborted")
			Return
		}
		If InStr(cheatsheet_app, ".lnk")
			FileCopy, % cheatsheet_app, % "cheat-sheets\" cheatsheet_selected "\app.lnk", 1
		Else If InStr(cheatsheet_app, ".exe")
			FileCreateShortcut, % cheatsheet_app, % "cheat-sheets\" cheatsheet_selected "\app.lnk"
		If FileExist("cheat-sheets\" cheatsheet_selected "\app.lnk")
		{
			GuiControl, cheatsheets_menu: +cLime, cheatsheets_applaunch_pick
			GuiControl, cheatsheets_menu: movedraw, cheatsheets_applaunch_pick
		}
	}
	Else If (click = 2)
	{
		FileDelete, % "cheat-sheets\" cheatsheet_selected "\app.lnk"
		If FileExist("cheat-sheets\" cheatsheet_selected "\app.lnk")
			LLK_FilePermissionError("delete")
		Else
		{
			GuiControl, cheatsheets_menu: +cWhite, cheatsheets_applaunch_pick
			GuiControl, cheatsheets_menu: movedraw, cheatsheets_applaunch_pick
		}
	}
	cheatsheet_app := ""
	Return
}
;################################################################## cheat-sheet configuration: clicking the test-app button
If (A_GuiControl = "cheatsheets_applaunch_test")
{
	If !FileExist("cheat-sheets\" cheatsheet_selected "\app.lnk")
	{
		LLK_ToolTip("file hasn't been selected yet", 1.5)
		Return
	}
	Run, % "cheat-sheets\" cheatsheet_selected "\app.lnk"
	Return
}
;################################################################## cheat-sheet configuration: clicking the test-title button
If (A_GuiControl = "cheatsheets_edit_apptest")
{
	Gui, cheatsheets_menu: Submit, NoHide
	If !cheatsheets_edit_apptitle || (cheatsheets_edit_apptitle = "A")
		Return
	If WinExist(cheatsheets_edit_apptitle)
	{
		WinActivate, % cheatsheets_edit_apptitle
		KeyWait, LButton
		WinSet, Bottom,, % cheatsheets_edit_apptitle
		WinMinimize, % cheatsheets_edit_apptitle
	}
	Else LLK_ToolTip("cannot find the`nspecified window", 1.5)
	Return
}
;################################################################## cheat-sheet configuration: choosing an activation type
If (A_GuiControl = "cheatsheets_edit_activation_ddl")
{
	IniWrite, % %A_GuiControl%, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, activation
	cheatsheets_activation_%cheatsheet_selected1% := %A_GuiControl%
	Return
}
;################################################################## cheat-sheet configuration: choosing a screen-check type
If (A_GuiControl = "cheatsheets_edit_screencheck_ddl")
{
	IniWrite, % %A_GuiControl%, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, image search
	cheatsheets_searchtype_%cheatsheet_selected1% := %A_GuiControl%
	Return
}
;################################################################## cheat-sheet configuration: choosing a position for [00] in the DDL
If (A_GuiControl = "cheatsheets_edit_position")
{
	IniWrite, % %A_GuiControl%, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, 00-position
	Return
}
;################################################################## cheat-sheet configuration: clicking 'snip' to initiate screen-capping
If InStr(A_GuiControl, "cheatsheets_edit_snip_")
{
	KeyWait, LButton
	cheatsheet_snip_selected := StrReplace(A_GuiControl, "cheatsheets_edit_snip_")
	Gdip_DisposeImage(pSnip)
	Gui, cheatsheets_menu: Hide
	pSnip := LLK_Snip(InStr(A_GuiControl, "00") || FileExist("cheat-sheets\"cheatsheet_selected "\[00]*") ? 1 : 2)
	Gui, cheatsheets_menu: Show, NA
	If (pSnip = -1)
		Return
	Else If (pSnip = 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		FileDelete, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_snip_selected "]*"
		Gdip_SaveBitmapToFile(pSnip, "cheat-sheets\" cheatsheet_selected "\["cheatsheet_snip_selected "].png", 100)
		Gdip_DisposeImage(pSnip)
	}
}
;################################################################## cheat-sheet configuration: clicking 'paste' to paste an img-file from clipboard
If InStr(A_GuiControl, "cheatsheets_edit_paste_")
{
	cheatsheet_paste_selected := StrReplace(A_GuiControl, "cheatsheets_edit_paste_")
	
	If InStr(Clipboard, ":\",,, 2) && InStr(Clipboard, "`r`n") ;multiple files in clipboard
	{
		If (cheatsheet_paste_selected = "00")
		{
			LLK_ToolTip("cannot paste multiple`nfiles into index 00", 2)
			Return
		}
		MsgBox, 4, Multiple files in the clipboard, There are multiple files in the clipboard.`nEvery index starting from %cheatsheet_paste_selected% will be overwritten.`n`nContinue?
		IfMsgBox, No
			Return
		IfMsgBox, Yes
		{
			Loop, Parse, Clipboard, `n, `r
			{
				If !(InStr(SubStr(A_LoopField, -3), ".bmp") || InStr(SubStr(A_LoopField, -3), ".png") || InStr(SubStr(A_LoopField, -3), ".jpg"))
					continue
				FileCopy, % A_LoopField, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_paste_selected "].*", 1
				cheatsheet_paste_selected += 1, cheatsheet_paste_selected := (cheatsheet_paste_selected < 10) ? "0" cheatsheet_paste_selected : cheatsheet_paste_selected
			}
			Return
		}
	}
	Else If InStr(Clipboard, ":\") && (InStr(SubStr(Clipboard, -3), ".bmp") || InStr(SubStr(Clipboard, -3), ".png") || InStr(SubStr(Clipboard, -3), ".jpg")) ;single img-file in clipboard
		FileCopy, % Clipboard, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_paste_selected "].*", 1
	Else
	{
		pCheatsheet := Gdip_CreateBitmapFromClipboard()
		If (pCheatsheet <= 0)
		{
			LLK_ToolTip("couldn't load image from clipboard", 1.5)
			Return
		}
		Else
		{
			FileDelete, "cheat-sheets\" cheatsheet_selected "\["cheatsheet_paste_selected "]*"
			Gdip_SaveBitmapToFile(pCheatsheet, "cheat-sheets\" cheatsheet_selected "\["cheatsheet_paste_selected "].png", 100)
			Gdip_DisposeImage(pCheatsheet)
		}
	}
}
;################################################################## cheat-sheet configuration: clicking 'del' to delete individual img-file
If InStr(A_GuiControl, "cheatsheets_edit_del_")
{
	cheatsheet_del_selected := StrReplace(A_GuiControl, "cheatsheets_edit_del_")
	If LLK_ProgressBar("cheatsheets_menu", "cheatsheets_edit_delbar_"cheatsheet_del_selected)
	{
		FileDelete, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_del_selected "]*"
		If (cheatsheet_del_selected = "00")
			IniDelete, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, 00-position
	}
	Else Return
}
;################################################################## cheat-sheet configuration: index is long-clicked for img-preview
If InStr(A_GuiControl, "cheatsheets_edit_preview_")
{
	cheatsheet_preview_selected := StrReplace(A_GuiControl, "cheatsheets_edit_preview_")
	LLK_CheatSheetsPreview("cheat-sheets\" cheatsheet_selected "\["cheatsheet_preview_selected "]*")
	Return
}
;################################################################## a tag-field received input
If InStr(A_GuiControl, "cheatsheets_edit_tag_")
{
	cheatsheet_tag_selected := StrReplace(A_GuiControl, "cheatsheets_edit_tag_")
	If LLK_IsAlpha(%A_GuiControl%) && FileExist("cheat-sheets\" cheatsheet_selected "\*] " %A_GuiControl% ".*")
	{
		LLK_ToolTip("tag already in use")
		GuiControl, cheatsheets_menu: text, % A_GuiControl, % ""
		Return
	}
	
	If !LLK_IsAlpha(%A_GuiControl%) && (%A_GuiControl% != "")
	{
		WinGetPos, cheatsheets_xEdit, cheatsheets_yEdit,, cheatsheets_hEdit, % "ahk_id " hwnd_%A_GuiControl%
		LLK_ToolTip("only accepts letters", 1, cheatsheets_xEdit, cheatsheets_yEdit + cheatsheets_hEdit)
		GuiControl, cheatsheets_menu: text, % A_GuiControl, % ""
		Return
	}
	
	If (%A_GuiControl% = "")
		FileMove, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_tag_selected "]*", % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_tag_selected "].*"
	Else FileMove, % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_tag_selected "]*", % "cheat-sheets\" cheatsheet_selected "\["cheatsheet_tag_selected "] "%A_GuiControl% ".*"
	Return
}
;################################################################## choosing an omni-key modifier
If InStr(A_GuiControl, "cheatsheets_omnikey_")
{
	cheatsheets_omnikey_modifier := StrReplace(A_GuiControl, "cheatsheets_omnikey_")
	IniWrite, % cheatsheets_omnikey_modifier, ini\cheat-sheets.ini, settings, modifier-key
	Return
}
;################################################################## clicking the test button
If InStr(A_GuiControl, "image_test")
{
	cheatsheets_parse := StrReplace(A_GuiControl, "_image_test"), cheatsheets_parse1 := StrReplace(cheatsheets_parse, "cheatsheets_"), cheatsheets_parse := StrReplace(cheatsheets_parse1, "_", " ")
	pHaystack_cheatsheets := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	cheatsheets_imgtest := LLK_SheetSearch(cheatsheets_parse)
	If cheatsheets_imgtest
	{
		LLK_ToolTip("test positive")
		GuiControl, settings_menu: +cWhite, cheatsheets_entry_%cheatsheets_parse1%
		GuiControl, settings_menu: movedraw, cheatsheets_entry_%cheatsheets_parse1%
	}
	Else LLK_ToolTip("test negative")
	Gdip_DisposeImage(pHaystack_cheatsheets)
	Return
}
;################################################################## clicking the calibrate button
If InStr(A_GuiControl, "image_calibrate")
{
	Clipboard := ""
	KeyWait, LButton
	gui_force_hide := 1
	LLK_Overlay("hide")
	SendInput, #+{s}
	WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
	WinWaitNotActive, ahk_exe ScreenClippingHost.exe
	pClipboard := Gdip_CreateBitmapFromClipboard()
	If (pClipboard <= 0)
	{
		gui_force_hide := 0
		LLK_Overlay("settings_menu", "show", 0)
		WinWait, ahk_id %hwnd_settings_menu%
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		cheatsheets_parse := StrReplace(A_GuiControl, "_image_calibrate"), cheatsheets_parse := StrReplace(cheatsheets_parse, "cheatsheets_")
		Gdip_SaveBitmapToFile(pClipboard, "cheat-sheets\" StrReplace(cheatsheets_parse, "_", " ") "\[check].bmp", 100)
		Gdip_DisposeImage(pClipboard)
		IniDelete, % "cheat-sheets\" StrReplace(cheatsheets_parse, "_", " ") "\info.ini", image search
	}
	gui_force_hide := 0
	GoSub, Settings_menu
	Return
}
;################################################################## clicking delete in the context-menu
If InStr(A_GuiControl, "cheatsheets_delete_")
{
	cheatsheet_selected1 := StrReplace(A_GuiControl, "cheatsheets_delete_"), cheatsheet_selected := StrReplace(cheatsheet_selected1, "_", " ")
	FileRemoveDir, cheat-sheets\%cheatsheet_selected%, 1
	If FileExist("cheat-sheets\" cheatsheet_selected "\")
	{
		cheatsheets_error := 1
		LLK_FilePermissionError("delete")
	}
	WinWaitActive, ahk_group poe_ahk_window
	If cheatsheets_error
	{
		cheatsheets_error := 0
		Return
	}
	GoSub, Settings_menu
	Return
}
;################################################################## clicking an entry in the list
If InStr(A_GuiControl, "cheatsheets_entry_")
{
	cheatsheet_selected1 := StrReplace(A_GuiControl, "cheatsheets_entry_"), cheatsheet_selected := StrReplace(cheatsheet_selected1, "_", " ")
	MouseGetPos, cheatsheets_xMouse, cheatsheets_yMouse
	If (click = 1) ;################################# left-click
	{
		Gui, cheatsheets_tooltip: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_cheatsheets_tooltip
		Gui, cheatsheets_tooltip: Margin, % fSize0//2, % fSize0//4
		Gui, cheatsheets_tooltip: Color, Black
		Gui, cheatsheets_tooltip: Font, cWhite s%fSize1%, Fontin SmallCaps
		cheatsheets_instructions_img := ""
		cheatsheet_resized := 0
		If FileExist("cheat-sheets\"cheatsheet_selected "\[sample].*") || FileExist("cheat-sheets\"cheatsheet_selected "\[check].bmp")
		{
			Loop, Files, % "cheat-sheets\"cheatsheet_selected "\[sample].*"
			{
				If InStr("jpg,bmp,png", A_LoopFileExt)
				{
					cheatsheets_instructions_img := A_LoopFilePath
					Break
				}
			}
			If (cheatsheets_instructions_img = "")
				cheatsheets_instructions_img := "cheat-sheets\"cheatsheet_selected "\[check].bmp"
			
			pCheatsheet := Gdip_CreateBitmapFromFile(cheatsheets_instructions_img)
			Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
			
			If (wCheatsheet > font_width*35)
			{
				pCheatsheet_copy := pCheatsheet
				pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, font_width*35, 10000, 1, 7)
				Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
				Gdip_DisposeImage(pCheatsheet_copy)
			}
			hbmCheatsheet := CreateDIBSection(wCheatsheet, hCheatsheet)
			hdcCheatsheet := CreateCompatibleDC()
			obmCheatsheet := SelectObject(hdcCheatsheet, hbmCheatsheet)
			gCheatsheet := Gdip_GraphicsFromHDC(hdcCheatsheet)
			Gdip_SetInterpolationMode(gCheatsheet, 0)
			Gdip_DrawImage(gCheatsheet, pCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 1)
			Gui, cheatsheets_tooltip: Add, Picture, % "Section Border BackgroundTrans", HBitmap:*%hbmCheatsheet%
			SelectObject(hdcCheatsheet, obmCheatsheet)
			DeleteObject(hbmCheatsheet)
			DeleteDC(hdcCheatsheet)
			Gdip_DeleteGraphics(gCheatsheet)
			Gdip_DisposeImage(pCheatsheet)
		}
		Else Gui, cheatsheets_tooltip: Add, Text, % "Border 0x200 Center BackgroundTrans w"font_width*35 " h"font_width*16, no image available
		
		If (cheatsheets_instructions_img != "")
		{
			Gui, cheatsheets_tooltip: Add, Text, % "Section xs BackgroundTrans w"font_width*35, % "instructions"
			IniRead, cheatsheet_instruction, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, instructions, % "to recalibrate, screen-cap the area displayed above"
			While (cheatsheet_instruction != "")
			{
				Gui, cheatsheets_tooltip: Add, Text, % "xs y+0 BackgroundTrans w"font_width*35, % "–> " cheatsheet_instruction
				IniRead, cheatsheet_instruction, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, instructions%A_Index%, % A_Space
			}
		}
		Gui, cheatsheets_tooltip: Add, Text, % "xs y+"font_height//2 " BackgroundTrans w"font_width*35, % "information`n–> type: " cheatsheets_type_%cheatsheet_selected1% "`n–> screen-check: " cheatsheets_searchtype_%cheatsheet_selected1% "`n–> activation: " cheatsheets_activation_%cheatsheet_selected1%
		
		IniRead, cheatsheet_description, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, description, % A_Space
		While (cheatsheet_description != "")
		{
			If (A_Index = 1)
				Gui, cheatsheets_tooltip: Add, Text, % "xs y+"font_height//2 " BackgroundTrans w"font_width*35, % "description"
			Gui, cheatsheets_tooltip: Add, Text, % "xs y+0 BackgroundTrans w"font_width*35, % "–> " cheatsheet_description
			IniRead, cheatsheet_description, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, description%A_Index%, % A_Space
		}
		Gui, cheatsheets_tooltip: Show, NA x10000 y10000
		WinGetPos,,, cheatsheets_wTooltip, cheatsheets_hTooltip, ahk_id %hwnd_cheatsheets_tooltip%
		cheatsheets_xTarget := (cheatsheets_xMouse - xScreenOffset + cheatsheets_wTooltip > poe_width) ? xScreenOffset + poe_width - cheatsheets_wTooltip : cheatsheets_xMouse
		cheatsheets_yTarget := (cheatsheets_yMouse - yScreenOffset + cheatsheets_hTooltip > poe_height) ? yScreenOffset + poe_height - cheatsheets_hTooltip : cheatsheets_yMouse
		Gui, cheatsheets_tooltip: Show, NA x%cheatsheets_xTarget% y%cheatsheets_yTarget%
		KeyWait, LButton
		Gui, cheatsheets_tooltip: Destroy
		hwnd_cheatsheets_tooltip := ""
		Return
	}
	If (click = 2) ;################################# right-click
	{
		Gui, cheatsheets_context_menu: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_cheatsheets_context_menu
		Gui, cheatsheets_context_menu: Margin, % fSize0//2, 0
		Gui, cheatsheets_context_menu: Color, Black
		WinSet, Transparent, %trans%
		Gui, cheatsheets_context_menu: Font, cWhite s%fSize0%, Fontin SmallCaps
		cheatsheets_edit_mode := 1
		Gui, cheatsheets_context_menu: Add, Text, Section BackgroundTrans vcheatsheets_edit_%cheatsheet_selected1% gCheatsheets, edit
		Gui, cheatsheets_context_menu: Add, Text, % "xs y+"fSize0//2 " BackgroundTrans vcheatsheets_delete_" cheatsheet_selected1 " gCheatsheets", delete
		Gui, cheatsheets_context_menu: Show, % "AutoSize x"cheatsheets_xMouse " y"cheatsheets_yMouse
		WinWaitNotActive, ahk_id %hwnd_cheatsheets_context_menu%
		Gui, cheatsheets_context_menu: Destroy
		hwnd_cheatsheets_context_menu := ""
		cheatsheets_edit_mode := 0
	}
	Return
}
;################################################################## toggling the enable checkbox
If InStr(A_GuiControl, "cheatsheets_enable_")
{
	cheatsheet_selected1 := StrReplace(A_GuiControl, "cheatsheets_enable_"), cheatsheet_selected := StrReplace(cheatsheet_selected1, "_", " ")
	IniWrite, % %A_GuiControl%, % "cheat-sheets\"cheatsheet_selected "\info.ini", general, enable
	If (%A_GuiControl% = 1) && (!FileExist("cheat-sheets\"cheatsheet_selected "\[check].*") || !cheatsheets_searchcoords_%cheatsheet_selected1%)
		GuiControl, settings_menu: +cRed, cheatsheets_entry_%cheatsheet_selected1%
	Else GuiControl, settings_menu: +cWhite, cheatsheets_entry_%cheatsheet_selected1%
	GuiControl, settings_menu: movedraw, cheatsheets_entry_%cheatsheet_selected1%
	GoSub, Init_cheatsheets
	Return
}
;################################################################## edit field receives input
If (A_GuiControl = "cheatsheets_new_name")
{
	Loop, Parse, cheatsheets_new_name
	{
		If !LLK_IsAlpha(A_LoopField) && (A_LoopField != " ")
		{
			WinGetPos, cheatsheets_xEdit, cheatsheets_yEdit,, cheatsheets_hEdit, ahk_id %hwnd_cheatsheets_new_name%
			LLK_ToolTip("only letters and spaces are allowed", 1.5, cheatsheets_xEdit, cheatsheets_yEdit + cheatsheets_hEdit)
			GuiControl, settings_menu: text, cheatsheets_new_name, % StrReplace(cheatsheets_new_name, A_LoopField)
			SendInput, {END}
			Return
		}
	}
	Return
}
;################################################################## clicking the add sheet button
If (A_GuiControl = "cheatsheets_new_save")
{
	While (SubStr(cheatsheets_new_name, 1, 1) = " ")
		cheatsheets_new_name := SubStr(cheatsheets_new_name, 2)
	While (SubStr(cheatsheets_new_name, 0) = " ")
		cheatsheets_new_name := SubStr(cheatsheets_new_name, 1, -1)
	If (cheatsheets_new_name = "")
	{
		WinGetPos, cheatsheets_xEdit, cheatsheets_yEdit,, cheatsheets_hEdit, ahk_id %hwnd_cheatsheets_new_name%
		LLK_ToolTip("name cannot be blank", 1.5, cheatsheets_xEdit, cheatsheets_yEdit + cheatsheets_hEdit)
		GuiControl, settings_menu: text, cheatsheets_new_name,
		Return
	}
	If FileExist("cheat-sheets\" cheatsheets_new_name "\")
	{
		MsgBox, 4, name conflict, A cheat-sheet with the same name already exists and will be overwritten. Do you want to continue?
		IfMsgBox No
		{
			WinActivate, ahk_id %hwnd_settings_menu%
			Return
		}
	}
	FileRemoveDir, cheat-sheets\%cheatsheets_new_name%, 1
	If FileExist("cheat-sheets\" cheatsheets_new_name)
	{
		cheatsheets_error := 1
		LLK_FilePermissionError("delete")
	}
	FileCreateDir, cheat-sheets\%cheatsheets_new_name%
	If !cheatsheets_error && !FileExist("cheat-sheets\" cheatsheets_new_name "\")
	{
		cheatsheets_error := 1
		LLK_FilePermissionError("create")
	}
	If cheatsheets_error
	{
		cheatsheets_error := 0
		Return
	}
	IniWrite, 1, cheat-sheets\%cheatsheets_new_name%\info.ini, general, enable
	IniWrite, % cheatsheets_type, cheat-sheets\%cheatsheets_new_name%\info.ini, general, type
	IniWrite, 1, cheat-sheets\%cheatsheets_new_name%\info.ini, UI, scale
	IniWrite, % "2,2", cheat-sheets\%cheatsheets_new_name%\info.ini, UI, position
	IniWrite, static, cheat-sheets\%cheatsheets_new_name%\info.ini, general, image search
	IniWrite, hold, cheat-sheets\%cheatsheets_new_name%\info.ini, general, activation
	GoSub, Settings_menu
	Return
}
;################################################################## clicking edit in the context-menu, or anything inside the cheat-sheets menu that initiates a refresh of the window
If InStr(A_GuiControl, "cheatsheets_edit") || (rAdvanced = -1)
{
	If (rAdvanced = -1)
	{
		cheatsheet_selected1 := cheatsheet_triggered1, cheatsheet_selected := cheatsheet_triggered
		cheatsheet_object_selected1 := cheatsheet_object_triggered1, cheatsheet_object_selected := cheatsheet_object_triggered
		rAdvanced := ""
	}
	Else cheatsheet_selected1 := (A_Gui = "cheatsheets_menu") ? cheatsheet_selected1 : StrReplace(A_GuiControl, "cheatsheets_edit_"), cheatsheet_selected := StrReplace(cheatsheet_selected1, "_", " ")
	LLK_Overlay("settings_menu", "hide")
	
	If WinExist("ahk_id " hwnd_cheatsheets_menu)
		WinGetPos, xCheatsheets_menu, yCheatsheets_menu,,, ahk_id %hwnd_cheatsheets_menu%
	Gui, cheatsheets_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_cheatsheets_menu, Lailloken UI: cheat-sheet configuration
	Gui, cheatsheets_menu: Color, Black
	Gui, cheatsheets_menu: Margin, % font_width//2, % font_height//4
	;WinSet, Transparent, %trans%
	Gui, cheatsheets_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
	;Gui, cheatsheets_menu: Add, Text, % "Section Center BackgroundTrans w"font_width*50,
	Gui, cheatsheets_menu: Add, Text, % "Section cSilver Center HWNDmain_text BackgroundTrans", % "name:"
	ControlGetPos,, yEdit,,,, ahk_id %main_text%
	Gui, cheatsheets_menu: Add, Text, % "ys Center BackgroundTrans", % cheatsheet_selected
	Gui, cheatsheets_menu: Add, Text, % "Section xs cSilver Center BackgroundTrans", % "type:"
	Gui, cheatsheets_menu: Add, Text, % "ys Center BackgroundTrans HWNDmain_text", % cheatsheets_type_%cheatsheet_selected1%
	Gui, cheatsheets_menu: Add, Text, % "Section xs cSilver Center BackgroundTrans", % "screen-check:"
	Gui, cheatsheets_menu: Font, % "s"fsize0 - 4
	cheatsheet_screencheck_ddl := StrReplace("static|dynamic|", cheatsheets_searchtype_%cheatsheet_selected1% "|", cheatsheets_searchtype_%cheatsheet_selected1% "||")
	Gui, cheatsheets_menu: Add, DDL, % "ys w"font_width*8 " hp r2 Center BackgroundTrans vcheatsheets_edit_screencheck_ddl gCheatsheets", % cheatsheet_screencheck_ddl
	Gui, cheatsheets_menu: Font, % "s"fsize0
	Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_screencheck_help", img\GUI\help.png
	Gui, cheatsheets_menu: Add, Text, % "Section xs cSilver Center BackgroundTrans", % "activation:"
	Gui, cheatsheets_menu: Font, % "s"fsize0 - 4
	cheatsheet_activation_ddl := StrReplace("hold|toggle|", cheatsheets_activation_%cheatsheet_selected1% "|", cheatsheets_activation_%cheatsheet_selected1% "||")
	Gui, cheatsheets_menu: Add, DDL, % "ys w"font_width*7 " hp r2 Center BackgroundTrans vcheatsheets_edit_activation_ddl gCheatsheets", % cheatsheet_activation_ddl
	Gui, cheatsheets_menu: Font, % "s"fsize0
	Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_activation_help", img\GUI\help.png
	
	If (cheatsheets_type_%cheatsheet_selected1% = "images")
	{
		cheatsheets_files := 0
		Loop, 99
		{
			If FileExist("cheat-sheets\" cheatsheet_selected "\[0" A_Index "]*") || FileExist("cheat-sheets\" cheatsheet_selected "\[" A_Index "]*")
				cheatsheets_files := (A_Index < 10) ? "0" A_Index : A_Index
		}
		
		Gui, cheatsheets_menu: Add, Text, % "y+"font_height//2 " Section xs cSilver BackgroundTrans", % "import image-files:"
		Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_import_help", img\GUI\help.png
		Gui, cheatsheets_menu: Font, underline
		Gui, cheatsheets_menu: Add, Text, % "Section xs BackgroundTrans gCheatsheets vcheatsheets_edit_preview_00", % "00"
		Gui, cheatsheets_menu: Font, norm
		Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans gCheatsheets vcheatsheets_edit_paste_00", % " paste "
		Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans gCheatsheets vcheatsheets_edit_snip_00", % " snip "
		If FileExist("cheat-sheets\" cheatsheet_selected "\[00]*")
		{
			IniRead, cheatsheet_position, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, 00-position, top
			Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans cRed gCheatsheets vcheatsheets_edit_del_00", % " del "
			Gui, cheatsheets_menu: Add, Progress, % "ys x+0 hp w"font_width//2 " Disabled vertical BackgroundTrans cRed range0-400 vcheatsheets_edit_delbar_00",
			Gui, cheatsheets_menu: Font, % "s"fSize0 - 4
			Gui, cheatsheets_menu: Add, DDL, % "ys x+0 w"font_width*6 " cBlack BackgroundTrans gCheatsheets vcheatsheets_edit_position", % StrReplace("top|left|", cheatsheet_position, cheatsheet_position "|")
			Gui, cheatsheets_menu: Font, % "s"fSize0
		}
		
		Loop, % cheatsheets_files
		{
			cheatsheets_loop := (A_Index < 10) ? "0" A_Index : A_Index
			Gui, cheatsheets_menu: Font, underline
			Gui, cheatsheets_menu: Add, Text, % "Section xs BackgroundTrans gCheatsheets vcheatsheets_edit_preview_"cheatsheets_loop, % cheatsheets_loop
			Gui, cheatsheets_menu: Font, norm
			Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans gCheatsheets vcheatsheets_edit_paste_"cheatsheets_loop, % " paste "
			Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans gCheatsheets vcheatsheets_edit_snip_"cheatsheets_loop, % " snip "
			If FileExist("cheat-sheets\"cheatsheet_selected "\["cheatsheets_loop "]*")
			{
				Loop, Files, % "cheat-sheets\"cheatsheet_selected "\["cheatsheets_loop "]*"
					cheatsheets_file := SubStr(A_LoopFileName, 1, InStr(A_LoopFileName, ".") - 1)
				If (StrLen(cheatsheets_file) > 6 || StrLen(cheatsheets_file) = 4)
					cheatsheets_file := ""
				Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans cRed gCheatsheets vcheatsheets_edit_del_"cheatsheets_loop, % " del "
				Gui, cheatsheets_menu: Add, Progress, % "ys x+0 hp w"font_width//2 " Disabled vertical BackgroundTrans cRed range0-400 vcheatsheets_edit_delbar_"cheatsheets_loop
				Gui, cheatsheets_menu: Font, % "s"fSize0 - 4
				Gui, cheatsheets_menu: Add, Edit, % "ys x+0 w"font_width*2 " cBlack BackgroundTrans Center Limit1 gCheatsheets HWNDhwnd_cheatsheets_edit_tag_"cheatsheets_loop " vcheatsheets_edit_tag_"cheatsheets_loop, % SubStr(cheatsheets_file, 0)
				Gui, cheatsheets_menu: Font, % "s"fSize0
			}
		}
		cheatsheets_files2 := (cheatsheets_files < 9) ? "0" cheatsheets_files + 1 : cheatsheets_files + 1
		Gui, cheatsheets_menu: Add, Text, % "Section xs BackgroundTrans cLime", % cheatsheets_files2
		Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans cLime gCheatsheets vcheatsheets_edit_paste_"cheatsheets_files2, % " paste "
		Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans cLime gCheatsheets vcheatsheets_edit_snip_"cheatsheets_files2, % " snip "
		Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_import_help2", img\GUI\help.png
		
		If (cheatsheets_files > 0)
		{
			Gui, cheatsheets_menu: Add, Text, % "Section xs Hidden BackgroundTrans", % cheatsheets_files2
			Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans gCheatsheets vcheatsheets_menu_preview", % " preview "
			Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_preview_help", img\GUI\help.png
		}
		GuiControl, Focus, % "cheatsheets_edit_snip_"cheatsheets_files2
	}
	
	If (cheatsheets_type_%cheatsheet_selected1% = "app")
	{
		IniRead, cheatsheets_apptitle_%cheatsheet_selected1%, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, app title, % A_Space
		Gui, cheatsheets_menu: Add, Text, % "y+"font_height//2 " Section xs cSilver BackgroundTrans", % "specify window title:"
		Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_apptitle_help", img\GUI\help.png
		Gui, cheatsheets_menu: Font, % "s"fSize0 - 4
		Gui, cheatsheets_menu: Add, Edit, % "Section xs w"font_width*18 " cBlack vcheatsheets_edit_apptitle", % cheatsheets_apptitle_%cheatsheet_selected1%
		Gui, cheatsheets_menu: Font, % "s"fSize0
		Gui, cheatsheets_menu: Add, Text, % "ys Border vcheatsheets_edit_apptest gCheatsheets", % " test "
		GuiControl, Focus, % "cheatsheets_edit_apptest"
		
		Gui, cheatsheets_menu: Add, Text, % "xs Section cSilver BackgroundTrans", % "if window is not found,"
		Gui, cheatsheets_menu: Add, Text, % "xs y+0 Section cSilver BackgroundTrans", % "launch app instead:"
		Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_applaunch_help", img\GUI\help.png
		cPick := FileExist("cheat-sheets\" cheatsheet_selected "\app.lnk") ? " cLime " : " cWhite "
		Gui, cheatsheets_menu: Add, Text, % "xs Section BackgroundTrans Border"cPick "gCheatsheets vCheatsheets_applaunch_pick", % " pick .exe/shortcut "
		Gui, cheatsheets_menu: Add, Text, % "ys BackgroundTrans Border gCheatsheets vCheatsheets_applaunch_test", % " test "
	}
	
	If (cheatsheets_type_%cheatsheet_selected1% = "advanced")
	{
		Gui, cheatsheets_menu: Add, Text, % "y+"font_height//2 " Section xs cSilver BackgroundTrans", % "add new object:"
		Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_objectadd_help", img\GUI\help.png
		Gui, cheatsheets_menu: Font, % "s"fSize0 - 4
		Gui, cheatsheets_menu: Add, Edit, % "Section xs w"font_width*18 " cBlack HWNDhwnd_cheatsheets_objectname vcheatsheets_edit_objectname gCheatsheets",
		Gui, cheatsheets_menu: Font, % "s"fSize0
		Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans HWNDmain_text vcheatsheets_edit_objectadd gCheatsheets", % " add "
		ControlGetPos, xEdit,, wEdit,,, ahk_id %main_text%
		cheatsheets_edit_width := xEdit + wEdit
		
		If cheatsheets_objects_%cheatsheet_selected1%.Length()
		{
			Gui, cheatsheets_menu: Add, Text, % "Section xs y+"font_height//2 " cSilver BackgroundTrans", % "list of added objects:"
			Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_objects_help", img\GUI\help.png
		}
		Loop, % cheatsheets_objects_%cheatsheet_selected1%.Length()
		{
			cIndex := FileExist("cheat-sheets\" cheatsheet_selected "\[check] " cheatsheets_objects_%cheatsheet_selected1%[A_Index] ".*") ? " cLime " : " cWhite "
			Gui, cheatsheets_menu: Font, underline
			Gui, cheatsheets_menu: Add, Text, % "Section xs" cIndex " w"font_width*2 " Center BackgroundTrans gCheatsheets vcheatsheets_edit_objectcheck_"A_Index, % A_Index
			Gui, cheatsheets_menu: Font, norm
			Gui, cheatsheets_menu: Add, Text, % "ys Border BackgroundTrans cRed vcheatsheets_edit_objectdel_"A_Index " gCheatsheets", % " del "
			Gui, cheatsheets_menu: Add, Progress, % "ys x+0 hp w"font_width//2 " Disabled vertical range0-400 BackgroundBlack cRed vcheatsheets_edit_objectdelbar_"A_Index,
			Gui, cheatsheets_menu: Font, underline
			cObject := (cheatsheets_objects_%cheatsheet_selected1%[A_Index] = cheatsheet_object_selected) ? " cFuchsia " : " cWhite "
			Gui, cheatsheets_menu: Add, Text, % "ys x+0 BackgroundTrans "cObject " HWNDmain_text vcheatsheets_edit_objectselect_"A_Index " gCheatsheets", % cheatsheets_objects_%cheatsheet_selected1%[A_Index]
			ControlGetPos, xEdit,, wEdit,,, ahk_id %main_text%
			cheatsheets_edit_width := (xEdit + wEdit > cheatsheets_edit_width) ? xEdit + wEdit : cheatsheets_edit_width
			Gui, cheatsheets_menu: Font, norm
		}
		GuiControl, Focus, cheatsheets_edit_objectadd
		
		If cheatsheet_object_selected
		{
			Gui, cheatsheets_menu: Add, Text, % "x"cheatsheets_edit_width + font_width*2 " y"yEdit - font_height " BackgroundTrans HWNDhwnd_cheatsheet_edit_check Border w"font_width*35 " h"font_height*16.5,
			Gui, cheatsheets_menu: Add, Text, % "Section xp+"font_width//2 " yp+"font_height//4 " vcheatsheets_edit_textheader BackgroundTrans", % "enter texts for the overlay-panels: "
			Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_textpanels_help", img\GUI\help.png
			Gui, cheatsheets_menu: Add, Edit, % "xs Hidden Center r3"
			Loop 4
			{
				style := (A_Index = 1) ? "Section xp yp " : "Section xs "
				IniRead, cheatsheets_edit_panel%A_Index%, % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%, % A_Space
				cheatsheets_edit_panel%A_Index% := StrReplace(cheatsheets_edit_panel%A_Index%, "^^^", "`n")
				Gui, cheatsheets_menu: Add, Text, % style "hp 0x200 Section Border w"font_width*2 " Center", % A_Index ":"
				Gui, cheatsheets_menu: Add, Edit, % "ys hp x+0 Center Border BackgroundTrans Limit cBlack w"font_width*32 " vcheatsheets_edit_panel"A_Index, % cheatsheets_edit_panel%A_Index%
			}
			Gui, cheatsheets_menu: Add, Text, % "Section xs BackgroundTrans Border Center gCheatsheets vcheatsheets_edit_panelpreview", % " preview "
			Gui, cheatsheets_menu: Add, Picture, % "ys hp w-1 x+"font_width//2 " BackgroundTrans gSettings_menu_help vCheatsheets_preview_help2", img\GUI\help.png
		}
		Else hwnd_cheatsheet_edit_check := ""
	}
	
	If (xCheatsheets_menu = "")
		Gui, cheatsheets_menu: Show, x%xScreenOffset%
	Else Gui, cheatsheets_menu: Show, x%xCheatsheets_menu% y%yCheatsheets_menu%
	If hwnd_snip
		Gui, snip: Show
}
Return

LLK_CheatSheetsApp(name)
{
	global
	cheatsheet_overlay_active := name, cheatsheet_overlay_active1 := StrReplace(name, " ", "_")
	local parse := StrReplace(name, " ", "_")
	If (cheatsheets_apptitle_%parse% = "")
	{
		LLK_ToolTip("cheat-sheet was activated but`nhas no window title", 2)
		Return
	}
	
	If !WinExist(cheatsheets_apptitle_%parse%)
	{
		If !FileExist("cheat-sheets\" cheatsheet_overlay_active "\app.lnk")
		{
			LLK_ToolTip("window title doesn't exist:`n"""cheatsheets_apptitle_%parse% """", 1.5)
			Return
		}
		Run, % "cheat-sheets\" cheatsheet_overlay_active "\app.lnk",
		WinWaitActive, % cheatsheets_apptitle_%parse%
		WinMaximize, % cheatsheets_apptitle_%parse%
	}
	
	cheatsheet_overlay_app := 1
	If WinExist(cheatsheets_apptitle_%parse%)
	{
		WinActivate, % cheatsheets_apptitle_%parse%
		If (cheatsheets_activation_%parse% = "hold") && (cheatsheet_toggle_check < 2)
		{
			KeyWait, % cheatsheets_hotkey
			WinActivate, ahk_group poe_window
			;WinSet, Bottom,, % cheatsheets_apptitle_%parse%
			WinMinimize, % cheatsheets_apptitle_%parse%
		}
		Else WinWaitActive, ahk_group poe_window
	}
	cheatsheet_overlay_app := 0
	cheatsheet_triggered1 := "", cheatsheet_triggered := ""
}

LLK_CheatSheetsClose()
{
	global
	If cheatsheets_resized
	{
		cheatsheets_resized := 0
		IniWrite, % cheatsheets_scale_%cheatsheet_triggered1%, % "cheat-sheets\" cheatsheet_triggered "\info.ini", UI, scale
		IniWrite, % cheatsheets_pos_%cheatsheet_triggered1%, % "cheat-sheets\" cheatsheet_triggered "\info.ini", UI, position
	}
	cheatsheets_loaded_images := ""
	cheatsheet_overlay_image := 0
	cheatsheet_overlay_advanced := 0
	cheatsheet_overlay_type := ""
	cheatsheet_triggered1 := "", cheatsheet_triggered := ""
	;Gui, cheatsheet: Destroy
	;hwnd_cheatsheet := ""
	LLK_Overlay("cheatsheet", "hide")
}

LLK_CheatSheetsImages(name)
{
	global
	cheatsheet_overlay_active := name, cheatsheet_overlay_active1 := StrReplace(name, " ", "_")
	local parse := StrReplace(name, " ", "_"), cheatsheet_type, pCheatsheet, pCheatsheet_copy, wCheatsheet, hCheatsheet, hotkey_copy, ignore_hotkeys := [tab_hotkey, "F1", "F2", "F3", "Up", "Down", "Left", "Right", "RButton"]
	, xCheatsheet, yCheatsheet, wCheatsheet, hCheatsheet, exist_00 := FileExist("cheat-sheets\"name "\[00]*")
	
	If (A_Gui != "cheatsheets_menu") && (A_ThisHotkey = "RButton") && (exist_00 || !IsNumber(SubStr(cheatsheets_include_%parse%, 1, 2)))
		Return
	
	Loop, Parse, cheatsheets_include_%parse%, `,
	{
		If (A_LoopField = "")
			continue
		If IsNumber(A_LoopField) && !FileExist("cheat-sheets\"name "\["A_LoopField "]*")
			cheatsheets_include_%parse% := StrReplace(cheatsheets_include_%parse%, A_LoopField ",")
		Else If !IsNumber(A_LoopField) && !FileExist("cheat-sheets\"name "\*] "A_LoopField ".*")
			cheatsheets_include_%parse% := StrReplace(cheatsheets_include_%parse%, A_LoopField ",")
	}
	
	If !exist_00 && InStr(cheatsheets_include_%parse%, ",",,, 2) ;clear include-list if 00 is no longer available (i.e. revert overlay to non-segmented)
		cheatsheets_include_%parse% := ""
	
	If exist_00 && !InStr(cheatsheets_include_%parse%, "00,") ;fixes [00] not being included if it was added after an overlay had previously been displayed without it
		cheatsheets_include_%parse% := "00," cheatsheets_include_%parse%
	
	If (A_Gui != "cheatsheets_menu")
	{
		If !LLK_ArrayHasVal(ignore_hotkeys, A_ThisHotkey)
		{
			If IsNumber(A_ThisHotkey)
				hotkey_copy := (A_ThisHotkey = "0") ? "10" : "0" A_ThisHotkey
			Else hotkey_copy := A_ThisHotkey
			
			If (A_ThisHotkey != "Space") && (InStr(cheatsheets_include_%parse%, hotkey_copy ",") || (IsNumber(hotkey_copy) && !FileExist("cheat-sheets\"name "\["hotkey_copy "]*")) || (!IsNumber(hotkey_copy) && !FileExist("cheat-sheets\"name "\*] "hotkey_copy ".*") && !InStr(hotkey_copy, "~")))
				Return
			
			If exist_00
			{
				If InStr(cheatsheets_loaded_images, "] " hotkey_copy) || InStr(cheatsheets_loaded_images, "[" hotkey_copy "]")
					Return
				If IsNumber(A_ThisHotkey) && FileExist("cheat-sheets\"name "\["hotkey_copy "]*")
					cheatsheets_include_%parse% .= hotkey_copy ","
				Else If !IsNumber(A_ThisHotkey) && FileExist("cheat-sheets\"name "\*] "hotkey_copy ".*")
					cheatsheets_include_%parse% .= hotkey_copy ","
			}
			Else
			{
				If IsNumber(A_ThisHotkey) && FileExist("cheat-sheets\"name "\["hotkey_copy "]*")
					cheatsheets_include_%parse% := hotkey_copy ","
				Else If !IsNumber(A_ThisHotkey) && FileExist("cheat-sheets\"name "\*] "hotkey_copy ".*")
					cheatsheets_include_%parse% := hotkey_copy ","
			}
		}
		
		If (A_ThisHotkey = "RButton") && !exist_00 && (cheatsheets_include_%parse% != "") && IsNumber(SubStr(cheatsheets_include_%parse%, 1, 2))
		{
			local start := A_TickCount, long_press := 0, target := SubStr(cheatsheets_include_%parse%, 1, 2)
			While GetKeyState("RButton", "P")
			{
				If (A_TickCount >= start + 300)
				{
					long_press := 1
					Break
				}
			}
			Loop, Files, % "cheat-sheets\"name "\[*"
			{
				If !IsNumber(SubStr(A_LoopFileName, 2, 2))
					continue
				If long_press && (SubStr(A_LoopFileName, 2, 2) < target)
					cheatsheets_include_%parse% := SubStr(A_LoopFileName, 2, 2) ","
				If !long_press && (SubStr(A_LoopFileName, 2, 2) > target)
				{
					cheatsheets_include_%parse% := SubStr(A_LoopFileName, 2, 2) ","
					Break
				}
			}
			If InStr(cheatsheets_include_%parse%, target)
				Return
		}
		
		If (A_ThisHotkey = "Space")
		{
			If !exist_00
				Return
			cheatsheets_include_%parse% := ""
			cheatsheets_loaded_images := ""
		}
	}
	
	If (cheatsheets_include_%parse% = "")
	{
		Loop, Files, % "cheat-sheets\"name "\[*"
		{
			If InStr(A_LoopFileName, "[00]") || InStr(A_LoopFileName, "check") || InStr(A_LoopFileName, "sample") || !InStr("jpg,png,bmp", A_LoopFileExt)
				continue
			local parse2 := SubStr(A_LoopFileName, 2, 2)
			Break
		}
		cheatsheets_include_%parse% := exist_00 ? "00," : parse2 ","
	}
	
	cheatsheet_overlay_image := 1
	Gui, cheatsheet: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_cheatsheet
	Gui, cheatsheet: Color, Black
	Gui, cheatsheet: Margin, 0, 0
	WinSet, Transparent, 255
	Gui, cheatsheet: Font, s%fSize1% cWhite, Fontin SmallCaps
	cheatsheets_valid_files := 0
	Loop, Files, % "cheat-sheets\"name "\[*"
	{
		If !InStr(A_LoopFileName, "[check]") && !InStr(A_LoopFileName, "[sample]") && InStr("jpg,png,bmp", A_LoopFileExt)
			cheatsheets_valid_files += 1
	}
	If !cheatsheets_valid_files
	{
		If (A_Gui = "cheatsheets_menu")
			LLK_ToolTip("sheet contains no files", 2)
		Else LLK_ToolTip("sheet was activated but`ncontains no files", 2)
		cheatsheets_include_%parse% := ""
		cheatsheets_loaded_images := ""
		Return
	}
	local files_added := 0
	Loop, Parse, cheatsheets_include_%parse%, `,
	{
		local loopfield_copy := A_LoopField
		If (A_LoopField = "") || !FileExist("cheat-sheets\"name "\["A_LoopField "]*") && !FileExist("cheat-sheets\"name "\*] "A_LoopField ".*")
			continue
		If IsNumber(A_LoopField)
		{
			Loop, Files, % "cheat-sheets\"name "\["A_LoopField "]*"
			{
				If InStr("jpg,png,bmp", A_LoopFileExt)
				{
					local cheatsheet_file := A_LoopFilePath, cheatsheet_filename := (SubStr(A_Loopfilename, 2, 1) = 0) ? SubStr(A_LoopFileName, 3, 1) : SubStr(A_LoopFileName, 2, 2)
					cheatsheets_loaded_images .= A_LoopFilePath "|"
					Break
				}
			}
		}
		Else
		{
			Loop, Files, % "cheat-sheets\"name "\*] "A_LoopField ".*"
			{
				If InStr("jpg,png,bmp", A_LoopFileExt)
				{
					local cheatsheet_file := A_LoopFilePath, cheatsheet_filename := loopfield_copy
					cheatsheets_loaded_images .= A_LoopFilePath "|"
					Break
				}
			}
		}
		
		If (A_LoopField = "00")
		{
			IniRead, cheatsheet_type, % "cheat-sheets\"name "\info.ini", general, 00-position, top
			local style_00 := (cheatsheet_type = "top") ? "xs" : "ys"
		}
		
		pCheatsheet := Gdip_LoadImageFromFile(cheatsheet_file)
		If (pCheatsheet <= 0)
		{
			MsgBox, % "The file """ cheatsheet_file """ could not be loaded correctly."
			Return
		}
		Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
		If (hCheatsheet >= height_native*0.9)
		{
			pCheatsheet_copy := pCheatsheet
			pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, ((height_native*0.9) / hCheatsheet) * wCheatsheet, 10000, 1, 7)
			Gdip_DisposeImage(pCheatsheet_copy)
		}
		Else If (wCheatsheet >= width_native*0.9)
		{
			pCheatsheet_copy := pCheatsheet
			pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, width_native*0.9, 10000, 1, 7)
			Gdip_DisposeImage(pCheatsheet_copy)
		}
		
		Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
		If (cheatsheets_scale_%parse% != 1)
		{
			pCheatsheet_copy := pCheatsheet
			pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, wCheatsheet*cheatsheets_scale_%parse%, 10000, 1, 7)
			Gdip_DisposeImage(pCheatsheet_copy)
			Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
		}
		
		local hbmCheatsheet := CreateDIBSection(wCheatsheet, hCheatsheet)
		local hdcCheatsheet := CreateCompatibleDC()
		local obmCheatsheet := SelectObject(hdcCheatsheet, hbmCheatsheet)
		local gCheatsheet := Gdip_GraphicsFromHDC(hdcCheatsheet)
		Gdip_SetInterpolationMode(gCheatsheet, 0)
		Gdip_DrawImage(gCheatsheet, pCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 1)
		If (A_LoopField = "00")
			Gui, cheatsheet: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmCheatsheet%
		Else Gui, cheatsheet: Add, Picture, % style_00 " Section BackgroundTrans", HBitmap:*%hbmCheatsheet%
		;Gui, cheatsheet: Add, Text, xp yp Hidden BackgroundTrans, % cheatsheet_filename
		;Gui, cheatsheet: Add, Progress, xp yp wp hp BackgroundBlack Disabled,
		;Gui, cheatsheet: Add, Text, xp yp BackgroundTrans, % cheatsheet_filename
		files_added += 1
		SelectObject(hdcCheatsheet, obmCheatsheet)
		DeleteObject(hbmCheatsheet)
		DeleteDC(hdcCheatsheet)
		Gdip_DeleteGraphics(gCheatsheet)
		Gdip_DisposeImage(pCheatsheet)
	}
	If files_added
	{
		Gui, cheatsheet: Show, NA x10000 y10000
		WinGetPos,,, wCheatsheet, hCheatsheet, ahk_id %hwnd_cheatsheet%
		local style := "", xPos := SubStr(cheatsheets_pos_%parse%, 1, 1), yPos := SubStr(cheatsheets_pos_%parse%, 3)
		Switch xPos
		{
			Case 1:
				style .= "x"xScreenOffset
			Case 2:
				style .= "xCenter"
			Case 3:
				style .= "x"xScreenOffset + poe_width - wCheatsheet
		}
		Switch yPos
		{
			Case 1:
				style .= (style = "") ? "y"yScreenOffset : " y"yScreenOffset
			Case 2:
				style .= (style = "") ? "yCenter" : " yCenter"
			Case 3:
				style .= (style = "") ? "y"yScreenOffset + poe_height - hCheatsheet : " y"yScreenOffset + poe_height - hCheatsheet
		}
		Gui, cheatsheet: Show, NA AutoSize %style%
		LLK_Overlay("cheatsheet", "show")
		cheatsheet_overlay_type := "images"
	}
}

LLK_CheatSheetsMove()
{
	global
	cheatsheet_move_selected := StrReplace(cheatsheet_overlay_active, " ", "_")
	local parse := StrReplace(cheatsheet_overlay_active, " ", "_")
	If InStr("F1,F2,F3", A_ThisHotkey)
	{
		Switch A_ThisHotkey
		{
			Case "F1":
				If (cheatsheets_scale_%parse% = 0.2)
					Return
				cheatsheets_scale_%parse% -= (cheatsheets_scale_%parse% > 0.2) ? 0.1 : 0
			Case "F2":
				If (cheatsheets_scale_%parse% = 2)
					Return
				cheatsheets_scale_%parse% += (cheatsheets_scale_%parse% < 2) ? 0.1 : 0
			Case "F3":
				If (cheatsheets_scale_%parse% = 1)
					Return
				cheatsheets_scale_%parse% := 1
		}
		cheatsheets_scale_%parse% := Format("{:0.1f}", cheatsheets_scale_%parse%)
		cheatsheets_resized := 1
		;IniWrite, % cheatsheets_scale_%parse%, % "cheat-sheets\" cheatsheet_overlay_active "\info.ini", UI, scale
	}
	Else
	{
		Switch A_ThisHotkey
		{
			Case "Up":
				If (SubStr(cheatsheets_pos_%parse%, 3) = 1)
					Return
				cheatsheets_pos_%parse% := SubStr(cheatsheets_pos_%parse%, 1, 1) "," SubStr(cheatsheets_pos_%parse%, 3) - 1
			Case "Down":
				If (SubStr(cheatsheets_pos_%parse%, 3) = 3)
					Return
				cheatsheets_pos_%parse% := SubStr(cheatsheets_pos_%parse%, 1, 1) "," SubStr(cheatsheets_pos_%parse%, 3) + 1
			Case "Left":
				If (SubStr(cheatsheets_pos_%parse%, 1, 1) = 1)
					Return
				cheatsheets_pos_%parse% := SubStr(cheatsheets_pos_%parse%, 1, 1) - 1 "," SubStr(cheatsheets_pos_%parse%, 3)
			Case "Right":
				If (SubStr(cheatsheets_pos_%parse%, 1, 1) = 3)
					Return
				cheatsheets_pos_%parse% := SubStr(cheatsheets_pos_%parse%, 1, 1) + 1 "," SubStr(cheatsheets_pos_%parse%, 3)
		}
		cheatsheets_resized := 1
		;IniWrite, % cheatsheets_pos_%parse%, % "cheat-sheets\" cheatsheet_overlay_active "\info.ini", UI, position
	}
	LLK_CheatSheetsImages(cheatsheet_overlay_active)
}

LLK_SheetSearch(name) ;checks the screen for sheet-related UI elements
{
	global
	If !FileExist("cheat-sheets\"name "\[check].bmp") ;return 0 if reference img-file is missing
	{
		LLK_ToolTip("check hasn't been calibrated yet", 1.5)
		Return 0
	}
	
	local parse := StrReplace(name, " ", "_"), width, height
	If !cheatsheets_searchcoords_%parse% && (A_Gui != "settings_menu")
		Return 0
	
	If (A_Gui = "settings_menu") ;search whole client-area if search was initiated from settings menu, or if this specific search doesn't have last-known coordinates
		local sheetsearch_x1 := 0, sheetsearch_y1 := 0, sheetsearch_x2 := 0, sheetsearch_y2 := 0
	Else ;otherwise, load last-known coordinates
	{
		Loop, Parse, cheatsheets_searchcoords_%parse%, `, ;last-known coordinates are stored in a string as "x1,y1,reference-img width,reference-img height"
		{
			Switch A_Index
			{
				Case 1:
					local sheetsearch_x1 := (cheatsheets_searchtype_%parse% = "static") ? A_LoopField : (A_LoopField - 100 <= 0) ? 0 : A_LoopField - 100
					local sheetsearch_x1_orig := A_LoopField
				Case 2:
					local sheetsearch_y1 := (cheatsheets_searchtype_%parse% = "static") ? A_LoopField : (A_LoopField - 100 <= 0) ? 0 : A_LoopField - 100
					local sheetsearch_y1_orig
				Case 3:
					local sheetsearch_x2 := (cheatsheets_searchtype_%parse% = "static") ? A_LoopField + sheetsearch_x1 : (A_LoopField + sheetsearch_x1_orig + 100 >= poe_width) ? poe_width : A_LoopField + sheetsearch_x1_orig + 100 ;x2 = x1 + reference-img width
				Case 4:
					local sheetsearch_y2 := (cheatsheets_searchtype_%parse% = "static") ? A_LoopField + sheetsearch_y1 : (A_LoopField + sheetsearch_y1_orig + 100 >= poe_height) ? poe_height : A_LoopField + sheetsearch_y1_orig + 100 ;y2 = y1 + reference-img height
			}
		}
	}
	pNeedle_cheatsheets := Gdip_CreateBitmapFromFile("cheat-sheets\"name "\[check].bmp") ;load reference img-file that will be searched for in the screenshot
	If (pNeedle_cheatsheets <= 0)
	{
		MsgBox,% "The reference bmp-file could not be loaded correctly.`n`nYou should recalibrate this sheet: " name
		Return 0
	}
	If (Gdip_ImageSearch(pHaystack_cheatsheets, pNeedle_cheatsheets, LIST, sheetsearch_x1, sheetsearch_y1, sheetsearch_x2, sheetsearch_y2, imagesearch_variation,, 1, 1) > 0) ;reference img-file was found in the screenshot
	{
		If (A_Gui = "settings_menu") ;if search was initiated from settings menu, save positive coordinates
		{
			Gdip_GetImageDimension(pNeedle_cheatsheets, width, height) ;get dimensions of the reference img-file
			cheatsheets_searchcoords_%parse% := LIST "," Format("{:0.0f}", width) "," Format("{:0.0f}", height) ;save string with last-known coordinates
			IniWrite, % cheatsheets_searchcoords_%parse%, % "cheat-sheets\"name "\info.ini", image search, last coordinates ;write string to ini-file
		}
		Gdip_DisposeImage(pNeedle_cheatsheets) ;clear reference-img file from memory
		Return 1
	}
	Else Gdip_DisposeImage(pNeedle_cheatsheets)
	Return 0
}

LLK_CheatSheetsAdvanced(name, object := "")
{
	global
	local parse := StrReplace(name, " ", "_"), wSnip, hSnip, panel1, panel2, panel3, panel4, result , result1, snip_ddl
	, trigger1 := (A_Gui != "") ? cheatsheet_selected1 : cheatsheet_triggered1, trigger := (A_Gui != "") ? cheatsheet_selected : cheatsheet_triggered
	
	If GetKeyState("RButton", "P") && (A_Gui != "cheatsheets_menu")
	{
		Clipboard := ""
		SendInput, #+{s}
		WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
		WinWaitNotActive, ahk_exe ScreenClippingHost.exe
		local pSnip := Gdip_CreateBitmapFromClipboard()
		
		If (pSnip <= 0)
		{
			LLK_ToolTip("screen-cap aborted")
			Return
		}
		Gdip_GetImageDimensions(pSnip, wSnip, hSnip)
		Gui, cheatsheets_calibration: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_cheatsheets_calibration
		Gui, cheatsheets_calibration: Margin, % font_width//2, % font_height//4
		Gui, cheatsheets_calibration: Color, Black
		Gui, cheatsheets_calibration: Font, cWhite s%fSize0% underline, Fontin SmallCaps
		
		local hbmSnip := CreateDIBSection(wSnip, hSnip)
		local hdcSnip := CreateCompatibleDC()
		local obmSnip := SelectObject(hdcSnip, hbmSnip)
		local gSnip := Gdip_GraphicsFromHDC(hdcSnip)
		Gdip_SetInterpolationMode(gSnip, 0)
		Gdip_DrawImage(gSnip, pSnip, 0, 0, wSnip, hSnip, 0, 0, wSnip, hSnip, 1)
		Gui, cheatsheets_calibration: Add, Picture, % "Section Border BackgroundTrans", HBitmap:*%hbmSnip%
		SelectObject(hdcSnip, obmSnip)
		DeleteObject(hbmSnip)
		DeleteDC(hdcSnip)
		Gdip_DeleteGraphics(gSnip)
		
		Loop, % cheatsheets_objects_%parse%.Length()
			snip_ddl .= cheatsheets_objects_%parse%[A_Index] "|"
		cheatsheets_calibration_choice := ""
		Gui, cheatsheets_calibration: Add, Text, % "Section BackgroundTrans", % "specify which object is linked to this screen-check"
		Gui, cheatsheets_calibration: Font, cWhite s%fSize0% norm
		Gui, cheatsheets_calibration: Add, ComboBox, % "Section xs BackgroundTrans wp-"font_width*5.5 " cBlack r"cheatsheets_objects_%parse%.Length() " vCheatsheets_calibration_choice", % snip_ddl
		Gui, cheatsheets_calibration: Add, Text, % "ys hp 0x200 BackgroundTrans Border Center w"font_width*5 " gCheatsheets vCheatsheets_calibration_save", % " save "
		Gui, cheatsheets_calibration: Add, Button, % "x0 y0 BackgroundTrans Hidden Default gCheatsheets vCheatsheets_calibration_save2", % "save"
		
		Gui, cheatsheets_calibration: Show
		While !cheatsheets_calibration_choice && !WinActive("ahk_id " hwnd_poe_client)
			sleep 50
		
		If cheatsheets_calibration_choice
		{
			Gdip_SaveBitmapToFile(pSnip, "cheat-sheets\" cheatsheet_triggered "\[check] " cheatsheets_calibration_choice ".bmp", 100)
			If !LLK_ArrayHasVal(cheatsheets_objects_%cheatsheet_triggered1%, cheatsheets_calibration_choice)
			{
				cheatsheets_objects_%cheatsheet_triggered1%.Push(cheatsheets_calibration_choice)
				cheatsheets_objects_%cheatsheet_triggered1% := LLK_SortArray(cheatsheets_objects_%cheatsheet_triggered1%)
				IniWrite, 1, % "cheat-sheets\" cheatsheet_triggered "\info.ini", objects, % cheatsheets_calibration_choice
			}
			If WinExist("ahk_id " hwnd_cheatsheets_menu)
			{
				cheatsheets_calibration_choice := ""
				Gdip_DisposeImage(pSnip)
				Gui, cheatsheets_calibration: Destroy
				cheatsheet_object_triggered := "", cheatsheet_object_triggered1 := ""
				cheatsheets_menuGuiClose()
				Return -1
			}
			cheatsheets_calibration_choice := ""
		}
		Else LLK_ToolTip("screen-cap aborted")
		Gdip_DisposeImage(pSnip)
		
		Gui, cheatsheets_calibration: Destroy
		Return
	}
	
	MouseGetPos, xMouse, yMouse
	local variation := cheatsheets_imgvariation_%parse%, x1Check := xMouse - xScreenOffset - poe_height/4, x2Check := xMouse - xScreenOffset + poe_height/4, y1Check := yMouse - yScreenOffset - poe_height/4, y2Check := yMouse - yScreenOffset + poe_height/4
	x1Check := (x1Check < xScreenOffset) ? 0 : x1Check, x2Check := (x2Check > poe_width) ? poe_width - 1 : x2Check, y1Check := (y1Check < yScreenOffset) ? 0 : y1Check, y2Check := (y2Check > poe_height) ? poe_height - 1 : y2Check
	
	If (A_Gui != "cheatsheets_menu")
	{
		local pHaystack_cheatsheets := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
		While GetKeyState(cheatsheets_hotkey, "P") && (variation <= 75)
		{
			ToolTip, checking..., xMouse + poe_width/100, yMouse, 1
			Loop, Files, % "cheat-sheets\" name "\[check] *.bmp"
			{
				local pNeedle_cheatsheets := Gdip_LoadImageFromFile(A_LoopFilePath)
				If (pNeedle_cheatsheets <= 0)
					Continue
				local rCheatsheets := Gdip_ImageSearch(pHaystack_cheatsheets, pNeedle_cheatsheets,, x1Check, y1Check, x2Check, y2Check, variation,,, 1)
				Gdip_DisposeImage(pNeedle_cheatsheets)
				If (rCheatsheets > 0)
				{
					result := StrReplace(A_LoopFileName, "." A_LoopFileExt), result := SubStr(result, InStr(result, "[check] ") + 8), result1 := StrReplace(result, " ", "_")
					Break 2
				}
			}
			variation += 10
		}
		Gdip_DisposeImage(pHaystack_cheatsheets)
		ToolTip,,,, 1
	}
	Else
	{
		result := object, result1 := StrReplace(object, " ", "_")
		Gui, cheatsheets_menu: Submit, NoHide
	}
	
	If result && (variation > cheatsheets_imgvariation_%parse%_ini)
	{
		cheatsheets_imgvariation_%parse% := variation
		cheatsheets_imgvariation_%parse%_ini := variation
		IniWrite, % variation, % "cheat-sheets\" name "\info.ini", general, image search variation
	}
	cheatsheet_object_triggered := result, cheatsheet_object_triggered1 := result1 ;need to be global in order to keep ranking-hotkeys functional
	
	If !result
	{
		LLK_ToolTip("no match")
		Return
	}
	
	If result && WinExist("ahk_id " hwnd_cheatsheets_menu) && cheatsheet_object_selected
	{
		Gui, cheatsheets_menu: Submit, NoHide
		Loop 4
		{
			cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
			IniWrite, % """" StrReplace(cheatsheets_edit_panel%A_Index%, "`n", "^^^") """", % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%
		}
	}
	
	Loop 4
		panel%A_Index% := cheatsheets_%trigger1%_object_%result1%_panel%A_Index%
	
	If (panel1 panel2 panel3 panel4 = "")
	{
		If (A_Gui != "cheatsheets_menu")
			LLK_ToolTip("object """result """ was`nfound but has no text", 2)
		Else LLK_ToolTip("object """result """ has no text", 2)
		Return -1
	}
	
	local style, height1 := 0, height2 := 0, height3 := 0, height4 := 0, height_max, width1, width2, width3, width4
	cheatsheet_overlay_advanced := 1
	Loop 2
	{
		Gui, cheatsheet: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_cheatsheet
		Gui, cheatsheet: Color, Black
		Gui, cheatsheet: Margin, 0, 0
		WinSet, Transparent, 255
		Gui, cheatsheet: Font, s%fSize_cheatsheets% cWhite, Fontin SmallCaps
		
		Loop, Parse, % panel1 "^" panel2 "^" panel3 "^" panel4, `^
		{
			If (A_LoopField = "")
				continue
			If height_max
				style := "h"height_max
			If !InStr(A_LoopField, "`n")
				style .= " 0x200"
			style .= (width%A_Index% != "") ? " w"width%A_Index% + font_width_cheatsheets : ""
			color := cheatsheets_panel_colors[cheatsheets_rank_%cheatsheet_object_triggered1%_panel%A_Index%]
			Gui, cheatsheet: Add, Text, % "Section "style " c"color " ys Border BackgroundTrans Center HWNDhwnd_cheatsheets_overlay_panel"A_Index " vcheatsheets_overlay_panel"A_Index, % StrReplace(A_LoopField, "&", "&&")
			ControlGetPos,,, width%A_Index%, height%A_Index%,, % "ahk_id " hwnd_cheatsheets_overlay_panel%A_Index% ;panels have an HWND in order to check if cursor is hovering over them
		}
		height_max := Max(height1, height2, height3, height4)
	}
	
	Gui cheatsheet: Show, NA x10000 y10000
	WinGetPos,,, width1, height1, ahk_id %hwnd_cheatsheet%
	If (xMouse - width1/2 < xScreenOffset)
		local xPos := xScreenOffset
	Else local xPos := (xMouse + width1/2 > xScreenOffset + poe_width) ? xScreenOffset + poe_width - width1 : xMouse - width1/2
	local yPos := (yMouse - height1 < yScreenOffset) ? yScreenOffset : yMouse - height1
	Gui cheatsheet: Show, NA x%xPos% y%yPos%
	LLK_Overlay("cheatsheet", "show")
	If (A_Gui != "cheatsheets_menu")
		LLK_ToolTip(cheatsheet_object_triggered, 0.75, xPos, yMouse)
	
	If (cheatsheets_activation_%trigger1% = "hold") && (cheatsheet_toggle_check < 2)
	{
		KeyWait, % cheatsheets_hotkey
		If (A_Gui = "cheatsheets_menu")
			KeyWait, LButton
		;Gui, cheatsheet: Destroy
		;hwnd_cheatsheet := ""
		LLK_Overlay("cheatsheet", "hide")
		cheatsheet_overlay_type := "advanced"
		cheatsheet_overlay_advanced := 0
		cheatsheet_triggered1 := "", cheatsheet_triggered := ""
	}
}

LLK_CheatSheetsPreview(filename, mouse := 0)
{
	global xScreenOffset, yScreenOffset, poe_width, poe_height, hwnd_cheatsheets_tooltip, height_native, width_native
	MouseGetPos, cheatsheets_xMouse, cheatsheets_yMouse
	If !FileExist(filename)
	{
		LLK_ToolTip("file doesn't exist")
		Return
	}
	Gui, cheatsheets_tooltip: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_cheatsheets_tooltip
	Gui, cheatsheets_tooltip: Margin, 0, 0
	Gui, cheatsheets_tooltip: Color, Black
	;WinSet, TransColor, EEAA99
	Gui, cheatsheets_tooltip: Font, cWhite s%fSize1%, Fontin SmallCaps
	cheatsheets_preview_file := ""
	Loop, Files, % filename
	{
		If InStr("jpg,bmp,png", A_LoopFileExt)
		{
			cheatsheets_preview_file := A_LoopFilePath
			Break
		}
	}
	pCheatsheet := Gdip_LoadImageFromFile(cheatsheets_preview_file)
	If (pCheatsheet <= 0)
	{
		LLK_ToolTip("couldn't load img-file", 1.5)
		Return
	}
	Else
	{
		Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
		
		If (hCheatsheet > height_native*0.9)
		{
			cheatsheet_ratio := (height_native * 0.9) / hCheatsheet
			pCheatsheet_copy := pCheatsheet
			pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, cheatsheet_ratio * wCheatsheet, cheatsheet_ratio * hCheatsheet, 1, 7)
			Gdip_DisposeImage(pCheatsheet_copy)
		}
		Else If (wCheatsheet > width_native*0.9)
		{
			pCheatsheet_copy := pCheatsheet
			pCheatsheet := Gdip_ResizeBitmap(pCheatsheet_copy, width_native * 0.9, 10000, 1, 7)
			Gdip_DisposeImage(pCheatsheet_copy)
		}
		
		Gdip_GetImageDimensions(pCheatsheet, wCheatsheet, hCheatsheet)
		
		hbmCheatsheet := CreateDIBSection(wCheatsheet, hCheatsheet)
		hdcCheatsheet := CreateCompatibleDC()
		obmCheatsheet := SelectObject(hdcCheatsheet, hbmCheatsheet)
		gCheatsheet := Gdip_GraphicsFromHDC(hdcCheatsheet)
		Gdip_SetInterpolationMode(gCheatsheet, 0)
		Gdip_DrawImage(gCheatsheet, pCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 0, 0, wCheatsheet, hCheatsheet, 1)
		Gui, cheatsheets_tooltip: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmCheatsheet%
		SelectObject(hdcCheatsheet, obmCheatsheet)
		DeleteObject(hbmCheatsheet)
		DeleteDC(hdcCheatsheet)
		Gdip_DeleteGraphics(gCheatsheet)
		Gdip_DisposeImage(pCheatsheet)
		If mouse
		{
			Gui, cheatsheets_tooltip: Show, NA x10000 y10000
			WinGetPos,,, width, height, ahk_id %hwnd_cheatsheets_tooltip%
			xPos := (cheatsheets_xMouse - xScreenOffset + width > poe_width) ? xScreenOffset + poe_width - width : cheatsheets_xMouse
			yPos := (cheatsheets_yMouse - yScreenOffset + height > poe_height) ? yScreenOffset + poe_height - height : cheatsheets_yMouse
			Gui, cheatsheets_tooltip: Show, NA x%xPos% y%yPos%
		}
		Else Gui, cheatsheets_tooltip: Show, NA
	}
	KeyWait, LButton
	Gui, cheatsheets_tooltip: Destroy
	hwnd_cheatsheets_tooltip := ""
}

LLK_CheatSheetsFontPreview()
{
	global fSize_cheatsheets, font_width, font_height
	MouseGetPos, xCheatsheet, yCheatsheet
	Gui, cheatsheets_preview: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
	Gui, cheatsheets_preview: Margin, 0, 0
	Gui, cheatsheets_preview: Color, Black
	Gui, cheatsheets_preview: Font, cWhite s%fSize_cheatsheets%, Fontin SmallCaps
	Gui, cheatsheets_preview: Add, Text, % "BackgroundTrans Border", % " sample text `n sample text "
	Gui, cheatsheets_preview: Show, % "NA x"xCheatsheet + font_width//2 " y"yCheatsheet + font_height//4
	SetTimer, LLK_CheatSheetsFontPreview2, -2000
}

LLK_CheatSheetsFontPreview2()
{
	global fSize_cheatsheets
	IniWrite, % fSize_cheatsheets, ini\cheat-sheets.ini, settings, font size
	Gui, cheatsheets_preview: Destroy
}

cheatsheets_menuGuiClose()
{
	global
	Gui, cheatsheets_menu: Submit, NoHide
	If (cheatsheets_edit_apptitle != "") && (cheatsheets_edit_apptitle != "A")
	{
		cheatsheets_apptitle_%cheatsheet_selected1% := cheatsheets_edit_apptitle
		IniWrite, % cheatsheets_edit_apptitle, % "cheat-sheets\" cheatsheet_selected "\info.ini", general, app title
		cheatsheets_edit_apptitle := ""
	}
	
	If (cheatsheets_type_%cheatsheet_selected1% = "advanced") && (cheatsheet_object_selected != "")
	{
		Loop 4
		{
			cheatsheets_%cheatsheet_selected1%_object_%cheatsheet_object_selected1%_panel%A_Index% := cheatsheets_edit_panel%A_Index%
			IniWrite, % """" StrReplace(cheatsheets_edit_panel%A_Index%, "`n", "^^^") """", % "cheat-sheets\" cheatsheet_selected "\info.ini", % cheatsheet_object_selected, panel %A_Index%
		}
	}
	
	xCheatsheets_menu := "", yCheatsheets_menu := ""
	Gui, snip: Destroy
	hwnd_snip := ""
	Gui, cheatsheets_menu: Destroy
	hwnd_cheatsheets_menu := ""
	cheatsheet_object_selected := ""
	WinWaitActive, ahk_group poe_window
	LLK_Overlay("settings_menu", "show")
}