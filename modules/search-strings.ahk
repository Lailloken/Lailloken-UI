Init_searchstrings:
If !FileExist("ini\search-strings.ini")
{
	IniWrite, 1, ini\search-strings.ini, searches, beast crafting
	IniWrite, % "", ini\search-strings.ini, beast crafting, last coordinates
	IniWrite, "warding", ini\search-strings.ini, beast crafting, 00-flasks: curse
	IniWrite, "sealing|lizard", ini\search-strings.ini, beast crafting, 00-flasks: bleed
	IniWrite, "earthing|conger", ini\search-strings.ini, beast crafting, 00-flasks: shock
	IniWrite, "convection|deer", ini\search-strings.ini, beast crafting, 00-flasks: freeze
	IniWrite, "damping|urchin", ini\search-strings.ini, beast crafting, 00-flasks: ignite
	IniWrite, "antitoxin|skunk", ini\search-strings.ini, beast crafting, 00-flasks: poison
}

IniRead, stash_search_list, ini\search-strings.ini, searches,, % A_Space
Sort, stash_search_list, D`n

searchstrings_enabled := []
Loop, Parse, stash_search_list, `n
{
	If (A_Index = 1)
		stash_search_list := []
	If (A_LoopField = "")
		continue
	parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), parse1 := StrReplace(parse, " ", "_")
	stash_search_list.Push(parse)
	searchstrings_enable_%parse1% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
	If searchstrings_enable_%parse1%
		searchstrings_enabled.Push(parse)
}
LLK_SortArray(stash_search_list)

Loop, % stash_search_list.Length()
{
	parse := StrReplace(stash_search_list[A_Index], " ", "_")
	IniRead, searchstrings_searchcoords_%parse%, ini\search-strings.ini, % stash_search_list[A_Index], last coordinates, % A_Space
	
	IniRead, parse_ini, ini\search-strings.ini, % stash_search_list[A_Index],, % A_Space
	searchstrings_%parse%_contents := {}
	Loop, Parse, parse_ini, `n
	{
		If (A_LoopField = "") || InStr(A_LoopField, "last coordinates")
			continue
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
		value := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		value := (SubStr(value, 1, 1) = """") ? SubStr(value, 2, -1) : value ;check for redundant quote-marks due to improper key-reading
		searchstrings_%parse%_contents[key] := StrReplace(value, " " ";;;" " ", "`n")
	}
}
Return

Stash_search:
If WinExist("ahk_id " hwnd_settings_menu)
	Gui, settings_menu: Submit, NoHide

