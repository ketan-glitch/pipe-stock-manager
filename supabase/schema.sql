-- Run this complete script in Supabase Dashboard > SQL Editor.
-- Seed rows use ON CONFLICT DO NOTHING; rerunning won't reset stock.
create extension if not exists pgcrypto;
create table if not exists public.authorized_users(user_id uuid primary key references auth.users(id) on delete cascade,note text,created_at timestamptz not null default now());
create table if not exists public.inventory(id uuid primary key default gen_random_uuid(),colour_code text not null unique,colour_name text not null,quantity integer not null default 0 check(quantity>=0),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.stock_movements(id uuid primary key default gen_random_uuid(),inventory_id uuid references public.inventory(id) on delete set null,colour_code text not null,colour_name text not null,movement_type text not null check(movement_type in('in','out')),quantity integer not null check(quantity>0),reason text,created_by uuid references auth.users(id) on delete set null,created_at timestamptz not null default now());
create index if not exists stock_movements_created_at_idx on public.stock_movements(created_at desc);
alter table public.authorized_users enable row level security; alter table public.inventory enable row level security; alter table public.stock_movements enable row level security;
create or replace function public.is_authorized_stock_user() returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.authorized_users au where au.user_id=(select auth.uid())); $$;
revoke all on function public.is_authorized_stock_user() from public; grant execute on function public.is_authorized_stock_user() to authenticated;
drop policy if exists "Read own authorization" on public.authorized_users; create policy "Read own authorization" on public.authorized_users for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists "Authorized users read inventory" on public.inventory; create policy "Authorized users read inventory" on public.inventory for select to authenticated using(public.is_authorized_stock_user());
drop policy if exists "Authorized users read movements" on public.stock_movements; create policy "Authorized users read movements" on public.stock_movements for select to authenticated using(public.is_authorized_stock_user());
create or replace function public.record_stock_movement(p_inventory_id uuid,p_movement_type text,p_quantity integer,p_reason text default null) returns void language plpgsql security definer set search_path='' as $$
declare v_item public.inventory%rowtype;
begin
 if auth.uid() is null or not public.is_authorized_stock_user() then raise exception 'You are not authorized to manage this inventory.'; end if;
 if p_movement_type not in('in','out') then raise exception 'Movement type must be in or out.'; end if;
 if p_quantity is null or p_quantity<=0 then raise exception 'Quantity must be a positive whole number.'; end if;
 select * into v_item from public.inventory where id=p_inventory_id for update;
 if not found then raise exception 'Colour not found.'; end if;
 if p_movement_type='out' and v_item.quantity<p_quantity then raise exception 'Not enough stock. Available: % pieces.',v_item.quantity; end if;
 update public.inventory set quantity=case when p_movement_type='in' then quantity+p_quantity else quantity-p_quantity end,updated_at=now() where id=p_inventory_id;
 insert into public.stock_movements(inventory_id,colour_code,colour_name,movement_type,quantity,reason,created_by) values(v_item.id,v_item.colour_code,v_item.colour_name,p_movement_type,p_quantity,nullif(left(trim(coalesce(p_reason,'')),120),''),auth.uid());
end; $$;
revoke all on function public.record_stock_movement(uuid,text,integer,text) from public; grant execute on function public.record_stock_movement(uuid,text,integer,text) to authenticated;
insert into public.inventory(colour_code,colour_name,quantity) values
('YA-01','Wire Red',300),('YA-03','Bright Red',700),('YA-05','Maroon',300),('YA-06','Milky White',50),('YA-08','Colour (Cream)',50),('YA-09','Pure White',500),('YA-12','Mango Yellow',500),('YA-14','Bright Yellow',500),('YA-15','Dark Yellow',700),('YA-16','Gold Yellow',500),('YA-19','Light Flour',400),('YA-20','Powder Cake',500),('YA-21','Pink Jade',200),('YA-22','Deep Flour',400),('YA-23','Peach Red',50),('YA-24','Plum Red',50),('YA-27','Light Purple',200),('YA-28','Sky Blue',100),('YA-29','Taro Purple',500),('YA-30','Purple',400),('YA-31','Liuli',100),('YA-34','Fruit Green',100),('YA-37','Yellow-Green',200),('YA-40','Army Green',500),('YA-42','Moss Green',200),('YA-43','Dark Green',100),('YA-44','Light Coffee',100),('YA-45','Dark Coffee',400),('YA-46','Brown',100),('YA-47','Light Gray',100),('YA-49','Black',100),('YA-50','Light Lake Blue',300),('YA-52','Turquoise Blue',100),('YA-53','Peacock Blue',200),('YA-55','Blue',50),('YA-56','Deep Lake Blue',50),('YA-57','Sapphire Blue',200),('YA-58','Red-Purple',100),('YA-59','Eggplant Purple',50),('YA-60','Dark Green',50)
on conflict(colour_code) do nothing;
-- After creating your account in the app, copy its UUID from Authentication > Users and run:
-- insert into public.authorized_users(user_id,note) values('YOUR-USER-UUID','Inventory owner') on conflict(user_id) do nothing;
