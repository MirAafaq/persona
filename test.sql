USE [HCS_DB]
GO
/****** Object:  StoredProcedure [dbo].[prEducationInformationFetchAll]    Script Date: 8/8/2024 11:00:46 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[prEducationInformationFetchAll]
(
    @UserId uniqueidentifier,
    @Filter nvarchar(max)
)
AS
BEGIN
    DECLARE @SortColumn nvarchar(100), @searchString nvarchar(255) = '', @SortOrder nvarchar(5) = '';
    DECLARE @PageNumber int = 1, @PageSize int = 10;

    SELECT @SortColumn = JSON_VALUE(@Filter, '$.sortColumn');
    SELECT @searchString = JSON_VALUE(@Filter, '$.searchString');
    SELECT @SortOrder = JSON_VALUE(@Filter, '$.sortOrder');
    SELECT @PageSize = CAST(JSON_VALUE(@Filter, '$.pageSize') AS int);
    SELECT @PageNumber = CAST(JSON_VALUE(@Filter, '$.pageNumber') AS int);

    DECLARE @Role NVARCHAR(500) = (
        SELECT TOP 1 RoleName
        FROM [Users] u
        INNER JOIN [Roles] r ON r.Id = u.RoleId        
        WHERE u.Id = @UserId
    );

    IF (@PageNumber IS NULL OR @PageNumber = 0)
        SET @PageNumber = 1;

    IF (@PageSize IS NULL OR @PageSize = 0)
        SET @PageSize = 10000;

    DECLARE @limitFrom int = @PageSize * (@PageNumber - 1);
    DECLARE @limitTo int = @PageSize * @PageNumber;

    IF ISNULL(@SortColumn, '') = ''
        SET @SortColumn = 'SchoolUniversity';

    IF ISNULL(@SortOrder, '') = ''
        SET @SortOrder = 'ASC'; 

    DECLARE @SQL nvarchar(max) = N'
    SELECT * FROM (
        SELECT ROW_NUMBER() OVER(ORDER BY e.' + QUOTENAME(@SortColumn) + ' ' + @SortOrder + ') AS RowNumber,
            e.Id,
            e.EmployeeId,
            e.SchoolUniversity,
            e.DegreeDiploma,
            e.YearOfGraduation,
            e.CreatedBy,
            e.UpdatedBy,
            e.CreatedOn,
            e.UpdatedOn,
            e.IsDeleted,
            e.DeletedBy,
            e.DeletedOn,
            Title + '' '' + FullName AS EmployeeName
        FROM [EducationInformation] e
        JOIN Employees emp ON emp.Id = e.EmployeeId
        JOIN Users u ON u.Id = emp.UserId
        WHERE (e.SchoolUniversity LIKE ''%' + @searchString + '%'' OR
               e.DegreeDiploma LIKE ''%' + @searchString + '%'' OR
               e.YearOfGraduation LIKE ''%' + @searchString + '%'')
        AND (@Role = ''Admin'' OR e.EmployeeId IN (SELECT Id FROM Employees WHERE UserId = @UserId))
    ) t
    WHERE RowNumber <= @limitTo AND RowNumber > @limitFrom
    FOR JSON PATH';

    PRINT @SQL;  -- Debugging purpose, can be removed in production

    EXEC sp_executesql @SQL, 
                        N'@UserId uniqueidentifier, @searchString nvarchar(255), @limitFrom int, @limitTo int, @Role nvarchar(500)',
                        @UserId = @UserId, 
                        @searchString = @searchString, 
                        @limitFrom = @limitFrom,
                        @limitTo = @limitTo,
                        @Role = @Role;

    DECLARE @countQuery nvarchar(max) = N'
    SELECT COUNT(1) AS [Count]
    FROM [EducationInformation] e
    JOIN Employees emp ON emp.Id = e.EmployeeId
    WHERE (e.SchoolUniversity LIKE ''%' + @searchString + '%'' OR
           e.DegreeDiploma LIKE ''%' + @searchString + '%'' OR
           e.YearOfGraduation LIKE ''%' + @searchString + '%'')
    AND (@Role = ''Admin'' OR e.EmployeeId IN (SELECT Id FROM Employees WHERE UserId = @UserId))';

    EXEC sp_executesql @countQuery,
                        N'@UserId uniqueidentifier, @searchString nvarchar(255), @Role nvarchar(500)',
                        @UserId = @UserId,
                        @searchString = @searchString,
                        @Role = @Role;
END
