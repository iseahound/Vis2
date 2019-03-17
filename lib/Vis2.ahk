; Script:    Vis2.ahk
; Author:    iseahound
; License:   GPLv3
; Version:   August 2018 (not for public use.)
; Release:   2018-08-21

#include <Gdip_All>    ; https://goo.gl/rUuEF5
#include <Graphics>
#include <JSON>        ; https://goo.gl/MAsQDe


; AsciiArt() - Artistically reduces an image to ASCII characters.
AsciiArt(image:="", option:="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}

; Describe() - Creates a phrase that best captions the image.
Describe(image:="", option:="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}

; ExplicitContent() - Detect offensive or inappropriate content.
ExplicitContent(image:="", option:="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}

; FindFaces() - Detect faces in images.
FindFaces(image:="", option="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}

; ImageIdentify() - Name and identify objects in images.
ImageIdentify(image:="", option:="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}

; TextRecognize() - Convert pictures of text into text.
TextRecognize(image:="", option:="", crop:="", settings:=""){
   return Vis2.Finding(A_ThisFunc, image, option, crop, settings)
}
; Alias for TextRecognize()
OCR(terms*){
   return TextRecognize(terms*)
}


class Vis2 {

   ; Flow A-01 - Search for the word Flow to follow the function calls.
   ;             This is one of two ways to start Vis2.
   ; Next: Flow 0-02
   Finding(name, terms*){
      static rank := ["Tesseract", "Google", "Wolfram", "IBM"]
      for i, index in rank
         if IsObject(Vis2.service[index][name])
            return Vis2.service[index][name].call(self, terms*)
   }

   class settings {
      ; These are the GLOBAL DEFAULT SETTINGS for the ux display.
      ; Local settings found in Vis2.service. Local settings override global settings.
      ; Users can manually override the local settings by using the fourth parameter:
      ; Example: Vis2.service.Tesseract.TextRecognize(,,,{"previewImage":true})
      static convertImageDelay := 900
      static previewBounds := false
      static previewImage := false
      static previewText := false
      static splashBounds := false
      static splashImage := false
      static splashText := true           ; Default splashText is true.
      static showCoordinates := false
      static toClipboard := true          ; Default toClipboard is true.
      ; Notes: convertImageDelay accepts an integer which becomes the delay in milliseconds.
      ;        For example, setting convertImageDelay to 500 is equal to 500 ms. (recommended)
      ;        convertImageDelay has been set locally to prevent the user from getting IP banned by
      ;        abusing the free quota on various cloud demo websites. Change at your own risk!!!

      ; Predefined styles for the user experience.
      class area {
         static set := ObjBindMethod(Vis2.settings, "set")
         static c := 0x7FDDDDDD
      }
      class picture {
         static set := ObjBindMethod(Vis2.settings, "set")
      }
      class polygon {
         static set := ObjBindMethod(Vis2.settings, "set")
      }
      class subtitle {
         class background {
            static set := ObjBindMethod(Vis2.settings, "set")
            static x := "center"
            static y := "83.33vh"
            static m := "1.35vmin"        ; margin is 15px
            static c := "#DD000000"       ; color is transparent black
            static r := "0.74vmin"        ; radius is 8px
         }
         class text {
            static set := ObjBindMethod(Vis2.settings, "set")
            static q := 4                 ; text quality is anti-alias
            static f := "Arial"           ; font is Arial
            static z := "Arial Narrow"    ; condensed font is Arial Narrow
            static s := "2.23vmin"        ; font size is 24pt
         }
      }
      /*
      class information {
         static set := ObjBindMethod(Vis2.settings, "set")
         ; obj.information.render(c2, "a:centerright x:98.14vw y:center w:8.33vmin h:33.33vmin r:8px c:DD000000"
         ;, "f:(Arial) j:center y:center s:2.23% c:White")
         class background {
            static set := ObjBindMethod(Vis2.settings, "set")
            static x := "center"
            static y := "83.33vh"         ; top is 83%
            static m := "1.35vmin"        ; margin is 15px
            static c := "#DD000000"
            static r := "0.74vmin"        ; radius is 8px
         }
         class text {
            static set := ObjBindMethod(Vis2.settings, "set")
            static q := 4                 ; text quality is anti-alias
            static f := "Arial"           ; font is Arial
            static z := "Arial Narrow"    ; condensed font is Arial Narrow
            static s := "2.23vmin"        ; font size is 24pt
         }
      }
      */


      ; This function is a mixin used by all subobjects in Vis2.settings
      set(self, key, value) {
         clone := self.Clone()
         clone[key] := value
         return clone
      }
   }

   class service {

      static user_agent := "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"

      class functor {

         ; Flow B-01 - Redirects this __call() to Vis2.shared.call().
         ;             A direct function call such as Vis2.service.Tesseract.TextRecognize()
         ;             calls this __call() meta function first.
         ; Next: Flow 0-02
         __Call(self, terms*) {
            if (self == "")
               return this.call(terms*)
            if IsObject(self)
               return this.call(self, terms*)
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

         outer[p:=""] {
            get {
               ; Determine if there is a parent class. this.__class will retrive the
               ; current instance's class name. Split the class string at each period,
               ; using array notation [] to dereference. Void if not nested in at least 2 classes.
               if ((_class := RegExReplace(this.__class, "^(.*)\..*$", "$1")) != this.__class)
                  Loop, Parse, _class, .
                     outer := (A_Index=1) ? %A_LoopField% : outer[A_LoopField]
               ; Test if this property is nested in one class. If so, return the global class "p".
               ; Otherwise if no subclass (p) is specified, return an empty string.
               if IsObject(outer)
                  return (p) ? outer[p] : outer
               else
                  return (p) ? %p% : ""
            }
         }
      }

      class shared extends Vis2.service.functor {

         ; Flow 0-02 - Diverges depending on a blank image parameter.
         ;             A blank image parameter means that it launches the user experience.
         ;             If an image is supplied, it only calls the service (back end).
         ; Next: Flow C-03, Flow D-03
         call(self, image:="", option:="", crop:="", settings:=""){
            settings := IsObject(settings) ? settings : {}   ; user settings
            settings.base := this.settings                   ; service specific settings
            settings.base.base := Vis2.settings              ; default settings

            if (image == "")
               return Vis2.ux.returnData(new this(option, settings), settings)
            else
               return (new this(option, settings)).convert(image, crop)
         }

         __New(option:="", settings:=""){
            this.option := option
            this.settings := settings
         }

         CreateUUID() {
            VarSetCapacity(puuid, 16, 0)
            if !(DllCall("rpcrt4.dll\UuidCreate", "ptr", &puuid))
               if !(DllCall("rpcrt4.dll\UuidToString", "ptr", &puuid, "uint*", suuid))
                  return StrGet(suuid), DllCall("rpcrt4.dll\RpcStringFree", "uint*", suuid)
            return
         }

         InternetConnected(url := "http://208.67.222.222") {
            if !DllCall("Wininet.dll\InternetGetConnectedState", "str","", "int",0)
               return 0
            if !DllCall("Wininet.dll\InternetCheckConnection", "str",url, "uint",1,"uint",0)
               return 0
            return 1
         }

         ; MAKE QUICK SORT GENERIC AND USE NOT SCORE LOL
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
      }

      class Google extends Vis2.service.functor {
         static api := true

         ; https://cloud.google.com/vision/docs/supported-files
         ; Supported Image Formats
         ; JPEG, PNG8, PNG24, GIF, Animated GIF (first frame only)
         ; BMP, WEBP, RAW, ICO
         ; Maximum Image Size - 4 MB
         ; Maximum Size per Request - 8 MB
         ; Compression to 640 x 480 - LABEL_DETECTION
         ;
         ; Cloud Platform Console Help - Setting up API keys
         ; Step 1: https://support.google.com/cloud/answer/6158862?hl=en
         ; Step 2: https://cloud.google.com/vision/docs/before-you-begin
         ;
         ; You must enter billing information to use the Cloud Vision API.
         ; https://cloud.google.com/vision/pricing
         ; First 1000 LABEL_DETECTION per month is free.
         ;
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
               (Vis2.ux.io.status == 0) ? Vis2.ux.suspend() : ""
               InputBox, api_key, Vis2.GoogleCloudVision.ImageIdentify, Enter your api_key for GoogleCloudVision.
               (Vis2.ux.io.status == 0) ? Vis2.ux.resume() : ""
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
            whr.SetRequestHeader("User-Agent", this.outer.user_agent)

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

         ; Vis2.service.Google.Describe()
         class Describe extends Vis2.service.shared {
         }

         ; Vis2.service.Google.ImageIdentify()
         class ImageIdentify extends Vis2.service.shared {

            class settings {
               static tooltip := "Google: Image Identification Tool"
               static alert := "ERROR: No images could be identified."
               static extension := "jpg"
               static compression := "75"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)
               reply := this.outer.request(coimage, this.settings.extension, "LABEL_DETECTION")
               obj := {}
               for i, value in reply.responses[1].labelAnnotations {
                  value.category := value.description
                  value.score    := value.score
                  obj.push(value)
               }
               obj := this.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : "`r`n") . v.category ", " Format("{:#.3f}", v.score)
               }
               data := sentence2
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.service.Google.TextRecognize()
         class TextRecognize extends Vis2.service.shared {

            class settings {
               static tooltip := "Google: Text Recognition Tool"
               static alert := "ERROR: No text data found."
               static extension := "png"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)

               ; Note: DOCUMENT_TEXT_DETECTION will take precedence over TEXT_DETECTION
               reply := this.outer.request(coimage, this.settings.extension, "DOCUMENT_TEXT_DETECTION", "TEXT_DETECTION")

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
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }
      }

      class IBM extends Vis2.service.functor {
         static api := true

         request(base64, extension){
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.Open("POST", "https://watson-visual-recognition-duo-dev.ng.bluemix.net/api/classify", true)
            whr.SetRequestHeader("Accept", "application/json")
            whr.SetRequestHeader("Origin", "https://watson-visual-recognition-duo-dev.ng.bluemix.net")
            whr.SetRequestHeader("User-Agent", this.outer.user_agent)
            whr.SetRequestHeader("Content-Type", "application/json")
            whr.SetRequestHeader("Referer", "https://watson-visual-recognition-duo-dev.ng.bluemix.net/")

            req := {"type":"file", "image_file":"data:image/" extension ";base64," base64}

            whr.Send(JSON.Dump(req))
            whr.WaitForResponse()
            return JSON.Load(whr.ResponseText)
         }

         ; Vis2.service.IBM.ExplicitContent()
         class ExplicitContent extends Vis2.service.shared {

            class settings {
               static tooltip := "IBM: Explicit Content Detection Tool"
               static alert := "ERROR: No content could be detected."
               static extension := "jpg"
               static compression := "75"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)
               reply := this.outer.request(coimage, this.settings.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "explicit")
                     for j, value in reply[i].classes {
                        value.category := value.class
                        value.score    := value.score
                        obj.push(value)
                     }

               obj := this.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : ", ") . v.category " " Format("{:#.3f}", v.score)
               }

               data := sentence2
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.service.IBM.FindFaces()
         class FindFaces extends Vis2.service.shared {

            class settings {
               static tooltip := "IBM: Facial Recognition Tool"
               static alert := "ERROR: No facial features detected."
               static extension := "jpg"
               static compression := "75"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)
               reply := this.outer.request(coimage, this.settings.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "faces")
                     for j, value in reply[i].faces {
                        value.category := Format("{:i}", (value.age.max + value.age.min)/2) " year old " Format("{:L}", value.gender.gender)
                        value.location := {"x":value.face_location.left, "y":value.face_location.top, "w":value.face_location.width, "h":value.face_location.height}
                        obj.push(value)
                     }

               obj := this.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : ", ") . v.category " " Format("{:#.3f}", v.score)
               }

               data := sentence
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
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

         }

         ; Vis2.service.IBM.ImageIdentify()
         class ImageIdentify extends Vis2.service.shared {

            class settings {
               static tooltip := "IBM: Image Identification Tool"
               static alert := "ERROR: No image data found."
               static extension := "jpg"
               static compression := "75"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)
               reply := this.outer.request(coimage, this.settings.extension)
               i := 0, obj := {}
               while (i++ < reply.maxIndex())
                  if (reply[i].classifier_id = "default")
                     for j, value in reply[i].classes {
                        value.category := value.class
                        value.score    := value.score
                        obj.push(value)
                     }

               obj := this.QuickSort(obj)
               for k, v in obj {
                  sentence  .= ((A_Index == 1) ? "" : ", ") . v.category
                  sentence2 .= ((A_Index == 1) ? "" : "`r`n") . v.category ", " Format("{:#.3f}", v.score)
               }

               data := sentence2
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }

         ; Vis2.service.IBM.TextRecognize()
         class TextRecognize extends Vis2.service.shared {

            class settings {
               static tooltip := "IBM: Text Recognition Tool"
               static alert := "ERROR: No text data found."
               static extension := "png"
               static previewText := false
               static splashImage := true
            }

            convert(image, crop := ""){
               coimage := ImagePreprocess("base64", image, crop, this.settings.upscale, this.settings.extension, this.settings.compression)
               reply := this.outer.request(coimage, this.settings.extension)
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
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
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
         }
      }

      class Tesseract extends Vis2.service.functor {

         static leptonica := A_ScriptDir "\service\leptonica_util\leptonica_util.exe"
         static tesseract := A_ScriptDir "\service\tesseract\tesseract.exe"
         static tessdata := A_ScriptDir "\service\tesseract\tessdata" ; https://github.com/tesseract-ocr/tessdata

         ; Vis2.service.Tesseract.TextRecognize()
         class TextRecognize extends Vis2.service.shared {

            class settings {
               static tooltip := "Tesseract: Optical Character Recognition Tool"
               static alert := "ERROR: No text data found."
               static upscale := 2
               static convertImageDelay := 500
               static previewBounds := true
               static previewText := true
               static splashImage := false
            }

            uuid := this.CreateUUID()
            temp1 := A_Temp "\Vis2_screenshot" this.uuid ".bmp"
            temp2 := A_Temp "\Vis2_preprocess" this.uuid ".tif"
            temp3 := A_Temp "\Vis2_text" this.uuid ".tsv"

            ; Flow D-03 - Directly calls the convert() function of the service.
            ;             Returns the text data to the user's function.
            ;             Object data can be extracted using
            ;             Vis2.service.Tesseract.TextRecognize(image).FullData
            ; Next: COMPLETE
            convert(image, crop := ""){
               this.temp1 := ImagePreprocess("file", image, crop, this.settings.upscale, this.temp1, this.settings.compression)

               static ocrPreProcessing := 1
               static negateArg := 2
               static performScaleArg := 1
               static DoNotScale := 1

               if !(FileExist(this.outer.leptonica))
                  throw Exception("Leptonica not found.",, this.outer.leptonica)

               if !(FileExist(this.temp1))
                  throw Exception("File failed.",, _cmd)

               static q := Chr(0x22)
               _cmd := q this.outer.leptonica q " " q this.temp1 q " " q this.temp2 q
               _cmd .= " " negateArg " 0.5 " performScaleArg " " DoNotScale " " ocrPreProcessing " 5 2.5 " ocrPreProcessing " 2000 2000 0 0 0.0"
               _cmd := ComSpec " /C " q _cmd q
               RunWait, % _cmd,, Hide

               if !(FileExist(this.temp2))
                  throw Exception("Preprocessing failed.",, _cmd)

               coimage := this.temp2

               if !(FileExist(coimage))
                  throw Exception("File not found.",, coimage)

               if !(FileExist(this.outer.tesseract))
                  throw Exception("Tesseract not found.",, this.outer.tesseract)

               _cmd := q this.outer.tesseract q " --tessdata-dir " q this.outer.tessdata q
               _cmd .= " " q coimage q " " q SubStr(this.temp3, 1, -4) q
               _cmd .= (this.option) ? " -l " q this.option q : ""
               _cmd .= " -c tessedit_create_tsv=1 -c tessedit_pageseg_mode=1"
               _cmd := ComSpec " /C " q _cmd q
               ;_cmd := "powershell -NoProfile -command "  q  "& " _cmd q
               RunWait % _cmd,, Hide

               database := FileOpen(this.temp3, "r`n", "UTF-8")
               tsv := Trim(database.Read())
               database.Close()

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
                  polygon := []
                  polygon.push({"x":field[7], "y":field[8]})
                  polygon.push({"x":field[7] + field[9], "y":field[8]})
                  polygon.push({"x":field[7] + field[9], "y":field[8] + field[10]})
                  polygon.push({"x":field[7], "y":field[8] + field[10]})


                  if (word_num != field[6]) {
                     if (word_num != 0) {
                        line.words.push(word)
                        line.text .= (line.text == "") ? word.text : " " . word.text
                        line.score := (line.score == "") ? word.score : (1/word_num)*word.score + ((word_num - 1)/word_num)*line.score
                     }
                     word_num := field[6]
                     word := {}
                     word.word_number := field[6]
                     word.text := field[12]
                     word.score := field[11]
                     word.rectangle := rectangle
                  }

                  if (line_num != field[5]) {
                     if (line_num != 0) {
                        paragraph.lines.push(line)
                        paragraph.text .= (paragraph.text == "") ? line.text : "`r`n" . line.text
                        paragraph.score := (paragraph.score == "") ? line.score : (1/line_num)*line.score + ((line_num - 1)/line_num)*paragraph.score
                     }
                     line_num := field[5]
                     line := {"words":[]}
                     line.line_number := field[5]
                     line.rectangle := rectangle
                  }

                  if (par_num != field[4]) {
                     if (par_num != 0) {
                        block.paragraphs.push(paragraph)
                        block.text .= (block.text == "") ? paragraph.text : "`r`n" . paragraph.text
                        block.score := (block.score == "") ? paragraph.score : (1/par_num)*paragraph.score + ((par_num - 1)/par_num)*block.score
                     }
                     par_num := field[4]
                     paragraph := {"lines":[]}
                     paragraph.paragraph_number := field[4]
                     paragraph.rectangle := rectangle
                  }
                  if (block_num != field[3]) {
                     if (block_num != 0) {
                        text .= (text == "") ? block.text : "`r`n`r`n" . block.text
                        score := (score == "") ? block.score : (1/block_num)*block.score + ((block_num - 1)/block_num)*score
                        obj.push(block)
                     }
                     block_num := field[3]
                     block := {"paragraphs":[]}
                     block.block_number := field[3]
                     block.rectangle := rectangle
                     block.polygon := polygon
                  }
               }

               ; Append all unfinished blocks when end of tsv is reached.
               line.words.push(word)
               line.text .= (line.text == "") ? word.text : " " . word.text
               line.score := (line.score == "") ? word.score : (1/word_num)*word.score + ((word_num - 1)/word_num)*line.score
               paragraph.lines.push(line)
               paragraph.text .= (paragraph.text == "") ? line.text : "`r`n" . line.text
               paragraph.score := (paragraph.score == "") ? line.score : (1/line_num)*line.score + ((line_num - 1)/line_num)*paragraph.score
               block.paragraphs.push(paragraph)
               block.text .= (block.text == "") ? paragraph.text : "`r`n" . paragraph.text
               block.score := (block.score == "") ? paragraph.score : (1/par_num)*paragraph.score + ((par_num - 1)/par_num)*block.score
               text .= (text == "") ? block.text : "`r`n`r`n" . block.text
               score := (score == "") ? block.score : (1/block_num)*block.score + ((block_num - 1)/block_num)*score
               obj.push(block)

               data := text
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }

            __Delete(){
               try FileDelete, % this.temp1
               try FileDelete, % this.temp2 ; coimage
               try FileDelete, % this.temp3
            }
         }
      }

      class Wolfram extends Vis2.service.functor {

         request(filename){
            objParam := { "image": [filename] }

            CreateFormData(postData, hdr_ContentType, objParam)

            static q := Chr(0x22)
            whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr.Open("POST", "https://www.imageidentify.com/objects/user-26a7681f-4b48-4f71-8f9f-93030898d70d/prd/imageapi", true)
            whr.SetRequestHeader("Accept", "application/json, text/javascript, */*; q=0.01")
            whr.SetRequestHeader("Origin", "https://www.imageidentify.com")
            whr.SetRequestHeader("X-Requested-With", "XMLHttpRequest")
            whr.SetRequestHeader("Content-Disposition", "attachment; filename=" q filename q)
            whr.SetRequestHeader("User-Agent", this.outer.user_agent)
            whr.SetRequestHeader("Content-Type", hdr_ContentType)
            whr.SetRequestHeader("Referer", "https://www.imageidentify.com/")

            whr.Send(postData)
            whr.WaitForResponse()
            return JSON.Load(whr.ResponseText)
         }

         class ImageIdentify extends Vis2.service.shared {

            class settings {
               static tooltip := "Wolfram: Image Identification Tool"
               static alert := "ERROR: No image content found."
               static compression := "92"
               static previewText := false
               static splashImage := true
            }

            uuid := this.CreateUUID()
            file := A_Temp "\Vis2_screenshot" this.uuid ".png"

            convert(image, crop := ""){
               coimage := ImagePreprocess("file", image, crop, this.file, this.settings.compression)
               reply := this.outer.request(coimage)
               obj := reply.identify
               obj.category := reply.title
               obj.score    := reply.score
               data := reply.identify.title
               data.base.coimage := coimage
               data.base.FullData := obj
               for reference, function in Vis2.Text {
                  if IsFunc(function)
                     data.base[reference] := ObjBindMethod(Vis2.Text, reference)
               } ; All of the functions in Vis2.Text can now be called as such: data.google()
               return data
            }
         }
      }
   }

   class ux {

      ; Flow C-03 - returnData() is a wrapper function that waits for Vis2.ux.start().
      ;             Unlike Vis2.ux.start(), this function will return a string of text.
      ;             To call directly: Vis2.ux.returnData(new Vis2.service.Tesseract.TextRecognize())
      ; Next: Flow C-04
      returnData(terms*){
         if (error := Vis2.ux.start(terms*))
            return error
         while !(Vis2.ux.io.status)
            Sleep 10
         return Vis2.ux.io.data
      }

      ; Flow C-04 - start() is the function that launches the user interface.
      ;             This can be called directly without calling Vis2.ux.returnData().
      ;             To call directly: Vis2.ux.start(new Vis2.service.Tesseract.TextRecognize())
      start(service, settings := ""){
      static void := ObjBindMethod({}, {})

         if (Vis2.ux.io.status == 0) {
            Vis2.ux.io.settings.palette++
            return "Already in use."
         }

         if !IsObject(settings) {
            settings := service.settings                 ; service specific settings
            settings.base := Vis2.settings               ; default settings
         }

         Vis2.ux.io := {"data": ""                       ; return data
                     , "status": 0                       ; -2 = blank data; -1 = escaped; 0 = in progress; 1 = success
                     , "settings": settings}             ; reference to settings object for I/O.

         Vis2.ux.setSystemCursor(32515)                  ; IDC_Cross := 32515
         Hotkey, LButton, % void, On
         Hotkey, ^LButton, % void, On
         Hotkey, !LButton, % void, On
         Hotkey, +LButton, % void, On
         Hotkey, RButton, % void, On
         Hotkey, Escape, % void, On

         Graphics.Startup()
         state := {}
         state.selectMode := "Quick"
         state.subtitle := new Graphics.Subtitle("Vis2_Hermes")
            .render(settings.tooltip, settings.subtitle.background, settings.subtitle.text)
         ;Tooltip % A_TickCount - state.subtitle.TickCount
         state.area := new Graphics.Area("Vis2_Aries")
         state.information := new Graphics.Subtitle("Vis2_Information")
         state.picture := new Graphics.Picture("Vis2_Kitsune")
         state.polygon := new Graphics.Picture("Vis2_Polygon")

         state.area.cache := 0
         state.area.color := settings.area.c
         state.style1_back := settings.subtitle.background
         state.style1_text := settings.subtitle.text

         state.style2_back := settings.subtitle.background.set("color", "#FF88EAB6")
         state.style2_text := settings.subtitle.text

         Vis2.ux.process.waitForUserInput(state, service, settings) ; Ensure this is run once.
         return
      }

      class process {

         waitForUserInput(state, service, settings){
            if (GetKeyState("Escape", "P"))
               return Vis2.ux.escape(state, -1)

            if (GetKeyState("LButton", "P")) {
               selectImage := ObjBindMethod(Vis2.ux.process, "selectImage", state, settings)
               SetTimer, % selectImage, -10
               if (settings.previewText || settings.previewImage || settings.previewBounds) {
                  Vis2.ux.process.display(state, "Searching for data...", state.style1_back, state.style1_text)
                  convertImage := ObjBindMethod(Vis2.ux.process, "convertImage", state, service, settings)
                  SetTimer, % convertImage, -250
               }
               else
                  Vis2.ux.process.display(state, "Waiting for user selection...", state.style2_back, state.style2_text, "Still patiently waiting for user selection...")
               return
            }

            if (A_Cursor == "Unknown" && WinExist("A") != state.area.hwnd) ; BUGFIX: Flickering on custom cursor
               state.area.clickThrough(1)

            state.area.origin()
            waitForUserInput := ObjBindMethod(Vis2.ux.process, "waitForUserInput", state, service, settings)
            SetTimer, % waitForUserInput, -10
            return
         }

         selectImage(state, settings){
            Critical On
            if (GetKeyState("Escape", "P"))
               return Vis2.ux.process.treasureChest(state, settings, A_ThisFunc, "escape")

            if (state.selectMode == "Quick")
               Vis2.ux.process.selectImageQuick(state, settings)
            if (state.selectMode == "Advanced")
               Vis2.ux.process.selectImageAdvanced(state, settings)

            Vis2.ux.process.display(state) ; Detect overlap mostly.

            if !(state.unlock.1 ~= "^Vis2\.ux\.process\.selectImage" || state.unlock.2 ~= "^Vis2\.ux\.process\.selectImage") {
               selectImage := ObjBindMethod(Vis2.ux.process, "selectImage", state, settings)
               SetTimer, % selectImage, -10
            }
            Critical Off
            return
         }

         selectImageQuick(state, settings){
            if (A_Cursor == "Unknown" && WinExist("A") != state.area.hwnd) ; BUGFIX: Flickering on custom cursor
               state.area.clickThrough(1)

            if (GetKeyState("LButton", "P")) {
               if (GetKeyState("Control", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P"))
                  Vis2.ux.process.selectImageTransition(state, settings) ; Must be last thing to happen.
               else if (GetKeyState("RButton", "P")) {
                  state.area.move()
                  if (!state.area.isMouseOnCorner() && state.area.isMouseStopped()) {
                     state.area.drag() ; Error Correction of Offset
                  }
               }
               else
                  state.area.drag()
            }
            else
               return Vis2.ux.process.treasureChest(state, settings, A_ThisFunc)
            return
         }

         selectImageTransition(state, settings){
         static void := ObjBindMethod({}, {})

            DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint",0, "uint",0, "uint",0) ; RestoreCursor()
            Hotkey, Space, % void, On
            Hotkey, ^Space, % void, On
            Hotkey, !Space, % void, On
            Hotkey, +Space, % void, On
            state.area.clickThrough(0) ; Allow the cursor to change again.
            state.tokenMousePressed := 1
            state.key := {}
            state.action := {}
            state.selectMode := "Advanced" ; Exit selectImageQuick.
            state.note_01 := TextRender("Advanced Mode - Press spacebar to select."
               , "time:30000 x:center y:16.67vh m:1.35vmin r:8px c:55F9E27E"
               , "font:(Century Gothic) size:3.33vmin color:#F88958"
               . A_Space "outline:(stroke:1px color:#F88958 glow:2px tint:Indigo)"
               . A_Space "dropShadow:(horizontal:3px vertical:3px color:#009DA7 blur:5px opacity:0.33 size:15px)")
            return
         }

         selectImageAdvanced(state, settings){
         static void := ObjBindMethod({}, {})

            if ((state.area.width() < -25 || state.area.height() < -25) && !state.note_02)
               state.note_02 := TextRender("Press Alt + LButton to create a new selection anywhere on screen."
                  , state.style1_back.clone().set("time", "6250").set("y", "66.67vh").set("color", "FCF9AF")
                  , state.style1_text.clone())

            state.key.LButton := GetKeyState("LButton", "P") ? 1 : 0
            state.key.RButton := GetKeyState("RButton", "P") ? 1 : 0
            state.key.Space   := GetKeyState("Space", "P")   ? 1 : 0
            state.key.Control := GetKeyState("Control", "P") ? 1 : 0
            state.key.Alt     := GetKeyState("Alt", "P")     ? 1 : 0
            state.key.Shift   := GetKeyState("Shift", "P")   ? 1 : 0

            ; Check if mouse is inside on activation.
            state.action.Control_LButton := (state.area.isMouseInside() && state.key.Control && state.key.LButton)
               ? 1 : (state.key.Control && state.key.LButton) ? state.action.Control_LButton : 0
            state.action.Shift_LButton   := (state.area.isMouseInside() && state.key.Shift && state.key.LButton)
               ? 1 : (state.key.Shift && state.key.LButton) ? state.action.Shift_LButton : 0
            state.action.LButton         := (state.area.isMouseInside() && state.key.LButton)
               ? 1 : (state.key.LButton) ? state.action.LButton : 0
            state.action.RButton         := (state.area.isMouseInside() && state.key.RButton)
               ? 1 : (state.key.RButton) ? state.action.RButton : 0

            ;___|���|___ 00011111000 Keypress
            ;___|_______ 0001----000 Activation Function (pseudo heaviside)
            state.action.Control_Space   := (state.key.Control && state.key.Space)
               ? ((!state.action.Control_Space) ? 1 : -1) : 0
            state.action.Alt_Space       := (state.key.Alt && state.key.Space)
               ? ((!state.action.Alt_Space) ? 1 : -1) : 0
            state.action.Shift_Space     := (state.key.Shift && state.key.Space)
               ? ((!state.action.Shift_Space) ? 1 : -1) : 0
            state.action.Alt_LButton     := (state.key.Alt && state.key.LButton)
               ? ((!state.action.Alt_LButton) ? 1 : -1) : 0

            ; Ensure only Space is pressed.
            state.action.Space := (state.key.Space && !state.key.Control && !state.key.Alt && !state.key.Shift)
               ? ((!state.action.Space) ? 1 : -1) : 0

            ; Mouse Hotkeys
            if (state.action.Control_LButton)
               state.area.resizeCorners()
            else if (state.action.Alt_LButton = 1)
               state.area.origin()
            else if (state.action.Alt_LButton = -1)
               state.area.drag()
            else if (state.action.Shift_LButton)
               state.area.resizeEdges()
            else if (state.action.LButton || state.action.RButton)
               state.area.move()
            else {
               state.area.hover() ; Collapse Stack
               if state.area.isMouseInside() {
                  Hotkey, LButton, % void, On
                  Hotkey, RButton, % void, On
               } else {
                  Hotkey, LButton, % void, Off
                  Hotkey, RButton, % void, Off
               }
            }

            ; Space Hotkeys
            if (state.action.Control_Space = 1) {
               if (settings.previewImage := !settings.previewImage) ; Toggle our new previewImage flag!
                  state.picture.render(Vis2.ux.io.data.coimage, "size:auto width:100vw height:33vh", Vis2.ux.io.data.FullData).show()
               else
                  state.picture.hide()
            } else if (state.action.Alt_Space = 1) {
               if (settings.showCoordinates := !settings.showCoordinates) {
                  c2 := RegExReplace((state.coordinates) ? state.coordinates : state.area.screenshotCoordinates(), "^(\d+)\|(\d+)\|(\d+)\|(\d+)$", "x`n$1`n`ny`n$2`n`nw`n$3`n`nh`n$4")
                  state.information.render(c2, "a:centerright x:98.14vw y:center w:8.33vmin h:33.33vmin r:8px c:DD000000"
                     , state.style1_text.clone().set("y", "center").set("justify", "center")).show()
               } else
                  state.information.hide()
            } else if (state.action.Shift_Space = 1) {

            } else if (state.action.Space = 1) {
               return Vis2.ux.process.treasureChest(state, settings, A_ThisFunc) ; return this!
            }
            return
         }

         convertImage(state, service, settings, bypass:=""){
            ; The bypass parameter is normally used when convertImage is off, producing no text on screen.
            ; Check for valid coordinates, returns "" if invalid.
            if (coordinates := state.area.screenshotCoordinates()) {
               ; Sometimes a user will make the subtitle blink from top to bottom. If so, hide subtitle temporarily.
               (overlap1 := Vis2.ux.process.overlap(state.area.rect(), state.subtitle.rect())) ? state.subtitle.hide() : ""
               (overlap2 := Vis2.ux.process.overlap(state.area.rect(), state.picture.rect())) ? state.picture.hide() : ""
               (overlap3 := Vis2.ux.process.overlap(state.area.rect(), state.information.rect())) ? state.information.hide() : ""
               (overlap4 := Vis2.ux.process.overlap(state.area.rect(), state.polygon.rect())) ? state.polygon.hide() : ""
               ;state.area.changeColor(0x01FFFFFF) ; Lighten Area object, but do not hide or delete it until key up.
               pBitmap := Gdip_BitmapFromScreen(coordinates) ; To avoid the grey tint, call Area.Hide() but this will cause flickering.
               ;state.area.changeColor(0x7FDDDDDD) ; Lighten Area object, but do not hide or delete it until key up.
               (overlap3 && settings.showCoordinates) ? state.information.show() : ""
               (overlap2 && settings.previewImage) ? state.picture.show() : ""
               (overlap1) ? state.subtitle.show() : ""
               (overlap1 || overlap2 || overlap3) ? state.area.show() : ""
               (overlap4) ? state.polygon.show() : "" ; Assert Topmost position in z-order.

               ; If any x,y,w,h coordinates are different, or the image has changed (like video), proceed.
               if (bypass || coordinates != state.coordinates || !state.picture.isBitmapEqual(pBitmap, state.pBitmap)) {

                  ; Declare type as pBitmap
                  try data := service.convert({"pBitmap":pBitmap})
                  catch e {
                     MsgBox, 16,, % "Exception thrown!`n`nwhat: " e.what "`nfile: " e.file
                        . "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra "`ncoordinates: " coordinates
                  }

                  if (Vis2.ux.io.status == 0)
                     Vis2.ux.io.data := data ; Eliminate race condition.
                  else
                     return Gdip_DisposeImage(pBitmap) ; If selectImage exited while convert, destroy the pBitmap.

                  ; Do not update last coordinates (space) and last pBitmap (time) until conversion finishes.
                  ; In Vis2.ux.process.treasureChest(), state.coordinates will be compared to user's mouse release.
                  if (state.pBitmap)
                     Gdip_DisposeImage(state.pBitmap)
                  state.coordinates := coordinates
                  state.pBitmap := pBitmap

                  ; Visual Effects
                  if (!bypass) {
                     if (settings.showCoordinates) {
                        c2 := RegExReplace(state.coordinates, "^(\d+)\|(\d+)\|(\d+)\|(\d+)$", "x`n$1`n`ny`n$2`n`nw`n$3`n`nh`n$4")
                        state.information.render(c2, "a:centerright x:98.14vw y:center w:8.33vmin h:33.33vmin r:8px c:DD000000", "f:(Arial) j:center y:center s:2.23% c:White")
                     }
                     if (settings.previewImage)
                        state.picture.render(Vis2.ux.io.data.coimage, "size:auto width:100vw height:33vh", Vis2.ux.io.data.FullData)
                     if (settings.previewBounds) {
                        xywh := StrSplit(state.coordinates, "|") ; use saved coordinates!
                        state.polygon.render(, {"size":1/settings.upscale, "x":xywh.1, "y":xywh.2, "w":xywh.3, "h":xywh.4}, Vis2.ux.io.data.FullData)
                     }
                     Vis2.ux.process.display(state, (Vis2.ux.io.data.maxLines(3)) ? Vis2.ux.io.data.maxLines(3) : settings.alert)
                  }
               }
               else { ; This is an identical image, so delete it.
                  Gdip_DisposeImage(pBitmap)
               }
            }

            if (state.unlock.1 && !state.unlock.2)
               return Vis2.ux.process.treasureChest(state, settings, A_ThisFunc)
            else if (!state.unlock.2) {
               convertImage := ObjBindMethod(Vis2.ux.process, "convertImage", state, service, settings)
               SetTimer, % convertImage, % -Abs(settings.previewText)
            }
            return
         }

         treasureChest(state, settings, key, escape:=""){
            ; Create an "unlock" object with two vacancies that will be filled when SelectImage and ConvertImage return.
            (IsObject(state.unlock) && key != state.unlock.1) ? state.unlock.push(key) : (state.unlock := [key])

            ; Immediately escape when called by SelectImage.
            if (escape) {
               Vis2.ux.io.data := "" ; race condition in ConvertImage!
               return Vis2.ux.escape(state, -1)
            }

            ; ConvertImage will do nothing when escaped via SelectImage.
            if (Vis2.ux.io.status != 0)
               return

            ; SelectImage returns. If ConvertImage was not started, start it now.
            if (key ~= "^Vis2\.ux\.process\.selectImage") {
               state.area.changeColor(0x01FFFFFF) ; Lighten Area object, but do not hide or delete it until key up.
               if (!settings.previewText) {
                  Vis2.ux.process.display(state, "Processing using " RegExReplace(settings.base.__class, ".*\.(.*)\.(.*)$", "$1's $2()..."), state.style2_back, state.style2_text)
                  return Vis2.ux.process.convertImage(state, service, settings, "bypass")
               } else {
                  ; If user's final coordinates and last processed coordinates are the same:
                  ; Do an early exit. Don't wait for the in progress convertImage to return. Skip that.
                  if (state.area.screenshotCoordinates() == state.coordinates)
                     return Vis2.ux.process.finale(state, settings)
               }
            }

            ; ConvertImage returns.
            if (state.unlock.maxIndex() == 2) {
               ; Even though ConvertImage has returned, make sure that the area coordinates when the mouse was released
               ; are equal to the coordinates that were sent to the last iteration of ConvertImage.
               if (state.area.screenshotCoordinates() != state.coordinates)
                  Vis2.ux.process.convertImage(state, service, settings, "bypass")
               return Vis2.ux.process.finale(state, settings)
            }
            return
         }

         finale(state, settings){
            if (Vis2.ux.io.data == "") {
               if (!settings.previewText)
                  TextRender(settings.alert, "time:1500 x:center y:83.33vh margin:1.35vmin c:FFB1AC radius:8", "f:(Arial) s2.23% c:Black")
               return Vis2.ux.escape(state, -2) ; blank data
            }

            t := 1250
            t += 8*Vis2.ux.io.data.maxLines(3).characters() ; Each character adds 8 milliseconds to base.
            if (settings.splashImage) {
               t += 1250                                    ; BUGFIX: Separate it, objects bug out occasionally.
               t += 75*Vis2.ux.io.data.FullData.maxIndex()  ; Each category adds 75 milliseconds to base.
            }

            if (settings.toClipboard)
               clipboard := Vis2.ux.io.data

            (settings.splashBounds) ? ImageRender(
               , {"time":t, "size":1/settings.upscale, "x":state.area.x1(), "y":state.area.y1(), "w":state.area.width(), "h":state.area.height()}
               , Vis2.ux.io.data.FullData).FreeMemory() : ""
            (settings.splashImage) ? ImageRender(Vis2.ux.io.data.coimage
               , "time:" t " a:center x:center y:40.99vh margin:0.926vmin size:auto width:100vw height:80.13vh"
               , Vis2.ux.io.data.FullData).FreeMemory() : ""
            (settings.splashText) ? TextRender(Vis2.ux.io.data.maxLines(3)
               , state.style1_back.clone().set("time", t).set("color", "Black")
               , state.style1_text.clone()) : ""
            (settings.toClipboard) ? TextRender("Saved to Clipboard."
               , state.style1_back.clone().set("time", t).set("y", "75.00vh").set("color", "#F9E486")
               , state.style1_text.clone()) : ""

            state.subtitle.hide()

            return Vis2.ux.escape(state, 1)  ; Success.
         }

         display(state, text := "", backgroundStyle := "", textStyle := "", overlapText := ""){
            if (overlap := Vis2.ux.process.overlap(state.area.rect(), state.subtitle.rect())) {
                state.style1_back.y := (state.style1_back.y == "83.33vh") ? "2.07vh" : "83.33vh"
                state.style2_back.y := (state.style2_back.y == "83.33vh") ? "2.07vh" : "83.33vh"
            }

            ; Save the current text so when overlap is detected, it can remember the last text.
            if (text != "")
               state.displayText := text
            if (overlapText != "")
               state.displayOverlapText := overlapText

            ; Render text on screen.
            if (overlap || text != "")
               state.subtitle.render((overlap && state.displayOverlapText) ? state.displayOverlapText : state.displayText, backgroundStyle, textStyle)
         }

         overlap(rect1, rect2) {
            if !(IsObject(rect1) && IsObject(rect2))
               return

            a := (rect1.1 <= rect2.1 && rect2.1 <= rect1.3) || (rect1.1 <= rect2.3 && rect2.3 <= rect1.3)
               || (rect2.1 <= rect1.1 && rect1.1 <= rect2.3) || (rect2.1 <= rect1.3 && rect1.3 <= rect2.3)
            b := (rect1.2 <= rect2.2 && rect2.2 <= rect1.4) || (rect1.2 <= rect2.4 && rect2.4 <= rect1.4)
               || (rect2.2 <= rect1.2 && rect1.2 <= rect2.4) || (rect2.2 <= rect1.4 && rect1.4 <= rect2.4)
            ;Tooltip % a "`t" b "`n`n" rect1.1 "`t" rect1.2 "`n" rect1.3 "`t" rect1.4 "`n`n" rect2.1 "`t" rect2.2 "`n" rect2.3 "`t" rect2.4
            return (a && b)
         }
      }

      escape(state, status){
      static void := ObjBindMethod({}, {})

         ; Fixes a bug where AHK does not detect key releases if there is an admin-level window beneath.
         ; This code must be positioned before state.area.destroy().
         if WinActive("ahk_id" state.area.hwnd) {
            KeyWait Control
            KeyWait Alt
            KeyWait Shift
            KeyWait RButton
            KeyWait LButton
            KeyWait Space
            KeyWait Escape
         }

         state.area.destroy()
         state.picture.destroy()
         state.polygon.destroy()
         state.information.destroy()
         state.subtitle.destroy()
         state.note_01.hide() ; Let them time out instead of Destroy()
         state.note_02.destroy()
         Gdip_DisposeImage(state.pBitmap) ; This must be positioned before state := ""
         state := "" ; Goodbye all, you were loved :c
         Graphics.Shutdown()

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
         DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint",0, "uint",0, "uint",0) ; RestoreCursor()

         Vis2.ux.io.status := status
         return
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
         DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint",0, "uint",0, "uint",0) ; RestoreCursor
         state.area.hide()
         return
      }

      resume(){
         Hotkey, LButton, % void, On
         Hotkey, ^LButton, % void, On
         Hotkey, !LButton, % void, On
         Hotkey, +LButton, % void, On
         Hotkey, RButton, % void, On
         Hotkey, Escape, % void, On

         if (state.selectMode == "Quick")
            Vis2.ux.setSystemCursor(32515) ; IDC_Cross := 32515

         if (state.selectMode == "Advanced") {
            Hotkey, Space, % void, On
            Hotkey, ^Space, % void, On
            Hotkey, !Space, % void, On
            Hotkey, +Space, % void, On
         }
         state.area.show()
         return
      }

      setSystemCursor(CursorID = "", cx = 0, cy = 0 ) { ; Thanks to Serenity - https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
         static SystemCursors := "32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651"

         Loop, Parse, SystemCursors, `,
         {
               Type := "SystemCursor"
               CursorHandle := DllCall("LoadCursor", "uint",0, "int",CursorID)
               %Type%%A_Index% := DllCall("CopyImage", "uint",CursorHandle, "uint",0x2, "int",cx, "int",cy, "uint",0)
               CursorHandle := DllCall("CopyImage", "uint",%Type%%A_Index%, "uint",0x2, "int",0, "int",0, "int",0 )
               DllCall("SetSystemCursor", "uint",CursorHandle, "int",A_Loopfield) ; Destroys CursorHandle
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
            ; (A) If a string�s ratio of alphanumeric characters to total characters is less than 50%...
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

      characters(data) {
         RegExReplace(data, "s).", "", i)
         return i
      }

      clipboard(data){
         clipboard := data
         return data
      }

      file(data, filename:="Vis2.txt") {
         file := FileOpen(filename, "w", "UTF-8")
         file.write(data)
         file.close()
         return data
      }

      google(data) {
         if (data == "")
            return
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
            temp := Trim(A_LoopField)
            if (temp != "") {
               copy .= (copy) ? ("`n" . temp) : temp
               i++
            }
         } until (i > lines)
         return copy
      }
   }
}


/*
   CreateFormData - Creates "multipart/form-data" for http post

   Usage: CreateFormData(ByRef retData, ByRef retHeader, objParam)

      retData   - (out) Data used for HTTP POST.
      retHeader - (out) Content-Type header used for HTTP POST.
      objParam  - (in)  An object defines the form parameters.

                  To specify files, use array as the value. Example:
                      objParam := { "key1": "value1"
                                  , "upload[]": ["1.png", "2.png"] }

   Requirement: BinArr.ahk -- https://gist.github.com/tmplinshi/a97d9a99b9aa5a65fd20
   Version    : 1.20 / 2016-6-17 - Added CreateFormData_WinInet(), which can be used for VxE's HTTPRequest().
                1.10 / 2015-6-23 - Fixed a bug
                1.00 / 2015-5-14
*/

; Used for WinHttp.WinHttpRequest.5.1, Msxml2.XMLHTTP ...
CreateFormData(ByRef retData, ByRef retHeader, objParam) {
   New CreateFormData(retData, retHeader, objParam)
}

; Used for WinInet
CreateFormData_WinInet(ByRef retData, ByRef retHeader, objParam) {
   New CreateFormData(safeArr, retHeader, objParam)

   size := safeArr.MaxIndex() + 1
   VarSetCapacity(retData, size, 1)
   DllCall("oleaut32\SafeArrayAccessData", "ptr", ComObjValue(safeArr), "ptr*", pdata)
   DllCall("RtlMoveMemory", "ptr", &retData, "ptr", pdata, "ptr", size)
   DllCall("oleaut32\SafeArrayUnaccessData", "ptr", ComObjValue(safeArr))
}

Class CreateFormData {

   __New(ByRef retData, ByRef retHeader, objParam) {

      static CRLF := "`r`n"

      ; Generate a random boundary.
      boundary := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
      Sort, boundary, D| Random
      boundary := StrReplace(boundary, "|")
      boundary := SubStr(boundary, 1, 12)
      boundaryLine := "------------------------------" . boundary

      ; Loop input paramters
      binArrs := []
      For k, v in objParam
      {
         If IsObject(v) {
            For i, FileName in v
            {
               str := BoundaryLine . CRLF
                  . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
                  . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF
               binArrs.Push( BinArr_FromString(str) )
               binArrs.Push( BinArr_FromFile(FileName) )
               binArrs.Push( BinArr_FromString(CRLF) )
            }
         } else {
            str := BoundaryLine . CRLF
               . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
               . v . CRLF
            binArrs.Push( BinArr_FromString(str) )
         }
      }

      str := BoundaryLine . "--" . CRLF
      binArrs.Push( BinArr_FromString(str) )

      retData := BinArr_Join(binArrs*)
      retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
   }

   MimeType(FileName) {
      n := FileOpen(FileName, "r").ReadUInt()
      Return (n        = 0x474E5089) ? "image/png"
           : (n        = 0x38464947) ? "image/gif"
           : (n&0xFFFF = 0x4D42    ) ? "image/bmp"
           : (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
           : (n&0xFFFF = 0x4949    ) ? "image/tiff"
           : (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
           : "application/octet-stream"
   }
}

; Update: 2015-6-4 - Added BinArr_ToFile()

BinArr_FromString(str) {
   oADO := ComObjCreate("ADODB.Stream")

   oADO.Type := 2 ; adTypeText
   oADO.Mode := 3 ; adModeReadWrite
   oADO.Open
   oADO.Charset := "UTF-8"
   oADO.WriteText(str)

   oADO.Position := 0
   oADO.Type := 1 ; adTypeBinary
   oADO.Position := 3 ; Skip UTF-8 BOM
   return oADO.Read, oADO.Close
}

BinArr_FromFile(FileName) {
   oADO := ComObjCreate("ADODB.Stream")

   oADO.Type := 1 ; adTypeBinary
   oADO.Open
   oADO.LoadFromFile(FileName)
   return oADO.Read, oADO.Close
}

BinArr_Join(Arrays*) {
   oADO := ComObjCreate("ADODB.Stream")

   oADO.Type := 1 ; adTypeBinary
   oADO.Mode := 3 ; adModeReadWrite
   oADO.Open
   For i, arr in Arrays
      oADO.Write(arr)
   oADO.Position := 0
   return oADO.Read, oADO.Close
}

BinArr_ToString(BinArr, Encoding := "UTF-8") {
   oADO := ComObjCreate("ADODB.Stream")

   oADO.Type := 1 ; adTypeBinary
   oADO.Mode := 3 ; adModeReadWrite
   oADO.Open
   oADO.Write(BinArr)

   oADO.Position := 0
   oADO.Type := 2 ; adTypeText
   oADO.Charset  := Encoding
   return oADO.ReadText, oADO.Close
}

BinArr_ToFile(BinArr, FileName) {
   oADO := ComObjCreate("ADODB.Stream")

   oADO.Type := 1 ; adTypeBinary
   oADO.Open
   oADO.Write(BinArr)
   oADO.SaveToFile(FileName, 2)
   oADO.Close
}
