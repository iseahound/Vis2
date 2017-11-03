# Vis2
Using Computer Vision to automate tasks. 
OCR(), ImageIdentify()


### Instructions
How to use OCR() - add the following line to your code.

    #^c:: OCR()

The above line will bring up a user interface that allows selection of text on-screen. 
To input a set of known coordinates, try inputting an array of 4 values, [x, y, w, h]

    text := OCR([0, 0, 430, 150])

This will search the screen from point (0, 0) extending in a rectangle of width 430 pixels and height 150 px. 

Note that the following snippet will also return text

    if ((text := OCR()) = "Vis2")
        MsgBox You have successfully used OCR!
    else
        MsgBox You have found [ %text% ] `, try finding 'Vis2' instead. 

Be sure to visit https://autohotkey.com/boards/viewtopic.php?f=6&t=36047 for help and support. 
