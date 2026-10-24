-- 진도깨 기기 연동용 테이블 (Supabase SQL Editor에서 한 번 실행)
create table if not exists public.user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null,
  device text,
  updated_at timestamptz not null default now()
);
create table if not exists public.user_data_hist (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null,
  device text,
  saved_at timestamptz not null
);
create index if not exists user_data_hist_user_idx on public.user_data_hist(user_id, saved_at desc);
alter table public.user_data enable row level security;
alter table public.user_data_hist enable row level security;
create policy "own select" on public.user_data for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_data for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_data for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own delete" on public.user_data for delete to authenticated using ((select auth.uid()) = user_id);
create policy "own hist select" on public.user_data_hist for select to authenticated using ((select auth.uid()) = user_id);
create policy "own hist delete" on public.user_data_hist for delete to authenticated using ((select auth.uid()) = user_id);

-- 저장 시각은 서버가 정하고, 이전 버전은 30분 간격으로 최대 5개 보관
create or replace function public.user_data_before_update() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.user_data_hist h where h.user_id = old.user_id and h.saved_at > now() - interval '30 minutes') then
    insert into public.user_data_hist(user_id, data, device, saved_at) values (old.user_id, old.data, old.device, old.updated_at);
    delete from public.user_data_hist h where h.user_id = old.user_id and h.id not in (select id from public.user_data_hist where user_id = old.user_id order by saved_at desc limit 5);
  end if;
  new.updated_at := clock_timestamp();
  return new;
end $$;
revoke all on function public.user_data_before_update() from public, anon, authenticated;
create trigger user_data_bu before update on public.user_data for each row execute function public.user_data_before_update();

create or replace function public.user_data_before_insert() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at := clock_timestamp(); return new; end $$;
create trigger user_data_bi before insert on public.user_data for each row execute function public.user_data_before_insert();
revoke all on public.user_data, public.user_data_hist from anon;
