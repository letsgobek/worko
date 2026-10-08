-- Worko · права доступа
-- Выполнить в SQL Editor целиком, одним запуском.
-- Возвращает разграничение по ролям: исполнитель видит только свои наряды,
-- мастер и руководитель — все.

-- ───────── базовые привилегии ─────────
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

alter default privileges in schema public grant select on tables to anon, authenticated;

-- ───────── вспомогательные функции ─────────
create or replace function my_emp_id() returns uuid language sql stable security definer as $$
  select id from employees where auth_id = auth.uid()
$$;

create or replace function my_role() returns text language sql stable security definer as $$
  select role from employees where auth_id = auth.uid()
$$;

-- ───────── справочники: читают все, меняет только администратор ─────────
alter table sites       enable row level security;
alter table equipment   enable row level security;
alter table fault_codes enable row level security;
alter table materials   enable row level security;

drop policy if exists ref_read_sites on sites;
drop policy if exists ref_read_equip on equipment;
drop policy if exists ref_read_codes on fault_codes;
drop policy if exists ref_read_mats  on materials;
drop policy if exists pub_read_sites on sites;
drop policy if exists pub_read_equip on equipment;
drop policy if exists pub_read_codes on fault_codes;
drop policy if exists pub_read_mats  on materials;

create policy ref_read_sites on sites       for select using (true);
create policy ref_read_equip on equipment   for select using (true);
create policy ref_read_codes on fault_codes for select using (true);
create policy ref_read_mats  on materials   for select using (true);

create policy ref_write_equip on equipment for insert to authenticated
  with check (my_role() in ('master','admin'));
create policy ref_write_sites on sites for insert to authenticated
  with check (my_role() in ('master','admin'));

-- ───────── сотрудники ─────────
-- читать справочник нужно до входа, иначе не найти человека по табельному номеру.
-- паролей в таблице нет, они хранятся в auth.users.
alter table employees enable row level security;

drop policy if exists emp_read      on employees;
drop policy if exists emp_read_self on employees;
drop policy if exists emp_read_all  on employees;
drop policy if exists emp_login     on employees;

create policy emp_read on employees for select using (true);
create policy emp_update_self on employees for update to authenticated
  using (auth_id = auth.uid() or my_role() in ('master','admin'));

-- ───────── наряды ─────────
alter table orders enable row level security;

drop policy if exists orders_read   on orders;
drop policy if exists orders_write  on orders;
drop policy if exists orders_insert on orders;

create policy orders_read on orders for select to authenticated using (
  assignee_id = my_emp_id()
  or master_id = my_emp_id()
  or my_role() in ('master','manager','admin')
);

create policy orders_update on orders for update to authenticated using (
  assignee_id = my_emp_id() or my_role() in ('master','manager','admin')
);

create policy orders_insert on orders for insert to authenticated
  with check (my_role() in ('master','admin'));

create policy orders_delete on orders for delete to authenticated
  using (my_role() in ('master','admin'));

-- ───────── журнал, фото, материалы, вердикты ─────────
alter table order_events    enable row level security;
alter table order_photos    enable row level security;
alter table order_materials enable row level security;
alter table ai_reviews      enable row level security;

drop policy if exists events_read   on order_events;
drop policy if exists events_insert on order_events;
drop policy if exists photos_all    on order_photos;
drop policy if exists mats_all      on order_materials;
drop policy if exists ai_read       on ai_reviews;
drop policy if exists ai_insert     on ai_reviews;

create policy events_read   on order_events for select to authenticated using (true);
create policy events_insert on order_events for insert to authenticated
  with check (my_emp_id() is not null);

create policy photos_read   on order_photos for select to authenticated using (true);
create policy photos_write  on order_photos for insert to authenticated
  with check (my_emp_id() is not null);

create policy mats_read     on order_materials for select to authenticated using (true);
create policy mats_write    on order_materials for all to authenticated
  using (my_emp_id() is not null) with check (my_emp_id() is not null);

create policy ai_read       on ai_reviews for select to authenticated using (true);
create policy ai_insert     on ai_reviews for insert to authenticated
  with check (my_emp_id() is not null);
create policy ai_update     on ai_reviews for update to authenticated
  using (my_role() in ('master','manager','admin'));

-- ───────── проверка ─────────
select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
