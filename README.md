# BAQL

BAQL is a GraphQL interface for Blue Archive.  
It serves various game data such as students, events, raids, etc.

Used by [mollulog.net](https://mollulog.net).

## Furniture catalog

Furniture data is owned by the private `baql-sync` resource snapshot. `FurnitureExcel.SetGroudpId` supplies the optional theme UID (`0` means no theme); theme names and descriptions come from `FurnitureGroupExcel`/`LocalizeEtcExcel`. Catalog-owned furniture names, theme translations, preview titles, and preview images are validated as complete before import. Existing English translations remain BAQL-owned.

`FurnitureTheme.furnitures` returns every canonical furniture member for that theme. `FurnitureTheme.previews` returns the curated template previews with their source UID, localized title, image, and thumbnail. The Excel tables do not provide a direct group-to-template foreign key. BAQL uses an explicit, curated mapping reviewed against the group names and template composition; it is not inferred from placements or numeric IDs. Legacy furniture rows remain stored but are excluded from the canonical catalog.

The queries distinguish an unfiltered catalog request from an empty filter:

```graphql
query {
  furnitures {
    uid
    name(lang: "ko")
    imageUrl
    theme { uid name(lang: "ja") }
  }
  furnitureThemes {
    uid
    name(lang: "ko")
    furnitures { uid }
    previews { uid title(lang: "ja") imageUrl thumbnailUrl }
  }
  furnitureTheme(uid: "122") {
    uid
    previews { uid title imageUrl thumbnailUrl }
  }
}
```

`furnitures(uids: [])` returns no records; omitting `uids` returns the canonical catalog, and unknown requested UIDs are omitted. Until both the resource snapshot and its furniture asset manifest have been imported, catalog queries return a GraphQL error rather than a successful empty list. Apply the furniture catalog migration before importing the new snapshot. In `baql-sync`, run `table extract --force` and then `table dump --force` against the same source database before `table import --apply`; both force flags are required because a cached v3 resource snapshot with the same database hash would otherwise be reused. Then extract and upload the resource and preview images, and apply the asset manifest. The `baql-sync` pipeline instructions list the commands in order.

## Development

### Prerequisites

- Ruby 4.0+
- Docker

### Run Server

Set environment variables.

- `ASSET_BUCKET_NAME`
- (Environment variables for AWS S3)

```bash
docker compose up -d

gem install bundler

bundle
bundle exec rails db:prepare
bundle exec rails server
```
