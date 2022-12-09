package main

import (
  "bytes"
	"fmt"
  "os"
)

func checkLess(tree byte, arr []byte) bool {
  for _, item := range arr {
    if item >= tree {
      return false
    }
  }
  return true
}

func transpose(grid [][]byte, width, height int) [][]byte {
  newGrid := make([][]byte, 0)
  for i := 0; i < width; i++ {
    newGrid = append(newGrid, make([]byte, height))
  }

  for i := range grid {
    for j := range grid[i] {
      newGrid[j][i] = grid[i][j]
    }
  }

  return newGrid
}

// truly horendous big O - womp womp
func scanGrid1(grid [][]byte, width, height int) int {
  transposed := transpose(grid, width, height)
  num := 0
  for i, row := range grid {
    for j, tree := range grid[i] {
      switch {
        case checkLess(tree, row[:j]):
          num++
        case checkLess(tree, row[j+1:]):
          num++
        case checkLess(tree, transposed[j][:i]):
          num++
        case checkLess(tree, transposed[j][i+1:]):
          num++
      }
    }
  }

  return num
}

func findFirstBigger(tree byte, arr []byte) int {
  for i, height := range arr {
    if height >= tree {
      return i + 1
    }
  }
  return len(arr)
}

func reverse(arr []byte) []byte {
  l := len(arr)
  newArr := make([]byte, l)
  for i, val := range arr {
    newArr[l - 1 - i] = val
  }
  return newArr
}

func scanGrid2(grid [][]byte, width, height int) int {
  transposed := transpose(grid, width, height)
  maxScore := 0
  for i, row := range grid {
    for j, tree := range grid[i] {
      treeScore := findFirstBigger(tree, reverse(row[:j]))
      treeScore *= findFirstBigger(tree, row[j+1:])
      treeScore *= findFirstBigger(tree, reverse(transposed[j][:i]))
      treeScore *= findFirstBigger(tree, transposed[j][i+1:])

      if treeScore > maxScore {
        maxScore = treeScore
      }
    }
  }

  return maxScore
}

func main() {
  data, _ := os.ReadFile("input.txt")
  grid := bytes.Split(data, []byte("\n"))
  height := len(grid)
  width := len(grid[0])
  res1 := scanGrid1(grid, width, height)
  res2 := scanGrid2(grid, width, height)
  
  fmt.Println(grid)
  fmt.Println(res1)
  fmt.Println(res2)
  fmt.Println(height, width)
}
