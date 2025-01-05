import nimblas
import nimpy
import sequtils
import math

type
  Matrix* = object
    data*: seq[float64]
    rows*, cols*: int

  Vector* = distinct seq[float64]

proc newMatrix*(rows, cols: int): Matrix =
  result.data = newSeq[float64](rows * cols)
  result.rows = rows
  result.cols = cols

proc `[]`*(m: Matrix, i, j: int): float64 =
  m.data[i * m.cols + j]

proc `[]=`*(m: var Matrix, i, j: int, val: float64) =
  m.data[i * m.cols + j] = val

proc matrixMultiply*(a, b: Matrix): Matrix =
  assert a.cols == b.rows
  result = newMatrix(a.rows, b.cols)
  let
    m = a.rows.int32
    k = a.cols.int32
    n = b.cols.int32

  dgemm(RowMajor, NoTranspose, NoTranspose,
        m, n, k,
        1.0,
        a.data[0].unsafeAddr, k,
        b.data[0].unsafeAddr, n,
        0.0,
        result.data[0].addr, n)

proc vectorMultiply*(m: Matrix, v: Vector): Vector =
  assert m.cols == v.seq[float64].len
  result = Vector(newSeq[float64](m.rows))
  let
    m_rows = m.rows.int32
    m_cols = m.cols.int32

  dgemv(RowMajor, NoTranspose,
        m_rows, m_cols,
        1.0,
        m.data[0].unsafeAddr, m_cols,
        v.seq[float64][0].unsafeAddr, 1,
        0.0,
        result.seq[float64][0].addr, 1)

proc norm*(v: Vector): float64 =
  let n = v.seq[float64].len.int32
  dnrm2(n, v.seq[float64][0].unsafeAddr, 1)

proc scale*(v: var Vector, alpha: float64) =
  let n = v.seq[float64].len.int32
  dscal(n, alpha, v.seq[float64][0].addr, 1)

when isMainModule:
  # Example usage
  var m = newMatrix(2, 2)
  m[0, 0] = 1.0
  m[0, 1] = 2.0
  m[1, 0] = 3.0
  m[1, 1] = 4.0
  
  let v = Vector(@[1.0, 2.0])
  let result = m.vectorMultiply(v)