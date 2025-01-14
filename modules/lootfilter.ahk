Init_lootfilter()
{
	local
	global vars, settings

	If !FileExist("ini" vars.poe_version "\lootfilter.ini")
		IniWrite, % settings.general.fSize, % "ini" vars.poe_version "\lootfilter.ini", settings, font-size

	If !vars.lootfilter
		vars.lootfilter := {"config_folder": SubStr(vars.system.config, 1, InStr(vars.system.config, "\",, 0))}, settings.lootfilter := {}

	ini := IniBatchRead("ini" vars.poe_version "\lootfilter.ini")
	settings.lootfilter.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.lootfilter.fSize, font_height, font_width), settings.lootfilter.fHeight := font_height, settings.lootfilter.fWidth := font_width
	LLK_FontDimensions(settings.lootfilter.fSize - 4, font_height, font_width), settings.lootfilter.fHeight2 := font_height, settings.lootfilter.fWidth2 := font_width
	settings.lootfilter.active := !Blank(check := ini.settings["active filter"]) && FileExist(vars.lootfilter.config_folder . check ".filter") ? check : ""
	settings.lootfilter.GUI_color := !Blank(check := ini.settings["GUI color"]) ? check : "404040"
	settings.lootfilter.highlight_color := !Blank(check := ini.settings["highlight color"]) ? check : "00FFFF"
	settings.lootfilter.style_color := !Blank(check := ini.settings["style color"]) ? check : "FF8000"
	settings.lootfilter.hLabel := Ceil(settings.lootfilter.fHeight * 1.5)
	While Mod(settings.lootfilter.hLabel, 5)
		settings.lootfilter.hLabel -= 1

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
		vars.lootfilter.maps_hide := vars.lootfilter.maps_hide_previous := 1, vars.lootfilter.classes_hide := [1, {}, 0]
		vars.lootfilter.gems_hide := [1, 1, 1], vars.lootfilter.gems_hide_previous := [1, 1, 1]
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
			{
				chunk := (SubStr(chunk, 1, 1) = "#") ? SubStr(chunk, InStr(chunk, "`n") + 1) : chunk, chunk := StrReplace(chunk, "`t")
				If (iLoad = 2 && index = 1) && InStr(chunk, "base file:")
					file2_base := SubStr(chunk, InStr(chunk, "base file:") + 11)
				Else If (SubStr(chunk, 1, 1) = "#")
					Continue
				Else If (iLoad = 1)
				{
					If InStr(chunk, "basetype ==") || vars.poe_version && InStr(chunk, "basetype """)
					{
						basetype := Lootfilter_Get(chunk, "basetype")
						For iBasetype, vBasetype in StrSplit(StrReplace(basetype, """ """, ""","""), ",")
							If !bases[vBasetype]
								bases[vBasetype] := 1
							Else bases[vBasetype] += 1
					}
					base_filter.Push(chunk)
				}
				Else If (iLoad = 2) && InStr(chunk, "(global):")
				{
					rarities := ["off", "magic", "rare", "unique"]
					If InStr(chunk, "LLK-UI modification (global): hide maps/waystones")
						vars.lootfilter.maps_hide_previous := vars.lootfilter.maps_hide := Lootfilter_Get(chunk, (vars.poe_version ? "waystone" : "map") "tier"), filter[-1] := chunk
					Else If InStr(chunk, "LLK-UI modification (global): hide classes")
					{
						classes := StrReplace(Lootfilter_Get(chunk, "`nClass"), """ """, """|"""), filter[-2] := chunk
						vars.lootfilter.classes_hide := [LLK_HasVal(rarities, Lootfilter_Get(chunk, "Rarity")), {}, InStr(chunk, "Quality < 1") ? 0 : 1]
						Loop, Parse, classes, % "|", % """"
							vars.lootfilter.classes_hide.2[A_LoopField] := 1
					}
					Else If InStr(chunk, "LLK-UI modification (global): hide skill gems")
						vars.lootfilter.gems_hide.1 := vars.lootfilter.gems_hide_previous.1 := Lootfilter_Get(chunk, "ItemLevel"), gems_append .= (!gems_append ? "" : "`r`n`r`n") . chunk
					Else If InStr(chunk, "LLK-UI modification (global): hide spirit gems")
						vars.lootfilter.gems_hide.2 := vars.lootfilter.gems_hide_previous.2 := Lootfilter_Get(chunk, "ItemLevel"), gems_append .= (!gems_append ? "" : "`r`n`r`n") . chunk
					Else If InStr(chunk, "LLK-UI modification (global): hide support gems")
						vars.lootfilter.gems_hide.3 := vars.lootfilter.gems_hide_previous.3 := Lootfilter_Get(chunk, "ItemLevel"), gems_append .= (!gems_append ? "" : "`r`n`r`n") . chunk
				}
				Else filter.Push(chunk)
			}
		}
		vars.lootfilter.classes_hide_previous := LLK_CloneObject(vars.lootfilter.classes_hide)

		If !filter.Count()
			vars.lootfilter.filter := base_filter.Clone()
		If gems_append
			vars.lootfilter.filter[-3] := gems_append
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
			{
				For index, match in LLK_HasRegex(vars.lootfilter.bases, "i)" (InStr(val, """") ? "^" : "") StrReplace(StrReplace(StrReplace(val, "$", """$"), "^", "^"""), " ", ".") . (InStr(val, """") ? "$" : ""), 1, 1)
					search_results[match] := vars.lootfilter.bases[match]
			}
			vars.lootfilter.search := [search.1, search_results]
		}
		vars.lootfilter.search_override := ""
		Return 1
	}
	Else If (mode = "unavailable")
	{
		IniDelete, % "ini" vars.poe_version "\lootfilter.ini", settings, active filter
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
			If (index > 0) && InStr(val, "LLK-UI modification")
				If !IsObject(modifications[(basetype := SubStr(Lootfilter_Get(val, "basetype"), 2, -1))])
					modifications[basetype] := [val]
				Else modifications[basetype].Push(val)

		If (mode = "load")
		{
			vars.lootfilter.modifications_backup := LLK_CloneObject(modifications)
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
							count := filter.Length(), target_index := [0, 0]
							Loop, % count
							{
								iFilter := count - (A_Index - 1), action := SubStr(chunk, 1, 4), basetype := Lootfilter_Get(chunk, "basetype"), chunk2 := filter[iFilter]
								If !InStr(chunk2, basetype) || InStr(chunk2, "LLK-UI modification")
									Continue
								If Lootfilter_ChunkCompare(chunk, chunk2)
								{
									vars.lootfilter.filter.InsertAt(iFilter, Lootfilter_ChunkModify(chunk2, action, {"BaseType": basetype}) . (InStr(chunk, "(addition)") ? " (addition)" : ""))
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

Lootfilter_ChunkModify(chunk, action, object := "", stack_size := 0)
{
	local

	If (action = 1)
		modified_chunk := StrReplace(chunk, (prev_action := SubStr(chunk, 1, 4)), (prev_action = "show") ? "Hide" : "Show",, 1)
	Else If !action
		modified_chunk := chunk
	Else modified_chunk := StrReplace(chunk, SubStr(chunk, 1, 4), action,, 1)

	modified_chunk .= (!InStr(modified_chunk, "LLK-UI modification") ? "`r`n# LLK-UI modification" : "") . (LLK_HasKey(object, "color", 1) && !InStr(modified_chunk, "(style)") ? " (style)" : "")
	Loop, Parse, modified_chunk, `n, `r
	{
		If ((index := A_Index) = 1)
			modified_chunk := ""
		insert_line := "", loopfield := A_LoopField
		For key, val in object
			If (index != 1) && !LLK_StringCompare(loopfield, ["basetype", "class"]) && !InStr(chunk, key) && !InStr(modified_chunk, key)
				modified_chunk .= "`r`n" (InStr(key, "color") ? "Set" key " " val : key " " val)
			Else If InStr(loopfield, key)
			{
				end := 0
				Loop, Parse, % "=<>"
					end := ((check := InStr(loopfield, A_LoopField,, 0)) > end) ? check + 1 : end
				If !end
					end := InStr(A_LoopField, " ")
				insert_line := SubStr(A_LoopField, 1, end) . (key = "basetype" ? """" StrReplace(val, """") """" : val)
				modified_chunk .= (!modified_chunk ? "" : "`r`n") insert_line
				Break
			}
		If !insert_line
			modified_chunk .= (!modified_chunk ? "" : "`r`n") A_LoopField
	}
	Return modified_chunk
}

Lootfilter_Get(chunk, data, ByRef operator := "")
{
	local

	operator := ""
	If (data = "style")
	{
		object := {}
		For index, type in ["TextColor", "BackgroundColor", "BorderColor"]
		{
			textcolor := "255 255 255 255", backgroundcolor := "0 0 0 240", bordercolor := "0 0 0 255"
			If (check := InStr(chunk, type,, 0))
				%type% := SubStr(chunk, check + StrLen(type) + 1), %type% := SubStr(%type%, 1, (check := InStr(%type%, "`r")) ? check - 1 : StrLen(%type%))
			object[type] := %type%
		}
		Return object
	}
	Else If (check := InStr(chunk, data,, 0))
	{
		data := StrReplace(data, "`n")
		operator := SubStr(chunk, check), operator := SubStr(operator, 1, InStr(operator, "`r") ? InStr(operator, "`r") - 1 : StrLen(operator))
		If LLK_PatternMatch(operator, "", ["<", ">", "="])
			operator := SubStr(operator, InStr(operator, " ") + 1), operator := SubStr(operator, 1, InStr(operator, " ") - 1)
		Else operator := ""
		%data% := SubStr(chunk, check), %data% := SubStr(%data%, 1, (check := InStr(%data%, "`r")) ? check - 1 : StrLen(%data%))
		start := InStr("arealevel, stacksize, maptier, waystonetier, rarity, itemlevel", data) ? InStr(%data%, " ",, 0) + 1 : InStr(%data%, InStr(data, "color") ? " " : """")
		%data% := SubStr(%data%, start + (InStr(data, "color") ? 1 : 0))
		Return (%data%)
	}
}

Lootfilter_GUI(cHWND := "", side := "", activation := "")
{
	local
	global vars, settings
	static toggle := 0, dock := 1, item_classes

	If !IsObject(item_classes) && vars.poe_version
		item_classes := {"Claws": 0, "Daggers": 0, "Wands": 1, "One Hand Swords": 0, "One Hand Axes": 0, "One Hand Maces": 1, "Sceptres": 1, "Spears": 0, "Flails": 0, "Bows": 1, "Staves": 1, "Two Hand Swords": 0, "Two Hand Axes": 0, "Two Hand Maces": 1, "Quarterstaves": 1, "Crossbows": 1, "Traps": 0, "Quivers": 1, "Shields": 1, "Foci": 1}

	If !IsObject(vars.lootfilter)
		Init_lootfilter()

	check := LLK_HasVal(vars.hwnd.lootfilter, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	label := LLK_HasKey(vars.lootfilter.labels, cHWND), dock := InStr(side, "dock_") ? SubStr(side, InStr(side, "_") + 1) : dock
	filter := vars.lootfilter.filter

	If !LLK_PatternMatch(check, "", ["selection_", "font_"]) && !(cHWND = "close")
		vars.lootfilter.selection := vars.lootfilter.selection_backup := ""

	If (cHWND = "close")
	{
		If vars.lootfilter.pending || vars.lootfilter.selection.pending || (vars.lootfilter.maps_hide != vars.lootfilter.maps_hide_previous) || vars.lootfilter.class_pending || vars.lootfilter.gem_pending
		{
			xPos := vars.lootfilter.xPos + vars.lootfilter.mod_header.1, yPos := vars.lootfilter.yPos + vars.lootfilter.mod_header.2
			LLK_ToolTip(Lang_Trans("lootfilter_unsaved"), 1.5, xPos, yPos,, "Red",,,,, "White")
			If !(LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton") || LLK_Progress(vars.hwnd.lootfilter.x_bar, "ESC"))
				Return
		}
		LLK_Overlay(vars.hwnd.lootfilter.main, "destroy"), vars.lootfilter.search := vars.hwnd.lootfilter.main := ""
		vars.lootfilter.pending := (vars.lootfilter.pending = 2) ? 2 : 0
		vars.lootfilter.filter := vars.lootfilter.filter_backup.Clone(), vars.lootfilter.modifications := LLK_CloneObject(vars.lootfilter.modifications_backup)
		vars.lootfilter.maps_hide := vars.lootfilter.maps_hide_previous
		vars.lootfilter.gems_hide := vars.lootfilter.gems_hide_previous.Clone()
		vars.lootfilter.classes_hide := LLK_CloneObject(vars.lootfilter.classes_hide_previous)
		Return
	}
	Else If (check = "basefilter")
	{
		If FileExist(vars.lootfilter.config_folder . A_GuiControl ".filter")
		{
			IniWrite, % """" (settings.lootfilter.active := A_GuiControl) """", % "ini" vars.poe_version "\lootfilter.ini", settings, active filter
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
		IniWrite, % settings.lootfilter.fSize, % "ini" vars.poe_version "\lootfilter.ini", settings, font-size
		LLK_FontDimensions(settings.lootfilter.fSize, font_height, font_width), settings.lootfilter.fWidth := font_width, settings.lootfilter.fHeight := font_height
		LLK_FontDimensions(settings.lootfilter.fSize - 4, font_height, font_width), settings.lootfilter.fWidth2 := font_width, settings.lootfilter.fHeight2 := font_height
		settings.lootfilter.hLabel := Ceil(settings.lootfilter.fHeight * 1.5)
		While Mod(settings.lootfilter.hLabel, 5)
			settings.lootfilter.hLabel -= 1
	}
	Else If InStr(check, "_color")
	{
		KeyWait, LButton
		KeyWait, RButton
		type := InStr(check, "gui_") ? "gui" : InStr(check, "highlight_") ? "highlight" : "style"
		If (vars.system.click = 1)
			rgb := RGB_Picker(settings.lootfilter[type "_color"])
		Else rgb := "default"

		If Blank(rgb)
			Return
		IniWrite, % """" (settings.lootfilter[type "_color"] := (rgb = "default") ? (type = "gui" ? "404040" : (type = "highlight") ? "00FFFF" : "FF8000") : rgb) """", % "ini" vars.poe_version "\lootfilter.ini", settings, % type " color"
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
		GuiControl,, % vars.hwnd.lootfilter.search, % (shift && !Blank(input) ? input ", " : "") """" basetype """"
		Lootfilter_GUI("search")
		Return
	}
	Else If (check = "apply_mods")
	{
		If !LLK_Progress(vars.hwnd.lootfilter.apply_bar, "LButton",, 0) && !(dev_mode := (settings.general.dev && LLK_Progress(vars.hwnd.lootfilter.apply_bar, "RButton",, 0)))
			Return
		vars.lootfilter.filter_backup := vars.lootfilter.filter.Clone(), vars.lootfilter.modifications_backup := LLK_CloneObject(vars.lootfilter.modifications)
		vars.lootfilter.maps_hide_previous := vars.lootfilter.maps_hide
		If (vars.lootfilter.classes_hide.1 > 1) && vars.lootfilter.classes_hide.2.Count()
			vars.lootfilter.classes_hide_previous := LLK_CloneObject(vars.lootfilter.classes_hide)
		Else vars.lootfilter.classes_hide_previous := [1, {}, 0], vars.lootfilter.classes_hide := [1, {}, 0]
		vars.lootfilter.gems_hide_previous := vars.lootfilter.gems_hide.Clone()
		FileDelete, % vars.lootfilter.config_folder "LLK-UI*.filter"
		file_dump := "# LLK-UI modded filter, base file: " settings.lootfilter.active
		For index, chunk in vars.lootfilter.filter
			file_dump .= "`r`n`r`n" chunk
		file := FileOpen(vars.lootfilter.config_folder . (new_file := "LLK-UI_modded_filter") ".filter", "w", "UTF-8-RAW")
		file.Write(file_dump "`r`n"), file.Close()
		KeyWait, LButton
		KeyWait, RButton
		If (vars.lootfilter.pending = 2)
			Lootfilter_Base("load")
		vars.lootfilter.pending := "", Clipboard := "/itemfilter " new_file
		If !dev_mode
		{
			WinActivate, % "ahk_id " vars.hwnd.poe_client
			WinWaitActive, % "ahk_id " vars.hwnd.poe_client
			SendInput, {ENTER}
			Sleep 100
			SendInput, ^{v}{ENTER}
		}
	}
	Else If (check = "map_hide")
	{
		input := IsNumber(A_GuiControl) ? A_GuiControl : 1, vars.lootfilter.search := "", vars.lootfilter.maps_hide := input
		append := "Hide`r`nRarity < Unique`r`n" (vars.poe_version ? "BaseType ""Waystone""`r`nWaystone" : "Class == ""Maps""`r`nMap") "Tier < " input "`r`nSetBorderColor 255 0 0 255`r`n# LLK-UI modification (global): hide maps/waystones"
		If (input > 1)
			vars.lootfilter.filter[-1] := append
		Else	vars.lootfilter.filter.Delete(-1)
	}
	Else If InStr(check, "class_hide") || (check = "qualsocket_hide")
	{
		vars.lootfilter.search := "", rarities := ["off", "Magic", "Rare", "Unique"]
		If InStr(check, "class_hide_")
		{
			class := SubStr(control, InStr(control, "_") + 1), input := LLK_ControlGet(cHWND)
			If input
				vars.lootfilter.classes_hide.2[class] := input
			Else vars.lootfilter.classes_hide.2.Delete(class)
		}
		Else If (check = "qualsocket_hide")
			vars.lootfilter.classes_hide.3 := LLK_ControlGet(cHWND)
		Else vars.lootfilter.classes_hide := ((input := LLK_HasVal(rarities, A_GuiControl)) > 1) ? [input, vars.lootfilter.classes_hide.2.Clone(), vars.lootfilter.classes_hide.3] : [1, {}, 0]

		For class, val in vars.lootfilter.classes_hide.2
			If val
				append_classes .= (!append_classes ? "" : " ") """" class """"

		append := "Hide`r`nRarity < " rarities[vars.lootfilter.classes_hide.1] "`r`nClass == " append_classes (!vars.lootfilter.classes_hide.3 ? "`r`nQuality < 1`r`nSockets 0" : "") "`r`nSetBorderColor 255 0 0 255`r`n# LLK-UI modification (global): hide classes"
		If (vars.lootfilter.classes_hide.1 > 1) && vars.lootfilter.classes_hide.2.Count()
			vars.lootfilter.filter[-2] := append
		Else vars.lootfilter.filter.Delete(-2)
	}
	Else If InStr(check, "gem_hide")
	{
		types := ["Skill", "Spirit", "Support"], type := SubStr(control, InStr(control, "_") + 1), input := LLK_ControlGet(cHWND), input := IsNumber(input) ? input : 1
		vars.lootfilter.gems_hide[LLK_HasVal(types, type)] := input, gems_hide := vars.lootfilter.gems_hide
		For index, gem in types
		{
			If (gems_hide[index] > 1)
				append .= (!append ? "" : "`r`n`r`n") "Hide`r`nBaseType == ""Uncut " gem " Gem""`r`nItemLevel < " gems_hide[index] "`r`nSetBorderColor 255 0 0 255`r`n# LLK-UI modification (global): hide " LLK_StringCase(gem) " gems"
		}
		
		If append
			vars.lootfilter.filter[-3] := append
		Else vars.lootfilter.filter.Delete(-3)
	}
	Else If InStr(check, "hide_") || InStr(check, "modificationtext_") && (vars.system.click = 2) || (check = "allmodifications")
	{
		If (check = "allmodifications") && LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton")
			remove_all := 1
		Else If (check = "allmodifications") && !LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton")
			Return
		count := vars.lootfilter.filter.Length(), control := StrReplace(control, """")

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
				If InStr(chunk, "`r`ncontinue") || InStr(chunk, "LLK-UI modification") || !InStr(Lootfilter_Get(chunk, "basetype"), """" control """")
				|| (arealevel := Lootfilter_Get(chunk, "arealevel"), operator) && (arealevel <= (vars.poe_version ? 1 : 67)) && !InStr(operator, ">") ; placeholder: arealevel 1 for PoE2
					Continue
				Else
				{
					modified_chunk := Lootfilter_ChunkModify(chunk, "Hide", {"BaseType": control})
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
	Else If InStr(check, "selection_")
	{
		selection := vars.lootfilter.selection
		If InStr(check, "color")
		{
			If (vars.system.click = 2)
				vars.lootfilter.selection.modifications[control] := vars.lootfilter.selection_backup.modifications[control]
			Else If (vars.system.click = 1) && !Blank(pick := RGB_Picker(RGB_Convert(original := vars.lootfilter.selection.modifications[control])))
				rgb := RGB_Convert(pick), vars.lootfilter.selection.modifications[control] := rgb.1 " " rgb.2 " " rgb.3 " " SubStr(original, InStr(original, " ",, 0) + 1)
			Else Return
		}
		Else If InStr(check, "_discard")
		{
			If LLK_Progress(vars.hwnd.lootfilter.x_bar, "LButton")
				vars.lootfilter.selection := vars.lootfilter.selection_backup := ""
			Else Return
		}
		Else If InStr(check, "_apply")
		{
			If InStr((chunk := vars.lootfilter.filter[selection.index]), "LLK-UI modification")
				vars.lootfilter.filter[selection.index] := Lootfilter_ChunkModify(chunk, 0, vars.lootfilter.selection.modifications)
			Else vars.lootfilter.filter.InsertAt(selection.index, Lootfilter_ChunkModify(chunk, 0, vars.lootfilter.selection.modifications))

			Lootfilter_Base("modifications"), vars.lootfilter.selection := vars.lootfilter.selection_backup := ""
		}
	}
	Else If !Blank(label)
	{
		text := SubStr(LLK_ControlGet(cHWND), 2, -1), filter_index := vars.lootfilter.labels[label].1, basetype := IsNumber(SubStr(text, 1, 1)) ? SubStr(text, InStr(text, " ") + 1) : text
		chunk := vars.lootfilter.filter[filter_index], action := SubStr(chunk, 1, 4), stack := Lootfilter_Get(chunk, "stacksize")

		If (vars.system.click = 1)
		{
			GuiControl,, % vars.hwnd.lootfilter.search, % """" basetype """"
			Lootfilter_Base("search")
			vars.lootfilter.selection := {"index": filter_index, "stack": stack, "modifications": {"basetype": basetype}}, colors := Lootfilter_Get(vars.lootfilter.filter[filter_index], "style")
			For key, val in colors
				vars.lootfilter.selection.modifications[key] := val
			vars.lootfilter.selection_backup := LLK_CloneObject(vars.lootfilter.selection)
		}
		Else
		{
			If InStr(chunk, "LLK-UI modification")
			{
				KeyWait, RButton, T0.2
				longpress := ErrorLevel

				If !InStr(chunk, "(style)") || InStr(chunk, "(style)") && ErrorLevel && LLK_Progress(vars.hwnd.lootfilter["labelbar_" filter_index], "RButton")
					vars.lootfilter.filter.RemoveAt(filter_index)
				Else If !longpress
					vars.lootfilter.filter[filter_index] := Lootfilter_ChunkModify(chunk, 1)
				Else Return

				Lootfilter_Base("modifications")
			}
			Else
			{
				modified_chunk := Lootfilter_ChunkModify(chunk, (action2 := (action = "show") ? "Hide" : "Show"), {"BaseType": basetype})
				vars.lootfilter.filter.InsertAt(filter_index, modified_chunk)
				If stack
					For index, val in vars.lootfilter.filter
						If (index < 1) || (index <= filter_index) || !InStr(val, """" basetype """") || (arealevel := Lootfilter_Get(val, "arealevel", operator)) && (arealevel <= (vars.poe_version ? 1 : 67)) && !InStr(operator, ">")
						|| InStr((prev_chunk := vars.lootfilter.filter[index - 1]), "LLK-UI modification") && InStr(prev_chunk, """" basetype """")
							Continue
						Else If Lootfilter_ChunkCompare(modified_chunk, val, 1)
							If InStr(val, "LLK-UI modification") ;override previous modifications to avoid unintentional flip-flopping
								vars.lootfilter.filter[index] := StrReplace(SubStr(val, 1, 4), action2,, 1)
							Else vars.lootfilter.filter.InsertAt(index, Lootfilter_ChunkModify(val, action2, {"BaseType": basetype}))
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
	Gui, %GUI_name%: Add, Text, % "xp yp hp Border BackgroundTrans Section HWNDhwnd w" wLabel, % " " Lang_Trans("lootfilter_basefilter") " "
	Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4

	Loop, Files, % vars.lootfilter.config_folder "*.filter"
		If !InStr(A_LoopFileName, "LLK-UI")
			file := LLK_StringCase(StrReplace(A_LoopFileName, ".filter")), ddl .= file . (file = settings.lootfilter.active ? "||" : "|")
			, max_length := (StrLen(file) > max_length) ? StrLen(file) : max_length, count += 1

	wDDL := Max(fWidth * 10, Ceil(settings.lootfilter.fWidth2 * max_length * 0.9))
	Gui, %GUI_name%: Add, Text, % "ys hp BackgroundTrans Border w" wDDl
	Gui, %GUI_name%: Add, DDL, % "xp yp wp HWNDhwnd1 gLootfilter_GUI R" Max(1, count), % ddl
	Gui, %GUI_name%: Add, Pic, % "ys hp-2 w-1 Border BackgroundTrans gLootfilter_GUI HWNDhwnd2", % "HBitmap:*" vars.pics.global.reload
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
		Gui, %GUI_name%: Add, Pic, % "ys hp-2 w-1 Border BackgroundTrans gLootfilter_GUI HWNDhwnd2", % "HBitmap:*" vars.pics.global.close
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
		ControlGetPos, xSearch, ySearch, wSearch, hSearch,, ahk_id %hwnd1%
		vars.hwnd.lootfilter.search_go := hwnd, vars.hwnd.lootfilter.search := vars.hwnd.help_tooltips.lootfilter_search := hwnd1
		vars.hwnd.lootfilter.resetsearch := vars.hwnd.help_tooltips["lootfilter_search reset"] := hwnd2
	}

	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans", % " " Lang_Trans("global_uisize") " "
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans Center gLootfilter_GUI HWNDhwnd w" fWidth * 2, % "–"
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans Center gLootfilter_GUI HWNDhwnd1 w" fWidth * 2, % "r"
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans Center gLootfilter_GUI HWNDhwnd2 w" fWidth * 2, % "+"
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans gLootfilter_GUI HWNDhwnd3 w" fWidth, % ""
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack HWNDhwnd4 c" settings.lootfilter.GUI_color, 100
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans gLootfilter_GUI HWNDhwnd5 w" fWidth, % ""
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack HWNDhwnd6 c" settings.lootfilter.highlight_color, 100
	Gui, %GUI_name%: Add, Text, % "ys hp Border BackgroundTrans gLootfilter_GUI HWNDhwnd7 w" fWidth, % ""
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack HWNDhwnd8 c" settings.lootfilter.style_color, 100
	ControlGetPos, xControl, yControl, wControl, hControl,, % "ahk_id " hwnd7
	vars.hwnd.lootfilter.font_minus := hwnd, vars.hwnd.lootfilter.font_reset := hwnd1, vars.hwnd.lootfilter.font_plus := hwnd2
	vars.hwnd.lootfilter.gui_color := hwnd3, vars.hwnd.help_tooltips["lootfilter_gui color"] := hwnd4
	vars.hwnd.lootfilter.highlight_color := hwnd5, vars.hwnd.help_tooltips["lootfilter_highlight color"] := hwnd6
	vars.hwnd.lootfilter.style_color := hwnd7, vars.hwnd.help_tooltips["lootfilter_style color"] := hwnd8
	xMax := xControl + wControl, yMax := yControl, hMax := hDDL := hControl

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
				If (index < 1) || !RegExMatch(chunk, "i)\s.*" base ".*") || InStr(chunk, "`r`ncontinue") || arealevel && (arealevel <= (vars.poe_version ? 1 : 67)) && !InStr(operator, ">") || search_override && !InStr(chunk, "LLK-UI modification")
					Continue
				stack := Lootfilter_Get(chunk, "stacksize"), text := (stack ? stack "x " : "") StrReplace(base, """")

				If stack && labels[text] || LLK_HasKey(labels, "x " StrReplace(base, """"), 1) && labels[text]
					Continue
				If !stack
					Loop
						If !InStr((prev_chunk := vars.lootfilter.filter[index - A_Index]), "LLK-UI modification")
							Break
						Else If InStr(prev_chunk, base) && !InStr(prev_chunk, "(addition)")
							Continue 2

				If ((count += 1) = 1)
				{
					ControlGetPos,, yFirst,, hFirst,, ahk_id %hwnd%
					yFirst += hFirst - 2
				}
				Lootfilter_ItemLabel(text, index, (count = 1) ? "xs x" wLabel + margin - 1 " Section y+" margin + 1 : "ys x+" margin//2, (base = prev) ? xMax : 10000, count)
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
			modified := modifications[StrReplace(base, """")].Count()
			Gui, %Gui_name%: Add, Text, % "ys x-1 y" yFirst + (A_Index = 1 ? 0 : 1) " Border BackgroundTrans Center 0x200 gLootfilter_GUI HWNDhwnd h" yLast + margin + 2 - yFirst " w" wLabel, % Lang_Trans("global_" (modified ? "revert" : "hide"))
			Gui, %Gui_name%: Add, Progress, % "Disabled Border HWNDhwnd2 Border xp yp wp hp BackgroundBlack c" (modified ? settings.lootfilter.gui_color : "Black"), % 100
			Gui, %Gui_name%: Add, Text, % "x+-1 yp w" xMax - wLabel + 1 " hp Border BackgroundTrans", % ""
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack c" settings.lootfilter.gui_color, 100 
			vars.hwnd.lootfilter["hide_" base] := hide_last := hwnd
			vars.hwnd.help_tooltips["lootfilter_" (modified ? "revert" : "hide") . handle] := hwnd2, handle .= "|"

			;If (bases != search.Count())
			;	Gui, %GUI_name%: Add, Progress, % "Disabled Background646464 HWNDhwnd xs x-1 Section h2 w" xMax " y+-1", % 0
		}
	}
	Else If !Blank((search := vars.lootfilter.search).1)
		Gui, %GUI_name%: Add, Text, % "Center x-1 cRed y" yMax + hMax " w" xMax - 1, % Lang_Trans("global_match", (StrLen(search.1) < 4) ? 2 : 1)
	Else If settings.lootfilter.active
	{
		mapsDDL := classesDDL := skillgemsDDL := spiritgemsDDL := supportgemsDDL := "off", maps_hide := vars.lootfilter.maps_hide, color := settings.lootfilter.highlight_color
		Loop, % vars.poe_version ? 14 : 15
			mapsDDL .= "|" A_Index + 1
		For index, rarity in ["magic", "rare", "unique"]
			classesDDL .= "|" rarity
		Loop 19
			skillgemsDDL .= "|" A_Index + 1, spiritgemsDDL .= "|" A_Index + 1, supportgemsDDL .= (A_Index < 3) ? "|" A_Index + 1 : ""
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
		;Gui, %GUI_name%: Add, Progress, % "xs Disabled Background646464 x-1 w" xMax " h5", 0
		Gui, %GUI_name%: Add, Text, % "xs Section BackgroundTrans x-1 Border Center w" xMax " h" hDDL, % "global overrides:"
		Gui, %GUI_name%: Add, Text, % "xp yp hp Hidden HWNDhwnd", % "global overrides:"
		ControlGetPos, xDummy, yDummy, wDummy, hDummy,, % "ahk_id " hwnd
		Gui, %GUI_name%: Add, Pic, % "x" xMax//2 + wDummy * 0.55 " yp hp w-1 HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
		Gui, %GUI_name%: Add, Text, % "xs Section y+-1 w" xMax " h" hDDL + 8 " Border BackgroundTrans"
		Gui, %GUI_name%: Add, Text, % "xp yp hp 0x200 HWNDhwnd" (maps_hide > 1 ? " c" color : ""), % " hide " (vars.poe_version ? "waystones" : "non-unique maps") " below tier "
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4
		ControlGetPos, xText, yText, wText, hText,, % "ahk_id " hwnd
		Gui, %GUI_name%: Add, DDL, % "ys yp+4 x+0 hp HWNDhwnd gLootfilter_GUI Choose" vars.lootfilter.maps_hide " R" StrSplit(mapsDDL, "|", A_Space).Count() " w" settings.lootfilter.fSize*3.25, % mapsDDL
		vars.hwnd.lootfilter.map_hide := hwnd, vars.hwnd.help_tooltips["lootfilter_global overrides"] := hwnd0
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize

		If vars.poe_version
		{
			classes_hide := vars.lootfilter.classes_hide, gems_hide := vars.lootfilter.gems_hide
			Gui, %GUI_name%: Add, Text, % "xs Section HWNDhwnd y" yText + hText - 1 " 0x200 h" hDDL + 6 . (classes_hide.1 > 1 && classes_hide.2.Count() ? " c" color : ""), % " hide specific item-classes below "
			Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4
			Gui, %GUI_name%: Add, DDL, % "ys x+0 yp+3 h" hDDL " HWNDhwnd1 gLootfilter_GUI Choose" classes_hide.1 " R" StrSplit(classesDDL, "|", A_Space).Count() " w" settings.lootfilter.fSize*5, % classesDDL
			Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
			vars.hwnd.lootfilter.class_hide := vars.hwnd.help_tooltips["lootfilter_global item-classes"] := hwnd1

			If (vars.lootfilter.classes_hide.1 > 1)
			{
				added := 0
				For class, val in item_classes
					If val
					{
						style := (!Mod(added, 3) || !added ? "Section xs y+0 x" settings.lootfilter.fWidth : "ys x+0") " w" xMax//3 - settings.lootfilter.fWidth//2, added += 1
						checked := vars.lootfilter.classes_hide.2[class] ? 1 : 0
						Gui, %GUI_name%: Add, Checkbox, % style " gLootfilter_GUI HWNDhwnd Checked" checked . (vars.lootfilter.classes_hide.1 > 1 && checked ? " c" color : ""), % LLK_StringCase(class)
						vars.hwnd.lootfilter["class_hide_" class] := hwnd
					}
				Gui, %GUI_name%: Add, Checkbox, % "Section xs y+" settings.lootfilter.fWidth//2 " gLootfilter_GUI HWNDhwnd Checked" (classes_hide.3 ? 1 . (classes_hide.1 > 1 && classes_hide.2.Count() ? " c" color : "") : 0), % "also hide items with quality/sockets"
				vars.hwnd.lootfilter.qualsocket_hide := hwnd
			}

			Gui, %GUI_name%: Add, Progress, % "Disabled xs x-1 Section y+4 w" xMax " h1 Background646464", 0
			Gui, %GUI_name%: Add, Text, % "xs Section y+0 HWNDhwnd 0x200 h" hDDL + 6 . (gems_hide.1 + gems_hide.2 + gems_hide.3 > 3 ? " c" color : ""), % " hide uncut skill/spirit/supp gems below level "
			Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 4
			For index, val in ["skill", "spirit", "support"]
			{
				Gui, %GUI_name%: Add, DDL, % "ys x+0 yp+" (index = 1 ? 3 : 0) " h" hDDL " HWNDhwnd1 gLootfilter_GUI Choose" gems_hide[index] " R" StrSplit(%val%gemsDDL, "|", A_Space).Count() " w" settings.lootfilter.fSize*3.25, % %val%gemsDDL
				vars.hwnd.lootfilter["gem_hide_" val] := hwnd1
			}
			Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize
		}
		hide_last := hwnd
	}

	classes_hide := vars.lootfilter.classes_hide, classes_hide_previous := vars.lootfilter.classes_hide_previous, vars.lootfilter.class_pending := 0
	If (classes_hide.1 != classes_hide_previous.1) || (classes_hide.3 != classes_hide_previous.3) || (classes_hide.2.Count() != classes_hide_previous.2.Count())
		vars.lootfilter.class_pending := 1
	Else
	{
		For key, val in classes_hide.2
			If (val != classes_hide_previous.2[key])
				vars.lootfilter.class_pending := 1
		For key, val in classes_hide_previous.2
			If (val != classes_hide.2[key])
				vars.lootfilter.class_pending := 1
	}

	gems_hide := vars.lootfilter.gems_hide, gems_hide_previous := vars.lootfilter.gems_hide_previous, vars.lootfilter.gem_pending := 0
	Loop 3
		If (gems_hide[A_Index] != gems_hide_previous[A_Index])
			vars.lootfilter.gem_pending := 1

	If (selection := vars.lootfilter.selection)
	{
		text := (selection.stack ? selection.stack "x " : "") selection.modifications.basetype
		LLK_PanelDimensions([Lang_Trans("lootfilter_selection")], settings.lootfilter.fSize, wSelectionHeader, hSelectionHeader)
		Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans Center HWNDhwnd_header gLootfilter_GUI x" xMax + 2 " y" yMax - 1 " w" wSelectionHeader " h" hDDL, % Lang_Trans("lootfilter_selection")
		ControlGetPos, xMods, yMods, wMods, hMods,, ahk_id %hwnd_header%
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 2
		Lootfilter_ItemLabel(text, selection.index, ["xs Section xp+" margin " y+" margin + 1])
		Gui, %GUI_name%: Add, Text, % "ys x+0 hp BackgroundTrans HWNDhwnd 0x200", % " " Lang_Trans("global_color", 2) " "
		ControlGetPos, xText, yText, wText, hText,, ahk_id %hwnd%
		colors := Lootfilter_Get(filter[selection.index], "style"), vars.lootfilter.selection.pending := 0
		For index, val in ["textcolor", "backgroundcolor", "bordercolor"]
		{
			If (index = 1)
				style := "ys x+" settings.lootfilter.fHeight//2 " yp+" settings.lootfilter.hLabel * 0.4 " w" Floor(settings.lootfilter.fWidth*3) " h" settings.lootfilter.hLabel/5
			Else If (index = 2)
				style := "xp-" settings.lootfilter.hLabel/5 " yp-" settings.lootfilter.hLabel/5 " wp+" settings.lootfilter.hLabel*0.4 " hp+" settings.lootfilter.hLabel*0.4
			Else style := "xp-" settings.lootfilter.hLabel/5 " y" yText - 1 " wp+" settings.lootfilter.hLabel*0.4 " h" settings.lootfilter.hLabel

			Gui, %GUI_name%: Add, Text, % style " Border BackgroundTrans gLootfilter_GUI HWNDhwnd"
			Gui, %GUI_name%: Add, Progress, % "Disabled HWNDhwnd2 xp yp wp hp Background" (RGB_Convert(Blank(vars.lootfilter.selection.modifications[val]) ? colors[val] : vars.lootfilter.selection.modifications[val])), 0
			vars.hwnd.lootfilter["selection_" val] := hwnd, vars.hwnd.lootfilter["selection_" val "_back"] := vars.hwnd.help_tooltips["lootfilter_" val] := hwnd2
			ControlGetPos, xSelection, ySelection, wSelection, hSelection,, ahk_id %hwnd%
			xSelection += wSelection, ySelection += hSelection
		}
		If (vars.lootfilter.selection_backup.modifications.Count() != vars.lootfilter.selection.modifications.Count())
			vars.lootfilter.selection.pending := 1
		Else 
			For key, val in vars.lootfilter.selection_backup.modifications
				If (val != vars.lootfilter.selection.modifications[key])
					vars.lootfilter.selection.pending := 1

		wSelectionHeader := Max(wSelectionHeader, xSelection - xMods + margin)
		While Mod(wSelectionHeader, 2)
			wSelectionHeader += 1
		ControlMove,, xMods,, wSelectionHeader,, ahk_id %hwnd_header%

		Gui, %GUI_name%: Add, Text, % "Border BackgroundTrans x" xMods - 1 " y" yMods + hMods - 2 " w" wSelectionHeader " h" ySelection - hMods + margin + 2
		Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack c" settings.lootfilter.gui_color, 100

		If vars.lootfilter.selection.pending
		{
			Gui, %Gui_name%: Add, Text, % "xs Section xp Border Center HWNDhwnd gLootfilter_GUI w" wSelectionHeader/2, % Lang_Trans("global_apply")
			Gui, %Gui_name%: Add, Text, % "ys x+0 Border BackgroundTrans Center HWNDhwnd2 gLootfilter_GUI w" wSelectionHeader/2, % Lang_Trans("global_discard")
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border HWNDhwnd_header_bar Vertical BackgroundBlack cRed Range0-500", 0
			ControlGetPos, xModification_last, yModification_last, wModification_last, hModification_last,, ahk_id %hwnd2%
			vars.lootfilter.mod_header := [xMods, yModification_last + hModification_last]
			vars.hwnd.lootfilter.selection_apply := hwnd, vars.hwnd.lootfilter.selection_discard := hwnd2, vars.hwnd.lootfilter.x_bar := hwnd_header_bar
		}
	}
	Else If modifications.Count() || vars.lootfilter.pending || vars.lootfilter.class_pending || vars.lootfilter.gem_pending
	{
		dimensions := [vars.lootfilter.pending ? Lang_Trans("global_apply", 2) : "."]
		LLK_PanelDimensions([Lang_Trans("lootfilter_modifications")], settings.lootfilter.fSize, wHeader, hHeader)
		For key, object in modifications
			dimensions.Push(LLK_StringCase(key) ": " object.Count())
		LLK_PanelDimensions(dimensions, settings.lootfilter.fSize - 2, wModifications, hModifications)
		wModifications := Max(wHeader, wModifications)

		Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans Center HWNDhwnd gLootfilter_GUI x" xMax + 2 " y" yMax - 1 " w" wModifications " h" hDDL, % Lang_Trans("lootfilter_modifications")
		Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border HWNDhwnd2 Vertical BackgroundBlack cRed Range0-500", 0
		ControlGetPos, xMods, yMods, wMods, hMods,, ahk_id %hwnd%
		vars.hwnd.lootfilter.allmodifications := hwnd, vars.hwnd.lootfilter.x_bar := vars.hwnd.help_tooltips["lootfilter_modifications"] := hwnd2, vars.lootfilter.mod_header := [xMods, yMods + hMods]
		Gui, %GUI_name%: Font, % "s" settings.lootfilter.fSize - 2
		For key, array in modifications
		{
			color := LLK_HasVal(array, "(incompatible)", 1) ? settings.lootfilter.style_color : ""
			Gui, %GUI_name%: Add, Text, % "xs Section Border BackgroundTrans HWNDhwnd gLootfilter_GUI w" wModifications . (color ? " c" color : ""), % " " LLK_StringCase(key) ": " array.Count()
			ControlGetPos, xModification_last, yModification_last, wModification_last, hModification_last,, ahk_id %hwnd%
			vars.hwnd.lootfilter["modificationtext_" key] := hwnd
			If color
				vars.hwnd.help_tooltips["lootfilter_incompatible"] := hwnd, handle2 .= "|"
		}

		If (pending := vars.lootfilter.pending) || (vars.lootfilter.maps_hide != vars.lootfilter.maps_hide_previous) || vars.lootfilter.class_pending || vars.lootfilter.gem_pending
		{
			Gui, %GUI_name%: Add, Text, % "xs Section Border BackgroundTrans Center gLootfilter_GUI HWNDhwnd cRed w" wModifications, % (pending = 2) ? Lang_Trans("lootfilter_update") : Lang_Trans("global_apply", 2)
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border Vertical HWNDhwnd2 BackgroundBlack cGreen Range0-500", 0
			ControlGetPos, xModification_last, yModification_last, wModification_last, hModification_last,, ahk_id %hwnd%
			vars.hwnd.lootfilter.apply_mods := hwnd, vars.hwnd.lootfilter.apply_bar := vars.hwnd.help_tooltips["lootfilter_apply mods"] := hwnd2
		}
	}

	If vars.lootfilter.selection || modifications.Count() || vars.lootfilter.pending || vars.lootfilter.class_pending || vars.lootfilter.gem_pending
	{
		ControlGetPos,, yHide_last,, hHide_last,, % "ahk_id " hide_last
		yHide_last := yHide_last + hHide_last, yModification_last := yModification_last + hModification_last

		If yHide_last || yModification_last
			Gui, %GUI_name%: Add, Progress, % "Disabled Background646464 w5 x" xMax - 2 " y-1 h" Max(!yHide_last ? 0 : yHide_last, !yModification_last ? 0 : yModification_last), 0
		If yHide_last && yLast && (yHide_last < yModification_last)
			Gui, %GUI_name%: Add, Progress, % "Disabled Background646464 HWNDhwnd x-1 y" yFirst + yLast + margin - yFirst - 1 " h2 w" xMax, % 0
	}

	If vars.hwnd.lootfilter.search && InStr(check, "search")
		ControlFocus,, % "ahk_id " vars.hwnd.lootfilter.search
	Else ControlFocus,, % "ahk_id " vars.hwnd.lootfilter.font_reset

	Gui, %GUI_name%: Show, % "NA AutoSize x10000 y10000"
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

Lootfilter_ItemLabel(text, filter_index, style, xMax := 10000, iGroup := 0)
{
	local
	global vars, settings
	static xControl, wControl, dimensions := {}

	selection := IsObject(style), style := IsObject(style) ? style.1 : style ;style being an object is used as a pseudo parameter for drawing a style-customization preview rather than a label in the search results
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
		textcolor := [255, 255, 255, 255], backgroundcolor := [0, 0, 0, 240], bordercolor := [0, 0, 0, 255]
		rgb := ""
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

			style0 := "BackgroundTrans 0x200" ((!stacked_group || stacked_group && mod_index < 2) && !selection ? " gLootfilter_GUI" : "")
				. " h" settings.lootfilter.hLabel " " (xControl + wControl + margin + dimensions[text] >= xMax ? "xs Section y+" margin + 1 : style)
		}
		Else style0 := "Disabled Range0-500 Vertical c" (SubStr(rgb, 3) = "FF0000" ? "000000" : "Red") " " (index = 2 ? "xp+2 yp+2 wp-4 hp-4" : "xp-2 yp-2 wp+4 hp+4")

		Gui, %GUI_name%: Add, % (index = 1) ? "Text" : "Progress", % style0 " " (index = 1 ? "c" : "Background") . (selection ? RGB_Convert(vars.lootfilter.selection.modifications[type]) : rgb) " HWNDhwnd", % (index = 1) ? " " text " " : 0

		If selection
			vars.hwnd.lootfilter["selection_" type "_preview"] := hwnd
		Else
		{
			If (index = 1)
				vars.lootfilter.labels[hwnd] := (iGroup = 1 && stack) ? [filter_index, "all"] : [filter_index]
			Else If (index = 2)
				vars.hwnd.help_tooltips["lootfilter_tooltip " filter_index . vars.lootfilter.handles[filter_index]] := hwnd, vars.lootfilter.handles[filter_index] .= "|", vars.hwnd.lootfilter["labelbar_" filter_index] := hwnd
			Else If (index = 3)
			{
				thickness := Max(2, settings.lootfilter.fWidth//8)
				Gui, %GUI_name%: Add, Progress, % "Disabled Background" (highlight ? settings.lootfilter[(InStr(chunk, "(style)") ? "style" : "highlight") "_color"] : settings.lootfilter.gui_color) " xp-" thickness " yp-" thickness " wp+" thickness*2 " hp+" thickness*2, 0
			}

			If (index != 3)
			{
				ControlGetPos, xControl,, wControl,,, ahk_id %hwnd%
				vars.hwnd.lootfilter.last_control := hwnd
			}
		}
	}
	Gui, %GUI_name%: Font, norm
}
