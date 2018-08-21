#include <Vis2>  ; Equivalent to #include .\lib\Vis2.ahk

v1 := Vis2.Graphics.Subtitle.Render( "Running Test Code... Please wait"
                                   , "time:45000 x:center y:66.66vh margin:1.35vh color:88EAB6 radius:8"
                                   , "font:(Arial) size:2.23% color:Black" )
v2 := Vis2.Graphics.Picture.Render( "test.jpg"
                                  , "time:45000 anchor:center_center x:25vw y:center margin:25px" )

; Converts "test.jpg" into text.
MsgBox % text := TextRecognize("test.jpg")

v1.Destroy(), v2.Destroy()
Vis2.Graphics.Subtitle.Render( "Press [Win] + [c] to highlight and copy any text on screen."
                             , "time:30000 x:center y:8.33vh margin:1.35vh color:FFB1AC radius:8"
                             , "font:(Arial) size:2.23% color:Black" )

#c:: TextRecognize()    ; Convert pictures of text into text.
#i:: ImageIdentify()    ; Name and identify objects in images.
Esc:: ExitApp
