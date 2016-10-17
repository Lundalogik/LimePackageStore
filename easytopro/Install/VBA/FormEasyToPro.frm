VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} FormEasyToPro 
   Caption         =   "EasyToCRM"
   ClientHeight    =   10980
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   23295
   OleObjectBlob   =   "FormEasyToPro.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "FormEasyToPro"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

















Option Explicit


Private m_idfieldmapping As Long
Private m_idoptionmapping As Long
Private m_profieldnamebeforechange As String
Private m_disableSave As Boolean

'Private Enum EnumExistingField
'    Existing = 0
'    Unknown = 1
'    NotExisting = 2
'End Enum


Private Const cCONTACT As String = "CONTACT"
Private Const cREFS As String = "REFS"
Private Const cPROJECT As String = "PROJECT"
Private Const cTIME As String = "TIME"
Private Const cHISTORY As String = "HISTORY"
Private Const cTODO As String = "TODO"
Private Const cARCHIVE As String = "ARCHIVE"
Private Const cUSER As String = "USER"

Private Sub ValidateLimeProFieldInput(tb As TextBox, ByVal KeyAscii As MSForms.ReturnInteger)
    On Error Resume Next
    If Not ((KeyAscii >= 48 And KeyAscii <= 57) Or (KeyAscii >= 97 And KeyAscii <= 122) Or (KeyAscii = 95)) Then
        KeyAscii = 0
    End If
End Sub

Private Sub ValidateLimeProLocalnameInput(tb As TextBox, ByVal KeyAscii As MSForms.ReturnInteger)
    On Error Resume Next
    If (KeyAscii = 46) Then
        KeyAscii = 0
    End If
End Sub

Private Sub btn_browse_Click()
    On Error GoTo Errorhandler

    Me.tb_easydatabasepath = OpenSingleFile("Easy database (*.mdb)|*.mdb")
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_browse_Click")
End Sub

Private Sub btn_companyhistory_Click()
    On Error GoTo Errorhandler
    
    Me.tb_companyhistorypath = OpenSingleFile("Text File (*.txt)|*.txt")
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_companyhistory_Click")
End Sub

'Private Sub btn_documentpath_Click()
'  On Error GoTo Errorhandler
'    Dim oDocumentpath As New LCO.FolderDialog
'    oDocumentpath.Text = "Select documentpath"
'    If oDocumentpath.show = 1 Then
'        tb_documentpath = oDocumentpath.Folder
'    End If
'    Set oDocumentpath = Nothing
'    Exit Sub
'Errorhandler:
'    Call UI.ShowError("FormEasyToPro.btn_documentpath_Click")
'End Sub

Private Sub btn_LoadMapping_Click()
    On Error GoTo Errorhandler
    
    Dim strFileName As String
    strFileName = OpenSingleFile("XML-file (*.xml)|*.xml")
    
    If strFileName <> "" Then
        If (Lime.MessageBox("Are you sure you want to replace existing fieldmapping with mapping from following file:" & vbNewLine & vbNewLine & strFileName & vbNewLine & vbNewLine & "All your previous work will be overwritten and this action cannot be undone.", vbYesNo + vbDefaultButton2) = vbYes) Then
            Application.MousePointer = 11
            
            Dim bContinue As Boolean
            Dim strFullXML As String
            Dim strXML As String
            Dim strLine As String
            Open strFileName For Input As #1
            Do Until EOF(1)
                Line Input #1, strLine
                strFullXML = strFullXML + strLine
            Loop
            Close #1
            
            Dim startPos As Long
            Dim endPos As Long
            
            startPos = InStr(strFullXML, "[BEGIN FIELDMAPPING]") + VBA.Len("[BEGIN FIELDMAPPING]")
            endPos = InStr(strFullXML, "[END FIELDMAPPING]")
            strXML = (VBA.Mid(strFullXML, startPos, endPos - startPos))
            
            bContinue = EasyToPro.LoadFieldMappingFromFile(strXML)
            
            If bContinue Then
                startPos = InStr(strFullXML, "[BEGIN OPTIONMAPPING]") + VBA.Len("[BEGIN OPTIONMAPPING]")
                endPos = InStr(strFullXML, "[END OPTIONMAPPING]")
                strXML = (VBA.Mid(strFullXML, startPos, endPos - startPos))
                
                bContinue = EasyToPro.LoadOptionMappingFromFile(strXML)
            End If
            
            If bContinue Then
                Call EasyToPro.AddSuperFieldsToEasyFieldMapping(False)
            End If
            
            Call SetUpForm
            
            Application.MousePointer = 0
            
        End If
    End If

    strFileName = ""
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_LoadMapping_Click")
End Sub

Private Sub btn_projecthistory_Click()
    On Error GoTo Errorhandler
    
    Me.tb_projecthistorypath = OpenSingleFile("Text File (*.txt)|*.txt")
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_projecthistory_Click")
End Sub

'"Text File (*.txt)|*.txt"
'"Easy database (*.mdb)|*.mdb"
Private Function OpenSingleFile(sFileType As String) As String
    On Error GoTo Errorhandler
    Dim oFileOpenDialog As New LCO.FileOpenDialog
    Dim sPath As String
    
    sPath = ""
    oFileOpenDialog.Filter = sFileType
 
    If (oFileOpenDialog.show = 1) Then
        sPath = oFileOpenDialog.FileName
    End If

    OpenSingleFile = sPath
    Exit Function
Errorhandler:
    OpenSingleFile = ""
    Call UI.ShowError("Actionpad_Campaign.OpenSingleFile")
End Function




Private Sub btn_BrowseDocumentpath_Click()
  On Error GoTo Errorhandler
  Dim oFolder As New LCO.FolderDialog
    oFolder.Text = "Select Easy documentfolder"
    If oFolder.show = 1 Then
        tb_easydocumentpath = oFolder.Folder
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_BrowseDocumentpath_Click")
End Sub

Private Sub btn_clearoption_Click()
    On Error GoTo Errorhandler
    If m_idoptionmapping > 0 Then
        Call EasyToPro.UpdateOptionMapping(m_idoptionmapping, m_idfieldmapping, -1)
        
        Call LoadOptionList
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_clearoption_Click")
End Sub

