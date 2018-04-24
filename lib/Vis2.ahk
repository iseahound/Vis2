; Script:    Vis2.ahk
; Author:    iseahound
; Version:   2017-08-19
; Recent:    2018-04-04

#include <Gdip_All>    ; https://goo.gl/rUuEF5
#include <JSON>        ; https://goo.gl/MAsQDe


; Describe() - Creates a phrase that best describes the image.
Describe(image:="", option:="", crop:=""){
   return Vis2.Describe(image, option, crop)
}

; ExplicitContent() - Detect offensive or inappropriate content.
ExplicitContent(image:="", option:="", crop:=""){
   return Vis2.ExplicitContent(image, option, crop)
}

; FindFaces() - Detect faces in images.
FindFaces(image:="", option="", crop:=""){
   return Vis2.FindFaces(image, option, crop)
}

; ImageIdentify() - Name and identify objects in images.
ImageIdentify(image:="", option:="", crop:=""){
   return Vis2.ImageIdentify(image, option, crop)
}

; TextRecognize() - Convert pictures of text into text.
TextRecognize(image:="", option:="", crop:=""){
   return Vis2.TextRecognize(image, option, crop)
}
; Alias for TextRecognize()
OCR(image:="", option:="", crop:=""){
   return Vis2.TextRecognize(image, option, crop)
}


class Vis2 {

   class Describe extends Vis2.functor {
      call(self, image:="", obj:="", crop:=""){
         Vis2.provider.listAll("Describe").SelectBest()
         return (image != "") ? (new Vis2.provider.Google()).ImageIdentify(image, search, crop)
            : Vis2.core.returnData({"provider":(new Vis2.provider.Google(search)), "tooltip":"Image Identification Tool", "splashImage":true})
      }
   }

   class ExplicitContent extends Vis2.functor {

   }

   class FindFaces extends Vis2.functor {

   }

   class ImageIdentify extends Vis2.functor {
      static rank := ["Google", "IBM"]

      call(self, image:="", option:="", crop:=""){
         for i, provider in this.rank {
            try {
               test := Vis2.provider[provider].ImageIdentify(image, option, crop)
            }
            catch e {
               this.rank.removeAt(i)
            }
            if (test != "")
               return test
         }
      }
   }

   class TextRecognize extends Vis2.functor {
      call(self, image:="", option:="", crop:=""){
         return (image != "") ? (new Vis2.provider.Tesseract()).OCR(image, option, crop)
            : Vis2.core.returnData({"provider":(new Vis2.provider.Tesseract(option)), "tooltip":"Optical Character Recognition Tool", "textPreview":true})
      }

      google(){
         return (image != "") ? (new Vis2.provider.Tesseract()).OCR(image, language, crop).google()
            : Vis2.core.returnData({"provider":(new Vis2.provider.Tesseract(language)), "tooltip":"Any selected text will be Googled.", "textPreview":true, "noCopy":true}).google()
      }
   }

   class core {

      ; returnData() is a wrapper function of Vis2.core.ux.start()
      ; Unlike Vis2.core.ux.start(), this function will return a string of text.
      ; You'll need a provider: Vis2.core.returnData({"provider":new Vis2.provider.Tesseract.TextRecognize()})
      returnData(obj){
         obj.callback := "returnData"
         if (error := Vis2.core.ux.start(obj))
            return error
         while !(EXITCODE := Vis2.obj.EXITCODE)
            Sleep 10
         data := Vis2.obj.data
         Vis2.obj.callbackConfirmed := true ; Deletes Vis2.obj
         return (EXITCODE > 0) ? data : EXITCODE
      }

      class ux {

         ; start() is the function that launches the user interface.
         ; This can be called directly without calling Vis2.core.returnData().
         ; You'll need a provider: Vis2.core.ux.start({"provider":new Vis2.provider.Tesseract.TextRecognize()})
         start(obj){
         static void := ObjBindMethod({}, {})

            if (Vis2.obj != "")
               return "Already in use."

            if !IsObject(obj.provider)
               return "Provider required."

            Vis2.Graphics.Startup()
            Vis2.stdlib.setSystemCursor(32515) ; IDC_Cross := 32515
            Hotkey, LButton, % void, On
            Hotkey, ^LButton, % void, On
            Hotkey, !LButton, % void, On
            Hotkey, +LButton, % void, On
            Hotkey, RButton, % void, On
            Hotkey, Escape, % void, On

            Vis2.obj := obj
            Vis2.obj.EXITCODE := 0 ; -2 = blank data; -1 = escape; 0 = in progress; 1 = success
            Vis2.obj.selectMode := "Quick"
            Vis2.obj.area := new Vis2.Graphics.Area("Vis2_Aries", "0x7FDDDDDD")
            Vis2.obj.picture := new Vis2.Graphics.Picture("Vis2_Kitsune").Hide()
            Vis2.obj.subtitle := new Vis2.Graphics.Subtitle("Vis2_Hermes")

            Vis2.obj.style1_back := {"x":"center", "y":"83%", "padding":"1.35%", "color":"DD000000", "radius":8}
            Vis2.obj.style1_text := {"q":4, "size":"2.23%", "font":"Arial", "z":"Arial Narrow", "justify":"left", "color":"White"}
            Vis2.obj.style2_back := {"x":"center", "y":"83%", "padding":"1.35%", "color":"FF88EAB6", "radius":8}
            Vis2.obj.style2_text := {"q":4, "size":"2.23%", "font":"Arial", "z":"Arial Narrow", "justify":"left", "color":"Black"}
            Vis2.obj.subtitle.render(Vis2.obj.tooltip, Vis2.obj.style1_back, Vis2.obj.style1_text)

            Vis2.obj.timer := {}
            Vis2.obj.timer.selectImage := ObjBindMethod(Vis2.core.ux.process, "selectImage")
            Vis2.obj.timer.textPreview := ObjBindMethod(Vis2.core.ux.process, "textPreview")

            return Vis2.core.ux.waitForUserInput()
         }

         waitForUserInput(){
         static escape := ObjBindMethod(Vis2.core.ux, "escape")
         static waitForUserInput := ObjBindMethod(Vis2.core.ux, "waitForUserInput")
         selectImage := Vis2.obj.timer.selectImage
         textPreview := Vis2.obj.timer.TextPreview

            if (GetKeyState("Escape", "P")) {
               Vis2.obj.EXITCODE := -1
               SetTimer, % escape, -9
               return
            }
            else if (GetKeyState("LButton", "P")) {
               SetTimer, % selectImage, 10
               if (Vis2.obj.textPreview) {
                  Vis2.obj.subtitle.render("Searching for data...", Vis2.obj.style1_back, Vis2.obj.style1_text)
                  SetTimer, % textPreview, 500
               }
               else
                  Vis2.obj.subtitle.render("Waiting for user selection...", Vis2.obj.style2_back, Vis2.obj.style2_text)
            }
            else {
               Vis2.obj.area.origin()
               SetTimer, % waitForUserInput, -10
            }
            return
         }

         class process {

            selectImage(){
            selectImage := Vis2.obj.timer.selectImage

               if (GetKeyState("Escape", "P")) {
                  Vis2.obj.EXITCODE := -1
                  SetTimer, % selectImage, Off
                  return Vis2.core.ux.process.treasureChest(A_ThisFunc)
               }

               if (Vis2.obj.selectMode == "Quick")
                  Vis2.core.ux.process.selectImageQuick()
               if (Vis2.obj.selectMode == "Advanced")
                  Vis2.core.ux.process.selectImageAdvanced()

               Vis2.core.ux.display()
               return
            }

            selectImageQuick(){
            selectImage := Vis2.obj.timer.selectImage

               if (GetKeyState("LButton", "P")) {
                  if (GetKeyState("Control", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P"))
                     Vis2.core.ux.process.selectImageTransition()
                  else if (GetKeyState("RButton", "P")) {
                     Vis2.obj.area.move()
                     if (!Vis2.obj.area.isMouseOnCorner() && Vis2.obj.area.isMouseStopped())
                        Vis2.obj.area.draw() ; Error Correction of Offset
                  }
                  else
                     Vis2.obj.area.draw()
               }
               else {
                  SetTimer, % selectImage, Off
                  return Vis2.core.ux.process.treasureChest(A_ThisFunc)
               }
               ; Do not return.
            }

            selectImageTransition(){
            static void := ObjBindMethod({}, {})

               DllCall("SystemParametersInfo", "uInt",0x57, "uInt",0, "uInt",0, "uInt",0) ; RestoreCursor()
               Hotkey, Space, % void, On
               Hotkey, ^Space, % void, On
               Hotkey, !Space, % void, On
               Hotkey, +Space, % void, On
               Vis2.obj.note_01 := Vis2.Graphics.Subtitle.Render("Advanced Mode", "time: 2500, xCenter y75% p1.35% cFFB1AC r8", "c000000 s2.23%")
               Vis2.obj.tokenMousePressed := 1
               Vis2.obj.selectMode := "Advanced" ; Exit selectImageQuick.
               Vis2.obj.key := {}
               Vis2.obj.action := {}
            }

            selectImageAdvanced(){
            static void := ObjBindMethod({}, {})
            selectImage := Vis2.obj.timer.selectImage

               if ((Vis2.obj.area.width() < -25 || Vis2.obj.area.height() < -25) && !Vis2.obj.note_02)
                  Vis2.obj.note_02 := Vis2.Graphics.Subtitle.Render("Press Alt + LButton to create a new selection anywhere on screen", "time: 6250, x: center, y: 67%, p1.35%, c: FCF9AF, r8", "c000000 s2.23%")

               Vis2.obj.key.LButton := GetKeyState("LButton", "P") ? 1 : 0
               Vis2.obj.key.RButton := GetKeyState("RButton", "P") ? 1 : 0
               Vis2.obj.key.Space   := GetKeyState("Space", "P")   ? 1 : 0
               Vis2.obj.key.Control := GetKeyState("Control", "P") ? 1 : 0
               Vis2.obj.key.Alt     := GetKeyState("Alt", "P")     ? 1 : 0
               Vis2.obj.key.Shift   := GetKeyState("Shift", "P")   ? 1 : 0

               ; Check if mouse is inside on activation.
               Vis2.obj.action.Control_LButton := (Vis2.obj.area.isMouseInside() && Vis2.obj.key.Control && Vis2.obj.key.LButton)
                  ? 1 : (Vis2.obj.key.Control && Vis2.obj.key.LButton) ? Vis2.obj.action.Control_LButton : 0
               Vis2.obj.action.Shift_LButton   := (Vis2.obj.area.isMouseInside() && Vis2.obj.key.Shift && Vis2.obj.key.LButton)
                  ? 1 : (Vis2.obj.key.Shift && Vis2.obj.key.LButton) ? Vis2.obj.action.Shift_LButton : 0
               Vis2.obj.action.LButton         := (Vis2.obj.area.isMouseInside() && Vis2.obj.key.LButton)
                  ? 1 : (Vis2.obj.key.LButton) ? Vis2.obj.action.LButton : 0
               Vis2.obj.action.RButton         := (Vis2.obj.area.isMouseInside() && Vis2.obj.key.RButton)
                  ? 1 : (Vis2.obj.key.RButton) ? Vis2.obj.action.RButton : 0

               ;___|¯¯¯|___ 00011111000 Keypress
               ;___|_______ 0001----000 Activation Function (pseudo heaviside)
               Vis2.obj.action.Control_Space   := (Vis2.obj.key.Control && Vis2.obj.key.Space)
                  ? ((!Vis2.obj.action.Control_Space) ? 1 : -1) : 0
               Vis2.obj.action.Alt_Space       := (Vis2.obj.key.Alt && Vis2.obj.key.Space)
                  ? ((!Vis2.obj.action.Alt_Space) ? 1 : -1) : 0
               Vis2.obj.action.Shift_Space     := (Vis2.obj.key.Shift && Vis2.obj.key.Space)
                  ? ((!Vis2.obj.action.Shift_Space) ? 1 : -1) : 0
               Vis2.obj.action.Alt_LButton     := (Vis2.obj.key.Alt && Vis2.obj.key.LButton)
                  ? ((!Vis2.obj.action.Alt_LButton) ? 1 : -1) : 0

               ; Ensure only Space is pressed.
               Vis2.obj.action.Space := (Vis2.obj.key.Space && !Vis2.obj.key.Control && !Vis2.obj.key.Alt && !Vis2.obj.key.Shift)
                  ? ((!Vis2.obj.action.Space) ? 1 : -1) : 0

               ; Space Hotkeys
               if (Vis2.obj.action.Control_Space = 1){
                  Vis2.obj.picture.render(Vis2.obj.preprocess, 0.5)
                  Vis2.obj.picture.toggleVisible()
               } else if (Vis2.obj.action.Alt_Space = 1){
                  Vis2.obj.area.toggleCoordinates()
               } else if (Vis2.obj.action.Shift_Space = 1){

               } else if (Vis2.obj.action.Space = 1) {
                  SetTimer, % selectImage, Off
                  return Vis2.core.ux.process.treasureChest(A_ThisFunc) ; Exit function.
               }

               ; Mouse Hotkeys
               if (Vis2.obj.action.Control_LButton)
                  Vis2.obj.area.resizeCorners()
               else if (Vis2.obj.action.Alt_LButton = 1)
                  Vis2.obj.area.origin()
               else if (Vis2.obj.action.Alt_LButton = -1)
                  Vis2.obj.area.draw()
               else if (Vis2.obj.action.Shift_LButton)
                  Vis2.obj.area.resizeEdges()
               else if (Vis2.obj.action.LButton || Vis2.obj.action.RButton)
                  Vis2.obj.area.move()
               else {
                  Vis2.obj.area.hover() ; Collapse Stack
                  if Vis2.obj.area.isMouseInside() {
                     Hotkey, LButton, % void, On
                     Hotkey, RButton, % void, On
                  } else {
                     Hotkey, LButton, % void, Off
                     Hotkey, RButton, % void, Off
                  }
               }
               ; Do not return.
            }

            textPreview(bypass:=""){
            textPreview := Vis2.obj.timer.TextPreview

               ; The bypass parameter is normally used when textPreview (preview text on bottom) is off.
               if (bypass || Vis2.obj.textPreview) {
                  ; Check for valid coordinates, returns "" if invalid.
                  if (coordinates := Vis2.obj.Area.ScreenshotRectangle()) {
                     ; Sometimes a user will make the subtitle blink from top to bottom. If so, hide subtitle temporarily.
                     (overlap := Vis2.core.ux.overlap()) ? Vis2.obj.subtitle.hide() : ""
                     pBitmap := Gdip_BitmapFromScreen(coordinates) ; To avoid the grey tint, call Area.Hide() but this will cause flickering.
                     (overlap) ? Vis2.obj.subtitle.show() : ""

                     ; If any x,y,w,h coordinates are different, or the image has changed (like video), proceed.
                     if (bypass || coordinates != Vis2.obj.coordinates || !Vis2.obj.picture.isBitmapEqual(pBitmap, Vis2.obj.pBitmap)) {

                        try {
                           Vis2.obj.preprocess := Vis2.obj.provider.preprocess({"pBitmap":pBitmap}) ; Declare type as pBitmap
                           if (Vis2.obj.picture.isVisible() == true)
                              Vis2.obj.picture.render(Vis2.obj.preprocess, 0.5)
                           Vis2.obj.data := Vis2.obj.provider.convert(Vis2.obj.preprocess, Vis2.obj.option, 100)
                        }
                        catch e {
                           MsgBox, 16,, % "Exception thrown!`n`nwhat: " e.what "`nfile: " e.file
                              . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra "`ncoordinates: " coordinates
                        }

                        ; Do not update last coordinates (space) and last pBitmap (time) until conversion finishes.
                        ; In Vis2.core.ux.process.treasureChest(), Vis2.obj.coordinates will be compared to user's mouse release.
                        if (Vis2.obj.pBitmap)
                           Gdip_DisposeImage(Vis2.obj.pBitmap)
                        Vis2.obj.coordinates := coordinates
                        Vis2.obj.pBitmap := pBitmap

                        if !(bypass)
                           Vis2.core.ux.display((Vis2.obj.data.maxLines(3)) ? Vis2.obj.data.maxLines(3) : "ERROR: No Text Data Found")

                     }
                     else { ; This is an identical image, so delete it.
                        Gdip_DisposeImage(pBitmap)
                     }
                  }
               }

               if (Vis2.obj.unlock.1 && !Vis2.obj.unlock.2) {
                  SetTimer, % textPreview, Off
                  return Vis2.core.ux.process.treasureChest(A_ThisFunc)
               }
               return
            }

            treasureChest(key){
               ; Create an "unlock" object with two vacancies that will be filled when SelectImage and TextPreview return.
               (IsObject(Vis2.obj.unlock) && key != Vis2.obj.unlock.1) ? Vis2.obj.unlock.push(key) : (Vis2.obj.unlock := [key])

               ; SelectImage returns. If TextPreview was not started, start it now or escape depending on the exit code.
               if (key ~= "^Vis2.core.ux.process.selectImage") {
                  Vis2.obj.Area.ChangeColor(0x01FFFFFF) ; Lighten Area object, but do not hide or delete it until key up.
                  if (!Vis2.obj.textPreview){
                     if (Vis2.obj.EXITCODE == -1)
                        return Vis2.core.ux.escape()
                     if (Vis2.obj.EXITCODE == 0) {
                        Vis2.obj.subtitle.render("Processing using " RegExReplace(Vis2.obj.provider.__class, ".*\.(.*)\.(.*)$", "$1's $2()..."), Vis2.obj.style2_back, Vis2.obj.style2_text)
                        return Vis2.core.ux.process.textPreview("bypass")
                     }
                  } else {
                     ; If user's final coordinates and last processed coordinates are the same:
                     ; Do an early exit. Don't wait for the in progress textPreview to return. Skip that.
                     if (Vis2.obj.area.screenshotRectangle() == Vis2.obj.coordinates)
                        return Vis2.core.ux.finale()
                  }
               }

               ; TextPreview returns.
               if (Vis2.obj.unlock.maxIndex() == 2) {
                  if (Vis2.obj.EXITCODE == 0) {
                     ; Even though TextPreview has returned, make sure that the area coordinates when the mouse was released
                     ; are equal to the coordinates that were sent to the last iteration of TextPreview.
                     if (Vis2.obj.area.screenshotRectangle() != Vis2.obj.coordinates)
                        Vis2.core.ux.process.textPreview("bypass")

                     Vis2.core.ux.finale()
                  }
                  return Vis2.core.ux.escape()
               }
               return
            }
         }

         display(text := "", backgroundStyle := "", textStyle := ""){
            if (overlap := Vis2.core.ux.overlap()) {
                Vis2.obj.style1_back.y := (Vis2.obj.style1_back.y == "83%") ? "2.07%" : "83%"
                Vis2.obj.style2_back.y := (Vis2.obj.style2_back.y == "83%") ? "2.07%" : "83%"
            }

            if (text != "")
               Vis2.obj.displayText := text

            if (text != "" || overlap) {
               if (Vis2.obj.textPreview)
                  Vis2.obj.subtitle.render(Vis2.obj.displayText, Vis2.obj.style1_back, Vis2.obj.style1_text)
               else
                  Vis2.obj.subtitle.render("Still patiently waiting for user selection...", Vis2.obj.style2_back, Vis2.obj.style2_text)
            }
         }

         finale(){
            if (Vis2.obj.EXITCODE == 0) { ; Make sure escape (-1) isn't called.
               if (Vis2.obj.data != "") {
                  if (Vis2.obj.noCopy != true) {
                     clipboard := Vis2.obj.data
                     t := 2500
                     if (Vis2.obj.splashImage == true) {
                        t := 5000
                        Vis2.Graphics.Picture.Render(Vis2.obj.provider.imageData, "time:5000 x:center y:center margin:0.926vmin", Vis2.obj.data.FullData)
                     }
                     Vis2.obj.Subtitle.Hide()
                     if (Vis2.obj.splashImage = "csv"){
                        for i, value in Vis2.obj.data.FullData {
                           category .= ((A_Index == 1) ? "" : "`r`n`r`n") . value.category
                           score    .= ((A_Index == 1) ? "" : "`r`n`r`n") . Format("{:#.3f}", value.score)
                        }
                        p := new Vis2.Graphics.Subtitle()
                        p.Draw(category, "time:" 10000 " c:DD000000 x:Left y:Top w:20vw h:100vh", "c:White x:1.5vw y:2.95vh f:Arial size:2.23vmin j:left margin:()", p.G)
                        for i, value in Vis2.obj.data.FullData {
                           y += 0.05145 * A_ScreenHeight
                           width := value.score * 0.17 * A_ScreenWidth
                           p.Draw("", " c:NavajoWhite x:1.5vw y:" y " w: 17vw h:0.7vh",, p.G)
                           p.Draw("", " c:DodgerBlue x:1.5vw y:" y " w:" width " h:0.7vh",, p.G)
                        }
                        p.Render("uigugugiugig;iug`nhfyfjyfjyfjyfyjfjyfjyfjyfjyfjyfjyfj", "c:Black x:Center y:Top w:20vw h:100vh", "a:right c:White f:Arial size:2.23vmin j:right", p.G)
                     }
                     else
                        Vis2.Graphics.Subtitle.Render(Vis2.obj.data.maxLines(3), "time:" t " x:center y:83% padding:1.35% c:Black radius:8", "size:2.23% f:(Arial) z:(Arial Narrow) j:left c:White")
                     Vis2.Graphics.Subtitle.Render("Saved to Clipboard.", "time: " t ", x: center, y: 75%, p: 1.35%, c: F9E486, r: 8", "c: 0x000000, s:2.23%, f:Arial")
                  }
                  Vis2.obj.EXITCODE := 1  ; Success.
               } else {
                  Vis2.obj.EXITCODE := -2 ; Error: No Text Data Found
               }
            }
         }

         escape(){
         static escape := ObjBindMethod(Vis2.core.ux, "escape")
         static void := ObjBindMethod({}, {})

            if (Vis2.obj.callback) {
               if !(Vis2.obj.callbackConfirmed) {
                  SetTimer, % escape, -9
                  return
               }
            }

            ; Fixes a bug where AHK does not detect key releases if there is an admin-level window beneath.
            ; This code must be positioned before Vis2.obj.area.destroy().
            if WinActive("ahk_id" Vis2.obj.area.hwnd) {
               KeyWait Control
               KeyWait Alt
               KeyWait Shift
               KeyWait RButton
               KeyWait LButton
               KeyWait Space
               KeyWait Escape
            }

            Gdip_DisposeImage(Vis2.obj.pBitmap)
            Vis2.obj.area.destroy()
            Vis2.obj.picture.destroy()
            Vis2.obj.subtitle.destroy()
            Vis2.obj.note_01.hide() ; Let them time out instead of Destroy()
            Vis2.obj.note_02.destroy()
            Vis2.obj := "" ; Goodbye all, you were loved :c
            Vis2.Graphics.Shutdown()

            Hotkey, LButton, % void, Off
            Hotkey, ^LButton, % void, Off
            Hotkey, !LButton, % void, Off
            Hotkey, +LButton, % void, Off
            Hotkey, RButton, % void, Off
            Hotkey, Escape, % void, Off
            Hotkey, Space, % void, Off
            Hotkey, ^Space, % void, Off
            Hotkey, !Space, % void, Off
            Hotkey, +Space, % void, Off

            return DllCall("SystemParametersInfo", "uInt",0x57, "uInt",0, "uInt",0, "uInt",0) ; RestoreCursor()
         }

         overlap() {
            p1 := Vis2.obj.area.x1()
            p2 := Vis2.obj.area.x2()
            r1 := Vis2.obj.area.y1()
            r2 := Vis2.obj.area.y2()

            q1 := Vis2.obj.subtitle.x1()
            q2 := Vis2.obj.subtitle.x2()
            s1 := Vis2.obj.subtitle.y1()
            s2 := Vis2.obj.subtitle.y2()

            a := (p1 < q1 && q1 < p2) || (p1 < q2 && q2 < p2) || (q1 < p1 && p1 < q2) || (q1 < p2 && p2 < q2)
            b := (r1 < s1 && s1 < r2) || (r1 < s2 && s2 < r2) || (s1 < r1 && r1 < s2) || (s1 < r2 && r2 < s2)

            ;Tooltip % a "`t" b "`n`n" p1 "`t" r1 "`n" p2 "`t" r2 "`n`n" q1 "`t" s1 "`n" q2 "`t" s2
            return (a && b)
         }

         suspend(){
            static void := ObjBindMethod({}, {})
            Hotkey, LButton, % void, Off
            Hotkey, ^LButton, % void, Off
            Hotkey, !LButton, % void, Off
            Hotkey, +LButton, % void, Off
            Hotkey, RButton, % void, Off
            Hotkey, Escape, % void, Off
            Hotkey, Space, % void, Off
            Hotkey, ^Space, % void, Off
            Hotkey, !Space, % void, Off
            Hotkey, +Space, % void, Off
            DllCall("SystemParametersInfo", "uInt",0x57, "uInt",0, "uInt",0, "uInt",0) ; RestoreCursor
            Vis2.obj.area.hide()
            return
         }

         resume(){
            Hotkey, LButton, % void, On
            Hotkey, ^LButton, % void, On
            Hotkey, !LButton, % void, On
            Hotkey, +LButton, % void, On
            Hotkey, RButton, % void, On
            Hotkey, Escape, % void, On

            if (Vis2.obj.selectMode == "Quick")
               Vis2.stdlib.setSystemCursor(32515) ; IDC_Cross := 32515

            if (Vis2.obj.selectMode == "Advanced") {
               Hotkey, Space, % void, On
               Hotkey, ^Space, % void, On
               Hotkey, !Space, % void, On
               Hotkey, +Space, % void, On
            }
            Vis2.obj.area.show()
            return
         }
      }
   }

