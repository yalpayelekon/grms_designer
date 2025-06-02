import '../comm/router_command_service.dart';
import '../protocol/query_commands.dart';
import '../protocol/protocol_parser.dart';
import '../utils/core/logger.dart';

class SceneQueryService {
  final RouterCommandService commandService;

  SceneQueryService(this.commandService);

  Future<int?> queryLastSceneInBlock(
    String routerIpAddress,
    int groupId,
    int blockId,
  ) async {
    try {
      logInfo('Querying last scene in block $blockId for group $groupId');

      final command = HelvarNetCommands.queryLastSceneInBlock(groupId, blockId);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final sceneValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (sceneValue != null) {
          final sceneNumber = int.tryParse(sceneValue);
          logInfo('Last scene in block $blockId: $sceneNumber');
          return sceneNumber;
        }
      }

      logWarning('Failed to query last scene in block: ${result.response}');
      return null;
    } catch (e) {
      logError('Error querying last scene in block: $e');
      return null;
    }
  }

  Future<int?> queryLastSceneInGroup(
    String routerIpAddress,
    int groupId,
  ) async {
    try {
      logInfo('Querying last scene in group $groupId');

      final command = HelvarNetCommands.queryLastSceneInGroup(groupId);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final sceneValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (sceneValue != null) {
          final sceneNumber = int.tryParse(sceneValue);
          logInfo('Last scene in group: $sceneNumber');
          return sceneNumber;
        }
      }

      logWarning('Failed to query last scene in group: ${result.response}');
      return null;
    } catch (e) {
      logError('Error querying last scene in group: $e');
      return null;
    }
  }

  Future<List<String>> querySceneNames(String routerIpAddress) async {
    try {
      logInfo('Querying scene names');

      final command = HelvarNetCommands.querySceneNames();
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final sceneNamesValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (sceneNamesValue != null && sceneNamesValue.isNotEmpty) {
          final sceneNames = sceneNamesValue.split(',');
          logInfo('Found ${sceneNames.length} scene names: $sceneNames');
          return sceneNames;
        }
      }

      logWarning('Failed to query scene names: ${result.response}');
      return [];
    } catch (e) {
      logError('Error querying scene names: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> querySceneInfo(
    String routerIpAddress,
    String address,
  ) async {
    try {
      logInfo('Querying scene info for address: $address');

      final command = HelvarNetCommands.querySceneInfo(address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final sceneInfoValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (sceneInfoValue != null && sceneInfoValue.isNotEmpty) {
          logInfo('Scene info for $address: $sceneInfoValue');

          final parsedInfo = ProtocolParser.parseFullResponse(result.response!);
          return parsedInfo;
        }
      }

      logWarning('Failed to query scene info: ${result.response}');
      return null;
    } catch (e) {
      logError('Error querying scene info: $e');
      return null;
    }
  }

  Future<Map<int, int?>> exploreGroupScenes(
    String routerIpAddress,
    int groupId,
  ) async {
    try {
      logInfo('Exploring scenes for group $groupId');

      final sceneData = <int, int?>{};

      for (int block = 1; block <= 8; block++) {
        final lastScene = await queryLastSceneInBlock(
          routerIpAddress,
          groupId,
          block,
        );
        sceneData[block] = lastScene;

        await Future.delayed(const Duration(milliseconds: 100));
      }

      logInfo('Scene exploration complete for group $groupId: $sceneData');
      return sceneData;
    } catch (e) {
      logError('Error exploring group scenes: $e');
      return {};
    }
  }

  List<int> buildSceneTable(Map<int, int?> sceneData) {
    final sceneSet = <int>{};

    for (final entry in sceneData.entries) {
      if (entry.value != null && entry.value! > 0) {
        sceneSet.add(entry.value!);
      }
    }

    final sceneTable = sceneSet.toList()..sort();

    logInfo(
      'Built scene table with ${sceneTable.length} distinct scenes: $sceneTable',
    );
    return sceneTable;
  }
}
