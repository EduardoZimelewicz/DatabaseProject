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
	privado boolean not null,
	primary key (usuario_id)
);

create table caixa_de_mensagem (
	caixa_id bigserial,
	usuario_id integer references usuario(usuario_id),
	qtd_conversas_nao_lidas integer, 
	primary key(caixa_id)
);

create table conversa (
	conversa_id bigserial,
	caixa_id integer references caixa_de_mensagem(caixa_id),
	receptor_id integer,
	bloqueado boolean,
	possui_mensagem_nova boolean, 
	primary key(conversa_id)
);

create table mensagem (
	mensagem_id bigserial,
	conversa_id integer references conversa(conversa_id),
	mensagem text,
	request boolean,
	lida boolean DEFAULT false,
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
	pendente boolean,
	primary key (usuario_id, seguidor_id)
);

create table midia(
	midia_id integer,
	usuario_id integer references usuario(usuario_id),
	conteudo varchar(255),
	duradoura boolean,
	time_stamp timestamp,
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

create or replace function create_message_box() returns trigger as $$
begin
	insert into caixa_de_mensagem values (default, new.usuario_id);
	return new;
end;
$$ language plpgsql;

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
declare
	rec_usuario usuario;
begin
	select * from usuario into rec_usuario where usuario_id = new.seguindo_id;
	if (rec_usuario.privado = false) then
		insert into seguidor values(new.seguindo_id, new.usuario_id, current_timestamp, false);
		return new;	
	end if;
	insert into seguidor values(new.seguindo_id, new.usuario_id, current_timestamp, true);
	return new;
end;
$$ language plpgsql;

create or replace function aceitar_request() returns trigger as $$
begin
	update seguidor set time_stamp = current_timestamp
		where seguidor.usuario_id = new.usuario_id and seguidor.seguidor_id = new.seguidor_id;
	return new;
end;
$$ language plpgsql;

create or replace function stories_check() returns trigger as $$
declare
	midia_rec midia;
	cursor_midia cursor for select * from midia;
begin
	open cursor_midia;
	loop 
		fetch cursor_midia into midia_rec;
	exit when not found;
	
	if ((age(current_timestamp,midia_rec.time_stamp) >= interval '24 hours') 
			and (midia_rec.duradoura = false)) then
		delete from midia where current of cursor_midia;
	end if;
	
	end loop;
	close cursor_midia;
	return new;
end;
$$ language plpgsql;

create or replace function conversa_request() returns trigger as $$
declare
	user_rec usuario;
begin
	select * from usuario into user_rec 
		where usuario.usuario_id = new.receptor_id;
	
	if(user_rec.privado = true) then
		insert into mensagem values (default, new.conversa_id, '', true);
		return new;
	end if;
end;
$$ language plpgsql;

create or replace function accept_message_request() returns trigger as $$
declare
begin
	delete from mensagem where
		mensagem.conversa_id = old.conversa_id and mensagem.request = true;
	return new;
end;
$$ language plpgsql;

create or replace function checa_mensagens_nao_lidas() returns trigger as $$
declare
	qtd_conv_nao_lidas integer;
begin

	if(TG_OP = 'INSERT') then
		update conversa set possui_mensagem_nova = true
			where conversa.conversa_id = new.conversa_id;
	elsif (TG_OP = 'UPDATE') THEN
		update conversa set possui_mensagem_nova = false
			where conversa.conversa_id = new.conversa_id;	
	end if;

	select count(*) into qtd_conv_nao_lidas 
		from conversa, caixa_de_mensagem
		where conversa.caixa_id = caixa_de_mensagem.caixa_id 
			and conversa.possui_mensagem_nova = true;
		
	update caixa_de_mensagem set qtd_conversas_nao_lidas = qtd_conv_nao_lidas;
	return new;
end;
$$ language plpgsql;


-- trigger for blocking user
create trigger bloqueia after insert on bloqueado 
	for each row execute procedure bloquear_usuario();

-- trigger for creating message box
create trigger new_user after insert on usuario
	for each row execute procedure create_message_box();

-- trigger for follow request
create trigger seguir after insert on seguindo
	for each row execute procedure seguir_usuario();

-- trigger for accept request
create trigger aceitar after update of pendente on seguidor
	for each row execute procedure aceitar_request();

-- trigger for stories update
create trigger stories after update on midia
	for each row execute procedure stories_check();

-- trigger for message request
create trigger req_conversa after insert on conversa
	for each row execute procedure conversa_request();

-- trigger for message acceptance
create trigger accept_message after update of bloqueado on conversa
	for each row execute procedure accept_message_request();
	
-- trigger for updating quantity of new messages on conversations
create trigger atualiza_caixa_de_mensagens after insert or update on mensagem
	for each row execute procedure checa_mensagens_nao_lidas();

-- test for blocking user trigger
/*
insert into usuario values (0,'a', 'b', 'a', null, false);
insert into usuario values (1,'b', 'c', 'b', null, false);
insert into seguindo values (1, current_timestamp, 0);

insert into bloqueado values (0, 1, current_timestamp);

select * from seguidor;
select * from seguindo;
select * from bloqueado;
*/

-- test for making request and accepting request
/*
insert into usuario values (0,'a', 'b', 'a', null, true);
insert into usuario values (1,'b', 'c', 'b', null, false);
insert into seguindo values (1, current_timestamp, 0);

update seguidor set pendente = false where seguidor.usuario_id = 0;

select * from seguidor;
*/

-- test for stories check
/*
insert into usuario values (0,'a', 'b', 'a', null, false);
insert into usuario values (1,'b', 'c', 'b', null, false);

insert into midia values (0, 0, null, true, current_timestamp);
insert into midia values (1, 1, null, false, current_timestamp);
insert into midia values (2, 1, null, true, current_timestamp);

update midia set time_stamp = current_timestamp - interval '24 hours'
	where midia.usuario_id = 1;

select * from midia;
*/

-- test for message request
/*
insert into usuario values (0,'a', 'b', 'a', null, true);
insert into usuario values (1,'b', 'c', 'b', null, false);

select * from caixa_de_mensagem;

insert into conversa values (default, 2, 0, true);

select * from conversa;
select * from mensagem;
*/

-- test for message acceptance
/*
insert into usuario values (0,'a', 'b', 'a', null, true);
insert into usuario values (1,'b', 'c', 'b', null, false);

select * from caixa_de_mensagem;

insert into conversa values (default, 2, 0, true);
update conversa set bloqueado = false 
	where conversa_id = 1;

select * from conversa;
select * from mensagem;
*/

-- test for check quantity da message box
/*
insert into usuario values (0,'a', 'b', 'a', null, false);
insert into usuario values (1,'b', 'c', 'b', null, false);
insert into usuario values (2,'c', 'c', 'b', null, false);

insert into conversa values (0, 1, 1, false, false);
insert into mensagem(mensagem_id ,conversa_id ,mensagem ,request ) values (0,0,'hello',false);

insert into conversa values (1, 1, 2, false, false);
insert into mensagem(mensagem_id ,conversa_id ,mensagem ,request ) values (1,1,'hi',false);

update mensagem set lida = true where mensagem.mensagem_id = 1;
update mensagem set lida = true where mensagem.mensagem_id = 0;

select * from caixa_de_mensagem;
*/
