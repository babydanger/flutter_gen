import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter_gen_core/generators/generator_helper.dart';
import 'package:flutter_gen_core/generators/integrations/flare_integration.dart';
import 'package:flutter_gen_core/generators/integrations/image_integration.dart';
import 'package:flutter_gen_core/generators/integrations/integration.dart';
import 'package:flutter_gen_core/generators/integrations/lottie_integration.dart';
import 'package:flutter_gen_core/generators/integrations/rive_integration.dart';
import 'package:flutter_gen_core/generators/integrations/svg_integration.dart';
import 'package:flutter_gen_core/settings/asset_type.dart';
import 'package:flutter_gen_core/settings/config.dart';
import 'package:flutter_gen_core/settings/pubspec.dart';
import 'package:flutter_gen_core/utils/error.dart';
import 'package:flutter_gen_core/utils/string.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';

class AssetsGenConfig {
  AssetsGenConfig._(
    this.rootPath,
    this._packageName,
    this.flutterGen,
    this.assets,
    this.exclude,
  );

  factory AssetsGenConfig.fromConfig(File pubspecFile, Config config) {
    return AssetsGenConfig._(
      pubspecFile.parent.absolute.path,
      config.pubspec.packageName,
      config.pubspec.flutterGen,
      config.pubspec.flutter.assets,
      config.pubspec.flutterGen.assets.exclude.map(Glob.new).toList(),
    );
  }

  final String rootPath;
  final String _packageName;
  final FlutterGen flutterGen;
  final List<String> assets;
  final List<Glob> exclude;

  String get packageParameterLiteral =>
      flutterGen.assets.outputs.packageParameterEnabled ? _packageName : '';
}

String generateAssets(
  AssetsGenConfig config,
  DartFormatter formatter,
) {
  if (config.assets.isEmpty) {
    throw const InvalidSettingsException(
        'The value of "flutter/assets:" is incorrect.');
  }

  final importsBuffer = StringBuffer();
  final classesBuffer = StringBuffer();

  final integrations = <Integration>[
    ImageIntegration(config.packageParameterLiteral,
        parseMetadata: config.flutterGen.parseMetadata),
    if (config.flutterGen.integrations.flutterSvg)
      SvgIntegration(config.packageParameterLiteral,
          parseMetadata: config.flutterGen.parseMetadata),
    if (config.flutterGen.integrations.flareFlutter)
      FlareIntegration(config.packageParameterLiteral),
    if (config.flutterGen.integrations.rive)
      RiveIntegration(config.packageParameterLiteral),
    if (config.flutterGen.integrations.lottie)
      LottieIntegration(config.packageParameterLiteral),
  ];

  // ignore: deprecated_member_use_from_same_package
  final deprecatedStyle = config.flutterGen.assets.style != null;
  final deprecatedPackageParam =
      // ignore: deprecated_member_use_from_same_package
      config.flutterGen.assets.packageParameterEnabled != null;
  if (deprecatedStyle || deprecatedPackageParam) {
    stderr.writeln('''
                                                                                        
                ░░░░                                                                    
                                                                                        
                                            ██                                          
                                          ██░░██                                        
  ░░          ░░                        ██░░░░░░██                            ░░░░      
                                      ██░░░░░░░░░░██                                    
                                      ██░░░░░░░░░░██                                    
                                    ██░░░░░░░░░░░░░░██                                  
                                  ██░░░░░░██████░░░░░░██                                
                                  ██░░░░░░██████░░░░░░██                                
                                ██░░░░░░░░██████░░░░░░░░██                              
                                ██░░░░░░░░██████░░░░░░░░██                              
                              ██░░░░░░░░░░██████░░░░░░░░░░██                            
                            ██░░░░░░░░░░░░██████░░░░░░░░░░░░██                          
                            ██░░░░░░░░░░░░██████░░░░░░░░░░░░██                          
                          ██░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░██                        
                          ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                        
                        ██░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░██                      
                        ██░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░██                      
                      ██░░░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░░░██                    
        ░░            ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                    
                        ██████████████████████████████████████████                      
                                                                                        
                                                                                        
                  ░░''');
  }
  if (deprecatedStyle && deprecatedPackageParam) {
    stderr.writeln('''
    ┌────────────────────────────────────────────────────────────────────────────────────────────────┐
    │ ⚠️  Warning                                                                                     │
    │   The `style` and `package_parameter_enabled` property moved from asset to under asset.output. │
    │   It should be changed in the following pubspec.yaml.                                          │
    │   https://github.com/FlutterGen/flutter_gen/pull/294                                           │
    │                                                                                                │
    │ [pubspec.yaml]                                                                                 │
    │                                                                                                │
    │  flutter_gen:                                                                                  │
    │    assets:                                                                                     │
    │      outputs:                                                                                  │
    │        style: snake-case                                                                       │
    │        package_parameter_enabled: true                                                         │
    └────────────────────────────────────────────────────────────────────────────────────────────────┘''');
  } else if (deprecatedStyle) {
    stderr.writeln('''
    ┌───────────────────────────────────────────────────────────────────────┐
    │ ⚠️  Warning                                                            │
    │   The `style` property moved from asset to under asset.output.        │
    │   It should be changed in the following ways                          │
    │   https://github.com/FlutterGen/flutter_gen/pull/294                  │
    │                                                                       │
    │ [pubspec.yaml]                                                        │
    │                                                                       │
    │  flutter_gen:                                                         │
    │    assets:                                                            │
    │      outputs:                                                         │
    │        style: snake-case                                              │
    └───────────────────────────────────────────────────────────────────────┘''');
  } else if (deprecatedPackageParam) {
    stderr.writeln('''
    ┌────────────────────────────────────────────────────────────────────────────────────────┐
    │ ⚠️  Warning                                                                             │
    │   The `package_parameter_enabled` property moved from asset to under asset.output.     │
    │   It should be changed in the following pubspec.yaml.                                  │
    │   https://github.com/FlutterGen/flutter_gen/pull/294                                   │
    │                                                                                        │
    │ [pubspec.yaml]                                                                         │
    │                                                                                        │
    │  flutter_gen:                                                                          │
    │    assets:                                                                             │
    │      outputs:                                                                          │
    │        package_parameter_enabled: true                                                 │
    └────────────────────────────────────────────────────────────────────────────────────────┘''');
  }

  if (config.flutterGen.assets.outputs.isDotDelimiterStyle) {
    classesBuffer.writeln(_dotDelimiterStyleDefinition(config, integrations));
  } else if (config.flutterGen.assets.outputs.isSnakeCaseStyle) {
    classesBuffer.writeln(_snakeCaseStyleDefinition(config, integrations));
  } else if (config.flutterGen.assets.outputs.isCamelCaseStyle) {
    classesBuffer.writeln(_camelCaseStyleDefinition(config, integrations));
  } else {
    throw 'The value of "flutter_gen/assets/style." is incorrect.';
  }

  final imports = <String>{};
  integrations
      .where((integration) => integration.isEnabled)
      .forEach((integration) {
    imports.addAll(integration.requiredImports);
    classesBuffer.writeln(integration.classOutput);
  });
  for (final package in imports) {
    importsBuffer.writeln(import(package));
  }

  final buffer = StringBuffer();

  buffer.writeln(header);
  buffer.writeln(ignore);
  buffer.writeln(importsBuffer.toString());
  buffer.writeln(classesBuffer.toString());
  return formatter.format(buffer.toString());
}

