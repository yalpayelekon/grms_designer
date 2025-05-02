class HelvarNetCommands {
  // Query commands
  static String queryDeviceType(int version, String address) {
    return '>V:$version,C:104,@$address#';
  }

  static String queryDescriptionGroup(int version, int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '>V:$version,C:105,G:$group#';
  }

  static String queryDescriptionDevice(int version, String address) {
    return '>V:$version,C:106,@$address#';
  }

  static String queryWorkgroupName(int version) {
    return '>V:$version,C:107#';
  }

  static String queryWorkgroupMembership(int version) {
    return '>V:$version,C:108#';
  }

  static String queryLastSceneInBlock(int version, int group, int block) {
    _validateGroup(group);
    _validateBlock(block);
    return '>V:$version,C:103,G:$group,B:$block#';
  }

  static String queryLastSceneInGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:109,G:$group#';
  }

  static String queryDeviceState(int version, String address) {
    return '>V:$version,C:110,@$address#';
  }

  static String queryDeviceIsDisabled(int version, String address) {
    return '>V:$version,C:111,@$address#';
  }

  static String queryLampFailure(int version, String address) {
    return '>V:$version,C:112,@$address#';
  }

  static String queryDeviceIsMissing(int version, String address) {
    return '>V:$version,C:113,@$address#';
  }

  static String queryDeviceIsFaulty(int version, String address) {
    return '>V:$version,C:114,@$address#';
  }

  static String queryEmergencyBatteryFailure(int version, String address) {
    return '>V:$version,C:129,@$address#';
  }

  static String queryLoadLevel(int version, String address) {
    return '>V:$version,C:152,@$address#';
  }

  static String queryPowerConsumption(int version, String address) {
    return '>V:$version,C:160,@$address#';
  }

  static String queryGroupPowerConsumption(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:161,G:$group#';
  }

  static String queryEmergencyFunctionTestTime(int version, String address) {
    return '>V:$version,C:170,@$address#';
  }

  static String queryEmergencyFunctionTestState(int version, String address) {
    return '>V:$version,C:171,@$address#';
  }

  static String queryEmergencyDurationTestTime(int version, String address) {
    return '>V:$version,C:172,@$address#';
  }

  static String queryEmergencyDurationTestState(int version, String address) {
    return '>V:$version,C:173,@$address#';
  }

  static String queryEmergencyBatteryCharge(int version, String address) {
    return '>V:$version,C:174,@$address#';
  }

  static String queryEmergencyBatteryTime(int version, String address) {
    return '>V:$version,C:175,@$address#';
  }

  static String queryEmergencyTotalLampTime(int version, String address) {
    return '>V:$version,C:176,@$address#';
  }

  static String queryTime(int version) {
    return '>V:$version,C:185#';
  }

  static String queryTimeZone(int version) {
    return '>V:$version,C:188#';
  }

  static String queryDaylightSavingTime(int version) {
    return '>V:$version,C:189#';
  }

  static String querySoftwareVersion(int version) {
    return '>V:$version,C:190#';
  }

  static String queryHelvarNetVersion(int version) {
    return '>V:$version,C:191#';
  }

  static String queryClusters(int version) {
    return '>V:$version,C:101#';
  }

  static String queryRouters(int version, int cluster) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    return '>V:$version,C:102,@$cluster#';
  }

  static String queryDeviceTypesAndAddresses(int version, String address) {
    return '>V:$version,C:100@$address#';
  }

  static String queryGroups(int version) {
    return '>V:$version,C:165#';
  }

  static String queryGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:164,G:$group#';
  }

  static String querySceneNames(int version) {
    return '>V:$version,C:166#';
  }

  static String querySceneInfo(int version, String address) {
    return '>V:$version,C:167@$address#';
  }

  static String recallSceneGroup(int version, int group, int block, int scene,
      {bool constantLight = false, int fadeTime = 0}) {
    _validateGroup(group);
    _validateBlock(block);
    _validateScene(scene);
    _validateFadeTime(fadeTime);

    final constantLightValue = constantLight ? 1 : 0;
    return '>V:$version,C:11,G:$group,K:$constantLightValue,B:$block,S:$scene,F:$fadeTime#';
  }

  static String recallSceneDevice(int version, int cluster, int router,
      int subnet, int device, int block, int scene,
      {int fadeTime = 0}) {
    _validateBlock(block);
    _validateScene(scene);
    _validateFadeTime(fadeTime);
    String address = '$cluster.$router.$subnet.$device';
    return '>V:$version,C:12,B:$block,S:$scene,F:$fadeTime,@$address#';
  }

  static String directLevelGroup(int version, int group, int level,
      {int fadeTime = 0}) {
    _validateGroup(group);
    _validateLevel(level);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:13,G:$group,L:$level,F:$fadeTime#';
  }

  static String directLevelDevice(int version, String address, int level,
      {int fadeTime = 0}) {
    _validateLevel(level);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:14,L:$level,F:$fadeTime,@$address#';
  }

  static String directProportionGroup(int version, int group, int proportion,
      {int fadeTime = 0}) {
    _validateGroup(group);
    _validateProportion(proportion);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:15,P:$proportion,G:$group,F:$fadeTime#';
  }

  static String directProportionDevice(int version, int cluster, int router,
      int subnet, int device, int proportion,
      {int fadeTime = 0}) {
    _validateProportion(proportion);
    _validateFadeTime(fadeTime);
    String address = '$cluster.$router.$subnet.$device';
    return '>V:$version,C:16,P:$proportion,F:$fadeTime,@$address#';
  }

  static String modifyProportionGroup(
      int version, int group, int proportionChange,
      {int fadeTime = 0}) {
    _validateGroup(group);
    _validateProportionChange(proportionChange);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:17,P:$proportionChange,G:$group,F:$fadeTime#';
  }

  static String modifyProportionDevice(int version, int cluster, int router,
      int subnet, int device, int proportionChange,
      {int fadeTime = 0}) {
    _validateProportionChange(proportionChange);
    _validateFadeTime(fadeTime);
    String address = '$cluster.$router.$subnet.$device';
    return '>V:$version,C:18,P:$proportionChange,F:$fadeTime,@$address#';
  }

  static String emergencyFunctionTestGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:19,G:$group#';
  }

  static String emergencyFunctionTestDevice(int version, String address) {
    return '>V:$version,C:20,@$address#';
  }

  static String emergencyDurationTestGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:21,G:$group#';
  }

  static String emergencyDurationTestDevice(int version, String address) {
    return '>V:$version,C:22,@$address#';
  }

  static String stopEmergencyTestsGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:23,G:$group#';
  }

  static String stopEmergencyTestsDevice(int version, String address) {
    return '>V:$version,C:24,@$address#';
  }

  static String storeSceneGroup(
      int version, int group, int block, int scene, int level,
      {bool forceStore = false}) {
    _validateGroup(group);
    _validateBlock(block);
    _validateScene(scene);
    _validateLevel(level);

    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:201,G:$group,O:$forceStoreValue,B:$block,S:$scene,L:$level#';
  }

  static String storeSceneDevice(int version, int cluster, int router,
      int subnet, int device, int block, int scene, int level,
      {bool forceStore = false}) {
    _validateBlock(block);
    _validateScene(scene);
    _validateLevel(level);
    String address = '$cluster.$router.$subnet.$device';
    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:202,@$address,O:$forceStoreValue,B:$block,S:$scene,L:$level#';
  }

  static String storeAsSceneGroup(int version, int group, int block, int scene,
      {bool forceStore = false}) {
    _validateGroup(group);
    _validateBlock(block);
    _validateScene(scene);

    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:203,G:$group,O:$forceStoreValue,B:$block,S:$scene#';
  }

  static String storeAsSceneDevice(int version, int cluster, int router,
      int subnet, int device, int block, int scene,
      {bool forceStore = false}) {
    _validateBlock(block);
    _validateScene(scene);
    String address = '$cluster.$router.$subnet.$device';
    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:204,@$address,O:$forceStoreValue,B:$block,S:$scene#';
  }

  static String resetEmergencyBatteryAndTotalLampTimeGroup(
      int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:205,G:$group#';
  }

  static String resetEmergencyBatteryAndTotalLampTimeDevice(
      int version, String address) {
    return '>V:$version,C:206,@$address#';
  }

  static void _validateGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
  }

  static void _validateBlock(int block) {
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
  }

  static void _validateScene(int scene) {
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
  }

  static void _validateLevel(int level) {
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }
  }

  static void _validateFadeTime(int fadeTime) {
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0 to 6553.5 seconds)');
    }
  }

  static void _validateProportion(int proportion) {
    if (proportion < -100 || proportion > 100) {
      throw ArgumentError('Proportion must be between -100 and 100');
    }
  }

  static void _validateProportionChange(int proportionChange) {
    if (proportionChange < -100 || proportionChange > 100) {
      throw ArgumentError('Proportion change must be between -100 and 100');
    }
  }
}
