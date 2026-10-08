-- Worko · связка пользователей Supabase Auth с сотрудниками
--
-- Сначала создайте пользователей: Authentication → Users → Add user
--   email    = <табельный>@worko.kz
--   password = worko<ПИН>
-- Например: 4417@worko.kz / worko1234 и 1102@worko.kz / worko5678
-- Галочку Auto Confirm User включить.

update employees e
set auth_id = u.id
from auth.users u
where u.email = e.staff_no || '@worko.kz';

select staff_no, full_name, role, auth_id
from employees
where auth_id is not null;
