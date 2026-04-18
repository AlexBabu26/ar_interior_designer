// Web implementation using dart:js_interop.
// Only compiled when targeting web (dart.library.js is available).
import 'dart:js_interop';

@JS('openRazorpayCheckout')
external void _openRazorpayCheckout(
  JSObject options,
  JSFunction onSuccess,
  JSFunction onError,
);

void openRazorpayWeb(
  Map<String, dynamic> options,
  void Function(String paymentId) onSuccess,
  void Function(String error) onError,
) {
  try {
    final jsOptions = options.jsify()! as JSObject;
    _openRazorpayCheckout(
      jsOptions,
      ((JSString paymentId) => onSuccess(paymentId.toDart)).toJS,
      ((JSString error) => onError(error.toDart)).toJS,
    );
  } catch (e) {
    onError(e.toString());
  }
}
