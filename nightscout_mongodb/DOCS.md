# Nightscout MongoDB

## Setup

1. Set `root_password` to a long random value.
2. Start the add-on.
3. Use the same value as `mongo_password` in the **Nightscout** add-on.

The add-on stops at startup with an error in its log if `root_password` is
empty.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `root_password` | empty | Password of the `nsroot` admin user. Required. |

## Changing the password

`root_password` is applied only the first time the database is created. Changing
it later does not change the password stored in the database. Change it there
first with `mongosh`, then update both add-ons.

## Hardware requirements

MongoDB 7.0 needs a CPU with AVX on amd64, and ARMv8.2-A on aarch64. A Raspberry
Pi 4 does not meet this; a Raspberry Pi 5 does. On unsupported CPUs the add-on
exits immediately, usually with an illegal instruction error.

## Upgrades

Patch updates within 7.0 are delivered as normal add-on updates. This add-on
stays on MongoDB 7.0: moving to a new major version is a manual migration, see
the top-level README of this repository.

## Backups

Data is stored in the add-on's `/data/mongodb` directory and is included in Home
Assistant backups. For a backup that is guaranteed to be consistent, stop this
add-on first.
