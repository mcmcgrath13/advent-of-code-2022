import System

struct Store {
    var ore: UInt8 = 0
    var clay: UInt8 = 0
    var obsidian: UInt8 = 0
    var geode: UInt8 = 0

    mutating func add(ore amount: UInt8) {
        ore += amount
    }
    mutating func add(clay amount: UInt8) {
        clay += amount
    }
    mutating func add(obsidian amount: UInt8) {
        obsidian += amount
    }
    mutating func add(geode amount: UInt8) {
        geode += amount
    }

    // meant to be called by the state's store (wallet)
    func canAfford(cost: Store) -> Bool {
        ore >= cost.ore && clay >= cost.clay && obsidian >= cost.obsidian
    }

    mutating func buy(cost: Store) {
        ore -= cost.ore
        clay -= cost.clay
        obsidian -= cost.obsidian
    }
}

extension Store: Hashable {
    static func == (lhs: Store, rhs: Store) -> Bool {
        return lhs.ore == rhs.ore && lhs.clay == rhs.clay && lhs.obsidian == rhs.obsidian && lhs.geode == rhs.geode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ore)
        hasher.combine(clay)
        hasher.combine(obsidian)
        hasher.combine(geode)
    }
}

func unwrapInt(match: Regex<AnyRegexOutput>.Match, key: String) -> UInt8 {
    return UInt8(match[key]!.substring!)!
}

struct Blueprint {
    var id: UInt8
    var robots: [String: Store] = [:]
    var maxes: [String: UInt8] = ["ore": 0, "clay": 0, "obsidian": 0]

    init(line: Substring) throws {
        let regex = try Regex("Blueprint (?<id>[0-9]+): Each ore robot costs (?<oo>[0-9]+) ore. Each clay robot costs (?<co>[0-9]+) ore. Each obsidian robot costs (?<obo>[0-9]+) ore and (?<obc>[0-9]+) clay. Each geode robot costs (?<go>[0-9]+) ore and (?<gob>[0-9]+) obsidian.")
        
        let match = try regex.firstMatch(in: line)!
        id = unwrapInt(match: match, key: "id")
        robots["ore"] = Store(ore: unwrapInt(match: match, key: "oo"))
        robots["clay"] = Store(ore: unwrapInt(match: match, key: "co"))
        robots["obsidian"] = Store(ore: unwrapInt(match: match, key: "obo"), clay: unwrapInt(match: match, key: "obc"))
        robots["geode"] = Store(ore: unwrapInt(match: match, key: "go"), obsidian: unwrapInt(match: match, key: "gob"))

        for (_, cost) in robots {
            if cost.ore > maxes["ore"]! { maxes["ore"] = cost.ore}
            if cost.clay > maxes["clay"]! { maxes["clay"] = cost.clay}
            if cost.obsidian > maxes["obsidian"]! { maxes["obsidian"] = cost.obsidian}
        }
    }
}

struct State {
    var wallet: Store = Store()
    var steps: UInt8 = 1
    var ore: UInt8 = 1
    var clay: UInt8 = 0
    var obsidian: UInt8 = 0
    var geode: UInt8 = 0

    subscript(index: String) -> UInt8 {
        get {
            switch index {
                case "ore":
                    return ore
                case "clay":
                    return clay
                case "obsidian":
                    return obsidian
                default:
                    return geode
            } 
        }
        set {
            switch index {
                case "ore":
                    ore = newValue
                case "clay":
                    clay = newValue
                case "obsidian":
                    obsidian = newValue
                default:
                    geode = newValue
            } 
        }
        
    }

    mutating func collect() {
        wallet.add(ore: ore)
        wallet.add(clay: clay)
        wallet.add(obsidian: obsidian)
        wallet.add(geode: geode)
    }
}

extension State: Hashable {
    static func == (lhs: State, rhs: State) -> Bool {
        return lhs.wallet == rhs.wallet && lhs.steps == rhs.steps && lhs.ore == rhs.ore && lhs.clay == rhs.clay && lhs.obsidian == rhs.obsidian && lhs.geode == rhs.geode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet)
        hasher.combine(steps)
        hasher.combine(ore)
        hasher.combine(clay)
        hasher.combine(obsidian)
        hasher.combine(geode)
    }
}


func run(blueprint: Blueprint, steps: UInt8) -> UInt8 {
    var cache: [State: UInt8] = [:]
    return run(cache: &cache, blueprint: blueprint, state: State(), numSteps: steps)
}
func run(cache: inout [State: UInt8], blueprint: Blueprint, state: State, numSteps: UInt8) -> UInt8 {
    var thisState = state
    // decide to build
    if thisState.steps == numSteps { 
        return state.geode
    }

    if let result = cache[state] {
        return result
    }
    
    let canBuild = blueprint.robots.filter({ (key: String, value: Store) -> Bool in return state.wallet.canAfford(cost: value) })
    
    // collect
    thisState.collect()
    thisState.steps += 1

    // build - if we can build a geode, we build a geode
    var result: UInt8 = 0
    if let cost = canBuild["geode"] {
        var nextState = thisState // should copy
        nextState.geode += 1
        nextState.wallet.buy(cost: cost)
        result = run(cache: &cache, blueprint: blueprint, state: nextState, numSteps: numSteps)
    } else {
        var nextStates: [State] = []
        for (robot, cost) in canBuild {
            if robot == "ore" && thisState.ore >= blueprint.maxes["ore"]! { continue }
            if robot == "clay" && thisState.clay >= blueprint.maxes["clay"]! { continue }
            if robot == "obsidian" && thisState.obsidian >= blueprint.maxes["obsidian"]! { continue }
            var nextState = thisState // should copy
            nextState[robot] += 1
            nextState.wallet.buy(cost: cost)
            nextStates.append(nextState)
        }

        // if we can build 3 + things, we should probably do that and not keep hoarding
        if canBuild.count < 3 { nextStates.append(thisState) }

        result = nextStates.map({ (s: State) -> UInt8 in run(cache: &cache, blueprint: blueprint, state: s, numSteps: numSteps)}).max()!
    }
    result += state.geode

    cache[state] = result
    return result
}

