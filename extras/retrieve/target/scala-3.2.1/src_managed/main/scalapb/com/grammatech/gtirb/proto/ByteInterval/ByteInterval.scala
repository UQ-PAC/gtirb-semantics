// Generated by the Scala Plugin for the Protocol Buffer Compiler.
// Do not edit!
//
// Protofile syntax: PROTO3

package com.grammatech.gtirb.proto.ByteInterval

@SerialVersionUID(0L)
final case class ByteInterval(
    uuid: _root_.com.google.protobuf.ByteString = _root_.com.google.protobuf.ByteString.EMPTY,
    blocks: _root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.Block] = _root_.scala.Seq.empty,
    symbolicExpressions: _root_.scala.collection.immutable.Map[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression] = _root_.scala.collection.immutable.Map.empty,
    hasAddress: _root_.scala.Boolean = false,
    address: _root_.scala.Long = 0L,
    size: _root_.scala.Long = 0L,
    contents: _root_.com.google.protobuf.ByteString = _root_.com.google.protobuf.ByteString.EMPTY,
    unknownFields: _root_.scalapb.UnknownFieldSet = _root_.scalapb.UnknownFieldSet.empty
    ) extends scalapb.GeneratedMessage with scalapb.lenses.Updatable[ByteInterval] {
    @transient
    private[this] var __serializedSizeMemoized: _root_.scala.Int = 0
    private[this] def __computeSerializedSize(): _root_.scala.Int = {
      var __size = 0
      
      {
        val __value = uuid
        if (!__value.isEmpty) {
          __size += _root_.com.google.protobuf.CodedOutputStream.computeBytesSize(1, __value)
        }
      };
      blocks.foreach { __item =>
        val __value = __item
        __size += 1 + _root_.com.google.protobuf.CodedOutputStream.computeUInt32SizeNoTag(__value.serializedSize) + __value.serializedSize
      }
      symbolicExpressions.foreach { __item =>
        val __value = com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toBase(__item)
        __size += 1 + _root_.com.google.protobuf.CodedOutputStream.computeUInt32SizeNoTag(__value.serializedSize) + __value.serializedSize
      }
      
      {
        val __value = hasAddress
        if (__value != false) {
          __size += _root_.com.google.protobuf.CodedOutputStream.computeBoolSize(4, __value)
        }
      };
      
      {
        val __value = address
        if (__value != 0L) {
          __size += _root_.com.google.protobuf.CodedOutputStream.computeUInt64Size(5, __value)
        }
      };
      
      {
        val __value = size
        if (__value != 0L) {
          __size += _root_.com.google.protobuf.CodedOutputStream.computeUInt64Size(6, __value)
        }
      };
      
      {
        val __value = contents
        if (!__value.isEmpty) {
          __size += _root_.com.google.protobuf.CodedOutputStream.computeBytesSize(7, __value)
        }
      };
      __size += unknownFields.serializedSize
      __size
    }
    override def serializedSize: _root_.scala.Int = {
      var __size = __serializedSizeMemoized
      if (__size == 0) {
        __size = __computeSerializedSize() + 1
        __serializedSizeMemoized = __size
      }
      __size - 1
      
    }
    def writeTo(`_output__`: _root_.com.google.protobuf.CodedOutputStream): _root_.scala.Unit = {
      {
        val __v = uuid
        if (!__v.isEmpty) {
          _output__.writeBytes(1, __v)
        }
      };
      blocks.foreach { __v =>
        val __m = __v
        _output__.writeTag(2, 2)
        _output__.writeUInt32NoTag(__m.serializedSize)
        __m.writeTo(_output__)
      };
      symbolicExpressions.foreach { __v =>
        val __m = com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toBase(__v)
        _output__.writeTag(3, 2)
        _output__.writeUInt32NoTag(__m.serializedSize)
        __m.writeTo(_output__)
      };
      {
        val __v = hasAddress
        if (__v != false) {
          _output__.writeBool(4, __v)
        }
      };
      {
        val __v = address
        if (__v != 0L) {
          _output__.writeUInt64(5, __v)
        }
      };
      {
        val __v = size
        if (__v != 0L) {
          _output__.writeUInt64(6, __v)
        }
      };
      {
        val __v = contents
        if (!__v.isEmpty) {
          _output__.writeBytes(7, __v)
        }
      };
      unknownFields.writeTo(_output__)
    }
    def withUuid(__v: _root_.com.google.protobuf.ByteString): ByteInterval = copy(uuid = __v)
    def clearBlocks = copy(blocks = _root_.scala.Seq.empty)
    def addBlocks(__vs: com.grammatech.gtirb.proto.ByteInterval.Block *): ByteInterval = addAllBlocks(__vs)
    def addAllBlocks(__vs: Iterable[com.grammatech.gtirb.proto.ByteInterval.Block]): ByteInterval = copy(blocks = blocks ++ __vs)
    def withBlocks(__v: _root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.Block]): ByteInterval = copy(blocks = __v)
    def clearSymbolicExpressions = copy(symbolicExpressions = _root_.scala.collection.immutable.Map.empty)
    def addSymbolicExpressions(__vs: (_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression) *): ByteInterval = addAllSymbolicExpressions(__vs)
    def addAllSymbolicExpressions(__vs: Iterable[(_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression)]): ByteInterval = copy(symbolicExpressions = symbolicExpressions ++ __vs)
    def withSymbolicExpressions(__v: _root_.scala.collection.immutable.Map[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]): ByteInterval = copy(symbolicExpressions = __v)
    def withHasAddress(__v: _root_.scala.Boolean): ByteInterval = copy(hasAddress = __v)
    def withAddress(__v: _root_.scala.Long): ByteInterval = copy(address = __v)
    def withSize(__v: _root_.scala.Long): ByteInterval = copy(size = __v)
    def withContents(__v: _root_.com.google.protobuf.ByteString): ByteInterval = copy(contents = __v)
    def withUnknownFields(__v: _root_.scalapb.UnknownFieldSet) = copy(unknownFields = __v)
    def discardUnknownFields = copy(unknownFields = _root_.scalapb.UnknownFieldSet.empty)
    def getFieldByNumber(__fieldNumber: _root_.scala.Int): _root_.scala.Any = {
      (__fieldNumber: @_root_.scala.unchecked) match {
        case 1 => {
          val __t = uuid
          if (__t != _root_.com.google.protobuf.ByteString.EMPTY) __t else null
        }
        case 2 => blocks
        case 3 => symbolicExpressions.iterator.map(com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toBase(_)).toSeq
        case 4 => {
          val __t = hasAddress
          if (__t != false) __t else null
        }
        case 5 => {
          val __t = address
          if (__t != 0L) __t else null
        }
        case 6 => {
          val __t = size
          if (__t != 0L) __t else null
        }
        case 7 => {
          val __t = contents
          if (__t != _root_.com.google.protobuf.ByteString.EMPTY) __t else null
        }
      }
    }
    def getField(__field: _root_.scalapb.descriptors.FieldDescriptor): _root_.scalapb.descriptors.PValue = {
      _root_.scala.Predef.require(__field.containingMessage eq companion.scalaDescriptor)
      (__field.number: @_root_.scala.unchecked) match {
        case 1 => _root_.scalapb.descriptors.PByteString(uuid)
        case 2 => _root_.scalapb.descriptors.PRepeated(blocks.iterator.map(_.toPMessage).toVector)
        case 3 => _root_.scalapb.descriptors.PRepeated(symbolicExpressions.iterator.map(com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toBase(_).toPMessage).toVector)
        case 4 => _root_.scalapb.descriptors.PBoolean(hasAddress)
        case 5 => _root_.scalapb.descriptors.PLong(address)
        case 6 => _root_.scalapb.descriptors.PLong(size)
        case 7 => _root_.scalapb.descriptors.PByteString(contents)
      }
    }
    def toProtoString: _root_.scala.Predef.String = _root_.scalapb.TextFormat.printToUnicodeString(this)
    def companion: com.grammatech.gtirb.proto.ByteInterval.ByteInterval.type = com.grammatech.gtirb.proto.ByteInterval.ByteInterval
    // @@protoc_insertion_point(GeneratedMessage[gtirb.proto.ByteInterval])
}

