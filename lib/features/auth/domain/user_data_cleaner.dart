abstract interface class UserDataCleaner {
  Future<void> deleteAll(String userId);
}
