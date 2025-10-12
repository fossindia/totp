# CI/CD Pipeline Setup

This document describes the CI/CD pipeline setup for the TOTP Authenticator app.

## Overview

The project uses GitHub Actions for continuous integration and deployment with the following features:

- Automated testing on every push and pull request
- Test coverage reporting with Codecov integration
- Android APK building and artifact storage
- iOS build support (when iOS configuration is present)
- Security scanning with Trivy
- Dependency vulnerability checking

## Pipeline Structure

### Jobs

1. **test**: Runs tests with coverage and uploads results
2. **build-android**: Builds Android APK
3. **build-ios**: Builds iOS app (conditional)
4. **security-scan**: Runs security vulnerability scanning
5. **dependency-check**: Audits dependencies for vulnerabilities

## Local Development

### Running Tests with Coverage

Use the provided script to run tests with coverage locally:

```bash
./test_coverage.sh
```

This script will:
- Generate mocks using build_runner
- Run all tests with coverage
- Generate HTML coverage reports (if lcov is installed)
- Display coverage summary

### Development Commands

Use the provided Makefile for common development tasks:

```bash
# Show available commands
make help

# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run static analysis
make analyze

# Format code
make format

# Run linting
make lint

# Generate mocks
make mocks

# View coverage report
make coverage

# Run full quality check (format + lint + analyze + test + coverage)
make quality

# Clean and rebuild
make rebuild
```

## Coverage Configuration

### Codecov Settings

The project uses Codecov for coverage reporting with the following configuration:

- **Target Coverage**: 80%
- **Threshold**: 1% (allows small coverage decreases)
- **Flags**: Separate reporting for Flutter code
- **Ignored Paths**: Generated files, test files, platform-specific code

### Coverage Exclusions

The following paths are excluded from coverage reporting:
- `lib/main.dart` - Application entry point
- `lib/src/app.dart` - App widget
- `lib/src/app_router.dart` - Routing configuration
- `lib/src/splash_screen.dart` - Splash screen
- Test files and platform-specific code

## CI/CD Workflow

### Triggers

The pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

### Environment

- **OS**: Ubuntu latest
- **Flutter**: 3.24.0 (stable channel)

### Artifacts

The pipeline generates the following artifacts:
- Test coverage reports (lcov format)
- Android APK builds
- iOS builds (when applicable)
- Security scan reports

## Security Features

### Automated Security Scanning

- **Trivy**: Container and filesystem vulnerability scanning
- **Dependency Audit**: Flutter pub audit for package vulnerabilities
- **SARIF Reports**: Security findings uploaded to GitHub Security tab

### Dependency Management

- Automated dependency updates monitoring
- Outdated package detection
- Security vulnerability alerts

## Quality Gates

### Required Checks

1. **Static Analysis**: `flutter analyze` must pass
2. **Tests**: All tests must pass
3. **Coverage**: Minimum 80% coverage required
4. **Security**: No critical vulnerabilities

### Build Requirements

- Android APK must build successfully
- iOS build (when configured) must succeed
- All dependencies must resolve correctly

## Branch Protection

For production branches (`main`), consider enabling:

- Required status checks for all CI jobs
- Required reviews for pull requests
- Branch protection rules
- Signed commits requirement

## Monitoring and Alerts

### Coverage Trends

Monitor coverage trends using Codecov dashboard to ensure code quality maintenance.

### Security Alerts

GitHub Security tab will show:
- Dependency vulnerabilities
- Code scanning alerts
- Secret scanning alerts

### Performance Monitoring

Track CI build times and failure rates to optimize pipeline performance.

## Troubleshooting

### Common Issues

1. **Test Failures**: Check test logs for platform-specific issues
2. **Coverage Issues**: Ensure all testable code is covered
3. **Build Failures**: Verify Flutter version compatibility
4. **Security Scans**: Review false positives in security reports

### Local Testing

For issues that only occur in CI:

1. Use the same Flutter version locally
2. Run tests in the same order as CI
3. Check for platform-specific dependencies
4. Verify environment variables and secrets

## Future Enhancements

### Planned Improvements

1. **Multi-platform Testing**: Add iOS simulator testing
2. **Integration Tests**: Add device farm testing
3. **Performance Testing**: Automated performance regression testing
4. **Accessibility Testing**: Automated accessibility checks
5. **E2E Testing**: Full user journey testing

### Advanced Features

1. **Deployment Automation**: Automatic app store deployments
2. **Canary Releases**: Gradual rollout capabilities
3. **Rollback Automation**: Quick rollback procedures
4. **Environment Management**: Staging/production environment handling