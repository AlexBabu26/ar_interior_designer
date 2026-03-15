# AR View: Background and Camera Behavior

## What the app supports today

### Image background apparent size (“too zoomed in”)

When you use a custom image as the AR background (from “My images” or “Upload new image”), the app now uses a **wider field of view** (75° default, up to 90° when you zoom out) so more of the background image is visible and it appears at a more natural size instead of cropped/zoomed in. You can still pinch or scroll to zoom in on the object (down to 30°) or zoom out to see even more of the background (up to 90°).

### 1. **Keep the background static and zoom in/out on the AR object** — **Yes**

This is the **default behavior** when you use the 3D viewer:

- **Pinch** (touch) or **scroll** (mouse) zooms the camera toward or away from the 3D model.
- The skybox/background image is drawn at “infinity,” so it does not noticeably zoom; only the object appears to get closer or farther.
- So with an image background selected, the background effectively stays fixed while you zoom the object.

**In the app:** When you have an image background set, a short tip is shown: *“The view is widened so more of the background shows. Pinch or scroll to zoom in/out on the object.”*

---

### 2. **Keep the AR object static and move/adjust the background** — **Not in the current app**

- The underlying **model-viewer** component does **not** expose a simple “rotate only the background” or “move only the skybox” control.
- The camera orbits around the whole scene (model + environment). When you drag to orbit, both the model and the background move together from the user’s point of view.
- To get “model static, background moving” you would need custom JavaScript that:
  - Listens to pointer/touch input,
  - Computes rotation deltas,
  - Uses the model-viewer API (e.g. `resetTurntableRotation()`) to keep the model still while effectively rotating the environment.
- That logic is not implemented in the current Flutter app or in the **model_viewer_plus** wrapper, so **this behavior is not available** in the app today. It could be added later by injecting custom JS (e.g. via `relatedJs` / `innerModelViewerHtml`) and wiring it to the web component.

---

## Summary

| Behavior | Supported? | Notes |
|----------|------------|--------|
| Background static, zoom in/out on object | **Yes** | Use pinch or scroll; tip shown when image background is on. |
| Object static, move/adjust background | **No** | Would require custom JS and model-viewer API usage; not implemented. |
