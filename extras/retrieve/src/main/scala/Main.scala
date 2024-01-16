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
  mod.auxData("ast").data.toStringUtf8.parseJson
}