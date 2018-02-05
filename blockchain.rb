require 'json'
require 'digest'
require 'uri'
require 'net/http'


class Blockchain
  ### Manages the chain ###

  attr_accessor :chain, :transactions, :nodes

  def initialize
    self.chain = []
    self.transactions = []

    # Creating the Genesis Block
    self.new_block(100,1)

    self.nodes = Set.new
  end

  ## Node Maintainence ##

  def register_node(address)
    self.nodes << address
    address
  end

  #######################

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

  ## Chain Maintainence ##

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

  def valid_chain?(chain)
    # Iterate over available chain to verify hashes and proof of work
    last_block = chain[0]
    current_index = 1

    while current_index < self.chain.size
      block = chain[current_index]

      # Checks to see if the transactions or data has been altered
      return false if block["previous_hash"] != self.hash(last_block)

      # Checks the proof of work
      return false unless self.validate_proof(last_block["proof"], block['proof'])

      # Move to the next block
      last_block = block
      current_index += 1
    end

    return true

  end

  def resolve_conflicts
    neighbours = self.nodes
    new_chain = nil

    max_length = self.chain.size

    neighbours.each do |node|
      response = Net::HTTP.get_response(URI("http://#{node}/chain"))

      if response.code == "200"
        @length = JSON.parse(response.body)['length']
        @chain = JSON.parse(response.body)['chain']
      end

      # Check if the length is longer and the chain is valid
      if @length > max_length and self.validate_chain(@chain)
          max_length = @length
          new_chain = @chain
        end

      if new_chain
        self.chain = new_chain
        return true
      end
    end

          return false

  end

  ########################


  ## Utility Methods ##

  def hash(block)
    # Hashes a block

    json_block = block.to_json
    Digest::SHA256.hexdigest json_block
  end

  def last_block
    # Gets last block in chain
    return self.chain[-1]
  end

  #####################

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