Public Function ValidateAllTableNames() As Boolean
    On Error GoTo Errorhandler
    Dim bOk As Boolean
    
    bOk = True
    
    'CONTACT
    If check_contact.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_contact.Value, True))
    End If
    'REFS
    If check_refs.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_refs.Value, True))
    End If
    'PROJECT
    If check_project.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_project.Value, True))
    End If
    'TIME
    If check_time.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_time.Value, True))
    End If
    'HISTORY
    If check_history.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_history.Value, True))
    End If
    'TODO
    If check_todo.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_todo.Value, True))
    End If
    'ARCHIVE
    If check_archive.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_archive.Value, True))
    End If
    'USER
    If check_user.Value = True Then
        bOk = (bOk And EasyToPro.ValidateTableName(Me.tb_user.Value, True))
   End If
   
    ValidateAllTableNames = bOk
    Exit Function
Errorhandler:
    ValidateAllTableNames = False
    Call UI.ShowError("FormEasyToPro.ValidateAllTableNames")
End Function



Private Sub btn_DoWork_Click()
    On Error GoTo Errorhandler
    Dim bOk As Boolean
    Dim sLanguage As String
    
    
    sLanguage = Me.cb_language.List(Me.cb_language.ListIndex, 0)
    bOk = True
    If VBA.Len(sLanguage) = 0 Then
        Call Lime.MessageBox("Language is not set")
        Exit Sub
    End If
    Application.MousePointer = 11
    lb_progress.Caption = "Validating..."
    If ValidateAll = True Then
        
        If ValidateAllTableNames = False Then
            Application.MousePointer = 0
            Call Lime.MessageBox("Validation of tablenames resulted with errors", VBA.vbExclamation)
            lb_progress.Caption = ""
            Exit Sub
        End If

         If bOk = True Then
            lb_progress.Caption = "Checking required tables..."
            bOk = EasyToPro.CheckRequiredTables(True)
        End If

        If ((bOk = True) And (check_truncatetables.Value = True)) Then
            lb_progress.Caption = "Truncating tables..."
            bOk = EasyToPro.TruncateTablesBeforeGO
        End If

        If bOk = True Then
            lb_progress.Caption = "Creating tables if missing..."
            bOk = EasyToPro.CreateTablesIfNeeded
        End If


        If bOk = True Then
            bOk = AddMigrationFields(sLanguage)
        End If

        If bOk = True Then
            bOk = AddFixedRelations
        End If
        If bOk = True Then
            bOk = AddSuperFields(sLanguage)
        End If
        If bOk = True Then
            bOk = ImportAndCreate
        End If
        If bOk = True Then
            bOk = UpdateFixedRelations
        End If

        If bOk = True Then
            lb_progress.Caption = "Link Project to Contact..."
            bOk = EasyToPro.LinkProjectContact
        End If

        If bOk = True Then
            bOk = ImportSuperFields
        End If
        If bOk = True Then
            lb_progress.Caption = "Importing history..."
            bOk = EasyToPro.ImportEasyHistory()
        End If
        
        If bOk = True Then
            lb_progress.Caption = "Run SQL On Update..."
            bOk = EasyToPro.RunSQLOnUpdate()
        End If
        
        If bOk = True Then
            lb_progress.Caption = "Fix createdtime and timestamp..."
            bOk = FixTimestamp()
        End If
        
        If bOk = True Then
            lb_progress.Caption = "Ending Migration..."
            bOk = EasyToPro.EndMigration()
        End If
        
        Application.MousePointer = 0
        If bOk = True Then
            Call Lime.MessageBox("Migration completed successfully!", VBA.vbInformation)
            lb_progress.Caption = "DONE :-)"
        Else
            Call Lime.MessageBox("Migration completed with errors!", VBA.vbExclamation)
            lb_progress.Caption = "FAILED :-("
        End If
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_DoWork_Click")
End Sub

Private Function AddMigrationFields(sLanguage As String) As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_contact.Text)
            bOk = EasyToPro.CreateMigrationFields("@@CONTACT_table", tb_contact.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cCONTACT, sLanguage)
            End If
            
        
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_refs.Text)
            bOk = EasyToPro.CreateMigrationFields("@@REFS_table", tb_refs.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cREFS, sLanguage)
            End If
            
           
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_project.Text)
            bOk = EasyToPro.CreateMigrationFields("@@PROJECT_table", tb_project.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cPROJECT, sLanguage)
            End If
            
           
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_time.Text)
            bOk = EasyToPro.CreateMigrationFields("@@TIME_table", tb_time.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cTIME, sLanguage)
            End If
            
          
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_history.Text)
            bOk = EasyToPro.CreateMigrationFields("@@HISTORY_table", tb_history.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cHISTORY, sLanguage)
            End If
            
            
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_todo.Text)
            bOk = EasyToPro.CreateMigrationFields("@@TODO_table", tb_todo.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cTODO, sLanguage)
            End If
            
            
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_archive.Text)
            bOk = EasyToPro.CreateMigrationFields("@@ARCHIVE_table", tb_archive.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cARCHIVE, sLanguage)
            End If
            
           
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            lb_progress.Caption = Lime.FormatString("Adding migration fields to table %1", tb_user.Text)
            bOk = EasyToPro.CreateMigrationFields("@@USER_table", tb_user.Text)
            
            lb_progress.Caption = Lime.FormatString("Adding fixed fields to table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedFields(cUSER, sLanguage)
            End If
            
            
        End If
    End If
    lb_progress.Caption = ""
    AddMigrationFields = bOk
    Exit Function
Errorhandler:
    AddMigrationFields = False
    Call UI.ShowError("FormEasyToPro.AddMigrationFields")
End Function

Private Function AddFixedRelations() As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cCONTACT)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cREFS)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cPROJECT)
            End If
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cTIME)
            End If
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cHISTORY)
            End If
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cTODO)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cARCHIVE)
            End If
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding relation fields to table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateFixedRelations(cUSER)
            End If
        End If
    End If
    lb_progress.Caption = ""
    AddFixedRelations = bOk
    Exit Function
Errorhandler:
    AddFixedRelations = False
    Call UI.ShowError("FormEasyToPro.AddFixedRelations")
End Function

Private Function ImportAndCreate() As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cCONTACT)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cREFS)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cPROJECT)
            End If
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cTIME)
            End If
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cHISTORY)
            End If
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cTODO)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportDataToFixedFields(cARCHIVE)
            End If
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing/updating table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.MergeUserTable(cUSER)
            End If
        End If
    End If
    lb_progress.Caption = ""
    ImportAndCreate = bOk
    Exit Function
