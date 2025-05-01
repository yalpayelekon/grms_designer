class HelvarNetCommands {
  // Query commands
  static String queryDeviceType(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:104,@$cluster.$router.$subnet.$device#';
  }

  static String queryDescriptionGroup(int version, int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '>V:$version,C:105,G:$group#';
  }

  static String queryDescriptionDevice(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:106,@$cluster.$router.$subnet.$device#';
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

  static String queryDeviceState(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:110,@$cluster.$router.$subnet.$device#';
  }

  static String queryDeviceIsDisabled(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:111,@$cluster.$router.$subnet.$device#';
  }

  static String queryLampFailure(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:112,@$cluster.$router.$subnet.$device#';
  }

  static String queryDeviceIsMissing(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:113,@$cluster.$router.$subnet.$device#';
  }

  static String queryDeviceIsFaulty(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:114,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyBatteryFailure(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:129,@$cluster.$router.$subnet.$device#';
  }

  static String queryMeasurement(int version, int cluster, int router,
      int subnet, int device, int subdevice) {
    _validateAddress(cluster, router, subnet, device);
    _validateSubdevice(subdevice);
    return '>V:$version,C:150,@$cluster.$router.$subnet.$device.$subdevice#';
  }

  static String queryInputs(int version, int cluster, int router, int subnet,
      int device, int subdevice) {
    _validateAddress(cluster, router, subnet, device);
    _validateSubdevice(subdevice);
    return '>V:$version,C:151,@$cluster.$router.$subnet.$device.$subdevice#';
  }

  static String queryLoadLevel(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:152,@$cluster.$router.$subnet.$device#';
  }

  static String queryPowerConsumption(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:160,@$cluster.$router.$subnet.$device#';
  }

  static String queryGroupPowerConsumption(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:161,G:$group#';
  }

  static String queryEmergencyFunctionTestTime(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:170,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyFunctionTestState(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:171,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyDurationTestTime(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:172,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyDurationTestState(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:173,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyBatteryCharge(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:174,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyBatteryTime(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:175,@$cluster.$router.$subnet.$device#';
  }

  static String queryEmergencyTotalLampTime(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:176,@$cluster.$router.$subnet.$device#';
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

  static String queryDeviceTypesAndAddresses(
      int version, int cluster, int router, int subnet) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    if (router < 1 || router > 254) {
      throw ArgumentError('Router must be between 1 and 254');
    }
    if (subnet < 1 || subnet > 4) {
      throw ArgumentError('Subnet must be between 1 and 4');
    }

    return '>V:$version,C:100@$cluster.$router.$subnet#';
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

  static String querySceneInfo(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:167@$cluster.$router.$subnet.$device#';
  }

  // Control commands
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
    _validateAddress(cluster, router, subnet, device);
    _validateBlock(block);
    _validateScene(scene);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:12,B:$block,S:$scene,F:$fadeTime,@$cluster.$router.$subnet.$device#';
  }

  static String directLevelGroup(int version, int group, int level,
      {int fadeTime = 0}) {
    _validateGroup(group);
    _validateLevel(level);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:13,G:$group,L:$level,F:$fadeTime#';
  }

  static String directLevelDevice(
      int version, int cluster, int router, int subnet, int device, int level,
      {int fadeTime = 0}) {
    _validateAddress(cluster, router, subnet, device);
    _validateLevel(level);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:14,L:$level,F:$fadeTime,@$cluster.$router.$subnet.$device#';
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
    _validateAddress(cluster, router, subnet, device);
    _validateProportion(proportion);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:16,P:$proportion,F:$fadeTime,@$cluster.$router.$subnet.$device#';
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
    _validateAddress(cluster, router, subnet, device);
    _validateProportionChange(proportionChange);
    _validateFadeTime(fadeTime);

    return '>V:$version,C:18,P:$proportionChange,F:$fadeTime,@$cluster.$router.$subnet.$device#';
  }

  // Emergency test control commands
  static String emergencyFunctionTestGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:19,G:$group#';
  }

  static String emergencyFunctionTestDevice(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:20,@$cluster.$router.$subnet.$device#';
  }

  static String emergencyDurationTestGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:21,G:$group#';
  }

  static String emergencyDurationTestDevice(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:22,@$cluster.$router.$subnet.$device#';
  }

  static String stopEmergencyTestsGroup(int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:23,G:$group#';
  }

  static String stopEmergencyTestsDevice(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:24,@$cluster.$router.$subnet.$device#';
  }

  // Configuration commands
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
    _validateAddress(cluster, router, subnet, device);
    _validateBlock(block);
    _validateScene(scene);
    _validateLevel(level);

    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:202,@$cluster.$router.$subnet.$device,O:$forceStoreValue,B:$block,S:$scene,L:$level#';
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
    _validateAddress(cluster, router, subnet, device);
    _validateBlock(block);
    _validateScene(scene);

    final forceStoreValue = forceStore ? 1 : 0;
    return '>V:$version,C:204,@$cluster.$router.$subnet.$device,O:$forceStoreValue,B:$block,S:$scene#';
  }

  static String resetEmergencyBatteryAndTotalLampTimeGroup(
      int version, int group) {
    _validateGroup(group);
    return '>V:$version,C:205,G:$group#';
  }

  static String resetEmergencyBatteryAndTotalLampTimeDevice(
      int version, int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);
    return '>V:$version,C:206,@$cluster.$router.$subnet.$device#';
  }

  // Validation methods
  static void _validateAddress(
      int cluster, int router, int subnet, int device) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    if (router < 1 || router > 254) {
      throw ArgumentError('Router must be between 1 and 254');
    }
    if (subnet < 1 || subnet > 4) {
      throw ArgumentError('Subnet must be between 1 and 4');
    }
    if (device < 1 || device > 255) {
      throw ArgumentError('Device must be between 1 and 255');
    }
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

  static void _validateSubdevice(int subdevice) {
    if (subdevice < 1 || subdevice > 16) {
      throw ArgumentError('Subdevice must be between 1 and 16');
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
