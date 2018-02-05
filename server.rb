require 'sinatra'
require 'securerandom' #UUID for node identification
require 'pry'
require_relative 'blockchain'

## Node Startup
# Node Identifier
node_identifier = SecureRandom.uuid.gsub('-','').to_s
blockchain = Blockchain.new

# Routes
get '/' do
   binding.pry
end

post '/transaction/new' do
  details = JSON.parse(request.body.read)
  @sender = details["sender"]
  @recipient = details["recipient"]
  @amount = details["amount"]
  blockchain.new_transaction(@sender, @recipient, @amount)
  [201, "transaction added"]
end

get '/mine' do
  # We run the proof of work algorithm to get the next proof...
    last_block = blockchain.last_block
    last_proof = last_block['proof']
    proof = blockchain.proof_of_work(last_proof)

    # We must receive a reward for finding the proof.
    # The sender is "0" to signify that this node has mined a new coin.
    blockchain.new_transaction("0",node_identifier,1)

    # Forge the new Block by adding it to the chain
    previous_hash = blockchain.hash(last_block)
    block = blockchain.new_block(proof, previous_hash)

    response = {
        message: "New Block Forged",
        index: block['index'],
        transactions: block['transactions'],
        proof: block['proof'],
        previous_hash: block['previous_hash']
    }

    [200, response.to_json]
end

post '/nodes/register' do
  address = "#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}"
  node = blockchain.register_node(address)
  [201, "Node #{node} added"]
end

get '/nodes/resolve' do
  replaced = blockchain.resolve_conflicts

  if replaced
    response = {
      'message': 'Our chain was replaced',
      'new_chain': blockchain.chain
      }
  else
    response = {
      'message': 'Our chain is authoritative',
      'chain': blockchain.chain
    }
  end

  [200, response.to_json]

end

get '/chain' do
  chain_hash = Hash.new
  chain_hash[:chain] = blockchain.chain
  chain_hash[:length] = blockchain.chain.count
  return_json = chain_hash.to_json
  [200, return_json]

end
