fn wait_one_block() {
    let res = parse_json(exec("curl localhost:26657/status | jq .result"));
    let height = parse_int(res.sync_info.latest_block_height);
    wait_for_block(height + 1);
}

fn wait_for_block(height) {
    wait_until(||{
        try {
            let res = parse_json(exec("curl localhost:26657/status | jq .result"));
            return parse_int(res.sync_info.latest_block_height) >= height;
        } catch (e) {
            return false;
        }
    }, "10s");
}