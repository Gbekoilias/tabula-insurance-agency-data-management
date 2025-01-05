import random, math, sequtils
import threadpool

type
  OptimizationMethod* = enum
    GradientDescent, EvolutionaryAlgorithm

  OptimizationParams* = object
    maxIterations*: int
    tolerance*: float
    learningRate*: float
    populationSize*: int
    mutationRate*: float

  OptimizationResult* = object
    optimalValues*: seq[float]
    objectiveValue*: float
    iterations*: int
    converged*: bool

proc gradientDescent*(
  objective: proc(x: seq[float]): float,
  gradient: proc(x: seq[float]): seq[float],
  initialGuess: seq[float],
  params: OptimizationParams
): OptimizationResult =
  var
    currentPoint = initialGuess
    iteration = 0
    prevValue = objective(currentPoint)
  
  while iteration < params.maxIterations:
    let grad = gradient(currentPoint)
    currentPoint = zip(currentPoint, grad).mapIt(
      it[0] - params.learningRate * it[1])
    
    let currentValue = objective(currentPoint)
    if abs(currentValue - prevValue) < params.tolerance:
      return OptimizationResult(
        optimalValues: currentPoint,
        objectiveValue: currentValue,
        iterations: iteration,
        converged: true
      )
    
    prevValue = currentValue
    iteration += 1
  
  OptimizationResult(
    optimalValues: currentPoint,
    objectiveValue: prevValue,
    iterations: iteration,
    converged: false
  )

proc evolve*(
  objective: proc(x: seq[float]): float,
  dimensions: int,
  params: OptimizationParams
): OptimizationResult =
  randomize()
  var
    population = newSeqWith(params.populationSize,
      newSeqWith(dimensions, rand(1.0)))
    bestSolution = population[0]
    bestFitness = objective(bestSolution)
    generation = 0
  
  while generation < params.maxIterations:
    parallel:
      for i in 0..<params.populationSize:
        let fitness = objective(population[i])
        if fitness < bestFitness:
          bestFitness = fitness
          bestSolution = population[i]
    
    var newPopulation = newSeq[seq[float]](params.populationSize)
    for i in 0..<params.populationSize:
      let
        parent1 = population[rand(params.populationSize-1)]
        parent2 = population[rand(params.populationSize-1)]
      
      newPopulation[i] = zip(parent1, parent2).mapIt(
        if rand(1.0) < params.mutationRate:
          rand(1.0)
        else:
          (it[0] + it[1]) / 2.0
      )
    
    population = newPopulation
    generation += 1
  
  OptimizationResult(
    optimalValues: bestSolution,
    objectiveValue: bestFitness,
    iterations: generation,
    converged: true
  )