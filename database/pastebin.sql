drop table if exists pastebin_post cascade;

create table pastebin_post
(
	id serial primary key,
	
	user_id integer references site_user(id),
	
	author text,
	ip text not null,

	description text not null,
	
	creation timestamp not null default now(),
	last_modification timestamp default null,
	
	expiration timestamp,
	
	modification_counter integer not null default 0
);

drop table if exists pastebin_unit cascade;

create table pastebin_unit
(
	id serial primary key,
	
	post_id integer references pastebin_post(id),
	
	description text not null,
	content text not null,
	highlighted_content text not null,
	
	paste_type text not null,
	
	time_added timestamp not null default now(),
	last_modification timestamp default null,
	
	modification_counter integer not null default 0
);

create index pastebin_unit_post_id on pastebin_unit (post_id);
