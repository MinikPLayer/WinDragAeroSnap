; Based on https://www.autohotkey.com/docs/v1/scripts/#EasyWindowDrag_(KDE)
; WARNING: Tested only on Single screen configurations.

#Requires AutoHotkey v2.0
#SingleInstance
Persistent

CoordMode "Mouse"
SetWinDelay 0

OnExit ExitFunc

snap_distance := 10

last_lbutton := A_TickCount
last_rbutton := A_TickCount
last_mbutton := A_TickCount

; Modified LWin + MouseButton detection method
; Using this method it's also possible to use this script in a VM / Parsec.
is_LWin_LMB_pressed := false
is_LWin_RMB_pressed := false

IsAdmin() {
    return A_IsAdmin
}

IsExe() {
    return A_IsCompiled
}

ExitTray(*) {
    ExitApp()
}

IsInstalled(*) {
    ret := RunWait(A_WinDir '\System32\schtasks.exe /QUERY /TN "WinDrag"', , "Hide")
    return ret == 0
}

RunAsAdmin(param) {
    try {
        if IsExe()
            Run '*RunAs "' A_ScriptFullPath '" ' param
        else
            Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '" ' param
    }
    catch Error as e {
        MsgBox("Error: " e.Message)
    }
}

InstallFunc(*) {
    if IsInstalled() {
        ret := MsgBox("Task already installed. Do you want to reinstall?", "Install", 4 | 32)
        if ret == "No"
            return
    }
    
    if not IsAdmin() {
        RunAsAdmin('/I')
        return
    }

    target_path := A_ScriptFullPath
    if not IsExe() {
        target_path := A_AhkPath " " A_ScriptFullPath
    }
    target_path := '"' target_path '"'
    ret := RunWait(A_WinDir '\System32\schtasks.exe /CREATE /SC ONLOGON /TN "WinDrag" /DELAY 0000:05 /RL HIGHEST /F /TR ' target_path,, "Hide")
    if ret != 0 {
        MsgBox("Installation failed", "Install", 16)
    } else {
        is_installed := IsInstalled()
        if not is_installed {
            MsgBox("SCHTASKS completed, but task is not created.", "Install", 16)
        }
        else {
            MsgBox("Installation completed!", "Install", 64)
            InitTray() ; Recreate tray
        }
    }
}

UninstallFunc(*) {
    if not IsInstalled() {
        MsgBox("Task not installed", "Uninstall", 16)
        return
    }

    if not IsAdmin() {
        RunAsAdmin('/U')
        return
    }

    ret := RunWait(A_WinDir '\System32\schtasks.exe /DELETE /TN "WinDrag" /F', , "Hide")
    if ret != 0 {
        MsgBox("Uninstallation failed", "Uninstall", 16)
    } else {
        is_installed := IsInstalled()
        if is_installed {
            MsgBox("SCHTASKS completed, but task is not deleted.", "Uninstall", 16)
        }
        else {
            MsgBox("Uninstallation completed!", "Uninstall", 64)
            InitTray() ; Recreate tray
        }
    }
}

InitTray() {
    Tray := A_TrayMenu ; For convenience.
    Tray.Delete()
    if not IsExe() {
        Tray.AddStandard()
        Tray.Add()
    }

    if IsInstalled() {
        Tray.Add("Uninstall", UninstallFunc)
    }
    else {
        Tray.Add("Install", InstallFunc)
    }
    
    if IsExe() {
        Tray.Add("Exit", ExitTray)      
    }
}

Log(text){
	OutputDebug("AHK | " text)
}

IsDoubleClick(last) {
    current := A_TickCount
    Log("Current: " current ", Last: " last " | Diff: " (current - last))
    if (current - last < 400) {
        last := 0
        return true
    }

    return false
}

Init() {
    for n, param in A_Args {
        if param == "-install" or param == "--install" or param == "/install" or param == "/I" {
            InstallFunc()
        }
        else if param == "-uninstall" or param == "--uninstall" or param == "/uninstall" or param == "/U" {
            UninstallFunc()
        }
        else {
            MsgBox("Invalid switch " param, "Invalid switch", 16)
            ExitApp()
        }
    }

    InitTray()
}