String? generatePackageNameForConfig(AssetsGenConfig config) {
  if (config.flutterGen.assets.outputs.packageParameterEnabled) {
    return config._packageName;
  } else {
    return null;
  }
}

/// Returns a list of all releative path assets that are to be considered.
List<String> _getAssetRelativePathList(
  /// The absolute root path of the assets directory.
  String rootPath,

  /// List of assets as provided the `flutter`.`assets` section in the pubspec.yaml.
  List<String> assets,

  /// List of globs as provided the `flutter_gen`.`assets`.`exclude` section in the pubspec.yaml.
  List<Glob> excludes,
) {
  final assetRelativePathList = <String>[];
  for (final assetName in assets) {
    final assetAbsolutePath = join(rootPath, assetName);
    if (FileSystemEntity.isDirectorySync(assetAbsolutePath)) {
      assetRelativePathList.addAll(Directory(assetAbsolutePath)
          .listSync()
          .whereType<File>()
          .map((e) => relative(e.path, from: rootPath))
          .toList());
    } else if (FileSystemEntity.isFileSync(assetAbsolutePath)) {
      assetRelativePathList.add(relative(assetAbsolutePath, from: rootPath));
    }
  }

  if (excludes.isEmpty) {
    return assetRelativePathList;
  }

  return assetRelativePathList
      .where((file) => !excludes.any((exclude) => exclude.matches(file)))
      .toList();
}

