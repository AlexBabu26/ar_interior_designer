create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

alter table public.products enable row level security;
alter table public.product_models enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'products'
      and policyname = 'Products are readable by everyone'
  ) then
    create policy "Products are readable by everyone"
      on public.products
      for select
      using (is_active or public.is_admin());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'products'
      and policyname = 'Admins manage products'
  ) then
    create policy "Admins manage products"
      on public.products
      for all
      to authenticated
      using (public.is_admin())
      with check (public.is_admin());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'product_models'
      and policyname = 'Product models are readable by everyone'
  ) then
    create policy "Product models are readable by everyone"
      on public.product_models
      for select
      using (
        exists (
          select 1
          from public.products
          where products.id = product_models.product_id
            and (products.is_active or public.is_admin())
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'product_models'
      and policyname = 'Admins manage product models'
  ) then
    create policy "Admins manage product models"
      on public.product_models
      for all
      to authenticated
      using (public.is_admin())
      with check (public.is_admin());
  end if;
end
$$;
