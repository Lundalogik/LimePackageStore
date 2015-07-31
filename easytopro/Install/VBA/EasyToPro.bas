Attribute VB_Name = "EasyToPro"
Option Explicit

Private Const cDOCUMENT_NOT_FOUND As String = "NO FILE DOCUMENT EXISTS"
Private Const cDOCUMENT_IMPORT_ERROR As String = "ERROR WHILE IMPORTING EXISTING FILE, Message: %1" ' %1 will be replaced by err.Description
Private Const cDOCUMENT_FILE_TO_LARGE As String = "FILE TO LARGE, MAX FILE SIZE IS %1 MB" ' %1 will be replaced by cDOCUMENT_MAX_FILE_SIZE
Private Const cDOCUMENT_MAX_FILE_SIZE As Long = 40

Private Const cMiddleObjectName As String = "projectincludecontact"

Public Const cEASYTABLES As String = ";ARCHIVE;CONTACT;DATA;FIELD;HISTORY;INCLUDE;PROJECT;REFS;STRING;TIME;TODO;USER;SETTINGS;"
Private Const cRowPage As Integer = 300

Private Const cTIMEOUT As Long = 299 ' MAXVALUE

Private Const cHistoryCharactersMaxValue As Long = 10000
Private Const cHistoryTopDefault As Long = 500 ' Used when cHistoryCharactersLarge is used, we get 500 history blobs when LEN(history) <= cHistoryCharactersLarge
Private Const cHistoryTopLarge As Long = 1 ' Used when cHistoryCharactersLarge is not supplied (NULL)


'Private Const cXMLFixedFieldsFile As String = "EasyFixedFields.xml"
Private Const cLOGNotFoundDocuments As String = "EasyToPro_Not_Imported_%1.log"

'Private Const cXMLFieldsFile As String = "EasyToPro.xml"
'Private Const cXMLOptionsFile As String = "EasyToPro_Options.xml"
Private m_save As Boolean

Private Const cConnectionString As String = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=%1;Persist Security Info=False" ' %1 will be replaced by supplied path

Private Const cARCHIVE As String = ";Type;Key 1;Key 2;Path;Date;Time;Comment;User ID;Reference;"
Private Const cCONTACT As String = ";Company ID;Company name;Suffix;Address;Telephone;Fax;Created date;Created time;Created user ID;Updated date;Updated time;Updated user ID;"
Private Const cDATA As String = ";Field ID;Key 1;Key 2;Key 3;Data;"
Private Const cFIELD As String = ";Field ID;Field name;Field type;Order;Symbol;Field width;Data type;Data type data;"
Private Const cHISTORY As String = ";Type;Key 1;Key 2;History;"
Private Const cINCLUDE As String = ";Project ID;Company ID;"
Private Const cPROJECT As String = ";Project ID;Name;Description;Flags;Created date;Created time;Created user ID;Updated date;Updated time;Updated user ID;"
Private Const cREFS As String = ";Company ID;Reference ID;Name;Flags;Created date;Created time;Created user ID;Updated date;Updated time;Updated user ID;"
Private Const cSTRING As String = ";String ID;String;"
Private Const cTIME As String = ";Company ID;Time ID;Date;Minutes;Done;Flags;Description;User ID;Type;Tax;Actual minutes;Project;Amount;"
Private Const cTODO As String = ";Type;Key 1;Key 2;Description;Priority;Start date;Start time;Stop date;Stop time;User ID;Done date;Done time;Done user ID;Timestamp date;Timestamp time;"
Private Const cUSER As String = ";User ID;Name;Active;Signature;"
Private Const cSETTINGS As String = ";Item;Value;"

Private Const cWARNINGS As String = ";duplicatefieldname;duplicateeasyfieldid;invalidcharactersfieldname;invalidcharacterslocalname;validatesystemfields;proposedvalueforrequired;validate_sv;validate_en_us;validate_no;validate_fi;validate_da;validatefieldtype;validatefieldlength;"
' USED TO KNOW WHICH FIELDS ARE DATEFIELDS (NEEDS TO BE HANDLED SINCE IN LIME EASY THEY WILL BE LOADED AS THE FORMAT ON THE COMPUTER)
Private Const cDATEFIELDS As String = ";Date;Created date;Updated date;Start date;Stop date;Done date;Timestamp date;"

Public Sub ShowMigrationForm()
    On Error GoTo Errorhandler
    Dim oFormEasyToPro As New FormEasyToPro
    
    Call oFormEasyToPro.show
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.ShowMigrationForm")
End Sub


' FUNCTION TO CHANGE DATEFORMAT TO yyyy-mm-dd AS IN LIME PRO
Private Function GetProDateFormat(sDate As String) As String
    On Error GoTo Errorhandler

    GetProDateFormat = Lime.FormatString("%1-%2-%3", VBA.Year(sDate), VBA.Right("0" & VBA.CStr(VBA.Month(sDate)), 2), VBA.Right("0" & VBA.CStr(VBA.Day(sDate)), 2))

    Exit Function
Errorhandler:
    GetProDateFormat = ""
    Call UI.ShowError("EasyToPro.GetProDateFormat")
End Function


Public Sub SaveChanges(bSave As Boolean)
    m_save = bSave
End Sub

Public Function ValidateTableName(sTableName As String, Optional bVerboseError As Boolean = True) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_validatetable", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@tablename").InputValue = sTableName
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@message").OutputValue) = False Then
            sMessage = proc.Parameters("@@message").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
        If VBA.IsNull(proc.Parameters("@@validationerror").OutputValue) = False Then
            If proc.Parameters("@@validationerror").OutputValue = 0 Then
                bOk = True
            Else
                bOk = False
            End If
        Else
            bOk = False
            If VBA.Len(sMessage) = 0 Then
                sMessage = "UNKNOWN RESULT"
            End If
        End If
    Else
        sMessage = "The procedure csp_easytopro_validatetable is missing"
        bOk = False
    End If
    
    
    Application.MousePointer = 0
    
    If ((bOk = False) And (bVerboseError = True)) Then
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    End If
        
      
    
    ValidateTableName = bOk

    Exit Function
Errorhandler:
    ValidateTableName = False
    Call UI.ShowError("EasyToPro.ValidateTableName")
End Function

' *******************' UPDATED TO HANDLE EXPORTED HISTORY FILES *****************************
Public Function PrepareHistory(ByRef oLabel As Object, sHistoryCompanyPath As String, sHistoryProjectPath) As Boolean
    On Error GoTo Errorhandler
    Dim bOk As Boolean
    
    Application.MousePointer = 11
    bOk = True
    
    bOk = RebuildSplittedHistory
    
    ' SPLIT SMALL HISTORY BLOBS
    If bOk Then
        bOk = AddSplittedHistory(oLabel, sHistoryCompanyPath, 0)
    End If
    ' SPLIT LARGE HISTORY BLOBS
    If bOk = True Then
        bOk = AddSplittedHistory(oLabel, sHistoryProjectPath, 2)
    End If
    
    PrepareHistory = bOk
    Application.MousePointer = 0
    
    Exit Function
Errorhandler:
    PrepareHistory = False
    oLabel.Caption = ""
    Call UI.ShowError("EasyToPro.PrepareHistory")
End Function

'Public Function PrepareHistory(ByRef oLabel As Object) As Boolean
'    On Error GoTo ErrorHandler
'    Dim bOk As Boolean
'
'    Application.MousePointer = 11
'    bOk = True
'
'    ' SPLIT SMALL HISTORY BLOBS
'
'    bOk = SplitHistory(oLabel, "%1/%2 history blobs shorter or equal to %3 characters splitted... elapsed time in (seconds): %4", True, False, cHistoryTopDefault)
'
'    ' SPLIT LARGE HISTORY BLOBS
'    If bOk = True Then
'        bOk = SplitHistory(oLabel, "%1/%2 history blobs longer than %3 characters splitted... elapsed time in (seconds): %4", False, True, cHistoryTopLarge)
'    End If
'
'    PrepareHistory = bOk
'    Application.MousePointer = 0
'
'    Exit Function
'ErrorHandler:
'    PrepareHistory = False
'    oLabel.Caption = ""
'    Call UI.ShowError("EasyToPro.PrepareHistory")
'End Function


