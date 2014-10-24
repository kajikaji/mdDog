create table docx_infos(
id serial primary key,
file_name text not null,
is_used boolean default true,
created_at timestamp,
deleted_at timestamp
);
