-- Worko · схема базы данных
-- Выполнить в Supabase → SQL Editor → New query → Run

-- ───────── справочники ─────────

create table if not exists sites (
  id          bigserial primary key,
  name        text not null unique
);

create table if not exists equipment (
  id          bigserial primary key,
  name        text not null,
  inv_no      text,
  site_id     bigint references sites(id) on delete set null,
  kind        text,
  criticality int default 2,          -- 1 низкая … 3 высокая
  qr_code     text unique             -- значение QR-бирки на оборудовании
);

create table if not exists fault_codes (
  code        text primary key,       -- М-02, Г-04, Э-07 …
  title       text not null,
  norm_min    int not null default 120
);

create table if not exists materials (
  id          bigserial primary key,
  name        text not null,
  unit        text not null,          -- шт, л, м
  norm_qty    numeric default 1       -- обычный расход на один наряд
);

-- ───────── люди ─────────

create table if not exists employees (
  id          uuid primary key default gen_random_uuid(),
  auth_id     uuid unique,            -- связь с auth.users
  staff_no    text not null unique,   -- табельный номер = логин
  full_name   text not null,
  role        text not null check (role in ('worker','master','manager','admin')),
  trade       text,                   -- слесарь, электрик, сварщик
  grade       int,                    -- разряд
  brigade     text,
  on_shift    boolean default true,
  rating      numeric default 0
);

-- ───────── наряды ─────────

create table if not exists orders (
  id            bigserial primary key,
  num           int not null unique,
  kind          text not null default 'unplanned' check (kind in ('planned','unplanned')),
  priority      text not null default 'normal' check (priority in ('emerg','high','normal','low')),
  problem       text not null,
  site_id       bigint references sites(id),
  equipment_id  bigint references equipment(id),
  assignee_id   uuid references employees(id),
  master_id     uuid references employees(id),
  status        text not null default 'issued'
                check (status in ('issued','accepted','queued','inprogress','paused',
                                  'done','check','rework','rejected','closed')),
  due_at        timestamptz not null,
  accept_by     timestamptz,          -- дедлайн ответа: 3 мин аварийный, 10 мин обычный
  started_at    timestamptz,
  finished_at   timestamptz,
  pause_reason  text,
  works         text,                 -- что сделано
  fault_code    text references fault_codes(code),
  created_at    timestamptz default now()
);

create index if not exists orders_assignee_idx on orders(assignee_id, status);
create index if not exists orders_status_idx   on orders(status);
create index if not exists orders_equip_idx    on orders(equipment_id, created_at);

-- журнал действий
create table if not exists order_events (
  id          bigserial primary key,
  order_id    bigint references orders(id) on delete cascade,
  actor_id    uuid references employees(id),
  action      text not null,          -- created, accepted, started, paused, done, closed …
  comment     text,
  at          timestamptz default now()
);

-- фото до/после
create table if not exists order_photos (
  id          bigserial primary key,
  order_id    bigint references orders(id) on delete cascade,
  phase       text not null check (phase in ('before','after')),
  path        text not null,          -- путь в Storage, бакет order-photos
  taken_at    timestamptz default now(),
  author_id   uuid references employees(id)
);

-- списанные материалы
create table if not exists order_materials (
  id          bigserial primary key,
  order_id    bigint references orders(id) on delete cascade,
  material_id bigint references materials(id),
  qty         numeric not null
);

-- вердикт ИИ
create table if not exists ai_reviews (
  id            bigserial primary key,
  order_id      bigint references orders(id) on delete cascade,
  verdict       text not null check (verdict in ('ok','warn','rework')),
  score         int not null check (score between 1 and 5),
  explanation   text,
  checks        jsonb,                -- массив проверок с результатами
  master_score  int,                  -- если мастер изменил оценку
  at            timestamptz default now()
);

-- ───────── права доступа ─────────

alter table orders           enable row level security;
alter table order_events     enable row level security;
alter table order_photos     enable row level security;
alter table order_materials  enable row level security;
alter table ai_reviews       enable row level security;
alter table employees        enable row level security;

create or replace function my_emp_id() returns uuid language sql stable as $$
  select id from employees where auth_id = auth.uid()
$$;

create or replace function my_role() returns text language sql stable as $$
  select role from employees where auth_id = auth.uid()
$$;

-- исполнитель видит только свои наряды, мастер и выше — все
create policy orders_read on orders for select using (
  assignee_id = my_emp_id() or my_role() in ('master','manager','admin')
);
create policy orders_write on orders for update using (
  assignee_id = my_emp_id() or my_role() in ('master','manager','admin')
);
create policy orders_insert on orders for insert with check (
  my_role() in ('master','admin')
);

create policy events_read on order_events for select using (true);
create policy events_insert on order_events for insert with check (my_emp_id() is not null);

create policy photos_all on order_photos for all using (my_emp_id() is not null);
create policy mats_all   on order_materials for all using (my_emp_id() is not null);
create policy ai_read    on ai_reviews for select using (true);
create policy ai_insert  on ai_reviews for insert with check (my_emp_id() is not null);

create policy emp_read on employees for select using (
  auth_id = auth.uid() or my_role() in ('master','manager','admin')
);

-- ───────── обновления в реальном времени ─────────
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table order_events;
