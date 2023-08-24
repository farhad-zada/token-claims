const validator = require('validator')

const AppError = require('../../utils/appError')

const catchAsync = require('../../utils/catchAsync')

const User = require(`./../../models/userModel`)

require('dotenv').config()

//TODO: test this
module.exports = catchAsync(async (req, res, next) => {
  const { email } = req.body
  if (!email) {
    return next(
      new AppError(
        'Request needs to include email at body.',
        400,
      ),
    )
  }

  if (!validator.isEmail(email)) {
    return next(new AppError('Invalid email!', 400))
  }

  const user = await User.findOne({ email })

  const resetToken = user.createToken('passwordResetToken')

  await user.save({ validateBeforeSave: false })

  //RESET URL
  const url = `${req.protocol}://${req.get(
    'host',
  )}/app/v1/user/resetPassword/${resetToken}`

  res.json({ status: 'success', data: { url } })

  //TODO: add email here
})