object ByteInterval extends scalapb.GeneratedMessageCompanion[com.grammatech.gtirb.proto.ByteInterval.ByteInterval] {
  implicit def messageCompanion: scalapb.GeneratedMessageCompanion[com.grammatech.gtirb.proto.ByteInterval.ByteInterval] = this
  def parseFrom(`_input__`: _root_.com.google.protobuf.CodedInputStream): com.grammatech.gtirb.proto.ByteInterval.ByteInterval = {
    var __uuid: _root_.com.google.protobuf.ByteString = _root_.com.google.protobuf.ByteString.EMPTY
    val __blocks: _root_.scala.collection.immutable.VectorBuilder[com.grammatech.gtirb.proto.ByteInterval.Block] = new _root_.scala.collection.immutable.VectorBuilder[com.grammatech.gtirb.proto.ByteInterval.Block]
    val __symbolicExpressions: _root_.scala.collection.mutable.Builder[(_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression), _root_.scala.collection.immutable.Map[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]] = _root_.scala.collection.immutable.Map.newBuilder[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]
    var __hasAddress: _root_.scala.Boolean = false
    var __address: _root_.scala.Long = 0L
    var __size: _root_.scala.Long = 0L
    var __contents: _root_.com.google.protobuf.ByteString = _root_.com.google.protobuf.ByteString.EMPTY
    var `_unknownFields__`: _root_.scalapb.UnknownFieldSet.Builder = null
    var _done__ = false
    while (!_done__) {
      val _tag__ = _input__.readTag()
      _tag__ match {
        case 0 => _done__ = true
        case 10 =>
          __uuid = _input__.readBytes()
        case 18 =>
          __blocks += _root_.scalapb.LiteParser.readMessage[com.grammatech.gtirb.proto.ByteInterval.Block](_input__)
        case 26 =>
          __symbolicExpressions += com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toCustom(_root_.scalapb.LiteParser.readMessage[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry](_input__))
        case 32 =>
          __hasAddress = _input__.readBool()
        case 40 =>
          __address = _input__.readUInt64()
        case 48 =>
          __size = _input__.readUInt64()
        case 58 =>
          __contents = _input__.readBytes()
        case tag =>
          if (_unknownFields__ == null) {
            _unknownFields__ = new _root_.scalapb.UnknownFieldSet.Builder()
          }
          _unknownFields__.parseField(tag, _input__)
      }
    }
    com.grammatech.gtirb.proto.ByteInterval.ByteInterval(
        uuid = __uuid,
        blocks = __blocks.result(),
        symbolicExpressions = __symbolicExpressions.result(),
        hasAddress = __hasAddress,
        address = __address,
        size = __size,
        contents = __contents,
        unknownFields = if (_unknownFields__ == null) _root_.scalapb.UnknownFieldSet.empty else _unknownFields__.result()
    )
  }
  implicit def messageReads: _root_.scalapb.descriptors.Reads[com.grammatech.gtirb.proto.ByteInterval.ByteInterval] = _root_.scalapb.descriptors.Reads{
    case _root_.scalapb.descriptors.PMessage(__fieldsMap) =>
      _root_.scala.Predef.require(__fieldsMap.keys.forall(_.containingMessage eq scalaDescriptor), "FieldDescriptor does not match message type.")
      com.grammatech.gtirb.proto.ByteInterval.ByteInterval(
        uuid = __fieldsMap.get(scalaDescriptor.findFieldByNumber(1).get).map(_.as[_root_.com.google.protobuf.ByteString]).getOrElse(_root_.com.google.protobuf.ByteString.EMPTY),
        blocks = __fieldsMap.get(scalaDescriptor.findFieldByNumber(2).get).map(_.as[_root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.Block]]).getOrElse(_root_.scala.Seq.empty),
        symbolicExpressions = __fieldsMap.get(scalaDescriptor.findFieldByNumber(3).get).map(_.as[_root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry]]).getOrElse(_root_.scala.Seq.empty).iterator.map(com.grammatech.gtirb.proto.ByteInterval.ByteInterval._typemapper_symbolicExpressions.toCustom(_)).toMap,
        hasAddress = __fieldsMap.get(scalaDescriptor.findFieldByNumber(4).get).map(_.as[_root_.scala.Boolean]).getOrElse(false),
        address = __fieldsMap.get(scalaDescriptor.findFieldByNumber(5).get).map(_.as[_root_.scala.Long]).getOrElse(0L),
        size = __fieldsMap.get(scalaDescriptor.findFieldByNumber(6).get).map(_.as[_root_.scala.Long]).getOrElse(0L),
        contents = __fieldsMap.get(scalaDescriptor.findFieldByNumber(7).get).map(_.as[_root_.com.google.protobuf.ByteString]).getOrElse(_root_.com.google.protobuf.ByteString.EMPTY)
      )
    case _ => throw new RuntimeException("Expected PMessage")
  }
  def javaDescriptor: _root_.com.google.protobuf.Descriptors.Descriptor = ByteIntervalProto.javaDescriptor.getMessageTypes().get(1)
  def scalaDescriptor: _root_.scalapb.descriptors.Descriptor = ByteIntervalProto.scalaDescriptor.messages(1)
  def messageCompanionForFieldNumber(__number: _root_.scala.Int): _root_.scalapb.GeneratedMessageCompanion[_] = {
    var __out: _root_.scalapb.GeneratedMessageCompanion[_] = null
    (__number: @_root_.scala.unchecked) match {
      case 2 => __out = com.grammatech.gtirb.proto.ByteInterval.Block
      case 3 => __out = com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry
    }
    __out
  }
  lazy val nestedMessagesCompanions: Seq[_root_.scalapb.GeneratedMessageCompanion[_ <: _root_.scalapb.GeneratedMessage]] =
    Seq[_root_.scalapb.GeneratedMessageCompanion[_ <: _root_.scalapb.GeneratedMessage]](
      _root_.com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry
    )
  def enumCompanionForFieldNumber(__fieldNumber: _root_.scala.Int): _root_.scalapb.GeneratedEnumCompanion[_] = throw new MatchError(__fieldNumber)
  lazy val defaultInstance = com.grammatech.gtirb.proto.ByteInterval.ByteInterval(
    uuid = _root_.com.google.protobuf.ByteString.EMPTY,
    blocks = _root_.scala.Seq.empty,
    symbolicExpressions = _root_.scala.collection.immutable.Map.empty,
    hasAddress = false,
    address = 0L,
    size = 0L,
    contents = _root_.com.google.protobuf.ByteString.EMPTY
  )
  @SerialVersionUID(0L)
  final case class SymbolicExpressionsEntry(
      key: _root_.scala.Long = 0L,
      value: _root_.scala.Option[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression] = _root_.scala.None,
      unknownFields: _root_.scalapb.UnknownFieldSet = _root_.scalapb.UnknownFieldSet.empty
      ) extends scalapb.GeneratedMessage with scalapb.lenses.Updatable[SymbolicExpressionsEntry] {
      @transient
      private[this] var __serializedSizeMemoized: _root_.scala.Int = 0
      private[this] def __computeSerializedSize(): _root_.scala.Int = {
        var __size = 0
        
        {
          val __value = key
          if (__value != 0L) {
            __size += _root_.com.google.protobuf.CodedOutputStream.computeUInt64Size(1, __value)
          }
        };
        if (value.isDefined) {
          val __value = value.get
          __size += 1 + _root_.com.google.protobuf.CodedOutputStream.computeUInt32SizeNoTag(__value.serializedSize) + __value.serializedSize
        };
        __size += unknownFields.serializedSize
        __size
      }
      override def serializedSize: _root_.scala.Int = {
        var __size = __serializedSizeMemoized
        if (__size == 0) {
          __size = __computeSerializedSize() + 1
          __serializedSizeMemoized = __size
        }
        __size - 1
        
      }
      def writeTo(`_output__`: _root_.com.google.protobuf.CodedOutputStream): _root_.scala.Unit = {
        {
          val __v = key
          if (__v != 0L) {
            _output__.writeUInt64(1, __v)
          }
        };
        value.foreach { __v =>
          val __m = __v
          _output__.writeTag(2, 2)
          _output__.writeUInt32NoTag(__m.serializedSize)
          __m.writeTo(_output__)
        };
        unknownFields.writeTo(_output__)
      }
      def withKey(__v: _root_.scala.Long): SymbolicExpressionsEntry = copy(key = __v)
      def getValue: com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression = value.getOrElse(com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression.defaultInstance)
      def clearValue: SymbolicExpressionsEntry = copy(value = _root_.scala.None)
      def withValue(__v: com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression): SymbolicExpressionsEntry = copy(value = Option(__v))
      def withUnknownFields(__v: _root_.scalapb.UnknownFieldSet) = copy(unknownFields = __v)
      def discardUnknownFields = copy(unknownFields = _root_.scalapb.UnknownFieldSet.empty)
      def getFieldByNumber(__fieldNumber: _root_.scala.Int): _root_.scala.Any = {
        (__fieldNumber: @_root_.scala.unchecked) match {
          case 1 => {
            val __t = key
            if (__t != 0L) __t else null
          }
          case 2 => value.orNull
        }
      }
      def getField(__field: _root_.scalapb.descriptors.FieldDescriptor): _root_.scalapb.descriptors.PValue = {
        _root_.scala.Predef.require(__field.containingMessage eq companion.scalaDescriptor)
        (__field.number: @_root_.scala.unchecked) match {
          case 1 => _root_.scalapb.descriptors.PLong(key)
          case 2 => value.map(_.toPMessage).getOrElse(_root_.scalapb.descriptors.PEmpty)
        }
      }
      def toProtoString: _root_.scala.Predef.String = _root_.scalapb.TextFormat.printToUnicodeString(this)
      def companion: com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry.type = com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry
      // @@protoc_insertion_point(GeneratedMessage[gtirb.proto.ByteInterval.SymbolicExpressionsEntry])
  }
  
  object SymbolicExpressionsEntry extends scalapb.GeneratedMessageCompanion[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry] {
    implicit def messageCompanion: scalapb.GeneratedMessageCompanion[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry] = this
    def parseFrom(`_input__`: _root_.com.google.protobuf.CodedInputStream): com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry = {
      var __key: _root_.scala.Long = 0L
      var __value: _root_.scala.Option[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression] = _root_.scala.None
      var `_unknownFields__`: _root_.scalapb.UnknownFieldSet.Builder = null
      var _done__ = false
      while (!_done__) {
        val _tag__ = _input__.readTag()
        _tag__ match {
          case 0 => _done__ = true
          case 8 =>
            __key = _input__.readUInt64()
          case 18 =>
            __value = Option(__value.fold(_root_.scalapb.LiteParser.readMessage[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression](_input__))(_root_.scalapb.LiteParser.readMessage(_input__, _)))
          case tag =>
            if (_unknownFields__ == null) {
              _unknownFields__ = new _root_.scalapb.UnknownFieldSet.Builder()
            }
            _unknownFields__.parseField(tag, _input__)
        }
      }
      com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry(
          key = __key,
          value = __value,
          unknownFields = if (_unknownFields__ == null) _root_.scalapb.UnknownFieldSet.empty else _unknownFields__.result()
      )
    }
    implicit def messageReads: _root_.scalapb.descriptors.Reads[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry] = _root_.scalapb.descriptors.Reads{
      case _root_.scalapb.descriptors.PMessage(__fieldsMap) =>
        _root_.scala.Predef.require(__fieldsMap.keys.forall(_.containingMessage eq scalaDescriptor), "FieldDescriptor does not match message type.")
        com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry(
          key = __fieldsMap.get(scalaDescriptor.findFieldByNumber(1).get).map(_.as[_root_.scala.Long]).getOrElse(0L),
          value = __fieldsMap.get(scalaDescriptor.findFieldByNumber(2).get).flatMap(_.as[_root_.scala.Option[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]])
        )
      case _ => throw new RuntimeException("Expected PMessage")
    }
    def javaDescriptor: _root_.com.google.protobuf.Descriptors.Descriptor = com.grammatech.gtirb.proto.ByteInterval.ByteInterval.javaDescriptor.getNestedTypes().get(0)
    def scalaDescriptor: _root_.scalapb.descriptors.Descriptor = com.grammatech.gtirb.proto.ByteInterval.ByteInterval.scalaDescriptor.nestedMessages(0)
    def messageCompanionForFieldNumber(__number: _root_.scala.Int): _root_.scalapb.GeneratedMessageCompanion[_] = {
      var __out: _root_.scalapb.GeneratedMessageCompanion[_] = null
      (__number: @_root_.scala.unchecked) match {
        case 2 => __out = com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression
      }
      __out
    }
    lazy val nestedMessagesCompanions: Seq[_root_.scalapb.GeneratedMessageCompanion[_ <: _root_.scalapb.GeneratedMessage]] = Seq.empty
    def enumCompanionForFieldNumber(__fieldNumber: _root_.scala.Int): _root_.scalapb.GeneratedEnumCompanion[_] = throw new MatchError(__fieldNumber)
    lazy val defaultInstance = com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry(
      key = 0L,
      value = _root_.scala.None
    )
    implicit class SymbolicExpressionsEntryLens[UpperPB](_l: _root_.scalapb.lenses.Lens[UpperPB, com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry]) extends _root_.scalapb.lenses.ObjectLens[UpperPB, com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry](_l) {
      def key: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Long] = field(_.key)((c_, f_) => c_.copy(key = f_))
      def value: _root_.scalapb.lenses.Lens[UpperPB, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression] = field(_.getValue)((c_, f_) => c_.copy(value = Option(f_)))
      def optionalValue: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Option[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]] = field(_.value)((c_, f_) => c_.copy(value = f_))
    }
    final val KEY_FIELD_NUMBER = 1
    final val VALUE_FIELD_NUMBER = 2
    @transient
    implicit val keyValueMapper: _root_.scalapb.TypeMapper[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry, (_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression)] =
      _root_.scalapb.TypeMapper[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry, (_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression)](__m => (__m.key, __m.getValue))(__p => com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry(__p._1, Some(__p._2)))
    def of(
      key: _root_.scala.Long,
      value: _root_.scala.Option[com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]
    ): _root_.com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry = _root_.com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry(
      key,
      value
    )
    // @@protoc_insertion_point(GeneratedMessageCompanion[gtirb.proto.ByteInterval.SymbolicExpressionsEntry])
  }
  
  implicit class ByteIntervalLens[UpperPB](_l: _root_.scalapb.lenses.Lens[UpperPB, com.grammatech.gtirb.proto.ByteInterval.ByteInterval]) extends _root_.scalapb.lenses.ObjectLens[UpperPB, com.grammatech.gtirb.proto.ByteInterval.ByteInterval](_l) {
    def uuid: _root_.scalapb.lenses.Lens[UpperPB, _root_.com.google.protobuf.ByteString] = field(_.uuid)((c_, f_) => c_.copy(uuid = f_))
    def blocks: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.Block]] = field(_.blocks)((c_, f_) => c_.copy(blocks = f_))
    def symbolicExpressions: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.collection.immutable.Map[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression]] = field(_.symbolicExpressions)((c_, f_) => c_.copy(symbolicExpressions = f_))
    def hasAddress: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Boolean] = field(_.hasAddress)((c_, f_) => c_.copy(hasAddress = f_))
    def address: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Long] = field(_.address)((c_, f_) => c_.copy(address = f_))
    def size: _root_.scalapb.lenses.Lens[UpperPB, _root_.scala.Long] = field(_.size)((c_, f_) => c_.copy(size = f_))
    def contents: _root_.scalapb.lenses.Lens[UpperPB, _root_.com.google.protobuf.ByteString] = field(_.contents)((c_, f_) => c_.copy(contents = f_))
  }
  final val UUID_FIELD_NUMBER = 1
  final val BLOCKS_FIELD_NUMBER = 2
  final val SYMBOLIC_EXPRESSIONS_FIELD_NUMBER = 3
  final val HAS_ADDRESS_FIELD_NUMBER = 4
  final val ADDRESS_FIELD_NUMBER = 5
  final val SIZE_FIELD_NUMBER = 6
  final val CONTENTS_FIELD_NUMBER = 7
  @transient
  private[ByteInterval] val _typemapper_symbolicExpressions: _root_.scalapb.TypeMapper[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry, (_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression)] = implicitly[_root_.scalapb.TypeMapper[com.grammatech.gtirb.proto.ByteInterval.ByteInterval.SymbolicExpressionsEntry, (_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression)]]
  def of(
    uuid: _root_.com.google.protobuf.ByteString,
    blocks: _root_.scala.Seq[com.grammatech.gtirb.proto.ByteInterval.Block],
    symbolicExpressions: _root_.scala.collection.immutable.Map[_root_.scala.Long, com.grammatech.gtirb.proto.SymbolicExpression.SymbolicExpression],
    hasAddress: _root_.scala.Boolean,
    address: _root_.scala.Long,
    size: _root_.scala.Long,
    contents: _root_.com.google.protobuf.ByteString
  ): _root_.com.grammatech.gtirb.proto.ByteInterval.ByteInterval = _root_.com.grammatech.gtirb.proto.ByteInterval.ByteInterval(
    uuid,
    blocks,
    symbolicExpressions,
    hasAddress,
    address,
    size,
    contents
  )
  // @@protoc_insertion_point(GeneratedMessageCompanion[gtirb.proto.ByteInterval])
}