If InStr(A_GuiControl, "searchstrings_enable_") ;toggling the checkbox
{
	parse := StrReplace(StrReplace(A_GuiControl, "searchstrings_enable_"), "_", " "), parse1 := StrReplace(A_GuiControl, "searchstrings_enable_")
	IniWrite, % %A_GuiControl%, ini\search-strings.ini, searches, % parse
	If (%A_GuiControl% = 0)
		GuiControl, settings_menu: +cWhite, % "settings_menu_searchstrings_entry_"parse1
	Else
	{
		If !searchstrings_searchcoords_%parse1%
			GuiControl, settings_menu: +cRed, % "settings_menu_searchstrings_entry_"parse1
	}
	GuiControl, settings_menu: movedraw, % "settings_menu_searchstrings_entry_"parse1
	GoSub, Init_searchstrings
	Return
}
If (A_GuiControl = "settings_menu_searchstrings_add") ;hitting enter to add a new search
{
	WinGetPos, xPos_settings_menu_searchstrings_edit, yPos_settings_menu_searchstrings_edit,, height_settings_menu_searchstrings_edit, ahk_id %hwnd_settings_menu_searchstrings_edit%
	newname_check := LLK_AddEntry(settings_menu_searchstrings_newname)
	If IsNumber(newname_check)
		Return
	IniWrite, 1, ini\search-strings.ini, searches, % newname_check
	GoSub, Settings_menu
	Return
}
If InStr(A_GuiControl, "settings_menu_searchstrings_test_") ;clicking <test>
{
	pHaystack_searchstrings := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	rSearchstrings := LLK_StringSearch(StrReplace(A_GuiControl, "settings_menu_searchstrings_test_"))
	If rSearchstrings
	{
		LLK_ToolTip("test positive")
		GuiControl, settings_menu: +cWhite, % "settings_menu_searchstrings_entry_"StrReplace(A_GuiControl, "settings_menu_searchstrings_test_")
		GuiControl, settings_menu: movedraw, % "settings_menu_searchstrings_entry_"StrReplace(A_GuiControl, "settings_menu_searchstrings_test_")
	}
	Gdip_DisposeImage(pHaystack_searchstrings)
	Return
}
If InStr(A_GuiControl, "settings_menu_searchstrings_calibrate_") ;clicking <calibrate>
{
	LLK_StringSnip(StrReplace(A_GuiControl, "settings_menu_searchstrings_calibrate_"))
	Return
}
If InStr(A_GuiControl, "settings_menu_searchstrings_entry_") ;clicking an entry
{
	pEntry := StrReplace(A_GuiControl, "settings_menu_searchstrings_entry_")
	If (click = 1)
		LLK_StringMenu(pEntry)
	Else
	{
		If (SubStr(A_GuiControl, -13) = "beast_crafting")
		{
			LLK_ToolTip("default searches cannot be removed", 1.5)
			Return
		}
		If LLK_ProgressBar("settings_menu", "settings_menu_searchstrings_delprogress_"pEntry)
		{
			FileDelete, % "img\Recognition ("poe_height "p)\GUI\[search-strings] "StrReplace(pEntry, "_", " ") ".bmp"
			IniDelete, ini\search-strings.ini, searches, % StrReplace(pEntry, "_", " ")
			IniDelete, ini\search-strings.ini, % StrReplace(pEntry, "_", " ")
			GoSub, Settings_menu
		}
		KeyWait, RButton
	}
	Return
}
Return

LLK_StringActivate(name)
{
	global
	local parse := StrReplace(name, " ", "_"), text, xMouse, yMouse, xWin, yWin, width, height, key, value
	
	If (searchstrings_%searchstring_activated1%_contents.Count() = 1)
	{
		For key, value in searchstrings_%searchstring_activated1%_contents
			LLK_StringPick(key)
		Return
	}
	
	MouseGetPos, xMouse, yMouse
	Gui, searchstrings_contextmenu: New, -DPIScale -caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_searchstrings_contextmenu
	Gui, searchstrings_contextmenu: Color, Black
	Gui, searchstrings_contextmenu: Margin, % font_width//2, % font_height/8
	;WinSet, Transparent, %trans%
	Gui, searchstrings_contextmenu: Font, s%fSize0% cWhite, Fontin SmallCaps
	
	For key, value in searchstrings_%parse%_contents
	{
		style := (A_Index = 1) ? "Section" : "xs"
		Gui, searchstrings_contextmenu: Add, Text, % style " BackgroundTrans gLLK_StringPick", % (SubStr(key, 1, 3) = "00-") ? SubStr(key, 4) : key
	}
	
	Gui, searchstrings_contextmenu: Show, NA x10000 y10000
	WinGetPos, xWin, yWin, width, height, ahk_id %hwnd_searchstrings_contextmenu%
	
	xMouse := (xMouse - xScreenOffset + width > poe_width) ? xScreenOffset + poe_width - width : xMouse
	yMouse := (yMouse - yScreenOffset + height > poe_height) ? yScreenOffset + poe_height - height : yMouse
	
	Gui, searchstrings_contextmenu: Show, x%xMouse% y%yMouse%
	WinWaitNotActive, ahk_id %hwnd_searchstrings_contextmenu%
	Gui, searchstrings_contextmenu: Destroy
	hwnd_searchstrings_contextmenu := ""
}