func parseFile(contents: String) throws -> [Blueprint] {
    return try contents.split(separator: "\n").map { try Blueprint(line: $0) }
}

// figuring out how to read the file was taking too long...
let example = """
Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.
"""

let input = """
Blueprint 1: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 20 clay. Each geode robot costs 3 ore and 14 obsidian.
Blueprint 2: Each ore robot costs 3 ore. Each clay robot costs 3 ore. Each obsidian robot costs 2 ore and 20 clay. Each geode robot costs 2 ore and 20 obsidian.
Blueprint 3: Each ore robot costs 3 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 16 clay. Each geode robot costs 3 ore and 9 obsidian.
Blueprint 4: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 2 ore and 15 clay. Each geode robot costs 2 ore and 13 obsidian.
Blueprint 5: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 16 clay. Each geode robot costs 3 ore and 13 obsidian.
Blueprint 6: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 2 ore and 14 clay. Each geode robot costs 3 ore and 14 obsidian.
Blueprint 7: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 6 clay. Each geode robot costs 2 ore and 20 obsidian.
Blueprint 8: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 5 clay. Each geode robot costs 4 ore and 8 obsidian.
Blueprint 9: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 3 ore and 19 clay. Each geode robot costs 3 ore and 8 obsidian.
Blueprint 10: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 2 ore and 14 clay. Each geode robot costs 3 ore and 8 obsidian.
Blueprint 11: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 3 ore and 19 clay. Each geode robot costs 4 ore and 13 obsidian.
Blueprint 12: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 20 clay. Each geode robot costs 4 ore and 18 obsidian.
Blueprint 13: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 2 ore and 16 clay. Each geode robot costs 4 ore and 16 obsidian.
Blueprint 14: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 3 ore and 20 clay. Each geode robot costs 2 ore and 16 obsidian.
Blueprint 15: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 3 ore and 11 clay. Each geode robot costs 3 ore and 8 obsidian.
Blueprint 16: Each ore robot costs 4 ore. Each clay robot costs 3 ore. Each obsidian robot costs 4 ore and 19 clay. Each geode robot costs 4 ore and 12 obsidian.
Blueprint 17: Each ore robot costs 2 ore. Each clay robot costs 4 ore. Each obsidian robot costs 2 ore and 20 clay. Each geode robot costs 3 ore and 15 obsidian.
Blueprint 18: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 15 clay. Each geode robot costs 4 ore and 20 obsidian.
Blueprint 19: Each ore robot costs 4 ore. Each clay robot costs 3 ore. Each obsidian robot costs 4 ore and 15 clay. Each geode robot costs 4 ore and 9 obsidian.
Blueprint 20: Each ore robot costs 3 ore. Each clay robot costs 3 ore. Each obsidian robot costs 2 ore and 7 clay. Each geode robot costs 2 ore and 9 obsidian.
Blueprint 21: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 3 ore and 19 obsidian.
Blueprint 22: Each ore robot costs 4 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 17 clay. Each geode robot costs 3 ore and 13 obsidian.
Blueprint 23: Each ore robot costs 3 ore. Each clay robot costs 4 ore. Each obsidian robot costs 3 ore and 18 clay. Each geode robot costs 4 ore and 19 obsidian.
Blueprint 24: Each ore robot costs 3 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 17 clay. Each geode robot costs 2 ore and 13 obsidian.
Blueprint 25: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 2 ore and 15 clay. Each geode robot costs 3 ore and 16 obsidian.
Blueprint 26: Each ore robot costs 4 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 15 clay. Each geode robot costs 2 ore and 13 obsidian.
Blueprint 27: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 18 clay. Each geode robot costs 4 ore and 9 obsidian.
Blueprint 28: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 7 clay. Each geode robot costs 2 ore and 19 obsidian.
Blueprint 29: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 15 clay. Each geode robot costs 4 ore and 17 obsidian.
Blueprint 30: Each ore robot costs 4 ore. Each clay robot costs 4 ore. Each obsidian robot costs 4 ore and 9 clay. Each geode robot costs 4 ore and 16 obsidian.
"""

func part1(contents: String) throws {
    let blueprints = try parseFile(contents: contents)
    var quality = 0
    for blueprint in blueprints {
        let res = run(blueprint: blueprint, steps: 24)
        quality += Int(blueprint.id) * Int(res)
    }
    print(quality)
}

func part2(contents: String) throws {
    let blueprints = try parseFile(contents: contents)
    var quality = 1
    for (index, blueprint) in blueprints.enumerated() {
        if index == 3 { break }
        let res = Int(run(blueprint: blueprint, steps: 32))
        print(res)
        quality *= res
    }
    print(quality)
}

do {
    try part1(contents: example)
    try part2(contents: input)
} catch {
    print("Unexpected error: \(error).")
}

