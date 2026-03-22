# BAQL — Model & Architecture Reference

> GraphQL API for Blue Archive. Fetches game data from SchaleDB (schaledb.com) and serves it via GraphQL.
> Used by [mollulog.net](https://mollulog.net)

## Tech Stack

| | |
|---|---|
| Language | Ruby ~4.0 |
| Framework | Rails 8.0 |
| API | GraphQL (`graphql` gem) |
| DB | PostgreSQL |
| Storage | AWS S3 (images) |
| Data Source | SchaleDB (`lib/schale_db/v1/data.rb`) |

---

## Model Reference

### Resources

#### `Currency` — `currencies` table
```
uid, baql_id, rarity, raw_data(jsonb)
```
- `Translatable`: `name`, `description`
- `ImageSyncable`: stores to S3 at `assets/images/currencies/:uid`
- `sync!`: SchaleDB currencies API → DB upsert + Translation upsert
- `baql_id` format: `baql::currencies::{uid}`

#### `Item` — `items` table
```
uid, baql_id, category, sub_category, rarity, raw_data(jsonb)
```
- `Translatable`: `name`, `description`
- `ImageSyncable`: stores to S3 at `assets/images/items/:uid`
- `sync!`: SchaleDB items API → DB upsert + Translation upsert
- `duplicate!(new_uid)`: duplicates the item including its image
- `baql_id` format: `baql::items::{uid}`

#### `Equipment` — `equipments` table
```
uid, baql_id, category, sub_category, rarity, raw_data(jsonb)
```
- `Translatable`: `name`, `description`
- `ImageSyncable`: stores to S3 at `assets/images/equipments/:uid`
- `baql_id` format: `baql::equipments::{uid}`

#### `Furniture` — `furnitures` table
```
uid, baql_id, category, sub_category, rarity, tags(string[]), raw_data(jsonb)
```
- `Translatable`: `name`, `description`
- `ImageSyncable`: stores to S3 at `assets/images/furnitures/:uid`
- `baql_id` format: `baql::furnitures::{uid}`

---

### Events

#### `EventContent` — `event_contents` table
```
uid, baql_id, raw_data_first(jsonb), raw_data_rerun(jsonb)
```
- `Translatable`: `name`
- `has_many :schedules`
- `baql_id` format: `baql::events::{uid}`
- `sync!`: SchaleDB events API → DB upsert + EventContentSchedule upsert + Translation upsert
- Instance methods (computed from raw_data, no extra DB queries):
  - `stages(run_type:)` → array of stage hashes
  - `bonuses(run_type:)` → array of student bonus hashes
  - `shop_resources(run_type:)` → array of shop item hashes

#### `EventContentSchedule` — `event_content_schedules` table
```
event_content_uid, region, run_type, start_at, end_at
```
- `region`: `jp`, `gl`, `cn`
- `run_type`: `first`, `rerun`, `permanent`
- Unique constraint: `(event_content_uid, region, run_type)`

---

### Main Story

#### `MainStoryVolume` — `main_story_volumes` table
```
uid, baql_id, label, sort_order
```
- `Translatable`: `name`
- `has_many :chapters`
- `baql_id` format: `baql::main_story_volumes::{uid}`
- `uid` values: `"1"`–`"6"`, `"final"`, `"ex"`
- `label`: fixed display prefix, not translatable (e.g. `"Vol.1"`, `"Final."`, `"Ex."`)
- `sort_order`: ordered by JP first release date

#### `MainStoryChapter` — `main_story_chapters` table
```
uid, baql_id, volume_uid, chapter_number
```
- `Translatable`: `name`
- `belongs_to :volume`, `has_many :parts`
- `baql_id` format: `baql::main_story_chapters::{uid}`
- `uid` format: `"{volume}-{chapter_number}"` (e.g. `"3-4"`, `"final-1"`, `"ex-2"`)

#### `MainStoryPart` — `main_story_parts` table
```
uid, baql_id, chapter_uid, sort_order, episode_start(nullable), episode_end(nullable)
```
- `Translatable`: `name` — multilingual part label (e.g. "전반"/"前半"/"Part 1", "Prologue")
- `belongs_to :chapter`, `has_many :schedules`
- `baql_id` format: `baql::main_story_parts::{uid}`
- `uid` format: `"{volume}-{chapter}-{part_index}"` (e.g. `"3-4-2"`, `"final-4-3"`)
- `episode_start/end`: nullable for unreleased parts
- Data managed manually via `lib/tasks/seed_main_story.rake`

#### `MainStoryPartSchedule` — `main_story_part_schedules` table
```
part_uid, region, released_at, confirmed(bool)
```
- `region`: `jp`, `gl` (no `cn` data)
- Unique constraint: `(part_uid, region)`
- `confirmed: false` for unannounced/estimated dates

---

### Students / Characters

#### `Student` — `students` table
```
uid, name, school, initial_tier, attack_type, defense_type, role, tactic_role,
position, birthday, equipments(comma-separated string), order, schale_db_id,
multiclass_uid, release_at, alt_names(string[])
```
- `ImageSyncable`: standing + collection images
- `released`: true when `release_at < now`
- `sync!`: syncs from SchaleDB students, populates skill materials
- `multiclass_uid`: references the original student uid for multiclass variants
- Cache: `Rails.cache` per uid, 1-minute TTL

#### `StudentSkillItem` — `student_skill_items` table
```
student_uid, item_uid, skill_type(ex/normal), skill_level(int), amount
```
- `belongs_to :item` (v2 `Item`)

#### `StudentFavoriteItem` — `student_favorite_items` table
```
student_uid, item_uid, exp, favorite_level, favorited(bool)
```
- `sync!`: computed from SchaleDB items (`Category == "Favor"`) + student `FavorItemTags`

---

### Recruitments

#### `RecruitmentGroup` — `recruitment_groups` table
```
uid, baql_id, recruitment_type, content_type(nullable), content_uid(nullable), start_at, end_at
```
- `has_many :recruitments`
- `content_type` values: `event_content`, `main_story_part`
- `#content`: returns associated `EventContent` or `MainStoryPart`
- `baql_id` format: `baql::recruitment_groups::{uid}`

#### `Recruitment` — `recruitments` table
```
uid, baql_id, recruitment_group_uid, recruitment_type, pickup(bool),
student_uid(nullable), student_name
```
- `belongs_to :recruitment_group`, `belongs_to :student` (optional)
- `recruitment_type` values: `given`, `usual`, `limited`, `fes`, `archive`, `encore`, `recollect`
- `delegate :start_at, :end_at → recruitment_group`

---

### Raids

#### `RaidBoss` — `raid_bosses` table _(v2)_
```
uid, baql_id, raid_type, event_content_uid(nullable)
```
- `Translatable`: `name`
- `belongs_to :event_content` (optional, `allied` type only)
- `has_many :schedules` (→ RaidSchedule)
- `raid_type` values: `raid` (total assault / elimination shared boss pool), `unlimit` (multi-floor raid), `allied` (interactive world raid + world raid)
- `uid` derived from SchaleDB `PathName`:
  - `Raid[]` → PathName as-is (e.g. `binah`, `shirokuro`)
  - `MultiFloorRaid[]` → PathName with armor-type suffix stripped (e.g. `set_specialarmor` → `set`)
  - `InteractiveWorldRaid[]` / `WorldRaid[]` → PathName as-is (e.g. `binah_854`)
- `baql_id` format: `baql::bosses::{uid}`
- `sync!`: SchaleDB raids API → upsert bosses from all 4 arrays (Raid, MultiFloorRaid, InteractiveWorldRaid, WorldRaid) + Translation upsert

#### `RaidSchedule` — `raid_schedules` table _(v2)_
```
uid, baql_id, raid_boss_uid, region, raid_type, season_index,
terrain, attack_type, start_at, end_at, defense_types(jsonb),
jp_season_index(nullable), event_content_run_type(nullable)
```
- `belongs_to :raid_boss`
- `raid_type` values: `total_assault`, `elimination`
- `region` values: `jp`, `gl` (CN not stored)
- `season_index`: SchaleDB `SeasonDisplay` integer value
- `jp_season_index`: the corresponding JP season index, used for cross-referencing GL schedules
- `defense_types`: elimination only — derived from `OpenDifficulty`. Array of `Data.define(:defense_type, :difficulty)` structs
- Unique constraint: `(region, raid_type, season_index)`
- Synced inside `RaidBoss.sync!` from `RaidSeasons[]` (`Seasons` → total_assault, `EliminateSeasons` → elimination)
- `baql_id` format: `baql::raid_schedules::{uid}`

#### `Raid` — `raids` table _(**DEPRECATED** — use `RaidBoss` + `RaidSchedule`)_
```
uid, name, boss, type, terrain, attack_type, since, until, confirmed,
raid_index_jp, rank_visible, defense_types(jsonb)
```
- Manually managed legacy data. Do not add new records here.
- Includes `Battleable`: provides `ATTACK_TYPES`, `DEFENSE_TYPES`, `TERRAINS` constants

#### `RaidVideo` — `raid_videos` table
```
title, score, youtube_id, thumbnail_url, published_at,
raid_type, raid_boss, raid_terrain, raid_defense_type
```

---

### Shared / Support

#### `Translation` — `translations` table
```
language, key, value
```
- `language`: `ja`, `ko`, `en`
- `key` format: `{baql_id}::{field}` (e.g. `baql::items::123::name`)
- Unique constraint: `(key, language)`

#### `Constants`
```ruby
REGIONS = ["jp", "gl", "cn"]
LANGUAGES = ["ja", "ko", "en"]
DEFAULT_LANGUAGE = "ko"
EVENT_SCHEDULE_RUN_TYPES = ["first", "rerun", "permanent"]
LANGUAGE_MAP = { "jp" => "ja", "kr" => "ko", "en" => "en" }
```

---

## Concerns

### `Translatable`
Multi-language support. Declaring `translatable :name, :description` generates:
- `name(lang = "ko")` → looks up Translation record
- `set_name(value, lang)` → upserts Translation record
- The model must define `translation_key_prefix` (typically returns `baql_id`)

### `ImageSyncable`
S3 image synchronization.
- `sync_image!(key, image_body)` — PUT to S3
- `copy_image!(source_key, dest_key)` — COPY within S3
- Requires env var: `STATIC_BUCKET_NAME`

### `Battleable`
Provides `ATTACK_TYPES` and `DEFENSE_TYPES` constants (used by `Raid`).

---

## GraphQL Layer

### QueryType Fields

| Field | Resolver |
|---|---|
| `event_content(uid)` | EventContentQuery |
| `raid_boss(uid)` | RaidBossQuery |
| `raid_bosses` | RaidBossesQuery |
| `raid(uid)` | RaidQuery _(deprecated)_ |
| `raids` | RaidsQuery _(deprecated)_ |
| `student(uid)` | StudentQuery |
| `students` | StudentsQuery |
| `items` | ItemsQuery |
| `main_stories` | MainStoriesQuery |
| `recruitment_group(uid)` | RecruitmentGroupQuery |
| `recruitment_groups` | RecruitmentGroupsQuery |
| `campaign(uid)` | CampaignQuery |
| `campaigns` | CampaignsQuery |
| `joint_firing_drill(uid)` | JointFiringDrillQuery |
| `joint_firing_drills` | JointFiringDrillsQuery |
| `mini_event_content(uid)` | MiniEventContentQuery |
| `mini_event_contents` | MiniEventContentsQuery |

### Key Interfaces
- **`ResourceInterface`**: `type, uid, name, rarity` — implemented by `Currency`, `Item`, `Equipment`, `Furniture`

### Resource Type Mapping (inside `EventContentType`)
```ruby
RESOURCE_CLASS_MAP = {
  "currency"  => -> { ::Currency },
  "item"      => -> { ::Item },
  "equipment" => -> { ::Equipment },
  "furniture" => -> { ::Furniture },
}
```

---

## Data Synchronization

### SchaleDB Data Source (`lib/schale_db/v1/data.rb`)
```
https://schaledb.com/data/{lang}/{dataset}.min.json
```
- `lang`: `kr` (default), `jp`, `en`
- `dataset`: `students`, `events`, `items`, `furniture`, `equipment`, `currency`, `raids`, `localization`

### Rake Tasks
```bash
rails sync:all          # students + items + furnitures + equipments + currencies
rails sync:students
rails sync:items        # Item.sync! + StudentFavoriteItem.sync!
rails sync:furnitures
rails sync:equipments
rails sync:currencies
rails sync:raid_bosses  # RaidBoss.sync! (bosses + schedules + translations)
```

### `sync!` Flow (per model)
1. Fetch data from SchaleDB API
2. `find_or_initialize_by(uid:, baql_id:)` → `update!`
3. Iterate `Constants::LANGUAGE_MAP` to upsert per-language Translations
4. Sync image to S3 if record changed

---

## Patterns & Conventions

- **`uid`**: String game ID. Used as primary key in associations (`primary_key: :uid, foreign_key: :xxx_uid`)
- **`baql_id`**: Internal namespaced ID. Format: `baql::{plural_model}::{uid}`
- **`raw_data` jsonb**: Models store the full SchaleDB source payload
- **Rarity**: N=1, R=2, SR=3, SSR=4
- **`json_array_attr`**: Custom Rails macro mapping a jsonb column to an array of `Data.define` structs
- **Polymorphic associations**: `resource_type/resource_uid` pattern