LLK_StringPick(name := "")
{
	global
	local parse := searchstring_activated, parse1 := StrReplace(searchstring_activated, " ", "_"), check0 := A_GuiControl ? A_GuiControl : name, check := searchstrings_%parse1%_contents.HasKey("00-" check0) ? "00-" : "", string := searchstrings_%parse1%_contents[check check0]
	
	If (name = "exile leveling")
		string := stash_search_string_leveling
	
	KeyWait, LButton
	Gui, searchstrings_contextmenu: Destroy
	hwnd_searchstrings_contextmenu := ""
	If !InStr(string, "`n") && !InStr(string, ";")
	{
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		Clipboard := string
		SendInput, ^{f}
		sleep 100
		SendInput, ^{v}{Enter}
		Return
	}
	Else If InStr(string, "`n")
	{
		searchstrings_scroll_contents := []
		searchstrings_scroll_index := 1
		Loop, Parse, string, `n
			searchstrings_scroll_contents.Push(A_LoopField)
		Clipboard := searchstrings_scroll_contents[1]
	}
	Else
	{
		searchstrings_scroll_contents := string
		searchstrings_scroll_number := SubStr(string, InStr(string, ";") + 1), searchstrings_scroll_number := SubStr(searchstrings_scroll_number, 1, InStr(searchstrings_scroll_number, ";") - 1)
		searchstrings_scroll_index := 0
		Clipboard := StrReplace(searchstrings_scroll_contents, ";")
	}
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, ^{f}
	sleep 100
	SendInput, ^{v}{Enter}
	SetTimer, LLK_StringScroll, 100
}

LLK_StringScroll()
{
	global
	local text := IsObject(searchstrings_scroll_contents) ? " " searchstrings_scroll_index "/" searchstrings_scroll_contents.Count() : ""
	If WinExist("ahk_id " hwnd_leveling_guide2)
	{
		If InStr(stash_search_string_leveling_gems, searchstrings_scroll_contents[searchstrings_scroll_index])
			text .= " (gems)"
		Else If InStr(stash_search_string_leveling_items, searchstrings_scroll_contents[searchstrings_scroll_index])
			text .= " (items)"
	}
	
	If !searchstrings_scroll_contents || !WinActive("ahk_group poe_window")
	{
		searchstrings_scroll_contents := ""
		ToolTip,,,, 11
		SetTimer, LLK_StringScroll, Delete
		Return
	}
	ToolTip, % "          scrolling..." text "`n          (ESC to exit)",,, 11
}

LLK_StringMenu(name)
{
	global
	local name1 := name, key, value, main_text, style, cEntry, xPos, yPos, width, height, xPos_max := 0, parse
	searchstring_selected1 := name
	name := StrReplace(name, "_", " ")
	searchstring_selected := name
	LLK_Overlay("settings_menu", "hide")
	
	xsearchstrings_menu := ""
	
	If WinExist("ahk_id " hwnd_searchstrings_menu)
	{
		WinGetPos, xsearchstrings_menu, ysearchstrings_menu,,, ahk_id %hwnd_searchstrings_menu%
		;searchstrings_menuGuiClose()
	}
	Gui, searchstrings_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_searchstrings_menu, Lailloken UI: search-string configuration
	Gui, searchstrings_menu: Color, Black
	Gui, searchstrings_menu: Margin, % font_width//2, % font_height//4
	;WinSet, Transparent, %trans%
	Gui, searchstrings_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
	;Gui, cheatsheets_menu: Add, Text, % "Section Center BackgroundTrans w"font_width*50,
	Gui, searchstrings_menu: Add, Text, % "Section cSilver Center BackgroundTrans", % "name:"
	Gui, searchstrings_menu: Add, Text, % "ys Center BackgroundTrans HWNDmain_text", % name
	WinGetPos, xPos, yPos, width, height, ahk_id %main_text%
	xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max
	
	IniRead, parse, ini\search-strings.ini, % name,, % A_Space
	searchstrings_%name1%_contents := {}
	Loop, Parse, parse, `n
	{
		If (A_LoopField = "") || InStr(A_LoopField, "last coordinates")
			continue
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
		value := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		value := (SubStr(value, 1, 1) = """") ? SubStr(value, 2, -1) : value ;check for redundant quote-marks due to improper key-reading
		searchstrings_%name1%_contents[key] := StrReplace(value, " " ";;;" " ", "`n")
	}
	
	searchstrings_entries := []
	For key, value in searchstrings_%name1%_contents
	{
		If (A_Index = 1)
		{
			Gui, searchstrings_menu: Add, Text, % "Section xs cSilver Center BackgroundTrans", % "list of entries: "
			Gui, searchstrings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vsearchstrings_entrylist_help hp w-1", img\GUI\help.png
		}
		searchstrings_entries.Push(key)
		style := (A_Index = 1) ? "y+0" : "y+"font_height/6
		;cEntry := (SubStr(key, 1, 3) != "00-") ? "cWhite gLLK_StringMenuPaste" : "cRed"
		;Gui, searchstrings_menu: Add, Text, % "Section xs "style " Border Center "cEntry " vsearchstrings_paste"A_Index " BackgroundTrans", % " paste "
		cEntry := (SubStr(key, 1, 3) != "00-") ? "cWhite gLLK_StringMenuDelete" : "cRed"
		Gui, searchstrings_menu: Add, Text, % "Section xs Border "style " Center "cEntry " vsearchstrings_delete"A_Index " BackgroundTrans", % " del "
		Gui, searchstrings_menu: Add, Progress, % "ys x+0 hp range0-400 vertical w"font_width/2 " BackgroundBlack cRed vsearchstrings_deletebar"A_Index,
		Gui, searchstrings_menu: Font, underline
		cEntry := (value = "") ? "cRed" : "cWhite", cEntry := (key = searchstring_entry_selected) ? "cFuchsia" : cEntry
		Gui, searchstrings_menu: Add, Text, % "ys x+0 Center "cEntry " BackgroundTrans HWNDmain_text gLLK_StringMenuSelect vsearchstrings_entry"A_Index, % (SubStr(key, 1, 3) = "00-") ? SubStr(key, 4) : key
		WinGetPos, xPos,, width,, ahk_id %main_text%
		xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max
		Gui, searchstrings_menu: Font, norm
	}
	Gui, searchstrings_menu: Add, Text, % "Section xs cSilver y+"font_height*0.8 " BackgroundTrans", % "add new entry: "
	Gui, searchstrings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vsearchstrings_entryadd_help hp w-1", img\GUI\help.png
	Gui, searchstrings_menu: Font, % "s"fSize0 - 4
	Gui, searchstrings_menu: Add, Edit, % "xs hp y+0 w"font_width*20 " hp cBlack vsearchstrings_newentry HWNDhwnd_searchstrings_menu_edit BackgroundTrans",
	WinGetPos, xPos,, width,, ahk_id %hwnd_searchstrings_menu_edit%
	xPos_max := (xPos + width > xPos_max) ? xPos + width : xPos_max
	Gui, searchstrings_menu: Font, % "s"fSize0
	Gui, searchstrings_menu: Add, Button, hidden x0 y0 default gLLK_StringMenuAdd, ok
	style := (searchstring_entry_selected = "") || (SubStr(searchstring_entry_selected, 1, 3) = "00-") ? "ReadOnly cRed" : "cBlack"
	Gui, searchstrings_menu: Add, Edit, % "x"xPos_max + font_width/2 " y"yPos - height " Border "style " BackgroundTrans vsearchstrings_string_edit w"font_width*55 " h"font_height*12, % searchstring_entry_selected ? searchstrings_%searchstring_selected1%_contents[searchstring_entry_selected] : ""
	;Gui, searchstrings_menu: Add, Text, % "Section ys hp x+"font_width/4 " Border Center gLLK_StringMenuAdd BackgroundTrans", % " add "
	style := (xsearchstrings_menu = "") ? "xCenter yCenter" : "x"xsearchstrings_menu " y"ysearchstrings_menu
	Gui, searchstrings_menu: Show, %style%
}

