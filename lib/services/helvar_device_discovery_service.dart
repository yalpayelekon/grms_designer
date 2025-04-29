// lib/services/helvar_device_discovery_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/helvar_device.dart';
import '../protocol/protocol_constants.dart';
import '../protocol/commands/query_commands.dart';
import '../protocol/commands/discovery_commands.dart';
import '../protocol/message_parser.dart';

class HelvarDeviceDiscoveryService {
  static const int defaultPort = 50000;

  Future<List<Map<String, dynamic>>> discoverDevices(
      String routerIpAddress) async {
    Socket? socket;
    List<Map<String, dynamic>> discoveredDevices = [];

    try {
      // Connect to the router using TCP
      socket = await Socket.connect(routerIpAddress, defaultPort);

      // Step 1: Discover clusters
      final clusters = await _discoverClusters(socket);
      if (clusters.isEmpty) {
        debugPrint('No clusters found');
        return [];
      }

      // Step 2: For each cluster, query routers
      for (final cluster in clusters) {
        final routers = await _queryRoutersInCluster(socket, cluster);

        // Step 3: For each router and subnet, query devices
        for (final router in routers) {
          // HelvarNet protocol supports subnets 1-4
          for (int subnet = 1; subnet <= 4; subnet++) {
            final devices =
                await _queryDevicesInSubnet(socket, cluster, router, subnet);
            discoveredDevices.addAll(devices);
          }
        }
      }

      return discoveredDevices;
    } catch (e) {
      debugPrint('Error discovering devices: $e');
      return [];
    } finally {
      socket?.destroy();
    }
  }

