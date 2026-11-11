# @expo/config-plugins and readonly gradle.properties lists

A blank Expo SDK 58 app (`npx create-expo-app --template blank-typescript`) with one config plugin,
`plugins/with-gradle-properties.ts`, which builds its `gradle.properties` list anew as a `readonly PropertiesItem[]`
rather than changing the one it is handed, hands it back from `withGradleProperties`, and writes such a list with
`AndroidConfig.Properties.propertiesListToString`.

```sh
npm install
npm run check:plugins
```

`check:plugins` runs `check.sh`, which type-checks the plugin with `strict: true`. It exits 1 while
`propertiesListToString` or `withGradleProperties` refuses a readonly list, 0 once the plugin type-checks, and 2 when a
step fails or another error shows.
