Delve:
If InStr(A_GuiControl, "button_delve_")
{
	If (A_GuiControl = "button_delve_minus")
		delve_panel_offset -= (delve_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_delve_reset")
		delve_panel_offset := 1
	If (A_GuiControl = "button_delve_plus")
		delve_panel_offset += (delve_panel_offset < 1) ? 0.1 : 0
	IniWrite, % delve_panel_offset, ini\delve.ini, Settings, button-offset
	delve_panel_dimensions := poe_width*0.03*delve_panel_offset
	GoSub, GUI
	Return
}
If (A_GuiControl = "delve_enable_recognition")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % delve_enable_recognition, ini\delve.ini, Settings, enable image-recognition
	Return
}
If (A_GuiControl = "enable_delve")
{
	Gui, settings_menu: Submit, NoHide
	If (enable_delve = 0)
	{
		LLK_Overlay("delve_panel", "hide")
		Gui, delve_grid2: Destroy
		hwnd_delve_grid2 := ""
		Gui, delve_grid: Destroy
		hwnd_delve_grid := ""
	}
	If (enable_delve = 1) && (poe_log_file != 0) && (enable_delvelog = 1)
		WinActivate, ahk_group poe_window
	If (enable_delve = 1) && (poe_log_file = 0)
		LLK_Overlay("delve_panel", "show")
	IniWrite, % enable_delve, ini\config.ini, Features, enable delve
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "enable_delvelog")
{
	Gui, settings_menu: Submit, NoHide
	If (enable_delvelog = 1) && (enable_delve = 1) && (poe_log_file != 0)
	{
		WinActivate, ahk_group poe_window
		GoSub, Log_loop
	}
	If (enable_delvelog = 0)
		LLK_Overlay("delve_panel", "show")
	IniWrite, % enable_delvelog, ini\delve.ini, Settings, enable log-scanning
	Return
}

If InStr(A_GuiControl, "delvegrid_")
{
	If (A_GuiControl = "delvegrid_minus")
		delve_gridwidth -= 1
	If (A_GuiControl = "delvegrid_reset")
		delve_gridwidth := Floor(poe_height*0.73/8)
	If (A_GuiControl = "delvegrid_plus")
		delve_gridwidth += 1
	IniWrite, % delve_gridwidth, ini\delve.ini, UI, grid dimensions
}
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "delve_panel") ;dragging the delve-button
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		delve_panel_xpos := panelXpos
		delve_panel_ypos := panelYpos
		IniWrite, % delve_panel_xpos, ini\delve.ini, UI, button xcoord
		IniWrite, % delve_panel_ypos, ini\delve.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}

If WinExist("ahk_id " hwnd_delve_grid) && (A_Gui != "settings_menu")
{
	LLK_Overlay("delve_grid", "hide")
	LLK_Overlay("delve_grid2", "hide")
}
Else If !WinExist("ahk_id " hwnd_delve_grid) && (hwnd_delve_grid != "") && (A_Gui != "settings_menu")
{
	LLK_Overlay("delve_grid", "show")
	LLK_Overlay("delve_grid2", "show")
}

