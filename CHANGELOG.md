# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-06-12

### Added
- Initial release of `idfy_license_checker`.
- DL extraction feature using IDfy `/extract/ind_driving_license` API.
- DL verification feature using IDfy `/verify_with_source/ind_driving_license` API.
- Support for image URL validation.
- Polling mechanism for async task completion.
- Parsed verification output with validity, name, DL number, and expiry.
- Unit tests for image URL validation.

### Notes
- Requires valid `apiKey` and `accountId` from [IDfy](https://www.idfy.com/).
- Uses `http` package for REST API calls.

