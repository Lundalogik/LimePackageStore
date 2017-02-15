VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} FormAddDocuments 
   Caption         =   "Masskapa dokument"
   ClientHeight    =   3510
   ClientLeft      =   45
   ClientTop       =   390
   ClientWidth     =   3690
   OleObjectBlob   =   "FormAddDocuments.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "FormAddDocuments"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private m_SelectedTemplate As String
Private m_SelectedDocumentType As String
Private m_Folders As Scripting.Dictionary

Private m_Closed As Boolean

Public Property Get SelectedTemplate() As String
    SelectedTemplate = m_SelectedTemplate
End Property

Public Property Get Closed() As Boolean
    Closed = m_Closed
End Property

Public Property Get SelectedDocumentType() As String
    SelectedDocumentType = m_SelectedDocumentType
End Property

Private Sub btnClose_Click()
    m_Closed = True
    Me.Hide
End Sub

Private Sub btnOk_Click()
    If cbTemplates.text = "" Or cbDocumentType.text = "" Then
        Call Application.MessageBox("Du måste välja en mall och dokumenttyp.")
        Exit Sub
    End If
    If cbTemplates.text <> "" Then
        m_SelectedTemplate = cbTemplates.text
        Me.Hide
    End If
    If cbDocumentType.text <> "" Then
        m_SelectedDocumentType = cbDocumentType.text
        Me.Hide
    End If
End Sub

Private Sub cbFolders_Change()
    cbTemplates.Clear
    Dim strTemplate As Variant
    Dim strFolder As String
    For Each strTemplate In m_Folders(cbFolders.text)
        Call cbTemplates.AddItem(strTemplate)
    Next strTemplate
End Sub

Private Sub UserForm_Initialize()
    Call FormHelper.SetFormDefaultColors(Me)
    Dim oTemplate As LDE.DocumentTemplate
    Set m_Folders = New Scripting.Dictionary
    Dim oCollection As New VBA.Collection
    For Each oTemplate In Application.Database.Templates
        Debug.Print oTemplate.Category
        If Not m_Folders.Exists(oTemplate.Category) Then
            Set oCollection = New VBA.Collection
            Call m_Folders.Add(oTemplate.Category, oCollection)
            Call cbFolders.AddItem(oTemplate.Category)
        End If
        Call m_Folders(oTemplate.Category).Add(oTemplate.Name)
        
    Next
    
    Dim oOption As LDE.Option
    For Each oOption In Database.Classes("document").Fields("type").Options
        Call cbDocumentType.AddItem(oOption.text)
    Next oOption
    
    If cbFolders.ListCount > 0 Then
        cbFolders.ListIndex = 0
    End If
    
    
End Sub
'Abort closing the form if the user is closing the window
Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
    If CloseMode <> 1 Then
        Me.Hide
        Cancel = 1
        m_Closed = True
    End If
End Sub
