const Claims = require('../../models/claimsModel')
const AppError = require('../../utils/appError')
const catchAsync = require('../../utils/catchAsync')

module.exports = catchAsync(async (req, res, next) => {
  const { address, chain_id } = req.body
  if (!address & !chain_id) {
    return next(
      new AppError('address and chain_id not provided in request body!')
    )
  } else if (!address) {
    return next(new AppError('address not provided in request body!'))
  } else if (!chain_id) {
    return next(new AppError('chain_id not provided in request body!'))
  }

  const claims = await Claims.create({
    address,
    chain_id,
  })

  res.status(200).json({
    status: 'success',
    data: {
      claims,
    },
  })
})