Errorhandler:
    ImportAndCreate = False
    Call UI.ShowError("FormEasyToPro.ImportAndCreate")
End Function

Private Function UpdateFixedRelations() As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cCONTACT)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cREFS)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cPROJECT)
            End If
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cTIME)
            End If
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cHISTORY)
            End If
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cTODO)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cARCHIVE)
            End If
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing data to table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.ConnectFixedRelationFields(cUSER)
            End If
        End If
    End If
    lb_progress.Caption = ""
    UpdateFixedRelations = bOk
    Exit Function
Errorhandler:
    UpdateFixedRelations = False
    Call UI.ShowError("FormEasyToPro.UpdateFixedRelations")
End Function

Private Function ImportSuperFields() As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cCONTACT)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cREFS)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cPROJECT)
            End If
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cTIME)
            End If
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cHISTORY)
            End If
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cTODO)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cARCHIVE)
            End If
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Importing superfield data to table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.ImportSuperFieldData(cUSER)
            End If
        End If
    End If
    lb_progress.Caption = ""
    ImportSuperFields = bOk
    Exit Function
Errorhandler:
    ImportSuperFields = False
    Call UI.ShowError("FormEasyToPro.ImportSuperFields")
End Function

Private Function AddSuperFields(sLanguage As String) As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cCONTACT, sLanguage)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cREFS, sLanguage)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cPROJECT, sLanguage)
            End If
        End If
    End If
    If bOk = True Then
        If check_time.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_time.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cTIME, sLanguage)
            End If
        End If
    End If
    If bOk = True Then
        If check_history.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_history.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cHISTORY, sLanguage)
            End If
        End If
    End If
    If bOk = True Then
        If check_todo.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_todo.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cTODO, sLanguage)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cARCHIVE, sLanguage)
            End If
        End If
    End If
    If bOk = True Then
        If check_user.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Adding super fields to table %1", tb_user.Text)
            If bOk = True Then
                bOk = EasyToPro.CreateSuperFields(cUSER, sLanguage)
            End If
        End If
    End If
    lb_progress.Caption = ""
    AddSuperFields = bOk
    Exit Function
Errorhandler:
    AddSuperFields = False
    Call UI.ShowError("FormEasyToPro.AddSuperFields")
End Function

Private Sub btn_ImportDocuments_Click()
    On Error GoTo Errorhandler
    
    If VBA.vbYes = Lime.MessageBox("This will import existing documents. Are you sure you want to continue?", VBA.vbYesNo + VBA.vbDefaultButton1) Then
        If ((VBA.Len(tb_archive.Text) = 0) Or (check_archive.Value = False)) Then
            Call Lime.MessageBox("Document table must be selected for migration", VBA.vbExclamation)
            Exit Sub
        End If
        If (VBA.Len(tb_easydocumentpath.Text) = 0) Then
            Call Lime.MessageBox("Path to Document folder must be set for migration", VBA.vbExclamation)
            Exit Sub
        End If
        
        If (VBA.Len(tb_documentfield.Text) = 0) Then
            Call Lime.MessageBox("Document field name must be set for migration", VBA.vbExclamation)
            Exit Sub
        End If
        
        If Application.Database.Classes.Exists(tb_archive.Text) = False Then
            Call Lime.MessageBox("Table %1 don´t exists.", VBA.vbExclamation, tb_archive.Text)
            Exit Sub
        End If
        If Application.Database.Classes(tb_archive.Text).Fields.Exists(tb_documentfield.Text) = False Then
            Call Lime.MessageBox("Document field %1 don´t exist in table %2.", VBA.vbExclamation, tb_documentfield.Text, tb_archive.Text)
            Exit Sub
        End If
        
        If AddDocumentFile(tb_archive.Text, tb_documentfield.Text, tb_easydocumentpath.Text, lb_progress, True) = True Then
            Call Lime.MessageBox("Documents imported, please check log in actionpadfolder: %1.", VBA.vbInformation, Application.WebFolder)
        Else
            Call Lime.MessageBox("Import documents failed", VBA.vbExclamation)
        End If
    End If
    Me.lb_progress.Caption = ""
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_ImportDocuments_Click")
End Sub

Private Sub btn_loadeasydata_Click()
    On Error GoTo Errorhandler
    Dim bContinue As Boolean
    Dim bLogChanges As Boolean
    Dim vTables As Variant
    Dim i As Integer
    
    
    If VBA.Len(Me.tb_companyhistorypath.Text) = 0 Then
        Call Lime.MessageBox("File path to Exported company history is required")
        Exit Sub
    End If
    
    If VBA.Len(Me.tb_projecthistorypath.Text) = 0 Then
        Call Lime.MessageBox("File path to Exported project history is required")
        Exit Sub
    End If
    
    
    If VBA.Len(Me.tb_easydatabasepath.Text) > 0 Then
        Application.MousePointer = 11
        bContinue = True
        vTables = VBA.Split(EasyToPro.cEASYTABLES, ";")
        For i = LBound(vTables) To UBound(vTables)
            If bContinue = True Then
                If VBA.Len(vTables(i)) > 0 Then
                    'bContinue = GetEasyTable(VBA.CStr(vTables(i)), tb_easydatabasepath, Me.lb_progress, IIf(check_documentpath.Value, tb_documentpath, ""))
                    bContinue = GetEasyTable(VBA.CStr(vTables(i)), tb_easydatabasepath, Me.lb_progress)
                End If
            End If
        Next i
        
        bLogChanges = Me.check_logchanges.Value
        
        If bContinue = True Then
            Me.lb_progress.Caption = Lime.FormatString("Creating table EASY__FIELDMAPPING")
            bContinue = EasyToPro.CreateEasyFieldMapping()
        End If
        If bContinue = True Then
            Me.lb_progress.Caption = Lime.FormatString("Adding super fields to table EASY__FIELDMAPPING")
            bContinue = EasyToPro.AddSuperFieldsToEasyFieldMapping(bLogChanges)
        End If
        If bContinue = True Then
            Me.lb_progress.Caption = Lime.FormatString("Creating table EASY__OPTIONMAPPING")
            bContinue = EasyToPro.CreateEasyOptionMapping(bLogChanges)
        End If
        
