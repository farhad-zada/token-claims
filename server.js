require('dotenv').config()
const mongoose = require('mongoose')
const app = require('./app')

const port = process.env.PORT
const database = process.env.DATABASE

const MONGO_URI = process.env.MONGO_URI.replace(
  '<PASSWORD>',
  process.env.DATABASE_PASSWORD
).replace('<DATABASE>', database)

mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
})

const server = app.listen(port, () => {
  console.log(`Metafluence APP running at port: ${port}`)
})
