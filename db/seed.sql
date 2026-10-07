-- Worko · тестовый набор данных
-- Выполнять ПОСЛЕ schema.sql

-- ───────── участки ─────────
insert into sites (name) values
 ('Дробление'), ('Обогащение'), ('РМЦ'), ('Карьер')
on conflict (name) do nothing;

-- ───────── оборудование ─────────
insert into equipment (name, inv_no, site_id, kind, criticality, qr_code) values
 ('Дробилка КМД-1750', '04-2101', (select id from sites where name='Дробление'),  'дробилка', 3, 'WORKO-EQ-2101'),
 ('Конвейер К-3',      '04-2102', (select id from sites where name='Дробление'),  'конвейер', 3, 'WORKO-EQ-2102'),
 ('Конвейер К-7',      '04-2103', (select id from sites where name='Дробление'),  'конвейер', 2, 'WORKO-EQ-2103'),
 ('Грохот ГИТ-51',     '04-2104', (select id from sites where name='Дробление'),  'грохот',   2, 'WORKO-EQ-2104'),
 ('Питатель ПК-12',    '04-2105', (select id from sites where name='Дробление'),  'питатель', 2, 'WORKO-EQ-2105'),
 ('Насос НЦ-250',      '04-2217', (select id from sites where name='Обогащение'), 'насос',    3, 'WORKO-EQ-2217'),
 ('Насос НЦ-180',      '04-2218', (select id from sites where name='Обогащение'), 'насос',    2, 'WORKO-EQ-2218'),
 ('Мельница МШР-2',    '04-2219', (select id from sites where name='Обогащение'), 'мельница', 3, 'WORKO-EQ-2219'),
 ('Сгуститель Ц-9',    '04-2220', (select id from sites where name='Обогащение'), 'сгуститель',2,'WORKO-EQ-2220'),
 ('Вентилятор ВЦ-14',  '04-2221', (select id from sites where name='Обогащение'), 'вентилятор',1,'WORKO-EQ-2221'),
 ('Кран-балка РМЦ-1',  '04-2301', (select id from sites where name='РМЦ'),        'кран',     2, 'WORKO-EQ-2301'),
 ('Станок 16К20',      '04-2302', (select id from sites where name='РМЦ'),        'станок',   1, 'WORKO-EQ-2302'),
 ('Пресс П-63',        '04-2303', (select id from sites where name='РМЦ'),        'пресс',    1, 'WORKO-EQ-2303')
on conflict do nothing;

-- ───────── шифры неисправностей ─────────
insert into fault_codes (code, title, norm_min) values
 ('М-01','Механические: крепёж, соосность', 120),
 ('М-02','Механические: подшипниковый узел', 240),
 ('М-03','Механические: износ ленты, ролика', 180),
 ('Э-01','Электрические: пускатель',          90),
 ('Э-07','Электрические: обрыв цепи питания', 120),
 ('Г-04','Гидравлика и смазка: течь',         120),
 ('П-01','Пневматика: утечка воздуха',        180),
 ('С-03','Смазка узлов по регламенту',         60)
on conflict (code) do nothing;

-- ───────── материалы ─────────
insert into materials (name, unit, norm_qty) values
 ('Прокладка фланцевая 180 мм', 'шт', 2),
 ('Масло И-40А',                'л',  2),
 ('Подшипник 7312',             'шт', 1),
 ('Кабель ВВГ 3х2.5',           'м',  10),
 ('Манжета 50х70',              'шт', 2),
 ('Лента конвейерная',          'м',  3),
 ('Смазка Литол-24',            'кг', 1)
on conflict do nothing;

-- ───────── сотрудники ─────────
-- auth_id проставляется после создания пользователей в Supabase Auth
insert into employees (staff_no, full_name, role, trade, grade, brigade) values
 ('1102','Сағынтаев Б.',  'master', 'мастер смены', null, null),
 ('4417','Ким В.',        'worker', 'электрик',   4, 'Бригада 2'),
 ('4418','Ахметов Е.',    'worker', 'слесарь',    5, 'Бригада 1'),
 ('4419','Нұрланов А.',   'worker', 'слесарь',    6, 'Бригада 1'),
 ('4420','Жұмабеков Д.',  'worker', 'сварщик',    5, 'Бригада 3'),
 ('4421','Петров С.',     'worker', 'слесарь',    4, 'Бригада 2'),
 ('4422','Оспанов Р.',    'worker', 'электрик',   5, 'Бригада 3'),
 ('1001','Главный механик','manager','руководитель', null, null)
