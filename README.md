# Vis2 - OCR(), ImageIdentify()
##### Automation using Computer Vision. Convert images on screen, image files, or an image URL to text. 

### Super Quick Start

Run demo.ahk.

### Quick Start
1. [Download Vis2.](https://github.com/iseahound/Vis2/archive/master.zip)
2. Create a new AHK script in the same folder as Vis2.ahk, copying the code below.

```
    #include <Vis2>
    MsgBox % OCR("https://i.stack.imgur.com/sFPWe.png")
```
    
3. Run the new AHK script. You should see a MsgBox with OCR Text. Press ```Enter``` to exit. Visit the image link to confirm the OCR is working correctly. 

### How to use
When you see the popup "Optical Character Recognition Tool", click and drag. If you press the right mouse button while holding down LButton you can reposition the rectangle. My personal suggestion is to bind OCR() to a mouse button instead of #c. 

### Using Additional Languages
Go to https://github.com/tesseract-ocr/tessdata_best and place your desired languages in bin/tessdata_best. 
Go to https://github.com/tesseract-ocr/tessdata_fast and place your desired languages in bin/tessdata_fast. 

Fast is used in the interactive GUI implementation, while best will be used for other cases. See below for what I mean. 


    #c:: OCR(, "fra")      ; French (requires fast fra.traineddata)
    #x:: OCR(, "eng+fra")  ; English and French


    MsgBox % OCR("https://i.imgur.com/T7WMxMs.png", "rus+eng")  ; Requires best eng.traineddata and rus.traineddata. 

### Advanced Interactive Mode
While using ```#c:: OCR()``` you can press ```Ctrl```, ```Alt```, or ```Shift``` to enter Advanced Mode. (You should see a pink pop up.) While in this mode, press ```Ctrl``` + ```Space``` to see a preview of the preprocessed image. Press ```Alt``` + ```Space``` to get the coordinates of the grey rectangle. Holding ```Ctrl``` and ```LButton``` will allow you to resize the corners of the box. ```Shift``` and ```LButton``` will resize edges. ```Alt``` and ```LButton``` to draw a new rectangle. 

## Documentation
### Input Data Types
The same rules apply for ImageIdentify()
#### ```OCR()``` - Launches an interactive GUI. 
Example: Pressing ```Ctrl``` + ```Win``` + ```c``` will allow the user to manually select an area on screen to OCR. 

    #^c:: OCR()

#### ```OCR([x, y, w, h])``` - Screen Coordinates as an Array
To input a set of known coordinates, try inputting an array of 4 values, [x, y, w, h]

    text := OCR([0, 0, 430, 150])

This will search the screen from point (0, 0) extending in a rectangle of width 430 pixels and height 150 px. 

#### ```OCR( file )``` - Path to File
File name can be an absolute or relative path

    text := OCR("myImage.jpg")
    text := OCR("C:\image.png")
    
#### ```OCR( url )``` - Website
The image will be downloaded and OCRed. You may experience a delay depending on the image size. 

    text := OCR("https://www.blog.google/static/blog/images/google-200x200.7714256da16f.png")

#### ```OCR( WinTitle )``` - Window Title
You may enter a native AHK window type such as "ahk_class notepad", "ahk_exe", "ahk_id", "ahk_pid", or the exact name of the window. [Reference](https://autohotkey.com/docs/misc/WinTitle.htm)

Example: 1) Open a new Notepad window. Type some text. Then run the following code. 

    MsgBox % OCR("Untitled - Notepad")
    
Note that only the client area is extracted, so the window border of Notepad is ignored. 

#### ```OCR( hWnd )``` - Unique Window ID
If you know the window ID, or hwnd, you may use it as well. Note that this is equivalent to ```OCR("ahk_id" hWnd)```. 

#### ```OCR( base64 )``` - Base64 encoded image string
#### ```OCR( GDI Bitmap )``` - Pointer to a memory bitmap
#### ```OCR( HBITMAP )``` - Handle to a memory bitmap

A sample script where you have to search for the text 'Vis2' on screen. 

    if ((text := OCR()) = "Vis2")
        MsgBox You have successfully used OCR!
    else
        MsgBox You have found [ %text% ] `, try finding 'Vis2' instead. 

## Need more help?
#### Be sure to visit https://autohotkey.com/boards/viewtopic.php?f=6&t=36047 for help and support. 
