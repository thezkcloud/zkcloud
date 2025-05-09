import "utils" as utils;

describe("Performing an upgrade", || {
    it("should wait for the validator to come up first", || {
        wait_until(||{
            try {
                let res = parse_json(exec("curl localhost:26657/status | jq .result"));
                return parse_int(res.sync_info.latest_block_height) > 0;
            } catch (e) {
                return false;
            }
        }, "10s");
    });

    it("should be possible to stake some tokens from alice to the validator", || {
        let validator_address = "zkcloudvaloper1lgyhugv2cndldecl0pxqcgdagrnaa8femzzhuf";
        let res = parse_json(exec(`podman exec node /app/zkcloudd tx staking delegate ${validator_address} 100000000000uproof --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json`));
        require(res.code == 0, "Failed to stake tokens");
    });

    it("should be possible tosubmit an upgrade", || {
        exec("podman cp ./assets/upgrade-proposal.json node:/root/upgrade-proposal.json");
        utils::wait_one_block();
        let res = parse_json(exec("podman exec node /app/zkcloudd tx gov submit-proposal /root/upgrade-proposal.json --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json"));
        require(res.code == 0, "Failed to submit upgrade proposal");
    });

    it("should be possible to vote for an upgrade", || {
        utils::wait_one_block();
        let res = parse_json(exec("podman exec node /app/zkcloudd tx gov vote 1 yes --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json"));
        require(res.code == 0, "Failed to vote for upgrade proposal");
    });

    it("should execute the proposal in time", || {
        wait_until(||{
            let res = parse_json(exec("podman exec node /app/zkcloudd q gov proposal 1 -o json"));
            return res.proposal.status == "PROPOSAL_STATUS_PASSED";
        }, "10s");
    });

    it("should switch the binaries after block 14", || {
        wait_until(||{
            try {
                let res = exec("podman logs node 2>&1 |grep -E 'start.*cosmovisor.*v0.2.0'");
                return res.contains("v0.2.0");
            } catch (e) {
                return false;
            }
        }, "10s");
    });
    
    it("should reach block 15", || {
        utils::wait_for_block(15);
    });
    
});

