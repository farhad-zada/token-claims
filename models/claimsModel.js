const mongoose = require('mongoose')

const claimsSchema = mongoose.Schema({
  address: {
    type: String,
    unique: true,
    required: [true, 'Address have not been provided.'],
  },
  chain_id: {
    type: Number,
    required: [true, 'Chain ID have not been provided.'],
  },
  added_at: {
    type: Date,
    default: Date.now(),
  },
})

const Claims = mongoose.model('Claims', claimsSchema)

module.exports = Claims
