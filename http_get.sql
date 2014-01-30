-- =============================================
-- Author:      Sergey Petunin (@forketyfork)
-- Create date: 24.12.2013
-- Description: A sample function for sending an HTTP GET request and receiving results.
--
-- WARNING: This is simply a demonstration of concept.
-- You almost never want to make HTTP requests from SQL stored procedures!
-- Seriously, consider using an multitier architecture with application server instead.
-- Unfortunately, I had a certain very narrow use case which resulted in writing this procedure.
-- (Not very proud of it, really, I'm not. Just hope it helps someone.)
--
-- To use this function, you should enable OLE Automation on your SQL Server instance.
-- Right-click on the server node in SQL Management Studio, select 'Facets', 'Surface Area Configuration',
-- and set 'OleAutomationEnabled' to true.
-- =============================================
if object_id(N'dbo.http_get', N'FN') is not null
  drop function dbo.http_get
go

create function dbo.http_get
  (@url varchar(max),       -- http url to get
  @login varchar(max),      -- user login for Basic auth
  @password varchar(max))   -- user password for Basic auth
  returns varchar(8000)
as
begin
declare @obj int,               -- an ServerXMLHttp handle
    @hr int,                    -- ServerXMLHttp operation result

    @source varchar(1024),      -- error source
    @description varchar(1024), -- error description
    @err_message varchar(2048), -- error message
    @result varchar(8000),      -- request result
    @authorization varchar(255);-- Authorization HTTP header (base64-encoded login and password)

-- creating Authorization header from login and password
set @authorization = 'Basic ' + (
  select cast(N'' as xml).value('xs:base64Binary(xs:hexBinary(sql:column("bin")))', 'VARCHAR(MAX)')
  from (select cast(concat(@login, ':', @password) as varbinary(max)) as bin)
  as bin_sql_server_temp
);

-- creating an OLE object for sending the request
exec @hr = sp_OACreate 'MSXML2.XMLHTTP.6.0', @obj out;
if @hr <> 0 goto err;
-- setting the URL for request
exec @hr = sp_OAMethod @obj, 'open', NULL, 'GET', @url, false;
if @hr <> 0 goto err;
-- setting auth header
exec @hr = sp_OAMethod @obj, 'setRequestHeader', NULL, 'Authorization', @authorization;
if @hr <> 0 goto err;
-- posting the message

exec @hr = sp_OAMethod @obj, 'send', NULL
if @hr <> 0 goto err;
exec @hr = sp_OAGetProperty @obj, 'responseText', @result out
if @hr <> 0 goto err;
exec @hr = sp_OADestroy @obj;
if @hr <> 0 goto err;
return @result;

-- error handling
err:
exec @hr = sp_OAGetErrorInfo @obj, @source out, @description out;
exec @hr = sp_OADestroy @obj;
set @err_message = @source + ': ' + @description;
return cast(@err_message as int);
end
go
