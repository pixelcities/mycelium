# Mycelium

## Installation

1. Install deps
```
mix deps.get
mix compile
```

2. Setup postgres database

* LiaisonServer
In `apps/liaison_server` (modify postgres connection details in config as required)
```
mix do event_store.create
```

Create the tenant schemas in the newly created database
```
psql -c "create schema ds1; create schema ds2;"
```

Modify `lib/liaison_server/event_store.ex` to generate a schema for each tenant
```
# Add an init block that specifies the schema (or modify the config)
def init(config) do
  {:ok, Keyword.put(config, :schema, "ds1")}
end
```

Run the migrations. This will pick up the schema that was just added.
```
event_store.init
```

Repeat for each tenant.

* MetaStore
Create the database
```
psql -c "create database metastore;"
```

Run the migrations. In `apps/meta_store`:
```
mix ecto.migrate
```

## Running

Quick way to get started is to invoke
```
mix run --no-halt
```

For development work it is better to use the interactive shell
```
iex -S mix
```

