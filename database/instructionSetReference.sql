drop table if exists instruction cascade;

create table instruction
(
        id serial primary key,

        instruction_name text not null,
        description text not null,
        pseudo_code text not null,
        flags_affected text,
        fpu_flags_affected text
);

create index instruction_instruction_name_index on instruction(instruction_name);

drop table if exists instruction_opcode cascade;

create table instruction_opcode
(
        id serial primary key,

        instruction_id integer references instruction(id),

        opcode text not null,
        mnemonic_description text not null,
        encoding_identifier text,
        long_mode_validity text not null,
        legacy_mode_validity text not null,
        description text not null
);

create index instruction_opcode_instruction_id_index on instruction_opcode(instruction_id);

drop table if exists instruction_exception_category cascade;

create table instruction_exception_category
(
        id serial primary key,

        category_name text not null,
);

drop table if exists instruction_exception cascade;

create table instruction_exception
(
        id serial primary key,

        instruction_id integer references instruction(id),
        category_id integer references instruction_exception_description(id),

        exception_name text,
        description text not null
);

create index instruction_exception_instruction_id_index on instruction_exception(instruction_id);