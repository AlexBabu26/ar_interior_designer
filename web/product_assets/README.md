# Local product assets (no Supabase Storage)

Store product images and 3D models here. They are served with the app when you run Flutter web.

- **`images/`** – product images (e.g. `.jpg`, `.png`)
- **`models/`** – 3D models for AR (e.g. `.glb`, `.gltf`). The admin product form can **upload** 3D files here via the Dart Frog server (`server/`). Run `dart_frog dev` from the `server/` directory so the "Upload file" button in Edit Product works; uploads are saved to this folder and the path (e.g. `/product_assets/models/xxx.glb`) is stored in Supabase.

In Supabase, set the model path in **`product_models.model_url`** to a **relative path** so the AR view loads the correct object:

- Example: `/product_assets/models/couch.glb`
- Example: `/product_assets/images/sofa.jpg`

Full URLs (e.g. `https://...`) also work; the app resolves relative paths to the current origin on web so local files load correctly.