If (hwnd_delve_grid = "") || (A_Gui = "settings_menu")
{
	Gui, delve_grid: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_delve_grid
	Gui, delve_grid: Margin, 0, 0
	Gui, delve_grid: Color, White
	WinSet, Transparent, 75
	Gui, delve_grid: Font, % "s"fSize1 " cRed", Fontin SmallCaps
	loop := 0
	delve_hidden_nodes := ""
	Loop 49
	{
		delve_node_%A_Index% := ""
		delve_node%A_Index%_toggle := ""
		delve_node_u%A_Index%_toggle := ""
		delve_node_d%A_Index%_toggle := ""
		delve_node_l%A_Index%_toggle := ""
		delve_node_r%A_Index%_toggle := ""
	}

	Loop, 7 ;% (Floor((poe_height*0.73)/(delve_gridwidth)) < 9) ? Floor((poe_height*0.73)/(delve_gridwidth)) : 8
	{
		Loop 7
		{
			loop += 1
			If (A_Index = 1)
				Gui, delve_grid: Add, Text, % "xs Section BackgroundTrans Center HWNDhwnd_delvenode" loop " Border w"delve_gridwidth " h"delve_gridwidth, % (A_Gui = "settings_menu") ? "sample" : ""
			Else Gui, delve_grid: Add, Text, % "ys BackgroundTrans Center HWNDhwnd_delvenode" loop " Border w"delve_gridwidth " h"delve_gridwidth, % (A_Gui = "settings_menu") ? "sample" : ""
			If (A_Gui != "settings_menu")
			{
				ControlGetPos, delve_nodeXpos, delve_nodeYpos,,,, % "ahk_id " hwnd_delvenode%loop%
				wDpad := delve_gridwidth//3
				xDpad := delve_nodeXpos + delve_gridwidth//3 - 1
				yDpad := delve_nodeYpos + delve_gridwidth//3 - 1
				Gui, delve_grid: Add, Picture, % "x"xDpad " y"yDpad " BackgroundTrans Border vdelve_node" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth/3 " y" delve_nodeYpos " BackgroundTrans vdelve_node_u" loop " gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos " y"delve_nodeYpos + delve_gridwidth/3 " BackgroundTrans vdelve_node_l" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth*2/3 - 1 " y" delve_nodeYpos + delve_gridwidth/3 " BackgroundTrans vdelve_node_r" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth/3 " y" delve_nodeYpos + delve_gridwidth*2/3 - 1 " BackgroundTrans vdelve_node_d" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
			}
		}
	}
	Gui, delve_grid: Show, % "NA"
	WinGetPos,,, width, height, ahk_id %hwnd_delve_grid%
	Gui, delve_grid: Show, % "NA y"yScreenOffSet + poe_height*0.09 " x"xScreenOffSet + poe_width/2 - width/2
	LLK_Overlay("delve_grid", "show")
	
	Gui, delve_grid2: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_delve_grid2
	Gui, delve_grid2: Margin, 0, 4
	Gui, delve_grid2: Color, Black
	WinSet, Transparent, %trans%
	Gui, delve_grid2: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
	Gui, delve_grid2: Font, % "underline s"fSize_config0 + 2
	If (delve_enable_recognition = 0)
		Gui, delve_grid2: Add, Text, % "Section BackgroundTrans cRed Center w"7 * delve_gridwidth, hidden passage can only lead through empty squares
	Else Gui, delve_grid2: Add, Text, % "Section BackgroundTrans cRed Center w"7 * delve_gridwidth, hidden passage can only start at checkpoints
	Gui, delve_grid2: Font, % "norm s"fSize0
	If (delve_enable_recognition = 1) && (A_Gui != "settings_menu")
	{
		IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors,, % A_Space
		style := (delve_pixelcolors = "") ? "cRed" : "cLime"
		Gui, delve_grid2: Add, Text, % "xs Section BackgroundTrans Center", % " mode: recognition "
		Gui, delve_grid2: Add, Text, % style " ys BackgroundTrans Center", % "(" LLK_InStrCount(delve_pixelcolors, "`n") " pixel values saved) "
		Gui, delve_grid2: Add, Text, % "ys Border vdelve_calibration gDelve_scan BackgroundTrans Center", % " calibrate "
		Gui, delve_grid2: Add, Text, % "ys x+4 Border vdelve_delete gDelve_scan BackgroundTrans Center", % " delete data "
	}
	Gui, delve_grid2: Show, % "NA x"xScreenOffSet + poe_width/2 - width/2 " y"yScreenOffSet + poe_height*0.09 + height - 2
	LLK_Overlay("delve_grid2", "show")
	
	guilist .= InStr(guilist, "delve_grid|") ? "" : "delve_grid|"
	guilist .= InStr(guilist, "delve_grid2|") ? "" : "delve_grid2|"
}
Return

