insert into public.products (
  id,
  name,
  description,
  price,
  image_url,
  categories,
  is_active
)
values
  (
    '00000000-0000-0000-0000-000000000001',
    'Eames Lounge Chair',
    'The Eames Lounge Chair and Ottoman are furnishings made of molded plywood and leather, designed by Charles and Ray Eames.',
    4999.00,
    'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&q=80&w=600',
    array['Chairs', 'Living Room'],
    true
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'Noguchi Table',
    'A piece of modern furniture first produced in the mid-20th century. Introduced by Herman Miller in 1947.',
    1250.00,
    'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&q=80&w=600',
    array['Tables', 'Living Room'],
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'Tufty-Time Sofa',
    'Patricia Urquiola designed Tufty-Time, an informal seating system that combines comfort with a modular spirit.',
    3200.00,
    'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=600',
    array['Sofas', 'Living Room'],
    true
  )
on conflict (id) do update
  set name = excluded.name,
      description = excluded.description,
      price = excluded.price,
      image_url = excluded.image_url,
      categories = excluded.categories,
      is_active = excluded.is_active;

insert into public.product_models (
  product_id,
  model_url,
  model_type,
  is_primary
)
values
  (
    '00000000-0000-0000-0000-000000000001',
    'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    'glb',
    true
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb',
    'glb',
    true
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    'glb',
    true
  )
on conflict do nothing;
