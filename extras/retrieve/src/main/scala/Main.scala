import java.io.{FileInputStream, BufferedWriter, FileWriter, File}
import com.grammatech.gtirb.proto.IR.IR
import com.grammatech.gtirb.proto.Module.Module
import com.grammatech.gtirb.proto.Section.Section
import spray.json._
import DefaultJsonProtocol._

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
  val modAux  = mods.map(_.auxData)
  val astsRaw = modAux.map(_.get("ast").get.data).head.toByteArray()
  val nMapBlk = astsRaw(0).toInt
  val popped  = astsRaw.slice(1, astsRaw.length)
  val tMap    = pullTMap(popped, nMapBlk, Map[String, Char]())
  val mapSize = countMap(tMap.keys.toList)
  val content = astsRaw.slice(mapSize, astsRaw.length)
  decompress(content, tMap)
}

def pad_8(in: String) = {
  "0" * (8 - (in.length % 8))
}

def pullTMap(raw: Array[Byte], mapSize: Int, map: Map[String, Char]) : Map[String, Char] = {
  if (mapSize == 0) {
    map
  } else {
    val bits  = raw(1).toInt
    val cend  = if (bits > 8) { 4 } else { 3 }
    val comp  = raw.slice(2, cend).toList.map(_.toInt).map(_.toBinaryString)
    val pads  = comp.map(s => (pad_8(s) + s)).mkString("")
    val key   = pads.slice(pads.length - bits, pads.length)
    val nmap  = map + (key -> raw(0).toChar)
    val cut   = raw.slice(cend, raw.length)
    pullTMap(cut, (mapSize - 1), nmap)
  } 
}

def countMap(tMap: List[String]) : Int = {
  if (tMap.length == 0) { 0 }
  else {
    val first = if (tMap(0).length > 8) { 2 } else { 1 }
    first + countMap(tMap.slice(1, tMap.length))
  } 
}

def decompress(compressed: Array[Byte], tMap: Map[String, Char]) = {
  val bits = compressed.map(_.toInt).map(_.toBinaryString).mkString("")
  println(bits)
}