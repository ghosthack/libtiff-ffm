# Publishing to Maven Central

Publishing is gated by a non-prerelease GitHub Release. Pushes and pull
requests build and test but never publish.

## Release procedure

1. Replace the SNAPSHOT version in the parent and both module poms, update the
   README coordinate, and commit the release.
2. Merge to `main` and wait for CI.
3. Publish a GitHub Release tagged `v<project.version>` at that commit.
4. The release workflow verifies the tag, rebuilds all three native
   classifiers from source, runs each platform's smoke tests, and deploys the
   resulting bundle to Maven Central.

Required repository secrets are `MAVEN_CENTRAL_USERNAME`,
`MAVEN_CENTRAL_PASSWORD`, `GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE`.

For a local packaging check without publishing:

```sh
mvn -Prelease -Dgpg.skip=true clean verify
```
