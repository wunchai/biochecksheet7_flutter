// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $JobsTable extends Jobs with TableInfo<$JobsTable, DbJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'jobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobNameMeta =
      const VerificationMeta('jobName');
  @override
  late final GeneratedColumn<String> jobName = GeneratedColumn<String>(
      'JobName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineNameMeta =
      const VerificationMeta('machineName');
  @override
  late final GeneratedColumn<String> machineName = GeneratedColumn<String>(
      'MachineName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'DocumentId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'Location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobStatusMeta =
      const VerificationMeta('jobStatus');
  @override
  late final GeneratedColumn<int> jobStatus = GeneratedColumn<int>(
      'JobStatus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        jobId,
        jobName,
        machineName,
        documentId,
        location,
        jobStatus,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(Insertable<DbJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('jobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['jobId']!, _jobIdMeta));
    }
    if (data.containsKey('JobName')) {
      context.handle(_jobNameMeta,
          jobName.isAcceptableOrUnknown(data['JobName']!, _jobNameMeta));
    }
    if (data.containsKey('MachineName')) {
      context.handle(
          _machineNameMeta,
          machineName.isAcceptableOrUnknown(
              data['MachineName']!, _machineNameMeta));
    }
    if (data.containsKey('DocumentId')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['DocumentId']!, _documentIdMeta));
    }
    if (data.containsKey('Location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['Location']!, _locationMeta));
    }
    if (data.containsKey('JobStatus')) {
      context.handle(_jobStatusMeta,
          jobStatus.isAcceptableOrUnknown(data['JobStatus']!, _jobStatusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbJob(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jobId']),
      jobName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}JobName']),
      machineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineName']),
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}DocumentId']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Location']),
      jobStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}JobStatus'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class DbJob extends DataClass implements Insertable<DbJob> {
  final int uid;
  final String? jobId;
  final String? jobName;
  final String? machineName;
  final String? documentId;
  final String? location;
  final int jobStatus;
  final String? lastSync;
  const DbJob(
      {required this.uid,
      this.jobId,
      this.jobName,
      this.machineName,
      this.documentId,
      this.location,
      required this.jobStatus,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || jobId != null) {
      map['jobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || jobName != null) {
      map['JobName'] = Variable<String>(jobName);
    }
    if (!nullToAbsent || machineName != null) {
      map['MachineName'] = Variable<String>(machineName);
    }
    if (!nullToAbsent || documentId != null) {
      map['DocumentId'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || location != null) {
      map['Location'] = Variable<String>(location);
    }
    map['JobStatus'] = Variable<int>(jobStatus);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      uid: Value(uid),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      jobName: jobName == null && nullToAbsent
          ? const Value.absent()
          : Value(jobName),
      machineName: machineName == null && nullToAbsent
          ? const Value.absent()
          : Value(machineName),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      jobStatus: Value(jobStatus),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbJob(
      uid: serializer.fromJson<int>(json['uid']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      jobName: serializer.fromJson<String?>(json['jobName']),
      machineName: serializer.fromJson<String?>(json['machineName']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      location: serializer.fromJson<String?>(json['location']),
      jobStatus: serializer.fromJson<int>(json['jobStatus']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'jobId': serializer.toJson<String?>(jobId),
      'jobName': serializer.toJson<String?>(jobName),
      'machineName': serializer.toJson<String?>(machineName),
      'documentId': serializer.toJson<String?>(documentId),
      'location': serializer.toJson<String?>(location),
      'jobStatus': serializer.toJson<int>(jobStatus),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbJob copyWith(
          {int? uid,
          Value<String?> jobId = const Value.absent(),
          Value<String?> jobName = const Value.absent(),
          Value<String?> machineName = const Value.absent(),
          Value<String?> documentId = const Value.absent(),
          Value<String?> location = const Value.absent(),
          int? jobStatus,
          Value<String?> lastSync = const Value.absent()}) =>
      DbJob(
        uid: uid ?? this.uid,
        jobId: jobId.present ? jobId.value : this.jobId,
        jobName: jobName.present ? jobName.value : this.jobName,
        machineName: machineName.present ? machineName.value : this.machineName,
        documentId: documentId.present ? documentId.value : this.documentId,
        location: location.present ? location.value : this.location,
        jobStatus: jobStatus ?? this.jobStatus,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbJob copyWithCompanion(JobsCompanion data) {
    return DbJob(
      uid: data.uid.present ? data.uid.value : this.uid,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      jobName: data.jobName.present ? data.jobName.value : this.jobName,
      machineName:
          data.machineName.present ? data.machineName.value : this.machineName,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      location: data.location.present ? data.location.value : this.location,
      jobStatus: data.jobStatus.present ? data.jobStatus.value : this.jobStatus,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbJob(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('jobName: $jobName, ')
          ..write('machineName: $machineName, ')
          ..write('documentId: $documentId, ')
          ..write('location: $location, ')
          ..write('jobStatus: $jobStatus, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, jobId, jobName, machineName, documentId,
      location, jobStatus, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbJob &&
          other.uid == this.uid &&
          other.jobId == this.jobId &&
          other.jobName == this.jobName &&
          other.machineName == this.machineName &&
          other.documentId == this.documentId &&
          other.location == this.location &&
          other.jobStatus == this.jobStatus &&
          other.lastSync == this.lastSync);
}

class JobsCompanion extends UpdateCompanion<DbJob> {
  final Value<int> uid;
  final Value<String?> jobId;
  final Value<String?> jobName;
  final Value<String?> machineName;
  final Value<String?> documentId;
  final Value<String?> location;
  final Value<int> jobStatus;
  final Value<String?> lastSync;
  const JobsCompanion({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.jobName = const Value.absent(),
    this.machineName = const Value.absent(),
    this.documentId = const Value.absent(),
    this.location = const Value.absent(),
    this.jobStatus = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  JobsCompanion.insert({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.jobName = const Value.absent(),
    this.machineName = const Value.absent(),
    this.documentId = const Value.absent(),
    this.location = const Value.absent(),
    this.jobStatus = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbJob> custom({
    Expression<int>? uid,
    Expression<String>? jobId,
    Expression<String>? jobName,
    Expression<String>? machineName,
    Expression<String>? documentId,
    Expression<String>? location,
    Expression<int>? jobStatus,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (jobId != null) 'jobId': jobId,
      if (jobName != null) 'JobName': jobName,
      if (machineName != null) 'MachineName': machineName,
      if (documentId != null) 'DocumentId': documentId,
      if (location != null) 'Location': location,
      if (jobStatus != null) 'JobStatus': jobStatus,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  JobsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? jobId,
      Value<String?>? jobName,
      Value<String?>? machineName,
      Value<String?>? documentId,
      Value<String?>? location,
      Value<int>? jobStatus,
      Value<String?>? lastSync}) {
    return JobsCompanion(
      uid: uid ?? this.uid,
      jobId: jobId ?? this.jobId,
      jobName: jobName ?? this.jobName,
      machineName: machineName ?? this.machineName,
      documentId: documentId ?? this.documentId,
      location: location ?? this.location,
      jobStatus: jobStatus ?? this.jobStatus,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (jobId.present) {
      map['jobId'] = Variable<String>(jobId.value);
    }
    if (jobName.present) {
      map['JobName'] = Variable<String>(jobName.value);
    }
    if (machineName.present) {
      map['MachineName'] = Variable<String>(machineName.value);
    }
    if (documentId.present) {
      map['DocumentId'] = Variable<String>(documentId.value);
    }
    if (location.present) {
      map['Location'] = Variable<String>(location.value);
    }
    if (jobStatus.present) {
      map['JobStatus'] = Variable<int>(jobStatus.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('jobName: $jobName, ')
          ..write('machineName: $machineName, ')
          ..write('documentId: $documentId, ')
          ..write('location: $location, ')
          ..write('jobStatus: $jobStatus, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DbDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'documentId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'jobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _documentNameMeta =
      const VerificationMeta('documentName');
  @override
  late final GeneratedColumn<String> documentName = GeneratedColumn<String>(
      'documentName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'userId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createDateMeta =
      const VerificationMeta('createDate');
  @override
  late final GeneratedColumn<String> createDate = GeneratedColumn<String>(
      'createDate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        documentId,
        jobId,
        documentName,
        userId,
        createDate,
        status,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<DbDocument> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('documentId')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['documentId']!, _documentIdMeta));
    }
    if (data.containsKey('jobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['jobId']!, _jobIdMeta));
    }
    if (data.containsKey('documentName')) {
      context.handle(
          _documentNameMeta,
          documentName.isAcceptableOrUnknown(
              data['documentName']!, _documentNameMeta));
    }
    if (data.containsKey('userId')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['userId']!, _userIdMeta));
    }
    if (data.containsKey('createDate')) {
      context.handle(
          _createDateMeta,
          createDate.isAcceptableOrUnknown(
              data['createDate']!, _createDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbDocument(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}documentId']),
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jobId']),
      documentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}documentName']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}userId']),
      createDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}createDate']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DbDocument extends DataClass implements Insertable<DbDocument> {
  final int uid;
  final String? documentId;
  final String? jobId;
  final String? documentName;
  final String? userId;
  final String? createDate;
  final int status;
  final String? lastSync;
  const DbDocument(
      {required this.uid,
      this.documentId,
      this.jobId,
      this.documentName,
      this.userId,
      this.createDate,
      required this.status,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || documentId != null) {
      map['documentId'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || jobId != null) {
      map['jobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || documentName != null) {
      map['documentName'] = Variable<String>(documentName);
    }
    if (!nullToAbsent || userId != null) {
      map['userId'] = Variable<String>(userId);
    }
    if (!nullToAbsent || createDate != null) {
      map['createDate'] = Variable<String>(createDate);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      uid: Value(uid),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      documentName: documentName == null && nullToAbsent
          ? const Value.absent()
          : Value(documentName),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      createDate: createDate == null && nullToAbsent
          ? const Value.absent()
          : Value(createDate),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbDocument.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbDocument(
      uid: serializer.fromJson<int>(json['uid']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      documentName: serializer.fromJson<String?>(json['documentName']),
      userId: serializer.fromJson<String?>(json['userId']),
      createDate: serializer.fromJson<String?>(json['createDate']),
      status: serializer.fromJson<int>(json['status']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'documentId': serializer.toJson<String?>(documentId),
      'jobId': serializer.toJson<String?>(jobId),
      'documentName': serializer.toJson<String?>(documentName),
      'userId': serializer.toJson<String?>(userId),
      'createDate': serializer.toJson<String?>(createDate),
      'status': serializer.toJson<int>(status),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbDocument copyWith(
          {int? uid,
          Value<String?> documentId = const Value.absent(),
          Value<String?> jobId = const Value.absent(),
          Value<String?> documentName = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> createDate = const Value.absent(),
          int? status,
          Value<String?> lastSync = const Value.absent()}) =>
      DbDocument(
        uid: uid ?? this.uid,
        documentId: documentId.present ? documentId.value : this.documentId,
        jobId: jobId.present ? jobId.value : this.jobId,
        documentName:
            documentName.present ? documentName.value : this.documentName,
        userId: userId.present ? userId.value : this.userId,
        createDate: createDate.present ? createDate.value : this.createDate,
        status: status ?? this.status,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbDocument copyWithCompanion(DocumentsCompanion data) {
    return DbDocument(
      uid: data.uid.present ? data.uid.value : this.uid,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      documentName: data.documentName.present
          ? data.documentName.value
          : this.documentName,
      userId: data.userId.present ? data.userId.value : this.userId,
      createDate:
          data.createDate.present ? data.createDate.value : this.createDate,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbDocument(')
          ..write('uid: $uid, ')
          ..write('documentId: $documentId, ')
          ..write('jobId: $jobId, ')
          ..write('documentName: $documentName, ')
          ..write('userId: $userId, ')
          ..write('createDate: $createDate, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, documentId, jobId, documentName, userId,
      createDate, status, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbDocument &&
          other.uid == this.uid &&
          other.documentId == this.documentId &&
          other.jobId == this.jobId &&
          other.documentName == this.documentName &&
          other.userId == this.userId &&
          other.createDate == this.createDate &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class DocumentsCompanion extends UpdateCompanion<DbDocument> {
  final Value<int> uid;
  final Value<String?> documentId;
  final Value<String?> jobId;
  final Value<String?> documentName;
  final Value<String?> userId;
  final Value<String?> createDate;
  final Value<int> status;
  final Value<String?> lastSync;
  const DocumentsCompanion({
    this.uid = const Value.absent(),
    this.documentId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.documentName = const Value.absent(),
    this.userId = const Value.absent(),
    this.createDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  DocumentsCompanion.insert({
    this.uid = const Value.absent(),
    this.documentId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.documentName = const Value.absent(),
    this.userId = const Value.absent(),
    this.createDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbDocument> custom({
    Expression<int>? uid,
    Expression<String>? documentId,
    Expression<String>? jobId,
    Expression<String>? documentName,
    Expression<String>? userId,
    Expression<String>? createDate,
    Expression<int>? status,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (documentId != null) 'documentId': documentId,
      if (jobId != null) 'jobId': jobId,
      if (documentName != null) 'documentName': documentName,
      if (userId != null) 'userId': userId,
      if (createDate != null) 'createDate': createDate,
      if (status != null) 'status': status,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  DocumentsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? documentId,
      Value<String?>? jobId,
      Value<String?>? documentName,
      Value<String?>? userId,
      Value<String?>? createDate,
      Value<int>? status,
      Value<String?>? lastSync}) {
    return DocumentsCompanion(
      uid: uid ?? this.uid,
      documentId: documentId ?? this.documentId,
      jobId: jobId ?? this.jobId,
      documentName: documentName ?? this.documentName,
      userId: userId ?? this.userId,
      createDate: createDate ?? this.createDate,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (documentId.present) {
      map['documentId'] = Variable<String>(documentId.value);
    }
    if (jobId.present) {
      map['jobId'] = Variable<String>(jobId.value);
    }
    if (documentName.present) {
      map['documentName'] = Variable<String>(documentName.value);
    }
    if (userId.present) {
      map['userId'] = Variable<String>(userId.value);
    }
    if (createDate.present) {
      map['createDate'] = Variable<String>(createDate.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('uid: $uid, ')
          ..write('documentId: $documentId, ')
          ..write('jobId: $jobId, ')
          ..write('documentName: $documentName, ')
          ..write('userId: $userId, ')
          ..write('createDate: $createDate, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $DocumentMachinesTable extends DocumentMachines
    with TableInfo<$DocumentMachinesTable, DbDocumentMachine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentMachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'JobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'documentId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineIdMeta =
      const VerificationMeta('machineId');
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
      'MachineId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineNameMeta =
      const VerificationMeta('machineName');
  @override
  late final GeneratedColumn<String> machineName = GeneratedColumn<String>(
      'MachineName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineTypeMeta =
      const VerificationMeta('machineType');
  @override
  late final GeneratedColumn<String> machineType = GeneratedColumn<String>(
      'MachineType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'Description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specificationMeta =
      const VerificationMeta('specification');
  @override
  late final GeneratedColumn<String> specification = GeneratedColumn<String>(
      'Specification', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'Status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        jobId,
        documentId,
        machineId,
        machineName,
        machineType,
        description,
        specification,
        status,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_machines';
  @override
  VerificationContext validateIntegrity(Insertable<DbDocumentMachine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('JobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['JobId']!, _jobIdMeta));
    }
    if (data.containsKey('documentId')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['documentId']!, _documentIdMeta));
    }
    if (data.containsKey('MachineId')) {
      context.handle(_machineIdMeta,
          machineId.isAcceptableOrUnknown(data['MachineId']!, _machineIdMeta));
    }
    if (data.containsKey('MachineName')) {
      context.handle(
          _machineNameMeta,
          machineName.isAcceptableOrUnknown(
              data['MachineName']!, _machineNameMeta));
    }
    if (data.containsKey('MachineType')) {
      context.handle(
          _machineTypeMeta,
          machineType.isAcceptableOrUnknown(
              data['MachineType']!, _machineTypeMeta));
    }
    if (data.containsKey('Description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['Description']!, _descriptionMeta));
    }
    if (data.containsKey('Specification')) {
      context.handle(
          _specificationMeta,
          specification.isAcceptableOrUnknown(
              data['Specification']!, _specificationMeta));
    }
    if (data.containsKey('Status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['Status']!, _statusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbDocumentMachine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbDocumentMachine(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}JobId']),
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}documentId']),
      machineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineId']),
      machineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineName']),
      machineType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineType']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Description']),
      specification: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Specification']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}Status'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $DocumentMachinesTable createAlias(String alias) {
    return $DocumentMachinesTable(attachedDatabase, alias);
  }
}

class DbDocumentMachine extends DataClass
    implements Insertable<DbDocumentMachine> {
  final int uid;
  final String? jobId;
  final String? documentId;
  final String? machineId;
  final String? machineName;
  final String? machineType;
  final String? description;
  final String? specification;
  final int status;
  final String? lastSync;
  const DbDocumentMachine(
      {required this.uid,
      this.jobId,
      this.documentId,
      this.machineId,
      this.machineName,
      this.machineType,
      this.description,
      this.specification,
      required this.status,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || jobId != null) {
      map['JobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || documentId != null) {
      map['documentId'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || machineId != null) {
      map['MachineId'] = Variable<String>(machineId);
    }
    if (!nullToAbsent || machineName != null) {
      map['MachineName'] = Variable<String>(machineName);
    }
    if (!nullToAbsent || machineType != null) {
      map['MachineType'] = Variable<String>(machineType);
    }
    if (!nullToAbsent || description != null) {
      map['Description'] = Variable<String>(description);
    }
    if (!nullToAbsent || specification != null) {
      map['Specification'] = Variable<String>(specification);
    }
    map['Status'] = Variable<int>(status);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  DocumentMachinesCompanion toCompanion(bool nullToAbsent) {
    return DocumentMachinesCompanion(
      uid: Value(uid),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      machineId: machineId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineId),
      machineName: machineName == null && nullToAbsent
          ? const Value.absent()
          : Value(machineName),
      machineType: machineType == null && nullToAbsent
          ? const Value.absent()
          : Value(machineType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      specification: specification == null && nullToAbsent
          ? const Value.absent()
          : Value(specification),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbDocumentMachine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbDocumentMachine(
      uid: serializer.fromJson<int>(json['uid']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      machineId: serializer.fromJson<String?>(json['machineId']),
      machineName: serializer.fromJson<String?>(json['machineName']),
      machineType: serializer.fromJson<String?>(json['machineType']),
      description: serializer.fromJson<String?>(json['description']),
      specification: serializer.fromJson<String?>(json['specification']),
      status: serializer.fromJson<int>(json['status']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'jobId': serializer.toJson<String?>(jobId),
      'documentId': serializer.toJson<String?>(documentId),
      'machineId': serializer.toJson<String?>(machineId),
      'machineName': serializer.toJson<String?>(machineName),
      'machineType': serializer.toJson<String?>(machineType),
      'description': serializer.toJson<String?>(description),
      'specification': serializer.toJson<String?>(specification),
      'status': serializer.toJson<int>(status),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbDocumentMachine copyWith(
          {int? uid,
          Value<String?> jobId = const Value.absent(),
          Value<String?> documentId = const Value.absent(),
          Value<String?> machineId = const Value.absent(),
          Value<String?> machineName = const Value.absent(),
          Value<String?> machineType = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> specification = const Value.absent(),
          int? status,
          Value<String?> lastSync = const Value.absent()}) =>
      DbDocumentMachine(
        uid: uid ?? this.uid,
        jobId: jobId.present ? jobId.value : this.jobId,
        documentId: documentId.present ? documentId.value : this.documentId,
        machineId: machineId.present ? machineId.value : this.machineId,
        machineName: machineName.present ? machineName.value : this.machineName,
        machineType: machineType.present ? machineType.value : this.machineType,
        description: description.present ? description.value : this.description,
        specification:
            specification.present ? specification.value : this.specification,
        status: status ?? this.status,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbDocumentMachine copyWithCompanion(DocumentMachinesCompanion data) {
    return DbDocumentMachine(
      uid: data.uid.present ? data.uid.value : this.uid,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      machineName:
          data.machineName.present ? data.machineName.value : this.machineName,
      machineType:
          data.machineType.present ? data.machineType.value : this.machineType,
      description:
          data.description.present ? data.description.value : this.description,
      specification: data.specification.present
          ? data.specification.value
          : this.specification,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbDocumentMachine(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('documentId: $documentId, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('machineType: $machineType, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, jobId, documentId, machineId,
      machineName, machineType, description, specification, status, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbDocumentMachine &&
          other.uid == this.uid &&
          other.jobId == this.jobId &&
          other.documentId == this.documentId &&
          other.machineId == this.machineId &&
          other.machineName == this.machineName &&
          other.machineType == this.machineType &&
          other.description == this.description &&
          other.specification == this.specification &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class DocumentMachinesCompanion extends UpdateCompanion<DbDocumentMachine> {
  final Value<int> uid;
  final Value<String?> jobId;
  final Value<String?> documentId;
  final Value<String?> machineId;
  final Value<String?> machineName;
  final Value<String?> machineType;
  final Value<String?> description;
  final Value<String?> specification;
  final Value<int> status;
  final Value<String?> lastSync;
  const DocumentMachinesCompanion({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.machineName = const Value.absent(),
    this.machineType = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  DocumentMachinesCompanion.insert({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.machineName = const Value.absent(),
    this.machineType = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbDocumentMachine> custom({
    Expression<int>? uid,
    Expression<String>? jobId,
    Expression<String>? documentId,
    Expression<String>? machineId,
    Expression<String>? machineName,
    Expression<String>? machineType,
    Expression<String>? description,
    Expression<String>? specification,
    Expression<int>? status,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (jobId != null) 'JobId': jobId,
      if (documentId != null) 'documentId': documentId,
      if (machineId != null) 'MachineId': machineId,
      if (machineName != null) 'MachineName': machineName,
      if (machineType != null) 'MachineType': machineType,
      if (description != null) 'Description': description,
      if (specification != null) 'Specification': specification,
      if (status != null) 'Status': status,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  DocumentMachinesCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? jobId,
      Value<String?>? documentId,
      Value<String?>? machineId,
      Value<String?>? machineName,
      Value<String?>? machineType,
      Value<String?>? description,
      Value<String?>? specification,
      Value<int>? status,
      Value<String?>? lastSync}) {
    return DocumentMachinesCompanion(
      uid: uid ?? this.uid,
      jobId: jobId ?? this.jobId,
      documentId: documentId ?? this.documentId,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      machineType: machineType ?? this.machineType,
      description: description ?? this.description,
      specification: specification ?? this.specification,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (jobId.present) {
      map['JobId'] = Variable<String>(jobId.value);
    }
    if (documentId.present) {
      map['documentId'] = Variable<String>(documentId.value);
    }
    if (machineId.present) {
      map['MachineId'] = Variable<String>(machineId.value);
    }
    if (machineName.present) {
      map['MachineName'] = Variable<String>(machineName.value);
    }
    if (machineType.present) {
      map['MachineType'] = Variable<String>(machineType.value);
    }
    if (description.present) {
      map['Description'] = Variable<String>(description.value);
    }
    if (specification.present) {
      map['Specification'] = Variable<String>(specification.value);
    }
    if (status.present) {
      map['Status'] = Variable<int>(status.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentMachinesCompanion(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('documentId: $documentId, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('machineType: $machineType, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $DocumentRecordsTable extends DocumentRecords
    with TableInfo<$DocumentRecordsTable, DbDocumentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'documentId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineIdMeta =
      const VerificationMeta('machineId');
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
      'machineId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'jobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tagId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagNameMeta =
      const VerificationMeta('tagName');
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
      'tagName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagTypeMeta =
      const VerificationMeta('tagType');
  @override
  late final GeneratedColumn<String> tagType = GeneratedColumn<String>(
      'tagType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagGroupIdMeta =
      const VerificationMeta('tagGroupId');
  @override
  late final GeneratedColumn<String> tagGroupId = GeneratedColumn<String>(
      'TagGroupId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagGroupNameMeta =
      const VerificationMeta('tagGroupName');
  @override
  late final GeneratedColumn<String> tagGroupName = GeneratedColumn<String>(
      'TagGroupName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagSelectionValueMeta =
      const VerificationMeta('tagSelectionValue');
  @override
  late final GeneratedColumn<String> tagSelectionValue =
      GeneratedColumn<String>('tagSelectionValue', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'Note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specificationMeta =
      const VerificationMeta('specification');
  @override
  late final GeneratedColumn<String> specification = GeneratedColumn<String>(
      'specification', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specMinMeta =
      const VerificationMeta('specMin');
  @override
  late final GeneratedColumn<String> specMin = GeneratedColumn<String>(
      'specMin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specMaxMeta =
      const VerificationMeta('specMax');
  @override
  late final GeneratedColumn<String> specMax = GeneratedColumn<String>(
      'specMax', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _queryStrMeta =
      const VerificationMeta('queryStr');
  @override
  late final GeneratedColumn<String> queryStr = GeneratedColumn<String>(
      'queryStr', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueTypeMeta =
      const VerificationMeta('valueType');
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
      'valueType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
      'remark', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unReadableMeta =
      const VerificationMeta('unReadable');
  @override
  late final GeneratedColumn<String> unReadable = GeneratedColumn<String>(
      'unReadable', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('false'));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        documentId,
        machineId,
        jobId,
        tagId,
        tagName,
        tagType,
        tagGroupId,
        tagGroupName,
        tagSelectionValue,
        description,
        note,
        specification,
        specMin,
        specMax,
        unit,
        queryStr,
        value,
        valueType,
        remark,
        status,
        unReadable,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_records';
  @override
  VerificationContext validateIntegrity(Insertable<DbDocumentRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('documentId')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['documentId']!, _documentIdMeta));
    }
    if (data.containsKey('machineId')) {
      context.handle(_machineIdMeta,
          machineId.isAcceptableOrUnknown(data['machineId']!, _machineIdMeta));
    }
    if (data.containsKey('jobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['jobId']!, _jobIdMeta));
    }
    if (data.containsKey('tagId')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tagId']!, _tagIdMeta));
    }
    if (data.containsKey('tagName')) {
      context.handle(_tagNameMeta,
          tagName.isAcceptableOrUnknown(data['tagName']!, _tagNameMeta));
    }
    if (data.containsKey('tagType')) {
      context.handle(_tagTypeMeta,
          tagType.isAcceptableOrUnknown(data['tagType']!, _tagTypeMeta));
    }
    if (data.containsKey('TagGroupId')) {
      context.handle(
          _tagGroupIdMeta,
          tagGroupId.isAcceptableOrUnknown(
              data['TagGroupId']!, _tagGroupIdMeta));
    }
    if (data.containsKey('TagGroupName')) {
      context.handle(
          _tagGroupNameMeta,
          tagGroupName.isAcceptableOrUnknown(
              data['TagGroupName']!, _tagGroupNameMeta));
    }
    if (data.containsKey('tagSelectionValue')) {
      context.handle(
          _tagSelectionValueMeta,
          tagSelectionValue.isAcceptableOrUnknown(
              data['tagSelectionValue']!, _tagSelectionValueMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('Note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['Note']!, _noteMeta));
    }
    if (data.containsKey('specification')) {
      context.handle(
          _specificationMeta,
          specification.isAcceptableOrUnknown(
              data['specification']!, _specificationMeta));
    }
    if (data.containsKey('specMin')) {
      context.handle(_specMinMeta,
          specMin.isAcceptableOrUnknown(data['specMin']!, _specMinMeta));
    }
    if (data.containsKey('specMax')) {
      context.handle(_specMaxMeta,
          specMax.isAcceptableOrUnknown(data['specMax']!, _specMaxMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('queryStr')) {
      context.handle(_queryStrMeta,
          queryStr.isAcceptableOrUnknown(data['queryStr']!, _queryStrMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('valueType')) {
      context.handle(_valueTypeMeta,
          valueType.isAcceptableOrUnknown(data['valueType']!, _valueTypeMeta));
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta,
          remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('unReadable')) {
      context.handle(
          _unReadableMeta,
          unReadable.isAcceptableOrUnknown(
              data['unReadable']!, _unReadableMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbDocumentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbDocumentRecord(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}documentId']),
      machineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}machineId']),
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jobId']),
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagId']),
      tagName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagName']),
      tagType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagType']),
      tagGroupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}TagGroupId']),
      tagGroupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}TagGroupName']),
      tagSelectionValue: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}tagSelectionValue']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Note']),
      specification: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specification']),
      specMin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specMin']),
      specMax: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specMax']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      queryStr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queryStr']),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      valueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}valueType']),
      remark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remark']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      unReadable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unReadable'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $DocumentRecordsTable createAlias(String alias) {
    return $DocumentRecordsTable(attachedDatabase, alias);
  }
}

class DbDocumentRecord extends DataClass
    implements Insertable<DbDocumentRecord> {
  final int uid;
  final String? documentId;
  final String? machineId;
  final String? jobId;
  final String? tagId;
  final String? tagName;
  final String? tagType;
  final String? tagGroupId;
  final String? tagGroupName;
  final String? tagSelectionValue;
  final String? description;
  final String? note;
  final String? specification;
  final String? specMin;
  final String? specMax;
  final String? unit;
  final String? queryStr;
  final String? value;
  final String? valueType;
  final String? remark;
  final int status;
  final String unReadable;
  final String? lastSync;
  const DbDocumentRecord(
      {required this.uid,
      this.documentId,
      this.machineId,
      this.jobId,
      this.tagId,
      this.tagName,
      this.tagType,
      this.tagGroupId,
      this.tagGroupName,
      this.tagSelectionValue,
      this.description,
      this.note,
      this.specification,
      this.specMin,
      this.specMax,
      this.unit,
      this.queryStr,
      this.value,
      this.valueType,
      this.remark,
      required this.status,
      required this.unReadable,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || documentId != null) {
      map['documentId'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || machineId != null) {
      map['machineId'] = Variable<String>(machineId);
    }
    if (!nullToAbsent || jobId != null) {
      map['jobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || tagId != null) {
      map['tagId'] = Variable<String>(tagId);
    }
    if (!nullToAbsent || tagName != null) {
      map['tagName'] = Variable<String>(tagName);
    }
    if (!nullToAbsent || tagType != null) {
      map['tagType'] = Variable<String>(tagType);
    }
    if (!nullToAbsent || tagGroupId != null) {
      map['TagGroupId'] = Variable<String>(tagGroupId);
    }
    if (!nullToAbsent || tagGroupName != null) {
      map['TagGroupName'] = Variable<String>(tagGroupName);
    }
    if (!nullToAbsent || tagSelectionValue != null) {
      map['tagSelectionValue'] = Variable<String>(tagSelectionValue);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || note != null) {
      map['Note'] = Variable<String>(note);
    }
    if (!nullToAbsent || specification != null) {
      map['specification'] = Variable<String>(specification);
    }
    if (!nullToAbsent || specMin != null) {
      map['specMin'] = Variable<String>(specMin);
    }
    if (!nullToAbsent || specMax != null) {
      map['specMax'] = Variable<String>(specMax);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || queryStr != null) {
      map['queryStr'] = Variable<String>(queryStr);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || valueType != null) {
      map['valueType'] = Variable<String>(valueType);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    map['status'] = Variable<int>(status);
    map['unReadable'] = Variable<String>(unReadable);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  DocumentRecordsCompanion toCompanion(bool nullToAbsent) {
    return DocumentRecordsCompanion(
      uid: Value(uid),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      machineId: machineId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      tagId:
          tagId == null && nullToAbsent ? const Value.absent() : Value(tagId),
      tagName: tagName == null && nullToAbsent
          ? const Value.absent()
          : Value(tagName),
      tagType: tagType == null && nullToAbsent
          ? const Value.absent()
          : Value(tagType),
      tagGroupId: tagGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(tagGroupId),
      tagGroupName: tagGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(tagGroupName),
      tagSelectionValue: tagSelectionValue == null && nullToAbsent
          ? const Value.absent()
          : Value(tagSelectionValue),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      specification: specification == null && nullToAbsent
          ? const Value.absent()
          : Value(specification),
      specMin: specMin == null && nullToAbsent
          ? const Value.absent()
          : Value(specMin),
      specMax: specMax == null && nullToAbsent
          ? const Value.absent()
          : Value(specMax),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      queryStr: queryStr == null && nullToAbsent
          ? const Value.absent()
          : Value(queryStr),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      valueType: valueType == null && nullToAbsent
          ? const Value.absent()
          : Value(valueType),
      remark:
          remark == null && nullToAbsent ? const Value.absent() : Value(remark),
      status: Value(status),
      unReadable: Value(unReadable),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbDocumentRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbDocumentRecord(
      uid: serializer.fromJson<int>(json['uid']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      machineId: serializer.fromJson<String?>(json['machineId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      tagId: serializer.fromJson<String?>(json['tagId']),
      tagName: serializer.fromJson<String?>(json['tagName']),
      tagType: serializer.fromJson<String?>(json['tagType']),
      tagGroupId: serializer.fromJson<String?>(json['tagGroupId']),
      tagGroupName: serializer.fromJson<String?>(json['tagGroupName']),
      tagSelectionValue:
          serializer.fromJson<String?>(json['tagSelectionValue']),
      description: serializer.fromJson<String?>(json['description']),
      note: serializer.fromJson<String?>(json['note']),
      specification: serializer.fromJson<String?>(json['specification']),
      specMin: serializer.fromJson<String?>(json['specMin']),
      specMax: serializer.fromJson<String?>(json['specMax']),
      unit: serializer.fromJson<String?>(json['unit']),
      queryStr: serializer.fromJson<String?>(json['queryStr']),
      value: serializer.fromJson<String?>(json['value']),
      valueType: serializer.fromJson<String?>(json['valueType']),
      remark: serializer.fromJson<String?>(json['remark']),
      status: serializer.fromJson<int>(json['status']),
      unReadable: serializer.fromJson<String>(json['unReadable']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'documentId': serializer.toJson<String?>(documentId),
      'machineId': serializer.toJson<String?>(machineId),
      'jobId': serializer.toJson<String?>(jobId),
      'tagId': serializer.toJson<String?>(tagId),
      'tagName': serializer.toJson<String?>(tagName),
      'tagType': serializer.toJson<String?>(tagType),
      'tagGroupId': serializer.toJson<String?>(tagGroupId),
      'tagGroupName': serializer.toJson<String?>(tagGroupName),
      'tagSelectionValue': serializer.toJson<String?>(tagSelectionValue),
      'description': serializer.toJson<String?>(description),
      'note': serializer.toJson<String?>(note),
      'specification': serializer.toJson<String?>(specification),
      'specMin': serializer.toJson<String?>(specMin),
      'specMax': serializer.toJson<String?>(specMax),
      'unit': serializer.toJson<String?>(unit),
      'queryStr': serializer.toJson<String?>(queryStr),
      'value': serializer.toJson<String?>(value),
      'valueType': serializer.toJson<String?>(valueType),
      'remark': serializer.toJson<String?>(remark),
      'status': serializer.toJson<int>(status),
      'unReadable': serializer.toJson<String>(unReadable),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbDocumentRecord copyWith(
          {int? uid,
          Value<String?> documentId = const Value.absent(),
          Value<String?> machineId = const Value.absent(),
          Value<String?> jobId = const Value.absent(),
          Value<String?> tagId = const Value.absent(),
          Value<String?> tagName = const Value.absent(),
          Value<String?> tagType = const Value.absent(),
          Value<String?> tagGroupId = const Value.absent(),
          Value<String?> tagGroupName = const Value.absent(),
          Value<String?> tagSelectionValue = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> specification = const Value.absent(),
          Value<String?> specMin = const Value.absent(),
          Value<String?> specMax = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<String?> queryStr = const Value.absent(),
          Value<String?> value = const Value.absent(),
          Value<String?> valueType = const Value.absent(),
          Value<String?> remark = const Value.absent(),
          int? status,
          String? unReadable,
          Value<String?> lastSync = const Value.absent()}) =>
      DbDocumentRecord(
        uid: uid ?? this.uid,
        documentId: documentId.present ? documentId.value : this.documentId,
        machineId: machineId.present ? machineId.value : this.machineId,
        jobId: jobId.present ? jobId.value : this.jobId,
        tagId: tagId.present ? tagId.value : this.tagId,
        tagName: tagName.present ? tagName.value : this.tagName,
        tagType: tagType.present ? tagType.value : this.tagType,
        tagGroupId: tagGroupId.present ? tagGroupId.value : this.tagGroupId,
        tagGroupName:
            tagGroupName.present ? tagGroupName.value : this.tagGroupName,
        tagSelectionValue: tagSelectionValue.present
            ? tagSelectionValue.value
            : this.tagSelectionValue,
        description: description.present ? description.value : this.description,
        note: note.present ? note.value : this.note,
        specification:
            specification.present ? specification.value : this.specification,
        specMin: specMin.present ? specMin.value : this.specMin,
        specMax: specMax.present ? specMax.value : this.specMax,
        unit: unit.present ? unit.value : this.unit,
        queryStr: queryStr.present ? queryStr.value : this.queryStr,
        value: value.present ? value.value : this.value,
        valueType: valueType.present ? valueType.value : this.valueType,
        remark: remark.present ? remark.value : this.remark,
        status: status ?? this.status,
        unReadable: unReadable ?? this.unReadable,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbDocumentRecord copyWithCompanion(DocumentRecordsCompanion data) {
    return DbDocumentRecord(
      uid: data.uid.present ? data.uid.value : this.uid,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      tagType: data.tagType.present ? data.tagType.value : this.tagType,
      tagGroupId:
          data.tagGroupId.present ? data.tagGroupId.value : this.tagGroupId,
      tagGroupName: data.tagGroupName.present
          ? data.tagGroupName.value
          : this.tagGroupName,
      tagSelectionValue: data.tagSelectionValue.present
          ? data.tagSelectionValue.value
          : this.tagSelectionValue,
      description:
          data.description.present ? data.description.value : this.description,
      note: data.note.present ? data.note.value : this.note,
      specification: data.specification.present
          ? data.specification.value
          : this.specification,
      specMin: data.specMin.present ? data.specMin.value : this.specMin,
      specMax: data.specMax.present ? data.specMax.value : this.specMax,
      unit: data.unit.present ? data.unit.value : this.unit,
      queryStr: data.queryStr.present ? data.queryStr.value : this.queryStr,
      value: data.value.present ? data.value.value : this.value,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      remark: data.remark.present ? data.remark.value : this.remark,
      status: data.status.present ? data.status.value : this.status,
      unReadable:
          data.unReadable.present ? data.unReadable.value : this.unReadable,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbDocumentRecord(')
          ..write('uid: $uid, ')
          ..write('documentId: $documentId, ')
          ..write('machineId: $machineId, ')
          ..write('jobId: $jobId, ')
          ..write('tagId: $tagId, ')
          ..write('tagName: $tagName, ')
          ..write('tagType: $tagType, ')
          ..write('tagGroupId: $tagGroupId, ')
          ..write('tagGroupName: $tagGroupName, ')
          ..write('tagSelectionValue: $tagSelectionValue, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('specification: $specification, ')
          ..write('specMin: $specMin, ')
          ..write('specMax: $specMax, ')
          ..write('unit: $unit, ')
          ..write('queryStr: $queryStr, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('unReadable: $unReadable, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        uid,
        documentId,
        machineId,
        jobId,
        tagId,
        tagName,
        tagType,
        tagGroupId,
        tagGroupName,
        tagSelectionValue,
        description,
        note,
        specification,
        specMin,
        specMax,
        unit,
        queryStr,
        value,
        valueType,
        remark,
        status,
        unReadable,
        lastSync
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbDocumentRecord &&
          other.uid == this.uid &&
          other.documentId == this.documentId &&
          other.machineId == this.machineId &&
          other.jobId == this.jobId &&
          other.tagId == this.tagId &&
          other.tagName == this.tagName &&
          other.tagType == this.tagType &&
          other.tagGroupId == this.tagGroupId &&
          other.tagGroupName == this.tagGroupName &&
          other.tagSelectionValue == this.tagSelectionValue &&
          other.description == this.description &&
          other.note == this.note &&
          other.specification == this.specification &&
          other.specMin == this.specMin &&
          other.specMax == this.specMax &&
          other.unit == this.unit &&
          other.queryStr == this.queryStr &&
          other.value == this.value &&
          other.valueType == this.valueType &&
          other.remark == this.remark &&
          other.status == this.status &&
          other.unReadable == this.unReadable &&
          other.lastSync == this.lastSync);
}

class DocumentRecordsCompanion extends UpdateCompanion<DbDocumentRecord> {
  final Value<int> uid;
  final Value<String?> documentId;
  final Value<String?> machineId;
  final Value<String?> jobId;
  final Value<String?> tagId;
  final Value<String?> tagName;
  final Value<String?> tagType;
  final Value<String?> tagGroupId;
  final Value<String?> tagGroupName;
  final Value<String?> tagSelectionValue;
  final Value<String?> description;
  final Value<String?> note;
  final Value<String?> specification;
  final Value<String?> specMin;
  final Value<String?> specMax;
  final Value<String?> unit;
  final Value<String?> queryStr;
  final Value<String?> value;
  final Value<String?> valueType;
  final Value<String?> remark;
  final Value<int> status;
  final Value<String> unReadable;
  final Value<String?> lastSync;
  const DocumentRecordsCompanion({
    this.uid = const Value.absent(),
    this.documentId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.tagType = const Value.absent(),
    this.tagGroupId = const Value.absent(),
    this.tagGroupName = const Value.absent(),
    this.tagSelectionValue = const Value.absent(),
    this.description = const Value.absent(),
    this.note = const Value.absent(),
    this.specification = const Value.absent(),
    this.specMin = const Value.absent(),
    this.specMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.queryStr = const Value.absent(),
    this.value = const Value.absent(),
    this.valueType = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.unReadable = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  DocumentRecordsCompanion.insert({
    this.uid = const Value.absent(),
    this.documentId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.tagType = const Value.absent(),
    this.tagGroupId = const Value.absent(),
    this.tagGroupName = const Value.absent(),
    this.tagSelectionValue = const Value.absent(),
    this.description = const Value.absent(),
    this.note = const Value.absent(),
    this.specification = const Value.absent(),
    this.specMin = const Value.absent(),
    this.specMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.queryStr = const Value.absent(),
    this.value = const Value.absent(),
    this.valueType = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.unReadable = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbDocumentRecord> custom({
    Expression<int>? uid,
    Expression<String>? documentId,
    Expression<String>? machineId,
    Expression<String>? jobId,
    Expression<String>? tagId,
    Expression<String>? tagName,
    Expression<String>? tagType,
    Expression<String>? tagGroupId,
    Expression<String>? tagGroupName,
    Expression<String>? tagSelectionValue,
    Expression<String>? description,
    Expression<String>? note,
    Expression<String>? specification,
    Expression<String>? specMin,
    Expression<String>? specMax,
    Expression<String>? unit,
    Expression<String>? queryStr,
    Expression<String>? value,
    Expression<String>? valueType,
    Expression<String>? remark,
    Expression<int>? status,
    Expression<String>? unReadable,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (documentId != null) 'documentId': documentId,
      if (machineId != null) 'machineId': machineId,
      if (jobId != null) 'jobId': jobId,
      if (tagId != null) 'tagId': tagId,
      if (tagName != null) 'tagName': tagName,
      if (tagType != null) 'tagType': tagType,
      if (tagGroupId != null) 'TagGroupId': tagGroupId,
      if (tagGroupName != null) 'TagGroupName': tagGroupName,
      if (tagSelectionValue != null) 'tagSelectionValue': tagSelectionValue,
      if (description != null) 'description': description,
      if (note != null) 'Note': note,
      if (specification != null) 'specification': specification,
      if (specMin != null) 'specMin': specMin,
      if (specMax != null) 'specMax': specMax,
      if (unit != null) 'unit': unit,
      if (queryStr != null) 'queryStr': queryStr,
      if (value != null) 'value': value,
      if (valueType != null) 'valueType': valueType,
      if (remark != null) 'remark': remark,
      if (status != null) 'status': status,
      if (unReadable != null) 'unReadable': unReadable,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  DocumentRecordsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? documentId,
      Value<String?>? machineId,
      Value<String?>? jobId,
      Value<String?>? tagId,
      Value<String?>? tagName,
      Value<String?>? tagType,
      Value<String?>? tagGroupId,
      Value<String?>? tagGroupName,
      Value<String?>? tagSelectionValue,
      Value<String?>? description,
      Value<String?>? note,
      Value<String?>? specification,
      Value<String?>? specMin,
      Value<String?>? specMax,
      Value<String?>? unit,
      Value<String?>? queryStr,
      Value<String?>? value,
      Value<String?>? valueType,
      Value<String?>? remark,
      Value<int>? status,
      Value<String>? unReadable,
      Value<String?>? lastSync}) {
    return DocumentRecordsCompanion(
      uid: uid ?? this.uid,
      documentId: documentId ?? this.documentId,
      machineId: machineId ?? this.machineId,
      jobId: jobId ?? this.jobId,
      tagId: tagId ?? this.tagId,
      tagName: tagName ?? this.tagName,
      tagType: tagType ?? this.tagType,
      tagGroupId: tagGroupId ?? this.tagGroupId,
      tagGroupName: tagGroupName ?? this.tagGroupName,
      tagSelectionValue: tagSelectionValue ?? this.tagSelectionValue,
      description: description ?? this.description,
      note: note ?? this.note,
      specification: specification ?? this.specification,
      specMin: specMin ?? this.specMin,
      specMax: specMax ?? this.specMax,
      unit: unit ?? this.unit,
      queryStr: queryStr ?? this.queryStr,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      unReadable: unReadable ?? this.unReadable,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (documentId.present) {
      map['documentId'] = Variable<String>(documentId.value);
    }
    if (machineId.present) {
      map['machineId'] = Variable<String>(machineId.value);
    }
    if (jobId.present) {
      map['jobId'] = Variable<String>(jobId.value);
    }
    if (tagId.present) {
      map['tagId'] = Variable<String>(tagId.value);
    }
    if (tagName.present) {
      map['tagName'] = Variable<String>(tagName.value);
    }
    if (tagType.present) {
      map['tagType'] = Variable<String>(tagType.value);
    }
    if (tagGroupId.present) {
      map['TagGroupId'] = Variable<String>(tagGroupId.value);
    }
    if (tagGroupName.present) {
      map['TagGroupName'] = Variable<String>(tagGroupName.value);
    }
    if (tagSelectionValue.present) {
      map['tagSelectionValue'] = Variable<String>(tagSelectionValue.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (note.present) {
      map['Note'] = Variable<String>(note.value);
    }
    if (specification.present) {
      map['specification'] = Variable<String>(specification.value);
    }
    if (specMin.present) {
      map['specMin'] = Variable<String>(specMin.value);
    }
    if (specMax.present) {
      map['specMax'] = Variable<String>(specMax.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (queryStr.present) {
      map['queryStr'] = Variable<String>(queryStr.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (valueType.present) {
      map['valueType'] = Variable<String>(valueType.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (unReadable.present) {
      map['unReadable'] = Variable<String>(unReadable.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRecordsCompanion(')
          ..write('uid: $uid, ')
          ..write('documentId: $documentId, ')
          ..write('machineId: $machineId, ')
          ..write('jobId: $jobId, ')
          ..write('tagId: $tagId, ')
          ..write('tagName: $tagName, ')
          ..write('tagType: $tagType, ')
          ..write('tagGroupId: $tagGroupId, ')
          ..write('tagGroupName: $tagGroupName, ')
          ..write('tagSelectionValue: $tagSelectionValue, ')
          ..write('description: $description, ')
          ..write('note: $note, ')
          ..write('specification: $specification, ')
          ..write('specMin: $specMin, ')
          ..write('specMax: $specMax, ')
          ..write('unit: $unit, ')
          ..write('queryStr: $queryStr, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('unReadable: $unReadable, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $JobMachinesTable extends JobMachines
    with TableInfo<$JobMachinesTable, DbJobMachine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobMachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'JobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineIdMeta =
      const VerificationMeta('machineId');
  @override
  late final GeneratedColumn<String> machineId = GeneratedColumn<String>(
      'MachineId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineNameMeta =
      const VerificationMeta('machineName');
  @override
  late final GeneratedColumn<String> machineName = GeneratedColumn<String>(
      'MachineName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _machineTypeMeta =
      const VerificationMeta('machineType');
  @override
  late final GeneratedColumn<String> machineType = GeneratedColumn<String>(
      'MachineType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'Description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specificationMeta =
      const VerificationMeta('specification');
  @override
  late final GeneratedColumn<String> specification = GeneratedColumn<String>(
      'Specification', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'Status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        jobId,
        machineId,
        machineName,
        machineType,
        description,
        specification,
        status,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_machines';
  @override
  VerificationContext validateIntegrity(Insertable<DbJobMachine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('JobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['JobId']!, _jobIdMeta));
    }
    if (data.containsKey('MachineId')) {
      context.handle(_machineIdMeta,
          machineId.isAcceptableOrUnknown(data['MachineId']!, _machineIdMeta));
    }
    if (data.containsKey('MachineName')) {
      context.handle(
          _machineNameMeta,
          machineName.isAcceptableOrUnknown(
              data['MachineName']!, _machineNameMeta));
    }
    if (data.containsKey('MachineType')) {
      context.handle(
          _machineTypeMeta,
          machineType.isAcceptableOrUnknown(
              data['MachineType']!, _machineTypeMeta));
    }
    if (data.containsKey('Description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['Description']!, _descriptionMeta));
    }
    if (data.containsKey('Specification')) {
      context.handle(
          _specificationMeta,
          specification.isAcceptableOrUnknown(
              data['Specification']!, _specificationMeta));
    }
    if (data.containsKey('Status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['Status']!, _statusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbJobMachine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbJobMachine(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}JobId']),
      machineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineId']),
      machineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineName']),
      machineType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}MachineType']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Description']),
      specification: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Specification']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}Status'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $JobMachinesTable createAlias(String alias) {
    return $JobMachinesTable(attachedDatabase, alias);
  }
}

class DbJobMachine extends DataClass implements Insertable<DbJobMachine> {
  final int uid;
  final String? jobId;
  final String? machineId;
  final String? machineName;
  final String? machineType;
  final String? description;
  final String? specification;
  final int status;
  final String? lastSync;
  const DbJobMachine(
      {required this.uid,
      this.jobId,
      this.machineId,
      this.machineName,
      this.machineType,
      this.description,
      this.specification,
      required this.status,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || jobId != null) {
      map['JobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || machineId != null) {
      map['MachineId'] = Variable<String>(machineId);
    }
    if (!nullToAbsent || machineName != null) {
      map['MachineName'] = Variable<String>(machineName);
    }
    if (!nullToAbsent || machineType != null) {
      map['MachineType'] = Variable<String>(machineType);
    }
    if (!nullToAbsent || description != null) {
      map['Description'] = Variable<String>(description);
    }
    if (!nullToAbsent || specification != null) {
      map['Specification'] = Variable<String>(specification);
    }
    map['Status'] = Variable<int>(status);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  JobMachinesCompanion toCompanion(bool nullToAbsent) {
    return JobMachinesCompanion(
      uid: Value(uid),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      machineId: machineId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineId),
      machineName: machineName == null && nullToAbsent
          ? const Value.absent()
          : Value(machineName),
      machineType: machineType == null && nullToAbsent
          ? const Value.absent()
          : Value(machineType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      specification: specification == null && nullToAbsent
          ? const Value.absent()
          : Value(specification),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbJobMachine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbJobMachine(
      uid: serializer.fromJson<int>(json['uid']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      machineId: serializer.fromJson<String?>(json['machineId']),
      machineName: serializer.fromJson<String?>(json['machineName']),
      machineType: serializer.fromJson<String?>(json['machineType']),
      description: serializer.fromJson<String?>(json['description']),
      specification: serializer.fromJson<String?>(json['specification']),
      status: serializer.fromJson<int>(json['status']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'jobId': serializer.toJson<String?>(jobId),
      'machineId': serializer.toJson<String?>(machineId),
      'machineName': serializer.toJson<String?>(machineName),
      'machineType': serializer.toJson<String?>(machineType),
      'description': serializer.toJson<String?>(description),
      'specification': serializer.toJson<String?>(specification),
      'status': serializer.toJson<int>(status),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbJobMachine copyWith(
          {int? uid,
          Value<String?> jobId = const Value.absent(),
          Value<String?> machineId = const Value.absent(),
          Value<String?> machineName = const Value.absent(),
          Value<String?> machineType = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> specification = const Value.absent(),
          int? status,
          Value<String?> lastSync = const Value.absent()}) =>
      DbJobMachine(
        uid: uid ?? this.uid,
        jobId: jobId.present ? jobId.value : this.jobId,
        machineId: machineId.present ? machineId.value : this.machineId,
        machineName: machineName.present ? machineName.value : this.machineName,
        machineType: machineType.present ? machineType.value : this.machineType,
        description: description.present ? description.value : this.description,
        specification:
            specification.present ? specification.value : this.specification,
        status: status ?? this.status,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbJobMachine copyWithCompanion(JobMachinesCompanion data) {
    return DbJobMachine(
      uid: data.uid.present ? data.uid.value : this.uid,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      machineId: data.machineId.present ? data.machineId.value : this.machineId,
      machineName:
          data.machineName.present ? data.machineName.value : this.machineName,
      machineType:
          data.machineType.present ? data.machineType.value : this.machineType,
      description:
          data.description.present ? data.description.value : this.description,
      specification: data.specification.present
          ? data.specification.value
          : this.specification,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbJobMachine(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('machineType: $machineType, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, jobId, machineId, machineName,
      machineType, description, specification, status, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbJobMachine &&
          other.uid == this.uid &&
          other.jobId == this.jobId &&
          other.machineId == this.machineId &&
          other.machineName == this.machineName &&
          other.machineType == this.machineType &&
          other.description == this.description &&
          other.specification == this.specification &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class JobMachinesCompanion extends UpdateCompanion<DbJobMachine> {
  final Value<int> uid;
  final Value<String?> jobId;
  final Value<String?> machineId;
  final Value<String?> machineName;
  final Value<String?> machineType;
  final Value<String?> description;
  final Value<String?> specification;
  final Value<int> status;
  final Value<String?> lastSync;
  const JobMachinesCompanion({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.machineName = const Value.absent(),
    this.machineType = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  JobMachinesCompanion.insert({
    this.uid = const Value.absent(),
    this.jobId = const Value.absent(),
    this.machineId = const Value.absent(),
    this.machineName = const Value.absent(),
    this.machineType = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbJobMachine> custom({
    Expression<int>? uid,
    Expression<String>? jobId,
    Expression<String>? machineId,
    Expression<String>? machineName,
    Expression<String>? machineType,
    Expression<String>? description,
    Expression<String>? specification,
    Expression<int>? status,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (jobId != null) 'JobId': jobId,
      if (machineId != null) 'MachineId': machineId,
      if (machineName != null) 'MachineName': machineName,
      if (machineType != null) 'MachineType': machineType,
      if (description != null) 'Description': description,
      if (specification != null) 'Specification': specification,
      if (status != null) 'Status': status,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  JobMachinesCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? jobId,
      Value<String?>? machineId,
      Value<String?>? machineName,
      Value<String?>? machineType,
      Value<String?>? description,
      Value<String?>? specification,
      Value<int>? status,
      Value<String?>? lastSync}) {
    return JobMachinesCompanion(
      uid: uid ?? this.uid,
      jobId: jobId ?? this.jobId,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      machineType: machineType ?? this.machineType,
      description: description ?? this.description,
      specification: specification ?? this.specification,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (jobId.present) {
      map['JobId'] = Variable<String>(jobId.value);
    }
    if (machineId.present) {
      map['MachineId'] = Variable<String>(machineId.value);
    }
    if (machineName.present) {
      map['MachineName'] = Variable<String>(machineName.value);
    }
    if (machineType.present) {
      map['MachineType'] = Variable<String>(machineType.value);
    }
    if (description.present) {
      map['Description'] = Variable<String>(description.value);
    }
    if (specification.present) {
      map['Specification'] = Variable<String>(specification.value);
    }
    if (status.present) {
      map['Status'] = Variable<int>(status.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobMachinesCompanion(')
          ..write('uid: $uid, ')
          ..write('jobId: $jobId, ')
          ..write('machineId: $machineId, ')
          ..write('machineName: $machineName, ')
          ..write('machineType: $machineType, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $JobTagsTable extends JobTags with TableInfo<$JobTagsTable, DbJobTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tagId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'jobId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagNameMeta =
      const VerificationMeta('tagName');
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
      'tagName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagTypeMeta =
      const VerificationMeta('tagType');
  @override
  late final GeneratedColumn<String> tagType = GeneratedColumn<String>(
      'tagType', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagGroupIdMeta =
      const VerificationMeta('tagGroupId');
  @override
  late final GeneratedColumn<String> tagGroupId = GeneratedColumn<String>(
      'tagGroupId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagGroupNameMeta =
      const VerificationMeta('tagGroupName');
  @override
  late final GeneratedColumn<String> tagGroupName = GeneratedColumn<String>(
      'TagGroupName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specificationMeta =
      const VerificationMeta('specification');
  @override
  late final GeneratedColumn<String> specification = GeneratedColumn<String>(
      'specification', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specMinMeta =
      const VerificationMeta('specMin');
  @override
  late final GeneratedColumn<String> specMin = GeneratedColumn<String>(
      'specMin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _specMaxMeta =
      const VerificationMeta('specMax');
  @override
  late final GeneratedColumn<String> specMax = GeneratedColumn<String>(
      'specMax', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _queryStrMeta =
      const VerificationMeta('queryStr');
  @override
  late final GeneratedColumn<String> queryStr = GeneratedColumn<String>(
      'queryStr', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        tagId,
        jobId,
        tagName,
        tagType,
        tagGroupId,
        tagGroupName,
        description,
        specification,
        specMin,
        specMax,
        unit,
        queryStr,
        status,
        lastSync
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_tags';
  @override
  VerificationContext validateIntegrity(Insertable<DbJobTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('tagId')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tagId']!, _tagIdMeta));
    }
    if (data.containsKey('jobId')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['jobId']!, _jobIdMeta));
    }
    if (data.containsKey('tagName')) {
      context.handle(_tagNameMeta,
          tagName.isAcceptableOrUnknown(data['tagName']!, _tagNameMeta));
    }
    if (data.containsKey('tagType')) {
      context.handle(_tagTypeMeta,
          tagType.isAcceptableOrUnknown(data['tagType']!, _tagTypeMeta));
    }
    if (data.containsKey('tagGroupId')) {
      context.handle(
          _tagGroupIdMeta,
          tagGroupId.isAcceptableOrUnknown(
              data['tagGroupId']!, _tagGroupIdMeta));
    }
    if (data.containsKey('TagGroupName')) {
      context.handle(
          _tagGroupNameMeta,
          tagGroupName.isAcceptableOrUnknown(
              data['TagGroupName']!, _tagGroupNameMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('specification')) {
      context.handle(
          _specificationMeta,
          specification.isAcceptableOrUnknown(
              data['specification']!, _specificationMeta));
    }
    if (data.containsKey('specMin')) {
      context.handle(_specMinMeta,
          specMin.isAcceptableOrUnknown(data['specMin']!, _specMinMeta));
    }
    if (data.containsKey('specMax')) {
      context.handle(_specMaxMeta,
          specMax.isAcceptableOrUnknown(data['specMax']!, _specMaxMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('queryStr')) {
      context.handle(_queryStrMeta,
          queryStr.isAcceptableOrUnknown(data['queryStr']!, _queryStrMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbJobTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbJobTag(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagId']),
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jobId']),
      tagName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagName']),
      tagType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagType']),
      tagGroupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tagGroupId']),
      tagGroupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}TagGroupName']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      specification: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specification']),
      specMin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specMin']),
      specMax: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}specMax']),
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit']),
      queryStr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queryStr']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $JobTagsTable createAlias(String alias) {
    return $JobTagsTable(attachedDatabase, alias);
  }
}

class DbJobTag extends DataClass implements Insertable<DbJobTag> {
  final int uid;
  final String? tagId;
  final String? jobId;
  final String? tagName;
  final String? tagType;
  final String? tagGroupId;
  final String? tagGroupName;
  final String? description;
  final String? specification;
  final String? specMin;
  final String? specMax;
  final String? unit;
  final String? queryStr;
  final int status;
  final String? lastSync;
  const DbJobTag(
      {required this.uid,
      this.tagId,
      this.jobId,
      this.tagName,
      this.tagType,
      this.tagGroupId,
      this.tagGroupName,
      this.description,
      this.specification,
      this.specMin,
      this.specMax,
      this.unit,
      this.queryStr,
      required this.status,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || tagId != null) {
      map['tagId'] = Variable<String>(tagId);
    }
    if (!nullToAbsent || jobId != null) {
      map['jobId'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || tagName != null) {
      map['tagName'] = Variable<String>(tagName);
    }
    if (!nullToAbsent || tagType != null) {
      map['tagType'] = Variable<String>(tagType);
    }
    if (!nullToAbsent || tagGroupId != null) {
      map['tagGroupId'] = Variable<String>(tagGroupId);
    }
    if (!nullToAbsent || tagGroupName != null) {
      map['TagGroupName'] = Variable<String>(tagGroupName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || specification != null) {
      map['specification'] = Variable<String>(specification);
    }
    if (!nullToAbsent || specMin != null) {
      map['specMin'] = Variable<String>(specMin);
    }
    if (!nullToAbsent || specMax != null) {
      map['specMax'] = Variable<String>(specMax);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || queryStr != null) {
      map['queryStr'] = Variable<String>(queryStr);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  JobTagsCompanion toCompanion(bool nullToAbsent) {
    return JobTagsCompanion(
      uid: Value(uid),
      tagId:
          tagId == null && nullToAbsent ? const Value.absent() : Value(tagId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      tagName: tagName == null && nullToAbsent
          ? const Value.absent()
          : Value(tagName),
      tagType: tagType == null && nullToAbsent
          ? const Value.absent()
          : Value(tagType),
      tagGroupId: tagGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(tagGroupId),
      tagGroupName: tagGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(tagGroupName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      specification: specification == null && nullToAbsent
          ? const Value.absent()
          : Value(specification),
      specMin: specMin == null && nullToAbsent
          ? const Value.absent()
          : Value(specMin),
      specMax: specMax == null && nullToAbsent
          ? const Value.absent()
          : Value(specMax),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      queryStr: queryStr == null && nullToAbsent
          ? const Value.absent()
          : Value(queryStr),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbJobTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbJobTag(
      uid: serializer.fromJson<int>(json['uid']),
      tagId: serializer.fromJson<String?>(json['tagId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      tagName: serializer.fromJson<String?>(json['tagName']),
      tagType: serializer.fromJson<String?>(json['tagType']),
      tagGroupId: serializer.fromJson<String?>(json['tagGroupId']),
      tagGroupName: serializer.fromJson<String?>(json['tagGroupName']),
      description: serializer.fromJson<String?>(json['description']),
      specification: serializer.fromJson<String?>(json['specification']),
      specMin: serializer.fromJson<String?>(json['specMin']),
      specMax: serializer.fromJson<String?>(json['specMax']),
      unit: serializer.fromJson<String?>(json['unit']),
      queryStr: serializer.fromJson<String?>(json['queryStr']),
      status: serializer.fromJson<int>(json['status']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'tagId': serializer.toJson<String?>(tagId),
      'jobId': serializer.toJson<String?>(jobId),
      'tagName': serializer.toJson<String?>(tagName),
      'tagType': serializer.toJson<String?>(tagType),
      'tagGroupId': serializer.toJson<String?>(tagGroupId),
      'tagGroupName': serializer.toJson<String?>(tagGroupName),
      'description': serializer.toJson<String?>(description),
      'specification': serializer.toJson<String?>(specification),
      'specMin': serializer.toJson<String?>(specMin),
      'specMax': serializer.toJson<String?>(specMax),
      'unit': serializer.toJson<String?>(unit),
      'queryStr': serializer.toJson<String?>(queryStr),
      'status': serializer.toJson<int>(status),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbJobTag copyWith(
          {int? uid,
          Value<String?> tagId = const Value.absent(),
          Value<String?> jobId = const Value.absent(),
          Value<String?> tagName = const Value.absent(),
          Value<String?> tagType = const Value.absent(),
          Value<String?> tagGroupId = const Value.absent(),
          Value<String?> tagGroupName = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> specification = const Value.absent(),
          Value<String?> specMin = const Value.absent(),
          Value<String?> specMax = const Value.absent(),
          Value<String?> unit = const Value.absent(),
          Value<String?> queryStr = const Value.absent(),
          int? status,
          Value<String?> lastSync = const Value.absent()}) =>
      DbJobTag(
        uid: uid ?? this.uid,
        tagId: tagId.present ? tagId.value : this.tagId,
        jobId: jobId.present ? jobId.value : this.jobId,
        tagName: tagName.present ? tagName.value : this.tagName,
        tagType: tagType.present ? tagType.value : this.tagType,
        tagGroupId: tagGroupId.present ? tagGroupId.value : this.tagGroupId,
        tagGroupName:
            tagGroupName.present ? tagGroupName.value : this.tagGroupName,
        description: description.present ? description.value : this.description,
        specification:
            specification.present ? specification.value : this.specification,
        specMin: specMin.present ? specMin.value : this.specMin,
        specMax: specMax.present ? specMax.value : this.specMax,
        unit: unit.present ? unit.value : this.unit,
        queryStr: queryStr.present ? queryStr.value : this.queryStr,
        status: status ?? this.status,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbJobTag copyWithCompanion(JobTagsCompanion data) {
    return DbJobTag(
      uid: data.uid.present ? data.uid.value : this.uid,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      tagType: data.tagType.present ? data.tagType.value : this.tagType,
      tagGroupId:
          data.tagGroupId.present ? data.tagGroupId.value : this.tagGroupId,
      tagGroupName: data.tagGroupName.present
          ? data.tagGroupName.value
          : this.tagGroupName,
      description:
          data.description.present ? data.description.value : this.description,
      specification: data.specification.present
          ? data.specification.value
          : this.specification,
      specMin: data.specMin.present ? data.specMin.value : this.specMin,
      specMax: data.specMax.present ? data.specMax.value : this.specMax,
      unit: data.unit.present ? data.unit.value : this.unit,
      queryStr: data.queryStr.present ? data.queryStr.value : this.queryStr,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbJobTag(')
          ..write('uid: $uid, ')
          ..write('tagId: $tagId, ')
          ..write('jobId: $jobId, ')
          ..write('tagName: $tagName, ')
          ..write('tagType: $tagType, ')
          ..write('tagGroupId: $tagGroupId, ')
          ..write('tagGroupName: $tagGroupName, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('specMin: $specMin, ')
          ..write('specMax: $specMax, ')
          ..write('unit: $unit, ')
          ..write('queryStr: $queryStr, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid,
      tagId,
      jobId,
      tagName,
      tagType,
      tagGroupId,
      tagGroupName,
      description,
      specification,
      specMin,
      specMax,
      unit,
      queryStr,
      status,
      lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbJobTag &&
          other.uid == this.uid &&
          other.tagId == this.tagId &&
          other.jobId == this.jobId &&
          other.tagName == this.tagName &&
          other.tagType == this.tagType &&
          other.tagGroupId == this.tagGroupId &&
          other.tagGroupName == this.tagGroupName &&
          other.description == this.description &&
          other.specification == this.specification &&
          other.specMin == this.specMin &&
          other.specMax == this.specMax &&
          other.unit == this.unit &&
          other.queryStr == this.queryStr &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class JobTagsCompanion extends UpdateCompanion<DbJobTag> {
  final Value<int> uid;
  final Value<String?> tagId;
  final Value<String?> jobId;
  final Value<String?> tagName;
  final Value<String?> tagType;
  final Value<String?> tagGroupId;
  final Value<String?> tagGroupName;
  final Value<String?> description;
  final Value<String?> specification;
  final Value<String?> specMin;
  final Value<String?> specMax;
  final Value<String?> unit;
  final Value<String?> queryStr;
  final Value<int> status;
  final Value<String?> lastSync;
  const JobTagsCompanion({
    this.uid = const Value.absent(),
    this.tagId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.tagType = const Value.absent(),
    this.tagGroupId = const Value.absent(),
    this.tagGroupName = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.specMin = const Value.absent(),
    this.specMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.queryStr = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  JobTagsCompanion.insert({
    this.uid = const Value.absent(),
    this.tagId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.tagType = const Value.absent(),
    this.tagGroupId = const Value.absent(),
    this.tagGroupName = const Value.absent(),
    this.description = const Value.absent(),
    this.specification = const Value.absent(),
    this.specMin = const Value.absent(),
    this.specMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.queryStr = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbJobTag> custom({
    Expression<int>? uid,
    Expression<String>? tagId,
    Expression<String>? jobId,
    Expression<String>? tagName,
    Expression<String>? tagType,
    Expression<String>? tagGroupId,
    Expression<String>? tagGroupName,
    Expression<String>? description,
    Expression<String>? specification,
    Expression<String>? specMin,
    Expression<String>? specMax,
    Expression<String>? unit,
    Expression<String>? queryStr,
    Expression<int>? status,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (tagId != null) 'tagId': tagId,
      if (jobId != null) 'jobId': jobId,
      if (tagName != null) 'tagName': tagName,
      if (tagType != null) 'tagType': tagType,
      if (tagGroupId != null) 'tagGroupId': tagGroupId,
      if (tagGroupName != null) 'TagGroupName': tagGroupName,
      if (description != null) 'description': description,
      if (specification != null) 'specification': specification,
      if (specMin != null) 'specMin': specMin,
      if (specMax != null) 'specMax': specMax,
      if (unit != null) 'unit': unit,
      if (queryStr != null) 'queryStr': queryStr,
      if (status != null) 'status': status,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  JobTagsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? tagId,
      Value<String?>? jobId,
      Value<String?>? tagName,
      Value<String?>? tagType,
      Value<String?>? tagGroupId,
      Value<String?>? tagGroupName,
      Value<String?>? description,
      Value<String?>? specification,
      Value<String?>? specMin,
      Value<String?>? specMax,
      Value<String?>? unit,
      Value<String?>? queryStr,
      Value<int>? status,
      Value<String?>? lastSync}) {
    return JobTagsCompanion(
      uid: uid ?? this.uid,
      tagId: tagId ?? this.tagId,
      jobId: jobId ?? this.jobId,
      tagName: tagName ?? this.tagName,
      tagType: tagType ?? this.tagType,
      tagGroupId: tagGroupId ?? this.tagGroupId,
      tagGroupName: tagGroupName ?? this.tagGroupName,
      description: description ?? this.description,
      specification: specification ?? this.specification,
      specMin: specMin ?? this.specMin,
      specMax: specMax ?? this.specMax,
      unit: unit ?? this.unit,
      queryStr: queryStr ?? this.queryStr,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (tagId.present) {
      map['tagId'] = Variable<String>(tagId.value);
    }
    if (jobId.present) {
      map['jobId'] = Variable<String>(jobId.value);
    }
    if (tagName.present) {
      map['tagName'] = Variable<String>(tagName.value);
    }
    if (tagType.present) {
      map['tagType'] = Variable<String>(tagType.value);
    }
    if (tagGroupId.present) {
      map['tagGroupId'] = Variable<String>(tagGroupId.value);
    }
    if (tagGroupName.present) {
      map['TagGroupName'] = Variable<String>(tagGroupName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (specification.present) {
      map['specification'] = Variable<String>(specification.value);
    }
    if (specMin.present) {
      map['specMin'] = Variable<String>(specMin.value);
    }
    if (specMax.present) {
      map['specMax'] = Variable<String>(specMax.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (queryStr.present) {
      map['queryStr'] = Variable<String>(queryStr.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobTagsCompanion(')
          ..write('uid: $uid, ')
          ..write('tagId: $tagId, ')
          ..write('jobId: $jobId, ')
          ..write('tagName: $tagName, ')
          ..write('tagType: $tagType, ')
          ..write('tagGroupId: $tagGroupId, ')
          ..write('tagGroupName: $tagGroupName, ')
          ..write('description: $description, ')
          ..write('specification: $specification, ')
          ..write('specMin: $specMin, ')
          ..write('specMax: $specMax, ')
          ..write('unit: $unit, ')
          ..write('queryStr: $queryStr, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $ProblemsTable extends Problems
    with TableInfo<$ProblemsTable, DbProblem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProblemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _problemIdMeta =
      const VerificationMeta('problemId');
  @override
  late final GeneratedColumn<String> problemId = GeneratedColumn<String>(
      'ProblemId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _problemNameMeta =
      const VerificationMeta('problemName');
  @override
  late final GeneratedColumn<String> problemName = GeneratedColumn<String>(
      'ProblemName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'Description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _problemStatusMeta =
      const VerificationMeta('problemStatus');
  @override
  late final GeneratedColumn<int> problemStatus = GeneratedColumn<int>(
      'ProblemStatus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, problemId, problemName, description, problemStatus, lastSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'problems';
  @override
  VerificationContext validateIntegrity(Insertable<DbProblem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('ProblemId')) {
      context.handle(_problemIdMeta,
          problemId.isAcceptableOrUnknown(data['ProblemId']!, _problemIdMeta));
    }
    if (data.containsKey('ProblemName')) {
      context.handle(
          _problemNameMeta,
          problemName.isAcceptableOrUnknown(
              data['ProblemName']!, _problemNameMeta));
    }
    if (data.containsKey('Description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['Description']!, _descriptionMeta));
    }
    if (data.containsKey('ProblemStatus')) {
      context.handle(
          _problemStatusMeta,
          problemStatus.isAcceptableOrUnknown(
              data['ProblemStatus']!, _problemStatusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbProblem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbProblem(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      problemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ProblemId']),
      problemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ProblemName']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}Description']),
      problemStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ProblemStatus'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $ProblemsTable createAlias(String alias) {
    return $ProblemsTable(attachedDatabase, alias);
  }
}

class DbProblem extends DataClass implements Insertable<DbProblem> {
  final int uid;
  final String? problemId;
  final String? problemName;
  final String? description;
  final int problemStatus;
  final String? lastSync;
  const DbProblem(
      {required this.uid,
      this.problemId,
      this.problemName,
      this.description,
      required this.problemStatus,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || problemId != null) {
      map['ProblemId'] = Variable<String>(problemId);
    }
    if (!nullToAbsent || problemName != null) {
      map['ProblemName'] = Variable<String>(problemName);
    }
    if (!nullToAbsent || description != null) {
      map['Description'] = Variable<String>(description);
    }
    map['ProblemStatus'] = Variable<int>(problemStatus);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  ProblemsCompanion toCompanion(bool nullToAbsent) {
    return ProblemsCompanion(
      uid: Value(uid),
      problemId: problemId == null && nullToAbsent
          ? const Value.absent()
          : Value(problemId),
      problemName: problemName == null && nullToAbsent
          ? const Value.absent()
          : Value(problemName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      problemStatus: Value(problemStatus),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbProblem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbProblem(
      uid: serializer.fromJson<int>(json['uid']),
      problemId: serializer.fromJson<String?>(json['problemId']),
      problemName: serializer.fromJson<String?>(json['problemName']),
      description: serializer.fromJson<String?>(json['description']),
      problemStatus: serializer.fromJson<int>(json['problemStatus']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'problemId': serializer.toJson<String?>(problemId),
      'problemName': serializer.toJson<String?>(problemName),
      'description': serializer.toJson<String?>(description),
      'problemStatus': serializer.toJson<int>(problemStatus),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbProblem copyWith(
          {int? uid,
          Value<String?> problemId = const Value.absent(),
          Value<String?> problemName = const Value.absent(),
          Value<String?> description = const Value.absent(),
          int? problemStatus,
          Value<String?> lastSync = const Value.absent()}) =>
      DbProblem(
        uid: uid ?? this.uid,
        problemId: problemId.present ? problemId.value : this.problemId,
        problemName: problemName.present ? problemName.value : this.problemName,
        description: description.present ? description.value : this.description,
        problemStatus: problemStatus ?? this.problemStatus,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbProblem copyWithCompanion(ProblemsCompanion data) {
    return DbProblem(
      uid: data.uid.present ? data.uid.value : this.uid,
      problemId: data.problemId.present ? data.problemId.value : this.problemId,
      problemName:
          data.problemName.present ? data.problemName.value : this.problemName,
      description:
          data.description.present ? data.description.value : this.description,
      problemStatus: data.problemStatus.present
          ? data.problemStatus.value
          : this.problemStatus,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbProblem(')
          ..write('uid: $uid, ')
          ..write('problemId: $problemId, ')
          ..write('problemName: $problemName, ')
          ..write('description: $description, ')
          ..write('problemStatus: $problemStatus, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, problemId, problemName, description, problemStatus, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbProblem &&
          other.uid == this.uid &&
          other.problemId == this.problemId &&
          other.problemName == this.problemName &&
          other.description == this.description &&
          other.problemStatus == this.problemStatus &&
          other.lastSync == this.lastSync);
}

class ProblemsCompanion extends UpdateCompanion<DbProblem> {
  final Value<int> uid;
  final Value<String?> problemId;
  final Value<String?> problemName;
  final Value<String?> description;
  final Value<int> problemStatus;
  final Value<String?> lastSync;
  const ProblemsCompanion({
    this.uid = const Value.absent(),
    this.problemId = const Value.absent(),
    this.problemName = const Value.absent(),
    this.description = const Value.absent(),
    this.problemStatus = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  ProblemsCompanion.insert({
    this.uid = const Value.absent(),
    this.problemId = const Value.absent(),
    this.problemName = const Value.absent(),
    this.description = const Value.absent(),
    this.problemStatus = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbProblem> custom({
    Expression<int>? uid,
    Expression<String>? problemId,
    Expression<String>? problemName,
    Expression<String>? description,
    Expression<int>? problemStatus,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (problemId != null) 'ProblemId': problemId,
      if (problemName != null) 'ProblemName': problemName,
      if (description != null) 'Description': description,
      if (problemStatus != null) 'ProblemStatus': problemStatus,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  ProblemsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? problemId,
      Value<String?>? problemName,
      Value<String?>? description,
      Value<int>? problemStatus,
      Value<String?>? lastSync}) {
    return ProblemsCompanion(
      uid: uid ?? this.uid,
      problemId: problemId ?? this.problemId,
      problemName: problemName ?? this.problemName,
      description: description ?? this.description,
      problemStatus: problemStatus ?? this.problemStatus,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (problemId.present) {
      map['ProblemId'] = Variable<String>(problemId.value);
    }
    if (problemName.present) {
      map['ProblemName'] = Variable<String>(problemName.value);
    }
    if (description.present) {
      map['Description'] = Variable<String>(description.value);
    }
    if (problemStatus.present) {
      map['ProblemStatus'] = Variable<int>(problemStatus.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProblemsCompanion(')
          ..write('uid: $uid, ')
          ..write('problemId: $problemId, ')
          ..write('problemName: $problemName, ')
          ..write('description: $description, ')
          ..write('problemStatus: $problemStatus, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

class $SyncsTable extends Syncs with TableInfo<$SyncsTable, DbSync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
      'SyncId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncNameMeta =
      const VerificationMeta('syncName');
  @override
  late final GeneratedColumn<String> syncName = GeneratedColumn<String>(
      'SyncName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'LastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
      'SyncStatus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextSyncMeta =
      const VerificationMeta('nextSync');
  @override
  late final GeneratedColumn<String> nextSync = GeneratedColumn<String>(
      'NextSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, syncId, syncName, lastSync, syncStatus, nextSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syncs';
  @override
  VerificationContext validateIntegrity(Insertable<DbSync> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('SyncId')) {
      context.handle(_syncIdMeta,
          syncId.isAcceptableOrUnknown(data['SyncId']!, _syncIdMeta));
    }
    if (data.containsKey('SyncName')) {
      context.handle(_syncNameMeta,
          syncName.isAcceptableOrUnknown(data['SyncName']!, _syncNameMeta));
    }
    if (data.containsKey('LastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['LastSync']!, _lastSyncMeta));
    }
    if (data.containsKey('SyncStatus')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['SyncStatus']!, _syncStatusMeta));
    }
    if (data.containsKey('NextSync')) {
      context.handle(_nextSyncMeta,
          nextSync.isAcceptableOrUnknown(data['NextSync']!, _nextSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbSync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbSync(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      syncId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}SyncId']),
      syncName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}SyncName']),
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}LastSync']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}SyncStatus'])!,
      nextSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}NextSync']),
    );
  }

  @override
  $SyncsTable createAlias(String alias) {
    return $SyncsTable(attachedDatabase, alias);
  }
}

class DbSync extends DataClass implements Insertable<DbSync> {
  final int uid;
  final String? syncId;
  final String? syncName;
  final String? lastSync;
  final int syncStatus;
  final String? nextSync;
  const DbSync(
      {required this.uid,
      this.syncId,
      this.syncName,
      this.lastSync,
      required this.syncStatus,
      this.nextSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || syncId != null) {
      map['SyncId'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || syncName != null) {
      map['SyncName'] = Variable<String>(syncName);
    }
    if (!nullToAbsent || lastSync != null) {
      map['LastSync'] = Variable<String>(lastSync);
    }
    map['SyncStatus'] = Variable<int>(syncStatus);
    if (!nullToAbsent || nextSync != null) {
      map['NextSync'] = Variable<String>(nextSync);
    }
    return map;
  }

  SyncsCompanion toCompanion(bool nullToAbsent) {
    return SyncsCompanion(
      uid: Value(uid),
      syncId:
          syncId == null && nullToAbsent ? const Value.absent() : Value(syncId),
      syncName: syncName == null && nullToAbsent
          ? const Value.absent()
          : Value(syncName),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      syncStatus: Value(syncStatus),
      nextSync: nextSync == null && nullToAbsent
          ? const Value.absent()
          : Value(nextSync),
    );
  }

  factory DbSync.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbSync(
      uid: serializer.fromJson<int>(json['uid']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      syncName: serializer.fromJson<String?>(json['syncName']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      nextSync: serializer.fromJson<String?>(json['nextSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'syncId': serializer.toJson<String?>(syncId),
      'syncName': serializer.toJson<String?>(syncName),
      'lastSync': serializer.toJson<String?>(lastSync),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'nextSync': serializer.toJson<String?>(nextSync),
    };
  }

  DbSync copyWith(
          {int? uid,
          Value<String?> syncId = const Value.absent(),
          Value<String?> syncName = const Value.absent(),
          Value<String?> lastSync = const Value.absent(),
          int? syncStatus,
          Value<String?> nextSync = const Value.absent()}) =>
      DbSync(
        uid: uid ?? this.uid,
        syncId: syncId.present ? syncId.value : this.syncId,
        syncName: syncName.present ? syncName.value : this.syncName,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
        syncStatus: syncStatus ?? this.syncStatus,
        nextSync: nextSync.present ? nextSync.value : this.nextSync,
      );
  DbSync copyWithCompanion(SyncsCompanion data) {
    return DbSync(
      uid: data.uid.present ? data.uid.value : this.uid,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      syncName: data.syncName.present ? data.syncName.value : this.syncName,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      nextSync: data.nextSync.present ? data.nextSync.value : this.nextSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbSync(')
          ..write('uid: $uid, ')
          ..write('syncId: $syncId, ')
          ..write('syncName: $syncName, ')
          ..write('lastSync: $lastSync, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('nextSync: $nextSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, syncId, syncName, lastSync, syncStatus, nextSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbSync &&
          other.uid == this.uid &&
          other.syncId == this.syncId &&
          other.syncName == this.syncName &&
          other.lastSync == this.lastSync &&
          other.syncStatus == this.syncStatus &&
          other.nextSync == this.nextSync);
}

class SyncsCompanion extends UpdateCompanion<DbSync> {
  final Value<int> uid;
  final Value<String?> syncId;
  final Value<String?> syncName;
  final Value<String?> lastSync;
  final Value<int> syncStatus;
  final Value<String?> nextSync;
  const SyncsCompanion({
    this.uid = const Value.absent(),
    this.syncId = const Value.absent(),
    this.syncName = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.nextSync = const Value.absent(),
  });
  SyncsCompanion.insert({
    this.uid = const Value.absent(),
    this.syncId = const Value.absent(),
    this.syncName = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.nextSync = const Value.absent(),
  });
  static Insertable<DbSync> custom({
    Expression<int>? uid,
    Expression<String>? syncId,
    Expression<String>? syncName,
    Expression<String>? lastSync,
    Expression<int>? syncStatus,
    Expression<String>? nextSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (syncId != null) 'SyncId': syncId,
      if (syncName != null) 'SyncName': syncName,
      if (lastSync != null) 'LastSync': lastSync,
      if (syncStatus != null) 'SyncStatus': syncStatus,
      if (nextSync != null) 'NextSync': nextSync,
    });
  }

  SyncsCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? syncId,
      Value<String?>? syncName,
      Value<String?>? lastSync,
      Value<int>? syncStatus,
      Value<String?>? nextSync}) {
    return SyncsCompanion(
      uid: uid ?? this.uid,
      syncId: syncId ?? this.syncId,
      syncName: syncName ?? this.syncName,
      lastSync: lastSync ?? this.lastSync,
      syncStatus: syncStatus ?? this.syncStatus,
      nextSync: nextSync ?? this.nextSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (syncId.present) {
      map['SyncId'] = Variable<String>(syncId.value);
    }
    if (syncName.present) {
      map['SyncName'] = Variable<String>(syncName.value);
    }
    if (lastSync.present) {
      map['LastSync'] = Variable<String>(lastSync.value);
    }
    if (syncStatus.present) {
      map['SyncStatus'] = Variable<int>(syncStatus.value);
    }
    if (nextSync.present) {
      map['NextSync'] = Variable<String>(nextSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncsCompanion(')
          ..write('uid: $uid, ')
          ..write('syncId: $syncId, ')
          ..write('syncName: $syncName, ')
          ..write('lastSync: $lastSync, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('nextSync: $nextSync')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, DbUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
      'uid', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'userId', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userCodeMeta =
      const VerificationMeta('userCode');
  @override
  late final GeneratedColumn<String> userCode = GeneratedColumn<String>(
      'userCode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'userName', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
      'position', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'Status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSyncMeta =
      const VerificationMeta('lastSync');
  @override
  late final GeneratedColumn<String> lastSync = GeneratedColumn<String>(
      'lastSync', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, userId, userCode, password, userName, position, status, lastSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<DbUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    }
    if (data.containsKey('userId')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['userId']!, _userIdMeta));
    }
    if (data.containsKey('userCode')) {
      context.handle(_userCodeMeta,
          userCode.isAcceptableOrUnknown(data['userCode']!, _userCodeMeta));
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('userName')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['userName']!, _userNameMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('Status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['Status']!, _statusMeta));
    }
    if (data.containsKey('lastSync')) {
      context.handle(_lastSyncMeta,
          lastSync.isAcceptableOrUnknown(data['lastSync']!, _lastSyncMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DbUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUser(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}uid'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}userId']),
      userCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}userCode']),
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}userName']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}position']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}Status'])!,
      lastSync: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lastSync']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class DbUser extends DataClass implements Insertable<DbUser> {
  final int uid;
  final String? userId;
  final String? userCode;
  final String? password;
  final String? userName;
  final String? position;
  final int status;
  final String? lastSync;
  const DbUser(
      {required this.uid,
      this.userId,
      this.userCode,
      this.password,
      this.userName,
      this.position,
      required this.status,
      this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || userId != null) {
      map['userId'] = Variable<String>(userId);
    }
    if (!nullToAbsent || userCode != null) {
      map['userCode'] = Variable<String>(userCode);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || userName != null) {
      map['userName'] = Variable<String>(userName);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<String>(position);
    }
    map['Status'] = Variable<int>(status);
    if (!nullToAbsent || lastSync != null) {
      map['lastSync'] = Variable<String>(lastSync);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      uid: Value(uid),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      userCode: userCode == null && nullToAbsent
          ? const Value.absent()
          : Value(userCode),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      userName: userName == null && nullToAbsent
          ? const Value.absent()
          : Value(userName),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      status: Value(status),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
    );
  }

  factory DbUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUser(
      uid: serializer.fromJson<int>(json['uid']),
      userId: serializer.fromJson<String?>(json['userId']),
      userCode: serializer.fromJson<String?>(json['userCode']),
      password: serializer.fromJson<String?>(json['password']),
      userName: serializer.fromJson<String?>(json['userName']),
      position: serializer.fromJson<String?>(json['position']),
      status: serializer.fromJson<int>(json['status']),
      lastSync: serializer.fromJson<String?>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<int>(uid),
      'userId': serializer.toJson<String?>(userId),
      'userCode': serializer.toJson<String?>(userCode),
      'password': serializer.toJson<String?>(password),
      'userName': serializer.toJson<String?>(userName),
      'position': serializer.toJson<String?>(position),
      'status': serializer.toJson<int>(status),
      'lastSync': serializer.toJson<String?>(lastSync),
    };
  }

  DbUser copyWith(
          {int? uid,
          Value<String?> userId = const Value.absent(),
          Value<String?> userCode = const Value.absent(),
          Value<String?> password = const Value.absent(),
          Value<String?> userName = const Value.absent(),
          Value<String?> position = const Value.absent(),
          int? status,
          Value<String?> lastSync = const Value.absent()}) =>
      DbUser(
        uid: uid ?? this.uid,
        userId: userId.present ? userId.value : this.userId,
        userCode: userCode.present ? userCode.value : this.userCode,
        password: password.present ? password.value : this.password,
        userName: userName.present ? userName.value : this.userName,
        position: position.present ? position.value : this.position,
        status: status ?? this.status,
        lastSync: lastSync.present ? lastSync.value : this.lastSync,
      );
  DbUser copyWithCompanion(UsersCompanion data) {
    return DbUser(
      uid: data.uid.present ? data.uid.value : this.uid,
      userId: data.userId.present ? data.userId.value : this.userId,
      userCode: data.userCode.present ? data.userCode.value : this.userCode,
      password: data.password.present ? data.password.value : this.password,
      userName: data.userName.present ? data.userName.value : this.userName,
      position: data.position.present ? data.position.value : this.position,
      status: data.status.present ? data.status.value : this.status,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUser(')
          ..write('uid: $uid, ')
          ..write('userId: $userId, ')
          ..write('userCode: $userCode, ')
          ..write('password: $password, ')
          ..write('userName: $userName, ')
          ..write('position: $position, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, userId, userCode, password, userName, position, status, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUser &&
          other.uid == this.uid &&
          other.userId == this.userId &&
          other.userCode == this.userCode &&
          other.password == this.password &&
          other.userName == this.userName &&
          other.position == this.position &&
          other.status == this.status &&
          other.lastSync == this.lastSync);
}

class UsersCompanion extends UpdateCompanion<DbUser> {
  final Value<int> uid;
  final Value<String?> userId;
  final Value<String?> userCode;
  final Value<String?> password;
  final Value<String?> userName;
  final Value<String?> position;
  final Value<int> status;
  final Value<String?> lastSync;
  const UsersCompanion({
    this.uid = const Value.absent(),
    this.userId = const Value.absent(),
    this.userCode = const Value.absent(),
    this.password = const Value.absent(),
    this.userName = const Value.absent(),
    this.position = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  UsersCompanion.insert({
    this.uid = const Value.absent(),
    this.userId = const Value.absent(),
    this.userCode = const Value.absent(),
    this.password = const Value.absent(),
    this.userName = const Value.absent(),
    this.position = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSync = const Value.absent(),
  });
  static Insertable<DbUser> custom({
    Expression<int>? uid,
    Expression<String>? userId,
    Expression<String>? userCode,
    Expression<String>? password,
    Expression<String>? userName,
    Expression<String>? position,
    Expression<int>? status,
    Expression<String>? lastSync,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (userId != null) 'userId': userId,
      if (userCode != null) 'userCode': userCode,
      if (password != null) 'password': password,
      if (userName != null) 'userName': userName,
      if (position != null) 'position': position,
      if (status != null) 'Status': status,
      if (lastSync != null) 'lastSync': lastSync,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? uid,
      Value<String?>? userId,
      Value<String?>? userCode,
      Value<String?>? password,
      Value<String?>? userName,
      Value<String?>? position,
      Value<int>? status,
      Value<String?>? lastSync}) {
    return UsersCompanion(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      userCode: userCode ?? this.userCode,
      password: password ?? this.password,
      userName: userName ?? this.userName,
      position: position ?? this.position,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (userId.present) {
      map['userId'] = Variable<String>(userId.value);
    }
    if (userCode.present) {
      map['userCode'] = Variable<String>(userCode.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (userName.present) {
      map['userName'] = Variable<String>(userName.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (status.present) {
      map['Status'] = Variable<int>(status.value);
    }
    if (lastSync.present) {
      map['lastSync'] = Variable<String>(lastSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('uid: $uid, ')
          ..write('userId: $userId, ')
          ..write('userCode: $userCode, ')
          ..write('password: $password, ')
          ..write('userName: $userName, ')
          ..write('position: $position, ')
          ..write('status: $status, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DocumentMachinesTable documentMachines =
      $DocumentMachinesTable(this);
  late final $DocumentRecordsTable documentRecords =
      $DocumentRecordsTable(this);
  late final $JobMachinesTable jobMachines = $JobMachinesTable(this);
  late final $JobTagsTable jobTags = $JobTagsTable(this);
  late final $ProblemsTable problems = $ProblemsTable(this);
  late final $SyncsTable syncs = $SyncsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final JobDao jobDao = JobDao(this as AppDatabase);
  late final DocumentDao documentDao = DocumentDao(this as AppDatabase);
  late final DocumentMachineDao documentMachineDao =
      DocumentMachineDao(this as AppDatabase);
  late final DocumentRecordDao documentRecordDao =
      DocumentRecordDao(this as AppDatabase);
  late final JobMachineDao jobMachineDao = JobMachineDao(this as AppDatabase);
  late final JobTagDao jobTagDao = JobTagDao(this as AppDatabase);
  late final ProblemDao problemDao = ProblemDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  late final UserDao userDao = UserDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        jobs,
        documents,
        documentMachines,
        documentRecords,
        jobMachines,
        jobTags,
        problems,
        syncs,
        users
      ];
}

typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> jobName,
  Value<String?> machineName,
  Value<String?> documentId,
  Value<String?> location,
  Value<int> jobStatus,
  Value<String?> lastSync,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> jobName,
  Value<String?> machineName,
  Value<String?> documentId,
  Value<String?> location,
  Value<int> jobStatus,
  Value<String?> lastSync,
});

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobName => $composableBuilder(
      column: $table.jobName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jobStatus => $composableBuilder(
      column: $table.jobStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobName => $composableBuilder(
      column: $table.jobName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jobStatus => $composableBuilder(
      column: $table.jobStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get jobName =>
      $composableBuilder(column: $table.jobName, builder: (column) => column);

  GeneratedColumn<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get jobStatus =>
      $composableBuilder(column: $table.jobStatus, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$JobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JobsTable,
    DbJob,
    $$JobsTableFilterComposer,
    $$JobsTableOrderingComposer,
    $$JobsTableAnnotationComposer,
    $$JobsTableCreateCompanionBuilder,
    $$JobsTableUpdateCompanionBuilder,
    (DbJob, BaseReferences<_$AppDatabase, $JobsTable, DbJob>),
    DbJob,
    PrefetchHooks Function()> {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> jobName = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<int> jobStatus = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobsCompanion(
            uid: uid,
            jobId: jobId,
            jobName: jobName,
            machineName: machineName,
            documentId: documentId,
            location: location,
            jobStatus: jobStatus,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> jobName = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<int> jobStatus = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobsCompanion.insert(
            uid: uid,
            jobId: jobId,
            jobName: jobName,
            machineName: machineName,
            documentId: documentId,
            location: location,
            jobStatus: jobStatus,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JobsTable,
    DbJob,
    $$JobsTableFilterComposer,
    $$JobsTableOrderingComposer,
    $$JobsTableAnnotationComposer,
    $$JobsTableCreateCompanionBuilder,
    $$JobsTableUpdateCompanionBuilder,
    (DbJob, BaseReferences<_$AppDatabase, $JobsTable, DbJob>),
    DbJob,
    PrefetchHooks Function()>;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  Value<int> uid,
  Value<String?> documentId,
  Value<String?> jobId,
  Value<String?> documentName,
  Value<String?> userId,
  Value<String?> createDate,
  Value<int> status,
  Value<String?> lastSync,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<int> uid,
  Value<String?> documentId,
  Value<String?> jobId,
  Value<String?> documentName,
  Value<String?> userId,
  Value<String?> createDate,
  Value<int> status,
  Value<String?> lastSync,
});

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentName => $composableBuilder(
      column: $table.documentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createDate => $composableBuilder(
      column: $table.createDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentName => $composableBuilder(
      column: $table.documentName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createDate => $composableBuilder(
      column: $table.createDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get documentName => $composableBuilder(
      column: $table.documentName, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get createDate => $composableBuilder(
      column: $table.createDate, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$DocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsTable,
    DbDocument,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (DbDocument, BaseReferences<_$AppDatabase, $DocumentsTable, DbDocument>),
    DbDocument,
    PrefetchHooks Function()> {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> documentName = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> createDate = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentsCompanion(
            uid: uid,
            documentId: documentId,
            jobId: jobId,
            documentName: documentName,
            userId: userId,
            createDate: createDate,
            status: status,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> documentName = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> createDate = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            uid: uid,
            documentId: documentId,
            jobId: jobId,
            documentName: documentName,
            userId: userId,
            createDate: createDate,
            status: status,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentsTable,
    DbDocument,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (DbDocument, BaseReferences<_$AppDatabase, $DocumentsTable, DbDocument>),
    DbDocument,
    PrefetchHooks Function()>;
typedef $$DocumentMachinesTableCreateCompanionBuilder
    = DocumentMachinesCompanion Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> documentId,
  Value<String?> machineId,
  Value<String?> machineName,
  Value<String?> machineType,
  Value<String?> description,
  Value<String?> specification,
  Value<int> status,
  Value<String?> lastSync,
});
typedef $$DocumentMachinesTableUpdateCompanionBuilder
    = DocumentMachinesCompanion Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> documentId,
  Value<String?> machineId,
  Value<String?> machineName,
  Value<String?> machineType,
  Value<String?> description,
  Value<String?> specification,
  Value<int> status,
  Value<String?> lastSync,
});

class $$DocumentMachinesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentMachinesTable> {
  $$DocumentMachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$DocumentMachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentMachinesTable> {
  $$DocumentMachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specification => $composableBuilder(
      column: $table.specification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$DocumentMachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentMachinesTable> {
  $$DocumentMachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => column);

  GeneratedColumn<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$DocumentMachinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentMachinesTable,
    DbDocumentMachine,
    $$DocumentMachinesTableFilterComposer,
    $$DocumentMachinesTableOrderingComposer,
    $$DocumentMachinesTableAnnotationComposer,
    $$DocumentMachinesTableCreateCompanionBuilder,
    $$DocumentMachinesTableUpdateCompanionBuilder,
    (
      DbDocumentMachine,
      BaseReferences<_$AppDatabase, $DocumentMachinesTable, DbDocumentMachine>
    ),
    DbDocumentMachine,
    PrefetchHooks Function()> {
  $$DocumentMachinesTableTableManager(
      _$AppDatabase db, $DocumentMachinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentMachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentMachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentMachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> machineType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentMachinesCompanion(
            uid: uid,
            jobId: jobId,
            documentId: documentId,
            machineId: machineId,
            machineName: machineName,
            machineType: machineType,
            description: description,
            specification: specification,
            status: status,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> machineType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentMachinesCompanion.insert(
            uid: uid,
            jobId: jobId,
            documentId: documentId,
            machineId: machineId,
            machineName: machineName,
            machineType: machineType,
            description: description,
            specification: specification,
            status: status,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentMachinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentMachinesTable,
    DbDocumentMachine,
    $$DocumentMachinesTableFilterComposer,
    $$DocumentMachinesTableOrderingComposer,
    $$DocumentMachinesTableAnnotationComposer,
    $$DocumentMachinesTableCreateCompanionBuilder,
    $$DocumentMachinesTableUpdateCompanionBuilder,
    (
      DbDocumentMachine,
      BaseReferences<_$AppDatabase, $DocumentMachinesTable, DbDocumentMachine>
    ),
    DbDocumentMachine,
    PrefetchHooks Function()>;
typedef $$DocumentRecordsTableCreateCompanionBuilder = DocumentRecordsCompanion
    Function({
  Value<int> uid,
  Value<String?> documentId,
  Value<String?> machineId,
  Value<String?> jobId,
  Value<String?> tagId,
  Value<String?> tagName,
  Value<String?> tagType,
  Value<String?> tagGroupId,
  Value<String?> tagGroupName,
  Value<String?> tagSelectionValue,
  Value<String?> description,
  Value<String?> note,
  Value<String?> specification,
  Value<String?> specMin,
  Value<String?> specMax,
  Value<String?> unit,
  Value<String?> queryStr,
  Value<String?> value,
  Value<String?> valueType,
  Value<String?> remark,
  Value<int> status,
  Value<String> unReadable,
  Value<String?> lastSync,
});
typedef $$DocumentRecordsTableUpdateCompanionBuilder = DocumentRecordsCompanion
    Function({
  Value<int> uid,
  Value<String?> documentId,
  Value<String?> machineId,
  Value<String?> jobId,
  Value<String?> tagId,
  Value<String?> tagName,
  Value<String?> tagType,
  Value<String?> tagGroupId,
  Value<String?> tagGroupName,
  Value<String?> tagSelectionValue,
  Value<String?> description,
  Value<String?> note,
  Value<String?> specification,
  Value<String?> specMin,
  Value<String?> specMax,
  Value<String?> unit,
  Value<String?> queryStr,
  Value<String?> value,
  Value<String?> valueType,
  Value<String?> remark,
  Value<int> status,
  Value<String> unReadable,
  Value<String?> lastSync,
});

class $$DocumentRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagType => $composableBuilder(
      column: $table.tagType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagSelectionValue => $composableBuilder(
      column: $table.tagSelectionValue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specMin => $composableBuilder(
      column: $table.specMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specMax => $composableBuilder(
      column: $table.specMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queryStr => $composableBuilder(
      column: $table.queryStr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unReadable => $composableBuilder(
      column: $table.unReadable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$DocumentRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagType => $composableBuilder(
      column: $table.tagType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagSelectionValue => $composableBuilder(
      column: $table.tagSelectionValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specification => $composableBuilder(
      column: $table.specification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specMin => $composableBuilder(
      column: $table.specMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specMax => $composableBuilder(
      column: $table.specMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queryStr => $composableBuilder(
      column: $table.queryStr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unReadable => $composableBuilder(
      column: $table.unReadable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$DocumentRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentRecordsTable> {
  $$DocumentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<String> get tagType =>
      $composableBuilder(column: $table.tagType, builder: (column) => column);

  GeneratedColumn<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => column);

  GeneratedColumn<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName, builder: (column) => column);

  GeneratedColumn<String> get tagSelectionValue => $composableBuilder(
      column: $table.tagSelectionValue, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => column);

  GeneratedColumn<String> get specMin =>
      $composableBuilder(column: $table.specMin, builder: (column) => column);

  GeneratedColumn<String> get specMax =>
      $composableBuilder(column: $table.specMax, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get queryStr =>
      $composableBuilder(column: $table.queryStr, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get unReadable => $composableBuilder(
      column: $table.unReadable, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$DocumentRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentRecordsTable,
    DbDocumentRecord,
    $$DocumentRecordsTableFilterComposer,
    $$DocumentRecordsTableOrderingComposer,
    $$DocumentRecordsTableAnnotationComposer,
    $$DocumentRecordsTableCreateCompanionBuilder,
    $$DocumentRecordsTableUpdateCompanionBuilder,
    (
      DbDocumentRecord,
      BaseReferences<_$AppDatabase, $DocumentRecordsTable, DbDocumentRecord>
    ),
    DbDocumentRecord,
    PrefetchHooks Function()> {
  $$DocumentRecordsTableTableManager(
      _$AppDatabase db, $DocumentRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> tagId = const Value.absent(),
            Value<String?> tagName = const Value.absent(),
            Value<String?> tagType = const Value.absent(),
            Value<String?> tagGroupId = const Value.absent(),
            Value<String?> tagGroupName = const Value.absent(),
            Value<String?> tagSelectionValue = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<String?> specMin = const Value.absent(),
            Value<String?> specMax = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> queryStr = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> valueType = const Value.absent(),
            Value<String?> remark = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String> unReadable = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentRecordsCompanion(
            uid: uid,
            documentId: documentId,
            machineId: machineId,
            jobId: jobId,
            tagId: tagId,
            tagName: tagName,
            tagType: tagType,
            tagGroupId: tagGroupId,
            tagGroupName: tagGroupName,
            tagSelectionValue: tagSelectionValue,
            description: description,
            note: note,
            specification: specification,
            specMin: specMin,
            specMax: specMax,
            unit: unit,
            queryStr: queryStr,
            value: value,
            valueType: valueType,
            remark: remark,
            status: status,
            unReadable: unReadable,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> documentId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> tagId = const Value.absent(),
            Value<String?> tagName = const Value.absent(),
            Value<String?> tagType = const Value.absent(),
            Value<String?> tagGroupId = const Value.absent(),
            Value<String?> tagGroupName = const Value.absent(),
            Value<String?> tagSelectionValue = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<String?> specMin = const Value.absent(),
            Value<String?> specMax = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> queryStr = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> valueType = const Value.absent(),
            Value<String?> remark = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String> unReadable = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              DocumentRecordsCompanion.insert(
            uid: uid,
            documentId: documentId,
            machineId: machineId,
            jobId: jobId,
            tagId: tagId,
            tagName: tagName,
            tagType: tagType,
            tagGroupId: tagGroupId,
            tagGroupName: tagGroupName,
            tagSelectionValue: tagSelectionValue,
            description: description,
            note: note,
            specification: specification,
            specMin: specMin,
            specMax: specMax,
            unit: unit,
            queryStr: queryStr,
            value: value,
            valueType: valueType,
            remark: remark,
            status: status,
            unReadable: unReadable,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DocumentRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentRecordsTable,
    DbDocumentRecord,
    $$DocumentRecordsTableFilterComposer,
    $$DocumentRecordsTableOrderingComposer,
    $$DocumentRecordsTableAnnotationComposer,
    $$DocumentRecordsTableCreateCompanionBuilder,
    $$DocumentRecordsTableUpdateCompanionBuilder,
    (
      DbDocumentRecord,
      BaseReferences<_$AppDatabase, $DocumentRecordsTable, DbDocumentRecord>
    ),
    DbDocumentRecord,
    PrefetchHooks Function()>;
typedef $$JobMachinesTableCreateCompanionBuilder = JobMachinesCompanion
    Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> machineId,
  Value<String?> machineName,
  Value<String?> machineType,
  Value<String?> description,
  Value<String?> specification,
  Value<int> status,
  Value<String?> lastSync,
});
typedef $$JobMachinesTableUpdateCompanionBuilder = JobMachinesCompanion
    Function({
  Value<int> uid,
  Value<String?> jobId,
  Value<String?> machineId,
  Value<String?> machineName,
  Value<String?> machineType,
  Value<String?> description,
  Value<String?> specification,
  Value<int> status,
  Value<String?> lastSync,
});

class $$JobMachinesTableFilterComposer
    extends Composer<_$AppDatabase, $JobMachinesTable> {
  $$JobMachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$JobMachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $JobMachinesTable> {
  $$JobMachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineId => $composableBuilder(
      column: $table.machineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specification => $composableBuilder(
      column: $table.specification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$JobMachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobMachinesTable> {
  $$JobMachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get machineId =>
      $composableBuilder(column: $table.machineId, builder: (column) => column);

  GeneratedColumn<String> get machineName => $composableBuilder(
      column: $table.machineName, builder: (column) => column);

  GeneratedColumn<String> get machineType => $composableBuilder(
      column: $table.machineType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$JobMachinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JobMachinesTable,
    DbJobMachine,
    $$JobMachinesTableFilterComposer,
    $$JobMachinesTableOrderingComposer,
    $$JobMachinesTableAnnotationComposer,
    $$JobMachinesTableCreateCompanionBuilder,
    $$JobMachinesTableUpdateCompanionBuilder,
    (
      DbJobMachine,
      BaseReferences<_$AppDatabase, $JobMachinesTable, DbJobMachine>
    ),
    DbJobMachine,
    PrefetchHooks Function()> {
  $$JobMachinesTableTableManager(_$AppDatabase db, $JobMachinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobMachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobMachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobMachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> machineType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobMachinesCompanion(
            uid: uid,
            jobId: jobId,
            machineId: machineId,
            machineName: machineName,
            machineType: machineType,
            description: description,
            specification: specification,
            status: status,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> machineId = const Value.absent(),
            Value<String?> machineName = const Value.absent(),
            Value<String?> machineType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobMachinesCompanion.insert(
            uid: uid,
            jobId: jobId,
            machineId: machineId,
            machineName: machineName,
            machineType: machineType,
            description: description,
            specification: specification,
            status: status,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JobMachinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JobMachinesTable,
    DbJobMachine,
    $$JobMachinesTableFilterComposer,
    $$JobMachinesTableOrderingComposer,
    $$JobMachinesTableAnnotationComposer,
    $$JobMachinesTableCreateCompanionBuilder,
    $$JobMachinesTableUpdateCompanionBuilder,
    (
      DbJobMachine,
      BaseReferences<_$AppDatabase, $JobMachinesTable, DbJobMachine>
    ),
    DbJobMachine,
    PrefetchHooks Function()>;
typedef $$JobTagsTableCreateCompanionBuilder = JobTagsCompanion Function({
  Value<int> uid,
  Value<String?> tagId,
  Value<String?> jobId,
  Value<String?> tagName,
  Value<String?> tagType,
  Value<String?> tagGroupId,
  Value<String?> tagGroupName,
  Value<String?> description,
  Value<String?> specification,
  Value<String?> specMin,
  Value<String?> specMax,
  Value<String?> unit,
  Value<String?> queryStr,
  Value<int> status,
  Value<String?> lastSync,
});
typedef $$JobTagsTableUpdateCompanionBuilder = JobTagsCompanion Function({
  Value<int> uid,
  Value<String?> tagId,
  Value<String?> jobId,
  Value<String?> tagName,
  Value<String?> tagType,
  Value<String?> tagGroupId,
  Value<String?> tagGroupName,
  Value<String?> description,
  Value<String?> specification,
  Value<String?> specMin,
  Value<String?> specMax,
  Value<String?> unit,
  Value<String?> queryStr,
  Value<int> status,
  Value<String?> lastSync,
});

class $$JobTagsTableFilterComposer
    extends Composer<_$AppDatabase, $JobTagsTable> {
  $$JobTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagType => $composableBuilder(
      column: $table.tagType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specMin => $composableBuilder(
      column: $table.specMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specMax => $composableBuilder(
      column: $table.specMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queryStr => $composableBuilder(
      column: $table.queryStr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$JobTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobTagsTable> {
  $$JobTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagType => $composableBuilder(
      column: $table.tagType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specification => $composableBuilder(
      column: $table.specification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specMin => $composableBuilder(
      column: $table.specMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specMax => $composableBuilder(
      column: $table.specMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queryStr => $composableBuilder(
      column: $table.queryStr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$JobTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobTagsTable> {
  $$JobTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<String> get tagType =>
      $composableBuilder(column: $table.tagType, builder: (column) => column);

  GeneratedColumn<String> get tagGroupId => $composableBuilder(
      column: $table.tagGroupId, builder: (column) => column);

  GeneratedColumn<String> get tagGroupName => $composableBuilder(
      column: $table.tagGroupName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get specification => $composableBuilder(
      column: $table.specification, builder: (column) => column);

  GeneratedColumn<String> get specMin =>
      $composableBuilder(column: $table.specMin, builder: (column) => column);

  GeneratedColumn<String> get specMax =>
      $composableBuilder(column: $table.specMax, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get queryStr =>
      $composableBuilder(column: $table.queryStr, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$JobTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $JobTagsTable,
    DbJobTag,
    $$JobTagsTableFilterComposer,
    $$JobTagsTableOrderingComposer,
    $$JobTagsTableAnnotationComposer,
    $$JobTagsTableCreateCompanionBuilder,
    $$JobTagsTableUpdateCompanionBuilder,
    (DbJobTag, BaseReferences<_$AppDatabase, $JobTagsTable, DbJobTag>),
    DbJobTag,
    PrefetchHooks Function()> {
  $$JobTagsTableTableManager(_$AppDatabase db, $JobTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> tagId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> tagName = const Value.absent(),
            Value<String?> tagType = const Value.absent(),
            Value<String?> tagGroupId = const Value.absent(),
            Value<String?> tagGroupName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<String?> specMin = const Value.absent(),
            Value<String?> specMax = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> queryStr = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobTagsCompanion(
            uid: uid,
            tagId: tagId,
            jobId: jobId,
            tagName: tagName,
            tagType: tagType,
            tagGroupId: tagGroupId,
            tagGroupName: tagGroupName,
            description: description,
            specification: specification,
            specMin: specMin,
            specMax: specMax,
            unit: unit,
            queryStr: queryStr,
            status: status,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> tagId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> tagName = const Value.absent(),
            Value<String?> tagType = const Value.absent(),
            Value<String?> tagGroupId = const Value.absent(),
            Value<String?> tagGroupName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> specification = const Value.absent(),
            Value<String?> specMin = const Value.absent(),
            Value<String?> specMax = const Value.absent(),
            Value<String?> unit = const Value.absent(),
            Value<String?> queryStr = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              JobTagsCompanion.insert(
            uid: uid,
            tagId: tagId,
            jobId: jobId,
            tagName: tagName,
            tagType: tagType,
            tagGroupId: tagGroupId,
            tagGroupName: tagGroupName,
            description: description,
            specification: specification,
            specMin: specMin,
            specMax: specMax,
            unit: unit,
            queryStr: queryStr,
            status: status,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$JobTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $JobTagsTable,
    DbJobTag,
    $$JobTagsTableFilterComposer,
    $$JobTagsTableOrderingComposer,
    $$JobTagsTableAnnotationComposer,
    $$JobTagsTableCreateCompanionBuilder,
    $$JobTagsTableUpdateCompanionBuilder,
    (DbJobTag, BaseReferences<_$AppDatabase, $JobTagsTable, DbJobTag>),
    DbJobTag,
    PrefetchHooks Function()>;
typedef $$ProblemsTableCreateCompanionBuilder = ProblemsCompanion Function({
  Value<int> uid,
  Value<String?> problemId,
  Value<String?> problemName,
  Value<String?> description,
  Value<int> problemStatus,
  Value<String?> lastSync,
});
typedef $$ProblemsTableUpdateCompanionBuilder = ProblemsCompanion Function({
  Value<int> uid,
  Value<String?> problemId,
  Value<String?> problemName,
  Value<String?> description,
  Value<int> problemStatus,
  Value<String?> lastSync,
});

class $$ProblemsTableFilterComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get problemId => $composableBuilder(
      column: $table.problemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get problemName => $composableBuilder(
      column: $table.problemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get problemStatus => $composableBuilder(
      column: $table.problemStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$ProblemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get problemId => $composableBuilder(
      column: $table.problemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get problemName => $composableBuilder(
      column: $table.problemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get problemStatus => $composableBuilder(
      column: $table.problemStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$ProblemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProblemsTable> {
  $$ProblemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get problemId =>
      $composableBuilder(column: $table.problemId, builder: (column) => column);

  GeneratedColumn<String> get problemName => $composableBuilder(
      column: $table.problemName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get problemStatus => $composableBuilder(
      column: $table.problemStatus, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$ProblemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProblemsTable,
    DbProblem,
    $$ProblemsTableFilterComposer,
    $$ProblemsTableOrderingComposer,
    $$ProblemsTableAnnotationComposer,
    $$ProblemsTableCreateCompanionBuilder,
    $$ProblemsTableUpdateCompanionBuilder,
    (DbProblem, BaseReferences<_$AppDatabase, $ProblemsTable, DbProblem>),
    DbProblem,
    PrefetchHooks Function()> {
  $$ProblemsTableTableManager(_$AppDatabase db, $ProblemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProblemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProblemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProblemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> problemId = const Value.absent(),
            Value<String?> problemName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> problemStatus = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              ProblemsCompanion(
            uid: uid,
            problemId: problemId,
            problemName: problemName,
            description: description,
            problemStatus: problemStatus,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> problemId = const Value.absent(),
            Value<String?> problemName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> problemStatus = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              ProblemsCompanion.insert(
            uid: uid,
            problemId: problemId,
            problemName: problemName,
            description: description,
            problemStatus: problemStatus,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProblemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProblemsTable,
    DbProblem,
    $$ProblemsTableFilterComposer,
    $$ProblemsTableOrderingComposer,
    $$ProblemsTableAnnotationComposer,
    $$ProblemsTableCreateCompanionBuilder,
    $$ProblemsTableUpdateCompanionBuilder,
    (DbProblem, BaseReferences<_$AppDatabase, $ProblemsTable, DbProblem>),
    DbProblem,
    PrefetchHooks Function()>;
typedef $$SyncsTableCreateCompanionBuilder = SyncsCompanion Function({
  Value<int> uid,
  Value<String?> syncId,
  Value<String?> syncName,
  Value<String?> lastSync,
  Value<int> syncStatus,
  Value<String?> nextSync,
});
typedef $$SyncsTableUpdateCompanionBuilder = SyncsCompanion Function({
  Value<int> uid,
  Value<String?> syncId,
  Value<String?> syncName,
  Value<String?> lastSync,
  Value<int> syncStatus,
  Value<String?> nextSync,
});

class $$SyncsTableFilterComposer extends Composer<_$AppDatabase, $SyncsTable> {
  $$SyncsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncName => $composableBuilder(
      column: $table.syncName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextSync => $composableBuilder(
      column: $table.nextSync, builder: (column) => ColumnFilters(column));
}

class $$SyncsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncsTable> {
  $$SyncsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncId => $composableBuilder(
      column: $table.syncId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncName => $composableBuilder(
      column: $table.syncName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextSync => $composableBuilder(
      column: $table.nextSync, builder: (column) => ColumnOrderings(column));
}

class $$SyncsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncsTable> {
  $$SyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get syncName =>
      $composableBuilder(column: $table.syncName, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get nextSync =>
      $composableBuilder(column: $table.nextSync, builder: (column) => column);
}

class $$SyncsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncsTable,
    DbSync,
    $$SyncsTableFilterComposer,
    $$SyncsTableOrderingComposer,
    $$SyncsTableAnnotationComposer,
    $$SyncsTableCreateCompanionBuilder,
    $$SyncsTableUpdateCompanionBuilder,
    (DbSync, BaseReferences<_$AppDatabase, $SyncsTable, DbSync>),
    DbSync,
    PrefetchHooks Function()> {
  $$SyncsTableTableManager(_$AppDatabase db, $SyncsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> syncId = const Value.absent(),
            Value<String?> syncName = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<String?> nextSync = const Value.absent(),
          }) =>
              SyncsCompanion(
            uid: uid,
            syncId: syncId,
            syncName: syncName,
            lastSync: lastSync,
            syncStatus: syncStatus,
            nextSync: nextSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> syncId = const Value.absent(),
            Value<String?> syncName = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
            Value<int> syncStatus = const Value.absent(),
            Value<String?> nextSync = const Value.absent(),
          }) =>
              SyncsCompanion.insert(
            uid: uid,
            syncId: syncId,
            syncName: syncName,
            lastSync: lastSync,
            syncStatus: syncStatus,
            nextSync: nextSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncsTable,
    DbSync,
    $$SyncsTableFilterComposer,
    $$SyncsTableOrderingComposer,
    $$SyncsTableAnnotationComposer,
    $$SyncsTableCreateCompanionBuilder,
    $$SyncsTableUpdateCompanionBuilder,
    (DbSync, BaseReferences<_$AppDatabase, $SyncsTable, DbSync>),
    DbSync,
    PrefetchHooks Function()>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> uid,
  Value<String?> userId,
  Value<String?> userCode,
  Value<String?> password,
  Value<String?> userName,
  Value<String?> position,
  Value<int> status,
  Value<String?> lastSync,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> uid,
  Value<String?> userId,
  Value<String?> userCode,
  Value<String?> password,
  Value<String?> userName,
  Value<String?> position,
  Value<int> status,
  Value<String?> lastSync,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userCode => $composableBuilder(
      column: $table.userCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userCode => $composableBuilder(
      column: $table.userCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSync => $composableBuilder(
      column: $table.lastSync, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userCode =>
      $composableBuilder(column: $table.userCode, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    DbUser,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (DbUser, BaseReferences<_$AppDatabase, $UsersTable, DbUser>),
    DbUser,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> userCode = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              UsersCompanion(
            uid: uid,
            userId: userId,
            userCode: userCode,
            password: password,
            userName: userName,
            position: position,
            status: status,
            lastSync: lastSync,
          ),
          createCompanionCallback: ({
            Value<int> uid = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> userCode = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<String?> userName = const Value.absent(),
            Value<String?> position = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> lastSync = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            uid: uid,
            userId: userId,
            userCode: userCode,
            password: password,
            userName: userName,
            position: position,
            status: status,
            lastSync: lastSync,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    DbUser,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (DbUser, BaseReferences<_$AppDatabase, $UsersTable, DbUser>),
    DbUser,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DocumentMachinesTableTableManager get documentMachines =>
      $$DocumentMachinesTableTableManager(_db, _db.documentMachines);
  $$DocumentRecordsTableTableManager get documentRecords =>
      $$DocumentRecordsTableTableManager(_db, _db.documentRecords);
  $$JobMachinesTableTableManager get jobMachines =>
      $$JobMachinesTableTableManager(_db, _db.jobMachines);
  $$JobTagsTableTableManager get jobTags =>
      $$JobTagsTableTableManager(_db, _db.jobTags);
  $$ProblemsTableTableManager get problems =>
      $$ProblemsTableTableManager(_db, _db.problems);
  $$SyncsTableTableManager get syncs =>
      $$SyncsTableTableManager(_db, _db.syncs);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
}
