
CREATE or alter FUNCTION sf_RemoveExtraChars (@NAME nvarchar(2500))
RETURNS nvarchar(2500)
AS
BEGIN
  declare @TempString nvarchar(2500)
  set @TempString = @NAME
  set @TempString = LOWER(@TempString)
  --set @TempString =  replace(@TempString,' ', '')
  set @TempString =  replace(@TempString,'à', 'a')
  set @TempString =  replace(@TempString,'ã', 'a')
  set @TempString =  replace(@TempString,'á', 'a')
  set @TempString =  replace(@TempString,'â', 'a')
  set @TempString =  replace(@TempString,'è', 'e')
  set @TempString =  replace(@TempString,'é', 'e')
  set @TempString =  replace(@TempString,'ì', 'i')
  set @TempString =  replace(@TempString,'í', 'i')
  set @TempString =  replace(@TempString,'ò', 'o')
  set @TempString =  replace(@TempString,'ó', 'o')
  set @TempString =  replace(@TempString,'ô', 'o')
  set @TempString =  replace(@TempString,'ù', 'u')
  set @TempString =  replace(@TempString,'ú', 'u')
  set @TempString =  replace(@TempString,'ç', 'c')
  set @TempString =  replace(@TempString,'''', '')
  set @TempString =  replace(@TempString,'`', '')
  set @TempString =  replace(@TempString,'-', ' ')
  set @TempString =  replace(@TempString,'"', ' ')
  return @TempString
END
GO