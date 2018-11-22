/*

Criar um TXT com as informações a seguir:
---------------------------
open 172.17.14.32
thomas
thomas121107
verbose
prompt
dir 
quit

*/



--Em Seguida executar o script abaixo informando o camnho em que se encontra o TXT com os comandos BACTH.

declare       
        @Server varchar(200 ) =   '172.17.14.32'
,      @Usuario varchar( 200)  = 'thomas'
,      @Senha varchar( 200) = 'thomas121107'
,      @CaminhoFtp varchar( 200)
,      @DiretorioPadrao varchar( 200) = 'g:\yamashiro'
,      @NomeExec varchar( 200) = 'teste.txt'
,      @CaminhoExec varchar( 200) = 'g:\yamashiro\'
,      @Operacao varchar( 200) -- "Download", "Upload"
,      @NomeArquivo varchar( 200)



        -- ( Início ) - Declara variável auxiliar ...
        declare @Cmd varchar (2000)
        -- ( Fim ) - Declara variável auxiliar . 


        -- ( Início ) - Seta o Servidor ...
        set @cmd = 'echo open ' + @Server + ' > ' + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd , no_output
        -- ( Fim ) - Seta o Servidor .

        -- ( Início ) - Seta o usuário e senha ...             
        set @cmd = 'echo ' + @Usuario + '>> ' + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd , no_output
       
        set @cmd = 'echo ' + @Senha+ '>> ' + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd , no_output
        -- ( Fim ) - Seta o usuário e senha .

        -- ( Início ) - Ativa os retornos dos comandos ...
        set @cmd = 'echo verbose' + ' >> ' + + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd      , no_output
        -- ( Fim ) - Ativa os retornos dos comandos .   
              
        -- ( Início ) - Desativa o modo interativo ...
        set @cmd = 'echo prompt' + ' >> ' + + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd      , no_output
        -- ( Fim ) - Desativa o modo interativo. 

        -- ( Início ) - Seta o diretorio padrao do server ...
        set @cmd = 'echo dir ' + ' >> ' + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd      , no_output
        -- ( Fim ) - Seta o diretorio padrao do server.        

        -- ( Início ) - Encerra o FTP ...        
        select @cmd = 'echo quit' + ' >> ' + + @CaminhoExec + @NomeExec
        exec master ..xp_cmdshell @cmd , no_output
        -- ( Fim ) - Encerra o FTP .
              
        select @cmd = 'ftp -s:' + @CaminhoExec + @NomeExec --+ ' > ' + @CaminhoExec + 'Retorno' + @NomeExec
       
        declare @t table (Campo varchar (1000))
        insert into @t
        exec master ..xp_cmdshell @cmd

       
        select
               SUBSTRING(campo ,43, 13)  as Tempo
        ,   SUBSTRING (campo, 56,100 )  as Arqui   
        from
              @t
        where
              Campo like '%teor%'
        order by       
               1
       
  
