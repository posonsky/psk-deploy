vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend cpz {
  .host = "[::1]";
  .port = "8000";
}

backend static {
  .host = "[::1]";
  .port = "80";
}

acl local {
  "localhost";
}

sub vcl_recv {
  # Happens before we check if we have this in cache already.
  if (req.url ~ "/static/") {
    set req.backend_hint = static;

    unset req.http.Cookie;

  } else {
    set req.backend_hint = default;
  }

  if (req.method == "PURGE") {
    if (client.ip ~ local) {
      return(purge);
    } else {
      return(synth(403, "Access denied."));
    }
  }
}

sub vcl_backend_response {
  if (bereq.url ~ "/static/") {
    unset beresp.http.set-cookie;
    set beresp.ttl = 1h;
  }
  # Keep the response in cache for 4 hours if the response has
  # validating headers.
  if (beresp.http.ETag || beresp.http.Last-Modified) {
    set beresp.keep = 4h;
  }
}

