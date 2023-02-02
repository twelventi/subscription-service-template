import Koa from "koa";
import bodyParser from "koa-bodyparser";
import Router from "koa-router";
import serve from "koa-static";
import mount from "koa-mount";

const PORT = process.env["PORT"] || 3000;

const app = new Koa();
const router = new Router();

router.get('/', (ctx, next) => {
  ctx.status = 200;
  ctx.body = "Hello World!"
})

const uiPath = __dirname + "/../../ui/dist";

app.use(bodyParser({ enableTypes: ["text"] }));
app.use(mount("/api", router.routes()));
app.use(serve(uiPath));

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}, serving ui from ${uiPath}`);
});
