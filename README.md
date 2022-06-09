# Mycelium

## Installation

### Install deps
```
mix deps.get
mix compile
```

### Setup postgres database

#### LiaisonServer
In `apps/liaison_server` (modify postgres connection details in config as required)
```
mix do event_store.create
```

#### Others
Create the database
```
psql -c "create database metastore;"
```

Run the migrations. In `apps/meta_store`:
```
mix ecto.migrate
```

Repeat for the other ecto apps.


## Running

Quick way to get started is to invoke
```
mix run --no-halt
```

For development work it is better to use the interactive shell
```
iex -S mix
```

