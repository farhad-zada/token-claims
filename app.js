const express = require('express')
const mongoSanitize = require('express-mongo-sanitize')
const cookieParser = require('cookie-parser')
const rateLimit = require('express-rate-limit')
const helmet = require('helmet')
const auth = require('./controllers/auth')
const userRoutes = require('./routes/userRoutes')
const claimsRoutes = require('./routes/claimsRoutes')
const globalErrorHandler = require('./controllers/errorController')
const AppError = require('./utils/appError')

const limiter = rateLimit({
  windowMS: 60 * 60 * 1000,
  max: (100 * 60 * 60) / 100,
  standardHeaders: true,
  legacyHeaders: false,
})

app = express()

app.use(express.json())

app.use(limiter)

app.use(mongoSanitize())

app.use(cookieParser())

app.use(helmet())
// app.use('*', (req) => {
//   console.log(`${req.protocol}://${req.get('host')}${req.originalUrl}`)
// })
app.use('/api/v1/user/', userRoutes)
app.use('/api/v1/contracts', claimsRoutes)

app.use('*', (req, res, next) => {
  next(
    new AppError(
      `${req.protocol}://${req.get('host')}${
        req.originalUrl
      } is not a route on this platform.`
    )
  )
})

app.use(globalErrorHandler)

module.exports = app

//TODO: Authentication

//TODO: Save to DB
