'********************************************************************
'**  PlayOn Video Player Application - Main
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - URL Utilities 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'******************************************************
'** Create a URL Transfer object
'******************************************************
Function CreateURLTransferObject(url As String) as Object
    obj = CreateObject("roUrlTransfer")
    obj.SetPort(CreateObject("roMessagePort"))
    obj.SetUrl(url)
    obj.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    obj.EnableEncodings(true)
    return obj
End Function

'******************************************************
'** Url Query builder
'******************************************************
Function NewHttp(url As String) as Object
    obj = CreateObject("roAssociativeArray")
    obj.Http                        = CreateURLTransferObject(url)
    obj.FirstParam                  = true
    obj.AddParam                    = http_add_param
    obj.AddRawQuery                 = http_add_raw_query
    obj.GetToStringWithRetry        = http_get_to_string_with_retry
    obj.PrepareUrlForQuery          = http_prepare_url_for_query
    obj.GetToStringWithTimeout      = http_get_to_string_with_timeout
    obj.PostFromStringWithTimeout   = http_post_from_string_with_timeout

    if Instr(1, url, "?") > 0 then obj.FirstParam = false

    return obj
End Function

'******************************************************
'** Encode an http string
'******************************************************
Function HttpEncode(str As String) As String
    o = CreateObject("roUrlTransfer")
    return o.Escape(str)
End Function

'******************************************************
'** Decode an http string
'******************************************************
Function HttpDecode(str As String) As String
    strReplace(str,"+"," ") ' backward compatibility
    o = CreateObject("roUrlTransfer")
    return o.Unescape(str)
End Function

'******************************************************
'** Prepare URL for adding query parameters
'******************************************************
Function http_prepare_url_for_query() As String
    url = m.Http.GetUrl()
    if m.FirstParam then
        url = url + "?"
        m.FirstParam = false
    else
        url = url + "&"
    endif
    m.Http.SetUrl(url)
    return url
End Function

'******************************************************
'** add the name/value parameter 
'******************************************************
Function http_add_param(name As String, val As String) as Void
    q = m.Http.Escape(name)
    q = q + "="
    url = m.Http.GetUrl()
    if Instr(1, url, q) > 0 return    'Parameter already present
    q = q + m.Http.Escape(val)
    m.AddRawQuery(q)
End Function

'******************************************************
'** append raw query string to the end
'******************************************************
Function http_add_raw_query(query As String) as Void
    url = m.PrepareUrlForQuery()
    url = url + query
    m.Http.SetUrl(url)
End Function

'******************************************************
'** perform AsyncGetToString in a retry loop
'******************************************************
Function http_get_to_string_with_retry() as String
    timeout%         = 1500
    num_retries%     = 5

    str = ""
    while num_retries% > 0
        if (m.Http.AsyncGetToString())
            event = wait(timeout%, m.Http.GetPort())
            if type(event) = "roUrlEvent"
                str = event.GetString()
                exit while        
            elseif event = invalid
                m.Http.AsyncCancel()
                REM reset the connection on timeouts
                m.Http = CreateURLTransferObject(m.Http.GetUrl())
                timeout% = 2 * timeout%
            else
                print "roUrlTransfer::AsyncGetToString(): unknown event"
            endif
        endif

        num_retries% = num_retries% - 1
    end while
    
    return str
End Function

'******************************************************
'** perform AsyncGetToString with a timeout
'******************************************************
Function http_get_to_string_with_timeout(seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
    m.Http.EnableFreshConnection(true) 'Don't reuse existing connections
    if (m.Http.AsyncGetToString())
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            str = event.GetString()
        elseif event = invalid
            Dbg("AsyncGetToString timeout")
            m.Http.AsyncCancel()
        else
            Dbg("AsyncGetToString unknown event", event)
        endif
    endif

    return str
End Function

'******************************************************
'** perform AsyncPostWithString with a timeout
'******************************************************
Function http_post_from_string_with_timeout(val As String, seconds as Integer) as String
    timeout% = 1000 * seconds

    str = ""
    if (m.Http.AsyncPostFromString(val))
        event = wait(timeout%, m.Http.GetPort())
        if type(event) = "roUrlEvent"
			print "1"
			str = event.GetString()
        elseif event = invalid
			print "2"
            Dbg("AsyncPostFromString timeout")
            m.Http.AsyncCancel()
        else
			print "3"
            Dbg("AsyncPostFromString unknown event", event)
        endif
    endif

    return str
End Function