'        If bContinue = True Then
'            Me.lb_progress.Caption = Lime.FormatString("Splitting History blob")
'            bContinue = EasyToPro.PrepareHistory(Me.lb_progress)
'        End If
        
        If bContinue = True Then
            Me.lb_progress.Caption = Lime.FormatString("Importing Exported History Files")
            bContinue = EasyToPro.PrepareHistory(Me.lb_progress, Me.tb_companyhistorypath, Me.tb_projecthistorypath)
        End If
        
        If bContinue = True Then
            Me.lb_progress.Caption = Lime.FormatString("Validating Easy Data")
            bContinue = EasyToPro.ValidateEasyData
        End If
        
        Me.lb_progress.Caption = ""
    
       
        Call SetUpForm
       
        If bContinue = True Then
            Call Lime.MessageBox("Data from LIME Easy were loaded successfully!", vbInformation)
        Else
            Call Lime.MessageBox("Something went wrong while loading data from LIME Easy. Please act on preceding error messages and try again.")
        End If

        Application.MousePointer = 0
    Else
        Application.MousePointer = 0
        Call Lime.MessageBox("%1 is required", VBA.vbInformation, Me.lb_easydatabasepath.Caption)
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_loadeasydata_Click")
End Sub

Private Sub btn_loadoptions_Click()
    On Error GoTo Errorhandler
    Call LoadOptionList
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_loadoptions_Click")
End Sub

Private Sub LoadOptionList()
    On Error GoTo Errorhandler
    Me.frm_options.Visible = False
    
    Call ClearOptionMapping

    
    Call EasyToPro.LoadEasyOptions(m_idfieldmapping, Me.lv_options)
    If lv_options.ListItems.Count > 0 Then
        Me.frm_options.Visible = True
        Me.lv_options.Left = 8
        Me.lv_options.Top = 8
    End If
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.LoadOptionList")
End Sub

Private Sub LoadValidationError()
    On Error GoTo Errorhandler
    Dim oDictionary As Scripting.Dictionary
'    Me.frm_validationerror.Visible = False
    Call EasyToPro.ListValidationError(m_idfieldmapping, Me.lv_validationerror)
'    If lv_validationerror.ListItems.Count > 0 Then
'        Me.frm_validationerror.Visible = True
'    End If
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.LoadValidationError")
End Sub

Private Sub btn_save_Click()
    On Error GoTo Errorhandler
    Dim sProTable As String
    
    If VBA.Len(VBA.Trim(Me.tb_profieldname.Text)) = 0 Then
        Call Lime.MessageBox("%1 is required", VBA.vbInformation, Me.lb_profieldname.Caption)
        Exit Sub
    End If
    
    sProTable = GetActiveProTableName
    If sProTable = "" Then
        Call Lime.MessageBox("Unknown Lime Pro Table, Aborted!", VBA.vbInformation)
        Exit Sub
    End If
    
    If ((m_profieldnamebeforechange = "") Or (m_idfieldmapping < 1)) Then
        Call Lime.MessageBox("Unknown value before change, Aborted!", VBA.vbInformation)
        Exit Sub
    End If
    
    
    ' Fix proposed value
    Dim proposedValueToUse As String
    If Not Me.tb_proposedvalue.Visible Then
        proposedValueToUse = ""
        Me.tb_proposedvalue.Text = ""
    Else
        proposedValueToUse = Me.tb_proposedvalue.Text
    End If
    
    If True = EasyToPro.SaveFieldChangesEasyFieldMapping(m_idfieldmapping, check_active.Value, tb_profieldname.Text, tb_localname_sv.Text, tb_localname_en_us.Text, tb_localname_no.Text, tb_localname_fi.Text, tb_localname_da.Text, proposedValueToUse) Then
        If (m_profieldnamebeforechange <> Me.tb_profieldname.Text) Then
            Call EasyToPro.ResetOptionMapping(m_idfieldmapping)
        End If
        'Call ResetSuperFieldMapping
        m_profieldnamebeforechange = Me.tb_profieldname.Text
        Call EasyToPro.LoadEasyFields(mp_tables.SelectedItem.Name, lv_superfields, VBA.CStr(m_idfieldmapping))
        Call LoadOptionList
        Call LoadValidationError
        Call EasyToPro.ValidationRequiredFields(lv_validaterequired, "")
    Else
        Call Lime.MessageBox("Failed to save changes")
    End If

    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_save_Click")
End Sub

Private Sub ClearOptionMapping()
    On Error GoTo Errorhandler
    
    Call lv_options.ListItems.Clear
    m_idoptionmapping = 0
    Me.tb_easyoptionstring.Text = ""
    Me.cb_prooption.Clear
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.ClearOptionMapping")
End Sub

Private Sub ClearFieldMapping()
    On Error GoTo Errorhandler
    
    Call lv_superfields.ListItems.Clear
    m_idfieldmapping = 0
    m_idoptionmapping = 0
    m_profieldnamebeforechange = ""
    
    Me.check_active.Value = False
    Me.tb_profieldname.Text = ""
    Me.tb_localname_sv.Text = ""
    Me.tb_localname_en_us.Text = ""
    Me.tb_localname_no.Text = ""
    Me.tb_localname_fi.Text = ""
    Me.tb_localname_da.Text = ""
    Me.frm_options.Visible = False
    Me.frm_field.Visible = False
    Me.frm_validationerror.Visible = False
    Call Me.lv_validationerror.ListItems.Clear
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.ClearFieldMapping")
End Sub

Private Sub btn_SaveMapping_Click()
    On Error GoTo Errorhandler
    
    Dim strFileName As String
    strFileName = SaveSingleFile("XML-file (*.xml)|*.xml")
    
    If strFileName <> "" Then
        Dim strFullXML As String
        strFullXML = "[BEGIN FIELDMAPPING]" + vbNewLine

        Dim oProc As LDE.Procedure
        Set oProc = Database.Procedures.Lookup("csp_easytopro_getfieldmappingxml", lkLookupProcedureByName)
        If Not oProc Is Nothing Then
            oProc.Execute (False)
            strFullXML = strFullXML + oProc.result
            strFullXML = strFullXML + vbNewLine + "[END FIELDMAPPING]" + vbNewLine + "[BEGIN OPTIONMAPPING]" + vbNewLine
            
            Set oProc = Database.Procedures.Lookup("csp_easytopro_getoptionmappingxml", lkLookupProcedureByName)
            If Not oProc Is Nothing Then
                oProc.Execute (False)
                strFullXML = strFullXML + oProc.result
                strFullXML = strFullXML + vbNewLine + "[END OPTIONMAPPING]"
                Open strFileName For Output As #1
                Print #1, strFullXML
                Close #1
            Else
                Call Lime.MessageBox("The required procedure csp_easytopro_getoptionmappingxml is missing", VBA.vbExclamation)
            End If
        Else
            Application.MousePointer = 0
            Call Lime.MessageBox("The required procedure csp_easytopro_getfieldmappingxml is missing", VBA.vbExclamation)
        End If
        
    End If

    strFullXML = ""
    strFileName = ""
   
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_SaveMapping_Click")
End Sub

