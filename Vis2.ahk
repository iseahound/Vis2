; Script:    Vis2.ahk
; Author:    iseahound
; Date:      2017-08-19
; Recent:    2017-08-28

#include <Gdip_All>

class Vis2 {

   static leptonica := ".\bin\leptonica_util\leptonica_util.exe"
   static tesseract := ".\bin\tesseract\tesseract.exe"
   static tessdata  := ".\bin\tesseract\tessdata"

   OCR(n:=0){
      return Vis2.core.start({"me": A_ThisFunc, "processType":"continuous", "google": n})
   }

   class core {

      start(obj := ""){
      static null := ObjBindMethod({}, {})

         if (Vis2.obj != "")
            return "Already in use."

         Vis2.core.setSystemCursor(32515) ; IDC_Cross := 32515
         Hotkey, LButton, % null, On
         Hotkey, ^LButton, % null, On
         Hotkey, !LButton, % null, On
         Hotkey, +LButton, % null, On
         Hotkey, RButton, % null, On
         Hotkey, Escape, % null, On

         Vis2.obj := IsObject(obj) ? obj : {}
         Vis2.obj.selectMode := "Quick"
         Vis2.obj.fileBitmap := A_Temp "\Vis2_screenshot.bmp"
         Vis2.obj.fileProcessedImage := A_Temp "\Vis2_preprocess.tif"
         Vis2.obj.fileConvert := A_Temp "\Vis2_text"
         Vis2.obj.fileConvertedText := A_Temp "\Vis2_text.txt"
         Vis2.obj.Area := new Vis2.Graphics.Area("Vis2_Aries", "0x7FDDDDDD")
         Vis2.obj.Image := new Vis2.Graphics.Image("Vis2_Kitsune")
         Vis2.obj.Subtitle := new Vis2.Graphics.Subtitle("Vis2_Hermes")
         Vis2.obj.background :=   {"x":"center", "y":"83%", "padding":"1.35%", "color":"dd000000", "radius":"8"}
         Vis2.obj.text :=         {"z":1, "q":4, "size":"2.23%", "font":"Arial", "justify":"left", "color":"ffffff"}
         text := (Vis2.obj.google == 0) ? "Optical Character Recognition Tool" : "Any selected text will be Googled."
         Vis2.obj.Subtitle.Render(text, Vis2.obj.background, Vis2.obj.text)

         return Vis2.core.waitForUserInput()
      }

      waitForUserInput(){
      static waitForUserInput := ObjBindMethod(Vis2.core, "waitForUserInput")
      static selectImage := ObjBindMethod(Vis2.core.process, "selectImage")
      static textPreview := ObjBindMethod(Vis2.core.process, "textPreview")

         if (GetKeyState("Escape", "P"))
            return Vis2.core.escape()

         else if (GetKeyState("LButton", "P")) {
            SetTimer, % selectImage, -10
            SetTimer, % textPreview, -25
         }
         else {
            Vis2.obj.Area.Origin()
            SetTimer, % waitForUserInput, -10
         }
         return
      }

      class process {

         selectImage(){
            static selectImage := ObjBindMethod(Vis2.core.process, "selectImage")

               if (GetKeyState("Escape", "P")) {                                   ; This is the escape pattern.
                  Vis2.obj.note_01.Destroy()                                       ; Destroys our "borrowed" Subtitle Object.
                  return Vis2.core.escape()
               }

               if (Vis2.obj.selectMode == "Quick")
                  Vis2.core.process.selectImageQuick()
               if (Vis2.obj.selectMode == "Advanced")
                  Vis2.core.process.selectImageAdvanced()

               if (Vis2.core.overlap() && Vis2.obj.dialogue != Vis2.obj.dialogue_past) {
                  Vis2.obj.dialogue_past := Vis2.obj.dialogue
                  Vis2.obj.background.y := (Vis2.obj.background.y == "83%") ? "2.07%" : "83%"
                  Vis2.obj.Subtitle.Render(Vis2.obj.dialogue, Vis2.obj.background, Vis2.obj.text)
               }

               if (Vis2.obj.Area != "")
                  SetTimer, % selectImage, -10
               return
            }

