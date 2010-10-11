drop table if exists pastebin_post cascade;

create table pastebin_post
(
	id serial primary key,
	
	user_id integer references site_user(id),
	
	--The author is null for the posts of registered users
	author text,
	ip text not null,

	description text not null,
	
	creation timestamp not null,
	last_modification timestamp default null,
	modification_counter integer not null default 0,
	
	--The expiration date is null when no expiration has been specified
	expiration timestamp,
	
	--This index into an array in the Ruby code specifies the expiration option which was used when the post was created originally
	--It is used when the post is edited
	expiration_index int not null,
	
	--Contains the private string for the URL for private pastebin entries - it is null for public posts
	private_string text,
	
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
	
	--null if the content type of this unit is marked as plain text
	highlighted_content text,
	
	paste_type text,
	
	time_added timestamp not null,
	last_modification timestamp default null,
	
	modification_counter integer not null default 0
);

create index pastebin_unit_post_id on pastebin_unit(post_id);

drop table if exists flood_protection cascade;

create table flood_protection
(
	ip text not null,
	paste_time timestamp not null
);

create index flood_protection_ip on flood_protection(ip);
