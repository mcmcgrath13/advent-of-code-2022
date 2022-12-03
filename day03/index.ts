import * as fs from "fs";

const readFile = () => {
    return fs.readFileSync("input.txt").toString()
    
}

const getPrioritiesPart1 = (contents: string): number => {
    const rucksacks = contents.split("\n").filter(c => c.length > 0)
    const components = rucksacks.map(items => [items.slice(0, items.length / 2), items.slice(items.length / 2)])

    return components.reduce((acc, rucksack) => {
        const first = new Set(rucksack[0])
        const second = new Set(rucksack[1])
        const letter = intersection(first, second).values().next().value
        return acc + getLetterValue(letter)
    }, 0)
}

const getPrioritiesPart2 = (contents: string): number => {
    const rucksacks = contents.split("\n").filter(c => c.length > 0)
    let res = 0
    for (let i = 0; i < rucksacks.length; i += 3) {
        const group = rucksacks.slice(i, i+3).map(r => new Set(r))
        const diff = group.reduce((acc, curr) => intersection(acc, curr))
        res += getLetterValue(diff.values().next().value)
    }

    return res
}

const getLetterValue = (letter: string): number => {
    const code = letter.charCodeAt(0);
    // lowercase
    if (code >= 97) {
        return code - 96
    } else {
        return code - 64 + 26
    }
}

// from MDN docs
function intersection(setA: Set<string>, setB: Set<string>): Set<string> {
    const _intersection: Set<string> = new Set();
    for (const elem of setB) {
      if (setA.has(elem)) {
        _intersection.add(elem);
      }
    }
    return _intersection;
  }

const testInput = `
vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw
`
console.log(getPrioritiesPart1(testInput) == 157)
console.log(getPrioritiesPart2(testInput) == 70)

console.log(getPrioritiesPart2(readFile()))