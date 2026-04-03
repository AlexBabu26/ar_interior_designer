const openAiApiKey =
    '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';

/// CORS proxy on the Dart Frog dev server. Set to null to call OpenAI directly
/// (works on mobile/desktop; web requires the proxy for CORS).
const openAiProxyUrl = 'http://localhost:8080/generate_openai_image';