            selectImageQuick(){
               if (GetKeyState("LButton", "P")) {
                  if (GetKeyState("Control", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P"))
                     Vis2.core.process.selectImageTransition()
                  else if (GetKeyState("RButton", "P")) {
                     Vis2.obj.Area.Move()
                     if (!Vis2.obj.Area.isMouseOnCorner() && Vis2.obj.Area.isMouseStopped())
                        Vis2.obj.Area.Draw() ;Error Correcting
                  }
                  else
                     Vis2.obj.Area.Draw()
               }
               else
                  Vis2.core.process.finale("Area.Release")
               ; Do not return.
            }

            selectImageTransition(){
            static null := ObjBindMethod({}, {})

               DllCall("SystemParametersInfo", UInt,0x57, UInt,0, UInt,0, UInt,0) ; RestoreCursor()
               Hotkey, Space, % null, On
               Hotkey, ^Space, % null, On
               Hotkey, !Space, % null, On
               Hotkey, +Space, % null, On
               Vis2.obj.note_01 := Vis2.Graphics.Subtitle.Render("Advanced Mode", "time: 2500, xCenter y75% p1.35% cFFB1AC r8", "c000000 s24")
               Vis2.obj.selectMode := "Advanced" ; Exit selectImageQuick.
               Vis2.obj.tokenMousePressed := 1
            }

            selectImageAdvanced(){
            static null := ObjBindMethod({}, {})

               if ((Vis2.obj.Area.width() < -25 || Vis2.obj.Area.height() < -25) && !Vis2.obj.note_02)
                  Vis2.obj.note_02 := Vis2.Graphics.Subtitle.Render("Press Alt + LButton to create a new selection anywhere on screen", "time: 6250, x: center, y: 92%, p1.35%, c: FCF9AF, r8", "c000000 s24")

               if (Vis2.obj.tokenEscape == 1) {
                  Vis2.obj.note_02.Destroy()
                  Vis2.core.process.finale("Area.Release")
               }
               else if (Vis2.obj.tokenRenderImage == 1 && !GetKeyState("Space", "P")) {
                  Vis2.obj.Image.Render(Vis2.obj.fileProcessedImage, 0.5)
                  Vis2.obj.Image.ToggleVisible()
                  Vis2.obj.tokenRenderImage := 0
               }
               else if (Vis2.obj.tokenTesseractInput == 1 && !GetKeyState("Space", "P")) {
                  Vis2.obj.tokenTesseractInput := 0
               }
               else if (Vis2.obj.tokenTesseractLanguage == 1 && !GetKeyState("Space", "P")) {
                  Vis2.obj.tokenTesseractLanguage := 0
               }
               else if (Vis2.obj.tokenRedraw == 1) {                                   ; Alt + LButton
                  Vis2.obj.Area.Draw()                                                    ; Redraw
                  if (!GetKeyState("LButton", "P"))
                     Vis2.obj.tokenRedraw := 0, DllCall("SystemParametersInfo", UInt,0x57, UInt,0, UInt,0, UInt,0)
               }
               else if (Vis2.obj.tokenMousePressed == 1) {
                  if (GetKeyState("LButton", "P")) {
                     if (GetKeyState("Control", "P"))                                  ; Ctrl + LButton
                        Vis2.obj.Area.ResizeCorners()                                     ; Drag Rectangle Corners.
                     else if (GetKeyState("Shift", "P"))                               ; Shift + LButton
                        Vis2.obj.Area.ResizeEdges()                                       ; Resize Rectangle Edges
                     else
                        Vis2.obj.Area.Move()                                              ; Transform Rectangle, 2D
                  }
                  else if (GetKeyState("RButton", "P"))
                     Vis2.obj.Area.Move()
                  if (!GetKeyState("LButton", "P") && !GetKeyState("RButton", "P"))
                     Vis2.obj.tokenMousePressed := 0
               }
               else if (GetKeyState("Space", "P") && GetKeyState("Control", "P"))
                  Vis2.obj.tokenRenderImage := 1
               else if (GetKeyState("Space", "P") && GetKeyState("Alt", "P"))
                  Vis2.obj.tokenTesseractInput := 1
               else if (GetKeyState("Space", "P") && GetKeyState("Shift", "P"))
                  Vis2.obj.tokenTesseractLanguage := 1
               else if (GetKeyState("Space", "P"))
                  Vis2.obj.tokenEscape := 1
               else if (GetKeyState("LButton", "P") && GetKeyState("Alt", "P")) {
                  Vis2.core.setSystemCursor(32515) ; IDC_Cross := 32515
                  Vis2.obj.tokenRedraw := 1
                  Vis2.obj.Area.Origin()
               }
               else if ((GetKeyState("LButton", "P") || GetKeyState("RButton", "P")) && Vis2.obj.Area.isMouseInside())
                  Vis2.obj.tokenMousePressed := 1                                      ; Check if isMouseInside only ONCE.
               else {                                                                  ; If no mouse buttons are pressed
                  Vis2.obj.Area.Hover()                                                   ; Collapse Stack
                  if Vis2.obj.Area.isMouseInside() {
                     Hotkey, LButton, % null, On
                     Hotkey, RButton, % null, On
                  } else {
                     Hotkey, LButton, % null, Off
                     Hotkey, RButton, % null, Off
                  }
               }
               ; Do not return.
         }

         textPreview(){
         static textPreview := ObjBindMethod(Vis2.core.process, "textPreview")

            ; Takes a Screenshot
            x := Vis2.obj.Area.x1()
            y := Vis2.obj.Area.y1()
            w := Vis2.obj.Area.width()
            h := Vis2.obj.Area.height()

            pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
            ;Vis2.obj.Area.ImageData := Gdip_EncodeBitmapTo64string(pBitmap, "jpg")
            Gdip_SaveBitmapToFile(pBitmap, Vis2.obj.fileBitmap, 92)
            Gdip_DisposeImage(pBitmap)

            if (true) {
               Vis2.core.preprocess(Vis2.obj.fileBitmap, Vis2.obj.fileProcessedImage)
               Vis2.core.convert(Vis2.obj.fileProcessedImage, Vis2.obj.fileConvert)
               if (Vis2.obj.Image.isVisible() == true)
                  Vis2.obj.Image.Render(Vis2.obj.fileProcessedImage, 0.5)

               database := FileOpen(Vis2.obj.fileConvertedText, "r`n", "UTF-8")
               i := 0
               dialogue := ""

               while (i < 3) {
                  data := database.ReadLine()
                  data := RegExReplace(data, "^\s*(.*?)\s*$", "$1")
                  if (data != "") {
                     dialogue .= (i == 0) ? data : ("`n" . data)
                     i++
                  }
                  if (!database || database.AtEOF)
                     break
               }

               if (dialogue != "") {
                  Vis2.obj.firstDialogue := true
                  Vis2.obj.dialogue := dialogue
                  Vis2.obj.Subtitle.Render(Vis2.obj.dialogue, Vis2.obj.background, Vis2.obj.text)  ; condensed font
               }
               else {
                  Vis2.obj.dialogue := (Vis2.obj.firstDialogue == true) ? "ERROR: No Text Data Found" : "Searching for text..."
                  Vis2.obj.Subtitle.Render(Vis2.obj.dialogue, Vis2.obj.background, Vis2.obj.text)
               }


               database.Seek(0, 0)
               Vis2.obj.database := RegExReplace(database.Read(), "^\s*(.*?)\s*$", "$1")
               Vis2.obj.database := RegExReplace(Vis2.obj.database, "(?<!\r)\n", "`r`n")
               database.Close()
            }

            if !Vis2.obj.Area {
               Vis2.obj.textPreview := "COMPLETE"
               return Vis2.core.process.finale()
            }
            else
               SetTimer, % textPreview, -100
            return
         }

         finale(string := ""){
            if (string == "Area.Release"){
               Vis2.obj.Area.Destroy()
               Vis2.obj.Area := ""
            }

            if (!Vis2.obj.Area && Vis2.obj.textPreview == "COMPLETE") {
               if (Vis2.obj.database != "") {
                  if (Vis2.obj.google == 1 && Vis2.obj.noCopy != true)
                     Run % "https://www.google.com/search?&q=" . RegExReplace(Vis2.obj.database, "\s", "+")
                  else if (Vis2.obj.noCopy != true) {
                     clipboard := Vis2.obj.database
                     Vis2.Graphics.Subtitle.Render("Saved to Clipboard.", "time: 1250, x: center, y: 83%, p: 1.35%, c: F9E486, r: 8", "c: 0x000000, s:24, f:Arial")
                  }
               }
               Vis2.core.escape()
            }
            return
         }
      }

      escape(){
      static null := ObjBindMethod({}, {})

         Hotkey, LButton, % null, Off
         Hotkey, ^LButton, % null, Off
         Hotkey, !LButton, % null, Off
         Hotkey, +LButton, % null, Off
         Hotkey, RButton, % null, Off
         Hotkey, Escape, % null, Off
         Hotkey, Space, % null, Off
         Hotkey, ^Space, % null, Off
         Hotkey, !Space, % null, Off
         Hotkey, +Space, % null, Off

         Vis2.core.deleteFiles()
         Vis2.obj.Area.Destroy()
         Vis2.obj.Image.Destroy()
         Vis2.obj.Subtitle.Destroy()
         Vis2.obj := "" ; Goodbye all, you were loved :c
         return DllCall("SystemParametersInfo", UInt,0x57, UInt,0, UInt,0, UInt,0) ; RestoreCursor()
      }

      overlap() {
         p1 := Vis2.obj.Area.x1()
         p2 := Vis2.obj.Area.x2()
         r1 := Vis2.obj.Area.y1()
         r2 := Vis2.obj.Area.y2()

         q1 := Vis2.obj.Subtitle.x1()
         q2 := Vis2.obj.Subtitle.x2()
         s1 := Vis2.obj.Subtitle.y1()
         s2 := Vis2.obj.Subtitle.y2()

         a := (p1 < q1 && q1 < p2) || (p1 < q2 && q2 < p2) || (q1 < p1 && p1 < q2) || (q1 < p2 && p2 < q2)
         b := (r1 < s1 && s1 < r2) || (r1 < s2 && s2 < r2) || (s1 < r1 && r1 < s2) || (s1 < r2 && r2 < s2)

         ;Tooltip % a "`t" b "`n`n" p1 "`t" r1 "`n" p2 "`t" r2 "`n`n" q1 "`t" s1 "`n" q2 "`t" s2
         return (a && b)
      }

      setSystemCursor(CursorID = "", cx = 0, cy = 0 ) { ; Thanks to Serenity - https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
         static SystemCursors := "32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651"

         Loop, Parse, SystemCursors, `,
         {
               Type := "SystemCursor"
               CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )
               %Type%%A_Index% := DllCall( "CopyImage", Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )
               CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
               DllCall( "SetSystemCursor", Uint,CursorHandle, Int,A_Loopfield)
         }
      }

      ; Takes a Screenshot of the Area. (including the Area Object itself, which lends the final image a grey tint.)
      ; To avoid the grey tint, call this.Destroy() before this to remove the window.
      ; If you do not input a fileName parameter, and do not set a fileName value (this.fileName)
      ; then it will return a pBitmap object.
      screenshot(fileName := "", quality := 92){
         pBitmap := Gdip_BitmapFromScreen(Vis2.obj.Area.ScreenshotRectangle())
         ;Vis2.obj.Area.ImageData := Gdip_EncodeBitmapTo64string(pBitmap, "jpg")
         Gdip_SaveBitmapToFile(pBitmap, Vis2.obj.fileBitmap, quality)
         Gdip_DisposeImage(pBitmap)
         return true
      }


      MD5(string, isFile := 0){
         static BCRYPT_MD5_ALGORITHM := "MD5"
         static BCRYPT_OBJECT_LENGTH := "ObjectLength"
         static BCRYPT_HASH_LENGTH   := "HashDigestLength"

         if !(hBCRYPT := DllCall("LoadLibrary", "str", "bcrypt.dll", "ptr"))
            throw Exception("Failed to load bcrypt.dll", -1)

         if (NT_STATUS := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "ptr*", hAlgo, "ptr", &BCRYPT_MD5_ALGORITHM, "ptr", 0, "uint", 0) != 0)
            throw Exception("BCryptOpenAlgorithmProvider: " NT_STATUS, -1)

         if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_OBJECT_LENGTH, "uint*", cbHashObject, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
            throw Exception("BCryptGetProperty: " NT_STATUS, -1)

         if (NT_STATUS := DllCall("bcrypt\BCryptGetProperty", "ptr", hAlgo, "ptr", &BCRYPT_HASH_LENGTH, "uint*", cbHash, "uint", 4, "uint*", cbResult, "uint", 0) != 0)
            throw Exception("BCryptGetProperty: " NT_STATUS, -1)

         VarSetCapacity(pbHashObject, cbHashObject, 0)
         if (NT_STATUS := DllCall("bcrypt\BCryptCreateHash", "ptr", hAlgo, "ptr*", hHash, "ptr", &pbHashObject, "uint", cbHashObject, "ptr", 0, "uint", 0, "uint", 0) != 0)
            throw Exception("BCryptCreateHash: " NT_STATUS, -1)

         if (isFile) {
            if !(f := FileOpen(string, "r", "UTF-8"))
               throw Exception("Failed to open file: " filename, -1)
            f.Seek(0)
            while (dataread := f.RawRead(data, 262144))
               if (NT_STATUS := DllCall("bcrypt\BCryptHashData", "ptr", hHash, "ptr", &data, "uint", dataread, "uint", 0) != 0)
                  throw Exception("BCryptHashData: " NT_STATUS, -1)
            f.Close()
         }
         else {
            VarSetCapacity(pbInput, StrPut(string, "UTF-8"), 0) && cbInput := StrPut(string, &pbInput, "UTF-8") - 1
            if (NT_STATUS := DllCall("bcrypt\BCryptHashData", "ptr", hHash, "ptr", &pbInput, "uint", cbInput, "uint", 0) != 0)
                  throw Exception("BCryptHashData: " NT_STATUS, -1)
         }

         VarSetCapacity(pbHash, cbHash, 0)
         if (NT_STATUS := DllCall("bcrypt\BCryptFinishHash", "ptr", hHash, "ptr", &pbHash, "uint", cbHash, "uint", 0) != 0)
               throw Exception("BCryptFinishHash: " NT_STATUS, -1)

         loop % cbHash
               hash .= Format("{:02x}", NumGet(pbHash, A_Index - 1, "uchar"))

         DllCall("bcrypt\BCryptDestroyHash", "ptr", hHash)
         DllCall("bcrypt\BCryptCloseAlgorithmProvider", "ptr", hAlgo, "uint", 0)
         DllCall("FreeLibrary", "ptr", hBCRYPT)

         return hash
      }

      isIdenticalScreenshot(){
         return Vis2.obj.Area.Hash == Vis2.obj.Area.Hash := Vis2.core.MD5(Vis2.obj.fileBitmap, 1)
      }


      preprocess(f_in, f_out){
         static ocrPreProcessing := 1
         static negateArg := 2
         static performScaleArg := 1
         static scaleFactor := 3.5

         RunWait, % Vis2.leptonica " " f_in " " f_out " " negateArg " 0.5 " performScaleArg " " scaleFactor " " ocrPreProcessing " 5 2.5 " ocrPreProcessing  " 2000 2000 0 0 0.0", , Hide
      }

      convert(f_in, f_out){
         RunWait, % Vis2.tesseract " " f_in " " f_out, , Hide
      }

      tesseractLanguage(){
         Loop, Files, % Vis2.tessdata "\*.traineddata"
         {
            Vis2.Graphics.Subtitle.Render("Language: " RegExReplace(A_LoopFileName, "^(.*?)\.traineddata$", "$1"))
         }
      }

      deleteFiles(){
         Vis2.core.FileDelete(Vis2.obj.fileBitmap)
         Vis2.core.FileDelete(Vis2.obj.fileProcessedImage)
         Vis2.core.FileDelete(Vis2.obj.fileConvertedText)
      }

      fileDelete(Filename) {
         FileDelete, %Filename%
      }
   }


   class Graphics {

      static pToken, Gdip := 0

      Startup(){
         return Vis2.Graphics.pToken := (Vis2.Graphics.Gdip++ > 0) ? Vis2.Graphics.pToken : Gdip_Startup()
      }

      Shutdown(){
         return Vis2.Graphics.pToken := (--Vis2.Graphics.Gdip == 0) ? Gdip_Shutdown(Vis2.Graphics.pToken) : Vis2.Graphics.pToken
      }

      Name(){
         VarSetCapacity(UUID, 16, 0)
         if (DllCall("rpcrt4.dll\UuidCreate", "ptr", &UUID) != 0)
             return (ErrorLevel := 1) & 0
         if (DllCall("rpcrt4.dll\UuidToString", "ptr", &UUID, "uint*", suuid) != 0)
             return (ErrorLevel := 2) & 0
         return A_TickCount "n" SubStr(StrGet(suuid), 1, 8), DllCall("rpcrt4.dll\RpcStringFree", "uint*", suuid)
      }


      class Area{

         ScreenWidth := A_ScreenWidth, ScreenHeight := A_ScreenHeight,
         action := [], x := [0], y := [0], w := [1], h := [1], a := ["top left"], q := ["bottom right"]

         __New(name := "", color := "0x7FDDDDDD") {
            this.name := name := (name == "") ? Vis2.Graphics.Name() "_Graphics_Area" : name "_Graphics_Area"
            this.color := color

            Vis2.Graphics.Startup()
            Gui, %name%:New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndSecretName, % this.name
            Gui, %name%:Show, % (this.isDrawable()) ? "NoActivate" : ""
            this.hwnd := SecretName
            this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            Gdip_SetSmoothingMode(this.G, 4) ;Adds one clickable pixel to the edge.
            this.pBrush := Gdip_BrushCreateSolid(this.color)
         }

         __Delete(){
            Vis2.Graphics.Shutdown()
         }

         Destroy(){
            Gdip_DeleteBrush(this.pBrush)
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            Gui, % this.name ":Destroy"
         }

         isDrawable(win := "A"){
             static WM_KEYDOWN := 0x100,
             static WM_KEYUP := 0x101,
             static vk_to_use := 7
             ; Test whether we can send keystrokes to this window.
             ; Use a virtual keycode which is unlikely to do anything:
             PostMessage, WM_KEYDOWN, vk_to_use, 0,, % win
             if !ErrorLevel
             {   ; Seems best to post key-up, in case the window is keeping track.
                 PostMessage, WM_KEYUP, vk_to_use, 0xC0000000,, % win
                 return true
             }
             return false
         }

         DetectScreenResolutionChange(){
            if (this.ScreenWidth != A_ScreenWidth || this.ScreenHeight != A_ScreenHeight) {
               this.ScreenWidth := A_ScreenWidth, this.ScreenHeight := A_ScreenHeight
               SelectObject(this.hdc, this.obm)
               DeleteObject(this.hbm)
               DeleteDC(this.hdc)
               Gdip_DeleteGraphics(this.G)
               this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
               this.hdc := CreateCompatibleDC()
               this.obm := SelectObject(this.hdc, this.hbm)
               this.G := Gdip_GraphicsFromHDC(this.hdc)
               Gdip_SetSmoothingMode(this.G, 4)
            }
         }

         Redraw(x, y, w, h){
            Critical
            this.DetectScreenResolutionChange()
            Gdip_GraphicsClear(this.G)
            Gdip_FillRectangle(this.G, this.pBrush, x, y, w, h)
            UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.ScreenWidth, this.ScreenHeight)
         }

         Propagate(v){
            this.a[v] := (this.a[v] == "") ? this.a[v-1] : this.a[v]
            this.q[v] := (this.q[v] == "") ? this.q[v-1] : this.q[v]
            this.x[v] := (this.x[v] == "") ? this.x[v-1] : this.x[v]
            this.y[v] := (this.y[v] == "") ? this.y[v-1] : this.y[v]
            this.w[v] := (this.w[v] == "") ? this.w[v-1] : this.w[v]
            this.h[v] := (this.h[v] == "") ? this.h[v-1] : this.h[v]
         }

         BackPropagate(pasts){
            action := this.action.pop()
            a := this.a.pop()
            q := this.q.pop()
            x := this.x.pop()
            y := this.y.pop()
            w := this.w.pop()
            h := this.h.pop()

            dx := x - this.x[pasts-1]
            dy := y - this.y[pasts-1]
            dw := w - this.w[pasts-1]
            dh := h - this.h[pasts-1]

            i := pasts-1
            while (i >= 1) {
               this.x[i] += dx
               this.y[i] += dy
               this.w[i] += dw
               this.h[i] += dh
               i--
            }
         }

         Converge(v := ""){
            v := (v) ? v : this.action.MaxIndex()

            if (v > 2) {
               this.action := [this.action[v-1], this.action[v]]
               this.a := [this.a[v-1], this.a[v]]
               this.q := [this.q[v-1], this.q[v]]
               this.x := [this.x[v-1], this.x[v]]
               this.y := [this.y[v-1], this.y[v]]
               this.w := [this.w[v-1], this.w[v]]
               this.h := [this.h[v-1], this.h[v]]
            }
         }

         Debug(){
            Tooltip % A_ThisFunc "`t" v . "`n" v-1 ": " this.action[v-1]
               . "`n" this.x[v-2] ", " this.y[v-2] ", " this.w[v-2] ", " this.h[v-2]
               . "`n" this.x[v-1] ", " this.y[v-1] ", " this.w[v-1] ", " this.h[v-1]
               . "`n" this.x[v] ", " this.y[v] ", " this.w[v] ", " this.h[v]
               . "`nAnchor:`t" this.a[v] "`nMouse:`t" this.q[v] "`t" this.isMouseInside()
         }

         Hover(){
            CoordMode, Mouse, Screen
            MouseGetPos, x_hover, y_hover
            this.x_hover := x_hover
            this.y_hover := y_hover

            ; Resets the stack to 1.
            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.action := [A_ThisFunc]
               this.a := [this.a.pop()]
               this.q := [this.q.pop()]
               this.x := [this.x.pop()]
               this.y := [this.y.pop()]
               this.w := [this.w.pop()]
               this.h := [this.h.pop()]
            }
         }

