import java.io.{FileInputStream, BufferedWriter, FileWriter, File}
import com.grammatech.gtirb.proto.IR.IR
import com.grammatech.gtirb.proto.Module.Module
import com.grammatech.gtirb.proto.Section.Section
import spray.json._
import DefaultJsonProtocol._

/* Individual block in the decompression map header found before the compressed semantics auxdata */
class TranslationBlock(val ascii: Char, val bits: Int, val repr: String) {
  def getChar = ascii
  def getBits = bits
  def getRepr = repr
}

/**
 * Mostly just boilerplate; take this and develop your own tools from here.
 *
 * Accesses the modified GTIRB IR (.gts file) and retrieves:
 * cfg        : interprocess control flow graph
 * texts      : text section from each compilation module
 * symbols    : symbols from each compilation module
 * semantics  : Spray json AST of the semantic information
 *              https://github.com/spray/spray-json
 */
def main(args: Array[String]) = {
  val InFile    = 0
  val OutFile   = 1
  val TextSect  = ".text"

  var fIn       = new FileInputStream(args(InFile))
  val ir        = IR.parseFrom(fIn)
  val mods      = ir.modules

  val cfg       = ir.cfg
  val texts     = mods.map(_.sections.head).filter(_.name == TextSect)
  val symbols   = mods.map(_.symbols)
  val semantics = mods.map(getSemantics)
  val top       = semantics.head.prettyPrint // Just for example's sake
  val bw        = new BufferedWriter(new FileWriter(new File(args(OutFile))))
  bw.write(top)
  bw.close()
}

/* Retrieve the semantics json data from a compilation module's auxdata */
def getSemantics(mod: Module) = {
  val JOpen     = '{'
  val JClose    = '}'
  val BinStart  = 0
  val BinInitL  = 1
  val Semantics = "ast"
  val NBlocks   = 0
  val MapStart  = 1

  val astRaw    = mod.auxData.get(Semantics).get.data.toByteArray()
  val nMapBlk   = astRaw(NBlocks).toInt
  val popped    = astRaw.slice(MapStart, astRaw.length)
  val mapBlocks = pullTMap(popped, nMapBlk, List[TranslationBlock]())
  val mapSize   = countMap(mapBlocks)
  val translate = blocksToMap(mapBlocks)
  val binary    = bytesToBinString(popped.slice(mapSize, popped.length))
  val json      = JOpen + unprefix(binary, BinStart, BinInitL, "", translate) + JClose
  json.parseJson
}

/* Decompression helper */
def pad_8(in: String) = {
  val BLen  = 8
  val Pad   = "0"

  val nlen  = in.length % BLen
  val plen  = if (nlen == 0) { 0 } else { BLen - nlen } 
  Pad * plen
}

/* Decompression helper */
def bytesToBinString(b: Iterable[Byte]) = {
  val UInt8T  = 0xFF
  val Join    = ""

  b.map(_.toInt).map(s => s & UInt8T).map(_.toBinaryString).map(s => (pad_8(s) + s)).mkString(Join)
}

/* Separate and deserialise translation map header from the compressed semantics auxdata */
def pullTMap(raw: Array[Byte], mSiz: Int, map: List[TranslationBlock]) : List[TranslationBlock] = {
  val Comp1B    = 3
  val Comp2B    = 4
  val BLen      = 8
  val Ascii     = 0
  val CompStart = 2
  
  if (mSiz == 0) {
    map
  } else {
    val bits  = raw(1).toInt
    val cend  = if (bits > BLen) { Comp2B } else { Comp1B }
    val comp  = bytesToBinString(raw.slice(CompStart, cend))
    val key   = comp.slice(comp.length - bits, comp.length)
    val cut   = raw.slice(cend, raw.length)
    val entry = TranslationBlock(raw(Ascii).toChar, bits, key)
    val nMap  = entry :: map
    pullTMap(cut, (mSiz - 1), nMap)
  } 
}

/* Determine the total serialised size of the compression translation map */
def countMap(tMap: List[TranslationBlock]) : Int = {
  val Comp1B    = 3
  val Comp2B    = 4
  val BLen      = 8
  tMap match {
    case Nil    => 0
    case h :: t => countMap(t) + (if (h.bits > BLen)  { Comp2B } else { Comp1B })
  }
}

/* Convert translation header blocks to a hashmap for speedy decompression */
def blocksToMap(blocks: List[TranslationBlock]) : Map[String, Char] = {
  blocks match {
    case Nil    => Map[String, Char]()
    case h :: t => blocksToMap(t) + (h.getRepr -> h.getChar)
  }
}

/*
 * Translate a binary string representation of the compressed semantics auxdata
 * back into the original uncompressed auxdata
 */
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