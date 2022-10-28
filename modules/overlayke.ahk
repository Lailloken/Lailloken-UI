Lake_helper:
If (A_Gui = "")
{
	If WinExist("ahk_id " hwnd_lakeboard)
		LLK_Overlay("lakeboard", "hide")
	Else If !WinExist("ahk_id" hwnd_lakeboard) && (hwnd_lakeboard != "")
		LLK_Overlay("lakeboard", "show")
}

If InStr(A_GuiControl, "lake_tile") && (A_Gui != "settings_menu") ;clicking a tile
{
	If (click = 2) ;right-click (setting entrance)
	{
		red_check := 0
		Loop 25 ;check if tablet has been scanned
		{
			If InStr(lake_tile%A_Index%_toggle, "red")
			{
				red_check += 1
				break
			}
		}
		If (red_check = 0) ;tablet has not been scanned
		{
			LLK_ToolTip("scan the tablet first")
			Return
		}
		If !InStr(%A_GuiControl%_toggle, "blank") && !InStr(%A_GuiControl%_toggle, "teal") ;check if right-click is on a water tile
		{
			LLK_ToolTip("entrance cannot be on water")
			Return
		}
		If InStr(%A_GuiControl%_toggle, "teal") ;clear tile and distances if entrance was right-clicked
		{
			lake_entrance := ""
			%A_GuiControl%_toggle := "img\GUI\square_blank.png"
				GuiControl, lakeboard:, %A_GuiControl%, img\GUI\square_blank.png
			Loop 25
				GuiControl, lakeboard:, lake_tile%A_Index%_text1, % ""
			GuiControl, lakeboard:, lake_stats_text, % ""
			Return
		}
		Loop 25 ;clear previous entrance-tile
		{
			If InStr(lake_tile%A_Index%_toggle, "teal")
			{
				lake_tile%A_Index%_toggle := "img\GUI\square_blank.png"
				GuiControl, lakeboard:, lake_tile%A_Index%, img\GUI\square_blank.png
			}
		}
		%A_GuiControl%_toggle := "img\GUI\square_teal_opaque.png"
		GuiControl, lakeboard:, %A_GuiControl%, % %A_GuiControl%_toggle
		lake_stats := ""
		lake_stats_avg := 0
		lake_distances := []
		LLK_LakePath(StrReplace(A_GuiControl, "lake_tile"))
		Loop, % lake_tile_pos.Length() ;go through all tiles and display their distance
		{
			GuiControl, lakeboard:, lake_tile%A_Index%_text1, % lake_distances[A_Index]
			If (lake_distances[A_Index] != "")
				lake_stats .= (lake_stats = "") ? lake_distances[A_Index] : "`n" lake_distances[A_Index]
		}
		Sort, lake_stats, N D`n R
		count := 0
		Loop, Parse, lake_stats, `n, `n ;calculate tablet statistics
		{
			If (A_Index = 1)
				lake_stats := ""
			If (A_LoopField = "")
				continue
			lake_stats_avg += A_LoopField
			count += 1
			If (count <= 2*SubStr(lake_tiles, 2, 1) - 2)
				lake_stats .= (lake_stats = "") ? A_Loopfield : "`n" A_Loopfield
		}
		lake_stats_avg := lake_stats_avg / count
		If (lake_enable_stats = 1)
			GuiControl, lakeboard:, lake_stats_text, % lake_stats "`n(" Format("{:0.2f}", lake_stats_avg) ")"
		Return
	}
	;left-clicking a tile
	start := A_TickCount
	While GetKeyState("LButton", "P") ;holding click to drag the overlay
	{
		If (A_TickCount >= start + 300)
		{
			While GetKeyState("LButton", "P")
			{
				MouseGetPos, lake_xpos, lake_ypos
				Gui, lakeboard: Show, NA x%lake_xpos% y%lake_ypos%
			}
			KeyWait, LButton
			lake_xpos -= xScreenOffSet
			lake_ypos -= yScreenOffSet
			IniWrite, % lake_xpos, ini\lake helper.ini, UI, x-coordinate (%lake_tiles%)
			IniWrite, % lake_ypos, ini\lake helper.ini, UI, y-coordinate (%lake_tiles%)
			Return
		}
	}
	red_check := 0
	Loop 25 ;check if tablet has been scanned
	{
		If InStr(lake_tile%A_Index%_toggle, "red")
		{
			red_check += 1
			break
		}
	}
	If (red_check = 0) ;tablet has not been scanned
	{
		LLK_ToolTip("scan the tablet first")
		Return
	}
	If InStr(%A_GuiControl%_toggle, "teal") ;check if left-click was on entrance
	{
		LLK_ToolTip("cannot place water on entrance")
		Return
	}
	If InStr(%A_GuiControl%_toggle, "red") ;clear red highlighting
	{
		%A_GuiControl%_toggle := "img\GUI\square_blank.png"
		GuiControl, lakeboard:, %A_GuiControl%, img\GUI\square_blank.png
	}
	Else If InStr(%A_GuiControl%_toggle, "blank") ;highlight tile red
	{
		%A_GuiControl%_toggle := "img\GUI\square_red_opaque.png"
		GuiControl, lakeboard:, %A_GuiControl%, img\GUI\square_red_opaque.png
	}
	If (lake_entrance != "") ;if entrance is placed, recalculate distances after placing/removing a water tile
	{
		lake_stats := ""
		lake_stats_avg := 0
		lake_distances := []
		LLK_LakePath(lake_entrance)
		Loop, % lake_tile_pos.Length() ;go through all tiles and display their distance
		{
			GuiControl, lakeboard:, lake_tile%A_Index%_text1, % lake_distances[A_Index]
			If (lake_distances[A_Index] != "")
				lake_stats .= (lake_stats = "") ? lake_distances[A_Index] : "`n" lake_distances[A_Index]
		}
		Sort, lake_stats, N D`n R
		count := 0
		Loop, Parse, lake_stats, `n, `n ;calculate tablet statistics
		{
			If (A_Index = 1)
				lake_stats := ""
			If (A_LoopField = "")
				continue
			lake_stats_avg += A_LoopField
			count += 1
			If (count <= 2*SubStr(lake_tiles, 2, 1) - 2)
				lake_stats .= (lake_stats = "") ? A_Loopfield : "`n" A_Loopfield
		}
		lake_stats_avg := lake_stats_avg / count
		If (lake_enable_stats = 1)
			GuiControl, lakeboard:, lake_stats_text, % lake_stats "`n(" Format("{:0.2f}", lake_stats_avg) ")"
	}
	Return
}

