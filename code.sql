USE [HCS_DB]
GO
/****** Object:  StoredProcedure [dbo].[prNonAvailabilityStatusUpdate]    Script Date: 8/6/2024 4:32:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[prNonAvailabilityStatusUpdate]
(
    @Id uniqueidentifier,
    @ApprovalStatus int,
    @ApprovalComments varchar(800),
    @UpdatedBy uniqueidentifier,
    @UpdatedOn datetime
) 
AS
BEGIN
Declare @errorMessage nvarchar(max)='';  
Declare @message nvarchar(max)='';
DECLARE @Role NVARCHAR(500) = (
        SELECT TOP 1 RoleName
        FROM [Users] u
        INNER JOIN [Roles] r ON r.Id = u.RoleId
        WHERE u.Id = @UpdatedBy
    );
 Begin	try	
    -- Check if the input status is valid
    IF @ApprovalStatus NOT IN (1, 2)
    BEGIN 
        RAISERROR('Invalid status value. Status must be either 1 (Approved) or 2 (Rejected).', 16, 1);
        RETURN;
    END
	IF @Role NOT IN ('Clinic Admin', 'Admin')
BEGIN 
    RAISERROR('You Don’t Have Access To Perform This Action', 16, 1);
    RETURN;
END


    -- Update the NonAvailability table based on the given status
    UPDATE NonAvailability
    SET 
        ApprovalStatus = @ApprovalStatus,
        ApprovalComments = @ApprovalComments,
        ApprovedBy = @UpdatedBy,
        ApprovedOn = @UpdatedOn, 
        UpdatedBy = @UpdatedBy,
        UpdatedOn = @UpdatedOn
    WHERE 
        Id = @Id;
		Set @message = 'Non-Availability Status Updated Successfully'

    end Try
		Begin Catch 
		    set @errorMessage='Error while saving the ExpenseType data.  \n\n  Trace: '+ERROR_MESSAGE()
		End Catch
	IF @errorMessage = ''
	BEGIN
		SELECT 1 success
			,@message [Message]
		FOR Json Path,WITHOUT_ARRAY_WRAPPER
	END
	ELSE
	BEGIN
		SELECT 0 success
			,@errorMessage [Message]
		FOR Json Path,WITHOUT_ARRAY_WRAPPER
	END
END