Delve_calc:
If (delve_enable_recognition = 1)
{
	If InStr(A_GuiControl, "delve_node_")
		Return
	If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 1) ;left-clicking a node
	{
		parse := StrReplace(A_GuiControl, "delve_node")
		If (delve_hidden_nodes = "")
		{
			;LLK_ToolTip("mark hidden node first")
			Return
		}
		If !InStr(delve_node%parse%_toggle, "green") ;return if clicked node is not highlighted green
			Return
		Else
		{
			delve_node%parse%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%parse%, % delve_node%parse%_toggle
			red_nodes .= parse ","
		}
	}
	If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 2) ;right-clicking hidden node
	{
		If (delve_hidden_nodes != "")
		{
			red_nodes := ","
			Loop 49
			{
				If !InStr(delve_node%A_Index%_toggle, "blank") || !InStr(delve_node%A_Index%_toggle, "black") || (delve_node%A_Index% != "") ;remove highlighting
				{
					delve_node%A_Index%_toggle := "img\GUI\square_blank.png"
					GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				}
			}
			If (StrReplace(A_GuiControl, "delve_node") = delve_hidden_nodes) ;return if old hidden node was un-marked
			{
				delve_hidden_nodes := ""
				Return
			}
			Else delve_hidden_nodes := ""
		}
		check := 0
		Loop 49
		{
			If (delve_node_%A_Index% != "") ;check if grid is blank or not
			{
				check := 1
				break
			}
		}
		If (check = 0) && !InStr(%A_GuiControl%_toggle, "fuchsia") ;display message if grid is blank (hasn't been scanned)
		{
			LLK_ToolTip("scan first")
			Return
		}
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		If (%parse% != "")
			Return
		GuiControlGet, test, delve_grid:, % A_GuiControl
		%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
		%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		delve_hidden_nodes .= StrReplace(A_GuiControl, "delve_node")
		red_nodes := ","
		Loop 49 ;mark impossible nodes red
		{
			check := A_Index
			If (delve_node_%A_Index% = "")
				continue
			If (StrLen(delve_node_%A_Index%) = 8) ;mark four-way nodes red immediately
			{
				delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				red_nodes .= InStr(red_nodes, "," A_Index ",") ? "" : A_Index ","
				continue
			}
			If (A_Index = delve_hidden_nodes - 7 || A_Index = delve_hidden_nodes + 1 || A_Index = delve_hidden_nodes + 7 || A_Index = delve_hidden_nodes - 1) && (delve_node_%A_Index% != "") ;check if node is adjacent to hidden one
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				continue
			}
			blocked := 0
			Loop, Parse, % LLK_DelveDir(check, StrReplace(A_GuiControl, "delve_node")) ;check if direction(s) to the hidden node are blocked
			{
				If ((StrLen(delve_node_%check%) < 6) && (delve_node_%check% = "u,d," || delve_node_%check% = "r,l,"))
					break
				parse := 0
				If InStr(delve_node_%check%, A_Loopfield)
					blocked += 1
				Else If (A_LoopField = "u")
					parse := check - 7
				Else If (A_LoopField = "r")
					parse := check + 1
				Else If (A_LoopField = "d")
					parse := check + 7
				Else If (A_LoopField = "l")
					parse := check - 1
				blocked += (delve_node_%parse% != "") ? 1 : 0
				If (blocked >= StrLen(LLK_DelveDir(check, StrReplace(A_GuiControl, "delve_node"))))
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					continue 2
				}
			}
			dead_ends := ","
			check2 := check
			success := 0
			Loop ;trace all paths to the hidden node and check if connection is possible
			{
				/*
				If (StrLen(LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node"))) = 2) ;prevent path from going into the opposite direction
				{
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "u,")
						general_direction := StrReplace(delve_directions, "d,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "r,")
						general_direction := StrReplace(delve_directions, "l,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "d,")
						general_direction := StrReplace(delve_directions, "u,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "l,")
						general_direction := StrReplace(delve_directions, "r,")
				}
				Else general_direction := LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) ;only let path go towards the hidden node
				*/
				general_direction := LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) ;only let path go towards the hidden node
				If (check2 = delve_hidden_nodes) ;break loop if hidden node has been reached
					break
				If (A_Index > 200)
				{
					LLK_ToolTip("something went wrong")
					Return
				}
				Loop, Parse, general_direction, `,, `, ;try to move from square to square without colliding
				{
					If (A_Loopfield = "") ;mark node red if connection to hidden one is impossible
					{
						dead_ends .= check2
						delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
						GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
						red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
						break 2
					}
					If (A_Loopfield = "u")
						parse := check2 - 7
					Else If (A_Loopfield = "r")
						parse := check2 + 1
					Else If (A_Loopfield = "d")
						parse := check2 + 7
					Else If (A_Loopfield = "l")
						parse := check2 - 1
					If InStr(dead_ends, parse)
						continue
					If (delve_node_%parse% != "") ;mark 'occupied' squares as dead ends
					{
						dead_ends .= parse ","
						check2 := check
						break
					}
					Else ;advance to square if empty
					{
						check2 := parse
						delve_last_move := A_Loopfield
						break
					}
				}
			}
		}
	}
	threeway_nodes := 0
	twoway_nodes := 0
	oneway_nodes := 0
	Loop 49 ;check all two-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 4) && !InStr(red_nodes, "," A_Index ",") ;mark two-way nodes green
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			twoway_nodes += 1
		}
	}
	Loop 49 ;check all three-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes = 0) ;mark three-way nodes green if there are no two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			threeway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes != 0) ;mark three-way nodes yellow if there are two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_yellow_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			threeway_nodes += 1
		}
	}
	Loop 49 ;check all one-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes = 0) && (threeway_nodes = 0) ;mark one-way nodes green if there are no two-way or three-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			oneway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && ((twoway_nodes = 0 && threeway_nodes != 0) || (twoway_nodes != 0 && threeway_nodes = 0)) ;mark one-way nodes yellow if there are three-way nodes but no two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_yellow_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			oneway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes != 0) && (threeway_nodes != 0) ;mark one-way nodes red if there are two-way and three-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
		}
	}
	solvable := 0
	Loop 49 ;check if current grid is unsolvable
	{
		If InStr(delve_node%A_Index%_toggle, "green")
		{
			solvable := 1
			break
		}
	}
	If (solvable = 0)
		LLK_ToolTip("current grid setup is not solvable.`ncheck for scanning errors.", 2)
	Return
}

