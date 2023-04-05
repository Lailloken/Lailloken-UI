Clone_frames_apply:
Gui, Settings_menu: Submit, NoHide
If (A_GuiControl = "clone_frames_hideout_enable")
{
	IniWrite, % %A_GuiControl%, ini\clone frames.ini, Settings, hide in hideout
	Return
}
If InStr(A_GuiControl, "pixel")
{
	If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
	{
		LLK_ToolTip("pixel-check setup required", 1.5)
		clone_frames_pixelcheck_enable := 0
		GuiControl, settings_menu:, clone_frames_pixelcheck_enable, 0
		Return
	}
	IniWrite, % clone_frames_pixelcheck_enable, ini\clone frames.ini, Settings, enable pixel-check
	Return
}
clone_frames_enabled := ""
Loop, Parse, clone_frames_list, `n, `n
{
	Gui, clone_frames_%A_Loopfield%: Hide
	If (clone_frame_%A_LoopField%_enable = 1)
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
	Else guilist := StrReplace(guilist, "clone_frames_" A_Loopfield "|")
}
GoSub, GUI_clone_frames
Return

Clone_frames_dimensions:
Gui, clone_frames_menu: Submit, NoHide
GuiControl, clone_frames_menu: Text, clone_frame_new_dimensions, % clone_frame_new_width " x " clone_frame_new_height " pixels"
Gui, clone_frame_preview: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview
Gui, clone_frame_preview: Show, NA
Gui, clone_frame_preview_frame: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border +OwnDialogs HWNDhwnd_clone_frame_preview_frame
Gui, clone_frame_preview_frame: Margin, 0, 0
Gui, clone_frame_preview_frame: Color, Black
WinSet, TransColor, Black
If ((clone_frame_new_width > 1) && (clone_frame_new_height > 1))
{
	Gui, clone_frame_preview_frame: Add, Text, % "x0 y0 BackgroundTrans Border w"clone_frame_new_width + 2 " h"clone_frame_new_height + 2
	Gui, clone_frame_preview_frame: Show, % "NA AutoSize x"xScreenOffset + clone_frame_new_topleft_x - 2 " y"yScreenOffset + clone_frame_new_topleft_y - 2
}
Else Gui, clone_frame_preview_frame: Hide
SetTimer, Clone_frames_preview, 100
Return

Clone_frames_delete:
delete_string := StrReplace(A_GuiControl, "delete_", "")
IniDelete, ini\clone frames.ini, %delete_string%
Gui, clone_frames_%delete_string%: Destroy
guilist := StrReplace(guilist, "clone_frames_" delete_string "|")
new_clone_menu_closed := 1
GoSub, Settings_menu
Return

Clone_frames_new:
Gui, settings_menu: Submit
LLK_Overlay("settings_menu", "hide")
If (clone_frames_edit_mode = 1)
{
	edit_string := StrReplace(A_GuiControl, "edit_", "")
	clone_frames_enabled := StrReplace(clone_frames_enabled, edit_string ",")
	Gui, clone_frames_%edit_string%: Hide
	IniRead, clone_frame_edit_topleft_x, ini\clone frames.ini, %edit_string%, source x-coordinate
	IniRead, clone_frame_edit_topleft_y, ini\clone frames.ini, %edit_string%, source y-coordinate
	IniRead, clone_frame_edit_width, ini\clone frames.ini, %edit_string%, frame-width
	IniRead, clone_frame_edit_height, ini\clone frames.ini, %edit_string%, frame-height
	IniRead, clone_frame_edit_target_x, ini\clone frames.ini, %edit_string%, target x-coordinate
	IniRead, clone_frame_edit_target_y, ini\clone frames.ini, %edit_string%, target y-coordinate
	IniRead, clone_frame_edit_scale_x, ini\clone frames.ini, %edit_string%, scaling x-axis, 100
	IniRead, clone_frame_edit_scale_y, ini\clone frames.ini, %edit_string%, scaling y-axis, 100
	IniRead, clone_frame_edit_opacity, ini\clone frames.ini, %edit_string%, opacity, 5
	clone_frames_edit_mode := 0
}
Else
{
	edit_string := ""
	clone_frame_edit_topleft_x := 0
	clone_frame_edit_topleft_y := 0
	clone_frame_edit_width := 0
	clone_frame_edit_height := 0
	clone_frame_edit_target_x := 0
	clone_frame_edit_target_y := 0
	clone_frame_edit_scale_x := 100
	clone_frame_edit_scale_y := 100
	clone_frame_edit_opacity := 5
}
Gui, clone_frames_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_clone_frames_menu, Lailloken UI: clone-frame configuration
Gui, clone_frames_menu: Color, Black
Gui, clone_frames_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, clone_frames_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