Private Sub btn_saveoption_Click()
    On Error GoTo Errorhandler
    If cb_prooption.ListIndex > -1 Then
        Call EasyToPro.UpdateOptionMapping(m_idoptionmapping, m_idfieldmapping, VBA.CLng(Me.cb_prooption.List(Me.cb_prooption.ListIndex, 1)))
        Call LoadOptionList
    End If
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.btn_saveoption_Click")
End Sub


Private Sub check_archive_Click()
    On Error GoTo Errorhandler
    
    Call TableChanges(Me.check_archive, Me.tb_archive)
   
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_archive_Click")
End Sub

Private Sub TableChanges(ByRef oCheck As MSForms.CheckBox, ByRef oTextBox As MSForms.TextBox)
    On Error GoTo Errorhandler
    Dim bSuccess As Boolean
    Dim bChecked As Boolean
    Dim sText As String
    
    If m_disableSave = True Then
        Exit Sub
    End If
    
    sText = Me.tb_contact.Text
    bChecked = Me.check_contact.Value
    
    bSuccess = False
    If oCheck.Value = True Then
        If VBA.Len(oTextBox.Text) = 0 Then
            Call Lime.MessageBox("Pro table name is mandatory", VBA.vbInformation)
            oCheck.Value = False
            Exit Sub
        End If
    End If
    
    Me.lb_progress.Caption = Lime.FormatString("Updating easy__fieldmapping for table %1", Me.mp_tables.SelectedItem.Name)
    Call ClearFieldMapping
    Call ClearOptionMapping
    bSuccess = EasyToPro.SaveTableChangesEasyFieldMapping(mp_tables.SelectedItem.Name, oTextBox.Text, oCheck.Value)
    If bSuccess = True Then
    '2015-03-02 JSP: Changing of table-name disabled due to problems with creating relations when not using standard-tables
'        If oCheck.Value = True Then
'            oTextBox.Enabled = False
'        Else
'            oTextBox.Enabled = True
'        End If
    Else
        oTextBox.Enabled = Not oTextBox.Enabled
        oCheck.Value = Not oCheck.Value
    End If
    If oCheck.Value = True Then
        Me.lb_progress.Caption = Lime.FormatString("Loading fields for table %1", Me.mp_tables.SelectedItem.Name)
        Call EasyToPro.LoadEasyFields(mp_tables.SelectedItem.Name, lv_superfields) 'LoadXML(mp_tables.SelectedItem.Name, lv_superfields)
        Call EasyToPro.ValidationRequiredFields(lv_validaterequired, mp_tables.SelectedItem.Name)
    End If
    Me.lb_progress.Caption = ""
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.TableChanges")
End Sub

Private Sub check_contact_Click()
    On Error GoTo Errorhandler
    Call TableChanges(Me.check_contact, Me.tb_contact)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_contact_Click")
End Sub

'Private Sub check_documentpath_Click()
'On Error GoTo Errorhandler
'    If check_documentpath.Value = True Then
'        tb_documentpath.Enabled = True
'        btn_documentpath.Enabled = True
'    Else
'        tb_documentpath.Enabled = False
'        btn_documentpath.Enabled = False
'    End If
'Exit Sub
'Errorhandler:
'    Call UI.ShowError("FormEasyToPro.check_documentpath_Click")
'End Sub

Private Sub check_history_Click()
    On Error GoTo Errorhandler
    
    Call TableChanges(Me.check_history, Me.tb_history)
    
    
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_history_Click")
End Sub

Private Sub check_project_Click()
    On Error GoTo Errorhandler
   
    Call TableChanges(Me.check_project, Me.tb_project)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_project_Click")
End Sub

Private Sub check_refs_Click()
    On Error GoTo Errorhandler
   
    Call TableChanges(Me.check_refs, Me.tb_refs)
      
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_refs_Click")
End Sub

Private Sub check_time_Click()
    On Error GoTo Errorhandler
    
    Call TableChanges(Me.check_time, Me.tb_time)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_time_Click")
End Sub

Private Sub check_todo_Click()
    On Error GoTo Errorhandler
   
    Call TableChanges(Me.check_todo, Me.tb_todo)
    
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_todo_Click")
End Sub

Private Function GetActiveProTableName() As String
    On Error GoTo ErroHandler
    Dim sProTableName As String
    sProTableName = ""
    
    If Not Me.mp_tables.SelectedItem Is Nothing Then
        Select Case mp_tables.SelectedItem.Name
            Case cCONTACT:
                If Me.check_contact.Value = True Then
                    sProTableName = Me.tb_contact.Text
                End If
            Case cREFS:
                If Me.check_refs.Value = True Then
                    sProTableName = Me.tb_refs.Text
                End If
            Case cPROJECT:
                If Me.check_project.Value = True Then
                    sProTableName = Me.tb_project.Text
                End If
            Case cTIME:
                If Me.check_time.Value = True Then
                    sProTableName = Me.tb_time.Text
                End If
            Case cHISTORY:
                If Me.check_history.Value = True Then
                    sProTableName = Me.tb_history.Text
                End If
            Case cTODO:
                If Me.check_todo.Value = True Then
                    sProTableName = Me.tb_todo.Text
                End If
            Case cARCHIVE:
                If Me.check_archive.Value = True Then
                    sProTableName = Me.tb_archive.Text
                End If
            Case cUSER:
                If Me.check_user.Value = True Then
                    sProTableName = Me.tb_user.Text
                End If
        End Select
    End If
    
    GetActiveProTableName = sProTableName
    Exit Function
