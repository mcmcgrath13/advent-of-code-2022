use std::fs;

fn main() {
    let input = fs::read_to_string("input.txt").unwrap();
    println!("{}", count_overlapping_assignments(input));
}

fn count_contained_assignments(input: String) -> u32 {
    input
        .lines()
        .map(|line| parse_line(line))
        .fold(0, |acc, parsed| acc + parsed[0].contains(parsed[1]) as u32)
}

fn count_overlapping_assignments(input: String) -> u32 {
    input
        .lines()
        .map(|line| parse_line(line))
        .fold(0, |acc, parsed| acc + parsed[0].overlaps(parsed[1]) as u32)
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
struct Assignment {
    start: u32,
    end: u32,
}

impl Assignment {
    fn new(v: Vec<u32>) -> Assignment {
        Assignment {
            start: v[0],
            end: v[1],
        }
    }

    fn contains(self, other: Assignment) -> bool {
        if self.start >= other.start && self.end <= other.end {
            return true;
        } else if other.start >= self.start && other.end <= self.end {
            return true;
        }
        false
    }

    fn overlaps(self, other: Assignment) -> bool {
        if self.start >= other.start && self.start <= other.end {
            return true;
        } else if self.end >= other.start && self.end <= other.end {
            return true;
        } else if other.start >= self.start && other.start <= self.end {
            return true;
        } else if other.end >= self.start && other.end <= self.end {
            return true;
        }
        false
    }
}

fn parse_line(line: &str) -> Vec<Assignment> {
    dbg!(line);
    line.trim()
        .split(",")
        .map(|a| Assignment::new(a.split("-").map(|v| v.parse::<u32>().unwrap()).collect()))
        .collect()
}

#[cfg(test)]
mod tests {
    use crate::{count_contained_assignments, count_overlapping_assignments};

    #[test]
    fn part1() {
        let input = "
        2-4,6-8
        2-3,4-5
        5-7,7-9
        2-8,3-7
        6-6,4-6
        2-6,4-8
        "
        .trim()
        .to_string();

        assert_eq!(count_contained_assignments(input), 2);
    }

    #[test]
    fn part2() {
        let input = "
        2-4,6-8
        2-3,4-5
        5-7,7-9
        2-8,3-7
        6-6,4-6
        2-6,4-8
        "
        .trim()
        .to_string();

        assert_eq!(count_overlapping_assignments(input), 4);
    }
}