LLK_StringMenuAdd()
{
	global
	local xPos, yPos, height
	
	Gui, searchstrings_menu: Submit, NoHide
	Gui, searchstrings_rename: Submit, NoHide
	
	If (A_Gui = "searchstrings_rename")
	{
		searchstrings_newentry := searchstrings_renameentry
		WinGetPos, xPos, yPos,, height, ahk_id %hwnd_searchstrings_rename_edit%
	}
	Else WinGetPos, xPos, yPos,, height, ahk_id %hwnd_searchstrings_menu_edit%
		
	searchstrings_newentry := StrReplace(searchstrings_newentry, "&", "&&")
	
	While (SubStr(searchstrings_newentry, 1, 1) = " ")
		searchstrings_newentry := SubStr(searchstrings_newentry, 2)
	While (SubStr(searchstrings_newentry, 0) = " ")
		searchstrings_newentry := SubStr(searchstrings_newentry, 1, -1)
	Loop, Parse, searchstrings_newentry
	{
		If !LLK_IsAlnum(A_LoopField) && !InStr(" :()/&%$?'#<>@+-*", A_LoopField)
		{
			LLK_ToolTip("cannot contain special characters", 1.5, xPos, yPos+ height)
			Return
		}
	}
	If (searchstrings_newentry = "")
	{
		LLK_ToolTip("name cannot be blank",, xPos, yPos+ height)
		Return
	}
	If (searchstrings_newentry = "last coordinates")
	{
		LLK_ToolTip("name is prohibited",, xPos, yPos+ height)
		Return
	}
	If searchstrings_%searchstring_selected1%_contents.HasKey(searchstrings_newentry) || searchstrings_%searchstring_selected1%_contents.HasKey("00-" searchstrings_newentry)
	{
		LLK_ToolTip("entry already exists",, xPos, yPos+ height)
		Return
	}
	
	LLK_StringMenuSave()
	
	If (A_Gui = "searchstrings_rename") ;if an entry-rename was initiated
	{
		local parse := searchstrings_%searchstring_selected1%_contents[searchstring_entryrename_selected] ;load the saved string for that entry
		searchstrings_renameentry := StrReplace(searchstrings_renameentry, "&", "&&")
		If (searchstring_entryrename_selected = searchstring_entry_selected) ;if the entry to be renamed is also the currently selected one, read the current state of the edit-field (so unsaved changes are not lost)
		{
			parse := searchstrings_string_edit
			searchstring_entry_selected := searchstrings_renameentry
		}
		While parse && InStr(" `n", SubStr(parse, 1, 1)) ;remove whitespace
			parse := SubStr(parse, 2)
		While parse && InStr(" `n", SubStr(parse, 0)) ;remove whitespace
			parse := SubStr(parse, 1, -1)
		Loop, Parse, parse, `n ;clean up empty lines in between
		{
			If (A_Index = 1)
				parse := ""
			If (A_LoopField = "")
				continue
			parse .= (parse = "") ? A_LoopField : "`n" A_LoopField
		}
		searchstrings_%searchstring_selected1%_contents[searchstrings_renameentry] := parse
		parse := StrReplace(parse, "`n", " " ";;;" " ")
		IniWrite, "%parse%", ini\search-strings.ini, % searchstring_selected, % searchstrings_renameentry
		IniDelete, ini\search-strings.ini, % searchstring_selected, % searchstring_entryrename_selected
		searchstrings_%searchstring_selected1%_contents.Delete(searchstring_entryrename_selected)
		Gui, searchstrings_rename: Destroy
		hwnd_searchstrings_rename := ""
	}
	Else IniWrite, % "", ini\search-strings.ini, % searchstring_selected, % searchstrings_newentry
	LLK_StringMenu(searchstring_selected1)
}