If InStr(A_GuiControl, "tiles") ;tile-size settings
{
	If InStr(A_GuiControl, "minus")
		lake_tile_dimensions -= (lake_tile_dimensions > 0) ? 1 : 0
	If InStr(A_GuiControl, "reset")
		lake_tile_dimensions := poe_height//18
	If InStr(A_GuiControl, "plus")
		lake_tile_dimensions += 1
	IniWrite, % lake_tile_dimensions, ini\lake helper.ini, UI, tile size
}
If InStr(A_GuiControl, "gap") ;gap-size settings
{
	If InStr(A_GuiControl, "minus")
		lake_tile_gap -= (lake_tile_gap > 0) ? 1 : 0
	If InStr(A_GuiControl, "reset")
		lake_tile_gap := 0
	If InStr(A_GuiControl, "plus")
		lake_tile_gap += 1
	IniWrite, % lake_tile_gap, ini\lake helper.ini, UI, gap size
}

If (hwnd_lakeboard = "") || (A_Gui = "settings_menu") ;create tablet overlay
{
	fSize_lake_helper := fSize_config0
	font_height := 0
	While (font_height <= lake_tile_dimensions*(7/16)) ;find font-size approx. half as tall as tile size
	{
		Gui, font_test: New
		Gui, font_test: Font, % "s"fSize_lake_helper, Fontin SmallCaps
		Gui, font_test: Add, Text, HWNDhwnd_font_test, 1
		ControlGetPos,,,, font_height,, ahk_id %hwnd_font_test%
		fSize_lake_helper += 1
	}
	
	guilist .= InStr(guilist, "lakeboard|") ? "" : "lakeboard|"
	Gui, lakeboard: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lakeboard
	Gui, lakeboard: Margin, % lake_tile_gap, % lake_tile_gap
	Gui, lakeboard: Color, White
	WinSet, Transparent, 100
	Gui, lakeboard: Font, % "s"fSize_lake_helper " cBlack Bold", Fontin SmallCaps
	loop := 0
	lake_tile_pos := []
	Loop 25
		lake_tile%A_Index%_toggle := "img\GUI\square_blank.png"
	Loop, % SubStr(lake_tiles, 2, 1)
	{
		Loop, % SubStr(lake_tiles, 1, 1)
		{
			loop += 1
			style := (loop = 1) ? "" : "xs"
			If (A_Index = 1)
				Gui, lakeboard: Add, Picture, % style " Section BackgroundTrans Border HWNDhwnd_lake_tile vlake_tile" loop " gLake_helper w"lake_tile_dimensions " h-1", % "img\GUI\square_blank.png"
			Else Gui, lakeboard: Add, Picture, % "ys BackgroundTrans Border HWNDhwnd_lake_tile vlake_tile" loop " gLake_helper w"lake_tile_dimensions " h-1", % "img\GUI\square_blank.png"
			If (loop = 1)
				ControlGetPos,, lake_stats_ypos,,,, ahk_id %hwnd_lake_tile%
			ControlGetPos, tileXpos, tileYpos, tilewidth,,, ahk_id %hwnd_lake_tile%
			lake_tile_pos[loop] := tileXpos "," tileYpos "," tilewidth
			Gui, lakeboard: Add, Text, % "BackgroundTrans Center vlake_tile" loop "_text1 xp yp w"lake_tile_dimensions, % "77"
			GuiControl, lakeboard:, lake_tile%loop%_text1, % ""
		}
	}
	If (lake_enable_stats = 1)
		Gui, lakeboard: Add, Text, % "ys BackgroundTrans Center vlake_stats_text h"lake_tile_dimensions*SubStr(lake_tiles, 2, 1)*0.95 " y"lake_stats_ypos, % "(7.77)"
	GuiControl, lakeboard:, lake_stats_text, % ""
	IniRead, lake_xpos, ini\lake helper.ini, UI, x-coordinate (%lake_tiles%), % A_Space ;load coordinates of tablet overlay (top-left corner)
	IniRead, lake_ypos, ini\lake helper.ini, UI, y-coordinate (%lake_tiles%), % A_Space
	If !IsNumber(lake_xpos) || !IsNumber(lake_ypos)
		Gui, lakeboard: Show, NA Center
	Else Gui, lakeboard: Show, % "NA x"xScreenOffSet + lake_xpos " y"yScreenOffSet + lake_ypos
	LLK_Overlay("lakeboard", "show")
}
Return

