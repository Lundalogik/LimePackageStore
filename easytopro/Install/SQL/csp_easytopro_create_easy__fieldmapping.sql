CREATE PROCEDURE [dbo].[csp_easytopro_create_easy__fieldmapping]
    (
      @@result INT = 0 OUTPUT ,
      @@errormessage AS NVARCHAR(2048) = N'' OUTPUT
    )
AS 
    BEGIN
	-- FLAG_EXTERNALACCESS --
        SET NOCOUNT ON;
        DECLARE @xmltext NVARCHAR(MAX)
     
        DECLARE @xml XML
        DECLARE @transaction INT
    

	-- Set initial values
        SET @@result = 0
        SET @transaction = 0
        SET @xmltext = N'
        <tables>
  <table name="CONTACT" protable="company" transfertable="1">
    <field issuperfield="0" easyfieldid="company_name" easyfieldorder="-10" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Company Name" profieldname="name" localname_sv="Företagsnamn" localname_en_us="Company name" localname_no="Navn" localname_fi="Nimi" localname_da="Virksomhedsnavn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="company_suffix" easyfieldorder="-9" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Suffix" profieldname="suffix" localname_sv="Tillägg" localname_en_us="Suffix" localname_no="Suffix" localname_fi="Suffix" localname_da="Suffix" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_phone" easyfieldorder="-8" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Telephone" profieldname="phone" localname_sv="Telefon" localname_en_us="Phone" localname_no="Phone" localname_fi="Phone" localname_da="Phone" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_fax" easyfieldorder="-7" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Fax" profieldname="telefax" localname_sv="Fax" localname_en_us="Fax" localname_no="Fax" localname_fi="Fax" localname_da="Fax" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_address" easyfieldorder="-6" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Address" profieldname="address" localname_sv="Easy Adress" localname_en_us="Easy Adress" localname_no="Easy Adress" localname_fi="Easy Adress" localname_da="Easy Adress" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip1" easyfieldorder="-5" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip1" profieldname="postaladdress1" localname_sv="Postadress 1" localname_en_us="Postaladdress1" localname_no="Postaladdress1" localname_fi="Postaladdress1" localname_da="Postaladdress1" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip2" easyfieldorder="-4" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip2" profieldname="postaladdress2" localname_sv="Postadress 2" localname_en_us="Postaladdress2" localname_no="Postaladdress2" localname_fi="Postaladdress2" localname_da="Postaladdress2" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesbeforezip3" easyfieldorder="-3" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesbeforezip3" profieldname="postaladdress3" localname_sv="Postadress 3" localname_en_us="Postaladdress3" localname_no="Postaladdress3" localname_fi="Postaladdress3" localname_da="Postaladdress3" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_zipcode" easyfieldorder="-2" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="zipcode" profieldname="postalzipcode" localname_sv="Postnummer" localname_en_us="Zipcode" localname_no="Zipcode" localname_fi="Zipcode" localname_da="Zipcode" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_city" easyfieldorder="-2" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="city" profieldname="postalcity" localname_sv="Postort" localname_en_us="City" localname_no="City" localname_fi="City" localname_da="City" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesafterzip1" easyfieldorder="-1" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesafterzip1" profieldname="country" localname_sv="Land" localname_en_us="Country" localname_no="Country" localname_fi="Country" localname_da="Country" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="company_addresslinesafterzip2" easyfieldorder="0" easyfieldtype="0" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="addresslinesafterzip2" profieldname="addressline2afterzip" localname_sv="addressline2afterzip" localname_en_us="addressline2afterzip" localname_no="addressline2afterzip" localname_fi="addressline2afterzip" localname_da="addressline2afterzip" proposedvalue="" active="1"/>
  </table>
  <table name="REFS" protable="person" transfertable="1">
    <field issuperfield="0" easyfieldid="person_firstname" easyfieldorder="-9" easyfieldtype="1" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="firstname" profieldname="firstname" localname_sv="Förnamn" localname_en_us="Firstname" localname_no="Firstname" localname_fi="Firstname" localname_da="Firstname" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="person_lastname" easyfieldorder="-8" easyfieldtype="1" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="lastname" profieldname="lastname" localname_sv="Efternamn" localname_en_us="Lastname" localname_no="Lastname" localname_fi="Lastname" localname_da="Lastname" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="person_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
  </table>
  <table name="PROJECT" protable="deal" transfertable="1">
    <field issuperfield="0" easyfieldid="project_name" easyfieldorder="-10" easyfieldtype="2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Name" profieldname="name" localname_sv="Namn" localname_en_us="Name" localname_no="Navn" localname_fi="Nimi" localname_da="Navn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="project_done" easyfieldorder="-9" easyfieldtype="2" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Flags" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="project_description" easyfieldorder="-8" easyfieldtype="2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Description" profieldname="description" localname_sv="Beskrivning" localname_en_us="Description" localname_no="Description" localname_fi="Description" localname_da="Description" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="project_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
  </table>
  <table name="TIME" protable="" transfertable="0">
    <field issuperfield="0" easyfieldid="time_date" easyfieldorder="-10" easyfieldtype="-3" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Date" localname_en_us="Date" localname_no="Date" localname_fi="Date" localname_da="Date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_description" easyfieldorder="-9" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Description" profieldname="description" localname_sv="Specifikation" localname_en_us="Specification" localname_no="Specification" localname_fi="Specification" localname_da="Specification" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_done" easyfieldorder="-8" easyfieldtype="-3" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Done" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_type" easyfieldorder="-7" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Type" profieldname="type" localname_sv="Typ" localname_en_us="Type" localname_no="Type" localname_fi="Type" localname_da="Type" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_tax" easyfieldorder="-6" easyfieldtype="-3" easydatatype="0" easydatatypedata="32" easydatatypetext="INT(FLOAT)" easyfieldname="Tax" profieldname="rate" localname_sv="Taxa" localname_en_us="Tax" localname_no="Tax" localname_fi="Tax" localname_da="Tax" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_minutes" easyfieldorder="-5" easyfieldtype="-3" easydatatype="0" easydatatypedata="32" easydatatypetext="INT" easyfieldname="Minutes" profieldname="minutes" localname_sv="Minuter" localname_en_us="Minutes" localname_no="Minutes" localname_fi="Minutes" localname_da="Minutes" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="time_projecttext" easyfieldorder="-4" easyfieldtype="-3" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Project" profieldname="projecttext" localname_sv="Projekt(Text)" localname_en_us="Project(Text)" localname_no="Project(Text)" localname_fi="Project(Text)" localname_da="Project (Text)" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="time_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="time_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table> 
  <table name="HISTORY" protable="history"  transfertable="1">
    <field issuperfield="0" easyfieldid="history_date" easyfieldorder="-10" easyfieldtype="-2" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Datum" localname_en_us="Date" localname_no="Date" localname_fi="Date" localname_da="Date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="history_type" easyfieldorder="-9" easyfieldtype="-2" easydatatype="2" easydatatypedata="3" easydatatypetext="OPTION" easyfieldname="Type" profieldname="type" localname_sv="Aktivitetstyp" localname_en_us="Type" localname_no="Type" localname_fi="Type" localname_da="Type" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="history_note" easyfieldorder="-8" easyfieldtype="-2" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Note" profieldname="note" localname_sv="Anteckningar" localname_en_us="Note" localname_no="Note" localname_fi="Note" localname_da="Note" proposedvalue="NOVALUEINEASY" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="history_relation_contact" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="history_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="history_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="deal" localname_sv="Affär" localname_en_us="Deal" localname_no="Tilbud" localname_fi="Projekti" localname_da="Projekt" proposedvalue="" active="1"/>
    <field relatedeasytable="TIME" issuperfield="2" easyfieldid="history_relation_time" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO TIME" easyfieldname="Time" profieldname="time" localname_sv="Time" localname_en_us="Time" localname_no="Time" localname_fi="Time" localname_da="Time" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="history_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <table name="TODO" protable="todo" transfertable="1">
    <field issuperfield="0" easyfieldid="todo_startdate" easyfieldorder="-10" easyfieldtype="-1" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Start date" profieldname="starttime" localname_sv="Start datum" localname_en_us="Start date" localname_no="Start date" localname_fi="Start date" localname_da="Start date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_enddate" easyfieldorder="-9" easyfieldtype="-1" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Stop date" profieldname="endtime" localname_sv="Slut datum" localname_en_us="End date" localname_no="End date" localname_fi="End date" localname_da="End date" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_subject" easyfieldorder="-8" easyfieldtype="-1" easydatatype="3" easydatatypedata="2" easydatatypetext="TEXT OPTION" easyfieldname="Description" profieldname="subject" localname_sv="Ämne" localname_en_us="Subject" localname_no="Subject" localname_fi="Subject" localname_da="Subject" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="todo_done" easyfieldorder="-7" easyfieldtype="-1" easydatatype="1" easydatatypedata="0" easydatatypetext="YES/NO" easyfieldname="Done" profieldname="done" localname_sv="Klar" localname_en_us="Done" localname_no="Done" localname_fi="Done" localname_da="Done" proposedvalue="" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="todo_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="todo_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="todo_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="deal" localname_sv="Affär" localname_en_us="Deal" localname_no="Tilbud" localname_fi="Projekti" localname_da="Projekt" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="todo_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <!-- IMPORTANT TO HAVE easyfieldtype 6, 7 (FIELD FROM COMPANY DOCUMENT AND PROJECT DOCUMENT) BECAUSE WE NEED TO HAVE ALL FIELDTYPES LISTED-->
  <table name="ARCHIVE" protable="document" transfertable="1">
    <field issuperfield="0" easyfieldid="archive_date" easyfieldorder="-10" easyfieldtype="6" easydatatype="0" easydatatypedata="16" easydatatypetext="DATE" easyfieldname="Date" profieldname="date" localname_sv="Skapad datum LIME Easy" localname_en_us="Created date LIME Easy" localname_no="Created date LIME Easy" localname_fi="Created date LIME Easy" localname_da="Created date LIME Easy" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="archive_comment" easyfieldorder="-9" easyfieldtype="7" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Comment" profieldname="comment" localname_sv="Kommentar" localname_en_us="Comment" localname_no="Comment" localname_fi="Comment" localname_da="Comment" proposedvalue="NOVALUEINEASY" active="1"/>
    <field relatedeasytable="CONTACT" issuperfield="2" easyfieldid="archive_relation_contact" easyfieldorder="-3" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO CONTACT" easyfieldname="Company" profieldname="company" localname_sv="Företag" localname_en_us="Company" localname_no="Company" localname_fi="Company" localname_da="Company" proposedvalue="" active="1"/>
    <field relatedeasytable="REFS" issuperfield="2" easyfieldid="archive_relation_refs" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO REFS" easyfieldname="Person" profieldname="person" localname_sv="Person" localname_en_us="Person" localname_no="Person" localname_fi="Person" localname_da="Person" proposedvalue="" active="1"/>
    <field relatedeasytable="PROJECT" issuperfield="2" easyfieldid="archive_relation_project" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO PROJECT" easyfieldname="Project" profieldname="deal" localname_sv="Affär" localname_en_us="Deal" localname_no="Tilbud" localname_fi="Projekti" localname_da="Projekt" proposedvalue="" active="1"/>
    <field relatedeasytable="USER" issuperfield="2" easyfieldid="archive_relation_user" easyfieldorder="-7" easyfieldtype="-999" easydatatype="-999" easydatatypedata="-999" easydatatypetext="RELATION TO COWORKER" easyfieldname="Coworker" profieldname="coworker" localname_sv="Medarbetare" localname_en_us="Coworker" localname_no="Coworker" localname_fi="Coworker" localname_da="Coworker" proposedvalue="" active="1"/>
  </table>
  <table name="USER" protable="coworker" transfertable="1">
    <field issuperfield="0" easyfieldid="user_firstname" easyfieldorder="-10" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="firstname" profieldname="firstname" localname_sv="Förnamn" localname_en_us="First name" localname_no="Fornavn" localname_fi="Etunimi" localname_da="Navn" proposedvalue="NOVALUEINEASY" active="1"/>
    <field issuperfield="0" easyfieldid="user_lastname" easyfieldorder="-9" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="lastname" profieldname="lastname" localname_sv="Efternamn" localname_en_us="Last name" localname_no="Etternavn" localname_fi="Sukunimi" localname_da="Efternavn" proposedvalue="" active="1"/>
    <field issuperfield="0" easyfieldid="user_signature" easyfieldorder="-8" easyfieldtype="-4" easydatatype="0" easydatatypedata="0" easydatatypetext="TEXT" easyfieldname="Signature" profieldname="easysignature" localname_sv="Easy signature" localname_en_us="Easy signature" localname_no="Easy signature" localname_fi="Easy signature" localname_da="Easy signature" proposedvalue="" active="1"/>
  </table>