LLK_StringMenuDelete()
{
	global
	local parse := StrReplace(A_GuiControl, "searchstrings_delete")
	If LLK_ProgressBar("searchstrings_menu", "searchstrings_deletebar"parse )
	{
		LLK_StringMenuSave()
		IniDelete, ini\search-strings.ini, % searchstring_selected, % searchstrings_entries[parse]
		If (searchstring_entry_selected = searchstrings_entries[parse]) ;if the string to be deleted is also the currently-selected one, clear selected string
			searchstring_entry_selected := ""
		LLK_StringMenu(searchstring_selected1)
		KeyWait, LButton
	}
}

LLK_StringMenuPaste() ;there used to be a <paste> button
{
	global
	local parse := StrReplace(A_GuiControl, "searchstrings_paste"), parse1
	If (Clipboard = "")
	{
		LLK_ToolTip("clipboard is blank")
		Return
	}
	If InStr(Clipboard, "`n")
	{
		LLK_ToolTip("clipboard contains line-breaks")
		Return
	}
	If (SubStr(Clipboard, 1, 1) = ";")
	{
		LLK_ToolTip("incorrect use of semi-colons")
		Return
	}
	If (click = 1) || (searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]] = "")
	{
		IniWrite, "%Clipboard%", ini\search-strings.ini, % searchstring_selected, % searchstrings_entries[parse]
		searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]] := Clipboard
		LLK_ToolTip("pasted: " Clipboard, 2)
	}
	Else
	{
		If InStr(searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]], Clipboard)
		{
			LLK_ToolTip("sub-string already added")
			Return
		}
		If IsNumber(Clipboard)
		{
			LLK_ToolTip("cannot add numbers as sub-strings", 1.5)
			Return
		}
		parse1 := searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]] ";" Clipboard
		IniWrite, "%parse1%", ini\search-strings.ini, % searchstring_selected, % searchstrings_entries[parse]
		searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]] := parse1
		LLK_ToolTip("added: " Clipboard, 2)
	}
	GuiControl, searchstrings_menu: +cWhite, searchstrings_entry%parse%
	GuiControl, searchstrings_menu: movedraw, searchstrings_entry%parse%
}

