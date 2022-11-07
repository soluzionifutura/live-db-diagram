#!/usr/bin/env node
import { join } from "path"
import { ldbd } from "."

const [,, src] = process.argv

void (async(): Promise<void> => {
  await ldbd({
    src: join(process.cwd(), src),
    port: 8001
  })
})()
  // eslint-disable-next-line no-console
  .catch(console.error)