Gui, clone_frames_menu: Add, Text, Section BackgroundTrans HWNDmain_text, % "unique frame name: "
ControlGetPos,,, width,,, ahk_id %main_text%

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack limit lowercase vClone_frame_new_name w"width, % edit_string
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_topleft_x gClone_frames_dimensions y+"fSize0*1.2, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly right Limit4 gClone_frames_dimensions vClone_frame_new_topleft_y x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, ys x+0 BackgroundTrans, % " source top-left corner (f1: snap to cursor)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly Limit4 gClone_frames_dimensions right vClone_frame_new_width", % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, 0
Gui, clone_frames_menu: Add, Edit, % "ys hp BackgroundTrans cWhite Number ReadOnly Limit4 gClone_frames_dimensions right vClone_frame_new_height x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, 0
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " frame width && height (f2: snap to cursor)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_target_x gClone_frames_dimensions", % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_target_y gClone_frames_dimensions x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " target top-left corner (f3: snap to cursor)"

GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_x, % clone_frame_edit_topleft_x
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_y, % clone_frame_edit_topleft_y
GuiControl, clone_frames_menu: Text, clone_frame_new_width, % clone_frame_edit_width
GuiControl, clone_frames_menu: Text, clone_frame_new_height, % clone_frame_edit_height
GuiControl, clone_frames_menu: Text, clone_frame_new_target_x, % clone_frame_edit_target_x
GuiControl, clone_frames_menu: Text, clone_frame_new_target_y, % clone_frame_edit_target_y

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cBlack Number Limit4 gClone_frames_dimensions right vClone_frame_new_scale_x", 1000
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range10-1000", % clone_frame_edit_scale_x
Gui, clone_frames_menu: Add, Edit, % "ys hp BackgroundTrans cBlack Number Limit4 gClone_frames_dimensions right vClone_frame_new_scale_y x+"fSize0//3, 1000
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range10-1000", % clone_frame_edit_scale_y
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " x/y-axis scaling (%)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly Limit3 ReadOnly gClone_frames_dimensions right vClone_frame_new_opacity", 10
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-5", % clone_frame_edit_opacity
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " opacity (0-5)"

Gui, clone_frames_menu: Add, Text, % "xs BackgroundTrans HWNDmain_text Border vSave_clone_frame gClone_frames_save y+"fSize0*1.2, % " save && close "
Gui, clone_frames_menu: Show, % "Hide"
WinGetPos,,, win_width, win_height
Gui, clone_frames_menu: Show, % "Hide x"xScreenOffSet + poe_width//2 - win_width//2 " y"yScreenOffSet + poe_height//2 - win_height//2
edit_string := ""
LLK_Overlay("clone_frames_menu", "show", 0)
Gui, clone_frames_menu: Submit, NoHide
Return

Clone_frames_preview:
pPreview := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_new_topleft_x "|" yScreenOffset + clone_frame_new_topleft_y "|" clone_frame_new_width "|" clone_frame_new_height)
wPreview := clone_frame_new_width
hPreview := clone_frame_new_height
wPreview_dest := clone_frame_new_width * clone_frame_new_scale_x//100
hPreview_dest := clone_frame_new_height * clone_frame_new_scale_y//100
hbmPreview := CreateDIBSection(wPreview_dest, hPreview_dest)
hdcPreview := CreateCompatibleDC()
obmPreview := SelectObject(hdcPreview, hbmPreview)
gPreview := Gdip_GraphicsFromHDC(hdcPreview)
Gdip_SetInterpolationMode(gPreview, 0)
Gdip_DrawImage(gPreview, pPreview, 0, 0, wPreview_dest, hPreview_dest, 0, 0, wPreview, hPreview, 0.2 + 0.16 * clone_frame_new_opacity)
UpdateLayeredWindow(hwnd_clone_frame_preview, hdcPreview, xScreenOffset + clone_frame_new_target_x, yScreenOffset + clone_frame_new_target_y, wPreview_dest, hPreview_dest)
SelectObject(hdcPreview, obmPreview)
DeleteObject(hbmPreview)
DeleteDC(hdcPreview)
Gdip_DeleteGraphics(gPreview)
Gdip_DisposeImage(pPreview)
Return

