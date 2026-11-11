import { AndroidConfig, type ConfigPlugin, withGradleProperties } from 'expo/config-plugins';

type PropertiesItem = AndroidConfig.Properties.PropertiesItem;

const settingProperty = (items: readonly PropertiesItem[], key: string, value: string): readonly PropertiesItem[] => [
  ...items.filter((item) => item.type !== 'property' || item.key !== key),
  { type: 'property', key, value },
];

export const propertiesText = (items: readonly PropertiesItem[]): string =>
  AndroidConfig.Properties.propertiesListToString(items);

const withJvmArguments: ConfigPlugin = (config) =>
  withGradleProperties(config, (gradle) => ({
    ...gradle,
    modResults: settingProperty(gradle.modResults, 'org.gradle.jvmargs', '-Xmx2048m'),
  }));

export default withJvmArguments;