LLK_StringMenuRename()
{
	global
	local xMouse, yMouse
	local parse := StrReplace(A_GuiControl, "searchstrings_entry")
	searchstring_entryrename_selected := searchstrings_entries[parse]
	If (SubStr(searchstring_entryrename_selected, 1, 3) = "00-") || (searchstring_entryrename_selected = "exile leveling gems")
	{
		LLK_ToolTip("default entries cannot be renamed", 1.5)
		Return
	}
	MouseGetPos, xMouse, yMouse
	Gui, searchstrings_rename: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_searchstrings_rename, Rename entry
	Gui, searchstrings_rename: Color, Black
	Gui, searchstrings_rename: Margin, % font_width//2, % font_height//4
	;WinSet, Transparent, %trans%
	Gui, searchstrings_rename: Font, % "s"fSize0 - 4 " cWhite", Fontin SmallCaps
	Gui, searchstrings_rename: Add, Edit, % "Section w"font_width*20 " cBlack vsearchstrings_renameentry HWNDhwnd_searchstrings_rename_edit BackgroundTrans",
	Gui, searchstrings_rename: Font, % "s"fSize0
	Gui, searchstrings_rename: Add, Button, wp hp hidden x0 y0 default gLLK_StringMenuAdd, ok
	Gui, searchstrings_rename: Show, x%xMouse% y%yMouse%
}

LLK_StringMenuSave()
{
	global
	local key, value
	
	Gui, searchstrings_menu: Submit, NoHide
	searchstrings_newentry := StrReplace(searchstrings_newentry, "&", "&&")
	While searchstrings_string_edit && InStr(" `n", SubStr(searchstrings_string_edit, 1, 1))
		searchstrings_string_edit := SubStr(searchstrings_string_edit, 2)
	While searchstrings_string_edit && InStr(" `n", SubStr(searchstrings_string_edit, 0))
		searchstrings_string_edit := SubStr(searchstrings_string_edit, 1, -1)
	Loop, Parse, searchstrings_string_edit, `n
	{
		If (A_Index = 1)
			searchstrings_string_edit := ""
		If (A_LoopField = "")
			continue
		searchstrings_string_edit .= (searchstrings_string_edit = "") ? A_LoopField : "`n" A_LoopField
	}
	
	If (searchstring_entry_selected != "")
		searchstrings_%searchstring_selected1%_contents[searchstring_entry_selected] := searchstrings_string_edit
	For key, value in searchstrings_%searchstring_selected1%_contents
	{
		If (SubStr(key, 1, 3) = "00-")
			continue
		IniRead, parse, ini\search-strings.ini, % searchstring_selected, % key, % A_Space
		While value && InStr(" `n", SubStr(value, 1, 1))
			value := SubStr(value, 2)
		While value && InStr(" `n", SubStr(value, 0))
			value := SubStr(value, 1, -1)
		
		value := StrReplace(value, "`n", " " ";;;" " ")
		If (parse != value)
			IniWrite, "%value%", ini\search-strings.ini, % searchstring_selected, % key
	}
}