         Origin(v := ""){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
            }

            v := (v) ? v : this.action.MaxIndex()

            if (x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               this.x[v] := x_mouse
               this.y[v] := y_mouse

               this.Redraw(x_mouse, y_mouse, 1, 1) ;stabilize x/y corrdinates in window spy.
            }
         }

         Draw(v := ""){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc == this.action[this.action.MaxIndex()-1]){
               this.BackPropagate(this.action.MaxIndex())
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }
            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.MaxIndex()
            dx := x_mouse - this.x_hover
            dy := y_mouse - this.y_hover
            xr := (x_mouse > this.x[v-1]) ? 1 : 0
            yr := (y_mouse > this.y[v-1]) ? 1 : 0

            if (pass == 1 || x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               this.x[v] := (xr) ? this.x[v-1] : x_mouse
               this.y[v] := (yr) ? this.y[v-1] : y_mouse
               this.w[v] := (xr) ? x_mouse - this.x[v-1] : this.x[v-1] - x_mouse
               this.h[v] := (yr) ? y_mouse - this.y[v-1] : this.y[v-1] - y_mouse

               this.a[v] := (xr && yr) ? "top left" : (xr && !yr) ? "bottom left" : (!xr && yr) ? "top right" : "bottom right"
               this.q[v] := (xr && yr) ? "bottom right" : (xr && !yr) ? "top right" : (!xr && yr) ? "bottom left" : "top left"

               this.Propagate(v)
               this.Redraw(this.x[v], this.y[v], this.w[v], this.h[v])
            }
         }

