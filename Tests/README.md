Run the credential-free regression harness on macOS with Xcode command-line tools:

```sh
Tests/run-metadata-tests.sh
```

It compiles the production Gemini service and restaurant/import models directly, then tests them with URLProtocol fixtures. No Xcode project changes, test dependencies, credentials, or live API requests are needed.

Simulator build:

```sh
xcodebuild -project Scout.xcodeproj -scheme Scout -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/scout-derived \
  CODE_SIGNING_ALLOWED=NO build
```

UI walkthrough with a configured Gemini key and signed-in circle (requires local credentials; not covered by the harness):

- Open Add restaurant and choose a Places match with no specific cuisine. Suggestions should fill an empty cuisine and select editable vibe chips; an uncommon cuisine appears in Other.
- Choose a match with a specific cuisine. Its cuisine should remain selected; name suggestions can still be requested explicitly.
- Type a restaurant name without choosing a place and tap Suggest cuisine & vibes. Unknown/ambiguous names should leave the form editable with a no-confident-suggestions message.
- While suggestions are loading, select or clear cuisine/vibe chips (including toggling back to empty). The response must preserve those choices. Custom Other text and changing type also protect cuisine.
- While loading, change the name, clear the place, select another place, or dismiss the sheet. Old suggestions must not be applied. Changing a name removes untouched generated details.
- Save while suggestions are loading. Saving must proceed with the current form values without waiting for Gemini.
- Remove GEMINI_API_KEY and rebuild. The suggestion control should be absent and Places/manual add should still work. With a bad key or offline connection, the form should show fallback text and still allow saving.