   class functor {

      __Call(method, args*) {
         ; When casting to Call(), use a new instance of the "function object"
         ; so as to avoid directly storing the properties(used across sub-methods)
         ; into the "function object" itself. Modified to accept empty arg.
         if (method == "")
            return (new this).Call(args*)
         if IsObject(method)
            return (new this).Call(method, args*)
      }

      inner[]
      {
         get {
            ; Gets a reference to the current class.
            ; Returns void if this function is not nested in a class.
            if (_class := this.__class)
               Loop, Parse, _class, .
                  inner := (A_Index=1) ? %A_LoopField% : inner[A_LoopField]
            return inner
         }
      }

      outer[]
      {
         get {
            ; Determine if there is a parent class. this.__class will retrive the
            ; current instance's class name. Array notation [] will dereference.
            ; Returns void if this function is not nested in at least 2 classes.
            if ((_class := RegExReplace(this.__class, "^(.*)\..*$", "$1")) != this.__class)
               Loop, Parse, _class, .
                  outer := (A_Index=1) ? %A_LoopField% : outer[A_LoopField]
            return outer
         }
      }
   }

   class Graphics {

      static pToken, Gdip := 0  ; Gdip is the number of active graphics objects.

      Startup() {
         global pToken
         return this.inner.pToken := (this.inner.Gdip++ > 0) ? this.inner.pToken : ((pToken) ? pToken : Gdip_Startup())
      }

      Shutdown() {
         global pToken
         return this.inner.pToken := (--this.inner.Gdip <= 0) ? ((pToken) ? pToken : Gdip_Shutdown(this.inner.pToken)) : this.inner.pToken
      }

      class Area {

         ScreenWidth := A_ScreenWidth, ScreenHeight := A_ScreenHeight,
         action := ["base"], x := [0], y := [0], w := [1], h := [1], a := ["top left"], q := ["bottom right"]

         __New(title := "", color := "0x7FDDDDDD") {
            this.outer.Startup()
            Gui, New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndhwnd
            this.color := color
            this.hwnd := hwnd
            this.title := (title != "") ? title : "Area_" this.hwnd
            DllCall("ShowWindow", "ptr",this.hwnd, "int", (this.isDrawable()) ? 8 : 1)
            DllCall("SetWindowText", "ptr",this.hwnd, "str",this.title)
            this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            Gdip_SetSmoothingMode(this.G, 4) ;Adds one clickable pixel to the edge.
            this.pBrush := Gdip_BrushCreateSolid(this.color)
         }

         __Delete() {
            this.outer.Shutdown()
         }

         Destroy() {
            Gdip_DeleteBrush(this.pBrush)
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            DllCall("DestroyWindow", "ptr",this.hwnd)
            return this
         }

         Hide() {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",0)
            return this
         }

         Show(i := 8) {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",i)
            return this
         }

         ToggleVisible() {
            return (this.isVisible()) ? this.Hide() : this.Show()
         }

         isVisible() {
            return DllCall("IsWindowVisible", "ptr",this.hwnd)
         }

         isDrawable(win := "A") {
             static WM_KEYDOWN := 0x100
             static WM_KEYUP := 0x101
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

         DetectScreenResolutionChange() {
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

         Redraw(x, y, w, h) {
            Critical On
            this.DetectScreenResolutionChange()
            Gdip_GraphicsClear(this.G)
            Gdip_FillRectangle(this.G, this.pBrush, x, y, w, h)
            if (this.coordinates)
               Vis2.Graphics.Subtitle.Draw("x: " x " │ y: " y " │ w: " w " │ h: " h
                  , {"a":"top_right", "x":"right", "y":"top", "color":"Black"}, {"font":"Lucida Sans Typewriter", "size":"1.67%"}, this.G)
            UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.ScreenWidth, this.ScreenHeight)
            Critical Off
         }

         ChangeColor(color) {
            this.color := color
            Gdip_DeleteBrush(this.pBrush)
            this.pBrush := Gdip_BrushCreateSolid(this.color)
            this.Redraw(this.x[this.x.maxIndex()], this.y[this.y.maxIndex()], this.w[this.w.maxIndex()], this.h[this.h.maxIndex()])
         }

         ShowCoordinates() {
            this.coordinates := true
            this.Redraw(this.x[this.x.maxIndex()], this.y[this.y.maxIndex()], this.w[this.w.maxIndex()], this.h[this.h.maxIndex()])
         }

         HideCoordinates() {
            this.coodinates := false
            this.Redraw(this.x[this.x.maxIndex()], this.y[this.y.maxIndex()], this.w[this.w.maxIndex()], this.h[this.h.maxIndex()])
         }

         ToggleCoordinates() {
            this.coordinates := !this.coordinates
            this.Redraw(this.x[this.x.maxIndex()], this.y[this.y.maxIndex()], this.w[this.w.maxIndex()], this.h[this.h.maxIndex()])
         }

         Propagate(v) {
            this.a[v] := (this.a[v] == "") ? this.a[v-1] : this.a[v]
            this.q[v] := (this.q[v] == "") ? this.q[v-1] : this.q[v]
            this.x[v] := (this.x[v] == "") ? this.x[v-1] : this.x[v]
            this.y[v] := (this.y[v] == "") ? this.y[v-1] : this.y[v]
            this.w[v] := (this.w[v] == "") ? this.w[v-1] : this.w[v]
            this.h[v] := (this.h[v] == "") ? this.h[v-1] : this.h[v]
         }

         BackPropagate(pasts) {
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

         Converge(v := "") {
            v := (v) ? v : this.action.maxIndex()

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

         Debug(function) {
            v := (v) ? v : this.action.maxIndex()
            Tooltip % function "`t" v . "`n" v-1 ": " this.action[v-1]
               . "`n" this.x[v-2] ", " this.y[v-2] ", " this.w[v-2] ", " this.h[v-2]
               . "`n" this.x[v-1] ", " this.y[v-1] ", " this.w[v-1] ", " this.h[v-1]
               . "`n" this.x[v] ", " this.y[v] ", " this.w[v] ", " this.h[v]
               . "`nAnchor:`t" this.a[v] "`nMouse:`t" this.q[v] "`t" this.isMouseInside()
         }

         Hover() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_hover, y_hover
            this.x_hover := x_hover
            this.y_hover := y_hover

            ; Resets the stack to 1.
            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.action := [A_ThisFunc]
               this.a := [this.a.pop()]
               this.q := [this.q.pop()]
               this.x := [this.x.pop()]
               this.y := [this.y.pop()]
               this.w := [this.w.pop()]
               this.h := [this.h.pop()]
            }
         }

         Origin(v := "") {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
            }

            v := (v) ? v : this.action.maxIndex()

            if (x_mouse != this.x_last || y_mouse != this.y_last) {
               this.x_last := x_mouse, this.y_last := y_mouse

               this.x[v] := x_mouse
               this.y[v] := y_mouse

               this.Propagate(v)
               this.Redraw(x_mouse, y_mouse, 1, 1) ;stabilize x/y corrdinates in window spy.
            }
         }

         Draw(v := "") {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc == this.action[this.action.maxIndex()-1]){
               this.BackPropagate(this.action.maxIndex())
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }
            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.maxIndex()
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

         Move(v := "") {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.maxIndex()
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

         ResizeCorners(v := "") {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.maxIndex()
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

         ResizeEdges(v := "") {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse

            if (A_ThisFunc != this.action[this.action.maxIndex()]){
               this.Converge()
               this.action.push(A_ThisFunc)
               this.x_hover := x_mouse
               this.y_hover := y_mouse
               pass := 1
            }

            v := (v) ? v : this.action.maxIndex()
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

         isMouseInside() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return (x_mouse >= this.x[this.x.maxIndex()]
               && x_mouse <= this.x[this.x.maxIndex()] + this.w[this.w.maxIndex()]
               && y_mouse >= this.y[this.y.maxIndex()]
               && y_mouse <= this.y[this.y.maxIndex()] + this.h[this.h.maxIndex()])
         }

         isMouseOutside() {
            return !this.isMouseInside()
         }

         isMouseOnCorner() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return (x_mouse == this.x[this.x.maxIndex()] || x_mouse == this.x[this.x.maxIndex()] + this.w[this.w.maxIndex()])
               && (y_mouse == this.y[this.y.maxIndex()] || y_mouse == this.y[this.y.maxIndex()] + this.h[this.h.maxIndex()])
         }

         isMouseOnEdge() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return ((x_mouse >= this.x[this.x.maxIndex()] && x_mouse <= this.x[this.x.maxIndex()] + this.w[this.w.maxIndex()])
               && (y_mouse == this.y[this.y.maxIndex()] || y_mouse == this.y[this.y.maxIndex()] + this.h[this.h.maxIndex()]))
               OR ((y_mouse >= this.y[this.y.maxIndex()] && y_mouse <= this.y[this.y.maxIndex()] + this.h[this.h.maxIndex()])
               && (x_mouse == this.x[this.x.maxIndex()] || x_mouse == this.x[this.x.maxIndex()] + this.w[this.w.maxIndex()]))
         }

         isMouseStopped() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            return x_mouse == this.x_last && y_mouse == this.y_last
         }

         ScreenshotArray() {
            x := this.x1(), y := this.y1(), w := this.width(), h := this.height()
            return (w > 0 && h > 0) ? [x, y, w, h] : ""
         }

         ScreenshotRectangle() {
            x := this.x1(), y := this.y1(), w := this.width(), h := this.height()
            return (w > 0 && h > 0) ? (x "|" y "|" w "|" h) : ""
         }

         x1() {
            return this.x[this.x.maxIndex()]
         }

         x2() {
            return this.x[this.x.maxIndex()] + this.w[this.w.maxIndex()]
         }

         y1() {
            return this.y[this.y.maxIndex()]
         }

         y2() {
            return this.y[this.y.maxIndex()] + this.h[this.h.maxIndex()]
         }

         width() {
            return this.w[this.w.maxIndex()]
         }

         height() {
            return this.h[this.h.maxIndex()]
         }

         outer[]
         {
            get {
               ; Determine if there is a parent class. this.__class will retrive the
               ; current instance's class name. Array notation [] will dereference.
               ; Returns void if this function is not nested in at least 2 classes.
               if ((_class := RegExReplace(this.__class, "^(.*)\..*$", "$1")) != this.__class)
                  Loop, Parse, _class, .
                     outer := (A_Index=1) ? %A_LoopField% : outer[A_LoopField]
               return outer
            }
         }
      } ; End of Area class.

      Class CustomFont {
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
      } ; End of CustomFont class.

      class Picture {

         ScreenWidth := A_ScreenWidth, ScreenHeight := A_ScreenHeight

         __New(title := "") {
            global pToken
            if !(this.outer.Startup())
               if !(pToken)
                  if !(this.pToken := Gdip_Startup())
                     throw Exception("Gdiplus failed to start. Please ensure you have gdiplus on your system.")

            Gui, New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndhwnd
            this.hwnd := hwnd
            this.title := (title != "") ? title : "Picture_" this.hwnd
            DllCall("ShowWindow", "ptr",this.hwnd, "int",8)
            DllCall("SetWindowText", "ptr",this.hwnd, "str",this.title)
            this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            return this
         }

         __Delete() {
            global pToken
            if (this.outer.pToken)
               return this.outer.Shutdown()
            if (pToken)
               return
            if (this.pToken)
               return Gdip_Shutdown(this.pToken)
         }

         FreeMemory() {
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            return this
         }

         Destroy() {
            this.FreeMemory()
            DllCall("DestroyWindow", "ptr",this.hwnd)
            return this
         }

         Hide() {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",0)
            return this
         }

         Show(i := 8) {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",i)
            return this
         }

         ToggleVisible() {
            return (this.isVisible()) ? this.Hide() : this.Show()
         }

         isVisible() {
            return DllCall("IsWindowVisible", "ptr",this.hwnd)
         }

         AlwaysOnTop() {
            WinSet, AlwaysOnTop, Toggle, % "ahk_id" this.hwnd
            return this
         }

         ClickThrough() {
            _dhw := A_DetectHiddenWindows
            DetectHiddenWindows On
            WinGet, ExStyle, ExStyle, % "ahk_id" this.hwnd
            if (ExStyle & 0x20)
               WinSet, ExStyle, -0x20, % "ahk_id" this.hwnd
            else
               WinSet, ExStyle, +0x20, % "ahk_id" this.hwnd
            DetectHiddenWindows %_dhw%
            return this
         }

         DetectScreenResolutionChange(w:="", h:="") {
            w := (w) ? w : A_ScreenWidth
            h := (h) ? h : A_ScreenHeight
            if (this.ScreenWidth != w || this.ScreenHeight != h) {
               this.ScreenWidth := w, this.ScreenHeight := h
               SelectObject(this.hdc, this.obm)
               DeleteObject(this.hbm)
               DeleteDC(this.hdc)
               Gdip_DeleteGraphics(this.G)
               this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
               this.hdc := CreateCompatibleDC()
               this.obm := SelectObject(this.hdc, this.hbm)
               this.G := Gdip_GraphicsFromHDC(this.hdc)
            }
         }

         ; Types of input accepted
         ; Objects: Rectangle Array (Screenshot)
         ; Strings: File, URL, Window Title (ahk_class...), base64
         ; Numbers: hwnd, GDI Bitmap, GDI HBitmap
         ; Rawfile: Binary

         ; Vis2.preprocess(image, crop) - This is a template function.
         ; Each provider should implement their own preprocess function based off
         ; this template. Accepts all 8 input types, returns a cropped pBitmap.
         ; If a provider implements this, it should return file/base64/binary.
         ; The provider should also implement a bypass if there is no crop array,
         ; and the input and output types are the same.
         Render(image, style := "", polygons := "") {
            if !(this.hwnd) {
               _picture := (this.outer) ? new this.outer.Picture() : new Picture()
               return _picture.Render(image, style, polygons)
            } else {
               Critical On
               if !(type := this.DontVerifyImageType(image))
                  type := this.ImageType(image)
               if (type != "pBitmap")
                  pBitmap := this.toBitmap(type, image)
               this.DetectScreenResolutionChange()
               this.Draw(pBitmap, style, polygons)
               if (type != "pBitmap")
                   Gdip_DisposeImage(pBitmap)
               UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.ScreenWidth, this.ScreenHeight)
               Critical Off
               if (this.time) {
                  self_destruct := ObjBindMethod(this, "Destroy")
                  SetTimer, % self_destruct, % -1 * this.time
               }
               return this
            }
         }