on conflict (staff_no) do nothing;

-- ───────── наряды текущей смены ─────────
insert into orders (num, kind, priority, problem, site_id, equipment_id, assignee_id, master_id, status, due_at, accept_by)
values
 (152,'unplanned','emerg','Течь масла по корпусу насоса, подтёк под фланцем',
  (select id from sites where name='Обогащение'),
  (select id from equipment where inv_no='04-2217'),
  (select id from employees where staff_no='4417'),
  (select id from employees where staff_no='1102'),
  'issued', now() + interval '2 hours', now() + interval '3 minutes'),

 (151,'unplanned','normal','Повышенная вибрация на холостом ходу',
  (select id from sites where name='Дробление'),
  (select id from equipment where inv_no='04-2104'),
  (select id from employees where staff_no='4417'),
  (select id from employees where staff_no='1102'),
  'issued', now() + interval '6 hours', now() + interval '10 minutes'),

 (147,'unplanned','emerg','Стук в подшипниковом узле, ждём подшипник',
  (select id from sites where name='Дробление'),
  (select id from equipment where inv_no='04-2101'),
  (select id from employees where staff_no='4418'),
  (select id from employees where staff_no='1102'),
  'inprogress', now() - interval '45 minutes', null),

 (148,'unplanned','high','Проскальзывает лента питателя',
  (select id from sites where name='Дробление'),
  (select id from equipment where inv_no='04-2105'),
  (select id from employees where staff_no='4419'),
  (select id from employees where staff_no='1102'),
  'inprogress', now() + interval '3 hours', null),

 (144,'planned','normal','Не запускается, щит без напряжения',
  (select id from sites where name='Обогащение'),
  (select id from equipment where inv_no='04-2221'),
  (select id from employees where staff_no='4417'),
  (select id from employees where staff_no='1102'),
  'queued', now() + interval '5 hours', null)
on conflict (num) do nothing;

-- ───────── история за 90 дней с заложенными закономерностями ─────────
-- 1) Конвейер К-3 ломается втрое чаще прочих, в основном шифр М-02
-- 2) У Петрова С. доля возвратов на доработку втрое выше средней
-- 3) По шифру Г-04 в ночную смену завышен расход масла
do $$
declare
  d int; j int; n int := 1000;
  eq record; emp record; code text; is_planned boolean; hour int;
begin
  for d in reverse 90..1 loop
    for j in 1..(4 + floor(random()*4)::int) loop
      n := n + 1;

      if random() < 0.14 then
        select * into eq from equipment where inv_no='04-2102';     -- К-3
        code := 'М-02';
      else
        select * into eq from equipment order by random() limit 1;
        select fc.code into code from fault_codes fc order by random() limit 1;
      end if;

      select * into emp from employees where role='worker' order by random() limit 1;
      is_planned := random() < 0.38;
      hour := 6 + floor(random()*18)::int;

      insert into orders (num, kind, priority, problem, site_id, equipment_id,
                          assignee_id, master_id, status, due_at, started_at, finished_at, works, fault_code, created_at)
      values (n,
        case when is_planned then 'planned' else 'unplanned' end,
        case when is_planned then 'low' when random() < 0.25 then 'emerg' else 'normal' end,
        'Работы по шифру ' || code,
        eq.site_id, eq.id, emp.id,
        (select id from employees where staff_no='1102'),
        'closed',
        now() - (d || ' days')::interval,
        now() - (d || ' days')::interval,
        now() - (d || ' days')::interval + interval '2 hours',
        'Выполнено по регламенту', code,
        now() - (d || ' days')::interval);

      insert into ai_reviews (order_id, verdict, score, explanation)
      select o.id,
        case when emp.staff_no='4421' and random() < 0.26 then 'rework'
             when random() < 0.25 then 'warn' else 'ok' end,
        case when emp.staff_no='4421' and random() < 0.26 then 3
             when random() < 0.25 then 4 else 5 end,
        'Автогенерация тестовой истории'
      from orders o where o.num = n;

      if code = 'Г-04' then
        insert into order_materials (order_id, material_id, qty)
        select o.id, (select id from materials where name='Масло И-40А'),
               case when hour >= 22 or hour < 6 then 2 + floor(random()*3) else 2 end
        from orders o where o.num = n;
      end if;
    end loop;
  end loop;
end $$;
