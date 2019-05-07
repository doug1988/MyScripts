use DbAcRg
GO
CREATE PROCEDURE dbo.SpPrapararDadosCIF
(
	@CodPostoEmissaoOrigem	int		-- 11
,	@NumeroRG				varchar = null -- '002.115-A'
)
as
begin
	
	--criando ou truncando os dados da tabela de trasnmissão
	if not exists(select 1 from sys.tables where name = 'DadosTransmissaoCIF')
	BEGIN
		create table DadosTransmissaoCIF
		(	NumeroPedido	bigint	
		,	NumeroRG		varchar(20)	collate Latin1_General_CI_AS
		,	Nome			varchar(70)	collate Latin1_General_CI_AS
		,	NomePai			varchar(60)	collate Latin1_General_CI_AS
		,	NomeMae			varchar(60)	collate Latin1_General_CI_AS
		,	DataNascimento	varchar(25)	collate Latin1_General_CI_AS
		,	BlobFoto		image
		,	BlobBiometria	image
		,	BlobAssinatura  image
		)
	END
	ELSE
	BEGIN
		truncate table DadosTransmissaoCIF
	END

	
	--carregando tabela com as chaves dessa busca
	select  a.NumeroRG				
	,		max(a.NumeroPedido)	as NumeroPedido
	into	#chaves
	from		[dbo].PedidosEmissao		as a (nolock)
	inner join	[dbo].PedidosEmissaoimagens as b (nolock) on b.NumeroPedido = a.NumeroPedido and b.CodPedidoEmissaoImagemTipo = 1 and datalength(b.BlobPedidoEmissaoImagem) > 3 -- que possua Foto válida
	inner join	[dbo].PedidosEmissaoimagens as c (nolock) on c.NumeroPedido = a.NumeroPedido and c.CodPedidoEmissaoImagemTipo = 2 and datalength(c.BlobPedidoEmissaoImagem) > 3 -- que possua Biometria válida
	inner join	[dbo].PedidosEmissaoimagens as d (nolock) on d.NumeroPedido = a.NumeroPedido and d.CodPedidoEmissaoImagemTipo = 3 and datalength(d.BlobPedidoEmissaoImagem) > 3 -- que possua Assinatura válida
	where	a.CodEstadoPedidoEmissaoAtual in (50, 60) --respectivamente (Expedido, Expedido para empresa parceira)
		and a.CodPostoEmissaoOrigem = @CodPostoEmissaoOrigem -- do posto passado no parametro
		and a.NumeroRG  = isnull(@NumeroRg, a.NumeroRG) -- do RG apssado no parÂmetro (caso tenha sido passado)
	group by a.NumeroRG

	--carregando tabela com as informações dos RGs (com base nas chaves já carregadas acima)
	select	a.NumeroPedido
	,		a.NumeroRG
	,		a.DataNascimento
	,		a.Nome
	,		a.NomePai
	,		a.NomeMae
	into #RG
	from		[dbo].PedidosEmissao				as a (nolock)
	inner join	#chaves								as a1 (nolock) on a.NumeroPedido = a1.NumeroPedido
	

	if @NumeroRG is null --busca somente pelos RGs disponíveis para criação da CIF
	begin

		--carregando dados na tabela de transmissao
		insert into DadosTransmissaoCIF
		(	NumeroPedido	
		,	NumeroRG		
		,	Nome			
		,	NomePai			
		,	NomeMae			
		,	DataNascimento	
		)
		SELECT * FROM #RG

	end 
	else -- traz os dados de um RG único - já com as fotos
	begin

		--carregando as imagens desse RG
		select 	a.NumeroPedido
		,		a.CodPedidoEmissaoImagemTipo
		,		b.DescPedidoEmissaoImagemTipo
		,		a.BlobPedidoEmissaoImagem
		,		a.DataOperacaoImagem
		,		a.CodUsuario
		into	#imagens
		from		[dbo].PedidosEmissaoimagens			as a (nolock)
		inner join	[dbo].PedidosEmissaoImagensTiposPC	as b (nolock) on a.CodPedidoEmissaoImagemTipo = b.CodPedidoEmissaoImagemTipo
		where exists (select 1 from #rg as a1 where a1.NumeroPedido = a.NumeroPedido)
		and a.CodPedidoEmissaoImagemTipo in (1, 2, 3)
		and datalength(a.BlobPedidoEmissaoImagem ) > 3


		--carregando dados na tabela de transmissao
		insert into DadosTransmissaoCIF
		(	NumeroPedido	
		,	NumeroRG		
		,	Nome			
		,	NomePai			
		,	NomeMae			
		,	DataNascimento	
		,	BlobFoto
		,	BlobBiometria
		,	BlobAssinatura
		)
		select	a.NumeroPedido
		,		a.NumeroRG
		,		a.DataNascimento
		,		a.Nome
		,		a.NomePai
		,		a.NomeMae
		,		b.BlobPedidoEmissaoImagem as blobFoto
		,		c.BlobPedidoEmissaoImagem as blobBiometria
		,		d.BlobPedidoEmissaoImagem as blobAssinatura
		from #rg			as a (nolock)
		inner join #imagens	as b (nolock) on a.NumeroPedido = b.NumeroPedido and b.CodPedidoEmissaoImagemTipo = 1 -- foto
		inner join #imagens	as c (nolock) on a.NumeroPedido = c.NumeroPedido and c.CodPedidoEmissaoImagemTipo = 2 -- Biometria
		inner join #imagens	as d (nolock) on a.NumeroPedido = d.NumeroPedido and d.CodPedidoEmissaoImagemTipo = 3 -- Assinatura
	END
END
