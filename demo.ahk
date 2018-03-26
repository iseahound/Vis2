#include <Vis2>  ; Equivalent to #include .\lib\Vis2.ahk

Vis2.Graphics.Subtitle.Render("Running Test Code... Make sure you are connected to the internet", "t7000 xCenter y67% p1.35% c88EAB6 r8", "s2.23% cBlack")
Vis2.Graphics.Subtitle.Render("Be sure to visit https://i.stack.imgur.com/sFPWe.png to check the OCR is running correctly.", "t30000 xCenter y75% p1.35% cBlack r8", "s2.23% cWhite")
Vis2.Graphics.Subtitle.Render("In fact you can press [Win] + [c] to highlight and visit the above link", "time: 30000 xCenter y92% p1.35% cFFB1AC r8", "c000000 s2.23%")
MsgBox % text := OCR("https://i.stack.imgur.com/sFPWe.png")

#c:: Vis2.OCR.google()
;#c:: OCR()   ; To copy to clipboard
Esc:: ExitApp
