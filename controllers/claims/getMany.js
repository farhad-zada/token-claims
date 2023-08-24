const Claims = require('../../models/claimsModel')
const catchAsync = require('../../utils/catchAsync')
const APIFeatures = require('../../utils/apiFeatures')

module.exports = catchAsync(async (req, res, next) => {
  const query = new APIFeatures(Claims.find(), req.query)
    .filter()
    .limitFields()
    .sort()
    .paginate(1000)

  const claims = await query.query
  res.status(200).json({
    status: 'success',
    data: {
      claims,
    },
  })
})
