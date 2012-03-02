This library provides an Lwt logger which opens an HTTP listening port and
serves up log messages as JSON. It also includes a simple Bootstrap+jQuery HTML
page which regularly polls the JSON port on the server and renders them to a
web browser.

To try it out, just run 'make test' and connect to http://localhost:8080
immediately.