ErroHandler:
    GetActiveProTableName = ""
    Call UI.ShowError("FormEasyToPro.GetActiveProTableName")
End Function


Public Sub FillOptions(ByRef Combo As MSForms.ComboBox, ByRef oOptions As LDE.options, Optional ByVal sDefaultid As String = "§§", Optional ByRef dicExcludeList As Scripting.Dictionary)
    On Error GoTo Errorhandler
    
    Dim oOption As LDE.Option
    Dim bAdd As Boolean
    Dim i As Integer
    Combo.Clear
    
    
    With Combo
        For Each oOption In oOptions
            bAdd = True
            If Not dicExcludeList Is Nothing Then
                If dicExcludeList.Exists(oOption.key) Then
                    bAdd = False
                End If
            End If
            
            If bAdd Then
                .AddItem oOption.Text
                .List(.ListCount - 1, 1) = oOption.Value
                
                'Om det skickats med ett standardvärde
                If VBA.StrComp(sDefaultid, "§§", VBA.vbTextCompare) <> 0 And VBA.CStr(oOption.Value) = sDefaultid Then
                    .ListIndex = .ListCount - 1
                    .Tag = .ListIndex
                End If
            End If
        Next oOption
    End With
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.FillOptions")
End Sub

Private Sub check_user_Click()
On Error GoTo Errorhandler
    
    Call TableChanges(Me.check_user, Me.tb_user)
    
  
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.check_user_Click")
End Sub



Private Sub lv_options_Click()
 On Error GoTo Errorhandler
    Dim sIdString As String
    Dim oOptions As LDE.options
    Dim sProTable As String
    Dim sProField As String
    
    If Not lv_options.SelectedItem Is Nothing Then
        sIdString = lv_options.SelectedItem.SubItems(2)
        Me.tb_easyoptionstring.Text = lv_options.SelectedItem.SubItems(1)
        
        m_idoptionmapping = VBA.CLng(lv_options.SelectedItem.Tag)
        
        sProTable = lv_options.SelectedItem.SubItems(4)
        sProField = lv_options.SelectedItem.SubItems(5)
        If Application.Database.Classes.Exists(sProTable) Then
            If Application.Database.Classes(sProTable).Fields.Exists(sProField) Then
                Set oOptions = Application.Database.Classes(sProTable).Fields(sProField).options
                
                If Not oOptions Is Nothing Then
                    Call FillOptions(Me.cb_prooption, oOptions, sIdString)
                End If
            End If
        End If
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.lv_options_Click")
End Sub

'Private Sub lv_options_DblClick()
'    On Error GoTo ErrorHandler
'    Dim sIdString As String
'    Dim oOptions As LDE.options
'    Dim sProTable As String
'    Dim sProField As String
'
'    If Not lv_options.SelectedItem Is Nothing Then
'        sIdString = lv_options.SelectedItem.SubItems(2)
'        Me.tb_easyoptionstring.Text = lv_options.SelectedItem.SubItems(1)
'
'        m_idoptionmapping = VBA.CLng(lv_options.SelectedItem.Tag)
'
'        sProTable = lv_options.SelectedItem.SubItems(4)
'        sProField = lv_options.SelectedItem.SubItems(5)
'        If Application.Database.Classes.Exists(sProTable) Then
'            If Application.Database.Classes(sProTable).Fields.Exists(sProField) Then
'                Set oOptions = Application.Database.Classes(sProTable).Fields(sProField).options
'
'                If Not oOptions Is Nothing Then
'                    Call FillOptions(Me.cb_prooption, oOptions, sIdString)
'                End If
'            End If
'        End If
'    End If
'    Exit Sub
'ErrorHandler:
'    Call UI.ShowError("FormEasyToPro.lv_options_DblClick")
'End Sub

Private Sub lv_superfields_Click()
    On Error GoTo Errorhandler
    
    If Not lv_superfields.SelectedItem Is Nothing Then
        m_idfieldmapping = lv_superfields.SelectedItem.Tag
        m_profieldnamebeforechange = lv_superfields.SelectedItem.SubItems(7)
        Me.tb_profieldname = m_profieldnamebeforechange 'profieldname
        Me.tb_localname_sv = lv_superfields.SelectedItem.SubItems(8) 'localname_sv
        Me.tb_localname_en_us = lv_superfields.SelectedItem.SubItems(9) 'localname_en_us
        Me.tb_localname_no = lv_superfields.SelectedItem.SubItems(10) 'localname_no
        Me.tb_localname_fi = lv_superfields.SelectedItem.SubItems(11) 'localname_fi
        Me.tb_localname_da = lv_superfields.SelectedItem.SubItems(12) 'localname_da
        Me.tb_proposedvalue = lv_superfields.SelectedItem.SubItems(13) 'proposedvalue
        Me.check_active.Value = IIf(lv_superfields.SelectedItem.SubItems(2) = "1", True, False)
        Me.frm_field.Visible = True
        Me.frm_validationerror.Visible = True
        Me.lv_validationerror.Left = 8
        Me.lv_validationerror.Top = 8
        
        Call LoadOptionList
        Call HandleFieldEdit
        Call LoadValidationError
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.lv_superfields_Click")
End Sub

'Private Sub lv_superfields_DblClick()
'    On Error GoTo ErrorHandler
'
'    If Not lv_superfields.SelectedItem Is Nothing Then
'        m_idfieldmapping = lv_superfields.SelectedItem.Tag
'        m_profieldnamebeforechange = lv_superfields.SelectedItem.SubItems(7)
'        Me.tb_profieldname = m_profieldnamebeforechange 'profieldname
'        Me.tb_localname_sv = lv_superfields.SelectedItem.SubItems(8) 'localname_sv
'        Me.tb_localname_en_us = lv_superfields.SelectedItem.SubItems(9) 'localname_en_us
'        Me.tb_localname_no = lv_superfields.SelectedItem.SubItems(10) 'localname_no
'        Me.tb_localname_fi = lv_superfields.SelectedItem.SubItems(11) 'localname_fi
'        Me.tb_localname_da = lv_superfields.SelectedItem.SubItems(12) 'localname_da
'        Me.tb_proposedvalue = lv_superfields.SelectedItem.SubItems(13) 'proposedvalue
'        Me.check_active.Value = IIf(lv_superfields.SelectedItem.SubItems(2) = "1", True, False)
'
'        Call LoadOptionList
'        Call HandleFieldEdit
'        Call LoadValidationError
'    End If
'    Exit Sub
'ErrorHandler:
'    Call UI.ShowError("FormEasyToPro.lv_superfields_DblClick")
'End Sub