If (delve_enable_recognition = 1)
	Return

If InStr(A_GuiControl, "delve_node_") && (click = 1) ;clicking paths
{
	If (delve_hidden_nodes != "")
	{
		LLK_ToolTip("uncheck the hidden node(s) before`nchanging surrounding paths")
		Return
	}
	parse := A_GuiControl
	While !IsNumber(SubStr(parse, 1, 1))
		parse := SubStr(parse, 2)
	If (parse = delve_hidden_nodes)
		Return
	
	GuiControlGet, test, delve_grid:, % A_GuiControl
	%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
	%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_black_opaque.png" : "img\GUI\square_blank.png"
	GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
	
	delve_node_%parse% := InStr(delve_node_%parse%, SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ",") ? StrReplace(delve_node_%parse%, SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ",") : delve_node_%parse% SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ","
	If (delve_node_%parse% != "")
		GuiControl, delve_grid:, delve_node%parse%, % "img\GUI\square_black_opaque.png"
	Else GuiControl, delve_grid:, delve_node%parse%, % "img\GUI\square_blank.png"
	Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (delve_hidden_nodes != "") && (click = 1) ;override green highlighting
{
	If InStr(%A_GuiControl%_toggle, "green")
	{
		%A_GuiControl%_toggle := "img\GUI\square_red_opaque.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		red_nodes .= StrReplace(A_GuiControl, "delve_node") ","
		parse := StrReplace(A_GuiControl, "delve_node")
		;If (StrLen(delve_node_%parse%) = 4)
		;	twoway_nodes -= 1
		;If (StrLen(delve_node_%parse%) = 6)
		;	threeway_nodes -= 1
	}
	Else Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 1) && (delve_hidden_nodes = "") ;QoL: toggle between four and zero connections when left-clicking nodes
{
	If (delve_hidden_nodes != "")
	{
		LLK_ToolTip("uncheck the hidden node(s) before`nchanging surrounding paths")
		Return
	}
	If (%A_GuiControl%_toggle = "") || InStr(%A_GuiControl%_toggle, "blank")
	{
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		%parse% := "u,d,l,r,"
		%A_GuiControl%_toggle := "img\GUI\square_black_opaque.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		Loop, parse, delve_directions, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse := StrReplace(A_GuiControl, "delve_node", "delve_node_" A_Loopfield)
			%parse%_toggle := "img\GUI\square_black_opaque.png"
			GuiControl, delve_grid:, % parse, % %parse%_toggle
		}
	}
	Else
	{
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		%parse% := ""
		%A_GuiControl%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		Loop, parse, delve_directions, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse := StrReplace(A_GuiControl, "delve_node", "delve_node_" A_Loopfield)
			%parse%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, % parse, % %parse%_toggle
		}
	}
	Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") ;right-clicking nodes
{
	If (click = 2)
	{
		check := 0
		Loop 49
		{
			If (delve_node_%A_Index% != "")
			{
				check := 1
				break
			}
		}
		If (check = 0) && !InStr(%A_GuiControl%_toggle, "fuchsia")
		{
			LLK_ToolTip("mark surrounding nodes first")
			Return
		}
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		If (%parse% != "")
			Return
		If (delve_hidden_nodes != "")
		{
			delve_node%delve_hidden_nodes%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node%delve_hidden_nodes%, % delve_node%delve_hidden_nodes%_toggle
		}
		/*
		Else
		{
			%A_GuiControl%_toggle := (InStr(%A_GuiControl%_toggle, "blank") || (%A_GuiControl%_toggle = "")) ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		*/
		/*
		If (delve_hidden_nodes = StrReplace(A_GuiControl, "delve_node"))
		{
			%A_GuiControl%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		Else
		{
			GuiControlGet, test, delve_grid:, % A_GuiControl
			%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
			%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		*/
		If (delve_hidden_nodes = StrReplace(A_GuiControl, "delve_node"))
			delve_hidden_nodes := ""
		Else
		{
			%A_GuiControl%_toggle := (InStr(%A_GuiControl%_toggle, "blank") || (%A_GuiControl%_toggle = "")) ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
			delve_hidden_nodes := StrReplace(A_GuiControl, "delve_node")
		}
		
		
		If (delve_hidden_nodes = "") ;reset all node markings if no hidden node is marked
		{
			Loop 49
			{
				If InStr(delve_node%A_Index%_toggle, "red") || InStr(delve_node%A_Index%_toggle, "yellow") || InStr(delve_node%A_Index%_toggle, "green")
				{
					delve_node%A_Index%_toggle := "img\GUI\square_black_opaque.png"
					GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				}
			}
			Return
		}
		red_nodes := ","
	}
	twoway_nodes := 0
	threeway_nodes := 0
	
	Loop 49 ;immediately mark nodes with four connections red
	{
		If (StrLen(delve_node_%A_Index%) = 8)
		{
			delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			red_nodes .= InStr(red_nodes, "," A_Index ",") ? "" : A_Index ","
		}
	}
	
	Loop 49 ;check nodes with two connections first as they are most likely to have the hidden passage
	{
		check := A_Index
		If (StrLen(delve_node_%A_Index%) = 4) && !InStr(red_nodes, "," A_Index ",")
		{
			twoway_nodes += 1
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				twoway_nodes -= 1
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			blocked_directions := 0
			If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes)) = 4)
			{
				Loop, Parse, % LLK_DelveDir(A_Index, delve_hidden_nodes), `,, `, ;check if hidden node is in unreachable direction
				{
					If (A_Loopfield = "")
						break
					If InStr(delve_node_%check%, A_Loopfield)
						blocked_directions += 1
				}
					
				If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes))/2 = blocked_directions) ;mark red if unreachable
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
		}
	}
	
	Loop 49 ;check nodes with three connections
	{
		check := A_Index
		blocked := 0
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",")
		{
			threeway_nodes += 1
			Loop, Parse, delve_directions, `,, `, ;check if open passage is blocked by something else
			{
				If (A_Loopfield = "")
					break
				If InStr(delve_node_%check%, A_Loopfield)
					continue
				If (A_LoopField = "u")
					parse := check - 7
				If (A_LoopField = "d")
					parse := check + 7
				If (A_LoopField = "l")
					parse := check - 1
				If (A_LoopField = "r")
					parse := check + 1
				If (delve_node_%parse% != "")
					blocked := 1
				If (blocked = 1) ;mark red if blocked
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
					break
				}
			}
			
			blocked_directions := 0
			If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes)) = 4)
			{
				Loop, Parse, % LLK_DelveDir(A_Index, delve_hidden_nodes), `,, `, ;check if hidden node is in unreachable direction
				{
					If (A_Loopfield = "")
						break
					If InStr(delve_node_%check%, A_Loopfield)
						blocked_directions += 1
				}
					
				If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes))/2 = blocked_directions) ;mark red if unreachable
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
			Else
			{
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "u,") && !InStr(delve_node_%check%, "d") ;check if hidden node is opposite the only open passage
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "d,") && !InStr(delve_node_%check%, "u")
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "l,") && !InStr(delve_node_%check%, "r")
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "r,") && !InStr(delve_node_%check%, "l")
					blocked_directions := 1
				If (blocked_directions = 1) ;mark red if opposite
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
			
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node, and mark red
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				threeway_nodes -= 1
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes = 0) ;mark node green in case no two-way node exists
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes != 0) ;mark node yellow in case two-way node(s) exist(s)
			{
				delve_node%check%_toggle := "img\GUI\square_yellow_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
		}
	}
	
	Loop 49 ;check nodes with one connection
	{
		check := A_Index
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",")
		{
			blocked_directions := 0
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "u,") && !InStr(delve_node_%check%, "d") ;check if hidden node is opposite the only open passage
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "d,") && !InStr(delve_node_%check%, "u")
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "l,") && !InStr(delve_node_%check%, "r")
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "r,") && !InStr(delve_node_%check%, "l")
				blocked_directions := 1
			If (blocked_directions = 1) ;mark red if opposite
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node, and mark red if there are two-/three-way nodes
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			Else If (twoway_nodes != 0 && threeway_nodes != 0)
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				;red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes = 0) && (threeway_nodes = 0) ;mark node green if it's possible it branches into two hidden paths
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;&& ((twoway_nodes != 0) || (threeway_nodes != 0))
			{
				delve_node%check%_toggle := "img\GUI\square_yellow_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
		}
	}
}
Return