         Move(v := ""){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.MaxIndex()
            dx := x_mouse - this.x_hover
            dy := y_mouse - this.y_hover

            if (pass == 1 || x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               this.x[v] := this.x[v-1] + dx
               this.y[v] := this.y[v-1] + dy

               this.Propagate(v)
               this.Redraw(this.x[v], this.y[v], this.w[v], this.h[v])
            }
         }

         ResizeCorners(v := ""){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.MaxIndex()
            xr := this.x_hover - this.x[v-1] - (this.w[v-1] / 2)
            yr := this.y[v-1] - this.y_hover + (this.h[v-1] / 2) ; Keep Change Change
            dx := x_mouse - this.x_hover
            dy := y_mouse - this.y_hover

            if (pass == 1 || x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               if (xr < -1 && yr > 1) {
                  r := "top left"
                  this.x[v] := this.x[v-1] + dx
                  this.y[v] := this.y[v-1] + dy
                  this.w[v] := this.w[v-1] - dx
                  this.h[v] := this.h[v-1] - dy
               }
               if (xr >= -1 && yr > 1) {
                  r := "top right"
                  this.x[v] := this.x[v-1]
                  this.y[v] := this.y[v-1] + dy
                  this.w[v] := this.w[v-1] + dx
                  this.h[v] := this.h[v-1] - dy
               }
               if (xr < -1 && yr <= 1) {
                  r := "bottom left"
                  this.x[v] := this.x[v-1] + dx
                  this.y[v] := this.y[v-1]
                  this.w[v] := this.w[v-1] - dx
                  this.h[v] := this.h[v-1] + dy
               }
               if (xr >= -1 && yr <= 1) {
                  r := "bottom right"
                  this.x[v] := this.x[v-1]
                  this.y[v] := this.y[v-1]
                  this.w[v] := this.w[v-1] + dx
                  this.h[v] := this.h[v-1] + dy
               }

               this.Propagate(v)
               this.Redraw(this.x[v], this.y[v], this.w[v], this.h[v])
            }
         }

