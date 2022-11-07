export type Table = {
  name: string,
  columns: Column[]
}

export type Column = {
  name: string,
  type?: string,
  length?: number,
  pk: boolean,
  fk: { columnName: string, tableName: string }[],
  notNull: boolean,
  unique: boolean
}

export type ImportData = { nomnomlCode: string | null, error: string | null }
