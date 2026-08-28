// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppStateTableTable extends AppStateTable
    with TableInfo<$AppStateTableTable, AppStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<int> onboardingCompleted = GeneratedColumn<int>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _firstLaunchAtMeta = const VerificationMeta(
    'firstLaunchAt',
  );
  @override
  late final GeneratedColumn<String> firstLaunchAt = GeneratedColumn<String>(
    'first_launch_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<String> lastSyncAt = GeneratedColumn<String>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncLockedAtMeta = const VerificationMeta(
    'syncLockedAt',
  );
  @override
  late final GeneratedColumn<String> syncLockedAt = GeneratedColumn<String>(
    'sync_locked_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    onboardingCompleted,
    languageCode,
    firstLaunchAt,
    lastSyncAt,
    syncLockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    }
    if (data.containsKey('first_launch_at')) {
      context.handle(
        _firstLaunchAtMeta,
        firstLaunchAt.isAcceptableOrUnknown(
          data['first_launch_at']!,
          _firstLaunchAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_locked_at')) {
      context.handle(
        _syncLockedAtMeta,
        syncLockedAt.isAcceptableOrUnknown(
          data['sync_locked_at']!,
          _syncLockedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      firstLaunchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_launch_at'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_at'],
      ),
      syncLockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_locked_at'],
      ),
    );
  }

  @override
  $AppStateTableTable createAlias(String alias) {
    return $AppStateTableTable(attachedDatabase, alias);
  }
}