Delve_scan:
If (A_GuiControl = "delve_delete")
{
	IniDelete, ini\delve calibration.ini, pixelcolors
	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
	GoSub, Delve
	Return
}
If (A_GuiControl = "delve_calibration")
{
	clipboard := ""
	KeyWait, LButton
	gui_force_hide := 1
	LLK_Overlay("hide")
	SendInput, #+{s}
	WinWaitNotActive, ahk_group poe_ahk_window
	Sleep, 1000
	WinWaitActive, ahk_group poe_ahk_window
	pDelve_section := Gdip_CreateBitmapFromClipboard()
	If (pDelve_section < 0)
	{
		gui_force_hide := 0
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		ToolTip, calibrating...,,, 17
		delve_pixelcolors2 := ""
		IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors,, % A_Space
		delve_pixelcolors .= (delve_pixelcolors != "") ? "`n" : ""
		Loop, % Gdip_GetImageHeight(pDelve_section)
		{
			check := A_Index - 1
			Loop, % Gdip_GetImageWidth(pDelve_section)
				delve_pixelcolors2 .= Gdip_GetPixelColor(pDelve_section, A_Index - 1, check, 3) "`n"
		}
		Gdip_DisposeImage(pDelve_section)
		Loop, Parse, delve_pixelcolors2, `n, `n
			delve_pixelcolors .= !InStr(delve_pixelcolors, A_Loopfield) && (LLK_InStrCount(delve_pixelcolors2, A_Loopfield, "`n") >= 2) ? A_Loopfield "`n" : ""
		delve_pixelcolors := (SubStr(delve_pixelcolors, 0, 1) = "`n") ? SubStr(delve_pixelcolors, 1, -1) : delve_pixelcolors
		IniDelete, ini\delve calibration.ini, pixelcolors
		IniWrite, % delve_pixelcolors, ini\delve calibration.ini, pixelcolors
		delve_pixelcolors := ""
		delve_pixelcolors2 := ""
		LLK_ToolTip("calibration finished")
		Gui, delve_grid: Destroy
		hwnd_delve_grid := ""
		Gui, delve_grid2: Destroy
		hwnd_delve_grid2 := ""
		GoSub, Delve
	}
	gui_force_hide := 0
	Return
}
Else
{
	WinGetPos, xzero0, yzero0,,, ahk_id %hwnd_delve_grid%
	IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors
	If (delve_pixelcolors = "")
	{
		LLK_ToolTip("no calibration data")
		Return
	}
	xzero0 -= xScreenOffSet
	yzero0 -= yScreenOffSet
	pDelve := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop 49
	{
		check := A_Index
		xgrid := SubStr(LLK_DelveGrid(A_Index), 1, 1)
		ygrid := SubStr(LLK_DelveGrid(A_Index), 3, 1)
		xzero := xzero0 + 1 + (xgrid - 1) * delve_gridwidth
		yzero := yzero0 + 1 + (ygrid - 1) * delve_gridwidth
		hits := 0
		delve_hidden_nodes := ""
		delve_node_%check% := ""
		delve_node%check%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
		Loop, % delve_gridwidth ;scan top edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + A_Index - 1, yzero, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "u,"
				delve_node_u%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_u%check%, % delve_node_u%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_u%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "u,")
			delve_node_u%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_u%check%, % delve_node_u%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan right edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + delve_gridwidth - 1, yzero + A_Index - 1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "r,"
				delve_node_r%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_r%check%, % delve_node_r%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_r%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "r,")
			delve_node_r%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_r%check%, % delve_node_r%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan bottom edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + A_Index - 1, yzero + delve_gridwidth -1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "d,"
				delve_node_d%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_d%check%, % delve_node_d%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_d%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "d,")
			delve_node_d%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_d%check%, % delve_node_d%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan left edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero, yzero + A_Index - 1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "l,"
				delve_node_l%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_l%check%, % delve_node_l%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_l%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "l,")
			delve_node_l%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_l%check%, % delve_node_l%check%_toggle
		}
	}
	Gdip_DisposeImage(pDelve)
	Return
}
Return

