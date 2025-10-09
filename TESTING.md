# Testing Guide for TOTP Flutter App

This document provides comprehensive information about testing the TOTP Flutter application, including unit tests, integration tests, widget tests, and CI/CD setup.

## 🧪 Test Structure

```
test/
├── unit/                          # Unit tests
│   ├── core/
│   │   ├── errors/
│   │   │   ├── app_error_test.dart
│   │   │   └── error_handler_test.dart
│   │   └── utils/
│   │       └── encryption_util_test.dart
│   └── features/
│       ├── auth/
│       ├── home/
│       ├── qr_scanner/
│       ├── settings/
│       ├── totp_generation/
│       │   └── totp_service_test.dart
│       └── totp_bloc_test.dart
├── widget/                        # Widget tests
│   └── totp_card_test.dart
├── integration/                   # Integration tests
│   └── qr_code_processing_workflow_test.dart
├── test_coverage.sh              # Coverage script
└── coverage_config.yaml          # Coverage configuration
```

## 🚀 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
./test_coverage.sh
```
or
```bash
flutter test --coverage
```

### Run Specific Test Files
```bash
flutter test test/unit/core/utils/encryption_util_test.dart
flutter test test/widget/totp_card_test.dart
```

### Run Tests with Verbose Output
```bash
flutter test -v
```

## 📊 Code Coverage

### Coverage Reports
- **LCOV Format**: `coverage/lcov.info`
- **HTML Report**: `coverage/html/index.html`
- **Codecov Integration**: Automatic upload on CI

### Coverage Thresholds
- **Minimum Overall**: 80%
- **Core Components**: 90%
- **Business Logic**: 85%
- **UI Components**: 70%

### Excluded from Coverage
- Entry points (`main.dart`, `app.dart`)
- Simple UI components
- Generated files
- Test files
- Data models (simple classes)

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
Located at: `.github/workflows/ci.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
1. **Test**: Run tests with coverage on Ubuntu
2. **Build Android**: Build APK on test success
3. **Build iOS**: Build iOS app on macOS (if applicable)

### Local CI Simulation
```bash
# Run full CI pipeline locally
./scripts/ci-local.sh
```

## 🛠️ Test Configuration

### Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  coverage: ^1.9.0
```

### Test Setup
- Uses Mockito for dependency mocking
- Service locator is reset between tests
- Platform-specific dependencies are mocked
- Test data uses realistic TOTP items

## 📋 Test Categories

### Unit Tests
- **Core Utilities**: Encryption, error handling
- **Business Logic**: TOTP generation, caching
- **State Management**: BLoC events and states

### Widget Tests
- **UI Components**: Card rendering, interactions
- **User Interactions**: Tap callbacks, state changes
- **Layout Validation**: Proper widget structure

### Integration Tests
- **Workflow Testing**: QR scanning to account creation
- **Service Integration**: Multiple services working together
- **Error Scenarios**: End-to-end error handling

## 🎯 Test Best Practices

### Naming Conventions
- `test_description.dart` for test files
- `group('Feature Name', () => {...})` for grouping
- `test('should do something', () => {...})` for individual tests

### Test Structure
```dart
void main() {
  group('Feature Name', () {
    setUp(() {
      // Setup code
    });

    tearDown(() {
      // Cleanup code
    });

    test('should handle normal case', () {
      // Arrange
      // Act
      // Assert
    });

    test('should handle edge case', () {
      // Test edge cases
    });
  });
}
```

### Mocking Guidelines
- Mock external dependencies (secure storage, services)
- Use realistic test data
- Verify interactions when necessary
- Reset state between tests

## 📈 Coverage Goals

### Current Status
- **Unit Tests**: ✅ Implemented
- **Widget Tests**: ✅ Implemented
- **Integration Tests**: ✅ Implemented
- **Coverage Reporting**: ✅ Configured
- **CI/CD Pipeline**: ✅ Set up

### Future Improvements
- Increase coverage to 90%+
- Add performance tests
- Implement visual regression tests
- Add accessibility testing

## 🐛 Debugging Tests

### Common Issues
1. **Service Locator Errors**: Ensure services are registered in setUp
2. **Platform Dependencies**: Mock platform channels properly
3. **Async Operations**: Use `await` and proper async test patterns
4. **Widget Testing**: Ensure proper widget tree setup

### Debugging Commands
```bash
# Run single test with detailed output
flutter test test/unit/core/utils/encryption_util_test.dart -v

# Run tests in debug mode
flutter test --debug

# Check test coverage for specific file
flutter test --coverage test/unit/core/utils/
```

## 📝 Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure minimum 80% coverage for new code
3. Update this documentation if needed
4. Run full test suite before submitting PR

## 🔗 Related Documentation

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Codecov Documentation](https://docs.codecov.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)