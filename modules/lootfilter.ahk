Init_lootfilter()
{
	local
	global vars, settings

	If !FileExist("ini\lootfilter.ini")
		IniWrite, % settings.general.fSize, ini\lootfilter.ini, settings, font-size

	If !vars.lootfilter
		vars.lootfilter := {"config_folder": SubStr(vars.system.config, 1, InStr(vars.system.config, "\",, 0))}, settings.lootfilter := {}

	ini := IniBatchRead("ini\lootfilter.ini")
	settings.lootfilter.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.lootfilter.fSize, font_height, font_width), settings.lootfilter.fHeight := font_height, settings.lootfilter.fWidth := font_width
	LLK_FontDimensions(settings.lootfilter.fSize - 4, font_height, font_width), settings.lootfilter.fHeight2 := font_height, settings.lootfilter.fWidth2 := font_width
	settings.lootfilter.active := !Blank(check := ini.settings["active filter"]) && FileExist(vars.lootfilter.config_folder . check ".filter") ? check : ""

	If settings.lootfilter.active && FileExist(vars.lootfilter.config_folder . settings.lootfilter.active ".filter")
		Lootfilter_Base("load")
}

Lootfilter_Base(mode)
{
	local
	global vars, settings

	If (mode = "load")
	{
		bases := vars.lootfilter.bases := {}, base_filter := vars.lootfilter.base_filter := [], filter := vars.lootfilter.filter := [], vars.lootfilter.pending := 0
		file1 := vars.lootfilter.config_folder . settings.lootfilter.active ".filter"
		Loop, Files, % vars.lootfilter.config_folder . "LLK-UI*.filter"
		{
			file2 := vars.lootfilter.config_folder . A_LoopFileName
			Break
		}

		For iLoad in [1, 2]
		{
			If !FileExist(file%iLoad%)
				Continue

			filter_raw := StrReplace(LLK_FileRead(file%iLoad%, 1), "`r`n`r`n", "§"), filter_raw := StrSplit(filter_raw, "§", "`r`n")
			For index, chunk in filter_raw
				If (iLoad = 2 && index = 1) && InStr(chunk, "base file:")
					file2_base := SubStr(chunk, InStr(chunk, "base file:") + 11)
				Else If (SubStr(chunk, 1, 1) = "#")
					Continue
				Else If (iLoad = 1)
				{
					If InStr(chunk, "basetype ==")
					{
						basetype := Lootfilter_Get(chunk, "basetype")
						For iBasetype, vBasetype in StrSplit(StrReplace(basetype, """ """, ""","""), ",", " """)
							If !bases[vBasetype]
								bases[vBasetype] := 1
							Else bases[vBasetype] += 1
					}
					base_filter.Push(chunk)
				}
				Else filter.Push(chunk)
		}
		If !filter.Count()
			vars.lootfilter.filter := base_filter.Clone()
		vars.lootfilter.filter_backup := filter.Clone()
	}
	Else If (mode = "search")
	{
		search := (override := vars.lootfilter.search_override) ? override : LLK_StringCase(LLK_ControlGet(vars.hwnd.lootfilter.search)), search := Trim(search, ","), search_results := {}
		If !override
			GuiControl, +Disabled, % vars.hwnd.lootfilter.search_go

		If Blank(search)
			vars.lootfilter.results := vars.lootfilter.search := ""
		Else
		{
			search := [(override ? "" : search), StrSplit(search, ",", InStr(search, ",") ? " " : "")], count := search.2.Count()
			Loop, % count
				If (StrLen(search.2[(index := count - (A_Index - 1))]) < 4) || (LLK_HasVal(search.2, search.2[index],,, 1).Count() > 1)
					search.2.RemoveAt(index)
			For index, val in search.2
				For index, match in OCR_HasRegex(vars.lootfilter.bases, "i)" (InStr(val, """") ? "^" : "") StrReplace(val, """") . (InStr(val, """") ? "$" : ""), 1, 1) ;LLK_HasKey(vars.lootfilter.bases, StrReplace(val, """"), InStr(val, """") ? 0 : 1,, 1)
					search_results[match] := vars.lootfilter.bases[match]
			vars.lootfilter.search := [search.1, search_results]
		}
		vars.lootfilter.search_override := ""
		Return 1
	}
	Else If (mode = "unavailable")
	{
		IniDelete, ini\lootfilter.ini, settings, active filter
		vars.lootfilter.filter := vars.lootfilter.filter_backup := vars.lootfilter.modifications := vars.lootfilter.modifications_backup := settings.lootfilter.active := vars.lootfilter.search := ""
		MsgBox, % "The previous base filter no longer exists, please select a new one"
		Return
	}

	If InStr("modifications, load", mode)
	{
		modifications := vars.lootfilter.modifications := {}
		If !vars.lootfilter.search.1 && vars.lootfilter.search.2.Count()
			vars.lootfilter.search := ""

		For index, val in vars.lootfilter.filter
			If InStr(val, "LLK-UI modification")
				If !IsObject(modifications[(basetype := SubStr(Lootfilter_Get(val, "basetype"), 2, -1))])
					modifications[basetype] := [val]
				Else modifications[basetype].Push(val)

		If (mode = "load")
		{
			vars.lootfilter.modifications_backup := modifications.Clone()
			FileGetTime, timestamp1, % file1, M
			If FileExist(file2)
			{
				FileGetTime, timestamp2, % file2, M
				If (timestamp1 > timestamp2) || !InStr(file1, file2_base)
				{
					filter := vars.lootfilter.filter := base_filter.Clone(), vars.lootfilter.pending := 2
					start := A_TickCount
					For key, array in modifications
					{
						For index, chunk in array
						{
							count := filter.Count(), target_index := [0, 0]
							Loop, % count
							{
								iFilter := count - (A_Index - 1), action := SubStr(chunk, 1, 4), basetype := Lootfilter_Get(chunk, "basetype"), chunk2 := filter[iFilter]
								If !InStr(chunk2, basetype) || InStr(chunk2, "LLK-UI modification")
									Continue
								If Lootfilter_ChunkCompare(chunk, chunk2)
								{
									vars.lootfilter.filter.InsertAt(iFilter, Lootfilter_ChunkModify(chunk2, action, basetype) . (InStr(chunk, "(addition)") ? " (addition)" : ""))
									Continue 2
								}
							}
							If InStr(chunk, "(addition)")
							{
								Loop, % count
								{
									iFilter := count - (A_Index - 1), chunk2 := filter[iFilter]
									If !InStr(chunk2, basetype) || InStr(chunk2, "LLK-UI modification")
										Continue
									If Lootfilter_ChunkCompare(chunk, chunk2, 1)
										target_index.1 := iFilter + (Lootfilter_Get(chunk, "stacksize") < Lootfilter_Get(chunk2, "stacksize") ? 1 : 0), target_index.2 += 1
								}
								If (target_index.2 = 1)
								{
									vars.lootfilter.filter.InsertAt(target_index.1, chunk)
									Continue
								}
							}
							modifications[key][index] .= " (incompatible)"
						}
					}
				}
			}
		}
		Else
		{
			modifications_backup := vars.lootfilter.modifications_backup
			If ((pending := vars.lootfilter.pending) != 2)
				vars.lootfilter.pending := 0
			If (modifications.Count() != modifications_backup.Count())
				vars.lootfilter.pending := (pending = 2) ? 2 : 1
			Else
				For key, array in modifications
				{
					If !modifications_backup.HasKey(key) || (modifications_backup[key].Count() != modifications[key].Count())
					{
						vars.lootfilter.pending := (pending = 2) ? 2 : 1
						Break
					}
					For index, chunk in array
						If (chunk != modifications_backup[key][index])
						{
							vars.lootfilter.pending := (pending = 2) ? 2 : 1
							Break 2
						}
				}
		}
	}
}

Lootfilter_ChunkCompare(chunk1, chunk2 := "", ignore_stack := 0, ByRef new_chunk1 := "")
{
	local

	new_chunk1 := ""
	For index in [1, 2]
		Loop, Parse, chunk%index%, `n, `r`t
			If (A_Index > 1) && !LLK_StringCompare(A_LoopField, ["basetype", "SetFontSize", "SetTextColor", "SetBorderColor", "SetBackgroundColor", "PlayAlertSound", "PlayEffect", "MinimapIcon", ignore_stack ? "stacksize" : "", "#"])
				new_chunk%index% .= A_LoopField "`r`n`t"
	new_chunk1 := Trim(new_chunk1, "`r`n`t"), new_chunk2 := Trim(new_chunk2, "`r`n`t")

	If (new_chunk1 = new_chunk2)
		Return 1
}

Lootfilter_ChunkModify(chunk, action, basetype, stack_size := 0)
{
	local

	modified_chunk := StrReplace(chunk, SubStr(chunk, 1, 4), action,, 1) . (!InStr(chunk, "LLK-UI modification") ? "`r`n`t# LLK-UI modification" : "")
	Loop, Parse, modified_chunk, `n, `r
		modified_chunk := (A_Index = 1) ? "" : modified_chunk
		, modified_chunk .= (!modified_chunk ? "" : "`r`n") . (InStr(A_LoopField, "basetype") ? "`tBaseType == """ StrReplace(basetype, """") """" : A_LoopField)

	Return modified_chunk
}

Lootfilter_Get(chunk, data, ByRef operator := "")
{
	local

	operator := ""
	If (check := InStr(chunk, data,, 0))
	{
		operator := SubStr(chunk, check), operator := SubStr(operator, 1, InStr(operator, "`r") ? InStr(operator, "`r") - 1 : StrLen(operator))
		If LLK_PatternMatch(operator, "", ["<", ">", "="])
			operator := SubStr(operator, InStr(operator, " ") + 1), operator := SubStr(operator, 1, InStr(operator, " ") - 1)
		Else operator := ""
		%data% := SubStr(chunk, check), %data% := SubStr(%data%, 1, (check := InStr(%data%, "`r")) ? check - 1 : StrLen(%data%))
		start := InStr("arealevel, stacksize", data) ? InStr(%data%, " ",, 0) + 1 : InStr(%data%, InStr(data, "color") ? " " : """")
		%data% := SubStr(%data%, start + (InStr(data, "color") ? 1 : 0))
	}
	Return (%data%)
}

Lootfilter_GUI(cHWND := "", side := "", activation := "")
{
	local
	global vars, settings
	static toggle := 0, dock := 1

	check := LLK_HasVal(vars.hwnd.lootfilter, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	label := LLK_HasKey(vars.lootfilter.labels, cHWND), dock := InStr(side, "dock_") ? SubStr(side, InStr(side, "_") + 1) : dock

	If (cHWND = "close")
	{
		If vars.lootfilter.pending
		{
			xPos := vars.lootfilter.xPos + vars.lootfilter.mod_header.1, yPos := vars.lootfilter.yPos + vars.lootfilter.mod_header.2
			LLK_ToolTip(Lang_Trans("lootfilter_unsaved"), 1.5, xPos, yPos,, "Red",,,,, "White")
			If !(LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton") || LLK_Progress(vars.hwnd.lootfilter.x_bar, "ESC"))
				Return
		}
		LLK_Overlay(vars.hwnd.lootfilter.main, "destroy"), vars.lootfilter.search := vars.hwnd.lootfilter.main := ""
		vars.lootfilter.pending := (vars.lootfilter.pending = 2) ? 2 : 0
		vars.lootfilter.filter := vars.lootfilter.filter_backup.Clone(), vars.lootfilter.modifications := vars.lootfilter.modifications_backup.Clone()
		Return
	}
	Else If (check = "basefilter")
	{
		If FileExist(vars.lootfilter.config_folder . A_GuiControl ".filter")
		{
			IniWrite, % """" (settings.lootfilter.active := A_GuiControl) """", ini\lootfilter.ini, settings, active filter
			Lootfilter_Base("load")
		}
		Else Lootfilter_Base("unavailable")
	}
	Else If (check = "refresh")
	{
		If !FileExist(vars.lootfilter.config_folder . settings.lootfilter.active ".filter")
			Lootfilter_Base("unavailable")
		Else Lootfilter_Base("load")
	}
	Else If InStr(check, "font_")
	{
		If (control = "reset")
			settings.lootfilter.fSize := settings.general.fSize
		Else settings.lootfilter.fSize += (control = "plus") ? 1 : (control = "minus" && settings.lootfilter.fSize > 6) ? -1 : 0
		KeyWait, LButton
		IniWrite, % settings.lootfilter.fSize, ini\lootfilter.ini, settings, font-size
		LLK_FontDimensions(settings.lootfilter.fSize, font_height, font_width), settings.lootfilter.fWidth := font_width, settings.lootfilter.fHeight := font_height
		LLK_FontDimensions(settings.lootfilter.fSize - 4, font_height, font_width), settings.lootfilter.fWidth2 := font_width, settings.lootfilter.fHeight2 := font_height
	}
	Else If (check = "search_go") || (cHWND = "search")
	{
		Lootfilter_Base("search")
		KeyWait, Enter
		If (check = "search_go")
		{
			GuiControl,, % vars.hwnd.lootfilter.search, % "searching..."
			GuiControl, +Disabled, % vars.hwnd.lootfilter.search
			GuiControl, +Disabled, % vars.hwnd.lootfilter.search_go
		}
	}
	Else If (check = "resetsearch")
		vars.lootfilter.search := ""
	Else If InStr(check, "modificationtext_") && (vars.system.click = 1)
	{
		KeyWait, LButton
		basetype := Trim(LLK_ControlGet(cHWND), " "), basetype := (check := InStr(basetype, ":")) ? SubStr(basetype, 1, check - 1) : basetype
		shift := GetKeyState("Shift", "P"), input := LLK_ControlGet(vars.hwnd.lootfilter.search)
		If InStr(input, """" basetype """") && (shift || !InStr(input, ","))
			Return
		GuiControl,, % vars.hwnd.lootfilter.search, % (shift ? input ", " : "") """" basetype """"
		Lootfilter_GUI("search")
		Return
	}
	Else If (check = "apply_mods")
	{
		If !LLK_Progress(vars.hwnd.lootfilter.apply_bar, "LButton",, 0)
			Return
		vars.lootfilter.filter_backup := vars.lootfilter.filter.Clone(), vars.lootfilter.modifications_backup := vars.lootfilter.modifications.Clone()
		FileDelete, % vars.lootfilter.config_folder "LLK-UI*.filter"
		file_dump := "# LLK-UI modded filter, base file: " settings.lootfilter.active
		For index, chunk in vars.lootfilter.filter
			file_dump .= "`r`n`r`n" chunk
		file := FileOpen(vars.lootfilter.config_folder . (new_file := "LLK-UI_modded_filter") ".filter", "w", "UTF-8-RAW")
		file.Write(file_dump "`r`n"), file.Close()
		KeyWait, LButton
		If (vars.lootfilter.pending = 2)
			Lootfilter_Base("load")
		vars.lootfilter.pending := "", Clipboard := "/itemfilter " new_file
		WinActivate, % "ahk_id " vars.hwnd.poe_client
		WinWaitActive, % "ahk_id " vars.hwnd.poe_client
		SendInput, {ENTER}
		Sleep 100
		SendInput, ^{v}{ENTER}
	}
	Else If InStr(check, "hide_") || InStr(check, "modificationtext_") && (vars.system.click = 2) || (check = "allmodifications")
	{
		If (check = "allmodifications") && LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton")
			remove_all := 1
		Else If (check = "allmodifications") && !LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton")
			Return
		count := vars.lootfilter.filter.Count()
		Loop, % count
		{
			index := count - (A_Index - 1), chunk := vars.lootfilter.filter[index], prev_chunk := vars.lootfilter.filter[index - 1]
			If vars.lootfilter.modifications[control] || remove_all
			{
				If !InStr(chunk, "LLK-UI modification")
					Continue
				If remove_all || ("""" control """" = Lootfilter_Get(chunk, "basetype"))
					vars.lootfilter.filter.RemoveAt(index)
			}
			Else
				If InStr(chunk, "`r`n`tcontinue") || InStr(chunk, "LLK-UI modification") || !InStr(Lootfilter_Get(chunk, "basetype"), """" control """")
				|| (arealevel := Lootfilter_Get(chunk, "arealevel"), operator) && (arealevel <= 67) && !InStr(operator, ">")
					Continue
				Else
				{
					modified_chunk := Lootfilter_ChunkModify(chunk, "Hide", control)
					If InStr(prev_chunk, "LLK-UI modification") && InStr(Lootfilter_Get(prev_chunk, "basetype"), """" control """")
						vars.lootfilter.filter[index - 1] := modified_chunk
					Else vars.lootfilter.filter.InsertAt(index, modified_chunk)
				}
		}
		Lootfilter_Base("modifications")
	}
	/*	currently unused "add stack" functionality
	Else If InStr(check, "addstack_")
	{
		base := SubStr(control, InStr(control, "_") + 1), control := SubStr(control, 1, InStr(control, "_") - 1)
		input := LLK_ControlGet(vars.hwnd.lootfilter["addstackedit_" control "_" base])
		If (input < 2)
		{
			LLK_ToolTip("minimum 2",,,,, "Red")
			Return
		}
		chunk := vars.lootfilter.filter[control]
		modified_chunk := Lootfilter_ChunkModify(chunk, "Show", base), modified_chunk := StrReplace(modified_chunk, "`r`n`t", "`r`n`tStackSize >= " input "`r`n`t",, 1) " (addition)"
		vars.lootfilter.filter.InsertAt(control, modified_chunk), Lootfilter_Base("modifications")
	}
	*/
	Else If !Blank(label)
	{
		If (vars.system.click = 1)
			Return
		text := Trim(LLK_ControlGet(cHWND), " "), filter_index := vars.lootfilter.labels[label].1, basetype := IsNumber(SubStr(text, 1, 1)) ? SubStr(text, InStr(text, " ") + 1) : text
		chunk := vars.lootfilter.filter[filter_index], action := SubStr(chunk, 1, 4), stack := Lootfilter_Get(chunk, "stacksize")

		If (vars.system.click = 2)
		{
			If InStr(chunk, "LLK-UI modification")
				vars.lootfilter.filter.RemoveAt(filter_index), Lootfilter_Base("modifications")
			Else
			{
				modified_chunk := Lootfilter_ChunkModify(chunk, (action2 := (action = "show") ? "Hide" : "Show"), basetype)
				vars.lootfilter.filter.InsertAt(filter_index, modified_chunk)
				If stack
					For index, val in vars.lootfilter.filter
						If (index <= filter_index) || !InStr(val, """" basetype """") || (arealevel := Lootfilter_Get(val, "arealevel", operator)) && (arealevel <= 67) && !InStr(operator, ">")
						|| InStr((prev_chunk := vars.lootfilter.filter[index - 1]), "LLK-UI modification") && InStr(prev_chunk, """" basetype """")
							Continue
						Else If Lootfilter_ChunkCompare(modified_chunk, val, 1)
							If InStr(val, "LLK-UI modification") ;override previous modifications to avoid unintentional flip-flopping
								vars.lootfilter.filter[index] := StrReplace(SubStr(val, 1, 4), action2,, 1)
							Else vars.lootfilter.filter.InsertAt(index, Lootfilter_ChunkModify(val, action2, basetype))
				Lootfilter_Base("modifications")
			}
		}
	}
	Else If !Blank(cHWND)
	{
		LLK_ToolTip("no action")
		Return
	}

	KeyWait, LButton
	KeyWait, RButton
	toggle := !toggle, GUI_name := "lootfilter" toggle, max_length := 0, fWidth := settings.lootfilter.fWidth, margin := fWidth//2, loaded_bases := vars.lootfilter.bases
	vars.lootfilter.handles := {}
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_lootfilter"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1
	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.lootfilter.main
	vars.hwnd.lootfilter := {"main": hwnd_lootfilter, "GUI_name": GUI_name}, count := 0
	LLK_PanelDimensions([Lang_Trans("global_hide"), Lang_Trans("global_revert"), " " Lang_Trans("lootfilter_basefilter") " "], settings.lootfilter.fSize, wLabel, hLabel,,, 0)

	Gui, %GUI_name%: Add, DDL, % "x-1 y-1 Hidden"
	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
	Gui, %GUI_name%: Add, Text, % "xp yp hp Border Right Section HWNDhwnd w" wLabel, % Lang_Trans("lootfilter_basefilter") " "
	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4

	Loop, Files, % vars.lootfilter.config_folder "*.filter"
		If !InStr(A_LoopFileName, "LLK-UI")
			file := LLK_StringCase(StrReplace(A_LoopFileName, ".filter")), ddl .= file . (file = settings.lootfilter.active ? "||" : "|")
			, max_length := (StrLen(file) > max_length) ? StrLen(file) : max_length, count += 1

	wDDL := Max(fWidth * 10, Ceil(settings.lootfilter.fWidth2 * max_length * 0.9))
	Gui, %GUI_name%: Add, Text, % "ys hp BackgroundTrans Border w" wDDl
	Gui, %GUI_name%: Add, DDL, % "xp yp wp HWNDhwnd1 gLootfilter_GUI R" Max(1, count), % ddl
	Gui, %GUI_name%: Add, Pic, % "ys hp-2 w-1 Border gLootfilter_GUI HWNDhwnd2", % "HBitmap:*" vars.pics.global.reload
	vars.hwnd.help_tooltips["lootfilter_basefilter"] := vars.hwnd.lootfilter.basefilter := hwnd1, vars.hwnd.lootfilter.refresh := vars.hwnd.help_tooltips["lootfilter_refresh"] := hwnd2
	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize

	If settings.lootfilter.active && !FileExist(vars.lootfilter.config_folder . settings.lootfilter.active ".filter")
		settings.lootfilter.active := "", vars.lootfilter.filter := vars.lootfilter.modifications := ""
	filter := vars.lootfilter.filter, modifications := vars.lootfilter.modifications, modifications_backup := vars.lootfilter.modifications_backup

	If settings.lootfilter.active
	{
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4
		Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans w" wDDL, % " "
		Gui, %GUI_name%: Add, Edit, % "xp yp wp hp cBlack HWNDhwnd1", % vars.lootfilter.search.1
		Gui, %GUI_name%: Add, Button, % "Hidden Default xp yp wp hp gLootfilter_GUI HWNDhwnd", ok
		Gui, %GUI_name%: Add, Pic, % "ys hp-2 w-1 Border gLootfilter_GUI HWNDhwnd2", % "HBitmap:*" vars.pics.global.close
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
		ControlGetPos, xSearch, ySearch, wSearch, hSearch,, ahk_id %hwnd1%
		vars.hwnd.lootfilter.search_go := hwnd, vars.hwnd.lootfilter.search := vars.hwnd.help_tooltips.lootfilter_search := hwnd1
		vars.hwnd.lootfilter.resetsearch := vars.hwnd.help_tooltips["lootfilter_search reset"] := hwnd2
	}

	Gui, %GUI_name%: Add, Text, % "ys hp Border", % " " Lang_Trans("global_uisize") " "
	Gui, %GUI_name%: Add, Text, % "ys hp Border Center gLootfilter_GUI HWNDhwnd w" fWidth * 2, % "–"
	Gui, %GUI_name%: Add, Text, % "ys hp Border Center gLootfilter_GUI HWNDhwnd1 w" fWidth * 2, % "r"
	Gui, %GUI_name%: Add, Text, % "ys hp Border Center gLootfilter_GUI HWNDhwnd2 w" fWidth * 2, % "+"
	ControlGetPos, xControl, yControl, wControl, hControl,, % "ahk_id " hwnd2
	vars.hwnd.lootfilter.font_minus := hwnd, vars.hwnd.lootfilter.font_reset := hwnd1, vars.hwnd.lootfilter.font_plus := hwnd2, xMax := xControl + wControl, yMax := yControl, hMax := hDDL := hControl

	vars.lootfilter.labels := {}, labels := {}, yHide_last := hHide_last := yModification_last := hModification_last := 0
	/* currently unused: list modifications in the search-list if search is blank
	If !vars.lootfilter.search.1 && !vars.lootfilter.search.2.Count() && modifications.Count()
	{
		vars.lootfilter.search_override := ""
		For key in modifications
			vars.lootfilter.search_override .= (A_Index = 1 ? "" : ", ") """" key """", search_override := 1
		Lootfilter_Base("search")
	}
	*/

	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 2
	If (search := vars.lootfilter.search.2).Count()
	{
		For base in search
		{
			count := 0, bases := A_Index
			For index, chunk in vars.lootfilter.filter
			{
				arealevel := Lootfilter_Get(chunk, "arealevel", operator)
				If !InStr(chunk, """" base """") || InStr(chunk, "`r`n`tcontinue") || arealevel && (arealevel <= 67) && !InStr(operator, ">") || search_override && !InStr(chunk, "LLK-UI modification")
					Continue
				stack := Lootfilter_Get(chunk, "stacksize"), text := (stack ? stack "x " : "") base

				If stack && labels[text] || LLK_HasKey(labels, "x " base, 1) && labels[text]
					Continue
				If !stack
					Loop
						If !InStr((prev_chunk := vars.lootfilter.filter[index - A_Index]), "LLK-UI modification")
							Break
						Else If InStr(prev_chunk, """" base """") && !InStr(prev_chunk, "(addition)")
							Continue 2

				If ((count += 1) = 1)
				{
					ControlGetPos,, yFirst,, hFirst,, ahk_id %hwnd%
					yFirst += hFirst - 2
				}
				Lootfilter_ItemLabel(text, index, (count = 1) ? "xs x" wLabel + margin - 1 " Section y+" margin : "ys x+" margin//2, (base = prev) ? xMax : 10000, count)
				ControlGetPos,, yLast,, hLast,, % "ahk_id " vars.hwnd.lootfilter.last_control
				prev := base, yLast += hLast, labels[text] := 1, last_index := index
			}
			/*	unused "add stack" functionality
			If (count = 1)
			{
				ControlGetPos, xPos, yPos, width,,, % "ahk_id " vars.hwnd.lootfilter.last_control
				Gui, %GUI_name%: Font, % "underline"
				Gui, %GUI_name%: Add, Text, % "ys x" (xPos := xPos + width + margin*2) " y" (yPos -= 1) " h" settings.lootfilter.fHeight * 1.4 " 0x200 BackgroundTrans HWNDhwnd gLootfilter_GUI", % Lang_Trans("lootfilter_addstack")
				Gui, %GUI_name%: Font, % "norm s" settings.lootfilter.fSize - 4
				Gui, %GUI_name%: Add, Edit, % "ys x+" margin " Border cBlack HWNDhwnd1 yp+" settings.lootfilter.fHeight * 0.2 " r1 Number Limit2 w" settings.lootfilter.fWidth * 2
				ControlGetPos, xEdit,, wEdit,,, ahk_id %hwnd1%
				Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 2
				;Gui, %GUI_name%: Add, Text, % "Border HWNDhwnd2 x" xPos " y" yPos " w" (xEdit + wEdit - xPos + margin) " h" settings.lootfilter.fHeight * 1.4, % ""
				vars.hwnd.lootfilter["addstack_" last_index "_" base] := hwnd, vars.hwnd.lootfilter["addstackedit_" last_index "_" base] := hwnd1
				vars.hwnd.help_tooltips["lootfilter_add stack" stack_handle] := hwnd, stack_handle .= "|"
			}
			*/
			modified := (modifications[base])
			Gui, %Gui_name%: Add, Text, % "ys x-1 y" yFirst " Border BackgroundTrans Center 0x200 gLootfilter_GUI HWNDhwnd h" yLast + margin - yFirst " w" wLabel
				, % Lang_Trans("global_" (modified ? "revert" : "hide"))
			Gui, %Gui_name%: Add, Progress, % "Disabled Border HWNDhwnd2 Border xp yp wp hp BackgroundBlack c" (modified ? "606060" : "Black"), % 100
			hide_last := vars.hwnd.lootfilter["hide_" base] := hwnd
			vars.hwnd.help_tooltips["lootfilter_" (modified ? "revert" : "hide") . handle] := hwnd2, handle .= "|"

			If (bases != search.Count())
				Gui, %GUI_name%: Add, Progress, % "Disabled Background606060 HWNDhwnd xs x-1 Section h2 w" xMax " y+-1", % 0
		}
	}
	Else If !Blank((search := vars.lootfilter.search).1)
		Gui, %GUI_name%: Add, Text, % "Center x-1 cRed y" yMax + hMax " w" xMax - 1, % Lang_Trans("global_match", (StrLen(search.1) < 4 || search.2 = -1) ? 2 : 1)

	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
	If modifications.Count() || vars.lootfilter.pending
	{
		dimensions := [vars.lootfilter.pending ? Lang_Trans("global_apply", 2) : "."]
		LLK_PanelDimensions([Lang_Trans("lootfilter_modifications")], settings.lootfilter.fSize, wHeader, hHeader)
		For key, object in modifications
			dimensions.Push(LLK_StringCase(key) ": " object.Count())
		LLK_PanelDimensions(dimensions, settings.lootfilter.fSize - 2, wModifications, hModifications)
		wModifications := Max(wHeader, wModifications)

		Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans Center HWNDhwnd gLootfilter_GUI x" xMax + 1 " y" yMax - 1 " w" wModifications " h" hDDL, % Lang_Trans("lootfilter_modifications")
		Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border HWNDhwnd2 Vertical BackgroundBlack cRed Range0-500", 0
		ControlGetPos, xMods, yMods, wMods, hMods,, ahk_id %hwnd%
		vars.hwnd.lootfilter.allmodifications := hwnd, vars.hwnd.lootfilter.x_bar := vars.hwnd.help_tooltips["lootfilter_modifications"] := hwnd2, vars.lootfilter.mod_header := [xMods, yMods + hMods]
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 2
		For key, array in modifications
		{
			color := LLK_HasVal(array, "(incompatible)", 1) ? "FF8000" : ""
			Gui, %GUI_name%: Add, Text, % "xs Section Border HWNDhwnd gLootfilter_GUI w" wModifications . (color ? " c" color : ""), % " " LLK_StringCase(key) ": " array.Count()
			ControlGetPos,, yModification_last,, hModification_last,, ahk_id %hwnd%
			vars.hwnd.lootfilter["modificationx_" key] := hwnd0, vars.hwnd.lootfilter["modificationtext_" key] := hwnd
			If color
				vars.hwnd.help_tooltips["lootfilter_incompatible"] := hwnd, handle2 .= "|"
		}

		If (pending := vars.lootfilter.pending)
		{
			Gui, %GUI_name%: Add, Text, % "xs Section Border BackgroundTrans Center gLootfilter_GUI HWNDhwnd cRed w" wModifications, % (pending = 2) ? Lang_Trans("lootfilter_update") : Lang_Trans("global_apply", 2)
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border Vertical HWNDhwnd2 BackgroundBlack cGreen Range0-500", 0
			ControlGetPos,, yModification_last,, hModification_last,, ahk_id %hwnd%
			vars.hwnd.lootfilter.apply_mods := hwnd, vars.hwnd.lootfilter.apply_bar := vars.hwnd.help_tooltips["lootfilter_apply mods"] := hwnd2
		}
		If (search := vars.lootfilter.search.2).Count() && (search.2 != -1)
			ControlGetPos,, yHide_last,, hHide_last,, % "ahk_id " hide_last
		yHide_last := yHide_last + hHide_last, yModification_last := yModification_last + hModification_last
		
		If yHide_last || yModification_last
			Gui, %GUI_name%: Add, Progress, % "Disabled Background606060 w4 x" xMax - 2 " y-1 h" Max(yHide_last, yModification_last), 0
		If yHide_last && (yHide_last < yModification_last)
			Gui, %GUI_name%: Add, Progress, % "Disabled Background606060 HWNDhwnd x-1 y" yFirst + yLast + margin - yFirst - 1 " h2 w" xMax, % 0
	}

	If vars.hwnd.lootfilter.search && InStr(check, "search")
		ControlFocus,, % "ahk_id " vars.hwnd.lootfilter.search
	Else ControlFocus,, % "ahk_id " vars.hwnd.lootfilter.font_reset

	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, wWin, hWin, ahk_id %hwnd_lootfilter%
	vars.lootfilter.width := wWin

	If (dock = 1)
		xPos := vars.monitor.x + vars.client.x + vars.client.w - Floor(vars.client.h * 0.6155) - wWin - 1, yPos := vars.monitor.y + vars.client.y + vars.client.h*0.53
	Else xPos := vars.monitor.x + vars.client.x + Floor(vars.client.h * 0.6155), yPos := vars.monitor.y + vars.client.y + vars.client.h*0.17

	Gui_CheckBounds(xPos, yPos, wWin, hWin), vars.lootfilter.xPos := xPos, vars.lootfilter.yPos := yPos
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(hwnd_lootfilter, "show", A_Gui ? 0 : 1, GUI_name), LLK_Overlay(hwnd_old, "destroy")

	If (yPos + yLast >= vars.monitor.h)
		LLK_ToolTip(Lang_Trans("global_match", 2), 3, xPos + xSearch, yPos + ySearch + hSearch,, "Red", settings.general.fSize + 4)
}

Lootfilter_ItemLabel(text, filter_index, style, xMax, iGroup)
{
	local
	global vars, settings
	static xControl, wControl, dimensions := {}

	GUI_name := vars.hwnd.lootfilter.GUI_name, loaded_filter := vars.lootfilter.filter, chunk := loaded_filter[filter_index], margin := settings.lootfilter.fWidth//2
	basetype := StrReplace(Lootfilter_Get(chunk, "basetype"), """")
	If (dimensions.fSize != settings.lootfilter.fSize - 2)
		dimensions := {"fSize": settings.lootfilter.fSize - 2}
	stack := InStr(text, "x ")
	action := SubStr(chunk, 1, 4), arealevel := Lootfilter_Get(chunk, "arealevel")

	If InStr(chunk, "LLK-UI modification")
		highlight := 1

	If (action = "hide")
		Gui, %GUI_name%: Font, strike

	For index, type in ["textcolor", "backgroundcolor", "bordercolor"]
	{
		textcolor := [170, 158, 129, 255], rgb := ""
		If InStr(chunk, type)
			%type% := SubStr(chunk, InStr(chunk, type) + StrLen(type) + 1), %type% := SubStr(%type%, 1, InStr(%type%, "`r") - 1), %type% := StrSplit(%type%, " ")
		For iRGB, vRGB in %type%
			If (iRGB < 4)
				rgb .= Format("{:02X}", vRGB)

		If !dimensions[text]
			LLK_PanelDimensions([text], settings.lootfilter.fSize - 2, width, height), dimensions[text] := width

		If (index = 1)
		{
			mod_index := 0, stacked_group := LLK_HasVal(vars.lootfilter.modifications[basetype], "stacksize", 1,,, 1)
			For index0, val in vars.lootfilter.modifications[basetype]
				If !InStr(vars.lootfilter.modifications[basetype].1, "(addition)") && Lootfilter_ChunkCompare(chunk, val)
					mod_index := index0

			style0 := "BackgroundTrans Border 0x200" (!stacked_group || stacked_group && mod_index < 2 ? " gLootfilter_GUI" : "")
				. " h" settings.lootfilter.fHeight * 1.4 " " (xControl + wControl + margin + dimensions[text] >= xMax ? "xs Section y+" margin + 1 : style)
		}
		Else style0 := "Disabled " (index = 2 ? "xp+2 yp+2 wp-4 hp-4" : "xp-2 yp-2 wp+4 hp+4")

		Gui, %GUI_name%: Add, % (index = 1) ? "Text" : "Progress", % style0 " " (index = 1 ? "c" : "Background") rgb " HWNDhwnd", % (index = 1) ? " " text " " : 0
		If (index = 1)
			vars.lootfilter.labels[hwnd] := (iGroup = 1 && stack) ? [filter_index, "all"] : [filter_index]
		ControlGetPos, xControl,, wControl,,, ahk_id %hwnd%
		vars.hwnd.lootfilter.last_control := hwnd
		If (index = 2)
			vars.hwnd.help_tooltips["lootfilter_tooltip " filter_index . vars.lootfilter.handles[filter_index]] := hwnd, vars.lootfilter.handles[filter_index] .= "|"
		Else If (index = 3)
		{
			thickness := Max(2, settings.lootfilter.fWidth//8)
			Gui, %GUI_name%: Add, Progress, % "Disabled Background" (highlight ? (InStr(chunk, "(addition)") ? "00CC00" : "Aqua") : "Black") " xp-" thickness " yp-" thickness " wp+" thickness*2 " hp+" thickness*2, 0
		}
	}
	Gui, %GUI_name%: Font, norm
}
