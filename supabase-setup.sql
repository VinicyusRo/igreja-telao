-- ==========================================================
-- Assembleia de Deus – Ministério Madureira
-- PASSO 1: rode este bloco inteiro no SQL Editor (pode rodar de novo sem problema)
-- ==========================================================

-- Tabelas
create table if not exists public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  usuario text unique not null,
  nome text,
  papel text not null check (papel in ('admin','recepcao','midia','telao'))
);
create table if not exists public.membros (
  id bigint generated always as identity primary key,
  nome text not null,
  dia smallint not null check (dia between 1 and 31),
  mes smallint not null check (mes between 1 and 12),
  ministerio text,
  foto text,
  criado_em timestamptz default now()
);
create table if not exists public.visitantes (
  id bigint generated always as identity primary key,
  nome text not null,
  qtd int default 1,
  bairro text,
  quem text,
  primeira boolean default true,
  criado_em timestamptz default now(),
  criado_por uuid default auth.uid()
);
create table if not exists public.avisos (
  id bigint generated always as identity primary key,
  titulo text not null,
  texto text,
  img text,
  ativo boolean default true,
  criado_em timestamptz default now()
);

-- Função que diz qual é o perfil de quem está logado
create or replace function public.papel() returns text
language sql stable security definer set search_path = public as
$$ select papel from public.perfis where id = auth.uid() $$;
revoke all on function public.papel() from public, anon;
grant execute on function public.papel() to authenticated;

-- Segurança em nível de linha (RLS)
alter table public.perfis     enable row level security;
alter table public.membros    enable row level security;
alter table public.visitantes enable row level security;
alter table public.avisos     enable row level security;

-- Permissões básicas (só para quem está logado; visitantes anônimos não têm nada)
grant select on public.perfis to authenticated;
grant select, insert, update, delete on public.membros, public.visitantes, public.avisos to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Regras por perfil
drop policy if exists perfis_ler on public.perfis;
create policy perfis_ler on public.perfis for select to authenticated
  using (id = auth.uid() or public.papel() = 'admin');

-- Todos os perfis podem VER membros, visitantes e avisos
drop policy if exists membros_ler on public.membros;
create policy membros_ler on public.membros for select to authenticated using (public.papel() is not null);
drop policy if exists visitantes_ler on public.visitantes;
create policy visitantes_ler on public.visitantes for select to authenticated using (public.papel() is not null);
drop policy if exists avisos_ler on public.avisos;
create policy avisos_ler on public.avisos for select to authenticated using (public.papel() is not null);

-- Membros: só o administrador edita
drop policy if exists membros_gravar on public.membros;
create policy membros_gravar on public.membros for all to authenticated
  using (public.papel() = 'admin') with check (public.papel() = 'admin');

-- Visitantes: administrador e recepção editam
drop policy if exists visitantes_gravar on public.visitantes;
create policy visitantes_gravar on public.visitantes for all to authenticated
  using (public.papel() in ('admin','recepcao')) with check (public.papel() in ('admin','recepcao'));

-- Avisos: administrador e mídia editam
drop policy if exists avisos_gravar on public.avisos;
create policy avisos_gravar on public.avisos for all to authenticated
  using (public.papel() in ('admin','midia')) with check (public.papel() in ('admin','midia'));

-- Atualização em tempo real (o telão se atualiza sozinho)
do $$ declare t text; begin
  foreach t in array array['membros','visitantes','avisos'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null; end;
  end loop;
end $$;

-- ==========================================================
-- PASSO 2: rode SÓ DEPOIS de criar os 4 usuários em Authentication > Users
-- (e-mails internos: admvini@igreja.local, admidia@igreja.local,
--  recepcao@igreja.local, adtelao@igreja.local). Não leva senha.
-- ==========================================================
insert into public.perfis (id, usuario, nome, papel)
select id, split_part(email,'@',1), split_part(email,'@',1),
  case split_part(email,'@',1)
    when 'admvini'  then 'admin'
    when 'admidia'  then 'midia'
    when 'recepcao' then 'recepcao'
    when 'adtelao'  then 'telao'
  end
from auth.users
where email in ('admvini@igreja.local','admidia@igreja.local','recepcao@igreja.local','adtelao@igreja.local')
on conflict (id) do update set papel = excluded.papel, usuario = excluded.usuario;
