create table pastebin_entry
(
	id serial primary key,
	
	user_id integer references site_user(id),
	
	author text,
	ip text,

	description text,
	content text,
	highlighted_content text,
	
	paste_type text,
	
	creation timestamp,
	last_modification timestamp
);