Private Sub mp_tables_Change()
    On Error GoTo Errorhandler
    Dim bLoadXML As Boolean
    bLoadXML = False
    Me.lb_progress.Caption = mp_tables.SelectedItem.Name
    
    Call ClearFieldMapping
    Call ClearOptionMapping
    Call HandleForm
    
    If Not mp_tables.SelectedItem Is Nothing Then
        Select Case mp_tables.SelectedItem.Name
            Case cCONTACT:
                If Me.check_contact.Value = True Then
                    bLoadXML = True
                    Me.tb_contact.Enabled = False
                    
                End If
            Case cREFS:
                If Me.check_refs.Value = True Then
                    bLoadXML = True
                    Me.tb_refs.Enabled = False
                    
                End If
            Case cPROJECT:
                If Me.check_project.Value = True Then
                    bLoadXML = True
                    Me.tb_project.Enabled = False
                    
                End If
            Case cTIME:
                If Me.check_time.Value = True Then
                    bLoadXML = True
                    Me.tb_time.Enabled = False
                    
                End If
            Case cHISTORY:
                If Me.check_history.Value = True Then
                    bLoadXML = True
                    Me.tb_history.Enabled = False
                    
                End If
            Case cTODO:
                If Me.check_todo.Value = True Then
                    bLoadXML = True
                    Me.tb_todo.Enabled = False
                    
                End If
            Case cARCHIVE:
                If Me.check_archive.Value = True Then
                    bLoadXML = True
                    Me.tb_archive.Enabled = False
                    
                End If
            Case cUSER:
                If Me.check_user.Value = True Then
                    bLoadXML = True
                    Me.tb_user.Enabled = False
                    
                End If
        End Select
        
        Call EasyToPro.ValidationRequiredFields(lv_validaterequired, "")
        
        If bLoadXML = True Then
            Me.lb_progress.Caption = Lime.FormatString("Loading fields for table %1", Me.mp_tables.SelectedItem.Name)
            Call EasyToPro.LoadEasyFields(mp_tables.SelectedItem.Name, lv_superfields) 'LoadXML(mp_tables.SelectedItem.Name, lv_superfields)
            
        End If
         Me.lb_progress.Caption = ""
    End If
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.mp_tables_Change")
End Sub

Private Sub tb_profieldname_Change()
    On Error GoTo Errorhandler

    Call HandleFieldEdit
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_profieldname_Change")
End Sub

Private Sub tb_profieldname_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_profieldname, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_profieldname_KeyPress")
End Sub

Private Sub HandleFieldEdit()
    On Error GoTo Errorhandler
    Dim bExistingField As Boolean
    Dim bRequired As Boolean
    
    bRequired = False
    bExistingField = False
   
   Call ProFieldExistsRequired(bExistingField, bRequired, GetActiveProTableName, Me.tb_profieldname.Text)
    
    
    Me.lb_existPro.Visible = bExistingField
    Me.tb_localname_sv.Enabled = Not bExistingField
    Me.tb_localname_en_us.Enabled = Not bExistingField
    Me.tb_localname_no.Enabled = Not bExistingField
    Me.tb_localname_fi.Enabled = Not bExistingField
    Me.tb_localname_da.Enabled = Not bExistingField
    
    If Not bRequired Then
        Me.tb_proposedvalue.Visible = False
        Me.lb_proposedvalue.Visible = False
    Else
        Me.tb_proposedvalue.Visible = True
        Me.lb_proposedvalue.Visible = True
    End If
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.HandleFieldEdit")
End Sub

Private Sub tb_contact_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_contact, KeyAscii)
   
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_contact_KeyPress")
End Sub

Private Sub tb_refs_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_refs, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_refs_KeyPress")
End Sub

Private Sub tb_project_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_project, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_project_KeyPress")
End Sub

Private Sub tb_time_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_time, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_time_KeyPress")
End Sub

Private Sub tb_history_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_history, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_history_KeyPress")
End Sub

Private Sub tb_todo_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_todo, KeyAscii)
     
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_todo_KeyPress")
End Sub

Private Sub tb_archive_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_archive, KeyAscii)
    
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_archive_KeyPress")
End Sub


Private Sub tb_localname_sv_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProLocalnameInput(tb_localname_sv, KeyAscii)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_localname_sv_KeyPress")
End Sub


Private Sub tb_localname_en_us_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProLocalnameInput(tb_localname_en_us, KeyAscii)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_localname_en_us_KeyPress")
End Sub

Private Sub tb_localname_no_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProLocalnameInput(tb_localname_fi, KeyAscii)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_localname_no_KeyPress")
End Sub

Private Sub tb_localname_fi_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProLocalnameInput(tb_localname_fi, KeyAscii)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_localname_fi_KeyPress")
End Sub

Private Sub tb_localname_da_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
    On Error GoTo Errorhandler
    Call ValidateLimeProLocalnameInput(tb_localname_da, KeyAscii)
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_localname_da_KeyPress")
End Sub


Private Sub tb_user_KeyPress(ByVal KeyAscii As MSForms.ReturnInteger)
On Error GoTo Errorhandler
    Call ValidateLimeProFieldInput(Me.tb_user, KeyAscii)
    
 Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.tb_user_KeyPress")
End Sub

