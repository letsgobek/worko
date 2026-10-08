-- Worko · права на хранилище фото
-- Выполнить ПОСЛЕ создания бакета order-photos (Storage → New bucket, приватный)

insert into storage.buckets (id, name, public)
values ('order-photos','order-photos', false)
on conflict (id) do nothing;

create policy "worko upload photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'order-photos');

create policy "worko read photos"
on storage.objects for select to authenticated
using (bucket_id = 'order-photos');
