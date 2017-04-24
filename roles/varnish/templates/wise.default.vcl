vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend bratsk_pravoslavny {
  .host = "127.0.0.1";
  .port = "8080";
}

backend static {
  .host = "[::1]";
  .port = "80";
}

backend eganovo_pokrova {
  .host = "127.0.0.1";
  .port = "8081";
}

acl local {
  "127.0.0.1";
}

sub vcl_recv {
  # Happens before we check if we have this in cache already.
  if (req.http.host ~ "bratsk-pravoslavny.ru") {
    if (req.url ~ "/wf/") {
      unset req.http.Cookie;
      set req.backend_hint = static;
    } else {
      set req.backend_hint = bratsk_pravoslavny;
    }
  } elsif (req.http.host ~ "eganovo-pokrova.ru") {
    set req.backend_hint = eganovo_pokrova;
  }

  if (req.http.Cookie) {
    # Do Plone cookie sanitization, so cookies do not destroy cacheable
    # anonymous pages
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie,
      ";(statusmessages|__ac|_ZopeId|__cp)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      unset req.http.Cookie;
    }
  }

  if ((req.url ~ "/portal_css/")
      || (req.url ~ "/portal_javascripts/")) {
    unset req.http.Cookie;
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
  if ((bereq.url ~ "/portal_css/")
        || (bereq.url ~ "/portal_javascripts/")) {
    unset beresp.http.set-cookie;
    set beresp.ttl = 1h;
  }

  # Keep the response in cache for 4 hours if the response has
  # validating headers.
  if (beresp.http.ETag || beresp.http.Last-Modified) {
    set beresp.keep = 4h;
  }
}

/*
Commands:

varnishstat -f MAIN.uptime -f MAIN.cache_hit -f MAIN.cache_hitpass \
  -f MAIN.cache_hitmiss -f MAIN.cache_miss

varnishtop -i BereqURL

*/