Private Function SplitHistory(ByRef oLabel As Object, sLabelTemplate As String, bRebuild As Boolean, bLargeHistory As Boolean, lngTop As Long) As Boolean
    On Error GoTo Errorhandler
    Dim oHistoryNode As IXMLDOMNode
    Dim oDataNode As IXMLDOMNode
   
    Dim oProc As LDE.Procedure
    Dim oProc2 As LDE.Procedure
    Dim oHistoryXML As MSXML2.DOMDocument60
    
    Dim iRebuild As Integer
    Dim bOk As Boolean
    Dim sMessage As String
    Dim bHasRowsToCatch As Boolean
    Dim lngCreated As Long
    Dim lngTotal As Long
    Dim lngRemaining As Long
    Dim sStartdate As String
    
    sStartdate = VBA.CStr(VBA.Now())
    
    lngTotal = 0
    lngRemaining = 0
    
    bOk = True
    bHasRowsToCatch = True
    Application.MousePointer = 11
    
    If bRebuild = True Then
        iRebuild = 1
    Else
        iRebuild = 0
    End If
    
    Set oProc = Database.Procedures.Lookup("csp_easytopro_gethistoryxml", lkLookupProcedureByName)
    Set oProc2 = Database.Procedures.Lookup("csp_easytopro_splithistory", lkLookupProcedureByName)
    
    If oProc Is Nothing Then
        SplitHistory = False
        Exit Function
        Call Lime.MessageBox("The procedure csp_easytopro_gethistoryxml is missing")
    End If
    
    If oProc2 Is Nothing Then
        SplitHistory = False
        Exit Function
        Call Lime.MessageBox("The procedure csp_easytopro_gethistoryxml is missing")
    End If
    
    While (bHasRowsToCatch And bOk)
        
        If bLargeHistory = False Then
            oProc.Parameters("@@maxnotelength").InputValue = cHistoryCharactersMaxValue
        End If
        
        oProc.Timeout = cTIMEOUT
        
        oProc.Execute (False)
       
        Set oHistoryXML = New MSXML2.DOMDocument60
        oHistoryXML.LoadXML (oProc.result)
        If Not oHistoryXML Is Nothing Then
            Set oDataNode = oHistoryXML.selectSingleNode("/data/info")
            If Not oDataNode Is Nothing Then
                lngRemaining = VBA.CLng(oDataNode.Attributes.getNamedItem("remaining").Text)
                
                ' SET TOTAL
                If lngTotal = 0 Then
                    lngTotal = lngRemaining
                End If
                
                If lngRemaining > 0 Then
                    oProc2.Parameters("@@top").InputValue = lngTop
                    
                    If bLargeHistory = False Then
                        oProc2.Parameters("@@maxnotelength").InputValue = cHistoryCharactersMaxValue
                    End If
                    
                    oProc2.Parameters("@@rebuildtable").InputValue = iRebuild
                    
                    oProc2.Timeout = cTIMEOUT
                    
                    oProc2.Execute (False)
                    iRebuild = 0
                    
                    If VBA.IsNull(oProc2.Parameters("@@errormessage").OutputValue) = False Then
                        sMessage = oProc2.Parameters("@@errormessage").OutputValue
                    Else
                        sMessage = "UNKNOWN RESULT"
                    End If
                    iRebuild = 0
                    lngCreated = lngCreated + lngTop
                    oLabel.Caption = Lime.FormatString(sLabelTemplate, lngCreated, lngTotal, cHistoryCharactersMaxValue, VBA.DateDiff("s", sStartdate, VBA.Now()))
                    If VBA.Len(sMessage) > 0 Then
                        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
                        bOk = False
                    End If
                Else
                    bHasRowsToCatch = False
                End If
            Else
                Call Lime.MessageBox("Couldn't load oDataNode", VBA.vbExclamation)
                bOk = False
            End If
                
        Else
            Call Lime.MessageBox("Couldn't load oHistoryXML", VBA.vbExclamation)
            bOk = False
        End If
    Wend
    
    SplitHistory = bOk
    Application.MousePointer = 0
    Exit Function
Errorhandler:
    SplitHistory = False
    oLabel.Caption = ""
    Call UI.ShowError("EasyToPro.SplitHistory")
End Function

Public Function ValidateAll() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim oValidationNode As IXMLDOMNode
    Dim oNode As IXMLDOMNode
    Dim oValidationXML As MSXML2.DOMDocument60
    
    Dim bValidateAll As Boolean
    
    Application.MousePointer = 11
    
    bValidateAll = ValidationRequiredFields(Nothing, "")
    
    If bValidateAll = True Then
        Set oValidationXML = GetValidationXML(0)

        If Not oValidationXML Is Nothing Then
            Set oValidationNode = oValidationXML.selectSingleNode("/data")
            If Not oValidationNode Is Nothing Then
                If oValidationNode.hasChildNodes Then
                    
                    Application.MousePointer = 0
                    For Each oNode In oValidationNode.childNodes
                        If ValidationNodeContainsError(oNode, True) = True Then
                            bValidateAll = False
                            Exit For
                        End If
                    Next oNode
                End If
            End If
        End If
    End If
                
    If bValidateAll = True Then
        Dim oOptionProc As LDE.Procedure

        Set oOptionProc = Database.Procedures.Lookup("csp_easytopro_validate_option", lkLookupProcedureByName)
        If Not oOptionProc Is Nothing Then
        
            oOptionProc.Timeout = cTIMEOUT
            
            oOptionProc.Execute (False)
        
            Set oValidationXML = New MSXML2.DOMDocument60
            oValidationXML.LoadXML (oOptionProc.result)
            If Not oValidationXML Is Nothing Then
                Set oValidationNode = oValidationXML.selectSingleNode("/data")
                If Not oValidationNode Is Nothing Then
                    If oValidationNode.hasChildNodes Then
                        bValidateAll = False
                        Application.MousePointer = 0
                        For Each oNode In oValidationNode.childNodes
                            Call Lime.MessageBox(oNode.Attributes.getNamedItem("validationmessage").Text, VBA.vbExclamation)
                        Next oNode
                    End If
                End If
            End If
                    
        Else
            Application.MousePointer = 0
            Call Lime.MessageBox("The required procedure csp_easytopro_validate_option is missing", VBA.vbExclamation)
            bValidateAll = False
        End If
    End If
    
    ValidateAll = bValidateAll
    Application.MousePointer = 0
    
    
    Exit Function
Errorhandler:
    ValidateAll = False
    Call UI.ShowError("EasyToPro.ValidateAll")
End Function

Public Function TruncateTablesBeforeGO() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_truncatetransfertables", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@linkprojecttocompanytable").InputValue = cMiddleObjectName
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_truncatetransfertables is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    TruncateTablesBeforeGO = bOk

    Exit Function
Errorhandler:
    TruncateTablesBeforeGO = False
    Call UI.ShowError("EasyToPro.TruncateTablesBeforeGO")
End Function

Public Function RunSQLOnUpdate() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_runsqlonupdate", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_runsqlonupdate is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    RunSQLOnUpdate = bOk

    Exit Function
Errorhandler:
    RunSQLOnUpdate = False
    Call UI.ShowError("EasyToPro.RunSQLOnUpdate")
End Function

Public Function EndMigration() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_endmigration", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_endmigration is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    EndMigration = bOk

    Exit Function
Errorhandler:
    EndMigration = False
    Call UI.ShowError("EasyToPro.EndMigration")
End Function

Public Function CreateTablesIfNeeded() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bCreateTablesIfNeeded As Boolean

    Application.MousePointer = 11
    
    bCreateTablesIfNeeded = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_createtransfertables", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_createtransfertables is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bCreateTablesIfNeeded = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bCreateTablesIfNeeded = True
    End If
        
       
    
    CreateTablesIfNeeded = bCreateTablesIfNeeded

    Exit Function
Errorhandler:
    CreateTablesIfNeeded = False
    Call UI.ShowError("EasyToPro.CreateTablesIfNeeded")
End Function