GetScreenResolutionUnderMouse(x, y) {
    dim := {width:0, height:0}                              ; Object to return with width and height
    count := SysGet(80)                            ; Get number of monitors
    Loop (count) {                                         ; Loop through each monitor
        MonitorGet(A_Index, &monLeft, &monTop, &monRight, &monBottom)                                ;  Get this monitor's bounds 
        if (x >= monLeft) && (x <= monRight)                ;  if x falls between the left and right
        && (y <= monBottom) && (y >= monTop)                ;  and y falls between top and bottom
            dim.width := Abs(monRight - monLeft)            ;   Use the bounds to calculate the width
            ,dim.height := Abs(monTop - monBottom)          ;   and the height
    } Until (dim.width > 0)                                 ; Break when a width is found
    return dim                                              ; Return the dimension object
}

SnapVertical(&already_snapped, is_snapped, key_name) {
    if is_snapped {
        if (NOT already_snapped) {
            sleep(1)                    ; Janky, not ideal, but it works. TODO: Find a better way.
            Send "{LWin down}" key_name
            already_snapped := True
        }
    }
    else {
        already_snapped := False
    }
}

SnapHorizontal(&already_snapped, is_snapped, key_name, &as_top, is_top, &as_bottom, is_bottom) {
    if is_snapped {
        if(NOT already_snapped) {
            Send "{LWin down}" key_name
            already_snapped := True
        }

        SnapVertical(&as_top, is_top, "{Up}")
        SnapVertical(&as_bottom, is_bottom, "{Down}")
    }
    else {
        already_snapped := False
    }
}


SetSystemCursor(Cursor := "", cx := 0, cy := 0) {

    static SystemCursors := Map("APPSTARTING", 32650, "ARROW", 32512, "CROSS", 32515, "HAND", 32649, "HELP", 32651, "IBEAM", 32513, "NO", 32648,
                            "SIZEALL", 32646, "SIZENESW", 32643, "SIZENS", 32645, "SIZENWSE", 32642, "SIZEWE", 32644, "UPARROW", 32516, "WAIT", 32514)
 
    if (Cursor = "") {
       AndMask := Buffer(128, 0xFF), XorMask := Buffer(128, 0)
 
       for CursorName, CursorID in SystemCursors {
          CursorHandle := DllCall("CreateCursor", "ptr", 0, "int", 0, "int", 0, "int", 32, "int", 32, "ptr", AndMask, "ptr", XorMask, "ptr")
          DllCall("SetSystemCursor", "ptr", CursorHandle, "int", CursorID) ; calls DestroyCursor
       }
       return
    }
 
    if (Cursor ~= "^(IDC_)?(?i:AppStarting|Arrow|Cross|Hand|Help|IBeam|No|SizeAll|SizeNESW|SizeNS|SizeNWSE|SizeWE|UpArrow|Wait)$") {
       Cursor := RegExReplace(Cursor, "^IDC_")
 
       if !(CursorShared := DllCall("LoadCursor", "ptr", 0, "ptr", SystemCursors[StrUpper(Cursor)], "ptr"))
          throw Error("Error: Invalid cursor name")
 
       for CursorName, CursorID in SystemCursors {
          CursorHandle := DllCall("CopyImage", "ptr", CursorShared, "uint", 2, "int", cx, "int", cy, "uint", 0, "ptr")
          DllCall("SetSystemCursor", "ptr", CursorHandle, "int", CursorID) ; calls DestroyCursor
       }
       return
    }
 
    throw Error("Error: Invalid file path or cursor name")
 }

RestoreCursor() {
    return DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint", 0, "ptr", 0, "uint", 0)
}

ExitFunc(ExitReason, ExitCode) {
    RestoreCursor()
}

LWin & LButton up::
{
    global is_LWin_LMB_pressed
    is_LWin_LMB_pressed := false
}

