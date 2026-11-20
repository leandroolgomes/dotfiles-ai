# Recipe: Go service (HTTP / gRPC / queue consumer)

- **Dependencies:** prefer the repo's own `docker compose up -d <deps>` or a `make`/`mise` task. For AWS
  services (SQS, DynamoDB, S3), use LocalStack or DynamoDB Local if the repo already uses them; otherwise ask.
- **Start:** `go run ./cmd/<svc> &> /tmp/<svc>.log &` with the env from `.env.example`, then wait for ready:
  `for i in $(seq 30); do curl -fsS localhost:<port>/health && break; sleep 1; done`.
- **Drive:** `curl -fsS -X POST localhost:<port>/<route> -d @fixture.json | jq -e '<assertion>'`;
  gRPC with `grpcurl`; queues by publishing a message (`aws --endpoint-url ... sqs send-message`) and then
  checking the side effect (DB row, output queue, log line).
- **Observe:** the log file, `jq` over responses, direct reads of the store (`aws dynamodb get-item`, `psql -c`).
- **Profile when it's about speed:** `curl localhost:<port>/debug/pprof/profile?seconds=10 > cpu.out` if
  pprof is mounted; `go test -bench` for hot paths.
- **Stop:** `kill %1` (or the saved PID), `docker compose down`.