         ; This works by finding the line equations of the diagonals of the rectangle.
         ; To identify the quadrant the cursor is located in, the while loop compares it's y value
         ; with the function line values f(x) = m * xr and y = -m * xr.
         ; So if yr is below both theoretical y values, then we know it's in the bottom quadrant.
         ; Be careful with this code, it converts the y plane inversely to match the Decartes tradition.

         ; Safety features include checking for past values to prevent flickering
         ; Sleep statements are required in every while loop.

         ResizeEdges(v := ""){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.MaxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.MaxIndex()
            m := -(this.h[v-1] / this.w[v-1])                              ; slope (dy/dx)
            xr := this.x_hover - this.x[v-1] - (this.w[v-1] / 2)           ; draw a line across the center
            yr := this.y[v-1] - this.y_hover + (this.h[v-1] / 2)           ; draw a vertical line halfing it
            dx := x_mouse - this.x_hover
            dy := y_mouse - this.y_hover

            if (pass == 1 || x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               if (m * xr >= yr && yr > -m * xr)
                  r := "left",                this.x[v] := this.x[v-1] + dx,               this.w[v] := this.w[v-1] - dx
               if (m * xr < yr && yr > -m * xr)
                  r := "top",                 this.y[v] := this.y[v-1] + dy,               this.h[v] := this.h[v-1] - dy
               if (m * xr < yr && yr <= -m * xr)
                  r := "right",   this.w[v] := this.w[v-1] + dx
               if (m * xr >= yr && yr <= -m * xr)
                  r := "bottom",  this.h[v] := this.h[v-1] + dy

               this.Propagate(v)
               this.Redraw(this.x[v], this.y[v], this.w[v], this.h[v])
            }
         }

         isMouseInside(){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return (x_mouse >= this.x[this.x.MaxIndex()]
               && x_mouse <= this.x[this.x.MaxIndex()] + this.w[this.w.MaxIndex()]
               && y_mouse >= this.y[this.y.MaxIndex()]
               && y_mouse <= this.y[this.y.MaxIndex()] + this.h[this.h.MaxIndex()])
         }

         isMouseOutside(){
            return !this.isMouseInside()
         }

         isMouseOnCorner(){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return (x_mouse == this.x[this.x.MaxIndex()] || x_mouse == this.x[this.x.MaxIndex()] + this.w[this.w.MaxIndex()])
               && (y_mouse == this.y[this.y.MaxIndex()] || y_mouse == this.y[this.y.MaxIndex()] + this.h[this.h.MaxIndex()])
         }

         isMouseOnEdge(){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return ((x_mouse >= this.x[this.x.MaxIndex()] && x_mouse <= this.x[this.x.MaxIndex()] + this.w[this.w.MaxIndex()])
               && (y_mouse == this.y[this.y.MaxIndex()] || y_mouse == this.y[this.y.MaxIndex()] + this.h[this.h.MaxIndex()]))
               OR ((y_mouse >= this.y[this.y.MaxIndex()] && y_mouse <= this.y[this.y.MaxIndex()] + this.h[this.h.MaxIndex()])
               && (x_mouse == this.x[this.x.MaxIndex()] || x_mouse == this.x[this.x.MaxIndex()] + this.w[this.w.MaxIndex()]))
         }

         isMouseStopped(){
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return x_mouse == this.x_last && y_mouse == this.y_last
         }

         ScreenshotRectangle(){
            return this.x[this.x.MaxIndex()] "|" this.y[this.y.MaxIndex()] "|" this.w[this.w.MaxIndex()] "|" this.h[this.h.MaxIndex()]
         }

         x1(){
            return this.x[this.x.MaxIndex()]
         }

         x2(){
            return this.x[this.x.MaxIndex()] + this.w[this.w.MaxIndex()]
         }

         y1(){
            return this.y[this.y.MaxIndex()]
         }

