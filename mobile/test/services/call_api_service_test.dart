import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallApiService', () {
    test('createCall returns CallSession with callId and roomName', () {}, skip: true);
    test('createCall throws CallUnavailableException on 409 busy', () {}, skip: true);
    test('createCall throws AuthException on 401', () {}, skip: true);
    test('acceptCall returns CallSession with token after accept', () {}, skip: true);
    test('rejectCall completes without error', () {}, skip: true);
    test('cancelCall completes without error', () {}, skip: true);
    test('endCall completes without error', () {}, skip: true);
    test('getToken returns fresh token string', () {}, skip: true);
    test('all methods include Bearer auth header', () {}, skip: true);
    test('getCallState returns current call state from backend', () {}, skip: true);
  });
}
