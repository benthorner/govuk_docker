#!/usr/bin/env bash

function try_find_file {
  set +e
  out="$(aws s3 ls "s3://${bucket}/postgresql-backend/" | grep "${1}_production.gz" | sed 's/.* //' | sort | tail -n1)"
  set -e
  echo "$out"
}

set -eu

if [[ "$#" == "0" ]]; then
  echo "usage: $0 \$app"
  exit 1
fi

app="${1//_/-}"

replication_dir="${GOVUK_DOCKER_REPLICATION_DIR:-${GOVUK_DOCKER_DIR:-${GOVUK_ROOT_DIR:-$HOME/govuk}/govuk-docker}/replication}"

bucket="govuk-integration-database-backups"
archive_dir="${replication_dir}/postgresql"

case "$app" in
  "support-api")
    archive_file="support_contacts_production.dump.gz"
    ;;
  *)
    archive_file="${app//-/_}_production.dump.gz"
    ;;
esac

archive_path="${archive_dir}/${archive_file}"

echo "Replicating postgres for $app"

if [[ -e "$archive_path" ]]; then
  echo "Skipping download - remove ${archive_path} to force"
else
  mkdir -p "$archive_dir"
  s3_file=$(try_find_file "$app")
  if [[ -z "$s3_file" ]]; then
    s3_file=$(try_find_file "${app//-/_}")
  fi
  if [[ -z "$s3_file" ]]; then
    echo "couldn't figure out backup filename in S3 - if you're sure the app uses PostgreSQL, file an issue in alphagov/govuk-docker."
    exit 1
  fi
  aws s3 cp "s3://${bucket}/postgresql-backend/${s3_file}" "${archive_path}"
fi

if [[ -n "${SKIP_IMPORT:-}" ]]; then
  echo "Skipping import as \$SKIP_IMPORT is set"
  exit 0
fi

echo "stopping running govuk-docker containers..."
govuk-docker down

govuk-docker up -d postgres-9.6
trap 'govuk-docker stop postgres-9.6' EXIT

echo "waiting for postgres..."
until govuk-docker run postgres-9.6 /usr/bin/psql -h postgres-9.6 -U postgres -c 'SELECT 1' &>/dev/null; do
  sleep 1
done

database="$app"
govuk-docker run postgres-9.6 /usr/bin/psql -h postgres-9.6 -U postgres -c "DROP DATABASE IF EXISTS \"${database}\""
govuk-docker run postgres-9.6 /usr/bin/createdb -h postgres-9.6 -U postgres "$database"
pv "$archive_path" | govuk-docker run postgres-9.6 /usr/bin/pg_restore -h postgres-9.6 -U postgres -d "$database" --no-owner
