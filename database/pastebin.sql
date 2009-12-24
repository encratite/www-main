drop table if exists pastebin_post cascade;

create table pastebin_post
(
	id serial primary key,
	
	user_id integer references site_user(id),
	
	--The author is null for the posts of registered users
	author text,
	ip text not null,

	description text not null,
	
	creation timestamp not null default now(),
	last_modification timestamp default null,
	
	--The expiration date is null when no expiration has been specified
	expiration timestamp,
	
	modification_counter integer not null default 0,
	
	--Contains the anonymous string for the URL for private pastebin entries - it is null for public posts
	anonymous_string text,
	
	--null if this is a new thread
	reply_to integer references pastebin_post(id)
);

drop table if exists pastebin_unit cascade;

create table pastebin_unit
(
	id serial primary key,
	
	post_id integer references pastebin_post(id) not null,
	
	description text not null,
	content text not null,
	highlighted_content text not null,
	
	paste_type text not null,
	
	time_added timestamp not null default now(),
	last_modification timestamp default null,
	
	modification_counter integer not null default 0
);

create index pastebin_unit_post_id on pastebin_unit(post_id);

create table flood_protection
(
	ip text not null,
	paste_time timestamp not null
);

create index flood_protection_ip on flood_protection(ip);
