/**
 * Waits for the next block to be produced.
 * 
 * Gets the current block height and then waits until a new block is produced.
 */
fn wait_one_block(node) {
    let endpoint = exec(`podman port ${node} 26657`);
    endpoint.trim();
    let res = parse_json(exec(`curl -s ${endpoint}/status | jq .result`));
    let height = parse_int(res.sync_info.latest_block_height);
    wait_for_block(node, height + 1);
}

/**
 * Waits until the blockchain reaches a specific block height.
 * 
 * @param height - The target block height to wait for
 */
fn wait_for_block(node, height) {
    let endpoint = exec(`podman port ${node} 26657`);
    endpoint.trim();
    wait_until(||{
        try {
            let res = parse_json(exec(`curl -s ${endpoint}/status | jq .result`));
            return parse_int(res.sync_info.latest_block_height) >= height;
        } catch (e) {
            return false;
        }
    }, "10s");
}

/**
 * Retrieves block information from the blockchain.
 * 
 * @param height - Optional block height to retrieve (retrieves latest if not specified)
 * @return The block data as a JSON object
 */
fn get_block(node, height) {
    let endpoint = exec(`podman port ${node} 26657`);
    endpoint.trim();
    let url = `${endpoint}/block`;
    if (height != ()) {
        url += `?height=${height}`;
    }
    let block = exec(`curl -s ${url}`);
    return parse_json(block).result;
}

/**
 * Waits for a specified number of new blocks to be produced.
 * 
 * @param node - The node to query for block height
 * @param n - Number of blocks to wait for
 * @param timeout - Maximum time to wait
 */
fn wait_for_n_blocks(node, n, timeout) {
    let start_height = current_block_height(node);
    wait_until(|| {
        let height = current_block_height(node);
        return height >= start_height + n;
    }, timeout);
}

/**
 * Waits for the next block to be produced.
 * 
 * @param timeout - Maximum time to wait for the next block
 * @return The result of the wait operation
 */
fn wait_for_next_block(node, timeout) {
    return wait_for_n_blocks(node, 1, timeout);
}

/**
 * Gets the current block height from a specified node.
 * 
 * @param node - The node to query
 * @return The current block height as an integer
 */
fn current_block_height(node) {
    let data = get_block(node, ());
    return parse_int(data.block.header.height);
}

/**
 * Checks if the node is healthy by verifying it's not catching up and is producing blocks.
 * 
 * First checks if the node is not in catching up state and has a positive block height.
 * Then waits for a new block to be produced to confirm the node is actively producing blocks.
 */
fn check_health(node) {
    let endpoint = exec(`podman port ${node} 26657`);
    endpoint.trim();
    let res = parse_json(exec(`curl -s ${endpoint}/status | jq .result`));
    let catching_up = res.sync_info.catching_up;
    let height = parse_int(res.sync_info.latest_block_height);
    assert(catching_up == false, `Node shows catching_up = true`);
    assert(height > 0, `Node height is not greater than 0`);
    wait_until(|| {
        let res = parse_json(exec(`curl -s ${endpoint}/status | jq .result`));
        let new_height = parse_int(res.sync_info.latest_block_height);
        return new_height > height;
    }, "1500ms");
}

fn wait_for_fullnode(node, timeout) {
    let endpoint = exec(`podman port ${node} 26657`);
    endpoint.trim();
    wait_until(|| {
        try {
            let res = exec(`curl -s ${endpoint}/status | jq .result`);
            let res = parse_json(res);
            let catching_up = res.sync_info.catching_up;
            let height = parse_int(res.sync_info.latest_block_height);
            return catching_up == false && height > 0;
        } catch (e) {
            return false;
        }
    }, timeout);
}

/**
 * Sends tokens from one account to another.
 * 
 * @param from - Sender account (can be alice or bob)
 * @param to - Recipient account (address, can be constants::ALICE or constants::BOB)
 * @param amount - Amount of tokens to send, i.e. "100uproof"
 * @return The transaction hash of the send operation
 */
fn send_token(from, to, amount) {
    let res = exec(`podman exec validator /app/zkcloudd tx bank send ${from} ${to} ${amount} --from ${from} --chain-id zkcloud --keyring-backend test --yes -o json --fees 1000uproof`);
    let response = parse_json(res);
    require(response.txhash != "", `Failed to send token from ${from} to ${to}: ${response}`);
    return response.txhash;
}

/**
 * Waits for a transaction to be confirmed on the blockchain.
 * 
 * @param txhash - The transaction hash to wait for
 */
fn wait_for_tx(node, txhash) {
    wait_until(|| {
        try {
            let res = exec(`podman exec ${node} /app/zkcloudd q tx ${txhash} -o json`);
            let response = parse_json(res);
            return response.code == 0;
        } catch (e) {
            return false;
        }
    }, "1500ms");
}

fn start_validator() {
    let command = `podman run -d --name validator --replace \
        --network test-network \
        -v ./assets/validator:/root/.zkcloud \
        -p 26657 -p 9090 \
        quay.io/thezkcloud/node:latest \
            start`;
    exec(command);
}


fn start_fullnode(name) {
    let command = `podman run -d --name ${name} --replace \
        --network test-network \
        -v ./assets/${name}:/root/.zkcloud \
        -p 26657 -p 9090 \
        quay.io/thezkcloud/node:latest \
            start --p2p.persistent_peers=305ff9a46c0b6de64949340dc2cf2a731a37bc11@validator:26656`;
    exec(command);
}