</tables>
        '
        

        IF NOT EXISTS ( SELECT  *
                        FROM    sys.objects
                        WHERE   object_id = OBJECT_ID(N'[dbo].[EASY__FIELDMAPPING]')
                                AND type IN ( N'U' ) ) 
            BEGIN
            
            -- Begin transaction
                IF @@TRANCOUNT = 0 
                    BEGIN
                        BEGIN TRANSACTION tran_create_easy__fieldmapping
                        SELECT  @transaction = 1
                    END
            
                BEGIN TRY
                    SET @xml = CAST(@xmltext AS XML)
					 
                    CREATE TABLE [dbo].[EASY__FIELDMAPPING]
                        (
                          [idfieldmapping] INT IDENTITY(1, 1)
                                               PRIMARY KEY ,
                          [easytable] NVARCHAR(64) ,
                          [relatedeasytable] NVARCHAR(64) ,
                          [easyfieldname] NVARCHAR(64) ,
                          [issuperfield] INT ,
                          [easyfieldid] NVARCHAR(64) ,
                          [easyfieldorder] INT ,
                          [easyfieldtype] INT ,
                          [easydatatype] INT ,
                          [easydatatypedata] INT ,
                          [easydatatypetext] NVARCHAR(64) ,
                          [protable] NVARCHAR(64) ,
                          [transfertable] INT ,
                          [profieldname] NVARCHAR(64) ,
                          [localname_sv] NVARCHAR(64) ,
                          [localname_en_us] NVARCHAR(64) ,
                          [localname_no] NVARCHAR(64) ,
                          [localname_fi] NVARCHAR(64) ,
                          [localname_da] NVARCHAR(64) ,
                          [active] INT ,
                          [easyprofieldtype] INT ,
                          [proposedvalue] NVARCHAR(64)
                        )
                    
                    
                    
                    INSERT  INTO [dbo].[EASY__FIELDMAPPING]
                            ( [easytable] ,
                              [relatedeasytable] ,
                              [easyfieldname] ,
                              [issuperfield] ,
                              [easyfieldid] ,
                              [easyfieldorder] ,
                              [easyfieldtype] ,
                              [easydatatype] ,
                              [easydatatypedata] ,
                              [easydatatypetext] ,
                              [protable] ,
                              [transfertable] ,
                              [profieldname] ,
                              [localname_sv] ,
                              [localname_en_us] ,
                              [localname_no] ,
                              [localname_fi] ,
                              [localname_da] ,
                              [active] ,
                              [easyprofieldtype] ,
                              [proposedvalue] 
                            )
                            SELECT  t.[table].value('@name', 'NVARCHAR(64)') AS [easytable] ,
                                    f.[field].value('@relatedeasytable',
                                                    'NVARCHAR(64)') AS [relatedeasytable] ,
                                    f.[field].value('@easyfieldname',
                                                    'NVARCHAR(64)') AS [easyfieldname] ,
                                    f.[field].value('@issuperfield', 'INT') AS [issuperfield] ,
                                    f.[field].value('@easyfieldid',
                                                    'NVARCHAR(64)') AS [easyfieldid] ,
                                    f.[field].value('@easyfieldorder', 'INT') AS [easyfieldorder] ,
                                    f.[field].value('@easyfieldtype', 'INT') AS [easyfieldtype] ,
                                    f.[field].value('@easydatatype', 'INT') AS [easydatatype] ,
                                    f.[field].value('@easydatatypedata', 'INT') AS [easydatatypedata] ,
                                    CASE WHEN f.[field].value('@easydatatype',
                                                              'INT') = -999
                                         THEN f.[field].value('@easydatatypetext',
                                                              'NVARCHAR(64)') -- GET VALUE FROM XML-FILE
                                         ELSE [dbo].[cfn_easytopro_geteasydatatypetext](f.[field].value('@easydatatype',
                                                              'INT'),
                                                              f.[field].value('@easydatatypedata',
                                                              'INT'))
                                    END AS [easydatatypetext] ,
                                    t.[table].value('@protable',
                                                    'NVARCHAR(64)') AS [protable] ,
                                    t.[table].value('@transfertable',
                                                    'NVARCHAR(64)') AS [transfertable] ,
                                    f.[field].value('@profieldname',
                                                    'NVARCHAR(64)') AS [profieldname] ,
                                    f.[field].value('@localname_sv',
                                                    'NVARCHAR(64)') AS [localname_sv] ,
                                    f.[field].value('@localname_en_us',
                                                    'NVARCHAR(64)') AS [localname_en_us] ,
                                    f.[field].value('@localname_no',
                                                    'NVARCHAR(64)') AS [localname_no] ,
                                    f.[field].value('@localname_fi',
                                                    'NVARCHAR(64)') AS [localname_fi] ,
									f.[field].value('@localname_da',
                                                    'NVARCHAR(64)') AS [localname_da] ,
                                    f.[field].value('@active', 'INT') AS [active] ,
                                    CASE WHEN f.[field].value('@easydatatype',
                                                              'INT') = -999
                                         THEN 16 -- RELATION FIELD
                                         ELSE [dbo].[cfn_easytopro_geteasyprofieldtype](f.[field].value('@easydatatype',
                                                              'INT'),
                                                              f.[field].value('@easydatatypedata',
                                                              'INT'))
                                    END AS [easyprofieldtype] ,
                                    f.[field].value('@proposedvalue',
                                                    'NVARCHAR(64)') AS [proposedvalue]
                            FROM    @xml.nodes('tables/table') AS t ( [table] )
                                    CROSS APPLY [table].nodes('field') AS f ( field )
                            WHERE   f.[field].value('@issuperfield', 'INT') IN (
                                    0, 2 )
                        
                    SET @@errormessage = N''
                    SET @@result = 0
                END TRY
                BEGIN CATCH
                    SET @@errormessage = ERROR_MESSAGE()
                    SET @@result = 1
                END CATCH
                
                IF @@result <> 0 
                    BEGIN
                        IF @transaction = 1 
                            ROLLBACK TRANSACTION tran_create_easy__fieldmapping
                    END

	-- Commit transaction
                IF ( @transaction = 1
                     AND @@result = 0
                   ) 
                    BEGIN
                        COMMIT TRANSACTION tran_create_easy__fieldmapping
                    END
            END
        ELSE 
            BEGIN
                SET @@errormessage = N''
                SET @@result = 0
            END

        IF ( @@errormessage IS NULL ) 
            SET @@errormessage = N''

    END