AssetType _constructAssetTree(
    List<String> assetRelativePathList, String rootPath) {
  // Relative path is the key
  final assetTypeMap = <String, AssetType>{
    '.': AssetType(rootPath: rootPath, path: '.'),
  };
  for (final assetPath in assetRelativePathList) {
    var path = assetPath;
    while (path != '.') {
      assetTypeMap.putIfAbsent(
          path, () => AssetType(rootPath: rootPath, path: path));
      path = dirname(path);
    }
  }
  // Construct the AssetType tree
  for (final assetType in assetTypeMap.values) {
    if (assetType.path == '.') {
      continue;
    }
    final parentPath = dirname(assetType.path);
    assetTypeMap[parentPath]?.addChild(assetType);
  }
  return assetTypeMap['.']!;
}

_Statement? _createAssetTypeStatement(
  AssetsGenConfig config,
  UniqueAssetType assetType,
  List<Integration> integrations,
) {
  final childAssetAbsolutePath = join(config.rootPath, assetType.path);
  if (FileSystemEntity.isDirectorySync(childAssetAbsolutePath)) {
    final childClassName = '\$${assetType.path.camelCase().capitalize()}Gen';
    return _Statement(
      type: childClassName,
      filePath: assetType.posixStylePath,
      name: assetType.name,
      value: '$childClassName()',
      isConstConstructor: true,
      isDirectory: true,
      needDartDoc: false,
    );
  } else if (!assetType.isIgnoreFile) {
    final integration = integrations.firstWhereOrNull(
      (element) => element.isSupport(assetType),
    );
    if (integration == null) {
      var assetKey = assetType.posixStylePath;
      if (config.flutterGen.assets.outputs.packageParameterEnabled) {
        assetKey = 'packages/${config._packageName}/$assetKey';
      }
      return _Statement(
        type: 'String',
        filePath: assetType.posixStylePath,
        name: assetType.name,
        value: '\'$assetKey\'',
        isConstConstructor: false,
        isDirectory: false,
        needDartDoc: true,
      );
    } else {
      integration.isEnabled = true;
      return _Statement(
        type: integration.className,
        filePath: assetType.posixStylePath,
        name: assetType.name,
        value: integration.classInstantiate(assetType),
        isConstConstructor: integration.isConstConstructor,
        isDirectory: false,
        needDartDoc: true,
      );
    }
  }
  return null;
}

/// Generate style like Assets.foo.bar
String _dotDelimiterStyleDefinition(
  AssetsGenConfig config,
  List<Integration> integrations,
) {
  final rootPath = Directory(config.rootPath).absolute.uri.toFilePath();
  final buffer = StringBuffer();
  final className = config.flutterGen.assets.outputs.className;
  final assetRelativePathList = _getAssetRelativePathList(
    rootPath,
    config.assets,
    config.exclude,
  );
  final assetsStaticStatements = <_Statement>[];

  final assetTypeQueue = ListQueue<AssetType>.from(
      _constructAssetTree(assetRelativePathList, rootPath).children);

  while (assetTypeQueue.isNotEmpty) {
    final assetType = assetTypeQueue.removeFirst();
    String assetPath = join(rootPath, assetType.path);
    final isDirectory = FileSystemEntity.isDirectorySync(assetPath);
    if (isDirectory) {
      assetPath = Directory(assetPath).absolute.uri.toFilePath();
    } else {
      assetPath = File(assetPath).absolute.uri.toFilePath();
    }

    final isRootAsset = !isDirectory &&
        File(assetPath).parent.absolute.uri.toFilePath() == rootPath;
    // Handles directories, and explicitly handles root path assets.
    if (isDirectory || isRootAsset) {
      final statements = assetType.children
          .mapToUniqueAssetType(camelCase, justBasename: true)
          .map(
            (e) => _createAssetTypeStatement(
              config,
              e,
              integrations,
            ),
          )
          .whereType<_Statement>()
          .toList();

      if (assetType.isDefaultAssetsDirectory) {
        assetsStaticStatements.addAll(statements);
      } else if (!isDirectory && isRootAsset) {
        // Creates explicit statement.
        assetsStaticStatements.add(
          _createAssetTypeStatement(
            config,
            UniqueAssetType(assetType: assetType, style: camelCase),
            integrations,
          )!,
        );
      } else {
        final className = '\$${assetType.path.camelCase().capitalize()}Gen';
        buffer.writeln(_directoryClassGenDefinition(className, statements));
        // Add this directory reference to Assets class
        // if we are not under the default asset folder
        if (dirname(assetType.path) == '.') {
          assetsStaticStatements.add(_Statement(
            type: className,
            filePath: assetType.posixStylePath,
            name: assetType.baseName.camelCase(),
            value: '$className()',
            isConstConstructor: true,
            isDirectory: true,
            needDartDoc: true,
          ));
        }
      }

      assetTypeQueue.addAll(assetType.children);
    }
  }
  final String? packageName = generatePackageNameForConfig(config);
  buffer.writeln(
    _dotDelimiterStyleAssetsClassDefinition(
      className,
      assetsStaticStatements,
      packageName,
    ),
  );
  return buffer.toString();
}

