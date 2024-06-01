# BAQL

> Blue Archive over GraphQL

Use Blue Archive's game data via GraphQL.  
Used by [mollulog.net](https://mollulog.net).

## Development

### Prerequisites

- Ruby 3.3+
- Docker

### Run Server

```bash
docker compose up -d

gem install bundler

bundle
bundle exec rails db:prepare
bundle exec rails server
```
