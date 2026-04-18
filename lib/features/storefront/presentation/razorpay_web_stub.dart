// Stub for non-web platforms.
// This file is imported when NOT running on web.
// These functions are no-ops on mobile/desktop.

void openRazorpayWeb(
  Map<String, dynamic> options,
  void Function(String paymentId) onSuccess,
  void Function(String error) onError,
) {
  // Not supported on this platform — should never be called.
  onError('Web Razorpay is not available on this platform.');
}
