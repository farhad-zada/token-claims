const router = require('express').Router()
const claimsController = require('../controllers/claims/index')
const authorize = require('./../controllers/auth/restrict')
const authed = require('./../controllers/auth/authed')

router.use(authed) // This forces user to log in to go forward
router.use(authorize('owner', 'admin')) // This restricts the roles to be either owner or admin to go forward

router
  .route('/')
  .get(claimsController.getMany)
  .post(claimsController.addOne)
  .delete(claimsController.deleteOne)

router.route('/:address').get(claimsController.getOne)

module.exports = router
