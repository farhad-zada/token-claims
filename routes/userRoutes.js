const express = require('express')
const auth = require(`./../controllers/auth/index`)
// const user = require(`${__dirname}/../controllers/auth/index`)

const router = express.Router()

/**
 * @dev Some routes below are commented, since they are not yet needed
 * But I creeated them in advance so once needed to be used
 */

router.route('/login').get(auth.login)
router.route('/verifyEmail/:token').get(auth.verifyEmail)
router.use(auth.authed)
router.route('/signup').post(auth.restrict('owner'), auth.signup)
router.route('/logout').get(auth.logout)

// router.route('/forgotPassword').get(auth.forgotPassword)
// router
//   .route('/resetPassword/:token')
//   .post(auth.resetPassword)
// router.route('/updatePassword').post(auth.updatePassword)
// router.route('/deleteUser/:email').get(user.deleteUser)

module.exports = router