Init_delve:
IniRead, enable_delve, ini\config.ini, Features, enable delve, 0
IniRead, delve_panel_offset, ini\delve.ini, Settings, button-offset, 1
delve_panel_dimensions := poe_width*0.03*delve_panel_offset
IniRead, delve_panel_xpos, ini\delve.ini, UI, button xcoord, % A_Space
If !delve_panel_xpos
	delve_panel_xpos := poe_width/2 - (delve_panel_dimensions + 2)/2
IniRead, delve_panel_ypos, ini\delve.ini, UI, button ycoord, % A_Space
If !delve_panel_ypos
	delve_panel_ypos := poe_height - (delve_panel_dimensions + 2)
IniRead, delve_gridwidth, ini\delve.ini, UI, grid dimensions, % Floor(poe_height*0.73/8)
IniRead, enable_delvelog, ini\delve.ini, Settings, enable log-scanning, 0
enable_delvelog := (poe_log_file = 0) ? 0 : enable_delvelog
IniRead, delve_enable_recognition, ini\delve.ini, Settings, enable image-recognition, 0
Return

LLK_DelveDir(hidden_node, node)
{
	direction := ""
	Loop 2
	{
		parse := ""
		loop := 1
		Loop, Parse, % (A_Index = 1) ? hidden_node : node
		{
			If !IsNumber(A_Loopfield)
				continue
			parse .= A_Loopfield
		}
		While (parse > 7)
		{
			parse -= 7
			loop += 1
		}
		If (A_Index = 1)
		{
			xcoord1 := parse
			ycoord1 := loop
		}
		Else
		{
			xcoord2 := parse
			ycoord2 := loop
		}
	}
	If (ycoord1 = ycoord2)
		direction .= ""
	Else direction .= (ycoord1 < ycoord2) ? "d," : "u,"
	If (xcoord1 = xcoord2)
		direction .= ""
	Else direction .= (xcoord1 < xcoord2) ? "r," : "l,"
	Return direction
}

LLK_DelveGrid(node)
{
	loop := 1
	While (node > 7)
	{
		node -= 7
		loop += 1
	}
	Return node "," loop
}