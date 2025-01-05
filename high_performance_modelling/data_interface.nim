import json, os, streams
import tables
import strutils
import asyncdispatch
import httpclient

type
  DataSource* = object
    path*: string
    format*: string
    metadata*: JsonNode

  ParsedData* = object
    data*: JsonNode
    timestamp*: int64
    source*: string

proc newDataSource*(path: string): DataSource =
  result.path = path
  result.format = path.splitFile.ext[1..^1]
  result.metadata = %*{"created": now().toUnix()}

proc loadJson*(ds: DataSource): ParsedData =
  let data = parseJson(readFile(ds.path))
  result = ParsedData(
    data: data,
    timestamp: now().toUnix(),
    source: ds.path
  )

proc loadCsv*(ds: DataSource): ParsedData =
  var jsonData = newJObject()
  var headers: seq[string]
  var firstLine = true
  
  for line in lines(ds.path):
    let fields = line.split(',')
    if firstLine:
      headers = fields
      firstLine = false
      continue
    
    var row = newJObject()
    for i, field in fields:
      row[headers[i]] = %*field
    jsonData.add(row)
  
  result = ParsedData(
    data: jsonData,
    timestamp: now().toUnix(),
    source: ds.path
  )

proc save*(pd: ParsedData, path: string) =
  let f = open(path, fmWrite)
  f.write($pd.data)
  f.close()

proc exportCsv*(pd: ParsedData, path: string) =
  let f = open(path, fmWrite)
  if pd.data.kind == JArray:
    let headers = pd.data[0].getFields().keys.toSeq
    f.writeLine(headers.join(","))
    
    for row in pd.data:
      var values: seq[string]
      for header in headers:
        values.add(row[header].getStr())
      f.writeLine(values.join(","))
  f.close()

proc fetchRemoteData*(url: string): Future[ParsedData] {.async.} =
  let client = newAsyncHttpClient()
  let response = await client.getContent(url)
  client.close()
  
  result = ParsedData(
    data: parseJson(response),
    timestamp: now().toUnix(),
    source: url
  )