LLK_StringMenuSelect()
{
	global
	
	If (click = 2)
	{
		LLK_StringMenuRename()
		Return
	}
	local parse := StrReplace(A_GuiControl, "searchstrings_entry"), color
	
	LLK_StringMenuSave()
	
	searchstring_entry_selected := searchstrings_entries[parse]
	Loop, % searchstrings_entries.Length()
	{
		color := (searchstrings_%searchstring_selected1%_contents[searchstrings_entries[A_Index]] = "") ? "Red" : "White"
		GuiControl, searchstrings_menu: +c%color%, searchstrings_entry%A_Index%
		GuiControl, searchstrings_menu: movedraw, searchstrings_entry%A_Index%
	}
	GuiControl, searchstrings_menu: +cFuchsia, % "searchstrings_entry"parse
	GuiControl, searchstrings_menu: movedraw, % "searchstrings_entry"parse
	If (SubStr(searchstring_entry_selected, 1, 3) = "00-")
		GuiControl, searchstrings_menu: +ReadOnly +cRed, searchstrings_string_edit
	Else GuiControl, searchstrings_menu: -ReadOnly +cBlack, searchstrings_string_edit
	GuiControl, searchstrings_menu: movedraw, searchstrings_string_edit
	GuiControl, searchstrings_menu: text, searchstrings_string_edit, % searchstrings_%searchstring_selected1%_contents[searchstring_entry_selected]
}

LLK_StringMenuTooltip() ;there used to be a tooltip when long-clicking an entry
{
	global
	If (click = 2)
	{
		LLK_StringMenuRename()
		Return
	}
	local xMouse, yMouse, width, height, number_scroll := 0
	local parse := StrReplace(A_GuiControl, "searchstrings_entry")
	If (searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]] = "")
		Return
	MouseGetPos, xMouse, yMouse
	Gui, searchstrings_tooltip: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, searchstrings_tooltip: Color, Black
	Gui, searchstrings_tooltip: Margin, % font_width//2, % font_height//4
	;WinSet, Transparent, %trans%
	Gui, searchstrings_tooltip: Font, s%fSize0% cWhite underline, Fontin SmallCaps
	Gui, searchstrings_tooltip: Add, Text, % "Section BackgroundTrans Center", % InStr(searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]], ";") ? "advanced search:" : "regular search:"
	Gui, searchstrings_tooltip: Font, norm
	Loop, Parse, % searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]], `; ;check if search contains scrollable number
	{
		If (A_LoopField = "")
			continue
		If IsNumber(A_LoopField)
		{
			number_scroll := 1
			break
		}
	}
	If !number_scroll
	{
		Loop, Parse, % searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]], `;
		{
			If (A_LoopField = "")
				continue
			Gui, searchstrings_tooltip: Add, Text, % "Section xs BackgroundTrans Center", % A_LoopField
		}
	}
	Else Gui, searchstrings_tooltip: Add, Text, % "Section xs BackgroundTrans Center", % StrReplace(searchstrings_%searchstring_selected1%_contents[searchstrings_entries[parse]], ";")
	Gui, searchstrings_tooltip: Show, NA x10000 y10000
	WinGetPos,,, width, height
	Gui, searchstrings_tooltip: Show, % "NA x"xMouse " y"yMouse - height
	KeyWait, LButton
	Gui, searchstrings_tooltip: Destroy
}