  Future<List<int>> _discoverClusters(Socket socket) async {
    final completer = Completer<List<int>>();
    final List<int> clusters = [];

    // Set up a subscription to listen for responses
    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();

        try {
          // Parse the response to get clusters
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('error')) {
            debugPrint(
                'Error discovering clusters: ${parsedResponse['errorMessage']}');
            return;
          }

          if (parsedResponse.containsKey('data')) {
            final responseData = parsedResponse['data'];
            if (responseData is List) {
              for (final item in responseData) {
                final clusterNum = int.tryParse(item.toString());
                if (clusterNum != null && clusterNum > 0 && clusterNum <= 253) {
                  clusters.add(clusterNum);
                }
              }
            } else if (responseData is String) {
              // Handle case where response data is a comma-separated string
              final clusterStrings = responseData.split(',');
              for (final clusterStr in clusterStrings) {
                final clusterNum = int.tryParse(clusterStr.trim());
                if (clusterNum != null && clusterNum > 0 && clusterNum <= 253) {
                  clusters.add(clusterNum);
                }
              }
            }

            completer.complete(clusters);
          }
        } catch (e) {
          debugPrint('Error parsing cluster response: $e');
          completer.complete([]);
        }
      },
      onError: (error) {
        debugPrint('Socket error in clusters query: $error');
        completer.complete([]);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(clusters);
        }
      },
    );

    // Send command to query clusters
    final queryCommand = QueryCommands.queryClusters();
    socket.write(queryCommand);

    // Wait for response with timeout
    final result = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Timeout while querying clusters');
        return [1]; // Default to cluster 1 if timeout
      },
    );

    await subscription.cancel();
    return result;
  }

  Future<List<int>> _queryRoutersInCluster(Socket socket, int cluster) async {
    final completer = Completer<List<int>>();
    final List<int> routers = [];

    // Set up a subscription to listen for responses
    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();

        try {
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('error')) {
            debugPrint(
                'Error querying routers: ${parsedResponse['errorMessage']}');
            return;
          }

          if (parsedResponse.containsKey('data')) {
            final responseData = parsedResponse['data'];
            if (responseData is List) {
              for (final item in responseData) {
                final routerNum = int.tryParse(item.toString());
                if (routerNum != null && routerNum > 0 && routerNum <= 254) {
                  routers.add(routerNum);
                }
              }
            } else if (responseData is String) {
              // Handle case where response data is a comma-separated string
              final routerStrings = responseData.split(',');
              for (final routerStr in routerStrings) {
                final routerNum = int.tryParse(routerStr.trim());
                if (routerNum != null && routerNum > 0 && routerNum <= 254) {
                  routers.add(routerNum);
                }
              }
            }

            completer.complete(routers);
          }
        } catch (e) {
          debugPrint('Error parsing router response: $e');
          completer.complete([]);
        }
      },
      onError: (error) {
        debugPrint('Socket error in routers query: $error');
        completer.complete([]);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(routers);
        }
      },
    );

    // Send command to query routers in the cluster
    final queryCommand = QueryCommands.queryRouters(cluster);
    socket.write(queryCommand);

    // Wait for response with timeout
    final result = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Timeout while querying routers in cluster $cluster');
        return [1]; // Default to router 1 if timeout
      },
    );

    await subscription.cancel();
    return result;
  }

  Future<List<Map<String, dynamic>>> _queryDevicesInSubnet(
      Socket socket, int cluster, int router, int subnet) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final List<Map<String, dynamic>> devices = [];

    // Set up a subscription to listen for responses
    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();

        try {
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('error')) {
            // If the subnet doesn't exist, just complete with empty list
            if (parsedResponse['error'] == ErrorCode.deviceNotExist
                // || parsedResponse['error'] == ErrorCode.subnetNotExist
                ) {
              completer.complete([]);
              return;
            }
            debugPrint(
                'Error querying devices: ${parsedResponse['errorMessage']}');
            return;
          }

          if (parsedResponse.containsKey('data')) {
            final responseData = parsedResponse['data'];
            if (responseData is String) {
              // Parse the response which may contain device types and addresses
              // Format: "deviceType1@address1,deviceType2@address2,..."
              final entries = responseData.split(',');

              for (final entry in entries) {
                if (entry.contains('@')) {
                  final parts = entry.split('@');
                  if (parts.length == 2) {
                    final deviceType = parts[0].trim();
                    final address = parts[1].trim();

                    // Only add valid addresses with 4 parts (cluster.router.subnet.device)
                    if (_isValidAddress(address)) {
                      devices.add({
                        'cluster': cluster,
                        'router': router,
                        'subnet': subnet,
                        'address': address,
                        'hexId': deviceType,
                        'type': _getDeviceTypeFromHexId(deviceType),
                      });
                    }
                  }
                }
              }
            }

            completer.complete(devices);
          }
        } catch (e) {
          debugPrint('Error parsing device response: $e');
          completer.complete([]);
        }
      },
      onError: (error) {
        debugPrint('Socket error in devices query: $error');
        completer.complete([]);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      },
    );

    // Using command 100 - Query Device Types and Addresses
    // This is the equivalent to the queryDeviceTypes method that was missing
    final command = '>V:1,C:100,@$cluster.$router.$subnet#';
    socket.write(command);

    // Wait for response with timeout
    final result = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint(
            'Timeout while querying devices in subnet $cluster.$router.$subnet');
        return [];
      },
    );

    await subscription.cancel();

    // Enrich device information by querying more details for each device
    final enrichedDevices = <Map<String, dynamic>>[];
    for (final device in result) {
      try {
        final parts = device['address'].split('.');
        if (parts.length == 4) {
          final deviceIndex = int.parse(parts[3]);
          final deviceInfo = await _getDeviceDetails(
              socket, cluster, router, subnet, deviceIndex);

          enrichedDevices.add({
            ...device,
            ...deviceInfo,
          });
        }
      } catch (e) {
        debugPrint('Error enriching device data: $e');
        enrichedDevices.add(device);
      }
    }

    return enrichedDevices;
  }

  Future<Map<String, dynamic>> _getDeviceDetails(
      Socket socket, int cluster, int router, int subnet, int device) async {
    final Map<String, dynamic> deviceInfo = {};

    try {
      // Query device description
      final description = await _queryDeviceDescription(
          socket, cluster, router, subnet, device);
      deviceInfo['description'] =
          description.isNotEmpty ? description : 'Device $device';

      // Query device state
      final deviceState =
          await _queryDeviceState(socket, cluster, router, subnet, device);
      deviceInfo['state'] = deviceState;

      // Determine device type based on hex ID
      final helvarType = _determineDeviceCategory(deviceInfo['hexId'] ?? '');
      deviceInfo['helvarType'] = helvarType;

      // If it's an output device, also query load level
      if (helvarType == 'output') {
        final level =
            await _queryLoadLevel(socket, cluster, router, subnet, device);
        deviceInfo['level'] = level;
      }
    } catch (e) {
      debugPrint('Error getting device details: $e');
    }

    return deviceInfo;
  }

  Future<String> _queryDeviceDescription(
      Socket socket, int cluster, int router, int subnet, int device) async {
    final completer = Completer<String>();
    String description = '';

    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();
        try {
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('data') &&
              parsedResponse['data'] is String) {
            description = parsedResponse['data'];
            completer.complete(description);
          }
        } catch (e) {
          debugPrint('Error parsing device description response: $e');
          completer.complete('');
        }
      },
      onError: (error) {
        debugPrint('Socket error in description query: $error');
        completer.complete('');
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(description);
        }
      },
    );

    final command =
        QueryCommands.queryDescriptionDevice(cluster, router, subnet, device);
    socket.write(command);

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => '',
    );

    await subscription.cancel();
    return result;
  }

  Future<String> _queryDeviceState(
      Socket socket, int cluster, int router, int subnet, int device) async {
    final completer = Completer<String>();
    String state = '';

    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();
        try {
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('data')) {
            final stateValue = parsedResponse['data'];
            if (stateValue is String) {
              final stateInt = int.tryParse(stateValue);
              if (stateInt != null) {
                // Convert state int value to readable format
                final stateMap = decodeDeviceState(stateInt);
                state = stateMap.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .join(', ');
              }
            }
            completer.complete(state);
          }
        } catch (e) {
          debugPrint('Error parsing device state response: $e');
          completer.complete('');
        }
      },
      onError: (error) {
        debugPrint('Socket error in state query: $error');
        completer.complete('');
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(state);
        }
      },
    );

    final command =
        QueryCommands.queryDeviceState(cluster, router, subnet, device);
    socket.write(command);

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => '',
    );

    await subscription.cancel();
    return result;
  }

  Future<int> _queryLoadLevel(
      Socket socket, int cluster, int router, int subnet, int device) async {
    final completer = Completer<int>();
    int level = 0;

    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();
        try {
          final parsedResponse = parseResponse(response);
          if (parsedResponse.containsKey('data')) {
            final levelValue = parsedResponse['data'];
            if (levelValue is String) {
              final levelInt = int.tryParse(levelValue);
              if (levelInt != null) {
                level = levelInt;
              }
            }
            completer.complete(level);
          }
        } catch (e) {
          debugPrint('Error parsing load level response: $e');
          completer.complete(0);
        }
      },
      onError: (error) {
        debugPrint('Socket error in load level query: $error');
        completer.complete(0);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(level);
        }
      },
    );

    final command =
        QueryCommands.queryLoadLevel(cluster, router, subnet, device);
    socket.write(command);

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => 0,
    );

    await subscription.cancel();
    return result;
  }

  bool _isValidAddress(String address) {
    final parts = address.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null) return false;
    }

    return true;
  }

  String _getDeviceTypeFromHexId(String hexId) {
    // This would use your device_types.dart mapping
    // For example, checking against DaliDeviceType, DigidimDeviceType, etc.
    // For now, return a placeholder based on hex pattern

    if (hexId.endsWith('01')) {
      return 'DALI Device';
    } else if (hexId.endsWith('02')) {
      return 'Digidim Device';
    } else if (hexId.endsWith('04')) {
      return 'Imagine Device';
    } else if (hexId.contains('LED')) {
      return 'LED Unit';
    } else if (hexId.contains('Button')) {
      return 'Button Panel';
    } else {
      return 'Helvar Device';
    }
  }

  String _determineDeviceCategory(String hexId) {
    // Simplified logic - should be expanded based on your device types
    if (hexId.contains('LED') ||
        hexId.endsWith('01') ||
        hexId.contains('Dimmer') ||
        hexId.contains('Ballast')) {
      return 'output';
    } else if (hexId.contains('Button') ||
        hexId.contains('Sensor') ||
        hexId.contains('detector')) {
      return 'input';
    } else if (hexId.contains('emergency') || hexId.contains('Emergency')) {
      return 'emergency';
    } else {
      // Default to output for unknown devices
      return 'output';
    }
  }
}
