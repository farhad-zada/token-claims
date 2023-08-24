const AppError = require('../../utils/appError')
const catchAsync = require('../../utils/catchAsync')
const jwt = require('jsonwebtoken')
require('dotenv').config()
const User = require(`${__dirname}/../../models/userModel`)
const createSendToken = require('./createSendToken')

module.exports = catchAsync(async (req, res, next) => {
  // 1. Check if password and email provided
  const { email, password } = req.body

  if (!email || !password)
    return next(
      new AppError(
        'Please, provide email and password.',
        404,
      ),
    )

  // 2. Check if user exists
  const user = await User.findOne({ email }).select(
    '+password',
  )

  if (
    !user ||
    !(await user.correctPassword(password, user.password))
  )
    return next(
      new AppError('Incorrect email or password!', 400),
    )
  createSendToken(user, 200, res)
})
