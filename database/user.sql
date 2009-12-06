create table site_user
(
	id serial primary key,

	name text unique,
	password text,
	
	email text,
	
	is_administrator boolean default false
);

create table login_session
(
	id serial primary key,
	
	user_id integer references site_user(id),
	session_string text,
	ip text,
	session_begin timestamp default current_timestamp
);
