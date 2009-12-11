drop table if exists site_user cascade;

create table site_user
(
	id serial primary key,

	name text unique not null,
	password bytea not null,
	
	email text not null,
	
	is_administrator boolean default false not null
);

drop table if exists login_session cascade;

create table login_session
(
	id serial primary key,
	
	user_id integer references site_user(id) not null,
	session_string char(128) unique not null,
	ip text not null,
	session_begin timestamp default current_timestamp not null
);

create index login_session_session_string on login_session (session_string);
