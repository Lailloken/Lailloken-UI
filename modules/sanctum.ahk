Init_sanctum()
{
	local
	global vars, settings, JSON

	If !FileExist("ini\sanctum.ini")
		IniWrite, % "", ini\sanctum.ini, settings

	If !IsObject(vars.sanctum)
	{
		vars.sanctum := {"pixels": {}, "targets": {}, "avoid": {}, "avoids": {}, "blocks": {}, "info": {}, "rooms": [{}, {}, {}, {}]}
		For outer in [1, 2, 3, 4]
			For inner in [1, 2, 3, 4, 5]
				vars.sanctum.rooms[outer][LangTrans("sanctum_rooms_" inner "_" outer) ":`n" LangTrans("sanctum_rooms_" inner)] := 1
		For key, array in vars.lang
			If (key = "sanctum_info")
				For index, val in array
					vars.sanctum.info[val] := 1
	}

	If !IsObject(settings.sanctum)
		settings.sanctum := {}

	ini := IniBatchRead("ini\sanctum.ini")
	settings.sanctum.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	settings.sanctum.cheatsheet := !Blank(check := ini.settings["enable cheat-sheet"]) ? check : 0
	vars.sanctum.pixels.path := !Blank(check := ini.data["pixels path"]) ? json.load(check) : {}
	vars.sanctum.pixels.room := !Blank(check := ini.data["pixels room"]) ? json.load(check) : {}
	vars.sanctum.floor := !Blank(check := ini.data.floor) ? check : 0
	If InStr(ini.data["grid snapshot"], "exit") && (SubStr(ini.data["grid snapshot"], 1, 1) . SubStr(ini.data["grid snapshot"], 0) = "[]")
		vars.sanctum.grid := json.load(ini.data["grid snapshot"])

	wSnip := vars.sanctum.wSnip := Round(vars.client.h * 0.8), hSnip := vars.sanctum.hSnip := Round(vars.client.h * (5/9))
	vars.sanctum.wBox := Round(hSnip * 0.11), vars.sanctum.hBox := Round(hSnip * 0.14)
	vars.sanctum.radius := Round(hSnip/40), vars.sanctum.radius2 := Round(vars.sanctum.radius * 0.65), vars.sanctum.gap := Round(hSnip * 0.035)
	vars.sanctum.columns := [], vars.sanctum.rows := [], vars.sanctum.row1 := []
	vars.sanctum.xSnip := Round(vars.client.w//2 - wSnip/2), vars.sanctum.ySnip := Round(vars.client.h * (7/45))

	For index, val in [0, 0.188, 0.37875, 0.57125, 0.76125, 0.9525, 1.144]
		vars.sanctum.columns.Push(Floor(hSnip * val))
	For index, val in [0, 0.09, 0.175, 0.26, 0.345, 0.43, 0.517, 0.6, 0.687, 0.77, 0.86]
		vars.sanctum.rows.Push(Floor(hSnip * val))
	For index, val in [0.225, 0.43, 0.64]
		vars.sanctum.row1.Push(Floor(hSnip * val))
}

Sanctum_(cHWND := "", hotkey := 0)
{
	local
	global vars, settings
	static toggle := 0, dimensions := [], floors := ["cellar", "vaults", "nave", "crypt"]

	If vars.sanctum.scanning
		Return

	If (cHWND = "close")
	{
		GuiControl, +Hidden, % vars.hwnd.sanctum.scan
		GuiControl, +Hidden, % vars.hwnd.sanctum.scan2
		GuiControl, +Hidden, % vars.hwnd.sanctum.cal_room
		GuiControl, +Hidden, % vars.hwnd.sanctum.cal_room2
		GuiControl, +Hidden, % vars.hwnd.sanctum.cal_path
		GuiControl, +Hidden, % vars.hwnd.sanctum.cal_path2
		Sleep 50
		LLK_Overlay(vars.hwnd.sanctum.main, "hide"), LLK_Overlay(vars.hwnd.sanctum.second, "hide"), vars.sanctum.active := 0
		Return
	}
	Else If (cHWND = "lock")
	{
		vars.sanctum.lock := 1
		GuiControl, -Hidden, % vars.hwnd.sanctum.cal_room
		GuiControl, -Hidden, % vars.hwnd.sanctum.cal_room2
		GuiControl, -Hidden, % vars.hwnd.sanctum.cal_path
		GuiControl, -Hidden, % vars.hwnd.sanctum.cal_path2

		If (vars.sanctum.pixels.path.Count() * vars.sanctum.pixels.room.Count())
		{
			GuiControl, -Hidden, % vars.hwnd.sanctum.scan
			GuiControl, -Hidden, % vars.hwnd.sanctum.scan2
		}
		Else
		{
			GuiControl, +Hidden, % vars.hwnd.sanctum.scan
			GuiControl, +Hidden, % vars.hwnd.sanctum.scan2
		}
		KeyWait, Space
		Return
	}
	Else If (cHWND = "trans")
	{
		WinSet, TransColor, Purple 20, % "ahk_id " vars.hwnd.sanctum.main
		KeyWait, LALT
		WinSet, TransColor, Purple 125, % "ahk_id " vars.hwnd.sanctum.main
		Return
	}

	If !Blank(cHWND)
	{
		check := LLK_HasVal(vars.hwnd.sanctum, cHWND), control := SubStr(check, InStr(check, "_") + 1)

		If (check = "scan")
		{
			If (vars.system.click = 1)
				error := !Sanctum_Scan()
			Else
			{
				If FileExist("img\sanctum scan.jpg")
				{
					GuiControl, -Hidden, % vars.hwnd.sanctum.scanned_img
					KeyWait, RButton
					GuiControl, +Hidden, % vars.hwnd.sanctum.scanned_img
				}
				Else KeyWait, RButton
				Return
			}
		}
		Else If InStr(check, "cal_")
		{
			If (vars.system.click = 1)
				Sanctum_Calibrate(control)
			Else If LLK_Progress(vars.hwnd.sanctum["cal_" control "2"], "RButton")
			{
				vars.sanctum.pixels[control] := {}
				IniDelete, ini\sanctum.ini, data, % "pixels " control
				GuiControl, +BackgroundMaroon, % vars.hwnd.sanctum["cal_" control "2"]
			}
			Sanctum_("lock")
			Return
		}
		Else
		{
			LLK_ToolTip("no action")
			Return
		}
	}
	floor := vars.sanctum.floor, correct_floor := (InStr(vars.log.areaID, floors[floor]) || InStr(vars.log.areaID, "foyer_" floor))

	If Blank(cHWND) && vars.hwnd.sanctum.uptodate
	{
		If floor && correct_floor
			LLK_Overlay(vars.hwnd.sanctum.main, "show")
		Else GuiControl, +BackgroundMaroon, % vars.hwnd.sanctum.scan2
		LLK_Overlay(vars.hwnd.sanctum.second, "show"), vars.sanctum.active := 1
		Return
	}
	;If error
	;	Return

	toggle := !toggle, GUI_name := "sanctum" toggle, GUI_name2 := "sanctum2" toggle
	wSnip := vars.sanctum.wSnip, hSnip := vars.sanctum.hSnip
	wBox := vars.sanctum.wBox, hBox := vars.sanctum.hBox
	xSnip := vars.sanctum.xSnip, ySnip := vars.sanctum.ySnip
	grid := vars.sanctum.grid

	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_sanctum"
	Gui, %GUI_name%: Font, % "s" settings.sanctum.fSize + 4 " cBlack w1000", % vars.system.font
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple 125
	Gui, %GUI_name%: Margin, 0, 0
	hwnd_old := vars.hwnd.sanctum.main, hwnd_old2 := vars.hwnd.sanctum.second, vars.hwnd.sanctum := {"main": hwnd_sanctum, "GUI_name": GUI_name}, vars.sanctum.lock := 0

	;Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans w" wSnip " h" hSnip

	If correct_floor
		For iColumn, vColumn in grid
		{
			For iRoom, vRoom in vColumn
			{
				color := vars.sanctum.avoids[iColumn . iRoom] ? "Fuchsia" : vars.sanctum.targets[iColumn . iRoom] ? "Lime" : "White"
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans HWNDhwnd Center x" vRoom.x " y" vRoom.y " w" wBox " h" hBox, % Sanctum_Connections(iColumn, iRoom, 1)
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd2 BackgroundBlack c" color, 100
				vars.hwnd.sanctum["room_" iColumn . iRoom] := hwnd, vars.hwnd.sanctum["room_" iColumn . iRoom "|"] := hwnd2
			}
		}

	Gui, %GUI_name%: Show, % "NA x" vars.client.x + xSnip " y" vars.client.y + ySnip
	LLK_Overlay(hwnd_sanctum, "show", 1, GUI_name), LLK_Overlay(hwnd_old, "destroy")

	Gui, %GUI_name2%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_sanctum2"
	Gui, %GUI_name2%: Font, % "s" settings.sanctum.fSize " cWhite", % vars.system.font
	Gui, %GUI_name2%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name2%: Margin, 0, 0
	vars.hwnd.sanctum.second := hwnd_sanctum2, vars.hwnd.sanctum.GUI_name2 := GUI_name2

	Gui, %GUI_name2%: Add, Text, % "Section x" xSnip " y" ySnip " Border BackgroundTrans w" wSnip " h" hSnip
	If FileExist("img\sanctum scan.jpg")
	{
		Gui, %GUI_name2%: Add, Pic, % "xp yp wp hp Hidden HWNDhwnd", % "img\sanctum scan.jpg"
		vars.hwnd.sanctum.scanned_img := hwnd
	}

	LLK_PanelDimensions([LangTrans("global_scan", 2), LangTrans("sanctum_calibrate"), LangTrans("sanctum_calibrate", 2)], settings.sanctum.fSize, wButtons, hButtons)
	For index, val in [LangTrans("global_scan", 2), LangTrans("sanctum_calibrate"), LangTrans("sanctum_calibrate", 2)]
	{
		style := (index = 1) ? "Section x" xSnip + wSnip - 1 " y" ySnip + hSnip - (hButtons * 3 - 2) : "xs y+-1", style .= !InStr(val, "`n") ? " 0x200" : ""
		Gui, %GUI_name2%: Add, Text, % style " Border BackgroundTrans Center gSanctum_ w" wButtons " h" hButtons " HWNDhwnd" index . (check != "scan" ? " Hidden" : ""), % " " StrReplace(val, "`n", " `n ") " "
		color := (index = 1 && (!grid.Count() || !correct_floor)) || (index = 2 && !vars.sanctum.pixels.path.Count()) || (index = 3 && !vars.sanctum.pixels.room.Count()) ? "Maroon" : "Black"
		style := (index = 1) ? " Range0-7" : " Range0-500"
		Gui, %GUI_name2%: Add, Progress, % "xp yp wp hp Disabled Background" color " cGreen HWNDhwnd" index "2" style . (check != "scan" ? " Hidden" : ""), 0
	}
	vars.hwnd.sanctum.scan := hwnd1, vars.hwnd.sanctum.scan2 := hwnd12
	vars.hwnd.sanctum.cal_path := hwnd2, vars.hwnd.sanctum.cal_path2 := hwnd22
	vars.hwnd.sanctum.cal_room := hwnd3, vars.hwnd.sanctum.cal_room2 := hwnd32

	If settings.sanctum.cheatsheet && floor && correct_floor
	{
		For key in vars.sanctum.rooms[floor]
			Gui, %GUI_name2%: Add, Text, % (A_Index = 1 ? "Section x0 y0" : "ys x+-1") " Border Hidden HWNDhwnd Center BackgroundTrans", % " " StrReplace(key, "`n", " `n ") " "
		ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
		wCheatsheet := xControl + wControl

		For key in vars.sanctum.rooms[floor]
		{
			style := (A_Index = 1) ? "Section x" xSnip + (wSnip - wCheatsheet)//2 " y" ySnip + hSnip - 1 : "ys x+-1"
			Gui, %GUI_name2%: Add, Text, % style " Border HWNDhnwd Center BackgroundTrans", % " " StrReplace(key, "`n", " `n ") " "
			Gui, %GUI_name2%: Add, Progress, % "xp yp wp hp Disabled Background202040", 0
		}
		ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%

		For key in vars.sanctum.info
			Gui, %GUI_name2%: Add, Text, % (A_Index = 1 ? "Section x0 y0" : "ys x+-1") " Border Hidden HWNDhwnd Center BackgroundTrans", % " " StrReplace(key, "`n", " `n ") " "
		ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
		wCheatsheet := xControl + wControl

		For key in vars.sanctum.info
		{
			style := (A_Index = 1) ? "Section x" xSnip + (wSnip - wCheatsheet)//2 " y" ySnip + hSnip + hLast - 2 : "ys x+-1"
			Gui, %GUI_name2%: Add, Text, % style " Border Center BackgroundTrans", % " " StrReplace(key, "`n", " `n ") " "
			Gui, %GUI_name2%: Add, Progress, % "xp yp wp hp Disabled Background202040", 0
		}
	}

	Gui, %GUI_name2%: Show, % "NA x" vars.client.x " y" vars.client.y
	LLK_Overlay(vars.hwnd.sanctum.second, "show", 1, GUI_name2), LLK_Overlay(hwnd_old2, "destroy")
	If error
		LLK_ToolTip(LangTrans("global_fail"), 1,,,, "Red")
	vars.sanctum.active := 1, vars.hwnd.sanctum.uptodate := 1
}

Sanctum_Calibrate(mode)
{
	local
	global vars, settings, JSON

	pSnip := SnippingTool(), pixels := {}
	If (pSnip <= 0)
		Return
	Gdip_GetImageDimensions(pSnip, wSnip, hSnip)
	
	Loop, % wSnip
	{
		x_coord := A_Index - 1
		Loop, % hSnip
		{
			y_coord := A_Index - 1
			pixel := Gdip_GetPixelColor(pSnip, x_coord, y_coord, 4)
			If !pixels[pixel]
				pixels[pixel] := 1
			Else pixels[pixel] += 1
		}
	}
	Gdip_DisposeImage(pSnip)
	For color, count in pixels
		pixel_count .= (!pixel_count ? "" : "`n") count " x " color
	Sort, pixel_count, D`n N R
	Loop, Parse, pixel_count, `n, % " `r"
		If (mode = "path") || (mode = "room" && A_Index < 11)
			vars.sanctum.pixels[mode][SubStr(A_LoopField, InStr(A_LoopField, " x ") + 3)] := 1
	
	If vars.sanctum.pixels[mode].Count()
	{
		IniWrite, % """" json.dump(vars.sanctum.pixels[mode]) """", ini\sanctum.ini, data, % "pixels " mode
		GuiControl, +BackgroundBlack, % vars.hwnd.sanctum["cal_" mode "2"]
	}
}

Sanctum_Connections(column, row, main := 0)
{
	local
	global vars, settings

	For exit in vars.sanctum.grid[column][row].exits
		If !vars.sanctum.avoids[exit]
			connections .= " " Sanctum_Connections(SubStr(exit, 1, 1), SubStr(exit, 2)), connections1 .= " " exit

	If main
	{
		connections .= " " connections1, connections1 := {}
		Loop, Parse, connections, %A_Space%, %A_Space%
			If A_LoopField
				connections1[A_LoopField] := 1
		Return connections1.Count()
	}
	Return connections . connections1
}

Sanctum_Mark(room, mode, hold := 0)
{
	local
	global vars, settings

	room := StrReplace(room, "|"), column := SubStr(room, 1, 1), row := SubStr(room, 2)
	grid := vars.sanctum.grid

	If (mode = 1) && (vars.sanctum.avoids[room] || vars.sanctum.blocks[room] || room = vars.sanctum.current)
	|| (mode = 2) && !vars.sanctum.avoid[room] && (InStr(vars.sanctum.target "," vars.sanctum.current, room) || vars.sanctum.blocks[room])
	|| (mode = 3) && (vars.sanctum.avoids[room])
	; block clicks on purple/black rooms, block right-clicks on primary green room
		Return

	If (mode = 1)
		vars.sanctum.target := (vars.sanctum.target = room) ? "" : room, vars.sanctum.targets := {}
	Else If (mode = 2)
		vars.sanctum.avoid[room] := !vars.sanctum.avoid[room], vars.sanctum.avoids := {}, vars.sanctum.targets := {}, vars.sanctum.blocks := {}
	Else vars.sanctum.current := (vars.sanctum.current = room) ? "" : room, vars.sanctum.blocks := {}

	Loop 7 ; banned rooms based on primary purple room(s)
	{
		column := 8 - A_Index
		For iRoom, vRoom in grid[column]
		{
			check := vRoom.exits.Count()
			For exit in vRoom.exits
				check -= vars.sanctum.avoids[exit] ? 1 : 0
			If !check || vars.sanctum.avoid[column . iRoom]
				vars.sanctum.avoids[column . iRoom] := 1
		}
	}

	Loop 7 ; inaccessible rooms behind (already passed) and ahead (resulting from bans)
	{
		column := A_Index
		;If (A_Index = 1)
		;	Continue
		For iRoom, vRoom in grid[column]
		{
			check := Max(1, vRoom.entries.Count())
			If grid[column - 1].Count()
				For entrance in vRoom.entries
					check -= vars.sanctum.avoids[entrance] || vars.sanctum.blocks[entrance] ? 1 : 0
			If (vars.sanctum.current != column . iRoom) && (!check || vars.sanctum.current && (column <= SubStr(vars.sanctum.current, 1, 1)))
				vars.sanctum.blocks[column . iRoom] := 1
		}
	}

	Loop 7 ; green path from primary green room
	{
		column := 8 - A_Index
		For iRoom, vRoom in grid[column]
		{
			If vars.sanctum.current && (column = SubStr(vars.sanctum.current, 1, 1))
				Break
			check := 0, check1 := Max(1, vRoom.entries.Count())
			For entrance in vRoom.entries
				check1 -= vars.sanctum.avoids[entrance] || vars.sanctum.blocks[entrance] ? 1 : 0
			For exit in vRoom.exits
				If !vars.sanctum.avoids[exit]
					check += vars.sanctum.targets[exit] ? 1 : 0
			If check1 && check || (vars.sanctum.target = column . iRoom)
				vars.sanctum.targets[column . iRoom] := 1
		}
	}

	For iColumn, vColumn in grid ; apply new colors to rooms
		For iRoom, vRoom in vColumn
		{
			If vars.sanctum.blocks[iColumn . iRoom]
				GuiControl, % "+cBlack +Background" (vars.sanctum.avoid[iColumn . iRoom] ? "White" : "Black"), % vars.hwnd.sanctum["room_" iColumn . iRoom "|"]
			Else If vars.sanctum.avoids[iColumn . iRoom]
				GuiControl, % "+cFuchsia +Background" (vars.sanctum.avoid[iColumn . iRoom] ? "White" : "Black"), % vars.hwnd.sanctum["room_" iColumn . iRoom "|"]
			Else If (vars.sanctum.current = iColumn . iRoom)
				GuiControl, % "+cYellow +BackgroundBlack", % vars.hwnd.sanctum["room_" iColumn . iRoom "|"]
			Else If vars.sanctum.targets[iColumn . iRoom]
				GuiControl, % "+cLime +Background" (vars.sanctum.target = iColumn . iRoom ? "White" : "Black"), % vars.hwnd.sanctum["room_" iColumn . iRoom "|"]
			Else GuiControl, +cWhite +BackgroundBlack, % vars.hwnd.sanctum["room_" iColumn . iRoom "|"]

			If (mode != 1) ; recalculate number of connections
				GuiControl, Text, % vars.hwnd.sanctum["room_" iColumn . iRoom], % vars.sanctum.avoids[iColumn . iRoom] || vars.sanctum.blocks[iColumn . iRoom] ? "" : Sanctum_Connections(iColumn, iRoom, 1)
		}
	Sleep, 250
	While (mode = 3) && hold && GetKeyState("MButton", "P")
	{
		If (vars.general.wMouse = vars.hwnd.sanctum.main) && vars.general.cMouse && (check := LLK_HasVal(vars.hwnd.sanctum, vars.general.cMouse))
		&& ((check := StrReplace(SubStr(check, InStr(check, "_") + 1), "|")) != vars.sanctum.current)
			Sanctum_Mark(check, 3)
		Sleep 100
	}
}

Sanctum_Scan(mode := "")
{
	local
	global vars, settings, JSON
	static floors := {"cellar": 1, "vaults": 2, "nave": 3, "crypt": 4}
	, colors := ["4294967295", "4294967040", "4278255615", "4294902015", "4286611584", "4278222976", "4294937600", "4287299723", "4286578644", "4294951115", "4280193279"]
	;			white,		yellow,		cyan,		magenta,		gray,	teal,		orange,	dark magenta,	aqua marine,		pink,	dodger blue

	wSnip := vars.sanctum.wSnip, hSnip := vars.sanctum.hSnip
	wBox := vars.sanctum.wBox, hBox := vars.sanctum.hBox
	radius := vars.sanctum.radius, radius2 := vars.sanctum.radius2, gap := vars.sanctum.gap
	columns := vars.sanctum.columns, rows := vars.sanctum.rows, row1 := vars.sanctum.row1
	xSnip := vars.sanctum.xSnip, ySnip := vars.sanctum.ySnip
	vars.sanctum.scanning := 1

	If !InStr(vars.log.areaID, "sanctum") || InStr(vars.log.areaID, "fellshrine")
		Return
	grid := []
	pBitmap := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
	pCrop := Gdip_CloneBitmapArea(pBitmap, settings.general.oGamescreen + xSnip, ySnip, wSnip, hSnip,, 1)
	Gdip_DisposeImage(pBitmap)

	For iColumn, vColumn in columns
	{
		If (iColumn = 1)
		{
			grid.1 := []
			For iRow, vRow in row1
			{
				If (InStr(vars.log.areaID, "sanctumfoyer_1") || InStr(vars.log.areaID, "sanctumcellar")) && InStr("13", iRow)
					Continue

				grid.1.Push({"x": vColumn, "y": vRow, "entries": {}, "exits": {}})
				Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2, "4294901760")
				Loop, % wBox//4
					Gdip_SetPixel(pCrop, vColumn + wBox/2 - A_Index, vRow + hBox/2, "4294901760"), Gdip_SetPixel(pCrop, vColumn + wBox/2 + A_Index, vRow + hBox/2, "4294901760")
					, Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2 - A_Index, "4294901760"), Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2 + A_Index, "4294901760")
			}
			Continue
		}
		
		x_coord := vColumn + wBox * 0.4 - 1, yMin := 100000
		Loop, % wBox/5
		{
			x_coord += 1
			Loop, % hSnip
			{
				y_coord := A_Index - 1
				pixel := Gdip_GetPixelColor(pCrop, x_coord, y_coord, 4)
				If vars.sanctum.pixels.room[pixel]
				{
					yMin := (y_coord < yMin) ? y_coord : yMin
					Gdip_SetPixel(pCrop, x_coord, y_coord, "4294901760")
					Continue 2
				}
			}
		}
		first_row := 0
		For iRow, vRow in rows
		{
			If LLK_IsBetween(yMin, vRow, vRow + hBox/2) || first_row && (!Mod(first_row, 2) && !Mod(iRow, 2) || Mod(first_row, 2) && Mod(iRow, 2)) && (iRow <= (11 - (first_row - 1)))
			{
				If !IsObject(grid[iColumn])
					grid[iColumn] := []
				first_row := !first_row ? iRow : first_row, grid[iColumn].Push({"x": vColumn, "y": vRow, "entries": {}, "exits": {}})
				
				Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2, "4294901760")
				Loop, % wBox//4
					Gdip_SetPixel(pCrop, vColumn + wBox/2 - A_Index, vRow + hBox/2, "4294901760"), Gdip_SetPixel(pCrop, vColumn + wBox/2 + A_Index, vRow + hBox/2, "4294901760")
					, Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2 - A_Index, "4294901760"), Gdip_SetPixel(pCrop, vColumn + wBox/2, vRow + hBox/2 + A_Index, "4294901760")
			}
		}
		If !grid[iColumn].Count()
		{
			error := 1, grid := []
			Break
		}
	}
	
	If !error
		For iColumn, vColumn in columns
		{
			GuiControl,, % vars.hwnd.sanctum.scan2, % iColumn
			If (iColumn = 7)
			{
				;grid.8 := [{"x": Round(wSnip - wBox), "y": rows.6, "connections": {"entries": {}}}]
				For iRoom in grid.7
					grid.7[iRoom].exits.81 := 1 ;, grid.8.1.connections.entries["7" iRoom] := 1
				Break
			}
			x_coord := Round(vColumn + wBox/2 - 1), paths := []
			Loop
			{
				x_coord += 1
				If (x_coord >= columns[iColumn + 1] + wBox/2)
					Break
				If (vars.client.h > 1200) && Mod(x_coord, (vars.client.h >= 1800) ? 3 : 2)
					Continue
				Loop, % hSnip
				{
					y_coord := A_Index - 1
					If (y_coord >= rows.11 + hBox * 0.6)
						Break
					pixel := Gdip_GetPixelColor(pCrop, x_coord, y_coord, 4)
					If vars.sanctum.pixels.path[pixel]
					{
						For iPath, vPath in paths
						{
							If LLK_IsBetween(x_coord, vPath.2.x, vPath.2.x + radius2) && LLK_IsBetween(y_coord, vPath.2.y - radius, vPath.2.y + radius)
							{
								paths[iPath].2.x := x_coord, paths[iPath].2.y := y_coord
								Gdip_SetPixel(pCrop, x_coord, y_coord, colors[iPath])
								Continue 2
							}
						}
						paths.Push([{"x": x_coord, "y": y_coord}, {"x": x_coord, "y": y_coord}])
						Gdip_SetPixel(pCrop, x_coord, y_coord, colors[paths.MaxIndex()])
					}
				}
			}

			For iPath, vPath in paths
			{
				start := end := ""
				For iRoom, vRoom in grid[iColumn]
				{
					If LLK_IsBetween(vPath.1.x, vRoom.x - gap/2, vRoom.x + wBox + gap/2) && LLK_IsBetween(vPath.1.y, vRoom.y - gap/2, vRoom.y + hBox + gap/2)
					{
						start := [iColumn, iRoom]
						Break
					}
				}

				For iRoom, vRoom in grid[iColumn + 1]
				{
					If LLK_IsBetween(vPath.2.x, vRoom.x - gap/2, vRoom.x + wBox + gap/2) && LLK_IsBetween(vPath.2.y, vRoom.y - gap/2, vRoom.y + hBox + gap/2)
					{
						end := [iColumn + 1, iRoom]
						Break
					}
				}

				If (IsObject(start) * IsObject(end))
					grid[start.1][start.2].exits[end.1 . end.2] := 1
				Else
				{
					error := 1, grid := []
					Gdip_SetPixel(pCrop, vPath.1.x, vPath.1.y, "4278255615")
					Loop, % wBox//4
						Gdip_SetPixel(pCrop, vPath.1.x - A_Index, vPath.1.y, "4278255615"), Gdip_SetPixel(pCrop, vPath.1.x + A_Index, vPath.1.y, "4278255615")
						, Gdip_SetPixel(pCrop, vPath.1.x, vPath.1.y - A_Index, "4278255615"), Gdip_SetPixel(pCrop, vPath.1.x, vPath.1.y + A_Index, "4278255615")
					Break
				}
			}
			If error
				Break

			For iRoom, vRoom in grid[iColumn]
				For exit in vRoom.exits
					grid[iColumn + 1][SubStr(exit, 2)].entries[iColumn . iRoom] := 1
		}

	If !error
		For iColumn, vColumn in grid
			Loop, % vColumn.Length()
				If !(vColumn[A_Index].entries.Count() + vColumn[A_Index].exits.Count())
					grid[iColumn].Delete(A_Index)

	Gdip_SaveBitmapToFile(pCrop, "img\sanctum scan.jpg", 100)
	Gdip_DisposeImage(pCrop)
	vars.sanctum.grid := grid.Clone()

	If !error
	{
		vars.sanctum.target := vars.sanctum.current := "", vars.sanctum.targets := {}
		vars.sanctum.avoid := {}, vars.sanctum.avoids := {}, vars.sanctum.blocks := {}
		vars.sanctum.floor := InStr(vars.log.areaID, "sanctumfoyer") ? SubStr(vars.log.areaID, InStr(vars.log.areaID, "_") + 1, 1) : floors[StrReplace(vars.log.areaID, "sanctum")]
		IniWrite, % vars.sanctum.floor, ini\sanctum.ini, data, floor
		IniWrite, % """" json.dump(grid) """", ini\sanctum.ini, data, grid snapshot
	}
	Else
	{
		vars.sanctum.floor := ""
		IniDelete, ini\sanctum.ini, data, floor
		IniDelete, ini\sanctum.ini, data, grid snapshot
	}

	GuiControl, % "+Background" (error ? "Maroon" : "Black"), % vars.hwnd.sanctum.scan2
	GuiControl,, % vars.hwnd.sanctum.scan2, 0
	vars.sanctum.scanning := 0
	Return !error
}
