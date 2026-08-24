# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0](https://github.com/test-kitchen/docker-api-ng/compare/v0.2.0...v0.3.0) (2026-08-24)


### Features

* resolve the daemon from the active Docker context ([0362208](https://github.com/test-kitchen/docker-api-ng/commit/03622082f4c7084989458e13fd3cfb4320fdd4aa))
* resolve the daemon from the active Docker context ([4b31f2e](https://github.com/test-kitchen/docker-api-ng/commit/4b31f2e3c289e2bcd130e9e0b70fb18ca255a33c))


### Bug Fixes

* keep an empty response body inside the error hierarchy ([9d238db](https://github.com/test-kitchen/docker-api-ng/commit/9d238dbb121bb5002a37817224f038fe22fb6247))
* keep an empty response body inside the error hierarchy ([266c4cc](https://github.com/test-kitchen/docker-api-ng/commit/266c4cc42dfb94bb73e4e92e3f520c4f11ab7e23))
* load without base64, and make CI install the gem it builds ([858c381](https://github.com/test-kitchen/docker-api-ng/commit/858c381b67f2806b302a7548a6ea5a74467244b8))
* load without base64, which is no longer a default gem ([2ae00ea](https://github.com/test-kitchen/docker-api-ng/commit/2ae00ea8b68f5908dc7b096db87bd4d502106ba1))
* parse image references correctly and push only the tag in hand ([29eb9de](https://github.com/test-kitchen/docker-api-ng/commit/29eb9de0ed3e1ab2befd49bf8a9d50d5ef3f55fe))
* parse image references correctly and push only the tag in hand ([6e4461c](https://github.com/test-kitchen/docker-api-ng/commit/6e4461c718d92beab2ef2b7c6ad2c806f72cee34))
* require cgi in the generated conformance suite ([73f6be5](https://github.com/test-kitchen/docker-api-ng/commit/73f6be561483dc70594fb53ff5e78e4935721432))
* require cgi in the generated conformance suite ([1d9a33a](https://github.com/test-kitchen/docker-api-ng/commit/1d9a33a415d31bcc30b23acdcea680f7a6d0882b))
* stop packaging the vendored Engine API specification ([6a81edf](https://github.com/test-kitchen/docker-api-ng/commit/6a81edf81a3066fbd0648358e43c821b1ffe0f2d))
* stop packaging the vendored Engine API specification ([6b4c10a](https://github.com/test-kitchen/docker-api-ng/commit/6b4c10a070dd9f7968b6eaec784dfd4ba401fe36))
* stop the unit suite reading real registry credentials ([fe6e528](https://github.com/test-kitchen/docker-api-ng/commit/fe6e528cb99ff87cc6719b4e09b3a98cfa1e8b17))
* stop the unit suite reading real registry credentials ([c49712c](https://github.com/test-kitchen/docker-api-ng/commit/c49712c86ddf75a079f671d528c8b2cd96d3162e))
* stream archives instead of holding them in memory, and close a leaked socket ([3815ac9](https://github.com/test-kitchen/docker-api-ng/commit/3815ac9015ff104f31a4db4e2c25497fd4583d0d))
* stream archives instead of holding them in memory, and close a leaked socket ([1661755](https://github.com/test-kitchen/docker-api-ng/commit/1661755d85fb1da6207b077460518f0ed21a6af4))
* three defects in the container lifecycle and its result reporting ([85f52ad](https://github.com/test-kitchen/docker-api-ng/commit/85f52ad6dda6abd8968a22e52dbf84c765547da5))
* three defects in the container lifecycle and its result reporting ([6a69be0](https://github.com/test-kitchen/docker-api-ng/commit/6a69be017f3ecc672ceeffbd88959f97544c7e89))

## [0.2.0](https://github.com/test-kitchen/docker-api-ng/compare/v0.1.0...v0.2.0) (2026-08-24)


### Features

* docker-api-ng, a dependency-free client for the modern Docker Engine API ([e7224dc](https://github.com/test-kitchen/docker-api-ng/commit/e7224dca5602620455881cd32072c40998cb7e70))
* ergonomic client, collections and normalised resources ([3956710](https://github.com/test-kitchen/docker-api-ng/commit/3956710f3e2b95e3554eb8c380820d93697d4050))
* generate the Engine API operations from Docker's specification ([b09f06a](https://github.com/test-kitchen/docker-api-ng/commit/b09f06ab8908ae84f2051633f77541dfe1ef225e))
* project skeleton, Apache-2.0 licence and CI ([8ea1f1f](https://github.com/test-kitchen/docker-api-ng/commit/8ea1f1ff5e08f9afd664308d196b353711af747a))
* transports, connection, errors and stream decoding ([26820c4](https://github.com/test-kitchen/docker-api-ng/commit/26820c4bc29dc3ff8ccdb3edd67816ddb3c5ce01))


### Bug Fixes

* label every body-bearing request with a content type ([1fd3fd5](https://github.com/test-kitchen/docker-api-ng/commit/1fd3fd55cb907bf229af90d7265c7e4bc4800dc7))

## 0.1.0

Initial release.
