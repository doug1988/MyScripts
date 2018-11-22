OPENROWSET

select 'Pedico' as DescImagem, (select * from OPENROWSET(bulk N'C:\Users\douglas.porto\Desktop\SSMS\40315428.jpg', SINGLE_BLOB) as T) as IMAGEN