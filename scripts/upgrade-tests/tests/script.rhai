import "utils" as utils;
import "constants" as constants;

describe("Performing an upgrade", || {
    it("should wait for the validator to come up first", || {
        utils::start_validator();
        utils::wait_for_fullnode("validator", "10s");
    });

    it("should be possible to stake some tokens from alice to the validator", || {
        let validator_address = "zkcloudvaloper1lgyhugv2cndldecl0pxqcgdagrnaa8femzzhuf";
        let res = parse_json(exec(`podman exec validator /app/zkcloudd tx staking delegate ${validator_address} 100000000000uproof --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json`));
        require(res.code == 0, "Failed to stake tokens");
    });

    it("should be possible tosubmit an upgrade", || {
        exec("podman cp ./assets/upgrade-proposal.json validator:/root/upgrade-proposal.json");
        utils::wait_one_block("validator");
        let res = parse_json(exec("podman exec validator /app/zkcloudd tx gov submit-proposal /root/upgrade-proposal.json --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json"));
        require(res.code == 0, "Failed to submit upgrade proposal");
    });

    it("should be possible to vote for an upgrade", || {
        utils::wait_one_block("validator");
        let res = parse_json(exec("podman exec validator /app/zkcloudd tx gov vote 1 yes --from alice --chain-id zkcloud --keyring-backend test --fees 250uproof --yes -o json"));
        require(res.code == 0, "Failed to vote for upgrade proposal");
    });

    it("should execute the proposal in time", || {
        wait_until(||{
            let res = parse_json(exec("podman exec validator /app/zkcloudd q gov proposal 1 -o json"));
            return res.proposal.status == "PROPOSAL_STATUS_PASSED";
        }, "10s");
    });

    it("should switch the binaries after block 14", || {
        wait_until(||{
            try {
                let res = exec("podman logs validator 2>&1 |grep -E 'start.*cosmovisor.*v0.2.0'");
                return res.contains("v0.2.0");
            } catch (e) {
                return false;
            }
        }, "10s");
    });
    
    it("should reach block 15", || {
        utils::wait_for_block("validator", 15);
    });

});

describe("Health after", || {
    
    it("should be healthy (not catching up and producing blocks)", || {
        utils::check_health("validator");
    });

    describe("Doing some send transactions", || {
        let count = 5;
        for i in 0..count {
            it(`should be possible to send some token around and survive (${i}/${count})`, || {
                let txhash = utils::send_token("alice", constants::BOB, "100uproof");
                utils::wait_for_tx("validator",txhash);
            });
        }
        it("should still be healthy after the transactions", || {
            utils::check_health("validator");
        });
    });


    describe("Starting a fullnode without statesync", || {
        it("should be possible to start the fullnode", || {
            utils::start_fullnode("fullnode-without-statesync");
            return;
        });

        it("should come up successfully", || {
            utils::wait_for_fullnode("fullnode-without-statesync", "15s");
            utils::check_health("fullnode-without-statesync");
        });
    });

    describe("Starting a fullnode with statesync", || {
        it("should be possible to configure statesync", || {
            let block = utils::get_block("validator", 1);
            let hash = block.block_id.hash;
            exec(`sed -i 's/enable = false/enable = true/' assets/fullnode-with-statesync/config/config.toml`);
            exec(`sed -i 's/rpc_servers = ""/rpc_servers = "http:\/\/validator:26657,http:\/\/validator:26657"/' assets/fullnode-with-statesync/config/config.toml`);
            exec(`sed -i 's/trust_height = 0/trust_height = 1/' assets/fullnode-with-statesync/config/config.toml`);
            exec(`sed -i 's/trust_hash = ""/trust_hash = "${hash}"/' assets/fullnode-with-statesync/config/config.toml`);
            return;
        });

        it("should be possible to start the fullnode", || {
            utils::start_fullnode_with_upgrade_version("fullnode-with-statesync", "v0.2.0", "15");
            return;
        });

        it("should come up successfully", || {
            utils::wait_for_fullnode("fullnode-with-statesync", "30s");
            utils::check_health("fullnode-with-statesync");
        });
    });
});
