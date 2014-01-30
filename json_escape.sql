-- =============================================
-- Author:        Sergey Petunin (@forketyfork)
-- Create date:   29.01.2014
-- Description:   A function to escape a varchar string to conform to JSON RFC.
-- See http://www.ietf.org/rfc/rfc4627.txt ch. 2.5
-- =============================================
if object_id(N'dbo.json_escape', N'FN') is not null
    drop function dbo.json_escape
go

create function dbo.json_escape (@string varchar(max)) returns varchar(max)
as
begin
    declare @wcount int, @index int, @len int, @char char, @escaped_string varchar(max)

    set @escaped_string = ''
    set @wcount = 0
    set @index = 1
    set @len = len(@string)

    while @index <= @len
    begin
        set @char = substring(@string, @index, 1)
        set @escaped_string += 
        case
            when @char = '"' then '\"'
            when @char = '\' then '\\'
            when unicode(@char) < 32 then '\u00' + right(sys.fn_varbintohexstr(cast(@char as varbinary)), 2)
            else @char
        end
        set @index += 1
    end
    return(@escaped_string)
end

go