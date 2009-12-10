create table site_user
(
	id serial primary key,

	name text unique not null,
	password char(32) not null,
	
	email text not null,
	
	is_administrator boolean default false not null
);

create table login_session
(
	id serial primary key,
	
	user_id integer references site_user(id) not null,
	session_string char(128) unique not null,
	ip text not null,
	session_begin timestamp default current_timestamp not null
);

create index login_session_user_id_index on login_session (user_id);