Lake_helper_scan:
IniRead, lake_pixels_water, ini\lake helper.ini, water tile,, % A_Space ;load water-tile color values
If (lake_pixels_water = "") ;couldn't load color values
{
	LLK_ToolTip("no calibration data: water tile")
	Return
}
lake_entrance := ""
pHaystack_lake := Gdip_BitmapFromHWND(hwnd_poe_client, 1) ;take screenshot of PoE-client
Loop, % lake_tile_pos.Length() ;scan every tile
{
	tile_hits := 0
	Loop, Parse, % lake_tile_pos[A_Index], `,, `, ;parse coordinates of every tile (coordinates are relative to overlay, not screen/client)
	{
		Switch A_Index
		{
			Case 1:
				tileXpos := A_LoopField + lake_xpos ;add tile coordinates and overlay coordinates to get tile coordinates relative to PoE-client
			Case 2:
				tileYpos := A_LoopField + lake_ypos
			Case 3:
				tileWidth := A_LoopField
		}
	}
	Loop, % tileWidth//2 ;loop x times (x = half the width of tiles)
	{
		loop := A_Index
		Loop, % tileWidth//2 ;loop y times (y = half the height of tiles)
		{
			pixel_get := Gdip_GetPixelColor(pHaystack_lake, tileXpos + tileWidth//4 + A_Index - 1, tileYpos + tileWidth//4 + loop - 1, 3) ;scan pixels in a quarter-size square in the middle of all tiles
			If InStr(lake_pixels_water, pixel_get) ;scanned pixel's color is present in calibration data
				tile_hits += 1
		}
	}
	GuiControl, lakeboard:, lake_tile%A_Index%_text1, % "" ;clear tile distance
	If (tile_hits >= 0.4*((tileWidth//2)*(tileWidth//2))) ;40% of scanned square has water-tile color
	{
		lake_tile%A_Index%_toggle := "img\GUI\square_red_opaque.png"
		GuiControl, lakeboard:, lake_tile%A_Index%, img\GUI\square_red_opaque.png
	}
	Else
	{
		lake_tile%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, lakeboard:, lake_tile%A_Index%, img\GUI\square_blank.png
	}
}
Gdip_DisposeImage(pHaystack_lake)
Return

Init_lake_helper:
IniRead, lake_tile_dimensions, ini\lake helper.ini, UI, tile size
If !IsNumber(lake_tile_dimensions) ;this is to make sure the UI section in the ini-file is on top
{
	lake_tile_dimensions := poe_height//18
	IniWrite, lake_tile_dimensions, ini\lake helper.ini, UI, tile size
}
IniRead, lake_tile_gap, ini\lake helper.ini, UI, gap size
If !IsNumber(lake_tile_gap)
{
	lake_tile_gap := 2
	IniWrite, 2, ini\lake helper.ini, UI, gap size
}
IniRead, lake_tiles, ini\lake helper.ini, UI, board size
If !IsNumber(lake_tiles)
{
	lake_tiles := 33
	IniWrite, 33, ini\lake helper.ini, UI, board size
}
IniRead, lake_xpos, ini\lake helper.ini, UI, x-coordinate, % A_Space
IniRead, lake_ypos, ini\lake helper.ini, UI, y-coordinate, % A_Space
IniRead, lake_enable_stats, ini\lake helper.ini, Settings, enable stats, 0
IniRead, lake_hotkey, ini\lake helper.ini, Settings, hotkey, % A_Space

If (lake_hotkey != "")
{
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	Hotkey, % lake_hotkey, Lake_helper, On
}
Return

LLK_LakeAdjacent(tile)
{
	global
	Loop 4
	{
		lake_parse_adjacent := ""
		lake_parse_adjacent%A_Index% := ""
	}
	Loop, Parse, delve_directions, `,, `, ;up, down, left, right
	{
		If (A_Loopfield = "") || IsNumber(lake_distances[tile]) ;skip if tile already has a distance value
			continue
		If (A_Loopfield = "u") && (SubStr(LLK_LakeGrid(tile), 3, 1) > 1) ;check if 'up' is inside the tablet
		{
			lake_parse_adjacent := tile - SubStr(lake_tiles, 1, 1) ;declare var for the 'up' tile
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent]) ;check whether 'up' tile is water and whether it has a distance value
				lake_parse_adjacent1 := lake_distances[lake_parse_adjacent] + 1 ;add 1 to 'up' tile's distance and save it as one of four possible distances
			Else lake_parse_adjacent1 := ""
		}
		If (A_Loopfield = "d") && (SubStr(LLK_LakeGrid(tile), 3, 1) < SubStr(lake_tiles, 2, 1))
		{
			lake_parse_adjacent := tile + SubStr(lake_tiles, 1, 1)
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent2 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent2 := ""
		}
		If (A_Loopfield = "l") && (SubStr(LLK_LakeGrid(tile), 1, 1) > 1)
		{
			lake_parse_adjacent := tile - 1
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent3 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent3 := ""
		}
		If (A_Loopfield = "r") && (SubStr(LLK_LakeGrid(tile), 1, 1) < SubStr(lake_tiles, 1, 1))
		{
			lake_parse_adjacent := tile + 1
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent4 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent4 := ""
		}
	}
	lake_parse_adjacent := lake_parse_adjacent1 "," lake_parse_adjacent2 "," lake_parse_adjacent3 "," lake_parse_adjacent4 ;collect the four possible distances in a string
	Loop, Parse, lake_parse_adjacent, `,, `,
	{
		If (A_Index = 1)
			lake_parse_adjacent_array := []
		If (A_Loopfield != "")
			lake_parse_adjacent_array.Push(A_Loopfield) ;collect valid distances in an array
	}
	/*
	If InStr(lake_tile%tile%_toggle, "red")
	{
		lake_distances[tile] := 0
		GuiControl, lakeboard:, lake_tile%tile%_text1, % lake_distances[tile]
	}
	Else
	*/
	If (lake_parse_adjacent_array.Length() != 0) ;array is not empty
		lake_distances[tile] := Min(lake_parse_adjacent_array*) ;the shortest of four possible distances is the correct distance to the entrance
}

LLK_LakeGrid(tile) ;convert tile number into coordinates
{
	global lake_tiles
	loop := 1
	While (tile > SubStr(lake_tiles, 1, 1))
	{
		tile -= SubStr(lake_tiles, 1, 1)
		loop += 1
	}
	Return tile "," loop
}

LLK_LakePath(entrance)
{
	global
	lake_entrance := entrance
	lake_distances[entrance] := 0 ;set distance to entrance to 0
	Loop 25 ;arbitrary number (needs to repeat often enough to assign a distance to each tile)
	{
		Loop, % lake_tile_pos.Length() ;go through all tiles
		{
			If (A_Index = entrance)
				continue
			LLK_LakeAdjacent(A_Index) ;check surrounding tiles
		}
	}
	Loop, % lake_distances.Length() ;check all distance values and clear them if 0 or tile is a water tile
	{
		If InStr(lake_tile%A_Index%_toggle, "red") || (lake_distances[A_Index] = 0)
			lake_distances[A_Index] := ""
	}
}