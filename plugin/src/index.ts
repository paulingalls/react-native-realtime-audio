import { AndroidConfig, ConfigPlugin, IOSConfig, withAppBuildGradle } from 'expo/config-plugins';

const MICROPHONE_USAGE = 'Allow $(PRODUCT_NAME) to access your microphone';

const withMicrophone: ConfigPlugin<{ microphonePermission?: string | false } | void> = (
  config,
  { microphonePermission } = {}
) => {
  config = IOSConfig.Permissions.createPermissionsPlugin({
    NSMicrophoneUsageDescription: MICROPHONE_USAGE,
  })(config, {
    NSMicrophoneUsageDescription: microphonePermission,
  });

  config = withAppBuildGradle(config, async (config) => {
    if (config.modResults.contents.includes('beatunes.com')) {
      return config;
    }

    config.modResults.contents += `

repositories {
    maven {
        url "https://www.beatunes.com/repo/maven2"
    }
}
`;
    return config;
  })

  return AndroidConfig.Permissions.withPermissions(
    config,
    [
      microphonePermission !== false && 'android.permission.RECORD_AUDIO',
      'android.permission.MODIFY_AUDIO_SETTINGS',
    ].filter(Boolean) as string[]
  );
};

export default withMicrophone;