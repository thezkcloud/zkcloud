export const ALICE_MNEMONIC = "know spread bronze icon soldier board couple lunar slight review bamboo cousin lumber hamster skirt abstract science earn cover minute panther fish drip essence";
export const BOB_MNEMONIC = "off emerge salmon protect close range exchange left faint swim beef ten awful split stool cross captain stove ginger tent roast sting horse stumble";

export const ALICE = "zkcloud122jczdm234rrl2puwgpwqgdvp9s3zzcd4pcx6v";
export const BOB = "zkcloud12tsyy0mfylw9v28yupyhe8ep0swvz6ufqz73f8";

export const CPU_TASK_SPEC = `
kind: Task
version: v0
metadata:
    name: "Test Task"
    description: "A test task"
    tags: []
    labels: []
spec:
    image: "https://storage.googleapis.com/gevulot-static-assets/simple_task_2.img"
    command: ["/task"]
    args: ["dummy-arg-1", "dummy-arg-2"]
    env:
    - name: "SIMPLE_TASK_2_KEY"
      value: "dummy_value"
    inputContexts:
    - source: "http://localhost:8080/hello.txt"
      target: "/mnt/gevulot/input/input1.txt"
    - source: "http://localhost:8080/hello.txt"
      target: "/mnt/gevulot/input/foo/bar/input2.txt"
    outputContexts:
    - source: "/mnt/gevulot/output/output1.txt"
      retentionPeriod: 60
    - source: "/mnt/gevulot/output/foo/bar/output2.txt"
      retentionPeriod: 60
    resources:
      cpus: "1cpu"
      gpus: "0gpu"
      memory: "1GB"
      time: "1min"
    storeStdout: true
    storeStderr: true
`;
export const GPU_TASK_SPEC = `
kind: Task
version: v0
metadata:
    name: "Test GPU Task"
    description: "A test gpu task"
    tags: []
    labels: []
spec:
    image: "https://storage.googleapis.com/gevulot-static-assets/simple_task_2.img"
    command: ["/task"]
    args: ["dummy-arg-1", "dummy-arg-2"]
    env:
    - name: "SIMPLE_TASK_2_KEY"
      value: "dummy_value"
    inputContexts:
    - source: "http://localhost:8080/hello.txt"
      target: "/mnt/gevulot/input/input1.txt"
    - source: "http://localhost:8080/hello.txt"
      target: "/mnt/gevulot/input/foo/bar/input2.txt"
    outputContexts:
    - source: "/mnt/gevulot/output/output1.txt"
      retentionPeriod: 60
    - source: "/mnt/gevulot/output/foo/bar/output2.txt"
      retentionPeriod: 60
    resources:
      cpus: "1cpu"
      gpus: "1gpu"
      memory: "1GB"
      time: "1min"
    storeStdout: true
    storeStderr: true
`;

export const WORKER_SPEC = `
kind: Worker
version: v0
metadata:
  id: 'worker-1'
  name: 'Worker 1'
  description: 'The first worker ever'
  tags:
    - gpu
    - cpu
  labels: 
    - key: 'location'
      value: 'us-east'
    - key: 'region'
      value: 'us-east-1'
spec:
  cpus: "64cpu"
  gpus: "4gpu"
  memory: "32GB"
  disk: "5TB"
`;