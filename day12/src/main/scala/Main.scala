import scala.io.Source
import collection.mutable.PriorityQueue

class HillMap(lines: Array[String]):
  var nodes = Map[(Int, Int), Location]()
  var destination = Location(0)

  val directions = List((-1, 0), (1, 0), (0, -1), (0, 1))

  // create nodes
  for (line, i) <- lines.view.zipWithIndex do
    for (b, j) <- line.getBytes.view.zipWithIndex do
      var node = Location(b)
      if b == 83 then // S
        node = Location(97, 0)
      // these two lines added for part 2
      if b == 97 then
        node = Location(97, 0) // all a's can be starts
      else if b == 69 then // E
        node = Location(122)
        destination = node

      nodes = nodes + ((i,j) -> node) 

  // add edges
  for ((i,j), node) <- nodes do
    for (ni, nj) <- directions do
      val neighborOpt = nodes.get((i + ni, j + nj))
      if neighborOpt.isDefined then 
        val neighbor = neighborOpt.get
        if neighbor.height <= node.height + 1 then
          node.neighbors = neighbor :: node.neighbors

  // dijkstra's algorithm
  def shortestPath: Int =
    def pathOrder(l: Location) = l.distance
    val order = Ordering.by(pathOrder).reverse
    var unvisited = PriorityQueue[Location]()(order)
    unvisited.addAll(nodes.values)
    while !unvisited.isEmpty do
      val node = unvisited.dequeue
      for neighbor <- node.neighbors do
        val distance = node.distance + 1
        if distance < neighbor.distance then
          neighbor.distance = distance

      // hack to get around updated priorities not updating the queue
      val uv = unvisited.toList
      unvisited = PriorityQueue[Location]()(order)
      unvisited.addAll(uv)

      if node == destination then
        return node.distance

    return 0



class Location(var height: Int, var distance: Int = 999999):
  var neighbors = List[Location]()
  override def toString: String =
    s"($height, $distance)"
end Location


@main def hello: Unit = 
  val bufferedSource = Source.fromFile("input.txt")
  val lines = bufferedSource.getLines.toArray
  bufferedSource.close
  val graph = HillMap(lines)
  println(graph.shortestPath)
