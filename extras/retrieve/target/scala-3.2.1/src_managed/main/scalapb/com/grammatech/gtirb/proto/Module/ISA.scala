// Generated by the Scala Plugin for the Protocol Buffer Compiler.
// Do not edit!
//
// Protofile syntax: PROTO3

package com.grammatech.gtirb.proto.Module

sealed abstract class ISA(val value: _root_.scala.Int) extends _root_.scalapb.GeneratedEnum {
  type EnumType = ISA
  def isIsaUndefined: _root_.scala.Boolean = false
  def isIa32: _root_.scala.Boolean = false
  def isPpc32: _root_.scala.Boolean = false
  def isX64: _root_.scala.Boolean = false
  def isArm: _root_.scala.Boolean = false
  def isValidButUnsupported: _root_.scala.Boolean = false
  def isPpc64: _root_.scala.Boolean = false
  def isArm64: _root_.scala.Boolean = false
  def isMips32: _root_.scala.Boolean = false
  def isMips64: _root_.scala.Boolean = false
  def companion: _root_.scalapb.GeneratedEnumCompanion[ISA] = com.grammatech.gtirb.proto.Module.ISA
  final def asRecognized: _root_.scala.Option[com.grammatech.gtirb.proto.Module.ISA.Recognized] = if (isUnrecognized) _root_.scala.None else _root_.scala.Some(this.asInstanceOf[com.grammatech.gtirb.proto.Module.ISA.Recognized])
}

object ISA extends _root_.scalapb.GeneratedEnumCompanion[ISA] {
  sealed trait Recognized extends ISA
  implicit def enumCompanion: _root_.scalapb.GeneratedEnumCompanion[ISA] = this
  
  @SerialVersionUID(0L)
  case object ISA_Undefined extends ISA(0) with ISA.Recognized {
    val index = 0
    val name = "ISA_Undefined"
    override def isIsaUndefined: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object IA32 extends ISA(1) with ISA.Recognized {
    val index = 1
    val name = "IA32"
    override def isIa32: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object PPC32 extends ISA(2) with ISA.Recognized {
    val index = 2
    val name = "PPC32"
    override def isPpc32: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object X64 extends ISA(3) with ISA.Recognized {
    val index = 3
    val name = "X64"
    override def isX64: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object ARM extends ISA(4) with ISA.Recognized {
    val index = 4
    val name = "ARM"
    override def isArm: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object ValidButUnsupported extends ISA(5) with ISA.Recognized {
    val index = 5
    val name = "ValidButUnsupported"
    override def isValidButUnsupported: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object PPC64 extends ISA(6) with ISA.Recognized {
    val index = 6
    val name = "PPC64"
    override def isPpc64: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object ARM64 extends ISA(7) with ISA.Recognized {
    val index = 7
    val name = "ARM64"
    override def isArm64: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object MIPS32 extends ISA(8) with ISA.Recognized {
    val index = 8
    val name = "MIPS32"
    override def isMips32: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  case object MIPS64 extends ISA(9) with ISA.Recognized {
    val index = 9
    val name = "MIPS64"
    override def isMips64: _root_.scala.Boolean = true
  }
  
  @SerialVersionUID(0L)
  final case class Unrecognized(unrecognizedValue: _root_.scala.Int) extends ISA(unrecognizedValue) with _root_.scalapb.UnrecognizedEnum
  lazy val values = scala.collection.immutable.Seq(ISA_Undefined, IA32, PPC32, X64, ARM, ValidButUnsupported, PPC64, ARM64, MIPS32, MIPS64)
  def fromValue(__value: _root_.scala.Int): ISA = __value match {
    case 0 => ISA_Undefined
    case 1 => IA32
    case 2 => PPC32
    case 3 => X64
    case 4 => ARM
    case 5 => ValidButUnsupported
    case 6 => PPC64
    case 7 => ARM64
    case 8 => MIPS32
    case 9 => MIPS64
    case __other => Unrecognized(__other)
  }
  def javaDescriptor: _root_.com.google.protobuf.Descriptors.EnumDescriptor = ModuleProto.javaDescriptor.getEnumTypes().get(1)
  def scalaDescriptor: _root_.scalapb.descriptors.EnumDescriptor = ModuleProto.scalaDescriptor.enums(1)
}