         y2(){
            return this.y[this.y.MaxIndex()] + this.h[this.h.MaxIndex()]
         }

         width(){
            return this.w[this.w.MaxIndex()]
         }

         height(){
            return this.h[this.h.MaxIndex()]
         }
      }


      Class CustomFont{
         /*
         CustomFont v2.00 (2016-2-24) by tmplinshi
         ---------------------------------------------------------
         Description: Load font from file or resource, without needed install to system.
         ---------------------------------------------------------
         Useage Examples:

            * Load From File
               font1 := New CustomFont("ewatch.ttf")
               Gui, Font, s100, ewatch

            * Load From Resource
               Gui, Add, Text, HWNDhCtrl w400 h200, 12345
               font2 := New CustomFont("res:ewatch.ttf", "ewatch", 80) ; <- Add a res: prefix to the resource name.
               font2.ApplyTo(hCtrl)

            * The fonts will removed automatically when script exits.
              To remove a font manually, just clear the variable (e.g. font1 := "").
         */

         static FR_PRIVATE  := 0x10

         __New(FontFile, FontName="", FontSize=30) {
            if RegExMatch(FontFile, "i)res:\K.*", _FontFile) {
               this.AddFromResource(_FontFile, FontName, FontSize)
            } else {
               this.AddFromFile(FontFile)
            }
         }

         AddFromFile(FontFile) {
            DllCall( "AddFontResourceEx", "Str", FontFile, "UInt", this.FR_PRIVATE, "UInt", 0 )
            this.data := FontFile
         }

         AddFromResource(ResourceName, FontName, FontSize = 30) {
            static FW_NORMAL := 400, DEFAULT_CHARSET := 0x1

            nSize    := this.ResRead(fData, ResourceName)
            fh       := DllCall( "AddFontMemResourceEx", "Ptr", &fData, "UInt", nSize, "UInt", 0, "UIntP", nFonts )
            hFont    := DllCall( "CreateFont", Int,FontSize, Int,0, Int,0, Int,0, UInt,FW_NORMAL, UInt,0
                        , Int,0, Int,0, UInt,DEFAULT_CHARSET, Int,0, Int,0, Int,0, Int,0, Str,FontName )

            this.data := {fh: fh, hFont: hFont}
         }

         ApplyTo(hCtrl) {
            SendMessage, 0x30, this.data.hFont, 1,, ahk_id %hCtrl%
         }

         __Delete() {
            if IsObject(this.data) {
               DllCall( "RemoveFontMemResourceEx", "UInt", this.data.fh    )
               DllCall( "DeleteObject"           , "UInt", this.data.hFont )
            } else {
               DllCall( "RemoveFontResourceEx"   , "Str", this.data, "UInt", this.FR_PRIVATE, "UInt", 0 )
            }
         }

         ; ResRead() By SKAN, from http://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/?p=609282
         ResRead( ByRef Var, Key ) {
            VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
            If ! ( A_IsCompiled ) {
               FileGetSize, nSize, %Key%
               FileRead, Var, *c %Key%
               Return nSize
            }

            If hMod := DllCall( "GetModuleHandle", UInt,0 )
               If hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10 )
                  If hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes )
                     If pData := DllCall( "LockResource", UInt,hData )
                        Return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes ) )
                           ,  DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
            Return 0
         }
      }


      class Image{

         __New(name := "") {
            this.name := name := (name == "") ? Vis2.Graphics.Name() "_Graphics_Image" : name "_Graphics_Image"

            Vis2.Graphics.Startup()
            Gui, %name%: New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndSecretName, % this.name
            Gui, %name%: Show, Hide
            this.hwnd := SecretName
            this.hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            Gdip_SetInterpolationMode(this.G, 7)
         }

         __Delete(){
            Vis2.Graphics.Shutdown()
         }

         Border() {
            Gui, % this.name ":+Border"
         }

         Destroy() {
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            Gui, % this.name ":Destroy"
         }

         Hide() {
            Gui, % this.name ":Show", Hide
         }

         Show() {
            Gui, % this.name ":Show", NoActivate
         }

         ToggleVisible() {
            if DllCall("IsWindowVisible", "UInt", this.hwnd)
               Gui, % this.name ":Show", Hide
            else
               Gui, % this.name ":Show", NoActivate
         }

         isVisible() {
            return DllCall("IsWindowVisible", "UInt", this.hwnd)
         }

         Render(file, scale := 1) {
            Critical
            pBitmap := Gdip_CreateBitmapFromFile(file)
            Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
            Gdip_DrawImage(this.G, pBitmap, 0, 0, Floor(Width*scale), Floor(Height*scale), 0, 0, Width, Height)
            UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, Floor(Width*scale), Floor(Height*scale))
            Gdip_DisposeImage(pBitmap)
         }
      }


      class Subtitle{

         ScreenWidth := A_ScreenWidth, ScreenHeight := A_ScreenHeight

         __New(name := ""){
            this.name := name := (name == "") ? Vis2.Graphics.Name() "_Graphics_Subtitle" : name "_Graphics_Subtitle"

            Vis2.Graphics.Startup()
            Gui, %name%: New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndSecretName, % this.name
            Gui, %name%: Show, NoActivate
            this.hwnd := SecretName
            this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            Gdip_SetSmoothingMode(this.G, 4)
         }

         __Delete(){
            Vis2.Graphics.Shutdown()
         }

         Destroy(){
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            Gui, % this.name ":Destroy"
         }

         Hide(){
            Gui, % this.name ":Show", Hide
         }

         DetectScreenResolutionChange(){
            if (this.ScreenWidth != A_ScreenWidth || this.ScreenHeight != A_ScreenHeight) {
               this.ScreenWidth := A_ScreenWidth, this.ScreenHeight := A_ScreenHeight
               SelectObject(this.hdc, this.obm)
               DeleteObject(this.hbm)
               DeleteDC(this.hdc)
               Gdip_DeleteGraphics(this.G)
               this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
               this.hdc := CreateCompatibleDC()
               this.obm := SelectObject(this.hdc, this.hbm)
               this.G := Gdip_GraphicsFromHDC(this.hdc)
               Gdip_SetSmoothingMode(this.G, 4)
            }
         }

         Render(text:="Alert!", obj1:="", obj2:=""){
            Critical
            if (!this.name){
               note := new Vis2.Graphics.Subtitle()
               return note.Render(text, obj1, obj2)
            }
            G := this.G
            this.text := text
            this.DetectScreenResolutionChange()
            self_destruct := ObjBindMethod(this, "Destroy")
            Gdip_GraphicsClear(G)
            ; BEGIN
            static q1 := "i)^.*?(?<!-|:|:\s)\b"
            static q2 := "(:\s?)?(?<value>[\da-z\.%]+).*$"

            time := (obj1.t) ? obj1.t : (obj1.time) ? obj1.time
                  : (!IsObject(obj1) && (___ := RegExReplace(obj1, q1 "(t(ime)?)" q2, "${value}")) != obj1) ? ___
                  : (obj2.t) ? obj2.t : (obj2.time) ? obj2.time
                  : (!IsObject(obj2) && (___ := RegExReplace(obj2, q1 "(t(ime)?)" q2, "${value}")) != obj2) ? ___
                  : 0

            SetTimer, % self_destruct, % (time) ? -1 * time : "Delete"

            static alpha := "^[A-Za-z]+$"
            static colorRGB := "^0x([0-9A-Fa-f]{6})$"
            static colorARGB := "^0x([0-9A-Fa-f]{8})$"
            static hex6 := "^([0-9A-Fa-f]{6})$"
            static hex8 := "^([0-9A-Fa-f]{8})$"
            static decimal := "^(\-?[\d\.]+)$"
            static integer := "^\d+$"
            static percentage := "^(\-?[\d\.]+)%$"
            static positive := "^[\d\.]+$"

            if IsObject(obj1){
               _x  := (obj1.x)  ? obj1.x  : obj1.left
               _y  := (obj1.y)  ? obj1.y  : obj1.top
               _w  := (obj1.w)  ? obj1.w  : obj1.width
               _h  := (obj1.h)  ? obj1.h  : obj1.height
               _r  := (obj1.r)  ? obj1.r  : obj1.radius
               _c  := (obj1.c)  ? obj1.c  : obj1.color
               _m  := (obj1.m)  ? obj1.m  : obj1.margin
               _p  := (obj1.p)  ? obj1.p  : obj1.padding
            } else {
               _x  := ((___ := RegExReplace(obj1, q1    "(x|left)"               q2, "${value}")) != obj1) ? ___ : ""
               _y  := ((___ := RegExReplace(obj1, q1    "(y|top)"                q2, "${value}")) != obj1) ? ___ : ""
               _w  := ((___ := RegExReplace(obj1, q1    "(w(idth)?)"             q2, "${value}")) != obj1) ? ___ : ""
               _h  := ((___ := RegExReplace(obj1, q1    "(h(eight)?)"            q2, "${value}")) != obj1) ? ___ : ""
               _r  := ((___ := RegExReplace(obj1, q1    "(r(adius)?)"            q2, "${value}")) != obj1) ? ___ : ""
               _c  := ((___ := RegExReplace(obj1, q1    "(c(olor)?)"             q2, "${value}")) != obj1) ? ___ : ""
               _m  := ((___ := RegExReplace(obj1, q1    "(m(argin)?)"            q2, "${value}")) != obj1) ? ___ : ""
               _p  := ((___ := RegExReplace(obj1, q1    "(p(adding)?)"           q2, "${value}")) != obj1) ? ___ : ""
            }

            if IsObject(obj2){
               x  := (obj2.x)  ? obj2.x  : obj2.left
               y  := (obj2.y)  ? obj2.y  : obj2.top
               w  := (obj2.w)  ? obj2.w  : obj2.width
               h  := (obj2.h)  ? obj2.h  : obj2.height
               m  := (obj2.m)  ? obj2.m  : obj2.margin
               f  := (obj2.f)  ? obj2.f  : obj2.font
               s  := (obj2.s)  ? obj2.s  : obj2.size
               c  := (obj2.c)  ? obj2.c  : obj2.color
               b  := (obj2.b)  ? obj2.b  : obj2.bold
               i  := (obj2.i)  ? obj2.i  : obj2.italic
               u  := (obj2.u)  ? obj2.u  : obj2.underline
               j  := (obj2.j)  ? obj2.j  : obj2.justify
               q  := (obj2.q)  ? obj2.q  : obj2.quality
               n  := (obj2.n)  ? obj2.n  : obj2.noWrap
               z  := (obj2.z)  ? obj2.z  : obj2.condensed
            } else {
               x  := ((___ := RegExReplace(obj2, q1    "(x|left)"               q2, "${value}")) != obj2) ? ___ : ""
               y  := ((___ := RegExReplace(obj2, q1    "(y|top)"                q2, "${value}")) != obj2) ? ___ : ""
               w  := ((___ := RegExReplace(obj2, q1    "(w(idth)?)"             q2, "${value}")) != obj2) ? ___ : ""
               h  := ((___ := RegExReplace(obj2, q1    "(h(eight)?)"            q2, "${value}")) != obj2) ? ___ : ""
               m  := ((___ := RegExReplace(obj2, q1    "(m(argin)?)"            q2, "${value}")) != obj2) ? ___ : ""
               f  := ((___ := RegExReplace(obj2, q1    "(f(ont)?)"              q2, "${value}")) != obj2) ? ___ : ""
               s  := ((___ := RegExReplace(obj2, q1    "(s(ize)?)"              q2, "${value}")) != obj2) ? ___ : ""
               c  := ((___ := RegExReplace(obj2, q1    "(c(olor)?)"             q2, "${value}")) != obj2) ? ___ : ""
               b  := ((___ := RegExReplace(obj2, q1    "(b(old)?)"              q2, "${value}")) != obj2) ? ___ : ""
               i  := ((___ := RegExReplace(obj2, q1    "(i(talic)?)"            q2, "${value}")) != obj2) ? ___ : ""
               u  := ((___ := RegExReplace(obj2, q1    "(u(nderline)?)"         q2, "${value}")) != obj2) ? ___ : ""
               j  := ((___ := RegExReplace(obj2, q1    "(j(ustify)?)"           q2, "${value}")) != obj2) ? ___ : ""
               q  := ((___ := RegExReplace(obj2, q1    "(q(uality)?)"           q2, "${value}")) != obj2) ? ___ : ""
               n  := ((___ := RegExReplace(obj2, q1    "(n(oWrap)?)"            q2, "${value}")) != obj2) ? ___ : ""
               z  := ((___ := RegExReplace(obj2, q1    "(z|condensed?)"         q2, "${value}")) != obj2) ? ___ : ""
            }

            ; Simulate string width and height, setting only the variables we need to determine it.
            style += (b) ? 1 : 0    ; bold
            style += (i) ? 2 : 0    ; italic
            style += (u) ? 4 : 0    ; underline
            style += (strike) ? 8 : ; strikeout, not implemented.
            s  := ( s  ~= percentage) ? A_ScreenHeight * RegExReplace( s, percentage, "$1")  // 100 :  s

            ;TextRenderingHintAntiAlias                  = 4,
            ;TextRenderingHintClearTypeGridFit           = 5
            Gdip_SetTextRenderingHint(G, (q >= 0 && q <= 5) ? q : 4)
            hFamily := (___ := Gdip_FontFamilyCreate(f)) ? ___ : Gdip_FontFamilyCreate("Arial")
            hFont := Gdip_FontCreate(hFamily, (s ~= positive) ? s : 36, style)
            hFormat := Gdip_StringFormatCreate((n) ? 0x4000 | 0x1000 : 0x4000)
            Gdip_SetStringFormatAlign(hFormat, (j = "left") ? 0 : (j = "center") ? 1 : (j = "right") ? 2 : 0)

            CreateRectF(RC, 0, 0, 0, 0)
            ReturnRC := Gdip_MeasureString(G, Text, hFont, hFormat, RC)
            ReturnRC := StrSplit(ReturnRC, "|")

            ; Set default dimensions for background, if left blank.
            _x  := (_x  != "") ? _x : "center"
            _y  := (_y  != "") ? _y : "center"
            _w  := (_w) ? _w  : ReturnRC[3]
            _h  := (_h) ? _h  : ReturnRC[4]

            ; Condense Text using a Condensed Font if simulated text width exceeds screen width.
            if (z && ReturnRC[3] > 0.95*A_ScreenWidth){
               hFamily := (___ := Gdip_FontFamilyCreate(z)) ? ___ : Gdip_FontFamilyCreate("Arial Narrow")
               hFont := Gdip_FontCreate(hFamily, (s ~= positive) ? s : 36, style)
               ReturnRC := Gdip_MeasureString(G, Text, hFont, hFormat, RC)
               ReturnRC := StrSplit(ReturnRC, "|")
               _w  := ReturnRC[3]
            }

            ; Relative to A_ScreenHeight or A_ScreenWidth
            _x  := (_x  ~= percentage) ? A_ScreenWidth  * RegExReplace(_x, percentage, "$1")  // 100 : _x
            _y  := (_y  ~= percentage) ? A_ScreenHeight * RegExReplace(_y, percentage, "$1")  // 100 : _y
            _w  := (_w  ~= percentage) ? A_ScreenWidth  * RegExReplace(_w, percentage, "$1")  // 100 : _w
            _h  := (_h  ~= percentage) ? A_ScreenHeight * RegExReplace(_h, percentage, "$1")  // 100 : _h
            _m  := (_m  ~= percentage) ? A_ScreenHeight * RegExReplace(_m, percentage, "$1")  // 100 : _m
            _p  := (_p  ~= percentage) ? A_ScreenHeight * RegExReplace(_p, percentage, "$1")  // 100 : _p

            ; Relative to Background width of height
            _smaller := (_w > _h) ? _h : _w
            _r  := (_r  ~= percentage) ? _smaller * RegExReplace(_r, percentage, "$1")  // 100 : _r
             x  := ( x  ~= percentage) ? _x + (_w * RegExReplace( x, percentage, "$1"))  // 100 : x
             y  := ( y  ~= percentage) ? _y + (_h * RegExReplace( y, percentage, "$1"))  // 100 : y
             w  := ( w  ~= percentage) ? _w * RegExReplace( w, percentage, "$1")  // 100 : w
             h  := ( h  ~= percentage) ? _h * RegExReplace( h, percentage, "$1")  // 100 : h
             m  := ( m  ~= percentage) ? _w * RegExReplace( m, percentage, "$1")  // 100 : m


            ; Resolving ambiguous inputs to non-ambiguous outputs.
            _x  := (_x = "left") ? 0 : (_x ~= "i)cent(er|re)") ? 0.5*(A_ScreenWidth - _w) : (_x = "right") ? A_ScreenWidth - _w : _x
            _y  := (_y = "top") ? 0 : (_y ~= "i)cent(er|re)") ? 0.5*(A_ScreenHeight - _h) : (_y = "bottom") ? A_ScreenHeight - _h : _y
            _c  := (_c  ~= colorRGB) ? "0xff" RegExReplace(_c, colorRGB, "$1") : (_c ~= hex8) ? "0x" _c : (_c ~= hex6) ? "0xff" _c : _c
             c  := ( c  ~= colorRGB) ? "0xff" RegExReplace( c, colorRGB, "$1") : ( c ~= hex8) ? "0x"  c : ( c ~= hex6) ? "0xff"  c :  c
             x  := ( x = "left") ? _x : (x ~= "i)cent(er|re)") ? _x + 0.5*(_w - ReturnRC[3]) : (x = "right") ? _x + _w - ReturnRC[3] : x
             y  := ( y = "top") ? _y : (y ~= "i)cent(er|re)") ? _y + 0.5*(_h - ReturnRC[4]) : (y = "bottom") ? _y + _h - ReturnRC[4] : y

            ; Detecting non-standard inputs (if any) and set them to default values.
            _x  := (_x  ~= decimal) ? _x  : 0
            _y  := (_y  ~= decimal) ? _y  : 0
            _m  := (_m  ~= positive) ? _m  : 0
            _r  := (_r  <= _smaller // 2 && _r ~= positive) ? _r : 0
            _c  := (_c  ~= colorARGB) ? _c  : 0xdd424242
             c  := ( c  ~= colorARGB) ?  c  : 0xffffffff
             m  := ( m  ~= positive) ?  m : 0
             x  := ( x  ~= decimal) ? x : _x + 0.5*(_w - ReturnRC[3])
             y  := ( y  ~= decimal) ? y : _y + 0.5*(_h - ReturnRC[4])
             w  := ( w  ~= positive) ? w : ReturnRC[3]
             h  := ( h  ~= positive) ? h : ReturnRC[4]

            ; Set Margin
            _x  -= m
            _y  -= m
            _w  += 2*m
            _h  += 2*m

            _x  -= _m
            _y  -= _m
            _w  += 2*_m
            _h  += 2*_m

            _x  -= _p
            _y  -= _p
            _w  += 2*_p
            _h  += 2*_p

            ; Draw Background
            pBrushBackground := Gdip_BrushCreateSolid(_c)
            Gdip_FillRoundedRectangle(G, pBrushBackground, _x, _y, _w, _h, _r)
            Gdip_DeleteBrush(pBrushBackground)

            ; Draw Text
            CreateRectF(RC, x, y, w, h)
            pBrushText := Gdip_BrushCreateSolid(c)
            Gdip_DrawString(G, Text, hFont, hFormat, pBrushText, RC)
            Gdip_DeleteBrush(pBrushText)

            ; Complete
            Gdip_DeleteStringFormat(hFormat)
            Gdip_DeleteFont(hFont)
            Gdip_DeleteFontFamily(hFamily)
            ; END
            UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.ScreenWidth, this.ScreenHeight)
            ;Tooltip % "x:`t" _x "`tw:`t" _w "`ny:`t" _y "`th:`t" _h "`n" x ", " y "`n" w ", " h
            return this, this.x := _x, this.y := _y, this.w := _w, this.h := _h
         }

         x1(){
            return this.x
         }

         y1(){
            return this.y
         }

         x2(){
            return this.x + this.w
         }

         y2(){
            return this.y + this.h
         }

         width(){
            return this.w
         }

         height(){
            return this.h
         }
      }
   }
}
