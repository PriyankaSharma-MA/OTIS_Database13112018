USE [Global_BI_NPrinting]
GO

--To add TaskNameColumn in  APP.TaskMaster TABLE
alter table [APP].[TaskMaster]
add TaskName nvarchar(50)

--------------------------------------------------------------------------------------------------------
--To Update TaskName from NPT.TaskMaster to APP.TaskMaster
UPDATE [APP].[TaskMaster]
SET [APP].[TaskMaster].TaskName=NTM.TaskName 
from [APP].[TaskMaster] ATM
join [NPT].[TaskMaster] NTM on ATM.NprintingTaskID=NTM.NprintingTaskID

-------------------------------------------------------------------------------------------------------

--1:APP.GetAttachmentDetails
IF EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE object_id=OBJECT_ID(N'APP.GetAttachmentDetails'))
BEGIN
DROP PROCEDURE [APP].[GetAttachmentDetails]
END
GO
CREATE PROCEDURE [APP].[GetAttachmentDetails]
AS
select  distinct AR.AttachmentID, TM.NPrintingTaskID TaskID,UM.[UserName],TM.TaskName,
UM.Email_ID,RM.[ReportName],AR.AttachmentName
from APP.[SubscriptionMaster] SM 
JOIN APP.[TaskMaster] TM ON (SM.[TaskMasterID]=TM.TaskMasterID) and TM.AuditFlag<>2
JOIN APP.AttachmentRetrieval AR ON RTRIM(LTRIM(AR.TASKID))= RTRIM(LTRIM(TM.NPrintingTaskID))
JOIN OTIS_SUBSCRIPTION.[DBO].[User_INFORMATION] UM ON (UM.ID=SM.[UserMasterID]) and UM.IsActive=1
JOIN APP.[ReportMaster] RM ON (TM.ReportID=RM.ReportMasterReportID) and RM.AuditFlag<>2
WHERE CONVERT(DATE,AR.INSERTEDDATE) =CONVERT(DATE,GETDATE())
AND AR.EMAILFLAG=0
AND SM.AuditFlag<>2

IF EXISTS(SELECT 1 FROM SYS.PROCEDURES WHERE object_id=OBJECT_ID(N'APP.SaveEmailTaskDetail'))
BEGIN
DROP PROCEDURE [APP].[SaveEmailTaskDetail]
END
GO

--2:[APP].[SaveEmailTaskDetail]
CREATE PROCEDURE [APP].[SaveEmailTaskDetail]
@TaskName nvarchar(50),
@AttachmentName nvarchar(100),
@Result varchar(10) output
AS
BEGIN
DECLARE @TASKID NVARCHAR(50)
SET @TASKID=(SELECT NprintingTaskID FROM [Global_BI_NPrinting].[APP].[TaskMaster] WHERE TaskName=@TaskName) 
IF  @TaskID is not null
BEGIN
IF NOT EXISTS(SELECT 1 FROM APP.AttachmentRetrieval WHERE TaskID=@TaskID AND AttachmentName=@AttachmentName
AND CONVERT(DATE,INSERTEDDATE)=CONVERT(DATE,GETDATE()))
BEGIN
	INSERT INTO APP.AttachmentRetrieval(TaskID,AttachmentName,EmailFlag,InsertedDate,UpdatedDate)
	VALUES(@TaskID,@AttachmentName,0,GETDATE(),GETDATE())
	SET @Result='Email Task Detail Inserted Successfully'

END
END
END