Private Sub UserForm_Initialize()
    On Error GoTo Errorhandler

    m_idfieldmapping = 0
    m_idoptionmapping = 0
    m_profieldnamebeforechange = ""

    Me.cb_language.AddItem ("sv")
    Me.cb_language.AddItem ("en_us")
    Me.cb_language.AddItem ("no")
    Me.cb_language.AddItem ("fi")
    Me.cb_language.AddItem ("da")
    Me.cb_language.ListIndex = 0
    '2015-07-22 JSP: Header for localname_da must be added here manually since the listview-control
    'was created in another environment and I can't edit the columns
    Call Me.lv_superfields.ColumnHeaders.Add(13, "LocalName_DA", "LocalName_DA")
    
    Call SetUpForm
 
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.UserForm_Initialize")
End Sub
Private Sub SetUpForm()
    On Error GoTo Errorhandler
    Dim sTable As String
    Dim bActive As Boolean
    
    m_disableSave = True
    If (EasyToPro.CheckRequiredTables(False) = True) Then
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cCONTACT, sTable, bActive)
        Me.tb_contact.Text = sTable
        Me.check_contact.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cREFS, sTable, bActive)
        Me.tb_refs.Text = sTable
        Me.check_refs.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cPROJECT, sTable, bActive)
        Me.tb_project.Text = sTable
        Me.check_project.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cTIME, sTable, bActive)
        Me.tb_time.Text = sTable
        Me.check_time.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cHISTORY, sTable, bActive)
        Me.tb_history.Text = sTable
        Me.check_history.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cTODO, sTable, bActive)
        Me.tb_todo.Text = sTable
        Me.check_todo.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cARCHIVE, sTable, bActive)
        Me.tb_archive.Text = sTable
        Me.check_archive.Value = bActive
        
        sTable = ""
        bActive = False
        Call EasyToPro.LoadTableData(cUSER, sTable, bActive)
        Me.tb_user.Text = sTable
        Me.check_user.Value = bActive
        
        Me.frm_mapping.Visible = True
        Me.frm_step3.Visible = True
        Me.frm_step4.Visible = True
        Call EasyToPro.ValidationRequiredFields(lv_validaterequired, "")
        Call HandleForm
        Call ClearFieldMapping
        Call ClearOptionMapping
        Call EasyToPro.LoadEasyFields(mp_tables.SelectedItem.Name, lv_superfields)
    Else
        
        Me.frm_mapping.Visible = False
        Me.frm_step3.Visible = False
        Me.frm_step4.Visible = False
        
    End If
    m_disableSave = False
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.SetUpForm")
End Sub

Private Sub HandleForm()
    On Error GoTo Errorhandler
    Dim bShow As Boolean
    bShow = True
    Me.frm_field.Enabled = bShow
    Me.frm_options.Enabled = bShow
    Me.lv_validationerror.Enabled = bShow
    Me.lv_superfields.Enabled = bShow
    Exit Sub
Errorhandler:
    Call UI.ShowError("FormEasyToPro.HandleForm")
End Sub


Private Function FixTimestamp() As Boolean
On Error GoTo Errorhandler
    Dim bOk As Boolean

    bOk = True
    If bOk = True Then
        If check_contact.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Fix createdtime and timestamp for table %1", tb_contact.Text)
            If bOk = True Then
                bOk = EasyToPro.UpdateTimestamp(cCONTACT)
            End If
        End If
    End If
    
    If bOk = True Then
        If check_refs.Value = True Then
           
            
            lb_progress.Caption = Lime.FormatString("Fix createdtime and timestamp for table %1", tb_refs.Text)
            If bOk = True Then
                bOk = EasyToPro.UpdateTimestamp(cREFS)
            End If
        End If
    End If
    If bOk = True Then
        If check_project.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Fix createdtime and timestamp for table %1", tb_project.Text)
            If bOk = True Then
                bOk = EasyToPro.UpdateTimestamp(cPROJECT)
            End If
        End If
    End If
    
    
    If bOk = True Then
        If check_archive.Value = True Then
            
            
            lb_progress.Caption = Lime.FormatString("Fix createdtime and timestamp for table %1", tb_archive.Text)
            If bOk = True Then
                bOk = EasyToPro.UpdateTimestamp(cARCHIVE)
            End If
        End If
    End If
    
    lb_progress.Caption = ""
    FixTimestamp = bOk
    Exit Function
Errorhandler:
    FixTimestamp = False
    Call UI.ShowError("FormEasyToPro.FixTimestamp")
End Function

Private Function SaveSingleFile(sFileType As String) As String
    On Error GoTo Errorhandler
    Dim oFileSaveDialog As New LCO.FileSaveDialog
    Dim sPath As String
    
    sPath = ""
    oFileSaveDialog.Filter = sFileType
 
    If (oFileSaveDialog.show = 1) Then
        sPath = oFileSaveDialog.FileName
    End If

    SaveSingleFile = sPath
    Exit Function
Errorhandler:
    SaveSingleFile = ""
    Call UI.ShowError("Actionpad_Campaign.SaveSingleFile")
End Function


'Private Function MappedToExistingField() As EnumExistingField
'    On Error GoTo ErrorHandler
'    Dim sProTableName As String
'    Dim sProFieldName As String
'    Dim eExisting As EnumExistingField
'
'    eExisting = Unknown
'
'    sProTableName = GetActiveProTableName
'    sProFieldName = Me.tb_profieldname.Text
'
'    If ((VBA.Len(sProTableName) > 0) And (VBA.Len(sProFieldName) > 0)) Then
'        eExisting = NotExisting
'
'        If Application.Database.Classes.Exists(sProTableName) Then
'            If Application.Database.Classes(sProTableName).Fields.Exists(sProFieldName) Then
'                eExisting = Existing
'            End If
'        End If
'    End If
'
'    MappedToExistingField = eExisting
'
'    Exit Function
'ErrorHandler:
'    MappedToExistingField = Unknown
'    Call UI.ShowError("MappedToExistingField")
'End Function

'Private Sub lv_superfields_ItemClick(ByVal Item As MSComctlLib.ListItem)
' On Error GoTo ErrorHandler
'
'    If Not lv_superfields.SelectedItem Is Nothing Then
'        m_easyfieldid = lv_superfields.SelectedItem.Tag
'        Me.tb_profieldname = lv_superfields.SelectedItem.SubItems(5) 'protablename
'        Me.tb_localname_sv = lv_superfields.SelectedItem.SubItems(6) 'localname_sv
'        Me.tb_localname_en_us = lv_superfields.SelectedItem.SubItems(7) 'localname_en_us
'        Me.tb_localname_no = lv_superfields.SelectedItem.SubItems(8) 'localname_no
'        Me.tb_localname_fi = lv_superfields.SelectedItem.SubItems(9) 'localname_fi
'        Me.tb_localname_da = lv_superfields.SelectedItem.SubItems(10) 'localname_da
'        Me.check_active.Value = IIf(lv_superfields.SelectedItem.SubItems(1) = "1", True, False)
'
'    End If
'    Exit Sub
'ErrorHandler:
'    Call UI.ShowError("lv_superfields_ItemClick")
'End Sub
