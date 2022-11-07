import { join } from "path"
import { ldbd } from "../src"
void (async(): Promise<void> => {
  await ldbd({
    src: join(__dirname, "test.sql"),
    port: 8001
  })
})()
  // eslint-disable-next-line no-console
  .catch(console.error)

