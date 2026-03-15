create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id),
  product_name text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  line_total numeric(12,2) not null check (line_total >= 0)
);

create or replace function public.checkout_active_cart()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  active_cart public.carts%rowtype;
  new_order_id uuid;
  subtotal_amount numeric(12,2);
  generated_order_number text;
begin
  select *
  into active_cart
  from public.carts
  where user_id = auth.uid()
    and status = 'active'
  limit 1;

  if active_cart.id is null then
    raise exception 'No active cart found for the current user.';
  end if;

  select coalesce(sum(products.price * cart_items.quantity), 0)
  into subtotal_amount
  from public.cart_items
  join public.products on products.id = cart_items.product_id
  where cart_items.cart_id = active_cart.id;

  if subtotal_amount = 0 then
    raise exception 'Your cart is empty.';
  end if;

  generated_order_number := 'ORD-' || to_char(timezone('utc', now()), 'YYYYMMDDHH24MISSMS');

  insert into public.orders (
    user_id,
    order_number,
    status,
    subtotal,
    total
  )
  values (
    auth.uid(),
    generated_order_number,
    'placed',
    subtotal_amount,
    subtotal_amount
  )
  returning id into new_order_id;

  insert into public.order_items (
    order_id,
    product_id,
    product_name,
    unit_price,
    quantity,
    line_total
  )
  select
    new_order_id,
    products.id,
    products.name,
    products.price,
    cart_items.quantity,
    products.price * cart_items.quantity
  from public.cart_items
  join public.products on products.id = cart_items.product_id
  where cart_items.cart_id = active_cart.id;

  update public.carts
  set status = 'checked_out'
  where id = active_cart.id;

  insert into public.carts (user_id, status)
  values (auth.uid(), 'active')
  on conflict do nothing;

  return new_order_id;
end;
$$;
