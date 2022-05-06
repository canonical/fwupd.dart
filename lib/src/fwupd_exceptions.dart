class FwupdException implements Exception {
  final dynamic message;

  const FwupdException([this.message]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Internal error
class FwupdInternalException extends FwupdException {
  const FwupdInternalException([dynamic message]) : super(message);
}

/// Installed newer firmware version
class FwupdVersionNewerException extends FwupdException {
  const FwupdVersionNewerException([dynamic message]) : super(message);
}

/// Installed same firmware version
class FwupdVersionSameException extends FwupdException {
  const FwupdVersionSameException([dynamic message]) : super(message);
}

/// Already set be be installed offline
class FwupdAlreadyPendingException extends FwupdException {
  const FwupdAlreadyPendingException([dynamic message]) : super(message);
}

/// Failed to get authentication
class FwupdAuthFailedException extends FwupdException {
  const FwupdAuthFailedException([dynamic message]) : super(message);
}

/// Failed to read from device
class FwupdReadException extends FwupdException {
  const FwupdReadException([dynamic message]) : super(message);
}

/// Failed to write to the device
class FwupdWriteException extends FwupdException {
  const FwupdWriteException([dynamic message]) : super(message);
}

/// Invalid file format
class FwupdInvalidFileException extends FwupdException {
  const FwupdInvalidFileException([dynamic message]) : super(message);
}

/// No matching device exists
class FwupdNotFoundException extends FwupdException {
  const FwupdNotFoundException([dynamic message]) : super(message);
}

/// Nothing to do
class FwupdNothingToDoException extends FwupdException {
  const FwupdNothingToDoException([dynamic message]) : super(message);
}

/// Action was not possible
class FwupdNotSupportedException extends FwupdException {
  const FwupdNotSupportedException([dynamic message]) : super(message);
}

/// Signature was invalid
class FwupdSignatureInvalidException extends FwupdException {
  const FwupdSignatureInvalidException([dynamic message]) : super(message);
}

/// AC power was required
class FwupdAcPowerRequiredException extends FwupdException {
  const FwupdAcPowerRequiredException([dynamic message]) : super(message);
}

/// Permission was denied
class FwupdPermissionDeniedException extends FwupdException {
  const FwupdPermissionDeniedException([dynamic message]) : super(message);
}

/// User has configured their system in a broken way
class FwupdBrokenSystemException extends FwupdException {
  const FwupdBrokenSystemException([dynamic message]) : super(message);
}

/// The system battery level is too low
class FwupdBatteryLevelTooLowException extends FwupdException {
  const FwupdBatteryLevelTooLowException([dynamic message]) : super(message);
}

/// User needs to do an action to complete the update
class FwupdNeedsUserActionException extends FwupdException {
  const FwupdNeedsUserActionException([dynamic message]) : super(message);
}