Public Function CreateMigrationFields(sParameter As String, sProTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_createmigrationfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters(sParameter).InputValue = sProTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_createmigrationfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    CreateMigrationFields = bOk

    Exit Function
Errorhandler:
    CreateMigrationFields = False
    Call UI.ShowError("EasyToPro.CreateMigrationFields")
End Function

Public Function UpdateTimestamp(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_fixtimestamps", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_fixtimestamps is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    UpdateTimestamp = bOk

    Exit Function
Errorhandler:
    UpdateTimestamp = False
    Call UI.ShowError("EasyToPro.UpdateTimestamp")
End Function

Public Function CreateFixedFields(sEasyTable As String, sLanguage As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_addfixedfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        proc.Parameters("@@lang").InputValue = sLanguage
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_addfixedfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    CreateFixedFields = bOk

    Exit Function
Errorhandler:
    CreateFixedFields = False
    Call UI.ShowError("EasyToPro.CreateFixedFields")
End Function

Public Function ImportEasyHistory() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_inserteasyhistory", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_inserteasyhistory is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    ImportEasyHistory = bOk

    Exit Function
Errorhandler:
    ImportEasyHistory = False
    Call UI.ShowError("EasyToPro.ImportEasyHistory")
End Function

Public Function CreateSuperFields(sEasyTable As String, sLanguage As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_addsuperfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        proc.Parameters("@@lang").InputValue = sLanguage
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_addsuperfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    CreateSuperFields = bOk

    Exit Function
Errorhandler:
    CreateSuperFields = False
    Call UI.ShowError("EasyToPro.CreateSuperFields")
End Function

Public Function CreateFixedRelations(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_addfixedrelationfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_addfixedrelationfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    CreateFixedRelations = bOk

    Exit Function
Errorhandler:
    CreateFixedRelations = False
    Call UI.ShowError("EasyToPro.CreateFixedRelations")
End Function

Public Function ImportDataToFixedFields(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_createandinsertfixedfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_createandinsertfixedfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    ImportDataToFixedFields = bOk

    Exit Function
Errorhandler:
    ImportDataToFixedFields = False
    Call UI.ShowError("EasyToPro.ImportDataToFixedFields")
End Function

Public Function MergeUserTable(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_mergeuser", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_mergeuser is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    MergeUserTable = bOk

    Exit Function
Errorhandler:
    MergeUserTable = False
    Call UI.ShowError("EasyToPro.MergeUserTable")
End Function

Public Function ConnectFixedRelationFields(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_updatefixedrelationfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_updatefixedrelationfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
       
    
    ConnectFixedRelationFields = bOk

    Exit Function
Errorhandler:
    ConnectFixedRelationFields = False
    Call UI.ShowError("EasyToPro.ConnectFixedRelationFields")
End Function

Public Function ImportSuperFieldData(sEasyTable As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bOk As Boolean

    Application.MousePointer = 11
    
    bOk = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_updatesuperfields", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_updatesuperfields is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
        
    ImportSuperFieldData = bOk

    Exit Function
Errorhandler:
    ImportSuperFieldData = False
    Call UI.ShowError("EasyToPro.ImportSuperFieldData")
End Function

Public Function LinkProjectContact() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bLinkProjectContact As Boolean

    Application.MousePointer = 11
    
    bLinkProjectContact = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_link_project_contact", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@tablenamemiddleobject").InputValue = cMiddleObjectName
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_link_project_contact is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bLinkProjectContact = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bLinkProjectContact = True
    End If
        
       
    
    LinkProjectContact = bLinkProjectContact

    Exit Function
Errorhandler:
    LinkProjectContact = False
    Call UI.ShowError("EasyToPro.LinkProjectContact")
End Function

Public Function SaveFieldChangesEasyFieldMapping(lngIDFieldMapping As Long, bActive As Boolean, sProFieldName As String, sSV As String, sEN_US As String, sNO As String, sFI As String, sDA As String, sProposedValue As String) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bSaveFieldChangesEasyFieldMapping As Boolean

    Application.MousePointer = 11
    
    bSaveFieldChangesEasyFieldMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_update_easy__fieldmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@idfieldmapping").InputValue = lngIDFieldMapping
        proc.Parameters("@@active").InputValue = IIf(bActive = True, 1, 0)
        proc.Parameters("@@profieldname").InputValue = sProFieldName
        proc.Parameters("@@localname_sv").InputValue = sSV
        proc.Parameters("@@localname_en_us").InputValue = sEN_US
        proc.Parameters("@@localname_no").InputValue = sNO
        proc.Parameters("@@localname_fi").InputValue = sFI
        proc.Parameters("@@localname_da").InputValue = sDA
        proc.Parameters("@@proposedvalue").InputValue = sProposedValue
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_update_easy__fieldmapping is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bSaveFieldChangesEasyFieldMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bSaveFieldChangesEasyFieldMapping = True
    End If
        
       
    
    SaveFieldChangesEasyFieldMapping = bSaveFieldChangesEasyFieldMapping

    Exit Function
Errorhandler:
    SaveFieldChangesEasyFieldMapping = False
    Call UI.ShowError("EasyToPro.SaveFieldChangesEasyFieldMapping")
End Function


Public Function AddDocumentFile(sLimeProDocumentTable As String, sDocumentField As String, sDocumentFolder As String, oLabel As MSForms.label, Optional bWriteLog As Boolean = False) As Boolean
    On Error GoTo Errorhandler
    Dim oFileNode As IXMLDOMNode
    Dim oDataNode As IXMLDOMNode
    Dim sPath As String
    Dim sFileExtension As String
    Dim lngType As Long
    Dim lngKey1 As Long
    Dim lngKey2 As Long
    Dim lngRecord As Long
    Dim oProc As LDE.Procedure
    Dim oFileXML As MSXML2.DOMDocument60
    Dim sFullPath As String
    Dim iFreeFile As Integer
    Dim sLogRow As String
    Dim bLogError As Boolean
    Dim lngTotal As Long
    Dim lngImported As Long
    Dim lngFailed As Long
    Dim sMessage As String
    Dim bOk As Boolean
    
    
    Application.MousePointer = 11
    
    bOk = False
    
    iFreeFile = 0
    If bWriteLog = True Then
        iFreeFile = VBA.FreeFile
        Open LCO.MakeFileName(Application.WebFolder, Lime.FormatString(cLOGNotFoundDocuments, Format(VBA.Date(), "yyyy_mm_dd"))) For Output As #iFreeFile
        sLogRow = Lime.FormatString("%2%1%3%1%4%1%5%1Fail Reason", VBA.vbTab, "Type", "Key 1", "Key 2", "FullPath")
        Print #iFreeFile, sLogRow
        
    End If
                
    Set oProc = Database.Procedures.Lookup("csp_easytopro_getdocumentxml", lkLookupProcedureByName)
    If Not oProc Is Nothing Then
        oProc.Parameters("@@limedocumenttable").InputValue = sLimeProDocumentTable
        
        oProc.Timeout = cTIMEOUT
        
        oProc.Execute (False)
        
        Set oFileXML = New MSXML2.DOMDocument60
        oFileXML.LoadXML (oProc.result)
        If Not oFileXML Is Nothing Then
            Set oDataNode = oFileXML.selectSingleNode("/data")
            If Not oDataNode Is Nothing Then
            
                bOk = True
            
                If oDataNode.hasChildNodes Then
                    lngTotal = oDataNode.childNodes.Length
                    lngImported = 0
                    lngFailed = 0
         
                    For Each oFileNode In oDataNode.childNodes
                        
                        bLogError = False
                        
                        sPath = oFileNode.Attributes.getNamedItem("path").Text
                        lngType = VBA.CLng(oFileNode.Attributes.getNamedItem("type").Text)
                        lngKey1 = VBA.CLng(oFileNode.Attributes.getNamedItem("key1").Text)
                        lngKey2 = VBA.CLng(oFileNode.Attributes.getNamedItem("key2").Text)
                        lngRecord = IIf(IsNull(oFileNode.Attributes.getNamedItem("idrecord").Text), 0, VBA.CLng(oFileNode.Attributes.getNamedItem("idrecord").Text))
                        
                        sFullPath = LCO.MakeFileName(sDocumentFolder, sPath)
                        sMessage = ""
                        If lngRecord > 0 Then
                            If ImportDocument(sLimeProDocumentTable, sDocumentField, sFullPath, lngRecord, sMessage) = False Then
                                
                                If bWriteLog = True Then
                                    sLogRow = Lime.FormatString("%2%1%3%1%4%1%5", VBA.vbTab, lngType, lngKey1, lngKey2, sFullPath)
                                    sLogRow = Lime.FormatString("%2%1%3", VBA.vbTab, sLogRow, sMessage)
                                    Print #iFreeFile, sLogRow
                                End If
                                lngFailed = lngFailed + 1
                            Else
                                lngImported = lngImported + 1
                            End If
                        Else
                            If bWriteLog = True Then
                                sLogRow = Lime.FormatString("%2%1%3%1%4%1%5%1NO RECORD FOUND IN LIME PRO", VBA.vbTab, lngType, lngKey1, lngKey2, sFullPath)
                                Print #iFreeFile, sLogRow
                            End If
                            lngFailed = lngFailed + 1
                        End If
                                               
                         oLabel.Caption = Lime.FormatString("%1/%2 documents handled, Imported: %3, Failed: %4", lngImported + lngFailed, lngTotal, lngImported, lngFailed)
                    Next oFileNode
                Else
                    Application.MousePointer = 0
                    Call Lime.MessageBox("There are no documents to import", VBA.vbInformation)
                End If
            End If
        End If
    Else
        Call Lime.MessageBox("The procedure csp_easytopro_getdocumentxml is missing")
    End If
    If bWriteLog = True Then
        Close #iFreeFile
    End If
    AddDocumentFile = bOk
    oLabel.Caption = ""
    Application.MousePointer = 0
    Exit Function
Errorhandler:
    AddDocumentFile = False
    oLabel.Caption = ""
    If bWriteLog = True Then
        Close #iFreeFile
    End If
    Call UI.ShowError("EasyToPro.AddDocumentFile")
End Function

Private Function ImportDocument(sDocumentTable As String, sDocumentField As String, sFileName As String, lngIdRecord As Long, ByRef sMessage As String) As Boolean
    On Error GoTo Errorhandler
    Dim oDocument As New LDE.document
    Dim oRecord As New LDE.record
    Dim oView As New LDE.view
    Dim bOk As Boolean
    
    bOk = False
    
    If LCO.FileExists(sFileName) Then
    
        Call oView.Add(sDocumentField)
        Call oRecord.Open(Application.Database.Classes(sDocumentTable), lngIdRecord, oView)
        
        oDocument.Load (sFileName)
        
        If (oDocument.size < (cDOCUMENT_MAX_FILE_SIZE * 1024 * 1024)) Then
            oRecord.Value(sDocumentField) = oDocument
            
            oRecord.Update
            bOk = True
            sMessage = ""
        Else
            bOk = False
            sMessage = Lime.FormatString(cDOCUMENT_FILE_TO_LARGE, cDOCUMENT_MAX_FILE_SIZE)
        End If
    Else
        bOk = False
        sMessage = cDOCUMENT_NOT_FOUND
    End If
    ImportDocument = bOk
    
    Exit Function
Errorhandler:
    ImportDocument = False
    sMessage = Lime.FormatString(cDOCUMENT_IMPORT_ERROR, Err.Description)
    Call UI.ShowError("EasyToPro.ImportDocument")
End Function

Public Function CheckRequiredTables(bVerbose As Boolean) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bCheckRequiredTables As Boolean

    Application.MousePointer = 11
    
    bCheckRequiredTables = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_checkrequiredtables", lkLookupProcedureByName)
    If Not proc Is Nothing Then
       
       proc.Timeout = cTIMEOUT
       
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_checkrequiredtables is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bCheckRequiredTables = False
        If bVerbose = True Then
            Call Lime.MessageBox(sMessage, VBA.vbExclamation)
        End If
    Else
        bCheckRequiredTables = True
    End If
        
       
    
    CheckRequiredTables = bCheckRequiredTables

    Exit Function
Errorhandler:
    CheckRequiredTables = False
    Call UI.ShowError("EasyToPro.CheckRequiredTables")

End Function

Public Function UpdateOptionMapping(lngIdOptionMapping As Long, lngFieldMapping As Long, lngIdString As Long) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bUpdateOptionMapping As Boolean

    Application.MousePointer = 11
    
    bUpdateOptionMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_update_easy__optionmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@idoptionmapping").InputValue = lngIdOptionMapping
        proc.Parameters("@@fieldmapping").InputValue = lngFieldMapping
        proc.Parameters("@@idstringlimepro").InputValue = lngIdString
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_update_easy__optionmapping is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bUpdateOptionMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bUpdateOptionMapping = True
    End If
        
       
    
    UpdateOptionMapping = bUpdateOptionMapping

    Exit Function
Errorhandler:
    UpdateOptionMapping = False
    Call UI.ShowError("EasyToPro.UpdateOptionMapping")

End Function

Public Function ResetOptionMapping(lngFieldMapping As Long) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bResetOptionMapping As Boolean

    Application.MousePointer = 11
    
    bResetOptionMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_update_easy__optionmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@fieldmapping").InputValue = lngFieldMapping
       
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_update_easy__optionmapping is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bResetOptionMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bResetOptionMapping = True
    End If
        
       
    
    ResetOptionMapping = bResetOptionMapping

    Exit Function
Errorhandler:
    ResetOptionMapping = False
    Call UI.ShowError("EasyToPro.ResetOptionMapping")

End Function

Public Sub ProFieldExistsRequired(ByRef bExists As Boolean, ByRef bRequired As Boolean, sProTable As String, sProField As String)
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bProFieldExists As Boolean

    
    bExists = False
    bRequired = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_fieldexist", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@tablename").InputValue = sProTable
        proc.Parameters("@@fieldname").InputValue = sProField
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@exists").OutputValue) = False Then
            If (1 = proc.Parameters("@@exists").OutputValue) Then
                bExists = True
            Else
                bExists = False
            End If
        End If
        
        If VBA.IsNull(proc.Parameters("@@required").OutputValue) = False Then
            If (1 = proc.Parameters("@@required").OutputValue) Then
                bRequired = True
            Else
                bRequired = False
            End If
        End If
    Else
        sMessage = "The procedure csp_easytopro_fieldexist is missing"
    End If

    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.ProFieldExists")
End Sub

Public Function SaveTableChangesEasyFieldMapping(sEasyTable As String, sProTableName As String, bTransferTable As Boolean) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bSaveTableChangesEasyFieldMapping As Boolean

    Application.MousePointer = 11
    
    bSaveTableChangesEasyFieldMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_update_easy__fieldmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        proc.Parameters("@@easytable").InputValue = sEasyTable
        proc.Parameters("@@protable").InputValue = sProTableName
        proc.Parameters("@@transfertable").InputValue = IIf(bTransferTable = True, 1, 0)
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_update_easy__fieldmapping is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bSaveTableChangesEasyFieldMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bSaveTableChangesEasyFieldMapping = True
    End If
        
       
    
    SaveTableChangesEasyFieldMapping = bSaveTableChangesEasyFieldMapping

    Exit Function
Errorhandler:
    SaveTableChangesEasyFieldMapping = False
    Call UI.ShowError("EasyToPro.SaveTableChangesEasyFieldMapping")

End Function

Private Function GetValidationXML(Optional lngIDFieldMapping As Long = 0) As MSXML2.DOMDocument60
    On Error GoTo Errorhandler
    Dim oValidationXML As MSXML2.DOMDocument60
    Dim oValidationProc As LDE.Procedure

    Set oValidationProc = Database.Procedures.Lookup("csp_easytopro_validate_field", lkLookupProcedureByName)
    If Not oValidationProc Is Nothing Then
        If lngIDFieldMapping > 0 Then
            oValidationProc.Parameters("@@idfieldmapping").InputValue = lngIDFieldMapping
        End If
        
        oValidationProc.Timeout = cTIMEOUT
        
        oValidationProc.Execute (False)
        
        Set oValidationXML = New MSXML2.DOMDocument60
        oValidationXML.LoadXML (oValidationProc.result)
    Else
        Call Lime.MessageBox("The required procedure csp_easytopro_validate_field is missing", VBA.vbExclamation)
        Set oValidationXML = Nothing
    End If
                
    Set GetValidationXML = oValidationXML
                
    Exit Function
Errorhandler:
    Call UI.ShowError("EasyToPro.GetValidationXML")
    Set GetValidationXML = Nothing
End Function


Public Sub ListValidationError(lngIDFieldMapping As Long, lv As Object)
    On Error GoTo Errorhandler

    Dim oListItem As MSComctlLib.ListItem
    Dim sMessage As String
    Dim oValidationNode As IXMLDOMNode
    Dim v As Variant
    Dim i As Long
    Dim oValidationXML As MSXML2.DOMDocument60
    
    Application.MousePointer = 11
    
    Call lv.ListItems.Clear
    
    
    Set oValidationXML = GetValidationXML(lngIDFieldMapping)
    
    If Not oValidationXML Is Nothing Then
        Set oValidationNode = oValidationXML.selectSingleNode("/data/warning[@idfieldmapping='" & VBA.CStr(lngIDFieldMapping) & "']")
        If Not oValidationNode Is Nothing Then
            v = VBA.Split(cWARNINGS, ";")
            For i = LBound(v) To UBound(v)
                If VBA.Len(v(i)) > 0 Then
                    sMessage = oValidationNode.Attributes.getNamedItem(v(i)).Text
                    If VBA.Len(sMessage) > 0 Then
                        Set oListItem = lv.ListItems.Add
                        oListItem.Text = sMessage
                    End If
                End If
            Next i
        End If
    End If

    Application.MousePointer = 0
    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.ListValidationError")
End Sub

Public Function ValidationRequiredFields(Optional lv As Object = Nothing, Optional sEasyTable As String = "") As Boolean
    On Error GoTo Errorhandler
    Dim oValidationXML As MSXML2.DOMDocument60
    Dim oValidationProc As LDE.Procedure
    Dim oDataNode As IXMLDOMNode
    Dim oErrorNode As IXMLDOMNode
    Dim oListItem As MSComctlLib.ListItem
    Dim sMessage As String
    Dim bValidationRequiredFields As Boolean
    
    Application.MousePointer = 11
    
    bValidationRequiredFields = True
    If Not lv Is Nothing Then
        lv.ListItems.Clear
    End If
    Set oValidationProc = Database.Procedures.Lookup("csp_easytopro_validate_requiredfields", lkLookupProcedureByName)
    If Not oValidationProc Is Nothing Then
        If VBA.Len(sEasyTable) > 0 Then
            oValidationProc.Parameters("@@easytable").InputValue = sEasyTable
        End If
        
        oValidationProc.Timeout = cTIMEOUT
        
        oValidationProc.Execute (False)
        
        Set oValidationXML = New MSXML2.DOMDocument60
        oValidationXML.LoadXML (oValidationProc.result)
    
        Set oDataNode = oValidationXML.selectSingleNode("/data")
        If Not oDataNode Is Nothing Then
            If oDataNode.hasChildNodes Then
                For Each oErrorNode In oDataNode.childNodes
                    sMessage = Lime.FormatString("Field '%1' in table '%2' is required but is not mapped or is missing a proposed value", oErrorNode.Attributes.getNamedItem("fieldname").Text, oErrorNode.Attributes.getNamedItem("tablename").Text)
                    If VBA.Len(sMessage) > 0 Then
                        If Not lv Is Nothing Then
                            Set oListItem = lv.ListItems.Add
                            oListItem.Text = sMessage
                        Else
                            Call Lime.MessageBox(sMessage, VBA.vbExclamation)
                        End If
                    End If
                    bValidationRequiredFields = False
                Next oErrorNode
            End If
        End If
     Else
        bValidationRequiredFields = False
        Application.MousePointer = 0
        Call Lime.MessageBox("The required procedure csp_easytopro_validate_requiredfields is missing", VBA.vbExclamation)
    End If
    Application.MousePointer = 0
    ValidationRequiredFields = bValidationRequiredFields
    
    Exit Function
Errorhandler:
    ValidationRequiredFields = False
    Call UI.ShowError("EasyToPro.ValidationRequiredFields")
End Function

Public Sub LoadEasyOptions(lngFieldMapping As Long, lv As Object)
    On Error GoTo Errorhandler
    Dim oOptionNode As IXMLDOMNode
    Dim oDataNode As IXMLDOMNode
    Dim oListItem As MSComctlLib.ListItem
    Dim oOption As LDE.Option
    Dim oOptionProc As LDE.Procedure
    Dim oOptionXML As MSXML2.DOMDocument60
    Dim sIdString As String
    Dim sProTable As String
    Dim sProField As String
    Dim sOptionText As String
    Dim bExistingField As Boolean
    Application.MousePointer = 11
    
    Call lv.ListItems.Clear
   bExistingField = False
    
    Set oOptionProc = Database.Procedures.Lookup("csp_easytopro_getoptionmappingxml", lkLookupProcedureByName)
    If Not oOptionProc Is Nothing Then
        oOptionProc.Parameters("@@fieldmapping").InputValue = lngFieldMapping
        
        oOptionProc.Timeout = cTIMEOUT
        
        oOptionProc.Execute (False)
        
        Set oOptionXML = New MSXML2.DOMDocument60
        oOptionXML.LoadXML (oOptionProc.result)
        If Not oOptionXML Is Nothing Then
            Set oDataNode = oOptionXML.selectSingleNode("/data")
            If Not oDataNode Is Nothing Then
                If oDataNode.hasChildNodes Then
                    For Each oOptionNode In oDataNode.childNodes
                
                        Set oListItem = lv.ListItems.Add
                        oListItem.Text = oOptionNode.Attributes.getNamedItem("idoptionmapping").Text ' idoptionmapping
                        oListItem.SubItems(1) = oOptionNode.Attributes.getNamedItem("easyvalue").Text ' easyvalue
                
                        sIdString = oOptionNode.Attributes.getNamedItem("idstringlimepro").Text ' idstringlimepro
                        oListItem.SubItems(2) = sIdString ' idstringlimepro
                        sProTable = oOptionNode.Attributes.getNamedItem("protable").Text
                        sProField = oOptionNode.Attributes.getNamedItem("profieldname").Text
                        If Application.Database.Classes.Exists(sProTable) Then
                            If Application.Database.Classes(sProTable).Fields.Exists(sProField) Then
                                bExistingField = True
                            End If
                        End If
                        If VBA.CLng(sIdString) > 0 Then
                            sOptionText = "RESTART_LIME_TO_SEE_TEXT"
                            
                            If bExistingField = True Then
                                Set oOption = Application.Database.Classes(sProTable).Fields(sProField).options.Lookup(VBA.CLng(sIdString), lkLookupOptionByValue)
                                
                                If Not oOption Is Nothing Then
                                    sOptionText = oOption.Text
                                End If
                            End If
                        ElseIf VBA.CLng(sIdString) < 0 Then
                            sOptionText = "NOT_MAPPED"
                        End If
                        oListItem.SubItems(3) = sOptionText
                        oListItem.SubItems(4) = sProTable
                        oListItem.SubItems(5) = sProField
                        oListItem.Tag = oOptionNode.Attributes.getNamedItem("idoptionmapping").Text ' idoptionmapping
                    Next oOptionNode
                End If
            End If
        End If
    Else
        Application.MousePointer = 0
        Call Lime.MessageBox("The required procedure csp_easytopro_getoptionmappingxml is missing", VBA.vbExclamation)
    End If
    
    If bExistingField = False Then
        lv.ListItems.Clear
        Call ResetOptionMapping(lngFieldMapping)
    End If
    Application.MousePointer = 0

    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.LoadEasyOptions")
End Sub

Public Sub LoadTableData(sTable As String, ByRef sProTable As String, ByRef bTransferTable As Boolean)
    On Error GoTo Errorhandler
    Dim oFieldNode As IXMLDOMNode
    Dim oFieldProc As LDE.Procedure
    Dim oFieldXML As MSXML2.DOMDocument60
    
    Dim sTableName As String
    Dim bChecked As Boolean
    
    sTableName = ""
    bChecked = False
 
    Application.MousePointer = 11
    
   
    
    Set oFieldProc = Database.Procedures.Lookup("csp_easytopro_getfieldmappingxml", lkLookupProcedureByName)
    If Not oFieldProc Is Nothing Then
        oFieldProc.Parameters("@@easytable").InputValue = sTable
        
        oFieldProc.Timeout = cTIMEOUT
        
        oFieldProc.Execute (False)
        
        Set oFieldXML = New MSXML2.DOMDocument60
        oFieldXML.LoadXML (oFieldProc.result)
        Set oFieldNode = oFieldXML.selectSingleNode("/data/fieldmapping[@easytable='" & sTable & "']")
        If Not oFieldNode Is Nothing Then
            sTableName = oFieldNode.Attributes.getNamedItem("protable").Text ' protable
            bChecked = IIf(oFieldNode.Attributes.getNamedItem("transfertable").Text = "1", True, False) ' transfertable
        End If
    Else
        Application.MousePointer = 0
        Call Lime.MessageBox("The required procedure csp_easytopro_getfieldmappingxml is missing", VBA.vbExclamation)
    End If
    
    sProTable = sTableName
    bTransferTable = bChecked
    Application.MousePointer = 0
    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.LoadTableData")
End Sub

Private Function ValidationNodeContainsError(oNode As Object, Optional bVerbose As Boolean = False) As Boolean
    On Error GoTo Errorhandler
    Dim v As Variant
    Dim i As Long

    If Not oNode Is Nothing Then
        v = VBA.Split(cWARNINGS, ";")
        For i = LBound(v) To UBound(v)
            If VBA.Len(v(i)) > 0 Then
                If VBA.Len(oNode.Attributes.getNamedItem(v(i)).Text) > 0 Then
                    If bVerbose = True Then
                        Call Lime.MessageBox(oNode.Attributes.getNamedItem(v(i)).Text, VBA.vbExclamation)
                    End If
                    ValidationNodeContainsError = True
                    Exit Function
                End If
            End If
        Next i
    End If

    ValidationNodeContainsError = False
    Exit Function
Errorhandler:
    ValidationNodeContainsError = True
    Call UI.ShowError("EasyToPro.ValidationNodeContainsError")
End Function

Public Sub LoadEasyFields(sTable As String, lv As Object, Optional sActiveFieldmapping As String = "")
    On Error GoTo Errorhandler
    Dim oFieldNode As IXMLDOMNode
    Dim oDataNode As IXMLDOMNode
    Dim oListItem As MSComctlLib.ListItem
    Dim sIdFieldMapping As String
    Dim oFieldProc As LDE.Procedure
    Dim oValidationNode As IXMLDOMNode
    Dim oFieldXML As MSXML2.DOMDocument60
    Dim oValidationXML As MSXML2.DOMDocument60
    Dim bError As Boolean
    
    Application.MousePointer = 11
    
    Call lv.ListItems.Clear
   
    
    Set oFieldProc = Database.Procedures.Lookup("csp_easytopro_getfieldmappingxml", lkLookupProcedureByName)
    If Not oFieldProc Is Nothing Then
        oFieldProc.Parameters("@@easytable").InputValue = sTable
        
        oFieldProc.Timeout = cTIMEOUT
        
        oFieldProc.Execute (False)
        
        Set oFieldXML = New MSXML2.DOMDocument60
        oFieldXML.LoadXML (oFieldProc.result)
        If Not oFieldXML Is Nothing Then
            Set oDataNode = oFieldXML.selectSingleNode("/data")
            If Not oDataNode Is Nothing Then
                Set oValidationXML = GetValidationXML()
                If Not oValidationXML Is Nothing Then
                    If oDataNode.hasChildNodes Then
                        For Each oFieldNode In oDataNode.childNodes
                            
                            sIdFieldMapping = oFieldNode.Attributes.getNamedItem("idfieldmapping").Text
                            
                            If Not oValidationXML Is Nothing Then
                                Set oValidationNode = oValidationXML.selectSingleNode("/data/warning[@idfieldmapping='" & sIdFieldMapping & "']")
                                bError = ValidationNodeContainsError(oValidationNode)
                            End If
                        
                            Set oListItem = lv.ListItems.Add
                            oListItem.Text = sIdFieldMapping ' idfieldmapping
                            oListItem.SubItems(1) = oFieldNode.Attributes.getNamedItem("easyfieldid").Text ' easyfieldid
                            oListItem.SubItems(2) = oFieldNode.Attributes.getNamedItem("active").Text ' active
                            oListItem.SubItems(3) = oFieldNode.Attributes.getNamedItem("existingfield").Text ' existingfield
                            
                            oListItem.SubItems(4) = IIf(bError, "Error", "")
                            oListItem.SubItems(5) = oFieldNode.Attributes.getNamedItem("easydatatypetext").Text ' easydatatypetext
                            oListItem.SubItems(6) = oFieldNode.Attributes.getNamedItem("easyfieldname").Text ' easyfieldname
                            oListItem.SubItems(7) = oFieldNode.Attributes.getNamedItem("profieldname").Text ' profieldname
                            oListItem.SubItems(8) = oFieldNode.Attributes.getNamedItem("localname_sv").Text ' localname_sv
                            oListItem.SubItems(9) = oFieldNode.Attributes.getNamedItem("localname_en_us").Text ' localname_en_us
                            oListItem.SubItems(10) = oFieldNode.Attributes.getNamedItem("localname_no").Text ' localname_no
                            oListItem.SubItems(11) = oFieldNode.Attributes.getNamedItem("localname_fi").Text ' localname_fi
                            oListItem.SubItems(12) = oFieldNode.Attributes.getNamedItem("localname_da").Text ' localname_da
                            
                            oListItem.SubItems(13) = oFieldNode.Attributes.getNamedItem("proposedvalue").Text ' proposedvalue
                            oListItem.SubItems(14) = oFieldNode.Attributes.getNamedItem("easyprofieldtype").Text ' easyprofieldtype
                            
                            oListItem.Tag = sIdFieldMapping ' idfieldmapping
                            
                            If VBA.Len(sActiveFieldmapping) > 0 Then
                                If sActiveFieldmapping = sIdFieldMapping Then
                                    oListItem.EnsureVisible
                                    oListItem.Selected = True
                                End If
                            End If

                            
                        Next oFieldNode
                    End If
                End If
            End If
        End If
    Else
        Application.MousePointer = 0
        Call Lime.MessageBox("The required procedure csp_easytopro_getfieldmappingxml is missing", VBA.vbExclamation)
    End If

    Application.MousePointer = 0
    Exit Sub
Errorhandler:
    Call UI.ShowError("EasyToPro.LoadEasyFields")
End Sub

Public Function AddAttribute(objDOM As Object, objXMLelement As Object, sAttribute As String, sValue As String) As Boolean
    On Error GoTo Errorhandler
    Dim objXMLattr As Object ' As IXMLDOMAttribute

    Set objXMLattr = objDOM.createAttribute(VBA.LCase(sAttribute))
    objXMLattr.nodeValue = sValue
    objXMLelement.setAttributeNode objXMLattr

    AddAttribute = True
    Exit Function
Errorhandler:
    Call UI.ShowError("EasyToPro.AddAttribute")
    AddAttribute = False
End Function

' ************************ UPDATED TO HANDLE HISTORY FROM EXPORTED FILES ************************************
Public Function ReplaceIllegalCharactersHistoryXML(ByVal sValue As String) As String
    On Error GoTo Errorhandler
    Dim sReplaceIllegalCharactersHistoryXML As String
    
    sReplaceIllegalCharactersHistoryXML = sValue
    
    Dim i As Integer
    For i = 0 To 31
    If i <> 9 And i <> 10 And i <> 13 Then
        sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, VBA.Chr$(i), "")
    End If
    Next i
    'Replace illegal characters (XML)
    sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, "&", "&amp;")
    sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, "<", "&lt;")
    sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, ">", "&gt;")
    sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, """", "&quot;")
    sReplaceIllegalCharactersHistoryXML = VBA.Replace(sReplaceIllegalCharactersHistoryXML, "'", "&apos;")

    ReplaceIllegalCharactersHistoryXML = sReplaceIllegalCharactersHistoryXML

    Exit Function
Errorhandler:
    ReplaceIllegalCharactersHistoryXML = ""
    Call UI.ShowError("GeneralDatabaseHandler.ReplaceIllegalCharactersHistoryXML")
End Function

Public Function ReplaceIllegalCharactersXML(ByVal sValue As String) As String
    On Error GoTo Errorhandler
    Dim sReplaceIllegalCharactersXML As String

    sReplaceIllegalCharactersXML = sValue

    'Replace illegal characters (XML)
'    sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, "&", "&amp;")
'    sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, "<", "&lt;")
'    sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, ">", "&gt;")
'    sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, """", "&quot;")
'    sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, "'", "&apos;")

    Dim i As Integer
    For i = 0 To 31
    If i <> 9 And i <> 10 And i <> 13 Then
        sReplaceIllegalCharactersXML = VBA.Replace(sReplaceIllegalCharactersXML, VBA.Chr$(i), "")
    End If
    Next i
    ReplaceIllegalCharactersXML = sReplaceIllegalCharactersXML

    Exit Function
Errorhandler:
    ReplaceIllegalCharactersXML = ""
    Call UI.ShowError("GeneralDatabaseHandler.ReplaceIllegalCharactersXML")
End Function


Public Function GetEasyTable(sEasyTable As String, sDatabasePath As String, oLabel As MSForms.label, Optional sDocumentPath As String = "") As Boolean
    On Error GoTo Errorhandler
    
    Dim SQL As String
    Dim rsmain As ADODB.Recordset
    Dim Db As Object
    Dim objDOM As Object 'DOMDocument
    Dim objXMLRootelement As Object ' As IXMLDOMElement
    Dim objXMLelement As Object
    Dim v As Variant
    Dim i As Long
    Dim proc As LDE.Procedure
    Dim oAddressParser As AddressParser 'Object 'AddressParser
    Dim bAllOK As Boolean
    Dim sAttributeValue As String
    Dim iRows As Integer
    Dim iCount As Long
    Dim iRebuild As Integer
    
    iRebuild = 1
    
    bAllOK = True
    '"C:\Users\mol\Desktop\EASY\kontakt.mdb" 'C:\Users\mol\Desktop\EASY\KON_TAKT.MDB
    
    Select Case VBA.UCase(sEasyTable)
        Case "ARCHIVE":
            v = VBA.Split(cARCHIVE, ";")
        Case "CONTACT":
             v = VBA.Split(cCONTACT, ";")
        Case "DATA":
             v = VBA.Split(cDATA, ";")
        Case "HISTORY":
             v = VBA.Split(cHISTORY, ";")
        Case "INCLUDE":
             v = VBA.Split(cINCLUDE, ";")
        Case "PROJECT":
             v = VBA.Split(cPROJECT, ";")
        Case "REFS":
             v = VBA.Split(cREFS, ";")
        Case "STRING":
             v = VBA.Split(cSTRING, ";")
        Case "TIME":
             v = VBA.Split(cTIME, ";")
        Case "TODO":
             v = VBA.Split(cTODO, ";")
        Case "USER":
             v = VBA.Split(cUSER, ";")
        Case "SETTINGS":
             v = VBA.Split(cSETTINGS, ";")
        Case "FIELD":
             v = VBA.Split(cFIELD, ";")
        Case Else
            Call Lime.MessageBox("'%1' is not a valid Easy table", VBA.vbInformation, sEasyTable)
            GetEasyTable = False
            Exit Function
    End Select
    
    Set Db = CreateObject("ADODB.Connection")
    
    Call Db.Open(Lime.FormatString(cConnectionString, sDatabasePath))
    
    SQL = Lime.FormatString("SELECT * FROM [%1]", sEasyTable)
    
    Set proc = Database.Procedures.Lookup(Lime.FormatString("csp_easytopro_%1", VBA.LCase(sEasyTable)), lkLookupProcedureByName)
    
    
'    Set oAddressParser = CreateObject("LLADR01.AddressParser")
    
    
    ' Hämtar ut data från Easy
    Set rsmain = Db.Execute(SQL)
    
    ' Skapar XML-dokument
    Set objDOM = CreateObject("MSXML2.DOMDocument")
   
    ' CREATE ROOT ELEMENT
    Set objXMLRootelement = objDOM.createElement("data")
    objDOM.appendChild objXMLRootelement
   
   iRows = 0
   iCount = 0
   
    ' CREATE ROW ELEMENT WITH ATTRIBUTE DATA
    While Not rsmain.EOF And bAllOK
        iRows = iRows + 1
        iCount = iCount + 1
        DoEvents
        oLabel.Caption = Lime.FormatString("%1: %2 rows created", sEasyTable, VBA.CStr(iCount))
        DoEvents
        ' ADD NEW ROW ELEMENT
        Set objXMLelement = objDOM.createElement("row")
        objXMLRootelement.appendChild objXMLelement
   
        ' ADD ATTRIBUTE
        For i = LBound(v) To UBound(v)
            If VBA.Len(v(i)) > 0 Then
                If bAllOK = True Then
                    sAttributeValue = ""
                    sAttributeValue = IIf(VBA.IsNull(rsmain(v(i)).Value), "", rsmain(v(i)))
                    sAttributeValue = ReplaceIllegalCharactersXML(sAttributeValue)
                    
                    ' HANDLE DATEFORMAT
                    If VBA.InStr(1, cDATEFIELDS, Lime.FormatString(";%1;", v(i))) > 0 And VBA.Len(sAttributeValue) > 0 Then
                        sAttributeValue = GetProDateFormat(sAttributeValue)
                    End If

                    bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, VBA.Replace(VBA.CStr(v(i)), " ", ""), sAttributeValue)
                End If
            End If
        Next i
        If bAllOK = True Then
            If VBA.UCase(sEasyTable) = "CONTACT" Then
                ' SPLIT ADDRESS USING ADDRESSPARSER
                Set oAddressParser = New AddressParser
                sAttributeValue = ""
                sAttributeValue = IIf(VBA.IsNull(rsmain("Address").Value), "", rsmain("Address"))
                sAttributeValue = VBA.Replace(sAttributeValue, "'", "''")
                oAddressParser.AddressBuffer = sAttributeValue
                
                Dim a As Integer
                Dim s As String
                
                
                For a = 0 To 2
                    If bAllOK = True Then
                        s = Lime.FormatString("AddressLinesBeforeZip%1", a + 1)
                        If a <= UBound(oAddressParser.AddressLinesBeforeArray) Then
                            bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, IIf(VBA.IsNull(oAddressParser.AddressLinesBeforeArray(a)), "", oAddressParser.AddressLinesBeforeArray(a)))
                        Else
                            bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, "")
                        End If
                    End If
                Next a
                If bAllOK = True Then
                    s = "Zipcode"
                    bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, IIf(VBA.IsNull(oAddressParser.ZipCode), "", oAddressParser.ZipCode))
                    s = "City"
                    bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, IIf(VBA.IsNull(oAddressParser.City), "", oAddressParser.City))
                End If
                For a = 0 To 1
                    If bAllOK = True Then
                        s = Lime.FormatString("AddressLinesAfterZip%1", a + 1)
                    
                        If a <= UBound(oAddressParser.AddressLinesAfterArray) Then
                            bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, IIf(VBA.IsNull(oAddressParser.AddressLinesAfterArray(a)), "", oAddressParser.AddressLinesAfterArray(a)))
                        Else
                            bAllOK = bAllOK And AddAttribute(objDOM, objXMLelement, s, "")
                        End If
                    End If
                Next a
                
            End If
        End If
        If iRows = cRowPage Then
            If bAllOK = True Then
   
     
                If Not proc Is Nothing Then
                    proc.Parameters("@@xml").InputValue = objDOM.XML
                    proc.Parameters("@@rebuildtable").InputValue = iRebuild
                    If sEasyTable = "ARCHIVE" Then
                        proc.Parameters("@@documentpath").InputValue = sDocumentPath
                    End If
                    
                    proc.Timeout = cTIMEOUT
                    
                    proc.Execute (False)
                End If
            End If
            
            iRebuild = 0
            
            
            
            ' Skapar XML-dokument
            Set objDOM = CreateObject("MSXML2.DOMDocument")
   
            ' CREATE ROOT ELEMENT
            Set objXMLRootelement = objDOM.createElement("data")
            objDOM.appendChild objXMLRootelement
            iRows = 0
        End If
        rsmain.MoveNext
    Wend
    
    If bAllOK = True Then
        If iRows > 0 Or iRebuild = 1 Then
            If Not proc Is Nothing Then
                proc.Parameters("@@xml").InputValue = objDOM.XML
                proc.Parameters("@@rebuildtable").InputValue = iRebuild
                If sEasyTable = "ARCHIVE" Then
                    proc.Parameters("@@documentpath").InputValue = sDocumentPath
                End If
                
                proc.Timeout = cTIMEOUT
                
                proc.Execute (False)
            End If
        End If
    Else
        Call Lime.MessageBox("Error While processing LIME Easy table '%1'", VBA.vbExclamation, sEasyTable)
    End If
    
    GetEasyTable = bAllOK
    
    Exit Function