LLK_StringSearch(name) ;checks the screen for string-related UI elements
{
	global
	local parse := StrReplace(name, " ", "_"), width, height
	name := StrReplace(name, "_", " ")
	searchstring_activated := ""
	If !FileExist("img\Recognition ("poe_height "p)\GUI\[search-strings] "name ".bmp") ;return 0 if reference img-file is missing
	{
		If (A_Gui = "settings_menu")
			LLK_ToolTip("check hasn't been calibrated yet", 1.5)
		Return 0
	}
	
	If !searchstrings_searchcoords_%parse% && (A_Gui != "settings_menu") ;return 0 if search doesn't have coordinates or strings
		Return 0
	
	If (A_Gui = "settings_menu") ;search whole client-area if search was initiated from settings menu, or if this specific search doesn't have last-known coordinates
		local search_x1 := 0, search_y1 := 0, search_x2 := 0, search_y2 := 0
	Else ;otherwise, load last-known coordinates
	{
		Loop, Parse, searchstrings_searchcoords_%parse%, `, ;last-known coordinates are stored in a string as "x1,y1,reference-img width,reference-img height"
		{
			Switch A_Index
			{
				Case 1:
					local search_x1 := A_LoopField
				Case 2:
					local search_y1 := A_LoopField
				Case 3:
					local search_x2 := A_LoopField + search_x1
				Case 4:
					local search_y2 := A_LoopField + search_y1
			}
		}
	}
	
	pNeedle_searchstrings := Gdip_CreateBitmapFromFile("img\Recognition ("poe_height "p)\GUI\[search-strings] "name ".bmp") ;load reference img-file that will be searched for in the screenshot
	If (A_Gui = "settings_menu") && (pNeedle_searchstrings <= 0)
	{
		MsgBox,% "The reference bmp-file could not be loaded correctly.`n`nYou should recalibrate this search: " name
		Return 0
	}
	
	If (Gdip_ImageSearch(pHaystack_searchstrings, pNeedle_searchstrings, LIST, search_x1, search_y1, search_x2, search_y2, imagesearch_variation,, 1, 1) > 0) ;reference img-file was found in the screenshot
	{
		If (A_Gui = "settings_menu") ;if search was initiated from settings menu, save positive coordinates
		{
			Gdip_GetImageDimension(pNeedle_searchstrings, width, height) ;get dimensions of the reference img-file
			searchstrings_searchcoords_%parse% := LIST "," Format("{:0.0f}", width) "," Format("{:0.0f}", height) ;save string with last-known coordinates
			IniWrite, % searchstrings_searchcoords_%parse%, % "ini\search-strings.ini", % name, last coordinates ;write string to ini-file
		}
		Gdip_DisposeImage(pNeedle_searchstrings) ;clear reference-img file from memory
		Return 1
	}
	Else Gdip_DisposeImage(pNeedle_searchstrings)
	If (A_Gui = "settings_menu")
		LLK_ToolTip("test negative")
	Return 0
}

LLK_StringSnip(name)
{
	global
	local name1 := StrReplace(name, " ", "_")
	name := StrReplace(name, "_", " ")
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
		LLK_Overlay("settings_menu", "show", 0)
		WinWait, ahk_id %hwnd_settings_menu%
		LLK_ToolTip("screen-cap failed")
	}
	Else
	{
		FileDelete, % "img\Recognition ("poe_height "p)\GUI\[search-strings]"name ".bmp"
		Gdip_SaveBitmapToFile(pClipboard, "img\Recognition ("poe_height "p)\GUI\[search-strings] "name ".bmp", 100)
		Gdip_DisposeImage(pClipboard)
		IniWrite, % "", % "ini\search-strings.ini", % name, last coordinates
		searchstrings_searchcoords_%name1% := ""
		GuiControl, settings_menu: +cRed, % "settings_menu_searchstrings_entry_"name1
	}
	gui_force_hide := 0
}

searchstrings_menuGuiClose()
{
	global
	local key, value, parse
	
	LLK_StringMenuSave()	
	searchstring_entry_selected := ""
	Gui, searchstrings_menu: Destroy
	hwnd_searchstrings_menu := ""
	Gui, searchstrings_rename: Destroy
	hwnd_searchstrings_rename := ""
	WinWaitActive, ahk_group poe_window
	LLK_Overlay("settings_menu", "show")
}

stash_search_menuGuiClose()
{
	global
	new_stash_search_menu_closed := 1
	GoSub, Settings_menu
	Gui, stash_search_menu: Destroy
}