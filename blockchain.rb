require 'json'
require 'digest' #sha-256 for hashing


class Blockchain
  ### Manages the chain ###

  attr_accessor :chain, :transactions

  def initialize
    self.chain = []
    self.transactions = []

    # Creating the Genesis Block
    self.new_block(100,1)
  end

  def new_transaction(sender, recipient, amount)
    # Add new transaction to transactions array
    #sender = params['sender']
    #recipient = params['recipient']
    #amount = params['amount']

    self.transactions << {
      'sender' => sender,
      'recipient' => recipient,
      'amount' => amount
    }

    self.last_block['index'] + 1  

  end

  def new_block(proof, last_block_hash=nil)
    # Creates a new block and adds it to the chain
    ## Get the proof needed
    ## Get the hash of the last block
    calculated_last_hash = self.hash self.last_block

    ## Create the block

    block = {
          'index'=> self.chain.count + 1,
          'timestamp'=> Time.now(),
          'transactions'=> self.transactions,
          'proof'=> proof,
          'previous_hash'=> last_block_hash || calculated_last_hash,
      }

    ## Reset the transactions
    self.transactions = []

    ## Add to the chain
    self.chain << block
    block

  end

  def hash(block)
    # Hashes a block

    json_block = block.to_json
    Digest::SHA256.hexdigest json_block
  end

  def last_block
    # Gets last block in chain
    return self.chain[-1]
  end

  # Proof of Work Algorithm
  # We needs a calculator and a validator

  def proof_of_work(previous_proof)
    # Find a number that when multiplied by the previous proof,
    # the hash has 4 leading 0s
    proof = 0

    while validate_proof(previous_proof, proof) == false
      proof += 1
    end

    return proof

  end

  def validate_proof(previous_proof, proof)
    # does the product of the current guessed proof and the previous proof
    # yield a hash with 4 leading 0s (0000...)?

    guess = previous_proof * proof
    guess = guess.to_s
    hashed_guess = Digest::SHA256.hexdigest guess
    hashed_guess[0..3] == "0000"

  end

end