Errorhandler:
    GetEasyTable = False
    Call UI.ShowError("EasyToPro.GetEasyTable")
End Function


Public Function CreateEasyFieldMapping() As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    
    Dim bCreateEasyFieldMapping As Boolean
    
    bCreateEasyFieldMapping = False


    
    Set proc = Database.Procedures.Lookup("csp_easytopro_create_easy__fieldmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
        
        bCreateEasyFieldMapping = False
        If VBA.IsNull(proc.Parameters("@@result").OutputValue) = False Then
            If (proc.Parameters("@@result").OutputValue = 0) Then
                bCreateEasyFieldMapping = True
            End If
        End If
    Else
        sMessage = "The procedure csp_easytopro_create_easy__fieldmapping is missing"
    End If
    
    If VBA.Len(sMessage) > 0 Then
        Call Lime.MessageBox(sMessage, IIf(bCreateEasyFieldMapping = True, VBA.vbInformation, VBA.vbExclamation))
    End If
        
       
    
    CreateEasyFieldMapping = bCreateEasyFieldMapping
    Exit Function
Errorhandler:
    CreateEasyFieldMapping = False
    Call UI.ShowError("EasyToPro.CreateEasyFieldMapping")

End Function


Public Function AddSuperFieldsToEasyFieldMapping(bLogChanges As Boolean) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bAddSuperFieldsToEasyFieldMapping As Boolean
    Dim oXML As MSXML2.DOMDocument60
    
    bAddSuperFieldsToEasyFieldMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_addsuperfieldsto_easy__fieldmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
        
        If bLogChanges = True Then
        
            If (VBA.IsNull(proc.result) = False) Then
                Open LCO.MakeFileName(Application.WebFolder, "AddSuperFieldsLog.xml") For Output As #1
                Print #1, proc.result
                Close #1
            End If
        End If
    Else
        sMessage = "The procedure csp_easytopro_addsuperfieldsto_easy__fieldmapping is missing"
    End If
    If VBA.Len(sMessage) > 0 Then
        bAddSuperFieldsToEasyFieldMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bAddSuperFieldsToEasyFieldMapping = True
    End If
        
       
    
    AddSuperFieldsToEasyFieldMapping = bAddSuperFieldsToEasyFieldMapping

    Exit Function
Errorhandler:
    AddSuperFieldsToEasyFieldMapping = False
    Call UI.ShowError("EasyToPro.AddSuperFieldsToEasyFieldMapping")

End Function

Public Function CreateEasyOptionMapping(bLogChanges As Boolean) As Boolean
    On Error GoTo Errorhandler
    Dim sMessage As String
    Dim proc As LDE.Procedure
    Dim bCreateEasyOptionMapping As Boolean
    Dim oXML As MSXML2.DOMDocument60
    
    bCreateEasyOptionMapping = False
   
    
    Set proc = Database.Procedures.Lookup("csp_easytopro_create_easy__optionmapping", lkLookupProcedureByName)
    If Not proc Is Nothing Then
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
        
        If bLogChanges = True Then
        
            If (VBA.IsNull(proc.result) = False) Then
                Open LCO.MakeFileName(Application.WebFolder, "CreateEasyOptionLog.xml") For Output As #1
                Print #1, proc.result
                Close #1
            End If
        End If
    Else
        sMessage = "The procedure csp_easytopro_create_easy__optionmapping is missing"
    End If
    If VBA.Len(sMessage) > 0 Then
        bCreateEasyOptionMapping = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bCreateEasyOptionMapping = True
    End If
        
       
    
    CreateEasyOptionMapping = bCreateEasyOptionMapping

    Exit Function
Errorhandler:
    CreateEasyOptionMapping = False
    Call UI.ShowError("EasyToPro.CreateEasyOptionMapping")

End Function


' ************** NEW HANDLE HISTORY FROM EXPORTED FILES **********************************

Public Function AddSplittedHistory(ByRef oLabel As Object, ByVal textFilePath As String, iType As Integer) As Boolean
On Error GoTo Errorhandler
    Dim nFileNum As Integer
    Dim sNextLine As String
    Dim iCount As Integer
    Dim lngCount As Long
    Dim totCount As Long
    Dim totCreated As Long
    Dim sXML As String
    Dim lngTotalRows As Long
    Dim bOk As Boolean
    Dim vRow As Variant
    Dim iExtraColumn As Integer
    
'idHistory
'idCompany/idProject
'PowerSellCompanyID/PowerSellProjectID
'Date
'Signature
'idUser
'Category
'Reference
'idPerson (Company History Only)
'History
'RawHistory
    
    
        ' Get a free file number
        nFileNum = FreeFile
        iCount = 0
        totCreated = 0
        bOk = True
        
        If iType = 0 Then
            iExtraColumn = 1
        Else
            iExtraColumn = 0
        End If
        
        If VBA.Len(textFilePath) > 0 Then
            lngTotalRows = NoOfRows(textFilePath)
            Application.MousePointer = 11
            
            
            ' Open a text file for input. inputbox returns the path to read the file
            sXML = "<root>"

            Open textFilePath For Input As nFileNum
            ' Read the contents of the file
            Do While ((Not EOF(nFileNum)) And bOk)
                Line Input #nFileNum, sNextLine

                If VBA.Len(VBA.Trim(sNextLine)) > 0 Then
                    vRow = VBA.Split(sNextLine, VBA.vbTab, , vbBinaryCompare)
                        If UBound(vRow) = (9 + iExtraColumn) And VBA.IsNumeric(vRow(0)) Then
                            sXML = sXML + "<row " & _
                                    "type=""" + VBA.CStr(iType) + """ " & _
                                    "historyid=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(0))) + """ " & _
                                    "powersellid=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(2))) + """ " & _
                                    "date=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(3))) + """ " & _
                                    "signature=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(4))) + """ " & _
                                    "category=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(6))) + """ " & _
                                    "reference=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(7))) + """ " & _
                                    "rawhistory=""" + ReplaceIllegalCharactersHistoryXML(VBA.Trim(vRow(9 + iExtraColumn))) + """ " & _
                                    "/>"
                            iCount = iCount + 1
                            lngCount = lngCount + 1
                            oLabel.Caption = Lime.FormatString("Importing %1 history, %2/%3", IIf(iType = 0, "Company", "Project"), lngCount, lngTotalRows)
                        End If
                End If

                If iCount = 200 Then
                    sXML = sXML + "</root>"
                    bOk = InsertHistory(sXML)
                    iCount = 0
                    sXML = "<root>"
                End If
            Loop

            If iCount > 0 And bOk Then
                sXML = sXML + "</root>"
                bOk = InsertHistory(sXML)
            End If

            ' Close the file
            Close nFileNum
        End If

    Application.MousePointer = 0
    AddSplittedHistory = bOk
    Exit Function
Errorhandler:
    Close nFileNum
    AddSplittedHistory = False
   Call UI.ShowError("Easy2Pro.AddSplittedHistory")
End Function


Private Function RebuildSplittedHistory() As Boolean
    On Error GoTo Errorhandler
    Dim proc As LDE.Procedure
    Dim bOk As Boolean
    Dim sMessage As String
    Application.MousePointer = 11

    Set proc = Database.Procedures("csp_easytopro_rebuildsplithistory")

    If Not proc Is Nothing Then
        
       
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        
        
        bOk = True
    End If
    
    RebuildSplittedHistory = bOk

    Application.MousePointer = 0

    Exit Function
Errorhandler:
    RebuildSplittedHistory = False
    Call UI.ShowError("Easy2Pro.RebuildSplittedHistory")
End Function


Private Function InsertHistory(ByVal sXML As String) As Boolean
    On Error GoTo Errorhandler
    Dim proc As LDE.Procedure
    Dim bOk As Boolean
    Dim sMessage As String
    Application.MousePointer = 11

    Set proc = Database.Procedures("csp_easytopro_insertsplithistory")

    If Not proc Is Nothing Then
        
        proc.Parameters("@@xml").InputValue = sXML
        
        proc.Timeout = cTIMEOUT
        
        proc.Execute (False)
        
        If VBA.IsNull(proc.Parameters("@@errormessage").OutputValue) = False Then
            sMessage = proc.Parameters("@@errormessage").OutputValue
        Else
            sMessage = "UNKNOWN RESULT"
        End If
        
    Else
        sMessage = "The procedure csp_easytopro_insertsplithistory is missing"
    End If
    
    Application.MousePointer = 0
    
    If VBA.Len(sMessage) > 0 Then
        bOk = False
        Call Lime.MessageBox(sMessage, VBA.vbExclamation)
    Else
        bOk = True
    End If
    
    InsertHistory = bOk
    'Debug.Print sXML

    Application.MousePointer = 0

    Exit Function
Errorhandler:
    InsertHistory = False
    Call UI.ShowError("Easy2Pro.InsertHistory")
End Function


Public Function NoOfRows(textFilePath As String) As Long
On Error GoTo Errorhandler
    Dim nFileNum As Integer
    Dim sNextLine As String
    'Dim textFilePath As String
    Dim lngCount As Long


    
    ' Get a free file number
    nFileNum = FreeFile
    lngCount = 0

    'textFilePath = OpenSingleFile()
    If VBA.Len(textFilePath) > 0 Then
        Application.MousePointer = 11
        
        ' Open a text file for input. inputbox returns the path to read the file
        Open textFilePath For Input As nFileNum
        ' Read the contents of the file
        Do While Not EOF(nFileNum)
            Line Input #nFileNum, sNextLine

            If VBA.Len(VBA.Trim(sNextLine)) > 0 Then
                
                lngCount = lngCount + 1
            End If

        Loop

        ' Close the file
        Close nFileNum
    End If
    If lngCount > 0 Then
        lngCount = lngCount - 1 ' REMOVE HEADER ROW
    End If
    NoOfRows = lngCount
    Application.MousePointer = 0
    Exit Function
Errorhandler:
    NoOfRows = 0
   Call UI.ShowError("Easy2Pro.NoOfRows")
End Function


Public Function LoadFieldMappingFromFile(strXML As String) As Boolean
On Error GoTo Errorhandler
    Dim bLoadFieldMappingFromFile As Boolean
    bLoadFieldMappingFromFile = False
    
    Dim oProc As LDE.Procedure
    Set oProc = Database.Procedures.Lookup("csp_easytopro_replace_easy__fieldmapping", lkLookupProcedureByName)
    If Not oProc Is Nothing Then
    
        Dim strMessage As String
        
        oProc.Parameters("@@xml").InputValue = strXML
        oProc.Timeout = cTIMEOUT
        oProc.Execute (False)
        
        If VBA.IsNull(oProc.Parameters("@@errormessage").OutputValue) = False Then
            strMessage = oProc.Parameters("@@errormessage").OutputValue
        Else
            Call Lime.MessageBox("Unknown result from loading fieldmapping. Please check result afterwards.")
        End If
        
        If VBA.Len(strMessage) > 0 Then
            Call Lime.MessageBox("Failed to load mapping." & vbNewLine & vbNewLine & strMessage)
        Else
            bLoadFieldMappingFromFile = True
        End If
        
    Else
        Call Lime.MessageBox("The required procedure csp_easytopro_replace_easy__fieldmapping", VBA.vbExclamation)
    End If
    
    LoadFieldMappingFromFile = bLoadFieldMappingFromFile
    
    Exit Function
Errorhandler:
    Call UI.ShowError("EasyToPro.LoadFieldMappingFromFile")
End Function

Public Function LoadOptionMappingFromFile(strXML As String) As Boolean
On Error GoTo Errorhandler
    Dim bLoadOptionMappingFromFile As Boolean
    bLoadOptionMappingFromFile = False
    
    Dim oProc As LDE.Procedure
    Set oProc = Database.Procedures.Lookup("csp_easytopro_replace_easy__optionmapping", lkLookupProcedureByName)
    If Not oProc Is Nothing Then
    
        Dim strMessage As String
        
        oProc.Parameters("@@xml").InputValue = strXML
        oProc.Timeout = cTIMEOUT
        oProc.Execute (False)
        
        If VBA.IsNull(oProc.Parameters("@@errormessage").OutputValue) = False Then
            strMessage = oProc.Parameters("@@errormessage").OutputValue
        Else
            Call Lime.MessageBox("Unknown result from loading optionmapping. Please check result afterwards.")
        End If
        
        If VBA.Len(strMessage) > 0 Then
            Call Lime.MessageBox("Failed to load mapping." & vbNewLine & vbNewLine & strMessage)
        Else
            bLoadOptionMappingFromFile = True
        End If
        
    Else
        Call Lime.MessageBox("The required procedure csp_easytopro_replace_easy__optionmapping is missing.", VBA.vbExclamation)
    End If
    
    LoadOptionMappingFromFile = bLoadOptionMappingFromFile
    
    Exit Function
Errorhandler:
    Call UI.ShowError("EasyToPro.LoadOptionMappingFromFile")
End Function

Public Function ValidateEasyData() As Boolean
On Error GoTo Errorhandler
    
    Dim bValidateEasyData As Boolean
    bValidateEasyData = True 'Only display a warning message if invalid data is found
    
    Dim oProc As LDE.Procedure
    Set oProc = Database.Procedures.Lookup("csp_easytopro_validate_easydata", lkLookupProcedureByName)
    
    If Not oProc Is Nothing Then
    
        Dim strError As String
        
        oProc.Timeout = cTIMEOUT
        oProc.Execute (False)
        
        If VBA.IsNull(oProc.Parameters("@@errormessage").OutputValue) = False Then
            strError = oProc.Parameters("@@errormessage").OutputValue
        Else
            Call Lime.MessageBox("Unknown result from validating data. Please check result afterwards.")
        End If
        
        If VBA.Len(strError) > 0 Then
            Call Lime.MessageBox(strError & vbNewLine & vbNewLine & "You can still proceed but invalid data will be ignored and not migrated. You should check the data in LIME Easy, correct any invalid data and then try to load the data again to avoid data loss.")
        End If
        
    Else
        Call Lime.MessageBox("The required procedure csp_easytopro_validate_easydata is missing", VBA.vbExclamation)
    End If
    
    ValidateEasyData = bValidateEasyData
    
    Exit Function
Errorhandler:
    Call UI.ShowError("EasyToPro.ValidateEasyData")
End Function
