import "example" as example;

describe("Example Test Suite", || {
    it("should respond to HTTP requests", || {
        // Make request to Caddy server
        let response = example::fetch(example::URL);
        
        // Validate response
        assert(response == "hello world", "Expected valid response from server");
    });
});