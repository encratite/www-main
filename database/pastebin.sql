create table pastebinEntry
(
	id serial primary key,
	
	userId integer references siteUser(id),
	
	author text,
	ip text,

	description text,
	content text,
	highlightedContent text,
	
	pasteType text,
	
	creation timestamp,
	lastModification timestamp
);
