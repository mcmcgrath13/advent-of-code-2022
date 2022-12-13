import 'dart:io';
import 'dart:collection';

class Item {
  int level = 0;

  Item.parse(String levelString) {
    this.level = int.parse(levelString);
  }

  @override
  String toString() {
    return 'Item = ${level}';
  }
}

// IDs are indexes in List
class Monkey {
  ListQueue<Item> items = ListQueue<Item>();
  int testDivisor = 0;
  int trueMonkey = 0;
  int falseMonkey = 0;
  String operation = "";

  int numInspected = 0;

  Monkey.parse(String contents) {
    var lines = contents.split('\n');
    this.items.addAll(
        readFrom(lines[1], 'Starting items: ').split(', ').map(Item.parse));
    this.operation = readFrom(lines[2], 'Operation: new = ');
    this.testDivisor = int.parse(readFrom(lines[3], 'Test: divisible by '));
    this.trueMonkey =
        int.parse(readFrom(lines[4], 'If true: throw to monkey '));
    this.falseMonkey =
        int.parse(readFrom(lines[5], 'If false: throw to monkey '));
  }

  @override
  String toString() {
    return 'Monkey: (items = ${items}) (divisor = ${testDivisor}) (true = ${trueMonkey}) (false = $falseMonkey) (op = ${operation}) (inspected = ${numInspected})\n';
  }

  int doOperation(int old) {
    var parts = operation.split(' ');
    var left = parts[0] == 'old' ? old : int.parse(parts[0]);
    var right = parts[2] == 'old' ? old : int.parse(parts[2]);
    if (parts[1] == '+') {
      return left + right;
    } else {
      return left * right;
    }
  }
}

String readFrom(String haystack, String needle) {
  return haystack.substring(haystack.indexOf(needle) + needle.length);
}

void runRound(List<Monkey> monkeys) {
  var divisor = monkeys.fold(1, (acc, cur) => acc * cur.testDivisor);
  for (final monkey in monkeys) {
    while (monkey.items.isNotEmpty) {
      monkey.numInspected++;
      var item = monkey.items.removeFirst();
      item.level = monkey.doOperation(item.level);
      // item.level = (item.level / 3).floor();
      item.level = item.level % divisor;
      if (item.level % monkey.testDivisor == 0) {
        monkeys[monkey.trueMonkey].items.add(item);
      } else {
        monkeys[monkey.falseMonkey].items.add(item);
      }
    }
  }
}

int getMonkeyBusiness(List<Monkey> monkeys) {
  monkeys.sort((a, b) => b.numInspected.compareTo(a.numInspected));
  return monkeys[0].numInspected * monkeys[1].numInspected;
}

void main(List<String> arguments) async {
  String contents = await File('input.txt').readAsString();
  List<Monkey> monkeys =
      contents.split('\n\n').map(Monkey.parse).toList(growable: false);
  print(monkeys);
  for (int i = 0; i < 20; i++) {
    runRound(monkeys);
  }
  print(monkeys);
  print(getMonkeyBusiness(monkeys));
}
