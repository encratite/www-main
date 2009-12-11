drop table pastebin_entry cascade;

create table pastebin_entry
(
	id serial primary key,
	
	user_id integer references site_user(id),
	
	author text,
	ip text not null,

	description text not null,
	content text not null,
	highlighted_content text not null,
	
	paste_type text not null,
	
	creation timestamp not null,
	last_modification timestamp not null
);
