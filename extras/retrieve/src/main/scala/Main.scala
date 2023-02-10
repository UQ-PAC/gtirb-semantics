import java.io.{FileInputStream, BufferedWriter, FileWriter, File}
import com.grammatech.gtirb.proto.IR.IR
import com.grammatech.gtirb.proto.Module.Module
import com.grammatech.gtirb.proto.Section.Section
import spray.json._
import DefaultJsonProtocol._

class CompressionException(s : String) extends Exception(s) {}

class TranslationBlock(val ascii: Char, val bits: Int, val repr: String) {
  def getChar = ascii
  def getBits = bits
  def getRepr = repr
}

def main(args: Array[String]) = {
  val ir        = readIR(args(0))
  val cfg       = ir.cfg
  val mods      = ir.modules
  val texts     = mods.map(_.sections(0)).filter(_.name == ".text")
  val semantics = getSemantics(mods)
}

def readIR(path: String) = {
  var fIn = new FileInputStream(path)
  IR.parseFrom(fIn)
}

def dump(json: String, path: String) = {
  val bw = new BufferedWriter(new FileWriter(new File(path)))
  bw.write(json)
  bw.close()
}

def getSemantics(mods: Seq[Module]) = {
  val modAux        = mods.map(_.auxData)
  val astsRaw       = modAux.map(_.get("ast").get.data).head.toByteArray()
  val nMapBlk       = astsRaw(0).toInt
  val popped        = astsRaw.slice(1, astsRaw.length)
  val mapBlocks     = pullTMap(popped, nMapBlk, List[TranslationBlock]())
  val mapSize       = countMap(mapBlocks)
  val translate     = blocksToMap(mapBlocks)
  println(translate)
  val binary        = bytesToBinString(popped.slice(mapSize, popped.length))
  val json          = '{' + unprefix(binary, 0, 1, "", translate) + '}'
  println(json)
}

def pad_8(in: String) = {
  val nlen = in.length % 8
  val plen = if (nlen == 0) { 0 } else { 8 - nlen } 
  "0" * plen
}

def bytesToBinString(b: Iterable[Byte]) = {
  b.map(_.toInt).map(s => s & 0xFF).map(_.toBinaryString).map(s => (pad_8(s) + s)).mkString("")
}

def pullTMap(raw: Array[Byte], mSiz: Int, map: List[TranslationBlock]) : List[TranslationBlock] = {
  if (mSiz == 0) {
    map
  } else {
    val bits  = raw(1).toInt
    val cend  = if (bits > 8) { 4 } else { 3 }
    val comp  = bytesToBinString(raw.slice(2, cend))
    val key   = comp.slice(comp.length - bits, comp.length)
    val cut   = raw.slice(cend, raw.length)
    val entry = TranslationBlock(raw(0).toChar, bits, key)
    val nMap  = entry :: map
    pullTMap(cut, (mSiz - 1), nMap)
  } 
}

def countMap(tMap: List[TranslationBlock]) : Int = {
  tMap match {
    case Nil    => 0
    case h :: t => countMap(t) + (if (h.bits > 8)  { 4 } else { 3 })
  }
}

def blocksToMap(blocks: List[TranslationBlock]) : Map[String, Char] = {
  blocks match {
    case Nil    => Map[String, Char]()
    case h :: t => blocksToMap(t) + (h.getRepr -> h.getChar)
  }
}

def unprefix(bits: String, start: Int, len: Int, dcmp: String, tMap: Map[String, Char]) : String = {
  val blen    = bits.length
  val target  = start + len
  if (target >= blen) {
    dcmp
  } else {
    val prefix  = bits.substring(start, target)
    val ascii   = tMap.get(prefix)
    ascii match {
      case None         => unprefix(bits, start, (len + 1), dcmp, tMap)
      case Some(letter) => unprefix(bits, target, 1, (dcmp + letter), tMap)
    }
  }
}