Attribute VB_Name = "CreateDocuments"
Option Explicit


Public Sub CreateDocuments()
On Error GoTo ErrorHandler
    Dim oExplorer As Lime.Explorer
    Dim oItem As Lime.ExplorerItem
    Dim strTemplate As String
    Dim strDocumenttype As String
    Set oExplorer = Application.ActiveExplorer
    If oExplorer.Selection.count = 0 Then
        Call Application.MessageBox("Du måste välja minst en post att masskapa dokument på.")
        Exit Sub
    End If
    
    Dim frmDocuments As New FormAddDocuments
    
    Call frmDocuments.Show
    
    If Not frmDocuments Is Nothing Then
        If frmDocuments.Closed = False Then
            strDocumenttype = frmDocuments.SelectedDocumentType
            strTemplate = frmDocuments.SelectedTemplate
        Else
            Unload frmDocuments
            Exit Sub
        End If
    End If
    
    If strTemplate = "" Or strDocumenttype = "" Then
        Exit Sub
    End If
    
    Dim oDocumentRecord As LDE.Record
    Dim oSourceRecords As New LDE.Records
    Dim oSourceRecord As LDE.Record
    Dim oFilter As New LDE.Filter
    Dim oTemplate As LDE.DocumentTemplate
    Set oTemplate = Database.Templates.Lookup(strTemplate, lkLookupDocumentTemplateByName)
    
    If oTemplate Is Nothing Then
        Call Application.MessageBox("Det gick inte att hitta den valda mallen.")
        Exit Sub
    End If
    
    Call oFilter.AddCondition("id" + oExplorer.Class.Name, lkOpIn, oExplorer.Selection.Pool, lkConditionTypePool)
    Call oSourceRecords.Open(Database.Classes(oExplorer.Class.Name), oFilter, Array("participant", "company", "business", "campaign"))
    Dim oDocument As LDE.Document
    Dim oBatch As New LDE.Batch
    Set oBatch.Database = Application.Database
    Dim frmProgress As New FormProgress
    Dim ctr As Long
    ctr = 1
    
    frmProgress.Show
    For Each oSourceRecord In oSourceRecords
        Set oDocumentRecord = New LDE.Record
        frmProgress.Title = "Skapar dokument " & VBA.CStr(ctr) & "/" & VBA.CStr(oSourceRecords.count)
        frmProgress.Progress = ctr / oSourceRecords.count
        Call oDocumentRecord.Open(Database.Classes("document"))
        
        oDocumentRecord.Value("type") = Database.Classes("document").Fields("type").Options.Lookup(strDocumenttype, lkLookupOptionByText).Value
        oDocumentRecord.Value("comment") = oTemplate.Name
        
        'Set relationfield values
        Call SetRecordValue(oDocumentRecord, oSourceRecord.Class.Name, oSourceRecord.ID)
        If oSourceRecord.Fields.Exists("campaign") Then
            Call SetRecordValue(oDocumentRecord, "campaign", oSourceRecord.Value("campaign"))
        End If
        If oSourceRecord.Fields.Exists("company") Then
            Call SetRecordValue(oDocumentRecord, "company", oSourceRecord.Value("company"))
        End If
        
        Set oDocument = Application.CreateDocumentFromTemplate(oTemplate, oSourceRecord, , "document", False)
        oDocumentRecord.Value("document") = oDocument
        Call oDocumentRecord.Update(oBatch)
        ctr = ctr + 1
    Next oSourceRecord
    
    frmProgress.Title = "Sparar dokumenten..."
    Call oBatch.Execute
    frmProgress.Hide
    Unload frmProgress
    Set frmProgress = Nothing
Exit Sub
ErrorHandler:
    If Not frmDocuments Is Nothing Then
        Unload frmDocuments
    End If
    If Not frmProgress Is Nothing Then
        Unload frmProgress
    End If
    Call UI.ShowError("CreateDocuments.CreateDocuments")
End Sub

Private Sub SetRecordValue(ByRef oRecord As LDE.Record, strFieldName As String, vValue As Variant)
    If oRecord.Fields.Exists(strFieldName) Then
        oRecord.Value(strFieldName) = vValue
    End If
    
End Sub

