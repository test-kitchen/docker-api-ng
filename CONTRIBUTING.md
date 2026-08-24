# Contributing

## Getting set up

```console
$ bundle install
$ bundle exec rake          # style + the unit suite
```

The unit suite is hermetic: no daemon, no network, no sleeping. It should run
in about a second. If a change makes it slower than that, something is
reaching for the world that should not be.

## Running the integration suite

```console
$ DOCKER_API_NG_INTEGRATION=1 bundle exec rake integration
```

This needs a real daemon. Everything it creates is named `docker-api-ng-test-*`
so a crashed run leaves behind something obviously disposable.

## The layers, and which one to change

```
Client / collections / resources   hand-written ergonomics
Operations                         GENERATED — do not edit
Connection                         hand-written
Transport                          hand-written
```

`lib/docker/api/operations.rb`, `sig/docker/api/operations.rbs` and
`spec/generated/` are generated from `data/swagger/`. Editing them by hand
means the next regeneration silently reverts your change. Change the emitter in
`tools/generator/` or the vendored specification instead, then:

```console
$ bundle exec rake api:generate
```

`rake api:verify` fails when the committed files do not match what the
specification produces, so CI catches a hand-edit.

## Upgrading the Engine API version

```console
$ bundle exec rake api:sync[1.56]
$ git diff --stat
```

Read the diff. New endpoints, changed parameters and altered paths all show up
there, and the conformance suite fails if a path or verb moved.

## Tests

- New behaviour needs a test that fails without it.
- Tests drive `Transport::Fake` rather than mocking the client's own methods,
  so they assert what goes on the wire instead of agreeing with the
  implementation.
- `Mocha.configure { stubbing_non_existent_method = :prevent }` is on. A
  stubbed typo fails rather than passing quietly.

## Style

```console
$ bundle exec rake style
$ bundle exec rubocop -a
```

Cookstyle's chefstyle, matching the other test-kitchen projects.

## Commits

Conventional commits, because release-please reads them to decide versions and
write the changelog:

```
feat: add ergonomic wrappers for swarm services
fix: send platform on image inspect as an OCI object
docs: explain the two platform encodings
```

## Documentation

Every public method carries YARD documentation with an `@return`. Explain why
something is the way it is when the reason is not obvious from the code —
particularly where Docker's API is surprising, because the next person will hit
the same surprise.
