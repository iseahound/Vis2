# Vis2
##### Interactively convert images to data.

![Imgur](https://i.imgur.com/UQ7tOtA.png)

### How to use

1. Install AutoHotkey from https://autohotkey.com/
2. Run demo.ahk by clicking on it.

### Manual Scripting

1. In the same folder as demo.ahk, create a new script.
2. This script will bind TextRecognize to the ```Win``` + ```c``` hotkey.
```
    #include <Vis2>
    #c:: TextRecognize()
```
3. So far the user interface only understands English. Let's change it to German and English.
```
    #include <Vis2>
    #c:: TextRecognize(, "eng+deu") ; Defaults to Tesseract.
```
4. Note that there are different service providers so let's call Tesseract explicitly.
```
    #include <Vis2>
    #c:: Vis2.service.Tesseract.TextRecognize(, "eng+deu")
    ; "eng+deu" is passed directly to Tesseract.
```
5.  Switching the service provider to Google. The second parameter is specific to the service provider, and is invalid here. 
```
    #include <Vis2>
    #c:: Vis2.service.Google.TextRecognize()
```
6.  Finally, a manual image can be specified in the first parameter.
```
    #include <Vis2>
    MsgBox % Vis2.service.Tesseract.TextRecognize("https://i.stack.imgur.com/sFPWe.png")
```
7.  The following script will screenshot a notepad window to read its contents. It may capture the blinking cursor.
```
    Run, notepad.exe
    WinWait, Untitled - Notepad
    ControlSend, Edit1, % "This is some fine looking text." , Untitled - Notepad
    MsgBox % TextRecognize("Untitled - Notepad")
```

### Tips
Press the right mouse button while holding down LButton to reposition the selection.
Alternatively, press ```Ctrl``` or another modifer key to enter Advanced Mode.

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
