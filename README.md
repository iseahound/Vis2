# Vis2 - OCR(), ImageIdentify()
##### Automation using Computer Vision. 

### Quick Start
1. [Download Vis2.](https://github.com/iseahound/Vis2/archive/master.zip)
2. Create a new AHK script in the same folder as Vis2.ahk, copying the code below.

```
    #include Vis2.ahk
    MsgBox % OCR("https://i.stack.imgur.com/sFPWe.png")
```
    
3. Press ```Enter``` to exit. Visit the image link to confirm the OCR is working correctly. 

## Documentation
#### OCR() - Launches an interactive GUI. 
Example: Pressing ```Ctrl``` + ```Win``` + ```c``` will allow the user to manually select an area on screen to OCR. 

    #^c:: OCR()

#### OCR( \[x, y, w, h\] ) - Array
To input a set of known coordinates, try inputting an array of 4 values, [x, y, w, h]

    text := OCR([0, 0, 430, 150])

This will search the screen from point (0, 0) extending in a rectangle of width 430 pixels and height 150 px. 

#### OCR( file ) - File Name
File name can be an absolute or relative path

    text := OCR("myImage.jpg")
    text := OCR("C:\image.png")
    
#### OCR( url ) - Website
The image will be downloaded and OCRed. You may experience a delay depending on the image size. 

    text := OCR("https://www.blog.google/static/blog/images/google-200x200.7714256da16f.png")
    
#### OCR( base64 ) - Base64 encoded image string
Pass a base64 string.

#### OCR( WinTitle ) - Window Title
You may enter a native AHK window type such as "ahk_class notepad", "ahk_exe", "ahk_id", "ahk_pid", or the exact name of the window. [Reference](https://autohotkey.com/docs/misc/WinTitle.htm)

Example: 1) Open a new Notepad window. Type some text. Then run the following code. 

    MsgBox % OCR("Untitled - Notepad")
    
Note that only the client area is extracted, so the window border of Notepad is ignored. 

#### OCR( hWnd ) - Unique Window ID
If you know the window ID, or hwnd, you may use it as well. Note that this is equivalent to ```OCR("ahk_id" hWnd)```. 

#### OCR( GDI Bitmap ) - Pointer to a memory bitmap
Pass a pBitmap memory address. 

#### OCR( HBITMAP ) - Handle to a memory bitmap
Pass an hBitmap. 

#### OCR( Binary ) - Raw File Binary
If you have loaded a file to memory, you may pass the data. Not recommended, pass the file name instead. 

Note that the following snippet will also return text

    if ((text := OCR()) = "Vis2")
        MsgBox You have successfully used OCR!
    else
        MsgBox You have found [ %text% ] `, try finding 'Vis2' instead. 

Be sure to visit https://autohotkey.com/boards/viewtopic.php?f=6&t=36047 for help and support. 
