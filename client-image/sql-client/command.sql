CREATE TABLE t1(
  uuid VARCHAR(20), -- you can use 'PRIMARY KEY NOT ENFORCED' syntax to mark the field as record key
  name VARCHAR(10),
  age INT,
  ts TIMESTAMP(3),
  `partition` VARCHAR(20)
)
PARTITIONED BY (`partition`)
WITH (
  'connector' = 'hudi',
  'path' = '/data/t1',
  'write.tasks' = '1', -- default is 4 ,required more resource
  'compaction.tasks' = '1', -- default is 10 ,required more resource
  'table.type' = 'COPY_ON_WRITE', -- this creates a MERGE_ON_READ table, by default is COPY_ON_WRITE
  'read.tasks' = '1', -- default is 4 ,required more resource
  'read.streaming.enabled' = 'true',  -- this option enable the streaming read
  'read.streaming.start-commit' = '0', -- specifies the start commit instant time
  'read.streaming.check-interval' = '4' -- specifies the check interval for finding new source commits, default 60s.
);

-- insert data using values
INSERT INTO t1 VALUES
  ('id1','Danny',23,TIMESTAMP '1970-01-01 00:00:01','par1'),
  ('id2','Stephen',33,TIMESTAMP '1970-01-01 00:00:02','par1'),
  ('id3','Julian',53,TIMESTAMP '1970-01-01 00:00:03','par2'),
  ('id4','Fabian',31,TIMESTAMP '1970-01-01 00:00:04','par2'),
  ('id5','Sophia',18,TIMESTAMP '1970-01-01 00:00:05','par3'),
  ('id6','Emma',20,TIMESTAMP '1970-01-01 00:00:06','par3'),
  ('id7','Bob',44,TIMESTAMP '1970-01-01 00:00:07','par4'),
  ('id8','Han',56,TIMESTAMP '1970-01-01 00:00:08','par4');

SELECT * FROM t1;


CREATE CATALOG datasource WITH (
    'type'='jdbc',
    'property-version'='1',
    'base-url'='jdbc:postgresql://postgres:5432/',
    'default-database'='postgres',
    'username'='postgres',
    'password'='postgres'
);

CREATE DATABASE IF NOT EXISTS datasource;


CREATE TABLE datasource.accident_claims WITH (
                                            'connector' = 'kafka',
                                            'topic' = 'pg_claims.claims.accident_claims',
                                            'properties.bootstrap.servers' = 'kafka:9092',
                                            'properties.group.id' = 'accident_claims-consumer-group',
                                            'format' = 'debezium-json',
                                            'scan.startup.mode' = 'earliest-offset'
                                            ) LIKE datasource.postgres.`claims.accident_claims` (EXCLUDING ALL);


SELECT * FROM datasource.accident_claims;


curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres.json
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres-members.json


curl -i -X PUT -H "Accept: application/json" -H "Content-Type: application/json" \
http://localhost:8083/connectors/claims-connector/config \
-d @register-postgres.json


curl -i -X DELETE http://localhost:8083/connectors/members-connector
curl -i -X DELETE http://localhost:8083/connectors/claims-connector


curl -X POST http://localhost:8083/connectors/members-connector/restart
curl -X POST http://localhost:8083/connectors/claims-connector/restart

SELECT pg_drop_replication_slot('claims-connector');

docker compose exec kafka /kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --from-beginning \
    --property print.key=true \
    --topic pg_claims.claims.members


docker compose exec kafka /kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --from-beginning \
    --property print.key=true \
    --topic pg_claims.claims.members



INSERT INTO dwd.accident_claims
SELECT
    claim_id,
    claim_total,
    claim_total_receipt,
    claim_currency,
    member_id,
    CAST(accident_date AS DATE),
    accident_type,
    accident_detail,
    CAST(claim_date AS DATE),  -- Cast claim_date to DATE
    claim_status,
    CAST(ts_created AS TIMESTAMP),
    CAST(ts_updated AS TIMESTAMP),
    CAST(claim_date AS DATE)  -- Cast claim_date to DATE
FROM datasource.accident_claims;


INSERT INTO dwb.accident_claims
SELECT claim_id,
       claim_total,
       claim_total_receipt,
       claim_currency,
       member_id,
       accident_date,
       accident_type,
       accident_detail,
       claim_date,
       claim_status,
       ts_created,
       ts_updated,
       claim_date
FROM dwd.accident_claims;


 {"claim_id": 100, "claim_total": null, "claim_total_receipt": null, "claim_currency": null, "member_id": null, "accident_date": null, "accident_type": null, "accident_detail": null, "claim_date": null, "claim_status": null, "ts_created": null, "ts_updated": null, "ds": null}

INSERT INTO dwd.members
SELECT
    id,
    first_name,
    last_name,
    address,
    address_city,
    address_country,
    insurance_company,
    insurance_number,
    CAST(ts_created AS TIMESTAMP(3)), -- Cast ts_created to TIMESTAMP(3)
    CAST(ts_updated AS TIMESTAMP(3)), -- Ensure ts_updated is also TIMESTAMP(3)
    CAST(ts_created AS DATE)          -- Cast ts_created to DATE
FROM datasource.members;


docker compose exec postgres env PGOPTIONS="--search_path=claims" bash -c 'psql -U $POSTGRES_USER postgres'

PGOPTIONS="--search_path=claims"

psql -U $POSTGRES_USER -d postgres -a -f postgres_bootstrap.sql

docker compose exec 2563476e858f env PGOPTIONS="--search_path=claims" bash -c 'psql -U $POSTGRES_USER -d postgres -a -f /postgres/postgres_bootstrap.sql'


SELECT slot_name FROM pg_replication_slots;


curl -X POST http://CONNECT_REST_URL/connectors/CONNECTOR_NAME/restart


./bin/flink cancel -a
