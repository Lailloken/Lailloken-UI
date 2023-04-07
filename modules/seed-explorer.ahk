Legion_seeds:
If (legion_profile = "")
	IniRead, legion_profile, ini\timeless jewels.ini, Settings, profile, %A_Space%

;create array with all socket-relevant notables
legion_notables_array := []
legion_tooltips_array := []
IniRead, parse, data\timeless jewels\mod descriptions.ini, descriptions
Loop, Parse, parse, `n, `n
	legion_tooltips_array.Push(SubStr(A_Loopfield, 1, InStr(A_Loopfield, "=")-1))
FileReadLine, legion_csv_parse, data\timeless jewels\brutal restraint.csv, 1
Loop, Parse, legion_csv_parse, CSV
	legion_notables_array.Push(StrReplace(A_LoopField, """"))
legion_csv_parse := ""

Loop, Files, data\timeless jewels\*.csv
{
	parse := StrReplace(A_LoopFileName, ".csv")
	parse := StrReplace(parse, " ", "_")
	IniRead, legion_%parse%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % StrReplace(parse, "_", " "), % A_Space
}
	
IniRead, legion_treemap_notables, data\timeless jewels\Treemap.ini, all notables

If !WinExist("ahk_id " hwnd_legion_window) ;create GUI with blank text labels
{
	Gui, legion_window: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_window
	Gui, legion_window: Margin, % fSize0//3, % fSize0//4
	Gui, legion_window: Color, Black
	WinSet, Transparent, %trans%
	Gui, legion_window: Font, % "s"fSize0 + fSize_offset_legion " cWhite", Fontin SmallCaps
	
	Gui, legion_window: Add, Text, Section y4 BackgroundTrans Center, % "profile:"
	Loop 5
	{
		If (A_Index = 1)
			Gui, legion_window: Add, Text, ys Border BackgroundTrans Center vlegion_profile gLegion_seeds_apply, % " " A_Index " "
		Else Gui, legion_window: Add, Text, ys Border BackgroundTrans Center vlegion_profile%A_Index% gLegion_seeds_apply, % " " A_Index " "
	}
	
	GuiControl, legion_window: +cFuchsia, % "legion_profile" StrReplace(legion_profile, "_")
	
	Gui, legion_window: Add, Text, xs Section BackgroundTrans Center, % "ui size:"
	Gui, legion_window: Add, Text, ys Border BackgroundTrans Center vlegion_minus gLegion_seeds_apply, % " – "
	Gui, legion_window: Add, Text, ys Border wp BackgroundTrans Center vlegion_zero gLegion_seeds_apply, % "r"
	Gui, legion_window: Add, Text, ys Border wp BackgroundTrans Center vlegion_plus gLegion_seeds_apply, % "+"
	Gui, legion_window: Add, Text, xs Section Border BackgroundTrans Center vlegion_paste gLegion_seeds_parse, % " import jewel "
	Gui, legion_window: Add, Text, % "ys Border BackgroundTrans Center vlegion_trade gLegion_seeds_parse", % " trade-check "
	
	Gui, legion_window: Add, Text, % "xs Section BackgroundTrans Left vlegion_type y+"fSize0//3, % "type: brutal restraint"
	Gui, legion_window: Add, Text, % "xs BackgroundTrans Left vlegion_seed wp y+0", % "seed:"
	Gui, legion_window: Add, Text, % "xs BackgroundTrans Left vlegion_name wp y+0", % "name:"
	
	Gui, legion_window: Font, underline
	Gui, legion_window: Add, Text, % "xs Section BackgroundTrans Left y+8", % "keystones:"
	Gui, legion_window: Font, norm
	Loop 3
		Gui, legion_window: Add, Text, % "xs BackgroundTrans vlegion_keystonetext" A_Index " gLegion_seeds_help y+0", supreme grandstanding
	
	
	Gui, legion_window: Font, underline
	Gui, legion_window: Add, Text, % "xs Section BackgroundTrans y+"fSize0//3, resulting modifications:
	Gui, legion_window: Font, norm
	
	Loop 22
		Gui, legion_window: Add, Text, % "xs Section vlegion_modtext" A_Index " gLegion_seeds_help BackgroundTrans y+0", night of a thousand ribbons (11x)
}

If (legion_type_parse = "") ;placeholder values in case UI is accessed via .legion
{
	legion_type_parse := "lethal pride"
	legion_seed_parse := 18000
	legion_name_parse := "kaom"
}

GuiControl, legion_window: text, legion_type, % "type: " legion_type_parse
GuiControl, legion_window: text, legion_seed, % "seed: " legion_seed_parse
GuiControl, legion_window: text, legion_name, % "name: " legion_name_parse

legion_encode_array := []
Iniread, legion_decode_keys, data\timeless jewels\jewels.ini, % legion_type_parse
legion_type_parse2 := StrReplace(legion_type_parse, " ", "_")

Loop, Parse, legion_decode_keys, `n, `n
{
	IniRead, legion_%legion_type_parse2%_mod%A_Index%, data\timeless jewels\jewels.ini, % legion_type_parse, % A_Index
	legion_encode_array.Push(legion_%legion_type_parse2%_mod%A_Index%)
}

IniRead, legion_keystones, data\timeless jewels\Jewels.ini, types, % legion_type_parse, 0
IniRead, legion_keystone, data\timeless jewels\Jewels.ini, names, % legion_name_parse, 0
IniRead, legion_keystone2, data\timeless jewels\Jewels.ini, names

Loop, Parse, legion_keystones, CSV ;highlight applicable keystone
{
	check := A_LoopField
	loop := A_Index
	Loop, Parse, legion_keystone2, `n, `n
		If InStr(A_LoopField, check)
			legion_name%loop% := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1)
	GuiControl, legion_window: text, legion_keystonetext%A_Index%, % A_LoopField
	If (legion_keystone = A_LoopField)
		GuiControl, legion_window: +cLime, legion_keystonetext%A_Index%
	Else GuiControl, legion_window: +cWhite, legion_keystonetext%A_Index%
}

Loop, Read, data\timeless jewels\%legion_type_parse%.csv ;create array with all modifications of the current seed
{
	If (SubStr(A_LoopReadLine, 1, InStr(A_LoopReadLine, ",",,, 1) - 1) = legion_seed_parse)
	{
		legion_csvline_array := []
		Loop, Parse, A_LoopReadLine, CSV
			legion_csvline_array.Push(A_Loopfield)
		break
	}
}

If (A_Gui != "legion_treemap") ;calculate desired mod numbers for the overview
{
	IniRead, legion_sockets, data\timeless jewels\sockets.ini
	Loop, Parse, legion_sockets, `n, `n
	{
		IniRead, legion_socket_notables, data\timeless jewels\sockets.ini, socket%A_Index%
		
		legion_socket_notables_array := []
		Loop, Parse, legion_socket_notables, `n, `n
			legion_socket_notables_array.Push(A_Loopfield)
		
		modpool := ""
		modpool_unique := ""
		
		Loop, % legion_socket_notables_array.Length()
		{
			target_key := legion_csvline_array[LLK_ArrayHasVal(legion_notables_array, legion_socket_notables_array[A_Index])]
			modpool .= legion_%legion_type_parse2%_mod%target_key% ","
			modpool_unique .= InStr(modpool_unique, legion_%legion_type_parse2%_mod%target_key%) ? "" : legion_%legion_type_parse2%_mod%target_key% ","
		}
		
		Sort, modpool_unique, D`,
		modpool_unique_array := []
		modpool_unique_array2 := []
		Loop, Parse, modpool_unique, `,, `,
		{
			If (A_Loopfield = "")
				break
			count := (LLK_InStrCount(modpool, A_Loopfield, ",") > 1) ? " (" LLK_InStrCount(modpool, A_Loopfield, ",") "x)" : ""
			modpool_unique_array.Push(A_Loopfield count)
			modpool_unique_array2.Push(A_Loopfield)
		}
		
		count := 0
		count_overlaps := 0
		IniRead, legion_socket%A_Index%_favs, ini\timeless jewels.ini, favorites%legion_profile%, socket%A_Index%, % A_Space
		Loop, Parse, legion_socket%A_Index%_favs, CSV
		{
			If (A_Loopfield = "")
				break
			target_column := LLK_ArrayHasVal(legion_notables_array, A_Loopfield)
			target_key := legion_csvline_array[target_column]
			count_overlaps += InStr(legion_%legion_type_parse2%_favs, legion_%legion_type_parse2%_mod%target_key% ",") ? 1 : 0
		}
		Loop 22
		{
			If InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) && (modpool_unique_array2[A_Index] != "")
			{
				If InStr(modpool_unique_array[A_Index], "x)")
				{
					multiplier := SubStr(modpool_unique_array[A_Index], -2, 1)
					count += 1*multiplier
				}
				Else count += 1
			}
		}
		GuiControl, legion_treemap: text, legion_socket_text%A_Index%, % (count = 0) ? "" : count
		GuiControl, legion_treemap: text, legion_socket_text%A_Index%overlap, % (count_overlaps = 0) ? "" : count_overlaps
		legion_socket%A_Index%_notables := count
	}
}
Else GoSub, Legion_seeds3

If (legion_socket != "") ;calculate data for top left panel and apply text to labels
{
	IniRead, legion_socket_notables, data\timeless jewels\sockets.ini, % legion_socket
	
	legion_socket_notables_array := []
	Loop, Parse, legion_socket_notables, `n, `n
		legion_socket_notables_array.Push(A_Loopfield)
	
	modpool := ""
	modpool_unique := ""
	
	Loop, % legion_socket_notables_array.Length()
	{
		target_key := legion_csvline_array[LLK_ArrayHasVal(legion_notables_array, legion_socket_notables_array[A_Index])]
		modpool .= legion_%legion_type_parse2%_mod%target_key% ","
		modpool_unique .= InStr(modpool_unique, legion_%legion_type_parse2%_mod%target_key%) ? "" : legion_%legion_type_parse2%_mod%target_key% ","
	}
	
	Sort, modpool_unique, D`,
	modpool_unique_array := []
	modpool_unique_array2 := []
	Loop, Parse, modpool_unique, `,, `,
	{
		If (A_Loopfield = "")
			break
		count := (LLK_InStrCount(modpool, A_Loopfield, ",") > 1) ? " (" LLK_InStrCount(modpool, A_Loopfield, ",") "x)" : ""
		modpool_unique_array.Push(A_Loopfield count)
		modpool_unique_array2.Push(A_Loopfield)
	}
	
	Loop 22
	{
		GuiControl, legion_window:, legion_modtext%A_Index%, % modpool_unique_array[A_Index]
		If InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) && (modpool_unique_array2[A_Index] != "")
			GuiControl, legion_window: +cAqua, legion_modtext%A_Index%
		Else If !InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) || (modpool_unique_array2[A_Index] = "")
			GuiControl, legion_window: +cWhite, legion_modtext%A_Index%
	}
	WinSet, Redraw,, ahk_id %hwnd_legion_window%
}
Else
{
	Loop 22
		GuiControl, legion_window: text, legion_modtext%A_Index%, % ""
}


If (A_Gui = "legion_treemap") && (legion_socket != "") ;auto-highlight notables affected by desired modifications
{
	legion_highlight := ""
	Loop, Parse, legion_%legion_type_parse2%_favs, `,, `,
	{
		If (A_Loopfield = "")
			break
		target_code := LLK_ArrayHasVal(legion_encode_array, A_Loopfield)
		Loop, Parse, % LLK_ArrayHasVal(legion_csvline_array, target_code, 1), `,, `,
		{
			If (A_Loopfield = "")
				break
			If InStr(legion_socket_notables, legion_notables_array[A_Loopfield] "`n") || (SubStr(legion_socket_notables, -StrLen(legion_notables_array[A_Loopfield])+1) = legion_notables_array[A_Loopfield])
			{
				legion_highlight .= SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))) "|"
				If (LLK_SubStrCount(legion_treemap_notables, SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))), "`n", 1) > 1) && (SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))) != legion_notables_array[A_Loopfield])
				{
					LLK_ToolTip("auto-highlight unavailable:`ntoo many desired mods around this socket", 2)
					WinActivate, ahk_group poe_window
					WinWaitActive, ahk_group poe_window
					sleep, 50
					SendInput, ^{f}
					Sleep, 100
					SendInput, {ESC}
					Return
				}
			}
		}
	}

	If (legion_highlight != "")
	{
		legion_highlight := SubStr(legion_highlight, 1, -1)
		legion_highlight := StrReplace(legion_highlight, " ", ".")
		legion_highlight = ^(%legion_highlight%)
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		sleep, 50
		clipboard := legion_highlight
		ClipWait, 0.05
		SendInput, ^{f}
		Sleep, 100
		SendInput, ^{v}
		Sleep, 100
		SendInput, {Enter}
	}
}

If !WinExist("ahk_id " hwnd_legion_window)
{
	Gui, legion_window: Show, % "NA x" xScreenOffSet " y" yScreenOffSet
	WinGetPos,,, legion_window_width,, ahk_id %hwnd_legion_window%
	Gui, legion_window: Show, % "NA x" xScreenOffSet " y" yScreenOffSet " h"poe_height - legion_window_width - 1
	LLK_Overlay("legion_window", "show")
}
WinGetPos,,, legion_window_width,, ahk_id %hwnd_legion_window%
GoSub, Legion_seeds3
Return

Legion_seeds_apply:
If (A_GuiControl = "legion_minus")
{
	fSize_offset_legion -= 1
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_zero")
{
	fSize_offset_legion := 0
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_plus")
{
	fSize_offset_legion += 1
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_minus" || A_GuiControl = "legion_zero" || A_GuiControl = "legion_plus")
{
	Gui, legion_window: Destroy
	Gui, legion_treemap: Destroy
	Gui, legion_treemap2: Destroy
	Gui, legion_list: Destroy
	hwnd_legion_window := ""
	hwnd_legion_treemap := ""
	hwnd_legion_treemap2 := ""
	hwnd_legion_list := ""
	GoSub, Legion_seeds
	GoSub, Legion_seeds2
	Return
}
If InStr(A_GuiControl, "legion_profile")
{
	If (click = 2)
	{
		If (legion_profile = StrReplace(A_GuiControl, "legion_profile") || legion_profile = "_" StrReplace(A_GuiControl, "legion_profile"))
			IniDelete, ini\timeless jewels.ini, favorites%legion_profile%
		Else
		{
			IniRead, ini_copy, ini\timeless jewels.ini, favorites%legion_profile%
			IniWrite, % ini_copy, ini\timeless jewels.ini, % (StrReplace(A_GuiControl, "legion_profile") = "") ? "favorites" : "favorites_" StrReplace(A_GuiControl, "legion_profile")
		}
		GoSub, Legion_seeds
		Return
	}
	legion_profile := (StrReplace(A_GuiControl, "legion_profile") = "") ? "" : "_" StrReplace(A_GuiControl, "legion_profile")
	Loop 5
	{
		GuiControl, legion_window: +cWhite, % (A_Index = 1) ? "legion_profile" : "legion_profile"A_Index
		GuiControl, legion_window: movedraw, % (A_Index = 1) ? "legion_profile" : "legion_profile"A_Index
	}
	GuiControl, legion_window: +cFuchsia, % "legion_profile" StrReplace(legion_profile, "_")
	GuiControl, legion_window: movedraw, % "legion_profile" StrReplace(legion_profile, "_")
	IniWrite, % legion_profile, ini\timeless jewels.ini, Settings, profile
	GoSub, Legion_seeds
	Return
}
Return

Legion_seeds2:
If (hwnd_legion_treemap != "")
	Return
Else ;create passive tree GUI & place squares and number labels
{
	Gui, legion_treemap2: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_treemap2
	Gui, legion_treemap2: Margin, 0, 0
	Gui, legion_treemap2: Color, Black
	Gui, legion_treemap2: Font, % "s"fSize0 + fSize_offset_legion " cAqua bold", Fontin SmallCaps
	Gui, legion_treemap2: Add, Picture, % "BackgroundTrans h" legion_window_width - 2 " w-1", img\GUI\legion_treemap.jpg
	
	Gui, legion_treemap: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_treemap
	Gui, legion_treemap: Margin, 0, 0
	Gui, legion_treemap: Color, Black
	Gui, legion_treemap: Font, % "s"fSize0 + fSize_offset_legion " cAqua bold", Fontin SmallCaps
	Gui, legion_treemap: Add, Picture, % "BackgroundTrans h" legion_window_width + legion_list_width - 3 " w-1", img\GUI\legion_treemap.jpg
	IniRead, squarecount, data\timeless jewels\Treemap.ini, squares
	Loop, Parse, squarecount, `n, `n
	{
		If (StrLen(A_Loopfield) < 4)
			break
		IniRead, coords, data\timeless jewels\Treemap.ini, squares, % A_Index, 0
		square_coords := StrSplit(coords, ",", ",")
		style := (StrReplace(previous_socket, "legion_socket") = A_Index) ? "img\GUI\square_red.png" : ""
		Gui, legion_treemap: Add, Text, % "BackgroundTrans Left vlegion_socket_text" A_Index " x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % A_Space
		Gui, legion_treemap: Add, Text, % "BackgroundTrans Right cYellow vlegion_socket_text" A_Index "overlap x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % A_Space
		Gui, legion_treemap: Add, Picture, % "BackgroundTrans gLegion_seeds_sockets vlegion_socket" A_Index " x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % style
	}
	GoSub, Legion_seeds
	Gui, legion_treemap: Show, % "Hide x"xScreenOffset " y"yScreenOffSet + poe_height - (legion_window_width + legion_list_width) + 1
	Gui, legion_treemap2: Show, % "NA x"xScreenOffset " y"yScreenOffSet + poe_height - legion_window_width
	LLK_Overlay("legion_treemap2", "show")
}
Return

Legion_seeds3: ;create list of all modifications or notables
If !WinExist("ahk_id " hwnd_legion_list)
{
	GuiControl, legion_window: text, legion_toggle, % " < "
	Gui, legion_list: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_list
	Gui, legion_list: Margin, % fSize0//3, % fSize0//4
	Gui, legion_list: Color, Black
	WinSet, Transparent, %trans%
	Gui, legion_list: Font, % "s"fSize0 + fSize_offset_legion " cWhite underline", Fontin SmallCaps
	Gui, legion_list: Add, Text, % "Section BackgroundTrans vlegion_list_header", notables around socket:
	Gui, legion_list: Font, norm

	Loop, 45
	{
		If (A_Index = 1)
			Gui, legion_list: Add, Text, % "xs BackgroundTrans gLegion_seeds_help vlegion_list_text" A_Index, night of a thousand ribbons
		Else Gui, legion_list: Add, Text, % "xs y+0 BackgroundTrans gLegion_seeds_help wp vlegion_list_text" A_Index, % ""
	}
}

If (legion_socket = "")
{
	GuiControl, legion_list: text, legion_list_header, notable modifications:
	
	IniRead, legion_notables, data\timeless jewels\jewels.ini, % legion_type_parse
	legion_notables_list := ""
	loops := 0
	Loop, Parse, legion_notables, `n, `n
	{
		IniRead, legion_notable%A_Index%, data\timeless jewels\jewels.ini, % legion_type_parse, % A_Index
		legion_notables_list .= (legion_notables_list = "") ? legion_notable%A_Index% : "," legion_notable%A_Index%
	}

	Sort, legion_notables_list, D`,
	Loop, Parse, legion_notables_list, CSV
	{
		loops += 1
		GuiControl, legion_list: text, legion_list_text%A_Index%, % A_Loopfield
		If InStr(legion_%legion_type_parse2%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cAqua, legion_list_text%A_Index%
		Else GuiControl, legion_list: +cWhite, legion_list_text%A_Index%
	}
	Loop 45
	{
		If (A_Index <= loops)
			continue
		GuiControl, legion_list: text, legion_list_text%A_Index%, % ""
	}
}
Else
{
	IniRead, legion_%legion_socket%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_socket, % A_Space
	GuiControl, legion_list: text, legion_list_header, notables around socket:
	legion_notables_socket_array := []
	loops := 0
	IniRead, legion_notables_socket, data\timeless jewels\sockets.ini, % legion_socket
	Loop, Parse, legion_notables_socket, `n, `n
	{
		loops += 1
		legion_notables_socket_array.Push(A_Loopfield)
		target_column := LLK_ArrayHasVal(legion_notables_array, A_LoopField)
		target_key := legion_csvline_array[target_column]
		GuiControl, legion_list: text, legion_list_text%A_Index%, % A_Loopfield
		If InStr(legion_%legion_type_parse2%_favs, legion_%legion_type_parse2%_mod%target_key% ",") && InStr(legion_%legion_socket%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cYellow, legion_list_text%A_Index%
		Else If InStr(legion_%legion_socket%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cAqua, legion_list_text%A_Index%
		Else GuiControl, legion_list: +cWhite, legion_list_text%A_Index%
	}
	Loop 45
	{
		If (A_Index <= loops)
			continue
		GuiControl, legion_list: text, legion_list_text%A_Index%, % ""
	}
}

If !WinExist("ahk_id " hwnd_legion_list)
{
	Gui, legion_list: Show, % "NA x" xScreenOffSet + legion_window_width - 1 " y" yScreenOffSet " h"poe_height - 2
	LLK_Overlay("legion_list", "show")
}
WinGetPos,,, legion_list_width,, ahk_id %hwnd_legion_list%
Return

Legion_seeds_help:
Gui, legion_help: Destroy
GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
If (modtext = "" || modtext = " ") || InStr(modtext, "+5 devotion")
{
	If InStr(modtext, "+5 devotion")
		LLK_ToolTip("cannot highlight devotion nodes", 2)
	Return
}
If (click = 2) ;right-click notable labels to mark as desired
{
	If InStr(A_GuiControl, "keystone")
		Return
	GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
	modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext
	If LLK_ArrayHasVal(legion_notables_socket_array, modtext)
	{
		If InStr(legion_%legion_socket%_favs, modtext)
			GuiControl, %A_Gui%: +cWhite, % A_GuiControl
		Else
			GuiControl, %A_Gui%: +cAqua, % A_GuiControl
		legion_%legion_socket%_favs := InStr(legion_%legion_socket%_favs, modtext) ? StrReplace(legion_%legion_socket%_favs, modtext ",") : (legion_%legion_socket%_favs = "") ? modtext "," : legion_%legion_socket%_favs modtext ","
		IniWrite, % legion_%legion_socket%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_socket
	}
	Else
	{
		If InStr(legion_%legion_type_parse2%_favs, modtext)
		{
			GuiControl, legion_window: +cWhite, % A_GuiControl
			GuiControl, %A_Gui%: +cWhite, % A_GuiControl
		}
		Else
		{
			GuiControl, legion_window: +cAqua, % A_GuiControl
			GuiControl, %A_Gui%: +cAqua, % A_GuiControl
		}
		legion_%legion_type_parse2%_favs := InStr(legion_%legion_type_parse2%_favs, modtext) ? StrReplace(legion_%legion_type_parse2%_favs, modtext ",") : (legion_%legion_type_parse2%_favs = "") ? modtext "," : legion_%legion_type_parse2%_favs modtext ","
		IniWrite, % legion_%legion_type_parse2%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_type_parse
	}
	GoSub, Legion_seeds
	Return
}

GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
If (InStr(A_GuiControl, "legion_modtext") || LLK_ArrayHasVal(legion_notables_socket_array, modtext)) && (modtext != "") && !InStr(modtext, "+5 devotion") ;click mod labels to highlight affected notables on the in-game passive tree
{
	If !InStr(A_GuiControl, "legion_modtext") && !LLK_ArrayHasVal(legion_notables_socket_array, modtext)
		Return
	
	modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext

	legion_highlight := ""
	target_code := LLK_ArrayHasVal(legion_encode_array, modtext)
	Loop, Parse, % LLK_ArrayHasVal(legion_csvline_array, target_code, 1), `,, `,
	{
		If (A_Loopfield = "")
			break
		If InStr(legion_socket_notables, legion_notables_array[A_Loopfield] "`n") || (SubStr(legion_socket_notables, -StrLen(legion_notables_array[A_Loopfield])+1) = legion_notables_array[A_Loopfield])
			legion_highlight .= legion_notables_array[A_Loopfield] "|"
	}
	
	legion_highlight := LLK_ArrayHasVal(legion_notables_socket_array, modtext) ? modtext : legion_highlight
	If (legion_highlight != "")
	{
		legion_highlight := LLK_ArrayHasVal(legion_notables_socket_array, modtext) ? legion_highlight : SubStr(legion_highlight, 1, -1)
		legion_highlight := StrReplace(legion_highlight, " ", ".")
		legion_highlight = notable ^(%legion_highlight%)
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		sleep, 50
		clipboard := legion_highlight
		ClipWait, 0.05
		SendInput, ^{f}
		Sleep, 100
		SendInput, ^{v}
		Sleep, 100
		SendInput, {Enter}
	}
}
Return

Legion_seeds_hover:
MouseGetPos, mouseXpos, mouseYpos
Gui, legion_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_legion_help
Gui, legion_help: Color, Black
Gui, legion_help: Margin, 0, 0
Gui, legion_help: Font, % "s"fSize1 + fSize_offset_legion " cWhite", Fontin SmallCaps

GuiControlGet, modtext,, % hwnd_control_hover
modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext
If (modtext = "") || (!LLK_ArrayHasVal(legion_tooltips_array, modtext) && !LLK_ArrayHasVal(legion_notables_socket_array, modtext))
{
	Gui, legion_help: Destroy
	Return
}

width_hover := (fSize0 + fSize_offset_legion)*25

If !LLK_ArrayHasVal(legion_notables_socket_array, modtext)
{
	IniRead, text, data\timeless jewels\mod descriptions.ini, descriptions, % modtext, 0
	Loop, Parse, text, ?, ?
	{
		If (A_Loopfield = "")
			continue
		If (A_Index = 1)
			Gui, legion_help: Add, Text, % "BackgroundTrans Center Border w"width_hover, % (text = 0) ? "n/a" : A_Loopfield
		Else Gui, legion_help: Add, Text, % "BackgroundTrans Center Border y+-1 w"width_hover, % (text = 0) ? "n/a" : A_Loopfield
	}
}
Else
{
	target_column := LLK_ArrayHasVal(legion_notables_array, modtext)
	target_key := legion_csvline_array[target_column]
	Gui, legion_help: Add, Text, % "BackgroundTrans Center Border w"width_hover, % legion_%legion_type_parse2%_mod%target_key%
	IniRead, text, data\timeless jewels\mod descriptions.ini, descriptions, % legion_%legion_type_parse2%_mod%target_key%, 0
	If (text != 0)
	{
		Loop, Parse, text, ??, ??
		{
			If (A_Loopfield = "")
				continue
			Gui, legion_help: Add, Text, % "BackgroundTrans Center Border y+-1 w"width_hover, % A_Loopfield
		}
	}
}
mouseYpos := (mouseYpos < yScreenOffSet + poe_height/2) ? mouseYpos : (mouseYpos - yScreenOffSet)*0.95
Gui, legion_help: Show, % "NA x"mouseXpos + fSize0*2 " y"mouseYpos " AutoSize"

If (hwnd_win_hover != hwnd_legion_window)
	SetTimer, Legion_seeds_hover_check
Return

Legion_seeds_hover_check:
MouseGetPos,,, hwnd_win_hover2,, 2
If (hwnd_win_hover2 != hwnd_legion_treemap) && (hwnd_win_hover2 != hwnd_legion_list)
{
	Gui, legion_help: Destroy
	hwnd_legion_help := ""
	LLK_Overlay("legion_treemap", "hide")
	SetTimer, Legion_seeds_hover_check, Delete
}
Return

Legion_seeds_parse:
If (A_GuiControl = "legion_trade") ;right-click button to open trade site with currently loaded jewel
{
	legion_trade := "{%22query%22:{%22status%22:{%22option%22:%22any%22},%22stats%22:[{%22type%22:%22count%22,%22filters%22:[{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name1 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse
	legion_trade .= "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name2 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse
	legion_trade .= "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name3 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse "},%22disabled%22:false}],%22value%22:{%22min%22:1}}]},%22sort%22:{%22price%22:%22asc%22}}"
	Run, https://www.pathofexile.com/trade/search/Sentinel?q=%legion_trade%
	Return
}
If !InStr(clipboard, "limited to: 1 historic")
{
	LLK_ToolTip("no timeless jewel in clipboard", 2)
	Return
}

parse_mode := InStr(clipboard, "{ unique modifier }") ? 0 : 1
	
unique_mod_line := ""
IniRead, legion_leaders_ini, data\timeless jewels\jewels.ini, names
legion_leaders := ""
Loop, Parse, legion_leaders_ini, `n, `n
	legion_leaders .= SubStr(A_Loopfield, 1, InStr(A_Loopfield, "=") -1) ","

If (parse_mode = 0) ;parsing the clipboard data when retrieved via context-menu
{
	Loop, Parse, clipboard, `n, `r
	{
		If (A_Index = 3)
			legion_type_parse := A_Loopfield
		If (A_Loopfield = "{ unique modifier }")
			unique_mod_line := A_Index
		If (unique_mod_line = A_Index - 1)
		{
			parse_line := A_Loopfield
			break
		}
	}
}
Else ;parsing the clipboard data when retrieved via ctrl-c or from the trade site
{
	Loop, Parse, clipboard, `n, `r
	{
		If (A_Index = 3)
			legion_type_parse := A_Loopfield
		If InStr(A_Loopfield, "item level:") || InStr(A_Loopfield, "(implicit)")
			unique_mod_line := A_Index
		If (unique_mod_line = A_Index - 2)
		{
			parse_line := A_Loopfield
			break
		}
	}	
}

StringLower, legion_type_parse, legion_type_parse
legion_seed_parse := ""
Loop, Parse, parse_line ;parse seed from the relevant line
{
	If IsNumber(A_Loopfield)
		legion_seed_parse .= A_Loopfield
	If !IsNumber(A_Loopfield) && (legion_seed_parse != "")
		break
}

Loop, Parse, legion_leaders, `,, `, ;parse name from clipboard data
{
	If ((parse_mode = 0) && InStr(clipboard, A_Loopfield "(")) || ((parse_mode = 1) && InStr(clipboard, A_Loopfield))
	{
		legion_name_parse := A_Loopfield
		break
	}
}

If (A_GuiControl = "legion_seed_vilsol")
{
	vilsol_type := ["glorious vanity", "lethal pride", "brutal restraint", "militant faith", "elegant hubris"]
	StringUpper, vilsol_name, legion_name_parse, T
	Run, % "https://vilsol.github.io/timeless-jewels/tree?jewel=" LLK_ArrayHasVal(vilsol_type, legion_type_parse) "&conqueror=" vilsol_name "&seed=" legion_seed_parse "&mode=seed"
	Return
}

GoSub, Legion_seeds
GoSub, Legion_seeds2
If WinExist("ahk_id " hwnd_legion_list)
	GoSub, Legion_seeds3
If (A_Gui = "")
	LLK_ToolTip("success", 0.5)
Return

Legion_seeds_sockets:
legion_socket := StrReplace(A_GuiControl, "legion_")
If (previous_socket != "")
	GuiControl,, % previous_socket, img\GUI\square_blank.png
If (A_GuiControl = previous_socket)
{
	GuiControl,, % A_GuiControl, img\GUI\square_blank.png
	legion_socket := ""
	previous_socket := ""
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, ^{f}
	Sleep, 100
	SendInput, {ESC}
	GoSub, Legion_seeds
	Return
}
Else GuiControl,, % A_GuiControl, img\GUI\square_red.png
previous_socket := A_GuiControl
GoSub, Legion_seeds
Return

Init_legion:
IniRead, fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset, 0
Return