LWin & LButton::
{
    global last_lbutton
    global is_LWin_LMB_pressed

    is_LWin_LMB_pressed := true
    last := last_lbutton
    last_lbutton := A_TickCount
    if IsDoubleClick(last)
    {
        last_lbutton := 0
        MouseGetPos ,, &KDE_id
        WinActivate KDE_id ; Activate the window.
        ; Toggle between maximized and restored state.
        if WinGetMinMax(KDE_id)
            WinRestore KDE_id
        Else
            WinMaximize KDE_id
        return
    }

    ; Get the initial mouse position and window id, and
    ; abort if the window is maximized.
    MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id

    ; Get the initial window position.
    WinGetPos &KDE_WinX1, &KDE_WinY1,,, KDE_id

    already_snapped_Left := False
    already_snapped_Right := False
    already_snapped_Top := False
    already_snapped_Bottom := False

    SetSystemCursor("SizeAll")
    Loop
    {
        if !is_LWin_LMB_pressed ; Break if button has been released.
            break

        MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
        MOUSE_X := KDE_X2
        MOUSE_Y := KDE_Y2

        KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
        KDE_Y2 -= KDE_Y1
        KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
        KDE_WinY2 := (KDE_WinY1 + KDE_Y2)

        if KDE_X2 != 0 and KDE_Y2 != 0 {
            if (NOT already_snapped_Left) AND (not already_snapped_Right) {
                WinRestore KDE_id
            }

            WinActivate KDE_id ; Activate the window.

            screen_res := GetScreenResolutionUnderMouse(MOUSE_X, MOUSE_Y)
            WinGetPos(&win_x, &win_y, &win_w, &win_h, KDE_id)

            snap_left := False
            snap_right := False
            snap_top := False
            snap_bottom := False

            if MOUSE_X < snap_distance {
                snap_left := True
            }
            else if MOUSE_X > screen_res.width - snap_distance {
                snap_right := True
            }

            if MOUSE_Y < snap_distance {
                snap_top := True
            }
            else if MOUSE_Y > screen_res.height - snap_distance {
                snap_bottom := True
            }

            SnapHorizontal(&already_snapped_Left, snap_left, "{Left}", &already_snapped_Top, snap_top, &already_snapped_Bottom, snap_bottom)
            SnapHorizontal(&already_snapped_Right, snap_right, "{Right}", &already_snapped_Top, snap_top, &already_snapped_Bottom, snap_bottom)

            if (not snap_left) and (not snap_right) {
                WinMove KDE_WinX2, KDE_WinY2,,, KDE_id ; Move the window to the new position.
            }
            
        }
    }

    RestoreCursor()
}

LWin & RButton up::
{
    global is_LWin_RMB_pressed
    is_LWin_RMB_pressed := false
}

LWin & RButton::
{
    global last_rbutton
    global is_LWin_RMB_pressed

    is_LWin_RMB_pressed := true
    last := last_rbutton
    last_rbutton := A_TickCount

    if IsDoubleClick(last)
    {
        last_rbutton := 0
        MouseGetPos ,, &KDE_id
        ; This message is mostly equivalent to WinMinimize,
        ; but it avoids a bug with PSPad.
        PostMessage 0x0112, 0xf020,,, KDE_id
        return
    }

    ; Get the initial mouse position and window id, and
    ; abort if the window is maximized.
    MouseGetPos &KDE_X1, &KDE_Y1, &KDE_id
    if WinGetMinMax(KDE_id)
        return

    ; Get the initial window position and size.
    WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id
    ; Define the window region the mouse is currently in.
    ; The four regions are Up and Left, Up and Right, Down and Left, Down and Right.
    if (KDE_X1 < KDE_WinX1 + KDE_WinW / 2) {
        KDE_WinLeft := 1
    }
    else {
        KDE_WinLeft := -1
    }
    if (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2){
        KDE_WinUp := 1
    }
    else {
        KDE_WinUp := -1
    }

    if KDE_WinLeft == KDE_WinUp
        SetSystemCursor("SizeNWSE")
    else
        SetSystemCursor("SizeNESW")

    Loop
    {
        if !is_LWin_RMB_pressed ; Break if button has been released.
            break
        MouseGetPos &KDE_X2, &KDE_Y2 ; Get the current mouse position.
        ; Get the current window position and size.
        WinGetPos &KDE_WinX1, &KDE_WinY1, &KDE_WinW, &KDE_WinH, KDE_id

        KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
        KDE_Y2 -= KDE_Y1
        ; Then, act according to the defined region.
        WinMove KDE_WinX1 + (KDE_WinLeft+1)/2*KDE_X2 ; X of resized window
        , KDE_WinY1 + (KDE_WinUp+1)/2*KDE_Y2 ; Y of resized window
        , KDE_WinW - KDE_WinLeft *KDE_X2 ; W of resized window
        , KDE_WinH - KDE_WinUp *KDE_Y2 ; H of resized window
        , KDE_id
        KDE_X1 := (KDE_X2 + KDE_X1) ; Reset the initial position for the next iteration.
        KDE_Y1 := (KDE_Y2 + KDE_Y1)
    }

    RestoreCursor()
}

; "Alt + MButton" may be simpler, but I like an extra measure of security for
; an operation like this.
LWin & MButton::
{
    global last_mbutton

    last := last_mbutton
    last_mbutton := A_TickCount

    if IsDoubleClick(last)
    {
        last_mbutton := 0
        MouseGetPos ,, &KDE_id
        WinClose KDE_id
        return
    }
}


Init()