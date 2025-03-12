# ZkCloud Chain Runner

## Overview

This repository provides a setup to run the ZkCloud chain locally.

zkcloud.com is a cloud-based platform designed for generating and verifying **zero-knowledge proofs (ZKPs)** in a user-friendly and efficient manner. It supports protocols like Groth16, PLONK, and ZK-STARKs, offering high-speed proof generation with the flexibility to handle confidential computations without revealing sensitive information.

---

## About Zero-Knowledge Proofs

Zero-knowledge proofs allow one party (the prover) to prove to another party (the verifier) that a statement is true without disclosing the underlying information. This is particularly valuable for applications requiring privacy, data integrity, and verification without exposure.

---

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/thezkcloud/zkcloud.git
   cd zkcloud
   ```

2. Build the chain:

   ```bash
   make build
   ```