         Draw(pBitmap, style := "", polygons := "", pGraphics := "") {
            if (pGraphics == "")
               pGraphics := this.G

            style := !IsObject(style) ? RegExReplace(style, "\s+", " ") : style

            if (style == "")
               style := this.style
            else
               this.style := style

            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            this.time := (style.time) ? style.time : (style.t) ? style.t
               : (!IsObject(style) && (___ := RegExReplace(style, q1 "(t(ime)?)" q2, "${value}")) != style) ? ___
               : this.time

            if IsObject(style) {
               a  := (style.anchor != "")      ? style.anchor      : style.a
               x  := (style.left != "")        ? style.left        : style.x
               y  := (style.top != "")         ? style.top         : style.y
               w  := (style.width != "")       ? style.width       : style.w
               h  := (style.height != "")      ? style.height      : style.h
               m  := (style.margin != "")      ? style.margin      : style.m
               s  := (style.size != "")        ? style.size        : style.s
               c  := (style.color != "")       ? style.color       : style.c
               q  := (style.quality != "")     ? style.quality     : (style.q) ? style.q : style.InterpolationMode
            } else {
               a  := ((___ := RegExReplace(style, q1    "(a(nchor)?)"        q2, "${value}")) != style) ? ___ : ""
               x  := ((___ := RegExReplace(style, q1    "(x|left)"           q2, "${value}")) != style) ? ___ : ""
               y  := ((___ := RegExReplace(style, q1    "(y|top)"            q2, "${value}")) != style) ? ___ : ""
               w  := ((___ := RegExReplace(style, q1    "(w(idth)?)"         q2, "${value}")) != style) ? ___ : ""
               h  := ((___ := RegExReplace(style, q1    "(h(eight)?)"        q2, "${value}")) != style) ? ___ : ""
               m  := ((___ := RegExReplace(style, q1    "(m(argin)?)"        q2, "${value}")) != style) ? ___ : ""
               s  := ((___ := RegExReplace(style, q1    "(s(ize)?)"          q2, "${value}")) != style) ? ___ : ""
               c  := ((___ := RegExReplace(style, q1    "(c(olor)?)"         q2, "${value}")) != style) ? ___ : ""
               q  := ((___ := RegExReplace(style, q1    "(q(uality)?)"       q2, "${value}")) != style) ? ___ : ""
            }

            static valid := "^\s*(\-?\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static valid_positive := "^\s*(\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"

            this.vw := 0.01 * this.ScreenWidth    ; 1% of viewport width.
            this.vh := 0.01 * this.ScreenHeight   ; 1% of viewport height.
            this.vmin := (this.vw < this.vh) ? this.vw : this.vh ; 1vw or 1vh, whichever is smaller.

            ; Default = 0, LowQuality = 1, HighQuality = 2, Bilinear = 3
            ; Bicubic = 4, NearestNeighbor = 5, HighQualityBilinear = 6, HighQualityBicubic = 7
            q := (q >= 0 && q <= 7) ? q : 7       ; Default InterpolationMode is HighQualityBicubic.
            Gdip_SetInterpolationMode(pGraphics, q)

            ; Get original Bitmap width and height.
            width := Gdip_GetImageWidth(pBitmap)
            height := Gdip_GetImageHeight(pBitmap)

            w  := ( w ~= valid_positive) ? RegExReplace( w, "\s", "") : width ; Default width is bitmap width.
            w  := ( w ~= "(pt|px)$") ? SubStr( w, 1, -2) :  w
            w  := ( w ~= "(%|vw)$") ? RegExReplace( w, "(%|vw)$", "") * this.vw :  w
            w  := ( w ~= "vh$") ? RegExReplace( w, "vh$", "") * this.vh :  w
            w  := ( w ~= "vmin$") ? RegExReplace( w, "vmin$", "") * this.vmin :  w

            h  := ( h ~= valid_positive) ? RegExReplace( h, "\s", "") : height ; Default height is bitmap height.
            h  := ( h ~= "(pt|px)$") ? SubStr( h, 1, -2) :  h
            h  := ( h ~= "vw$") ? RegExReplace( h, "vw$", "") * this.vw :  h
            h  := ( h ~= "(%|vh)$") ? RegExReplace( h, "(%|vh)$", "") * this.vh :  h
            h  := ( h ~= "vmin$") ? RegExReplace( h, "vmin$", "") * this.vmin :  h

            s  := ( s ~= valid_positive) ? RegExReplace( s, "\s", "") : 1 ; Default size is 1.00.
            s  := ( s ~= "(pt|px)$") ? SubStr( s, 1, -2) :  s
            s  := ( s ~= "vw$") ? RegExReplace( s, "vw$", "") * this.vw :  s
            s  := ( s ~= "vh$") ? RegExReplace( s, "vh$", "") * this.vh :  s
            s  := ( s ~= "vmin$") ? RegExReplace( s, "vmin$", "") * this.vmin :  s
            s  := ( s ~= "%$") ? RegExReplace( s, "%$", "") * 0.01 :  s

            ; Scale width and height.
            w := Floor(w * s)
            h := Floor(h * s)

            a  := RegExReplace( a, "\s", "")
            a  := (a = "top") ? 2 : (a = "left") ? 4 : (a = "right") ? 6 : (a = "bottom") ? 8
               : (a ~= "i)top" && a ~= "i)left") ? 1 : (a ~= "i)top" && a ~= "i)cent(er|re)") ? 2
               : (a ~= "i)top" && a ~= "i)bottom") ? 3 : (a ~= "i)cent(er|re)" && a ~= "i)left") ? 4
               : (a ~= "i)cent(er|re)") ? 5 : (a ~= "i)cent(er|re)" && a ~= "i)bottom") ? 6
               : (a ~= "i)bottom" && a ~= "i)left") ? 7 : (a ~= "i)bottom" && a ~= "i)cent(er|re)") ? 8
               : (a ~= "i)bottom" && a ~= "i)right") ? 9 : (a ~= "^[1-9]$") ? a : 1 ; Default anchor is top-left.

            a  := ( x ~= "i)left") ? 1+((( a-1)//3)*3) : ( x ~= "i)cent(er|re)") ? 2+((( a-1)//3)*3) : ( x ~= "i)right") ? 3+((( a-1)//3)*3) :  a
            a  := ( y ~= "i)top") ? 1+(mod( a-1,3)) : ( y ~= "i)cent(er|re)") ? 4+(mod( a-1,3)) : ( y ~= "i)bottom") ? 7+(mod( a-1,3)) :  a

            ; Convert English words to numbers. Don't mess with these values any further.
            x  := ( x ~= "i)left") ? 0 : (x ~= "i)cent(er|re)") ? 0.5*this.ScreenWidth : (x ~= "i)right") ? this.ScreenWidth : x
            y  := ( y ~= "i)top") ? 0 : (y ~= "i)cent(er|re)") ? 0.5*this.ScreenHeight : (y ~= "i)bottom") ? this.ScreenHeight : y

            ; Validate x and y, convert to pixels.
            x  := ( x ~= valid) ? RegExReplace( x, "\s", "") : 0 ; Default x is 0.
            x  := ( x ~= "(pt|px)$") ? SubStr( x, 1, -2) :  x
            x  := ( x ~= "(%|vw)$") ? RegExReplace( x, "(%|vw)$", "") * this.vw :  x
            x  := ( x ~= "vh$") ? RegExReplace( x, "vh$", "") * this.vh :  x
            x  := ( x ~= "vmin$") ? RegExReplace( x, "vmin$", "") * this.vmin :  x

            y  := ( y ~= valid) ? RegExReplace( y, "\s", "") : 0 ; Default y is 0.
            y  := ( y ~= "(pt|px)$") ? SubStr( y, 1, -2) :  y
            y  := ( y ~= "vw$") ? RegExReplace( y, "vw$", "") * this.vw :  y
            y  := ( y ~= "(%|vh)$") ? RegExReplace( y, "(%|vh)$", "") * this.vh :  y
            y  := ( y ~= "vmin$") ? RegExReplace( y, "vmin$", "") * this.vmin :  y

            ; Modify x and y values with the anchor, so that the image has a new point of origin.
            x  -= (mod(a-1,3) == 0) ? 0 : (mod(a-1,3) == 1) ? w/2 : (mod(a-1,3) == 2) ? w : 0
            y  -= (((a-1)//3) == 0) ? 0 : (((a-1)//3) == 1) ? h/2 : (((a-1)//3) == 2) ? h : 0

            ; Prevent half-pixel rendering and keep image sharp.
            x := Floor(x)
            y := Floor(y)

            m := this.margin_and_padding(m)

            ; Calculate border using margin.
            _x  := x - (m.4)
            _y  := y - (m.1)
            _w  := w + (m.2 + m.4)
            _h  := h + (m.1 + m.3)

            ; Save size.
            this.x := _x
            this.y := _y
            this.w := _w
            this.h := _h

            ; Draw border.
            c := this.color(c, 0xFF000000) ; Default color is black.
            pBrush := Gdip_BrushCreateSolid(c)
            Gdip_FillRectangle(pGraphics, pBrush, _x, _y, _w, _h)
            Gdip_DeleteBrush(pBrush)

            Gdip_DrawImage(pGraphics, pBitmap, x, y, w, h, 0, 0, width, height)

            ; POINTF
            Gdip_SetSmoothingMode(pGraphics, 4)  ; None = 3, AntiAlias = 4
            pPen := Gdip_CreatePen(0xFFFF0000, 1)

            ;MsgBox % polygons[1].polygon
            for i, polygon in polygons {
               DllCall("gdiplus\GdipCreatePath", "int",1, "uptr*",pPath)
               VarSetCapacity(pointf, 8*polygons[i].polygon.maxIndex(), 0)
               for j, point in polygons[i].polygon {
                  NumPut(point.x + x, pointf, 8*(A_Index-1) + 0, "float")
                  NumPut(point.y + y, pointf, 8*(A_Index-1) + 4, "float")
               }
               DllCall("gdiplus\GdipAddPathPolygon", "ptr",pPath, "ptr",&pointf, "uint",polygons[i].polygon.maxIndex())
               DllCall("gdiplus\GdipDrawPath", "ptr",pGraphics, "ptr",pPen, "ptr",pPath) ; DRAWING!
            }

            ;DllCall("gdiplus\GdipSetPenLineJoin", "ptr",pPenGlow, "uint",2)
            ;DllCall("gdiplus\GdipSetPenWidth", "ptr",pPen, "float",o.1 + 2*A_Index)
            Gdip_DeletePen(pPen)



            return (pGraphics == "") ? this : ""
         }

         color(c, default := 0xDD424242) {
            static colorRGB  := "^0x([0-9A-Fa-f]{6})$"
            static colorARGB := "^0x([0-9A-Fa-f]{8})$"
            static hex6      :=   "^([0-9A-Fa-f]{6})$"
            static hex8      :=   "^([0-9A-Fa-f]{8})$"

            if ObjGetCapacity([c], 1) {
               c  := (c ~= "^#") ? SubStr(c, 2) : c
               c  := ((___ := this.outer.Subtitle.colorMap(c)) != "") ? ___ : c ; BORROW
               c  := (c ~= colorRGB) ? "0xFF" RegExReplace(c, colorRGB, "$1") : (c ~= hex8) ? "0x" c : (c ~= hex6) ? "0xFF" c : c
               c  := (c ~= colorARGB) ? c : default
            }
            return (c != "") ? c : default
         }

         margin_and_padding(m, default := 0) {
            static valid := "^\s*(\-?\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            if IsObject(m) {
               m.1 := (m.top    != "") ? m.top    : m.t
               m.2 := (m.right  != "") ? m.right  : m.r
               m.3 := (m.bottom != "") ? m.bottom : m.b
               m.4 := (m.left   != "") ? m.left   : m.l
            } else if (m != "") {
               _ := RegExReplace(m, ":\s+", ":")
               _ := RegExReplace(_, "\s+", " ")
               _ := StrSplit(_, " ")
               _.1 := ((___ := RegExReplace(m, q1    "(t(op)?)"           q2, "${value}")) != m) ? ___ : _.1
               _.2 := ((___ := RegExReplace(m, q1    "(r(ight)?)"         q2, "${value}")) != m) ? ___ : _.2
               _.3 := ((___ := RegExReplace(m, q1    "(b(ottom)?)"        q2, "${value}")) != m) ? ___ : _.3
               _.4 := ((___ := RegExReplace(m, q1    "(l(eft)?)"          q2, "${value}")) != m) ? ___ : _.4
               m := _
            }
            else return {1:default, 2:default, 3:default, 4:default}

            ; Follow CSS guidelines for margin!
            if (m.2 == "" && m.3 == "" && m.4 == "")
               m.4 := m.3 := m.2 := m.1, exception := true
            if (m.3 == "" && m.4 == "")
               m.4 := m.2, m.3 := m.1
            if (m.4 == "")
               m.4 := m.2

            for key, value in m {
               m[key] := (m[key] ~= valid) ? RegExReplace(m[key], "\s", "") : default
               m[key] := (m[key] ~= "(pt|px)$") ? SubStr(m[key], 1, -2) : m[key]
               m[key] := (m[key] ~= "vw$") ? RegExReplace(m[key], "vw$", "") * this.vw : m[key]
               m[key] := (m[key] ~= "vh$") ? RegExReplace(m[key], "vh$", "") * this.vh : m[key]
               m[key] := (m[key] ~= "vmin$") ? RegExReplace(m[key], "vmin$", "") * this.vmin : m[key]
            }
            m.1 := (m.1 ~= "%$") ? SubStr(m.1, 1, -1) * this.vh : m.1
            m.2 := (m.2 ~= "%$") ? SubStr(m.2, 1, -1) * (exception ? this.vh : this.vw) : m.2
            m.3 := (m.3 ~= "%$") ? SubStr(m.3, 1, -1) * this.vh : m.3
            m.4 := (m.4 ~= "%$") ? SubStr(m.4, 1, -1) * (exception ? this.vh : this.vw) : m.4
            return m
         }

         ; TEMPLATE FUNCTION - Please copy, paste, and modify.
         ; Preprocess() - Modifies an input image and returns a Bitmap.
         ; Example: Preprocess("https://goo.gl/BWUygC", "base64")
         ;          The image is downloaded from the URL and is converted to base64.
         Preprocess(image, crop := "") {
            ; Attempt to extract the type of the input image.
            if !(type := this.DontVerifyImageType(image))
               type := this.ImageType(image)
            ; If the input type and output type match, return the input image.
            ; MODIFY - "pBitmap" to your destination type.
            if (type = "pBitmap" && !this.isScreenshot(crop))
               return image
            ; Or else convert the input image to the output type and crop.
            pBitmap := this.toBitmap(type, image)
            if this.isScreenshot(crop){
               pBitmap2 := this.Gdip_CropBitmap(pBitmap, image)
               if (type != "pBitmap")
                  Gdip_DisposeImage(pBitmap)
               pBitmap := pBitmap2
            }
            ; Conversion code here...
            ; if (type != "pBitmap" || this.isScreenshot(crop))
            ;    Gdip_DisposeImage(pBitmap)
            ; MODIFY - return your destination type.
            return pBitmap
         }

         ; DontVerifyImageType() - The user should declare exactly what type it is.
         ; Ex. DontVerifyImageType({"Screenshot":[0,0,100,100]})
         DontVerifyImageType(ByRef image) {
            ; Check for type declaration.
            if !IsObject(image)
               return

            if (image.screenshot)
               return "screenshot", image := image.screenshot

            if (image.file)
               return "file", image := image.file

            if (image.url)
               return "url", image := image.url

            if (image.window)
               return "window", image := image.window

            if (image.hwnd)
               return "hwnd", image := image.hwnd

            if (image.pBitmap)
               return "pBitmap", image := image.pBitmap

            if (image.hBitmap)
               return "hBitmap", image := image.hBitmap

            if (image.base64)
               return "base64", image := image.base64

            return
         }

         ; ImageType() -  Makes best guess as to the user's intention.
         ImageType(image) {
            ; Check if image is empty string.
            if (image == "")
               throw Exception("Image data is empty string.")
            ; Check if image is an array of 4 numbers.
            if this.isScreenshot(image)
               return "screenshot"
            ; Check if image points to a valid file.
            if FileExist(image)
               return "file"
            ; Check if image points to a valid URL.
            if this.isURL(image)
               return "url"
            ; Check if image matches a window title.
            if WinExist(image)
               return "window"
            ; Check if image is a valid handle to a window.
            if DllCall("IsWindow", "ptr", image)
               return "hwnd"
            ; Check if image is a valid GDI Bitmap.
            if DeleteObject(Gdip_CreateHBITMAPFromBitmap(image))
               return "pBitmap"
            ; Check if image is a valid handle to a GDI Bitmap.
            if (DllCall("GetObjectType", "ptr", image) == 7)
               return "hBitmap"
            ; Check if image is a base64 string.
            if (image ~= "^(?:[A-Za-z0-9+/]{4})*?(?:[A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$")
               return "base64"

            throw Exception("Image type could not be identified.")
         }

         toBitmap(type, image) {
            if (type = "screenshot")
               return Gdip_BitmapFromScreen(image.1 "|" image.2 "|" image.3 "|" image.4)

            if (type = "file")
               return Gdip_CreateBitmapFromFile(image)

            if (type = "url"){
               req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
               req.Open("GET", image)
               req.Send()
               pStream := ComObjQuery(req.ResponseStream, "{0000000C-0000-0000-C000-000000000046}")
               DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr",pStream, "uptr*",pBitmap)
               ObjRelease(pStream)
               return pBitmap
            }

            if (type = "window")
               return this.Gdip_BitmapFromClientHWND(WinExist(image))

            if (type = "hwnd")
               return this.Gdip_BitmapFromClientHWND(image)

            if (type = "pBitmap")
               return image

            if (type = "hBitmap")
               return Gdip_CreateBitmapFromHBITMAP(image)

            if (type = "base64"){
               DllCall("crypt32\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), "ptr",&image, "uint",0, "uint",1, "ptr",0, "uint*",nSize, "ptr",0, "ptr",0)
               VarSetCapacity(bin, nSize, 0)
               DllCall("crypt32\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), "ptr",&image, "uint",0, "uint",1, "ptr",&bin, "uint*",nSize, "ptr",0, "ptr",0)
               hData := DllCall("GlobalAlloc", "uint",0x2, "ptr",nSize)
               pData := DllCall("GlobalLock", "ptr",hData)
               DllCall("RtlMoveMemory", "ptr",pData, "ptr",&bin, "ptr",nSize)
               DllCall("ole32\CreateStreamOnHGlobal", "ptr",hData, "int",0, "uptr*",pStream)
               DllCall("gdiplus\GdipCreateBitmapFromStream", "ptr",pStream, "uptr*",pBitmap)
               pBitmap2 := Gdip_CloneBitmapArea(pBitmap, 0, 0, Gdip_GetImageWidth(pBitmap), Gdip_GetImageHeight(pBitmap))
               Gdip_DisposeImage(pBitmap)
               ObjRelease(pStream)
               DllCall("GlobalUnlock", "ptr",hData)
               DllCall("GlobalFree", "ptr",hData) ; Will delete the original bitmap if not cloned.
               return pBitmap2
            }
         }

         Gdip_BitmapFromClientHWND(hwnd) {
            VarSetCapacity(rc, 16)
            DllCall("GetClientRect", "ptr", hwnd, "ptr", &rc)
         	hbm := CreateDIBSection(NumGet(rc, 8, "int"), NumGet(rc, 12, "int"))
            VarSetCapacity(rc, 0)
            hdc := CreateCompatibleDC()
            obm := SelectObject(hdc, hbm)
         	PrintWindow(hwnd, hdc, 1)
         	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
         	SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
         	return pBitmap
         }

         Gdip_CropBitmap(pBitmap, crop, width:="", height:=""){
            width := (width) ? width : Gdip_GetImageWidth(pBitmap)
            height := (height) ? height : Gdip_GetImageHeight(pBitmap)
            ; Ensure that coordinates can never exceed the expected Bitmap area.
            safe_x := (crop.1 > width) ? 0 : crop.1
            safe_y := (crop.2 > height) ? 0 : crop.2
            safe_w := (crop.1 + crop.3 > width) ? width - safe_x : crop.3
            safe_h := (crop.2 + crop.4 > height) ? height - safe_y : crop.4
            return Gdip_CloneBitmapArea(pBitmap, safe_x, safe_y, safe_w, safe_h)
         }

         Gdip_EncodeBitmapToBase64(pBitmap, ext, Quality=75) {

            if Ext not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
               return -1
            Extension := "." Ext

            DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
            VarSetCapacity(ci, nSize)
            DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, Ptr, &ci)
            if !(nCount && nSize)
               return -2

            Loop, %nCount%
            {
               sString := StrGet(NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize), "UTF-16")
               if !InStr(sString, "*" Extension)
                  continue

               pCodec := &ci+idx
               break
            }

            if !pCodec
               return -3

            if (Quality != 75)
            {
               Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
               if Extension in .JPG,.JPEG,.JPE,.JFIF
               {
                  DllCall("gdiplus\GdipGetEncoderParameterListSize", Ptr, pBitmap, Ptr, pCodec, "uint*", nSize)
                  VarSetCapacity(EncoderParameters, nSize, 0)
                  DllCall("gdiplus\GdipGetEncoderParameterList", Ptr, pBitmap, Ptr, pCodec, "uint", nSize, Ptr, &EncoderParameters)
                  Loop, % NumGet(EncoderParameters, "UInt")
                  {
                     elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
                     if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
                     {
                        p := elem+&EncoderParameters-pad-4
                        NumPut(Quality, NumGet(NumPut(4, NumPut(1, p+0)+20, "UInt")), "UInt")
                        break
                     }
                  }
               }
            }

            DllCall("ole32\CreateStreamOnHGlobal", "ptr",0, "int",true, "ptr*",pStream)
            DllCall("gdiplus\GdipSaveImageToStream", "ptr",pBitmap, "ptr",pStream, "ptr",pCodec, "uint",p ? p : 0)

            DllCall("ole32\GetHGlobalFromStream", "ptr",pStream, "uint*",hData)
            pData := DllCall("GlobalLock", "ptr",hData, "uptr")
            nSize := DllCall("GlobalSize", "uint",pData)

            VarSetCapacity(Bin, nSize, 0)
            DllCall("RtlMoveMemory", "ptr",&Bin, "ptr",pData, "uint",nSize)
            DllCall("GlobalUnlock", "ptr",hData)
            DllCall(NumGet(NumGet(pStream + 0, 0, "uptr") + (A_PtrSize * 2), 0, "uptr"), "ptr",pStream)
            DllCall("GlobalFree", "ptr",hData)

            ; Using CryptBinaryToStringA saves about 2MB in memory.
            DllCall("Crypt32.dll\CryptBinaryToStringA", "ptr",&Bin, "uint",nSize, "uint",0x40000001, "ptr",0, "uint*",base64Length)
            VarSetCapacity(base64, base64Length, 0)
            DllCall("Crypt32.dll\CryptBinaryToStringA", "ptr",&Bin, "uint",nSize, "uint",0x40000001, "ptr",&base64, "uint*",base64Length)
            VarSetCapacity(Bin, 0)

            return StrGet(&base64, base64Length, "CP0")
         }

         isBitmapEqual(pBitmap1, pBitmap2, width:="", height:="") {
            ; Check if pointers are identical.
            if (pBitmap1 == pBitmap2)
               return true

            ; Assume both Bitmaps are equal in width and height.
            width := (width) ? width : Gdip_GetImageWidth(pBitmap1)
            height := (height) ? height : Gdip_GetImageHeight(pBitmap1)
            E1 := Gdip_LockBits(pBitmap1, 0, 0, width, height, Stride1, Scan01, BitmapData1)
            E2 := Gdip_LockBits(pBitmap2, 0, 0, width, height, Stride2, Scan02, BitmapData2)

            ; RtlCompareMemory preforms an unsafe comparison stopping at the first different byte.
            size := width * height * 4  ; ARGB = 4 bytes
            byte := DllCall("RtlCompareMemory", "ptr", Scan01+0, "ptr", Scan02+0, "uint", size)

            Gdip_UnlockBits(pBitmap1, BitmapData1)
            Gdip_UnlockBits(pBitmap2, BitmapData2)
            return (byte == size) ? true : false
         }

         isScreenshot(array){
            return array.1 ~= "^\d+$" && array.2 ~= "^\d+$" && array.3 ~= "^\d+$"  && array.4 ~= "^\d+$"
         }

         isURL(url){
            regex .= "((https?|ftp)\:\/\/)" ; SCHEME
            regex .= "([a-z0-9+!*(),;?&=\$_.-]+(\:[a-z0-9+!*(),;?&=\$_.-]+)?@)?" ; User and Pass
            regex .= "([a-z0-9-.]*)\.([a-z]{2,3})" ; Host or IP
            regex .= "(\:[0-9]{2,5})?" ; Port
            regex .= "(\/([a-z0-9+\$_-]\.?)+)*\/?" ; Path
            regex .= "(\?[a-z+&\$_.-][a-z0-9;:@&%=+\/\$_.-]*)?" ; GET Query
            regex .= "(#[a-z_.-][a-z0-9+\$_.-]*)?" ; Anchor

            return (url ~= "i)" regex) ? true : false
         }

         outer[]
         {
            get {
               ; Determine if there is a parent class. this.__class will retrive the
               ; current instance's class name. Array notation [] will dereference.
               ; Returns void if this function is not nested in at least 2 classes.
               if ((_class := RegExReplace(this.__class, "^(.*)\..*$", "$1")) != this.__class)
                  Loop, Parse, _class, .
                     outer := (A_Index=1) ? %A_LoopField% : outer[A_LoopField]
               return outer
            }
         }

         x1() {
            return this.x
         }

         y1() {
            return this.y
         }

         x2() {
            return this.x + this.w
         }

         y2() {
            return this.y + this.h
         }

         width() {
            return this.w
         }

         height() {
            return this.h
         }
      } ; End of Image class.

      class Subtitle {

         layers := {}, ScreenWidth := A_ScreenWidth, ScreenHeight := A_ScreenHeight

         __New(title := "") {
            global pToken
            if !(this.outer.Startup())
               if !(pToken)
                  if !(this.pToken := Gdip_Startup())
                     throw Exception("Gdiplus failed to start. Please ensure you have gdiplus on your system.")

            Gui, New, +LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow +hwndhwnd
            this.hwnd := hwnd
            this.title := (title != "") ? title : "Subtitle_" this.hwnd
            DllCall("ShowWindow", "ptr",this.hwnd, "int",8)
            DllCall("SetWindowText", "ptr",this.hwnd, "str",this.title)
            this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
            this.hdc := CreateCompatibleDC()
            this.obm := SelectObject(this.hdc, this.hbm)
            this.G := Gdip_GraphicsFromHDC(this.hdc)
            return this
         }

         __Delete() {
            global pToken
            if (this.outer.pToken)
               return this.outer.Shutdown()
            if (pToken)
               return
            if (this.pToken)
               return Gdip_Shutdown(this.pToken)
         }

         FreeMemory() {
            SelectObject(this.hdc, this.obm)
            DeleteObject(this.hbm)
            DeleteDC(this.hdc)
            Gdip_DeleteGraphics(this.G)
            return this
         }

         Destroy() {
            this.FreeMemory()
            DllCall("DestroyWindow", "ptr",this.hwnd)
            return this
         }

         Hide() {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",0)
            return this
         }

         Show(i := 8) {
            DllCall("ShowWindow", "ptr",this.hwnd, "int",i)
            return this
         }

         ToggleVisible() {
            return (this.isVisible()) ? this.Hide() : this.Show()
         }

         isVisible() {
            return DllCall("IsWindowVisible", "ptr",this.hwnd)
         }

         AlwaysOnTop() {
            WinSet, AlwaysOnTop, Toggle, % "ahk_id" this.hwnd
            return this
         }

         ClickThrough() {
            _dhw := A_DetectHiddenWindows
            DetectHiddenWindows On
            WinGet, ExStyle, ExStyle, % "ahk_id" this.hwnd
            if (ExStyle & 0x20)
               WinSet, ExStyle, -0x20, % "ahk_id" this.hwnd
            else
               WinSet, ExStyle, +0x20, % "ahk_id" this.hwnd
            DetectHiddenWindows %_dhw%
            return this
         }

         DetectScreenResolutionChange(width := "", height := "") {
            width := (width) ? width : A_ScreenWidth
            height := (height) ? height : A_ScreenHeight
            if (width != this.ScreenWidth || height != this.ScreenHeight) {
               this.ScreenWidth := width, this.ScreenHeight := height
               SelectObject(this.hdc, this.obm)
               DeleteObject(this.hbm)
               DeleteDC(this.hdc)
               Gdip_DeleteGraphics(this.G)
               this.hbm := CreateDIBSection(this.ScreenWidth, this.ScreenHeight)
               this.hdc := CreateCompatibleDC()
               this.obm := SelectObject(this.hdc, this.hbm)
               this.G := Gdip_GraphicsFromHDC(this.hdc)
               loop % this.layers.maxIndex()
                  this.Draw(this.layers[A_Index].1, this.layers[A_Index].2, this.layers[A_Index].3, pGraphics)
            }
         }

         Bitmap(x := "", y := "", w := "", h := "") {
            x := (x != "") ? x : this.x
            y := (y != "") ? y : this.y
            w := (w != "") ? w : this.xx - this.x
            h := (h != "") ? h : this.yy - this.y

            pBitmap := Gdip_CreateBitmap(this.ScreenWidth, this.ScreenHeight)
            pGraphics := Gdip_GraphicsFromImage(pBitmap)
            loop % this.layers.maxIndex()
               this.Draw(this.layers[A_Index].1, this.layers[A_Index].2, this.layers[A_Index].3, pGraphics)
            Gdip_DeleteGraphics(pGraphics)
            pBitmapCopy := Gdip_CloneBitmapArea(pBitmap, x, y, w, h)
            Gdip_DisposeImage(pBitmap)
            return pBitmapCopy ; Please dispose of this image responsibly.
         }

         hBitmap(alpha := 0xFFFFFFFF) {
            ; hBitmap converts alpha channel to specified alpha color.
            ; Adds 1 pixel because Anti-Alias (SmoothingMode = 4)
            ; Should it be crop 1 pixel instead?
            pBitmap := this.Bitmap()
            hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap, alpha)
            Gdip_DisposeImage(pBitmap)
            return hBitmap
         }

         Save(filename := "", quality := 92) {
            filename := (filename ~= "i)\.(bmp|dib|rle|jpg|jpeg|jpe|jfif|gif|tif|tiff|png)$") ? filename
                     : (filename != "") ? filename ".png" : this.title ".png"
            pBitmap := this.Bitmap()
            Gdip_SaveBitmapToFile(pBitmap, filename, quality)
            Gdip_DisposeImage(pBitmap)
            return this
         }

         Screenshot(filename := "", quality := 92) {
            filename := (filename ~= "i)\.(bmp|dib|rle|jpg|jpeg|jpe|jfif|gif|tif|tiff|png)$") ? filename
                     : (filename != "") ? filename ".png" : this.title ".png"
            pBitmap := Gdip_BitmapFromScreen(this.x "|" this.y "|" this.xx - this.x "|" this.yy - this.y)
            Gdip_SaveBitmapToFile(pBitmap, filename, quality)
            Gdip_DisposeImage(pBitmap)
            return this
         }

         Render(text := "", style1 := "", style2 := "", update := true) {
            if !(this.hwnd){
               _subtitle := (this.outer) ? new this.outer.Subtitle() : new Subtitle()
               return _subtitle.Render(text, style1, style2, update)
            }
            else {
               Critical On
               this.Draw(text, style1, style2)
               this.DetectScreenResolutionChange()
               if (this.allowDrag == true)
                  this.Reposition()
               if (update == true) {
                  UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.ScreenWidth, this.ScreenHeight)
               }
               if (this.time) {
                  self_destruct := ObjBindMethod(this, "Destroy")
                  SetTimer, % self_destruct, % -1 * this.time
               }
               this.rendered := true
               Critical Off
               return this
            }
         }

         RenderToBitmap(text := "", style1 := "", style2 := "") {
            if !(this.hwnd){
               _subtitle := (this.outer) ? new this.outer.Subtitle() : new Subtitle()
               return _subtitle.RenderToBitmap(text, style1, style2)
            } else {
               this.Render(text, style1, style2, false)
               return this.Bitmap()
            }
         }

         RenderToHBitmap(text := "", style1 := "", style2 := "") {
            if !(this.hwnd){
               _subtitle := (this.outer) ? new this.outer.Subtitle() : new Subtitle()
               return _subtitle.RenderToHBitmap(text, style1, style2)
            } else {
               this.Render(text, style1, style2, false)
               return this.hBitmap()
            }
         }

         Reposition() {
            CoordMode, Mouse, Screen
            MouseGetPos, x_mouse, y_mouse
            this.LButton := GetKeyState("LButton", "P") ? 1 : 0
            this.keypress := (this.LButton && DllCall("GetForegroundWindow") == this.hwnd) ? ((!this.keypress) ? 1 : -1) : ((this.keypress == -1) ? 2 : 0)

            if (this.keypress == 1) {
               this.x_mouse := x_mouse, this.y_mouse := y_mouse
               this.hbm2 := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
               this.hdc2 := CreateCompatibleDC()
               this.obm2 := SelectObject(this.hdc2, this.hbm2)
               this.G2 := Gdip_GraphicsFromHDC(this.hdc2)
            }

            if (this.keypress == -1) {
               dx := x_mouse - this.x_mouse
               dy := y_mouse - this.y_mouse
               safe_x := (0 + dx <= 0) ? 0 : 0 + dx
               safe_y := (0 + dy <= 0) ? 0 : 0 + dy
               safe_w := (0 + this.ScreenWidth + dx >= this.ScreenWidth) ? this.ScreenWidth : 0 + this.ScreenWidth + dx
               safe_h := (0 + this.ScreenHeight + dy >= this.ScreenHeight) ? this.ScreenHeight : 0 + this.ScreenHeight + dy
               source_x := (dx < 0) ? -dx : 0
               source_y := (dy < 0) ? -dy : 0
               ;Tooltip % dx ", " dy "`n" safe_x ", " safe_y ", " safe_w ", " safe_h
               Gdip_GraphicsClear(this.G2)
               BitBlt(this.hdc2, safe_x, safe_y, safe_w, safe_h, this.hdc, source_x, source_y)
               UpdateLayeredWindow(this.hwnd, this.hdc2, 0, 0, this.ScreenWidth, this.ScreenHeight)
            }

            if (this.keypress == 2) {
               Gdip_DeleteGraphics(this.G)
               SelectObject(this.hdc, this.obm)
               DeleteObject(this.hbm)
               DeleteDC(this.hdc)
               this.hdc := this.hdc2
               this.obm := this.obm2
               this.hbm := this.hbm2
               this.G := Gdip_GraphicsFromHDC(this.hdc2)
            }

            Reposition := ObjBindMethod(this, "Reposition")
            SetTimer, % Reposition, -10
         }

         Draw(text := "", style1 := "", style2 := "", pGraphics := "") {
            ; If the image was previously rendered, reset everything like a new Subtitle object.
            if (pGraphics == "") {
               if (this.rendered == true) {
                  this.rendered := false
                  this.layers := {}
                  this.x := this.y := this.xx := this.yy := "" ; not 0!
                  Gdip_GraphicsClear(this.G)
               }
               this.layers.push([text, style1, style2]) ; Saves each call of Draw()
               pGraphics := this.G
            }

            ; Remove excess whitespace. This is required for proper RegEx detection.
            style1 := !IsObject(style1) ? RegExReplace(style1, "\s+", " ") : style1
            style2 := !IsObject(style2) ? RegExReplace(style2, "\s+", " ") : style2

            ; Load saved styles if and only if both styles are blank.
            if (style1 == "" && style2 == "")
               style1 := this.style1, style2 := this.style2
            else
               this.style1 := style1, this.style2 := style2 ; Remember styles so that they can be loaded next time.

            ; RegEx help? https://regex101.com/r/xLzZzO/2
            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            ; Extract the time variable and save it for later when we Render() everything.
            this.time := (style1.time) ? style1.time : (style1.t) ? style1.t
               : (!IsObject(style1) && (___ := RegExReplace(style1, q1 "(t(ime)?)" q2, "${value}")) != style1) ? ___
               : (style2.time) ? style2.time : (style2.t) ? style2.t
               : (!IsObject(style2) && (___ := RegExReplace(style2, q1 "(t(ime)?)" q2, "${value}")) != style2) ? ___
               : this.time

            ; Extract styles from the background styles parameter.
            if IsObject(style1) {
               _a  := (style1.anchor != "")   ? style1.anchor   : style1.a
               _x  := (style1.left != "")     ? style1.left     : style1.x
               _y  := (style1.top != "")      ? style1.top      : style1.y
               _w  := (style1.width != "")    ? style1.width    : style1.w
               _h  := (style1.height != "")   ? style1.height   : style1.h
               _r  := (style1.radius != "")   ? style1.radius   : style1.r
               _c  := (style1.color != "")    ? style1.color    : style1.c
               _m  := (style1.margin != "")   ? style1.margin   : style1.m
               _p  := (style1.padding != "")  ? style1.padding  : style1.p
               _q  := (style1.quality != "")  ? style1.quality  : (style1.q) ? style1.q : style1.SmoothingMode
            } else {
               _a  := ((___ := RegExReplace(style1, q1    "(a(nchor)?)"        q2, "${value}")) != style1) ? ___ : ""
               _x  := ((___ := RegExReplace(style1, q1    "(x|left)"           q2, "${value}")) != style1) ? ___ : ""
               _y  := ((___ := RegExReplace(style1, q1    "(y|top)"            q2, "${value}")) != style1) ? ___ : ""
               _w  := ((___ := RegExReplace(style1, q1    "(w(idth)?)"         q2, "${value}")) != style1) ? ___ : ""
               _h  := ((___ := RegExReplace(style1, q1    "(h(eight)?)"        q2, "${value}")) != style1) ? ___ : ""
               _r  := ((___ := RegExReplace(style1, q1    "(r(adius)?)"        q2, "${value}")) != style1) ? ___ : ""
               _c  := ((___ := RegExReplace(style1, q1    "(c(olor)?)"         q2, "${value}")) != style1) ? ___ : ""
               _m  := ((___ := RegExReplace(style1, q1    "(m(argin)?)"        q2, "${value}")) != style1) ? ___ : ""
               _p  := ((___ := RegExReplace(style1, q1    "(p(adding)?)"       q2, "${value}")) != style1) ? ___ : ""
               _q  := ((___ := RegExReplace(style1, q1    "(q(uality)?)"       q2, "${value}")) != style1) ? ___ : ""
            }

            ; Extract styles from the text styles parameter.
            if IsObject(style2) {
               a  := (style2.anchor != "")      ? style2.anchor      : style2.a
               x  := (style2.left != "")        ? style2.left        : style2.x
               y  := (style2.top != "")         ? style2.top         : style2.y
               w  := (style2.width != "")       ? style2.width       : style2.w
               h  := (style2.height != "")      ? style2.height      : style2.h
               m  := (style2.margin != "")      ? style2.margin      : style2.m
               f  := (style2.font != "")        ? style2.font        : style2.f
               s  := (style2.size != "")        ? style2.size        : style2.s
               c  := (style2.color != "")       ? style2.color       : style2.c
               b  := (style2.bold != "")        ? style2.bold        : style2.b
               i  := (style2.italic != "")      ? style2.italic      : style2.i
               u  := (style2.underline != "")   ? style2.underline   : style2.u
               j  := (style2.justify != "")     ? style2.justify     : style2.j
               n  := (style2.noWrap != "")      ? style2.noWrap      : style2.n
               z  := (style2.condensed != "")   ? style2.condensed   : style2.z
               d  := (style2.dropShadow != "")  ? style2.dropShadow  : style2.d
               o  := (style2.outline != "")     ? style2.outline     : style2.o
               q  := (style2.quality != "")     ? style2.quality     : (style2.q) ? style2.q : style2.TextRenderingHint
            } else {
               a  := ((___ := RegExReplace(style2, q1    "(a(nchor)?)"        q2, "${value}")) != style2) ? ___ : ""
               x  := ((___ := RegExReplace(style2, q1    "(x|left)"           q2, "${value}")) != style2) ? ___ : ""
               y  := ((___ := RegExReplace(style2, q1    "(y|top)"            q2, "${value}")) != style2) ? ___ : ""
               w  := ((___ := RegExReplace(style2, q1    "(w(idth)?)"         q2, "${value}")) != style2) ? ___ : ""
               h  := ((___ := RegExReplace(style2, q1    "(h(eight)?)"        q2, "${value}")) != style2) ? ___ : ""
               m  := ((___ := RegExReplace(style2, q1    "(m(argin)?)"        q2, "${value}")) != style2) ? ___ : ""
               f  := ((___ := RegExReplace(style2, q1    "(f(ont)?)"          q2, "${value}")) != style2) ? ___ : ""
               s  := ((___ := RegExReplace(style2, q1    "(s(ize)?)"          q2, "${value}")) != style2) ? ___ : ""
               c  := ((___ := RegExReplace(style2, q1    "(c(olor)?)"         q2, "${value}")) != style2) ? ___ : ""
               b  := ((___ := RegExReplace(style2, q1    "(b(old)?)"          q2, "${value}")) != style2) ? ___ : ""
               i  := ((___ := RegExReplace(style2, q1    "(i(talic)?)"        q2, "${value}")) != style2) ? ___ : ""
               u  := ((___ := RegExReplace(style2, q1    "(u(nderline)?)"     q2, "${value}")) != style2) ? ___ : ""
               j  := ((___ := RegExReplace(style2, q1    "(j(ustify)?)"       q2, "${value}")) != style2) ? ___ : ""
               n  := ((___ := RegExReplace(style2, q1    "(n(oWrap)?)"        q2, "${value}")) != style2) ? ___ : ""
               z  := ((___ := RegExReplace(style2, q1    "(z|condensed)"      q2, "${value}")) != style2) ? ___ : ""
               d  := ((___ := RegExReplace(style2, q1    "(d(ropShadow)?)"    q2, "${value}")) != style2) ? ___ : ""
               o  := ((___ := RegExReplace(style2, q1    "(o(utline)?)"       q2, "${value}")) != style2) ? ___ : ""
               q  := ((___ := RegExReplace(style2, q1    "(q(uality)?)"       q2, "${value}")) != style2) ? ___ : ""
            }

            ; These are the type checkers.
            static valid := "^\s*(\-?\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static valid_positive := "^\s*(\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"

            ; Define viewport width and height. This is the visible screen area.
            this.vw := 0.01 * this.ScreenWidth    ; 1% of viewport width.
            this.vh := 0.01 * this.ScreenHeight   ; 1% of viewport height.
            this.vmin := (this.vw < this.vh) ? this.vw : this.vh ; 1vw or 1vh, whichever is smaller.

            ; Get Rendering Quality.
            _q := (_q >= 0 && _q <= 4) ? _q : 4          ; Default SmoothingMode is 4 if radius is set. See Draw 1.
            q  := (q >= 0 && q <= 5) ? q : 4             ; Default TextRenderingHint is 4 (antialias).

            ; Get Font size.
            s  := (s ~= valid_positive) ? RegExReplace(s, "\s", "") : "2.23vh"           ; Default font size is 2.23vh.
            s  := (s ~= "(pt|px)$") ? SubStr(s, 1, -2) : s                               ; Strip spaces, px, and pt.
            s  := (s ~= "vh$") ? RegExReplace(s, "vh$", "") * this.vh : s                ; Relative to viewport height.
            s  := (s ~= "vw$") ? RegExReplace(s, "vw$", "") * this.vw : s                ; Relative to viewport width.
            s  := (s ~= "(%|vmin)$") ? RegExReplace(s, "(%|vmin)$", "") * this.vmin : s  ; Relative to viewport minimum.

            ; Get Bold, Italic, Underline, NoWrap, and Justification of text.
            style += (b) ? 1 : 0         ; bold
            style += (i) ? 2 : 0         ; italic
            style += (u) ? 4 : 0         ; underline
            style += (strikeout) ? 8 : 0 ; strikeout, not implemented.
            n  := (n) ? 0x4000 | 0x1000 : 0x4000
            j  := (j ~= "i)cent(er|re)") ? 1 : (j ~= "i)(far|right)") ? 2 : 0   ; Left/near, center/centre, far/right.

            ; Later when text x and w are finalized and it is found that x + ReturnRC[3] exceeds the screen,
            ; then the _redrawBecauseOfCondensedFont flag is set to true.
            if (this._redrawBecauseOfCondensedFont == true)
               f:=z, z:=0, this._redrawBecauseOfCondensedFont := false

            ; Create Font.
            hFamily := (___ := Gdip_FontFamilyCreate(f)) ? ___ : Gdip_FontFamilyCreate("Arial") ; Default font is Arial.
            hFont := Gdip_FontCreate(hFamily, s, style)
            hFormat := Gdip_StringFormatCreate(n)
            Gdip_SetStringFormatAlign(hFormat, j)  ; Left = 0, Center = 1, Right = 2

            ; Simulate string width and height. This will get the exact width and height of the text.
            CreateRectF(RC, 0, 0, 0, 0)
            Gdip_SetSmoothingMode(pGraphics, _q)     ; None = 3, AntiAlias = 4
            Gdip_SetTextRenderingHint(pGraphics, q)  ; Anti-Alias = 4, Cleartype = 5 (and gives weird effects.)
            ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, RC)
            ReturnRC := StrSplit(ReturnRC, "|")      ; Contains the values for measured x, y, w, h text.

            ; Get background width and height. Default width and height are simulated width and height.
            _w := (_w ~= valid_positive) ? RegExReplace(_w, "\s", "") : ReturnRC[3]
            _w := (_w ~= "(pt|px)$") ? SubStr(_w, 1, -2) : _w
            _w := (_w ~= "(%|vw)$") ? RegExReplace(_w, "(%|vw)$", "") * this.vw : _w
            _w := (_w ~= "vh$") ? RegExReplace(_w, "vh$", "") * this.vh : _w
            _w := (_w ~= "vmin$") ? RegExReplace(_w, "vmin$", "") * this.vmin : _w
            ; Output is a decimal with pixel units.

            _h := (_h ~= valid_positive) ? RegExReplace(_h, "\s", "") : ReturnRC[4]
            _h := (_h ~= "(pt|px)$") ? SubStr(_h, 1, -2) : _h
            _h := (_h ~= "vw$") ? RegExReplace(_h, "vw$", "") * this.vw : _h
            _h := (_h ~= "(%|vh)$") ? RegExReplace(_h, "(%|vh)$", "") * this.vh : _h
            _h := (_h ~= "vmin$") ? RegExReplace(_h, "vmin$", "") * this.vmin : _h
            ; Output is a decimal with pixel units.

            ; Get background anchor. This is where the origin of the image is located.
            ; The default origin is the top left corner. Default anchor is 1.
            _a := RegExReplace(_a, "\s", "")
            _a := (_a = "top") ? 2 : (_a = "left") ? 4 : (_a = "right") ? 6 : (_a = "bottom") ? 8
               : (_a ~= "i)top" && _a ~= "i)left") ? 1 : (_a ~= "i)top" && _a ~= "i)cent(er|re)") ? 2
               : (_a ~= "i)top" && _a ~= "i)bottom") ? 3 : (_a ~= "i)cent(er|re)" && _a ~= "i)left") ? 4
               : (_a ~= "i)cent(er|re)") ? 5 : (_a ~= "i)cent(er|re)" && _a ~= "i)bottom") ? 6
               : (_a ~= "i)bottom" && _a ~= "i)left") ? 7 : (_a ~= "i)bottom" && _a ~= "i)cent(er|re)") ? 8
               : (_a ~= "i)bottom" && _a ~= "i)right") ? 9 : (_a ~= "^[1-9]$") ? _a : 1 ; Default anchor is top-left.

            ; _x and _y can be specified as locations (left, center, right, top, bottom).
            ; These location words in _x and _y take precedence over the values in _a.
            _a  := (_x ~= "i)left") ? 1+(((_a-1)//3)*3) : (_x ~= "i)cent(er|re)") ? 2+(((_a-1)//3)*3) : (_x ~= "i)right") ? 3+(((_a-1)//3)*3) : _a
            _a  := (_y ~= "i)top") ? 1+(mod(_a-1,3)) : (_y ~= "i)cent(er|re)") ? 4+(mod(_a-1,3)) : (_y ~= "i)bottom") ? 7+(mod(_a-1,3)) : _a

            ; Convert English words to numbers. Don't mess with these values any further.
            _x  := (_x ~= "i)left") ? 0 : (_x ~= "i)cent(er|re)") ? 0.5*this.ScreenWidth : (_x ~= "i)right") ? this.ScreenWidth : _x
            _y  := (_y ~= "i)top") ? 0 : (_y ~= "i)cent(er|re)") ? 0.5*this.ScreenHeight : (_y ~= "i)bottom") ? this.ScreenHeight : _y

            ; Get _x value.
            _x := (_x ~= valid) ? RegExReplace(_x, "\s", "") : 0  ; Default _x is 0.
            _x := (_x ~= "(pt|px)$") ? SubStr(_x, 1, -2) : _x
            _x := (_x ~= "(%|vw)$") ? RegExReplace(_x, "(%|vw)$", "") * this.vw : _x
            _x := (_x ~= "vh$") ? RegExReplace(_x, "vh$", "") * this.vh : _x
            _x := (_x ~= "vmin$") ? RegExReplace(_x, "vmin$", "") * this.vmin : _x

            ; Get _y value.
            _y := (_y ~= valid) ? RegExReplace(_y, "\s", "") : 0  ; Default _y is 0.
            _y := (_y ~= "(pt|px)$") ? SubStr(_y, 1, -2) : _y
            _y := (_y ~= "vw$") ? RegExReplace(_y, "vw$", "") * this.vw : _y
            _y := (_y ~= "(%|vh)$") ? RegExReplace(_y, "(%|vh)$", "") * this.vh : _y
            _y := (_y ~= "vmin$") ? RegExReplace(_y, "vmin$", "") * this.vmin : _y

            ; Now let's modify the _x and _y values with the _anchor, so that the image has a new point of origin.
            ; We need our calculated _width and _height for this.
            _x  -= (mod(_a-1,3) == 0) ? 0 : (mod(_a-1,3) == 1) ? _w/2 : (mod(_a-1,3) == 2) ? _w : 0
            _y  -= (((_a-1)//3) == 0) ? 0 : (((_a-1)//3) == 1) ? _h/2 : (((_a-1)//3) == 2) ? _h : 0
            ; Fractional y values might cause gdi+ slowdown.


            ; Get the text width and text height.
            ; Note that there are two new lines. Matching a percent symbol (%) will give text width/height
            ; that is relative to the background width/height. This is undesirable behavior, and so
            ; the user should use "vh" and "vw" whenever possible.
            w  := ( w ~= valid_positive) ? RegExReplace( w, "\s", "") : ReturnRC[3] ; Default is simulated text width.
            w  := ( w ~= "(pt|px)$") ? SubStr( w, 1, -2) :  w
            w  := ( w ~= "vw$") ? RegExReplace( w, "vw$", "") * this.vw :  w
            w  := ( w ~= "vh$") ? RegExReplace( w, "vh$", "") * this.vh :  w
            w  := ( w ~= "vmin$") ? RegExReplace( w, "vmin$", "") * this.vmin :  w
            w  := ( w ~= "%$") ? RegExReplace( w, "%$", "") * 0.01 * _w :  w

            h  := ( h ~= valid_positive) ? RegExReplace( h, "\s", "") : ReturnRC[4] ; Default is simulated text height.
            h  := ( h ~= "(pt|px)$") ? SubStr( h, 1, -2) :  h
            h  := ( h ~= "vw$") ? RegExReplace( h, "vw$", "") * this.vw :  h
            h  := ( h ~= "vh$") ? RegExReplace( h, "vh$", "") * this.vh :  h
            h  := ( h ~= "vmin$") ? RegExReplace( h, "vmin$", "") * this.vmin :  h
            h  := ( h ~= "%$") ? RegExReplace( h, "%$", "") * 0.01 * _h :  h

            ; If text justification is set but x is not, align the justified text relative to the center
            ; or right of the backgound, after taking into account the text width.
            if (x == "")
               x  := (j = 1) ? _x + (_w/2) - (w/2) : (j = 2) ? _x + _w - w : x

            ; Get anchor.
            a  := RegExReplace( a, "\s", "")
            a  := (a = "top") ? 2 : (a = "left") ? 4 : (a = "right") ? 6 : (a = "bottom") ? 8
               : (a ~= "i)top" && a ~= "i)left") ? 1 : (a ~= "i)top" && a ~= "i)cent(er|re)") ? 2
               : (a ~= "i)top" && a ~= "i)bottom") ? 3 : (a ~= "i)cent(er|re)" && a ~= "i)left") ? 4
               : (a ~= "i)cent(er|re)") ? 5 : (a ~= "i)cent(er|re)" && a ~= "i)bottom") ? 6
               : (a ~= "i)bottom" && a ~= "i)left") ? 7 : (a ~= "i)bottom" && a ~= "i)cent(er|re)") ? 8
               : (a ~= "i)bottom" && a ~= "i)right") ? 9 : (a ~= "^[1-9]$") ? a : 1 ; Default anchor is top-left.

            ; Text x and text y can be specified as locations (left, center, right, top, bottom).
            ; These location words in text x and text y take precedence over the values in the text anchor.
            a  := ( x ~= "i)left") ? 1+((( a-1)//3)*3) : ( x ~= "i)cent(er|re)") ? 2+((( a-1)//3)*3) : ( x ~= "i)right") ? 3+((( a-1)//3)*3) :  a
            a  := ( y ~= "i)top") ? 1+(mod( a-1,3)) : ( y ~= "i)cent(er|re)") ? 4+(mod( a-1,3)) : ( y ~= "i)bottom") ? 7+(mod( a-1,3)) :  a

            ; Convert English words to numbers. Don't mess with these values any further.
            ; Also, these values are relative to the background.
            x  := ( x ~= "i)left") ? _x : (x ~= "i)cent(er|re)") ? _x + 0.5*_w : (x ~= "i)right") ? _x + _w : x
            y  := ( y ~= "i)top") ? _y : (y ~= "i)cent(er|re)") ? _y + 0.5*_h : (y ~= "i)bottom") ? _y + _h : y

            ; Validate text x and y, convert to pixels.
            x  := ( x ~= valid) ? RegExReplace( x, "\s", "") : _x ; Default text x is background x.
            x  := ( x ~= "(pt|px)$") ? SubStr( x, 1, -2) :  x
            x  := ( x ~= "vw$") ? RegExReplace( x, "vw$", "") * this.vw :  x
            x  := ( x ~= "vh$") ? RegExReplace( x, "vh$", "") * this.vh :  x
            x  := ( x ~= "vmin$") ? RegExReplace( x, "vmin$", "") * this.vmin :  x
            x  := ( x ~= "%$") ? RegExReplace( x, "%$", "") * 0.01 * _w :  x

            y  := ( y ~= valid) ? RegExReplace( y, "\s", "") : _y ; Default text y is background y.
            y  := ( y ~= "(pt|px)$") ? SubStr( y, 1, -2) :  y
            y  := ( y ~= "vw$") ? RegExReplace( y, "vw$", "") * this.vw :  y
            y  := ( y ~= "vh$") ? RegExReplace( y, "vh$", "") * this.vh :  y
            y  := ( y ~= "vmin$") ? RegExReplace( y, "vmin$", "") * this.vmin :  y
            y  := ( y ~= "%$") ? RegExReplace( y, "%$", "") * 0.01 * _h :  y

            ; Modify text x and text y values with the anchor, so that the text has a new point of origin.
            ; The text anchor is relative to the text width and height before margin/padding.
            ; This is NOT relative to the background width and height.
            x  -= (mod(a-1,3) == 0) ? 0 : (mod(a-1,3) == 1) ? w/2 : (mod(a-1,3) == 2) ? w : 0
            y  -= (((a-1)//3) == 0) ? 0 : (((a-1)//3) == 1) ? h/2 : (((a-1)//3) == 2) ? h : 0

            ; Define margin and padding. Both parameters will leave the text unchanged,
            ; expanding the background box. The difference between the two is NON-EXISTENT.
            ; What does matter is if the margin/padding is a background style, the position of the text will not change.
            ; If the margin/padding is a text style, the text position will change.
            ; THERE REALLY IS NO DIFFERENCE BETWEEN MARGIN AND PADDING.
            _p := this.margin_and_padding(_p)
            _m := this.margin_and_padding(_m)
            p  := this.margin_and_padding( p)
            m  := this.margin_and_padding( m)

            ; Modify _x, _y, _w, _h with margin and padding, increasing the size of the background.
            if (_w || _h) {
               _w  += (_m.2 + _m.4 + _p.2 + _p.4) + (m.2 + m.4 + p.2 + p.4)
               _h  += (_m.1 + _m.3 + _p.1 + _p.3) + (m.1 + m.3 + p.1 + p.3)
               _x  -= (_m.4 + _p.4)
               _y  -= (_m.1 + _p.1)
            }

            ; If margin/padding are defined in the text parameter, shift the position of the text.
            x  += (m.4 + p.4)
            y  += (m.1 + p.1)

            ; Re-run: Condense Text using a Condensed Font if simulated text width exceeds screen width.
            if (Gdip_FontFamilyCreate(z)) {
               if (ReturnRC[3] + x > this.ScreenWidth) {
                  this._redrawBecauseOfCondensedFont := true
                  return this.Draw(text, style1, style2, pGraphics)
               }
            }

            ; Define radius of rounded corners.
            _r := (_r ~= valid_positive) ? RegExReplace(_r, "\s", "") : 0  ; Default radius is 0, or square corners.
            _r := (_r ~= "(pt|px)$") ? SubStr(_r, 1, -2) : _r
            _r := (_r ~= "vw$") ? RegExReplace(_r, "vw$", "") * this.vw : _r
            _r := (_r ~= "vh$") ? RegExReplace(_r, "vh$", "") * this.vh : _r
            _r := (_r ~= "vmin$") ? RegExReplace(_r, "vmin$", "") * this.vmin : _r
            ; percentage is defined as a percentage of the smaller background width/height.
            _r := (_r ~= "%$") ? RegExReplace(_r, "%$", "") * 0.01 * ((_w > _h) ? _h : _w) : _r
            ; the radius cannot exceed the half width or half height, whichever is smaller.
            _r  := (_r <= ((_w > _h) ? _h : _w) / 2) ? _r : 0

            ; Define color.
            _c := this.color(_c, 0xDD424242) ; Default background color is transparent gray.
            c  := this.color( c, 0xFFFFFFFF) ; Default text color is white.

            ; Define outline and dropShadow.
            o := this.outline(o, s, c)
            d := this.dropShadow(d, ReturnRC[3], ReturnRC[4], s)

            ; Round 9 - Define Text
            if (!A_IsUnicode){
               nSize := DllCall("MultiByteToWideChar", "uint",0, "uint",0, "ptr",&text, "int",-1, "ptr",0, "int",0)
               VarSetCapacity(wtext, nSize*2)
               DllCall("MultiByteToWideChar", "uint",0, "uint",0, "ptr",&text, "int",-1, "ptr",&wtext, "int",nSize)
            }

            ; Round 10 - Finalize _x, _y, _w, _h
            _x  := Round(_x)
            _y  := Round(_y)
            _w  := Round(_w)
            _h  := Round(_h)

            ; Define image boundaries using the background boundaries.
            this.x  := (this.x  = "" || _x < this.x) ? _x : this.x
            this.y  := (this.y  = "" || _y < this.y) ? _y : this.y
            this.xx := (this.xx = "" || _x + _w > this.xx) ? _x + _w : this.xx
            this.yy := (this.yy = "" || _y + _h > this.yy) ? _y + _h : this.yy

            ; Define image boundaries using the text boundaries + outline boundaries.
            artifacts := Ceil(o.3 + 0.5*o.1)
            this.x  := (x - artifacts < this.x) ? x - artifacts : this.x
            this.y  := (y - artifacts < this.y) ? y - artifacts : this.y
            this.xx := (x + w + artifacts > this.xx) ? x + w + artifacts : this.xx
            this.yy := (y + h + artifacts > this.yy) ? y + h + artifacts : this.yy

            ; Define image boundaries using the dropShadow boundaries.
            artifacts := Ceil(d.3 + d.6 + 0.5*o.1)
            this.x  := (x + d.1 - artifacts < this.x) ? x + d.1 - artifacts : this.x
            this.y  := (y + d.2 - artifacts < this.y) ? y + d.2 - artifacts : this.y
            this.xx := (x + d.1 + w + artifacts > this.xx) ? x + d.1 + w + artifacts : this.xx
            this.yy := (y + d.2 + h + artifacts > this.yy) ? y + d.2 + h + artifacts : this.yy

            ; Round to the nearest integer.
            this.x := Floor(this.x)
            this.y := Floor(this.y)
            this.xx := Ceil(this.xx)
            this.yy := Ceil(this.yy)

            ; Draw 1 - Background
            if (_w && _h && _c && (_c & 0xFF000000)) {
               if (_r == 0)
                  Gdip_SetSmoothingMode(pGraphics, 1) ; Turn antialiasing off if not a rounded rectangle.
               pBrushBackground := Gdip_BrushCreateSolid(_c)
               Gdip_FillRoundedRectangle(pGraphics, pBrushBackground, _x, _y, _w, _h, _r) ; DRAWING!
               Gdip_DeleteBrush(pBrushBackground)
               if (_r == 0)
                  Gdip_SetSmoothingMode(pGraphics, _q) ; Turn antialiasing on for text rendering.
            }

            ; Draw 2 - DropShadow
            if (!d.void) {
               offset2 := d.3 + d.6 + Ceil(0.5*o.1)

               if (d.3) {
                  DropShadow := Gdip_CreateBitmap(w + 2*offset2, h + 2*offset2)
                  DropShadowG := Gdip_GraphicsFromImage(DropShadow)
                  Gdip_SetSmoothingMode(DropShadowG, _q)
                  Gdip_SetTextRenderingHint(DropShadowG, q)
                  CreateRectF(RC, offset2, offset2, w + 2*offset2, h + 2*offset2)
               } else {
                  CreateRectF(RC, x + d.1, y + d.2, w, h)
                  DropShadowG := pGraphics
               }

               ; Literally draw the text. Then later a second version will be drawn over.
               ; This version that is drawn under is called the "shadow".
               if (o.void && d.6 == 0)
               {
                  pBrush := Gdip_BrushCreateSolid(d.4)
                  Gdip_DrawString(DropShadowG, Text, hFont, hFormat, pBrush, RC) ; DRAWING!
                  Gdip_DeleteBrush(pBrush)
               }
               else ; Fancy stuff occurs when outline and dropShadow parameters are set.
               {
                  ; Draw the outer edge of the text string.
                  DllCall("gdiplus\GdipCreatePath", "int",1, "uptr*",pPath)
                  DllCall("gdiplus\GdipAddPathString", "ptr",pPath, "ptr", A_IsUnicode ? &text : &wtext, "int",-1
                                                     , "ptr",hFamily, "int",style, "float",s, "ptr",&RC, "ptr",hFormat)
                  pPen := Gdip_CreatePen(d.4, 2*d.6 + o.1)
                  DllCall("gdiplus\GdipSetPenLineJoin", "ptr",pPen, "uint",2)
                  DllCall("gdiplus\GdipDrawPath", "ptr",DropShadowG, "ptr",pPen, "ptr",pPath)
                  Gdip_DeletePen(pPen)

                  ; Fill in the outline. Turn off antialiasing and alpha blending to the gaps are 100% filled.
                  pBrush := Gdip_BrushCreateSolid(d.4)
                  Gdip_SetCompositingMode(DropShadowG, 1) ; Turn off alpha blending
                  Gdip_SetSmoothingMode(DropShadowG, 3)   ; Turn off anti-aliasing
                  Gdip_FillPath(DropShadowG, pBrush, pPath)
                  Gdip_DeleteBrush(pBrush)
                  Gdip_DeletePath(pPath)
                  Gdip_SetCompositingMode(DropShadowG, 0)
                  Gdip_SetSmoothingMode(DropShadowG, _q)
               }

               if (d.3) {
                  Gdip_DeleteGraphics(DropShadowG)
                  this.GaussianBlur(DropShadow, d.3, d.5)
                  Gdip_SetInterpolationMode(pGraphics, 5) ; NearestNeighbor
                  Gdip_SetSmoothingMode(pGraphics, 3) ; Turn off anti-aliasing
                  Gdip_DrawImage(pGraphics, DropShadow, x + d.1 - offset2, y + d.2 - offset2, w + 2*offset2, h + 2*offset2) ; DRAWING!
                  Gdip_SetSmoothingMode(pGraphics, _q)
                  Gdip_DisposeImage(DropShadow)
               }
            }

            ; Draw 3 - Text Outline
            if (!o.void) {
               ; Convert our text to a path.
               CreateRectF(RC, x, y, w, h)
               DllCall("gdiplus\GdipCreatePath", "int",1, "uptr*",pPath)
               DllCall("gdiplus\GdipAddPathString", "ptr",pPath, "ptr", A_IsUnicode ? &text : &wtext, "int",-1
                                                  , "ptr",hFamily, "int",style, "float",s, "ptr",&RC, "ptr",hFormat)

               ; Create a glow effect around the edges.
               if (o.3) {
                  pPenGlow := Gdip_CreatePen(Format("0x{:02X}",((o.4 & 0xFF000000) >> 24)/o.3) . Format("{:06X}",(o.4 & 0x00FFFFFF)), 1)
                  DllCall("gdiplus\GdipSetPenLineJoin", "ptr",pPenGlow, "uInt",2)

                  loop % o.3
                  {
                     DllCall("gdiplus\GdipSetPenWidth", "ptr",pPenGlow, "float",o.1 + 2*A_Index)
                     DllCall("gdiplus\GdipDrawPath", "ptr",pGraphics, "ptr",pPenGlow, "ptr",pPath) ; DRAWING!
                  }
                  Gdip_DeletePen(pPenGlow)
               }

               ; Draw outline text.
               if (o.1) {
                  pPen := Gdip_CreatePen(o.2, o.1)
                  DllCall("gdiplus\GdipSetPenLineJoin", "ptr",pPen, "uint",2)
                  DllCall("gdiplus\GdipDrawPath", "ptr",pGraphics, "ptr",pPen, "ptr",pPath) ; DRAWING!
                  Gdip_DeletePen(pPen)
               }

               ; Fill outline text.
               if (c && (c & 0xFF000000)) {
                  pBrush := Gdip_BrushCreateSolid(c)
                  Gdip_FillPath(pGraphics, pBrush, pPath) ; DRAWING!
                  Gdip_DeleteBrush(pBrush)
               }
               Gdip_DeletePath(pPath)
            }

            ; Draw Text if outline is not are not specified.
            if (text != "" && o.void) {
               CreateRectF(RC, x, y, w, h)
               pBrushText := Gdip_BrushCreateSolid(c)
               Gdip_DrawString(pGraphics, A_IsUnicode ? text : wtext, hFont, hFormat, pBrushText, RC) ; DRAWING!
               Gdip_DeleteBrush(pBrushText)
            }

            ; Delete Font Objects.
            Gdip_DeleteStringFormat(hFormat)
            Gdip_DeleteFont(hFont)
            Gdip_DeleteFontFamily(hFamily)

            return (pGraphics == "") ? this : ""
         }

         color(c, default := 0xDD424242) {
            static colorRGB  := "^0x([0-9A-Fa-f]{6})$"
            static colorARGB := "^0x([0-9A-Fa-f]{8})$"
            static hex6      :=   "^([0-9A-Fa-f]{6})$"
            static hex8      :=   "^([0-9A-Fa-f]{8})$"

            if ObjGetCapacity([c], 1) {
               c  := (c ~= "^#") ? SubStr(c, 2) : c
               c  := ((___ := this.colorMap(c)) != "") ? ___ : c
               c  := (c ~= colorRGB) ? "0xFF" RegExReplace(c, colorRGB, "$1") : (c ~= hex8) ? "0x" c : (c ~= hex6) ? "0xFF" c : c
               c  := (c ~= colorARGB) ? c : default
            }
            return (c != "") ? c : default
         }

         dropShadow(d, x_simulated, y_simulated, font_size) {
            static valid := "^\s*(\-?\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            if IsObject(d) {
               d.1 := (d.1) ? d.1 : (d.horizontal != "") ? d.horizontal : d.h
               d.2 := (d.2) ? d.2 : (d.vertical   != "") ? d.vertical   : d.v
               d.3 := (d.3) ? d.3 : (d.blur       != "") ? d.blur       : d.b
               d.4 := (d.4) ? d.4 : (d.color      != "") ? d.color      : d.c
               d.5 := (d.5) ? d.5 : (d.opacity    != "") ? d.opacity    : d.o
               d.6 := (d.6) ? d.6 : (d.size       != "") ? d.size       : d.s
            } else if (d != "") {
               _ := RegExReplace(d, ":\s+", ":")
               _ := RegExReplace(_, "\s+", " ")
               _ := StrSplit(_, " ")
               _.1 := ((___ := RegExReplace(d, q1    "(h(orizontal)?)"    q2, "${value}")) != d) ? ___ : _.1
               _.2 := ((___ := RegExReplace(d, q1    "(v(ertical)?)"      q2, "${value}")) != d) ? ___ : _.2
               _.3 := ((___ := RegExReplace(d, q1    "(b(lur)?)"          q2, "${value}")) != d) ? ___ : _.3
               _.4 := ((___ := RegExReplace(d, q1    "(c(olor)?)"         q2, "${value}")) != d) ? ___ : _.4
               _.5 := ((___ := RegExReplace(d, q1    "(o(pacity)?)"       q2, "${value}")) != d) ? ___ : _.5
               _.6 := ((___ := RegExReplace(d, q1    "(s(ize)?)"          q2, "${value}")) != d) ? ___ : _.6
               d := _
            }
            else return {"void":true, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0}

            for key, value in d {
               if (key = 4) ; Don't mess with color data.
                  continue
               d[key] := (d[key] ~= valid) ? RegExReplace(d[key], "\s", "") : 0 ; Default for everything is 0.
               d[key] := (d[key] ~= "(pt|px)$") ? SubStr(d[key], 1, -2) : d[key]
               d[key] := (d[key] ~= "vw$") ? RegExReplace(d[key], "vw$", "") * this.vw : d[key]
               d[key] := (d[key] ~= "vh$") ? RegExReplace(d[key], "vh$", "") * this.vh : d[key]
               d[key] := (d[key] ~= "vmin$") ? RegExReplace(d[key], "vmin$", "") * this.vmin : d[key]
            }

            d.1 := (d.1 ~= "%$") ? SubStr(d.1, 1, -1) * 0.01 * x_simulated : d.1
            d.2 := (d.2 ~= "%$") ? SubStr(d.2, 1, -1) * 0.01 * y_simulated : d.2
            d.3 := (d.3 ~= "%$") ? SubStr(d.3, 1, -1) * 0.01 * font_size : d.3
            d.4 := this.color(d.4, 0xFFFF0000) ; Default color is red.
            d.5 := (d.5 ~= "%$") ? SubStr(d.5, 1, -1) / 100 : d.5
            d.5 := (d.5 <= 0 || d.5 > 1) ? 1 : d.5 ; Range Opacity is a float from 0-1.
            d.6 := (d.6 ~= "%$") ? SubStr(d.6, 1, -1) * 0.01 * font_size : d.6
            return d
         }

         outline(o, font_size, font_color) {
            static valid_positive := "^\s*(\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            if IsObject(o) {
               o.1 := (o.1) ? o.1 : (o.stroke != "") ? o.stroke : o.s
               o.2 := (o.2) ? o.2 : (o.color  != "") ? o.color  : o.c
               o.3 := (o.3) ? o.3 : (o.glow   != "") ? o.glow   : o.g
               o.4 := (o.4) ? o.4 : (o.tint   != "") ? o.tint   : o.t
            } else if (o != "") {
               _ := RegExReplace(o, ":\s+", ":")
               _ := RegExReplace(_, "\s+", " ")
               _ := StrSplit(_, " ")
               _.1 := ((___ := RegExReplace(o, q1    "(s(troke)?)"        q2, "${value}")) != o) ? ___ : _.1
               _.2 := ((___ := RegExReplace(o, q1    "(c(olor)?)"         q2, "${value}")) != o) ? ___ : _.2
               _.3 := ((___ := RegExReplace(o, q1    "(g(low)?)"          q2, "${value}")) != o) ? ___ : _.3
               _.4 := ((___ := RegExReplace(o, q1    "(t(int)?)"          q2, "${value}")) != o) ? ___ : _.4
               o := _
            }
            else return {"void":true, 1:0, 2:0, 3:0, 4:0}

            for key, value in o {
               if (key = 2) || (key = 4) ; Don't mess with color data.
                  continue
               o[key] := (o[key] ~= valid_positive) ? RegExReplace(o[key], "\s", "") : 0 ; Default for everything is 0.
               o[key] := (o[key] ~= "(pt|px)$") ? SubStr(o[key], 1, -2) : o[key]
               o[key] := (o[key] ~= "vw$") ? RegExReplace(o[key], "vw$", "") * this.vw : o[key]
               o[key] := (o[key] ~= "vh$") ? RegExReplace(o[key], "vh$", "") * this.vh : o[key]
               o[key] := (o[key] ~= "vmin$") ? RegExReplace(o[key], "vmin$", "") * this.vmin : o[key]
            }

            o.1 := (o.1 ~= "%$") ? SubStr(o.1, 1, -1) * 0.01 * font_size : o.1
            o.2 := this.color(o.2, font_color) ; Default color is the text font color.
            o.3 := (o.3 ~= "%$") ? SubStr(o.3, 1, -1) * 0.01 * font_size : o.3
            o.4 := this.color(o.4, o.2) ; Default color is outline color.
            return o
         }

         margin_and_padding(m, default := 0) {
            static valid := "^\s*(\-?\d+(?:\.\d*)?)\s*(%|pt|px|vh|vmin|vw)?\s*$"
            static q1 := "(?i)^.*?\b(?<!:|:\s)\b"
            static q2 := "(?!(?>\([^()]*\)|[^()]*)*\))(:\s*)?\(?(?<value>(?<=\()([\s:#%_a-z\-\.\d]+|\([\s:#%_a-z\-\.\d]*\))*(?=\))|[#%_a-z\-\.\d]+).*$"

            if IsObject(m) {
               m.1 := (m.top    != "") ? m.top    : m.t
               m.2 := (m.right  != "") ? m.right  : m.r
               m.3 := (m.bottom != "") ? m.bottom : m.b
               m.4 := (m.left   != "") ? m.left   : m.l
            } else if (m != "") {
               _ := RegExReplace(m, ":\s+", ":")
               _ := RegExReplace(_, "\s+", " ")
               _ := StrSplit(_, " ")
               _.1 := ((___ := RegExReplace(m, q1    "(t(op)?)"           q2, "${value}")) != m) ? ___ : _.1
               _.2 := ((___ := RegExReplace(m, q1    "(r(ight)?)"         q2, "${value}")) != m) ? ___ : _.2
               _.3 := ((___ := RegExReplace(m, q1    "(b(ottom)?)"        q2, "${value}")) != m) ? ___ : _.3
               _.4 := ((___ := RegExReplace(m, q1    "(l(eft)?)"          q2, "${value}")) != m) ? ___ : _.4
               m := _
            }
            else return {1:default, 2:default, 3:default, 4:default}

            ; Follow CSS guidelines for margin!
            if (m.2 == "" && m.3 == "" && m.4 == "")
               m.4 := m.3 := m.2 := m.1, exception := true
            if (m.3 == "" && m.4 == "")
               m.4 := m.2, m.3 := m.1
            if (m.4 == "")
               m.4 := m.2

            for key, value in m {
               m[key] := (m[key] ~= valid) ? RegExReplace(m[key], "\s", "") : default
               m[key] := (m[key] ~= "(pt|px)$") ? SubStr(m[key], 1, -2) : m[key]
               m[key] := (m[key] ~= "vw$") ? RegExReplace(m[key], "vw$", "") * this.vw : m[key]
               m[key] := (m[key] ~= "vh$") ? RegExReplace(m[key], "vh$", "") * this.vh : m[key]
               m[key] := (m[key] ~= "vmin$") ? RegExReplace(m[key], "vmin$", "") * this.vmin : m[key]
            }
            m.1 := (m.1 ~= "%$") ? SubStr(m.1, 1, -1) * this.vh : m.1
            m.2 := (m.2 ~= "%$") ? SubStr(m.2, 1, -1) * (exception ? this.vh : this.vw) : m.2
            m.3 := (m.3 ~= "%$") ? SubStr(m.3, 1, -1) * this.vh : m.3
            m.4 := (m.4 ~= "%$") ? SubStr(m.4, 1, -1) * (exception ? this.vh : this.vw) : m.4
            return m
         }

         colorMap(c) {
            static map

            if !(map) {
            color := [] ; 73 LINES MAX
            color["Clear"] := color["Off"] := color["None"] := color["Transparent"] := "0x00000000"

               color["AliceBlue"]             := "0xFFF0F8FF"
            ,  color["AntiqueWhite"]          := "0xFFFAEBD7"
            ,  color["Aqua"]                  := "0xFF00FFFF"
            ,  color["Aquamarine"]            := "0xFF7FFFD4"
            ,  color["Azure"]                 := "0xFFF0FFFF"
            ,  color["Beige"]                 := "0xFFF5F5DC"
            ,  color["Bisque"]                := "0xFFFFE4C4"
            ,  color["Black"]                 := "0xFF000000"
            ,  color["BlanchedAlmond"]        := "0xFFFFEBCD"
            ,  color["Blue"]                  := "0xFF0000FF"
            ,  color["BlueViolet"]            := "0xFF8A2BE2"
            ,  color["Brown"]                 := "0xFFA52A2A"
            ,  color["BurlyWood"]             := "0xFFDEB887"
            ,  color["CadetBlue"]             := "0xFF5F9EA0"
            ,  color["Chartreuse"]            := "0xFF7FFF00"
            ,  color["Chocolate"]             := "0xFFD2691E"
            ,  color["Coral"]                 := "0xFFFF7F50"
            ,  color["CornflowerBlue"]        := "0xFF6495ED"
            ,  color["Cornsilk"]              := "0xFFFFF8DC"
            ,  color["Crimson"]               := "0xFFDC143C"
            ,  color["Cyan"]                  := "0xFF00FFFF"
            ,  color["DarkBlue"]              := "0xFF00008B"
            ,  color["DarkCyan"]              := "0xFF008B8B"
            ,  color["DarkGoldenRod"]         := "0xFFB8860B"
            ,  color["DarkGray"]              := "0xFFA9A9A9"
            ,  color["DarkGrey"]              := "0xFFA9A9A9"
            ,  color["DarkGreen"]             := "0xFF006400"
            ,  color["DarkKhaki"]             := "0xFFBDB76B"
            ,  color["DarkMagenta"]           := "0xFF8B008B"
            ,  color["DarkOliveGreen"]        := "0xFF556B2F"
            ,  color["DarkOrange"]            := "0xFFFF8C00"
            ,  color["DarkOrchid"]            := "0xFF9932CC"
            ,  color["DarkRed"]               := "0xFF8B0000"
            ,  color["DarkSalmon"]            := "0xFFE9967A"
            ,  color["DarkSeaGreen"]          := "0xFF8FBC8F"
            ,  color["DarkSlateBlue"]         := "0xFF483D8B"
            ,  color["DarkSlateGray"]         := "0xFF2F4F4F"
            ,  color["DarkSlateGrey"]         := "0xFF2F4F4F"
            ,  color["DarkTurquoise"]         := "0xFF00CED1"
            ,  color["DarkViolet"]            := "0xFF9400D3"
            ,  color["DeepPink"]              := "0xFFFF1493"
            ,  color["DeepSkyBlue"]           := "0xFF00BFFF"
            ,  color["DimGray"]               := "0xFF696969"
            ,  color["DimGrey"]               := "0xFF696969"
            ,  color["DodgerBlue"]            := "0xFF1E90FF"
            ,  color["FireBrick"]             := "0xFFB22222"
            ,  color["FloralWhite"]           := "0xFFFFFAF0"
            ,  color["ForestGreen"]           := "0xFF228B22"
            ,  color["Fuchsia"]               := "0xFFFF00FF"
            ,  color["Gainsboro"]             := "0xFFDCDCDC"
            ,  color["GhostWhite"]            := "0xFFF8F8FF"
            ,  color["Gold"]                  := "0xFFFFD700"
            ,  color["GoldenRod"]             := "0xFFDAA520"
            ,  color["Gray"]                  := "0xFF808080"
            ,  color["Grey"]                  := "0xFF808080"
            ,  color["Green"]                 := "0xFF008000"
            ,  color["GreenYellow"]           := "0xFFADFF2F"
            ,  color["HoneyDew"]              := "0xFFF0FFF0"
            ,  color["HotPink"]               := "0xFFFF69B4"
            ,  color["IndianRed"]             := "0xFFCD5C5C"
            ,  color["Indigo"]                := "0xFF4B0082"
            ,  color["Ivory"]                 := "0xFFFFFFF0"
            ,  color["Khaki"]                 := "0xFFF0E68C"
            ,  color["Lavender"]              := "0xFFE6E6FA"
            ,  color["LavenderBlush"]         := "0xFFFFF0F5"
            ,  color["LawnGreen"]             := "0xFF7CFC00"
            ,  color["LemonChiffon"]          := "0xFFFFFACD"
            ,  color["LightBlue"]             := "0xFFADD8E6"
            ,  color["LightCoral"]            := "0xFFF08080"
            ,  color["LightCyan"]             := "0xFFE0FFFF"
            ,  color["LightGoldenRodYellow"]  := "0xFFFAFAD2"
            ,  color["LightGray"]             := "0xFFD3D3D3"
            ,  color["LightGrey"]             := "0xFFD3D3D3"
               color["LightGreen"]            := "0xFF90EE90"
            ,  color["LightPink"]             := "0xFFFFB6C1"
            ,  color["LightSalmon"]           := "0xFFFFA07A"
            ,  color["LightSeaGreen"]         := "0xFF20B2AA"
            ,  color["LightSkyBlue"]          := "0xFF87CEFA"
            ,  color["LightSlateGray"]        := "0xFF778899"
            ,  color["LightSlateGrey"]        := "0xFF778899"
            ,  color["LightSteelBlue"]        := "0xFFB0C4DE"
            ,  color["LightYellow"]           := "0xFFFFFFE0"
            ,  color["Lime"]                  := "0xFF00FF00"
            ,  color["LimeGreen"]             := "0xFF32CD32"
            ,  color["Linen"]                 := "0xFFFAF0E6"
            ,  color["Magenta"]               := "0xFFFF00FF"
            ,  color["Maroon"]                := "0xFF800000"
            ,  color["MediumAquaMarine"]      := "0xFF66CDAA"
            ,  color["MediumBlue"]            := "0xFF0000CD"
            ,  color["MediumOrchid"]          := "0xFFBA55D3"
            ,  color["MediumPurple"]          := "0xFF9370DB"
            ,  color["MediumSeaGreen"]        := "0xFF3CB371"
            ,  color["MediumSlateBlue"]       := "0xFF7B68EE"
            ,  color["MediumSpringGreen"]     := "0xFF00FA9A"
            ,  color["MediumTurquoise"]       := "0xFF48D1CC"
            ,  color["MediumVioletRed"]       := "0xFFC71585"
            ,  color["MidnightBlue"]          := "0xFF191970"
            ,  color["MintCream"]             := "0xFFF5FFFA"
            ,  color["MistyRose"]             := "0xFFFFE4E1"
            ,  color["Moccasin"]              := "0xFFFFE4B5"
            ,  color["NavajoWhite"]           := "0xFFFFDEAD"
            ,  color["Navy"]                  := "0xFF000080"
            ,  color["OldLace"]               := "0xFFFDF5E6"
            ,  color["Olive"]                 := "0xFF808000"
            ,  color["OliveDrab"]             := "0xFF6B8E23"
            ,  color["Orange"]                := "0xFFFFA500"
            ,  color["OrangeRed"]             := "0xFFFF4500"
            ,  color["Orchid"]                := "0xFFDA70D6"
            ,  color["PaleGoldenRod"]         := "0xFFEEE8AA"
            ,  color["PaleGreen"]             := "0xFF98FB98"
            ,  color["PaleTurquoise"]         := "0xFFAFEEEE"
            ,  color["PaleVioletRed"]         := "0xFFDB7093"
            ,  color["PapayaWhip"]            := "0xFFFFEFD5"
            ,  color["PeachPuff"]             := "0xFFFFDAB9"
            ,  color["Peru"]                  := "0xFFCD853F"
            ,  color["Pink"]                  := "0xFFFFC0CB"
            ,  color["Plum"]                  := "0xFFDDA0DD"
            ,  color["PowderBlue"]            := "0xFFB0E0E6"
            ,  color["Purple"]                := "0xFF800080"
            ,  color["RebeccaPurple"]         := "0xFF663399"
            ,  color["Red"]                   := "0xFFFF0000"
            ,  color["RosyBrown"]             := "0xFFBC8F8F"
            ,  color["RoyalBlue"]             := "0xFF4169E1"
            ,  color["SaddleBrown"]           := "0xFF8B4513"
            ,  color["Salmon"]                := "0xFFFA8072"
            ,  color["SandyBrown"]            := "0xFFF4A460"
            ,  color["SeaGreen"]              := "0xFF2E8B57"
            ,  color["SeaShell"]              := "0xFFFFF5EE"
            ,  color["Sienna"]                := "0xFFA0522D"
            ,  color["Silver"]                := "0xFFC0C0C0"
            ,  color["SkyBlue"]               := "0xFF87CEEB"
            ,  color["SlateBlue"]             := "0xFF6A5ACD"
            ,  color["SlateGray"]             := "0xFF708090"
            ,  color["SlateGrey"]             := "0xFF708090"
            ,  color["Snow"]                  := "0xFFFFFAFA"
            ,  color["SpringGreen"]           := "0xFF00FF7F"
            ,  color["SteelBlue"]             := "0xFF4682B4"
            ,  color["Tan"]                   := "0xFFD2B48C"
            ,  color["Teal"]                  := "0xFF008080"
            ,  color["Thistle"]               := "0xFFD8BFD8"
            ,  color["Tomato"]                := "0xFFFF6347"
            ,  color["Turquoise"]             := "0xFF40E0D0"
            ,  color["Violet"]                := "0xFFEE82EE"
            ,  color["Wheat"]                 := "0xFFF5DEB3"
            ,  color["White"]                 := "0xFFFFFFFF"
            ,  color["WhiteSmoke"]            := "0xFFF5F5F5"
               color["Yellow"]                := "0xFFFFFF00"
            ,  color["YellowGreen"]           := "0xFF9ACD32"
            map := color
            }

            return map[c]
         }

         GaussianBlur(ByRef pBitmap, radius, opacity := 1) {
            static x86 := "
            (LTrim
            VYnlV1ZTg+xci0Uci30c2UUgx0WsAwAAAI1EAAGJRdiLRRAPr0UYicOJRdSLRRwP
            r/sPr0UYiX2ki30UiUWoi0UQjVf/i30YSA+vRRgDRQgPr9ONPL0SAAAAiUWci0Uc
            iX3Eg2XE8ECJVbCJRcCLRcSJZbToAAAAACnEi0XEiWXk6AAAAAApxItFxIllzOgA
            AAAAKcSLRaiJZcjHRdwAAAAAx0W8AAAAAIlF0ItFvDtFFA+NcAEAAItV3DHAi12c
            i3XQiVXgAdOLfQiLVdw7RRiNDDp9IQ+2FAGLTcyLfciJFIEPtgwDD69VwIkMh4tN
            5IkUgUDr0THSO1UcfBKLXdwDXQzHRbgAAAAAK13Q6yAxwDtFGH0Ni33kD7YcAQEc
            h0Dr7kIDTRjrz/9FuAN1GItF3CtF0AHwiceLRbg7RRx/LDHJO00YfeGLRQiLfcwB
            8A+2BAgrBI+LfeQDBI+ZiQSPjTwz933YiAQPQevWi0UIK0Xci03AAfCJRbiLXRCJ
            /itdHCt13AN14DnZfAgDdQwrdeDrSot1DDHbK3XcAf4DdeA7XRh9KItV4ItFuAHQ
            A1UID7YEGA+2FBop0ItV5AMEmokEmpn3fdiIBB5D69OLRRhBAUXg66OLRRhDAUXg
            O10QfTIxyTtNGH3ti33Ii0XgA0UID7YUCIsEjynQi1XkAwSKiQSKi1XgjTwWmfd9
            2IgED0Hr0ItF1P9FvAFF3AFF0OmE/v//i0Wkx0XcAAAAAMdFvAAAAACJRdCLRbAD
            RQyJRaCLRbw7RRAPjXABAACLTdwxwItdoIt10IlN4AHLi30Mi1XcO0UYjQw6fSEP
            thQBi33MD7YMA4kUh4t9yA+vVcCJDIeLTeSJFIFA69Ex0jtVHHwSi13cA10Ix0W4
            AAAAACtd0OsgMcA7RRh9DYt95A+2HAEBHIdA6+5CA03U68//RbgDddSLRdwrRdAB
            8InHi0W4O0UcfywxyTtNGH3hi0UMi33MAfAPtgQIKwSPi33kAwSPmYkEj408M/d9
            2IgED0Hr1otFDCtF3ItNwAHwiUW4i10Uif4rXRwrddwDdeA52XwIA3UIK3Xg60qL
            dQgx2yt13AH+A3XgO10YfSiLVeCLRbgB0ANVDA+2BBgPthQaKdCLVeQDBJqJBJqZ
            933YiAQeQ+vTi0XUQQFF4Ouji0XUQwFF4DtdFH0yMck7TRh97Yt9yItF4ANFDA+2
            FAiLBI+LfeQp0ItV4AMEj4kEj408Fpn3fdiIBA9B69CLRRj/RbwBRdwBRdDphP7/
            //9NrItltA+Fofz//9no3+l2PzHJMds7XRR9OotFGIt9CA+vwY1EBwMx/zt9EH0c
            D7Yw2cBHVtoMJFrZXeTzDyx15InyiBADRRjr30MDTRDrxd3Y6wLd2I1l9DHAW15f
            XcM=
            )"
            static x64 := "
            (LTrim
            VUFXQVZBVUFUV1ZTSIHsqAAAAEiNrCSAAAAARIutkAAAAIuFmAAAAESJxkiJVRhB
            jVH/SYnPi42YAAAARInHQQ+v9Y1EAAErvZgAAABEiUUARIlN2IlFFEljxcdFtAMA
            AABIY96LtZgAAABIiUUID6/TiV0ESIld4A+vy4udmAAAAIl9qPMPEI2gAAAAiVXQ
            SI0UhRIAAABBD6/1/8OJTbBIiVXoSINl6PCJXdxBifaJdbxBjXD/SWPGQQ+v9UiJ
            RZhIY8FIiUWQiXW4RInOK7WYAAAAiXWMSItF6EiJZcDoAAAAAEgpxEiLRehIieHo
            AAAAAEgpxEiLRehIiWX46AAAAABIKcRIi0UYTYn6SIll8MdFEAAAAADHRdQAAAAA
            SIlFyItF2DlF1A+NqgEAAESLTRAxwEWJyEQDTbhNY8lNAflBOcV+JUEPthQCSIt9
            +EUPthwBSItd8IkUhw+vVdxEiRyDiRSBSP/A69aLVRBFMclEO42YAAAAfA9Ii0WY
            RTHbMdtNjSQC6ytMY9oxwE0B+0E5xX4NQQ+2HAMBHIFI/8Dr7kH/wUQB6uvGTANd
            CP/DRQHoO52YAAAAi0W8Ro00AH82SItFyEuNPCNFMclJjTQDRTnNftRIi1X4Qg+2
            BA9CKwSKQgMEiZlCiQSJ930UQogEDkn/wevZi0UQSWP4SAN9GItd3E1j9kUx200B
            /kQpwIlFrEiJfaCLdaiLRaxEAcA580GJ8XwRSGP4TWPAMdtMAf9MA0UY60tIi0Wg
            S408Hk+NJBNFMclKjTQYRTnNfiFDD7YUDEIPtgQPKdBCAwSJmUKJBIn3fRRCiAQO
            Sf/B69r/w0UB6EwDXQjrm0gDXQhB/8FEO00AfTRMjSQfSY00GEUx20U53X7jSItF
            8EMPthQcQosEmCnQQgMEmZlCiQSZ930UQogEHkn/w+vXi0UEAUUQSItF4P9F1EgB
            RchJAcLpSv7//0yLVRhMiX3Ix0UQAAAAAMdF1AAAAACLRQA5RdQPja0BAABEi00Q
            McBFichEA03QTWPJTANNGEE5xX4lQQ+2FAJIi3X4RQ+2HAFIi33wiRSGD69V3ESJ
            HIeJFIFI/8Dr1otVEEUxyUQ7jZgAAAB8D0iLRZBFMdsx202NJALrLUxj2kwDXRgx
            wEE5xX4NQQ+2HAMBHIFI/8Dr7kH/wQNVBOvFRANFBEwDXeD/wzudmAAAAItFsEaN
            NAB/NkiLRchLjTwjRTHJSY00A0U5zX7TSItV+EIPtgQPQisEikIDBImZQokEifd9
            FEKIBA5J/8Hr2YtFEE1j9klj+EwDdRiLXdxFMdtEKcCJRaxJjQQ/SIlFoIt1jItF
            rEQBwDnzQYnxfBFNY8BIY/gx20gDfRhNAfjrTEiLRaBLjTweT40kE0UxyUqNNBhF
            Oc1+IUMPthQMQg+2BA8p0EIDBImZQokEifd9FEKIBA5J/8Hr2v/DRANFBEwDXeDr
            mkgDXeBB/8FEO03YfTRMjSQfSY00GEUx20U53X7jSItF8EMPthQcQosEmCnQQgME
            mZlCiQSZ930UQogEHkn/w+vXSItFCP9F1EQBbRBIAUXISQHC6Uf+////TbRIi2XA
            D4Ui/P//8w8QBQAAAAAPLsF2TTHJRTHARDtF2H1Cicgx0kEPr8VImEgrRQhNjQwH
            McBIA0UIO1UAfR1FD7ZUAQP/wvNBDyrC8w9ZwfNEDyzQRYhUAQPr2kH/wANNAOu4
            McBIjWUoW15fQVxBXUFeQV9dw5CQkJCQkJCQkJCQkJAAAIA/
            )"
            width := Gdip_GetImageWidth(pBitmap)
            height := Gdip_GetImageHeight(pBitmap)
            clone := Gdip_CloneBitmapArea(pBitmap, 0, 0, width, height)
            E1 := Gdip_LockBits(pBitmap, 0, 0, width, height, Stride1, Scan01, BitmapData1)
            E2 := Gdip_LockBits(clone, 0, 0, width, height, Stride2, Scan02, BitmapData2)

            DllCall("crypt32\CryptStringToBinary", "str",(A_PtrSize == 8) ? x64 : x86, "uint",0, "uint",0x1, "ptr",0, "uint*",s, "ptr",0, "ptr",0)
            p := DllCall("GlobalAlloc", "uint",0, "ptr",s, "ptr")
            if (A_PtrSize == 8)
               DllCall("VirtualProtect", "ptr",p, "ptr",s, "uint",0x40, "uint*",op)
            DllCall("crypt32\CryptStringToBinary", "str",(A_PtrSize == 8) ? x64 : x86, "uint",0, "uint",0x1, "ptr",p, "uint*",s, "ptr",0, "ptr",0)
            value := DllCall(p, "ptr",Scan01, "ptr",Scan02, "uint",width, "uint",height, "uint",4, "uint",radius, "float",opacity)
            DllCall("GlobalFree", "ptr", p)

            Gdip_UnlockBits(pBitmap, BitmapData1)
            Gdip_UnlockBits(clone, BitmapData2)
            Gdip_DisposeImage(clone)
            return value
         }

         outer[]
         {
            get {
               ; Determine if there is a parent class. this.__class will retrive the
               ; current instance's class name. Array notation [] will dereference.
               ; Returns void if this function is not nested in at least 2 classes.
               if ((_class := RegExReplace(this.__class, "^(.*)\..*$", "$1")) != this.__class)
                  Loop, Parse, _class, .
                     outer := (A_Index=1) ? %A_LoopField% : outer[A_LoopField]
               return outer
            }
         }

         x1() {
            return this.x
         }

         y1() {
            return this.y
         }

         x2() {
            return this.xx
         }

         y2() {
            return this.yy
         }

         width() {
            return this.xx - this.x
         }

         height() {
            return this.yy - this.y
         }
      } ; End of Subtitle class.

      inner[]
      {
         get {
            ; Gets a reference to the current class.
            ; Returns void if this function is not nested in a class.
            if (_class := this.__class)
               Loop, Parse, _class, .
                  inner := (A_Index=1) ? %A_LoopField% : inner[A_LoopField]
            return inner
         }
      }
   }

   class provider {

      ; https://cloud.google.com/vision/docs/supported-files
      ; Supported Image Formats
      ; JPEG, PNG8, PNG24, GIF, Animated GIF (first frame only)
      ; BMP, WEBP, RAW, ICO
      ; Maximum Image Size - 4 MB
      ; Maximum Size per Request - 8 MB
      ; Compression to 640 x 480 - LABEL_DETECTION

      class Google extends Vis2.functor {
         static api := true
         ; Cloud Platform Console Help - Setting up API keys
         ; Step 1: https://support.google.com/cloud/answer/6158862?hl=en
         ; Step 2: https://cloud.google.com/vision/docs/before-you-begin

         ; You must enter billing information to use the Cloud Vision API.
         ; https://cloud.google.com/vision/pricing
         ; First 1000 LABEL_DETECTION per month is free.

         ; Please enter your api_key for Google Cloud Vision API.
         ; static api_key := "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
         ; FOR SAFETY REASONS, DO NOT PASTE YOUR API KEY HERE.
         ; Instead, keep your api_key in a separate file, "Vis2_API.txt"

         call(self, api_key:=""){
            if (api_key != "")
               this.inner.api_key := api_key
            return this
         }

         getCredentials(error:=""){
            if (error != "") {
               (Vis2.obj) ? Vis2.core.ux.suspend() : ""
               InputBox, api_key, Vis2.GoogleCloudVision.ImageIdentify, Enter your api_key for GoogleCloudVision.
               (Vis2.obj) ? Vis2.core.ux.resume() : ""
               FileAppend, GoogleCloudVision=%api_key%, Vis2_API.txt
               return api_key
            }

            if (this.api_key ~= "^X{39}$") {
               if FileExist("Vis2_API.txt") {
                  file := FileOpen("Vis2_API.txt", "r")
                  keys := file.Read()
                  api_key := ((___ := RegExReplace(keys, "s)^.*?GoogleCloudVision(?:\s*)=(?:\s*)([A-Za-z0-9\-]+).*$", "$1")) != keys) ? ___ : ""
                  file.close()

                  if (api_key != "")
                     return api_key
               }
            }
            else
               return this.api_key
         }

         request(base64, extension, models*){
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            if (api_key := this.getCredentials())
               whr.Open("POST", "https://vision.googleapis.com/v1/images:annotate?key=" api_key, true)
            else
               whr.Open("POST", "https://cxl-services.appspot.com/proxy?url=https%3A%2F%2Fvision.googleapis.com%2Fv1%2Fimages%3Aannotate", true)
            whr.SetRequestHeader("Accept", "*/*")
            whr.SetRequestHeader("Origin", "https://cloud.google.com")
            whr.SetRequestHeader("Content-Type", "text/plain;charset=UTF-8")
            whr.SetRequestHeader("Referer", "https://cloud.google.com/vision/")
            whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36")

            req := {"requests":[]}
            req.requests[1] := {"features":[], "image":{}, "imageContext":{}}
            for i, model in models
               req.requests[1].features.push({"type":model, "maxResults":50})
            req.requests[1].image.content := base64
            req.requests[1].imageContext.cropHintsParams := {"aspectRatios":[0.8, 1.0, 1.2]}

            whr.Send(JSON.Dump(req))
            whr.WaitForResponse()
            ado          := ComObjCreate("adodb.stream")
            ado.Type     := 1
            ado.Mode     := 3
            ado.Open()
            ado.Write(whr.ResponseBody)
            ado.Position := 0
            ado.Type     := 2
            ado.Charset  := "UTF-8"
            best := ado.ReadText()
            ado.Close()
            try reply := JSON.Load(best)
            catch
               this.getCredentials(best)
            return reply
         }

         ; Vis2.provider.Google.Describe()
         class Describe extends Vis2.functor{
         }

         ; Vis2.provider.Google.ImageIdentify()
         class ImageIdentify extends Vis2.functor {
            static extension := "jpg", compression := "75"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"Google: Image Identification Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := "") {
               process := new Vis2.Graphics.Picture()
               if !(type := process.DontVerifyImageType(image))
                  type := process.ImageType(image)
               if (type = "base64" && !process.isScreenshot(crop))
                  return image
               pBitmap := process.toBitmap(type, image)
               if process.isScreenshot(crop){
                  pBitmap2 := process.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.imageData := process.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || process.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               process.Destroy()
               process := ""
               return this.imageData
            }

            convert(base64, option := ""){
               reply := this.outer.request(base64, this.extension, "LABEL_DETECTION")
               obj := {}
               for i, value in reply.responses[1].labelAnnotations {
                  value.category := value.description
                  value.score    := value.score
                  obj.push(value)
               }
               obj := Vis2.stdlib.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : "`r`n") . v.category ", " Format("{:#.3f}", v.score)
               }
               data := sentence2
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.provider.Google.TextRecognize()
         class TextRecognize extends Vis2.functor {
            static extension := "png"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"Google: Text Recognition Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := "") {
               process := new Vis2.Graphics.Picture()
               if !(type := process.DontVerifyImageType(image))
                  type := process.ImageType(image)
               if (type = "base64" && !process.isScreenshot(crop))
                  return image
               pBitmap := process.toBitmap(type, image)
               if process.isScreenshot(crop){
                  pBitmap2 := process.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.imageData := process.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || process.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               process.Destroy()
               process := ""
               return this.imageData
            }

            convert(base64, option := ""){
               ; Note: DOCUMENT_TEXT_DETECTION will take precedence over TEXT_DETECTION
               reply := this.outer.request(base64, this.extension, "DOCUMENT_TEXT_DETECTION", "TEXT_DETECTION")

               ; Get text from both models. I'm not sure if the text is the same.
               if !(data := reply.responses[1].fullTextAnnotation.text)
                  data := reply.responses[1].textAnnotations[1].description

               ; Extract blocks of text: Full sentences or sections, not individual words.
               obj := {}
               for i, block in reply.responses[1].fullTextAnnotation.pages[1].blocks {
                  ; Begin constructing blocks of text from symbols.
                  text := ""
                  for j, paragraph in block.paragraphs {
                     text .= (j == 1) ? "" : "`r`n"
                     for k, word in block.paragraphs[j].words {
                        text .= (k == 1) ? "" : " "
                        for l, symbol in block.paragraphs[j].words[k].symbols {
                           text .= symbol.text
                        }
                     }
                  }

                  ; Standardize objects
                  block.category := text
                  block.score    := block.confidence
                  block.polygon  := block.boundingBox.vertices
                  obj.push(block)
               }

               data := RegExReplace(data, "(?<!\r)\n", "`r`n") ; LF to CRLF
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }
      }

      class IBM {
         static api := true

         request(base64, extension){
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.Open("POST", "https://watson-visual-recognition-duo-dev.ng.bluemix.net/api/classify", true)
            whr.SetRequestHeader("Accept", "application/json")
            whr.SetRequestHeader("Origin", "https://watson-visual-recognition-duo-dev.ng.bluemix.net")
            whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36")
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.SetRequestHeader("Referer", "https://watson-visual-recognition-duo-dev.ng.bluemix.net/")

            req := {"type":"file", "image_file":"data:image/" extension ";base64," base64}

            whr.Send(JSON.Dump(req))
            whr.WaitForResponse()
            return JSON.Load(whr.ResponseText)
         }

         ; Vis2.provider.IBM.ExplicitContent()
         class ExplicitContent extends Vis2.functor {
            static extension := "jpg", compression := "75"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"IBM: Explicit Content Detection Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := ""){
               Vis2.Graphics.Startup()
               if !(type := Vis2.preprocess.DontVerifyImageType(image))
                  if !(type := Vis2.preprocess.ImageType(image))
                     throw Exception("Ensure that the reference to an image is valid.")
               if (type = "base64" && !Vis2.stdlib.isScreenshot(crop))
                  return image
               pBitmap := Vis2.preprocess.toBitmap(type, image)
               if Vis2.stdlib.isScreenshot(crop){
                  pBitmap2 := Vis2.stdlib.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.base64 := Vis2.stdlib.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || Vis2.stdlib.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               Vis2.Graphics.Shutdown()
               return this.base64
            }

            convert(base64, option := ""){
               reply := this.outer.request(base64, this.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "explicit")
                     for j, value in reply[i].classes {
                        value.category := value.class
                        value.score    := value.score
                        obj.push(value)
                     }

               obj := Vis2.stdlib.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : ", ") . v.category " " Format("{:#.3f}", v.score)
               }

               data := sentence2
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.provider.IBM.FindFaces()
         class FindFaces extends Vis2.functor {
            static extension := "jpg", compression := "75"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"IBM: Face Detection Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := ""){
               Vis2.Graphics.Startup()
               if !(type := Vis2.preprocess.DontVerifyImageType(image))
                  if !(type := Vis2.preprocess.ImageType(image))
                     throw Exception("Ensure that the reference to an image is valid.")
               if (type = "base64" && !Vis2.stdlib.isScreenshot(crop))
                  return image
               pBitmap := Vis2.preprocess.toBitmap(type, image)
               if Vis2.stdlib.isScreenshot(crop){
                  pBitmap2 := Vis2.stdlib.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.base64 := Vis2.stdlib.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || Vis2.stdlib.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               Vis2.Graphics.Shutdown()
               return this.base64
            }

            /*
            {
             "classifier_id": "faces",
             "display": "Face Model",
             "description": "Locate faces within an image and assess gender and age.",
             "faces": [
               {
                 "age": {
                    "min": 23,
                    "max": 26,
                    "score": 0.7395025
                 },
                 "face_location": {
                    "height": 90,
                    "width": 79,
                    "left": 358,
                    "top": 83
                 },
                 "gender": {
                    "gender": "FEMALE",
                    "score": 0.9999887
                 }
               }
             ]
            },
            */

            convert(base64, option := ""){
               reply := this.outer.request(base64, this.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "faces")
                     for j, value in reply[i].faces {
                        value.category := Format("{:i}", (value.age.max + value.age.min)/2) " year old " Format("{:L}", value.gender.gender)
                        value.location := {"x":value.face_location.left, "y":value.face_location.top, "w":value.face_location.width, "h":value.face_location.height}
                        obj.push(value)
                     }

               obj := Vis2.stdlib.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : ", ") . v.category " " Format("{:#.3f}", v.score)
               }

               data := sentence
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.provider.IBM.ImageIdentify()
         class ImageIdentify extends Vis2.functor {
            static extension := "jpg", compression := "75"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"IBM: Image Identification Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := "") {
               process := new Vis2.Graphics.Picture()
               if !(type := process.DontVerifyImageType(image))
                  type := process.ImageType(image)
               if (type = "base64" && !process.isScreenshot(crop))
                  return image
               pBitmap := process.toBitmap(type, image)
               if process.isScreenshot(crop){
                  pBitmap2 := process.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.imageData := process.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || process.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               process.Destroy()
               process := ""
               return this.imageData
            }

            convert(base64, option := ""){
               reply := this.outer.request(base64, this.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "default")
                     for j, value in reply[i].classes {
                        value.category := value.class
                        value.score    := value.score
                        obj.push(value)
                     }

               obj := Vis2.stdlib.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : "`r`n") . v.category ", " Format("{:#.3f}", v.score)
               }

               data := sentence2
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.provider.IBM.TextRecognize()
         class TextRecognize extends Vis2.functor {
            static extension := "png"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"IBM: Text Recognition Tool", "splashImage":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := ""){
               Vis2.Graphics.Startup()
               if !(type := Vis2.preprocess.DontVerifyImageType(image))
                  if !(type := Vis2.preprocess.ImageType(image))
                     throw Exception("Ensure that the reference to an image is valid.")
               if (type = "base64" && !Vis2.stdlib.isScreenshot(crop))
                  return image
               pBitmap := Vis2.preprocess.toBitmap(type, image)
               if Vis2.stdlib.isScreenshot(crop){
                  pBitmap2 := Vis2.stdlib.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.base64 := Vis2.stdlib.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               if (type != "pBitmap" || Vis2.stdlib.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               Vis2.Graphics.Shutdown()
               return this.base64
            }
            /*
            {
               "classifier_id": "text",
               "display": "Text Model (private beta)",
               "description": "Extract text from natural scene images. To learn more, please contact sragarwa@us.ibm.com with a screenshot of the results.",
               "image": "7976da80-3d15-11e8-8328-7140922c1cd9.jpg",
               "text": "if ive learned anything\nfrom video games it is\nthat when you meet\nenemies it means that\nyoure going in the right\ndirection\nreally inspiring\nthats",
               "words": [
                  {
                     "word": "if",
                     "location": {
                        "width": 41,
                        "height": 59,
                        "left": 255,
                        "top": 33
                     },
                     "score": 0.9536,
                     "line_number": 0
                  },
                  {
                     "word": "ive",
                     "location": {
                        "width": 110,
                        "height": 61,
                        "left": 315,
                        "top": 33
                     },
                     "score": 0.9635,
                     "line_number": 0
                  },
                  {
                     "word": "learned",
                     "location": {
                        "width": 237,
                        "height": 58,
                        "left": 446,
                        "top": 35
                     },
                     "score": 0.9728,
                     "line_number": 0
                  },
                  {
                     "word": "anything",
                     "location": {
                        "width": 301,
                        "height": 125,
                        "left": 692,
                        "top": 0
                     },
                     "score": 0.9779,
                     "line_number": 0
                  },
                  {
                     "word": "from",
                     "location": {
                        "width": 147,
                        "height": 74,
                        "left": 250,
                        "top": 138
                     },
                     "score": 0.9558,
                     "line_number": 1
                  },
                  {
                     "word": "video",
                     "location": {
                        "width": 192,
                        "height": 67,
                        "left": 407,
                        "top": 134
                     },
                     "score": 0.9779,
                     "line_number": 1
                  },
                  {
                     "word": "games",
                     "location": {
                        "width": 256,
                        "height": 115,
                        "left": 596,
                        "top": 124
                     },
                     "score": 0.9246,
                     "line_number": 1
                  },
                  {
                     "word": "it",
                     "location": {
                        "width": 35,
                        "height": 58,
                        "left": 866,
                        "top": 147
                     },
                     "score": 0.9788,
                     "line_number": 1
                  },
                  {
                     "word": "is",
                     "location": {
                        "width": 53,
                        "height": 62,
                        "left": 921,
                        "top": 144
                     },
                     "score": 0.9794,
                     "line_number": 1
                  },
                  {
                     "word": "that",
                     "location": {
                        "width": 120,
                        "height": 58,
                        "left": 253,
                        "top": 260
                     },
                     "score": 0.9722,
                     "line_number": 2
                  },
                  {
                     "word": "when",
                     "location": {
                        "width": 192,
                        "height": 108,
                        "left": 380,
                        "top": 238
                     },
                     "score": 0.9718,
                     "line_number": 2
                  },
                  {
                     "word": "you",
                     "location": {
                        "width": 116,
                        "height": 61,
                        "left": 583,
                        "top": 272
                     },
                     "score": 0.9832,
                     "line_number": 2
                  },
            */
            convert(base64, option := ""){
               reply := this.outer.request(base64, this.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "text") {
                     data := reply[i].text
                     for j, value in reply[i].words {
                        value.category := value.class
                        value.score    := value.score
                        obj.push(value)
                     }
                  }

               data := RegExReplace(data, "(?<!\r)\n", "`r`n")
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }
      }

      class Tesseract {

         static leptonica := A_ScriptDir "\provider\leptonica_util\leptonica_util.exe"
         static tesseract := A_ScriptDir "\provider\tesseract\tesseract.exe"
         static tessdata_best := A_ScriptDir "\provider\tesseract\tessdata_best"
         static tessdata_fast := A_ScriptDir "\provider\tesseract\tessdata_fast"

         ; Vis2.provider.Tesseract.TextRecognize()
         class TextRecognize extends Vis2.functor {
            uuid := Vis2.stdlib.CreateUUID()
            temp1 := A_Temp "\Vis2_screenshot" this.uuid ".bmp"
            temp2 := A_Temp "\Vis2_preprocess" this.uuid ".tif"
            temp3 := A_Temp "\Vis2_text" this.uuid ".tsv"

            call(self, image:="", option:="", crop:=""){
               instance := new this
               if (image == "")
                  return Vis2.core.returnData({"provider":instance, "option":option, "tooltip":"Tesseract: Optical Character Recognition Tool", "textPreview":true})
               else
                  return instance.convert(instance.preprocess(image, crop), option)
            }

            preprocess(image, crop := ""){
               process := new Vis2.Graphics.Picture()
               if !(type := process.DontVerifyImageType(image))
                  type := process.ImageType(image)
               if (type = "file" && !process.isScreenshot(crop)) ;POSSIBLY BITMAP ONLY?
                  return image
               pBitmap := process.toBitmap(type, image)
               if process.isScreenshot(crop){
                  pBitmap2 := process.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2s
               }
               Gdip_SaveBitmapToFile(pBitmap, this.temp1, this.compression)
               if (type != "pBitmap" || process.isScreenshot(crop))
                  Gdip_DisposeImage(pBitmap)
               process.Destroy()
               process := ""

               static ocrPreProcessing := 1
               static negateArg := 2
               static performScaleArg := 1
               static scaleFactor := 3.5

               if !(FileExist(this.outer.leptonica))
                  throw Exception("Leptonica not found.",, this.outer.leptonica)

               static q := Chr(0x22)
               _cmd .= q this.outer.leptonica q " " q this.temp1 q " " q this.temp2 q
               _cmd .= " " negateArg " 0.5 " performScaleArg " " scaleFactor " " ocrPreProcessing " 5 2.5 " ocrPreProcessing  " 2000 2000 0 0 0.0"
               _cmd := ComSpec " /C " q _cmd q
               RunWait, % _cmd,, Hide

               if !(FileExist(this.temp2))
                  throw Exception("Preprocessing failed.",, _cmd)

               FileDelete, % this.temp1
               return this.imageData := this.temp2
            }

            convert(file, option := "", speed := 0){
               if !(FileExist(file))
                  throw Exception("File not found.",, file)

               if !(FileExist(this.outer.tesseract))
                  throw Exception("Tesseract not found.",, this.outer.tesseract)

               static q := Chr(0x22)
               _cmd .= q this.outer.tesseract q " --tessdata-dir " q ((speed) ? this.outer.tessdata_fast : this.outer.tessdata_best) q
               _cmd .= " " q file q " " q SubStr(this.temp3, 1, -4) q
               _cmd .= (option) ? " -l " q option q : ""
               _cmd .= " -c tessedit_create_tsv=1 -c tessedit_pageseg_mode=1"
               _cmd := ComSpec " /C " q _cmd q
               ;_cmd := "powershell -NoProfile -command "  q  "& " _cmd q
               RunWait % _cmd,, Hide

               if !(database := FileOpen(this.temp3, "r`n", "UTF-8"))
                  throw Exception("Tesseract did not output a file.",, this.temp3)
               tsv := RegExReplace(database.Read(), "^\s*(.*?)\s*+$", "$1")
               database.Close()

               OnExit(ObjBindMethod(this, "Exit")) ; Deletes temp2 on exit.
               FileDelete, % this.temp3

               obj := {}, block := {"paragraphs":[]}, paragraph := {"lines":[]}, line := {"words":[]}, word := {}

               line_num := block_num := par_num := word_num := 0
               Loop, Parse, tsv, `n
               {
                  if (A_Index = 1)
                     continue ; Skip headers

                  ; 1 = level, 2 = page_num, 3 = block_num, 4 = par_num, 5 = line_num, 6 = word_num
                  ; 7 = left, 8 = top, 9 = width, 10 = height, 11 = confidence, 12 = text
                  field := StrSplit(A_LoopField, "`t")

                  rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}

                  if (word_num != field[6]) {
                     if (word_num != 0) {
                        line.words.push(word)
                        line.text .= word.text . ((field[6] > 1) ? " " : "")
                        line.confidence := (line.confidence == "") ? word.confidence : (1/word_num)*word.confidence + ((word_num - 1)/word_num)*line.confidence
                     }
                     word_num := field[6]
                     word := {}
                     word.word_number := field[6]
                     word.text := field[12]
                     word.confidence := field[11]
                     word.rectangle := rectangle
                  }

                  if (line_num != field[5]) {
                     if (line_num != 0) {
                        paragraph.lines.push(line)
                        paragraph.text .= line.text . ((field[5] > 1) ? "`r`n" : "")
                        paragraph.confidence := (paragraph.confidence == "") ? line.confidence : (1/line_num)*line.confidence + ((line_num - 1)/line_num)*paragraph.confidence
                     }
                     line_num := field[5]
                     line := {"words":[]}
                     line.line_number := field[5]
                     line.rectangle := rectangle
                  }

                  if (par_num != field[4]) {
                     if (par_num != 0) {
                        block.paragraphs.push(paragraph)
                        block.text .= paragraph.text . ((field[4] > 1) ? "`r`n" : "")
                        block.confidence := (block.confidence == "") ? paragraph.confidence : (1/par_num)*paragraph.confidence + ((par_num - 1)/par_num)*block.confidence
                     }
                     par_num := field[4]
                     paragraph := {"lines":[]}
                     paragraph.paragraph_number := field[4]
                     paragraph.rectangle := rectangle
                  }
                  if (block_num != field[3]) {
                     if (block_num != 0) {
                        text .= block.text
                        confidence := (confidence == "") ? block.confidence : (1/block_num)*block.confidence + ((block_num - 1)/block_num)*confidence
                        obj.push(block)
                     }
                     block_num := field[3]
                     block := {"paragraphs":[]}
                     block.block_number := field[3]
                     block.rectangle := rectangle
                  }
               }

               line.words.push(word)
               line.text .= ((field[6] > 1) ? " " : "") . word.text
               line.confidence := (line.confidence == "") ? word.confidence : (1/word_num)*word.confidence + ((word_num - 1)/word_num)*line.confidence
               paragraph.lines.push(line)
               paragraph.text .= ((field[5] > 1) ? "`r`n" : "") . line.text
               paragraph.confidence := (paragraph.confidence == "") ? line.confidence : (1/line_num)*line.confidence + ((line_num - 1)/line_num)*paragraph.confidence
               block.paragraphs.push(paragraph)
               block.text .= paragraph.text
               block.confidence := (block.confidence == "") ? paragraph.confidence : (1/par_num)*paragraph.confidence + ((par_num - 1)/par_num)*block.confidence
               text .= block.text
               confidence := (confidence == "") ? block.confidence : (1/block_num)*block.confidence + ((block_num - 1)/block_num)*confidence
               obj.push(block)


                  /*
                  if (block_num != field[3]) {
                     block_num := field[3]
                     if (field[3] > 0) {
                        block := {"paragraphs":[]}
                     }
                  }
                  if (field[3] > 0 && par_num != field[4]) {
                     par_num := field[4]
                     if (field[4] > 0) {
                        paragraph := {"lines":[]}
                     }
                  }
                  if (field[3] > 0 && field[4] > 0 && line_num != field[5]) {
                     line_num := field[5]
                     if (field[5] > 0) {
                        line := {"words":[]}
                        _blocks := true
                     }
                  }
                  if (field[3] > 0 && field[4] > 0 && field[5] > 0 && word_num != field[6]) {
                     word_num := field[6]
                     if (field[6] > 0) {
                        word := {}
                        word.word_num := field[6]
                        word.text := field[12]
                        word.confidence := field[11]
                        word.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                        line.words.push(word)
                        line.text .= ((field[6] > 1) ? " " : "") . word.text
                        line.confidence := (line.confidence == "") ? word.confidence : (1/word_num)*word.confidence + ((word_num - 1)/word_num)*line.confidence
                        _lines := true
                        _paragraphs := true
                     }
                  }
                  if (field[3] > 0 && field[4] > 0 && field[5] > 0 && field[6] == 0)
                     line.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                  if (_lines == true) {
                     line.line_num := field[5]
                     paragraph.text .= ((field[5] > 1) ? "`r`n" : "") . line.text
                     paragraph.confidence := (paragraph.confidence == "") ? line.confidence : (1/line_num)*line.confidence + ((line_num - 1)/line_num)*paragraph.confidence
                     paragraph.lines.push(line)
                     _lines := false
                  }
                  if (field[3] > 0 && field[4] > 0 && field[5] == 0 && field[6] == 0)
                     paragraph.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                  if (_paragraphs == true) {
                     paragraph.par_num := field[4]
                     block.text .= paragraph.text . "xd"
                     block.confidence := (block.confidence == "") ? paragraph.confidence : (1/par_num)*paragraph.confidence + ((par_num - 1)/par_num)*block.confidence
                     block.paragraphs.push(paragraph)
                     _paragraphs == false
                  }
                  if (field[3] > 0 && field[4] == 0 && field[5] == 0 && field[6] == 0)
                     block.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                  if (_blocks == true) {
                     block.block_num := field[3]
                     text .= block.text . "lol"
                     obj.push(block)
                     _blocks == false
                  }
                  */


                  /*
                  ; words
                  if (field[3] > 0 && field[4] > 0 && field[5] > 0 && word_num != field[6]) {
                     word_num := field[6]
                     if (field[6] == 0) {
                        line.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                     } else {
                        word := {}
                        word.text := field[12]
                        word.confidence := field[11]
                        word.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                        line.text .= word.text . " "
                        line.confidence := (line.confidence == "") ? word.confidence : (1/word_num)*word.confidence + ((word_num - 1)/word_num)*line.confidence
                        line.words.push(word)
                     }
                  }

                  ; lines
                  if (field[3] > 0 && field[4] > 0 && line_num != field[5]) {
                     line_num := field[5]
                     if (field[5] == 0) {
                        paragraph.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                     } else {
                        paragraph.text .= line.text . "`r`n"
                        paragraph.confidence := (paragraph.confidence == "") ? line.confidence : (1/line_num)*line.confidence + ((line_num - 1)/line_num)*paragraph.confidence
                        paragraph.lines.push(line)
                        line := {"words":[]}
                     }
                  }

                  ; paragraphs
                  if (field[3] > 0 && par_num != field[4]) {
                     par_num := field[4]
                     if (field[4] == 0) {
                        block.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                     } else {
                        block.text .= paragraph.text . "xd"
                        block.confidence := (block.confidence == "") ? paragraph.confidence : (1/par_num)*paragraph.confidence + ((par_num - 1)/par_num)*block.confidence
                        block.paragraphs.push(paragraph)
                        paragraph := {"lines":[]}
                     }
                  }

                  ; blocks
                  if (block_num != field[3]) {
                     block_num := field[3]
                     if (field[3] == 0) {
                        block.rectangle := {"x":field[7], "y":field[8], "w":field[9], "h":field[10]}
                     } else {
                        obj.text .= block.text . "lol"
                        obj.confidence := (obj.confidence == "") ? block.confidence : (1/block_num)*block.confidence + ((block_num - 1)/block_num)*obj.confidence
                        obj.blocks.push(block)
                        block := {"paragraphs":[]}
                     }
                  }
               }
               */
               /*
               if (field[7] < obj[block].x)
                  obj[block].x := field[7]
               if (field[8] < obj[block].y)
                  obj[block].y := field[8]
               if (field[9] > obj[block].w)
                  obj[block].w := field[9]
               if (field[10] > obj[block].h)
                  obj[block].h := field[10]

               Loop % obj.MaxIndex() {
                  MsgBox % "number A_Index x:" obj[A_Index].x " y:" obj[A_Index].y " w:" obj[A_Index].w " h:" obj[A_Index].h
               }
               */

               data := text
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }

            exit(){
               FileDelete , % this.temp2 ; imageData
            }
         }
      }

      class Wolfram {

         request(binary, filename){
            static q := Chr(0x22)
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.Open("POST", "https://www.imageidentify.com/objects/user-26a7681f-4b48-4f71-8f9f-93030898d70d/prd/imageapi", true)
            whr.SetRequestHeader("Accept", "application/json, text/javascript, */*; q=0.01")
            whr.SetRequestHeader("Origin", "https://www.imageidentify.com")
            whr.SetRequestHeader("X-Requested-With", "XMLHttpRequest")
            whr.SetRequestHeader("Content-Disposition", "attachment; filename=" q filename q)
            whr.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36")
            whr.SetRequestHeader("Content-Type", "multipart/form-data; boundary=----WebKitFormBoundaryvDFhjAljR458on8O")
            whr.SetRequestHeader("Referer", "https://www.imageidentify.com/")

            req := {"type":"file", "image_file":"data:image/" extension ";base64," base64}

            whr.Send(JSON.Dump(req))
            whr.WaitForResponse()
            return JSON.Load(whr.ResponseText)
         }

         class ImageIdentify extends Vis2.functor {
            static extension := "jpg", compression := "75"

            call(self, image, option:="", crop:=""){
               return this.convert(this.preprocess(image, crop), option)
            }

            preprocess(image, crop){
               Vis2.Graphics.Startup()
               if !(type := Vis2.preprocess.DontVerifyImageType(image))
                  if !(type := Vis2.preprocess.ImageType(image))
                     throw Exception("Ensure that the reference to an image is valid.")
               pBitmap := Vis2.preprocess.toBitmap(type, image)
               if Vis2.stdlib.isScreenshot(crop){
                  pBitmap2 := Vis2.stdlib.Gdip_CropBitmap(pBitmap, crop)
                  if (type != "pBitmap")
                     Gdip_DisposeImage(pBitmap)
                  pBitmap := pBitmap2
               }
               this.base64 := base64 := Vis2.stdlib.Gdip_EncodeBitmapToBase64(pBitmap, this.extension, this.compression)
               Gdip_DisposeImage(pBitmap)
               Vis2.Graphics.Shutdown()
               return base64
            }

            convert(base64, option){
               reply := this.outer.request(base64, this.extension)
               i := 0, j := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "default")
                     while (j++ < reply[i].classes.maxIndex())
                        obj.push({ "category":    reply[i].classes[j].class
                                 , "score":       reply[i].classes[j].score
                                 , "hierarchy":   reply[i].classes[j].type_hierarchy})

               obj := Vis2.stdlib.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : ", ") . v.category " " v.score
               }
               sentence2.base.FullData := obj
               return sentence2
            }
         }
      }
   }

   class stdlib {

      isBinaryImageFormat(data){
         Loop 12
            bytes .= Chr(NumGet(data, A_Index-1, "uchar"))

         ; Null bytes are not passed, so they have been omitted below

         if (bytes ~= "^BM")
            return "bmp"
         if (bytes ~= "^(GIF87a|GIF89a)")
            return "gif"
         if (bytes ~= "^ÿØÿÛ")
            return "jpg"
         if (bytes ~= "s)^ÿØÿà..\x4A\x46\x49\x46") ;\x00\x01
            return "jfif"
         if (bytes ~= "^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A")
            return "png"
         if (bytes ~= "^(\x49\x49\x2A|\x4D\x4D\x2A)") ; 49 49 2A 00, 4D 4D 00 2A
            return "tif"
         return
      }

      CreateUUID() {
         VarSetCapacity(puuid, 16, 0)
         if !(DllCall("rpcrt4.dll\UuidCreate", "ptr", &puuid))
            if !(DllCall("rpcrt4.dll\UuidToString", "ptr", &puuid, "uint*", suuid))
               return StrGet(suuid), DllCall("rpcrt4.dll\RpcStringFree", "uint*", suuid)
         return ""
      }

      QuickSort(a){
         if (a.MaxIndex() <= 1)
            return a
         Less := [], Same := [], More := []
         Pivot := a[1].score
         for k, v in a
         {
            if (v.score > Pivot)
               less.push(v)
            else if (v.score < Pivot)
               more.push(v)
            else
               same.push(v)
         }
         Less := this.QuickSort(Less)
         Out := this.QuickSort(More)
         if (Same.MaxIndex())
            Out.InsertAt(1, Same*) ; insert all values of same at index 1
         if (Less.MaxIndex())
            Out.InsertAt(1, Less*) ; insert all values of less at index 1
         return Out
      }

      setSystemCursor(CursorID = "", cx = 0, cy = 0 ) { ; Thanks to Serenity - https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
         static SystemCursors := "32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651"

         Loop, Parse, SystemCursors, `,
         {
               Type := "SystemCursor"
               CursorHandle := DllCall( "LoadCursor", "uInt",0, "Int",CursorID )
               %Type%%A_Index% := DllCall( "CopyImage", "uInt",CursorHandle, "uInt",0x2, "Int",cx, "Int",cy, "uInt",0 )
               CursorHandle := DllCall( "CopyImage", "uInt",%Type%%A_Index%, "uInt",0x2, "Int",0, "Int",0, "Int",0 )
               DllCall( "SetSystemCursor", "uInt",CursorHandle, "Int",A_Loopfield)
         }
      }
   }

   class Text {

      ; Based on this paper: http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.81.8901
      rmgarbage(data := ""){
         ; If the input value is blank, send ^c to capture highlighted text.
         text := (data == "") ? Vis2.Text.copy() : data

         ; Split our text into strings, creating an array of words.
         strings := [], whitespaces := [], pos := 1
         while RegexMatch(text, "O)([^\s]+)", string, pos) {
            strings.push(string.value())
            pos := string.pos() + string.len()
            RegexMatch(text, "O)([\s]+)", whitespace, pos)
            whitespaces.push(whitespace.value)
         }

         for i in strings {
            ; (L) If a string is longer than 40 characters...
            ;strings[i] := RegExReplace(strings[i], "[^\s]{40,}", "")
            ; (A) If a string’s ratio of alphanumeric characters to total characters is less than 50%...
            alnum_thresholds := {1: 0     ; single chars can be non-alphanumeric
                    ,2: 0     ; so can doublets
                    ,3: 0.32  ; at least one of three should be alnum
                    ,4: 0.24  ; at least one of four should be alnum
                    ,5: 0.39}  ; at least two of five should be alnum
            strings[i] := (StrLen(RegExReplace(strings[i], "\W")) / StrLen(strings[i]) < 0.5) ? "" : strings[i]
            ; (R) If a string has 4 identical characters in a row...
            ;strings[i] := (strings[i] ~= "([^\s])\1\1\1") ? "" : strings[i]
            ; (V) If a string has nothing but alphabetic characters, look at the number of consonants and vowels.
            ;     If the number of one is less than 10% of the number of the other...
            ;     This includes a length threshold.

            /*
            def bad_consonant_vowel_ratio(self, string):
             """
             Rule V
             ======
             if a string has nothing but alphabetic characters, look at the
             number of consonants and vowels. If the number of one is less than 10%
             of the number of the other, then the string is garbage.
             This includes a length threshold.
             :param string: string to be tested
             :returns: either True or False
             """
             alpha_string = filter(str.isalpha, string)
             vowel_count = sum(1 for char in alpha_string if char in 'aeiouAEIOU')
             consonant_count = len(alpha_string) - vowel_count

             if (consonant_count > 0 and vowel_count > 0):
                 ratio = float(vowel_count)/consonant_count
                 if (ratio < 0.1 or ratio > 10):
                     return True
             elif (vowel_count == 0 and consonant_count > len('rhythms')):
                 return True
             elif (consonant_count == 0 and vowel_count > len('IEEE')):
                 return True

             return False
             */
            ;strings[i] := (strings[i] ~= "^(\w(?<=\D))+$") ? () : strings[i]
            ; (P) Strip off the first and last characters of a string. If there are two distinct
            ;     punctuation characters in the result...

            ; (C) If a string begins and ends with a lowercase letter, then if the string
            ;     contains an uppercase letter anywhere in between...
         }

         ; Reassemble the text
         text := ""
         for i, string in strings {
            text .= string . whitespaces[i]
         }

         return (data == "") ? Vis2.Text.paste(text) : text
      }

      clipboard(data){
         clipboard := data
         return data
      }

      google(data) {
         copy := data
         if not RegExMatch(data, "^(http|ftp|telnet)")
            copy := "https://www.google.com/search?&q=" . RegExReplace(data, "\s", "+")
         if (data)
            Run % copy
         return data
      }

      json(data, replacer:="", space:=2){
         copy := JSON.Dump(data.FullData, replacer, space)
         copy := RegExReplace(copy, "(?<!\r)\n", "`r`n")
         return copy
      }

      maxLines(data, lines:=3){
         i := 1
         Loop, Parse, % data, `r`n
         {
            temp := RegExReplace(A_LoopField, "^\s*(.*?)\s*$", "$1")
            if (temp != "") {
               copy .= (copy) ? ("`n" . temp) : temp
               i++
            }
         } until (i > lines)
         return copy
      }
   }
}
