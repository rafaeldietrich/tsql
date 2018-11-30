drop table parcelas_tmp
go
drop table itemPedido
go
drop table pedido
GO
drop table cliente
go
drop table produto

Create table parcelas_tmp (id int identity(1,1), num int)
GO

insert into parcelas_tmp values(NULL)
go 100
go

update parcelas_tmp set num = id
GO

--Select * from parcelas_tmp
GO

create table cliente(
	id int identity(1,1),
	primeiroNome varchar(100) not null, 
	sobrenome varchar(300) not null, 
	dataNascimento datetime not null, 
	statusAtivo bit default 1 not null,
	dataCadastro datetime not null,
	constraint pk_cliente primary key(id)
)
GO

create table #tmpNomes(id int identity(1,3), nome varchar(100), sobrenome varchar(200))
GO

insert into #tmpNomes values('Carlos','de Almeida')
insert into #tmpNomes values('Jose','da Silva')
insert into #tmpNomes values('Maria','de Oliveira')
insert into #tmpNomes values('Rafael','santos silva')
insert into #tmpNomes values('Roger','costa e costa')
insert into #tmpNomes values('Jo�o','silva da silva')
insert into #tmpNomes values('Marcus','c. de oliveira')
insert into #tmpNomes values('Fernando','almeida alcantara')
insert into #tmpNomes values('Karla','genoveva')
insert into #tmpNomes values('Marta','o. a de albuquerque')
insert into #tmpNomes values('Joana','dos santos')
insert into #tmpNomes values('Alessandro', 'librelato petkova')
GO

insert into cliente 
Select distinct a.nome, b.sobrenome, dateadd(Year, a.id*(-1) ,dateadd(month,a.id,convert(datetime,'1985-01-01')+(a.id*b.id))), 1,getdate()
from #tmpNomes a cross join #tmpNomes b
order by 3
GO

drop table #tmpNomes
GO

create table produto(
	id int identity(1,1) not null,
	nome varchar(200),
	valorUnit decimal(18,2),
	dataCadastro datetime constraint df_dataCadastroProduto default getdate()
	constraint pk_produto primary key(id)
)
GO
create table #tmpProduto (
	id int identity(1,7), 
	nome varchar(50)
)
GO
insert into #tmpProduto values('Notebook ')
insert into #tmpProduto values('Microfone')
insert into #tmpProduto values('Teclado')
insert into #tmpProduto values('kit multimidia')
insert into #tmpProduto values('Pacote de software')
insert into #tmpProduto values('Cadeira')
insert into #tmpProduto values('Adaptador')
insert into #tmpProduto values('Carregar de notbook')
GO
insert into produto
Select distinct a.nome +' '+ convert(varchar, row_number() over(order by a.id)), (8*row_number() over(order by a.id))*RAND() , getdate()
from #tmpProduto a cross join #tmpProduto b

GO
drop table #tmpProduto
GO
create table pedido(
	id int identity(1,1) not null,
	idCliente int not null constraint fk_pedido_cliente references cliente(id) ,
	valor decimal(18,2),
	valorTaxas decimal (18,2),
	valorTotal as valor + valorTaxas,
	dataPedido datetime not null constraint df_dataPedidoPedido default getdate()
	constraint pk_pedido primary key(id)
)
GO
insert into pedido (idCliente, dataPedido)
select id, convert(datetime,'2018-04-02')+id 
from cliente 
where year(dataNascimento) %2 =0 and id%2=0
GO
insert into pedido (idCliente, dataPedido)
select id, convert(datetime,'2018-04-02')-id +1
from cliente 
where year(dataNascimento) %2 =0 and id%2=0
GO
insert into pedido (idCliente, dataPedido)
select id, convert(datetime,'2018-11-15')-id 
from cliente 
where year(dataNascimento) %2 !=0 and id%2=0


GO
create table #tmpItemPedido (idPedido int, idProduto int)
GO
insert into #tmpItemPedido
Select p.id, month(dataNascimento)
from pedido p inner join cliente c 
on p.idCliente = c.id
GO

insert into #tmpItemPedido
Select p.id, day(DataNascimento)*2-2
from pedido p inner join cliente c 
on p.idCliente = c.id
GO

insert into #tmpItemPedido
Select p.id, idCliente
from pedido p inner join cliente c 
on p.idCliente = c.id
GO

insert into #tmpItemPedido
Select p.id,convert(int,(rand()*3)*day(c.dataNascimento))
from pedido p inner join cliente c 
on p.idCliente = c.id
GO 3
GO

insert into #tmpItemPedido
Select p.id,convert(int,(rand()*4)*day(c.dataNascimento))
from pedido p inner join cliente c 
on p.idCliente = c.id
GO 2

insert into #tmpItemPedido
Select p.id,convert(int,(rand()*6)*day(c.dataNascimento))
from pedido p inner join cliente c 
on p.idCliente = c.id
GO


create table itemPedido(
	id int identity(1,1) not null,
	idPedido int not null constraint fk_itemPedidoPedido references pedido(id), 
	idProduto int not null constraint fk_itemPedidoProduto references produto(id),
	quantidade int,
	valorUnit decimal(18,2),
	valorDesc decimal(18,2),
	valorTotal as (valorUnit*quantidade)-valorDesc
	constraint pk_itemPedido primary key(id),
	constraint uk_ChaveItemPedido unique (idPedido, idProduto)
)
GO

insert into itemPedido (idPedido, idProduto, quantidade)
Select idPedido, idProduto, count(*) from #tmpItemPedido
where exists(Select top 1 * from produto where produto.id = idProduto)
group by idPedido, idProduto
GO


update ip set valorUnit = p.valorUnit, valorDesc = (rand()*0.20)*p.valorUnit
from itemPedido ip
inner join produto p
on ip.idProduto = p.id
GO

drop table #tmpItemPedido
GO


update p set valor = ip.valorTotal, valorTaxas = ip.valorTotal*0.17
from pedido p
inner join (Select idPedido, sum(valorTotal) as valorTotal from itemPedido group by idPedido) ip
on p.id = ip.idPedido

