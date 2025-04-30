import 'dart:io';
import 'helvarnet_client.dart';

void main() async {
  // Replace with your router's IP
  final routerIP = '10.11.10.150';
  final client = HelvarNetClient(routerIP);

  print('HelvarNet Client Test');
  print('====================');

  try {
    // Step 1: Discover workgroups
    print('\nStep 1: Discovering Workgroups...');
    final workgroups = await client.discoverWorkgroups();
    print('Found ${workgroups.length} workgroups: $workgroups');

    // Step 2: Discover subnets
    print('\nStep 2: Discovering Subnets...');
    final subnets = await client.discoverSubnets();
    print('Found ${subnets.length} subnets: $subnets');

    // Step 3: Discover groups (limited range for testing)
    print('\nStep 3: Discovering Groups (201-220)...');
    final groups = <int>[];
    // Use a smaller range for quicker testing
    for (int i = 1; i <= 65535; i++) {
      final response = await client.sendTcpCommand('>V:1,C:105,G:$i#');
      if (response.startsWith('?')) {
        groups.add(i);
        print('Found group: $i');
      }
    }
    print('Found ${groups.length} groups: $groups');

    // Step 4: Get info for each group
    print('\nStep 4: Getting Group Info...');
    for (final groupId in groups) {
      final groupInfo = await client.getGroupInfo(groupId);
      print('Group $groupId: $groupInfo');
    }

    // Step 5: Try controlling a group (if you want to test this)
    if (groups.isNotEmpty &&
        await shouldContinue(
            'Would you like to test controlling a group? (y/n)')) {
      final groupId = groups.first;
      print('\nStep 5: Controlling Group $groupId...');

      // Get current scene
      final currentInfo = await client.getGroupInfo(groupId);
      final currentScene = currentInfo['lastScene'] ?? 1;
      print('Current scene: $currentScene');

      // Try to set to a different scene
      final newScene = currentScene == 1 ? 2 : 1;
      print('Setting to scene $newScene...');
      final success =
          await client.recallGroupScene(groupId, 1, newScene, fadeTime: 500);
      print('Scene recall ${success ? 'succeeded' : 'failed'}');

      // Verify the change
      await Future.delayed(Duration(milliseconds: 700)); // Wait for fade
      final newInfo = await client.getGroupInfo(groupId);
      print('New scene: ${newInfo['lastScene']}');

      // Try setting a level directly
      if (await shouldContinue(
          'Would you like to test setting a direct level? (y/n)')) {
        print('Setting to 50% level...');
        final levelSuccess =
            await client.setGroupLevel(groupId, 50, fadeTime: 500);
        print('Level set ${levelSuccess ? 'succeeded' : 'failed'}');

        await Future.delayed(Duration(milliseconds: 700)); // Wait for fade
        print('Getting updated power consumption...');
        final finalInfo = await client.getGroupInfo(groupId);
        print('Updated info: $finalInfo');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\nTest completed.');
}

Future<bool> shouldContinue(String question) async {
  stdout.write('$question ');
  final response = stdin.readLineSync()?.toLowerCase() ?? '';
  return response == 'y' || response == 'yes';
}