Clone_frames_preview_list:
MouseGetPos, mouseXpos, mouseYpos
If (click = 2)
{
	Gui, clone_frame_context_menu: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_context_menu
	Gui, clone_frame_context_menu: Margin, % fSize0//2, 0
	Gui, clone_frame_context_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, clone_frame_context_menu: Font, cWhite s%fSize0%, Fontin SmallCaps
	clone_frames_edit_mode := 1
	Gui, clone_frame_context_menu: Add, Text, Section BackgroundTrans vEdit_%A_GuiControl% gClone_frames_new, edit
	Gui, clone_frame_context_menu: Add, Text, % "xs BackgroundTrans vDelete_" A_GuiControl " gClone_frames_delete y+"fSize0//2, delete
	Gui, clone_frame_context_menu: Show, % "AutoSize x"mouseXpos " y"mouseYpos
	WinWaitNotActive, ahk_id %hwnd_clone_frame_context_menu%
	clone_frames_edit_mode := 0
	Gui, clone_frame_context_menu: Destroy
	Return
}
Gui, clone_frame_preview_list: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview_list
Gui, clone_frame_preview_list: Show, NA
Gui, clone_frame_preview_list_frame: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview_list_frame
Gui, clone_frame_preview_list_frame: Color, Red
bmpPreview_list := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_%A_GuiControl%_topleft_x "|" yScreenoffset + clone_frame_%A_GuiControl%_topleft_y "|" clone_frame_%A_GuiControl%_width "|" clone_frame_%A_GuiControl%_height)
Gdip_GetImageDimensions(bmpPreview_list, WidthPreview_list, HeightPreview_list)
hbmPreview_list := CreateDIBSection(WidthPreview_list, HeightPreview_list)
hdcPreview_list := CreateCompatibleDC()
obmPreview_list := SelectObject(hdcPreview_list, hbmPreview_list)
GPreview_list := Gdip_GraphicsFromHDC(hdcPreview_list)
Gdip_SetInterpolationMode(GPreview_list, 0)
Gdip_DrawImage(GPreview_list, bmpPreview_list, 0, 0, WidthPreview_list, HeightPreview_list, 0, 0, WidthPreview_list, HeightPreview_list, 1)
UpdateLayeredWindow(hwnd_clone_frame_Preview_list, hdcPreview_list, mouseXpos, mouseYpos, WidthPreview_list, HeightPreview_list)
Gui, clone_frame_preview_list_frame: Show, % "NA x"mouseXpos - fSize0//6 " y"mouseYpos - fSize0//6 " w"WidthPreview_list + 2*(fSize0//6) " h"HeightPreview_list + 2*(fSize0//6)
Gui, clone_frame_preview_list: Show, NA
KeyWait, LButton
Gui, clone_frame_preview_list: Destroy
Gui, clone_frame_preview_list_frame: Destroy
SelectObject(hdcPreview_list, obmPreview_list)
DeleteObject(hbmPreview_list)
DeleteDC(hdcPreview_list)
Gdip_DeleteGraphics(GPreview_list)
Gdip_DisposeImage(bmpPreview_list)
Return

