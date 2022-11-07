import express, { Response } from "express"
import { readFileSync, watchFile } from "fs"
import { AST, Parser } from "node-sql-parser"
import { join, parse } from "path"
import Handlebars from "handlebars"
import EventEmitter from "events"

const emitter = new EventEmitter()
setInterval(() => {
  emitter.emit("keep-alive")
}, 10000)

const parser = new Parser()

export type Table = {
  name: string,
  columns: {
    name: string,
    type: string,
    length?: number,
    pk: boolean,
    fk: { columnName: string, tableName: string }[]
  }[]
}

export type ImportData = { nomnomlCode: string | null, error: string | null }

const _ast2tables = (ast: AST | AST[]): Table[] => {
  return (Array.isArray(ast) ? ast : [ast]).reduce((acc: Table[], e) => {
    if (e.type === "create") {
      if (e.keyword === "table") {

        const table: Table = {
          name: e.table!.map(e => e.table).join(" "),
          columns: []
        }

        e.create_definitions?.forEach(column => {
          if (column.resource === "column") {
            table.columns.push({
              name: column.column.column,
              type: column.definition.dataType,
              length: column.definition.length,
              pk: false,
              fk: []
            })
          }
        })

        e.create_definitions?.forEach(constraint => {
          if (constraint.resource === "constraint") {
            constraint.definition.forEach(({ type, column }: { type: string, column: string }) => {
              if (type === "column_ref") {
                for (let i = 0; i < table.columns.length; i++) {
                  const c = table.columns[i]
                  if (c.name === column) {
                    if (constraint.constraint_type === "primary key") {
                      c.pk = true
                    } else if (constraint.constraint_type === "FOREIGN KEY") {
                      for (let l = 0; l <  constraint.reference_definition.definition.length; l++) {
                        c.fk.push({
                          columnName: constraint.reference_definition.definition[l].column,
                          tableName: constraint.reference_definition.table[l].table
                        })
                      }
                    }
                    break
                  }
                }
              }
            })
          }
        })
        acc.push(table)
      }
    }
    return acc
  }, [])
}

const _tables2nomnomlCode = (tables: Table[]): string => {


  return [
    // "#font: Menlo",

    ...tables.map(e => {
      return `[${e.name}|${e.columns.map(e =>
        `${e.name}: ${[
          e.pk ? "(PK)" : null,
          e.fk.length ? "(FK)" : null,
          e.type,
          e.length ? `(${e.length})` : null
        ].filter(e => e).join(" ")}`
      )
        .join("|")}]`
    }),

    ...tables.reduce((acc: string[], { name, columns }) => {
      columns.forEach(({ name: sourceColumnName, fk }) => {
        if (fk.length) {
          fk.forEach(({ tableName, columnName }) => {
            acc.push(`[${name}]${sourceColumnName}--${columnName}[${tableName}]`)
          })
        }
      })
      return acc
    }, [])
  ].filter(e => e).join("\n")
}

const _importSQL = (src: string, dbType: string, lastData?: ImportData): ImportData => {
  try {
    const sql = readFileSync(src, "utf-8")
    const ast = parser.astify(sql, { database: dbType })
    const tables = _ast2tables(ast)

    // console.dir(ast, { depth: null })
    // console.dir(tables, { depth: null })

    const nomnomlCode = _tables2nomnomlCode(tables)
    const data = { nomnomlCode, error: null }
    emitter.emit("change", data)
    return data
  } catch (err) {
    const message = (err as Error).message
    const data = { nomnomlCode: lastData?.nomnomlCode || null, error: message }
    emitter.emit("change", data)
    return data
  }
}

export const ldbd = async(options: {
  src: string,
  dbType: string,
  port: number
}): Promise<void> => {
  const nomnoml = readFileSync(require.resolve(join(require.resolve("nomnoml"))), "utf-8")
  const graphre = readFileSync(require.resolve(join(require.resolve("graphre"), "../dist/graphre.js")), "utf-8")
  const template = Handlebars.compile(readFileSync(join(__dirname, "index.hbs"), "utf-8"))

  let data = _importSQL(options.src, options.dbType)
  watchFile(options.src, () => {
    data = _importSQL(options.src, options.dbType, data)
  })

  const app = express()

  app.get("/", (req, res) => {
    res.send(template({
      nomnoml,
      graphre,
      title: parse(options.src).base
    }))
  })

  app.get("/stream", (req, res) => {
    const sendData = (res: Response, data: ImportData): void => {
      res.write(`data: ${JSON.stringify({
        nomnomlCode: data.nomnomlCode,
        error: data.error
      })}\nretry: 1000\n\n`)
    }

    res.set({
      "Cache-Control": "no-cache",
      "Content-Type": "text/event-stream",
      Connection: "keep-alive"
    })

    res.flushHeaders()

    sendData(res, data)

    emitter.on("change", data => {
      sendData(res, data)
    })

    emitter.on("keep-alive", () => {
      res.write(":keep-alive\n\n")
    })
  })

  // eslint-disable-next-line no-console
  app.listen(options.port, () => console.log(`live db schema available at http://localhost:${options.port}`))
}