class AppStateTableData extends DataClass
    implements Insertable<AppStateTableData> {
  /// Singleton enforced at the app layer (INSERT with id=1 only).
  /// A CHECK constraint cannot be expressed via Drift's column DSL without
  /// recursive getter issues; enforcement is handled by the repository.
  final int id;
  final int onboardingCompleted;

  /// 'en' | 'si' | 'ta'
  final String languageCode;

  /// ISO8601 — nullable
  final String? firstLaunchAt;
  final String? lastSyncAt;

  /// ISO8601 timestamp of the sync run currently holding the advisory lock,
  /// or null when no run is active.
  ///
  /// Sync can be triggered from the UI, the connectivity listener, the
  /// post-auth hook, AND a WorkManager background isolate. The isolate has
  /// its own memory, so an in-process flag cannot exclude it — the lock has
  /// to live somewhere both can see, i.e. the database. Treated as stale
  /// after a timeout so a crashed run cannot deadlock sync forever.
  final String? syncLockedAt;
  const AppStateTableData({
    required this.id,
    required this.onboardingCompleted,
    required this.languageCode,
    this.firstLaunchAt,
    this.lastSyncAt,
    this.syncLockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['onboarding_completed'] = Variable<int>(onboardingCompleted);
    map['language_code'] = Variable<String>(languageCode);
    if (!nullToAbsent || firstLaunchAt != null) {
      map['first_launch_at'] = Variable<String>(firstLaunchAt);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<String>(lastSyncAt);
    }
    if (!nullToAbsent || syncLockedAt != null) {
      map['sync_locked_at'] = Variable<String>(syncLockedAt);
    }
    return map;
  }

  AppStateTableCompanion toCompanion(bool nullToAbsent) {
    return AppStateTableCompanion(
      id: Value(id),
      onboardingCompleted: Value(onboardingCompleted),
      languageCode: Value(languageCode),
      firstLaunchAt: firstLaunchAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstLaunchAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      syncLockedAt: syncLockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncLockedAt),
    );
  }

  factory AppStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateTableData(
      id: serializer.fromJson<int>(json['id']),
      onboardingCompleted: serializer.fromJson<int>(
        json['onboardingCompleted'],
      ),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      firstLaunchAt: serializer.fromJson<String?>(json['firstLaunchAt']),
      lastSyncAt: serializer.fromJson<String?>(json['lastSyncAt']),
      syncLockedAt: serializer.fromJson<String?>(json['syncLockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'onboardingCompleted': serializer.toJson<int>(onboardingCompleted),
      'languageCode': serializer.toJson<String>(languageCode),
      'firstLaunchAt': serializer.toJson<String?>(firstLaunchAt),
      'lastSyncAt': serializer.toJson<String?>(lastSyncAt),
      'syncLockedAt': serializer.toJson<String?>(syncLockedAt),
    };
  }

  AppStateTableData copyWith({
    int? id,
    int? onboardingCompleted,
    String? languageCode,
    Value<String?> firstLaunchAt = const Value.absent(),
    Value<String?> lastSyncAt = const Value.absent(),
    Value<String?> syncLockedAt = const Value.absent(),
  }) => AppStateTableData(
    id: id ?? this.id,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    languageCode: languageCode ?? this.languageCode,
    firstLaunchAt: firstLaunchAt.present
        ? firstLaunchAt.value
        : this.firstLaunchAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    syncLockedAt: syncLockedAt.present ? syncLockedAt.value : this.syncLockedAt,
  );
  AppStateTableData copyWithCompanion(AppStateTableCompanion data) {
    return AppStateTableData(
      id: data.id.present ? data.id.value : this.id,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      firstLaunchAt: data.firstLaunchAt.present
          ? data.firstLaunchAt.value
          : this.firstLaunchAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      syncLockedAt: data.syncLockedAt.present
          ? data.syncLockedAt.value
          : this.syncLockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateTableData(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('languageCode: $languageCode, ')
          ..write('firstLaunchAt: $firstLaunchAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncLockedAt: $syncLockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    onboardingCompleted,
    languageCode,
    firstLaunchAt,
    lastSyncAt,
    syncLockedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppStateTableData &&
          other.id == this.id &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.languageCode == this.languageCode &&
          other.firstLaunchAt == this.firstLaunchAt &&
          other.lastSyncAt == this.lastSyncAt &&
          other.syncLockedAt == this.syncLockedAt);
}

class AppStateTableCompanion extends UpdateCompanion<AppStateTableData> {
  final Value<int> id;
  final Value<int> onboardingCompleted;
  final Value<String> languageCode;
  final Value<String?> firstLaunchAt;
  final Value<String?> lastSyncAt;
  final Value<String?> syncLockedAt;
  const AppStateTableCompanion({
    this.id = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.firstLaunchAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.syncLockedAt = const Value.absent(),
  });
  AppStateTableCompanion.insert({
    this.id = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.firstLaunchAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.syncLockedAt = const Value.absent(),
  });
  static Insertable<AppStateTableData> custom({
    Expression<int>? id,
    Expression<int>? onboardingCompleted,
    Expression<String>? languageCode,
    Expression<String>? firstLaunchAt,
    Expression<String>? lastSyncAt,
    Expression<String>? syncLockedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (languageCode != null) 'language_code': languageCode,
      if (firstLaunchAt != null) 'first_launch_at': firstLaunchAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (syncLockedAt != null) 'sync_locked_at': syncLockedAt,
    });
  }

  AppStateTableCompanion copyWith({
    Value<int>? id,
    Value<int>? onboardingCompleted,
    Value<String>? languageCode,
    Value<String?>? firstLaunchAt,
    Value<String?>? lastSyncAt,
    Value<String?>? syncLockedAt,
  }) {
    return AppStateTableCompanion(
      id: id ?? this.id,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      languageCode: languageCode ?? this.languageCode,
      firstLaunchAt: firstLaunchAt ?? this.firstLaunchAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncLockedAt: syncLockedAt ?? this.syncLockedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<int>(onboardingCompleted.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (firstLaunchAt.present) {
      map['first_launch_at'] = Variable<String>(firstLaunchAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<String>(lastSyncAt.value);
    }
    if (syncLockedAt.present) {
      map['sync_locked_at'] = Variable<String>(syncLockedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppStateTableCompanion(')
          ..write('id: $id, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('languageCode: $languageCode, ')
          ..write('firstLaunchAt: $firstLaunchAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('syncLockedAt: $syncLockedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalUserTableTable extends LocalUserTable
    with TableInfo<$LocalUserTableTable, LocalUserTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUserTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteUserIdMeta = const VerificationMeta(
    'remoteUserId',
  );
  @override
  late final GeneratedColumn<String> remoteUserId = GeneratedColumn<String>(
    'remote_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGuestMeta = const VerificationMeta(
    'isGuest',
  );
  @override
  late final GeneratedColumn<int> isGuest = GeneratedColumn<int>(
    'is_guest',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sessionTokenMeta = const VerificationMeta(
    'sessionToken',
  );
  @override
  late final GeneratedColumn<String> sessionToken = GeneratedColumn<String>(
    'session_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionRefreshTokenMeta =
      const VerificationMeta('sessionRefreshToken');
  @override
  late final GeneratedColumn<String> sessionRefreshToken =
      GeneratedColumn<String>(
        'session_refresh_token',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sessionExpiresAtMeta = const VerificationMeta(
    'sessionExpiresAt',
  );
  @override
  late final GeneratedColumn<String> sessionExpiresAt = GeneratedColumn<String>(
    'session_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteUserId,
    email,
    phoneNumber,
    isGuest,
    sessionToken,
    sessionRefreshToken,
    sessionExpiresAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_user';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalUserTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_user_id')) {
      context.handle(
        _remoteUserIdMeta,
        remoteUserId.isAcceptableOrUnknown(
          data['remote_user_id']!,
          _remoteUserIdMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_guest')) {
      context.handle(
        _isGuestMeta,
        isGuest.isAcceptableOrUnknown(data['is_guest']!, _isGuestMeta),
      );
    }
    if (data.containsKey('session_token')) {
      context.handle(
        _sessionTokenMeta,
        sessionToken.isAcceptableOrUnknown(
          data['session_token']!,
          _sessionTokenMeta,
        ),
      );
    }
    if (data.containsKey('session_refresh_token')) {
      context.handle(
        _sessionRefreshTokenMeta,
        sessionRefreshToken.isAcceptableOrUnknown(
          data['session_refresh_token']!,
          _sessionRefreshTokenMeta,
        ),
      );
    }
    if (data.containsKey('session_expires_at')) {
      context.handle(
        _sessionExpiresAtMeta,
        sessionExpiresAt.isAcceptableOrUnknown(
          data['session_expires_at']!,
          _sessionExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalUserTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUserTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_user_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      isGuest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_guest'],
      )!,
      sessionToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_token'],
      ),
      sessionRefreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_refresh_token'],
      ),
      sessionExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalUserTableTable createAlias(String alias) {
    return $LocalUserTableTable(attachedDatabase, alias);
  }
}

class LocalUserTableData extends DataClass
    implements Insertable<LocalUserTableData> {
  /// Local UUID; becomes server user id after auth.
  final String id;
  final String? remoteUserId;
  final String? email;
  final String? phoneNumber;
  final int isGuest;
  final String? sessionToken;
  final String? sessionRefreshToken;
  final String? sessionExpiresAt;

  /// ISO8601 — NOT NULL
  final String createdAt;
  final String updatedAt;
  const LocalUserTableData({
    required this.id,
    this.remoteUserId,
    this.email,
    this.phoneNumber,
    required this.isGuest,
    this.sessionToken,
    this.sessionRefreshToken,
    this.sessionExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteUserId != null) {
      map['remote_user_id'] = Variable<String>(remoteUserId);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    map['is_guest'] = Variable<int>(isGuest);
    if (!nullToAbsent || sessionToken != null) {
      map['session_token'] = Variable<String>(sessionToken);
    }
    if (!nullToAbsent || sessionRefreshToken != null) {
      map['session_refresh_token'] = Variable<String>(sessionRefreshToken);
    }
    if (!nullToAbsent || sessionExpiresAt != null) {
      map['session_expires_at'] = Variable<String>(sessionExpiresAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocalUserTableCompanion toCompanion(bool nullToAbsent) {
    return LocalUserTableCompanion(
      id: Value(id),
      remoteUserId: remoteUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUserId),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      isGuest: Value(isGuest),
      sessionToken: sessionToken == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionToken),
      sessionRefreshToken: sessionRefreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionRefreshToken),
      sessionExpiresAt: sessionExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionExpiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalUserTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUserTableData(
      id: serializer.fromJson<String>(json['id']),
      remoteUserId: serializer.fromJson<String?>(json['remoteUserId']),
      email: serializer.fromJson<String?>(json['email']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      isGuest: serializer.fromJson<int>(json['isGuest']),
      sessionToken: serializer.fromJson<String?>(json['sessionToken']),
      sessionRefreshToken: serializer.fromJson<String?>(
        json['sessionRefreshToken'],
      ),
      sessionExpiresAt: serializer.fromJson<String?>(json['sessionExpiresAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteUserId': serializer.toJson<String?>(remoteUserId),
      'email': serializer.toJson<String?>(email),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'isGuest': serializer.toJson<int>(isGuest),
      'sessionToken': serializer.toJson<String?>(sessionToken),
      'sessionRefreshToken': serializer.toJson<String?>(sessionRefreshToken),
      'sessionExpiresAt': serializer.toJson<String?>(sessionExpiresAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocalUserTableData copyWith({
    String? id,
    Value<String?> remoteUserId = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    int? isGuest,
    Value<String?> sessionToken = const Value.absent(),
    Value<String?> sessionRefreshToken = const Value.absent(),
    Value<String?> sessionExpiresAt = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => LocalUserTableData(
    id: id ?? this.id,
    remoteUserId: remoteUserId.present ? remoteUserId.value : this.remoteUserId,
    email: email.present ? email.value : this.email,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    isGuest: isGuest ?? this.isGuest,
    sessionToken: sessionToken.present ? sessionToken.value : this.sessionToken,
    sessionRefreshToken: sessionRefreshToken.present
        ? sessionRefreshToken.value
        : this.sessionRefreshToken,
    sessionExpiresAt: sessionExpiresAt.present
        ? sessionExpiresAt.value
        : this.sessionExpiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalUserTableData copyWithCompanion(LocalUserTableCompanion data) {
    return LocalUserTableData(
      id: data.id.present ? data.id.value : this.id,
      remoteUserId: data.remoteUserId.present
          ? data.remoteUserId.value
          : this.remoteUserId,
      email: data.email.present ? data.email.value : this.email,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      isGuest: data.isGuest.present ? data.isGuest.value : this.isGuest,
      sessionToken: data.sessionToken.present
          ? data.sessionToken.value
          : this.sessionToken,
      sessionRefreshToken: data.sessionRefreshToken.present
          ? data.sessionRefreshToken.value
          : this.sessionRefreshToken,
      sessionExpiresAt: data.sessionExpiresAt.present
          ? data.sessionExpiresAt.value
          : this.sessionExpiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserTableData(')
          ..write('id: $id, ')
          ..write('remoteUserId: $remoteUserId, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('isGuest: $isGuest, ')
          ..write('sessionToken: $sessionToken, ')
          ..write('sessionRefreshToken: $sessionRefreshToken, ')
          ..write('sessionExpiresAt: $sessionExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteUserId,
    email,
    phoneNumber,
    isGuest,
    sessionToken,
    sessionRefreshToken,
    sessionExpiresAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUserTableData &&
          other.id == this.id &&
          other.remoteUserId == this.remoteUserId &&
          other.email == this.email &&
          other.phoneNumber == this.phoneNumber &&
          other.isGuest == this.isGuest &&
          other.sessionToken == this.sessionToken &&
          other.sessionRefreshToken == this.sessionRefreshToken &&
          other.sessionExpiresAt == this.sessionExpiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalUserTableCompanion extends UpdateCompanion<LocalUserTableData> {
  final Value<String> id;
  final Value<String?> remoteUserId;
  final Value<String?> email;
  final Value<String?> phoneNumber;
  final Value<int> isGuest;
  final Value<String?> sessionToken;
  final Value<String?> sessionRefreshToken;
  final Value<String?> sessionExpiresAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocalUserTableCompanion({
    this.id = const Value.absent(),
    this.remoteUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.isGuest = const Value.absent(),
    this.sessionToken = const Value.absent(),
    this.sessionRefreshToken = const Value.absent(),
    this.sessionExpiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUserTableCompanion.insert({
    required String id,
    this.remoteUserId = const Value.absent(),
    this.email = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.isGuest = const Value.absent(),
    this.sessionToken = const Value.absent(),
    this.sessionRefreshToken = const Value.absent(),
    this.sessionExpiresAt = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalUserTableData> custom({
    Expression<String>? id,
    Expression<String>? remoteUserId,
    Expression<String>? email,
    Expression<String>? phoneNumber,
    Expression<int>? isGuest,
    Expression<String>? sessionToken,
    Expression<String>? sessionRefreshToken,
    Expression<String>? sessionExpiresAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteUserId != null) 'remote_user_id': remoteUserId,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (isGuest != null) 'is_guest': isGuest,
      if (sessionToken != null) 'session_token': sessionToken,
      if (sessionRefreshToken != null)
        'session_refresh_token': sessionRefreshToken,
      if (sessionExpiresAt != null) 'session_expires_at': sessionExpiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUserTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteUserId,
    Value<String?>? email,
    Value<String?>? phoneNumber,
    Value<int>? isGuest,
    Value<String?>? sessionToken,
    Value<String?>? sessionRefreshToken,
    Value<String?>? sessionExpiresAt,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalUserTableCompanion(
      id: id ?? this.id,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isGuest: isGuest ?? this.isGuest,
      sessionToken: sessionToken ?? this.sessionToken,
      sessionRefreshToken: sessionRefreshToken ?? this.sessionRefreshToken,
      sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteUserId.present) {
      map['remote_user_id'] = Variable<String>(remoteUserId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (isGuest.present) {
      map['is_guest'] = Variable<int>(isGuest.value);
    }
    if (sessionToken.present) {
      map['session_token'] = Variable<String>(sessionToken.value);
    }
    if (sessionRefreshToken.present) {
      map['session_refresh_token'] = Variable<String>(
        sessionRefreshToken.value,
      );
    }
    if (sessionExpiresAt.present) {
      map['session_expires_at'] = Variable<String>(sessionExpiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUserTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteUserId: $remoteUserId, ')
          ..write('email: $email, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('isGuest: $isGuest, ')
          ..write('sessionToken: $sessionToken, ')
          ..write('sessionRefreshToken: $sessionRefreshToken, ')
          ..write('sessionExpiresAt: $sessionExpiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CropTableTable extends CropTable
    with TableInfo<$CropTableTable, CropTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameSiMeta = const VerificationMeta('nameSi');
  @override
  late final GeneratedColumn<String> nameSi = GeneratedColumn<String>(
    'name_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameTaMeta = const VerificationMeta('nameTa');
  @override
  late final GeneratedColumn<String> nameTa = GeneratedColumn<String>(
    'name_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSupportedMeta = const VerificationMeta(
    'isSupported',
  );
  @override
  late final GeneratedColumn<int> isSupported = GeneratedColumn<int>(
    'is_supported',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _iconAssetMeta = const VerificationMeta(
    'iconAsset',
  );
  @override
  late final GeneratedColumn<String> iconAsset = GeneratedColumn<String>(
    'icon_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameEn,
    nameSi,
    nameTa,
    isSupported,
    iconAsset,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crop';
  @override
  VerificationContext validateIntegrity(
    Insertable<CropTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_si')) {
      context.handle(
        _nameSiMeta,
        nameSi.isAcceptableOrUnknown(data['name_si']!, _nameSiMeta),
      );
    }
    if (data.containsKey('name_ta')) {
      context.handle(
        _nameTaMeta,
        nameTa.isAcceptableOrUnknown(data['name_ta']!, _nameTaMeta),
      );
    }
    if (data.containsKey('is_supported')) {
      context.handle(
        _isSupportedMeta,
        isSupported.isAcceptableOrUnknown(
          data['is_supported']!,
          _isSupportedMeta,
        ),
      );
    }
    if (data.containsKey('icon_asset')) {
      context.handle(
        _iconAssetMeta,
        iconAsset.isAcceptableOrUnknown(data['icon_asset']!, _iconAssetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CropTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_si'],
      ),
      nameTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ta'],
      ),
      isSupported: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_supported'],
      )!,
      iconAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_asset'],
      ),
    );
  }

  @override
  $CropTableTable createAlias(String alias) {
    return $CropTableTable(attachedDatabase, alias);
  }
}

class CropTableData extends DataClass implements Insertable<CropTableData> {
  /// e.g. 'tomato'
  final String id;
  final String nameEn;
  final String? nameSi;
  final String? nameTa;
  final int isSupported;
  final String? iconAsset;
  const CropTableData({
    required this.id,
    required this.nameEn,
    this.nameSi,
    this.nameTa,
    required this.isSupported,
    this.iconAsset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameSi != null) {
      map['name_si'] = Variable<String>(nameSi);
    }
    if (!nullToAbsent || nameTa != null) {
      map['name_ta'] = Variable<String>(nameTa);
    }
    map['is_supported'] = Variable<int>(isSupported);
    if (!nullToAbsent || iconAsset != null) {
      map['icon_asset'] = Variable<String>(iconAsset);
    }
    return map;
  }

  CropTableCompanion toCompanion(bool nullToAbsent) {
    return CropTableCompanion(
      id: Value(id),
      nameEn: Value(nameEn),
      nameSi: nameSi == null && nullToAbsent
          ? const Value.absent()
          : Value(nameSi),
      nameTa: nameTa == null && nullToAbsent
          ? const Value.absent()
          : Value(nameTa),
      isSupported: Value(isSupported),
      iconAsset: iconAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(iconAsset),
    );
  }

  factory CropTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropTableData(
      id: serializer.fromJson<String>(json['id']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameSi: serializer.fromJson<String?>(json['nameSi']),
      nameTa: serializer.fromJson<String?>(json['nameTa']),
      isSupported: serializer.fromJson<int>(json['isSupported']),
      iconAsset: serializer.fromJson<String?>(json['iconAsset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameSi': serializer.toJson<String?>(nameSi),
      'nameTa': serializer.toJson<String?>(nameTa),
      'isSupported': serializer.toJson<int>(isSupported),
      'iconAsset': serializer.toJson<String?>(iconAsset),
    };
  }

  CropTableData copyWith({
    String? id,
    String? nameEn,
    Value<String?> nameSi = const Value.absent(),
    Value<String?> nameTa = const Value.absent(),
    int? isSupported,
    Value<String?> iconAsset = const Value.absent(),
  }) => CropTableData(
    id: id ?? this.id,
    nameEn: nameEn ?? this.nameEn,
    nameSi: nameSi.present ? nameSi.value : this.nameSi,
    nameTa: nameTa.present ? nameTa.value : this.nameTa,
    isSupported: isSupported ?? this.isSupported,
    iconAsset: iconAsset.present ? iconAsset.value : this.iconAsset,
  );
  CropTableData copyWithCompanion(CropTableCompanion data) {
    return CropTableData(
      id: data.id.present ? data.id.value : this.id,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameSi: data.nameSi.present ? data.nameSi.value : this.nameSi,
      nameTa: data.nameTa.present ? data.nameTa.value : this.nameTa,
      isSupported: data.isSupported.present
          ? data.isSupported.value
          : this.isSupported,
      iconAsset: data.iconAsset.present ? data.iconAsset.value : this.iconAsset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropTableData(')
          ..write('id: $id, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSi: $nameSi, ')
          ..write('nameTa: $nameTa, ')
          ..write('isSupported: $isSupported, ')
          ..write('iconAsset: $iconAsset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameEn, nameSi, nameTa, isSupported, iconAsset);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropTableData &&
          other.id == this.id &&
          other.nameEn == this.nameEn &&
          other.nameSi == this.nameSi &&
          other.nameTa == this.nameTa &&
          other.isSupported == this.isSupported &&
          other.iconAsset == this.iconAsset);
}

class CropTableCompanion extends UpdateCompanion<CropTableData> {
  final Value<String> id;
  final Value<String> nameEn;
  final Value<String?> nameSi;
  final Value<String?> nameTa;
  final Value<int> isSupported;
  final Value<String?> iconAsset;
  final Value<int> rowid;
  const CropTableCompanion({
    this.id = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameSi = const Value.absent(),
    this.nameTa = const Value.absent(),
    this.isSupported = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CropTableCompanion.insert({
    required String id,
    required String nameEn,
    this.nameSi = const Value.absent(),
    this.nameTa = const Value.absent(),
    this.isSupported = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameEn = Value(nameEn);
  static Insertable<CropTableData> custom({
    Expression<String>? id,
    Expression<String>? nameEn,
    Expression<String>? nameSi,
    Expression<String>? nameTa,
    Expression<int>? isSupported,
    Expression<String>? iconAsset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameEn != null) 'name_en': nameEn,
      if (nameSi != null) 'name_si': nameSi,
      if (nameTa != null) 'name_ta': nameTa,
      if (isSupported != null) 'is_supported': isSupported,
      if (iconAsset != null) 'icon_asset': iconAsset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CropTableCompanion copyWith({
    Value<String>? id,
    Value<String>? nameEn,
    Value<String?>? nameSi,
    Value<String?>? nameTa,
    Value<int>? isSupported,
    Value<String?>? iconAsset,
    Value<int>? rowid,
  }) {
    return CropTableCompanion(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      nameTa: nameTa ?? this.nameTa,
      isSupported: isSupported ?? this.isSupported,
      iconAsset: iconAsset ?? this.iconAsset,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameSi.present) {
      map['name_si'] = Variable<String>(nameSi.value);
    }
    if (nameTa.present) {
      map['name_ta'] = Variable<String>(nameTa.value);
    }
    if (isSupported.present) {
      map['is_supported'] = Variable<int>(isSupported.value);
    }
    if (iconAsset.present) {
      map['icon_asset'] = Variable<String>(iconAsset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CropTableCompanion(')
          ..write('id: $id, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSi: $nameSi, ')
          ..write('nameTa: $nameTa, ')
          ..write('isSupported: $isSupported, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiseaseTableTable extends DiseaseTable
    with TableInfo<$DiseaseTableTable, DiseaseTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiseaseTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES crop (id)',
    ),
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameSiMeta = const VerificationMeta('nameSi');
  @override
  late final GeneratedColumn<String> nameSi = GeneratedColumn<String>(
    'name_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameTaMeta = const VerificationMeta('nameTa');
  @override
  late final GeneratedColumn<String> nameTa = GeneratedColumn<String>(
    'name_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityDefaultMeta = const VerificationMeta(
    'severityDefault',
  );
  @override
  late final GeneratedColumn<String> severityDefault = GeneratedColumn<String>(
    'severity_default',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cropId,
    nameEn,
    nameSi,
    nameTa,
    severityDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disease';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiseaseTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_si')) {
      context.handle(
        _nameSiMeta,
        nameSi.isAcceptableOrUnknown(data['name_si']!, _nameSiMeta),
      );
    }
    if (data.containsKey('name_ta')) {
      context.handle(
        _nameTaMeta,
        nameTa.isAcceptableOrUnknown(data['name_ta']!, _nameTaMeta),
      );
    }
    if (data.containsKey('severity_default')) {
      context.handle(
        _severityDefaultMeta,
        severityDefault.isAcceptableOrUnknown(
          data['severity_default']!,
          _severityDefaultMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiseaseTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiseaseTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_si'],
      ),
      nameTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ta'],
      ),
      severityDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity_default'],
      ),
    );
  }

  @override
  $DiseaseTableTable createAlias(String alias) {
    return $DiseaseTableTable(attachedDatabase, alias);
  }
}

class DiseaseTableData extends DataClass
    implements Insertable<DiseaseTableData> {
  /// e.g. 'tomato_late_blight'
  final String id;
  final String cropId;
  final String nameEn;
  final String? nameSi;
  final String? nameTa;

  /// 'low' | 'moderate' | 'high' — nullable
  final String? severityDefault;
  const DiseaseTableData({
    required this.id,
    required this.cropId,
    required this.nameEn,
    this.nameSi,
    this.nameTa,
    this.severityDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['crop_id'] = Variable<String>(cropId);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameSi != null) {
      map['name_si'] = Variable<String>(nameSi);
    }
    if (!nullToAbsent || nameTa != null) {
      map['name_ta'] = Variable<String>(nameTa);
    }
    if (!nullToAbsent || severityDefault != null) {
      map['severity_default'] = Variable<String>(severityDefault);
    }
    return map;
  }

  DiseaseTableCompanion toCompanion(bool nullToAbsent) {
    return DiseaseTableCompanion(
      id: Value(id),
      cropId: Value(cropId),
      nameEn: Value(nameEn),
      nameSi: nameSi == null && nullToAbsent
          ? const Value.absent()
          : Value(nameSi),
      nameTa: nameTa == null && nullToAbsent
          ? const Value.absent()
          : Value(nameTa),
      severityDefault: severityDefault == null && nullToAbsent
          ? const Value.absent()
          : Value(severityDefault),
    );
  }

  factory DiseaseTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiseaseTableData(
      id: serializer.fromJson<String>(json['id']),
      cropId: serializer.fromJson<String>(json['cropId']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameSi: serializer.fromJson<String?>(json['nameSi']),
      nameTa: serializer.fromJson<String?>(json['nameTa']),
      severityDefault: serializer.fromJson<String?>(json['severityDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cropId': serializer.toJson<String>(cropId),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameSi': serializer.toJson<String?>(nameSi),
      'nameTa': serializer.toJson<String?>(nameTa),
      'severityDefault': serializer.toJson<String?>(severityDefault),
    };
  }

  DiseaseTableData copyWith({
    String? id,
    String? cropId,
    String? nameEn,
    Value<String?> nameSi = const Value.absent(),
    Value<String?> nameTa = const Value.absent(),
    Value<String?> severityDefault = const Value.absent(),
  }) => DiseaseTableData(
    id: id ?? this.id,
    cropId: cropId ?? this.cropId,
    nameEn: nameEn ?? this.nameEn,
    nameSi: nameSi.present ? nameSi.value : this.nameSi,
    nameTa: nameTa.present ? nameTa.value : this.nameTa,
    severityDefault: severityDefault.present
        ? severityDefault.value
        : this.severityDefault,
  );
  DiseaseTableData copyWithCompanion(DiseaseTableCompanion data) {
    return DiseaseTableData(
      id: data.id.present ? data.id.value : this.id,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameSi: data.nameSi.present ? data.nameSi.value : this.nameSi,
      nameTa: data.nameTa.present ? data.nameTa.value : this.nameTa,
      severityDefault: data.severityDefault.present
          ? data.severityDefault.value
          : this.severityDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseTableData(')
          ..write('id: $id, ')
          ..write('cropId: $cropId, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSi: $nameSi, ')
          ..write('nameTa: $nameTa, ')
          ..write('severityDefault: $severityDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cropId, nameEn, nameSi, nameTa, severityDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiseaseTableData &&
          other.id == this.id &&
          other.cropId == this.cropId &&
          other.nameEn == this.nameEn &&
          other.nameSi == this.nameSi &&
          other.nameTa == this.nameTa &&
          other.severityDefault == this.severityDefault);
}

class DiseaseTableCompanion extends UpdateCompanion<DiseaseTableData> {
  final Value<String> id;
  final Value<String> cropId;
  final Value<String> nameEn;
  final Value<String?> nameSi;
  final Value<String?> nameTa;
  final Value<String?> severityDefault;
  final Value<int> rowid;
  const DiseaseTableCompanion({
    this.id = const Value.absent(),
    this.cropId = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameSi = const Value.absent(),
    this.nameTa = const Value.absent(),
    this.severityDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiseaseTableCompanion.insert({
    required String id,
    required String cropId,
    required String nameEn,
    this.nameSi = const Value.absent(),
    this.nameTa = const Value.absent(),
    this.severityDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cropId = Value(cropId),
       nameEn = Value(nameEn);
  static Insertable<DiseaseTableData> custom({
    Expression<String>? id,
    Expression<String>? cropId,
    Expression<String>? nameEn,
    Expression<String>? nameSi,
    Expression<String>? nameTa,
    Expression<String>? severityDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cropId != null) 'crop_id': cropId,
      if (nameEn != null) 'name_en': nameEn,
      if (nameSi != null) 'name_si': nameSi,
      if (nameTa != null) 'name_ta': nameTa,
      if (severityDefault != null) 'severity_default': severityDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiseaseTableCompanion copyWith({
    Value<String>? id,
    Value<String>? cropId,
    Value<String>? nameEn,
    Value<String?>? nameSi,
    Value<String?>? nameTa,
    Value<String?>? severityDefault,
    Value<int>? rowid,
  }) {
    return DiseaseTableCompanion(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      nameEn: nameEn ?? this.nameEn,
      nameSi: nameSi ?? this.nameSi,
      nameTa: nameTa ?? this.nameTa,
      severityDefault: severityDefault ?? this.severityDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameSi.present) {
      map['name_si'] = Variable<String>(nameSi.value);
    }
    if (nameTa.present) {
      map['name_ta'] = Variable<String>(nameTa.value);
    }
    if (severityDefault.present) {
      map['severity_default'] = Variable<String>(severityDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseTableCompanion(')
          ..write('id: $id, ')
          ..write('cropId: $cropId, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSi: $nameSi, ')
          ..write('nameTa: $nameTa, ')
          ..write('severityDefault: $severityDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreatmentGuidelineTableTable extends TreatmentGuidelineTable
    with TableInfo<$TreatmentGuidelineTableTable, TreatmentGuidelineTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatmentGuidelineTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diseaseIdMeta = const VerificationMeta(
    'diseaseId',
  );
  @override
  late final GeneratedColumn<String> diseaseId = GeneratedColumn<String>(
    'disease_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disease (id)',
    ),
  );
  static const VerificationMeta _guidelineVersionMeta = const VerificationMeta(
    'guidelineVersion',
  );
  @override
  late final GeneratedColumn<String> guidelineVersion = GeneratedColumn<String>(
    'guideline_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryEnMeta = const VerificationMeta(
    'summaryEn',
  );
  @override
  late final GeneratedColumn<String> summaryEn = GeneratedColumn<String>(
    'summary_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summarySiMeta = const VerificationMeta(
    'summarySi',
  );
  @override
  late final GeneratedColumn<String> summarySi = GeneratedColumn<String>(
    'summary_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryTaMeta = const VerificationMeta(
    'summaryTa',
  );
  @override
  late final GeneratedColumn<String> summaryTa = GeneratedColumn<String>(
    'summary_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToDoEnMeta = const VerificationMeta(
    'whatToDoEn',
  );
  @override
  late final GeneratedColumn<String> whatToDoEn = GeneratedColumn<String>(
    'what_to_do_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToDoSiMeta = const VerificationMeta(
    'whatToDoSi',
  );
  @override
  late final GeneratedColumn<String> whatToDoSi = GeneratedColumn<String>(
    'what_to_do_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToDoTaMeta = const VerificationMeta(
    'whatToDoTa',
  );
  @override
  late final GeneratedColumn<String> whatToDoTa = GeneratedColumn<String>(
    'what_to_do_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToAvoidEnMeta = const VerificationMeta(
    'whatToAvoidEn',
  );
  @override
  late final GeneratedColumn<String> whatToAvoidEn = GeneratedColumn<String>(
    'what_to_avoid_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToAvoidSiMeta = const VerificationMeta(
    'whatToAvoidSi',
  );
  @override
  late final GeneratedColumn<String> whatToAvoidSi = GeneratedColumn<String>(
    'what_to_avoid_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whatToAvoidTaMeta = const VerificationMeta(
    'whatToAvoidTa',
  );
  @override
  late final GeneratedColumn<String> whatToAvoidTa = GeneratedColumn<String>(
    'what_to_avoid_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recheckAfterDaysMeta = const VerificationMeta(
    'recheckAfterDays',
  );
  @override
  late final GeneratedColumn<int> recheckAfterDays = GeneratedColumn<int>(
    'recheck_after_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<String> publishedAt = GeneratedColumn<String>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diseaseId,
    guidelineVersion,
    summaryEn,
    summarySi,
    summaryTa,
    whatToDoEn,
    whatToDoSi,
    whatToDoTa,
    whatToAvoidEn,
    whatToAvoidSi,
    whatToAvoidTa,
    recheckAfterDays,
    publishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treatment_guideline';
  @override
  VerificationContext validateIntegrity(
    Insertable<TreatmentGuidelineTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('disease_id')) {
      context.handle(
        _diseaseIdMeta,
        diseaseId.isAcceptableOrUnknown(data['disease_id']!, _diseaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diseaseIdMeta);
    }
    if (data.containsKey('guideline_version')) {
      context.handle(
        _guidelineVersionMeta,
        guidelineVersion.isAcceptableOrUnknown(
          data['guideline_version']!,
          _guidelineVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_guidelineVersionMeta);
    }
    if (data.containsKey('summary_en')) {
      context.handle(
        _summaryEnMeta,
        summaryEn.isAcceptableOrUnknown(data['summary_en']!, _summaryEnMeta),
      );
    }
    if (data.containsKey('summary_si')) {
      context.handle(
        _summarySiMeta,
        summarySi.isAcceptableOrUnknown(data['summary_si']!, _summarySiMeta),
      );
    }
    if (data.containsKey('summary_ta')) {
      context.handle(
        _summaryTaMeta,
        summaryTa.isAcceptableOrUnknown(data['summary_ta']!, _summaryTaMeta),
      );
    }
    if (data.containsKey('what_to_do_en')) {
      context.handle(
        _whatToDoEnMeta,
        whatToDoEn.isAcceptableOrUnknown(
          data['what_to_do_en']!,
          _whatToDoEnMeta,
        ),
      );
    }
    if (data.containsKey('what_to_do_si')) {
      context.handle(
        _whatToDoSiMeta,
        whatToDoSi.isAcceptableOrUnknown(
          data['what_to_do_si']!,
          _whatToDoSiMeta,
        ),
      );
    }
    if (data.containsKey('what_to_do_ta')) {
      context.handle(
        _whatToDoTaMeta,
        whatToDoTa.isAcceptableOrUnknown(
          data['what_to_do_ta']!,
          _whatToDoTaMeta,
        ),
      );
    }
    if (data.containsKey('what_to_avoid_en')) {
      context.handle(
        _whatToAvoidEnMeta,
        whatToAvoidEn.isAcceptableOrUnknown(
          data['what_to_avoid_en']!,
          _whatToAvoidEnMeta,
        ),
      );
    }
    if (data.containsKey('what_to_avoid_si')) {
      context.handle(
        _whatToAvoidSiMeta,
        whatToAvoidSi.isAcceptableOrUnknown(
          data['what_to_avoid_si']!,
          _whatToAvoidSiMeta,
        ),
      );
    }
    if (data.containsKey('what_to_avoid_ta')) {
      context.handle(
        _whatToAvoidTaMeta,
        whatToAvoidTa.isAcceptableOrUnknown(
          data['what_to_avoid_ta']!,
          _whatToAvoidTaMeta,
        ),
      );
    }
    if (data.containsKey('recheck_after_days')) {
      context.handle(
        _recheckAfterDaysMeta,
        recheckAfterDays.isAcceptableOrUnknown(
          data['recheck_after_days']!,
          _recheckAfterDaysMeta,
        ),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TreatmentGuidelineTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TreatmentGuidelineTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diseaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disease_id'],
      )!,
      guidelineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guideline_version'],
      )!,
      summaryEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_en'],
      ),
      summarySi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_si'],
      ),
      summaryTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_ta'],
      ),
      whatToDoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_do_en'],
      ),
      whatToDoSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_do_si'],
      ),
      whatToDoTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_do_ta'],
      ),
      whatToAvoidEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_avoid_en'],
      ),
      whatToAvoidSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_avoid_si'],
      ),
      whatToAvoidTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what_to_avoid_ta'],
      ),
      recheckAfterDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recheck_after_days'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_at'],
      ),
    );
  }

  @override
  $TreatmentGuidelineTableTable createAlias(String alias) {
    return $TreatmentGuidelineTableTable(attachedDatabase, alias);
  }
}

class TreatmentGuidelineTableData extends DataClass
    implements Insertable<TreatmentGuidelineTableData> {
  final String id;
  final String diseaseId;

  /// e.g. 'tg-2026.03'
  final String guidelineVersion;
  final String? summaryEn;
  final String? summarySi;
  final String? summaryTa;
  final String? whatToDoEn;
  final String? whatToDoSi;
  final String? whatToDoTa;
  final String? whatToAvoidEn;
  final String? whatToAvoidSi;
  final String? whatToAvoidTa;
  final int? recheckAfterDays;
  final String? publishedAt;
  const TreatmentGuidelineTableData({
    required this.id,
    required this.diseaseId,
    required this.guidelineVersion,
    this.summaryEn,
    this.summarySi,
    this.summaryTa,
    this.whatToDoEn,
    this.whatToDoSi,
    this.whatToDoTa,
    this.whatToAvoidEn,
    this.whatToAvoidSi,
    this.whatToAvoidTa,
    this.recheckAfterDays,
    this.publishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['disease_id'] = Variable<String>(diseaseId);
    map['guideline_version'] = Variable<String>(guidelineVersion);
    if (!nullToAbsent || summaryEn != null) {
      map['summary_en'] = Variable<String>(summaryEn);
    }
    if (!nullToAbsent || summarySi != null) {
      map['summary_si'] = Variable<String>(summarySi);
    }
    if (!nullToAbsent || summaryTa != null) {
      map['summary_ta'] = Variable<String>(summaryTa);
    }
    if (!nullToAbsent || whatToDoEn != null) {
      map['what_to_do_en'] = Variable<String>(whatToDoEn);
    }
    if (!nullToAbsent || whatToDoSi != null) {
      map['what_to_do_si'] = Variable<String>(whatToDoSi);
    }
    if (!nullToAbsent || whatToDoTa != null) {
      map['what_to_do_ta'] = Variable<String>(whatToDoTa);
    }
    if (!nullToAbsent || whatToAvoidEn != null) {
      map['what_to_avoid_en'] = Variable<String>(whatToAvoidEn);
    }
    if (!nullToAbsent || whatToAvoidSi != null) {
      map['what_to_avoid_si'] = Variable<String>(whatToAvoidSi);
    }
    if (!nullToAbsent || whatToAvoidTa != null) {
      map['what_to_avoid_ta'] = Variable<String>(whatToAvoidTa);
    }
    if (!nullToAbsent || recheckAfterDays != null) {
      map['recheck_after_days'] = Variable<int>(recheckAfterDays);
    }
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<String>(publishedAt);
    }
    return map;
  }

  TreatmentGuidelineTableCompanion toCompanion(bool nullToAbsent) {
    return TreatmentGuidelineTableCompanion(
      id: Value(id),
      diseaseId: Value(diseaseId),
      guidelineVersion: Value(guidelineVersion),
      summaryEn: summaryEn == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryEn),
      summarySi: summarySi == null && nullToAbsent
          ? const Value.absent()
          : Value(summarySi),
      summaryTa: summaryTa == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryTa),
      whatToDoEn: whatToDoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToDoEn),
      whatToDoSi: whatToDoSi == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToDoSi),
      whatToDoTa: whatToDoTa == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToDoTa),
      whatToAvoidEn: whatToAvoidEn == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToAvoidEn),
      whatToAvoidSi: whatToAvoidSi == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToAvoidSi),
      whatToAvoidTa: whatToAvoidTa == null && nullToAbsent
          ? const Value.absent()
          : Value(whatToAvoidTa),
      recheckAfterDays: recheckAfterDays == null && nullToAbsent
          ? const Value.absent()
          : Value(recheckAfterDays),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory TreatmentGuidelineTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TreatmentGuidelineTableData(
      id: serializer.fromJson<String>(json['id']),
      diseaseId: serializer.fromJson<String>(json['diseaseId']),
      guidelineVersion: serializer.fromJson<String>(json['guidelineVersion']),
      summaryEn: serializer.fromJson<String?>(json['summaryEn']),
      summarySi: serializer.fromJson<String?>(json['summarySi']),
      summaryTa: serializer.fromJson<String?>(json['summaryTa']),
      whatToDoEn: serializer.fromJson<String?>(json['whatToDoEn']),
      whatToDoSi: serializer.fromJson<String?>(json['whatToDoSi']),
      whatToDoTa: serializer.fromJson<String?>(json['whatToDoTa']),
      whatToAvoidEn: serializer.fromJson<String?>(json['whatToAvoidEn']),
      whatToAvoidSi: serializer.fromJson<String?>(json['whatToAvoidSi']),
      whatToAvoidTa: serializer.fromJson<String?>(json['whatToAvoidTa']),
      recheckAfterDays: serializer.fromJson<int?>(json['recheckAfterDays']),
      publishedAt: serializer.fromJson<String?>(json['publishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diseaseId': serializer.toJson<String>(diseaseId),
      'guidelineVersion': serializer.toJson<String>(guidelineVersion),
      'summaryEn': serializer.toJson<String?>(summaryEn),
      'summarySi': serializer.toJson<String?>(summarySi),
      'summaryTa': serializer.toJson<String?>(summaryTa),
      'whatToDoEn': serializer.toJson<String?>(whatToDoEn),
      'whatToDoSi': serializer.toJson<String?>(whatToDoSi),
      'whatToDoTa': serializer.toJson<String?>(whatToDoTa),
      'whatToAvoidEn': serializer.toJson<String?>(whatToAvoidEn),
      'whatToAvoidSi': serializer.toJson<String?>(whatToAvoidSi),
      'whatToAvoidTa': serializer.toJson<String?>(whatToAvoidTa),
      'recheckAfterDays': serializer.toJson<int?>(recheckAfterDays),
      'publishedAt': serializer.toJson<String?>(publishedAt),
    };
  }

  TreatmentGuidelineTableData copyWith({
    String? id,
    String? diseaseId,
    String? guidelineVersion,
    Value<String?> summaryEn = const Value.absent(),
    Value<String?> summarySi = const Value.absent(),
    Value<String?> summaryTa = const Value.absent(),
    Value<String?> whatToDoEn = const Value.absent(),
    Value<String?> whatToDoSi = const Value.absent(),
    Value<String?> whatToDoTa = const Value.absent(),
    Value<String?> whatToAvoidEn = const Value.absent(),
    Value<String?> whatToAvoidSi = const Value.absent(),
    Value<String?> whatToAvoidTa = const Value.absent(),
    Value<int?> recheckAfterDays = const Value.absent(),
    Value<String?> publishedAt = const Value.absent(),
  }) => TreatmentGuidelineTableData(
    id: id ?? this.id,
    diseaseId: diseaseId ?? this.diseaseId,
    guidelineVersion: guidelineVersion ?? this.guidelineVersion,
    summaryEn: summaryEn.present ? summaryEn.value : this.summaryEn,
    summarySi: summarySi.present ? summarySi.value : this.summarySi,
    summaryTa: summaryTa.present ? summaryTa.value : this.summaryTa,
    whatToDoEn: whatToDoEn.present ? whatToDoEn.value : this.whatToDoEn,
    whatToDoSi: whatToDoSi.present ? whatToDoSi.value : this.whatToDoSi,
    whatToDoTa: whatToDoTa.present ? whatToDoTa.value : this.whatToDoTa,
    whatToAvoidEn: whatToAvoidEn.present
        ? whatToAvoidEn.value
        : this.whatToAvoidEn,
    whatToAvoidSi: whatToAvoidSi.present
        ? whatToAvoidSi.value
        : this.whatToAvoidSi,
    whatToAvoidTa: whatToAvoidTa.present
        ? whatToAvoidTa.value
        : this.whatToAvoidTa,
    recheckAfterDays: recheckAfterDays.present
        ? recheckAfterDays.value
        : this.recheckAfterDays,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
  );
  TreatmentGuidelineTableData copyWithCompanion(
    TreatmentGuidelineTableCompanion data,
  ) {
    return TreatmentGuidelineTableData(
      id: data.id.present ? data.id.value : this.id,
      diseaseId: data.diseaseId.present ? data.diseaseId.value : this.diseaseId,
      guidelineVersion: data.guidelineVersion.present
          ? data.guidelineVersion.value
          : this.guidelineVersion,
      summaryEn: data.summaryEn.present ? data.summaryEn.value : this.summaryEn,
      summarySi: data.summarySi.present ? data.summarySi.value : this.summarySi,
      summaryTa: data.summaryTa.present ? data.summaryTa.value : this.summaryTa,
      whatToDoEn: data.whatToDoEn.present
          ? data.whatToDoEn.value
          : this.whatToDoEn,
      whatToDoSi: data.whatToDoSi.present
          ? data.whatToDoSi.value
          : this.whatToDoSi,
      whatToDoTa: data.whatToDoTa.present
          ? data.whatToDoTa.value
          : this.whatToDoTa,
      whatToAvoidEn: data.whatToAvoidEn.present
          ? data.whatToAvoidEn.value
          : this.whatToAvoidEn,
      whatToAvoidSi: data.whatToAvoidSi.present
          ? data.whatToAvoidSi.value
          : this.whatToAvoidSi,
      whatToAvoidTa: data.whatToAvoidTa.present
          ? data.whatToAvoidTa.value
          : this.whatToAvoidTa,
      recheckAfterDays: data.recheckAfterDays.present
          ? data.recheckAfterDays.value
          : this.recheckAfterDays,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentGuidelineTableData(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('guidelineVersion: $guidelineVersion, ')
          ..write('summaryEn: $summaryEn, ')
          ..write('summarySi: $summarySi, ')
          ..write('summaryTa: $summaryTa, ')
          ..write('whatToDoEn: $whatToDoEn, ')
          ..write('whatToDoSi: $whatToDoSi, ')
          ..write('whatToDoTa: $whatToDoTa, ')
          ..write('whatToAvoidEn: $whatToAvoidEn, ')
          ..write('whatToAvoidSi: $whatToAvoidSi, ')
          ..write('whatToAvoidTa: $whatToAvoidTa, ')
          ..write('recheckAfterDays: $recheckAfterDays, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diseaseId,
    guidelineVersion,
    summaryEn,
    summarySi,
    summaryTa,
    whatToDoEn,
    whatToDoSi,
    whatToDoTa,
    whatToAvoidEn,
    whatToAvoidSi,
    whatToAvoidTa,
    recheckAfterDays,
    publishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreatmentGuidelineTableData &&
          other.id == this.id &&
          other.diseaseId == this.diseaseId &&
          other.guidelineVersion == this.guidelineVersion &&
          other.summaryEn == this.summaryEn &&
          other.summarySi == this.summarySi &&
          other.summaryTa == this.summaryTa &&
          other.whatToDoEn == this.whatToDoEn &&
          other.whatToDoSi == this.whatToDoSi &&
          other.whatToDoTa == this.whatToDoTa &&
          other.whatToAvoidEn == this.whatToAvoidEn &&
          other.whatToAvoidSi == this.whatToAvoidSi &&
          other.whatToAvoidTa == this.whatToAvoidTa &&
          other.recheckAfterDays == this.recheckAfterDays &&
          other.publishedAt == this.publishedAt);
}

class TreatmentGuidelineTableCompanion
    extends UpdateCompanion<TreatmentGuidelineTableData> {
  final Value<String> id;
  final Value<String> diseaseId;
  final Value<String> guidelineVersion;
  final Value<String?> summaryEn;
  final Value<String?> summarySi;
  final Value<String?> summaryTa;
  final Value<String?> whatToDoEn;
  final Value<String?> whatToDoSi;
  final Value<String?> whatToDoTa;
  final Value<String?> whatToAvoidEn;
  final Value<String?> whatToAvoidSi;
  final Value<String?> whatToAvoidTa;
  final Value<int?> recheckAfterDays;
  final Value<String?> publishedAt;
  final Value<int> rowid;
  const TreatmentGuidelineTableCompanion({
    this.id = const Value.absent(),
    this.diseaseId = const Value.absent(),
    this.guidelineVersion = const Value.absent(),
    this.summaryEn = const Value.absent(),
    this.summarySi = const Value.absent(),
    this.summaryTa = const Value.absent(),
    this.whatToDoEn = const Value.absent(),
    this.whatToDoSi = const Value.absent(),
    this.whatToDoTa = const Value.absent(),
    this.whatToAvoidEn = const Value.absent(),
    this.whatToAvoidSi = const Value.absent(),
    this.whatToAvoidTa = const Value.absent(),
    this.recheckAfterDays = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TreatmentGuidelineTableCompanion.insert({
    required String id,
    required String diseaseId,
    required String guidelineVersion,
    this.summaryEn = const Value.absent(),
    this.summarySi = const Value.absent(),
    this.summaryTa = const Value.absent(),
    this.whatToDoEn = const Value.absent(),
    this.whatToDoSi = const Value.absent(),
    this.whatToDoTa = const Value.absent(),
    this.whatToAvoidEn = const Value.absent(),
    this.whatToAvoidSi = const Value.absent(),
    this.whatToAvoidTa = const Value.absent(),
    this.recheckAfterDays = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diseaseId = Value(diseaseId),
       guidelineVersion = Value(guidelineVersion);
  static Insertable<TreatmentGuidelineTableData> custom({
    Expression<String>? id,
    Expression<String>? diseaseId,
    Expression<String>? guidelineVersion,
    Expression<String>? summaryEn,
    Expression<String>? summarySi,
    Expression<String>? summaryTa,
    Expression<String>? whatToDoEn,
    Expression<String>? whatToDoSi,
    Expression<String>? whatToDoTa,
    Expression<String>? whatToAvoidEn,
    Expression<String>? whatToAvoidSi,
    Expression<String>? whatToAvoidTa,
    Expression<int>? recheckAfterDays,
    Expression<String>? publishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diseaseId != null) 'disease_id': diseaseId,
      if (guidelineVersion != null) 'guideline_version': guidelineVersion,
      if (summaryEn != null) 'summary_en': summaryEn,
      if (summarySi != null) 'summary_si': summarySi,
      if (summaryTa != null) 'summary_ta': summaryTa,
      if (whatToDoEn != null) 'what_to_do_en': whatToDoEn,
      if (whatToDoSi != null) 'what_to_do_si': whatToDoSi,
      if (whatToDoTa != null) 'what_to_do_ta': whatToDoTa,
      if (whatToAvoidEn != null) 'what_to_avoid_en': whatToAvoidEn,
      if (whatToAvoidSi != null) 'what_to_avoid_si': whatToAvoidSi,
      if (whatToAvoidTa != null) 'what_to_avoid_ta': whatToAvoidTa,
      if (recheckAfterDays != null) 'recheck_after_days': recheckAfterDays,
      if (publishedAt != null) 'published_at': publishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TreatmentGuidelineTableCompanion copyWith({
    Value<String>? id,
    Value<String>? diseaseId,
    Value<String>? guidelineVersion,
    Value<String?>? summaryEn,
    Value<String?>? summarySi,
    Value<String?>? summaryTa,
    Value<String?>? whatToDoEn,
    Value<String?>? whatToDoSi,
    Value<String?>? whatToDoTa,
    Value<String?>? whatToAvoidEn,
    Value<String?>? whatToAvoidSi,
    Value<String?>? whatToAvoidTa,
    Value<int?>? recheckAfterDays,
    Value<String?>? publishedAt,
    Value<int>? rowid,
  }) {
    return TreatmentGuidelineTableCompanion(
      id: id ?? this.id,
      diseaseId: diseaseId ?? this.diseaseId,
      guidelineVersion: guidelineVersion ?? this.guidelineVersion,
      summaryEn: summaryEn ?? this.summaryEn,
      summarySi: summarySi ?? this.summarySi,
      summaryTa: summaryTa ?? this.summaryTa,
      whatToDoEn: whatToDoEn ?? this.whatToDoEn,
      whatToDoSi: whatToDoSi ?? this.whatToDoSi,
      whatToDoTa: whatToDoTa ?? this.whatToDoTa,
      whatToAvoidEn: whatToAvoidEn ?? this.whatToAvoidEn,
      whatToAvoidSi: whatToAvoidSi ?? this.whatToAvoidSi,
      whatToAvoidTa: whatToAvoidTa ?? this.whatToAvoidTa,
      recheckAfterDays: recheckAfterDays ?? this.recheckAfterDays,
      publishedAt: publishedAt ?? this.publishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diseaseId.present) {
      map['disease_id'] = Variable<String>(diseaseId.value);
    }
    if (guidelineVersion.present) {
      map['guideline_version'] = Variable<String>(guidelineVersion.value);
    }
    if (summaryEn.present) {
      map['summary_en'] = Variable<String>(summaryEn.value);
    }
    if (summarySi.present) {
      map['summary_si'] = Variable<String>(summarySi.value);
    }
    if (summaryTa.present) {
      map['summary_ta'] = Variable<String>(summaryTa.value);
    }
    if (whatToDoEn.present) {
      map['what_to_do_en'] = Variable<String>(whatToDoEn.value);
    }
    if (whatToDoSi.present) {
      map['what_to_do_si'] = Variable<String>(whatToDoSi.value);
    }
    if (whatToDoTa.present) {
      map['what_to_do_ta'] = Variable<String>(whatToDoTa.value);
    }
    if (whatToAvoidEn.present) {
      map['what_to_avoid_en'] = Variable<String>(whatToAvoidEn.value);
    }
    if (whatToAvoidSi.present) {
      map['what_to_avoid_si'] = Variable<String>(whatToAvoidSi.value);
    }
    if (whatToAvoidTa.present) {
      map['what_to_avoid_ta'] = Variable<String>(whatToAvoidTa.value);
    }
    if (recheckAfterDays.present) {
      map['recheck_after_days'] = Variable<int>(recheckAfterDays.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<String>(publishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreatmentGuidelineTableCompanion(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('guidelineVersion: $guidelineVersion, ')
          ..write('summaryEn: $summaryEn, ')
          ..write('summarySi: $summarySi, ')
          ..write('summaryTa: $summaryTa, ')
          ..write('whatToDoEn: $whatToDoEn, ')
          ..write('whatToDoSi: $whatToDoSi, ')
          ..write('whatToDoTa: $whatToDoTa, ')
          ..write('whatToAvoidEn: $whatToAvoidEn, ')
          ..write('whatToAvoidSi: $whatToAvoidSi, ')
          ..write('whatToAvoidTa: $whatToAvoidTa, ')
          ..write('recheckAfterDays: $recheckAfterDays, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModelVersionTableTable extends ModelVersionTable
    with TableInfo<$ModelVersionTableTable, ModelVersionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModelVersionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releasedAtMeta = const VerificationMeta(
    'releasedAt',
  );
  @override
  late final GeneratedColumn<String> releasedAt = GeneratedColumn<String>(
    'released_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, releasedAt, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'model_version';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModelVersionTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('released_at')) {
      context.handle(
        _releasedAtMeta,
        releasedAt.isAcceptableOrUnknown(data['released_at']!, _releasedAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModelVersionTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModelVersionTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      releasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}released_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $ModelVersionTableTable createAlias(String alias) {
    return $ModelVersionTableTable(attachedDatabase, alias);
  }
}

class ModelVersionTableData extends DataClass
    implements Insertable<ModelVersionTableData> {
  /// e.g. 'cropcare-v1.0'
  final String id;
  final String? releasedAt;
  final int isActive;
  const ModelVersionTableData({
    required this.id,
    this.releasedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || releasedAt != null) {
      map['released_at'] = Variable<String>(releasedAt);
    }
    map['is_active'] = Variable<int>(isActive);
    return map;
  }

  ModelVersionTableCompanion toCompanion(bool nullToAbsent) {
    return ModelVersionTableCompanion(
      id: Value(id),
      releasedAt: releasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(releasedAt),
      isActive: Value(isActive),
    );
  }

  factory ModelVersionTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModelVersionTableData(
      id: serializer.fromJson<String>(json['id']),
      releasedAt: serializer.fromJson<String?>(json['releasedAt']),
      isActive: serializer.fromJson<int>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'releasedAt': serializer.toJson<String?>(releasedAt),
      'isActive': serializer.toJson<int>(isActive),
    };
  }

  ModelVersionTableData copyWith({
    String? id,
    Value<String?> releasedAt = const Value.absent(),
    int? isActive,
  }) => ModelVersionTableData(
    id: id ?? this.id,
    releasedAt: releasedAt.present ? releasedAt.value : this.releasedAt,
    isActive: isActive ?? this.isActive,
  );
  ModelVersionTableData copyWithCompanion(ModelVersionTableCompanion data) {
    return ModelVersionTableData(
      id: data.id.present ? data.id.value : this.id,
      releasedAt: data.releasedAt.present
          ? data.releasedAt.value
          : this.releasedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModelVersionTableData(')
          ..write('id: $id, ')
          ..write('releasedAt: $releasedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, releasedAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModelVersionTableData &&
          other.id == this.id &&
          other.releasedAt == this.releasedAt &&
          other.isActive == this.isActive);
}

class ModelVersionTableCompanion
    extends UpdateCompanion<ModelVersionTableData> {
  final Value<String> id;
  final Value<String?> releasedAt;
  final Value<int> isActive;
  final Value<int> rowid;
  const ModelVersionTableCompanion({
    this.id = const Value.absent(),
    this.releasedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModelVersionTableCompanion.insert({
    required String id,
    this.releasedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ModelVersionTableData> custom({
    Expression<String>? id,
    Expression<String>? releasedAt,
    Expression<int>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (releasedAt != null) 'released_at': releasedAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModelVersionTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? releasedAt,
    Value<int>? isActive,
    Value<int>? rowid,
  }) {
    return ModelVersionTableCompanion(
      id: id ?? this.id,
      releasedAt: releasedAt ?? this.releasedAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (releasedAt.present) {
      map['released_at'] = Variable<String>(releasedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModelVersionTableCompanion(')
          ..write('id: $id, ')
          ..write('releasedAt: $releasedAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanTableTable extends ScanTable
    with TableInfo<$ScanTableTable, ScanTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteScanIdMeta = const VerificationMeta(
    'remoteScanId',
  );
  @override
  late final GeneratedColumn<String> remoteScanId = GeneratedColumn<String>(
    'remote_scan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_user (id)',
    ),
  );
  static const VerificationMeta _cropIdMeta = const VerificationMeta('cropId');
  @override
  late final GeneratedColumn<String> cropId = GeneratedColumn<String>(
    'crop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES crop (id)',
    ),
  );
  static const VerificationMeta _imageLocalPathMeta = const VerificationMeta(
    'imageLocalPath',
  );
  @override
  late final GeneratedColumn<String> imageLocalPath = GeneratedColumn<String>(
    'image_local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageRemoteUrlMeta = const VerificationMeta(
    'imageRemoteUrl',
  );
  @override
  late final GeneratedColumn<String> imageRemoteUrl = GeneratedColumn<String>(
    'image_remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<String> capturedAt = GeneratedColumn<String>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteScanId,
    userId,
    cropId,
    imageLocalPath,
    imageRemoteUrl,
    status,
    capturedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remote_scan_id')) {
      context.handle(
        _remoteScanIdMeta,
        remoteScanId.isAcceptableOrUnknown(
          data['remote_scan_id']!,
          _remoteScanIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('crop_id')) {
      context.handle(
        _cropIdMeta,
        cropId.isAcceptableOrUnknown(data['crop_id']!, _cropIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cropIdMeta);
    }
    if (data.containsKey('image_local_path')) {
      context.handle(
        _imageLocalPathMeta,
        imageLocalPath.isAcceptableOrUnknown(
          data['image_local_path']!,
          _imageLocalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_imageLocalPathMeta);
    }
    if (data.containsKey('image_remote_url')) {
      context.handle(
        _imageRemoteUrlMeta,
        imageRemoteUrl.isAcceptableOrUnknown(
          data['image_remote_url']!,
          _imageRemoteUrlMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      remoteScanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_scan_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cropId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_id'],
      )!,
      imageLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_local_path'],
      )!,
      imageRemoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_remote_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}captured_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ScanTableTable createAlias(String alias) {
    return $ScanTableTable(attachedDatabase, alias);
  }
}

class ScanTableData extends DataClass implements Insertable<ScanTableData> {
  /// Local UUID; becomes scan_id on server.
  final String id;
  final String? remoteScanId;
  final String userId;
  final String cropId;
  final String imageLocalPath;

  /// Populated after image sync.
  final String? imageRemoteUrl;

  /// Lifecycle state — app-layer enforcement only (see schema spec).
  /// 'CREATED'|'VALIDATING'|'ANALYZING'|'DIAGNOSED'|'COMPLETED'|
  /// 'ESCALATED'|'SHARED'|'RESOLVED'|'USER_CANCELLED'|
  /// 'INVALID_IMAGE'|'ANALYSIS_FAILED'
  final String status;
  final String capturedAt;
  final String createdAt;
  final String updatedAt;
  const ScanTableData({
    required this.id,
    this.remoteScanId,
    required this.userId,
    required this.cropId,
    required this.imageLocalPath,
    this.imageRemoteUrl,
    required this.status,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || remoteScanId != null) {
      map['remote_scan_id'] = Variable<String>(remoteScanId);
    }
    map['user_id'] = Variable<String>(userId);
    map['crop_id'] = Variable<String>(cropId);
    map['image_local_path'] = Variable<String>(imageLocalPath);
    if (!nullToAbsent || imageRemoteUrl != null) {
      map['image_remote_url'] = Variable<String>(imageRemoteUrl);
    }
    map['status'] = Variable<String>(status);
    map['captured_at'] = Variable<String>(capturedAt);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ScanTableCompanion toCompanion(bool nullToAbsent) {
    return ScanTableCompanion(
      id: Value(id),
      remoteScanId: remoteScanId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteScanId),
      userId: Value(userId),
      cropId: Value(cropId),
      imageLocalPath: Value(imageLocalPath),
      imageRemoteUrl: imageRemoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageRemoteUrl),
      status: Value(status),
      capturedAt: Value(capturedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScanTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanTableData(
      id: serializer.fromJson<String>(json['id']),
      remoteScanId: serializer.fromJson<String?>(json['remoteScanId']),
      userId: serializer.fromJson<String>(json['userId']),
      cropId: serializer.fromJson<String>(json['cropId']),
      imageLocalPath: serializer.fromJson<String>(json['imageLocalPath']),
      imageRemoteUrl: serializer.fromJson<String?>(json['imageRemoteUrl']),
      status: serializer.fromJson<String>(json['status']),
      capturedAt: serializer.fromJson<String>(json['capturedAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remoteScanId': serializer.toJson<String?>(remoteScanId),
      'userId': serializer.toJson<String>(userId),
      'cropId': serializer.toJson<String>(cropId),
      'imageLocalPath': serializer.toJson<String>(imageLocalPath),
      'imageRemoteUrl': serializer.toJson<String?>(imageRemoteUrl),
      'status': serializer.toJson<String>(status),
      'capturedAt': serializer.toJson<String>(capturedAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  ScanTableData copyWith({
    String? id,
    Value<String?> remoteScanId = const Value.absent(),
    String? userId,
    String? cropId,
    String? imageLocalPath,
    Value<String?> imageRemoteUrl = const Value.absent(),
    String? status,
    String? capturedAt,
    String? createdAt,
    String? updatedAt,
  }) => ScanTableData(
    id: id ?? this.id,
    remoteScanId: remoteScanId.present ? remoteScanId.value : this.remoteScanId,
    userId: userId ?? this.userId,
    cropId: cropId ?? this.cropId,
    imageLocalPath: imageLocalPath ?? this.imageLocalPath,
    imageRemoteUrl: imageRemoteUrl.present
        ? imageRemoteUrl.value
        : this.imageRemoteUrl,
    status: status ?? this.status,
    capturedAt: capturedAt ?? this.capturedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScanTableData copyWithCompanion(ScanTableCompanion data) {
    return ScanTableData(
      id: data.id.present ? data.id.value : this.id,
      remoteScanId: data.remoteScanId.present
          ? data.remoteScanId.value
          : this.remoteScanId,
      userId: data.userId.present ? data.userId.value : this.userId,
      cropId: data.cropId.present ? data.cropId.value : this.cropId,
      imageLocalPath: data.imageLocalPath.present
          ? data.imageLocalPath.value
          : this.imageLocalPath,
      imageRemoteUrl: data.imageRemoteUrl.present
          ? data.imageRemoteUrl.value
          : this.imageRemoteUrl,
      status: data.status.present ? data.status.value : this.status,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanTableData(')
          ..write('id: $id, ')
          ..write('remoteScanId: $remoteScanId, ')
          ..write('userId: $userId, ')
          ..write('cropId: $cropId, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageRemoteUrl: $imageRemoteUrl, ')
          ..write('status: $status, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteScanId,
    userId,
    cropId,
    imageLocalPath,
    imageRemoteUrl,
    status,
    capturedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanTableData &&
          other.id == this.id &&
          other.remoteScanId == this.remoteScanId &&
          other.userId == this.userId &&
          other.cropId == this.cropId &&
          other.imageLocalPath == this.imageLocalPath &&
          other.imageRemoteUrl == this.imageRemoteUrl &&
          other.status == this.status &&
          other.capturedAt == this.capturedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScanTableCompanion extends UpdateCompanion<ScanTableData> {
  final Value<String> id;
  final Value<String?> remoteScanId;
  final Value<String> userId;
  final Value<String> cropId;
  final Value<String> imageLocalPath;
  final Value<String?> imageRemoteUrl;
  final Value<String> status;
  final Value<String> capturedAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ScanTableCompanion({
    this.id = const Value.absent(),
    this.remoteScanId = const Value.absent(),
    this.userId = const Value.absent(),
    this.cropId = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.imageRemoteUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanTableCompanion.insert({
    required String id,
    this.remoteScanId = const Value.absent(),
    required String userId,
    required String cropId,
    required String imageLocalPath,
    this.imageRemoteUrl = const Value.absent(),
    required String status,
    required String capturedAt,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       cropId = Value(cropId),
       imageLocalPath = Value(imageLocalPath),
       status = Value(status),
       capturedAt = Value(capturedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ScanTableData> custom({
    Expression<String>? id,
    Expression<String>? remoteScanId,
    Expression<String>? userId,
    Expression<String>? cropId,
    Expression<String>? imageLocalPath,
    Expression<String>? imageRemoteUrl,
    Expression<String>? status,
    Expression<String>? capturedAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteScanId != null) 'remote_scan_id': remoteScanId,
      if (userId != null) 'user_id': userId,
      if (cropId != null) 'crop_id': cropId,
      if (imageLocalPath != null) 'image_local_path': imageLocalPath,
      if (imageRemoteUrl != null) 'image_remote_url': imageRemoteUrl,
      if (status != null) 'status': status,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? remoteScanId,
    Value<String>? userId,
    Value<String>? cropId,
    Value<String>? imageLocalPath,
    Value<String?>? imageRemoteUrl,
    Value<String>? status,
    Value<String>? capturedAt,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScanTableCompanion(
      id: id ?? this.id,
      remoteScanId: remoteScanId ?? this.remoteScanId,
      userId: userId ?? this.userId,
      cropId: cropId ?? this.cropId,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageRemoteUrl: imageRemoteUrl ?? this.imageRemoteUrl,
      status: status ?? this.status,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remoteScanId.present) {
      map['remote_scan_id'] = Variable<String>(remoteScanId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cropId.present) {
      map['crop_id'] = Variable<String>(cropId.value);
    }
    if (imageLocalPath.present) {
      map['image_local_path'] = Variable<String>(imageLocalPath.value);
    }
    if (imageRemoteUrl.present) {
      map['image_remote_url'] = Variable<String>(imageRemoteUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<String>(capturedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteScanId: $remoteScanId, ')
          ..write('userId: $userId, ')
          ..write('cropId: $cropId, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageRemoteUrl: $imageRemoteUrl, ')
          ..write('status: $status, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageValidationTableTable extends ImageValidationTable
    with TableInfo<$ImageValidationTableTable, ImageValidationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageValidationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _isUsableMeta = const VerificationMeta(
    'isUsable',
  );
  @override
  late final GeneratedColumn<int> isUsable = GeneratedColumn<int>(
    'is_usable',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectionReasonMeta = const VerificationMeta(
    'rejectionReason',
  );
  @override
  late final GeneratedColumn<String> rejectionReason = GeneratedColumn<String>(
    'rejection_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<String> checkedAt = GeneratedColumn<String>(
    'checked_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    isUsable,
    rejectionReason,
    checkedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_validation';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageValidationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('is_usable')) {
      context.handle(
        _isUsableMeta,
        isUsable.isAcceptableOrUnknown(data['is_usable']!, _isUsableMeta),
      );
    } else if (isInserting) {
      context.missing(_isUsableMeta);
    }
    if (data.containsKey('rejection_reason')) {
      context.handle(
        _rejectionReasonMeta,
        rejectionReason.isAcceptableOrUnknown(
          data['rejection_reason']!,
          _rejectionReasonMeta,
        ),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageValidationTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageValidationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      isUsable: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_usable'],
      )!,
      rejectionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejection_reason'],
      ),
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checked_at'],
      )!,
    );
  }

  @override
  $ImageValidationTableTable createAlias(String alias) {
    return $ImageValidationTableTable(attachedDatabase, alias);
  }
}

class ImageValidationTableData extends DataClass
    implements Insertable<ImageValidationTableData> {
  final String id;
  final String scanId;
  final int isUsable;

  /// 'BLURRY'|'TOO_DARK'|'TOO_BRIGHT'|'LOW_RESOLUTION'|
  /// 'NO_PLANT_DETECTED'|'UNSUPPORTED_FORMAT' — nullable
  final String? rejectionReason;
  final String checkedAt;
  const ImageValidationTableData({
    required this.id,
    required this.scanId,
    required this.isUsable,
    this.rejectionReason,
    required this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scan_id'] = Variable<String>(scanId);
    map['is_usable'] = Variable<int>(isUsable);
    if (!nullToAbsent || rejectionReason != null) {
      map['rejection_reason'] = Variable<String>(rejectionReason);
    }
    map['checked_at'] = Variable<String>(checkedAt);
    return map;
  }

  ImageValidationTableCompanion toCompanion(bool nullToAbsent) {
    return ImageValidationTableCompanion(
      id: Value(id),
      scanId: Value(scanId),
      isUsable: Value(isUsable),
      rejectionReason: rejectionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionReason),
      checkedAt: Value(checkedAt),
    );
  }

  factory ImageValidationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageValidationTableData(
      id: serializer.fromJson<String>(json['id']),
      scanId: serializer.fromJson<String>(json['scanId']),
      isUsable: serializer.fromJson<int>(json['isUsable']),
      rejectionReason: serializer.fromJson<String?>(json['rejectionReason']),
      checkedAt: serializer.fromJson<String>(json['checkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scanId': serializer.toJson<String>(scanId),
      'isUsable': serializer.toJson<int>(isUsable),
      'rejectionReason': serializer.toJson<String?>(rejectionReason),
      'checkedAt': serializer.toJson<String>(checkedAt),
    };
  }

  ImageValidationTableData copyWith({
    String? id,
    String? scanId,
    int? isUsable,
    Value<String?> rejectionReason = const Value.absent(),
    String? checkedAt,
  }) => ImageValidationTableData(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    isUsable: isUsable ?? this.isUsable,
    rejectionReason: rejectionReason.present
        ? rejectionReason.value
        : this.rejectionReason,
    checkedAt: checkedAt ?? this.checkedAt,
  );
  ImageValidationTableData copyWithCompanion(
    ImageValidationTableCompanion data,
  ) {
    return ImageValidationTableData(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      isUsable: data.isUsable.present ? data.isUsable.value : this.isUsable,
      rejectionReason: data.rejectionReason.present
          ? data.rejectionReason.value
          : this.rejectionReason,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageValidationTableData(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('isUsable: $isUsable, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scanId, isUsable, rejectionReason, checkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageValidationTableData &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.isUsable == this.isUsable &&
          other.rejectionReason == this.rejectionReason &&
          other.checkedAt == this.checkedAt);
}

class ImageValidationTableCompanion
    extends UpdateCompanion<ImageValidationTableData> {
  final Value<String> id;
  final Value<String> scanId;
  final Value<int> isUsable;
  final Value<String?> rejectionReason;
  final Value<String> checkedAt;
  final Value<int> rowid;
  const ImageValidationTableCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.isUsable = const Value.absent(),
    this.rejectionReason = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageValidationTableCompanion.insert({
    required String id,
    required String scanId,
    required int isUsable,
    this.rejectionReason = const Value.absent(),
    required String checkedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scanId = Value(scanId),
       isUsable = Value(isUsable),
       checkedAt = Value(checkedAt);
  static Insertable<ImageValidationTableData> custom({
    Expression<String>? id,
    Expression<String>? scanId,
    Expression<int>? isUsable,
    Expression<String>? rejectionReason,
    Expression<String>? checkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (isUsable != null) 'is_usable': isUsable,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageValidationTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scanId,
    Value<int>? isUsable,
    Value<String?>? rejectionReason,
    Value<String>? checkedAt,
    Value<int>? rowid,
  }) {
    return ImageValidationTableCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      isUsable: isUsable ?? this.isUsable,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      checkedAt: checkedAt ?? this.checkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (isUsable.present) {
      map['is_usable'] = Variable<int>(isUsable.value);
    }
    if (rejectionReason.present) {
      map['rejection_reason'] = Variable<String>(rejectionReason.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<String>(checkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageValidationTableCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('isUsable: $isUsable, ')
          ..write('rejectionReason: $rejectionReason, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiagnosisTableTable extends DiagnosisTable
    with TableInfo<$DiagnosisTableTable, DiagnosisTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiagnosisTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _diseaseIdMeta = const VerificationMeta(
    'diseaseId',
  );
  @override
  late final GeneratedColumn<String> diseaseId = GeneratedColumn<String>(
    'disease_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disease (id)',
    ),
  );
  static const VerificationMeta _modelVersionIdMeta = const VerificationMeta(
    'modelVersionId',
  );
  @override
  late final GeneratedColumn<String> modelVersionId = GeneratedColumn<String>(
    'model_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES model_version (id)',
    ),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultStateMeta = const VerificationMeta(
    'resultState',
  );
  @override
  late final GeneratedColumn<String> resultState = GeneratedColumn<String>(
    'result_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alternativesJsonMeta = const VerificationMeta(
    'alternativesJson',
  );
  @override
  late final GeneratedColumn<String> alternativesJson = GeneratedColumn<String>(
    'alternatives_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _treatmentSourceMeta = const VerificationMeta(
    'treatmentSource',
  );
  @override
  late final GeneratedColumn<String> treatmentSource = GeneratedColumn<String>(
    'treatment_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _treatmentGuidelineIdMeta =
      const VerificationMeta('treatmentGuidelineId');
  @override
  late final GeneratedColumn<String> treatmentGuidelineId =
      GeneratedColumn<String>(
        'treatment_guideline_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES treatment_guideline (id)',
        ),
      );
  static const VerificationMeta _llmInterpretationIdMeta =
      const VerificationMeta('llmInterpretationId');
  @override
  late final GeneratedColumn<String> llmInterpretationId =
      GeneratedColumn<String>(
        'llm_interpretation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _aiTreatmentJsonMeta = const VerificationMeta(
    'aiTreatmentJson',
  );
  @override
  late final GeneratedColumn<String> aiTreatmentJson = GeneratedColumn<String>(
    'ai_treatment_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiTreatmentFetchedAtMeta =
      const VerificationMeta('aiTreatmentFetchedAt');
  @override
  late final GeneratedColumn<String> aiTreatmentFetchedAt =
      GeneratedColumn<String>(
        'ai_treatment_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inferredAtMeta = const VerificationMeta(
    'inferredAt',
  );
  @override
  late final GeneratedColumn<String> inferredAt = GeneratedColumn<String>(
    'inferred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    diseaseId,
    modelVersionId,
    confidence,
    resultState,
    severity,
    alternativesJson,
    treatmentSource,
    treatmentGuidelineId,
    llmInterpretationId,
    aiTreatmentJson,
    aiTreatmentFetchedAt,
    inferredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diagnosis';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiagnosisTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('disease_id')) {
      context.handle(
        _diseaseIdMeta,
        diseaseId.isAcceptableOrUnknown(data['disease_id']!, _diseaseIdMeta),
      );
    }
    if (data.containsKey('model_version_id')) {
      context.handle(
        _modelVersionIdMeta,
        modelVersionId.isAcceptableOrUnknown(
          data['model_version_id']!,
          _modelVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionIdMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('result_state')) {
      context.handle(
        _resultStateMeta,
        resultState.isAcceptableOrUnknown(
          data['result_state']!,
          _resultStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultStateMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('alternatives_json')) {
      context.handle(
        _alternativesJsonMeta,
        alternativesJson.isAcceptableOrUnknown(
          data['alternatives_json']!,
          _alternativesJsonMeta,
        ),
      );
    }
    if (data.containsKey('treatment_source')) {
      context.handle(
        _treatmentSourceMeta,
        treatmentSource.isAcceptableOrUnknown(
          data['treatment_source']!,
          _treatmentSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_treatmentSourceMeta);
    }
    if (data.containsKey('treatment_guideline_id')) {
      context.handle(
        _treatmentGuidelineIdMeta,
        treatmentGuidelineId.isAcceptableOrUnknown(
          data['treatment_guideline_id']!,
          _treatmentGuidelineIdMeta,
        ),
      );
    }
    if (data.containsKey('llm_interpretation_id')) {
      context.handle(
        _llmInterpretationIdMeta,
        llmInterpretationId.isAcceptableOrUnknown(
          data['llm_interpretation_id']!,
          _llmInterpretationIdMeta,
        ),
      );
    }
    if (data.containsKey('ai_treatment_json')) {
      context.handle(
        _aiTreatmentJsonMeta,
        aiTreatmentJson.isAcceptableOrUnknown(
          data['ai_treatment_json']!,
          _aiTreatmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('ai_treatment_fetched_at')) {
      context.handle(
        _aiTreatmentFetchedAtMeta,
        aiTreatmentFetchedAt.isAcceptableOrUnknown(
          data['ai_treatment_fetched_at']!,
          _aiTreatmentFetchedAtMeta,
        ),
      );
    }
    if (data.containsKey('inferred_at')) {
      context.handle(
        _inferredAtMeta,
        inferredAt.isAcceptableOrUnknown(data['inferred_at']!, _inferredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_inferredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiagnosisTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiagnosisTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      diseaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disease_id'],
      ),
      modelVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version_id'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      resultState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_state'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      ),
      alternativesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternatives_json'],
      ),
      treatmentSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatment_source'],
      )!,
      treatmentGuidelineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatment_guideline_id'],
      ),
      llmInterpretationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}llm_interpretation_id'],
      ),
      aiTreatmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_treatment_json'],
      ),
      aiTreatmentFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_treatment_fetched_at'],
      ),
      inferredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inferred_at'],
      )!,
    );
  }

  @override
  $DiagnosisTableTable createAlias(String alias) {
    return $DiagnosisTableTable(attachedDatabase, alias);
  }
}

class DiagnosisTableData extends DataClass
    implements Insertable<DiagnosisTableData> {
  final String id;
  final String scanId;

  /// NULL if result_state = 'UNSUPPORTED'
  final String? diseaseId;
  final String modelVersionId;

  /// 0.0–1.0
  final double confidence;

  /// 'CONFIDENT'|'LOW_CONFIDENCE'|'UNSUPPORTED'|'ANALYSIS_FAILED'
  final String resultState;

  /// 'low'|'moderate'|'high' — nullable
  final String? severity;

  /// JSON array of {disease_id, confidence}
  final String? alternativesJson;

  /// 'LLM' | 'LOCAL_FALLBACK'
  final String treatmentSource;

  /// Set only when treatment_source = 'LOCAL_FALLBACK'
  final String? treatmentGuidelineId;

  /// Set only when treatment_source = 'LLM'.
  /// FK to llm_interpretation is intentionally omitted per schema spec
  /// (llm_interpretation table is not part of this scope).
  final String? llmInterpretationId;

  /// The AI-written TreatmentResponse (see domain/entities/treatment.dart's
  /// toJson/fromJson), cached the moment it's fetched so re-opening this
  /// diagnosis never re-asks the LLM for something already answered. Before
  /// this column existed, the response lived only in DiagnosisCubit's
  /// in-memory state and was gone the instant the screen was disposed - a
  /// re-open re-ran the full request every time, spending real API quota on
  /// a question already asked and answered.
  final String? aiTreatmentJson;

  /// When [aiTreatmentJson] was cached. Not currently used to expire the
  /// cache — this treatment is tied to one immutable diagnosis, not a value
  /// that goes stale — kept for the same reason [inferredAt] is: an audit
  /// trail costs one column and answers "when" questions later for free.
  final String? aiTreatmentFetchedAt;
  final String inferredAt;
  const DiagnosisTableData({
    required this.id,
    required this.scanId,
    this.diseaseId,
    required this.modelVersionId,
    required this.confidence,
    required this.resultState,
    this.severity,
    this.alternativesJson,
    required this.treatmentSource,
    this.treatmentGuidelineId,
    this.llmInterpretationId,
    this.aiTreatmentJson,
    this.aiTreatmentFetchedAt,
    required this.inferredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scan_id'] = Variable<String>(scanId);
    if (!nullToAbsent || diseaseId != null) {
      map['disease_id'] = Variable<String>(diseaseId);
    }
    map['model_version_id'] = Variable<String>(modelVersionId);
    map['confidence'] = Variable<double>(confidence);
    map['result_state'] = Variable<String>(resultState);
    if (!nullToAbsent || severity != null) {
      map['severity'] = Variable<String>(severity);
    }
    if (!nullToAbsent || alternativesJson != null) {
      map['alternatives_json'] = Variable<String>(alternativesJson);
    }
    map['treatment_source'] = Variable<String>(treatmentSource);
    if (!nullToAbsent || treatmentGuidelineId != null) {
      map['treatment_guideline_id'] = Variable<String>(treatmentGuidelineId);
    }
    if (!nullToAbsent || llmInterpretationId != null) {
      map['llm_interpretation_id'] = Variable<String>(llmInterpretationId);
    }
    if (!nullToAbsent || aiTreatmentJson != null) {
      map['ai_treatment_json'] = Variable<String>(aiTreatmentJson);
    }
    if (!nullToAbsent || aiTreatmentFetchedAt != null) {
      map['ai_treatment_fetched_at'] = Variable<String>(aiTreatmentFetchedAt);
    }
    map['inferred_at'] = Variable<String>(inferredAt);
    return map;
  }

  DiagnosisTableCompanion toCompanion(bool nullToAbsent) {
    return DiagnosisTableCompanion(
      id: Value(id),
      scanId: Value(scanId),
      diseaseId: diseaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(diseaseId),
      modelVersionId: Value(modelVersionId),
      confidence: Value(confidence),
      resultState: Value(resultState),
      severity: severity == null && nullToAbsent
          ? const Value.absent()
          : Value(severity),
      alternativesJson: alternativesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(alternativesJson),
      treatmentSource: Value(treatmentSource),
      treatmentGuidelineId: treatmentGuidelineId == null && nullToAbsent
          ? const Value.absent()
          : Value(treatmentGuidelineId),
      llmInterpretationId: llmInterpretationId == null && nullToAbsent
          ? const Value.absent()
          : Value(llmInterpretationId),
      aiTreatmentJson: aiTreatmentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(aiTreatmentJson),
      aiTreatmentFetchedAt: aiTreatmentFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(aiTreatmentFetchedAt),
      inferredAt: Value(inferredAt),
    );
  }

  factory DiagnosisTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiagnosisTableData(
      id: serializer.fromJson<String>(json['id']),
      scanId: serializer.fromJson<String>(json['scanId']),
      diseaseId: serializer.fromJson<String?>(json['diseaseId']),
      modelVersionId: serializer.fromJson<String>(json['modelVersionId']),
      confidence: serializer.fromJson<double>(json['confidence']),
      resultState: serializer.fromJson<String>(json['resultState']),
      severity: serializer.fromJson<String?>(json['severity']),
      alternativesJson: serializer.fromJson<String?>(json['alternativesJson']),
      treatmentSource: serializer.fromJson<String>(json['treatmentSource']),
      treatmentGuidelineId: serializer.fromJson<String?>(
        json['treatmentGuidelineId'],
      ),
      llmInterpretationId: serializer.fromJson<String?>(
        json['llmInterpretationId'],
      ),
      aiTreatmentJson: serializer.fromJson<String?>(json['aiTreatmentJson']),
      aiTreatmentFetchedAt: serializer.fromJson<String?>(
        json['aiTreatmentFetchedAt'],
      ),
      inferredAt: serializer.fromJson<String>(json['inferredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scanId': serializer.toJson<String>(scanId),
      'diseaseId': serializer.toJson<String?>(diseaseId),
      'modelVersionId': serializer.toJson<String>(modelVersionId),
      'confidence': serializer.toJson<double>(confidence),
      'resultState': serializer.toJson<String>(resultState),
      'severity': serializer.toJson<String?>(severity),
      'alternativesJson': serializer.toJson<String?>(alternativesJson),
      'treatmentSource': serializer.toJson<String>(treatmentSource),
      'treatmentGuidelineId': serializer.toJson<String?>(treatmentGuidelineId),
      'llmInterpretationId': serializer.toJson<String?>(llmInterpretationId),
      'aiTreatmentJson': serializer.toJson<String?>(aiTreatmentJson),
      'aiTreatmentFetchedAt': serializer.toJson<String?>(aiTreatmentFetchedAt),
      'inferredAt': serializer.toJson<String>(inferredAt),
    };
  }

  DiagnosisTableData copyWith({
    String? id,
    String? scanId,
    Value<String?> diseaseId = const Value.absent(),
    String? modelVersionId,
    double? confidence,
    String? resultState,
    Value<String?> severity = const Value.absent(),
    Value<String?> alternativesJson = const Value.absent(),
    String? treatmentSource,
    Value<String?> treatmentGuidelineId = const Value.absent(),
    Value<String?> llmInterpretationId = const Value.absent(),
    Value<String?> aiTreatmentJson = const Value.absent(),
    Value<String?> aiTreatmentFetchedAt = const Value.absent(),
    String? inferredAt,
  }) => DiagnosisTableData(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    diseaseId: diseaseId.present ? diseaseId.value : this.diseaseId,
    modelVersionId: modelVersionId ?? this.modelVersionId,
    confidence: confidence ?? this.confidence,
    resultState: resultState ?? this.resultState,
    severity: severity.present ? severity.value : this.severity,
    alternativesJson: alternativesJson.present
        ? alternativesJson.value
        : this.alternativesJson,
    treatmentSource: treatmentSource ?? this.treatmentSource,
    treatmentGuidelineId: treatmentGuidelineId.present
        ? treatmentGuidelineId.value
        : this.treatmentGuidelineId,
    llmInterpretationId: llmInterpretationId.present
        ? llmInterpretationId.value
        : this.llmInterpretationId,
    aiTreatmentJson: aiTreatmentJson.present
        ? aiTreatmentJson.value
        : this.aiTreatmentJson,
    aiTreatmentFetchedAt: aiTreatmentFetchedAt.present
        ? aiTreatmentFetchedAt.value
        : this.aiTreatmentFetchedAt,
    inferredAt: inferredAt ?? this.inferredAt,
  );
  DiagnosisTableData copyWithCompanion(DiagnosisTableCompanion data) {
    return DiagnosisTableData(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      diseaseId: data.diseaseId.present ? data.diseaseId.value : this.diseaseId,
      modelVersionId: data.modelVersionId.present
          ? data.modelVersionId.value
          : this.modelVersionId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      resultState: data.resultState.present
          ? data.resultState.value
          : this.resultState,
      severity: data.severity.present ? data.severity.value : this.severity,
      alternativesJson: data.alternativesJson.present
          ? data.alternativesJson.value
          : this.alternativesJson,
      treatmentSource: data.treatmentSource.present
          ? data.treatmentSource.value
          : this.treatmentSource,
      treatmentGuidelineId: data.treatmentGuidelineId.present
          ? data.treatmentGuidelineId.value
          : this.treatmentGuidelineId,
      llmInterpretationId: data.llmInterpretationId.present
          ? data.llmInterpretationId.value
          : this.llmInterpretationId,
      aiTreatmentJson: data.aiTreatmentJson.present
          ? data.aiTreatmentJson.value
          : this.aiTreatmentJson,
      aiTreatmentFetchedAt: data.aiTreatmentFetchedAt.present
          ? data.aiTreatmentFetchedAt.value
          : this.aiTreatmentFetchedAt,
      inferredAt: data.inferredAt.present
          ? data.inferredAt.value
          : this.inferredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosisTableData(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('modelVersionId: $modelVersionId, ')
          ..write('confidence: $confidence, ')
          ..write('resultState: $resultState, ')
          ..write('severity: $severity, ')
          ..write('alternativesJson: $alternativesJson, ')
          ..write('treatmentSource: $treatmentSource, ')
          ..write('treatmentGuidelineId: $treatmentGuidelineId, ')
          ..write('llmInterpretationId: $llmInterpretationId, ')
          ..write('aiTreatmentJson: $aiTreatmentJson, ')
          ..write('aiTreatmentFetchedAt: $aiTreatmentFetchedAt, ')
          ..write('inferredAt: $inferredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanId,
    diseaseId,
    modelVersionId,
    confidence,
    resultState,
    severity,
    alternativesJson,
    treatmentSource,
    treatmentGuidelineId,
    llmInterpretationId,
    aiTreatmentJson,
    aiTreatmentFetchedAt,
    inferredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiagnosisTableData &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.diseaseId == this.diseaseId &&
          other.modelVersionId == this.modelVersionId &&
          other.confidence == this.confidence &&
          other.resultState == this.resultState &&
          other.severity == this.severity &&
          other.alternativesJson == this.alternativesJson &&
          other.treatmentSource == this.treatmentSource &&
          other.treatmentGuidelineId == this.treatmentGuidelineId &&
          other.llmInterpretationId == this.llmInterpretationId &&
          other.aiTreatmentJson == this.aiTreatmentJson &&
          other.aiTreatmentFetchedAt == this.aiTreatmentFetchedAt &&
          other.inferredAt == this.inferredAt);
}

class DiagnosisTableCompanion extends UpdateCompanion<DiagnosisTableData> {
  final Value<String> id;
  final Value<String> scanId;
  final Value<String?> diseaseId;
  final Value<String> modelVersionId;
  final Value<double> confidence;
  final Value<String> resultState;
  final Value<String?> severity;
  final Value<String?> alternativesJson;
  final Value<String> treatmentSource;
  final Value<String?> treatmentGuidelineId;
  final Value<String?> llmInterpretationId;
  final Value<String?> aiTreatmentJson;
  final Value<String?> aiTreatmentFetchedAt;
  final Value<String> inferredAt;
  final Value<int> rowid;
  const DiagnosisTableCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.diseaseId = const Value.absent(),
    this.modelVersionId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.resultState = const Value.absent(),
    this.severity = const Value.absent(),
    this.alternativesJson = const Value.absent(),
    this.treatmentSource = const Value.absent(),
    this.treatmentGuidelineId = const Value.absent(),
    this.llmInterpretationId = const Value.absent(),
    this.aiTreatmentJson = const Value.absent(),
    this.aiTreatmentFetchedAt = const Value.absent(),
    this.inferredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiagnosisTableCompanion.insert({
    required String id,
    required String scanId,
    this.diseaseId = const Value.absent(),
    required String modelVersionId,
    required double confidence,
    required String resultState,
    this.severity = const Value.absent(),
    this.alternativesJson = const Value.absent(),
    required String treatmentSource,
    this.treatmentGuidelineId = const Value.absent(),
    this.llmInterpretationId = const Value.absent(),
    this.aiTreatmentJson = const Value.absent(),
    this.aiTreatmentFetchedAt = const Value.absent(),
    required String inferredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scanId = Value(scanId),
       modelVersionId = Value(modelVersionId),
       confidence = Value(confidence),
       resultState = Value(resultState),
       treatmentSource = Value(treatmentSource),
       inferredAt = Value(inferredAt);
  static Insertable<DiagnosisTableData> custom({
    Expression<String>? id,
    Expression<String>? scanId,
    Expression<String>? diseaseId,
    Expression<String>? modelVersionId,
    Expression<double>? confidence,
    Expression<String>? resultState,
    Expression<String>? severity,
    Expression<String>? alternativesJson,
    Expression<String>? treatmentSource,
    Expression<String>? treatmentGuidelineId,
    Expression<String>? llmInterpretationId,
    Expression<String>? aiTreatmentJson,
    Expression<String>? aiTreatmentFetchedAt,
    Expression<String>? inferredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (diseaseId != null) 'disease_id': diseaseId,
      if (modelVersionId != null) 'model_version_id': modelVersionId,
      if (confidence != null) 'confidence': confidence,
      if (resultState != null) 'result_state': resultState,
      if (severity != null) 'severity': severity,
      if (alternativesJson != null) 'alternatives_json': alternativesJson,
      if (treatmentSource != null) 'treatment_source': treatmentSource,
      if (treatmentGuidelineId != null)
        'treatment_guideline_id': treatmentGuidelineId,
      if (llmInterpretationId != null)
        'llm_interpretation_id': llmInterpretationId,
      if (aiTreatmentJson != null) 'ai_treatment_json': aiTreatmentJson,
      if (aiTreatmentFetchedAt != null)
        'ai_treatment_fetched_at': aiTreatmentFetchedAt,
      if (inferredAt != null) 'inferred_at': inferredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiagnosisTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scanId,
    Value<String?>? diseaseId,
    Value<String>? modelVersionId,
    Value<double>? confidence,
    Value<String>? resultState,
    Value<String?>? severity,
    Value<String?>? alternativesJson,
    Value<String>? treatmentSource,
    Value<String?>? treatmentGuidelineId,
    Value<String?>? llmInterpretationId,
    Value<String?>? aiTreatmentJson,
    Value<String?>? aiTreatmentFetchedAt,
    Value<String>? inferredAt,
    Value<int>? rowid,
  }) {
    return DiagnosisTableCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      diseaseId: diseaseId ?? this.diseaseId,
      modelVersionId: modelVersionId ?? this.modelVersionId,
      confidence: confidence ?? this.confidence,
      resultState: resultState ?? this.resultState,
      severity: severity ?? this.severity,
      alternativesJson: alternativesJson ?? this.alternativesJson,
      treatmentSource: treatmentSource ?? this.treatmentSource,
      treatmentGuidelineId: treatmentGuidelineId ?? this.treatmentGuidelineId,
      llmInterpretationId: llmInterpretationId ?? this.llmInterpretationId,
      aiTreatmentJson: aiTreatmentJson ?? this.aiTreatmentJson,
      aiTreatmentFetchedAt: aiTreatmentFetchedAt ?? this.aiTreatmentFetchedAt,
      inferredAt: inferredAt ?? this.inferredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (diseaseId.present) {
      map['disease_id'] = Variable<String>(diseaseId.value);
    }
    if (modelVersionId.present) {
      map['model_version_id'] = Variable<String>(modelVersionId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (resultState.present) {
      map['result_state'] = Variable<String>(resultState.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (alternativesJson.present) {
      map['alternatives_json'] = Variable<String>(alternativesJson.value);
    }
    if (treatmentSource.present) {
      map['treatment_source'] = Variable<String>(treatmentSource.value);
    }
    if (treatmentGuidelineId.present) {
      map['treatment_guideline_id'] = Variable<String>(
        treatmentGuidelineId.value,
      );
    }
    if (llmInterpretationId.present) {
      map['llm_interpretation_id'] = Variable<String>(
        llmInterpretationId.value,
      );
    }
    if (aiTreatmentJson.present) {
      map['ai_treatment_json'] = Variable<String>(aiTreatmentJson.value);
    }
    if (aiTreatmentFetchedAt.present) {
      map['ai_treatment_fetched_at'] = Variable<String>(
        aiTreatmentFetchedAt.value,
      );
    }
    if (inferredAt.present) {
      map['inferred_at'] = Variable<String>(inferredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiagnosisTableCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('modelVersionId: $modelVersionId, ')
          ..write('confidence: $confidence, ')
          ..write('resultState: $resultState, ')
          ..write('severity: $severity, ')
          ..write('alternativesJson: $alternativesJson, ')
          ..write('treatmentSource: $treatmentSource, ')
          ..write('treatmentGuidelineId: $treatmentGuidelineId, ')
          ..write('llmInterpretationId: $llmInterpretationId, ')
          ..write('aiTreatmentJson: $aiTreatmentJson, ')
          ..write('aiTreatmentFetchedAt: $aiTreatmentFetchedAt, ')
          ..write('inferredAt: $inferredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EscalationTableTable extends EscalationTable
    with TableInfo<$EscalationTableTable, EscalationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EscalationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scan (id)',
    ),
  );
  static const VerificationMeta _diagnosisIdMeta = const VerificationMeta(
    'diagnosisId',
  );
  @override
  late final GeneratedColumn<String> diagnosisId = GeneratedColumn<String>(
    'diagnosis_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diagnosis (id)',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedViaMeta = const VerificationMeta(
    'sharedVia',
  );
  @override
  late final GeneratedColumn<String> sharedVia = GeneratedColumn<String>(
    'shared_via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('WHATSAPP'),
  );
  static const VerificationMeta _sharedAtMeta = const VerificationMeta(
    'sharedAt',
  );
  @override
  late final GeneratedColumn<String> sharedAt = GeneratedColumn<String>(
    'shared_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scanId,
    diagnosisId,
    notes,
    sharedVia,
    sharedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'escalation';
  @override
  VerificationContext validateIntegrity(
    Insertable<EscalationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('diagnosis_id')) {
      context.handle(
        _diagnosisIdMeta,
        diagnosisId.isAcceptableOrUnknown(
          data['diagnosis_id']!,
          _diagnosisIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diagnosisIdMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('shared_via')) {
      context.handle(
        _sharedViaMeta,
        sharedVia.isAcceptableOrUnknown(data['shared_via']!, _sharedViaMeta),
      );
    }
    if (data.containsKey('shared_at')) {
      context.handle(
        _sharedAtMeta,
        sharedAt.isAcceptableOrUnknown(data['shared_at']!, _sharedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EscalationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EscalationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      diagnosisId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sharedVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_via'],
      )!,
      sharedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EscalationTableTable createAlias(String alias) {
    return $EscalationTableTable(attachedDatabase, alias);
  }
}

class EscalationTableData extends DataClass
    implements Insertable<EscalationTableData> {
  final String id;
  final String scanId;
  final String diagnosisId;
  final String? notes;
  final String sharedVia;
  final String? sharedAt;
  final String createdAt;
  const EscalationTableData({
    required this.id,
    required this.scanId,
    required this.diagnosisId,
    this.notes,
    required this.sharedVia,
    this.sharedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scan_id'] = Variable<String>(scanId);
    map['diagnosis_id'] = Variable<String>(diagnosisId);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['shared_via'] = Variable<String>(sharedVia);
    if (!nullToAbsent || sharedAt != null) {
      map['shared_at'] = Variable<String>(sharedAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  EscalationTableCompanion toCompanion(bool nullToAbsent) {
    return EscalationTableCompanion(
      id: Value(id),
      scanId: Value(scanId),
      diagnosisId: Value(diagnosisId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sharedVia: Value(sharedVia),
      sharedAt: sharedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedAt),
      createdAt: Value(createdAt),
    );
  }

  factory EscalationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EscalationTableData(
      id: serializer.fromJson<String>(json['id']),
      scanId: serializer.fromJson<String>(json['scanId']),
      diagnosisId: serializer.fromJson<String>(json['diagnosisId']),
      notes: serializer.fromJson<String?>(json['notes']),
      sharedVia: serializer.fromJson<String>(json['sharedVia']),
      sharedAt: serializer.fromJson<String?>(json['sharedAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scanId': serializer.toJson<String>(scanId),
      'diagnosisId': serializer.toJson<String>(diagnosisId),
      'notes': serializer.toJson<String?>(notes),
      'sharedVia': serializer.toJson<String>(sharedVia),
      'sharedAt': serializer.toJson<String?>(sharedAt),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  EscalationTableData copyWith({
    String? id,
    String? scanId,
    String? diagnosisId,
    Value<String?> notes = const Value.absent(),
    String? sharedVia,
    Value<String?> sharedAt = const Value.absent(),
    String? createdAt,
  }) => EscalationTableData(
    id: id ?? this.id,
    scanId: scanId ?? this.scanId,
    diagnosisId: diagnosisId ?? this.diagnosisId,
    notes: notes.present ? notes.value : this.notes,
    sharedVia: sharedVia ?? this.sharedVia,
    sharedAt: sharedAt.present ? sharedAt.value : this.sharedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  EscalationTableData copyWithCompanion(EscalationTableCompanion data) {
    return EscalationTableData(
      id: data.id.present ? data.id.value : this.id,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      diagnosisId: data.diagnosisId.present
          ? data.diagnosisId.value
          : this.diagnosisId,
      notes: data.notes.present ? data.notes.value : this.notes,
      sharedVia: data.sharedVia.present ? data.sharedVia.value : this.sharedVia,
      sharedAt: data.sharedAt.present ? data.sharedAt.value : this.sharedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EscalationTableData(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('notes: $notes, ')
          ..write('sharedVia: $sharedVia, ')
          ..write('sharedAt: $sharedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scanId,
    diagnosisId,
    notes,
    sharedVia,
    sharedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EscalationTableData &&
          other.id == this.id &&
          other.scanId == this.scanId &&
          other.diagnosisId == this.diagnosisId &&
          other.notes == this.notes &&
          other.sharedVia == this.sharedVia &&
          other.sharedAt == this.sharedAt &&
          other.createdAt == this.createdAt);
}

class EscalationTableCompanion extends UpdateCompanion<EscalationTableData> {
  final Value<String> id;
  final Value<String> scanId;
  final Value<String> diagnosisId;
  final Value<String?> notes;
  final Value<String> sharedVia;
  final Value<String?> sharedAt;
  final Value<String> createdAt;
  final Value<int> rowid;
  const EscalationTableCompanion({
    this.id = const Value.absent(),
    this.scanId = const Value.absent(),
    this.diagnosisId = const Value.absent(),
    this.notes = const Value.absent(),
    this.sharedVia = const Value.absent(),
    this.sharedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EscalationTableCompanion.insert({
    required String id,
    required String scanId,
    required String diagnosisId,
    this.notes = const Value.absent(),
    this.sharedVia = const Value.absent(),
    this.sharedAt = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scanId = Value(scanId),
       diagnosisId = Value(diagnosisId),
       createdAt = Value(createdAt);
  static Insertable<EscalationTableData> custom({
    Expression<String>? id,
    Expression<String>? scanId,
    Expression<String>? diagnosisId,
    Expression<String>? notes,
    Expression<String>? sharedVia,
    Expression<String>? sharedAt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      if (diagnosisId != null) 'diagnosis_id': diagnosisId,
      if (notes != null) 'notes': notes,
      if (sharedVia != null) 'shared_via': sharedVia,
      if (sharedAt != null) 'shared_at': sharedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EscalationTableCompanion copyWith({
    Value<String>? id,
    Value<String>? scanId,
    Value<String>? diagnosisId,
    Value<String?>? notes,
    Value<String>? sharedVia,
    Value<String?>? sharedAt,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return EscalationTableCompanion(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      notes: notes ?? this.notes,
      sharedVia: sharedVia ?? this.sharedVia,
      sharedAt: sharedAt ?? this.sharedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (diagnosisId.present) {
      map['diagnosis_id'] = Variable<String>(diagnosisId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sharedVia.present) {
      map['shared_via'] = Variable<String>(sharedVia.value);
    }
    if (sharedAt.present) {
      map['shared_at'] = Variable<String>(sharedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EscalationTableCompanion(')
          ..write('id: $id, ')
          ..write('scanId: $scanId, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('notes: $notes, ')
          ..write('sharedVia: $sharedVia, ')
          ..write('sharedAt: $sharedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationTableTable extends SyncOperationTable
    with TableInfo<$SyncOperationTableTable, SyncOperationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CREATE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _uploadedImageUrlMeta = const VerificationMeta(
    'uploadedImageUrl',
  );
  @override
  late final GeneratedColumn<String> uploadedImageUrl = GeneratedColumn<String>(
    'uploaded_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityId,
    entityType,
    operationType,
    payloadJson,
    status,
    retryCount,
    uploadedImageUrl,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operation';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('uploaded_image_url')) {
      context.handle(
        _uploadedImageUrlMeta,
        uploadedImageUrl.isAcceptableOrUnknown(
          data['uploaded_image_url']!,
          _uploadedImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      uploadedImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploaded_image_url'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncOperationTableTable createAlias(String alias) {
    return $SyncOperationTableTable(attachedDatabase, alias);
  }
}

class SyncOperationTableData extends DataClass
    implements Insertable<SyncOperationTableData> {
  final String id;

  /// The local id of the scan, diagnosis, or escalation
  final String entityId;

  /// 'SCAN' | 'DIAGNOSIS' | 'ESCALATION'
  final String entityType;

  /// 'CREATE' | 'UPDATE'
  final String operationType;

  /// JSON payload representation for idempotent upsert
  final String payloadJson;

  /// 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED' |
  /// 'PERMANENTLY_FAILED' | 'AUTH_REQUIRED'
  ///
  /// PERMANENTLY_FAILED: retrying will not help (the server rejected the
  /// payload, or the transient-retry budget is exhausted). Surfaced to the
  /// user rather than silently dropped.
  /// AUTH_REQUIRED: the session expired mid-sync. Held, not retried, until
  /// the user signs in again — retrying with a dead token just burns the
  /// retry budget and loses the backlog silently.
  final String status;
  final int retryCount;

  /// Remote URL of an image that has ALREADY been uploaded for this
  /// operation. Set immediately after a successful upload, before the
  /// metadata POST is attempted.
  ///
  /// Image upload happens before the metadata POST, so without this a
  /// failure of the POST would make the retry re-upload the same bytes from
  /// scratch — expensive on a metered rural connection, and it orphans a
  /// blob in remote storage every attempt.
  final String? uploadedImageUrl;
  final String? lastError;
  final String createdAt;
  final String updatedAt;
  const SyncOperationTableData({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    required this.retryCount,
    this.uploadedImageUrl,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || uploadedImageUrl != null) {
      map['uploaded_image_url'] = Variable<String>(uploadedImageUrl);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SyncOperationTableCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationTableCompanion(
      id: Value(id),
      entityId: Value(entityId),
      entityType: Value(entityType),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      retryCount: Value(retryCount),
      uploadedImageUrl: uploadedImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedImageUrl),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncOperationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperationTableData(
      id: serializer.fromJson<String>(json['id']),
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      uploadedImageUrl: serializer.fromJson<String?>(json['uploadedImageUrl']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'uploadedImageUrl': serializer.toJson<String?>(uploadedImageUrl),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SyncOperationTableData copyWith({
    String? id,
    String? entityId,
    String? entityType,
    String? operationType,
    String? payloadJson,
    String? status,
    int? retryCount,
    Value<String?> uploadedImageUrl = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => SyncOperationTableData(
    id: id ?? this.id,
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    uploadedImageUrl: uploadedImageUrl.present
        ? uploadedImageUrl.value
        : this.uploadedImageUrl,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncOperationTableData copyWithCompanion(SyncOperationTableCompanion data) {
    return SyncOperationTableData(
      id: data.id.present ? data.id.value : this.id,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      uploadedImageUrl: data.uploadedImageUrl.present
          ? data.uploadedImageUrl.value
          : this.uploadedImageUrl,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationTableData(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('uploadedImageUrl: $uploadedImageUrl, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityId,
    entityType,
    operationType,
    payloadJson,
    status,
    retryCount,
    uploadedImageUrl,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperationTableData &&
          other.id == this.id &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.uploadedImageUrl == this.uploadedImageUrl &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncOperationTableCompanion
    extends UpdateCompanion<SyncOperationTableData> {
  final Value<String> id;
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> uploadedImageUrl;
  final Value<String?> lastError;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SyncOperationTableCompanion({
    this.id = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.uploadedImageUrl = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationTableCompanion.insert({
    required String id,
    required String entityId,
    required String entityType,
    this.operationType = const Value.absent(),
    required String payloadJson,
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.uploadedImageUrl = const Value.absent(),
    this.lastError = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityId = Value(entityId),
       entityType = Value(entityType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncOperationTableData> custom({
    Expression<String>? id,
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? uploadedImageUrl,
    Expression<String>? lastError,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (uploadedImageUrl != null) 'uploaded_image_url': uploadedImageUrl,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationTableCompanion copyWith({
    Value<String>? id,
    Value<String>? entityId,
    Value<String>? entityType,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? uploadedImageUrl,
    Value<String?>? lastError,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncOperationTableCompanion(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      uploadedImageUrl: uploadedImageUrl ?? this.uploadedImageUrl,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (uploadedImageUrl.present) {
      map['uploaded_image_url'] = Variable<String>(uploadedImageUrl.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationTableCompanion(')
          ..write('id: $id, ')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('uploadedImageUrl: $uploadedImageUrl, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiseaseExplanationTableTable extends DiseaseExplanationTable
    with TableInfo<$DiseaseExplanationTableTable, DiseaseExplanationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiseaseExplanationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diseaseIdMeta = const VerificationMeta(
    'diseaseId',
  );
  @override
  late final GeneratedColumn<String> diseaseId = GeneratedColumn<String>(
    'disease_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disease (id)',
    ),
  );
  static const VerificationMeta _plantDescriptionEnMeta =
      const VerificationMeta('plantDescriptionEn');
  @override
  late final GeneratedColumn<String> plantDescriptionEn =
      GeneratedColumn<String>(
        'plant_description_en',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plantDescriptionSiMeta =
      const VerificationMeta('plantDescriptionSi');
  @override
  late final GeneratedColumn<String> plantDescriptionSi =
      GeneratedColumn<String>(
        'plant_description_si',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plantDescriptionTaMeta =
      const VerificationMeta('plantDescriptionTa');
  @override
  late final GeneratedColumn<String> plantDescriptionTa =
      GeneratedColumn<String>(
        'plant_description_ta',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resultMeaningEnMeta = const VerificationMeta(
    'resultMeaningEn',
  );
  @override
  late final GeneratedColumn<String> resultMeaningEn = GeneratedColumn<String>(
    'result_meaning_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultMeaningSiMeta = const VerificationMeta(
    'resultMeaningSi',
  );
  @override
  late final GeneratedColumn<String> resultMeaningSi = GeneratedColumn<String>(
    'result_meaning_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultMeaningTaMeta = const VerificationMeta(
    'resultMeaningTa',
  );
  @override
  late final GeneratedColumn<String> resultMeaningTa = GeneratedColumn<String>(
    'result_meaning_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationVersionMeta =
      const VerificationMeta('explanationVersion');
  @override
  late final GeneratedColumn<String> explanationVersion =
      GeneratedColumn<String>(
        'explanation_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diseaseId,
    plantDescriptionEn,
    plantDescriptionSi,
    plantDescriptionTa,
    resultMeaningEn,
    resultMeaningSi,
    resultMeaningTa,
    explanationVersion,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disease_explanation';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiseaseExplanationTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('disease_id')) {
      context.handle(
        _diseaseIdMeta,
        diseaseId.isAcceptableOrUnknown(data['disease_id']!, _diseaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diseaseIdMeta);
    }
    if (data.containsKey('plant_description_en')) {
      context.handle(
        _plantDescriptionEnMeta,
        plantDescriptionEn.isAcceptableOrUnknown(
          data['plant_description_en']!,
          _plantDescriptionEnMeta,
        ),
      );
    }
    if (data.containsKey('plant_description_si')) {
      context.handle(
        _plantDescriptionSiMeta,
        plantDescriptionSi.isAcceptableOrUnknown(
          data['plant_description_si']!,
          _plantDescriptionSiMeta,
        ),
      );
    }
    if (data.containsKey('plant_description_ta')) {
      context.handle(
        _plantDescriptionTaMeta,
        plantDescriptionTa.isAcceptableOrUnknown(
          data['plant_description_ta']!,
          _plantDescriptionTaMeta,
        ),
      );
    }
    if (data.containsKey('result_meaning_en')) {
      context.handle(
        _resultMeaningEnMeta,
        resultMeaningEn.isAcceptableOrUnknown(
          data['result_meaning_en']!,
          _resultMeaningEnMeta,
        ),
      );
    }
    if (data.containsKey('result_meaning_si')) {
      context.handle(
        _resultMeaningSiMeta,
        resultMeaningSi.isAcceptableOrUnknown(
          data['result_meaning_si']!,
          _resultMeaningSiMeta,
        ),
      );
    }
    if (data.containsKey('result_meaning_ta')) {
      context.handle(
        _resultMeaningTaMeta,
        resultMeaningTa.isAcceptableOrUnknown(
          data['result_meaning_ta']!,
          _resultMeaningTaMeta,
        ),
      );
    }
    if (data.containsKey('explanation_version')) {
      context.handle(
        _explanationVersionMeta,
        explanationVersion.isAcceptableOrUnknown(
          data['explanation_version']!,
          _explanationVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiseaseExplanationTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiseaseExplanationTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diseaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disease_id'],
      )!,
      plantDescriptionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plant_description_en'],
      ),
      plantDescriptionSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plant_description_si'],
      ),
      plantDescriptionTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plant_description_ta'],
      ),
      resultMeaningEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_meaning_en'],
      ),
      resultMeaningSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_meaning_si'],
      ),
      resultMeaningTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_meaning_ta'],
      ),
      explanationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_version'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $DiseaseExplanationTableTable createAlias(String alias) {
    return $DiseaseExplanationTableTable(attachedDatabase, alias);
  }
}

class DiseaseExplanationTableData extends DataClass
    implements Insertable<DiseaseExplanationTableData> {
  final String id;
  final String diseaseId;

  /// What the plant itself is — crop, habit, what a healthy one looks like.
  final String? plantDescriptionEn;
  final String? plantDescriptionSi;
  final String? plantDescriptionTa;

  /// What the scan result suggests, in plain language, including how much
  /// weight to put on it.
  final String? resultMeaningEn;
  final String? resultMeaningSi;
  final String? resultMeaningTa;

  /// Content revision, e.g. 'ex-2026.03' — mirrors guideline_version.
  final String? explanationVersion;
  final String? updatedAt;
  const DiseaseExplanationTableData({
    required this.id,
    required this.diseaseId,
    this.plantDescriptionEn,
    this.plantDescriptionSi,
    this.plantDescriptionTa,
    this.resultMeaningEn,
    this.resultMeaningSi,
    this.resultMeaningTa,
    this.explanationVersion,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['disease_id'] = Variable<String>(diseaseId);
    if (!nullToAbsent || plantDescriptionEn != null) {
      map['plant_description_en'] = Variable<String>(plantDescriptionEn);
    }
    if (!nullToAbsent || plantDescriptionSi != null) {
      map['plant_description_si'] = Variable<String>(plantDescriptionSi);
    }
    if (!nullToAbsent || plantDescriptionTa != null) {
      map['plant_description_ta'] = Variable<String>(plantDescriptionTa);
    }
    if (!nullToAbsent || resultMeaningEn != null) {
      map['result_meaning_en'] = Variable<String>(resultMeaningEn);
    }
    if (!nullToAbsent || resultMeaningSi != null) {
      map['result_meaning_si'] = Variable<String>(resultMeaningSi);
    }
    if (!nullToAbsent || resultMeaningTa != null) {
      map['result_meaning_ta'] = Variable<String>(resultMeaningTa);
    }
    if (!nullToAbsent || explanationVersion != null) {
      map['explanation_version'] = Variable<String>(explanationVersion);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  DiseaseExplanationTableCompanion toCompanion(bool nullToAbsent) {
    return DiseaseExplanationTableCompanion(
      id: Value(id),
      diseaseId: Value(diseaseId),
      plantDescriptionEn: plantDescriptionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(plantDescriptionEn),
      plantDescriptionSi: plantDescriptionSi == null && nullToAbsent
          ? const Value.absent()
          : Value(plantDescriptionSi),
      plantDescriptionTa: plantDescriptionTa == null && nullToAbsent
          ? const Value.absent()
          : Value(plantDescriptionTa),
      resultMeaningEn: resultMeaningEn == null && nullToAbsent
          ? const Value.absent()
          : Value(resultMeaningEn),
      resultMeaningSi: resultMeaningSi == null && nullToAbsent
          ? const Value.absent()
          : Value(resultMeaningSi),
      resultMeaningTa: resultMeaningTa == null && nullToAbsent
          ? const Value.absent()
          : Value(resultMeaningTa),
      explanationVersion: explanationVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(explanationVersion),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DiseaseExplanationTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiseaseExplanationTableData(
      id: serializer.fromJson<String>(json['id']),
      diseaseId: serializer.fromJson<String>(json['diseaseId']),
      plantDescriptionEn: serializer.fromJson<String?>(
        json['plantDescriptionEn'],
      ),
      plantDescriptionSi: serializer.fromJson<String?>(
        json['plantDescriptionSi'],
      ),
      plantDescriptionTa: serializer.fromJson<String?>(
        json['plantDescriptionTa'],
      ),
      resultMeaningEn: serializer.fromJson<String?>(json['resultMeaningEn']),
      resultMeaningSi: serializer.fromJson<String?>(json['resultMeaningSi']),
      resultMeaningTa: serializer.fromJson<String?>(json['resultMeaningTa']),
      explanationVersion: serializer.fromJson<String?>(
        json['explanationVersion'],
      ),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diseaseId': serializer.toJson<String>(diseaseId),
      'plantDescriptionEn': serializer.toJson<String?>(plantDescriptionEn),
      'plantDescriptionSi': serializer.toJson<String?>(plantDescriptionSi),
      'plantDescriptionTa': serializer.toJson<String?>(plantDescriptionTa),
      'resultMeaningEn': serializer.toJson<String?>(resultMeaningEn),
      'resultMeaningSi': serializer.toJson<String?>(resultMeaningSi),
      'resultMeaningTa': serializer.toJson<String?>(resultMeaningTa),
      'explanationVersion': serializer.toJson<String?>(explanationVersion),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  DiseaseExplanationTableData copyWith({
    String? id,
    String? diseaseId,
    Value<String?> plantDescriptionEn = const Value.absent(),
    Value<String?> plantDescriptionSi = const Value.absent(),
    Value<String?> plantDescriptionTa = const Value.absent(),
    Value<String?> resultMeaningEn = const Value.absent(),
    Value<String?> resultMeaningSi = const Value.absent(),
    Value<String?> resultMeaningTa = const Value.absent(),
    Value<String?> explanationVersion = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => DiseaseExplanationTableData(
    id: id ?? this.id,
    diseaseId: diseaseId ?? this.diseaseId,
    plantDescriptionEn: plantDescriptionEn.present
        ? plantDescriptionEn.value
        : this.plantDescriptionEn,
    plantDescriptionSi: plantDescriptionSi.present
        ? plantDescriptionSi.value
        : this.plantDescriptionSi,
    plantDescriptionTa: plantDescriptionTa.present
        ? plantDescriptionTa.value
        : this.plantDescriptionTa,
    resultMeaningEn: resultMeaningEn.present
        ? resultMeaningEn.value
        : this.resultMeaningEn,
    resultMeaningSi: resultMeaningSi.present
        ? resultMeaningSi.value
        : this.resultMeaningSi,
    resultMeaningTa: resultMeaningTa.present
        ? resultMeaningTa.value
        : this.resultMeaningTa,
    explanationVersion: explanationVersion.present
        ? explanationVersion.value
        : this.explanationVersion,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  DiseaseExplanationTableData copyWithCompanion(
    DiseaseExplanationTableCompanion data,
  ) {
    return DiseaseExplanationTableData(
      id: data.id.present ? data.id.value : this.id,
      diseaseId: data.diseaseId.present ? data.diseaseId.value : this.diseaseId,
      plantDescriptionEn: data.plantDescriptionEn.present
          ? data.plantDescriptionEn.value
          : this.plantDescriptionEn,
      plantDescriptionSi: data.plantDescriptionSi.present
          ? data.plantDescriptionSi.value
          : this.plantDescriptionSi,
      plantDescriptionTa: data.plantDescriptionTa.present
          ? data.plantDescriptionTa.value
          : this.plantDescriptionTa,
      resultMeaningEn: data.resultMeaningEn.present
          ? data.resultMeaningEn.value
          : this.resultMeaningEn,
      resultMeaningSi: data.resultMeaningSi.present
          ? data.resultMeaningSi.value
          : this.resultMeaningSi,
      resultMeaningTa: data.resultMeaningTa.present
          ? data.resultMeaningTa.value
          : this.resultMeaningTa,
      explanationVersion: data.explanationVersion.present
          ? data.explanationVersion.value
          : this.explanationVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseExplanationTableData(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('plantDescriptionEn: $plantDescriptionEn, ')
          ..write('plantDescriptionSi: $plantDescriptionSi, ')
          ..write('plantDescriptionTa: $plantDescriptionTa, ')
          ..write('resultMeaningEn: $resultMeaningEn, ')
          ..write('resultMeaningSi: $resultMeaningSi, ')
          ..write('resultMeaningTa: $resultMeaningTa, ')
          ..write('explanationVersion: $explanationVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diseaseId,
    plantDescriptionEn,
    plantDescriptionSi,
    plantDescriptionTa,
    resultMeaningEn,
    resultMeaningSi,
    resultMeaningTa,
    explanationVersion,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiseaseExplanationTableData &&
          other.id == this.id &&
          other.diseaseId == this.diseaseId &&
          other.plantDescriptionEn == this.plantDescriptionEn &&
          other.plantDescriptionSi == this.plantDescriptionSi &&
          other.plantDescriptionTa == this.plantDescriptionTa &&
          other.resultMeaningEn == this.resultMeaningEn &&
          other.resultMeaningSi == this.resultMeaningSi &&
          other.resultMeaningTa == this.resultMeaningTa &&
          other.explanationVersion == this.explanationVersion &&
          other.updatedAt == this.updatedAt);
}

class DiseaseExplanationTableCompanion
    extends UpdateCompanion<DiseaseExplanationTableData> {
  final Value<String> id;
  final Value<String> diseaseId;
  final Value<String?> plantDescriptionEn;
  final Value<String?> plantDescriptionSi;
  final Value<String?> plantDescriptionTa;
  final Value<String?> resultMeaningEn;
  final Value<String?> resultMeaningSi;
  final Value<String?> resultMeaningTa;
  final Value<String?> explanationVersion;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const DiseaseExplanationTableCompanion({
    this.id = const Value.absent(),
    this.diseaseId = const Value.absent(),
    this.plantDescriptionEn = const Value.absent(),
    this.plantDescriptionSi = const Value.absent(),
    this.plantDescriptionTa = const Value.absent(),
    this.resultMeaningEn = const Value.absent(),
    this.resultMeaningSi = const Value.absent(),
    this.resultMeaningTa = const Value.absent(),
    this.explanationVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiseaseExplanationTableCompanion.insert({
    required String id,
    required String diseaseId,
    this.plantDescriptionEn = const Value.absent(),
    this.plantDescriptionSi = const Value.absent(),
    this.plantDescriptionTa = const Value.absent(),
    this.resultMeaningEn = const Value.absent(),
    this.resultMeaningSi = const Value.absent(),
    this.resultMeaningTa = const Value.absent(),
    this.explanationVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diseaseId = Value(diseaseId);
  static Insertable<DiseaseExplanationTableData> custom({
    Expression<String>? id,
    Expression<String>? diseaseId,
    Expression<String>? plantDescriptionEn,
    Expression<String>? plantDescriptionSi,
    Expression<String>? plantDescriptionTa,
    Expression<String>? resultMeaningEn,
    Expression<String>? resultMeaningSi,
    Expression<String>? resultMeaningTa,
    Expression<String>? explanationVersion,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diseaseId != null) 'disease_id': diseaseId,
      if (plantDescriptionEn != null)
        'plant_description_en': plantDescriptionEn,
      if (plantDescriptionSi != null)
        'plant_description_si': plantDescriptionSi,
      if (plantDescriptionTa != null)
        'plant_description_ta': plantDescriptionTa,
      if (resultMeaningEn != null) 'result_meaning_en': resultMeaningEn,
      if (resultMeaningSi != null) 'result_meaning_si': resultMeaningSi,
      if (resultMeaningTa != null) 'result_meaning_ta': resultMeaningTa,
      if (explanationVersion != null) 'explanation_version': explanationVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiseaseExplanationTableCompanion copyWith({
    Value<String>? id,
    Value<String>? diseaseId,
    Value<String?>? plantDescriptionEn,
    Value<String?>? plantDescriptionSi,
    Value<String?>? plantDescriptionTa,
    Value<String?>? resultMeaningEn,
    Value<String?>? resultMeaningSi,
    Value<String?>? resultMeaningTa,
    Value<String?>? explanationVersion,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return DiseaseExplanationTableCompanion(
      id: id ?? this.id,
      diseaseId: diseaseId ?? this.diseaseId,
      plantDescriptionEn: plantDescriptionEn ?? this.plantDescriptionEn,
      plantDescriptionSi: plantDescriptionSi ?? this.plantDescriptionSi,
      plantDescriptionTa: plantDescriptionTa ?? this.plantDescriptionTa,
      resultMeaningEn: resultMeaningEn ?? this.resultMeaningEn,
      resultMeaningSi: resultMeaningSi ?? this.resultMeaningSi,
      resultMeaningTa: resultMeaningTa ?? this.resultMeaningTa,
      explanationVersion: explanationVersion ?? this.explanationVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diseaseId.present) {
      map['disease_id'] = Variable<String>(diseaseId.value);
    }
    if (plantDescriptionEn.present) {
      map['plant_description_en'] = Variable<String>(plantDescriptionEn.value);
    }
    if (plantDescriptionSi.present) {
      map['plant_description_si'] = Variable<String>(plantDescriptionSi.value);
    }
    if (plantDescriptionTa.present) {
      map['plant_description_ta'] = Variable<String>(plantDescriptionTa.value);
    }
    if (resultMeaningEn.present) {
      map['result_meaning_en'] = Variable<String>(resultMeaningEn.value);
    }
    if (resultMeaningSi.present) {
      map['result_meaning_si'] = Variable<String>(resultMeaningSi.value);
    }
    if (resultMeaningTa.present) {
      map['result_meaning_ta'] = Variable<String>(resultMeaningTa.value);
    }
    if (explanationVersion.present) {
      map['explanation_version'] = Variable<String>(explanationVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseExplanationTableCompanion(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('plantDescriptionEn: $plantDescriptionEn, ')
          ..write('plantDescriptionSi: $plantDescriptionSi, ')
          ..write('plantDescriptionTa: $plantDescriptionTa, ')
          ..write('resultMeaningEn: $resultMeaningEn, ')
          ..write('resultMeaningSi: $resultMeaningSi, ')
          ..write('resultMeaningTa: $resultMeaningTa, ')
          ..write('explanationVersion: $explanationVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiseaseConfusionTableTable extends DiseaseConfusionTable
    with TableInfo<$DiseaseConfusionTableTable, DiseaseConfusionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiseaseConfusionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diseaseIdMeta = const VerificationMeta(
    'diseaseId',
  );
  @override
  late final GeneratedColumn<String> diseaseId = GeneratedColumn<String>(
    'disease_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disease (id)',
    ),
  );
  static const VerificationMeta _confusedWithDiseaseIdMeta =
      const VerificationMeta('confusedWithDiseaseId');
  @override
  late final GeneratedColumn<String> confusedWithDiseaseId =
      GeneratedColumn<String>(
        'confused_with_disease_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES disease (id)',
        ),
      );
  static const VerificationMeta _confusedWithLabelEnMeta =
      const VerificationMeta('confusedWithLabelEn');
  @override
  late final GeneratedColumn<String> confusedWithLabelEn =
      GeneratedColumn<String>(
        'confused_with_label_en',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _confusedWithLabelSiMeta =
      const VerificationMeta('confusedWithLabelSi');
  @override
  late final GeneratedColumn<String> confusedWithLabelSi =
      GeneratedColumn<String>(
        'confused_with_label_si',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _confusedWithLabelTaMeta =
      const VerificationMeta('confusedWithLabelTa');
  @override
  late final GeneratedColumn<String> confusedWithLabelTa =
      GeneratedColumn<String>(
        'confused_with_label_ta',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _distinguishingSymptomsEnMeta =
      const VerificationMeta('distinguishingSymptomsEn');
  @override
  late final GeneratedColumn<String> distinguishingSymptomsEn =
      GeneratedColumn<String>(
        'distinguishing_symptoms_en',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _distinguishingSymptomsSiMeta =
      const VerificationMeta('distinguishingSymptomsSi');
  @override
  late final GeneratedColumn<String> distinguishingSymptomsSi =
      GeneratedColumn<String>(
        'distinguishing_symptoms_si',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _distinguishingSymptomsTaMeta =
      const VerificationMeta('distinguishingSymptomsTa');
  @override
  late final GeneratedColumn<String> distinguishingSymptomsTa =
      GeneratedColumn<String>(
        'distinguishing_symptoms_ta',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diseaseId,
    confusedWithDiseaseId,
    confusedWithLabelEn,
    confusedWithLabelSi,
    confusedWithLabelTa,
    distinguishingSymptomsEn,
    distinguishingSymptomsSi,
    distinguishingSymptomsTa,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disease_confusion';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiseaseConfusionTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('disease_id')) {
      context.handle(
        _diseaseIdMeta,
        diseaseId.isAcceptableOrUnknown(data['disease_id']!, _diseaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diseaseIdMeta);
    }
    if (data.containsKey('confused_with_disease_id')) {
      context.handle(
        _confusedWithDiseaseIdMeta,
        confusedWithDiseaseId.isAcceptableOrUnknown(
          data['confused_with_disease_id']!,
          _confusedWithDiseaseIdMeta,
        ),
      );
    }
    if (data.containsKey('confused_with_label_en')) {
      context.handle(
        _confusedWithLabelEnMeta,
        confusedWithLabelEn.isAcceptableOrUnknown(
          data['confused_with_label_en']!,
          _confusedWithLabelEnMeta,
        ),
      );
    }
    if (data.containsKey('confused_with_label_si')) {
      context.handle(
        _confusedWithLabelSiMeta,
        confusedWithLabelSi.isAcceptableOrUnknown(
          data['confused_with_label_si']!,
          _confusedWithLabelSiMeta,
        ),
      );
    }
    if (data.containsKey('confused_with_label_ta')) {
      context.handle(
        _confusedWithLabelTaMeta,
        confusedWithLabelTa.isAcceptableOrUnknown(
          data['confused_with_label_ta']!,
          _confusedWithLabelTaMeta,
        ),
      );
    }
    if (data.containsKey('distinguishing_symptoms_en')) {
      context.handle(
        _distinguishingSymptomsEnMeta,
        distinguishingSymptomsEn.isAcceptableOrUnknown(
          data['distinguishing_symptoms_en']!,
          _distinguishingSymptomsEnMeta,
        ),
      );
    }
    if (data.containsKey('distinguishing_symptoms_si')) {
      context.handle(
        _distinguishingSymptomsSiMeta,
        distinguishingSymptomsSi.isAcceptableOrUnknown(
          data['distinguishing_symptoms_si']!,
          _distinguishingSymptomsSiMeta,
        ),
      );
    }
    if (data.containsKey('distinguishing_symptoms_ta')) {
      context.handle(
        _distinguishingSymptomsTaMeta,
        distinguishingSymptomsTa.isAcceptableOrUnknown(
          data['distinguishing_symptoms_ta']!,
          _distinguishingSymptomsTaMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiseaseConfusionTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiseaseConfusionTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diseaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disease_id'],
      )!,
      confusedWithDiseaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confused_with_disease_id'],
      ),
      confusedWithLabelEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confused_with_label_en'],
      ),
      confusedWithLabelSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confused_with_label_si'],
      ),
      confusedWithLabelTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confused_with_label_ta'],
      ),
      distinguishingSymptomsEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distinguishing_symptoms_en'],
      ),
      distinguishingSymptomsSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distinguishing_symptoms_si'],
      ),
      distinguishingSymptomsTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distinguishing_symptoms_ta'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DiseaseConfusionTableTable createAlias(String alias) {
    return $DiseaseConfusionTableTable(attachedDatabase, alias);
  }
}

class DiseaseConfusionTableData extends DataClass
    implements Insertable<DiseaseConfusionTableData> {
  final String id;

  /// The diagnosed disease this look-alike is listed under.
  final String diseaseId;

  /// The look-alike, when it is itself a known disease.
  final String? confusedWithDiseaseId;

  /// The look-alike's name, when it is not a row in `disease`.
  final String? confusedWithLabelEn;
  final String? confusedWithLabelSi;
  final String? confusedWithLabelTa;

  /// How to tell the two apart in the field.
  final String? distinguishingSymptomsEn;
  final String? distinguishingSymptomsSi;
  final String? distinguishingSymptomsTa;

  /// Display order; lower first.
  final int sortOrder;
  const DiseaseConfusionTableData({
    required this.id,
    required this.diseaseId,
    this.confusedWithDiseaseId,
    this.confusedWithLabelEn,
    this.confusedWithLabelSi,
    this.confusedWithLabelTa,
    this.distinguishingSymptomsEn,
    this.distinguishingSymptomsSi,
    this.distinguishingSymptomsTa,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['disease_id'] = Variable<String>(diseaseId);
    if (!nullToAbsent || confusedWithDiseaseId != null) {
      map['confused_with_disease_id'] = Variable<String>(confusedWithDiseaseId);
    }
    if (!nullToAbsent || confusedWithLabelEn != null) {
      map['confused_with_label_en'] = Variable<String>(confusedWithLabelEn);
    }
    if (!nullToAbsent || confusedWithLabelSi != null) {
      map['confused_with_label_si'] = Variable<String>(confusedWithLabelSi);
    }
    if (!nullToAbsent || confusedWithLabelTa != null) {
      map['confused_with_label_ta'] = Variable<String>(confusedWithLabelTa);
    }
    if (!nullToAbsent || distinguishingSymptomsEn != null) {
      map['distinguishing_symptoms_en'] = Variable<String>(
        distinguishingSymptomsEn,
      );
    }
    if (!nullToAbsent || distinguishingSymptomsSi != null) {
      map['distinguishing_symptoms_si'] = Variable<String>(
        distinguishingSymptomsSi,
      );
    }
    if (!nullToAbsent || distinguishingSymptomsTa != null) {
      map['distinguishing_symptoms_ta'] = Variable<String>(
        distinguishingSymptomsTa,
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DiseaseConfusionTableCompanion toCompanion(bool nullToAbsent) {
    return DiseaseConfusionTableCompanion(
      id: Value(id),
      diseaseId: Value(diseaseId),
      confusedWithDiseaseId: confusedWithDiseaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(confusedWithDiseaseId),
      confusedWithLabelEn: confusedWithLabelEn == null && nullToAbsent
          ? const Value.absent()
          : Value(confusedWithLabelEn),
      confusedWithLabelSi: confusedWithLabelSi == null && nullToAbsent
          ? const Value.absent()
          : Value(confusedWithLabelSi),
      confusedWithLabelTa: confusedWithLabelTa == null && nullToAbsent
          ? const Value.absent()
          : Value(confusedWithLabelTa),
      distinguishingSymptomsEn: distinguishingSymptomsEn == null && nullToAbsent
          ? const Value.absent()
          : Value(distinguishingSymptomsEn),
      distinguishingSymptomsSi: distinguishingSymptomsSi == null && nullToAbsent
          ? const Value.absent()
          : Value(distinguishingSymptomsSi),
      distinguishingSymptomsTa: distinguishingSymptomsTa == null && nullToAbsent
          ? const Value.absent()
          : Value(distinguishingSymptomsTa),
      sortOrder: Value(sortOrder),
    );
  }

  factory DiseaseConfusionTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiseaseConfusionTableData(
      id: serializer.fromJson<String>(json['id']),
      diseaseId: serializer.fromJson<String>(json['diseaseId']),
      confusedWithDiseaseId: serializer.fromJson<String?>(
        json['confusedWithDiseaseId'],
      ),
      confusedWithLabelEn: serializer.fromJson<String?>(
        json['confusedWithLabelEn'],
      ),
      confusedWithLabelSi: serializer.fromJson<String?>(
        json['confusedWithLabelSi'],
      ),
      confusedWithLabelTa: serializer.fromJson<String?>(
        json['confusedWithLabelTa'],
      ),
      distinguishingSymptomsEn: serializer.fromJson<String?>(
        json['distinguishingSymptomsEn'],
      ),
      distinguishingSymptomsSi: serializer.fromJson<String?>(
        json['distinguishingSymptomsSi'],
      ),
      distinguishingSymptomsTa: serializer.fromJson<String?>(
        json['distinguishingSymptomsTa'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diseaseId': serializer.toJson<String>(diseaseId),
      'confusedWithDiseaseId': serializer.toJson<String?>(
        confusedWithDiseaseId,
      ),
      'confusedWithLabelEn': serializer.toJson<String?>(confusedWithLabelEn),
      'confusedWithLabelSi': serializer.toJson<String?>(confusedWithLabelSi),
      'confusedWithLabelTa': serializer.toJson<String?>(confusedWithLabelTa),
      'distinguishingSymptomsEn': serializer.toJson<String?>(
        distinguishingSymptomsEn,
      ),
      'distinguishingSymptomsSi': serializer.toJson<String?>(
        distinguishingSymptomsSi,
      ),
      'distinguishingSymptomsTa': serializer.toJson<String?>(
        distinguishingSymptomsTa,
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DiseaseConfusionTableData copyWith({
    String? id,
    String? diseaseId,
    Value<String?> confusedWithDiseaseId = const Value.absent(),
    Value<String?> confusedWithLabelEn = const Value.absent(),
    Value<String?> confusedWithLabelSi = const Value.absent(),
    Value<String?> confusedWithLabelTa = const Value.absent(),
    Value<String?> distinguishingSymptomsEn = const Value.absent(),
    Value<String?> distinguishingSymptomsSi = const Value.absent(),
    Value<String?> distinguishingSymptomsTa = const Value.absent(),
    int? sortOrder,
  }) => DiseaseConfusionTableData(
    id: id ?? this.id,
    diseaseId: diseaseId ?? this.diseaseId,
    confusedWithDiseaseId: confusedWithDiseaseId.present
        ? confusedWithDiseaseId.value
        : this.confusedWithDiseaseId,
    confusedWithLabelEn: confusedWithLabelEn.present
        ? confusedWithLabelEn.value
        : this.confusedWithLabelEn,
    confusedWithLabelSi: confusedWithLabelSi.present
        ? confusedWithLabelSi.value
        : this.confusedWithLabelSi,
    confusedWithLabelTa: confusedWithLabelTa.present
        ? confusedWithLabelTa.value
        : this.confusedWithLabelTa,
    distinguishingSymptomsEn: distinguishingSymptomsEn.present
        ? distinguishingSymptomsEn.value
        : this.distinguishingSymptomsEn,
    distinguishingSymptomsSi: distinguishingSymptomsSi.present
        ? distinguishingSymptomsSi.value
        : this.distinguishingSymptomsSi,
    distinguishingSymptomsTa: distinguishingSymptomsTa.present
        ? distinguishingSymptomsTa.value
        : this.distinguishingSymptomsTa,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DiseaseConfusionTableData copyWithCompanion(
    DiseaseConfusionTableCompanion data,
  ) {
    return DiseaseConfusionTableData(
      id: data.id.present ? data.id.value : this.id,
      diseaseId: data.diseaseId.present ? data.diseaseId.value : this.diseaseId,
      confusedWithDiseaseId: data.confusedWithDiseaseId.present
          ? data.confusedWithDiseaseId.value
          : this.confusedWithDiseaseId,
      confusedWithLabelEn: data.confusedWithLabelEn.present
          ? data.confusedWithLabelEn.value
          : this.confusedWithLabelEn,
      confusedWithLabelSi: data.confusedWithLabelSi.present
          ? data.confusedWithLabelSi.value
          : this.confusedWithLabelSi,
      confusedWithLabelTa: data.confusedWithLabelTa.present
          ? data.confusedWithLabelTa.value
          : this.confusedWithLabelTa,
      distinguishingSymptomsEn: data.distinguishingSymptomsEn.present
          ? data.distinguishingSymptomsEn.value
          : this.distinguishingSymptomsEn,
      distinguishingSymptomsSi: data.distinguishingSymptomsSi.present
          ? data.distinguishingSymptomsSi.value
          : this.distinguishingSymptomsSi,
      distinguishingSymptomsTa: data.distinguishingSymptomsTa.present
          ? data.distinguishingSymptomsTa.value
          : this.distinguishingSymptomsTa,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseConfusionTableData(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('confusedWithDiseaseId: $confusedWithDiseaseId, ')
          ..write('confusedWithLabelEn: $confusedWithLabelEn, ')
          ..write('confusedWithLabelSi: $confusedWithLabelSi, ')
          ..write('confusedWithLabelTa: $confusedWithLabelTa, ')
          ..write('distinguishingSymptomsEn: $distinguishingSymptomsEn, ')
          ..write('distinguishingSymptomsSi: $distinguishingSymptomsSi, ')
          ..write('distinguishingSymptomsTa: $distinguishingSymptomsTa, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diseaseId,
    confusedWithDiseaseId,
    confusedWithLabelEn,
    confusedWithLabelSi,
    confusedWithLabelTa,
    distinguishingSymptomsEn,
    distinguishingSymptomsSi,
    distinguishingSymptomsTa,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiseaseConfusionTableData &&
          other.id == this.id &&
          other.diseaseId == this.diseaseId &&
          other.confusedWithDiseaseId == this.confusedWithDiseaseId &&
          other.confusedWithLabelEn == this.confusedWithLabelEn &&
          other.confusedWithLabelSi == this.confusedWithLabelSi &&
          other.confusedWithLabelTa == this.confusedWithLabelTa &&
          other.distinguishingSymptomsEn == this.distinguishingSymptomsEn &&
          other.distinguishingSymptomsSi == this.distinguishingSymptomsSi &&
          other.distinguishingSymptomsTa == this.distinguishingSymptomsTa &&
          other.sortOrder == this.sortOrder);
}

class DiseaseConfusionTableCompanion
    extends UpdateCompanion<DiseaseConfusionTableData> {
  final Value<String> id;
  final Value<String> diseaseId;
  final Value<String?> confusedWithDiseaseId;
  final Value<String?> confusedWithLabelEn;
  final Value<String?> confusedWithLabelSi;
  final Value<String?> confusedWithLabelTa;
  final Value<String?> distinguishingSymptomsEn;
  final Value<String?> distinguishingSymptomsSi;
  final Value<String?> distinguishingSymptomsTa;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DiseaseConfusionTableCompanion({
    this.id = const Value.absent(),
    this.diseaseId = const Value.absent(),
    this.confusedWithDiseaseId = const Value.absent(),
    this.confusedWithLabelEn = const Value.absent(),
    this.confusedWithLabelSi = const Value.absent(),
    this.confusedWithLabelTa = const Value.absent(),
    this.distinguishingSymptomsEn = const Value.absent(),
    this.distinguishingSymptomsSi = const Value.absent(),
    this.distinguishingSymptomsTa = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiseaseConfusionTableCompanion.insert({
    required String id,
    required String diseaseId,
    this.confusedWithDiseaseId = const Value.absent(),
    this.confusedWithLabelEn = const Value.absent(),
    this.confusedWithLabelSi = const Value.absent(),
    this.confusedWithLabelTa = const Value.absent(),
    this.distinguishingSymptomsEn = const Value.absent(),
    this.distinguishingSymptomsSi = const Value.absent(),
    this.distinguishingSymptomsTa = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diseaseId = Value(diseaseId);
  static Insertable<DiseaseConfusionTableData> custom({
    Expression<String>? id,
    Expression<String>? diseaseId,
    Expression<String>? confusedWithDiseaseId,
    Expression<String>? confusedWithLabelEn,
    Expression<String>? confusedWithLabelSi,
    Expression<String>? confusedWithLabelTa,
    Expression<String>? distinguishingSymptomsEn,
    Expression<String>? distinguishingSymptomsSi,
    Expression<String>? distinguishingSymptomsTa,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diseaseId != null) 'disease_id': diseaseId,
      if (confusedWithDiseaseId != null)
        'confused_with_disease_id': confusedWithDiseaseId,
      if (confusedWithLabelEn != null)
        'confused_with_label_en': confusedWithLabelEn,
      if (confusedWithLabelSi != null)
        'confused_with_label_si': confusedWithLabelSi,
      if (confusedWithLabelTa != null)
        'confused_with_label_ta': confusedWithLabelTa,
      if (distinguishingSymptomsEn != null)
        'distinguishing_symptoms_en': distinguishingSymptomsEn,
      if (distinguishingSymptomsSi != null)
        'distinguishing_symptoms_si': distinguishingSymptomsSi,
      if (distinguishingSymptomsTa != null)
        'distinguishing_symptoms_ta': distinguishingSymptomsTa,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiseaseConfusionTableCompanion copyWith({
    Value<String>? id,
    Value<String>? diseaseId,
    Value<String?>? confusedWithDiseaseId,
    Value<String?>? confusedWithLabelEn,
    Value<String?>? confusedWithLabelSi,
    Value<String?>? confusedWithLabelTa,
    Value<String?>? distinguishingSymptomsEn,
    Value<String?>? distinguishingSymptomsSi,
    Value<String?>? distinguishingSymptomsTa,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DiseaseConfusionTableCompanion(
      id: id ?? this.id,
      diseaseId: diseaseId ?? this.diseaseId,
      confusedWithDiseaseId:
          confusedWithDiseaseId ?? this.confusedWithDiseaseId,
      confusedWithLabelEn: confusedWithLabelEn ?? this.confusedWithLabelEn,
      confusedWithLabelSi: confusedWithLabelSi ?? this.confusedWithLabelSi,
      confusedWithLabelTa: confusedWithLabelTa ?? this.confusedWithLabelTa,
      distinguishingSymptomsEn:
          distinguishingSymptomsEn ?? this.distinguishingSymptomsEn,
      distinguishingSymptomsSi:
          distinguishingSymptomsSi ?? this.distinguishingSymptomsSi,
      distinguishingSymptomsTa:
          distinguishingSymptomsTa ?? this.distinguishingSymptomsTa,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diseaseId.present) {
      map['disease_id'] = Variable<String>(diseaseId.value);
    }
    if (confusedWithDiseaseId.present) {
      map['confused_with_disease_id'] = Variable<String>(
        confusedWithDiseaseId.value,
      );
    }
    if (confusedWithLabelEn.present) {
      map['confused_with_label_en'] = Variable<String>(
        confusedWithLabelEn.value,
      );
    }
    if (confusedWithLabelSi.present) {
      map['confused_with_label_si'] = Variable<String>(
        confusedWithLabelSi.value,
      );
    }
    if (confusedWithLabelTa.present) {
      map['confused_with_label_ta'] = Variable<String>(
        confusedWithLabelTa.value,
      );
    }
    if (distinguishingSymptomsEn.present) {
      map['distinguishing_symptoms_en'] = Variable<String>(
        distinguishingSymptomsEn.value,
      );
    }
    if (distinguishingSymptomsSi.present) {
      map['distinguishing_symptoms_si'] = Variable<String>(
        distinguishingSymptomsSi.value,
      );
    }
    if (distinguishingSymptomsTa.present) {
      map['distinguishing_symptoms_ta'] = Variable<String>(
        distinguishingSymptomsTa.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiseaseConfusionTableCompanion(')
          ..write('id: $id, ')
          ..write('diseaseId: $diseaseId, ')
          ..write('confusedWithDiseaseId: $confusedWithDiseaseId, ')
          ..write('confusedWithLabelEn: $confusedWithLabelEn, ')
          ..write('confusedWithLabelSi: $confusedWithLabelSi, ')
          ..write('confusedWithLabelTa: $confusedWithLabelTa, ')
          ..write('distinguishingSymptomsEn: $distinguishingSymptomsEn, ')
          ..write('distinguishingSymptomsSi: $distinguishingSymptomsSi, ')
          ..write('distinguishingSymptomsTa: $distinguishingSymptomsTa, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessageTableTable extends ChatMessageTable
    with TableInfo<$ChatMessageTableTable, ChatMessageTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessageTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diagnosisIdMeta = const VerificationMeta(
    'diagnosisId',
  );
  @override
  late final GeneratedColumn<String> diagnosisId = GeneratedColumn<String>(
    'diagnosis_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diagnosis (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SENT'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diagnosisId,
    role,
    content,
    languageCode,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_message';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('diagnosis_id')) {
      context.handle(
        _diagnosisIdMeta,
        diagnosisId.isAcceptableOrUnknown(
          data['diagnosis_id']!,
          _diagnosisIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diagnosisIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diagnosisId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessageTableTable createAlias(String alias) {
    return $ChatMessageTableTable(attachedDatabase, alias);
  }
}

class ChatMessageTableData extends DataClass
    implements Insertable<ChatMessageTableData> {
  final String id;
  final String diagnosisId;

  /// 'USER' | 'ASSISTANT'
  final String role;
  final String content;

  /// The language the exchange happened in. Kept per message because a farmer
  /// can change language mid-conversation, and a Sinhala answer rendered under
  /// a Tamil heading is worse than one that says which language it is in.
  final String languageCode;

  /// 'PENDING' | 'SENT' | 'FAILED'
  ///
  /// Only ever non-SENT on a USER message: a question typed with no signal is
  /// kept and marked, so it is visibly still there rather than silently lost.
  final String status;
  final String createdAt;
  const ChatMessageTableData({
    required this.id,
    required this.diagnosisId,
    required this.role,
    required this.content,
    required this.languageCode,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['diagnosis_id'] = Variable<String>(diagnosisId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['language_code'] = Variable<String>(languageCode);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ChatMessageTableCompanion toCompanion(bool nullToAbsent) {
    return ChatMessageTableCompanion(
      id: Value(id),
      diagnosisId: Value(diagnosisId),
      role: Value(role),
      content: Value(content),
      languageCode: Value(languageCode),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageTableData(
      id: serializer.fromJson<String>(json['id']),
      diagnosisId: serializer.fromJson<String>(json['diagnosisId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diagnosisId': serializer.toJson<String>(diagnosisId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'languageCode': serializer.toJson<String>(languageCode),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ChatMessageTableData copyWith({
    String? id,
    String? diagnosisId,
    String? role,
    String? content,
    String? languageCode,
    String? status,
    String? createdAt,
  }) => ChatMessageTableData(
    id: id ?? this.id,
    diagnosisId: diagnosisId ?? this.diagnosisId,
    role: role ?? this.role,
    content: content ?? this.content,
    languageCode: languageCode ?? this.languageCode,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageTableData copyWithCompanion(ChatMessageTableCompanion data) {
    return ChatMessageTableData(
      id: data.id.present ? data.id.value : this.id,
      diagnosisId: data.diagnosisId.present
          ? data.diagnosisId.value
          : this.diagnosisId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageTableData(')
          ..write('id: $id, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('languageCode: $languageCode, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diagnosisId,
    role,
    content,
    languageCode,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageTableData &&
          other.id == this.id &&
          other.diagnosisId == this.diagnosisId &&
          other.role == this.role &&
          other.content == this.content &&
          other.languageCode == this.languageCode &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class ChatMessageTableCompanion extends UpdateCompanion<ChatMessageTableData> {
  final Value<String> id;
  final Value<String> diagnosisId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> languageCode;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ChatMessageTableCompanion({
    this.id = const Value.absent(),
    this.diagnosisId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessageTableCompanion.insert({
    required String id,
    required String diagnosisId,
    required String role,
    required String content,
    required String languageCode,
    this.status = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diagnosisId = Value(diagnosisId),
       role = Value(role),
       content = Value(content),
       languageCode = Value(languageCode),
       createdAt = Value(createdAt);
  static Insertable<ChatMessageTableData> custom({
    Expression<String>? id,
    Expression<String>? diagnosisId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? languageCode,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diagnosisId != null) 'diagnosis_id': diagnosisId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (languageCode != null) 'language_code': languageCode,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessageTableCompanion copyWith({
    Value<String>? id,
    Value<String>? diagnosisId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? languageCode,
    Value<String>? status,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessageTableCompanion(
      id: id ?? this.id,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      role: role ?? this.role,
      content: content ?? this.content,
      languageCode: languageCode ?? this.languageCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diagnosisId.present) {
      map['diagnosis_id'] = Variable<String>(diagnosisId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageTableCompanion(')
          ..write('id: $id, ')
          ..write('diagnosisId: $diagnosisId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('languageCode: $languageCode, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppStateTableTable appStateTable = $AppStateTableTable(this);
  late final $LocalUserTableTable localUserTable = $LocalUserTableTable(this);
  late final $CropTableTable cropTable = $CropTableTable(this);
  late final $DiseaseTableTable diseaseTable = $DiseaseTableTable(this);
  late final $TreatmentGuidelineTableTable treatmentGuidelineTable =
      $TreatmentGuidelineTableTable(this);
  late final $ModelVersionTableTable modelVersionTable =
      $ModelVersionTableTable(this);
  late final $ScanTableTable scanTable = $ScanTableTable(this);
  late final $ImageValidationTableTable imageValidationTable =
      $ImageValidationTableTable(this);
  late final $DiagnosisTableTable diagnosisTable = $DiagnosisTableTable(this);
  late final $EscalationTableTable escalationTable = $EscalationTableTable(
    this,
  );
  late final $SyncOperationTableTable syncOperationTable =
      $SyncOperationTableTable(this);
  late final $DiseaseExplanationTableTable diseaseExplanationTable =
      $DiseaseExplanationTableTable(this);
  late final $DiseaseConfusionTableTable diseaseConfusionTable =
      $DiseaseConfusionTableTable(this);
  late final $ChatMessageTableTable chatMessageTable = $ChatMessageTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appStateTable,
    localUserTable,
    cropTable,
    diseaseTable,
    treatmentGuidelineTable,
    modelVersionTable,
    scanTable,
    imageValidationTable,
    diagnosisTable,
    escalationTable,
    syncOperationTable,
    diseaseExplanationTable,
    diseaseConfusionTable,
    chatMessageTable,
  ];
}

typedef $$AppStateTableTableCreateCompanionBuilder =
    AppStateTableCompanion Function({
      Value<int> id,
      Value<int> onboardingCompleted,
      Value<String> languageCode,
      Value<String?> firstLaunchAt,
      Value<String?> lastSyncAt,
      Value<String?> syncLockedAt,
    });
typedef $$AppStateTableTableUpdateCompanionBuilder =
    AppStateTableCompanion Function({
      Value<int> id,
      Value<int> onboardingCompleted,
      Value<String> languageCode,
      Value<String?> firstLaunchAt,
      Value<String?> lastSyncAt,
      Value<String?> syncLockedAt,
    });

class $$AppStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTableTable> {
  $$AppStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstLaunchAt => $composableBuilder(
    column: $table.firstLaunchAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncLockedAt => $composableBuilder(
    column: $table.syncLockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTableTable> {
  $$AppStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstLaunchAt => $composableBuilder(
    column: $table.firstLaunchAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncLockedAt => $composableBuilder(
    column: $table.syncLockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTableTable> {
  $$AppStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstLaunchAt => $composableBuilder(
    column: $table.firstLaunchAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncLockedAt => $composableBuilder(
    column: $table.syncLockedAt,
    builder: (column) => column,
  );
}

class $$AppStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppStateTableTable,
          AppStateTableData,
          $$AppStateTableTableFilterComposer,
          $$AppStateTableTableOrderingComposer,
          $$AppStateTableTableAnnotationComposer,
          $$AppStateTableTableCreateCompanionBuilder,
          $$AppStateTableTableUpdateCompanionBuilder,
          (
            AppStateTableData,
            BaseReferences<
              _$AppDatabase,
              $AppStateTableTable,
              AppStateTableData
            >,
          ),
          AppStateTableData,
          PrefetchHooks Function()
        > {
  $$AppStateTableTableTableManager(_$AppDatabase db, $AppStateTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> onboardingCompleted = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String?> firstLaunchAt = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<String?> syncLockedAt = const Value.absent(),
              }) => AppStateTableCompanion(
                id: id,
                onboardingCompleted: onboardingCompleted,
                languageCode: languageCode,
                firstLaunchAt: firstLaunchAt,
                lastSyncAt: lastSyncAt,
                syncLockedAt: syncLockedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> onboardingCompleted = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String?> firstLaunchAt = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<String?> syncLockedAt = const Value.absent(),
              }) => AppStateTableCompanion.insert(
                id: id,
                onboardingCompleted: onboardingCompleted,
                languageCode: languageCode,
                firstLaunchAt: firstLaunchAt,
                lastSyncAt: lastSyncAt,
                syncLockedAt: syncLockedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppStateTableTable,
      AppStateTableData,
      $$AppStateTableTableFilterComposer,
      $$AppStateTableTableOrderingComposer,
      $$AppStateTableTableAnnotationComposer,
      $$AppStateTableTableCreateCompanionBuilder,
      $$AppStateTableTableUpdateCompanionBuilder,
      (
        AppStateTableData,
        BaseReferences<_$AppDatabase, $AppStateTableTable, AppStateTableData>,
      ),
      AppStateTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalUserTableTableCreateCompanionBuilder =
    LocalUserTableCompanion Function({
      required String id,
      Value<String?> remoteUserId,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<int> isGuest,
      Value<String?> sessionToken,
      Value<String?> sessionRefreshToken,
      Value<String?> sessionExpiresAt,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$LocalUserTableTableUpdateCompanionBuilder =
    LocalUserTableCompanion Function({
      Value<String> id,
      Value<String?> remoteUserId,
      Value<String?> email,
      Value<String?> phoneNumber,
      Value<int> isGuest,
      Value<String?> sessionToken,
      Value<String?> sessionRefreshToken,
      Value<String?> sessionExpiresAt,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$LocalUserTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalUserTableTable,
          LocalUserTableData
        > {
  $$LocalUserTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ScanTableTable, List<ScanTableData>>
  _scanTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanTable,
    aliasName: 'local_user__id__scan__user_id',
  );

  $$ScanTableTableProcessedTableManager get scanTableRefs {
    final manager = $$ScanTableTableTableManager(
      $_db,
      $_db.scanTable,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalUserTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalUserTableTable> {
  $$LocalUserTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUserId => $composableBuilder(
    column: $table.remoteUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isGuest => $composableBuilder(
    column: $table.isGuest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionToken => $composableBuilder(
    column: $table.sessionToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionRefreshToken => $composableBuilder(
    column: $table.sessionRefreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionExpiresAt => $composableBuilder(
    column: $table.sessionExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scanTableRefs(
    Expression<bool> Function($$ScanTableTableFilterComposer f) f,
  ) {
    final $$ScanTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableFilterComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalUserTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalUserTableTable> {
  $$LocalUserTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUserId => $composableBuilder(
    column: $table.remoteUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isGuest => $composableBuilder(
    column: $table.isGuest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionToken => $composableBuilder(
    column: $table.sessionToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionRefreshToken => $composableBuilder(
    column: $table.sessionRefreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionExpiresAt => $composableBuilder(
    column: $table.sessionExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalUserTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalUserTableTable> {
  $$LocalUserTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteUserId => $composableBuilder(
    column: $table.remoteUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isGuest =>
      $composableBuilder(column: $table.isGuest, builder: (column) => column);

  GeneratedColumn<String> get sessionToken => $composableBuilder(
    column: $table.sessionToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionRefreshToken => $composableBuilder(
    column: $table.sessionRefreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionExpiresAt => $composableBuilder(
    column: $table.sessionExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> scanTableRefs<T extends Object>(
    Expression<T> Function($$ScanTableTableAnnotationComposer a) f,
  ) {
    final $$ScanTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalUserTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalUserTableTable,
          LocalUserTableData,
          $$LocalUserTableTableFilterComposer,
          $$LocalUserTableTableOrderingComposer,
          $$LocalUserTableTableAnnotationComposer,
          $$LocalUserTableTableCreateCompanionBuilder,
          $$LocalUserTableTableUpdateCompanionBuilder,
          (LocalUserTableData, $$LocalUserTableTableReferences),
          LocalUserTableData,
          PrefetchHooks Function({bool scanTableRefs})
        > {
  $$LocalUserTableTableTableManager(
    _$AppDatabase db,
    $LocalUserTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUserTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUserTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUserTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<int> isGuest = const Value.absent(),
                Value<String?> sessionToken = const Value.absent(),
                Value<String?> sessionRefreshToken = const Value.absent(),
                Value<String?> sessionExpiresAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalUserTableCompanion(
                id: id,
                remoteUserId: remoteUserId,
                email: email,
                phoneNumber: phoneNumber,
                isGuest: isGuest,
                sessionToken: sessionToken,
                sessionRefreshToken: sessionRefreshToken,
                sessionExpiresAt: sessionExpiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteUserId = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<int> isGuest = const Value.absent(),
                Value<String?> sessionToken = const Value.absent(),
                Value<String?> sessionRefreshToken = const Value.absent(),
                Value<String?> sessionExpiresAt = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalUserTableCompanion.insert(
                id: id,
                remoteUserId: remoteUserId,
                email: email,
                phoneNumber: phoneNumber,
                isGuest: isGuest,
                sessionToken: sessionToken,
                sessionRefreshToken: sessionRefreshToken,
                sessionExpiresAt: sessionExpiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalUserTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (scanTableRefs) db.scanTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scanTableRefs)
                    await $_getPrefetchedData<
                      LocalUserTableData,
                      $LocalUserTableTable,
                      ScanTableData
                    >(
                      currentTable: table,
                      referencedTable: $$LocalUserTableTableReferences
                          ._scanTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalUserTableTableReferences(
                            db,
                            table,
                            p0,
                          ).scanTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalUserTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalUserTableTable,
      LocalUserTableData,
      $$LocalUserTableTableFilterComposer,
      $$LocalUserTableTableOrderingComposer,
      $$LocalUserTableTableAnnotationComposer,
      $$LocalUserTableTableCreateCompanionBuilder,
      $$LocalUserTableTableUpdateCompanionBuilder,
      (LocalUserTableData, $$LocalUserTableTableReferences),
      LocalUserTableData,
      PrefetchHooks Function({bool scanTableRefs})
    >;
typedef $$CropTableTableCreateCompanionBuilder =
    CropTableCompanion Function({
      required String id,
      required String nameEn,
      Value<String?> nameSi,
      Value<String?> nameTa,
      Value<int> isSupported,
      Value<String?> iconAsset,
      Value<int> rowid,
    });
typedef $$CropTableTableUpdateCompanionBuilder =
    CropTableCompanion Function({
      Value<String> id,
      Value<String> nameEn,
      Value<String?> nameSi,
      Value<String?> nameTa,
      Value<int> isSupported,
      Value<String?> iconAsset,
      Value<int> rowid,
    });

final class $$CropTableTableReferences
    extends BaseReferences<_$AppDatabase, $CropTableTable, CropTableData> {
  $$CropTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiseaseTableTable, List<DiseaseTableData>>
  _diseaseTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diseaseTable,
    aliasName: 'crop__id__disease__crop_id',
  );

  $$DiseaseTableTableProcessedTableManager get diseaseTableRefs {
    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diseaseTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScanTableTable, List<ScanTableData>>
  _scanTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scanTable,
    aliasName: 'crop__id__scan__crop_id',
  );

  $$ScanTableTableProcessedTableManager get scanTableRefs {
    final manager = $$ScanTableTableTableManager(
      $_db,
      $_db.scanTable,
    ).filter((f) => f.cropId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CropTableTableFilterComposer
    extends Composer<_$AppDatabase, $CropTableTable> {
  $$CropTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSi => $composableBuilder(
    column: $table.nameSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameTa => $composableBuilder(
    column: $table.nameTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isSupported => $composableBuilder(
    column: $table.isSupported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> diseaseTableRefs(
    Expression<bool> Function($$DiseaseTableTableFilterComposer f) f,
  ) {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scanTableRefs(
    Expression<bool> Function($$ScanTableTableFilterComposer f) f,
  ) {
    final $$ScanTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableFilterComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CropTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CropTableTable> {
  $$CropTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSi => $composableBuilder(
    column: $table.nameSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameTa => $composableBuilder(
    column: $table.nameTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isSupported => $composableBuilder(
    column: $table.isSupported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CropTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropTableTable> {
  $$CropTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameSi =>
      $composableBuilder(column: $table.nameSi, builder: (column) => column);

  GeneratedColumn<String> get nameTa =>
      $composableBuilder(column: $table.nameTa, builder: (column) => column);

  GeneratedColumn<int> get isSupported => $composableBuilder(
    column: $table.isSupported,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconAsset =>
      $composableBuilder(column: $table.iconAsset, builder: (column) => column);

  Expression<T> diseaseTableRefs<T extends Object>(
    Expression<T> Function($$DiseaseTableTableAnnotationComposer a) f,
  ) {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scanTableRefs<T extends Object>(
    Expression<T> Function($$ScanTableTableAnnotationComposer a) f,
  ) {
    final $$ScanTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.cropId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CropTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CropTableTable,
          CropTableData,
          $$CropTableTableFilterComposer,
          $$CropTableTableOrderingComposer,
          $$CropTableTableAnnotationComposer,
          $$CropTableTableCreateCompanionBuilder,
          $$CropTableTableUpdateCompanionBuilder,
          (CropTableData, $$CropTableTableReferences),
          CropTableData,
          PrefetchHooks Function({bool diseaseTableRefs, bool scanTableRefs})
        > {
  $$CropTableTableTableManager(_$AppDatabase db, $CropTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CropTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String?> nameSi = const Value.absent(),
                Value<String?> nameTa = const Value.absent(),
                Value<int> isSupported = const Value.absent(),
                Value<String?> iconAsset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CropTableCompanion(
                id: id,
                nameEn: nameEn,
                nameSi: nameSi,
                nameTa: nameTa,
                isSupported: isSupported,
                iconAsset: iconAsset,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nameEn,
                Value<String?> nameSi = const Value.absent(),
                Value<String?> nameTa = const Value.absent(),
                Value<int> isSupported = const Value.absent(),
                Value<String?> iconAsset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CropTableCompanion.insert(
                id: id,
                nameEn: nameEn,
                nameSi: nameSi,
                nameTa: nameTa,
                isSupported: isSupported,
                iconAsset: iconAsset,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CropTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({diseaseTableRefs = false, scanTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diseaseTableRefs) db.diseaseTable,
                    if (scanTableRefs) db.scanTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diseaseTableRefs)
                        await $_getPrefetchedData<
                          CropTableData,
                          $CropTableTable,
                          DiseaseTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CropTableTableReferences
                              ._diseaseTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CropTableTableReferences(
                                db,
                                table,
                                p0,
                              ).diseaseTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cropId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scanTableRefs)
                        await $_getPrefetchedData<
                          CropTableData,
                          $CropTableTable,
                          ScanTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CropTableTableReferences
                              ._scanTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CropTableTableReferences(
                                db,
                                table,
                                p0,
                              ).scanTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cropId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CropTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CropTableTable,
      CropTableData,
      $$CropTableTableFilterComposer,
      $$CropTableTableOrderingComposer,
      $$CropTableTableAnnotationComposer,
      $$CropTableTableCreateCompanionBuilder,
      $$CropTableTableUpdateCompanionBuilder,
      (CropTableData, $$CropTableTableReferences),
      CropTableData,
      PrefetchHooks Function({bool diseaseTableRefs, bool scanTableRefs})
    >;
typedef $$DiseaseTableTableCreateCompanionBuilder =
    DiseaseTableCompanion Function({
      required String id,
      required String cropId,
      required String nameEn,
      Value<String?> nameSi,
      Value<String?> nameTa,
      Value<String?> severityDefault,
      Value<int> rowid,
    });
typedef $$DiseaseTableTableUpdateCompanionBuilder =
    DiseaseTableCompanion Function({
      Value<String> id,
      Value<String> cropId,
      Value<String> nameEn,
      Value<String?> nameSi,
      Value<String?> nameTa,
      Value<String?> severityDefault,
      Value<int> rowid,
    });

final class $$DiseaseTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $DiseaseTableTable, DiseaseTableData> {
  $$DiseaseTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CropTableTable _cropIdTable(_$AppDatabase db) =>
      db.cropTable.createAlias('disease__crop_id__crop__id');

  $$CropTableTableProcessedTableManager get cropId {
    final $_column = $_itemColumn<String>('crop_id')!;

    final manager = $$CropTableTableTableManager(
      $_db,
      $_db.cropTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TreatmentGuidelineTableTable,
    List<TreatmentGuidelineTableData>
  >
  _treatmentGuidelineTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.treatmentGuidelineTable,
        aliasName: 'disease__id__treatment_guideline__disease_id',
      );

  $$TreatmentGuidelineTableTableProcessedTableManager
  get treatmentGuidelineTableRefs {
    final manager = $$TreatmentGuidelineTableTableTableManager(
      $_db,
      $_db.treatmentGuidelineTable,
    ).filter((f) => f.diseaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _treatmentGuidelineTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiagnosisTableTable, List<DiagnosisTableData>>
  _diagnosisTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnosisTable,
    aliasName: 'disease__id__diagnosis__disease_id',
  );

  $$DiagnosisTableTableProcessedTableManager get diagnosisTableRefs {
    final manager = $$DiagnosisTableTableTableManager(
      $_db,
      $_db.diagnosisTable,
    ).filter((f) => f.diseaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diagnosisTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DiseaseExplanationTableTable,
    List<DiseaseExplanationTableData>
  >
  _diseaseExplanationTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.diseaseExplanationTable,
        aliasName: 'disease__id__disease_explanation__disease_id',
      );

  $$DiseaseExplanationTableTableProcessedTableManager
  get diseaseExplanationTableRefs {
    final manager = $$DiseaseExplanationTableTableTableManager(
      $_db,
      $_db.diseaseExplanationTable,
    ).filter((f) => f.diseaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _diseaseExplanationTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DiseaseConfusionTableTable,
    List<DiseaseConfusionTableData>
  >
  _confusionsForDiseaseTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diseaseConfusionTable,
    aliasName: 'disease__id__disease_confusion__disease_id',
  );

  $$DiseaseConfusionTableTableProcessedTableManager get confusionsForDisease {
    final manager = $$DiseaseConfusionTableTableTableManager(
      $_db,
      $_db.diseaseConfusionTable,
    ).filter((f) => f.diseaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _confusionsForDiseaseTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DiseaseConfusionTableTable,
    List<DiseaseConfusionTableData>
  >
  _confusionsNamingDiseaseTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.diseaseConfusionTable,
        aliasName: 'disease__id__disease_confusion__confused_with_disease_id',
      );

  $$DiseaseConfusionTableTableProcessedTableManager
  get confusionsNamingDisease {
    final manager =
        $$DiseaseConfusionTableTableTableManager(
          $_db,
          $_db.diseaseConfusionTable,
        ).filter(
          (f) =>
              f.confusedWithDiseaseId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _confusionsNamingDiseaseTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiseaseTableTableFilterComposer
    extends Composer<_$AppDatabase, $DiseaseTableTable> {
  $$DiseaseTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSi => $composableBuilder(
    column: $table.nameSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameTa => $composableBuilder(
    column: $table.nameTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severityDefault => $composableBuilder(
    column: $table.severityDefault,
    builder: (column) => ColumnFilters(column),
  );

  $$CropTableTableFilterComposer get cropId {
    final $$CropTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableFilterComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> treatmentGuidelineTableRefs(
    Expression<bool> Function($$TreatmentGuidelineTableTableFilterComposer f) f,
  ) {
    final $$TreatmentGuidelineTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.treatmentGuidelineTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TreatmentGuidelineTableTableFilterComposer(
                $db: $db,
                $table: $db.treatmentGuidelineTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> diagnosisTableRefs(
    Expression<bool> Function($$DiagnosisTableTableFilterComposer f) f,
  ) {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.diseaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diseaseExplanationTableRefs(
    Expression<bool> Function($$DiseaseExplanationTableTableFilterComposer f) f,
  ) {
    final $$DiseaseExplanationTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseExplanationTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseExplanationTableTableFilterComposer(
                $db: $db,
                $table: $db.diseaseExplanationTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> confusionsForDisease(
    Expression<bool> Function($$DiseaseConfusionTableTableFilterComposer f) f,
  ) {
    final $$DiseaseConfusionTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseConfusionTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseConfusionTableTableFilterComposer(
                $db: $db,
                $table: $db.diseaseConfusionTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> confusionsNamingDisease(
    Expression<bool> Function($$DiseaseConfusionTableTableFilterComposer f) f,
  ) {
    final $$DiseaseConfusionTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseConfusionTable,
          getReferencedColumn: (t) => t.confusedWithDiseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseConfusionTableTableFilterComposer(
                $db: $db,
                $table: $db.diseaseConfusionTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DiseaseTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DiseaseTableTable> {
  $$DiseaseTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSi => $composableBuilder(
    column: $table.nameSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameTa => $composableBuilder(
    column: $table.nameTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severityDefault => $composableBuilder(
    column: $table.severityDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $$CropTableTableOrderingComposer get cropId {
    final $$CropTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableOrderingComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiseaseTableTable> {
  $$DiseaseTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameSi =>
      $composableBuilder(column: $table.nameSi, builder: (column) => column);

  GeneratedColumn<String> get nameTa =>
      $composableBuilder(column: $table.nameTa, builder: (column) => column);

  GeneratedColumn<String> get severityDefault => $composableBuilder(
    column: $table.severityDefault,
    builder: (column) => column,
  );

  $$CropTableTableAnnotationComposer get cropId {
    final $$CropTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableAnnotationComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> treatmentGuidelineTableRefs<T extends Object>(
    Expression<T> Function($$TreatmentGuidelineTableTableAnnotationComposer a)
    f,
  ) {
    final $$TreatmentGuidelineTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.treatmentGuidelineTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TreatmentGuidelineTableTableAnnotationComposer(
                $db: $db,
                $table: $db.treatmentGuidelineTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> diagnosisTableRefs<T extends Object>(
    Expression<T> Function($$DiagnosisTableTableAnnotationComposer a) f,
  ) {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.diseaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diseaseExplanationTableRefs<T extends Object>(
    Expression<T> Function($$DiseaseExplanationTableTableAnnotationComposer a)
    f,
  ) {
    final $$DiseaseExplanationTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseExplanationTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseExplanationTableTableAnnotationComposer(
                $db: $db,
                $table: $db.diseaseExplanationTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> confusionsForDisease<T extends Object>(
    Expression<T> Function($$DiseaseConfusionTableTableAnnotationComposer a) f,
  ) {
    final $$DiseaseConfusionTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseConfusionTable,
          getReferencedColumn: (t) => t.diseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseConfusionTableTableAnnotationComposer(
                $db: $db,
                $table: $db.diseaseConfusionTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> confusionsNamingDisease<T extends Object>(
    Expression<T> Function($$DiseaseConfusionTableTableAnnotationComposer a) f,
  ) {
    final $$DiseaseConfusionTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diseaseConfusionTable,
          getReferencedColumn: (t) => t.confusedWithDiseaseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiseaseConfusionTableTableAnnotationComposer(
                $db: $db,
                $table: $db.diseaseConfusionTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DiseaseTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiseaseTableTable,
          DiseaseTableData,
          $$DiseaseTableTableFilterComposer,
          $$DiseaseTableTableOrderingComposer,
          $$DiseaseTableTableAnnotationComposer,
          $$DiseaseTableTableCreateCompanionBuilder,
          $$DiseaseTableTableUpdateCompanionBuilder,
          (DiseaseTableData, $$DiseaseTableTableReferences),
          DiseaseTableData,
          PrefetchHooks Function({
            bool cropId,
            bool treatmentGuidelineTableRefs,
            bool diagnosisTableRefs,
            bool diseaseExplanationTableRefs,
            bool confusionsForDisease,
            bool confusionsNamingDisease,
          })
        > {
  $$DiseaseTableTableTableManager(_$AppDatabase db, $DiseaseTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiseaseTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiseaseTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiseaseTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cropId = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String?> nameSi = const Value.absent(),
                Value<String?> nameTa = const Value.absent(),
                Value<String?> severityDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseTableCompanion(
                id: id,
                cropId: cropId,
                nameEn: nameEn,
                nameSi: nameSi,
                nameTa: nameTa,
                severityDefault: severityDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cropId,
                required String nameEn,
                Value<String?> nameSi = const Value.absent(),
                Value<String?> nameTa = const Value.absent(),
                Value<String?> severityDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseTableCompanion.insert(
                id: id,
                cropId: cropId,
                nameEn: nameEn,
                nameSi: nameSi,
                nameTa: nameTa,
                severityDefault: severityDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiseaseTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cropId = false,
                treatmentGuidelineTableRefs = false,
                diagnosisTableRefs = false,
                diseaseExplanationTableRefs = false,
                confusionsForDisease = false,
                confusionsNamingDisease = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (treatmentGuidelineTableRefs) db.treatmentGuidelineTable,
                    if (diagnosisTableRefs) db.diagnosisTable,
                    if (diseaseExplanationTableRefs) db.diseaseExplanationTable,
                    if (confusionsForDisease) db.diseaseConfusionTable,
                    if (confusionsNamingDisease) db.diseaseConfusionTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cropId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cropId,
                                    referencedTable:
                                        $$DiseaseTableTableReferences
                                            ._cropIdTable(db),
                                    referencedColumn:
                                        $$DiseaseTableTableReferences
                                            ._cropIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (treatmentGuidelineTableRefs)
                        await $_getPrefetchedData<
                          DiseaseTableData,
                          $DiseaseTableTable,
                          TreatmentGuidelineTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiseaseTableTableReferences
                              ._treatmentGuidelineTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiseaseTableTableReferences(
                                db,
                                table,
                                p0,
                              ).treatmentGuidelineTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diseaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (diagnosisTableRefs)
                        await $_getPrefetchedData<
                          DiseaseTableData,
                          $DiseaseTableTable,
                          DiagnosisTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiseaseTableTableReferences
                              ._diagnosisTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiseaseTableTableReferences(
                                db,
                                table,
                                p0,
                              ).diagnosisTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diseaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (diseaseExplanationTableRefs)
                        await $_getPrefetchedData<
                          DiseaseTableData,
                          $DiseaseTableTable,
                          DiseaseExplanationTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiseaseTableTableReferences
                              ._diseaseExplanationTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiseaseTableTableReferences(
                                db,
                                table,
                                p0,
                              ).diseaseExplanationTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diseaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (confusionsForDisease)
                        await $_getPrefetchedData<
                          DiseaseTableData,
                          $DiseaseTableTable,
                          DiseaseConfusionTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiseaseTableTableReferences
                              ._confusionsForDiseaseTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiseaseTableTableReferences(
                                db,
                                table,
                                p0,
                              ).confusionsForDisease,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diseaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (confusionsNamingDisease)
                        await $_getPrefetchedData<
                          DiseaseTableData,
                          $DiseaseTableTable,
                          DiseaseConfusionTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiseaseTableTableReferences
                              ._confusionsNamingDiseaseTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiseaseTableTableReferences(
                                db,
                                table,
                                p0,
                              ).confusionsNamingDisease,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.confusedWithDiseaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DiseaseTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiseaseTableTable,
      DiseaseTableData,
      $$DiseaseTableTableFilterComposer,
      $$DiseaseTableTableOrderingComposer,
      $$DiseaseTableTableAnnotationComposer,
      $$DiseaseTableTableCreateCompanionBuilder,
      $$DiseaseTableTableUpdateCompanionBuilder,
      (DiseaseTableData, $$DiseaseTableTableReferences),
      DiseaseTableData,
      PrefetchHooks Function({
        bool cropId,
        bool treatmentGuidelineTableRefs,
        bool diagnosisTableRefs,
        bool diseaseExplanationTableRefs,
        bool confusionsForDisease,
        bool confusionsNamingDisease,
      })
    >;
typedef $$TreatmentGuidelineTableTableCreateCompanionBuilder =
    TreatmentGuidelineTableCompanion Function({
      required String id,
      required String diseaseId,
      required String guidelineVersion,
      Value<String?> summaryEn,
      Value<String?> summarySi,
      Value<String?> summaryTa,
      Value<String?> whatToDoEn,
      Value<String?> whatToDoSi,
      Value<String?> whatToDoTa,
      Value<String?> whatToAvoidEn,
      Value<String?> whatToAvoidSi,
      Value<String?> whatToAvoidTa,
      Value<int?> recheckAfterDays,
      Value<String?> publishedAt,
      Value<int> rowid,
    });
typedef $$TreatmentGuidelineTableTableUpdateCompanionBuilder =
    TreatmentGuidelineTableCompanion Function({
      Value<String> id,
      Value<String> diseaseId,
      Value<String> guidelineVersion,
      Value<String?> summaryEn,
      Value<String?> summarySi,
      Value<String?> summaryTa,
      Value<String?> whatToDoEn,
      Value<String?> whatToDoSi,
      Value<String?> whatToDoTa,
      Value<String?> whatToAvoidEn,
      Value<String?> whatToAvoidSi,
      Value<String?> whatToAvoidTa,
      Value<int?> recheckAfterDays,
      Value<String?> publishedAt,
      Value<int> rowid,
    });

final class $$TreatmentGuidelineTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TreatmentGuidelineTableTable,
          TreatmentGuidelineTableData
        > {
  $$TreatmentGuidelineTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiseaseTableTable _diseaseIdTable(_$AppDatabase db) => db.diseaseTable
      .createAlias('treatment_guideline__disease_id__disease__id');

  $$DiseaseTableTableProcessedTableManager get diseaseId {
    final $_column = $_itemColumn<String>('disease_id')!;

    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diseaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DiagnosisTableTable, List<DiagnosisTableData>>
  _diagnosisTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnosisTable,
    aliasName: 'treatment_guideline__id__diagnosis__treatment_guideline_id',
  );

  $$DiagnosisTableTableProcessedTableManager get diagnosisTableRefs {
    final manager = $$DiagnosisTableTableTableManager($_db, $_db.diagnosisTable)
        .filter(
          (f) =>
              f.treatmentGuidelineId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_diagnosisTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TreatmentGuidelineTableTableFilterComposer
    extends Composer<_$AppDatabase, $TreatmentGuidelineTableTable> {
  $$TreatmentGuidelineTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guidelineVersion => $composableBuilder(
    column: $table.guidelineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryEn => $composableBuilder(
    column: $table.summaryEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summarySi => $composableBuilder(
    column: $table.summarySi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryTa => $composableBuilder(
    column: $table.summaryTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToDoEn => $composableBuilder(
    column: $table.whatToDoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToDoSi => $composableBuilder(
    column: $table.whatToDoSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToDoTa => $composableBuilder(
    column: $table.whatToDoTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToAvoidEn => $composableBuilder(
    column: $table.whatToAvoidEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToAvoidSi => $composableBuilder(
    column: $table.whatToAvoidSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatToAvoidTa => $composableBuilder(
    column: $table.whatToAvoidTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recheckAfterDays => $composableBuilder(
    column: $table.recheckAfterDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DiseaseTableTableFilterComposer get diseaseId {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> diagnosisTableRefs(
    Expression<bool> Function($$DiagnosisTableTableFilterComposer f) f,
  ) {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.treatmentGuidelineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TreatmentGuidelineTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TreatmentGuidelineTableTable> {
  $$TreatmentGuidelineTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guidelineVersion => $composableBuilder(
    column: $table.guidelineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryEn => $composableBuilder(
    column: $table.summaryEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summarySi => $composableBuilder(
    column: $table.summarySi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryTa => $composableBuilder(
    column: $table.summaryTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToDoEn => $composableBuilder(
    column: $table.whatToDoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToDoSi => $composableBuilder(
    column: $table.whatToDoSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToDoTa => $composableBuilder(
    column: $table.whatToDoTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToAvoidEn => $composableBuilder(
    column: $table.whatToAvoidEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToAvoidSi => $composableBuilder(
    column: $table.whatToAvoidSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatToAvoidTa => $composableBuilder(
    column: $table.whatToAvoidTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recheckAfterDays => $composableBuilder(
    column: $table.recheckAfterDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiseaseTableTableOrderingComposer get diseaseId {
    final $$DiseaseTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableOrderingComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TreatmentGuidelineTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TreatmentGuidelineTableTable> {
  $$TreatmentGuidelineTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guidelineVersion => $composableBuilder(
    column: $table.guidelineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summaryEn =>
      $composableBuilder(column: $table.summaryEn, builder: (column) => column);

  GeneratedColumn<String> get summarySi =>
      $composableBuilder(column: $table.summarySi, builder: (column) => column);

  GeneratedColumn<String> get summaryTa =>
      $composableBuilder(column: $table.summaryTa, builder: (column) => column);

  GeneratedColumn<String> get whatToDoEn => $composableBuilder(
    column: $table.whatToDoEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatToDoSi => $composableBuilder(
    column: $table.whatToDoSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatToDoTa => $composableBuilder(
    column: $table.whatToDoTa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatToAvoidEn => $composableBuilder(
    column: $table.whatToAvoidEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatToAvoidSi => $composableBuilder(
    column: $table.whatToAvoidSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whatToAvoidTa => $composableBuilder(
    column: $table.whatToAvoidTa,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recheckAfterDays => $composableBuilder(
    column: $table.recheckAfterDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  $$DiseaseTableTableAnnotationComposer get diseaseId {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> diagnosisTableRefs<T extends Object>(
    Expression<T> Function($$DiagnosisTableTableAnnotationComposer a) f,
  ) {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.treatmentGuidelineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TreatmentGuidelineTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TreatmentGuidelineTableTable,
          TreatmentGuidelineTableData,
          $$TreatmentGuidelineTableTableFilterComposer,
          $$TreatmentGuidelineTableTableOrderingComposer,
          $$TreatmentGuidelineTableTableAnnotationComposer,
          $$TreatmentGuidelineTableTableCreateCompanionBuilder,
          $$TreatmentGuidelineTableTableUpdateCompanionBuilder,
          (
            TreatmentGuidelineTableData,
            $$TreatmentGuidelineTableTableReferences,
          ),
          TreatmentGuidelineTableData,
          PrefetchHooks Function({bool diseaseId, bool diagnosisTableRefs})
        > {
  $$TreatmentGuidelineTableTableTableManager(
    _$AppDatabase db,
    $TreatmentGuidelineTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreatmentGuidelineTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TreatmentGuidelineTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TreatmentGuidelineTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diseaseId = const Value.absent(),
                Value<String> guidelineVersion = const Value.absent(),
                Value<String?> summaryEn = const Value.absent(),
                Value<String?> summarySi = const Value.absent(),
                Value<String?> summaryTa = const Value.absent(),
                Value<String?> whatToDoEn = const Value.absent(),
                Value<String?> whatToDoSi = const Value.absent(),
                Value<String?> whatToDoTa = const Value.absent(),
                Value<String?> whatToAvoidEn = const Value.absent(),
                Value<String?> whatToAvoidSi = const Value.absent(),
                Value<String?> whatToAvoidTa = const Value.absent(),
                Value<int?> recheckAfterDays = const Value.absent(),
                Value<String?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatmentGuidelineTableCompanion(
                id: id,
                diseaseId: diseaseId,
                guidelineVersion: guidelineVersion,
                summaryEn: summaryEn,
                summarySi: summarySi,
                summaryTa: summaryTa,
                whatToDoEn: whatToDoEn,
                whatToDoSi: whatToDoSi,
                whatToDoTa: whatToDoTa,
                whatToAvoidEn: whatToAvoidEn,
                whatToAvoidSi: whatToAvoidSi,
                whatToAvoidTa: whatToAvoidTa,
                recheckAfterDays: recheckAfterDays,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diseaseId,
                required String guidelineVersion,
                Value<String?> summaryEn = const Value.absent(),
                Value<String?> summarySi = const Value.absent(),
                Value<String?> summaryTa = const Value.absent(),
                Value<String?> whatToDoEn = const Value.absent(),
                Value<String?> whatToDoSi = const Value.absent(),
                Value<String?> whatToDoTa = const Value.absent(),
                Value<String?> whatToAvoidEn = const Value.absent(),
                Value<String?> whatToAvoidSi = const Value.absent(),
                Value<String?> whatToAvoidTa = const Value.absent(),
                Value<int?> recheckAfterDays = const Value.absent(),
                Value<String?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatmentGuidelineTableCompanion.insert(
                id: id,
                diseaseId: diseaseId,
                guidelineVersion: guidelineVersion,
                summaryEn: summaryEn,
                summarySi: summarySi,
                summaryTa: summaryTa,
                whatToDoEn: whatToDoEn,
                whatToDoSi: whatToDoSi,
                whatToDoTa: whatToDoTa,
                whatToAvoidEn: whatToAvoidEn,
                whatToAvoidSi: whatToAvoidSi,
                whatToAvoidTa: whatToAvoidTa,
                recheckAfterDays: recheckAfterDays,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TreatmentGuidelineTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({diseaseId = false, diagnosisTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diagnosisTableRefs) db.diagnosisTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (diseaseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.diseaseId,
                                    referencedTable:
                                        $$TreatmentGuidelineTableTableReferences
                                            ._diseaseIdTable(db),
                                    referencedColumn:
                                        $$TreatmentGuidelineTableTableReferences
                                            ._diseaseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diagnosisTableRefs)
                        await $_getPrefetchedData<
                          TreatmentGuidelineTableData,
                          $TreatmentGuidelineTableTable,
                          DiagnosisTableData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$TreatmentGuidelineTableTableReferences
                                  ._diagnosisTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TreatmentGuidelineTableTableReferences(
                                db,
                                table,
                                p0,
                              ).diagnosisTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.treatmentGuidelineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TreatmentGuidelineTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TreatmentGuidelineTableTable,
      TreatmentGuidelineTableData,
      $$TreatmentGuidelineTableTableFilterComposer,
      $$TreatmentGuidelineTableTableOrderingComposer,
      $$TreatmentGuidelineTableTableAnnotationComposer,
      $$TreatmentGuidelineTableTableCreateCompanionBuilder,
      $$TreatmentGuidelineTableTableUpdateCompanionBuilder,
      (TreatmentGuidelineTableData, $$TreatmentGuidelineTableTableReferences),
      TreatmentGuidelineTableData,
      PrefetchHooks Function({bool diseaseId, bool diagnosisTableRefs})
    >;
typedef $$ModelVersionTableTableCreateCompanionBuilder =
    ModelVersionTableCompanion Function({
      required String id,
      Value<String?> releasedAt,
      Value<int> isActive,
      Value<int> rowid,
    });
typedef $$ModelVersionTableTableUpdateCompanionBuilder =
    ModelVersionTableCompanion Function({
      Value<String> id,
      Value<String?> releasedAt,
      Value<int> isActive,
      Value<int> rowid,
    });

final class $$ModelVersionTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ModelVersionTableTable,
          ModelVersionTableData
        > {
  $$ModelVersionTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$DiagnosisTableTable, List<DiagnosisTableData>>
  _diagnosisTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnosisTable,
    aliasName: 'model_version__id__diagnosis__model_version_id',
  );

  $$DiagnosisTableTableProcessedTableManager get diagnosisTableRefs {
    final manager = $$DiagnosisTableTableTableManager(
      $_db,
      $_db.diagnosisTable,
    ).filter((f) => f.modelVersionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diagnosisTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ModelVersionTableTableFilterComposer
    extends Composer<_$AppDatabase, $ModelVersionTableTable> {
  $$ModelVersionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> diagnosisTableRefs(
    Expression<bool> Function($$DiagnosisTableTableFilterComposer f) f,
  ) {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.modelVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ModelVersionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ModelVersionTableTable> {
  $$ModelVersionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModelVersionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModelVersionTableTable> {
  $$ModelVersionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> diagnosisTableRefs<T extends Object>(
    Expression<T> Function($$DiagnosisTableTableAnnotationComposer a) f,
  ) {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.modelVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ModelVersionTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModelVersionTableTable,
          ModelVersionTableData,
          $$ModelVersionTableTableFilterComposer,
          $$ModelVersionTableTableOrderingComposer,
          $$ModelVersionTableTableAnnotationComposer,
          $$ModelVersionTableTableCreateCompanionBuilder,
          $$ModelVersionTableTableUpdateCompanionBuilder,
          (ModelVersionTableData, $$ModelVersionTableTableReferences),
          ModelVersionTableData,
          PrefetchHooks Function({bool diagnosisTableRefs})
        > {
  $$ModelVersionTableTableTableManager(
    _$AppDatabase db,
    $ModelVersionTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModelVersionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModelVersionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModelVersionTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> releasedAt = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelVersionTableCompanion(
                id: id,
                releasedAt: releasedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> releasedAt = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModelVersionTableCompanion.insert(
                id: id,
                releasedAt: releasedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ModelVersionTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diagnosisTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (diagnosisTableRefs) db.diagnosisTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (diagnosisTableRefs)
                    await $_getPrefetchedData<
                      ModelVersionTableData,
                      $ModelVersionTableTable,
                      DiagnosisTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ModelVersionTableTableReferences
                          ._diagnosisTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ModelVersionTableTableReferences(
                            db,
                            table,
                            p0,
                          ).diagnosisTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.modelVersionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ModelVersionTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModelVersionTableTable,
      ModelVersionTableData,
      $$ModelVersionTableTableFilterComposer,
      $$ModelVersionTableTableOrderingComposer,
      $$ModelVersionTableTableAnnotationComposer,
      $$ModelVersionTableTableCreateCompanionBuilder,
      $$ModelVersionTableTableUpdateCompanionBuilder,
      (ModelVersionTableData, $$ModelVersionTableTableReferences),
      ModelVersionTableData,
      PrefetchHooks Function({bool diagnosisTableRefs})
    >;
typedef $$ScanTableTableCreateCompanionBuilder =
    ScanTableCompanion Function({
      required String id,
      Value<String?> remoteScanId,
      required String userId,
      required String cropId,
      required String imageLocalPath,
      Value<String?> imageRemoteUrl,
      required String status,
      required String capturedAt,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$ScanTableTableUpdateCompanionBuilder =
    ScanTableCompanion Function({
      Value<String> id,
      Value<String?> remoteScanId,
      Value<String> userId,
      Value<String> cropId,
      Value<String> imageLocalPath,
      Value<String?> imageRemoteUrl,
      Value<String> status,
      Value<String> capturedAt,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$ScanTableTableReferences
    extends BaseReferences<_$AppDatabase, $ScanTableTable, ScanTableData> {
  $$ScanTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalUserTableTable _userIdTable(_$AppDatabase db) =>
      db.localUserTable.createAlias('scan__user_id__local_user__id');

  $$LocalUserTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$LocalUserTableTableTableManager(
      $_db,
      $_db.localUserTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CropTableTable _cropIdTable(_$AppDatabase db) =>
      db.cropTable.createAlias('scan__crop_id__crop__id');

  $$CropTableTableProcessedTableManager get cropId {
    final $_column = $_itemColumn<String>('crop_id')!;

    final manager = $$CropTableTableTableManager(
      $_db,
      $_db.cropTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cropIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ImageValidationTableTable,
    List<ImageValidationTableData>
  >
  _imageValidationTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.imageValidationTable,
        aliasName: 'scan__id__image_validation__scan_id',
      );

  $$ImageValidationTableTableProcessedTableManager
  get imageValidationTableRefs {
    final manager = $$ImageValidationTableTableTableManager(
      $_db,
      $_db.imageValidationTable,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _imageValidationTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiagnosisTableTable, List<DiagnosisTableData>>
  _diagnosisTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diagnosisTable,
    aliasName: 'scan__id__diagnosis__scan_id',
  );

  $$DiagnosisTableTableProcessedTableManager get diagnosisTableRefs {
    final manager = $$DiagnosisTableTableTableManager(
      $_db,
      $_db.diagnosisTable,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diagnosisTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EscalationTableTable, List<EscalationTableData>>
  _escalationTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.escalationTable,
    aliasName: 'scan__id__escalation__scan_id',
  );

  $$EscalationTableTableProcessedTableManager get escalationTableRefs {
    final manager = $$EscalationTableTableTableManager(
      $_db,
      $_db.escalationTable,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _escalationTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScanTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScanTableTable> {
  $$ScanTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteScanId => $composableBuilder(
    column: $table.remoteScanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageRemoteUrl => $composableBuilder(
    column: $table.imageRemoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalUserTableTableFilterComposer get userId {
    final $$LocalUserTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localUserTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalUserTableTableFilterComposer(
            $db: $db,
            $table: $db.localUserTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropTableTableFilterComposer get cropId {
    final $$CropTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableFilterComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> imageValidationTableRefs(
    Expression<bool> Function($$ImageValidationTableTableFilterComposer f) f,
  ) {
    final $$ImageValidationTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageValidationTable,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageValidationTableTableFilterComposer(
            $db: $db,
            $table: $db.imageValidationTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diagnosisTableRefs(
    Expression<bool> Function($$DiagnosisTableTableFilterComposer f) f,
  ) {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> escalationTableRefs(
    Expression<bool> Function($$EscalationTableTableFilterComposer f) f,
  ) {
    final $$EscalationTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.escalationTable,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EscalationTableTableFilterComposer(
            $db: $db,
            $table: $db.escalationTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanTableTable> {
  $$ScanTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteScanId => $composableBuilder(
    column: $table.remoteScanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageRemoteUrl => $composableBuilder(
    column: $table.imageRemoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalUserTableTableOrderingComposer get userId {
    final $$LocalUserTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localUserTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalUserTableTableOrderingComposer(
            $db: $db,
            $table: $db.localUserTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropTableTableOrderingComposer get cropId {
    final $$CropTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableOrderingComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScanTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanTableTable> {
  $$ScanTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteScanId => $composableBuilder(
    column: $table.remoteScanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageLocalPath => $composableBuilder(
    column: $table.imageLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageRemoteUrl => $composableBuilder(
    column: $table.imageRemoteUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocalUserTableTableAnnotationComposer get userId {
    final $$LocalUserTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.localUserTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalUserTableTableAnnotationComposer(
            $db: $db,
            $table: $db.localUserTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CropTableTableAnnotationComposer get cropId {
    final $$CropTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cropId,
      referencedTable: $db.cropTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CropTableTableAnnotationComposer(
            $db: $db,
            $table: $db.cropTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> imageValidationTableRefs<T extends Object>(
    Expression<T> Function($$ImageValidationTableTableAnnotationComposer a) f,
  ) {
    final $$ImageValidationTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.imageValidationTable,
          getReferencedColumn: (t) => t.scanId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ImageValidationTableTableAnnotationComposer(
                $db: $db,
                $table: $db.imageValidationTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> diagnosisTableRefs<T extends Object>(
    Expression<T> Function($$DiagnosisTableTableAnnotationComposer a) f,
  ) {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> escalationTableRefs<T extends Object>(
    Expression<T> Function($$EscalationTableTableAnnotationComposer a) f,
  ) {
    final $$EscalationTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.escalationTable,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EscalationTableTableAnnotationComposer(
            $db: $db,
            $table: $db.escalationTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScanTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanTableTable,
          ScanTableData,
          $$ScanTableTableFilterComposer,
          $$ScanTableTableOrderingComposer,
          $$ScanTableTableAnnotationComposer,
          $$ScanTableTableCreateCompanionBuilder,
          $$ScanTableTableUpdateCompanionBuilder,
          (ScanTableData, $$ScanTableTableReferences),
          ScanTableData,
          PrefetchHooks Function({
            bool userId,
            bool cropId,
            bool imageValidationTableRefs,
            bool diagnosisTableRefs,
            bool escalationTableRefs,
          })
        > {
  $$ScanTableTableTableManager(_$AppDatabase db, $ScanTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> remoteScanId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> cropId = const Value.absent(),
                Value<String> imageLocalPath = const Value.absent(),
                Value<String?> imageRemoteUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> capturedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanTableCompanion(
                id: id,
                remoteScanId: remoteScanId,
                userId: userId,
                cropId: cropId,
                imageLocalPath: imageLocalPath,
                imageRemoteUrl: imageRemoteUrl,
                status: status,
                capturedAt: capturedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> remoteScanId = const Value.absent(),
                required String userId,
                required String cropId,
                required String imageLocalPath,
                Value<String?> imageRemoteUrl = const Value.absent(),
                required String status,
                required String capturedAt,
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScanTableCompanion.insert(
                id: id,
                remoteScanId: remoteScanId,
                userId: userId,
                cropId: cropId,
                imageLocalPath: imageLocalPath,
                imageRemoteUrl: imageRemoteUrl,
                status: status,
                capturedAt: capturedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScanTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userId = false,
                cropId = false,
                imageValidationTableRefs = false,
                diagnosisTableRefs = false,
                escalationTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (imageValidationTableRefs) db.imageValidationTable,
                    if (diagnosisTableRefs) db.diagnosisTable,
                    if (escalationTableRefs) db.escalationTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable: $$ScanTableTableReferences
                                        ._userIdTable(db),
                                    referencedColumn: $$ScanTableTableReferences
                                        ._userIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (cropId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cropId,
                                    referencedTable: $$ScanTableTableReferences
                                        ._cropIdTable(db),
                                    referencedColumn: $$ScanTableTableReferences
                                        ._cropIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (imageValidationTableRefs)
                        await $_getPrefetchedData<
                          ScanTableData,
                          $ScanTableTable,
                          ImageValidationTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScanTableTableReferences
                              ._imageValidationTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScanTableTableReferences(
                                db,
                                table,
                                p0,
                              ).imageValidationTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (diagnosisTableRefs)
                        await $_getPrefetchedData<
                          ScanTableData,
                          $ScanTableTable,
                          DiagnosisTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScanTableTableReferences
                              ._diagnosisTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScanTableTableReferences(
                                db,
                                table,
                                p0,
                              ).diagnosisTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (escalationTableRefs)
                        await $_getPrefetchedData<
                          ScanTableData,
                          $ScanTableTable,
                          EscalationTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScanTableTableReferences
                              ._escalationTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScanTableTableReferences(
                                db,
                                table,
                                p0,
                              ).escalationTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScanTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanTableTable,
      ScanTableData,
      $$ScanTableTableFilterComposer,
      $$ScanTableTableOrderingComposer,
      $$ScanTableTableAnnotationComposer,
      $$ScanTableTableCreateCompanionBuilder,
      $$ScanTableTableUpdateCompanionBuilder,
      (ScanTableData, $$ScanTableTableReferences),
      ScanTableData,
      PrefetchHooks Function({
        bool userId,
        bool cropId,
        bool imageValidationTableRefs,
        bool diagnosisTableRefs,
        bool escalationTableRefs,
      })
    >;
typedef $$ImageValidationTableTableCreateCompanionBuilder =
    ImageValidationTableCompanion Function({
      required String id,
      required String scanId,
      required int isUsable,
      Value<String?> rejectionReason,
      required String checkedAt,
      Value<int> rowid,
    });
typedef $$ImageValidationTableTableUpdateCompanionBuilder =
    ImageValidationTableCompanion Function({
      Value<String> id,
      Value<String> scanId,
      Value<int> isUsable,
      Value<String?> rejectionReason,
      Value<String> checkedAt,
      Value<int> rowid,
    });

final class $$ImageValidationTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ImageValidationTableTable,
          ImageValidationTableData
        > {
  $$ImageValidationTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScanTableTable _scanIdTable(_$AppDatabase db) =>
      db.scanTable.createAlias('image_validation__scan_id__scan__id');

  $$ScanTableTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScanTableTableTableManager(
      $_db,
      $_db.scanTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImageValidationTableTableFilterComposer
    extends Composer<_$AppDatabase, $ImageValidationTableTable> {
  $$ImageValidationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isUsable => $composableBuilder(
    column: $table.isUsable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScanTableTableFilterComposer get scanId {
    final $$ScanTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableFilterComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageValidationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageValidationTableTable> {
  $$ImageValidationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isUsable => $composableBuilder(
    column: $table.isUsable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScanTableTableOrderingComposer get scanId {
    final $$ScanTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableOrderingComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageValidationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageValidationTableTable> {
  $$ImageValidationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get isUsable =>
      $composableBuilder(column: $table.isUsable, builder: (column) => column);

  GeneratedColumn<String> get rejectionReason => $composableBuilder(
    column: $table.rejectionReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  $$ScanTableTableAnnotationComposer get scanId {
    final $$ScanTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageValidationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageValidationTableTable,
          ImageValidationTableData,
          $$ImageValidationTableTableFilterComposer,
          $$ImageValidationTableTableOrderingComposer,
          $$ImageValidationTableTableAnnotationComposer,
          $$ImageValidationTableTableCreateCompanionBuilder,
          $$ImageValidationTableTableUpdateCompanionBuilder,
          (ImageValidationTableData, $$ImageValidationTableTableReferences),
          ImageValidationTableData,
          PrefetchHooks Function({bool scanId})
        > {
  $$ImageValidationTableTableTableManager(
    _$AppDatabase db,
    $ImageValidationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageValidationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageValidationTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ImageValidationTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<int> isUsable = const Value.absent(),
                Value<String?> rejectionReason = const Value.absent(),
                Value<String> checkedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageValidationTableCompanion(
                id: id,
                scanId: scanId,
                isUsable: isUsable,
                rejectionReason: rejectionReason,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scanId,
                required int isUsable,
                Value<String?> rejectionReason = const Value.absent(),
                required String checkedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImageValidationTableCompanion.insert(
                id: id,
                scanId: scanId,
                isUsable: isUsable,
                rejectionReason: rejectionReason,
                checkedAt: checkedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImageValidationTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable:
                                    $$ImageValidationTableTableReferences
                                        ._scanIdTable(db),
                                referencedColumn:
                                    $$ImageValidationTableTableReferences
                                        ._scanIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImageValidationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageValidationTableTable,
      ImageValidationTableData,
      $$ImageValidationTableTableFilterComposer,
      $$ImageValidationTableTableOrderingComposer,
      $$ImageValidationTableTableAnnotationComposer,
      $$ImageValidationTableTableCreateCompanionBuilder,
      $$ImageValidationTableTableUpdateCompanionBuilder,
      (ImageValidationTableData, $$ImageValidationTableTableReferences),
      ImageValidationTableData,
      PrefetchHooks Function({bool scanId})
    >;
typedef $$DiagnosisTableTableCreateCompanionBuilder =
    DiagnosisTableCompanion Function({
      required String id,
      required String scanId,
      Value<String?> diseaseId,
      required String modelVersionId,
      required double confidence,
      required String resultState,
      Value<String?> severity,
      Value<String?> alternativesJson,
      required String treatmentSource,
      Value<String?> treatmentGuidelineId,
      Value<String?> llmInterpretationId,
      Value<String?> aiTreatmentJson,
      Value<String?> aiTreatmentFetchedAt,
      required String inferredAt,
      Value<int> rowid,
    });
typedef $$DiagnosisTableTableUpdateCompanionBuilder =
    DiagnosisTableCompanion Function({
      Value<String> id,
      Value<String> scanId,
      Value<String?> diseaseId,
      Value<String> modelVersionId,
      Value<double> confidence,
      Value<String> resultState,
      Value<String?> severity,
      Value<String?> alternativesJson,
      Value<String> treatmentSource,
      Value<String?> treatmentGuidelineId,
      Value<String?> llmInterpretationId,
      Value<String?> aiTreatmentJson,
      Value<String?> aiTreatmentFetchedAt,
      Value<String> inferredAt,
      Value<int> rowid,
    });

final class $$DiagnosisTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DiagnosisTableTable,
          DiagnosisTableData
        > {
  $$DiagnosisTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScanTableTable _scanIdTable(_$AppDatabase db) =>
      db.scanTable.createAlias('diagnosis__scan_id__scan__id');

  $$ScanTableTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScanTableTableTableManager(
      $_db,
      $_db.scanTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DiseaseTableTable _diseaseIdTable(_$AppDatabase db) =>
      db.diseaseTable.createAlias('diagnosis__disease_id__disease__id');

  $$DiseaseTableTableProcessedTableManager? get diseaseId {
    final $_column = $_itemColumn<String>('disease_id');
    if ($_column == null) return null;
    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diseaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ModelVersionTableTable _modelVersionIdTable(_$AppDatabase db) => db
      .modelVersionTable
      .createAlias('diagnosis__model_version_id__model_version__id');

  $$ModelVersionTableTableProcessedTableManager get modelVersionId {
    final $_column = $_itemColumn<String>('model_version_id')!;

    final manager = $$ModelVersionTableTableTableManager(
      $_db,
      $_db.modelVersionTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_modelVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TreatmentGuidelineTableTable _treatmentGuidelineIdTable(
    _$AppDatabase db,
  ) => db.treatmentGuidelineTable.createAlias(
    'diagnosis__treatment_guideline_id__treatment_guideline__id',
  );

  $$TreatmentGuidelineTableTableProcessedTableManager?
  get treatmentGuidelineId {
    final $_column = $_itemColumn<String>('treatment_guideline_id');
    if ($_column == null) return null;
    final manager = $$TreatmentGuidelineTableTableTableManager(
      $_db,
      $_db.treatmentGuidelineTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _treatmentGuidelineIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EscalationTableTable, List<EscalationTableData>>
  _escalationTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.escalationTable,
    aliasName: 'diagnosis__id__escalation__diagnosis_id',
  );

  $$EscalationTableTableProcessedTableManager get escalationTableRefs {
    final manager = $$EscalationTableTableTableManager(
      $_db,
      $_db.escalationTable,
    ).filter((f) => f.diagnosisId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _escalationTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChatMessageTableTable, List<ChatMessageTableData>>
  _chatMessageTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatMessageTable,
    aliasName: 'diagnosis__id__chat_message__diagnosis_id',
  );

  $$ChatMessageTableTableProcessedTableManager get chatMessageTableRefs {
    final manager = $$ChatMessageTableTableTableManager(
      $_db,
      $_db.chatMessageTable,
    ).filter((f) => f.diagnosisId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chatMessageTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiagnosisTableTableFilterComposer
    extends Composer<_$AppDatabase, $DiagnosisTableTable> {
  $$DiagnosisTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultState => $composableBuilder(
    column: $table.resultState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treatmentSource => $composableBuilder(
    column: $table.treatmentSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get llmInterpretationId => $composableBuilder(
    column: $table.llmInterpretationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiTreatmentJson => $composableBuilder(
    column: $table.aiTreatmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiTreatmentFetchedAt => $composableBuilder(
    column: $table.aiTreatmentFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inferredAt => $composableBuilder(
    column: $table.inferredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScanTableTableFilterComposer get scanId {
    final $$ScanTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableFilterComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableFilterComposer get diseaseId {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModelVersionTableTableFilterComposer get modelVersionId {
    final $$ModelVersionTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelVersionId,
      referencedTable: $db.modelVersionTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelVersionTableTableFilterComposer(
            $db: $db,
            $table: $db.modelVersionTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TreatmentGuidelineTableTableFilterComposer get treatmentGuidelineId {
    final $$TreatmentGuidelineTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.treatmentGuidelineId,
          referencedTable: $db.treatmentGuidelineTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TreatmentGuidelineTableTableFilterComposer(
                $db: $db,
                $table: $db.treatmentGuidelineTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> escalationTableRefs(
    Expression<bool> Function($$EscalationTableTableFilterComposer f) f,
  ) {
    final $$EscalationTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.escalationTable,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EscalationTableTableFilterComposer(
            $db: $db,
            $table: $db.escalationTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chatMessageTableRefs(
    Expression<bool> Function($$ChatMessageTableTableFilterComposer f) f,
  ) {
    final $$ChatMessageTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessageTable,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessageTableTableFilterComposer(
            $db: $db,
            $table: $db.chatMessageTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiagnosisTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DiagnosisTableTable> {
  $$DiagnosisTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultState => $composableBuilder(
    column: $table.resultState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treatmentSource => $composableBuilder(
    column: $table.treatmentSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get llmInterpretationId => $composableBuilder(
    column: $table.llmInterpretationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiTreatmentJson => $composableBuilder(
    column: $table.aiTreatmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiTreatmentFetchedAt => $composableBuilder(
    column: $table.aiTreatmentFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inferredAt => $composableBuilder(
    column: $table.inferredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScanTableTableOrderingComposer get scanId {
    final $$ScanTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableOrderingComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableOrderingComposer get diseaseId {
    final $$DiseaseTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableOrderingComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModelVersionTableTableOrderingComposer get modelVersionId {
    final $$ModelVersionTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.modelVersionId,
      referencedTable: $db.modelVersionTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ModelVersionTableTableOrderingComposer(
            $db: $db,
            $table: $db.modelVersionTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TreatmentGuidelineTableTableOrderingComposer get treatmentGuidelineId {
    final $$TreatmentGuidelineTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.treatmentGuidelineId,
          referencedTable: $db.treatmentGuidelineTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TreatmentGuidelineTableTableOrderingComposer(
                $db: $db,
                $table: $db.treatmentGuidelineTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DiagnosisTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiagnosisTableTable> {
  $$DiagnosisTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultState => $composableBuilder(
    column: $table.resultState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get alternativesJson => $composableBuilder(
    column: $table.alternativesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get treatmentSource => $composableBuilder(
    column: $table.treatmentSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get llmInterpretationId => $composableBuilder(
    column: $table.llmInterpretationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiTreatmentJson => $composableBuilder(
    column: $table.aiTreatmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiTreatmentFetchedAt => $composableBuilder(
    column: $table.aiTreatmentFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inferredAt => $composableBuilder(
    column: $table.inferredAt,
    builder: (column) => column,
  );

  $$ScanTableTableAnnotationComposer get scanId {
    final $$ScanTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableAnnotationComposer get diseaseId {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ModelVersionTableTableAnnotationComposer get modelVersionId {
    final $$ModelVersionTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.modelVersionId,
          referencedTable: $db.modelVersionTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ModelVersionTableTableAnnotationComposer(
                $db: $db,
                $table: $db.modelVersionTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$TreatmentGuidelineTableTableAnnotationComposer get treatmentGuidelineId {
    final $$TreatmentGuidelineTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.treatmentGuidelineId,
          referencedTable: $db.treatmentGuidelineTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TreatmentGuidelineTableTableAnnotationComposer(
                $db: $db,
                $table: $db.treatmentGuidelineTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> escalationTableRefs<T extends Object>(
    Expression<T> Function($$EscalationTableTableAnnotationComposer a) f,
  ) {
    final $$EscalationTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.escalationTable,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EscalationTableTableAnnotationComposer(
            $db: $db,
            $table: $db.escalationTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chatMessageTableRefs<T extends Object>(
    Expression<T> Function($$ChatMessageTableTableAnnotationComposer a) f,
  ) {
    final $$ChatMessageTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessageTable,
      getReferencedColumn: (t) => t.diagnosisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessageTableTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessageTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiagnosisTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiagnosisTableTable,
          DiagnosisTableData,
          $$DiagnosisTableTableFilterComposer,
          $$DiagnosisTableTableOrderingComposer,
          $$DiagnosisTableTableAnnotationComposer,
          $$DiagnosisTableTableCreateCompanionBuilder,
          $$DiagnosisTableTableUpdateCompanionBuilder,
          (DiagnosisTableData, $$DiagnosisTableTableReferences),
          DiagnosisTableData,
          PrefetchHooks Function({
            bool scanId,
            bool diseaseId,
            bool modelVersionId,
            bool treatmentGuidelineId,
            bool escalationTableRefs,
            bool chatMessageTableRefs,
          })
        > {
  $$DiagnosisTableTableTableManager(
    _$AppDatabase db,
    $DiagnosisTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiagnosisTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiagnosisTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiagnosisTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String?> diseaseId = const Value.absent(),
                Value<String> modelVersionId = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> resultState = const Value.absent(),
                Value<String?> severity = const Value.absent(),
                Value<String?> alternativesJson = const Value.absent(),
                Value<String> treatmentSource = const Value.absent(),
                Value<String?> treatmentGuidelineId = const Value.absent(),
                Value<String?> llmInterpretationId = const Value.absent(),
                Value<String?> aiTreatmentJson = const Value.absent(),
                Value<String?> aiTreatmentFetchedAt = const Value.absent(),
                Value<String> inferredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiagnosisTableCompanion(
                id: id,
                scanId: scanId,
                diseaseId: diseaseId,
                modelVersionId: modelVersionId,
                confidence: confidence,
                resultState: resultState,
                severity: severity,
                alternativesJson: alternativesJson,
                treatmentSource: treatmentSource,
                treatmentGuidelineId: treatmentGuidelineId,
                llmInterpretationId: llmInterpretationId,
                aiTreatmentJson: aiTreatmentJson,
                aiTreatmentFetchedAt: aiTreatmentFetchedAt,
                inferredAt: inferredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scanId,
                Value<String?> diseaseId = const Value.absent(),
                required String modelVersionId,
                required double confidence,
                required String resultState,
                Value<String?> severity = const Value.absent(),
                Value<String?> alternativesJson = const Value.absent(),
                required String treatmentSource,
                Value<String?> treatmentGuidelineId = const Value.absent(),
                Value<String?> llmInterpretationId = const Value.absent(),
                Value<String?> aiTreatmentJson = const Value.absent(),
                Value<String?> aiTreatmentFetchedAt = const Value.absent(),
                required String inferredAt,
                Value<int> rowid = const Value.absent(),
              }) => DiagnosisTableCompanion.insert(
                id: id,
                scanId: scanId,
                diseaseId: diseaseId,
                modelVersionId: modelVersionId,
                confidence: confidence,
                resultState: resultState,
                severity: severity,
                alternativesJson: alternativesJson,
                treatmentSource: treatmentSource,
                treatmentGuidelineId: treatmentGuidelineId,
                llmInterpretationId: llmInterpretationId,
                aiTreatmentJson: aiTreatmentJson,
                aiTreatmentFetchedAt: aiTreatmentFetchedAt,
                inferredAt: inferredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiagnosisTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scanId = false,
                diseaseId = false,
                modelVersionId = false,
                treatmentGuidelineId = false,
                escalationTableRefs = false,
                chatMessageTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (escalationTableRefs) db.escalationTable,
                    if (chatMessageTableRefs) db.chatMessageTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (scanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scanId,
                                    referencedTable:
                                        $$DiagnosisTableTableReferences
                                            ._scanIdTable(db),
                                    referencedColumn:
                                        $$DiagnosisTableTableReferences
                                            ._scanIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (diseaseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.diseaseId,
                                    referencedTable:
                                        $$DiagnosisTableTableReferences
                                            ._diseaseIdTable(db),
                                    referencedColumn:
                                        $$DiagnosisTableTableReferences
                                            ._diseaseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (modelVersionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.modelVersionId,
                                    referencedTable:
                                        $$DiagnosisTableTableReferences
                                            ._modelVersionIdTable(db),
                                    referencedColumn:
                                        $$DiagnosisTableTableReferences
                                            ._modelVersionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (treatmentGuidelineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.treatmentGuidelineId,
                                    referencedTable:
                                        $$DiagnosisTableTableReferences
                                            ._treatmentGuidelineIdTable(db),
                                    referencedColumn:
                                        $$DiagnosisTableTableReferences
                                            ._treatmentGuidelineIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (escalationTableRefs)
                        await $_getPrefetchedData<
                          DiagnosisTableData,
                          $DiagnosisTableTable,
                          EscalationTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiagnosisTableTableReferences
                              ._escalationTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiagnosisTableTableReferences(
                                db,
                                table,
                                p0,
                              ).escalationTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diagnosisId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chatMessageTableRefs)
                        await $_getPrefetchedData<
                          DiagnosisTableData,
                          $DiagnosisTableTable,
                          ChatMessageTableData
                        >(
                          currentTable: table,
                          referencedTable: $$DiagnosisTableTableReferences
                              ._chatMessageTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiagnosisTableTableReferences(
                                db,
                                table,
                                p0,
                              ).chatMessageTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diagnosisId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DiagnosisTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiagnosisTableTable,
      DiagnosisTableData,
      $$DiagnosisTableTableFilterComposer,
      $$DiagnosisTableTableOrderingComposer,
      $$DiagnosisTableTableAnnotationComposer,
      $$DiagnosisTableTableCreateCompanionBuilder,
      $$DiagnosisTableTableUpdateCompanionBuilder,
      (DiagnosisTableData, $$DiagnosisTableTableReferences),
      DiagnosisTableData,
      PrefetchHooks Function({
        bool scanId,
        bool diseaseId,
        bool modelVersionId,
        bool treatmentGuidelineId,
        bool escalationTableRefs,
        bool chatMessageTableRefs,
      })
    >;
typedef $$EscalationTableTableCreateCompanionBuilder =
    EscalationTableCompanion Function({
      required String id,
      required String scanId,
      required String diagnosisId,
      Value<String?> notes,
      Value<String> sharedVia,
      Value<String?> sharedAt,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$EscalationTableTableUpdateCompanionBuilder =
    EscalationTableCompanion Function({
      Value<String> id,
      Value<String> scanId,
      Value<String> diagnosisId,
      Value<String?> notes,
      Value<String> sharedVia,
      Value<String?> sharedAt,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$EscalationTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EscalationTableTable,
          EscalationTableData
        > {
  $$EscalationTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScanTableTable _scanIdTable(_$AppDatabase db) =>
      db.scanTable.createAlias('escalation__scan_id__scan__id');

  $$ScanTableTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScanTableTableTableManager(
      $_db,
      $_db.scanTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DiagnosisTableTable _diagnosisIdTable(_$AppDatabase db) =>
      db.diagnosisTable.createAlias('escalation__diagnosis_id__diagnosis__id');

  $$DiagnosisTableTableProcessedTableManager get diagnosisId {
    final $_column = $_itemColumn<String>('diagnosis_id')!;

    final manager = $$DiagnosisTableTableTableManager(
      $_db,
      $_db.diagnosisTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diagnosisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EscalationTableTableFilterComposer
    extends Composer<_$AppDatabase, $EscalationTableTable> {
  $$EscalationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedVia => $composableBuilder(
    column: $table.sharedVia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScanTableTableFilterComposer get scanId {
    final $$ScanTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableFilterComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosisTableTableFilterComposer get diagnosisId {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EscalationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EscalationTableTable> {
  $$EscalationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedVia => $composableBuilder(
    column: $table.sharedVia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedAt => $composableBuilder(
    column: $table.sharedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScanTableTableOrderingComposer get scanId {
    final $$ScanTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableOrderingComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosisTableTableOrderingComposer get diagnosisId {
    final $$DiagnosisTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableOrderingComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EscalationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EscalationTableTable> {
  $$EscalationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sharedVia =>
      $composableBuilder(column: $table.sharedVia, builder: (column) => column);

  GeneratedColumn<String> get sharedAt =>
      $composableBuilder(column: $table.sharedAt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ScanTableTableAnnotationComposer get scanId {
    final $$ScanTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scanTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScanTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scanTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiagnosisTableTableAnnotationComposer get diagnosisId {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EscalationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EscalationTableTable,
          EscalationTableData,
          $$EscalationTableTableFilterComposer,
          $$EscalationTableTableOrderingComposer,
          $$EscalationTableTableAnnotationComposer,
          $$EscalationTableTableCreateCompanionBuilder,
          $$EscalationTableTableUpdateCompanionBuilder,
          (EscalationTableData, $$EscalationTableTableReferences),
          EscalationTableData,
          PrefetchHooks Function({bool scanId, bool diagnosisId})
        > {
  $$EscalationTableTableTableManager(
    _$AppDatabase db,
    $EscalationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EscalationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EscalationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EscalationTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> diagnosisId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> sharedVia = const Value.absent(),
                Value<String?> sharedAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EscalationTableCompanion(
                id: id,
                scanId: scanId,
                diagnosisId: diagnosisId,
                notes: notes,
                sharedVia: sharedVia,
                sharedAt: sharedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scanId,
                required String diagnosisId,
                Value<String?> notes = const Value.absent(),
                Value<String> sharedVia = const Value.absent(),
                Value<String?> sharedAt = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EscalationTableCompanion.insert(
                id: id,
                scanId: scanId,
                diagnosisId: diagnosisId,
                notes: notes,
                sharedVia: sharedVia,
                sharedAt: sharedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EscalationTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false, diagnosisId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable:
                                    $$EscalationTableTableReferences
                                        ._scanIdTable(db),
                                referencedColumn:
                                    $$EscalationTableTableReferences
                                        ._scanIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (diagnosisId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.diagnosisId,
                                referencedTable:
                                    $$EscalationTableTableReferences
                                        ._diagnosisIdTable(db),
                                referencedColumn:
                                    $$EscalationTableTableReferences
                                        ._diagnosisIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EscalationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EscalationTableTable,
      EscalationTableData,
      $$EscalationTableTableFilterComposer,
      $$EscalationTableTableOrderingComposer,
      $$EscalationTableTableAnnotationComposer,
      $$EscalationTableTableCreateCompanionBuilder,
      $$EscalationTableTableUpdateCompanionBuilder,
      (EscalationTableData, $$EscalationTableTableReferences),
      EscalationTableData,
      PrefetchHooks Function({bool scanId, bool diagnosisId})
    >;
typedef $$SyncOperationTableTableCreateCompanionBuilder =
    SyncOperationTableCompanion Function({
      required String id,
      required String entityId,
      required String entityType,
      Value<String> operationType,
      required String payloadJson,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> uploadedImageUrl,
      Value<String?> lastError,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$SyncOperationTableTableUpdateCompanionBuilder =
    SyncOperationTableCompanion Function({
      Value<String> id,
      Value<String> entityId,
      Value<String> entityType,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> uploadedImageUrl,
      Value<String?> lastError,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$SyncOperationTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationTableTable> {
  $$SyncOperationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadedImageUrl => $composableBuilder(
    column: $table.uploadedImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOperationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationTableTable> {
  $$SyncOperationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadedImageUrl => $composableBuilder(
    column: $table.uploadedImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOperationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationTableTable> {
  $$SyncOperationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadedImageUrl => $composableBuilder(
    column: $table.uploadedImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncOperationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOperationTableTable,
          SyncOperationTableData,
          $$SyncOperationTableTableFilterComposer,
          $$SyncOperationTableTableOrderingComposer,
          $$SyncOperationTableTableAnnotationComposer,
          $$SyncOperationTableTableCreateCompanionBuilder,
          $$SyncOperationTableTableUpdateCompanionBuilder,
          (
            SyncOperationTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncOperationTableTable,
              SyncOperationTableData
            >,
          ),
          SyncOperationTableData,
          PrefetchHooks Function()
        > {
  $$SyncOperationTableTableTableManager(
    _$AppDatabase db,
    $SyncOperationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> uploadedImageUrl = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationTableCompanion(
                id: id,
                entityId: entityId,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                uploadedImageUrl: uploadedImageUrl,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityId,
                required String entityType,
                Value<String> operationType = const Value.absent(),
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> uploadedImageUrl = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationTableCompanion.insert(
                id: id,
                entityId: entityId,
                entityType: entityType,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                uploadedImageUrl: uploadedImageUrl,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOperationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOperationTableTable,
      SyncOperationTableData,
      $$SyncOperationTableTableFilterComposer,
      $$SyncOperationTableTableOrderingComposer,
      $$SyncOperationTableTableAnnotationComposer,
      $$SyncOperationTableTableCreateCompanionBuilder,
      $$SyncOperationTableTableUpdateCompanionBuilder,
      (
        SyncOperationTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncOperationTableTable,
          SyncOperationTableData
        >,
      ),
      SyncOperationTableData,
      PrefetchHooks Function()
    >;
typedef $$DiseaseExplanationTableTableCreateCompanionBuilder =
    DiseaseExplanationTableCompanion Function({
      required String id,
      required String diseaseId,
      Value<String?> plantDescriptionEn,
      Value<String?> plantDescriptionSi,
      Value<String?> plantDescriptionTa,
      Value<String?> resultMeaningEn,
      Value<String?> resultMeaningSi,
      Value<String?> resultMeaningTa,
      Value<String?> explanationVersion,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$DiseaseExplanationTableTableUpdateCompanionBuilder =
    DiseaseExplanationTableCompanion Function({
      Value<String> id,
      Value<String> diseaseId,
      Value<String?> plantDescriptionEn,
      Value<String?> plantDescriptionSi,
      Value<String?> plantDescriptionTa,
      Value<String?> resultMeaningEn,
      Value<String?> resultMeaningSi,
      Value<String?> resultMeaningTa,
      Value<String?> explanationVersion,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

final class $$DiseaseExplanationTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DiseaseExplanationTableTable,
          DiseaseExplanationTableData
        > {
  $$DiseaseExplanationTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiseaseTableTable _diseaseIdTable(_$AppDatabase db) => db.diseaseTable
      .createAlias('disease_explanation__disease_id__disease__id');

  $$DiseaseTableTableProcessedTableManager get diseaseId {
    final $_column = $_itemColumn<String>('disease_id')!;

    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diseaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiseaseExplanationTableTableFilterComposer
    extends Composer<_$AppDatabase, $DiseaseExplanationTableTable> {
  $$DiseaseExplanationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantDescriptionEn => $composableBuilder(
    column: $table.plantDescriptionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantDescriptionSi => $composableBuilder(
    column: $table.plantDescriptionSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantDescriptionTa => $composableBuilder(
    column: $table.plantDescriptionTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultMeaningEn => $composableBuilder(
    column: $table.resultMeaningEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultMeaningSi => $composableBuilder(
    column: $table.resultMeaningSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultMeaningTa => $composableBuilder(
    column: $table.resultMeaningTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationVersion => $composableBuilder(
    column: $table.explanationVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DiseaseTableTableFilterComposer get diseaseId {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseExplanationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DiseaseExplanationTableTable> {
  $$DiseaseExplanationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantDescriptionEn => $composableBuilder(
    column: $table.plantDescriptionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantDescriptionSi => $composableBuilder(
    column: $table.plantDescriptionSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantDescriptionTa => $composableBuilder(
    column: $table.plantDescriptionTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultMeaningEn => $composableBuilder(
    column: $table.resultMeaningEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultMeaningSi => $composableBuilder(
    column: $table.resultMeaningSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultMeaningTa => $composableBuilder(
    column: $table.resultMeaningTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationVersion => $composableBuilder(
    column: $table.explanationVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiseaseTableTableOrderingComposer get diseaseId {
    final $$DiseaseTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableOrderingComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseExplanationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiseaseExplanationTableTable> {
  $$DiseaseExplanationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plantDescriptionEn => $composableBuilder(
    column: $table.plantDescriptionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plantDescriptionSi => $composableBuilder(
    column: $table.plantDescriptionSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plantDescriptionTa => $composableBuilder(
    column: $table.plantDescriptionTa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultMeaningEn => $composableBuilder(
    column: $table.resultMeaningEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultMeaningSi => $composableBuilder(
    column: $table.resultMeaningSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultMeaningTa => $composableBuilder(
    column: $table.resultMeaningTa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationVersion => $composableBuilder(
    column: $table.explanationVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DiseaseTableTableAnnotationComposer get diseaseId {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseExplanationTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiseaseExplanationTableTable,
          DiseaseExplanationTableData,
          $$DiseaseExplanationTableTableFilterComposer,
          $$DiseaseExplanationTableTableOrderingComposer,
          $$DiseaseExplanationTableTableAnnotationComposer,
          $$DiseaseExplanationTableTableCreateCompanionBuilder,
          $$DiseaseExplanationTableTableUpdateCompanionBuilder,
          (
            DiseaseExplanationTableData,
            $$DiseaseExplanationTableTableReferences,
          ),
          DiseaseExplanationTableData,
          PrefetchHooks Function({bool diseaseId})
        > {
  $$DiseaseExplanationTableTableTableManager(
    _$AppDatabase db,
    $DiseaseExplanationTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiseaseExplanationTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DiseaseExplanationTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DiseaseExplanationTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diseaseId = const Value.absent(),
                Value<String?> plantDescriptionEn = const Value.absent(),
                Value<String?> plantDescriptionSi = const Value.absent(),
                Value<String?> plantDescriptionTa = const Value.absent(),
                Value<String?> resultMeaningEn = const Value.absent(),
                Value<String?> resultMeaningSi = const Value.absent(),
                Value<String?> resultMeaningTa = const Value.absent(),
                Value<String?> explanationVersion = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseExplanationTableCompanion(
                id: id,
                diseaseId: diseaseId,
                plantDescriptionEn: plantDescriptionEn,
                plantDescriptionSi: plantDescriptionSi,
                plantDescriptionTa: plantDescriptionTa,
                resultMeaningEn: resultMeaningEn,
                resultMeaningSi: resultMeaningSi,
                resultMeaningTa: resultMeaningTa,
                explanationVersion: explanationVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diseaseId,
                Value<String?> plantDescriptionEn = const Value.absent(),
                Value<String?> plantDescriptionSi = const Value.absent(),
                Value<String?> plantDescriptionTa = const Value.absent(),
                Value<String?> resultMeaningEn = const Value.absent(),
                Value<String?> resultMeaningSi = const Value.absent(),
                Value<String?> resultMeaningTa = const Value.absent(),
                Value<String?> explanationVersion = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseExplanationTableCompanion.insert(
                id: id,
                diseaseId: diseaseId,
                plantDescriptionEn: plantDescriptionEn,
                plantDescriptionSi: plantDescriptionSi,
                plantDescriptionTa: plantDescriptionTa,
                resultMeaningEn: resultMeaningEn,
                resultMeaningSi: resultMeaningSi,
                resultMeaningTa: resultMeaningTa,
                explanationVersion: explanationVersion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiseaseExplanationTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diseaseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diseaseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.diseaseId,
                                referencedTable:
                                    $$DiseaseExplanationTableTableReferences
                                        ._diseaseIdTable(db),
                                referencedColumn:
                                    $$DiseaseExplanationTableTableReferences
                                        ._diseaseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiseaseExplanationTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiseaseExplanationTableTable,
      DiseaseExplanationTableData,
      $$DiseaseExplanationTableTableFilterComposer,
      $$DiseaseExplanationTableTableOrderingComposer,
      $$DiseaseExplanationTableTableAnnotationComposer,
      $$DiseaseExplanationTableTableCreateCompanionBuilder,
      $$DiseaseExplanationTableTableUpdateCompanionBuilder,
      (DiseaseExplanationTableData, $$DiseaseExplanationTableTableReferences),
      DiseaseExplanationTableData,
      PrefetchHooks Function({bool diseaseId})
    >;
typedef $$DiseaseConfusionTableTableCreateCompanionBuilder =
    DiseaseConfusionTableCompanion Function({
      required String id,
      required String diseaseId,
      Value<String?> confusedWithDiseaseId,
      Value<String?> confusedWithLabelEn,
      Value<String?> confusedWithLabelSi,
      Value<String?> confusedWithLabelTa,
      Value<String?> distinguishingSymptomsEn,
      Value<String?> distinguishingSymptomsSi,
      Value<String?> distinguishingSymptomsTa,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$DiseaseConfusionTableTableUpdateCompanionBuilder =
    DiseaseConfusionTableCompanion Function({
      Value<String> id,
      Value<String> diseaseId,
      Value<String?> confusedWithDiseaseId,
      Value<String?> confusedWithLabelEn,
      Value<String?> confusedWithLabelSi,
      Value<String?> confusedWithLabelTa,
      Value<String?> distinguishingSymptomsEn,
      Value<String?> distinguishingSymptomsSi,
      Value<String?> distinguishingSymptomsTa,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$DiseaseConfusionTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DiseaseConfusionTableTable,
          DiseaseConfusionTableData
        > {
  $$DiseaseConfusionTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiseaseTableTable _diseaseIdTable(_$AppDatabase db) =>
      db.diseaseTable.createAlias('disease_confusion__disease_id__disease__id');

  $$DiseaseTableTableProcessedTableManager get diseaseId {
    final $_column = $_itemColumn<String>('disease_id')!;

    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diseaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DiseaseTableTable _confusedWithDiseaseIdTable(_$AppDatabase db) => db
      .diseaseTable
      .createAlias('disease_confusion__confused_with_disease_id__disease__id');

  $$DiseaseTableTableProcessedTableManager? get confusedWithDiseaseId {
    final $_column = $_itemColumn<String>('confused_with_disease_id');
    if ($_column == null) return null;
    final manager = $$DiseaseTableTableTableManager(
      $_db,
      $_db.diseaseTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _confusedWithDiseaseIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiseaseConfusionTableTableFilterComposer
    extends Composer<_$AppDatabase, $DiseaseConfusionTableTable> {
  $$DiseaseConfusionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confusedWithLabelEn => $composableBuilder(
    column: $table.confusedWithLabelEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confusedWithLabelSi => $composableBuilder(
    column: $table.confusedWithLabelSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confusedWithLabelTa => $composableBuilder(
    column: $table.confusedWithLabelTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distinguishingSymptomsEn => $composableBuilder(
    column: $table.distinguishingSymptomsEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distinguishingSymptomsSi => $composableBuilder(
    column: $table.distinguishingSymptomsSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distinguishingSymptomsTa => $composableBuilder(
    column: $table.distinguishingSymptomsTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$DiseaseTableTableFilterComposer get diseaseId {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableFilterComposer get confusedWithDiseaseId {
    final $$DiseaseTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.confusedWithDiseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableFilterComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseConfusionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DiseaseConfusionTableTable> {
  $$DiseaseConfusionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confusedWithLabelEn => $composableBuilder(
    column: $table.confusedWithLabelEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confusedWithLabelSi => $composableBuilder(
    column: $table.confusedWithLabelSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confusedWithLabelTa => $composableBuilder(
    column: $table.confusedWithLabelTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distinguishingSymptomsEn => $composableBuilder(
    column: $table.distinguishingSymptomsEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distinguishingSymptomsSi => $composableBuilder(
    column: $table.distinguishingSymptomsSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distinguishingSymptomsTa => $composableBuilder(
    column: $table.distinguishingSymptomsTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiseaseTableTableOrderingComposer get diseaseId {
    final $$DiseaseTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableOrderingComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableOrderingComposer get confusedWithDiseaseId {
    final $$DiseaseTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.confusedWithDiseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableOrderingComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseConfusionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiseaseConfusionTableTable> {
  $$DiseaseConfusionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get confusedWithLabelEn => $composableBuilder(
    column: $table.confusedWithLabelEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confusedWithLabelSi => $composableBuilder(
    column: $table.confusedWithLabelSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confusedWithLabelTa => $composableBuilder(
    column: $table.confusedWithLabelTa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distinguishingSymptomsEn => $composableBuilder(
    column: $table.distinguishingSymptomsEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distinguishingSymptomsSi => $composableBuilder(
    column: $table.distinguishingSymptomsSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get distinguishingSymptomsTa => $composableBuilder(
    column: $table.distinguishingSymptomsTa,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$DiseaseTableTableAnnotationComposer get diseaseId {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiseaseTableTableAnnotationComposer get confusedWithDiseaseId {
    final $$DiseaseTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.confusedWithDiseaseId,
      referencedTable: $db.diseaseTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiseaseTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diseaseTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiseaseConfusionTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiseaseConfusionTableTable,
          DiseaseConfusionTableData,
          $$DiseaseConfusionTableTableFilterComposer,
          $$DiseaseConfusionTableTableOrderingComposer,
          $$DiseaseConfusionTableTableAnnotationComposer,
          $$DiseaseConfusionTableTableCreateCompanionBuilder,
          $$DiseaseConfusionTableTableUpdateCompanionBuilder,
          (DiseaseConfusionTableData, $$DiseaseConfusionTableTableReferences),
          DiseaseConfusionTableData,
          PrefetchHooks Function({bool diseaseId, bool confusedWithDiseaseId})
        > {
  $$DiseaseConfusionTableTableTableManager(
    _$AppDatabase db,
    $DiseaseConfusionTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiseaseConfusionTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DiseaseConfusionTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DiseaseConfusionTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diseaseId = const Value.absent(),
                Value<String?> confusedWithDiseaseId = const Value.absent(),
                Value<String?> confusedWithLabelEn = const Value.absent(),
                Value<String?> confusedWithLabelSi = const Value.absent(),
                Value<String?> confusedWithLabelTa = const Value.absent(),
                Value<String?> distinguishingSymptomsEn = const Value.absent(),
                Value<String?> distinguishingSymptomsSi = const Value.absent(),
                Value<String?> distinguishingSymptomsTa = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseConfusionTableCompanion(
                id: id,
                diseaseId: diseaseId,
                confusedWithDiseaseId: confusedWithDiseaseId,
                confusedWithLabelEn: confusedWithLabelEn,
                confusedWithLabelSi: confusedWithLabelSi,
                confusedWithLabelTa: confusedWithLabelTa,
                distinguishingSymptomsEn: distinguishingSymptomsEn,
                distinguishingSymptomsSi: distinguishingSymptomsSi,
                distinguishingSymptomsTa: distinguishingSymptomsTa,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diseaseId,
                Value<String?> confusedWithDiseaseId = const Value.absent(),
                Value<String?> confusedWithLabelEn = const Value.absent(),
                Value<String?> confusedWithLabelSi = const Value.absent(),
                Value<String?> confusedWithLabelTa = const Value.absent(),
                Value<String?> distinguishingSymptomsEn = const Value.absent(),
                Value<String?> distinguishingSymptomsSi = const Value.absent(),
                Value<String?> distinguishingSymptomsTa = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiseaseConfusionTableCompanion.insert(
                id: id,
                diseaseId: diseaseId,
                confusedWithDiseaseId: confusedWithDiseaseId,
                confusedWithLabelEn: confusedWithLabelEn,
                confusedWithLabelSi: confusedWithLabelSi,
                confusedWithLabelTa: confusedWithLabelTa,
                distinguishingSymptomsEn: distinguishingSymptomsEn,
                distinguishingSymptomsSi: distinguishingSymptomsSi,
                distinguishingSymptomsTa: distinguishingSymptomsTa,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiseaseConfusionTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({diseaseId = false, confusedWithDiseaseId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (diseaseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.diseaseId,
                                    referencedTable:
                                        $$DiseaseConfusionTableTableReferences
                                            ._diseaseIdTable(db),
                                    referencedColumn:
                                        $$DiseaseConfusionTableTableReferences
                                            ._diseaseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (confusedWithDiseaseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.confusedWithDiseaseId,
                                    referencedTable:
                                        $$DiseaseConfusionTableTableReferences
                                            ._confusedWithDiseaseIdTable(db),
                                    referencedColumn:
                                        $$DiseaseConfusionTableTableReferences
                                            ._confusedWithDiseaseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$DiseaseConfusionTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiseaseConfusionTableTable,
      DiseaseConfusionTableData,
      $$DiseaseConfusionTableTableFilterComposer,
      $$DiseaseConfusionTableTableOrderingComposer,
      $$DiseaseConfusionTableTableAnnotationComposer,
      $$DiseaseConfusionTableTableCreateCompanionBuilder,
      $$DiseaseConfusionTableTableUpdateCompanionBuilder,
      (DiseaseConfusionTableData, $$DiseaseConfusionTableTableReferences),
      DiseaseConfusionTableData,
      PrefetchHooks Function({bool diseaseId, bool confusedWithDiseaseId})
    >;
typedef $$ChatMessageTableTableCreateCompanionBuilder =
    ChatMessageTableCompanion Function({
      required String id,
      required String diagnosisId,
      required String role,
      required String content,
      required String languageCode,
      Value<String> status,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessageTableTableUpdateCompanionBuilder =
    ChatMessageTableCompanion Function({
      Value<String> id,
      Value<String> diagnosisId,
      Value<String> role,
      Value<String> content,
      Value<String> languageCode,
      Value<String> status,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$ChatMessageTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ChatMessageTableTable,
          ChatMessageTableData
        > {
  $$ChatMessageTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiagnosisTableTable _diagnosisIdTable(_$AppDatabase db) => db
      .diagnosisTable
      .createAlias('chat_message__diagnosis_id__diagnosis__id');

  $$DiagnosisTableTableProcessedTableManager get diagnosisId {
    final $_column = $_itemColumn<String>('diagnosis_id')!;

    final manager = $$DiagnosisTableTableTableManager(
      $_db,
      $_db.diagnosisTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diagnosisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatMessageTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessageTableTable> {
  $$ChatMessageTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DiagnosisTableTableFilterComposer get diagnosisId {
    final $$DiagnosisTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableFilterComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessageTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessageTableTable> {
  $$ChatMessageTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiagnosisTableTableOrderingComposer get diagnosisId {
    final $$DiagnosisTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableOrderingComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessageTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessageTableTable> {
  $$ChatMessageTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DiagnosisTableTableAnnotationComposer get diagnosisId {
    final $$DiagnosisTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diagnosisId,
      referencedTable: $db.diagnosisTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiagnosisTableTableAnnotationComposer(
            $db: $db,
            $table: $db.diagnosisTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessageTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessageTableTable,
          ChatMessageTableData,
          $$ChatMessageTableTableFilterComposer,
          $$ChatMessageTableTableOrderingComposer,
          $$ChatMessageTableTableAnnotationComposer,
          $$ChatMessageTableTableCreateCompanionBuilder,
          $$ChatMessageTableTableUpdateCompanionBuilder,
          (ChatMessageTableData, $$ChatMessageTableTableReferences),
          ChatMessageTableData,
          PrefetchHooks Function({bool diagnosisId})
        > {
  $$ChatMessageTableTableTableManager(
    _$AppDatabase db,
    $ChatMessageTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessageTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessageTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessageTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diagnosisId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessageTableCompanion(
                id: id,
                diagnosisId: diagnosisId,
                role: role,
                content: content,
                languageCode: languageCode,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diagnosisId,
                required String role,
                required String content,
                required String languageCode,
                Value<String> status = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatMessageTableCompanion.insert(
                id: id,
                diagnosisId: diagnosisId,
                role: role,
                content: content,
                languageCode: languageCode,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatMessageTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diagnosisId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diagnosisId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.diagnosisId,
                                referencedTable:
                                    $$ChatMessageTableTableReferences
                                        ._diagnosisIdTable(db),
                                referencedColumn:
                                    $$ChatMessageTableTableReferences
                                        ._diagnosisIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessageTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessageTableTable,
      ChatMessageTableData,
      $$ChatMessageTableTableFilterComposer,
      $$ChatMessageTableTableOrderingComposer,
      $$ChatMessageTableTableAnnotationComposer,
      $$ChatMessageTableTableCreateCompanionBuilder,
      $$ChatMessageTableTableUpdateCompanionBuilder,
      (ChatMessageTableData, $$ChatMessageTableTableReferences),
      ChatMessageTableData,
      PrefetchHooks Function({bool diagnosisId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppStateTableTableTableManager get appStateTable =>
      $$AppStateTableTableTableManager(_db, _db.appStateTable);
  $$LocalUserTableTableTableManager get localUserTable =>
      $$LocalUserTableTableTableManager(_db, _db.localUserTable);
  $$CropTableTableTableManager get cropTable =>
      $$CropTableTableTableManager(_db, _db.cropTable);
  $$DiseaseTableTableTableManager get diseaseTable =>
      $$DiseaseTableTableTableManager(_db, _db.diseaseTable);
  $$TreatmentGuidelineTableTableTableManager get treatmentGuidelineTable =>
      $$TreatmentGuidelineTableTableTableManager(
        _db,
        _db.treatmentGuidelineTable,
      );
  $$ModelVersionTableTableTableManager get modelVersionTable =>
      $$ModelVersionTableTableTableManager(_db, _db.modelVersionTable);
  $$ScanTableTableTableManager get scanTable =>
      $$ScanTableTableTableManager(_db, _db.scanTable);
  $$ImageValidationTableTableTableManager get imageValidationTable =>
      $$ImageValidationTableTableTableManager(_db, _db.imageValidationTable);
  $$DiagnosisTableTableTableManager get diagnosisTable =>
      $$DiagnosisTableTableTableManager(_db, _db.diagnosisTable);
  $$EscalationTableTableTableManager get escalationTable =>
      $$EscalationTableTableTableManager(_db, _db.escalationTable);
  $$SyncOperationTableTableTableManager get syncOperationTable =>
      $$SyncOperationTableTableTableManager(_db, _db.syncOperationTable);
  $$DiseaseExplanationTableTableTableManager get diseaseExplanationTable =>
      $$DiseaseExplanationTableTableTableManager(
        _db,
        _db.diseaseExplanationTable,
      );
  $$DiseaseConfusionTableTableTableManager get diseaseConfusionTable =>
      $$DiseaseConfusionTableTableTableManager(_db, _db.diseaseConfusionTable);
  $$ChatMessageTableTableTableManager get chatMessageTable =>
      $$ChatMessageTableTableTableManager(_db, _db.chatMessageTable);
}
