-- Worko · подготовка демо
-- Выполнять по частям, каждая часть независима.

-- ═══════════ ЧАСТЬ 1. Переименовать сотрудников ═══════════
-- Логины и ПИН-коды не меняются: 4417 / 1234 и 1102 / 5678

update employees set full_name = 'Л. Месси'   where staff_no = '4417';
update employees set full_name = 'К. Роналду' where staff_no = '1102';

select staff_no, full_name, role from employees order by staff_no;


-- ═══════════ ЧАСТЬ 2. Убрать наряды текущей смены ═══════════
-- Останется только история за 90 дней — она нужна аналитике ИИ.
-- Мастер начинает смену с чистой доски и выдаёт наряды сам.

delete from orders where status <> 'closed';

select status, count(*) from orders group by status;


-- ═══════════ ЧАСТЬ 3. Оставить только двух сотрудников ═══════════
-- ВНИМАНИЕ: после этого рейтинг исполнителей и вывод ИИ
-- «доработки сосредоточены на одном исполнителе» перестанут работать —
-- сравнивать будет не с кем. Выполняйте, только если это осознанное решение.

-- update orders
--   set assignee_id = (select id from employees where staff_no = '4417')
--   where assignee_id in (select id from employees where staff_no not in ('4417','1102'));
--
-- delete from employees where staff_no not in ('4417','1102');


-- ═══════════ ЧАСТЬ 4. Полная очистка (если нужен совсем чистый старт) ═══════════
-- ВНИМАНИЕ: удалит и историю за 90 дней. Аналитика, рейтинг и прогноз отказов
-- останутся пустыми — это минус 15 баллов по критерию «Аналитика».

-- truncate order_events, order_photos, order_materials, ai_reviews, orders
--   restart identity cascade;
