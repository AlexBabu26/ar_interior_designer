-- Add stock_quantity to products and ensure defaults
alter table public.products 
add column if not exists stock_quantity integer not null default 0;

-- Update existing products to have some stock so they aren't all "Sold out"
update public.products
set stock_quantity = 10
where stock_quantity = 0;