/// Generate style like Assets.fooBar
String _camelCaseStyleDefinition(
  AssetsGenConfig config,
  List<Integration> integrations,
) {
  return _flatStyleDefinition(
    config,
    integrations,
    camelCase,
  );
}

/// Generate style like Assets.foo_bar
String _snakeCaseStyleDefinition(
  AssetsGenConfig config,
  List<Integration> integrations,
) {
  return _flatStyleDefinition(
    config,
    integrations,
    snakeCase,
  );
}

String _flatStyleDefinition(
  AssetsGenConfig config,
  List<Integration> integrations,
  String Function(String) style,
) {
  final statements = _getAssetRelativePathList(
    config.rootPath,
    config.assets,
    config.exclude,
  )
      .distinct()
      .sorted()
      .map((assetPath) => AssetType(rootPath: config.rootPath, path: assetPath))
      .mapToUniqueAssetType(style)
      .map(
        (e) => _createAssetTypeStatement(
          config,
          e,
          integrations,
        ),
      )
      .whereType<_Statement>()
      .toList();
  final className = config.flutterGen.assets.outputs.className;
  final String? packageName = generatePackageNameForConfig(config);
  return _flatStyleAssetsClassDefinition(className, statements, packageName);
}

String _flatStyleAssetsClassDefinition(
  String className,
  List<_Statement> statements,
  String? packageName,
) {
  final statementsBlock =
      statements.map((statement) => '''${statement.toDartDocString()}
           ${statement.toStaticFieldString()}
           ''').join('\n');
  final valuesBlock = _assetValuesDefinition(statements, static: true);
  return _assetsClassDefinition(
    className,
    statements,
    statementsBlock,
    valuesBlock,
    packageName,
  );
}

String _dotDelimiterStyleAssetsClassDefinition(
  String className,
  List<_Statement> statements,
  String? packageName,
) {
  final statementsBlock =
      statements.map((statement) => statement.toStaticFieldString()).join('\n');
  final valuesBlock = _assetValuesDefinition(statements, static: true);
  return _assetsClassDefinition(
    className,
    statements,
    statementsBlock,
    valuesBlock,
    packageName,
  );
}

String _assetValuesDefinition(
  List<_Statement> statements, {
  bool static = false,
}) {
  final values = statements.where((element) => !element.isDirectory);
  if (values.isEmpty) return '';
  final names = values.map((value) => value.name).join(', ');
  final type = values.every((element) => element.type == values.first.type)
      ? values.first.type
      : 'dynamic';

  return '''
  /// List of all assets
  ${static ? 'static ' : ''}List<$type> get values => [$names];''';
}

String _assetsClassDefinition(
  String className,
  List<_Statement> statements,
  String statementsBlock,
  String valuesBlock,
  String? packageName,
) {
  return '''
class $className {
  $className._();
${packageName != null ? "\n  static const String package = '$packageName';" : ''}

  $statementsBlock
  $valuesBlock
}
''';
}

String _directoryClassGenDefinition(
  String className,
  List<_Statement> statements,
) {
  final statementsBlock = statements
      .map((statement) => statement.needDartDoc
          ? '''${statement.toDartDocString()}
          ${statement.toGetterString()}
          '''
          : statement.toGetterString())
      .join('\n');
  final valuesBlock = _assetValuesDefinition(statements);

  return '''
class $className {
  const $className();
  
  $statementsBlock
  $valuesBlock
}
''';
}

/// The generated statement for each asset, e.g
/// '$type get $name => ${isConstConstructor ? 'const' : ''} $value;';
class _Statement {
  const _Statement({
    required this.type,
    required this.filePath,
    required this.name,
    required this.value,
    required this.isConstConstructor,
    required this.isDirectory,
    required this.needDartDoc,
  });

  /// The type of this asset, e.g AssetGenImage, SvgGenImage, String, etc.
  final String type;

  /// The relative path of this asset from the root directory.
  final String filePath;

  /// The variable name of this asset.
  final String name;

  /// The code to instantiate this asset. e.g `AssetGenImage('assets/image.png');`
  final String value;

  final bool isConstConstructor;
  final bool isDirectory;
  final bool needDartDoc;

  String toDartDocString() => '/// File path: $filePath';

  String toGetterString() =>
      '$type get $name => ${isConstConstructor ? 'const' : ''} $value;';

  String toStaticFieldString() => 'static const $type $name = $value;';
}
