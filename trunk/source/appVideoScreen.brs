'********************************************************************
'**  PlayOn Video Player Application - Video Playback
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - Video Playback 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'***********************************************************
'** Create and show the video screen.  The video screen is
'** a special full screen video playback component.  It 
'** handles most of the keypresses automatically and our
'** job is primarily to make sure it has the correct data 
'** at startup. We will receive event back on progress and
'** error conditions so it's important to monitor these to
'** understand what's going on, especially in the case of errors
'***********************************************************  
Function showVideoScreen(video As Object)

    if type(video) <> "roAssociativeArray" then
        Dbg("showVideoScreen: invalid data passed to showVideoScreen")
        return -1
    endif

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)


	boolStr = RegRead("IncreasedBuffering")
	IncreasedBufferingOn = strtobool(boolStr)
	
	bitrates  = [800]    
	if IncreasedBufferingOn = true then
        Dbg("showVideoScreen: Increasing video buffer")
		bitrates  = [2200]    
	end if
	
    qualities = ["SD"]
    streamformat = "hls"
	srt = ""
	
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = video.StreamURls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = streamformat
    videoclip.Title = video.Title
	
    if srt <> invalid and srt <> "" then
        videoclip.SubtitleUrl = srt
    end if

	if showInitPlayOnStream(video) = true then
		Dbg("showVideoScreen: Stream is ready")
	end if

    screen.SetContent(videoclip)
    screen.show()

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isScreenClosed()
                Dbg("showVideoScreen: Screen closed")
                exit while
            elseif msg.isRequestFailed()
                Dbg("showVideoScreen: video request failure, index = ", msg.GetIndex())
				Dbg("showVideoScreen: video request failure, data =  ", msg.GetData() )
				ShowErrorDialog(msg.getMessage(), "Video Request Failure")
			elseif msg.isPlaybackPosition()
				Dbg("showVideoScreen: playback position = " + tostr(msg.GetIndex()))
			elseif msg.isStreamStarted()
				Dbg("showVideoScreen: stream started")
            elseif msg.isStatusMessage()
                Dbg("showVideoScreen: video status index= ", msg.GetIndex())
				Dbg("showVideoScreen: video status data = ", msg.GetData())
            elseif msg.isButtonPressed()
                Dbg("showVideoScreen: button pressed = ", msg.GetIndex())
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
            else
                Dbg("showVideoScreen: unexpected event type = ", msg.GetType())
            end if
        else
            Dbg("showVideoScreen: unexpected message class = " + type(msg))
        end if
    end while

End Function

Function showInitPlayOnStream(video As Object) As Boolean

	delayTime = 500
	
	if video.videoURL <> invalid then

		waitobj = ShowPleaseWait("Preparing stream, please wait...", "")

		http = NewHttp(video.videoURL)
		Dbg("showInitPlayOnStream: video url = ", http.Http.GetUrl())

		m3u8String = http.GetToStringWithTimeout(60)
		
		if Len(m3u8String) > 0 then
			r = CreateObject("roRegex", "\n", "")
			lines = r.Split(m3u8String)
			Dbg("showInitPlayOnStream: number of lines = " + itostr((lines.Count())))

			relativeURL = invalid
			
			lines.ResetIndex()
			line = lines.GetIndex()
			while line <> invalid
				if Left(line, 1) <> "" and Left(line,1) <> "#" then
					relativeURL = line
				end if
				
				line = lines.GetIndex()
			end while	
			
			if relativeURL <> invalid then
				hlsURL = "http://" + video.IP + "/" + video.ContentId + "/" + relativeURL
				http = NewHttp(hlsURL)
				Dbg("showInitPlayOnStream: url = ", http.Http.GetUrl())

				m3u8String = http.GetToStringWithTimeout(60)

				if Len(m3u8String) > 0 then
					sleep(delayTime)
					return true
				end if
			end if
		end if
	end if
	
	return false
End Function
