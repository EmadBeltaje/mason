// ignore_for_file: no_adjacent_strings_in_list
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:mason/src/command_runner.dart';
import 'package:mason/src/version.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('MasonCommandRunner', () {
    List<String> printLogs;
    Logger logger;
    MasonCommandRunner commandRunner;

    void Function() overridePrint(void Function() fn) {
      return () {
        final spec = ZoneSpecification(print: (_, __, ___, String msg) {
          printLogs.add(msg);
        });
        return Zone.current.fork(specification: spec).run<void>(fn);
      };
    }

    setUp(() {
      printLogs = [];
      logger = MockLogger();
      commandRunner = MasonCommandRunner(logger: logger);
    });

    test('can be instantiated without an explicit logger instance', () {
      final commandRunner = MasonCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
      test('handles FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;
        when(logger.info(any)).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(logger.err(exception.message)).called(1);
        verify(logger.info(commandRunner.usage)).called(1);
      });

      test('handles UsageException', () async {
        final exception = UsageException('oops!', commandRunner.usage);
        var isFirstInvocation = true;
        when(logger.info(any)).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.usage.code));
        verify(logger.err(exception.message)).called(1);
        verify(logger.info(commandRunner.usage)).called(1);
      });

      test('handles no command', overridePrint(() async {
        const expectedPrintLogs = [
          '⛏️  mason • lay the foundation!\n'
              '\n'
              'Usage: mason <command> [arguments]\n'
              '\n'
              'Global options:\n'
              '-h, --help       Print this usage information.\n'
              '    --version    Print the current version.\n'
              '\n'
              'Available commands:\n'
              '  cache   Interact with mason cache\n'
              '  get     Gets all bricks.\n'
              '  init    Initialize mason in the current directory.\n'
              '  make    Generate code using an existing brick template.\n'
              '  new     Creates a new brick template.\n'
              '\n'
              'Run "mason help <command>" for more information about a command.'
        ];
        final result = await commandRunner.run([]);
        expect(printLogs, equals(expectedPrintLogs));
        expect(result, equals(ExitCode.success.code));
      }));

      group('--help', () {
        test('outputs usage', overridePrint(() async {
          const expectedPrintLogs = [
            '⛏️  mason • lay the foundation!\n'
                '\n'
                'Usage: mason <command> [arguments]\n'
                '\n'
                'Global options:\n'
                '-h, --help       Print this usage information.\n'
                '    --version    Print the current version.\n'
                '\n'
                'Available commands:\n'
                '  cache   Interact with mason cache\n'
                '  get     Gets all bricks.\n'
                '  init    Initialize mason in the current directory.\n'
                '  make    Generate code using an existing brick template.\n'
                '  new     Creates a new brick template.\n'
                '\n'
                '''Run "mason help <command>" for more information about a command.'''
          ];
          final result = await commandRunner.run(['--help']);
          expect(printLogs, equals(expectedPrintLogs));
          expect(result, equals(ExitCode.success.code));

          printLogs.clear();

          final resultAbbr = await commandRunner.run(['-h']);
          expect(printLogs, equals(expectedPrintLogs));
          expect(resultAbbr, equals(ExitCode.success.code));
        }));
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(logger.info('mason version: $packageVersion'));
        });
      });
    });
  });
}
