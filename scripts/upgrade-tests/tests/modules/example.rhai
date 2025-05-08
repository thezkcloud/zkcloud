// Example test module

// explicitly export constants
export const URL = "http://127.0.0.1:8080/hello.txt";

// functions are always exported
fn fetch(url) {
    http_get(#{url: url});
}

