drop table if exists seguindo;
drop table if exists seguidor;
drop table if exists likes_midia;
drop table if exists likes_comentario;
drop table if exists comentario;
drop table if exists mensagem;
drop table if exists conversa;
drop table if exists caixa_de_mensagem;
drop table if exists descricao;
drop table if exists bloqueado;
drop table if exists midia;
drop table if exists usuario;


create table usuario (
	usuario_id integer not null,
	login varchar(255) unique not null,
	senha varchar(255) not null,
	nome varchar(255) not null,
	descricao text,
	privado boolean,
	primary key (usuario_id)
);

create table caixa_de_mensagem (
	caixa_id integer,
	usuario_id integer references usuario(usuario_id),
	primary key(caixa_id)
);

create table conversa (
	conversa_id integer,
	caixa_id integer references caixa_de_mensagem(caixa_id),
	receptor_id integer,
	primary key(conversa_id)
);

create table mensagem (
	mensagem_id integer,
	conversa_id integer references conversa(conversa_id),
	mensagem text,
	primary key(mensagem_id)
);

create table seguindo (
	usuario_id integer references usuario(usuario_id),
	time_stamp timestamp,
	seguindo_id integer,
	primary key (usuario_id, seguindo_id)
);

create table seguidor (
	usuario_id integer references usuario(usuario_id),
	seguidor_id integer,
	time_stamp timestamp,
	primary key (usuario_id, seguidor_id)
);

create table midia(
	midia_id integer,
	usuario_id integer references usuario(usuario_id),
	conteudo varchar(255),
	tipo varchar(255),
	primary key (midia_id)
);

create table descricao (
	descricao_id integer,
	midia_id integer references midia(midia_id),
	hash_tag varchar(255),
	texto text,
	primary key (descricao_id)
);

create table comentario (
	comentario_id integer,
	midia_id integer references midia(midia_id),
	usuario_id integer references usuario(usuario_id),
	comentario varchar(255),
	time_stamp timestamp,
	primary key (comentario_id)
);

create table likes_midia (
	midia_id integer references midia(midia_id),
	usuario_id integer references usuario(usuario_id),
	time_stamp timestamp
);

create table likes_comentario (
	comentario_id integer references comentario(comentario_id),
	usuario_id integer references usuario(usuario_id),
	time_stamp timestamp
);

create table bloqueado (
	usuario_id integer references usuario(usuario_id),
	bloqueado_id integer,
	time_stamp timestamp
);

create or replace function bloquear_usuario() returns trigger as $$
begin
	delete from seguidor where 
		seguidor.usuario_id = new.usuario_id and seguidor.seguidor_id = new.bloqueado_id;
	delete from seguindo where
		seguindo.usuario_id = new.bloqueado_id and seguindo.seguindo_id = new.usuario_id;
	return new;
end;
$$ language plpgsql;

create or replace function seguir_usuario() returns trigger as $$
begin
	insert into seguidor values(new.seguindo_id, new.usuario_id, current_timestamp);
	return new;
end;
$$ language plpgsql;

create trigger bloqueia after insert on bloqueado 
	for each row execute procedure bloquear_usuario();

-- created one more for following user
create trigger seguir after insert on seguindo
	for each row execute procedure seguir_usuario();

-- some tests
insert into usuario values (0,'a', 'b', 'a', null, null);
insert into usuario values (1,'b', 'c', 'b', null, null);
insert into seguindo values (1, current_timestamp, 0);

insert into bloqueado values (0, 1, current_timestamp);

select * from seguidor;
select * from seguindo;
select * from bloqueado;