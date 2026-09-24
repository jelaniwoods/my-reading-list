# Browser capabilities start closed. Widen a directive deliberately when an
# application feature needs it, for example camera access for uploads.
Rails.application.config.action_dispatch.default_headers["Permissions-Policy"] = [
  "camera=()",
  "geolocation=()",
  "microphone=()",
  "payment=()",
  "usb=()"
].join(", ")
