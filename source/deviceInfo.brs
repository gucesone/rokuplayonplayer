'********************************************************************
'**  PlayOn Video Player Application - DeviceInfo
'**  August 2010
'**  Copyright (c) 2010  All Rights Reserved.
'********************************************************************
'**  Video Player Example Application - DeviceInfo 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************


'******************************************************
'Get our device version
'******************************************************
Function GetDeviceVersion()
    return CreateObject("roDeviceInfo").GetVersion()
End Function

'******************************************************
'Get our serial number
'******************************************************
Function GetDeviceESN()
    return CreateObject("roDeviceInfo").GetDeviceUniqueId()
End Function
