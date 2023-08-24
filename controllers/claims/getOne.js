const Claims = require('../../models/claimsModel')
const catchAsync = require('../../utils/catchAsync')
const AppError = require('../../utils/appError')

module.exports = catchAsync(async (req, res, next) => {
  const claims = await Claims.findOne({
    address: req.params.address,
  })

  if (!claims) {
    return next(new AppError('Claims not found!'))
  }

  res.status(200).json({
    status: 'success',
    data: {
      claims,
    },
  })
})
