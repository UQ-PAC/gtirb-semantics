import java.io.{FileInputStream, BufferedWriter, FileWriter, File}
import com.grammatech.gtirb.proto.IR.{IR => Gtirb}
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
 // dump(semantics(0), args(1))
}

def readIR(path: String) = {
  var fIn   = new FileInputStream(path)
  Gtirb.parseFrom(fIn)
}

def dump(json: String, path: String) = {
  val bw = new BufferedWriter(new FileWriter(new File(path)))
  bw.write(json)
  bw.close()
}

def getSemantics(mods: Seq[Module]) = {
  val modAux  = mods.map(_.auxData)
  val astsRaw = modAux.map(_.get("ast").get.data).head.toByteArray()
  val mapSize = astsRaw(0).toInt
  val popped  = astsRaw.slice(1, astsRaw.length)
  val tmap    = pullTMap(popped, mapSize, Map[String, Char]())
  println(mapSize)
  println(tmap)
  //astsRaw.map(_.toStringUtf8())
  //val readable  = astsRaw.map(_.toStringUtf8())
  //readable.map(_.parseJson)
}

def pad_8(in: String) = {
  "0" * (8 - (in.length % 8))
}

def pullTMap(raw: Array[Byte], mapSize: Int, map: Map[String, Char]) : Map[String, Char] = {
  if (mapSize == 0) {
    map
  } else {
    val base  = raw(0)
    val bits  = raw(1).toInt
    val cend  = if (bits > 8) { 4 } else { 3 }
    val comp  = raw.slice(2, cend).toList.map(_.toInt).map(_.toBinaryString).map(s => (pad_8(s) + s)).mkString("")
    val key   = comp.slice(comp.length - bits, comp.length)
    val nmap  = map + (key -> base.toChar)
    val cut   = raw.slice(cend, raw.length)
    println(s"$base $bits $key")
    pullTMap(cut, (mapSize - 1), nmap)
  } 
}