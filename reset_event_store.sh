#!/bin/bash

pushd ~/mycelium/apps/liaison_server

psql -d eventstore -c "drop schema ds1 cascade;"
psql -d eventstore -c "create schema ds1;"

sed -i "s/  # /   /g" lib/liaison_server/event_store.ex

mix do event_store.init

sed -i "4,6 s/   /  # /g" lib/liaison_server/event_store.ex

popd