Clone_frames_save:
Gui, clone_frames_menu: Submit, NoHide
clone_frame_new_name_first_letter := SubStr(clone_frame_new_name, 1, 1)
If (clone_frame_new_name = "")
{
	LLK_ToolTip("enter name")
	Return
}
If (clone_frame_new_name = "settings")
{
	LLK_ToolTip("The selected name is not allowed.`nPlease choose a different name.", 3)
	GuiControl, clone_frames_menu: Text, clone_frame_new_name,
	Return
}
If clone_frame_new_name_first_letter is not alnum
{
	LLK_ToolTip("Unsupported first character in frame-name detected.`nPlease choose a different name.", 3)
	GuiControl, clone_frames_menu: Text, clone_frame_new_name,
	Return
}
If (clone_frame_new_width < 1) || (clone_frame_new_height < 1)
{
	LLK_ToolTip("Incorrect dimensions detected.`nPlease make sure to set the source corners properly.", 3)
	Return
}
clone_frame_new_name_save := ""
Loop, Parse, clone_frame_new_name
{
	If (A_LoopField = A_Space)
		add_character := "_"
	Else If A_LoopField is not alnum
		add_character := "_"
	Else add_character := A_LoopField
	clone_frame_new_name_save := (clone_frame_new_name_save = "") ? add_character : clone_frame_new_name_save add_character
}
IniWrite, %clone_frame_new_topleft_x%, ini\clone frames.ini, %clone_frame_new_name_save%, source x-coordinate
IniWrite, %clone_frame_new_topleft_y%, ini\clone frames.ini, %clone_frame_new_name_save%, source y-coordinate
IniWrite, %clone_frame_new_target_x%, ini\clone frames.ini, %clone_frame_new_name_save%, target x-coordinate
IniWrite, %clone_frame_new_target_y%, ini\clone frames.ini, %clone_frame_new_name_save%, target y-coordinate
IniWrite, %clone_frame_new_width%, ini\clone frames.ini, %clone_frame_new_name_save%, frame-width
IniWrite, %clone_frame_new_height%, ini\clone frames.ini, %clone_frame_new_name_save%, frame-height
IniWrite, %clone_frame_new_scale_x%, ini\clone frames.ini, %clone_frame_new_name_save%, scaling x-axis
IniWrite, %clone_frame_new_scale_y%, ini\clone frames.ini, %clone_frame_new_name_save%, scaling y-axis
IniWrite, %clone_frame_new_opacity%, ini\clone frames.ini, %clone_frame_new_name_save%, opacity
clone_frame_%clone_frame_new_name_save%_topleft_x := clone_frame_new_topleft_x
clone_frame_%clone_frame_new_name_save%_topleft_y := clone_frame_new_topleft_y
clone_frame_%clone_frame_new_name_save%_target_x := clone_frame_new_target_x
clone_frame_%clone_frame_new_name_save%_target_y := clone_frame_new_target_y
clone_frame_%clone_frame_new_name_save%_width := clone_frame_new_width
clone_frame_%clone_frame_new_name_save%_height := clone_frame_new_height
clone_frame_%clone_frame_new_name_save%_scale_x := clone_frame_new_scale_x
clone_frame_%clone_frame_new_name_save%_scale_y := clone_frame_new_scale_y
clone_frame_%clone_frame_new_name_save%_opacity := clone_frame_new_opacity
guilist := InStr(guilist, clone_frame_new_name_save) ? guilist : guilist "clone_frames_" clone_frame_new_name_save "|"
clone_frames_menuGuiClose()
Return

Init_cloneframes:
If !FileExist("ini\clone frames.ini")
	IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
IniRead, clone_frames_list, ini\clone frames.ini,,, % A_Space
IniRead, clone_frames_pixelcheck_enable, ini\clone frames.ini, Settings, enable pixel-check, 1
IniRead, clone_frames_hideout_enable, ini\clone frames.ini, Settings, hide in hideout, 0
Loop, Parse, clone_frames_list, `n, `n
{
	If (A_LoopField = "Settings")
		continue
	IniRead, clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable, 0
	If (clone_frame_%A_LoopField%_enable = 1)
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
	IniRead, clone_frame_%A_LoopField%_topleft_x, ini\clone frames.ini, %A_LoopField%, source x-coordinate, 0
	IniRead, clone_frame_%A_LoopField%_topleft_y, ini\clone frames.ini, %A_LoopField%, source y-coordinate, 0
	IniRead, clone_frame_%A_LoopField%_width, ini\clone frames.ini, %A_LoopField%, frame-width, 200
	IniRead, clone_frame_%A_LoopField%_height, ini\clone frames.ini, %A_LoopField%, frame-height, 200
	IniRead, clone_frame_%A_LoopField%_target_x, ini\clone frames.ini, %A_LoopField%, target x-coordinate, % xScreenOffset + poe_width//2
	IniRead, clone_frame_%A_LoopField%_target_y, ini\clone frames.ini, %A_LoopField%, target y-coordinate, % yScreenOffset + poe_height//2
	IniRead, clone_frame_%A_LoopField%_scale_x, ini\clone frames.ini, %A_LoopField%, scaling x-axis, 100
	IniRead, clone_frame_%A_LoopField%_scale_y, ini\clone frames.ini, %A_LoopField%, scaling y-axis, 100
	IniRead, clone_frame_%A_LoopField%_opacity, ini\clone frames.ini, %A_LoopField%, opacity, 5
}
Return

clone_frames_menuGuiClose()
{
	global
	SetTimer, Clone_frames_preview, Delete
	new_clone_menu_closed := 1
	GoSub, Settings_menu
	Gui, clone_frame_preview: Destroy
	Gui, clone_frame_preview_frame: Destroy
	Gui, clone_frames_menu: Destroy
}