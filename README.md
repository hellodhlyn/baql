# BAQL

BAQL is a GraphQL interface for Blue Archive.  
It serves various game data such as students, events, raids, etc.

Used by [mollulog.net](https://mollulog.net).

## Development

### Prerequisites

- Ruby 3.4+
- Docker

### Run Server

Set environment variables.

- `STATIC_BUCKET_NAME`
- (Environment variables for AWS S3)

```bash
docker compose up -d

gem install bundler

bundle
bundle exec rails db:prepare
bundle exec rails server
```
